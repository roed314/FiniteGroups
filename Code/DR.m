
cycquos := function(Lat, h)
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
            Include(~ans, Lat!(Bsub@@fA));
        end if;
    end for;
    return ans;
end function;

all_minimal_chains := function(G, Lat)
    assert IsSolvable(G);
    cycdist := AssociativeArray();
    top := Lat!(#Lat);
    bottom := Lat!1;
    cycdist[top] := 0;
    reverse_path := AssociativeArray();
    cqsubs := AssociativeArray();
    Seen := {top};
    Layer := {top};
    while true do
        NewLayer := {};
        for h in Layer do
            cq := cycquos(Lat, h);
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
        if bottom in Layer then
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
    pc_code := SmallGroupEncoding(Codomain(G`OptimizedIso));
    return pc_code;
end intrinsic;
