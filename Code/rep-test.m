G := DihedralGroup(10);
tab := CharacterTable(G);
chi := tab[7];
M_mod := GModule(chi);
M0 := MatrixGroup(M_mod);
M := CyclotomizeMatrixGroup(M0);
