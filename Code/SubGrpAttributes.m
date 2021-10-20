
/*
list of attributes to compute. DONE is either done here or in Basics.m
see https://github.com/roed314/FiniteGroups/blob/master/ProposedSchema.md for description of attributes
*/
intrinsic outer_equivalence(H::LMFDBSubGrp) -> BoolElt
    {}
    return H`Grp`outer_equivalence;
end intrinsic;


intrinsic generators(H::LMFDBSubGrp) -> SeqEnum
    {}
    // We need to match up the generators with the list of generators of this subgroup as an abstract group
    // TODO: actually give this isomorphism
    //if HasAttribute(H, "standard_generators") and H`standard_generators then
    GG := H`MagmaAmbient;
    return [GG!h : h in Generators(H`MagmaSubGrp)];
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

intrinsic characteristic(H::LMFDBSubGrp) -> BoolElt
{Returns true if H is a characteristic subgroup of G}
    if not Get(H, "normal") then return false; end if;
    G := H`Grp;
    HH := H`MagmaSubGrp;
    Hol := Get(G, "Holomorph");
    inj := Get(G, "HolInj");
    return IsNormal(Hol, inj(HH));
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

/*
intrinsic Quotient(H::LMFDBSubGrp) -> LMFDBGrp
    {returns the quotient as an abstract group and sets QuotientMap}
    GG := Get(H, "MagmaAmbient");
    HH := Get(H, "MagmaSubGrp");
    if not Get(H, "normal") then
        error "Subgroup is not normal";
    end if;
    Q := quo< GG | HH >;
*/

intrinsic quotient(H::LMFDBSubGrp) -> Any // Need to be together with all the labels
{Determine label of the quotient group}
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  if not IsNormal(GG, HH) then
    return None();
  else
    Q := quo< GG | HH >;
    return label(Q);
  end if;
end intrinsic;

intrinsic quotient_order(H::LMFDBSubGrp) -> Any // Need to be subgroup attribute file
{Determine the order of the quotient group}
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  return Index(GG, HH);
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
  G := Get(H, "Grp");
  HH := H`MagmaSubGrp;
  // We don't consider the trivial subgroup to be minimal normal
  if not IsNormal(GG, HH) or Order(HH) eq 1 then
    return false;
  else
    for r in Get(G, "NormalSubgroups") do
      N := r`MagmaSubGrp;
      if (N subset HH) and (N ne HH) and (Order(N) ne 1) then
         return false;
      end if;
    end for;
    return true;
  end if;
end intrinsic;


intrinsic split(H::LMFDBSubGrp) -> Any
  {Returns whether this sequence with H splits or not, null when non-normal}
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  G := Get(H, "Grp");
  S := Get(G, "Subgroups");
  if not IsNormal(GG, HH) then
    return None();
  else
    comps := [el : el in S | Order(el`MagmaSubGrp) eq (Order(GG) div Order(HH))];
    for s in comps do
      K := s`MagmaSubGrp;
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
  G := Get(H, "Grp");
  S:= Get(G, "Subgroups");
  if not Get(H, "normal") then
    return [];
  else
    comps := [el : el in S | Order(el`MagmaSubGrp) eq (Order(GG) div Order(HH))];
    M := [];
    for s in comps do
      K := s`MagmaSubGrp;
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

intrinsic stem(H::LMFDBSubGrp) -> BoolElt
   {Determine whether H is contained in both the center and commutator subgroups of G}
   GG := Get(H, "MagmaAmbient");
   HH := H`MagmaSubGrp;
   Cent:=Center(GG);
   Comm:=CommutatorSubgroup(GG);
   if HH subset Cent and HH subset Comm then
      return true;
   else
     return false;
   end if;
end intrinsic;

intrinsic QuotientActionMap(H::LMFDBSubGrp) -> Any
{if not normal, None; if split or N abelian, Q -> Aut(N); otherwise, Q -> Out(N)}
    if Get(H, "normal") and Get(H, "subgroup_order") ne 1 and Get(H, "quotient_order") ne 1 then
        G := H`Grp;
        GG := G`MagmaGrp;
        N := H`MagmaSubGrp;
        A := AutomorphismGroup(N);
        if Get(H, "split") then
            Q := Get(H, "complements")[1];
            //print "split", H`label;
            return hom<Q -> A| [<q, hom<N -> N | [<n, n^q> : n in Generators(N)]>> : q in Generators(Q)]>;
        else
            Q, Qproj := quo< G`MagmaGrp | N >;
            if IsAbelian(N) then
                //print "abelian", H`label;
                return hom<Q -> A | [<q, hom<N -> N | [<n, n^(q@@Qproj)> : n in Generators(N)]>> : q in Generators(Q)]>;
            else
                return None();
                // Out, Oproj := OuterFPGroup(A);
                // return hom<Q -> Out | [hom<N -> N | [n^(q@@Qproj) : n in Generators(N)]>@Oproj : q in Generators(Q)]>;
            end if;
        end if;
    else
        return None();
    end if;
end intrinsic;

/* This should be rewritten later for nomal subgroups, it returns none for now */
intrinsic quotient_action_image(H::LMFDBSubGrp) -> Any
{the label for Q/K as an abstract group, where K is the quotient action kernel (NULL if H is not normal)}
    // Taking the image of the QuotientActionMap can cause segfaults (e.g. 336.172) so we disable it for now.
    f := Get(H, "QuotientActionMap");
    if Type(f) eq NoneType then
        return None();
    else
        return label(Image(f));
    end if;
end intrinsic;

/* It would be better for this to return the subgroup label in the quotient, rather than the label as an abstract group */
intrinsic quotient_action_kernel(H::LMFDBSubGrp) -> Any
{the label of the kernel of the map from Q to A, as an abstract group (NULL if H is not normal). }
    // Taking the kernel of the QuotientActionMap can cause segfaults (e.g. 336.172) so we disable it for now.
    f := Get(H, "QuotientActionMap");
    if Type(f) eq NoneType then
        return None();
    else
        return label(Kernel(f));
    end if;
end intrinsic;

intrinsic quotient_action_kernel_order(H::LMFDBSubGrp) -> Any
{the label of the kernel of the map from Q to A, as an abstract group (NULL if H is not normal). }
    // Taking the kernel of the QuotientActionMap can cause segfaults (e.g. 336.172) so we disable it for now.
    f := Get(H, "QuotientActionMap");
    if Type(f) eq NoneType then
        return None();
    else
        return #Kernel(f);
    end if;
end intrinsic;

/* This should be rewritten later, it returns none for now */
intrinsic quotient_fusion(H::LMFDBSubGrp) -> Any
    {A list of lists: for each conjugacy class of Q, lists the conjugacy classes in G that map to it (NULL if unknown)}
    return None();
end intrinsic;

/* This should be rewritten later, it returns none for now */
intrinsic subgroup_fusion(H::LMFDBSubGrp) -> Any
    {A list: for each conjugacy class of H, gives the conjugacy class of G in which its contained}
    return None();
end intrinsic;


intrinsic diagram_x(H::LMFDBSubGrp) -> RngIntElt
    {integer from 1 to 10000 indicating the x-coordinate for plotting the subgroup in the lattice, 0 if not computed--will be computed elsewhere}
    return 0;
end intrinsic;

intrinsic diagram_aut_x(H::LMFDBSubGrp) -> RngIntElt
{integer from 1 to 10000 indicating the x-coordinate for plotting the subgroup in the lattice, 0 if not computed--will be computed elsewhere}
    return 0;
end intrinsic;

intrinsic subgroup_tex(H::LMFDBSubGrp) -> Any
  {Returns Magma's name for the subgroup.}
  g:=H`MagmaSubGrp;
  gn:= GroupName(g: TeX:=true);
  return ReplaceString(gn, "\\", "\\\\");
end intrinsic;

intrinsic ambient_tex(H::LMFDBSubGrp) -> Any
  {Returns Magma's name for the ambient group.}
  g := Get(H, "MagmaAmbient");
  gn:= GroupName(g: TeX:=true);
  return ReplaceString(gn, "\\", "\\\\");
end intrinsic;

intrinsic quotient_tex(H::LMFDBSubGrp) -> Any
  {Returns Magma's name for the quotient.}
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  if IsNormal(GG, HH) then
    Q := quo< GG | HH >;
    gn:= GroupName(Q: TeX:=true);
    return ReplaceString(gn, "\\", "\\\\");
  else
    return None();
  end if;
end intrinsic;

intrinsic quotient_cyclic(H::LMFDBSubGrp) -> Any
  {Whether the quotient exists and is cyclic}
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  if IsNormal(GG, HH) then
    Q := quo< GG | HH >;
    return IsCyclic(Q);
  else
    return None();
  end if;
end intrinsic;

intrinsic quotient_abelian(H::LMFDBSubGrp) -> Any
  {Whether the quotient exists and is abelian}
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  if IsNormal(GG, HH) then
    Q := quo< GG | HH >;
    return IsAbelian(Q);
  else
    return None();
  end if;
end intrinsic;

intrinsic quotient_solvable(H::LMFDBSubGrp) -> Any
  {Whether the quotient exists and is solvable}
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  if IsNormal(GG, HH) then
    Q := quo< GG | HH >;
    return IsSolvable(Q);
  else
    return None();
  end if;
end intrinsic;

intrinsic weyl_group(H::LMFDBSubGrp) -> Any
  {The quotient of the normalizer by the centralizer}
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  N := Normalizer(GG, HH);
  Z := Centralizer(GG, HH);
  W := quo< N | Z >;
  try
    return label(W);
  catch e;
    print "weyl_group", e;
    return None();
  end try;
end intrinsic;

intrinsic aut_weyl_group(H::LMFDBSubGrp) -> Any
{The quotient of the normalizer by the centralizer, inside the holomorph}
    G := H`Grp;
    GG := G`MagmaGrp;
    Ambient := Get(G, "Holomorph");
    inj := Get(G, "HolInj");
    HH := H`MagmaSubGrp;
    N := Normalizer(Ambient, inj(HH));
    Z := Centralizer(Ambient, inj(HH));
    H`aut_weyl_index := (#Ambient * #Z) div (#N * #GG);
    H`aut_centralizer_order := #(Z meet Stabilizer(Ambient, 1));
    if (#N div #Z) gt 2000 or (#N div #Z) in [512, 1024, 1152, 1536, 1920] then
        return None();
    end if;
    try
        W := quo< N | Z >;
        return label(W);
    catch e;
        return None();
    end try;
end intrinsic;

intrinsic aut_centralizer_order(H::LMFDBSubGrp) -> Any
{The number of automorphisms of the ambient group that act trivially on this subgroup}
    W := Get(H, "aut_weyl_group"); // sets attr
    return H`aut_centralizer_order;
end intrinsic;

intrinsic aut_weyl_index(H::LMFDBSubGrp) -> Any
{The index of the aut_weyl_group inside the automorphism group of H}
    W := Get(H, "aut_weyl_group"); // sets attr
    return H`aut_weyl_index;
end intrinsic;

intrinsic proper(H::LMFDBSubGrp) -> Any
  {false for trivial group and whole group}
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  return (Order(HH) ne 1 and Index(GG, HH) ne 1);
end intrinsic;
