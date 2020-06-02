intrinsic IsQuasiSimple(G::LMFDBGrp) -> Any
  {}
  GG := G`MagmaGrp;
  return (IsPerfect(GG) and IsSimple(quo< GG | Center(GG)>));
end intrinsic;

intrinsic SmithAbelianInvariants(G::LMFDBGrp) -> Any
  {Compute invariant factors of maximal abelian quotient}
  C := Get(G, "Commutator");
  GG := G`MagmaGrp;
  A := quo< GG | C>;
  return InvariantFactors(A);
end intrinsic;

intrinsic PerfectCore(G::LMFDBGrp) -> Any
  {Compute perfect core, the maximal perfect subgroup}
  DD := Get(G, "DerivedSeries");
  for i := 1 to #DD-1 do
    if DD[i] eq DD[i+1] then
      return DD[i];
    end if;
  end for;
  return DD[#DD];
end intrinsic;

intrinsic CompositionLength(G::LMFDBGrp) -> Any
  {Compute length of composition series.}
  return #Get(G,"CompositionFactors"); // Correct if trivial group is labeled G_0
end intrinsic;

intrinsic IsSemidirectProduct(G::LMFDBGrp : direct := false) -> Any
  {Returns true if G is a semidirect product; otherwise returns false.}
  dirbool := false;
  GG := Get(G, "MagmaGrp");
  Ns := NormalSubgroups(GG); // TODO: this should be changed to call on subgroup database when it exists
  if direct then
    Ks := Ns;
  else
    Ks := Subgroups(GG); // this should be changed to call on subgroup database when it exists
  end if;
  for r in Ns do
    N := r`subgroup;
    comps := [el : el in Ks | el`order eq (ordG div Order(N))];
    for K in comps do
      if #(N meet K) eq 1 then
        dirbool := true;
      end if;
    end for;
  end for;
  return dirbool;
end intrinsic;

intrinsic IsDirectProduct(G::LMFDBGrp) -> Any
  {Returns true if G is a direct product; otherwise returns false.}
  return IsSemidirectProduct(G : direct := true);
end intrinsic;
