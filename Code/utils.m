/*
function ReplaceStringFunc(s,fs,ts)
  if Type(fs) eq SeqEnum then
    for i:=1 to #fs do
      s:=ReplaceStringFunc(s,fs[i],ts[i]);
    end for;
    return s;
  end if;
  s:=CodeToString(255) cat Sprint(s) cat CodeToString(255);
  while Position(s,fs) ne 0 do
    p:=Position(s,fs);
    p:=[p-1,#fs,#s-p-#fs+1];
    s1,s2,s3:=Explode(Partition(Eltseq(s),p));
    s:=&cat(s1) cat ts cat &cat(s3);
  end while;
  return s[[2..#s-1]];
end function;
*/

intrinsic ReplaceString(s::MonStgElt, fs::MonStgElt, ts::MonStgElt) -> MonStgElt
    {Return a string obtained from the string s by replacing all occurences of the SINGLE character fs with ts.}
    assert #fs eq 1;
    L := Split(s, fs);
    // Split doesn't deal with fs at the beginning or end of the string correctly.
    if s[1] eq fs then Insert(~L, 1, ""); end if;
    if s[#s] eq fs then Append(~L, ""); end if;
    return Join(L, ts);
end intrinsic;

intrinsic ReplaceString(s::MonStgElt, fs::[MonStgElt], ts::[MonStgElt]) -> MonStgElt
  {Return a string obtained from the string s by replacing all occurences of strings in fs with strings in ts.}
  // assert not (true in [ts[i] in s : i in [1..#ts]]);
  for i:=1 to #fs do
    s:=ReplaceString(s,fs[i],ts[i]);
  end for;
  return s;
end intrinsic;

// procedure versions
intrinsic ReplaceString(~s::MonStgElt, fs::MonStgElt, ts::MonStgElt)
  {In the string s, replace all occurences of fs with ts.}
  s := ReplaceString(s,fs,ts);
end intrinsic;

intrinsic ReplaceString(~s::MonStgElt, fs::[MonStgElt], ts::[MonStgElt])
  {In the string s, replace all occurences of strings in fs with strings in ts.}
  for i:=1 to #fs do
    ReplaceString(~s,fs[i],ts[i]);
  end for;
end intrinsic;

// More code from Tim
intrinsic PrintRelExtElement(r::Any) -> Any
  {For storing character values as lists}
  K:=Parent(r);
  QQ:=Rationals();
  return K eq BaseRing(K)
    select QQ!r
    else   [PrintRelExtElement(u): u in Eltseq(r)];
end intrinsic;

intrinsic DelSpaces(s::MonStgElt) ->MonStgElt
  {Delete spaces from a string s}
  return &cat([x: x in Eltseq(Sprint(s)) | (x ne " ") and (x ne "\n")]);
end intrinsic;

intrinsic PolredabsCache(f::Any, g::Any)
  { Write to a cache file of polredabs results }
  ff:= DelSpaces(Sprint(f));
  gg:= DelSpaces(Sprint(g));
  write(Sprintf("Polredabs/%o", Degree(f)), Sprintf("%o %o", ff, gg) : rewrite:=false);
end intrinsic;

intrinsic LoadPolredabsCache(n) -> Any
  {Load polredabs values of degree n from a file}
  prac:= AssociativeArray();
  try
    prastr:=Split(Read(Sprintf("Polredabs/%o", n)));
  catch e;
    return prac;
  end try;
  R<x>:=PolynomialRing(Rationals());
  for pdat in prastr do
    pralist:=Split(pdat, " ");
    prac[eval(pralist[1])] := eval(pralist[2]);
  end for;
  return prac;
end intrinsic;

intrinsic Polredabs(f::Any) -> Any
  {Have gp compute polredabs}
  // If degree is too large, we just return f, since we won't be adding this field to the LMFDB
  if Degree(f) gt 48 then
    return f;
  end if;
  vprint User1: "Calling polredabs on polynomial of degree", Degree(f);
  R<x>:=PolynomialRing(Rationals());
  out := Sprintf("/tmp/polredabs%o.out", Random(10^30));
  txt := Sprintf("/tmp/polredabs%o.txt", Random(10^30));
  //f:=R!f * Denominator(VectorContent(Coefficients(f)));
  // Avoid hardwiring gp path
  write(txt,Sprintf("polredabs(%o)",f): rewrite:=true);
  System("which sage>"*out);
  gppath:= DelSpaces(Read(out));
  System("rm "* out);
  System(gppath*" -gp -f -q --default parisizemax=1G <"*txt*">"*out);
  //try
  f:=eval DelSpaces(Read(out));
  //catch e;
  //end try;
  System("rm "* out);
  System("rm "* txt);
  return f;
end intrinsic;

intrinsic GAP_ID(G::Grp) -> Tup
{Use GAP to identify the group}
    vprint User1: "Using GAP to identify group of order", #G;
    out := Sprintf("/tmp/gap%o.out", Random(10^30));
    txt := Sprintf("/tmp/gap%o.txt", Random(10^30));
    if Category(G) eq GrpPC then
        desc := Sprintf("PcGroupCode(%o,%o)", SmallGroupEncoding(G), #G);
    elif Category(G) eq GrpPerm then
        desc := Sprintf("Group(%o)", Join([DelSpaces(Sprintf("%o", g)) : g in Generators(G)], ","));
    else
        error Sprintf("Category %o not yet supported", Category(G));
    end if;
    write(txt,Sprintf("IdGroup(%o);quit;", desc));
    System("which sage>"*out);
    sagepath := DelSpaces(Read(out));
    System("rm "*out);
    System(sagepath*" --gap -b -q <"*txt*">"*out);
    pair := eval DelSpaces(Read(out));
    System("rm "*out);
    System("rm "*txt);
    assert #pair eq 2;
    assert pair[1] eq #G;
    return <#G, pair[2]>;
end intrinsic;

intrinsic write(filename::MonStgElt,str::MonStgElt: console:=false, rewrite:=false)
  {Write str to file filename as a line
   rewrite:= true means we overwrite the file, default is to append to it
   console:= true means we echo the string as well.
   If the filename is the empty string, don't write it.}
  if console then str; end if;
  if filename ne "" then
    F:=Open(filename,rewrite select "w" else "a");
    WriteBytes(F,[StringToCode(c): c in Eltseq(Sprint(str)*"\n")]);
    Flush(F);
  end if;
end intrinsic;

intrinsic Classify (S::[], E::UserProgram) -> SeqEnum[SeqEnum]
{ Given a list of objects S and an equivalence relation E on them returns a list of equivalence classes (each of which is a list). }
    if #S eq 0 then return []; end if;
    if #S eq 1 then return [S]; end if;
    if #S eq 2 then return E(S[1],S[2]) select [S] else [[S[1]],[S[2]]]; end if;
    T:=[[S[1]]];
    for i:=2 to #S do
        s:=S[i]; sts:=true;
        for j:=#T to 1 by -1 do // check most recently added classes first in case adjacent objects in S are more likely to be equivalent (often true)
            if E(s,T[j][1]) then T[j] cat:= [s]; sts:=false; break; end if;
        end for;
        if sts then T:=Append(T,[s]); end if;
    end for;
    return T;
end intrinsic;

intrinsic IndexFibers(S::SeqEnum, f::UserProgram) -> Assoc
    {Given a list of objects S and a function f on S creates an associative array satisfying A[f(s)] = [t:t in S|f(t) eq f(s)]}
    A:=AssociativeArray();
    for x in S do
        y := f(x);
        if IsDefined(A, y) then
            Append(~A[y], x);
        else
            A[y] := [x];
        end if;
    end for;
    return A;
end intrinsic;

intrinsic AssociativeArrayToMap(xs :: Assoc, codomain) -> Map
  {The map from Keys(xs) to codomain implied by xs.}
  return map<Keys(xs) -> codomain | k :-> xs[k]>;
end intrinsic;

/* convert number to cremona-type number */
intrinsic CremonaCode(num::RngIntElt) -> MonStgElt
{}
    q,r:=Quotrem(num,26);
    strg:=CodeToString(r+97);  /* a = 97  z=122 */

    x:=q;

    while x ne 0 do
        q,r := Quotrem(x,26);
        strg cat:= CodeToString(r+97);
        x:=q;
    end while;
    return Reverse(strg);
end intrinsic;

intrinsic strip(X::MonStgElt) -> MonStgElt
{ Strips spaces and carraige returns from string; much faster than StripWhiteSpace. }
    return Join(Split(Join(Split(X," "),""),"\n"),"");
end intrinsic;

intrinsic sprint(X::.) -> MonStgElt
{ Sprints object X with spaces and carraige returns stripped. }
    if Type(X) eq Assoc then return Join(Sort([ $$(k) cat "=" cat $$(X[k]) : k in Keys(X)]),":"); end if;
    return strip(Sprintf("%o",X));
end intrinsic;

intrinsic find_process_id(N::RngIntElt, i::RngIntElt : Nlower:=1) -> RngIntElt
{The overall index of a given group N.i among groups of all orders}
    return &+[NumberOfSmallGroups(m) : m in [Nlower..N-1]] + i;
end intrinsic;


// We encode groups using strings that allow for their reconstruction
// Moved from IO.m so that it could be used while just attaching hashspec

function is_iterative_description(desc)
    for i in [1..#desc - 1] do
        if desc[i] eq "-" and not desc[i+1] in "123456789" then
            return true;
        end if;
    end for;
    return false;
end function;

sporadic_codes := AssociativeArray();
sporadic_codes["J1"] := "7,11Mat010000000100000001000000010000000100000001100000082AA8A89113133AA8A882A8A882A8A882AA13391133391131";
sporadic_codes["J2"] := "6,q4Mat111100000000101100000000101011110000011010110000001111110001111011001100011011101111011001101001010111111000000000001010111011110111111011011101";
sporadic_codes["HS"] := "Simp138";
sporadic_codes["J3"] := "18,q9Mat201000000000000000000000000000000000000010000000000000000000000000000000202010000000000000000000000000000000000000001000000000000000000000000000000000000000100000000000000000000000000000000000001000000000000000000000000000100000000000000000000000000000000000000000000000001000000000000000000000000000000000000010000000000000000000000000000000000000100000000000000000000010000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000001000112120022120100222211111101000000200202102102201012202121021020010102200000000000000000010000000000000000000000000000000000000100000000000000000101102022111100102022110220000211210001000000000000000000000000000000000100000000000000000000000000000000000000000100000000000000000000000000000000010000000000000000000000000000000000000000010000000000000000000000000000000001000000000000000000000000000000000000000000010000000000000000000000000000000000000100000000000000000000000000000100000000000000000000000000000000000001000000000000000000000000000000000000000000000001000000000000000000000000000000000000010000000122120102010010202011100102200000000000000000000000000001000000000000000000000000000000000000010000000000000000000000000000000000000000000000010201022112010002000102002001001011002000000000000000000000000000000100000";
sporadic_codes["McL"] := "Simp269";
sporadic_codes["He"] := "51,2Mat001000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000001000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000100100111011011000101011010000011001011111010000001000000000000000000000000000000000000000000000000000010001111111001010111010111010111011110010001001001100101001011110000110001011000101011001100111101100110100110101001000000001100101101101100000011101110110001010110011101011000110111100101110111111001000000010101110111000000010001111011011001011100010001000001101000001111011111111110101111101010010111110100000000000000000000000000000000000000000000000000001001100110111011100101000000111101001010010001001000010011111010010011111111111110110111011100011001100101001110111001100000011010011101101000000100011001111101101100000010101100011111010111011010101101011100000110110110010000100010000011010110010011011111010100000110011111010010100111111100011111110000101100101010010011111100110000101110101111111011100101011111110000100010110110100010001111010100010010110110110011000010101000001110000000011000100100000000100001011100001001111011011001100000110101111110011010000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000100000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000001000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000010000000000000000000000000100000000000000000000000000000010101111001000111111001100010000010000111001000000000000000000000000000010000000000000000000000000000110111010010011110111001001010100010000100000010000000000000000000000000000000000000001000000000000000000000000000000000000000100000000000000000000000000000101101110101101001110011000110100010100000010000010000110011111010000011010000001110101111001000000000000000000000000000000001000000000000000000000000010000010101100100101000010101101010100100000010000000000000000000000000000000100000000000000000000000011110111000110010111101010111100110000011000101110110101101100111001111110110010010100100000010000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000100000000000000000000100000110011111000000000010001001010100111000001000101011011110100101001100101100100110100111101101010000111110110011100101110100100110100100001000010010001011101111000000110100101011101100000001101101111";
sporadic_codes["Ru"] := "28,2Mat11000001100010000000100010100001100001000011100110001010101100000011100110111111010111100011011110000001000010101111011010101000001011001100110010011000111111100110010010000100000000111111100000111101010010000111110010101111000101101110010110100111111011111011110001011111011000000100000100101111100001010100011001001010001010011110101100110110010001110111001010101100110111111100110000111010110011001010101111011000000101100010101010111101011000100111010100111110011111000110001010110110010100011010010000001001001100011010010010001101100011000101001101111000101101000101001000111010111110000100111011110010011010100110010111010001101101100001001000110100111100001110000110011101111010011111010110100000101011101110001111001111100001000101010101000000111000011011101011110110111111101100110111110001010100100101010001101011011110101011000000010011110101001000110011000001010100101110111100110110100011000010000101111001001000000100100101001110011100011100011110000010100001100010100001001000001010010101100110000101111111000010110000110011001100110001011010010110000101011110001100110110100011100011011111101000100011111110110011111011000000011110100100111110001010001010010110011000101000100110000010111101101101110001100100101000011101111001101001100100010001010010100011000111000001100000001100000000101110100011000111101101011010111101011110000100111011110011101100001000111100110000000101000011100011110111110101011001001101100100010001110100001010011010111010110000111001111110010110111000011001011001000000110010100011010010101100010011011111110110000001101110";
sporadic_codes["Co3"] := "22,2Mat10001001101001110110110010011000111110101011000100011100010110001000011111101110101011011010000011011011010100110000001000111111100110010011011011010010001110000000001000010001101000000001111001001110000010100011011110000110110111101010100001100111000011100101001101111100100101100000001010001010011100001000011010010010101101101101011101110101011001011101100110001000100110100010010011001000101110001000101000011010110100011010011011011100110010100010010111111001011001001000011000110101010100000001000001110110001000001010011011101000001100101001001100011100010110011000111010110111011111111011110110110001110010001100001110001111101101111010000111001010011011000001001111111011011011100011110000000100100000101001000011010010111100001100111101101111100011010010100100011111101111101101001110100110001110011100000001110010000011101000110010010101111010000100011101110000101110001111100110110100101001101110010001101101100100001000001111101001101110010100011100011100";
sporadic_codes["Co2"] := "22,2Mat01000000000000000000001000000000000000000000000100000000000000000000100000000000000000000000001000000000000000000000001000000000000000001000000000000000000000111110000000000000000001000000000000000011000100110000000000000000000000100000000000000010100001000000000000001110100010000000000000000000000000100000110010100000001000000000000000000000000001000000000000000100000000000010100000000101010000001010000001011011000000000000000001000000001101001000010010001011000100100001001000010010000000000000000000011000000000000000000000001000000000000000000000010000000000000000000000010000000000000000000000010000000000000000000000100000000000101010010000000000000000000000000100000000000000000000001000000000000000000000010000000000000000000000100000000000000000000001000000000000000000000001000000000000000000000010000001000000000000000000000000000000000000001000010110011011010100000001010011011011001000000111111100110101111000000000000000000000011111110111111111110110";
sporadic_codes["Co1"] := "24,2Mat111101000111000010000110110110010011011100000111000101100001000000101101111110010110010010000110110000100010010111001110100100101010001001100011001011001101011010011111000110011001110111010111000011100110110111110110001011110010011110010100001000000101010001101001110110000101001111001000001000110000100001000110101011011000110001010100010110011111100111011101110111100001001101000010101101100110011110000011111100000110011101001010110100111010000010000111101100101101010000111111010010101010000001000100011100100100001110010100100110101100010110101000101001000010101000100011011001001011001001111011010010011110110010100001010111101000000010101111110001101110100101110100010101101100110001110110101111010000001000001101101110001011101001111010001010000011101010000001010100111100000101110101110000000100010111111001101001011001101001010110101001111110110010101011110001100111010000101000100101111011101111010111100101110110001000101000110111110100000111010011000111100010000111011001100010011110100111101100010010101110011101010111000010110000001010010001001101111000000100101001110111111100000110100110010101110011101101011101010001000000110111111101";

function HexToInteger(s)
    return StringToInteger(s, 16);
end function;
function HexToSignedInteger(s)
    if HexToInteger(s[1]) gt 7 then
        return HexToInteger(s) - 16^#s;
    else
        return HexToInteger(s);
    end if;
end function;

function IntegerToHex(n, b)
    n := Integers()!n;
    if n lt 0 then
        n +:= 16^b;
    end if;
    assert n lt 16^b;
    s := Sprintf("%h", n);
    s := s[3..#s]; // strip leading 0x
    return "0"^(b-#s) * s;
end function;

intrinsic StringToGroup(s::MonStgElt) -> Grp
{}
    // We want to support iterated constructions separated by hyphens, but also need to handle negative signs
    if is_iterative_description(s) then
        path := Split(s, "-");
        G := StringToGroup(path[1]);
        for zig in path[2..#path] do
            if zig[1] eq "A" then
                // Since computing the automorphism group can be expensive, we allow storage of the actual automorphisms
                if #zig eq 1 then
                    G := AutomorphismGroup(G);
                else
                    gens, auts := Explode(Split(zig[2..#zig], ";"));
                    gens := [StringToInteger(c) : c in Split(gens, ",")];
                    auts := [StringToInteger(c) : c in Split(auts, ",")];
                    auts := [auts[i..i+#gens-1] : i in [1..#auts by #gens]];
                    if Type(G) eq GrpPerm then
                        n := Degree(G);
                        gens := [DecodePerm(gen, n) : gen in gens];
                        auts := [[DecodePerm(x, n) : x in imgs] : imgs in auts];
                    elif Type(G) eq GrpMat then
                        d := Dimension(G);
                        R := CoefficientRing(G);
                        if Type(R) eq FldFin and Degree(R) gt 1 then
                            k := Degree(R);
                            gens := [R!gens[i..i+k-1] : i in [1..#gens by k]];
                            auts := [[R!imgs[i..i+k-1] : i in [1..#imgs by k]] : imgs in auts];
                        end if;
                        gens := [G!gens[i..i+d^2-1] : i in [1..#gens by d^2]];
                        auts := [[G!imgs[i..i+d^2-1] : i in [1..#imgs by d^2]] : imgs in auts];
                    elif Type(G) eq GrpPC then
                        n := NumberOfPCGenerators(G);
                        gens := [G!gens[i..i+n-1] : i in [1..#gens by n]];
                        auts := [[G!imgs[i..i+n-1] : i in [1..#imgs by n]] : imgs in auts];
                    else
                        error "Unsupported group type", Type(G);
                    end if;
                    G := AutomorphismGroup(G, gens, auts);
                end if;
            elif zig eq "Z" then
                G := Center(G);
            elif zig eq "D" then
                G := DerivedSubgroup(G);
            elif zig eq "P" then
                G := FrattiniSubgroup(G);
            elif zig eq "F" then
                G := FittingSubgroup(G);
            elif zig eq "R" then
                G := Radical(G);
            elif zig eq "S" then
                G := Socle(G);
            else
                // may want to add quotients here
                error "Unrecognized group construction term", zig;
            end if;
        end for;
        return G;
    elif "Simp" in s then
        N := StringToInteger(s[5..#s]);
        return SimpleGroup(N);
    elif "Perf" in s then
        N := StringToInteger(s[5..#s]);
        return PermutationGroup(PerfectGroupDatabase(), N);
    elif "Chev" in s then
        series, n, q := Explode(Split(s[5..#s], ","));
        n := StringToInteger(n);
        q := StringToInteger(q);
        return ChevalleyGroup(series, n, q);
    elif "Mat" in s then
        dR, L := Explode(Split(s, "Mat"));
        d, Rcode := Explode(Split(dR, ","));
        d := StringToInteger(d);
        b := 1;
        if Rcode eq "0" then
            R := Integers();
            b := #L div d^2;
        elif Rcode[1] eq "q" then
            q := StringToInteger(Rcode[2..#Rcode]);
            _, p := IsPrimePower(q);
            b := 1 + Ilog(16, p-1);
            R := GF(q);
        else
            N := StringToInteger(Rcode);
            b := 1 + Ilog(16, N-1);
            R := Integers(N);
        end if;
        if "," in L then
            L := [StringToInteger(c) : c in Split(L, ",")];
        else
            assert IsDivisibleBy(#L, d^2);
            if Rcode eq "0" then
                L := [HexToSignedInteger(L[i..i+b-1]) : i in [1..#L by b]];
            else
                L := [HexToInteger(L[i..i+b-1]) : i in [1..#L by b]];
            end if;
        end if;
        assert IsDivisibleBy(#L, d^2);
        if Rcode[1] eq "q" then
            k := Degree(R);
            L := [R!L[i..i+k-1] : i in [1..#L by k]];
        end if;
        L := [L[i..i+d^2-1] : i in [1..#L by d^2]];
        return MatrixGroup<d, R| L >;
    elif "Perm" in s then
        n, L := Explode(Split(s, "Perm"));
        n := StringToInteger(n);
        L := [DecodePerm(StringToInteger(c), n) : c in Split(L, ",")];
        return PermutationGroup<n | L>;
    elif "PC" in s then
        N, code := Explode([StringToInteger(c) : c in Split(s, "PC")]);
        return SmallGroupDecoding(code, N);
    elif s[#s] eq ")" and #Split(s, "(") eq 2 then
        // We just use the Magma command to store classical matrix groups, since we can then recover
        // the homomorphism in the projective case
        // We don't just eval in case this code is ever used with untrusted input
        cmd, data := Explode(Split(s[1..#s-1], "("));
        n, q := Explode([StringToInteger(c) : c in Split(data, ",")]);
        assert cmd in ["GL", "SL", "Sp", "SO", "SOPlus", "SOMinus", "SU", "GO", "GOPlus", "GOMinus", "GU", "CSp", "CSO", "CSOPlus", "CSOMinus", "CU", "Omega", "OmegaPlus", "OmegaMinus", "Spin", "SpinPlus", "SpinMinus", "PGL", "PSL", "PSp", "PSO", "PSOPlus", "PSOMinus", "PSU", "PGO", "PGOPlus", "PGOMinus", "PGU", "POmega", "POmegaPlus", "POmegaMinus", "PGammaL", "PSigmaL", "PSigmaSp", "PGammaU", "AGL", "ASL", "AGammaL", "ASigmaL", "ASigmaSp"];
        cmd := eval cmd;
        return cmd(n, q);
    elif s in ["J1", "J2", "HS", "J3", "McL", "He", "Ru", "Co3", "Co2", "Co1"] then
        return StringToGroup(sporadic_codes[s]);
    elif "." in s then
        N, i := Explode([StringToInteger(c) : c in Split(s, ".")]);
        return SmallGroup(N, i);
    elif "T" in s then
        n, t := Explode([StringToInteger(c) : c in Split(s, "T")]);
        return TransitiveGroup(n, t);
    else
        error "Unrecognized format", s;
    end if;
end intrinsic;

intrinsic GroupToString(G::Grp) -> MonStgElt
{}
    // This produces a string from which the group can be reconstructed, up to isomorphism
    // Note that it does not guarantee the same presentation or choice of generators
    N := #G;
    if Type(G) eq GrpAuto then
        A := G;
        G := Group(G);
        Gdesc := GroupToString(G);
        if Type(G) eq GrpPC then
            gens := PCGenerators(G);
        else
            gens := Generators(G);
        end if;
        auts := &cat[[phi(g) : g in gens] : phi in Generators(A)];
        if Type(G) eq GrpPC then
            gens := &cat[ElementToSequence(g) : g in gens];
            auts := &cat[ElementToSequence(im) : im in auts];
        elif Type(G) eq GrpPerm then
            gens := [EncodePerm(g) : g in gens];
            auts := [EncodePerm(im) : im in auts];
        elif Type(G) eq GrpMat then
            gens := &cat[Eltseq(g) : g in gens];
            auts := &cat[Eltseq(im) : im in auts];
            R := CoefficientRing(G);
            if Type(R) eq FldFin and Degree(R) gt 1 then
                gens := &cat[Eltseq(a) : a in gens];
                auts := &cat[Eltseq(a) : a in auts];
            end if;
        else
            error "Unsupported group type", Type(G);
        end if;
        return Sprintf("%o-A%o;%o", Gdesc, Join([Sprint(g) : g in gens], ","), Join([Sprint(a) : a in auts], ","));
    elif CanIdentifyGroup(N) then
        return Sprintf("%o.%o", N, IdentifyGroup(G)[2]);
    elif Type(G) eq GrpPerm then
        if IsTransitive(G) and Degree(G) lt 48 then
            t,n := TransitiveGroupIdentification(G);
            return Sprintf("%oT%o", n, t);
        else
            return Sprintf("%oPerm%o", Degree(G), Join([Sprint(EncodePerm(g)) : g in Generators(G)], ","));
        end if;
    elif Type(G) eq GrpMat then
        R := CoefficientRing(G);
        L := &cat[Eltseq(g) : g in Generators(G)];
        if Type(R) eq RngInt then
            R := "0";
            b := Max([1 + Ilog(16, Integers()!(2*Abs(c+1/2))) : c in L]); // only need 1 digit for -8, but 2 for 8; deals with c=0 correctly
            L := [IntegerToHex(c, b) : c in L];
        elif Type(R) eq RngIntRes then
            b := 1 + Ilog(16, Modulus(R) - 1);
            L := [IntegerToHex(c, b) : c in L];
            R := Sprint(Modulus(R));
        elif Type(R) eq FldFin then
            p := Characteristic(R);
            b := 1 + Ilog(16, p-1);
            k := Degree(R);
            if k eq 1 then
                R := Sprint(p);
            elif DefiningPolynomial(R) ne ConwayPolynomial(p, k) then
                error "Matrix rings over finite fields not defined by a Conway polynomial are unsupported";
            else
                L := &cat[Eltseq(a) : a in L];
                R := Sprintf("q%o", #R);
            end if;
            L := [IntegerToHex(c, b) : c in L];
        else
            error "Unsupported coefficient ring", R;
        end if;
        return Sprintf("%o,%oMat%o", Dimension(G), R, &*[Sprint(c) : c in L]);
    else
        if Type(G) eq GrpAb then
            G := PCGroup(G);
        end if;
        if Type(G) eq GrpPC then
            code, N := SmallGroupEncoding(G);
            return Sprintf("%oPC%o", N, code);
        end if;
        error Sprintf("Unsupported group type %o of order %o", Type(G), N);
    end if;
end intrinsic;

intrinsic ConjClassTupAction(A::GrpAuto : n:=1, dbound:=5000, try_union:=false) -> Grp
{G, a permutation group; reps, a list of elements of G in DISTINCT conjugacy classes}
    dmin := 1;
    dprod := 1;
    while dprod lt #A do
        dmin +:= 1;
        dprod *:= dmin;
    end while;
    G := Group(A);
    C := ConjugacyClasses(G);
    S := Sym(#C);
    f := ClassMap(G);
    // Have to figure out which classes are joined by automorphisms
    Cact := sub<S|[[f(a(C[i][3])) : i in [1..#C]] : a in Generators(A)]>;
    O := Orbits(Cact);
    O := [o : o in O | o[1] eq 1 or &+[C[i][2] : i in o] gt 1];
    Osizes := [&+[C[i][2] : i in o] : o in O];
    ParallelSort(~Osizes, ~O);
    tups := [tup : tup in CartesianProduct([[1..#O] : _ in [1..n]]) | &and[tup[i] eq 1 or tup[i] lt tup[i+1] : i in [1..#tup-1]] and &*[Osizes[i] : i in tup] le dbound and &*[Osizes[i] : i in tup] ge dmin];
    tupsizes := [&*[Osizes[i] : i in tup] : tup in tups];
    ParallelSort(~tupsizes, ~tups);
    //L := &join[{@ x : x in r^G @} : r in reps];
    if try_union then
        F := [[&join[C[j][3]^G : j in O[i]] : i in tup]: tup in tups];
        L := &cat[[<facs[i][c[i]] : i in [1..#c]> : c in CartesianProduct([[1..#facs[i]] : i in [1..#facs]])] : facs in F];
        S := Sym(#L);
        print "Start", #L;
        GG := [];
        indexer := AssociativeArray();
        for i in [1..#L] do
            indexer[L[i]] := i;
        end for;
        GG := [[ indexer[<a(g) : g in gtup>] : gtup in L ] : a in Generators(A)];
        print "End";
        H := sub<S|GG>;
        if #H eq #A then
            print "success";
            return H;
        end if;
        print "fail";
        return G;
    end if;
    for tup in tups do
        print [O[i] : i in tup];
        facs := [&join[C[j][3]^G : j in O[i]] : i in tup];
        L := [<facs[i][c[i]] : i in [1..#c]> : c in CartesianProduct([[1..#facs[i]] : i in [1..#facs]])];
        S := Sym(#L);
        GG := [[ Index(L, <a(g) : g in gtup>): gtup in L ] : a in Generators(A)];
        H := sub<S|GG>;
        if #H eq #A then
            print "success";
            return H;
        end if;
    end for;
    print "fail";
    return G;
end intrinsic;

intrinsic AutPermRep(A::GrpAuto : dbound:=1000, verbose:=false) -> GrpPerm, MonStgElt
{Gives a permutation representation of A, either a transitive one of degree up to 47 or one of smallest degree}
    t0 := Cputime();
    G := Group(A);
    if Type(G) ne GrpPerm then
        error "AutoPermRep only available for permutation groups";
    end if;
    Sn := Sym(Degree(G));
    N := Normalizer(Sn, G);
    T := Centralizer(Sn, G);
    //if #N eq #T * #A and (#T eq 1 or #A lt 1000000 or IsSolvable(A)) then
    if false then
        // have full automorphism group as N/T
        if verbose then
            print "Normalizer gives full automorphism group";
        end if;
        NtoA := hom<N -> A | [n -> A!hom<G -> G| [g -> n^-1*g*n : g in Generators(G)]> : n in Generators(N)]>;
        AtoN := NtoA^-1;
        if #T eq 1 then
            if IsTransitive(N) and Degree(G) lt 48 then
                M1 := Sprintf("%oPerm%o", Degree(N), Join([Sprint(EncodePerm(AtoN(a))) : a in Generators(N)], ","));
                return N, M1;
            else
                R := N;
                AtoR := AtoN;
            end if;
        elif #A lt 1000000 then
            R, NtoR := quo<N | T>;
            AtoR := AtoN * NtoR;
        else
            NP, NtoNP := PCGroup(N);
            R, NPtoR := quo<NP | NtoNP(T)>;
            AtoR := AtoN * NtoNP * NPtoR;
        end if;
        if verbose then
            printf "Quotient constructed in %o seconds", Cputime() - t0;
        end if;
    else
        Z := Center(G);
        nOut := (#A * #Z) div #G;
        rho := PermutationRepresentation(A);
        P := Codomain(rho);
        dlimit := Ceiling(Degree(P) / nOut);
        if dbound gt dlimit then
            dbound := dlimit;
        end if;
        if verbose then
            printf "G of order %o, with %o inner automorphisms and %o outer classes\n", #G, #G div #Z, nOut;
            printf "Initial permutation representation of degree %o found in %o seconds\n", Degree(P), Cputime() - t0;
            t0 := Cputime();
        end if;
        Phom := hom<G -> P | [g -> rho(A!hom<G -> G| [e -> g^-1*e*g : e in Generators(G)]>) : g in Generators(G)]>;
        dlow := 1;
        while true do
            S := [X : X in LowIndexSubgroups(G, <dlow, dbound>) | IsDivisibleBy(#X, #Z) and Z subset X and Core(G, X) eq Z];
            if verbose then
                printf "Found %o subgroups of index %o-%o with central core in %o seconds\n", #S, dlow, dbound, Cputime() - t0;
                t0 := Cputime();
            end if;
            Sind := [Index(G, X) : X in S];
            ParallelSort(~Sind, ~S);
            broken := false;
            for H in S do
                K := Phom(H);
                if #Core(P, K) eq 1 then
                    if verbose then
                        printf "Found a core-free subgroup with index %o in %o seconds\n", Index(P, K), Cputime() - t0;
                        t0 := Cputime();
                    end if;
                    phi := CosetAction(P, K);
                    R := Image(phi);
                    AtoR := rho * phi;
                    broken := true;
                    break;
                end if;
            end for;
            if broken then break; end if;
            if dbound eq dlimit then
                R := P;
                AtoR := rho;
                break;
            end if;
            dlow := dbound + 1;
            dbound := Min(2*dbound, dlimit);
        end while;
    end if;
    psi := MinimalDegreePermutationRepresentation(R);
    M := Image(psi);
    if verbose then
        printf "Minimized representation in %o seconds; final degree %o\n", Cputime() - t0, Degree(M);
        t0 := Cputime();
    end if;
    F := FewGenerators(M);
    if verbose then
        printf "Minimized number of generators in %o seconds; %o generators\n", Cputime() - t0, #F;
        t0 := Cputime();
    end if;
    M0 := sub<Sym(Degree(M))|F>;
    M1 := Sprintf("%oPerm%o", Degree(M), Join([Sprint(EncodePerm(psi(AtoR(a)))) : a in Generators(A)], ","));
    return M0, M1;
end intrinsic;

intrinsic ProjMatHom(G, P, L) -> Map
{Returns the homomorphism from the matrix group G to its projectivization P, given the set of lines L on which P acts (returned by the constructor of P)}
    K := CoefficientRing(G);
    images := [];
    lookup := AssociativeArray();
    for i in [1..#L] do
        x := L[i];
        for c in K do
            if c ne 0 then
                lookup[c*x] := i;
            end if;
        end for;
    end for;
    return hom<G -> P | [<g, P![lookup[x^g] : x in L]> : g in Generators(G)]>;
end intrinsic;
