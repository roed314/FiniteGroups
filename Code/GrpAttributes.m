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

intrinsic quasisimple(G::LMFDBGrp) -> BoolElt
{}
  GG := Get(G, "MagmaGrp");
  Q := quo< GG | Get(G, "MagmaCenter")>; // will center be stored?
  return (Get(G, "perfect") and IsSimple(Q));
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
  return Get(G, "order") div Order(ts);
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

// TODO: needs to be rewritten to use special subgroup labels
// currently on blacklist
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
   return label(OuterFPGroup(aut));
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

CreateLabel:=function(Glabel,Hlabel);
   strng:=Glabel;
   for i in [1..#Hlabel] do
       strng cat:=".";  
       strng cat:=IntegerToString(Hlabel[i]);
   end for; 
   return strng;
end function;


intrinsic Subgroups(G::LMFDBGrp) -> SeqEnum
    {The list of subgroups computed for this group}
    S := [];
    GG:=G`MagmaGrp;
    by_index := AssociativeArray();
    if G`all_subgroups_known then
        max_index := 0;
    else
        max_index := G`subgroup_index_bound;
    end if;
    // Need to include the conjugacy class ordering 
    SubLabels:= LabelSubgroups(GG, Subgroups(GG: IndexLimit:=max_index));
    for tup in SubLabels do
        H := New(LMFDBSubGrp);
        H`MagmaAmbient := GG;
        H`MagmaSubGrp := tup[2];
        H`label := CreateLabel(G`label,tup[1]);
        AssignBasicAttributes(H);
       /* Add normal and maximal label to special_labels */
        if H`normal then
           if not assigned H`special_labels then
	      H`special_labels:=[];
           end if;
           Append(~H`special_labels, Get(H,"label") cat ".N");
	end if;

        if H`maximal then
           if not assigned H`special_labels then
	      H`special_labels:=[];
           end if;
           Append(~H`special_labels, Get(H,"label") cat ".M");
	end if;

        Append(~S, H);
    end for;


/* assign the normal beyond index bound */
    all_normal:=G`normal_subgroups_known;
    if max_index ne 0 and all_normal then /*  unlabeled ones */
    
        N:=NormalSubgroups(GG);

        ordbd:=Integers()!(Get(G,"order")/max_index);
        UnLabeled:=[n : n in N | n`order lt ordbd];
        SubLabels:= LabelSubgroups(GG, UnLabeled);
			       
        for tup in SubLabels do
            H := New(LMFDBSubGrp);
            H`MagmaAmbient := GG;
            H`MagmaSubGrp := tup[2];
            Hlabeltemp:=CreateLabel(G`label,tup[1]);
            AssignBasicAttributes(H);
            if not assigned H`special_labels then
	        H`special_labels:=[];
            end if;
            Append(~H`special_labels, Hlabeltemp cat ".N");
       
           Append(~S,H);
        end for;
    end if;

/* assign the maximal beyond index bound */
    all_maximal:=G`maximal_subgroups_known; 
    if max_index ne 0 and all_maximal then /*  unlabeled ones */
       M:=MaximalSubgroups(GG);

       ordbd:=Integers()!(Get(G,"order")/max_index);
       UnLabeled:=[m : m in M | m`order lt ordbd];
       SubLabels:= LabelSubgroups(GG, UnLabeled);
       for tup in SubLabels do
           if IsMaximal(GG,tup`subgroup) and all_normal then  /* need to match up to Normal special label */		 
              for i in [1..#S] do
		  s:=S[i];    
		  if IsConjugate(GG,tup[2],s`MagmaSubGrp) then
     		     if not assigned s`special_labels then  /* likely don't need */
	                 s`special_labels:=[];
                     end if;
		     Append(~(s`special_labels), Get(s,"label") cat ".M");
                  end if;
	      end for;	      
           else
	      H := New(LMFDBSubGrp);
              H`MagmaAmbient := GG;
              H`MamgaSubGrp := tup[2];
              Hlabeltemp:=CreateLabel(G`label,tup[1]);
              AssignBasicAttributes(H);
              if not assigned H`special_labels then
	          H`special_labels:=[];
              end if;
              Append(~H`special_labels,  Hlabeltemp cat ".M");
              Append(~S,H);
           end if;
       end for;
    end if;

/* special groups labeled */
    Z:=Center(GG);
    D:=CommutatorSubgroup(GG);
    F:=FittingSubgroup(GG);
    Ph:=FrattiniSubgroup(GG);
    R:=Radical(GG);
    So:=Get(G,"socle");  /* run special routine in case matrix group */

    SpecialGrps:=[[* Z,".Z" *],[* D,".D" *],[* F,".F" *],[* Ph,".Phi" *],[* R,".R" *],[* So,".S" *]];

    for i in [1..#S] do
       s:=S[i];	    
       for j in [1..#SpecialGrps] do
	   tup:=SpecialGrps[j];	 
           if IsConjugate(GG,tup[1],s`MagmaSubGrp) then
               if not assigned s`special_labels then
	           s`special_labels:=[];
               end if;
               Append(~s`special_labels, Get(G,"label") cat tup[2]);
               Remove(~SpecialGrps,j); 
               if #SpecialGrps eq 0 then /* done loop */
	          break i;
               end if;
               break j;
           end if;
       end for;
    end for;

/* anything left in SpecialGroups is not yet a subgroup */
/* add the remaining subgroups as new */

    for tup in SpecialGrps do
	H := New(LMFDBSubGrp);
        H`MagmaAmbient := GG;
        H`MagmaSubGrp := tup[1];
        AssignBasicAttributes(H);
        if not assigned H`special_labels then
	    H`special_labels:=[];
        end if;
        Append(~H`special_labels, Get(G,"label") cat tup[2]);
        Append(~S,H);
    end for;

    return S;
end intrinsic;

intrinsic LookupSubgroupLabel(G::LMFDBGrp, HH::Grp) -> Any
    {Find a subgroup label for H, or return None if H is not labeled}
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
  dirbool := false;
  GG := Get(G, "MagmaGrp");
  ordG := Get(G, "order");
  Ns := NormalSubgroups(GG); // TODO: this should be changed to call on subgroup database when it exists
  Remove(~Ns,#Ns); // remove full group;
  Remove(~Ns,1); // remove trivial group;
  if direct then
    Ks := Ns;
  else
    Ks := Subgroups(GG); // this should be changed to call on subgroup database when it exists
  end if;
  for r in Ns do
    N := r`subgroup;
    comps := [el : el in Ks | el`order eq (ordG div Order(N))];
    for s in comps do
      K := s`subgroup;
      if #(N meet K) eq 1 then
        return true;
        //print N, K;
      end if;
    end for;
  end for;
  return dirbool;
end intrinsic;

intrinsic direct_product(G::LMFDBGrp) -> Any
  {Returns true if G is a nontrivial direct product; otherwise returns false.}
  return semidirect_product(G : direct := true);
end intrinsic;


intrinsic ConjugacyClasses(G::LMFDBGrp) ->  SeqEnum
{The list of conjugacy classes for this group}
  g:=G`MagmaGrp;
  cc:=ConjugacyClasses(g);
  cm:=ClassMap(g);
  pm:=PowerMap(g);
  gens:=Generators(g); // Get this from the LMFDBGrp?
  ordercc, _, labels := ordercc(g,cc,cm,pm,gens);
  // perm will convert given index to the one out of ordercc
  perm := [0 : j in [1..#cc]];
  for j:=1 to #cc do
    perm[cm(ordercc[j])] := j;
  end for;
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


intrinsic central_product(G::LMFDBGrp) -> BoolElt
    {Checks if the group G is a central product.}
    GG := G`MagmaGrp;
    if IsAbelian(GG) then
        /* G abelian will not be a central product <=> it is cyclic of prime power order (including trivial group).*/
        if not (IsCyclic(GG) and #FactoredOrder(GG) in {0,1}) then
            return true;
        end if;
    else
        /* G is not abelian. We run through the proper nontrivial normal subgroups N and consider whethe$
the centralizer C = C_G(N) together with N form a central product decomposition for G. We skip over N wh$
central (C = G) since if a complement C' properly contained in C = G exists, then it cannot also be cent$
is not abelian. Since C' must itself be normal (NC' = G), we will encounter C' (with centralizer smaller$
somewhere else in the loop. */

        normal_list := NormalSubgroups(GG);
        for ent in normal_list do
            N := ent`subgroup;
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


