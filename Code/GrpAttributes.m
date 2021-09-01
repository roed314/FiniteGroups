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
  szs := Get(G, "MagmaCharacterMatching");
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
    if Get(G, "order") eq 1 then
        return g;
    end if;
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

intrinsic Generators(G::LMFDBGrp) -> Any
    {Returns the chosen generators of the underlying group}
    ert := Get(G, "elt_rep_type");
    if ert eq 0 then
        print "inside Generators(G)";
        gu := Get(G, "gens_used");
        gens := SetToSequence(PCGenerators(G`MagmaGrp));
        if Type(gu) ne NoneType then
            gens := [gens[i] : i in gu];
        end if;
        return gens;
    end if;
    return SetToSequence(Generators(G`MagmaGrp));
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
    faith:= Get(G, "faithful_reps");
    if #faith gt 0 then
      return faith[1][1];
    else
      return 0;
    end if;
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
  if Get(G, "abelian") then
    return 0; // the identity is an empty product
  end if;
  g:=G`MagmaGrp;
  ct := Get(G, "MagmaCharacterTable");
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
        print "aut_group", e;
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
    // We're getting errors when the outer group is too large to construct a regular representation
    // TODO: This should be changed as we start to label larger groups
    if not CanIdentifyGroup(Get(G, "outer_order")) then
        return None();
    end if;
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

intrinsic SemidirectFactorization(G::LMFDBGrp : direct := false) -> Any, Any, Any
  {Returns true if G is a nontrivial semidirect product, along with factors; otherwise returns false.}
  GG := Get(G, "MagmaGrp");
  ordG := Get(G, "order");
  // deal with trivial group
  if ordG eq 1 then
    return false, _, _;
  end if;
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
        return true, N, K;
        //print N, K;
      end if;
    end for;
  end for;
  return false, _, _;
end intrinsic;

intrinsic DirectFactorization(G::LMFDBGrp) -> Any
  {Returns true if G is a nontrivial direct product, along with factors; otherwise returns false.}
  return SemidirectFactorization(G : direct := true);
end intrinsic;

intrinsic semidirect_product(G::LMFDBGrp) -> Any
  {Returns true if G is a nontrivial semidirect product; otherwise returns false.}
  fact_bool, _, _ := SemidirectFactorization(G);
  return fact_bool;
end intrinsic;

intrinsic direct_product(G::LMFDBGrp) -> Any
  {Returns true if G is a nontrivial direct product; otherwise returns false.}
  fact_bool, _, _ := DirectFactorization(G);
  return fact_bool;
end intrinsic;

intrinsic direct_factorization(G::LMFDBGrp) -> SeqEnum
  {}
  fact_bool, Nsub, Ksub := DirectFactorization(G);
  if not fact_bool then
    return [];
  end if;
  N := LabelToLMFDBGrp(Get(Nsub, "subgroup"));
  K := LabelToLMFDBGrp(Get(Ksub, "subgroup"));
  facts := [N,K];
  irred_facts := [];
  all_irred := false;
  while not all_irred do
    new_facts :=[];
    for fact in facts do
      split_bool, Nisub, Kisub := DirectFactorization(fact);
      if not split_bool then
        Append(~irred_facts, fact);
      else
        Ni := LabelToLMFDBGrp(Get(Nisub, "subgroup"));
        Ki := LabelToLMFDBGrp(Get(Kisub, "subgroup"));
        new_facts cat:= [Ni,Ki];
      end if;
    end for;
    if #new_facts eq 0 then
      all_irred := true;
    end if;
    facts := new_facts;
  end while;
  // check that they're really isomorphic
  GG := Get(G, "MagmaGrp");
  // The factors might not be in the same magma "universe" e.g., for 120.35
  // Can't have a SeqEnum of these, so you can't take apply DirectProduct
  //irred_facts_mag := [ Get(el, "MagmaGrp") : el in irred_facts ];
  //assert IsIsomorphic(GG, DirectProduct(irred_facts_mag));

  return CollectDirectFactors(irred_facts);
end intrinsic;

intrinsic CollectDirectFactors(facts::SeqEnum) -> SeqEnum
  {Group together factors in direct product, returning a sequence of pairs <label, exponent>}
  pairs := [];
  for fact in facts do
    label := Get(fact, "label");
    old_bool := false;
    for i := 1 to #pairs do
      if label eq pairs[i][1] then
        fact_ind := i;
        old_bool := true;
      end if;
    end for;
    if old_bool then
      pairs[fact_ind][2] +:= 1;
    else
      // tuples are sortable while sequences [* *] are not
      Append(~pairs, <Get(fact, "label"), 1>);
    end if;
  end for;
  Sort(~pairs);
  return pairs;
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

intrinsic MagmaPowerMap(G::LMFDBGrp) -> Any
  {Return Magma's powermap.}
  return PowerMap(G`MagmaGrp);
end intrinsic;

intrinsic MagmaClassMap(G::LMFDBGrp) -> Any
  {Return Magma's ClassMap.}
  return ClassMap(G`MagmaGrp);
end intrinsic;

intrinsic MagmaConjugacyClasses(G::LMFDBGrp) -> Any
  {Return Magma's Conjugacy classes.}
  return ConjugacyClasses(G`MagmaGrp);
end intrinsic;

intrinsic MagmaGenerators(G::LMFDBGrp) -> Any
  {Like magma command GeneratorsSequence, but works for small groups too.
   It should change to use our recorded generators.}
  return SetToSequence(Generators(G`MagmaGrp));
  /* Note: the following code doesn't work or PC groups
   * > g := G`MagmaGrp;
   * > return [g.j : j in [1..NumberOfGenerators(g)]]
   * as G.i is i-th polycyclic generator for G
   * thus one is not guaranteed to get all generators, e.g:
   * > G`MagmaGrp := SmallGroupDecoding(292129084436, 64);
   * > Generators(G`MagmaGrp);
   * { $.1, $.2, $.3, $.5 }
   */
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

intrinsic MagmaCharacterTable(G::LMFDBGrp) -> Any
  {Return Magma's character table.}
  return CharacterTable(G`MagmaGrp);
end intrinsic;

intrinsic MagmaCharacterMatching(G::LMFDBGrp) -> Any
  {Return the list of list showing which complex characters go with each rational character.}
  u:=Get(G,"MagmaRationalCharacterTable");
  return G`MagmaCharacterMatching; // Set as side effect
end intrinsic;


intrinsic MagmaRationalCharacterTable(G::LMFDBGrp) -> Any
  {Return Magma's rational character table.}
  u,v:= RationalCharacterTable(G`MagmaGrp);
  G`MagmaCharacterMatching:=v;
  return u;
end intrinsic;

intrinsic complexconjindex(ct::Any, gorb::Any, achar::Any) -> Any
  {Find the complex conj of achar among indeces in gorb all from
   character table ct (which is now a list of lists).}
  findme:=[ComplexConjugate(achar[z]) : z in [1..#achar]];
  gorbvals:=[ct[z] : z in gorb];
  myind:= Index(gorbvals, findme);
  return gorb[myind];
end intrinsic;

intrinsic QQCharacters(G::LMFDBGrp) -> Any
  { Compute and return Q characters }
  dummy := Get(G, "Characters");
  return G`QQCharacters;
end intrinsic;

intrinsic CCCharacters(G::LMFDBGrp) -> Any
  { Compute and return Q characters }
  dummy := Get(G, "Characters");
  return G`CCCharacters;
end intrinsic;

declare type CyclotomicCache;
declare attributes CyclotomicCache:
    cache;

cyc_cache := New(CyclotomicCache);
cyc_cache`cache := AssociativeArray();
// Get the global cyc_cache
intrinsic CycEltCache(G::LMFDBGrp) -> AssociativeArray
{}
    return cyc_cache;
end intrinsic;


intrinsic characters_add_sort_and_labels(G::LMFDBGrp, cchars::Any, rchars::Any) -> Any
  {Order characters and make labels for them.  This does complex and rational
   characters together since the ordering and labelling are connected.}
  g:=G`MagmaGrp;
  ct:=Get(G,"MagmaCharacterTable");
  rct:=Get(G,"MagmaRationalCharacterTable");
  matching:=Get(G,"MagmaCharacterMatching");
  perm:=Get(G, "CCpermutationInv"); // perm[j] is the a Magma index
  glabel:=Get(G, "label");
  // Need outer sort for rct, and then an inner sort for ct
  goodsubs:=getgoodsubs(g, ct); // gives <subs, tvals>
  ntlist:= goodsubs[2];
  // Need the list which takes complex chars and gives index of rational char
  comp2rat:=[0 : z in ct];
  for j:=1 to #matching do
    for k:=1 to #matching[j] do
      comp2rat[matching[j][k]]:=j;
    end for;
  end for;
  // Want sort list to be <degree, size of Gal orbit, n, t, lex info, ...>
  // We give rational character values first, then complex
  // Priorities by lex sort
  forlexsortrat:=<<rct[comp2rat[j]][perm[k]] : k in [1..#ct]> : j in [1..#ct]>;
  forlexsort:=<Flat(<<Round(10^25*Real(ct[j,perm[k]])), Round(10^25*Imaginary(ct[j,perm[k]]))> : k in [1..#ct]>) : j in [1..#ct]>;
//"forlexsortrat";
//forlexsortrat;
//"forlexsort";
//forlexsort;
  // We add three fields at the end. The last is old index, before sorting.
  // Before that is the old index in the rational table
  // Before that is the old index of its complex conjugate
  sortme:=<<Degree(ct[j]), #matching[comp2rat[j]], ntlist[j][1], ntlist[j][2]> cat forlexsortrat[j]
     cat forlexsort[j] cat <0,0,0> : j in [1..#ct]>;
//"sortme";
//sortme;
//"done";
  len:=#sortme[1];
  for j:=1 to #ct do
    sortme[j][len] := j;
  end for;
  allvals := [[ct[j][k] : k in [1..#ct]] : j in [1..#ct]];
  for j:=1 to #matching do
    for k:=1 to #matching[j] do
      sortme[matching[j][k]][len-1] := j;
      sortme[matching[j][k]][len-2]:= complexconjindex(allvals, matching[j], ct[matching[j][k]]);
    end for;
  end for;
  sortme:= [[a : a in b] : b in sortme];
  Sort(~sortme);
//"did it";
//sortme;
  // Now step through to figure out the order
  donec:={};
  doneq:={};
  olddim:=-1;
  rcnt:=0;
  rtotalcnt:=0;
  ccnt:=0;
  ctotalcnt:=0;
  for j:=1 to #sortme do
    dat:=sortme[j];
    if dat[1] ne olddim then
      olddim := dat[1];
      rcnt:=0;
      ccnt:=0;
    end if;
    if dat[len] notin donec then // New C character
      if dat[len-1] notin doneq then // New Q character
        rcnt+:=1;
        ccnt:=0;
        rtotalcnt+:=1;
        rcode:=num2letters(rcnt: Case:="lower");
        Include(~doneq, dat[len-1]);
        rindex:=Integers()!dat[len-1];
        rchars[rindex]`counter :=rtotalcnt;
        rchars[rindex]`label:=Sprintf("%o.%o%o",glabel,dat[1],rcode);
        rchars[rindex]`nt:=[dat[3],dat[2]];
        rchars[rindex]`qvalues:=[Integers()! dat[j+4] : j in [1..#ct]];
      end if;
      ccnt+:=1;
      ctotalcnt+:=1;
      Include(~donec, dat[len]);
      cindex:=Integers()!dat[len];
      cchars[cindex]`counter:=ctotalcnt;
      cchars[cindex]`nt:=[dat[3],dat[2]];
      cextra:= (dat[2] eq 1) select "" else Sprintf("%o", ccnt);
      cchars[cindex]`label:=Sprintf("%o.%o%o", glabel, dat[1],rcode)*cextra;
      // Encode values
      thischar:=ct[cindex];
      basef:=BaseRing(thischar);
      cyclon:=CyclotomicOrder(basef);
      Kn:=CyclotomicField(cyclon);
      cchars[cindex]`cyclotomic_n:=cyclon;
      //cchars[cindex]`values:=[PrintRelExtElement(Kn!thischar[perm[z]]) : z in [1..#thischar]];
      cchars[cindex]`values:=[WriteCyclotomicElement(Kn!thischar[perm[z]],cyclon,cyc_cache) : z in [1..#thischar]];
      if dat[len-2] notin donec then
        ccnt+:=1;
        ctotalcnt+:=1;
        cindex:=Integers()!dat[len-2];
        Include(~donec, dat[len-2]);
        cchars[cindex]`counter:=ctotalcnt;
        cchars[cindex]`nt:=[dat[3],dat[2]];
        cextra:= (dat[2] eq 1) select "" else Sprintf("%o", ccnt);
        cchars[cindex]`label:=Sprintf("%o.%o%o", glabel, dat[1],rcode)*cextra;
        thischar:=ct[cindex];
        basef:=BaseRing(thischar);
        cyclon:=CyclotomicOrder(basef);
        Kn:=CyclotomicField(cyclon);
        cchars[cindex]`cyclotomic_n:=cyclon;
        cchars[cindex]`values:=[WriteCyclotomicElement(Kn!thischar[perm[z]], cyclon, cyc_cache) : z in [1..#thischar]];
      end if;
    end if;
  end for;
  cntlist:=[z`counter : z in rchars];
  ParallelSort(~cntlist,~rchars);
  G`QQCharacters := rchars;
  cntlist:=[z`counter : z in cchars];
  ParallelSort(~cntlist, ~cchars);
  G`CCCharacters := cchars;
  return <cchars, rchars>;
end intrinsic;


intrinsic Characters(G::LMFDBGrp) ->  Tup
  {Initialize characters of an LMFDB group and return a list of complex characters and a list of rational characters}
  t := Cputime();
  g:=G`MagmaGrp;
  ct:=Get(G,"MagmaCharacterTable");
  rct:=Get(G,"MagmaRationalCharacterTable");
  matching:=Get(G,"MagmaCharacterMatching");
  R<x>:=PolynomialRing(Rationals());
  polredabscache:=LoadPolredabsCache();
  //cc:=Classes(g);
  cchars:=[New(LMFDBGrpChtrCC) : c in ct];
  rchars:=[New(LMFDBGrpChtrQQ) : c in rct];
  vprint User2: "A", t;
  t := Cputime(t);
  for j:=1 to #cchars do
    cchars[j]`Grp:=G;
    cchars[j]`MagmaChtr:=ct[j];
    cchars[j]`dim:= Integers() ! Degree(ct[j]);
    cchars[j]`faithful:=IsFaithful(ct[j]);
    cchars[j]`group:=Get(G,"label");
    thepoly:=DefiningPolynomial(CharacterField(ct[j]));
    // Sometimes the type is Cyclotomic field, in which case thepoly is a different type
    if Type(thepoly) eq SeqEnum then thepoly:=thepoly[1]; end if;
    if not IsDefined(polredabscache,thepoly) then
      thepoly1:=Polredabs(thepoly);
      polredabscache[thepoly] := thepoly1;
      PolredabsCache(thepoly, thepoly1);
    end if;
    thepoly:=polredabscache[thepoly];
    cchars[j]`field:=Coefficients(thepoly);
    cchars[j]`Image_object:=New(LMFDBRepCC);
    cchars[j]`indicator:=FrobeniusSchur(ct[j]);
    cchars[j]`label:="placeholder";
    vprint User2: "B", j, t;
    t := Cputime(t);
  end for;
  for j:=1 to #rchars do
    rchars[j]`Grp:=G; // These don't have a group?
    //rchars[j]`MagmaChtr:=ct[matching[j][1]];
    rchars[j]`MagmaChtr:=rct[j];
    rchars[j]`group:=Get(G,"label");
    rchars[j]`schur_index:=SchurIndex(ct[matching[j][1]]);
    rchars[j]`multiplicity:=#matching[j];
    rchars[j]`qdim:=Integers()! Degree(rct[j]);
    rchars[j]`cdim:=(Integers()! Degree(rct[j])) div #matching[j];
    rchars[j]`Image_object:=New(LMFDBRepQQ);
    rchars[j]`faithful:=IsFaithful(rct[j]);
    // Character may not be irreducible, so value might not be in 1,0,-1
    rchars[j]`label:="placeholder";
    vprint User2: "C", j, t;
    t := Cputime(t);
  end for;
  /* This still needs labels and ordering for both types */
  sortdata:=characters_add_sort_and_labels(G, cchars, rchars);

  return <cchars, rchars>;
end intrinsic;

intrinsic name(G::LMFDBGrp) -> Any
  {Returns Magma's name for the group.}
  g:=G`MagmaGrp;
  return GroupName(g);
end intrinsic;

intrinsic tex_name(G::LMFDBGrp) -> Any
  {Returns Magma's name for the group.}
  g:=G`MagmaGrp;
  gn:= GroupName(g: TeX:=true);
  return ReplaceString(gn, "\\", "\\\\");
end intrinsic;

intrinsic Socle(G::LMFDBGrp) -> Any
  {Returns the socle of a group.}
  g:=G`MagmaGrp;
  try
    s:=Socle(g);
    return s;
  catch e  ;
  end try;
  nl:=NormalLattice(g);
  mins:=[z : z in MinimalOvergroups(Bottom(nl))];
  spot:= IntegerRing() ! mins[#mins];
  // Can't believe there is no support of join of subgroups
  while spot le #nl do
    fail := false;
    for j:=1 to #mins do
      if not ((nl ! spot) ge (nl ! mins[j])) then
        fail:=true;
        break;
      end if;
    end for;
    if fail then spot +:= 1; else break; end if;
  end while;
  assert spot le #nl;
  return nl! spot;
end intrinsic;

intrinsic coset_action_label(H::LMFDBSubGrp) -> Any
  {Determine the transitive classification for G/H}
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  if Order(Core(GG,HH)) eq 1 then
    if Index(GG,HH) gt 47 then
      return None();
    end if;
    ca:=CosetImage(GG,HH);
    t,n:=TransitiveGroupIdentification(ca);
    return Sprintf("%oT%o", n, t);
  else
    return None();
  end if;
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


intrinsic counter(G::LMFDBGrp) -> RngIntElt
{Second entry in label}
   lab:= Get(G,"label");
   spl:=Split(lab,".");
   return eval spl[2];
end intrinsic;

intrinsic elt_rep_type(G:LMFDBGrp) -> Any
    {type of an element of the group}
    if Type(G`MagmaGrp) eq GrpPC then
        return 0;
    elif Type(G`MagmaGrp) eq GrpPerm then
      deg:=Get(G,"transitive_degree");
      return -deg;
      /* return -Degree(G`MagmaGrp);  */
    elif Type(G`MagmaGrp) eq GrpMat then
        R := CoefficientRing(G);
        if R eq Integers() then
            return 1;
        elif Type(R) eq FldFin then
            return #R;
        else
            error Sprintf("Unsupported ring %o", R);
        end if;
    else
        error Sprintf("Unsupported group type %o", Type(G`MagmaGrp));
    end if;
end intrinsic;

/* should be improved when matrix groups are added */
intrinsic finite_matrix_group(G:LMFDBGrp)-> Any
{determines whether finite matrix group}
  return None();
end intrinsic;

/* placeholder for when larger groups get added */
intrinsic old_label(G:LMFDBGrp)-> Any
{graveyard for labels when they are no longer needed. Currently just returns None, since this is used when we compute labels all groups of a given order where we did not have a label before}
  return None();
end intrinsic;


/* From DR.m */
cycquos := function(L, h)
    H := Group(h);
    D := DerivedSubgroup(H);
    A, fA := quo<H | D>; // Can maybe make this more efficient by switching to GrpAb and using Dual
    n := Order(A);
    ans := {};
    for B in Subgroups(A) do
        if B`order eq n then
            continue;
        end if;
        Bsub := B`subgroup;
        if IsCyclic(A / Bsub) then
            Include(~ans, L!(Bsub@@fA));
        end if;
    end for;
    return ans;
end function;

all_minimal_chains := function(G, L)
    assert IsSolvable(G);
    cycdist := AssociativeArray();
    top := L!(#L);
    bottom := L!1;
    cycdist[top] := 0;
    reverse_path := AssociativeArray();
    cqsubs := AssociativeArray();
    Seen := {top};
    Layer := {top};
    while true do
        NewLayer := {};
        for h in Layer do
            cq := cycquos(L, h);
            cqsubs[h] := cq;
            for x in cq do
                if not IsDefined(cycdist, x) or cycdist[x] gt cycdist[h] + 1 then
                    cycdist[x] := cycdist[h] + 1;
                    reverse_path[x] := {h};
                elif cycdist[x] eq cycdist[h] + 1 then
                    Include(~(reverse_path[x]), h);
                end if;
                if not (x in Seen) then
                    Include(~NewLayer, x);
                    Include(~Seen, x);
                end if;
            end for;
        end for;
        Layer := NewLayer;
        if (bottom in Layer) or (#Layer eq 0) then
            break;
        end if;
    end while;
    M := cycdist[bottom];
    chains := [[bottom]];
    /* The following was brainstorming that I don't think works yet....

       For now, we just use centralizers of already chosen elements.
       At each step (while adding a subgroup H above a subgroup J),
       compute the normalizer N of H and the orbits for the action of N on H.
       Similarly, the normalizer M of J and the orbits for the action of M on J.
       Those of J map to those of H, and places where the count increase
       are possible conjugacy classes from which we can choose a generator.
       We aim for those where the size of the conjugacy class is small,
       since that will yield a large centralizer with lots of commuting relations.
    */
    for i in [1..M] do
        new_chains := [];
        for chain in chains do
            for x in reverse_path[chain[i]] do
                Append(~new_chains, Append(chain, x));
            end for;
        end for;
        chains := new_chains;
    end for;
    return chains;
end function;


chain_to_gens := function(chain)
    ans := [];
    G := Group(chain[#chain]);
    A := Group(chain[1]);
    for i in [2..#chain] do
        B := Group(chain[i]);
        r := #B div #A;
        if not (A subset B and IsCyclic(quo<B | A>)) then
            // have to conjugate
            N := Normalizer(G, B);
            T := Transversal(G, N);
            for t in T do
                Bt := B^t;
                if A subset Bt then
                    Q, fQ := quo<Bt | A>;
                    if IsCyclic(Q) then
                        B := Bt;
                        break;
                    end if;
                end if;
            end for;
        else
            Q, fQ := quo<B | A>;
        end if;
        C, fC := AbelianGroup(Q);
        g := G!((C.1@@fC)@@fQ);
        Append(~ans, <g, r, B>);
        A := B;
    end for;
    return ans;
end function;

intrinsic RePresentLat(G::LMFDBGrp, L::SubGrpLat)
    {}
    GG := G`MagmaGrp;
    chains := all_minimal_chains(GG, L);
    gens := [chain_to_gens(chain) : chain in chains];
    //print "#gensA", #gens;
    // Figure out which gives the "best" presentation.  Desired features:
    // * raising each generator to its relative order gives the identity
    // * fewer conjugacy relations
    // * relative orders are non-increasing
    // * RHS of conjugacy relations are "deeper"
    if Get(G, "order") eq 1 then
      G`MagmaOptimized := GG;
      G`OptimizedIso := IdentityHomomorphism(GG);
      G`gens_used := [];
    else
      relcnt := AssociativeArray();
      for i in [1..#gens] do
          c := 0;
          for tup in gens[i] do
              if IsIdentity(tup[1]^tup[2]) then
                  c +:= 1;
              end if;
          end for;
          if not IsDefined(relcnt, c) then relcnt[c] := []; end if;
          Append(~relcnt[c], i);
      end for;
      // Only keep chains with the maximum number of identity relative powers
      gens := [gens[i] : i in relcnt[Max(Keys(relcnt))]];
      //print "#gensB", #gens;

      commut := AssociativeArray();
      for i in [1..#gens] do
          c := 0;
          for a in [1..#gens[i]] do
              for b in [a+1..#gens[i]] do
                  g := gens[i][a][1];
                  h := gens[i][b][1];
                  if IsIdentity(g*h*g^-1*h^-1) then
                      c +:= 1;
                  end if;
              end for;
          end for;
          if not IsDefined(commut, c) then commut[c] := []; end if;
          Append(~commut[c], i);
      end for;
      // Only keep chains that have the most commuting pairs of generators
      gens := [gens[i] : i in commut[Max(Keys(commut))]];
      //print "#gensC", #gens;

      ooo := AssociativeArray();
      for i in [1..#gens] do
          c := 0;
          for a in [1..#gens[i]] do
              for b in [a+1..#gens[i]] do
                  r := gens[i][a][2];
                  s := gens[i][b][2];
                  if r lt s then
                      c +:= 1;
                  end if;
              end for;
          end for;
          if not IsDefined(ooo, c) then ooo[c] := []; end if;
          Append(~ooo[c], i);
      end for;
      // Only keep chains that have the minimal number of out-of-order relative orders
      gens := [gens[i] : i in ooo[Min(Keys(ooo))]];
      //print "#gensD", #gens;

      total_depth := AssociativeArray();
      for i in [1..#gens] do
          c := 0;
          for a in [1..#gens[i]] do
              for b in [a+1..#gens[i]] do
                  g := gens[i][a][1];
                  h := gens[i][b][1];
                  com := g*h*g^-1*h^-1;
                  if not IsIdentity(com) then
                      for j in [b-2..1 by -1] do
                          if not com in gens[i][j][3] then
                              c +:= j;
                          end if;
                      end for;
                  end if;
              end for;
          end for;
          if not IsDefined(total_depth, c) then total_depth[c] := []; end if;
          Append(~total_depth[c], i);
      end for;
      // Only keep chains that have the minimal total depth
      gens := [gens[i] : i in total_depth[Min(Keys(total_depth))]];
      //print "#gensE", #gens;

      orders := [[tup[2] : tup in chain] : chain in gens];
      ParallelSort(~orders, ~gens);

      // We can't feasibly make this deterministic, and we don't have any more ideas for
      // picking a "better" presentation, so we now just take the last one,
      // which has the largest relative order for the first generator (and so on)

      best := gens[#gens];
      //print "best", [<tup[1], tup[2], #tup[3]> : tup in best];

      // Now we build a new PC group with an isomorphism to our given one.
      // We have to fill in powers of our chosen generators since magma wants prime relative orders
      // We keep track of which generators are actually needed; other generators are powers of these
      filled := [];
      H := sub<GG|>;
      gens_used := [];
      used_tracker := -1;
      for tup in best do
          g := tup[1];
          r := tup[2];
          segment := [];
          for pe in Factorization(r) do
              p := pe[1]; e := pe[2];
              for i in [1..e] do
                  Append(~segment, <g, p, sub<GG| H, g>>);
                  g := g^p;
              end for;
          end for;
          used_tracker +:= #segment;
          Append(~gens_used, used_tracker);
          filled cat:= Reverse(segment);
          H := tup[3];
      end for;
      // Magma has a descending filtration, so we switch to that here.
      Reverse(~filled);
      gens_used := [#filled - i : i in gens_used];
      //print "filled", [<tup[1], tup[2], #tup[3]> : tup in filled];
      F := FreeGroup(#filled);
      rels := {};
      one := Identity(F);
      gens := [filled[i][1] : i in [1..#filled]];
      function translate_to_F(x, depth)
          fvec := one;
          for k in [depth..#filled] do
              //print "k", k;
              // For the groups we're working with, the primes involved are small, so we just do a super-naive discrete log
              if k eq #filled then
                  Filt := [Identity(GG)];
              else
                  Filt := filled[k+1][3];
              end if;
              //print x, Filt;
              while not x in Filt do
                  x := gens[k]^-1 * x;
                  fvec := fvec * F.k;
              end while;
          end for;
          return fvec;
      end function;

      //print "Allrels";
      //for i in [1..#filled] do
      //    for j in [i+1..#filled] do
      //        print "i,j,gj^gi", i, j, gens[j]^gens[i];
      //    end for;
      //end for;
      for i in [1..#filled] do
          //print "i", i;
          p := filled[i][2];
          Include(~rels, F.i^p = translate_to_F(gens[i]^p, i+1));
          for j in [i+1..#filled] do
              //print "j", j;
              fvec := translate_to_F(gens[j]^gens[i], i+1);
              if fvec ne F.j then
                  Include(~rels, F.j^F.i = fvec);
              end if;
          end for;
      end for;
      //print "rels", rels;
      H := quo< GrpPC : F | rels >;
      f := hom< H -> G`MagmaGrp | gens >;
      G`MagmaOptimized := H;
      G`OptimizedIso := f^-1;
      G`gens_used := gens_used;
    end if;
end intrinsic;

intrinsic RePresent(G::LMFDBGrp)
    {}
    // Without the lattice, we can't find an optimal presentation, but we can use the derived series to get something reasonable.
    GG := G`MagmaGrp;
    // TODO: leaving this for later since we're initially computing the lattice for all groups
end intrinsic;


intrinsic pc_code(G::LMFDBGrp) -> RngInt
    {This should be updated to give a better presentation}
    // Make sure subgoups have been computed, since that sets OptimizedIso
    if not Get(G, "solvable") then
        return 0;
    end if;
    pc_code := SmallGroupEncoding(Codomain(G`OptimizedIso));
    return pc_code;
end intrinsic;
