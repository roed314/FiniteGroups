/* list of attributes to compute.*/

intrinsic almost_simple(G::LMFDBGrp) -> Any
    {}
    // In order to be almost simple, we need a simple nonabelian normal subgroup with trivial centralizer
    if G`abelian or G`solvable then
        return false;
    end if;

    if not G`normal_subgroups_known then
        return None();
    end if;
    GG := G`MagmaGrp;
    for N in Get(G, "NormalSubgroups") do
        if IsSimple(N`MagmaSubGrp) and not IsAbelian(N`MagmaSubGrp) and (Order(Centralizer(GG, N`MagmaSubGrp)) eq 1) then
            return true;
        end if;
    end for;
    return false;
end intrinsic;

intrinsic number_conjugacy_classes(G::LMFDBGrp) -> Any
    {Number of conjugacy classes in a group}
    return Nclasses(G`MagmaGrp);
end intrinsic;

intrinsic primary_abelian_invariants(G::LMFDBGrp) -> Any
    {If G is abelian, return the PrimaryAbelianInvariants.}
    if G`IsAbelian then
        A := G`MagmaGrp;
    else
        A := G`MagmaGrp / Get(G, "MagmaCommutator");
    end if;
    return PrimaryAbelianInvariants(A);
end intrinsic;

intrinsic quasisimple(G::LMFDBGrp) -> BoolElt
    {}
    Q := G`MagmaGrp / Get(G, "MagmaCenter");
    return (Get(G, "perfect") and IsSimple(Q));
end intrinsic;

intrinsic supersolvable(G::LMFDBGrp) -> BoolElt
    {Check if LMFDBGrp is supersolvable}
    if not Get(G, "solvable") then
        return false;
    end if;
    if Get(G, "nilpotent") then
        return true;
    end if;
    GG := G`MagmaGrp;
    C := [Order(H) : H in ChiefSeries(GG)];
    for i := 1 to #C-1 do
        if not IsPrime(C[i] div C[i+1]) then
            return false;
        end if;
    end for;
    return true;
end intrinsic;

// for LMFDBGrp
// Next 3 intrinsics are helpers for metacyclic
intrinsic EasyIsMetacyclic(G::LMFDBGrp) -> BoolElt
    {Easy checks for possibly being metacyclic}
    if IsSquarefree(Get(G, "order")) or Get(G, "cyclic") then
        return true;
    end if;
    if not Get(G, "solvable") then
        return false;
    end if;
    if Get(G, "abelian") then
        if #Get(G, "smith_abelian_invariants") gt 2 then // take Smith invariants (Invariant Factors), check if length <= 2
            return false;
        end if;
        return true;
    end if;
    return 0;
end intrinsic;

// for groups in Magma
intrinsic EasyIsMetacyclicMagma(G::Grp) -> BoolElt
    {Easy checks for possibly being metacyclic}
    if IsSquarefree(Order(G)) or IsCyclic(G) then
        return true;
    end if;
    if not IsSolvable(G) then
        return false;
    end if;
    if IsAbelian(G) then
        if #InvariantFactors(AbelianGroup(G)) gt 2 then  //take Smith invariants (Invariant Factors), check if length <= 2
			/* Needs to be an abelian group type for Invariant Factor */
            return false;
        end if;
        return true;
    end if;
    return 0;
end intrinsic;

intrinsic CyclicSubgroups(G::GrpAb) -> SeqEnum
    {Compute the cyclic subgroups of the abelian group G}
    cycs := [];
    seen := {};
    for g in G do
        if g in seen then continue; end if;
        H := sub<G | g>;
        m := Order(g);
        for k in [2..m-1] do
            if Gcd(k, m) eq 1 then
                Include(~seen, k*g);
            end if;
        end for;
        Append(~cycs, H);
    end for;
    return cycs;
end intrinsic;

intrinsic metacyclic(G::LMFDBGrp) -> BoolElt
    {Check if LMFDBGrp is metacyclic}
    easy := EasyIsMetacyclic(G);
    if not easy cmpeq 0 then
        return easy;
    end if;
    GG := G`MagmaGrp;
    if Get(G, "pgroup") ne 0 then
        return IsMetacyclicPGroup(GG);
    // IsMetacyclicPGroup doesn't work for abelian groups...
    end if;
    D := DerivedSubgroup(GG);
    if not IsCyclic(D) then
        return false;
    end if;
    Q := quo< GG | D>;
    if not EasyIsMetacyclicMagma(Q) then
        return false;
    end if;
    for HH in CyclicSubgroups(GG) do
	H:=HH`subgroup;    
        if D subset H then
            Q2 := quo<GG | H>;
            if IsCyclic(Q2) then
                return true;
            end if;
        end if;
    end for;
    return false;
end intrinsic;


intrinsic factors_of_order(G::LMFDBGrp) -> Any
    {Prime factors of the order of the group}
    gord:=Get(G,"order");
    return [z[1] : z in Factorization(gord)];
end intrinsic;

intrinsic metabelian(G::LMFDBGrp) -> BoolElt
    {Determine if a group is metabelian}
    g:=G`MagmaGrp;
    return IsAbelian(DerivedSubgroup(g));
end intrinsic;

intrinsic monomial(G::LMFDBGrp) -> BoolElt
    {Determine if a group is monomial}
    g:=G`MagmaGrp;
    if not Get(G,"solvable") then
        return false;
    elif Get(G, "supersolvable") then
        return true;
    elif Get(G,"solvable") and Get(G,"Agroup") then
        return true;
    else
        ct:=CharacterTable(g);
        maxd := Integers() ! Degree(ct[#ct]); // Crazy that coercion is needed
        stat:=[false : c in ct];
        ls:= LowIndexSubgroups(G, maxd);
        if Type(ls) eq NoneType then
          return None();
        else
          hh:=<z`MagmaSubGrp : z in ls>;
          for h in hh do
              lc := LinearCharacters(h);
              indc := <Induction(z,g) : z in lc>;
              for c1 in indc do
                  p := Position(ct, c1);
                  if p gt 0 then
                      Remove(~ct, p);
                  end if;
              end for;
              if #ct eq 0 then
                  return true;
              end if;
          end for;
        end if;
    end if;
    return false;
end intrinsic;




intrinsic rational(G::LMFDBGrp) -> BoolElt
  {Determine if a group is rational, i.e., all characters are rational}
  g:=G`MagmaGrp;
  ct,szs:=RationalCharacterTable(g);
  for s in szs do
    if #s gt 1 then
        return false;
    end if;
  end for;
  return true;
end intrinsic;

intrinsic elementary(G::LMFDBGrp) -> Any
  {Product of a all primes p such that G is a direct product of a p-group and a cyclic group}
  ans := 1;
  if Get(G,"solvable") and Get(G,"order") gt 1 then
    g:=G`MagmaGrp;
    g:=PCGroup(g);
    sylowsys:= SylowBasis(g);
    comp:=ComplementBasis(g);
    facts:= factors_of_order(G);
    for j:=1 to #sylowsys do
      if IsNormal(g, sylowsys[j]) and IsNormal(g,comp[j]) and IsCyclic(comp[j]) then
        ans := ans*facts[j];
      end if;
    end for;
  end if;
  return ans;
end intrinsic;

intrinsic hyperelementary(G::LMFDBGrp) -> Any
  {Product of all primes p such that G is an extension of a p-group by a group of order prime to p}
  ans := 1;
  if Get(G,"solvable") and Get(G,"order") gt 1 then
    g:=G`MagmaGrp;
    g:=PCGroup(g);
    comp:=ComplementBasis(g);
    facts:= factors_of_order(G);
    for j:=1 to #comp do
      if IsNormal(g,comp[j]) and IsCyclic(comp[j]) then
        ans := ans*facts[j];
      end if;
    end for;
  end if;
  return ans;
end intrinsic;


intrinsic MagmaTransitiveSubgroup(G::LMFDBGrp) -> Any
    {Subgroup producing a minimal degree transitive faithful permutation representation}
    g := G`MagmaGrp;
    S := Get(G, "Subgroups");
    m := G`subgroup_index_bound;
    for j in [1..#S] do
        if m ne 0 and Get(S[j], "quotient_order") gt m then
            return None();
        end if;
        if #Core(g, S[j]`MagmaSubGrp) eq 1 then
            return S[j]`MagmaSubGrp;
        end if;
    end for;
    return None();
end intrinsic;

intrinsic transitive_degree(G::LMFDBGrp) -> Any
    {Smallest transitive degree for a faithful permutation representation}
    ts:=Get(G, "MagmaTransitiveSubgroup");
    if Type(ts) eq NoneType then return None(); end if;
    return Get(G, "order") div Order(ts);
end intrinsic;

intrinsic perm_gens(G::LMFDBGrp) -> Any
  {Generators of a minimal degree transitive faithful permutation representation}
  ts := Get(G, "MagmaTransitiveSubgroup");
  g := G`MagmaGrp;
  gg := CosetImage(g,ts);
  return [z : z in Generators(gg)];
end intrinsic;

intrinsic faithful_reps(G::LMFDBGrp) -> Any
  {Dimensions and Frobenius-Schur indicators of faithful irreducible representations}
  if not IsCyclic(Get(G, "MagmaCenter")) then
    return [];
  end if;
  A := AssociativeArray();
  g := G`MagmaGrp;
  ct := CharacterTable(g);
  for j:=1 to #ct do
    ch := ct[j];
    if IsFaithful(ch) then
      if IsOrthogonalCharacter(ch) then
        s := 1;
      elif IsSymplecticCharacter(ch) then
        s := -1;
      else
        s := 0;
      end if;
      v := <Degree(ch), s>;
      if not IsDefined(A, v) then
        A[v] := 0;
      end if;
      A[v] +:= 1;
    end if;
  end for;
  return Sort([[Integers() | k[1], k[2], v] : k -> v in A]);
end intrinsic;

intrinsic smallrep(G::LMFDBGrp) -> Any
  {Smallest degree of a faithful irreducible representation}
  if IsCyclic(Get(G, "MagmaCenter")) then
    return Get(G, "faithful_reps")[1][1];
  else
    return 0;
  end if;
end intrinsic;

// Next 2 intrinsics are helpers for commutator_count
intrinsic ClassPositionsOfKernel(lc::AlgChtrElt) -> Any
  {List of conjugacy class positions in the kernel of the character lc}
  return [j : j in [1..#lc] | lc[j] eq lc[1]];
end intrinsic;

intrinsic dosum(li) -> Any
  {Total a list}
  return &+li;
end intrinsic;

intrinsic commutator_count(G::LMFDBGrp) -> Any
  {Smallest integer n such that every element of the derived subgroup is a product of n commutators}
  g:=G`MagmaGrp;
  ct := CharacterTable(g);
  nccl:= #ct;
  kers := [Set(ClassPositionsOfKernel(lc)) : lc in ct | Degree(lc) eq 1];
  derived := kers[1];
  for s in kers do derived := derived meet s; end for;
  commut := {z : z in [1..nccl] | dosum([ct[j][z]/ct[j][1] : j in [1..#ct[1]]]) ne 0};
  other:= derived diff commut;
  n:=1;
  G_n := derived;
  while not IsEmpty(other) do
    new:={};
    for i in other do
      for j in derived do
        for k in G_n do
          if StructureConstant(g,i,j,k) ne 0 then
            new := new join {i};
            break j;
          end if;
        end for;
      end for;
    end for;
    n:= n+1;
    G_n:=G_n join new;
    other:= other diff new;
  end while;

  return n;
end intrinsic;

// Check redundancy of Sylow call
intrinsic MagmaSylowSubgroups(G::LMFDBGrp) -> Any
  {Compute SylowSubgroups of the group G}
  GG := G`MagmaGrp;
  SS := AssociativeArray();
  F := FactoredOrder(GG);
  for uu in F do
    p := uu[1];
    SS[p] := SylowSubgroup(GG, p);
  end for;
  return SS;
end intrinsic;

intrinsic Zgroup(G::LMFDBGrp) -> Any
  {Check whether all the Syllowsubgroups are cylic}
  SS := MagmaSylowSubgroups(G);
  K := Keys(SS);
  for k in K do
    if not IsCyclic(SS[k]) then
      return false;
    end if;
  end for;
  return true;
end intrinsic;

intrinsic Agroup(G::LMFDBGrp) -> Any
  {Check whether all the Syllowsubgroups are abelian}
  SS := MagmaSylowSubgroups(G);
  K := Keys(SS);
  for k in K do
    if not IsAbelian(SS[k]) then
      return false;
    end if;
  end for;
  return true;
end intrinsic;

intrinsic primary_abelian_invariants(G::LMFDBGrp) -> Any
  {Compute primary abelian invariants of maximal abelian quotient}
  C := Get(G, "MagmaCommutator");
  GG := G`MagmaGrp;
  A := quo< GG | C>;
  return PrimaryAbelianInvariants(A);
end intrinsic;

intrinsic smith_abelian_invariants(G::LMFDBGrp) -> Any
  {Compute invariant factors of maximal abelian quotient}
  C := Get(G, "MagmaCommutator");
  GG := G`MagmaGrp;
  A := quo< GG | C>;
  A := AbelianGroup(A);
  return InvariantFactors(A);
end intrinsic;

intrinsic chevalley_letter(t::Tup) -> MonStgElt
  {Given a tuple of integers corresponding to a finite simple group, as in output of CompositionFactors, return appropriate string for Chevalley group}
  assert #t eq 3;
  assert Type(t[1]) eq "RngIntElt";
  return chevalley_letter(t[1]);
end intrinsic;

intrinsic chevalley_letter(f::RngIntElt) -> MonStgElt
  {Given an integer corresponding to a finite simple group, as in output of CompositionFactors, return appropriate string for Chevalley group}
  assert f in [1..16];
  lets := ["A", "B", "C", "D", "G", "F", "E", "E", "E", "2A", "2B", "2D", "3D", "2G", "2F", "2E"];
  return lets[f];
  /*
    from https://magma.maths.usyd.edu.au/magma/handbook/text/625#6962
      1       A(d, q)
      2       B(d, q)
      3       C(d, q)
      4       D(d, q)
      5       G(2, q)
      6       F(4, q)
      7       E(6, q)
      8       E(7, q)
      9       E(8, q)
     10       2A(d, q)
     11       2B(2, q)
     12       2D(d, q)
     13       3D(4, q)
     14       2G(2, q)
     15       2F(4, q)
     16       2E(6, q)
  */
end intrinsic;

// https://magma.maths.usyd.edu.au/magma/handbook/text/743
intrinsic composition_factor_decode(t::Tup) -> Grp
  {Given a tuple <f,d,q>, in the format of the output of CompositionFactors, return the corresponding group.}
  assert #t eq 3;
  f,d,q := Explode(t);
  if f in [1..16] then
    chev := chevalley_letter(f);
    return ChevalleyGroup(chev, d, q);
  elif f eq 18 then
    // TODO
    // sporadic
    error "Sporadic groups not implemented yet; sorry! :(";
  elif f eq 17 then
    return Alt(d);
  elif f eq 19 then
    return CyclicGroup(q);
  else
    error "Invalid first entry";
  end if;
end intrinsic;

intrinsic composition_factors(G::LMFDBGrp) -> Any
    {labels for composition factors}
    // see https://magma.maths.usyd.edu.au/magma/handbook/text/625#6962
    GG := G`MagmaGrp;
    tups := CompositionFactors(GG);
    facts := [composition_factor_decode(tup) : tup in tups];
    return [label(H) : H in facts];
end intrinsic;

intrinsic composition_length(G::LMFDBGrp) -> Any
  {Compute length of composition series.}
  /*
  GG := Get(G, "MagmaGrp");
  return #CompositionFactors(GG);
  */
  return #Get(G,"composition_factors"); // Correct if trivial group is labeled G_0
end intrinsic;

intrinsic aut_group(G::LMFDBGrp) -> MonStgElt
    {returns label of automorphism group}
    aut:=Get(G, "MagmaAutGroup");
    try
        return label(aut);
    catch e;
        return None();
    end try;
end intrinsic;

intrinsic aut_order(G::LMFDBGrp) -> RingIntElt
   {returns order of automorphism group}
   aut:=Get(G, "MagmaAutGroup");
   return #aut;
end intrinsic;

intrinsic factors_of_aut_order(G::LMFDBGrp) -> SeqEnum
   {returns primes in factorization of automorphism group}
   autOrd:=Get(G,"aut_order");
   return PrimeFactors(autOrd);
end intrinsic;

intrinsic outer_order(G::LMFDBGrp) -> RingIntElt
    {returns order of OuterAutomorphisms }
    aut:=Get(G, "MagmaAutGroup");
    return OuterOrder(aut);
end intrinsic;

intrinsic outer_group(G::LMFDBGrp) -> Any
    {returns OuterAutomorphism Group}
    aut:=Get(G, "MagmaAutGroup");
    try
        return label(OuterFPGroup(aut));
    catch e;
        print "outer_group", e;
        return None();
    end try;
end intrinsic;


intrinsic center_label(G::LMFDBGrp) -> Any
   {Label string for Center}
   return label(Center(G`MagmaGrp));
end intrinsic;


intrinsic central_quotient(G::LMFDBGrp) -> Any
   {label string for CentralQuotient}
   return label(quo<G`MagmaGrp | Center(G`MagmaGrp)>);
end intrinsic;


intrinsic MagmaCommutator(G::LMFDBGrp) -> Any
   {Commutator subgroup}
   return CommutatorSubgroup(G`MagmaGrp);
end intrinsic;


intrinsic commutator_label(G::LMFDBGrp) -> Any
   {label string for Commutator Subgroup}
   comm:= Get(G,"MagmaCommutator");
   return label(comm);
end intrinsic;


intrinsic abelian_quotient(G::LMFDBGrp) -> Any
   {label string for quotient of Commutator Subgroup}
      comm:= Get(G,"MagmaCommutator");
   return label(quo<G`MagmaGrp | G`MagmaCommutator>);
end intrinsic;


intrinsic MagmaFrattini(G::LMFDBGrp) -> Any
   { Frattini Subgroup}
   return FrattiniSubgroup(G`MagmaGrp);
end intrinsic;


intrinsic frattini_label(G::LMFDBGrp) -> Any
   {label string for Frattini Subgroup}
   fratt:= Get(G,"MagmaFrattini");
   return label(fratt);
end intrinsic;


intrinsic frattini_quotient(G::LMFDBGrp) -> Any
   {label string for Frattini Quotient}
   fratt:= Get(G,"MagmaFrattini");
   return label(quo<G`MagmaGrp | fratt>);
end intrinsic;


intrinsic MagmaFitting(G::LMFDBGrp) -> Any
   {Fitting Subgroup}
   return FittingSubgroup(G`MagmaGrp);
end intrinsic;


intrinsic pgroup(G::LMFDBGrp) -> RngInt
    {1 if trivial group, p if order a power of p, otherwise 0}
    if G`order eq 1 then
        return 1;
    else
        fac := Factorization(G`order);
        if #fac gt 1 then
           /* #G has more than one prime divisor. */
           return 0;
        else
            /* First component in fac[1] is unique prime divisor. */
            return fac[1][1];
        end if;
    end if;
end intrinsic;


/* turns G`label and output of LabelSubgroups into string */

function CreateLabel(Glabel, Hlabel);
    if #Hlabel gt 0 then
        return Glabel * "." * Join([Sprint(x) : x in Hlabel], ".");
    else // used for special subgroups where there is only a suffix
        return Glabel;
    end if;
end function;


intrinsic Subgroups(G::LMFDBGrp) -> SeqEnum
    {The list of subgroups computed for this group}
    S := [];
    GG := G`MagmaGrp;
    function MakeSubgroups(SubLabels, orig: suffixes := "")
        // SubLabels is a SeqEnum of triples (label, subgroup, index in orig)
        // orig may be a SubGrpLat or a SeqEnum of records
        S := [];
        if Type(suffixes) eq MonStgElt then
            suffixes := [suffixes : _ in SubLabels];
        end if;
        initial := (Type(suffixes) eq MonStgElt and suffixes eq "");
        if initial then
            // These counters allow us to determine the normal/maximal label as we iterate
            // normal subgroups have distinct Gassman classes, so just indexed by index
            normal_counter := AssociativeArray();
            // set of Gassman classes that have shown up in each index
            maximal_gclasses := AssociativeArray();
            // indexed by pairs, index and Gassman class
            maximal_counter := AssociativeArray();
        end if;
        if Type(orig) eq SubGrpLat then
            EltLabel := AssociativeArray();
            for tup in SubLabels do
                // no suffix, since we only use the subgroup lattice
                EltLabel[orig!(tup[3])] := CreateLabel(G`label, tup[1]);
            end for;
        end if;
        for i in [1..#SubLabels] do
            tup := SubLabels[i];
            suffix := suffixes[i];
            H := New(LMFDBSubGrp);
            H`Grp := G;
            H`MagmaAmbient := GG;
            H`MagmaSubGrp := tup[2];
            if #suffix gt 0 then
                H`label := None();
                H`special_labels := [CreateLabel(G`label, tup[1]) * suffix];
            else
                H`label := CreateLabel(G`label, tup[1]);
                H`special_labels:=[];
            end if;
            if Type(orig) eq SubGrpLat then
                elt := orig!(tup[3]);
                top := orig!(#orig);
                H`count := Length(elt);
                H`contains := [EltLabel[j] : j in MaximalSubgroups(elt)];
                H`contained_in := [EltLabel[j] : j in MinimalOvergroups(elt)];
                H`normalizer := EltLabel[Normalizer(top, elt)];
                H`centralizer := EltLabel[Centralizer(top, elt)];
                // breadth first search on overgroups to find normal closure
                seen := {};
                current_layer := {elt};
                while not HasAttribute(H, "normal_closure") do
                    next_layer := {};
                    for cur in current_layer do
                        if Normalizer(top, cur) eq top then
                            H`normal_closure := EltLabel[cur];
                            break;
                        end if;
                        for next in MinimalOvergroups(cur) do
                            Include(~next_layer, next);
                        end for;
                    end for;
                    current_layer := next_layer;
                end while;
            else // SeqEnum of records
                H`count := orig[tup[3]]`length;
                H`contains := None();
                H`contained_in := None();
            end if;
            AssignBasicAttributes(H);
            if initial then
                n := tup[1][1]; // index
                /* Add normal and maximal label to special_labels */
                if H`normal then
                    if not IsDefined(normal_counter, n) then
                        normal_counter[n] := 0;
                    end if;
                    normal_counter[n] +:= 1;
                    nlabel := CreateLabel(G`label, [n, normal_counter[n], 1]) * ".N";
                    Append(~H`special_labels, nlabel);
	        end if;

                if H`maximal then
                    m := tup[1][2];
                    if not IsDefined(maximal_gclasses, n) then
                        maximal_gclasses[n] := {};
                    end if;
                    Include(~(maximal_gclasses[n]), m);
                    if not IsDefined(maximal_counter, <n, m>) then
                        maximal_counter[<n, m>] := 0;
                    end if;
                    maximal_counter[<n, m>] +:= 1;
                    mlabel := CreateLabel(G`label, [n, #maximal_gclasses[n], maximal_counter[<n, m>]]) * ".M";
                    Append(~H`special_labels, mlabel);
	        end if;
            end if;
            Append(~S, H);
        end for;
        return S;
    end function;
    max_index := G`subgroup_index_bound;
    if max_index ne 0 then
        ordbd := Get(G,"order") div max_index;
    end if;
    // Need to include the conjugacy class ordering
    lmfdbcc := ConjugacyClasses(G);
    cccounters := [c`counter : c in lmfdbcc];
    ccreps := [c`representative : c in lmfdbcc];
    ParallelSort(~cccounters, ~ccreps);
    cm:=Get(G, "MagmaClassMap");
    perm := {};
    for j := 1 to #ccreps do
        res:=cm(ccreps[j]);
        Include(~perm, <res, j>);
    end for;
    sset := {j : j in cccounters};
    perm := map<sset->sset | perm>;
    newphi := cm*perm; // Magma does composition backwards!
    if G`subgroup_inclusions_known and max_index eq 0 then
        Orig := SubgroupLattice(GG : Centralizers := true, Normalizers := true);
        RF := recformat< subgroup : Grp, order : Integers() >;
        Subs := [rec< RF | subgroup := Orig[i], order := Order(Orig!i) > : i in [1..#Orig]];
        SubLabels := LabelSubgroups(GG, Subs : phi:=newphi);
    else
        Orig := Subgroups(GG: IndexLimit:=max_index);
        SubLabels:= LabelSubgroups(GG, Orig : phi:=newphi);
    end if;

    S := MakeSubgroups(SubLabels, Orig);
    /* assign the normal beyond index bound */
    all_normal:=G`normal_subgroups_known;
    if max_index ne 0 and all_normal then /* some unlabeled */

        N := NormalSubgroups(GG);

        UnLabeled := [n : n in N | n`order lt ordbd];
        SubLabels := LabelSubgroups(GG, UnLabeled : phi:=newphi);
        S cat:= MakeSubgroups(SubLabels, Orig : suffixes := ".N");
    end if;

    /* assign the maximal beyond index bound */
    all_maximal:=G`maximal_subgroups_known;
    if max_index ne 0 and all_maximal then /* some unlabeled */
        M := MaximalSubgroups(GG);

        UnLabeled := [m : m in M | m`order lt ordbd];
        SubLabels := LabelSubgroups(GG, UnLabeled);
        NewSubLabels := [];
        for tup in SubLabels do
            if all_normal and IsNormal(GG, tup[2]) then  /* need to match up to Normal special label */
                for i in [1..#S] do
                    H := S[i];
                    if not H`normal then continue; end if;
		    if tup[2] eq H`MagmaSubGrp then // normal, so can just use equality

                        mlabel := CreateLabel(G`label, tup[1]) * ".M";
		        Append(~H`special_labels, mlabel);
                        break;
                  end if;
	      end for;
          else
              Append(~NewSubLabels, tup);
           end if;
       end for;
       S cat:= MakeSubgroups(NewSubLabels, Orig : suffixes := ".M");
    end if;

    /* special groups labeled */
    Z := Center(GG);
    D := CommutatorSubgroup(GG);
    F := FittingSubgroup(GG);
    Ph := FrattiniSubgroup(GG);
    R := Radical(GG);
    So := Socle(G);  /* run special routine in case matrix group */

    // Add series
    Un := Reverse(UpperCentralSeries(GG));
    Ln := LowerCentralSeries(GG);
    Dn := DerivedSeries(GG);
    Cn := ChiefSeries(GG);
    SpecialGrps := [<Z,"Z">, <D,"D">, <F,"F">, <Ph,"Phi">, <R,"R">, <So,"S">, <Dn[#Dn],"PC">];
    Series := [<Un,"U">, <Ln,"L">, <Dn,"D">, <Cn,"C">];
    for tup in Series do
        for i in [1..#tup[1]] do
            H := tup[1][i];
            Append(~SpecialGrps, <H, tup[2]*Sprint(i-1)>);
        end for;
    end for;

    /* all of the special groups are normal */
    NewSubLabels := [];
    NewSuffixes := [];
    for tup in SpecialGrps do
        n := G`order div Order(tup[1]);
        found := false;
        // Check if we have the subgroup, and just need to add the special label
        for i in [1..#S] do
            H := S[i];
            if not H`normal then continue; end if;
            if tup[1] eq H`MagmaSubGrp then // normal, so can just use equality
                slabel := CreateLabel(G`label, [tup[2]]);
                Append(~H`special_labels, slabel);
                found := true;
                break;
            end if;
        end for;
        if not found then
            Append(~NewSubLabels, <[], tup[1], 1>);
            Append(~NewSuffixes, "."*tup[2]);
        end if;
    end for;
    S cat:= MakeSubgroups(NewSubLabels, Orig : suffixes := NewSuffixes);

    return S;
end intrinsic;

intrinsic NormalSubgroups(G::LMFDBGrp) -> Any
    {List of normal LMFDBSubGrps, or None if not computed}
    if not G`normal_subgroups_known then
        return None();
    end if;
    return [H : H in Get(G, "Subgroups") | H`normal];
end intrinsic;

intrinsic LowIndexSubgroups(G::LMFDBGrp, d::RngIntElt) -> SeqEnum
    {List of low index LMFDBSubGrps, or None if not computed}
    m := G`subgroup_index_bound;
    if d eq 0 then
        if m eq 0 then
            return Get(G, "Subgroups");
        else
            return None();
        end if;
    end if;
    if m eq 0 or d le m then
        LIS := [];
        ordbd := Get(G, "order") div d;
        for H in Get(G, "Subgroups") do
            if Get(H, "subgroup_order") gt ordbd then
                Append(~LIS, H);
            end if;
        end for;
        return LIS;
    else;
        return None();
    end if;
end intrinsic;

intrinsic LookupSubgroupLabel(G::LMFDBGrp, HH::Any) -> Any
    {Find a subgroup label for H, or return None if H is not labeled}
    if Type(HH) eq MonStgElt then
        // already labeled
        return HH;
    else
        S := Get(G, "Subgroups");
        GG := Get(G, "MagmaGrp");
        for K in S do
            KK := Get(K, "MagmaSubGrp");
            if IsConjugate(GG, HH, KK) then
                v := Get(K, "label");
                if Type(v) eq NoneType then
                    v := Get(K, "special_label")[1];
                end if;
                return v;
            end if;
        end for;
        return None();
    end if;
end intrinsic;

intrinsic LookupSubgroup(G::LMFDBGrp, label::MonStgElt) -> Grp
{Find a subgroup with a given label}
    S := Get(G, "Subgroups");
    for K in S do
        if label eq Get(K, "label") or label in Get(K, "special_labels") then
            return Get(K, "MagmaSubGrp");
        end if;
    end for;
    error Sprintf("Subgroup with label %o not found", label);
end intrinsic;

intrinsic order_stats(G::LMFDBGrp) -> Any
    {returns the list of pairs [o, m] where m is the number of elements of order o}
    GG := G`MagmaGrp;
    A := AssociativeArray();
    C := Classes(GG);
    for c in C do
        if not IsDefined(A, c[1]) then
            A[c[1]] := 0;
        end if;
        A[c[1]] +:= c[2];
    end for;
    return [[k, v] : k -> v in A];
end intrinsic;

intrinsic semidirect_product(G::LMFDBGrp : direct := false) -> Any
  {Returns true if G is a nontrivial semidirect product; otherwise returns false.}
  GG := Get(G, "MagmaGrp");
  ordG := Get(G, "order");
  Ns := Get(G, "NormalSubgroups");
  if Type(Ns) eq NoneType then return None(); end if;
  Remove(~Ns,#Ns); // remove full group;
  Remove(~Ns,1); // remove trivial group;
  if direct then
    Ks := Ns;
  else // semidirect
    Ks := Get(G, "Subgroups");
  end if;
  for N in Ns do
    NN := Get(N, "MagmaSubGrp");
    comps := [el : el in Ks | Get(el, "subgroup_order") eq (ordG div Get(N, "subgroup_order"))];
    for K in comps do
      KK := Get(K, "MagmaSubGrp");
      if #(NN meet KK) eq 1 then
        return true;
        //print N, K;
      end if;
    end for;
  end for;
  return false;
end intrinsic;

intrinsic direct_product(G::LMFDBGrp) -> Any
  {Returns true if G is a nontrivial direct product; otherwise returns false.}
  return semidirect_product(G : direct := true);
end intrinsic;

intrinsic CCpermutation(G::LMFDBGrp) -> SeqEnum
  {Get the permutation p which takes Magma's CC indeces and returns ours.}
   ccs:=Get(G, "ConjugacyClasses");
   return G`CCpermutation; // Set as a side effect
end intrinsic;

intrinsic CCpermutationInv(G::LMFDBGrp) -> SeqEnum
  {Get the permutation p which takes our CC index and returns Magma's.}
   ccs:=Get(G, "ConjugacyClasses");
   return G`CCpermutationInv; // Set as a side effect
end intrinsic;

intrinsic ConjugacyClasses(G::LMFDBGrp) ->  SeqEnum
  {The list of conjugacy classes for this group}
  g:=G`MagmaGrp;
  cc:=Get(G, "MagmaConjugacyClasses");
  cm:=Get(G, "MagmaClassMap");
  pm:=Get(G, "MagmaPowerMap");
  gens:=Get(G, "MagmaGenerators");
  ordercc, _, labels := ordercc(g,cc,cm,pm,gens);
  // perm will convert given index to the one out of ordercc
  // perm2 is its inverse
  perm := [0 : j in [1..#cc]];
  perminv := [0 : j in [1..#cc]];
  for j:=1 to #cc do
    perm[cm(ordercc[j])] := j;
    perminv[j] := cm(ordercc[j]);
  end for;
  G`CCpermutation:=perm;
  G`CCpermutationInv:=perminv;
  magccs:=[ New(LMFDBGrpConjCls) : j in cc];
  gord:=Order(g);
  plist:=[z[1] : z in Factorization(gord)];
  //gord:=Get(G, 'Order');
  for j:=1 to #cc do
    ix:=perm[j];
    magccs[j]`Grp := G;
    magccs[j]`MagmaConjCls := cc[ix];
    magccs[j]`label := labels[j];
    magccs[j]`size := cc[ix][2];
    magccs[j]`counter := j;
    magccs[j]`order := cc[ix][1];
    // Not sure of which other powers are desired
    magccs[j]`powers := [perm[pm(ix,p)] : p in plist];
    magccs[j]`representative := cc[ix][3];
  end for;
  return magccs;
end intrinsic;

intrinsic FrobeniusSchur(ch::Any) -> Any
  {Frobenius Schur indicator of a Magma character}
  assert IsIrreducible(ch);
  if IsOrthogonalCharacter(ch) then
    return 1;
  elif IsSymplecticCharacter(ch) then
    return -1;
  end if;
  return 0;
end intrinsic;

intrinsic Characters(G::LMFDBGrp) ->  Tup
  {Initialize characters of an LMFDB group and return a list of complex characters and a list of rational characters}
  g:=G`MagmaGrp;
  ct:=Get(G,"MagmaCharacterTable");
  rct:=Get(G,"MagmaRationalCharacterTable");
  matching:=Get(G,"MagmaCharacterMatching");
  //cc:=Classes(g);
  cchars:=[New(LMFDBGrpChtrCC) : c in ct];
  rchars:=[New(LMFDBGrpChtrQQ) : c in rct];
  for j:=1 to #cchars do
    cchars[j]`Grp:=G;
    cchars[j]`MagmaChtr:=cchars[j];
    cchars[j]`dim:=Degree(ct[j]);
    rchars[j]`MagmaChtr:=rchars[j];
    cchars[j]`faithful:=IsFaithful(ct[j]);
    //cchars[j]`indicator:=FrobeniusSchur(ct[j]); // Not in schema, but should be?
    cchars[j]`label:="placeholder";
  end for;
  for j:=1 to #rchars do
    rchars[j]`Grp:=G; // These don't have a group?
    rchars[j]`MagmaChtr:=rchars[j];
    rchars[j]`schur_index:=SchurIndex(ct[matching[j][1]]);
    rchars[j]`multiplicity:=#matching[j];
    rchars[j]`qdim:=Integers()! Degree(rct[j]);
    rchars[j]`cdim:=(Integers()! Degree(rct[j])) div #matching[j];
    // Character may not be irreducible, so value might not be in 1,0,-1
    rchars[j]`indicator:=FrobeniusSchur(ct[matching[j][1]])*rchars[j]`multiplicity;
    rchars[j]`label:="placeholder";
  end for;
  /* This still needs labels and ordering for both types */
  sortdata:=characters_add_sort_and_labels(G, cchars, rchars);

  return <cchars, rchars>;
end intrinsic;

intrinsic central_product(G::LMFDBGrp) -> BoolElt
    {Checks if the group G is a central product.}
    GG := G`MagmaGrp;
    if Get(G, "abelian") then
        /* G abelian will not be a central product <=> it is cyclic of prime power order (including trivial group).*/
        if not (Get(G, "cyclic") and #factors_of_order(G) in {0,1}) then /* changed FactoredOrder(GG) by factors_of_order(G).*/
            return true;
        end if;
    else
        /* G is not abelian. We run through the proper nontrivial normal subgroups N and consider whethe$
the centralizer C = C_G(N) together with N form a central product decomposition for G. We skip over N wh$
central (C = G) since if a complement C' properly contained in C = G exists, then it cannot also be cent$
is not abelian. Since C' must itself be normal (NC' = G), we will encounter C' (with centralizer smaller$
somewhere else in the loop. */

        normal_list := Get(G, "NormalSubgroups");
        for ent in normal_list do
            N := ent`MagmaSubGrp;
            if (#N gt 1) and (#N lt #GG) then
                C := Centralizer(GG,N);
                if (#C lt #GG) then  /* C is a proper subgroup of G. */
                    C_meet_N := C meet N;
                    // |CN| = |C||N|/|C_meet_N|. We check if |CN| = |G| and return true if so.
                    if #C*#N eq #C_meet_N*#GG then
                        return true;
                    end if;
                end if;
            end if;
        end for;
    end if;
    return false;
end intrinsic;

intrinsic schur_multiplier(G::LMFDBGrp) -> Any
  {Returns abelian invariants for Schur multiplier by computing prime compoments and then merging them.}
  invs := [];
  ps := factors_of_order(G);
  GG := Get(G, "MagmaGrp"); 
  // Need GrpPerm for pMultiplicator function calls below. Check and convert if not GrpPerm.
  if Type(GG) ne GrpPerm then
       // We find an efficient permutation representation. 
       ts:=Get(G, "MagmaTransitiveSubgroup");
       GG:=CosetImage(GG,ts); 
  end if;
  for p in ps do 
    for el in pMultiplicator(GG,p) do 
      if el gt 1 then
        Append(~invs, el);
      end if;
    end for;
  end for;
  return AbelianInvariants(AbelianGroup(invs));
end intrinsic;


intrinsic wreath_product(G::LMFDBGrp) -> Any
  {Returns true if G is a wreath product; otherwise returns false.}
  GG := Get(G, "MagmaGrp");
  // Need GrpPerm for IsWreathProduct function call below. Check and convert if not GrpPerm.
  if Type(GG) ne GrpPerm then
       // We find an efficient permutation representation. 
       ts:=Get(G, "MagmaTransitiveSubgroup");
       GG:=CosetImage(GG,ts); 
  end if;
  return IsWreathProduct(GG);
end intrinsic;


intrinsic old_label(G::LMFDBGrp) -> Any
    {Currently just returns None, since this is used when we compute labels all groups of a given order where we didn't have a label before}
    return None();
end intrinsic;
