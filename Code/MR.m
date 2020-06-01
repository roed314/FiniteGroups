intrinsic SylowSubgroups(G::LMFDBGrp) -> Any
  {Compute SylowSubgroups of the group G}
  GG := G`MagmaGrp;
  P := [];
  SS := AssociativeArray();
  F := FactoredOrder(GG);
  for uu in F do 
    p := uu[1];
    SS[p] := SylowSubgroup(GG, p);
  end for;
  G`SylowSubgroups := SS;
end intrinsic;

intrinsic IsZGroup(G::LMFDBGrp) -> Any
  {Check whether all the Syllowsubgroups are cylic}
  GG := G`MagmaGrp;
  for S in SylowSubgroups(GG) do
    if not IsCyclic(S) then
      return false;
    end if;
  end for;
  return true;
end intrinsic;

intrinsic IsAGroup(G::LMFDBGrp) -> Any
  {Check whether all the Syllowsubgroups are abelian}
  GG := G`MagmaGrp;
  for S in SylowSubgroups(GG) do
    if not IsAbelian(S) then
      return false;
    end if;
  end for;
  return true;
end intrinsic;




