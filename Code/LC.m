

intrinsic characteristic(H::LMFDBSubGrp) -> Any
  {Returns true if H is a characteristic subgroup of G}
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  A:=AutomorphismGroup(GG);
  gens:=Generators(A); //we only need to check the generators
  IsChar:=true;
  for aut in gens do
    for h in HH do
      if not(aut(h) in HH) then
        IsChar:=false;
        break aut;
      end if;
    end for;
  end for;
  return IsChar;
end intrinsic;






intrinsic number_characteristic_subgroups(G::LMFDBGrp) -> Any
  {Compute the number of characteristic subgroups}
  S:=Subgroups(G`MagmaGrp);
  total:=0;
  for s in S do
    H:=New(LMFDBSubGrp);
    H`Grp:=G;
    H`MagmaSubGrp:=s`subgroup;
    if Get(H,"characteristic") then
      total+:=s`length;
    end if;
  end for;
  return total;
end intrinsic;






intrinsic number_subgroup_classes(G::LMFDBGrp) -> Any
  {Calculates the number of subgroups of the group, up to conjugation by G}
  return #Subgroups(G`MagmaGrp);
end intrinsic;







intrinsic number_subgroups(G::LMFDBGrp) -> Any
  {Calculates the number of subgroups of the group}
  S:=Subgroups(G`MagmaGrp);
  total:=0;
  for s in S do //the AllSubgroups function is pretty slow, we try not to call it
    total+:=s`length;
  end for;
  return total;
end intrinsic;






intrinsic number_normal_subgroups(G::LMFDBGrp) -> Any
  {Calculates the number of normal subgroups of the group}
  GG:=G`MagmaGrp;
  S:=Subgroups(GG);
  total:=0;
  for s in S do
    H:=New(LMFDBSubGrp);
    H`MagmaSubGrp:=s`subgroup;
    H`label := label(H`MagmaSubGrp) cat ".1";
    H`Grp:=G;
    H`ambient := G`label;
    H`label := label(H`MagmaSubGrp) cat ".1";
    H`subgroup_order := #H`MagmaSubGrp;
    AssignBasicAttributes(H);
    if Get(H,"normal") then
      total+:=s`length;
    end if;
  end for;
  return total;
end intrinsic;
