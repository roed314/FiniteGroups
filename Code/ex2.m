G := New(LMFDBGrp);
G`Label := "whateva";
G`MagmaGrp := Alt(9);
AssignBasicAttributes(G);


GG:=G`MagmaGrp;
S:=Subgroups(GG);

H:=New(LMFDBSubGrp);
H`MagmaSubGrp := Random(S)`subgroup;
H`Label := Label(H`MagmaSubGrp) cat ".1";
H`Ambient := G`Label;
H`MagmaAmbient := GG;
H`SubgroupOrder := #H`MagmaSubGrp;
AssignBasicAttributes(H);


harder:=["IsMaximal"];

for j in harder do dummy:=Get(H,j); end for;


