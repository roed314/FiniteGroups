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
  {Returns whether this sequence with H splits or not, null when non-normal}
  dirbool := false;
  GG := H`MagmaAmbient;
  HH := H`MagmaSubGrp;
  S := Subgroups(GG); 
  if not IsNormal(GG, HH) then
    return None();
  else 
    comps := [el : el in S | el`order eq (Order(GG) div Order(HH))]; 
    for s in comps do
      K := s`subgroup;
      if #(HH meet K) eq 1 then 
        return true;
      end if;
    end for;
  end if;
  return dirbool;
end intrinsic;

intrinsic sylow(H::LMFDBSubGrp) -> RngIntElt
{when order of H and order of Q are prime to each other it returns the radical of the order of H}
  GG := H`MagmaAmbient;
  HH := H`MagmaSubGrp;
  Q := quo< GG | HH >;
  if IsPrimePower(Order(HH)) and (Gcd(Order(HH), Order(Q)) eq 1) then
    _, k , _ :=IsPrimePower(Order(HH));
    return k;
  else 
    return 0;
  end if;
end intrinsic;

intrinsic hall(H::LMFDBSubGrp) -> RngIntElt
{when order of H and order of Q are prime to each other it returns the radical of the order of H}
  GG := H`MagmaAmbient;
  HH := H`MagmaSubGrp;
  Q := quo< GG | HH >;
  if Gcd(Order(HH), Order(Q)) eq 1 then
    F:= Factorization(Order(HH));
    return &*[f[1] : f in F];
  end if;
end intrinsic;

intrinsic subgroup(H::LMFDBSubGrp) -> MonStgElt
  {Determine label of subgroup}
  GG := H`MagmaAmbient;
  HH := H`MagmaSubGrp;
  return label(H);
end intrinsic;

intrinsic subgroup_order(H::LMFDBSubGrp) -> RngIntElt
  {returns order of the subgroup}
  HH := H`MagmaSubGrp;
  return Order(HH);
end intrinsic;

intrinsic ambient(H::LMFDBSubGrp) -> MonStgElt
  {Determine label of the ambient group}
  GG := H`MagmaAmbient;
  return label(GG);
end intrinsic;

intrinsic ambient_order(H::LMFDBSubGrp) -> RngIntElt
  {returns order of the ambient group}
  GG := H`MagmaAmbient;
  return Order(GG);
end intrinsic;

intrinsic quotient(H::LMFDBSubGrp) -> MonStgElt
{Determine label of the quotient group}
  GG := H`MagmaAmbient;
  HH := H`MagmaSubGrp;
  Q := quo< GG | HH >;
  return label(Q);
end intrinsic;

intrinsic quotient_order(H::LMFDBSubGrp) -> RngIntElt
{Determine the order of the quotient group}
  GG := H`MagmaAmbient;
  HH := H`MagmaSubGrp;
  Q := quo< GG | HH >;
  return label(Q);
end intrinsic;
