
intrinsic FactorsOfOrder(G::LMFDBGrp) -> Any
  {Prime factors of the order of the group}
  gord:=G`Order;
  return [z[1] : z in Factorization(gord)];
end intrinsic;

intrinsic IsMetabelian(G::LMFDBGrp) -> BoolElt
  {Determine if a group is metabelian}
  g:=G`MagmaGrp;
  return IsAbelian(DerivedSubgroup(g));
end intrinsic;

intrinsic IsMonomial(G::LMFDBGrp) -> BoolElt
  {Determine if a group is monomial}
  g:=G`MagmaGrp;
  if not IsSolvable(g) then
    return false;
  elif Get(G, "IsSupersolvable") then
    return true;
  // elif G`IsSolvable and G`IsAgroup then
  //   return true;
  else
    ct:=CharacterTable(g);
    maxd := Degree(ct[#ct]);
    stat:=[false : c in ct];
    hh:=<z`subgroup : z in LowIndexSubgroups(g, maxd)>;
    for h in hh do
        lc := LinearCharacters(h);
        indc := <Induction(z,g) : z in lc>;
        for c1 in indc do
            p := Position(ct, c1);
            if p gt 0 then
                Remove(~ct, p);
            end if;
        end for;
        if #ct eq 0 then
            return true;
        end if;
    end for;
  end if;   
  return false;
end intrinsic;

intrinsic IsRational(G::LMFDBGrp) -> BoolElt
  {Determine if a group is rational, i.e., all characters are rational}
  g:=G`MagmaGrp;
  ct,szs:=RationalCharacterTable(g);
  for s in szs do
    if #s gt 1 then
        return false;
    end if;
  end for;
  return true;
end intrinsic;

intrinsic Elementary(G::LMFDBGrp) -> Any
  {Product of a all primes p such that G is a direct product of a p-group and a cyclic group}
  ans := 1;
  if G`IsSolvable and G`Order gt 1 then
    g:=G`MagmaGrp;
    g:=PCGroup(g);
    sylowsys:= SylowBasis(g);
    comp:=ComplementBasis(g);
    facts:= FactorsOfOrder(G);
    for j:=1 to #sylowsys do
      if IsNormal(g, sylowsys[j]) and IsNormal(g,comp[j]) and IsCyclic(comp[j]) then
        ans := ans*facts[j];
      end if;
    end for;
  end if;
  return ans;
end intrinsic;

intrinsic Hyperelementary(G::LMFDBGrp) -> Any
  {Product of all primes p such that G is an extension of a p-group by a group of order prime to p}
  ans := 1;
  if G`IsSolvable and G`Order gt 1 then
    g:=G`MagmaGrp;
    g:=PCGroup(g);
    comp:=ComplementBasis(g);
    facts:= FactorsOfOrder(G);
    for j:=1 to #comp do
      if IsNormal(g,comp[j]) and IsCyclic(comp[j]) then
        ans := ans*facts[j];
      end if;
    end for;
  end if;
  return ans;
end intrinsic;

intrinsic TransitiveSubgroup(G::LMFDBGrp) -> Any
  {Subgroup producing a minimal degree transitive faithful permutation representation}
  g:=G`MagmaGrp;
  ss:=Subgroups(g);
  tg:=ss[1]`subgroup;
  for j:=#ss to 1 by -1 do
    if Core(g,ss[j]`subgroup) eq tg then
      return ss[j]`subgroup;
    end if;
  end for;
end intrinsic;

intrinsic TransitiveDegree(G::LMFDBGrp) -> Any
  {Smallest transitive degree for a faithful permutation representation}
  ts:=Get(G, "TransitiveSubgroup");
  return Get(G, "Order")/Order(ts);
end intrinsic;

intrinsic SmallRep(G::LMFDBGrp) -> Any
  {Smallest degree of a faithful irreducible representation}
  if not IsCyclic(Get(G,"Center")) then
    return 0;
  end if;
  g:=G`MagmaGrp;
  ct := CharacterTable(g);
  for j:=1 to #ct do
    if IsFaithful(ct[j]) then
      return Degree(ct[j]);
    end if;
  end for;
  return 0; // Should not get here
end intrinsic;

