/*
list of attributes to compute. DONE is either done here or in Basics.m
see https://github.com/roed314/FiniteGroups/blob/master/ProposedSchema.md for description of attributes

DONE: Order, Exponent, IsAbelian, IsCyclic, IsSolvable, IsNilpotent, IsMetacyclic, IsSimple, IsPerfect, Center, FrattiniSubgroup, Radical, Socle, AutomorphismGroup, NilpotencyClass, Ngens, DerivedSeries, DerivedLength, ChiefSeries, LowerCentralSeries, UpperCentralSeries, PrimaryAbelianInvariants, Commutator, NumberOfConjugacyClasses, IsAlmostSimple

TODO: MagmaGrp, Label, OldLabel, Name, TeXName, Counter, FactorsOfOrder, IsSuperSolvable, IsMetabelian, IsQuasiSimple, IsMonomial, IsRational, IsZGroup, IsAGroup, pGroup, Elementary, Hyperelementary, Rank, EulerianFunction, CenterLabel, CentralQuotient, CommutatorLabel, AbelianQuotient, CommutatorCount, FrattiniLabel, FrattiniQuotient, FittingSubgroup, TransitiveDegree, TransitiveSubgroup, SmallRep, AutOrder, OuterOrder, OuterGroup, FactorsOfAutOrder, PCCode, NumberOfSubgroupClasses, NumberOfSubgroups, NumberOfNormalSubgroups, NumberOfCharacteristicSubgroups, PerfectCore, SmithAbelianInvariants, SchurMultiplier, OrderStats, EltRepType, PermGens, AllSubgroupsKnown, NormalSubgroupsKnown, MaximalSubgroupsKnown, SylowSubgroupsKnown, SubgroupInclusionsKnown, OuterEquivalence, SubgroupIndexBound, IsWreathProduct, IsCentralProduct, IsFiniteMatrixGroup, IsDirectProduct, IsSemidirectProduct, CompositionLength;
*/
 
intrinsic IsAlmostSimple(G::LMFDBGrp) -> Any
  {}
  // In order to be almost simple, we need a simple nonabelian normal subgroup with trivial centralizer
  GG := G`MagmaGrp;
  if G`IsAbelian or G`IsSolvable then
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

intrinsic NumberOfConjugacyClasses(G::LMFDBGrp) -> Any
  {Number of conjugacy classes in a group}
  return Nclasses(G`MagmaGrp);
end intrinsic;

intrinsic Commutator(G::LMFDBGrp) -> Any
  {Compute commutator subgroup}
  return CommutatorSubgroup(G`MagmaGrp);
end intrinsic;

intrinsic PrimaryAbelianInvariants(G::LMFDBGrp) -> Any
  {If G is abelian, return the PrimaryAbelianInvariants.}
  if G`IsAbelian then
    GG := G`MagmaGrp;
    return PrimaryAbelianInvariants(GG);
  end if;
  // TODO: This should return the invariants of the maximal abelian quotient
end intrinsic;

intrinsic IsSupersolvable(G::LMFDBGrp) -> BoolElt
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

intrinsic IsMetacyclic(G::LMFDBGrp) -> BoolElt
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


intrinsic FactorsOfOrder(G::LMFDBGrp) -> Any
  {Prime factors of the order of the group}
  gord:=Get(G,"Order");
  return [z[1] : z in Factorization(gord)];
end intrinsic;

intrinsic IsMetabelian(G::LMFDBGrp) -> BoolElt
  {Determine if a group is metabelian}
  g:=G`MagmaGrp;
  return IsAbelian(DerivedSubgroup(g));
end intrinsic;

intrinsic IsMonomial(G::LMFDBGrp) -> BoolElt
  {Determine if a group is monomial}
  g:=G`MagmaGrp;
  if not IsSolvable(g) then
    return false;
  elif Get(G, "IsSupersolvable") then
    return true;
  elif Get(G,"IsSolvable") and Get(G,"IsAGroup") then
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

intrinsic IsRational(G::LMFDBGrp) -> BoolElt
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

intrinsic Elementary(G::LMFDBGrp) -> Any
  {Product of a all primes p such that G is a direct product of a p-group and a cyclic group}
  ans := 1;
  if Get(G,"IsSolvable") and Get(G,"Order") gt 1 then
    g:=G`MagmaGrp;
    g:=PCGroup(g);
    sylowsys:= SylowBasis(g);
    comp:=ComplementBasis(g);
    facts:= FactorsOfOrder(G);
    for j:=1 to #sylowsys do
      if IsNormal(g, sylowsys[j]) and IsNormal(g,comp[j]) and IsCyclic(comp[j]) then
        ans := ans*facts[j];
      end if;
    end for;
  end if;
  return ans;
end intrinsic;

intrinsic Hyperelementary(G::LMFDBGrp) -> Any
  {Product of all primes p such that G is an extension of a p-group by a group of order prime to p}
  ans := 1;
  if Get(G,"IsSolvable") and Get(G,"Order") gt 1 then
    g:=G`MagmaGrp;
    g:=PCGroup(g);
    comp:=ComplementBasis(g);
    facts:= FactorsOfOrder(G);
    for j:=1 to #comp do
      if IsNormal(g,comp[j]) and IsCyclic(comp[j]) then
        ans := ans*facts[j];
      end if;
    end for;
  end if;
  return ans;
end intrinsic;

intrinsic TransitiveSubgroup(G::LMFDBGrp) -> Any
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

intrinsic TransitiveDegree(G::LMFDBGrp) -> Any
  {Smallest transitive degree for a faithful permutation representation}
  ts:=Get(G, "TransitiveSubgroup");
  return Get(G, "Order")/Order(ts);
end intrinsic;

intrinsic PermGens(G::LMFDBGrp) -> Any
  {Generators of a minimal degree transitive faithful permutation representation}
  ts:=Get(G, "TransitiveSubgroup");
  g:=G`MagmaGrp;
  gg:=CosetImage(g,ts);
  return [z : z in Generators(gg)];
end intrinsic;

intrinsic SmallRep(G::LMFDBGrp) -> Any
  {Smallest degree of a faithful irreducible representation}
  if not IsCyclic(Get(G,"Center")) then
    return 0;
  end if;
  g:=G`MagmaGrp;
  ct := CharacterTable(g);
  for j:=1 to #ct do
    if IsFaithful(ct[j]) then
      return Degree(ct[j]);
    end if;
  end for;
  return 0; // Should not get here
end intrinsic;

intrinsic ClassPositionsOfKernel(lc::AlgChtrElt) -> Any
  {List of conjugacy class positions in the kernel of the character lc}
  return [j : j in [1..#lc] | lc[j] eq lc[1]];
end intrinsic;

intrinsic dosum(li) -> Any
  {Total a list}
  return &+li;
end intrinsic;

intrinsic CommutatorCount(G::LMFDBGrp) -> Any
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


intrinsic SylowSubgroups(G::LMFDBGrp) -> Any
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

intrinsic IsZGroup(G::LMFDBGrp) -> Any
  {Check whether all the Syllowsubgroups are cylic}
  SS := SylowSubgroups(G);
  K := Keys(SS);
  for k in K do
    if not IsCyclic(SS[k]) then
      return false;
    end if;
  end for;
  return true;
end intrinsic;

intrinsic IsAGroup(G::LMFDBGrp) -> Any
  {Check whether all the Syllowsubgroups are abelian}
  SS := SylowSubgroups(G);
  K := Keys(SS);
  for k in K do
    if not IsAbelian(SS[k]) then
      return false;
    end if;
  end for;
  return true;
end intrinsic;

intrinsic IsQuasiSimple(G::LMFDBGrp) -> Any
  {}
  GG := G`MagmaGrp;
  return (IsPerfect(GG) and IsSimple(quo< GG | Center(GG)>));
end intrinsic;

intrinsic SmithAbelianInvariants(G::LMFDBGrp) -> Any
  {Compute invariant factors of maximal abelian quotient}
  C := Get(G, "Commutator");
  GG := G`MagmaGrp;
  A := quo< GG | C>;
  return InvariantFactors(A);
end intrinsic;

intrinsic PerfectCore(G::LMFDBGrp) -> Any
  {Compute perfect core, the maximal perfect subgroup}
  DD := Get(G, "DerivedSeries");
  for i := 1 to #DD-1 do
    if DD[i] eq DD[i+1] then
      return DD[i];
    end if;
  end for;
  return DD[#DD];
end intrinsic;

intrinsic CompositionLength(G::LMFDBGrp) -> Any
  {Compute length of composition series.}
  return #Get(G,"CompositionFactors"); // Correct if trivial group is labeled G_0
end intrinsic;


