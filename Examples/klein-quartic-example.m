K<nu> := CyclotomicField(7);
S<X,Y,Z> := PolynomialRing(K,3);
PP := ProjectiveSpace(S);
C := KleinQuartic(PP);
GG := AutomorphismGroup(C);
Order(GG);
Gperm, rho := PermutationRepresentation(GG);
//Gmat, psi := MatrixRepresentation(G);
subgroups := Subgroups(Gperm);
curves := [* *];
morphisms := [* *];
for rec in subgroups do
  H := rec`subgroup;
  HH_gens := [el @@ rho : el in Generators(H)];
  HH := AutomorphismGroup(C, HH_gens);
  C_H, mp_H := CurveQuotient(HH);
  Append(~curves, C_H);
  Append(~morphisms, mp_H);
end for;
