R<x> := PolynomialRing(Rationals());
K<a> := NumberField(R![-1, 1, -4, 2, -1, 1]); // deg 5 extension
L<b> := NumberField(R![1, -2, 0, 10, -15, 0, 40, -64, 46, 8, -32, 8, 46, -64, 40, 0, -15, 10, 0, -2, 1]); // Galois closure
G, mp := AutomorphismGroup(L);
subgroups := Subgroups(G);
fields := [* FixedField(L, rec`subgroup) : rec in subgroups *];
