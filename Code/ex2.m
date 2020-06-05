G := New(LMFDBGrp);
G`label := "whateva";
G`MagmaGrp := DihedralGroup(12);
AssignBasicAttributes(G);


GG:=G`MagmaGrp;
S:=Subgroups(GG);

H:=New(LMFDBSubGrp);
H`MagmaSubGrp := Random(S)`subgroup;
H`label := label(H`MagmaSubGrp) cat ".1";
H`ambient := G`label;
H`Grp := G;
H`subgroup_order := #H`MagmaSubGrp;
AssignBasicAttributes(H);


harder:=["maximal","abelian","normal"];

for j in harder do dummy:=Get(H,j); end for;


