G := New(LMFDBGrp);
G`label := "whateva";
G`MagmaGrp := Alt(9);
AssignBasicAttributes(G);

function ezinit(g)
  G:=New(LMFDBGrp);
  G`label:=GroupName(g);
  G`MagmaGrp := g;
  AssignBasicAttributes(G);
  return G;
end function;
