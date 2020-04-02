intrinsic IsSupersolvable(G::LMFDBGrp) -> BoolElt
  {Check if LMFDBGrp is supersolvable}
  GG := G`MagmaGrp;
  if not IsSolvable(GG) then
    return false;
  end if;
  if IsNilpotent(GG) then
    return true;
  end if;
  C := [Order(H) : H in ChiefSeries(GG)];
  for i := 1 to #C-1 do
    if not IsPrime(C[i] div C[i+1]) then
      return false;
    end if;
  end for;
  return true;
end intrinsic;

// for LMFDBGrp
intrinsic EasyIsMetacyclic(G::LMFDBGrp) -> BoolElt
  {Easy checks for possibly being metacyclic}
  if IsSquarefree(G`Order) or G`IsCyclic then
    return true;
  end if;
  if not G`IsSolvable then
    return false;
  end if;
  if G`IsAbelian then
    if #G`SmithAbelianInvariants gt 2 then // take Smith invariants (Invariant Factors), check if length <= 2
      return false;
    end if;
    return true;
  end if;
  return 0;
end intrinsic;

// for groups in Magma
intrinsic EasyIsMetacyclicMagma(G::Grp) -> BoolElt
  {Easy checks for possibly being metacyclic}
  if IsSquarefree(Order(G)) or IsCyclic(G) then
    return true;
  end if;
  if not IsSolvable(G) then
    return false;
  end if;
  if IsAbelian(G) then
    if #InvariantFactors(G) gt 2 then // take Smith invariants (Invariant Factors), check if length <= 2
      return false;
    end if;
    return true;
  end if;
  return 0;
end intrinsic;

intrinsic CyclicSubgroups(G::GrpAb) -> SeqEnum
  {Compute the cyclic subgroups of the abelian group G}
  cycs := [];
  for rec in Subgroups(G) do
    H := rec`subgroup;
    if IsCyclic(H) then // naive...
      Append(~cycs, H);
    end if;
  end for;
  return cycs;
end intrinsic;

intrinsic IsMetacyclic(G::LMFDBGrp) -> BoolElt
  {Check if LMFDBGrp is metacyclic}
  easy := EasyIsMetacyclic(G);
  if not easy cmpeq 0 then
    return easy;
  end if;
  GG := G`MagmaGrp;
  if G`pGroup ne 0 then
    return IsMetacyclicPGroup(GG);
  // IsMetacyclicPGroup doesn't work for abelian groups...
  end if;
  D := DerivedSubgroup(GG);
  if not IsCyclic(D) then
    return false;
  end if;
  Q := quo< GG | D>;
  if not EasyIsMetacyclicMagma(Q) then
    return false;
  end if;
  for H in CyclicSubgroups(GG) do
    if D subset H then
      Q2 := quo<GG | H>;
      if IsCyclic(Q2) then
        return true;
      end if;
    end if;
  end for;
  return false;
end intrinsic;
