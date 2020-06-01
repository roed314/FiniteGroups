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
