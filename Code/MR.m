intrinsic direct(H::LMFDBSubGrp) -> Any // Need to be subgroup attribute file
  {Returns whether this sequence with H direct or not, null when non-normal}
  GG := H`MagmaAmbient;
  HH := H`MagmaSubGrp; 
  if not IsNormal(GG, HH) then
    return None();
  else
    comps := Complements(GG, HH);
    for K in comps do
      if #(K meet HH) eq 1 and IsNormal(GG, K) then
        return true;
      end if;
    end for;
    return false;
  end if;
end intrinsic;



