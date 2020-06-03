

intrinsic AutOrder(G::LMFDBGrp) -> RingIntElt
   {returns order of automorphism group}
   aut:=Get(G, "AutomorphismGroup");
   return #aut;
end intrinsic;

intrinsic FactorsOfAutOrder(G::LMFDBGrp) -> SeqEnum
   {returns primes in factorization of automorphism group}
   /* This assumes AutOrder is computed */
   autOrd:=Get(G,"AutOrder");
   return PrimeFactors(autOrd);
end intrinsic;

intrinsic OuterOrder(G::LMFDBGrp) -> RingIntElt
   {returns order of OuterAutomorphisms }
    aut:=Get(G, "AutomorphismGroup");     
   return OuterOrder(aut);
end intrinsic;

intrinsic OuterGroup(G::LMFDBGrp) -> Any
   {returns OuterAutomorphism Group)
   aut:=Get(G, "AutomorphismGroup");
   return OuterFPGroup(aut);
end intrinsic;




intrinsic CenterLabel(G::LMFDBGrp) -> Any
   {currently returns Center NOT Label}
   return Center(G`MagmaGrp);
end intrinsic;


intrinsic CentralQuotient(G::LMFDBGrp) -> Any
   {currently returns CentralQuotient NOT Label}
   return quo<G`MagmaGrp | Center(G`MagmaGrp)>;

end intrinsic;




intrinsic CommutatorLabel(G::LMFDBGrp) --> Any
   {currently returns Commutator Subgroup NOT Label}
   return CommutatorSubgroup(G`MagmaGrp);  
end intrinsic;



intrinsic FrattiniLabel(G::LMFDBGrp) -> Any
   {currently returns Frattini Subgroup NOT Label}
   return FrattiniSubgroup(G`MagmaGrp);  
end intrinsic;


intrinsic FrattiniQuotient(G::LMFDBGrp) -> Any
   {currently returns Frattini Quotient NOT Label}
   return quo<G`MagmaGrp | FrattiniSubgroup(G`MagmaGrp)>;
end intrinsic;


intrinsic FittingSubgroup(G::LMFDBGrp) -> Any
   {currently returns Fitting Subgroup NOT Label}
   return FittingSubgroup(G`MagmaGrp);  
end intrinsic;

