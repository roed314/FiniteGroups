/*
list of attributes to compute. DONE is either done here or in Basics.m
see https://github.com/roed314/FiniteGroups/blob/master/ProposedSchema.md for description of attributes
*/
intrinsic outer_equivalence(H::LMFDBSubGrp) -> BoolElt
    {}
    return H`Grp`outer_equivalence;
end intrinsic;


/* moved to Basic */
/* intrinsic maximal(H::LMFDBSubGrp) -> BoolElt */// Need to be subgroup attribute file
/*  {Determine if a subgroup is maximal}
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  return IsMaximal(GG, HH);
  end intrinsic; */


intrinsic minimal(H::LMFDBSubGrp) -> BoolElt // Need to be subgroup attribute file
  {Determine if a subgroup is maximal}
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  if IsPrime(Order(HH)) then
    return true;
  else
    return false;
  end if;
end intrinsic;


intrinsic maximal_normal(H::LMFDBSubGrp) -> BoolElt // Need to be subgroup attribute file
  {Determine if a subgroup is maximal normal subgroup}
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  if not IsNormal(GG, HH) then
    return false;
  else
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
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  Q := quo< GG | HH >;
  if Order(HH) eq 1 then
    return 1;
  elif Gcd(Order(HH), Order(Q)) eq 1 then
    F:= Factorization(Order(HH));
    return &*[f[1] : f in F];
  else
    return 0;
  end if;
end intrinsic;

intrinsic sylow(H::LMFDBSubGrp) -> RngIntElt // Need to be subgroup attribute file
{when order of H and order of Q are prime to each other it returns the radical of the order of H, otherwise returns 0}
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  Q := quo< GG | HH >;
  if Order(HH) eq 1 then
    return 1;
  elif IsPrimePower(Order(HH)) and (Gcd(Order(HH), Order(Q)) eq 1) then
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
  GG := Get(H, "MagmaAmbient");
  return label(GG);
end intrinsic;

intrinsic ambient_order(H::LMFDBSubGrp) -> RngIntElt // Need to be subgroup attribute file
  {returns order of the ambient group}
  GG := Get(H, "MagmaAmbient");
  return Order(GG);
end intrinsic;

intrinsic quotient(H::LMFDBSubGrp) -> Any // Need to be together with all the labels
{Determine label of the quotient group}
  GG := Get(H, "MagmaAmbient");
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
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  Q := quo< GG | HH >;
  if not IsNormal(GG, HH) then
    return None();
  else
    return Order(Q);
  end if;
end intrinsic;

intrinsic GetGrp(H::LMFDBSubGrp) -> LMFDBGrp
    {This function is used by the file IO code to help identify subgroups}
    return H`Grp;
end intrinsic;

intrinsic MagmaAmbient(H::LMFDBSubGrp) -> Grp
{The underlying magma group of the ambient group}
    return (H`Grp)`MagmaGrp;
end intrinsic;


intrinsic minimal_normal(H::LMFDBSubGrp) -> BoolElt // Need to be subgroup attribute file
  {Determine whether a subgroup is minimal normal or not}
  GG := Get(H, "MagmaAmbient");
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
  GG := Get(H, "MagmaAmbient");
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

intrinsic projective_image(H::LMFDBSubGrp) -> Any // Need to be subgroup attribute file
  {returns label of the quotient by the center of the ambient group}
  GG := H`MagmaAmbient;
  HH := H`MagmaSubGrp; 
  return label(quo<GG|HH meet Center(GG)>);
end intrinsic;

intrinsic complements(H::LMFDBSubGrp) -> Any
  {Returns the subgroups K of G such that H ∩ K = e and G=HK in a list}
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  S:= Subgroups(GG);
  if not Get(H, "normal") then
    return [];
  else
    comps := [el : el in S | el`order eq (Order(GG) div Order(HH))];
    M := [];
    for s in comps do
      K := s`subgroup;
      if #(K meet HH) eq 1 then
        Append(~M, K);
      end if;
    end for;
    return M;
  end if;
end intrinsic;


intrinsic direct(H::LMFDBSubGrp) -> Any // Need to be subgroup attribute file
  {Returns whether this sequence with H direct or not, null when non-normal}
  GG := H`MagmaAmbient;
  HH := H`MagmaSubGrp; 
  if not IsNormal(GG, HH) then
    return None();
  else
    comps := complements(H);
    for K in comps do
      if #(K meet HH) eq 1 and IsNormal(GG, K) then
        return true;
      end if;
    end for;
    return false;
  end if;
end intrinsic;



