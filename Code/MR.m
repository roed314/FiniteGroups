
intrinsic minimal_normal(H::LMFDBSubGrp) -> BoolElt // Need to be subgroup attribute file
  {Determine if a subgroup is minimal normal subgroup}
  GG := H`MagmaAmbient;
  HH := H`MagmaSubGrp;
  if not IsNormal(GG, HH) then 
    return false;
  else
    for r in NormalSubgroups(GG) do
      N := r`subgroup;
      if (N subset HH) and (N ne HH) and (Order(N) ne 1) then
        return false;
      end if;
    end for;
    return true;
  end if;
end intrinsic;


intrinsic split(H::LMFDBSubGrp) -> Any // Need to be subgroup attribute file
  {Returns whether this sequence with H splits or not, null when non-normal}
  GG := H`MagmaAmbient;
  HH := H`MagmaSubGrp;
  S := Subgroups(GG); 
  if not IsNormal(GG, HH) then
    return None();
  else 
    comps := [el : el in S | el`order eq (Order(GG) div Order(HH))]; 
    for s in comps do
      K := s`subgroup;
      if #(K meet HH) eq 1 then 
        return true;
      end if;
    end for;
  end if;
  return false;
end intrinsic;

intrinsic order_stats(G::LMFDBGrp) -> Any
  {gives an order pair of order of elements and number of element}
  GG := G`MagmaGrp;
  A := AssociativeArray()
  C := Classes(GG);
  L := {c[1]: c in C};
  for l in L do 
    for c in C do 
      A[l] := &+[c[2] : c in C | c[1] eq l];
    end for;
  end for;
  return A;
end intrinsic;





