/*
list of attributes to compute. DONE is either done here or in Basics.m
see https://github.com/roed314/FiniteGroups/blob/master/ProposedSchema.md for description of attributes
*/
intrinsic maximal(H::LMFDBSubGrp) -> BoolElt // Need to be subgroup attribute file
  {Determine if a subgroup is maximal}
  GG := H`MagmaAmbient;
  HH := H`MagmaSubGrp;
  return IsMaximal(GG, HH);
end intrinsic;


intrinsic minimal(H::LMFDBSubGrp) -> BoolElt // Need to be subgroup attribute file
  {Determine if a subgroup is maximal}
  GG := H`MagmaAmbient;
  HH := H`MagmaSubGrp;
  if IsPrime(Order(HH)) then
    return true;
  else
    return false;
  end if;
end intrinsic;


intrinsic maximal_normal(H::LMFDBSubGrp) -> BoolElt // Need to be subgroup attribute file
  {Determine if a subgroup is maximal normal subgroup}
  GG := H`MagmaAmbient;
  HH := H`MagmaSubGrp;
  if not IsNormal(GG, HH) then 
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


intrinsic hall(H::LMFDBSubGrp) -> RngIntElt // Need to be subgroup attribute file
{when order of H and order of Q are prime to each other it returns the radical of the order of H, otherwise returns 0}
  GG := H`MagmaAmbient;
  HH := H`MagmaSubGrp;
  Q := quo< GG | HH >;
  if Gcd(Order(HH), Order(Q)) eq 1 then
    F:= Factorization(Order(HH));
    return &*[f[1] : f in F];
  else
    return 0;
  end if;
end intrinsic;

intrinsic sylow(H::LMFDBSubGrp) -> RngIntElt // Need to be subgroup attribute file
{when order of H and order of Q are prime to each other it returns the radical of the order of H, otherwise returns 0}
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

intrinsic subgroup(H::LMFDBSubGrp) -> MonStgElt // Need to be together with all the labels
  {Determine label of subgroup}
  HH := H`MagmaSubGrp;
  return label(HH);
end intrinsic;

intrinsic subgroup_order(H::LMFDBSubGrp) -> RngIntElt // Need to be subgroup attribute file
  {returns order of the subgroup}
  HH := H`MagmaSubGrp;
  return Order(HH);
end intrinsic;

intrinsic ambient(H::LMFDBSubGrp) -> MonStgElt // Need to be together with all the labels
  {Determine label of the ambient group}
  GG := H`MagmaAmbient;
  return label(GG);
end intrinsic;

intrinsic ambient_order(H::LMFDBSubGrp) -> RngIntElt // Need to be subgroup attribute file
  {returns order of the ambient group}
  GG := H`MagmaAmbient;
  return Order(GG);
end intrinsic;

intrinsic quotient(H::LMFDBSubGrp) -> Any // Need to be together with all the labels
{Determine label of the quotient group}
  GG := H`MagmaAmbient;
  HH := H`MagmaSubGrp;
  Q := quo< GG | HH >;
  if not IsNormal(GG, HH) then
    return None();
  else
    return label(Q);
  end if;
end intrinsic;

intrinsic quotient_order(H::LMFDBSubGrp) -> Any // Need to be subgroup attribute file
{Determine the order of the quotient group}
  GG := H`MagmaAmbient;
  HH := H`MagmaSubGrp;
  Q := quo< GG | HH >;
  if not IsNormal(GG, HH) then
    return None();
  else
    return Order(Q);
  end if;
end intrinsic;
