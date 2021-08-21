G := MakeSmallGroup(1,1);
GG := G`MagmaGrp;
Orig := SubgroupLattice(GG : Centralizers := true, Normalizers := true);
L := Orig;
//RePresentLat(G) // seems to hang forever
