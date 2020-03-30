intrinsic IsSupersolvable(G::LMFDBGrp) -> BoolElt
  {Check if LMFDBGrp is supersolvable}
  GG := G`MagmaGrp;
  if not IsSolvable(GG) then
    return false
  end if;
  if IsNilpotent(GG) then
    return true
  end if;
  C = [Order(H) : H in ChiefSeries(GG)]
  for i := 1 to #C-1 do
    if not IsPrime(C[i] div C[i+1]) then
      return false
    end if;
  end for;
  return true
end intrinsic;

intrinsic LazyIsMetacyclic(G::LMFDBGrp) -> BoolElt
  {}
  // take Smith invariants (Invariant Factors), check if length <= 2
end intrinsic;
