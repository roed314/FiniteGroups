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

intrinsic StringToGroup(s::MonStgElt) -> Grp
{}
    if "-" in s then
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
    elif "Mat" in s then
        dR, L := Explode(Split(s, "Mat"));
        L := [StringToInteger(c) : c in Split(L, ",")];
        d, R := Explode(Split(dR, ","));
        d := StringToInteger(d);
        if R eq "0" then
            R := Integers();
        elif R[1] eq "q" then
            q := StringToInteger(R[2..#R]);
            R := GF(q);
            k := Degree(R);
            L := [R!L[i..i+k-1] : i in [1..#L by k]];
        else
            R := Integers(StringToInteger(R));
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
        elif Type(R) eq RngIntRes then
            R := Sprint(Modulus(R));
        elif Type(R) eq FldFin then
            p := Characteristic(R);
            k := Degree(R);
            if k eq 1 then
                R := Sprint(p);
            elif DefiningPolynomial(R) ne ConwayPolynomial(p, k) then
                error "Matrix rings over finite fields not defined by a Conway polynomial are unsupported";
            else
                L := &cat[Eltseq(a) : a in L];
                R := Sprintf("q%o", #R);
            end if;
        else
            error "Unsupported coefficient ring", R;
        end if;
        return Sprintf("%o,%oMat%o", Dimension(G), R, Join([Sprint(c) : c in L], ","));
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
