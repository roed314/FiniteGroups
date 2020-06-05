intrinsic ComputeAllSplittings(G::LMFDBGrp) -> Any
  {Compute all splittings of G as a semidirect product}
  GG := Get(G, "MagmaGrp");
  ordG := Get(G, "Order");
  Ns := NormalSubgroups(GG); // TODO: this should be changed to call on subgroup database when it exists
  Remove(~Ns,#Ns); // remove full group;
  Remove(~Ns,1); // remove trivial group;
  Ks := Subgroups(GG); // this should be changed to call on subgroup database when it exists
  splittings := [];
  for r in Ns do
    N := r`subgroup;
    comps := [el : el in Ks | el`order eq (ordG div Order(N))];
    for s in comps do
      K := s`subgroup;
      if #(N meet K) eq 1 then
        Append(~splittings, [N,K]);
      end if;
    end for;
  end for;
  return splittings;
end intrinsic;

intrinsic schur_multiplier(G::LMFDBGrp) -> Any
  {}
  invs := [];
  ps := factors_of_order(G);
  GG := Get(G, "MagmaGrp");
  for p in ps do
    for el in pMultiplicator(GG,p) do // handbook claims pMultiplicator works for GrpFin, but in Magma only for GrpPerm...
      if el gt 1 then
        Append(~invs, el);
      end if;
    end for;
  end for;
  return invs;
end intrinsic;
