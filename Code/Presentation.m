/**********************************************************
This file supports computation of a human-friendly presentation
for solvable groups.
**********************************************************/

intrinsic CyclicQuotients(Ambient::Grp, H::Grp) -> SeqEnum
{The normal subgroups K of H with H/K cyclic, up to conjugacy inside Ambient}
    N := Normalizer(Ambient, H);
    D := DerivedSubgroup(H);
    Q, fQ := quo<H | D>;
    A, fA := AbelianGroup(Q);
    m := Exponent(A);
    d := Ngens(A);
    ords := [Order(A.i) : i in [1..d]];
    adjust := [m div ords[i] : i in [1..d]]; // match the order of each generator
    assert &*ords eq #Q;
    // We construct equivalence classes of homs H -> Q -> Z/m, up to the action of N
    // the kernels of these homs provide the cyclic quotients
    V := { v : v in CartesianProduct([[0..(m-1) by (m div ords[i])] : i in [1..d]])};
    Exclude(~V, <0 : _ in [1..d]>); // remove the trivial hom, corresponding to H itself
    VxN := CartesianProduct(V, N);
    lifts := [A.i @@ fA @@fQ : i in [1..d]];
    //action := map<VxN -> V | x :-> <c : c in Eltseq(((&*[lifts[i]^x[1][i] : i in [1..d]])^x[2]) @ fQ @ fA)>>;
    function dotprod(a, b)
        // assumes all have the same length
        return &+[a[i]*b[i] : i in [1..#a]];
    end function;
    action := map<VxN -> V | x :-> <dotprod(x[1], Eltseq((lifts[i]^(x[2]^-1)) @ fQ @ fA)) mod m : i in [1..d]>>;
    GS := GSet(N, V, action);
    orbs := Orbits(N, GS);
    // since we only care about the kernel, we identify homs generating the same cyclic subgroup in the dual.
    /*inj := Lat`Grp`HolInj; // remove
    for orb in orbs do
        print Join([Sprint(v) : v in orb], " ");
        fs := [hom<A -> C | [v[i]*z : i in [1..d]]> : v in orb];
        Ks := [Kernel(fQ * fA * fv) : fv in fs];
        print Join([Sprint(Lat!(K@@inj)) : K in Ks], " ");
    end for;*/
    vec_reps := [];
    scalars := [x : x in [2..m-1] | Gcd(x, m) eq 1];
    while #orbs gt 0 do
        o := orbs[1];
        v := o[1];
        Append(~vec_reps, v);
        Remove(~orbs, 1);
        for s in scalars do
            sv := <s*v[i] mod m : i in [1..d]>;
            for oi in [1..#orbs] do
                if sv in orbs[oi] then
                    Remove(~orbs, oi);
                    break;
                end if;
            end for;
        end for;
    end while;
    C := CyclicGroup(GrpAb, m); // GrpPC might be better?
    z := C.1;
    subgroups := [];
    for v in vec_reps do
        fv := hom<A -> C | [v[i]*z : i in [1..d]]>;
        Append(~subgroups, Kernel(fQ * fA * fv));
    end for;
    return subgroups;
end intrinsic;

RF := recformat<subgroup, order, length>;
intrinsic all_minimal_chains(G::LMFDBGrp : use_aut:=true) -> SeqEnum
{Returns minimal length chains of subgroups so that each is normal in the previous with cyclic quotient}
    assert IsSolvable(G`MagmaGrp);
    L := New(SubgroupLat); // we build a new subgroup list in order to be able to take advantage of the identification features.
    if use_aut then
        Ambient := Get(G, "Holomorph");
        inj := Get(G, "HolInj");
        GG := inj(G`MagmaGrp);
        L`outer_equivalence := true;
    else
        // Just using Ambient := G`MagmaGrp doesn't work, since GSet needs a permutation group
        //
        GG := G`MagmaGrp;
        Ambient := GG;
        inj := IdentityHomomorphism(GG);
        L`outer_equivalence := false;
    end if;
    L`Grp := G;
    L`inclusions_known := false;
    n := #GG;
    KK := SubgroupLatElement(L, GG : i:=1);
    L`subs := [KK];
    L`by_index := AssociativeArray();
    L`by_index[1] := [KK];
    cycdist := AssociativeArray();
    cycdist[1] := 0;
    reverse_path := AssociativeArray();
    Conjugators := AssociativeArray();
    Layer := {1};
    while true do
        NewLayer := {};
        vprint User1: "Minimal chains: layer of size", #Layer;
        for layer_ind in Layer do
            HH := L`subs[layer_ind];
            H := HH`subgroup;
            for K in CyclicQuotients(Ambient, H) do
                // We avoid gassman classification since we're working with subgroups of Ambient
                conj, i, elt := SubgroupIdentify(L, K : use_gassman:=false, get_conjugator:=true);
                if conj then
                    // It's possible that [i, HH`i] was already defined using a different subgroup, but that's not a problem
                    Conjugators[[i, HH`i]] := elt;
                    KK := L`subs[i];
                else
                    i := 1+#L`subs;
                    KK := SubgroupLatElement(L, K : i:=i);
                    Append(~L`subs, KK);
                    ind := n div KK`order;
                    if not IsDefined(L`by_index, ind) then
                        L`by_index[ind] := [];
                    end if;
                    Append(~L`by_index[ind], KK);
                    Include(~NewLayer, i);
                end if;
                if not IsDefined(cycdist, KK`i) or cycdist[KK`i] gt cycdist[HH`i] + 1 then
                    cycdist[KK`i] := cycdist[HH`i] + 1;
                    reverse_path[KK`i] := {HH};
                elif cycdist[KK`i] eq cycdist[HH`i] + 1 then
                    Include(~reverse_path[KK`i], HH);
                end if;
            end for;
        end for;
        Layer := NewLayer;
        if IsDefined(L`by_index, n) then
            break;
        elif (#Layer eq 0) then
            error "Didn't reach bottom";
        end if;
    end while;
    bottom := L`by_index[n][1];
    M := cycdist[bottom`i];
    chains := [[bottom]];
    for j in [1..M] do
        new_chains := [];
        for chain in chains do
            for x in reverse_path[chain[j]`i] do
                Append(~new_chains, Append(chain, x));
            end for;
        end for;
        chains := new_chains;
    end for;
    // We adjust the chains so that each subgroup is actually contained in the next, instead of only up to conjugacy
    vprint User1: "Fixing chains for actual containment";
    fixed_chains := [];
    for k in [1..#chains] do
        chain := chains[k];
        fixed_chain := [rec<RF|subgroup:=G`MagmaGrp, order:=n>];
        conjugator := Identity(GG);
        for j in [M..1 by -1] do
            sub := chain[j];
            super := chain[j+1];
            i := sub`i;
            if IsDefined(Conjugators, [sub`i, super`i]) then
                conjugator := Conjugators[[sub`i, super`i]] * conjugator;
            end if;
            sub := rec<RF|subgroup:=((sub`subgroup)^conjugator)@@inj, order:=sub`order>;
            Append(~fixed_chain, sub);
        end for;
        Append(~fixed_chains, Reverse(fixed_chain));
    end for;
    return fixed_chains;
end intrinsic;

chain_to_gens := function(chain)
    ans := [];
    G := chain[#chain]`subgroup;
    A := chain[1]`subgroup;
    for i in [2..#chain] do
        B := chain[i]`subgroup;
        r := #B div #A;
        assert A subset B;
        Q, fQ := quo<B | A>;
        assert IsCyclic(Q);
        C, fC := AbelianGroup(Q);
        g := G!((C.1@@fC)@@fQ);
        Append(~ans, <g, r, B>);
        A := B;
    end for;
    return ans;
end function;

gens_to_pc := function(GG, best)
    // This function takes a list ``best`` of tuples as output by chain_to_gens
    // and produces a pc group together with a list of integers describing
    // which generators are actually needed (others will be powers of these)
    // We have to fill in powers of our chosen generators since magma wants prime relative orders
    filled := [];
    H := sub<GG|>;
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
        filled cat:= Reverse(segment);
        H := tup[3];
    end for;
    // Magma has a descending filtration, so we switch to that here.
    Reverse(~filled);
    vprint User1: "filled", [<tup[1], tup[2], #tup[3]> : tup in filled];
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
    vprint User1: "rels", rels;
    H := quo< GrpPC : F | rels >;
    to_old := hom<H -> GG | [<PCGenerators(H)[i], gens[i]> : i in [1..#gens]]>;
    return H, to_old;
end function;

function pick_best_gens(gens)
    vprint User1: #gens, "generators (initial)";
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
    vprint User1: #gens, "generators (most identity relative powers)";

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
    vprint User1: #gens, "generators (most commuting pairs)";

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
    vprint User1: #gens, "generators (fewest out-of-order relative orders)";

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
    vprint User1: #gens, "generators (require minimal total depth)";

    orders := [[tup[2] : tup in chain] : chain in gens];
    ParallelSort(~orders, ~gens);

    // We can't feasibly make this deterministic, and we don't have any more ideas for
    // picking a "better" presentation, so we now just take the last one,
    // which has the largest relative order for the first generator (and so on)

    return gens[#gens];
    //print "best", [<tup[1], tup[2], #tup[3]> : tup in best];
end function;

/*
The following groups took more than an hour to RePresent (timed out)
256.31887
256.31977
256.34703
256.34815
256.34850
256.36305
256.36405
256.36567
256.36781
256.36968
256.37611
256.39106
256.39782
256.40191
256.41187
256.41294
256.42185
256.44886
256.52508
*/
intrinsic RePresent(G::LMFDBGrp : reset_attrs:=true, use_aut:=true)
{Changes G`MagmaGrp to a better presentation.
This function is only safe to call on a newly created group, since it changes MagmaGrp (and thus invalidates a lot of attributes)}
    //print "#gensA", #gens;
    // Figure out which gives the "best" presentation.  Desired features:
    // * raising each generator to its relative order gives the identity
    // * fewer conjugacy relations
    // * relative orders are non-increasing
    // * RHS of conjugacy relations are "deeper"
    GG := G`MagmaGrp;
    if #GG ne 1 and IsSolvable(GG) then
        chains := all_minimal_chains(G : use_aut:=use_aut);
        gens := [chain_to_gens(chain) : chain in chains];
        best := pick_best_gens(gens);
        H, to_old := gens_to_pc(GG, best);

        // Now we build a new PC group with an isomorphism to our given one.
        //print sprint([x : x in GetAttributes(LMFDBGrp) | assigned G``x]);
        //[CCAutCollapse,CCpermutation,CCpermutationInv]
        G`MagmaGrp := H;
        G`IsoToOldPresentation := to_old;
        // We have to reset Holomorph, HolInj, ClassMap to use the new group
        // We could instead compose with the isomorphism between the new and old group, but that seems
        // prone to errors since it keeps the old group around
        //print "MagmaAutGroup", Get(G, "pc_code");
        if reset_attrs then
            G`MagmaAutGroup := MagmaAutGroup(G);
            G`Holomorph := Holomorph(G);
            G`HolInj := HolInj(G);
            // Various conjugacy class attributes were set in determining an ordering on conjugacy classes for Gassman vectors
            G`MagmaConjugacyClasses := MagmaConjugacyClasses(G);
            G`MagmaClassMap := MagmaClassMap(G);
            G`MagmaPowerMap := MagmaPowerMap(G);
            G`MagmaGenerators := MagmaGenerators(G);
            G`ConjugacyClasses := ConjugacyClasses(G); // also sets CCpermutation, CCpermutationInv and ClassMap
            G`CCAutCollapse := CCAutCollapse(G);
        end if;
    else
        G`IsoToOldPresentation := IdentityHomomorphism(G`MagmaGrp);
    end if;
end intrinsic;

intrinsic RePresentFastest(G::LMFDBGrp)
{Very basic version that just depends on computing derived subgroups and smith decomposition}
    GG := G`MagmaGrp;
    H := GG;
    chain := [rec<RF|subgroup:=H, order:=#H>];
    while #H gt 1 do
        D := DerivedSubgroup(H);
        A, proj := quo<H | D>;
        basis := AbelianBasis(A);
        H := sub<GG | D, sub<GG | [basis[j]@@proj : j in [1..#basis-1]]>>;
        Append(~chain, rec<RF|subgroup:=H, order:=#H>);
    end while;
    Reverse(~chain);

    gens := chain_to_gens(chain);
    Gnew, to_old := gens_to_pc(GG, gens);
    G`MagmaGrp := Gnew;
    G`IsoToOldPresentation := to_old;
end intrinsic;

function random_chain(GG)
    H := GG;
    chain := [rec<RF|subgroup:=H, order:=#H>];
    while #H gt 1 do
        D := DerivedSubgroup(H);
        A, proj := quo<H | D>;
        basis, invs := AbelianBasis(A);
        i := Random([1..#invs]);
        H := sub<GG | D, sub<GG | [basis[j]@@proj : j in [1..#invs] | j ne i]>>;
        Append(~chain, rec<RF|subgroup:=H, order:=#H>);
    end while;
    Reverse(~chain);
    return chain;
end function;

intrinsic RePresentRand(G::LMFDBGrp : reps:=60)
{Randomly construct chains and pick the best}
    gens := [chain_to_gens(random_chain(G`MagmaGrp)) : _ in [1..reps]];
    best := pick_best_gens(gens);
    Gnew, to_old := gens_to_pc(G`MagmaGrp, best);
    G`MagmaGrp := Gnew;
    G`IsoToOldPresentation := to_old;
end intrinsic;

intrinsic RePresentFast(G::LMFDBGrp)
{Changes G`MagmaGrp to give a more human readable presentation.
Much faster than RePresent, but may not give as good a presentation.
This function is only safe to call on a newly created group, since it changes MagmaGrp (and thus invalidates a lot of attributes)}
    // We greedily build from the top down.
    // This version will only work with permutation groups, and will struggle with groups that are close to abelian
    GG := G`MagmaGrp;
    H := GG;
    chain := [rec<RF|subgroup:=H, order:=#H>];
    while #H gt 1 do
        C := CyclicQuotients(GG, H);
        m := Max([Index(H, c) : c in C]);
        poss := [c : c in C | Index(H, c) eq m];
        if #poss gt 1 then
            invs := [AbelianQuotientInvariants(PCGroup(c)) : c in poss];
            m := Max([Max(inv) : inv in invs]);
            poss := [poss[i] : i in [1..#poss] | Max(invs[i]) eq m];
        end if;
        H := Random(poss);
        Append(~chain, rec<RF|subgroup:=H, order:=#H>);
    end while;
    Reverse(~chain);
    gens := chain_to_gens(chain);
    G`MagmaGrp, G`IsoToOldPresentation := gens_to_pc(GG, gens);
end intrinsic;
