// cat DATA/arith_equiv.in | parallel --timeout 7200 magma Grp:={1} ArithEquiv.m

n, t := Explode([StringToInteger(c) : c in Split(Grp, "T")]);

matching := function(f, cc)
  for j in cc do
    //if CycleStructure(j) ne CycleStructure(f(j)) then
    if #Fix(j) ne #Fix(f(j)) then
      return false;
    end if;
  end for;
  return true;
end function;

twin := function(g,n,s)
  s1 := Stabilizer(g,1);
  ns1 := Order(s1);
  s := [z : z in s | Order(z) eq ns1];
  good := [z : z in s | Order(Core(g,z)) eq 1];
  if #good eq 1 then return 0; end if;
  // Now have trivial core
  cc := [z[3] : z in Classes(g)];
  cnt := -1;
  for j in good do
    ff, g1:= CosetAction(g, j);
    if matching(ff, cc) then
      cnt := cnt+1;
    end if;
  end for;
  return cnt;
end function;

G := TransitiveGroup(n, t);
S := [H`subgroup : H in Subgroups(G : IndexEqual:=n)];
//S := [H`subgroup : H in S | #Core(G, H`subgroup) eq 1];
//S := [H : H in S | TransitiveGroupIdentification(Image(CosetAction(G, H))) eq t];
cnt := twin(G, n, S);

PrintFile("DATA/arith_equiv/" * Grp, Sprint(cnt));

exit;
