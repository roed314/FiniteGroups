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

intrinsic allrankslist(n::Any)->Any
  {}
  l:=[];
  for j:=1 to n do
    for k:=1 to NumberOfSmallGroups(j) do
      [j,k];
      g:=MakeSmallGroup(j,k);
      Append(~l, <j,k,Get(g,"rank")>);
    end for;
  end for;
  return l;
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
