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
