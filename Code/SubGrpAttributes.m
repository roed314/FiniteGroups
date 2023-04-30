
/*
list of attributes to compute. DONE is either done here or in Basics.m
see https://github.com/roed314/FiniteGroups/blob/master/ProposedSchema.md for description of attributes
*/

intrinsic MagmaCentralizer(H::LMFDBSubGrp) -> Grp
{compute magma version of centralizer}
    GG:=H`Grp`MagmaGrp;
    HH:=H`MagmaSubGrp;
    try
        C:=Centralizer(GG,HH);
    catch e     //dealing with a strange Magma bug in 120.5
        GenCentralizers:={Centralizer(GG,h) : h in Generators(HH)};
        C:=&meet(GenCentralizers);
    end try;
    return C;
end intrinsic;

intrinsic outer_equivalence(H::LMFDBSubGrp) -> BoolElt
    {}
    return Get(H`Grp, "outer_equivalence");
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
    // This will usually not get called since it's set by the LMFDBSubgroup(SubgroupLatElt) constructor
    if not Get(H, "normal") then return false; end if;
    G := H`Grp;
    HH := H`MagmaSubGrp;
    Hol := Get(G, "Holomorph");
    inj := Get(G, "HolInj");
    return IsNormal(Hol, inj(HH));
end intrinsic;


intrinsic hall(H::LMFDBSubGrp) -> RngIntElt // Need to be subgroup attribute file
{when order of H and order of Q are prime to each other it returns the radical of the order of H, otherwise returns 0}
    Hord := Get(H, "subgroup_order");
    Qord := Get(H, "quotient_order");
    if Hord eq 1 then
        return 1;
    elif Gcd(Hord, Qord) eq 1 then
        F := Factorization(Hord);
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
    return label_subgroup(H`Grp, H`MagmaSubGrp : hsh:=Get(H, "subgroup_hash"), giveup:=true);
end intrinsic;

intrinsic subgroup_order(H::LMFDBSubGrp) -> RngIntElt // Need to be subgroup attribute file
{the order of the subgroup}
    return Order(H`MagmaSubGrp);
end intrinsic;

intrinsic subgroup_hash(H::LMFDBSubGrp) -> Any
{the hash of the subgroup}
    return hash(H`MagmaSubGrp);
end intrinsic;

intrinsic ambient(H::LMFDBSubGrp) -> MonStgElt // Need to be together with all the labels
{Determine label of the ambient group}
    return Get(H`Grp, "label");
end intrinsic;

intrinsic ambient_order(H::LMFDBSubGrp) -> RngIntElt // Need to be subgroup attribute file
{returns order of the ambient group}
    return Get(H`Grp, "order");
end intrinsic;

intrinsic core_order(H::LMFDBSubGrp) -> RngIntElt
{}
    return Order(H`core);
end intrinsic;

intrinsic Quotient(H::LMFDBSubGrp) -> Grp
    {returns the quotient as an abstract group and sets QuotientMap}
    GG := Get(H, "MagmaAmbient");
    HH := Get(H, "MagmaSubGrp");
    if not Get(H, "normal") then
        error "Subgroup is not normal";
    end if;
    Q, H`QuotientMap := BestQuotient(GG, HH);
    return Q;
end intrinsic;

intrinsic QuotientMap(H::LMFDBSubGrp) -> Map
{}
    Q := Get(H, "Quotient"); // sets map
    return H`QuotientMap;
end intrinsic;

intrinsic quotient(H::LMFDBSubGrp) -> Any // Need to be together with all the labels
{Determine label of the quotient group}
    if not Get(H, "normal") then
        return None();
    else
        return label_quotient(H`Grp, H`MagmaSubGrp : GN:=Get(H, "Quotient"), hsh:=Get(H, "quotient_hash"), giveup:=true);
    end if;
end intrinsic;

intrinsic quotient_order(H::LMFDBSubGrp) -> Any // Need to be subgroup attribute file
{Determine the order of the quotient group}
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  return Index(GG, HH);
end intrinsic;

intrinsic quotient_hash(H::LMFDBSubGrp) -> Any
{the hash of the quotient; None if not normal}
    if Get(H, "normal") then
        return hash(Get(H, "Quotient"));
    else
        return None();
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
  G := Get(H, "Grp");
  HH := H`MagmaSubGrp;
  // We don't consider the trivial subgroup to be minimal normal
  if not IsNormal(GG, HH) or Order(HH) eq 1 then
    return false;
  else
    if IsSimple(HH) then return true; end if;
    // Any minimal normal subgroup is the direct product of isomorphic simple groups
    if IsSolvable(HH) then
      if not IsAbelian(HH) then return false; end if;
      if not IsPrime(Exponent(HH)) then return false; end if;
      return IsIrreducible(GModule(GG, HH));
    else
      if #{F : F in CompositionFactors(HH)} ne 1 then return false; end if;
    end if;
    // We fall back on iterating over the minimal normal subgroups of G.  This should occur rarely.
    Norms := Get(G, "MagmaMinimalNormalSubgroups");
    if Type(Norms) eq NoneType then
        return None();
    end if;
    for N in Norms do
      if HH eq N then
        return true;
      end if;
    end  for;
    return false;
  end if;
end intrinsic;

intrinsic central_factor(H::LMFDBSubGrp) -> BoolElt
{H is a central factor of G if it is nontrivial, noncentral, normal and generates G together with its centralizer.
 In such a case, G will be a nontrivial central product of H with its centralizer.
 Moreover, any nonabelian group that has some nontrivial central product decomposition will have one of this form}
    if Get(H, "normal") and Get(H, "subgroup_order") ne 1 and Get(H, "quotient_order") ne 1 then
        HH := H`MagmaSubGrp;
        GG := Get(H, "MagmaAmbient");
C := Get(H,"MagmaCentralizer");  // JP changes centralizer
        // |CH| = |C||H|/|C meet H|. We check if |CH| = |G| and return true if so.
        if #C lt #GG and #C * #HH eq #(C meet HH) * #GG then
            return true;
        end if;
    end if;
    return false;
end intrinsic;

intrinsic split(H::LMFDBSubGrp) -> Any
{Returns whether this sequence with H splits or not, null when non-normal}
    if not Get(H, "normal") then return None(); end if;
    if Get(H`Grp, "complements_known") then
        return #Get(H, "complements") gt 0;
    elif Gcd(Get(H, "subgroup_order"), Get(H, "quotient_order")) eq 1 then
        //Schur-Zassenhaus Theorem: if (#N,#G/N)=1 then splits (JP)
        return true;
    else
        return None();
    end if;
end intrinsic;

intrinsic projective_image(H::LMFDBSubGrp) -> Any // Need to be subgroup attribute file
  {returns label of the quotient by the center of the ambient group}
  return label_quotient(H`Grp, H`MagmaSubGrp meet Center(H`MagmaAmbient) : giveup:=true);
end intrinsic;

RF := recformat<subgroup, order, length>;
intrinsic complements(H::LMFDBSubGrp) -> Any
{Returns the subgroups K of G such that H ∩ K = e and G=HK in a list}
  // This is usually set when constructed from a SubgroupLatElt
  if not Get(H, "normal") then
      return [];
  end if;
  if not Get(H`Grp, "complements_known") then return None(); end if;
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  return [rec<RF|subgroup:=C> : C in Complements(GG, HH)];
end intrinsic;


intrinsic direct(H::LMFDBSubGrp) -> Any // Need to be subgroup attribute file
  {Returns whether this sequence with H direct or not, null when non-normal}
  GG := H`MagmaAmbient;
  if not Get(H, "normal") then
    return None();
  else
    comps := Get(H, "complements");
    if Type(comps) eq NoneType then
      return None();
    end if;
    for K in comps do
      if IsNormal(GG, K`subgroup) then
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

intrinsic mobius_sub(H::LMFDBSubGrp) -> Any
{The value of the mobius function within the lattice of all subgroups}
    x := H`LatElt;
    L := x`Lat;
    if L`index_bound ne 0 then
        return None();
    elif assigned L`from_conj then
        conjL, lookup, inv_lookup := Explode(L`from_conj);
        y := conjL`subs[inv_lookup[x`i][1]];
        if not assigned y`mobius_sub then
            SetMobiusSub(conjL);
        end if;
        return y`mobius_sub;
    else
        if not assigned x`mobius_sub then
            SetMobiusSub(L);
        end if;
        return x`mobius_sub;
    end if;
end intrinsic;

intrinsic mobius_quo(H::LMFDBSubGrp) -> Any
{The value of the mobius function within the lattice of normal subgroups}
    if not Get(H, "normal") then return None(); end if;
    x := H`LatElt;
    L := x`Lat;
    G := L`Grp;
    if not (Get(G, "normal_subgroups_known") and Get(G, "subgroup_inclusions_known")) then return None(); end if;
    y := x`NormLatElt;
    N := y`Lat;
    if assigned N`from_conj then
        conjN, lookup, inv_lookup := Explode(N`from_conj);
        z := conjN`subs[inv_lookup[y`i][1]];
        if not assigned z`mobius_quo then
            SetMobiusQuo(conjN);
        end if;
        return z`mobius_quo;
    else
        if not assigned y`mobius_quo then
            SetMobiusQuo(N);
        end if;
        return y`mobius_quo;
    end if;
end intrinsic;

intrinsic QuotientActionMap(H::LMFDBSubGrp : use_solv:=true) -> Any
{if not normal, None; if split or N abelian, Q -> Aut(N); otherwise, Q -> Out(N)}
    if Get(H, "normal") and Get(H, "subgroup_order") ne 1 and Get(H, "quotient_order") ne 1 then
        G := H`Grp;
        GG := G`MagmaGrp;
        N := H`MagmaSubGrp;
        //vprint User1: "Starting QuotientActionMap with", use_solv, Get(H, "split");
        t := Cputime();
        if use_solv and Type(GG) eq GrpPC then
            A := AutomorphismGroupSolubleGroup(N);
        else
            A := AutomorphismGroup(N);
        end if;
        //vprint User1: "Aut complete in", Cputime() - t;
        t := Cputime();
        try
            if Get(H, "split") then
                Q := Get(H, "complements")[1]`subgroup;
                //print "split", H`label;
                f := hom<Q -> A| [<q, hom<N -> N | [<n, n^q> : n in Generators(N)]>> : q in Generators(Q)]>;
            else
                Q, Qproj := quo< G`MagmaGrp | N >;
                if IsAbelian(N) then
                    //print "abelian", H`label;
                    f := hom<Q -> A | [<q, hom<N -> N | [<n, n^(q@@Qproj)> : n in Generators(N)]>> : q in Generators(Q)]>;
                else
                    //vprint User1: "Not split or abelian";
                    return None();
                    // Out, Oproj := OuterFPGroup(A);
                    // return hom<Q -> Out | [hom<N -> N | [n^(q@@Qproj) : n in Generators(N)]>@Oproj : q in Generators(Q)]>;
                end if;
            end if;
            //vprint User1: "Hom complete in", Cputime() - t;
            return f;
        catch e;
            if use_solv then
                return None();
            else
                return QuotientActionMap(H : use_solv:=true);
            end if;
        end try;
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
        return label(Image(f) : strict:=false, giveup:=true);
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
        return label(Kernel(f) : strict:=false, giveup:=true);
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
    if H`order eq H`Grp`order then
        return Get(H`Grp, "tex_name");
    end if;
    g:=H`MagmaSubGrp;
    gn:= GroupName(g: TeX:=true);
    return ReplaceString(gn, "\\", "\\\\");
end intrinsic;

intrinsic ambient_tex(H::LMFDBSubGrp) -> Any
{Returns Magma's name for the ambient group.}
    return Get(H`Grp, "tex_name");
end intrinsic;

intrinsic quotient_tex(H::LMFDBSubGrp) -> Any
{Returns Magma's name for the quotient.}
    if H`order eq 1 then
        return Get(H`Grp, "tex_name");
    end if;
    if Get(H, "normal") then
        gn:= GroupName(Get(H, "Quotient"): TeX:=true);
        return ReplaceString(gn, "\\", "\\\\");
    else
        return None();
    end if;
end intrinsic;

intrinsic quotient_cyclic(H::LMFDBSubGrp) -> Any
  {Whether the quotient exists and is cyclic}
  if Get(H, "normal") then
    return IsCyclic(Get(H, "Quotient"));
  else
    return None();
  end if;
end intrinsic;

intrinsic quotient_abelian(H::LMFDBSubGrp) -> Any
  {Whether the quotient exists and is abelian}
  if Get(H, "normal") then
    return IsAbelian(Get(H, "Quotient"));
  else
    return None();
  end if;
end intrinsic;

intrinsic quotient_solvable(H::LMFDBSubGrp) -> Any
  {Whether the quotient exists and is solvable}
  if Get(H, "normal") then
    return IsSolvable(Get(H, "Quotient"));
  else
    return None();
  end if;
end intrinsic;

intrinsic weyl_group(H::LMFDBSubGrp) -> Any
{The quotient of the normalizer by the centralizer}
    GG := Get(H, "MagmaAmbient");
    HH := H`MagmaSubGrp;
    N := Normalizer(GG, HH);
Z := Get(H,"MagmaCentralizer");  // JP changed centralizer
    W := BestQuotient(N, Z);
    try
        return label(W : strict:=false, giveup:=true);
    catch e;
        print "error in weyl_group", e;
        return None();
    end try;
end intrinsic;

intrinsic aut_weyl_group(H::LMFDBSubGrp) -> Any
{The quotient of the normalizer by the centralizer, inside the holomorph}
    G := H`Grp;
    if Get(H, "quotient_order") eq 1 or Get(H, "subgroup_order") eq 1 or not Get(G, "HaveHolomorph") then
        return None();
    end if;
    GG := G`MagmaGrp;
    Ambient := Get(G, "Holomorph");
    inj := Get(G, "HolInj");
    HH := H`MagmaSubGrp;
    N := Normalizer(Ambient, inj(HH));
    Z := Centralizer(Ambient, inj(HH));
    H`AutStab := N;
    H`aut_weyl_index := (#Ambient * #Z) div (#N * #GG);
    H`aut_centralizer_order := #(Z meet Stabilizer(Ambient, 1));
    W := BestQuotient(N, Z);
    return label(W : strict:=false, giveup:=true);
end intrinsic;

intrinsic aut_centralizer_order(H::LMFDBSubGrp) -> Any
{The number of automorphisms of the ambient group that act trivially on this subgroup}
    W := Get(H, "aut_weyl_group"); // sets attr
    return (assigned H`aut_centralizer_order) select H`aut_centralizer_order else None();
end intrinsic;

intrinsic aut_stab_index(H::LMFDBSubGrp) -> Any
{The index of Stab_A(H) in Aut(G); 1 for characteristic subgroups}
    W := Get(H, "aut_weyl_group"); // sets AutStab
    if not assigned H`AutStab then return None(); end if;
    G := H`Grp;
    Ambient := Get(G, "Holomorph");
    N := (H`AutStab meet Stabilizer(Ambient, 1));
    return #Ambient div (#N * Get(H, "ambient_order"));
end intrinsic;

intrinsic aut_weyl_index(H::LMFDBSubGrp) -> Any
{The index of the aut_weyl_group inside the automorphism group of H}
    W := Get(H, "aut_weyl_group"); // sets attr
    if not assigned H`aut_weyl_index then return None(); end if;
    return H`aut_weyl_index;
end intrinsic;

intrinsic aut_quo_index(H::LMFDBSubGrp) -> Any
{The index of the image of Stab_A(H) in Aut(G/H)}
    if not Get(H, "normal") then return None(); end if;
    W := Get(H, "aut_weyl_group"); // sets AutStab
    if not assigned H`AutStab then return None(); end if;
    N := H`AutStab;
    G := H`Grp;
    Ambient := Get(G, "Holomorph");
    inj := Get(G, "HolInj");
    Q := Get(H, "Quotient");
    if #Q eq 1 then
        return 1;
    end if;
    proj := Get(H, "QuotientMap");
    gens := [g : g in Generators(Q)];
    Ngens := Generators(N);
    lifts := [x @@ proj : x in gens];
    AQ := AutomorphismGroup(Q); // could be expensive, would be ideal to fetch this
    AQimg := AutomorphismGroup(Q, gens, [[(inj(x)^n) @@ inj @ proj : x in lifts] : n in Ngens]);
    return #AQ div #AQimg;
end intrinsic;

intrinsic proper(H::LMFDBSubGrp) -> Any
  {false for trivial group and whole group}
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  return (Order(HH) ne 1 and Index(GG, HH) ne 1);
end intrinsic;

/* TODO
intrinsic diagramx(H::LMFDBSubGrp) -> Any
{A list of integer x-coordinates (between 0 and 10000) of length 2 (outer_equivalence and not normal), 4(outer_equivalence and normal or not outer_equivalence and not normal), or 8 (not outer_equivalence and normal)}
    if Get(H`Grp, "outer_equivalence") then
        if Get(H, "normal") then
            
*/
