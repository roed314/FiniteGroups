/* list of attributes to compute.*/

intrinsic almost_simple(G::LMFDBGrp) -> Any
    {}
    // In order to be almost simple, we need a simple nonabelian normal subgroup with trivial centralizer
    if Get(G, "abelian") or Get(G, "solvable") then
        return false;
    end if;
    if Get(G, "simple") then
        return true;
    end if;

    GG := G`MagmaGrp;
    Norms := Get(G, "MagmaMinimalNormalSubgroups");
    if Type(Norms) eq NoneType then
        return None();
    end if;
    for N in Norms do
        if not IsAbelian(N) and IsSimple(N) and #Centralizer(GG, N) eq 1 then
            return true;
        end if;
    end for;
    return false;
end intrinsic;

intrinsic number_conjugacy_classes(G::LMFDBGrp) -> Any
    {Number of conjugacy classes in a group}
    return Nclasses(G`MagmaGrp);
end intrinsic;

intrinsic number_autjugacy_classes(G::LMFDBGrp) -> Any
{Number of orbits of the automorphism group on elements}
    return &+[quad[4] : quad in Get(G, "aut_stats")];
end intrinsic;

intrinsic number_divisions(G::LMFDBGrp) -> Any
{Number of divisions: equivalence classes of elements up to conjugacy and exponentiation by integers prime to the order}
    return #Get(G, "MagmaDivisions");
end intrinsic;

intrinsic aut_stats(G::LMFDBGrp) -> Any
{returns the list of quadruples [o, s, k, m] where m is the number of autjugacy classes of order o containing k conjugacy classes of size s}
    // Don't want to use CCAutCollapse since that triggers computation of the rational character table
    CC := Get(G, "MagmaConjugacyClasses");
    if Get(G, "HaveHolomorph") then
        Hol := Get(G, "Holomorph");
        inj := Get(G, "HolInj");
        D := Classify([1..#CC], func<i, j | IsConjugate(Hol, inj(CC[i][3]), inj(CC[j][3]))>);
    elif Get(G, "HaveAutomorphisms") then
        Aut := Get(G, "MagmaAutGroup");
        cm := Get(G, "MagmaClassMap");
        outs := Get(G, "OuterGenerators");
        edges := [{Integers()|} : _ in [1..#CC]];
        for f in outs do
            for i in [1..#CC] do
                j := cm(f(CC[i][3]));
                if i ne j then
                    Include(~(edges[i]), j);
                end if;
            end for;
        end for;
        V := Graph<#CC| edges : SparseRep := true>;
        D := [Sort([Index(v) : v in comp]) : comp in Components(V)];
    else
        error "Must have either holomorph or automorphisms";
    end if;
    A := AssociativeArray();
    for d in D do
        c := CC[d[1]];
        os := [c[1], c[2], #d];
        if not IsDefined(A, os) then
            A[os] := 0;
        end if;
        A[os] +:= 1;
    end for;
    return Sort([[os[1], os[2], os[3], m] : os -> m in A]);
end intrinsic;

intrinsic quasisimple(G::LMFDBGrp) -> BoolElt
{}
    Z := Get(G, "MagmaCenter");
    n := Get(G, "order");
    Qord := n div #Z;
    if not (Get(G, "perfect") and IsSimpleOrder(Qord)) then
        return false;
    end if;
    if Qord lt 1000000 then
        return IsSimple(G`MagmaGrp / Z);
    else
        Zcomp := CompositionFactors(Z);
        return Get(G, "composition_length") eq #Zcomp + 1;
    end if;
end intrinsic;

intrinsic MagmaLowerCentralSeries(G::LMFDBGrp) -> SeqEnum
{}
    return LowerCentralSeries(G`MagmaGrp);
end intrinsic;

intrinsic MagmaUpperCentralSeries(G::LMFDBGrp) -> SeqEnum
{}
    return UpperCentralSeries(G`MagmaGrp);
end intrinsic;

intrinsic MagmaChiefSeries(G::LMFDBGrp) -> SeqEnum
{}
    return ChiefSeries(G`MagmaGrp);
end intrinsic;

intrinsic MagmaDerivedSeries(G::LMFDBGrp) -> SeqEnum
{}
    return DerivedSeries(G`MagmaGrp);
end intrinsic;

intrinsic IsSupersolvable(GG::Grp) -> BoolElt
{}
    if not IsSolvable(GG) then
        return false;
    end if;
    if IsNilpotent(GG) then
        return true;
    end if;
    C := [Order(H) : H in ChiefSeries(GG)];
    for i := 1 to #C-1 do
        if not IsPrime(C[i] div C[i+1]) then
            return false;
        end if;
    end for;
    return true;
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
    C := [Order(H) : H in Get(G, "MagmaChiefSeries")];
    for i := 1 to #C-1 do
        if not IsPrime(C[i] div C[i+1]) then
            return false;
        end if;
    end for;
    return true;
end intrinsic;

intrinsic solvability_type(G::LMFDBGrp) -> RngIntElt
{An encoding of where this group falls along the spectrum from cyclic to nonsolvable}
    if Get(G, "cyclic") then
        return 0;
    elif Get(G, "abelian") then
        if Get(G, "metacyclic") then
            return 1;
        else
            return 2;
        end if;
    elif Get(G, "nilpotent") then
        if Get(G, "metacyclic") then
            return 3;
        elif Get(G, "metabelian") then
            return 4;
        else
            return 5;
        end if;
    elif Get(G, "metacyclic") then
        return 6;
    elif Get(G, "metabelian") then
        if Get(G, "supersolvable") then
            return 7;
        elif Get(G, "monomial") then
            return 8;
        else
            return 9;
        end if;
    elif Get(G, "supersolvable") then
        return 10;
    elif Get(G, "monomial") then
        return 11;
    elif Get(G, "solvable") then
        return 12;
    else
        return 13;
    end if;
end intrinsic;

intrinsic backup_solvability_type(G::LMFDBGrp) -> RngIntElt
{A version of solvability_type that skips the computation of monomial, which may not be feasible (character table)}
    if Get(G, "cyclic") then
        return 0;
    elif Get(G, "abelian") then
        if Get(G, "metacyclic") then
            return 1;
        else
            return 2;
        end if;
    elif Get(G, "nilpotent") then
        if Get(G, "metacyclic") then
            return 3;
        elif Get(G, "metabelian") then
            return 4;
        else
            return 5;
        end if;
    elif Get(G, "metacyclic") then
        return 6;
    elif Get(G, "metabelian") then
        if Get(G, "supersolvable") then
            return 7;
        else
            return 16;
        end if;
    elif Get(G, "supersolvable") then
        return 10;
    elif Get(G, "solvable") then
        return 17;
    else
        return 13;
    end if;
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
intrinsic EasyIsMetacyclicMagma(G::Grp) -> Any
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
    return [z[1] : z in Factorization(G`order)];
end intrinsic;

intrinsic exponents_of_order(G::LMFDBGrp) -> Any
{Exponents of the distinct prime factors of the order of the group, sorted in reverse order}
    exps := [-z[2] : z in Factorization(Get(G, "order"))];
    Sort(~exps);
    return [-e : e in exps];
end intrinsic;

intrinsic metabelian(G::LMFDBGrp) -> BoolElt
{Determine if a group is metabelian}
    if not Get(G, "solvable") then
        return false;
    end if;
    g:=G`MagmaGrp;
    return IsAbelian(DerivedSubgroup(g));
end intrinsic;

intrinsic monomial_number(n::RngIntElt) -> BoolElt
{If true, then all SOLVABLE groups of this order are monomial}
    // This routine was ported from GAP (https://github.com/gap-system/gap/blob/46eef40fd7f14c8769d8ba993a52b485e6075b89/lib/ctblmono.gi#L932)
    nu2 := Valuation(n, 2);
    fac := Factorization(n);
    // minimal nonmonomial groups of type 1
    if nu2 ge 2 and &or[pair[1] mod 4 eq 3 and pair[2] ge 3 : pair in fac] then
        return false;
    end if;
    // minimal nonmonomial groups of type 2
    if nu2 ge 3 and &or[pair[1] mod 4 eq 1 and pair[2] ge 3 : pair in fac] then
        return false;
    end if;
    // minimal nonmonomial groups of type 3
    for pair in fac do
        p, e := Explode(pair);
        for pair2 in fac do
            q, f := Explode(pair2);
            if p ne q and q ne 2 then
                ord := Modorder(p, q);
                if IsEven(ord) and ord lt e then
                    return false;
                end if;
            end if;
        end for;
    end for;
    // minimal nonmonomial groups of type 4
    if nu2 ge 4 and &or[pair[1] ne 2 and nu2 ge 2 * Modorder(2, pair[1]) + 2 : pair in fac] then
        return false;
    end if;
    // minimal nonmonomial groups of type 5
    if nu2 ge 2 then
        for pair in fac do
            p, e := Explode(pair);
            if p mod 4 eq 1 and e ge 3 then
                for pair2 in fac do
                    q, f := Explode(pair2);
                    if q ne 2 then
                        ord := Modorder(p, q);
                        if IsOdd(ord) and 2 * ord lt e then
                            return false;
                        end if;
                    end if;
                end for;
            end if;
        end for;
    end if;
    return true;
end intrinsic;

intrinsic monomial(G::LMFDBGrp) -> BoolElt
    {Determine if a group is monomial}
    g:=G`MagmaGrp;
    if not Get(G,"solvable") then
        return false;
    elif Get(G, "supersolvable") then
        return true;
    elif Get(G,"Agroup") then
        return true;
    elif monomial_number(Get(G, "order")) then
        return true;
    else
        ct := Get(G,"MagmaCharacterTable");
        maxd := Integers() ! Degree(ct[#ct]); // Crazy that coercion is needed
        ls := LowIndexSubgroups(G, maxd);
        if Type(ls) eq NoneType then
            return None();
        else
            hh := <z`MagmaSubGrp : z in ls>;
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


function IsCpxCq(n)
    // Whether a non-abelian group of order n is necessarily of the form C_p \rtimes C_q with p = 1 (mod q)
    F := Factorization(n);
    return #F eq 2 and F[1][2] eq 1 and F[2][2] eq 1;
end function;

intrinsic rational(G::LMFDBGrp) -> Any
{Determine if a group is rational, i.e., all characters are rational}
    if Get(G, "abelian") then
        return Get(G, "exponent") eq 2;
    elif IsCpxCq(G`order) then // C_p \rtimes C_q
        return G`order eq 6;
    end if;
    return Get(G, "number_conjugacy_classes") eq Get(G, "number_divisions");
end intrinsic;

intrinsic elementary(G::LMFDBGrp) -> Any
  {Product of a all primes p such that G is a direct product of a p-group and a cyclic group}
  ans := 1;
  if Get(G,"solvable") and Get(G,"order") gt 1 then
    g:=G`MagmaGrp;
    g:=PCGroup(g);
    sylowsys:= SylowBasis(g);
    comp := ComplementBasis(g);
    facts := Get(G, "factors_of_order");
    for j:=1 to #sylowsys do
      if IsNormal(g, sylowsys[j]) and IsNormal(g,comp[j]) and IsCyclic(comp[j]) then
        ans := ans*facts[j];
      end if;
    end for;
  end if;
  return ans;
end intrinsic;

intrinsic hyperelementary(G::LMFDBGrp) -> Any
  {Product of all primes p such that G is an extension of a p-group by a cyclic group of order prime to p}
  ans := 1;
  if Get(G,"solvable") and Get(G,"order") gt 1 then
    g := G`MagmaGrp;
    g := PCGroup(g);
    comp := ComplementBasis(g);
    facts := Get(G, "factors_of_order");
    for j:=1 to #comp do
      if IsNormal(g, comp[j]) and IsCyclic(comp[j]) then
        ans := ans*facts[j];
      end if;
    end for;
  end if;
  return ans;
end intrinsic;


intrinsic MagmaTransitiveSubgroup(G::LMFDBGrp) -> Any
    {Subgroup producing a minimal degree transitive faithful permutation representation}
    g := G`MagmaGrp;
    if Get(G, "order") eq 1 then
        return g;
    end if;
    L := Get(G, "BestSubgroupLat");
    m := L`index_bound;
    N := G`order;
    for H in Get(L, "ordered_subs") do
        if m ne 0 then
            ind := N div H`order;
            if ind gt m then
                return None();
            end if;
        end if;
        if Get(H, "core_order") eq 1 then
            return H`subgroup;
        end if;
    end for;
    return None();
end intrinsic;

intrinsic transitive_degree(G::LMFDBGrp) -> Any
    {Smallest transitive degree for a faithful permutation representation}
    ts := Get(G, "MagmaTransitiveSubgroup");
    if Type(ts) eq NoneType then return None(); end if;
    return Get(G, "order") div Order(ts);
end intrinsic;

intrinsic permutation_degree(G::LMFDBGrp) -> Any
{Smallest degree for a faithful permutation representation}
    return Degree(Image(MinimalDegreePermutationRepresentation(G`MagmaGrp)));
end intrinsic;

intrinsic irrC_degree(G::LMFDBGrp) -> Any
{}
    faith := Get(G, "faithful_reps");
    if Type(faith) eq NoneType then
        return None();
    elif #faith eq 0 then
        return -1;
    end if;
    return faith[1][1];
end intrinsic;

intrinsic irrQ_degree(G::LMFDBGrp) -> Any
{}
    n := G`order;
    if Get(G, "abelian") then
        if Get(G, "cyclic") then
            return EulerPhi(n);
        else
            return -1;
        end if;
    elif IsCpxCq(n) then
        q, p := Explode(PrimeDivisors(n));
        return p - 1;
    end if;
    rct := Get(G, "MagmaRationalCharacterTable");
    faithful := [Integers()!Degree(chi) : chi in rct | IsFaithful(chi)];
    if #faithful gt 0 then
        return Min(faithful);
    else
        return -1;
    end if;
end intrinsic;

// The following attributes are set externally for now (using Preload)
intrinsic linC_degree(G::LMFDBGrp) -> Any
{}
    if Get(G, "abelian") then
        return #Get(G, "smith_abelian_invariants");
    end if;
    return None();
end intrinsic;
intrinsic linQ_degree(G::LMFDBGrp) -> Any
{}
    return None();
end intrinsic;
intrinsic linFp_degree(G::LMFDBGrp) -> Any
{}
    return None();
end intrinsic;
intrinsic linFq_degree(G::LMFDBGrp) -> Any
{}
    return None();
end intrinsic;
intrinsic pc_rank(G::LMFDBGrp) -> Any
{}
    return None();
end intrinsic;

intrinsic perm_gens(G::LMFDBGrp) -> Any
{Generators of a minimal degree faithful permutation representation}
    ert := Get(G, "elt_rep_type");
    if ert eq 0 then
        return None();
    end if;
    return [z : z in Generators(G`MagmaGrp)];
    /*ts := Get(G, "MagmaTransitiveSubgroup");
    g := G`MagmaGrp;
    gg := CosetImage(g,ts);
    return [z : z in Generators(gg)];*/
end intrinsic;

intrinsic GeneratorsSequence(G::GrpPC) -> SeqEnum
{A version of the intrinsic that exists for permutation and matrix groups.
 Note that this is not the same as either Generators or PCGenerators: it omits generators that are powers of another generator}
    gu := gens_used(G);
    return [G.i : i in [1..NumberOfPCGenerators(G)] | i in gu];
end intrinsic;

intrinsic Generators(G::LMFDBGrp) -> Any
{Returns the chosen generators of the underlying group}
    return GeneratorsSequence(G`MagmaGrp);
end intrinsic;

intrinsic faithful_reps(G::LMFDBGrp) -> Any
{Dimensions and Frobenius-Schur indicators of faithful irreducible representations}
    if not IsCyclic(Get(G, "MagmaCenter")) then
        return [];
    end if;
    // We first use some formulas for easy cases where we can compute the result without resorting to a character table
    n := Get(G, "order");
    if n eq 1 then
        return [[1, 1, 1]];
    elif n eq 2 then
        return [[1, 1, 1]];
    elif Get(G, "cyclic") then
        return [[1, 0, EulerPhi(n)]];
    elif IsCpxCq(n) then // C_p \rtimes C_q with p = 1 (mod q)
        q, p := Explode(PrimeDivisors(n));
        // There are q 1-dim irreps that are not faithful, and (p-1)/q irreps of dimension q that are
        if q eq 2 then // dihedral
            return [[2, 1, (p-1) div 2]];
        else
            return [[q, 0, (p-1) div q]];
        end if;
    end if;
    A := AssociativeArray();
    g := G`MagmaGrp;
    ct := Get(G,"MagmaCharacterTable");
    for j:=1 to #ct do
        ch := ct[j];
        if IsFaithful(ch) then
            v := <Degree(ch), Integers()!Indicator(ch)>;
            if not IsDefined(A, v) then
                A[v] := 0;
            end if;
            A[v] +:= 1;
        end if;
    end for;
    return Sort([[Integers() | k[1], k[2], v] : k -> v in A]);
end intrinsic;

intrinsic smallrep(G::LMFDBGrp) -> Any
{Smallest degree of a faithful irreducible representation; deprecated alias of irrC_degree}
    return Get(G, "irrC_degree");
end intrinsic;

// Next 2 intrinsics are helpers for commutator_count
intrinsic ClassPositionsOfKernel(lc::AlgChtrElt) -> Any
  {List of conjugacy class positions in the kernel of the character lc}
  return [j : j in [1..#lc] | lc[j] eq lc[1]];
end intrinsic;

intrinsic commutator_count(G::LMFDBGrp) -> Any
{Smallest integer n such that every element of the derived subgroup is a product of n commutators}
  if Get(G, "abelian") then
    return 0; // the identity is an empty product
  elif Get(G, "simple") then
    // Liebeck, Martin W.; O'Brien, E. A.; Shalev, Aner; Tiep, Pham Huu. The Ore conjecture. J. Eur. Math. Soc. (JEMS) 12 (2010), no. 4, 939–1008
    return 1;
  elif IsCpxCq(G`order) then // C_p \rtimes C_q with p = 1 (mod q)
    // the derived set below is the same as commut, since on the classes of order q (the only elements not in commut) the values are just the qth roots of unity which sum to 0.
    return 1;
  end if;
  g := G`MagmaGrp;
  ct := Get(G, "MagmaCharacterTable");
  derived := &meet[Set(ClassPositionsOfKernel(lc)) : lc in ct | Degree(lc) eq 1];
  commut := {z : z in [1..#ct] | &+[ct[j][z]/ct[j][1] : j in [1..#ct[1]]] ne 0};
  other := derived diff commut;
  n := 1;
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
    n := n+1;
    G_n := G_n join new;
    other := other diff new;
  end while;

  return n;
end intrinsic;

// Check redundancy of Sylow call
intrinsic MagmaSylowSubgroups(G::LMFDBGrp) -> Assoc
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

intrinsic MagmaMinimalNormalSubgroups(G::LMFDBGrp) -> SeqEnum
{The minimal normal subgroups of G}
    if Type(G`MagmaGrp) eq GrpMat then
        // MinimalNormalSubgroups not implemented for matrix groups
        if Get(G, "normal_subgroups_known") and Get(G, "subgroup_inclusions_known") then
            L := BestNormalSubgroupLat(G);
            triv := Rep(Get(L, "by_index")[G`order])`i;
            return [N`subgroup : N in L`subs | IsDefined(N`unders, triv)];
        else
            // Could work harder here....
            return None();
        end if;
    end if;
    return MinimalNormalSubgroups(G`MagmaGrp);
end intrinsic;

intrinsic Zgroup(G::LMFDBGrp) -> Any
  {Check whether all the Syllowsubgroups are cylic}
  SS := Get(G, "MagmaSylowSubgroups");
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
  SS := Get(G, "MagmaSylowSubgroups");
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
  GG := G`MagmaGrp;
  if Get(G, "abelian") then
      A := GG;
  else
      C := Get(G, "MagmaCommutator");
      A := BestQuotient(GG, C);
  end if;
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
intrinsic composition_factor_decode(t::Tup) -> RngIntElt, MonStgElt
  {Given a tuple <f,d,q>, in the format of the output of CompositionFactors, return the corresponding size and label.}
  assert #t eq 3;
  if t[1] eq 19 then
      return t[3], Sprintf("%o.1", t[3]);
  else
      N := SimpleGroupOrder(t);
      if t[1] eq 3 and t[3] eq 3 and t[2] ge 3 then
          // In this case (n=t[2]), Omega(2n+1, 3) is not isomorphic to PSp(2n, 3) but has the same order
          ctr := "b";
      elif t[1] eq 1 and t[2] eq 2 and t[3] eq 4 then
          // In this case PSL(3,4) is not isomorphic to A8 = GL(4,2) but has the same order
          ctr := "b";
      elif t[1] eq 17 and t[2] eq 9 then
          // In this case A9 is not isomorphic to GL(3,4) but has the same order
          ctr := "b";
      elif N lt 2000 then
          ctr := IdentifyGroup(SimpleGroup(t))[2];
      else
          // I worry that there will be more exceptional cases in the future, but hard-coding 500+ cases is also unpleasant
          ctr := "a";
      end if;
      return N, Sprintf("%o.%o", N, ctr);
  end if;
end intrinsic;

intrinsic composition_factors(G::LMFDBGrp) -> Any
    {labels for composition factors}
    // see https://magma.maths.usyd.edu.au/magma/handbook/text/625#6962
    data := [];
    for tup in CompositionFactors(G`MagmaGrp) do
        size, lab := composition_factor_decode(tup);
        Append(~data, <size, tup, lab>);
    end for;
    Sort(~data);
    return [datum[3] : datum in data];
end intrinsic;

intrinsic composition_length(G::LMFDBGrp) -> Any
  {Compute length of composition series.}
  return #Get(G,"composition_factors");
end intrinsic;

intrinsic MagmaCenter(G::LMFDBGrp) -> Grp
{}
    return Center(G`MagmaGrp);
end intrinsic;

intrinsic MagmaRadical(G::LMFDBGrp) -> Grp
{}
    return Radical(G`MagmaGrp);
end intrinsic;

intrinsic center_label(G::LMFDBGrp) -> Any
{Label string for Center}
   return label_subgroup(G, Get(G, "MagmaCenter") : giveup:=true);
end intrinsic;

intrinsic center_order(G::LMFDBGrp) -> RngIntElt
{}
    return #Get(G, "MagmaCenter");
end intrinsic;


intrinsic central_quotient(G::LMFDBGrp) -> Any
{label string for CentralQuotient}
    return label_quotient(G, Get(G, "MagmaCenter") : giveup:=true);
end intrinsic;


intrinsic MagmaCommutator(G::LMFDBGrp) -> Any
{Commutator subgroup}
    return CommutatorSubgroup(G`MagmaGrp);
end intrinsic;


intrinsic commutator_label(G::LMFDBGrp) -> Any
{label string for Commutator Subgroup}
    t0 := ReportStart(G, "LabelCommutator");
    s := label_subgroup(G, Get(G, "MagmaCommutator") : giveup:=true);
    ReportEnd(G, "LabelCommutator", t0);
    return s;
end intrinsic;


intrinsic abelian_quotient(G::LMFDBGrp) -> Any
{label string for quotient of Commutator Subgroup}
    return label_quotient(G, Get(G, "MagmaCommutator") : giveup:=true);
end intrinsic;


intrinsic MagmaFrattini(G::LMFDBGrp) -> Any
{ Frattini Subgroup}
    GG := G`MagmaGrp;
    if Type(GG) eq GrpMat and not Get(G, "solvable") then
        // Magma's built in function fails
        return Core(GG, &meet[H`subgroup : H in MaximalSubgroups(GG)]);
    end if;
    return FrattiniSubgroup(GG);
end intrinsic;


intrinsic frattini_label(G::LMFDBGrp) -> Any
{label string for Frattini Subgroup}
    return label_subgroup(G, Get(G, "MagmaFrattini") : giveup:=true);
end intrinsic;


intrinsic frattini_quotient(G::LMFDBGrp) -> Any
{label string for Frattini Quotient}
    return label_quotient(G, Get(G, "MagmaFrattini") : giveup:=true);
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
    A := AssociativeArray();
    if G`order eq 1 then
        return [[1, 1]];
    elif Get(G, "abelian") then
        primary := AssociativeArray();
        for q in Get(G, "primary_abelian_invariants") do
            _, p, e := IsPrimePower(q);
            if not IsDefined(primary, p) then primary[p] := AssociativeArray(); end if;
            if not IsDefined(primary[p], e) then primary[p][e] := 0; end if;
            primary[p][e] +:= 1;
        end for;
        comps := [];
        for p -> part in primary do
            trunccnt := AssociativeArray(); // log of (product of q, truncated at p^e)
            M := Max([e : e -> k in part]);
            for i in [0..M] do trunccnt[i] := 0; end for;
            for e -> k in part do
                for i in [1..M] do
                    trunccnt[i] +:= k * Min(i, e);
                end for;
            end for;
            Append(~comps, [<1, 1>] cat [<p^i, p^trunccnt[i] - p^trunccnt[i-1]> : i in [1..M]]);
        end for;
        for tup in CartesianProduct(comps) do
            order := &*[pair[1] : pair in tup];
            cnt := &*[pair[2] : pair in tup];
            A[order] := cnt;
        end for;
    elif IsCpxCq(G`order) then
        q, p := Explode(PrimeDivisors(G`order));
        return [[1, 1], [q, (q-1)*p], [p, p-1]];
    else
        C := Get(G, "MagmaConjugacyClasses");
        for c in C do
            if not IsDefined(A, c[1]) then
                A[c[1]] := 0;
            end if;
            A[c[1]] +:= c[2];
        end for;
    end if;
    return Sort([[k, v] : k -> v in A]);
end intrinsic;

intrinsic cc_stats(G::LMFDBGrp) -> Any
{returns the list of triples [o, s, m] where m is the number of conjugacy classes of order o and size s}
    if Get(G, "abelian") then
        return [[pair[1], 1, pair[2]] : pair in Get(G, "order_stats")];
    elif IsCpxCq(G`order) then
        q, p := Explode(PrimeDivisors(G`order));
        return [[1, 1, 1], [q, p, q-1], [p, q, (p-1) div q]];
    end if;
    C := Get(G, "MagmaConjugacyClasses");
    A := AssociativeArray();
    for c in C do
        os := [c[1], c[2]];
        if not IsDefined(A, os) then
            A[os] := 0;
        end if;
        A[os] +:= 1;
    end for;
    return Sort([[k[1], k[2], v] : k -> v in A]);
end intrinsic;

intrinsic div_stats(G::LMFDBGrp) -> Any
{returns the list of quadruples [o, s, k, m] where m is the number of divisions of order o containing k conjugacy classes of size s}
    if Get(G, "abelian") then
        return [[pair[1], 1, EulerPhi(pair[1]), pair[2] div EulerPhi(pair[1])] : pair in Get(G, "order_stats")];
    elif IsCpxCq(G`order) then
        return [trip cat [1] : trip in Get(G, "cc_stats")]; // a single division of each order
    end if;
    divs := AssociativeArray();
    for d in Get(G, "MagmaDivisions") do
        os := [d[1], d[2], #d[3]];
        if not IsDefined(divs, os) then
            divs[os] := 0;
        end if;
        divs[os] +:= 1;
    end for;
    return Sort([[os[1], os[2], os[3], m] : os -> m in divs]);
end intrinsic;

// copied from /Applications/Magma/package/Group/GrpFin/groupname.m
function GenHallSubgroupMinP(G,p)
  if Type(G) eq GrpPC then
    return HallSubgroup(G,-p);
  end if;
  GPC,m:=PCGroup(G);
  return HallSubgroup(GPC,-p)@@m;
end function;

intrinsic IsADirectProductHeuristic(G::Grp : steps:=50) -> Any
  {}
  vprint GroupName,2:"IsADirectProductHeuristic";
  if IsAbelian(G) then
    if #G eq 1 then return false, _, _; end if;
    if IsPrimePower(#G) then
      if IsCyclic(G) then
        return false, _, _;
      else A:=AbelianBasis(G);
        return true, sub<G|A[1]>, sub<G|A[[2..#A]]>;
      end if;
    else
      p := PrimeDivisors(#G)[1];
      S := SylowSubgroup(G,p);
      H := GenHallSubgroupMinP(G,p);
      return true, S, H;
    end if;
  end if;
  vprint GroupName,2:"IsADirectProductHeuristic: Centre";
  Z := Centre(G);
  vprint GroupName,2:"IsADirectProductHeuristic: Steps";
  for i:=1 to steps do
    repeat
      for i:=1 to 5 do
        r := Random(G);
        if IsSquarefree(Order(r)) then break; end if;
      end for;
      g := r^Random(Divisors(Order(r)));
    until not (g in Z);
    N1 := NormalClosure(G, sub<G|g>);
    try
        N2:=Centralizer(G, N1);
    catch e     //dealing with a strange Magma bug in 120.5
        GenCentralizers := {Centralizer(G,h) : h in Generators(N1)};
        N2 := &meet(GenCentralizers);
    end try;
    // N2 := Centralizer(G,N1);
    if (#N1*#N2 eq #G) and (#(N1 meet N2) eq 1) and (#N2 ne 1) then
      return true, N1, N2;    //! should be fixed in a new version of Magma
      //return true,eval Sprint(N1,"Magma"),eval Sprint(N2,"Magma");
    end if;
  end for;
  vprint GroupName,2:"IsADirectProductHeuristic: Done";
  return false, _, _;
end intrinsic;

intrinsic DirectFactorization(GG::Grp : Ns:=[]) -> Any
{Returns true if G is a nontrivial direct product, along with factors; otherwise returns false.}
  heur_bool, N, K := IsADirectProductHeuristic(GG);
  if heur_bool then
    return heur_bool, N, K, Ns;
  end if;
  ordG := #GG;
  // deal with trivial group
  if ordG eq 1 then
    return false, _, _, _;
  end if;
  if #Ns eq 0 then
    //Ns := NormalSubgroups(GG);
    Ns := [el`subgroup : el in NormalSubgroups(GG) | el`order gt 1 and el`order lt ordG];
  end if;
  for N in Ns do
    comps := [el : el in Ns | #el eq (ordG div #N)];
    for K in comps do
      if #(N meet K) eq 1 then
        //print N, K;
        return true, N, K, Ns;
      end if;
    end for;
  end for;
  return false, _, _, _;
end intrinsic;

intrinsic direct_factorization(G::LMFDBGrp) -> Any
{}
  GG := G`MagmaGrp;
  if Get(G, "simple") or (Get(G, "cyclic") and IsPrimePower(G`order)) then
      return [];
  elif Get(G, "abelian") then
      return CollectDirectFactors([CyclicGroup(m) : m in PrimaryAbelianInvariants(G`MagmaGrp)]);
  end if;
  if not Get(G, "normal_subgroups_known") or FindSubsWithoutAut(G) then return None(); end if;
  if Get(G, "outer_equivalence") then
    Ns := []; // compute the full set of normal subgroups inside DirectFactorization
  else
    Ns := [H`subgroup : H in Get(G, "NormSubGrpLat")`subs | H`order ne 1 and H`order ne G`order];
  end if;
  t0 := ReportStart(G, "direct_factorization");
  fact_bool, N, K, Ns := DirectFactorization(GG : Ns:=Ns);
  if not fact_bool then
    ReportEnd(G, "direct_factorization", t0);
    return [];
  end if;
  facts := [N, K];
  irred_facts := [];
  all_irred := false;
  while not all_irred do
    new_facts := [];
    for fact in facts do
      Ns_fact := [el : el in Ns | el subset fact];
      split_bool, Ni, Ki := DirectFactorization(fact: Ns := Ns_fact);
      if not split_bool then
        Append(~irred_facts, fact);
      else
      new_facts cat:= [Ni, Ki];
      end if;
    end for;
    if #new_facts eq 0 then
      all_irred := true;
    end if;
    facts := new_facts;
  end while;
  facts := CollectDirectFactors(irred_facts);
  ReportEnd(G, "direct_factorization", t0);
  return facts;
end intrinsic;

intrinsic CollectDirectFactors(facts::SeqEnum) -> SeqEnum
  {Group together factors in direct product, returning a sequence of pairs <label, exponent>}
  //facts := [el`subgroup : el in facts];
  pairs := [];
  for fact in facts do
    lab := label(fact : strict:=false);
    if lab cmpeq None() then // unable to label one of the direct factors
      return None();
    end if;
    old_bool := false;
    for i := 1 to #pairs do
      if lab eq pairs[i][1] then
        fact_ind := i;
        old_bool := true;
      end if;
    end for;
    if old_bool then
      pairs[fact_ind][2] +:= 1;
    else
      // tuples are sortable while lists [* *] are not
      Append(~pairs, <lab, 1>);
    end if;
  end for;
  Sort(~pairs);
  return pairs;
end intrinsic;

intrinsic semidirect_product(G::LMFDBGrp) -> Any
{Returns true if G is a nontrivial semidirect product; otherwise returns false.}
    if Get(G, "normal_subgroups_known") then
        // complements are stored in the full subgroup lattice
        L := Get(G, "BestSubgroupLat");
        missing_split := false;
        comp_known := Get(G, "complements_known");
        for H in L`subs do
            if H`order ne 1 and H`order ne G`order and Get(H, "normal") then
                if comp_known and #H`complements gt 0 then
                    return true;
                elif Gcd(H`order, G`order div H`order) eq 1 then
                    // Schur-Zassenhaus theorem
                    return true;
                else
                    missing_split := true;
                end if;
            end if;
        end for;
        if L`index_bound eq 0 and not missing_split then return false; end if;
    end if;
    DP := Get(G, "direct_product");
    if Type(DP) eq BoolElt and DP then return true; end if;
    return None();
end intrinsic;

intrinsic direct_product(G::LMFDBGrp) -> Any
{Returns true if G is a nontrivial direct product; otherwise returns false.}
    fact := Get(G, "direct_factorization");
    if Type(fact) eq NoneType then
        if FindSubsWithoutAut(G) then return None(); end if;
        // Try to do just one decomposition
        // This can succeed where direct_factorization failed if we were unable to label
        // one of the terms
        if Get(G, "normal_subgroups_known") then
            if Get(G, "complements_known") then
                // Scan for normal complements
                L := Get(G, "BestSubgroupLat");
                for H in L`subs do
                    if H`order ne 1 and H`order ne G`order and Get(H, "normal") and &or[Get(L`subs[j], "normal") : j in H`complements] then
                        return true;
                    end if;
                end for;
                if L`index_bound eq 0 then return false; end if;
            end if;
            if not Get(G, "outer_equivalence") then
                // We use the full DirectFactorization machinery
                Ns := [N`subgroup : N in Get(G, "NormSubGrpLat")`subs];
                return DirectFactorization(G`MagmaGrp : Ns:=Ns);
            end if;
        end if;
        if IsADirectProductHeuristic(G`MagmaGrp) then return true; end if;
        return None();
    end if;
    return (#fact gt 0);
end intrinsic;

/*
intrinsic direct_factorization_recursive(G::LMFDBGrp) -> SeqEnum
{}
  fact_bool, Nsub, Ksub := DirectFactorization(G);
  if not fact_bool then
    return [G];
  else
    N := LabelToLMFDBGrp(Get(Nsub, "subgroup") : represent:=false);
    K := LabelToLMFDBGrp(Get(Ksub, "subgroup") : represent:=false);
    vprintf User1: "N = %o\nK = %o\n", N, K;
    return $$(N) cat $$(K);
  end if;
end intrinsic;
*/

/*
intrinsic direct_factorization(G::LMFDBGrp) -> SeqEnum
{}
  fact_bool, Nsub, Ksub := DirectFactorization(G`MagmaGrp);
  if not fact_bool then
    return [];
  end if;
  // It would be better to do this computation without creating new LMFDBGrps, since it should be possible entirely within the SubgroupLat (given that we have normalizers).
  N := LabelToLMFDBGrp(Get(Nsub, "subgroup") : represent:=false);
  K := LabelToLMFDBGrp(Get(Ksub, "subgroup") : represent:=false);
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
        Ni := LabelToLMFDBGrp(Get(Nisub, "subgroup") : represent:=false);
        Ki := LabelToLMFDBGrp(Get(Kisub, "subgroup") : represent:=false);
        new_facts cat:= [Ni,Ki];
      end if;
    end for;
    if #new_facts eq 0 then
      all_irred := true;
    end if;
    facts := new_facts;
  end while;
  // check that they're really isomorphic
  //GG := Get(G, "MagmaGrp");
  // The factors might not be in the same magma "universe" e.g., for 120.35
  // Can't have a SeqEnum of these, so you can't take apply DirectProduct
  //irred_facts_mag := [ Get(el, "MagmaGrp") : el in irred_facts ];
  //assert IsIsomorphic(GG, DirectProduct(irred_facts_mag));

  return CollectDirectFactors(irred_facts);
end intrinsic;
*/

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
    t0 := ReportStart(G, "MagmaPowerMap");
    pm := PowerMap(G`MagmaGrp);
    ReportEnd(G, "MagmaPowerMap", t0);
    return pm;
end intrinsic;

intrinsic MagmaClassMap(G::LMFDBGrp) -> Map
{Return Magma's ClassMap.}
    t0 := ReportStart(G, "MagmaClassMap");
    cm := ClassMap(G`MagmaGrp);
    ReportEnd(G, "MagmaClassMap", t0);
    return cm;
end intrinsic;

intrinsic ClassMap(G::LMFDBGrp) -> Map
{Renumbered version of the class map to align with our numbering}
    cc := ConjugacyClasses(G); // set as a side effect
    return G`ClassMap;
end intrinsic;

intrinsic MagmaConjugacyClasses(G::LMFDBGrp) -> SeqEnum
{Return Magma's Conjugacy classes.}
    t0 := ReportStart(G, "MagmaConjugacyClasses");
    C := ConjugacyClasses(G`MagmaGrp);
    ReportEnd(G, "MagmaConjugacyClasses", t0);
    return C;
end intrinsic;

intrinsic MagmaGenerators(G::LMFDBGrp) -> SeqEnum
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
    t0 := ReportStart(G, "LabelConjugacyClasses");
    cc := Get(G, "MagmaConjugacyClasses");
    cm := Get(G, "MagmaClassMap");
    pm := Get(G, "MagmaPowerMap");
    gens := Get(G, "MagmaGenerators");
    reordered_cc, _, labels := ordercc(G, gens);

    // We determine the number of rational characters

    // perm will convert given index to the one out of ordercc
    // perm2 is its inverse
    perm := [0 : j in [1..#cc]];
    perminv := [0 : j in [1..#cc]];
    for i:=1 to #cc do
        j := cm(reordered_cc[i]);
        perm[j] := i;
        perminv[i] := j;
    end for;
    G`CCpermutation := perm;
    G`CCpermutationInv := perminv;
    sset := {1..#cc};
    permmap := map<sset->sset | [i -> perm[i] : i in sset]>;
    G`ClassMap := cm*permmap; // Magma does composition backwards!
    magccs := [ New(LMFDBGrpConjCls) : j in cc];
    gord := Get(G, "order");
    plist := [z[1] : z in Factorization(gord) * Factorization(EulerPhi(Get(G, "exponent")))];
    //gord:=Get(G, 'Order');
    for j:=1 to #cc do
        ix := perm[j];
        magccs[ix]`Grp := G;
        magccs[ix]`MagmaConjCls := cc[j];
        magccs[ix]`label := labels[ix];
        magccs[ix]`size := cc[j][2];
        magccs[ix]`counter := ix;
        magccs[ix]`order := cc[j][1];
        magccs[ix]`powers := [perm[pm(j,p)] : p in plist];
        magccs[ix]`representative := reordered_cc[ix]; // We use the reordered_cc representative, since it is deterministically chosen
    end for;
    ReportEnd(G, "LabelConjugacyClasses", t0);
    return magccs;
end intrinsic;

intrinsic CheckConjugacyClasses(G::LMFDBGrp)
{Run some tests on the output of ConjugacyClasses(G)}
    C := Get(G, "ConjugacyClasses");
    cm := Get(G, "MagmaClassMap");
    // Check that the order part of the label is correct
    orders := [Sprint(c`order) : c in C];
    assert &and[(C[i]`label)[1..#orders[i]] eq orders[i] : i in [1..#C]];
    // Check that powers is correct
    plist := [z[1] : z in Factorization(Get(G, "order")) * Factorization(EulerPhi(Get(G, "exponent")))];
    assert &and[#(c`powers) eq #plist and &and[cm((c`representative)^(plist[i])) eq cm(C[(c`powers)[i]]`representative) : i in [1..#plist]] : c in C];
    // Check that "inverse classes" are actually inverse
    by_label := AssociativeArray();
    for c in C do
        by_label[c`label] := c;
    end for;
    for c in C do
        if "-" in c`label then
            assert cm((c`representative)^-1) eq cm(by_label[ReplaceString(c`label, "-", "")]`representative);
        end if;
    end for;
    // Check that order, size, counter are correct
    assert &and[C[i]`counter eq i and C[i]`order eq Order(C[i]`representative) and C[i]`size eq Index(G`MagmaGrp, Centralizer(G`MagmaGrp, C[i]`representative)) : i in [1..#C]];
    // Check that classes are sorted correctly by (order, size)
    assert &and[<C[i]`order, C[i]`size> le <C[i+1]`order, C[i+1]`size> : i in [1..#C-1]];
    // Check that classes of size 1 are exactly the center
    size_one := [c : c in C | c`size eq 1];
    Z := Get(G, "MagmaCenter");
    assert #size_one eq #Z;
    assert &and[c`representative in Z : c in size_one];
end intrinsic;

intrinsic CheckConjugacyClasses(label::MonStgElt)
{Run tests based on label}
    desc := Read("DATA/descriptions/"*label);
    G := MakeBigGroup(desc, label);
    CheckConjugacyClasses(G);
end intrinsic;

intrinsic MagmaCharacterTable(G::LMFDBGrp) -> Any
{Return Magma's character table.}
    t0 := ReportStart(G, "MagmaCharacterTable");
    CT := CharacterTableDS(G`MagmaGrp);
    ReportEnd(G, "MagmaCharacterTable", t0);
    return CT;
end intrinsic;

intrinsic irrep_stats(G::LMFDBGrp) -> Any
{Return the sequence of pairs <d, m>, where m is the number of complex irreducible representations of G of dimension d}
    n := G`order;
    if Get(G, "abelian") then
        return [<1, n>];
    elif IsCpxCq(n) then
        q, p := Explode(PrimeDivisors(n));
        // There are q 1-dim irreps that are not faithful, and (p-1)/q irreps of dimension q that are
        return [<1, q>, <q, (p-1) div q>];
    end if;
    return CountFibers(Get(G, "MagmaCharacterTable"), func<chi|Degree(chi)>);
end intrinsic;

intrinsic MagmaCharacterMatching(G::LMFDBGrp) -> Any
  {Return the list of list showing which complex characters go with each rational character.}
  u := Get(G,"MagmaRationalCharacterTable");
  return G`MagmaCharacterMatching; // Set as side effect
end intrinsic;


intrinsic MagmaRationalCharacterTable(G::LMFDBGrp) -> Any
{Return Magma's rational character table.}
    t0 := ReportStart(G, "MagmaRationalCharacterTable");
    u, v := RationalCharacterTable(G`MagmaGrp);
    G`MagmaCharacterMatching := v;
    ReportEnd(G, "MagmaRationalCharacterTable", t0);
    return u;
end intrinsic;

intrinsic ratrep_stats(G::LMFDBGrp) -> Any
{Return the sequence of pairs <d, m>, where m is the number of rational representations of G of dimension d that are irreducible over Q}
    if Get(G, "abelian") then
        A := AssociativeArray();
        for d in Get(G, "div_stats") do
            n := EulerPhi(d[1]);
            if not IsDefined(A, n) then A[n] := 0; end if;
            A[n] +:= d[4];
        end for;
        return Sort([<n, m> : n -> m in A]);
    elif IsCpxCq(G`order) then
        q, p := Explode(PrimeDivisors(G`order));
        if q eq 2 then
            return [<1, 2>, <p-1, 1>];
        else
            return [<1, 1>, <q-1, 1>, <p-1, 1>];
        end if;
    end if;
    return CountFibers(Get(G, "MagmaRationalCharacterTable"), func<chi|Degree(chi)>);
end intrinsic;

intrinsic complexconjindex(ct::Any, gorb::Any, achar::Any) -> Any
  {Find the complex conj of achar among indeces in gorb all from
   character table ct (which is now a list of lists).}
  findme := [ComplexConjugate(achar[z]) : z in [1..#achar]];
  gorbvals := [ct[z] : z in gorb];
  myind := Index(gorbvals, findme);
  return gorb[myind];
end intrinsic;

intrinsic rational_characters_known(G::LMFDBGrp) -> BoolElt
{ Whether to store rational characters }
    return Get(G, "number_divisions") lt 512;
end intrinsic;

intrinsic complex_characters_known(G::LMFDBGrp) -> BoolElt
{ Whether to store complex characters }
    return Get(G, "number_conjugacy_classes") lt 512;
end intrinsic;

intrinsic QQCharacters(G::LMFDBGrp) -> Any
{ Compute and return Q characters }
    if Get(G, "rational_characters_known") then
        dummy := Get(G, "Characters");
        return G`QQCharacters;
    end if;
    return []; // don't compute characters
end intrinsic;

intrinsic CCCharacters(G::LMFDBGrp) -> Any
{ Compute and return C characters }
    if Get(G, "complex_characters_known") then
        dummy := Get(G, "Characters");
        return G`CCCharacters;
    end if;
    return []; // don't compute characters
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
  g := G`MagmaGrp;
  ct := Get(G,"MagmaCharacterTable");
  rct := Get(G,"MagmaRationalCharacterTable");
  matching := Get(G,"MagmaCharacterMatching");
  perm := Get(G, "CCpermutation"); // perm[j] is the a Magma index
  glabel := Get(G, "label");
  // Need outer sort for rct, and then an inner sort for ct
  goodsubs := getgoodsubs(g, ct); // gives <subs, tvals>
  ntlist := goodsubs[2];
  // Need the list which takes complex chars and gives index of rational char
  comp2rat := [0 : z in ct];
  for j:=1 to #matching do
    for k:=1 to #matching[j] do
      comp2rat[matching[j][k]] := j;
    end for;
  end for;
  // Want sort list to be <degree, size of Gal orbit, n, t, lex info, ...>
  // We give rational character values first, then complex
  // Priorities by lex sort
  forlexsortrat := <<rct[comp2rat[j]][perm[k]] : k in [1..#ct]> : j in [1..#ct]>;
  forlexsort := <Flat(<<Round(10^25*Real(ct[j,perm[k]])), Round(10^25*Imaginary(ct[j,perm[k]]))> : k in [1..#ct]>) : j in [1..#ct]>;
//"forlexsortrat";
//forlexsortrat;
//"forlexsort";
//forlexsort;
  // We add three fields at the end. The last is old index, before sorting.
  // Before that is the old index in the rational table
  // Before that is the old index of its complex conjugate
  sortme := <<Degree(ct[j]), #matching[comp2rat[j]], ntlist[j][1], ntlist[j][2]> cat forlexsortrat[j]
     cat forlexsort[j] cat <0,0,0> : j in [1..#ct]>;
//"sortme",  sortme;
//"done";
  len := #sortme[1];
  for j:=1 to #ct do
    sortme[j][len] := j;
  end for;
  allvals := [[ct[j][k] : k in [1..#ct]] : j in [1..#ct]];
  for j:=1 to #matching do
    for k:=1 to #matching[j] do
      sortme[matching[j][k]][len-1] := j;
      sortme[matching[j][k]][len-2] := complexconjindex(allvals, matching[j], ct[matching[j][k]]);
    end for;
  end for;
  sortme := [[a : a in b] : b in sortme];
  Sort(~sortme);
//"did it";
//sortme;
  // Now step through to figure out the order
  donec := {};
  doneq := {};
  olddim := -1;
  rcnt := 0;
  rtotalcnt := 0;
  ccnt := 0;
  ctotalcnt := 0;
  for j:=1 to #sortme do
    dat := sortme[j];
    if dat[1] ne olddim then
      olddim := dat[1];
      rcnt := 0;
      ccnt := 0;
    end if;
    if dat[len] notin donec then // New C character
      if dat[len-1] notin doneq then // New Q character
        rcnt +:= 1;
        ccnt := 0;
        rtotalcnt +:= 1;
        rcode := num2letters(rcnt: Case:="lower");
        Include(~doneq, dat[len-1]);
        rindex := Integers()!dat[len-1];
        rchars[rindex]`counter := rtotalcnt;
        rchars[rindex]`label := Sprintf("%o.%o%o",glabel,dat[1],rcode);
        rchars[rindex]`nt := [dat[3],dat[4]];
        rchars[rindex]`qvalues := [Integers()! dat[j+4] : j in [1..#ct]];
      end if;
      ccnt +:= 1;
      ctotalcnt +:= 1;
      Include(~donec, dat[len]);
      cindex := Integers()!dat[len];
      cchars[cindex]`counter := ctotalcnt;
      cchars[cindex]`nt := [dat[3],dat[4]];
      cextra :=  (dat[2] eq 1) select "" else Sprintf("%o", ccnt);
      cchars[cindex]`label := Sprintf("%o.%o%o", glabel, dat[1],rcode)*cextra;
      // Encode values
      thischar := ct[cindex];
      basef := BaseRing(thischar);
      cyclon := CyclotomicOrder(basef);
      Kn := CyclotomicField(cyclon);
      cchars[cindex]`cyclotomic_n := cyclon;
      //cchars[cindex]`values := [PrintRelExtElement(Kn!thischar[perm[z]]) : z in [1..#thischar]];
      cchars[cindex]`values := [WriteCyclotomicElement(Kn!thischar[perm[z]],cyclon,cyc_cache) : z in [1..#thischar]];
      if dat[len-2] notin donec then
        ccnt +:= 1;
        ctotalcnt +:= 1;
        cindex := Integers()!dat[len-2];
        Include(~donec, dat[len-2]);
        cchars[cindex]`counter := ctotalcnt;
        cchars[cindex]`nt := [dat[3],dat[2]];
        cextra :=  (dat[2] eq 1) select "" else Sprintf("%o", ccnt);
        cchars[cindex]`label := Sprintf("%o.%o%o", glabel, dat[1],rcode)*cextra;
        thischar := ct[cindex];
        basef := BaseRing(thischar);
        cyclon := CyclotomicOrder(basef);
        Kn := CyclotomicField(cyclon);
        cchars[cindex]`cyclotomic_n := cyclon;
        cchars[cindex]`values := [WriteCyclotomicElement(Kn!thischar[perm[z]], cyclon, cyc_cache) : z in [1..#thischar]];
      end if;
    end if;
  end for;
  cntlist := [z`counter : z in rchars];
  ParallelSort(~cntlist,~rchars);
  G`QQCharacters := rchars;
  cntlist := [z`counter : z in cchars];
  ParallelSort(~cntlist, ~cchars);
  G`CCCharacters := cchars;
  return <cchars, rchars>;
end intrinsic;


// We don't want to have to compute the subgroup lattice at the same time as computing the characters
// Thus we split up the process of identifying the center and kernel into two steps: writing down generators, and then identifying the subgroups (as part of the same run that computes the subgroup lattice)

intrinsic charc_center_gens(G::LMFDBGrp) -> SeqEnum
{}
    return [[g : g in Generators(Get(chi, "center"))] : chi in Get(G, "CCCharacters")];
end intrinsic;

intrinsic charc_kernel_gens(G::LMFDBGrp) -> SeqEnum
{}
    return [[g : g in Generators(Get(chi, "kernel"))] : chi in Get(G, "CCCharacters")];
end intrinsic;

intrinsic charc_centers(G::LMFDBGrp) -> SeqEnum
{}
    GG := G`MagmaGrp;
    return [sub<GG|gens> : gens in Get(G, "charc_center_gens")];
end intrinsic;

intrinsic charc_kernels(G::LMFDBGrp) -> SeqEnum
{}
    GG := G`MagmaGrp;
    return [sub<GG|gens> : gens in Get(G, "charc_kernel_gens")];
end intrinsic;

intrinsic conj_centralizer_gens(G::LMFDBGrp) -> SeqEnum
{}
    if not FindSubsWithoutAut(G) and (Get(G, "complex_characters_known") or Get(G, "rational_characters_known")) then
        return [[g : g in Generators(Get(cc, "centralizer"))] : cc in Get(G, "ConjugacyClasses")];
    else
        return [];
    end if;
end intrinsic;

intrinsic conj_centralizers(G::LMFDBGrp) -> SeqEnum
{}
    GG := G`MagmaGrp;
    return [sub<GG|gens> : gens in Get(G, "conj_centralizer_gens")];
end intrinsic;


intrinsic Characters(G::LMFDBGrp) ->  Tup
  {Initialize characters of an LMFDB group and return a list of complex characters and a list of rational characters}
  g := G`MagmaGrp;
  ct := Get(G,"MagmaCharacterTable");
  rct := Get(G,"MagmaRationalCharacterTable");
  matching := Get(G,"MagmaCharacterMatching");
  R<x> := PolynomialRing(Rationals());
  polredabscaches := AssociativeArray();
  //cc:=Classes(g);
  cchars := [New(LMFDBGrpChtrCC) : c in ct];
  rchars := [New(LMFDBGrpChtrQQ) : c in rct];
  t0 := ReportStart(G, "LMFDBComplexChar");
  t := t0;
  for j:=1 to #cchars do
    cchars[j]`Grp := G;
    cchars[j]`MagmaChtr := ct[j];
    cchars[j]`dim := Integers() ! Degree(ct[j]);
    t1 := Cputime();
    cchars[j]`faithful := IsFaithful(ct[j]);
    vprint User2: "Faithful", j, Cputime() - t1;
    cchars[j]`group := Get(G,"label");
    thepoly := DefiningPolynomial(CharacterField(ct[j]));
    // Sometimes the type is Cyclotomic field, in which case thepoly is a different type
    if Type(thepoly) eq SeqEnum then thepoly := thepoly[1]; end if;
    d := Degree(thepoly);
    if not IsDefined(polredabscaches, d) then
      polredabscaches[d] := LoadPolredabsCache(d);
    end if;
    if not IsDefined(polredabscaches[d],thepoly) then
      if d gt 16 then tpol := ReportStart(G, Sprintf("Polredabs%o", d)); end if;
      thepoly1 := Polredabs(thepoly);
      if d gt 16 then ReportEnd(G, Sprintf("Polredabs%o", d), tpol); end if;
      polredabscaches[d][thepoly] := thepoly1;
      PolredabsCache(thepoly, thepoly1);
    end if;
    thepoly := polredabscaches[d][thepoly];
    cchars[j]`field := Coefficients(thepoly);
    cchars[j]`Image_object := New(LMFDBRepCC);
    t1 := Cputime();
    cchars[j]`indicator := Integers()!Indicator(ct[j]);
    vprint User2: "FrobSchur", j, Cputime() - t1;
    cchars[j]`label := "placeholder";
    t := Cputime();
  end for;
  ReportEnd(G, "LMFDBComplexChar", t0);
  t0 := Cputime();
  for j:=1 to #rchars do
    rchars[j]`Grp := G; // These don't have a group?
    //rchars[j]`MagmaChtr := ct[matching[j][1]];
    rchars[j]`MagmaChtr := rct[j];
    rchars[j]`group := Get(G,"label");
    rchars[j]`schur_index := SchurIndex(ct[matching[j][1]]);
    rchars[j]`multiplicity := #matching[j];
    rchars[j]`qdim := Integers()! Degree(rct[j]);
    rchars[j]`cdim := (Integers()! Degree(rct[j])) div #matching[j];
    rchars[j]`Image_object := New(LMFDBRepQQ);
    rchars[j]`faithful := IsFaithful(rct[j]);
    // Character may not be irreducible, so value might not be in 1,0,-1
    rchars[j]`label := "placeholder";
    vprint User2: "C", j, Cputime() - t;
    t := Cputime();
  end for;
  ReportEnd(G, "LMFDBRationalChar", t0);
  t0 := Cputime();
  /* This still needs labels and ordering for both types */
  sortdata:=characters_add_sort_and_labels(G, cchars, rchars);
  ReportEnd(G, "LabelChars", t0);
  return <cchars, rchars>;
end intrinsic;

intrinsic name(G::LMFDBGrp) -> Any
  {Returns Magma's name for the group.}
  t0 := ReportStart(G, "GroupName");
  gn := GroupName(G`MagmaGrp: prodeasylimit:=2, wreathlimit:=0);
  ReportEnd(G, "GroupName", t0);
  return gn;
end intrinsic;

intrinsic tex_name(G::LMFDBGrp) -> Any
  {Returns Magma's name for the group.}
  t0 := ReportStart(G, "TexName");
  gn := GroupName(G`MagmaGrp: TeX:=true, prodeasylimit:=2, wreathlimit:=0);
  ReportEnd(G, "TexName", t0);
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
  return Group(nl!spot);
end intrinsic;

intrinsic coset_action_label(H::LMFDBSubGrp) -> Any
  {Determine the transitive classification for G/H}
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  if Order(Core(GG,HH)) eq 1 and Index(GG, HH) lt 48 then
    ca := CosetImage(GG,HH);
    t,n := TransitiveGroupIdentification(ca);
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
        return not (Get(G, "cyclic") and #Get(G, "factors_of_order") in {0,1});
    else
        /* G is not abelian. We run through the proper nontrivial normal subgroups N and consider whether
the centralizer C = C_G(N) together with N form a central product decomposition for G. We skip over N that are
central (C = G) since if a complement C' properly contained in C = G exists, then it cannot also be central since G
is not abelian. Since C' must itself be normal (NC' = G), we will encounter C' (with centralizer smaller than G)
somewhere else in the loop. */
        if Get(G, "normal_subgroups_known") and not FindSubsWithoutAut(G) then
            return &or[Get(H, "central_factor") : H in Get(G, "NormalSubgroups")];
        else
            return None();
        end if;
    end if;
end intrinsic;

intrinsic PermutationGrp(G::LMFDBGrp) -> Any
{Returns a permutation group isomorphic to this group}
    reps := Get(G, "representations");
    if IsDefined(reps, "Perm") then
        d := reps["Perm"]["d"];
        gens := reps["Perm"]["gens"];
        return PermutationGroup<d | [DecodePerm(g, d) : g in gens]>;
    else
        GG := G`MagmaGrp;
        // Use MyQuotient rather than BestQuotient to ensure that we get a permutation group out
        GG, phi := MyQuotient(GG, sub<GG|> : max_orbits:=4);
        G`HomToPermutationGrp := phi;
        return GG;
    end if;
end intrinsic;


intrinsic schur_multiplier(G::LMFDBGrp) -> Any
  {Returns abelian invariants for Schur multiplier by computing prime compoments and then merging them.}
  t0 := ReportStart(G, "SchurMultiplier");
  invs := [];
  ps := Get(G, "factors_of_order");
  GG := Get(G, "MagmaGrp");
  // Need GrpPerm for pMultiplicator function calls below. Check and convert if not GrpPerm.
  if Type(GG) ne GrpPerm then
    // We find an efficient permutation representation.
    GG := Get(G, "PermutationGrp");
  end if;
  for p in ps do
    for el in pMultiplicator(GG,p) do
      if el gt 1 then
        Append(~invs, el);
      end if;
    end for;
  end for;
  ReportEnd(G, "SchurMultiplier", t0);
  return AbelianInvariants(AbelianGroup(invs));
end intrinsic;


intrinsic wreath_product(G::LMFDBGrp) -> Any
{Returns true if G is a wreath product; otherwise returns false.}
    G`wreath_data := None();
    if Get(G, "abelian") then return false; end if; // abelian groups can't be nontrivial wreath products
    GG := Get(G, "MagmaGrp");
    // Need GrpPerm for IsWreathProduct function call below. Check and convert if not GrpPerm.
    if Type(GG) ne GrpPerm then
        // We find an efficient permutation representation.
        GG := Get(G, "PermutationGrp");
        phi := assigned G`HomToPermutationGrp select G`HomToPermutationGrp else 0;
    else
        phi := IdentityHomomorphism(GG);
    end if;
    t0 := ReportStart(G, "WreathProduct");
    isw := IsWreathProduct(GG);
    ReportEnd(G, "WreathProduct", t0);
    if isw then
        // For some reason, Magma doesn't return 4 values when isw is false
        isw, A, B, C := IsWreathProduct(GG);
        BC := CosetImage(B, C);
        n, d := TransitiveGroupIdentification(BC);
        T := Sprintf("%oT%o", d, n);
        if phi cmpeq 0 then
            G`wreath_data := [GroupName(A: TeX:=true, prodeasylimit:=2), GroupName(B: TeX:=true, prodeasylimit:=2), T];
        else
            L := Get(G, "BestSubgroupLat");
            if L`index_bound eq 0 or (Index(GG, A) le L`index_bound and Index(GG, C) le L`index_bound) then
                S := Get(G, "Subgroups"); // triggers labeling of subgroups
                A := L`subs[SubgroupIdentify(L, A @@ phi)];
                B := L`subs[SubgroupIdentify(L, B @@ phi)];
                C := L`subs[SubgroupIdentify(L, C @@ phi)];
                G`wreath_data := [A`label, B`label, C`label, T];
            else
                G`wreath_data := [GroupName(A: TeX:=true, prodeasylimit:=2), GroupName(B: TeX:=true, prodeasylimit:=2), T];
            end if;
        end if;
    end if;
    return isw;
end intrinsic;

intrinsic wreath_data(G::LMFDBGrp) -> SeqEnum
{}
    _ := Get(G, "wreath_product");
    return G`wreath_data;
end intrinsic;

function letters2num(s)
    letters := [StringToCode(x) - 96 : x in Eltseq(s)];
    ssum := 0;
    for c in letters do
        ssum := ssum*26 + c;
    end for;
    return ssum;
end function;

intrinsic counter(G::LMFDBGrp) -> RngIntElt
{Second entry in label}
   lab:= Get(G,"label");
   spl:=Split(lab,".");
   if Regexp("[0-9]+", spl[2]) then
       return StringToInteger(spl[2]);
   else
       return letters2num(spl[2]);
   end if;
end intrinsic;

intrinsic elt_rep_type(G:LMFDBGrp) -> Any
    {type of an element of the group}
    if Type(G`MagmaGrp) eq GrpPC then
        return 0;
    elif Type(G`MagmaGrp) eq GrpPerm then
      return -Degree(G`MagmaGrp);
    elif Type(G`MagmaGrp) eq GrpMat then
        R := CoefficientRing(G`MagmaGrp);
        if R cmpeq Integers() then
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

/* placeholder for when larger groups get added */
intrinsic old_label(G:LMFDBGrp)-> Any
{graveyard for labels when they are no longer needed. Currently just returns None, since this is used when we compute labels all groups of a given order where we did not have a label before}
  return None();
end intrinsic;

intrinsic pc_code(G::LMFDBGrp) -> RngInt
{This should be set externally for solvable groups that are not represented as a polycyclic group}
    GG := G`MagmaGrp;
    if not Get(G, "solvable") then
        return 0;
    end if;
    return SmallGroupEncoding(GG);
end intrinsic;

intrinsic gens_used(G::GrpPC) -> SeqEnum
{The indices of the PCGenerators so that every PCGenerator is a power of one of these}
    if #G eq 1 then return []; end if;
    ps := PCPrimes(G);
    gens := PCGenerators(G);
    return [1] cat [i : i in [2..#gens] | gens[i] ne gens[i-1]^ps[i-1]];
end intrinsic;

intrinsic gens_used(G::LMFDBGrp) -> Any
{}
    if Type(G`MagmaGrp) eq GrpPC then
        return gens_used(G`MagmaGrp);
    elif IsDefined(Get(G, "representations"), "PC") then
        A := Get(G, "representations")["PC"];
        if IsDefined(A, "gens") then
            return A["gens"];
        end if;
        if IsDefined(A, "pres") then
            GPC := PCGroup(A["pres"]);
        else
            GPC := SmallGroupDecoding(A["code"], G`order);
        end if;
        return gens_used(GPC);
    end if;
    return None();
end intrinsic;

intrinsic ngens(G::LMFDBGrp) -> Any
{The number of generators used in the representation used to represent elements}
    return #Get(G, "representations")[Get(G, "element_repr_type")]["gens"];
end intrinsic;

function GrpToAssoc(X, Xgens)
    B := AssociativeArray();
    if Type(X) eq GrpMat then
        L, R := MatricesToIntegers([x : x in Xgens], CoefficientRing(X));
        R := Split(R, ",");
        B["d"] := Degree(X);
        B["gens"] := L;
        if R[1] eq "0" then
            typ := "GLZ";
            B["b"] := StringToInteger(R[2]);
        elif R[1][1] eq "q" then
            typ := "GLFq";
            B["q"] := StringToInteger(R[1][2..#R[1]]);
        else
            q := StringToInteger(R[1]);
            B["q"] := q;
            if IsPrime(q) then
                typ := "GLFp";
            elif IsPrimePower(q) then
                typ := "GLZq";
            else
                typ := "GLZN";
            end if;
        end if;
    elif Type(X) eq GrpPerm then
        typ := "Perm";
        d := Degree(X);
        B["d"] := d;
        B["gens"] := [EncodePerm(x) : x in Xgens];
    elif Type(X) eq GrpPC then
        typ := "PC";
        B["code"] := SmallGroupEncoding(X);
        B["pres"] := CompactPresentation(X);
        B["gens"] := gens_used(X);
    end if;
    return B, typ;
end function;

intrinsic representations(G::LMFDBGrp) -> Assoc
{Different representations of this group, storing the relevant generators.  This implementation just records the current representation; additional representations should be set externally using Preload}
    GG := G`MagmaGrp;
    A := AssociativeArray();
    if assigned G`ElementReprCovers then
        f := G`ElementReprHom;
        X := Domain(f);
        Y := Codomain(f);
        if G`ElementReprCovers then
            assert Type(X) eq GrpMat and &and[IsScalar(g) : g in Generators(Kernel(f))];
            B, typ := GrpToAssoc(X, Generators(X));
            G`element_repr_type := "P" * typ;
            A["P" * typ] := B;
            B, typ := GrpToAssoc(Y, [f(x) : x in Generators(X)]);
            B[typ] := B;
        else
            BX, typX := GrpToAssoc(X, Generators(X));
            A[typX] := BX;
            BY, typY := GrpToAssoc(Y, [f(x) : x in Generators(X)]);
            G`element_repr_type := typY;
            if typX ne typY then
                A[typY] := BY;
            end if;
        end if;
    else
        B, typ := GrpToAssoc(G`MagmaGrp);
        G`element_repr_type := typ;
        A[typ] := B;
    end if;
    return A;
end intrinsic;

intrinsic element_repr_type(G::LMFDBGrp) -> MonStgElt
{The key from representations to be used when representing elements}
    rep := Get(G, "representations"); // sets element_repr_type
    return G`element_repr_type;
end intrinsic;

intrinsic easy_rank(G::LMFDBGrp) -> Any
{Computes the rank in cases where doing so does not require the full subgroup lattice; -1 if too hard}
    if Get(G, "order") eq 1 then return 0; end if;
    if Get(G, "abelian") then return #Get(G, "smith_abelian_invariants"); end if;
    if Ngens(G`MagmaGrp) eq 2 then
        // Not cyclic since not abelian
        return 2;
    end if;
    if Get(G, "pgroup") ne 0 then
        _, p, m := IsPrimePower(Get(G, "order"));
        F := #Get(G, "MagmaFrattini");
        if F eq 1 then
            k := 0;
        else
            _, _, k := IsPrimePower(F);
        end if;
        return m - k;
    end if;
    return -1;
end intrinsic;

intrinsic rank(G::LMFDBGrp) -> Any
{Calculates the rank of the group G: the minimal number of generators}
    r := Get(G, "easy_rank");
    if r ne -1 then
        return r;
    end if;
    return #SmallestGeneratingSet(G`MagmaGrp);
    /*if not Get(G, "subgroup_inclusions_known") then return None(); end if;
    if Get(G, "subgroup_index_bound") ne 0 then return None(); end if;
    Subs := Get(G, "Subgroups");
    if &or[Type(Get(H, "mobius_sub")) eq NoneType : H in Subs] then
        return None();
    end if;
    for r in [2..Get(G, "order")] do
        tot := &+[Get(H, "subgroup_order")^r * Get(H, "mobius_sub") * Get(H, "count") : H in Subs];
        if tot gt 0 then
            G`EulerianTimesAut := tot;
            return r;
        end if;
    end for;
    error "rank calculation overflow";*/
end intrinsic;

intrinsic eulerian_function(G::LMFDBGrp) -> Any
{Calculates the Eulerian function of G for n = rank(G)}
    if Get(G, "order") eq 1 then return 1; end if;
    // TODO: FIX THIS
    return None();
    if not Get(G, "subgroup_inclusions_known") then return None(); end if;
    r := Get(G,"rank"); // sets EulerianTimesAut unless easy_rank
    if Type(r) eq NoneType then return None(); end if;
    if assigned G`EulerianTimesAut then
        tot := G`EulerianTimesAut;
    else
        tot := &+[Get(H, "subgroup_order")^r * Get(H, "mobius_sub") * Get(H, "count") : H in Get(G, "Subgroups")];
    end if;
    aut := Get(G, "aut_order");
    assert tot ne 0 and IsDivisibleBy(tot, aut);
    return tot div aut;
end intrinsic;

intrinsic MinPermDeg(G::LMFDBGrp) -> RngSerPowElt
{}
    R<x> := PowerSeriesRing(Integers() : Precision:=100);
    m := Get(G, "order");
    N0 := NormalSubgroups(G);
    print [N`mobius_quo : N in N0];
    if Get(G, "outer_equivalence") then
        L := SubGrpLatAut(G);
        Normals := [N : N in L`subs | N`cc_count eq Get(N, "subgroup_count")];
        Ambient := Get(G, "Holomorph");
        inj := Get(G, "HolInj");
        f := &+[N`mobius_quo * N`cc_count * &*[(1 - x^(m div H`order))^(-NumberOfInclusions(N, H) * H`subgroup_count div N`subgroup_count) : H in L`subs | IsConjugateSubgroup(Ambient, inj(Core(G`MagmaGrp, H`subgroup)), inj(N`subgroup))] : N in Normals];
        /*for N in Normals do
            print Get(N, "subgroup_order"), N`mobius_quo, N`conjugacy_class_count;
            print [(1 - x^(m div Get(H, "subgroup_order")))^(-H`conjugacy_class_count) : H in S | IsConjugateSubgroup(Ambient, inj(H`core), inj(N`MagmaSubGrp))];
        end for;
        f := &+[N`mobius_quo * N`conjugacy_class_count * &*[(1 - x^(m div Get(H, "subgroup_order")))^(-H`conjugacy_class_count) : H in S | IsConjugateSubgroup(Ambient, inj(H`core), inj(N`MagmaSubGrp))] : N in NormalSubgroups(G)];*/
    else
        S := Get(G, "Subgroups");
        f := &+[N`mobius_quo * &*[(1 - x^(m div Get(H, "subgroup_order")))^(-1) : H in S | N`MagmaSubGrp subset Get(H, "core")] : N in N0];
    end if;
    return f;
end intrinsic;

intrinsic MinLinDeg(G::LMFDBGrp) -> RngSerPowElt
{}
    R<x> := PowerSeriesRing(Integers() : Precision:=100);
    CT := Get(G, "MagmaCharacterTable");
    N0 := NormalSubgroups(G);
    if Get(G, "outer_equivalence") then
        L := SubGrpLatAut(G);
        Normals := [N : N in L`subs | N`cc_count eq Get(N, "subgroup_count")];
        Ambient := Get(G, "Holomorph");
        inj := Get(G, "HolInj");
        f := &+[N`mobius_quo * N`cc_count * &*[(1 - x^Degree(chi))^(-1) : chi in CT | N`subgroup subset Kernel(chi)]: N in Normals];
    else
        f := &+[N`mobius_quo * &*[(1 - x^Degree(chi))^(-1) : chi in CT | N`MagmaSubGrp subset Kernel(chi)] : N in N0];
    end if;
    return f;
end intrinsic;

intrinsic ZGramified(G::LMFDBGrp) -> RngIntElt
{}
    F := Factorization(Get(G, "order"));
    if #F ne 1 or F[1][1] ne 2 then
        return 0;
    end if;
    GG := G`MagmaGrp;
    S := Socle(GG);
    Z := Center(GG);
    if S ne Z or Exponent(Z) ne 2 then
        return 0;
    end if;
    if #Z ne G`order then
        CT := Get(G, "MagmaCharacterTable");
        C := Get(G, "MagmaConjugacyClasses");
        center_spots := [i : i in [1..#C] | C[i][2] eq 1];
        b, e := IsSquare(Index(GG, Z));
        if not b then
            return 0;
        end if;
        for chi in CT do
            if &and[chi[i] eq chi[1] : i in center_spots] then continue; end if;
            if &and[(chi[i] eq e or chi[i] eq -e) : i in center_spots] then continue; end if;
            return 0;
        end for;
    end if;
    F := Factorization(#Z);
    return F[1][2];
end intrinsic;

intrinsic CheckZGConj() -> SeqEnum, SeqEnum
{}
    zgram := [];
    bad := [];
    for N in [8, 16, 32, 64, 128, 256] do
        for i in [1..NumberOfSmallGroups(N)] do
            G := MakeSmallGroup(N, i : represent:=false);
            zgr := ZGramified(G);
            rdim := Valuation(MinLinDeg(G));
            if zgr in [2,3,4] then
                Append(~zgram, <G, rdim, (rdim^2 ge N)>);
                print "ZGR", N, i, zgr, rdim, (rdim^2 ge N) select "big" else "failure";
            end if;
            if zgr eq 0 and (rdim^2 ge N) then
                Append(~bad, <G, rdim>);
                print "Big without ZGR!", N, i;
            end if;
            if i mod 100 eq 0 then
                print "Progress:", N, i;
            end if;
        end for;
        print "Finished", N;
    end for;
    return zgram, bad;
end intrinsic;

intrinsic MinPermDegSplit(G::LMFDBGrp, K::LMFDBSubGrp) -> RngSerPowElt, RngSerPowElt, RngSerPowElt
{K should be normal in G}
    R<x> := PowerSeriesRing(Integers() : Precision:=100);
    assert not Get(G, "outer_equivalence");
    S := Get(G, "Subgroups");
    m := Get(G, "order");
    N0 := NormalSubgroups(G);
    N1 := [N : N in N0 | K`MagmaSubGrp subset N`MagmaSubGrp];
    print [N`mobius_quo : N in N1];
    N2 := [N : N in N0 | not K`MagmaSubGrp subset N`MagmaSubGrp];
    print [N`mobius_quo : N in N2];
    f1 := &+[N`mobius_quo * &*[(1 - x^(m div Get(H, "subgroup_order")))^(-1) : H in S | N`MagmaSubGrp subset Get(H, "core")] : N in N1];
    f2 := &+[N`mobius_quo * &*[(1 - x^(m div Get(H, "subgroup_order")))^(-1) : H in S | N`MagmaSubGrp subset Get(H, "core")] : N in N2];
    GK := NewLMFDBGrp(G`MagmaGrp / K`MagmaSubGrp, "G/K");
    f3 := MinPermDeg(GK);
    return f1, f2, f3;
end intrinsic;

intrinsic MinPermDegAbSplits(G::LMFDBGrp) -> RngIntElt
{}
    R<x> := PowerSeriesRing(Integers() : Precision:=100);
    S := Get(G, "Subgroups");
    f := MinPermDeg(G);
    prec := Valuation(f) + 2;
    print f + BigO(x^prec);
    for K in S do
        if Get(K, "subgroup_order") ne 1 and Get(K, "quotient_order") ne 1 and Get(K, "normal") and Get(K, "quotient_abelian") then
            f1, f2, f3 := MinPermDegSplit(G, K);
            print K`label;
            print f1+BigO(x^prec), f2+BigO(x^prec), f3+BigO(x^prec);
        end if;
    end for;
    return 0;
end intrinsic;
