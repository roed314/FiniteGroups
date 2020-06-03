intrinsic maximal(H::LMFDBSubGrp) -> BoolElt
  {Determine if a subgroup is maximal}
  GG := H`MagmaAmbient;
  HH := H`MagmaSubGrp;
  return IsMaximal(GG, HH);
end intrinsic;



intrinsic minimal(H::LMFDBSubGrp) -> BoolElt
  {Determine if a subgroup is maximal}
  GG := H`MagmaAmbient;
  HH := H`MagmaSubGrp;
  if IsPrime(Order(HH)) then
    return true;
  else
    return false;
  end if;
end intrinsic;


intrinsic maximal_normal(H::LMFDBSubGrp) -> BoolElt
  {Determine if a subgroup is maximal normal subgroup}
  GG := H`MagmaAmbient;
  HH := H`MagmaSubGrp;
  if not IsNormal(GG, HH) then // this can be changed by IsNormal(H) when David's attribute is avialable.
    return false;
  end if;
  if IsNormal(GG, HH) then
    Q := quo< GG | HH >;
    if IsSimple(Q) then 
      return true;
    else 
      return false;
    end if;
  end if;    
end intrinsic;


intrinsic minimal_normal(H::LMFDBSubGrp) -> BoolElt
  {Determine if a subgroup is minimal normal subgroup}
  GG := H`MagmaAmbient;
  HH := H`MagmaSubGrp;
  if not IsNormal(GG, HH) then
    return false;
  else
    for r in NormalSubgroups(GG) do
      N := r`subgroup;
      if #(HH meet N) eq 2 then
        return true;
      else 
        return false;
      end if;
    end for;
  end if;
end intrinsic;


intrinsic split(H::LMFDBSubGrp) -> Any
  {Determine if a subgroup is minimal normal subgroup}
  GG := H`MagmaAmbient;
  HH := H`MagmaSubGrp;
  if not IsNormal(GG, HH) then
    return None();
  end if;
end intrinsic;


