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

intrinsic number_autjugacy_classes(G::LMFDBGrp) -> Any
{Number of orbits of the automorphism group on elements}
    A := Get(G, "CCAutCollapse");
    CC := Get(G, "ConjugacyClasses");
    D := [[] : _ in [1..#Codomain(A)]];
    for k in [1..#CC] do
        Append(~D[A(k)], k);
        // set the aut label to the label of the first equivalent conjugacy class
        CC[k]`aut_label := CC[D[A(k)][1]]`label;
    end for;
    return #Codomain(A);
end intrinsic;

intrinsic number_divisions(G::LMFDBGrp) -> Any
{Number of divisions: equivalence classes of elements up to conjugacy and exponentiation by integers prime to the order}
    C := Get(G, "ConjugacyClasses"); // computes the number
    return G`number_divisions;
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

intrinsic exponents_of_order(G::LMFDBGrp) -> Any
{Exponents of the distinct prime factors of the order of the group, sorted in reverse order}
    exps := [-z[2] : z in Factorization(Get(G, "order"))];
    Sort(~exps);
    return [-e : e in exps];
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
        ct:=Get(G,"MagmaCharacterTable");
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
  ct := Get(G,"MagmaCharacterTable");
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
  if t[1] eq 19 then
    return CyclicGroup(t[3]);
  else
    return SimpleGroup(t);
  end if;
end intrinsic;

intrinsic composition_factors(G::LMFDBGrp) -> Any
    {labels for composition factors}
    // see https://magma.maths.usyd.edu.au/magma/handbook/text/625#6962
    data := [];
    for tup in CompositionFactors(G`MagmaGrp) do
        H := composition_factor_decode(tup);
        Append(~data, <#H, tup, label(H)>);
    end for;
    Sort(~data);
    return [datum[3] : datum in data];
end intrinsic;

intrinsic composition_length(G::LMFDBGrp) -> Any
  {Compute length of composition series.}
  return #Get(G,"composition_factors");
end intrinsic;

bad_cases := Split("64.12 64.14 128.63 128.64 128.65 128.66 128.89 128.90 128.91 128.92 128.93 128.94 128.95 128.96 128.97 128.98 128.270 128.273 128.277 128.280 128.287 128.290 128.352 128.353 128.363 128.372 128.373 160.17 160.39 160.42 192.41 192.42 192.44 192.93 192.94 192.103 192.105 192.106 192.345 192.346 192.360 192.362 192.363 192.366 192.368 192.372 192.377 192.378 192.607 192.608 192.712 192.721 224.16 224.41 256.42 256.82 256.83 256.84 256.85 256.86 256.94 256.95 256.122 256.371 256.372 256.373 256.374 256.377 256.432 256.433 256.434 256.435 256.436 256.437 256.438 256.439 256.440 256.1327 256.1330 256.1342 256.1343 256.1376 256.1386 256.1397 256.1398 256.1414 256.1422 256.1430 256.1479 256.1480 256.1482 256.1483 256.1493 256.1518 256.1519 256.1520 256.1521 256.3200 256.3202 256.3204 256.3289 256.3290 256.3291 256.4583 256.4584 256.4586 256.4636 256.4639 256.4642 256.4643 256.4648 256.4651 256.4652 256.4654 256.4658 256.4906 256.4907 256.4909 256.4911 256.4913 256.4915 256.4916 256.4918 256.4921 256.4923 256.4925 256.4926 256.4928 256.4929 256.4943 256.4945 256.4947 256.4949 256.4950 256.4952 256.4953 256.4954 256.4955 256.4957 256.4959 256.4960 256.4962 256.4963 256.4967 256.4968 256.4973 256.4974 256.4975 256.4976 256.4980 256.4981 256.4982 256.5304 256.5306 256.5307 256.5308 256.5310 256.5311 256.5316 256.5317 256.5320 256.5321 256.5340 256.5341 256.5342 256.5343 256.5344 256.5345 256.5346 256.5347 256.5356 256.5358 256.5359 256.5360 256.5362 256.5363 256.5368 256.5369 256.5372 256.5373 256.5392 256.5393 256.5394 256.5395 256.5396 256.5397 256.5398 256.5399 256.10681 256.10684 256.10686 256.10687 256.10689 256.10693 256.10697 256.10698 256.10708 256.10709 256.10710 256.10711 256.10712 256.10713 256.10716 256.10720 256.10729 256.10733 256.10734 256.10746 256.10747 256.10748 256.10758 256.10767 256.10769 256.11466 256.11472 256.11556 256.11564 256.11602 256.11603 256.11609 256.11610 256.11639 256.11640 256.11671 256.11672 256.11673 256.11700 256.11704 256.11705 256.11708 256.11711 256.11712 256.11715 256.11716 256.11738 256.11739 256.11838 256.11839 256.11846 256.11847 256.11858 256.11859 256.11860 256.11861 256.11870 256.11871 256.11872 256.11873 256.11918 256.11919 256.31887 256.31977 256.34703 256.34815 256.34850 256.36305 256.36405 256.36567 256.36781 256.36968 256.37611 256.39106 256.39782 256.40191 256.41187 256.41294 256.42185 256.44886 256.52508 288.40 288.43 288.201 288.203 288.211 288.266 288.269 320.39 320.40 320.41 320.42 320.43 320.92 320.93 320.102 320.104 320.105 320.263 320.268 320.269 320.402 320.413 320.414 320.428 320.429 320.430 320.431 320.434 320.435 320.445 320.446 320.631 320.675 320.676 320.698 320.780 320.789 320.792 320.842 352.41 384.41 384.42 384.43 384.44 384.47 384.48 384.49 384.50 384.51 384.52 384.80 384.81 384.92 384.93 384.136 384.137 384.138 384.139 384.140 384.141 384.146 384.147 384.148 384.149 384.150 384.338 384.339 384.340 384.341 384.363 384.366 384.367 384.369 384.370 384.372 384.375 384.376 384.377 384.378 384.756 384.758 384.760 384.762 384.763 384.764 384.765 384.766 384.767 384.768 384.769 384.771 384.774 384.775 384.778 384.779 384.820 384.822 384.825 384.827 384.828 384.829 384.830 384.831 384.832 384.833 384.834 384.835 384.836 384.837 384.838 384.839 384.848 384.850 384.956 384.959 384.960 384.963 384.964 384.965 384.966 384.967 384.968 384.970 384.971 384.972 384.973 384.974 384.975 384.976 384.977 384.978 384.979 384.980 384.981 384.982 384.983 384.984 384.985 384.986 384.987 384.988 384.989 384.990 384.991 384.992 384.994 384.996 384.997 384.998 384.999 384.1004 384.1005 384.1006 384.1007 384.1008 384.1010 384.1014 384.1015 384.1032 384.1033 384.1034 384.1035 384.1036 384.1037 384.1046 384.1056 384.1057 384.1058 384.1059 384.1060 384.1063 384.1064 384.1065 384.1066 384.1067 384.1069 384.1071 384.1074 384.1080 384.1081 384.1082 384.1083 384.1086 384.3001 384.3003 384.3006 384.3010 384.3011 384.3012 384.3078 384.3080 384.3081 384.3082 384.3083 384.3084 384.3350 384.3354 384.3355 384.3356 384.3394 384.3395 384.3400 384.3590 384.3591 384.3592 384.3593 384.3604 384.3606 384.3607 384.3608 384.3610 384.3611 384.3615 384.3622 384.3631 384.3636 384.3637 384.3639 384.3640 384.3643 384.3684 384.3687 384.3689 384.3690 384.3701 384.3703 384.3705 384.3706 384.3707 384.3710 384.3718 384.3720 384.3726 384.3732 384.3734 384.3735 384.3736 384.3737 384.3774 384.3782 384.3783 384.3806 384.3845 384.3846 384.3847 384.3857 384.3860 384.3861 384.4172 384.4196 384.4215 384.4217 384.4327 384.4329 384.4334 384.4335 384.4336 384.4347 384.4348 384.4349 384.4350 384.4351 384.4353 384.4385 384.4386 384.4402 384.4489 384.4490 384.4491 384.4492 384.4494 384.4495 384.4496 384.4514 384.4515 384.4516 384.4517 384.4519 384.4521 384.15966 384.15987 384.16610 384.16611 384.16689 384.16693 416.17 416.42 448.38 448.39 448.40 448.41 448.42 448.43 448.91 448.92 448.101 448.103 448.104 448.309 448.312 448.320 448.321 448.335 448.337 448.338 448.341 448.342 448.347 448.352 448.353 448.582 448.583 448.605 448.687 448.696 448.749 480.30 480.43 480.47 480.49 480.151 480.170", " ");
intrinsic MagmaAutGroup(G::LMFDBGrp) -> Grp
{Returns the automorphism group}
    // Unfortunately, both AutomorphismGroup and AutomorphismGroupSolubleGroup
    // can hang, and AutomorphismGroupSolubleGroup also has the potential to raise an error
    // The best we can do for now is to hard code cases where AutomorphismGroupSolubleGroup seems to be hanging.
    // Note that this often happens after calling RePresent
    if Get(G, "solvable") and not G`label in bad_cases then
        try
            return AutomorphismGroupSolubleGroup(G`MagmaGrp);
        catch e;
        end try;
    end if;
    return AutomorphismGroup(G`MagmaGrp);
end intrinsic;

intrinsic aut_group(G::LMFDBGrp) -> MonStgElt
    {returns label of automorphism group}
    aut:=Get(G, "MagmaAutGroup");
    try
        return label(aut);
    catch e;
        //print "aut_group", e;
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

intrinsic complete(G::LMFDBGrp) -> BoolElt
{}
    return (#Get(G, "MagmaCenter") eq 1 and Get(G, "outer_order") eq 1);
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
  Ns := Remove(Ns,#Ns); // remove full group;
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

intrinsic MagmaClassMap(G::LMFDBGrp) -> Map
  {Return Magma's ClassMap.}
  return ClassMap(G`MagmaGrp);
end intrinsic;

intrinsic ClassMap(G::LMFDBGrp) -> Map
{Renumbered version of the class map to align with our numbering}
    cc := ConjugacyClasses(G); // set as a side effect
    return G`ClassMap;
end intrinsic;

intrinsic MagmaConjugacyClasses(G::LMFDBGrp) -> SeqEnum
  {Return Magma's Conjugacy classes.}
  return ConjugacyClasses(G`MagmaGrp);
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
    g:=G`MagmaGrp;
    cc:=Get(G, "MagmaConjugacyClasses");
    cm:=Get(G, "MagmaClassMap");
    pm:=Get(G, "MagmaPowerMap");
    gens:=Get(G, "MagmaGenerators");
    ordercc, _, labels, G`number_divisions := ordercc(g,cc,cm,pm,gens);
    // We determine the number of rational characters

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
    sset := {1..#cc};
    permmap := map<sset->sset | [j -> perminv[j] : j in sset]>;
    G`ClassMap := cm*permmap; // Magma does composition backwards!
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
  vprint User1: "Magma character information found in", Cputime() - t;
  t0 := Cputime();
  t := t0;
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
    vprint User2: "B", j, Cputime() - t;
    t := Cputime();
  end for;
  vprint User1: "LMFDB complex character information computed in", Cputime() - t0;
  t0 := Cputime();
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
    vprint User2: "C", j, Cputime() - t;
    t := Cputime();
  end for;
  vprint User1: "LMFDB rational character information computed in", Cputime() - t0;
  /* This still needs labels and ordering for both types */
  sortdata:=characters_add_sort_and_labels(G, cchars, rchars);
  vprint User1: "Characters sorted and labeled in", Cputime() - t;
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
    G`wreath_data := None();
    if Get(G, "abelian") then return false; end if; // abelian groups can't be nontrivial wreath products
    GG := Get(G, "MagmaGrp");
    // Need GrpPerm for IsWreathProduct function call below. Check and convert if not GrpPerm.
    if Type(GG) ne GrpPerm then
        // We find an efficient permutation representation.
        ts := Get(G, "MagmaTransitiveSubgroup");
        if Type(ts) eq NoneType then
            return None();
        end if;
        phi, GG := CosetAction(GG, ts);
    else
        phi := IdentityHomomorphism(GG);
    end if;
    isw := IsWreathProduct(GG);
    if isw then
        // For some reason, Magma doesn't return 4 values when isw is false
        isw, A, B, C := IsWreathProduct(GG);
        BC := CosetImage(B, C);
        n, d := TransitiveGroupIdentification(BC);
        T := Sprintf("%oT%o", d, n);
        if G`all_subgroups_known or (Index(GG, A) le G`subgroup_index_bound and Index(GG, C) le G`subgroup_index_bound) then
            S := Get(G, "Subgroups"); // triggers labeling of subgroups
            L := BestSubgroupLat(G);
            A := L`subs[SubgroupIdentify(L, A @@ phi)];
            B := L`subs[SubgroupIdentify(L, B @@ phi)];
            C := L`subs[SubgroupIdentify(L, C @@ phi)];
            G`wreath_data := [A`label, B`label, C`label, T];
        else
            G`wreath_data := [GroupName(A: TeX:=true), GroupName(B: TeX:=true), T];
        end if;
    end if;
    return isw;
end intrinsic;

intrinsic wreath_data(G::LMFDBGrp) -> SeqEnum
{}
    _ := Get(G, "wreath_product");
    return G`wreath_data;
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

intrinsic pc_code(G::LMFDBGrp) -> RngInt
{}
    if not Get(G, "solvable") then
        return 0;
    end if;
    return SmallGroupEncoding(G`MagmaGrp);
end intrinsic;

intrinsic rank(G::LMFDBGrp) -> Any
{Calculates the rank of the group G: the minimal number of generators}
    if Get(G, "order") eq 1 then return 0; end if;
    if Get(G, "cyclic") then return 1; end if;
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
    if not G`subgroup_inclusions_known then return None(); end if;
    subs := Get(G, "Subgroups");
    for r in [2..Get(G, "order")] do
        if &+[Get(s, "subgroup_order")^r * s`mobius_function * s`count : s in subs] gt 0 then
            return r;
        end if;
    end for;
    error "rank calculation overflow";
end intrinsic;

intrinsic eulerian_function(G::LMFDBGrp) -> Any
{Calculates the Eulerian function of G for n = rank(G)}
    if Get(G, "order") eq 1 then return 1; end if;
    r := Get(G,"rank");
    tot := &+[Get(s, "subgroup_order")^r * s`mobius_function * s`count : s in Get(G, "Subgroups")];
    aut := Get(G, "aut_order");
    //print "tot", tot, "aut", aut;
    assert tot ne 0 and IsDivisibleBy(tot, aut);
    return tot div aut;
end intrinsic;

intrinsic MagmaCenter(G::LMFDBGrp) -> Grp
{}
    return Center(G`MagmaGrp);
end intrinsic;

intrinsic MagmaRadical(G::LMFDBGrp) -> Grp
{}
    return Radical(G`MagmaGrp);
end intrinsic;
