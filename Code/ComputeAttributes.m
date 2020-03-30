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
end intrinsic;

intrinsic CyclicSubgroups(G::Grp) -> SeqEnum
  {Compute the cyclic subgroups of G}
  if Type(G) in [GrpMat, GrpPC, GrpPerm] then
    return CyclicSubgroups(G);
  elif Type(G) eq GrpAb then // naive...
    cycs := [];
    for H in Subgroups(G) do
      if IsCyclic(H) then
        Append(~cycs, H);
      end if;
    end for;
  else
    error "Not implemented";
end intrinsic;

intrinsic IsMetacyclic(G::LMFDBGrp) -> BoolElt
  {Check if LMFDBGrp is metacyclic}
  easy_bool := EasyMetacyclic(G);
  if not easy_bool then
    return false;
  end if;
  GG := G`MagmaGrp;
  D := DerivedSubgroup(GG);
  Q := quo< GG | D>;
  if not EasyIsMetaCyclicMagma(Q) then
    return false;
  end if;

end intrinsic;
