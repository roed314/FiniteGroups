
/* ****************************** */
/* Code for automorphism groups */
/* aut_order	numeric	Order of the automorphism group
DONE IN BASIC: aut_group	text	Label for the automorphism group (might be null if not in database)
outer_order	numeric	Order of the outer automorphism group
outer_group	text	Label for the outer automorphism group (might be null if not in database)
factors_of_aut_order	integer[]	List of primes dividing the order of the automorphism group
*/


/* Assumes AutomorphismGroup is computed */
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




/* ****************************** */
/* Code for some subgroups */
/* Eventually change to labels in a few places */



/* intrinsic CenterLabel(G::LMFDBGrp) --> Any
   {currently returns Center NOT Label}
  
   return Get(G, "Order")/Order(ts);
return Center(G`MagmaGrp)
end intrinsic;


intrinsic CentralQuotient(G::LMFDBGrp) --> Any
   {currently returns CentralQuotient NOT Label}
   return quo<G`MagmaGrp | Center(G`MagmaGrp)>
end intrinsic;



intrinsic CommutatorLabel(G::LMFDBGrp) --> Any
   {currently returns Commutator Subgroup NOT Label}
   return CommutatorSubgroup(G`MagmaGrp);  
end intrinsic;


intrinsic FrattiniLabel(G::LMFDBGrp) --> Any
   {currently returns Frattini Subgroup NOT Label}
   return FrattiniSubgroup(G`MagmaGrp);  
end intrinsic;


intrinsic FrattiniQuotient(G::LMFDBGrp) --> Any
   {currently returns Frattini Quotient NOT Label}
return quo<G`MagmaGrp | FrattiniSubgroup(G`MagmaGrp)>
end intrinsic;


intrinsic FittingSubgroup(G::LMFDBGrp) --> Any
   {currently returns Frattini Subgroup NOT Label}
   return FittingSubgroup(G`MagmaGrp);  
end intrinsic;


*/

/* CenterLabel
Central Quotient
CommutatorLabel
FrattiniLabel
FrattiniQuotient
FittingSubgroup 

CenterLabel, CentralQuotient, CommutatorLabel, AbelianQuotient, CommutatorCount, FrattiniLabel, FrattiniQuotient, FittingSubgroup

center_label	text	Label for the isomoprhism class of the center Z
central_quotient	text	Label for the isomorphism class of G/Z

frattini	integer	Subgroup label for the Frattini subgroup
frattini_label	text	Label for the isomorphism class of the Frattini subgroup
frattini_quotient	text	Label for the isomorphism class of the Frattini quotient
fitting   integer  Subgroup label for the Fitting subgroup (largest nilpotent normal)

*/


