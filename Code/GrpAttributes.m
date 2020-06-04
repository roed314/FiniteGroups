/* list of attributes to compute.*/
 
intrinsic almost_simple(G::LMFDBGrp) -> Any
  {}
  // In order to be almost simple, we need a simple nonabelian normal subgroup with trivial centralizer
  GG := G`MagmaGrp;
  if G`abelian or G`solvable then
    return false;
  end if;
  // will we have the normal subgroups stored to G?
  for N in NormalSubgroups(GG) do
    if IsSimple(N) and (Order(Centralizer(GG,N)) eq 1) then
      return true;
    end if;
  end for;
  return false;
end intrinsic;

intrinsic number_conjugacy_classes(G::LMFDBGrp) -> Any
  {Number of conjugacy classes in a group}
  return Nclasses(G`MagmaGrp);
end intrinsic;

intrinsic commutator(G::LMFDBGrp) -> Any
  {Compute commutator subgroup}
  return CommutatorSubgroup(G`MagmaGrp);
end intrinsic;

intrinsic primary_abelian_invariants(G::LMFDBGrp) -> Any
  {If G is abelian, return the PrimaryAbelianInvariants.}
  if G`IsAbelian then
    GG := G`MagmaGrp;
    return PrimaryAbelianInvariants(GG);
  end if;
  // TODO: This should return the invariants of the maximal abelian quotient
end intrinsic;

intrinsic supersolvable(G::LMFDBGrp) -> BoolElt
  {Check if LMFDBGrp is supersolvable}
  GG := G`MagmaGrp;
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

// for LMFDBGrp
// Next 3 intrinsics are helpers for metacyclic
intrinsic EasyIsMetacyclic(G::LMFDBGrp) -> BoolElt
  {Easy checks for possibly being metacyclic}
  if IsSquarefree(G`Order) or G`IsCyclic then
    return true;
  end if;
  if not G`IsSolvable then
    return false;
  end if;
  if G`IsAbelian then
    if #G`SmithAbelianInvariants gt 2 then // take Smith invariants (Invariant Factors), check if length <= 2
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
    if #InvariantFactors(G) gt 2 then // take Smith invariants (Invariant Factors), check if length <= 2
      return false;
    end if;
    return true;
  end if;
  return 0;
end intrinsic;

intrinsic CyclicSubgroups(G::GrpAb) -> SeqEnum
  {Compute the cyclic subgroups of the abelian group G}
  cycs := [];
  for rec in Subgroups(G) do
    H := rec`subgroup;
    if IsCyclic(H) then // naive...
      Append(~cycs, H);
    end if;
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
  if G`pGroup ne 0 then
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
  for H in CyclicSubgroups(GG) do
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
  if not IsSolvable(g) then
    return false;
  elif Get(G, "supersolvable") then
    return true;
  elif Get(G,"solvable") and Get(G,"Agroup") then
    return true;
  else
    ct:=CharacterTable(g);
    maxd := Integers() ! Degree(ct[#ct]); // Crazy that coercion is needed
    stat:=[false : c in ct];
    ls:= LowIndexSubgroups(g, maxd); // Different return types depending on input
    lst := Type(ls[1]);
    if lst eq GrpPC or lst eq GrpPerm or lst eq GrpMat then
      hh:= ls;
    else
      hh:=<z`subgroup : z in LowIndexSubgroups(g, maxd)>;
    end if;
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
  g:=G`MagmaGrp;
  ss:=Subgroups(g);
  tg:=ss[1]`subgroup;
  for j:=#ss to 1 by -1 do
    if Core(g,ss[j]`subgroup) eq tg then
      return ss[j]`subgroup;
    end if;
  end for;
end intrinsic;

intrinsic transitive_degree(G::LMFDBGrp) -> Any
  {Smallest transitive degree for a faithful permutation representation}
  ts:=Get(G, "MagmaTransitiveSubgroup");
  return Get(G, "order")/Order(ts);
end intrinsic;

intrinsic perm_gens(G::LMFDBGrp) -> Any
  {Generators of a minimal degree transitive faithful permutation representation}
  ts:=Get(G, "MagmaTransitiveSubgroup");
  g:=G`MagmaGrp;
  gg:=CosetImage(g,ts);
  return [z : z in Generators(gg)];
end intrinsic;

intrinsic faithful_reps(G::LMFDBGrp) -> Any
  {Dimensions and Frobenius-Schur indicators of faithful irreducible representations}
  if not IsCyclic(Get(G, "MagmaCenter")) then
    return [];
  end if;
  A := AssociatieArray();
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
      if not HasKey(A, v) then
        A[v] := 0;
      end if;
      A[v] +:= 1;
    end if;
  end for;
  return Sort([[k[1], k[2], m] : k -> v in A]);
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

intrinsic quasisimple(G::LMFDBGrp) -> Any
  {}
  GG := G`MagmaGrp;
  return (IsPerfect(GG) and IsSimple(quo< GG | Center(GG)>));
end intrinsic;

intrinsic smith_abelian_invariants(G::LMFDBGrp) -> Any
  {Compute invariant factors of maximal abelian quotient}
  C := Get(G, "MagmaCommutator");
  GG := G`MagmaGrp;
  A := quo< GG | C>;
  return InvariantFactors(A);
end intrinsic;

intrinsic perfect_core(G::LMFDBGrp) -> Any
  {Compute perfect core, the maximal perfect subgroup}
  DD := Get(G, "derived_series");
  for i := 1 to #DD-1 do
    if DD[i] eq DD[i+1] then
      return DD[i];
    end if;
  end for;
  return DD[#DD];
end intrinsic;

intrinsic composition_length(G::LMFDBGrp) -> Any
  {Compute length of composition series.}
  return #Get(G,"composition_factors"); // Correct if trivial group is labeled G_0
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
   return OuterFPGroup(aut);
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
   return CommutatorSubgroup(G);
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


intrinsic Subgroups(G::LMFDBGrp) -> SeqEnum
    {The list of subgroups that we have computed for this group}
    return [];
end intrinsic;
