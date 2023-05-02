/**********************************************************
This file supports computation of subgroups of abstract groups.
**********************************************************/

VS_QUOTIENT_CUTOFF := 5; // if G has a subquotient vector space of dimension larger than this, we always compute up to automorphism;
NUM_SUBS_RATCHECK := 128; // if G has less than this many subgroups up to conjugacy, we definitely compute them up to conjugacy (and the orbits under Aut(G)
NUM_SUBS_RATIO := 2; // if G has between NUM_SUBS_RATCHECK and NUM_SUBS_CUTOFF_CONJ subgroups up to conjugacy, we record up to conjugacy (and the orbits under Aut(G))
NUM_SUBS_CUTOFF_CONJ := 1024; // if G has at least this many subgroups up to conjugacy, we compute subgroups up to automorphism (or truncate at this point if outer_equivalence has been set to false externally)
NUM_SUBS_CUTOFF_AUT := 4096; // if G has at least this many subgroups up to automorphism, we only compute subgroups up to automorphism, and up to an index bound
NUM_SUBS_LIMIT_AUT := 1024; // if we compute up to an index bound, we set it so that less than this many subgroups up to automorphism are stored
NUM_NORMALS_NOAUT_LIMIT := 4096; // when only computing subgroups up to conjugacy, we trim the list of normal subgroups to keep it from getting out of hand; this is the limit
LAT_CUTOFF := 4096; // if G has less than this many subgroups up to automorphism, we compute inclusion relations for the lattices of subgroups (both up-to-automorphism and, if present, up-to-conjugacy)

intrinsic AllSubgroupsOk(G::LMFDBGrp) -> BoolElt
{}
    // A simple heuristic on whether Subgroups(G) might take a very long time
    E := ElementaryAbelianSeriesCanonical(G`MagmaGrp);
    for i in [1..#E-1] do
        if Factorization(Order(E[i]) div Order(E[i+1]))[1][2] gt VS_QUOTIENT_CUTOFF then
            return false;
        end if;
    end for;
    return true;
end intrinsic;

intrinsic outer_equivalence(G::LMFDBGrp) -> Any
{Whether subgroups are computed up to automorphism (vs only up to conjugacy)}
    // Just using #byA gives an infinite recursion, since some steps in the computation of byA
    // require knowing outer_equivalence
    // Instead, we set a numerical variable during the computation of byA that serves as a proxy: the number of subgroups above the cutoff
    a := Get(G, "AutAboveCutoff");
    b := Get(G, "AutIndexBound");
    if a ge NUM_SUBS_CUTOFF_CONJ or b ne 0 or not Get(G, "AllSubgroupsOk") then
        // too many subgroups up to automorphism, so we don't need to compute the list up to conjugacy
        //printf "%o subgroups up to automorphism (min order %o, ok %o), so not computing up to conjugacy\n", #byA, byA[1]`order, AllSubgroupsOk(GG);
        return true;
    end if;
    c := Get(G, "number_subgroup_classes");
    return c ge NUM_SUBS_RATCHECK and c ge NUM_SUBS_RATIO * a;
end intrinsic;

intrinsic AutAboveCutoff(G::LMFDBGrp) -> RngIntElt
{}
    dummy := Get(G, "SubGrpLstAut"); // triggers computation, set halfway through to prevent infinite recursion
    return G`AutAboveCutoff;
end intrinsic;

intrinsic AutIndexBound(G::LMFDBGrp) -> RngIntElt
{}
    dummy := Get(G, "SubGrpLstAut"); // triggers computation, set halfway through to prevent infinite recursion
    return G`AutIndexBound;
end intrinsic;

intrinsic SubGrpLstCutoff(G::LMFDBGrp) -> FldReElt
{}
    // For now we just set to a constant value; it should probably be changed based on manifest
    return 600;
end intrinsic;

intrinsic subgroup_index_bound(G::LMFDBGrp) -> RngIntElt
{}
    return Get(G, "BestSubgroupLat")`index_bound;
end intrinsic;

intrinsic all_subgroups_known(G::LMFDBGrp) -> BoolElt
{}
    return Get(G, "subgroup_index_bound") eq 0;
end intrinsic;

intrinsic maximal_subgroups_known(G::LMFDBGrp) -> BoolElt
{Can be set externally to prevent computation of maximal subgroups beyond index bound}
    return true;
end intrinsic;

intrinsic normal_subgroups_known(G::LMFDBGrp) -> BoolElt
{Can be set externally to prevent computation of normal subgroups beyond index bound}
    return true;
end intrinsic;

intrinsic complements_known(G::LMFDBGrp) -> BoolElt
{Can be set externally to prevent computation of complements (done for one case in SubGrpLstAut)}
    return Get(G, "normal_subgroups_known");
end intrinsic;

intrinsic sylow_subgroups_known(G::LMFDBGrp) -> BoolElt
{Can be set externally to prevent computation of Sylow subgroups beyond index bound}
    return true;
end intrinsic;

intrinsic subgroup_inclusions_known(G::LMFDBGrp) -> BoolElt
{Can be set externally to prevent computation of subgroup inclusions (note that this will screw up labeling)}
    // (#byA lt LAT_CUTOFF and byA`index_bound eq 0);
    return true;
end intrinsic;

RF := recformat<subgroup, order, length>;
declare type SubgroupLatElt;
declare attributes SubgroupLatElt:
        Lat,
        NormLatElt,
        MaxLatElt,
        subgroup,
        order,
        gens,
        sort_gens, // used for labeling: a canonical choice of generators of some subgroup in this class; independent of which subgroup was initially chosen
        sort_pick, // the subgroup generated by sort_gens.  This can be set without sort_gens if normal
        sort_conj, // an element conjugating subgroup to sort_pick
        aut_sort_gens, // used for labeling: a canonical choice of generators of some subgroup in this class; independent of which subgroup was initially chosen
        aut_sort_pick, // the subgroup generated by aut_sort_gens.  This can be set without sort_gens if characteristic
        aut_sort_conj, // an element conjugating subgroup to aut_sort_pick, in the Holomorph
        i, // can be negative during construction, but set to the index in subs when complete
        aut_label, // list of integers giving the automorphism part of the label
        full_label, // list of integers giving the full label
        label, // string giving the label (omitting the N.i from the group label)
        special_labels, // other labels (normal, maximal, special; omitting the N.i)
        unders, // other subs this sub contains maximally, as an associative array i->cnt, where i is the index in subs and cnt is the number of reps in that class contained in a single rep of this class
        overs, // other subs this sub is contained in minimally, in the same format
        normal_unders, // normal subgroups this sub contains maximally, as a set of i
        normal_overs, // normal subgroups this sub is contained in minimally, as a set of i
        mobius_sub, // value of the mobius subgroup function on this node of the lattice
        mobius_quo, // value of the mobius quotient function on this node of the lattice
        aut_overs, // as above, but up to automorphism
        subgroup_count, // the number of subgroups in this conjugacy class of subgroups
        cc_count, // the number of conjugacy classes in this autjugacy class of subgroups
        recurse,
        standard_generators,
        gassman_vec, // for identification
        aut_gassman_vec, // for identification
        orig_gassman_vec, // used when we don't want to do any labeling
        easy_hash, // for identification
        keep, // to indicate that this subgroup shouldn't be trimmed
        normalizer,
        centralizer,
        normal,
        characteristic,
        core,
        core_order,
        complements,
        split,
        normal_closure,
        characteristic_closure;

declare type SubgroupLat;
declare attributes SubgroupLat:
        Grp,
        NormLat,
        MaxLat,
        outer_equivalence,
        inclusions_known,
        subs,
        by_index,
        by_index_aut,
        ordered_subs,
        conjugator,
        aut_class,
        aut_orbit,
        from_conj,
        aut_component_data,
        index_bound;

declare type SubgroupLatInterval;
declare attributes SubgroupLatInterval:
        Lat,
        top,
        bottom,
        subs,
        by_index;

declare type LMFDBSubgroupCache;
declare attributes LMFDBSubgroupCache:
        MagmaGrp,
        Subgroups,
        description, // a string usable to reconstruct the ambient group
        outer_equivalence, // true if up to automorphism
        labels, // a list of labels of subgroups
        gens, // a list of lists of elements generating the subgroups
        lengths, // a list of lengths (number of subgroups in the equivalence class)
        standard; // a list of booleans; whether the generators correspond to the standard generators for that abstract group

declare type LMFDBSubgroupCacheCollection;
declare attributes LMFDBSubgroupCacheCollection:
        cache;
subgroup_cache := New(LMFDBSubgroupCacheCollection);
subgroup_cache`cache := AssociativeArray();
// Add layer of indirection so that Magma lets us modify the cache
intrinsic GetSubgroupCacheCollection() -> LMFDBSubgroupCacheCollection
{}
    return subgroup_cache;
end intrinsic;

intrinsic GetGrp(C::LMFDBSubgroupCache) -> LMFDBGrp
{}
    G := New(LMFDBGrp);
    G`MagmaGrp := C`MagmaGrp;
    return G;
end intrinsic;

intrinsic LoadSubgroupCache(label::MonStgElt : sep:=":") -> LMFDBSubgroupCache
{}
    sgcache := GetSubgroupCacheCollection();
    if IsDefined(sgcache`cache, label) then
        return sgcache`cache[label];
    end if;
    C := New(LMFDBSubgroupCache);
    folder := GetLMFDBRootFolder();
    if #folder ne 0 then
        cache := folder * "SUBCACHE/" * label;
        ok, I := OpenTest(cache, "r");
        if ok then
            data := Read(I);
            data := Split(data, sep: IncludeEmpty := true);
            attrs := DefaultAttributes(LMFDBSubgroupCache);
            error if #data ne #attrs, "Wrong size data line";
            C`description := data[1];
            C`MagmaGrp := eval data[1];
            for i in [2..#attrs] do
                attr := attrs[i];
                C``attr := LoadAttr(attr, data[i], C);
            end for;
        end if;
    end if;
    sgcache`cache[label] := C;
    return C;
end intrinsic;

intrinsic SaveSubgroupCache(G::LMFDBGrp, subs::SeqEnum : sep:=":")
{We only save subgroup caches when complete (no index bound)}
    folder := GetLMFDBRootFolder();
    if #folder ne 0 then
        C := New(LMFDBSubgroupCache);
        C`outer_equivalence := Get(G, "outer_equivalence");
        C`description := description(G);
        C`labels := [H`label : H in subs];
        C`gens := [H`generators : H in subs];
        C`standard := [H`standard_generators : H in subs];
        data := SaveLMFDBObject(C : attrs := ["description", "labels", "gens", "standard"]);
        ok, I := OpenTest(folder * "SUBCACHE/" * G`label, "w");
        if ok then
            PrintFile(I, data);
        end if;
    end if;
end intrinsic;

intrinsic Valid(C::LMFDBSubgroupCache) -> BoolElt
{}
    return assigned C`description;
end intrinsic;

function SplitByAuts(L, G : use_order:=true, use_hash:=true, use_gassman:=false, aut:=true, fill_orbits:=false)
    // when aut is false we are using this function to group subgroups up to CONJUGACY,
    // in cases where the subgroups were iteratively found up to conjugacy inside a smaller group
    // than G
    // L is a list of lists of records, SubgroupLatElts or subgroups (if record, includes `order and `subgroup)
    // It should be closed under the action of the automorphism group (up to conjugacy), unless fill_orbits is set to true in which case additional conjugacy classes of subgroups will be added (fill_orbits should only be used when L consists of actual subgroups, rather than records or SubgroupLatElts)
    // Gassman class is slow in holomorphs
    function check_done(M)
        return &and[#x eq 1 : x in M];
    end function;
    function get_order(x)
        if Type(x) eq Rec or Type(x) eq SubgroupLatElt then return x`order; end if;
        return #x;
    end function;
    function get_easy_hash(x)
        if Type(x) eq SubgroupLatElt then return Get(x, "easy_hash"); end if;
        if Type(x) eq Rec then x := x`subgroup; end if;
        return EasyHash(x);
    end function;
    gvstr := aut select "aut_gassman_vec" else "gassman_vec";
    function get_gassman_vec(x)
        if Type(x) eq SubgroupLatElt then return Get(x, gvstr); end if;
        if Type(x) eq Rec then x := x`subgroup; end if;
        if gvstr eq "gassman_vec" then
            return SubgroupClass(x, Get(G, "ClassMap"));
        else
            return SubgroupClass(x, AutClassMap(G));
        end if;
    end function;
    function get_subgroup(x)
        if Type(x) eq Rec or Type(x) eq SubgroupLatElt then return x`subgroup; end if;
        return x;
    end function;
    if check_done(L) then return L; end if;
    if use_order then
        newL := [];
        for chunk in L do
            if #chunk gt 1 then
                newL cat:= [x : x in IndexFibers(chunk, get_order)];
            else
                Append(~newL, chunk);
            end if;
        end for;
        L := newL;
        if check_done(L) then return L; end if;
    end if;
    if use_hash then
        newL := [];
        for chunk in L do
            if #chunk gt 1 then
                newL cat:= [x : x in IndexFibers(chunk, get_easy_hash)];
            else
                Append(~newL, chunk);
            end if;
        end for;
        L := newL;
        if check_done(L) then return L; end if;
    end if;
    if use_gassman then
        newL := [];
        for chunk in L do
            if #chunk gt 1 then
                newL cat:= [x : x in IndexFibers(chunk, get_gassman_vec)];
            else
                Append(~newL, chunk);
            end if;
        end for;
        L := newL;
        if check_done(L) then return L; end if;
    end if;
    newL := [];
    GG := G`MagmaGrp;
    Auts := 0; outs := 0; H := 0; inj := 0; cm := 0; outperms := []; // stupid Magma compiler requires these to be defined since used below
    if not aut then
        H := G`MagmaGrp;
        inj := IdentityHomomorphism(H);
        use_graph := false;
    elif Get(G, "HaveHolomorph") then
        H := Get(G, "Holomorph");
        inj := Get(G, "HolInj");
        use_graph := false;
    else
        // We spend some time minimizing the number of generators here, since the runtime below is directly proportional to the number of generators
        outs := Get(G, "FewOuterGenerators");
        // We don't need the renumbered class map for this application
        cm := Get(G, "MagmaClassMap");
        CC := Get(G, "MagmaConjugacyClasses");
        // outperm[l] = index of f(lth conj cls)
        // so gv1[outperm[l]] = count of the f(lth conj class) that lies in H1
        // Want count of the lth conj class that lies in f(H1)
        outperms := [[cm(cc[3] @ f) : cc in CC] : f in outs];
        use_graph := true;
    end if;
    for chunki in [1..#L] do
        chunk := L[chunki];
        if #chunk gt 1 then
            if use_graph then
                edges := [{Integers()|} : _ in [1..#chunk]];
                gvecs := [SubgroupClass(get_subgroup(chunk[i]), cm) : i in [1..#chunk]];
                by_gvec := AssociativeArray();
                for i in [1..#chunk] do
                    gv := gvecs[i];
                    if IsDefined(by_gvec, gv) then
                        Append(~by_gvec[gv], i);
                    else
                        by_gvec[gv] := [i];
                    end if;
                end for;
                orig_len := #chunk;
                i := 1;
                while i le #chunk do
                    H1 := get_subgroup(chunk[i]);
                    gv1 := gvecs[i];
                    for k in [1..#outs] do
                        f := outs[k];
                        outperm := outperms[k];
                        gv2 := Sort([[outperm[pair[1]], pair[2]] : pair in gv1]);
                        if IsDefined(by_gvec, gv2) then
                            poss := by_gvec[gv2];
                            if #poss eq 1 and not fill_orbits then
                                // only one possibility
                                Include(~(edges[i]), poss[1]);
                                continue;
                            end if;
                            H2 := f(H1);
                            // check first if fixed by f, since this is common and means no edge
                            if gv1 eq gv2 and IsConjugate(GG, H1, H2) then
                                continue;
                            end if;
                            found := false;
                            for j in poss do
                                if i ne j and IsConjugate(GG, H2, get_subgroup(chunk[j])) then
                                    Include(~(edges[i]), j);
                                    found := true;
                                    break;
                                end if;
                            end for;
                            if not found then
                                if fill_orbits then
                                    Append(~chunk, H2);
                                    Append(~edges, {Integers()|});
                                    Include(~edges[i], #chunk);
                                    Append(~gvecs, gv2);
                                    Append(~by_gvec[gv2], #chunk);
                                else
                                    error "subgroups not closed under automorphism";
                                end if;
                            end if;
                        elif fill_orbits then
                            Append(~chunk, f(H1));
                            Append(~edges, {Integers()|});
                            Include(~edges[i], #chunk);
                            Append(~gvecs, gv2);
                            by_gvec[gv2] := [#chunk];
                        else
                            error "subgroups not closed under automorphism";
                        end if;
                    end for;
                    i +:= 1;
                end while;
                V := Graph<#chunk| edges : SparseRep := true>;
                // We restrict i to being less than orig_len so that the return value only contains subgroups that were passed in.
                newL cat:= [[chunk[i] : i in Sort([Index(j) : j in comp]) | i le orig_len] : comp in Components(V)];
            else
                new_chunk := [];
                for s in chunk do
                    found := false;
                    j := 1;
                    while j le #new_chunk do
                        x := new_chunk[j];
                        if IsConjugate(H, inj(get_subgroup(s)), inj(get_subgroup(x[1]))) then
                            found := true;
                            break;
                        end if;
                        j +:= 1;
                    end while;
                    if found then
                        Append(~new_chunk[j], s);
                    else
                        Append(~new_chunk, [s]);
                    end if;
                end for;
                newL cat:= new_chunk;
            end if;
        else
            Append(~newL, chunk);
        end if;
    end for;
    return newL;
end function;

intrinsic by_index(Lat::SubgroupLat) -> Assoc
{An associative array with integer keys and values the list of subgroups with that index}
    L := Lat`subs;
    n := (Lat`Grp)`order;
    AA := AssociativeArray();
    for j in [1..#L] do
        H := L[j];
        index := n div H`order;
        if not IsDefined(AA, index) then
            AA[index] := [];
        end if;
        Append(~AA[index], H);
    end for;
    return AA;
end intrinsic;

intrinsic by_index(Int::SubgroupLatInterval) -> Assoc
{An associative array with integer keys and values the list of subgroups with that index}
    L := Int`subs;
    n := Int`top`Lat`Grp`order;
    AA := AssociativeArray();
    for H in Int`subs do
        ind := n div H`order;
        if not IsDefined(AA, ind) then
            AA[ind] := [H];
        end if;
        Append(~AA[ind], H);
    end for;
    return AA;
end intrinsic;

intrinsic ordered_subs(L::SubgroupLat) -> SeqEnum
{Subgroups ordered by index}
    bi := Get(L, "by_index");
    return &cat[bi[m] : m in Sort([k : k in Keys(bi)])];
end intrinsic;

intrinsic by_index_aut(L::SubgroupLat) -> Assoc
{}
    t0 := ReportStart(L`Grp, "by_index_aut");
    ans := AssociativeArray();
    for index -> subs in Get(L, "by_index") do
        if L`outer_equivalence then
            ans[index] := [[s] : s in subs];
        else
            ans[index] := SplitByAuts([subs], L`Grp : use_order:=false);
        end if;
    end for;
    ReportEnd(L`Grp, "by_index_aut", t0);
    return ans;
end intrinsic;

intrinsic aut_class(L::SubgroupLat) -> Assoc
{}
    bia := Get(L, "by_index_aut");
    ans := AssociativeArray();
    aut_orbit := AssociativeArray();
    for index -> aclasses in bia do
        for aclass in aclasses do
            orbit := [s`i : s in aclass];
            first := Min(orbit);
            for s in aclass do
                ans[s`i] := first;
                aut_orbit[s`i] := orbit;
            end for;
        end for;
    end for;
    L`aut_orbit := aut_orbit;
    return ans;
end intrinsic;

intrinsic aut_orbit(L::SubgroupLat) -> Assoc
{}
    _ := Get(L, "aut_class"); // Sets aut_orbit
    return L`aut_orbit;
end intrinsic;

intrinsic HaveHolomorph(X::LMFDBGrp) -> BoolElt
{Current implementation of Holomorph is as a permutation group of degree #G, which becomes infeasible as G grows}
    // Even for small groups, there may be cases where where the non-holomorph approach is faster.  Should profile
    return X`order lt 5000;
end intrinsic;

intrinsic HaveAutomorphisms(X::LMFDBGrp) -> BoolElt
{This variable controls whether we attempt to compute the automorphism group; it is true by default but can be set to false externally}
    return true;
end intrinsic;

intrinsic Holomorph(X::LMFDBGrp) -> Grp
{}
    assert Get(X, "HaveHolomorph");
    G := X`MagmaGrp;
    A := Get(X, "MagmaAutGroup");
    H, inj := Holomorph(G, A);
    // Work around a Magma bug with an incorrect holomorph
    if #H ne #A * #G then
        H := Normalizer(H, inj(G));
        assert #H eq #A * #G;
    end if;
    X`HolInj := inj;
    return H;
end intrinsic;

intrinsic HolInj(X::LMFDBGrp) -> HomGrp
{}
    _ := Holomorph(X); // computes the injection
    return X`HolInj;
end intrinsic;

intrinsic FewOuterGenerators(X::LMFDBGrp) -> SeqEnum
{A short list of generators for the outer automorphism group (ie automorphisms whose images generate the outer automorphism group)}
    t0 := ReportStart(X, "FewOuterGenerators");
    outs := FewGenerators(Get(X, "MagmaAutGroup") : outer:=true);
    ReportEnd(X, "FewOuterGenerators", t0);
    return outs;
end intrinsic;

intrinsic aut_component_data(L::SubgroupLat) -> Tuple
{Returns lookup, inv_lookup, retract; where lookup[i] is the index i0 of the chosen subgroup in the same component as subs[i], inv_lookup[i0] is the list of all i in the same component as i0, and retract[i] is an automorphism mapping subs[i] to subs[i0]}
    subs := Get(L, "by_index_aut");
    t0 := ReportStart(L`Grp, "aut_component_data");
    subs := &cat[subs[n] : n in Sort([k : k in Keys(subs)])];
    lookup := AssociativeArray();
    inv_lookup := AssociativeArray();
    retract := AssociativeArray();
    G := L`Grp;
    GG := G`MagmaGrp;
    Aut := Get(G, "MagmaAutGroup");
    outs := Get(G, "FewOuterGenerators");
    cm := Get(G, "ClassMap");
    /*
    Each of the entries in subs is an automorphism class of subgroups, consisting of a sequence of conjugacy classes making up the automorphism class.

    lookup and inv_lookup are easy to compute from this data: they're just a record of the mapping from the list of conjugacy classes to the list of automorphism classes.

    To find retract, we take automorphisms that generate the outer automorphism group,
    and think about these as giving edges between conjugacy classes of subgroups.
    For each automorphism class the corresponding graph will be connected
    (the automorphism classes are precisely the connected components),
    so we can work out from the first conjugacy class until we reach all the vertices,
    tracking the automorphisms used as we go.
    */
    for i in [1..#subs] do
        comp := subs[i];
        inv_lookup[i] := [H`i : H in comp];
        for H in comp do
            lookup[H`i] := i;
        end for;
        retract[comp[1]`i] := Identity(Aut);
        seen := {1};
        layer := {1};
        by_gvec := AssociativeArray();
        if #comp gt 1 then
            for i in [2..#comp] do
                H := comp[i];
                if L`outer_equivalence then
                    // We don't want to use Get(x, "gassman_vec") since that switches to aut_gassman_vec when outer_equivalence is set
                    gv := SubgroupClass(H`subgroup, cm);
                else
                    gv := Get(H, "gassman_vec");
                end if;
                if not IsDefined(by_gvec, gv) then
                    by_gvec[gv] := [];
                end if;
                Append(~by_gvec[gv], i);
            end for;
        end if;
        while #seen lt #comp do
            new_layer := {};
            for j in layer do
                H := comp[j]`subgroup;
                for f in outs do
                    K := f(H);
                    gvK := SubgroupClass(K, cm);
                    if not IsDefined(by_gvec, gvK) then
                        // this can happen if K is in the class of comps[1], since we didn't add that
                        continue;
                    end if;
                    for k in by_gvec[gvK] do
                        if not (k in seen) then
                            conj, c := IsConjugate(GG, K, comp[k]`subgroup);
                            if conj then
                                fc := Aut!hom<GG -> GG | [g -> g^c : g in Generators(GG)]>;
                                Include(~seen, k);
                                Include(~new_layer, k);
                                retract[comp[k]`i] := fc^-1 * f^-1 * retract[comp[j]`i];
                            end if;
                        end if;
                    end for;
                end for;
            end for;
            assert #new_layer gt 0;
            layer := new_layer;
        end while;
    end for;
    ReportEnd(L`Grp, "aut_component_data", t0);
    return <lookup, inv_lookup, retract>;
end intrinsic;

// As an alternative to the Holomorph, we can form a graph on the set of conjugacy classes (of elements or of subgroups) with edges given by the generators of the automorphism group, and then use connected components and geodesics
//
intrinsic IsAutjugateSubgroup(L::SubgroupLat, H1::Grp, H2::Grp) -> BoolElt, GrpElt
{Whether H1 and H2 are related by an automorphism, and an automorphism with f(H1) = H2 if they are}
    G := L`Grp;
    GG := G`MagmaGrp;
    A := Get(G, "MagmaAutGroup");
    if assigned L`from_conj then
        conjL, lookup, inv_lookup := Explode(L`from_conj);
        b, c := IsAutjugateSubgroup(conjL, H1, H2);
        return b, c;
    elif L`outer_equivalence then
        Ambient := Get(G, "Holomorph");
        inj := Get(G, "HolInj");
        b, c := IsConjugateSubgroup(Ambient, inj(H1), inj(H2));
        if b then
            f := hom<GG -> GG | [g -> ((g @ inj)^c) @@ inj : g in Generators(GG)]>;
            return true, A!f;
        else
            return false, _;
        end if;
    end if;
    b1, i1, c1 := SubgroupIdentify(L, H1 : get_conjugator:=true); assert b1;
    b2, i2, c2 := SubgroupIdentify(L, H2 : get_conjugator:=true); assert b2;
    lookup, inv_lookup, retract := Explode(Get(L, "aut_component_data"));
    i0 := lookup[i1]; i0x := lookup[i2];
    if i0 ne i0x then return false, _; end if;
    f1 := A!hom<GG -> GG | [g -> g^(c1^-1) : g in Generators(GG)]>;
    f2 := A!hom<GG -> GG | [g -> g^c2 : g in Generators(GG)]>;
    return true, f1 * retract[i1] * retract[i2]^-1 * f2;
end intrinsic;

intrinsic CCAutCollapse(X::LMFDBGrp) -> Map
{}
    CC := Get(X, "ConjugacyClasses");
    use_hol := Get(X, "HaveHolomorph");
    ccac_str := Sprintf("CCAutCollapse(%o)", use_hol select "hol" else "aut");
    t0 := ReportStart(X, ccac_str);
    if use_hol then
        Hol := Get(X, "Holomorph");
        inj := Get(X, "HolInj");
        D := Classify([1..#CC], func<i, j | IsConjugate(Hol, inj(CC[i]`representative), inj(CC[j]`representative))>);
    elif Get(X, "HaveAutomorphisms") then
        Aut := Get(X, "MagmaAutGroup");
        cm := Get(X, "ClassMap");
        outs := Get(X, "FewOuterGenerators");
        edges := [{Integers()|} : _ in [1..#CC]];
        for f in outs do
            for i in [1..#CC] do
                j := cm(f(CC[i]`representative));
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
    for i in [1..#D] do
        for j in [1..#D[i]] do
            A[D[i][j]] := i;
        end for;
    end for;
    ReportEnd(X, ccac_str, t0);
    return AssociativeArrayToMap(A, [1..#D]);
end intrinsic;

intrinsic AutClassMap(G::LMFDBGrp) -> Map
{}
    return Get(G, "ClassMap") * Get(G, "CCAutCollapse");
end intrinsic;

function SolvAutSubs(X : normal:=false)
    G := X`MagmaGrp;
    Ambient := Get(X, "Holomorph");
    inj := Get(X, "HolInj");
    GG := inj(G);
    E := ElementaryAbelianSeriesCanonical(G);
    EE := [inj(e) : e in E];
    subs := Subgroups(sub<GG|> : Presentation:=true);
    for i in [1..#EE-1] do
        subs := SubgroupsLift(Ambient, EE[i], EE[i+1], subs);
        if normal then
            subs := [S : S in subs | IsNormal(GG, sub<GG|S`subgroup, EE[i+1]>)];
        end if;
    end for;
    return [ rec< RF | subgroup := s`subgroup @@ inj, order := s`order> : s in subs ];
end function;

intrinsic is_sylow_order(X::LMFDBGrp, m::RngIntElt) -> BoolElt
{}
    N := Get(X, "order");
    // Apparently 1 is not a prime power in Magma
    return m eq 1 or IsPrimePower(m) and Gcd(m, N div m) eq 1;
end intrinsic;

intrinsic IsCharacteristic(G::LMFDBGrp, H::Grp) -> BoolElt
{Whether H is a characteristic subgroup of G (fixed under all automorphisms)}
    if Get(G, "HaveHolomorph") then
        Ambient := Get(G, "Holomorph");
        inj := Get(G, "HolInj");
        return IsNormal(Ambient, inj(H));
    else
        outs := Get(G, "FewOuterGenerators");
        return IsNormal(G`MagmaGrp, H) and &and[f(H) eq H : f in outs];
    end if;
end intrinsic;

intrinsic IncludeNormalSubgroups(L::SubgroupLat)
{Add data from the normal subgroup lattice to L}
    G := L`Grp;
    t0 := ReportStart(G, "IncludeNormalSubgroups");
    // When IncludeNormalSubgroups is called, no subgroups have been added below the initial index bound
    // So we can test if the subgroup is new by just comparing to the index bound.
    // Moreover, we want to use L`index_bound here rather than L`AutIndexBound since L may still contain
    // subgroups above AutIndexBound (since TrimSubgroups hasn't been called yet)
    ibnd := L`index_bound;
    obnd := (ibnd eq 0) select 1 else G`order div ibnd;
    // For determining whether to add complements and adding labels to normal subgroups,
    // we want to use the eventual trimmed value if present
    aibnd := (assigned G`AutIndexBound) select G`AutIndexBound else L`index_bound;
    aobnd := (aibnd eq 0) select 1 else (G`order div aibnd);
    GG := G`MagmaGrp;
    do_add := Get(G, "normal_subgroups_known");
    dummy := Get(G, "NormalSubgroups"); // triggers labeling for N
    N := BestNormalSubgroupLat(G);
    L`NormLat := N;
    additions := [];
    if Get(G, "subgroup_inclusions_known") then
        // The main reason to compute the lattice of normal subgroups separately and then match them up is to transfer the inclusions to normal_contains and normal_contained_in.
        // This isn't relevant if subgroup inclusions aren't computed, so we don't need to match lattice elements in this case
        IncludeSpecialSubgroups(N); // Add labels to the special normal subgroups
        lookup := AssociativeArray();
        t1 := ReportStart(G, "IdentifyNormalSubgroups");
        for i in [1..#N] do
            H := N`subs[i];
            j := SubgroupIdentify(L, H`subgroup : error_if_missing:=(H`order ge obnd));
            if j eq -1 then // not found
                if not do_add then continue; end if;
                j := #L + #additions + 1;
                Hnew := SubgroupLatElement(L, H`subgroup : i:=j);
                Hnew`subgroup_count := Get(H, "subgroup_count");
                Append(~additions, Hnew);
            else
                Hnew := L`subs[j];
                Hnew`keep := true;
            end if;
            if Hnew`order lt aobnd then
                Hnew`label := H`label;
                if assigned H`aut_label then
                    Hnew`aut_label := H`aut_label;
                end if; // the .N is appended later
            end if;
            Hnew`NormLatElt := H;
            lookup[i] := j;
        end for;
        if #additions gt 0 then
            ChangeSubs(L, [], additions);
        end if;
        ReportEnd(G, "IdentifyNormalSubgroups", t1);
        if L`outer_equivalence then
            t1 := ReportStart(G, Sprintf("ComputeNormalCounts (%o)", #N));
            for i in [1..#N] do
                dummy := Get(L`subs[lookup[i]], "subgroup_count");
            end for;
            ReportEnd(G, Sprintf("ComputeNormalCounts (%o)", #N), t1);
        end if;
        for i in [1..#N] do
            if not IsDefined(lookup, i) then continue; end if; // not adding subgroups below index bound
            j := lookup[i];
            H := N`subs[i];
            Hnew := L`subs[j];
            Hnew`normal := true;
            Hnew`characteristic := H`characteristic;
            Hnew`normalizer := 1;
            Hnew`normal_closure := j;
            if assigned H`characteristic_closure then
                Hnew`characteristic_closure := lookup[H`characteristic_closure];
            end if;
            if not L`outer_equivalence then // other case handled above
                Hnew`subgroup_count := 1;
            end if;
            Hnew`cc_count := Hnew`subgroup_count;
            if assigned H`overs then
                Hnew`normal_overs := {lookup[k] : k in Keys(H`overs)};
            end if;
            if assigned H`unders then
                Hnew`normal_unders := {lookup[k] : k in Keys(H`unders)};
            end if;
            Hnew`special_labels := H`special_labels;
            if assigned H`easy_hash then Hnew`easy_hash := H`easy_hash; end if;
            if assigned H`gassman_vec then Hnew`gassman_vec := H`gassman_vec; end if;
            if assigned H`aut_gassman_vec then Hnew`aut_gassman_vec := H`aut_gassman_vec; end if;
        end for;
    else // subgroup inclusions are not known, so we add subgroups below the index bound and assign relevant quantities above
        if ibnd ne 0 then
            IncludeSpecialSubgroups(N : index_bound:=-ibnd);
            IncludeSpecialSubgroups(L : index_bound:=ibnd);
        else
            IncludeSpecialSubgroups(L);
        end if;
        for i in [1..#N] do
            H := N`subs[i];
            if H`order lt obnd then
                j := #L + #additions + 1;
                Hnew := SubgroupLatElement(L, H`subgroup : i:=j);
                Hnew`NormLatElt := H;
                Append(~additions, Hnew);
            end if;
        end for;
        if #additions gt 0 then
            ChangeSubs(L, [], additions);
        end if;
    end if;
    L`by_index := by_index(L);
    if Get(G, "complements_known") then
        t1 := ReportStart(G, "ComputeComplements");
        for i in [1..#N] do
            // We only add complements when L can identify all subgroups (since otherwise detecting collisions between complements of different normal subgroups is annoying)
            // Thus we won't be adding to L`subs here, though we may be determining a label (since labeling is only done up to the index bound)
            if not IsDefined(lookup, i) then continue; end if; // normal subgroup missing
            H := N`subs[i];
            k := lookup[i];
            Comps := Complements(GG, H`subgroup);
            L`subs[k]`complements := [];
            if #Comps eq 0 then continue; end if;
            if L`outer_equivalence then
                Comps := [C[1] : C in SplitByAuts([Comps], G : use_order:=false, fill_orbits:=true)];
            end if;
            compnum := 1;
            for C in Comps do
                if IsNormal(GG, C) then
                    j := lookup[SubgroupIdentify(N, C)];
                else
                    j := SubgroupIdentify(L, C);
                    if #C lt aobnd then
                        // Need to assign label, since this is above the index bound
                        CinL := L`subs[j];
                        label := Split(H`label, ".");
                        label[1] := Sprint(G`order div CinL`order);
                        label[#label] := "NC" * Sprint(compnum);
                        compnum +:= 1;
                        CinL`label := Join(label, ".");
                        L`subs[j]`keep := true;
                    end if;
                end if;
                Append(~(L`subs[k]`complements), j);
            end for;
            // Record whether H is split
            H`split := (#Comps ne 0);
        end for;
        ReportEnd(G, "ComputeComplements", t1);
    end if;
    for i in [1..#L] do
        if not assigned L`subs[i]`normal then
            L`subs[i]`normal := false;
        end if;
    end for;
    ReportEnd(G, "IncludeNormalSubgroups", t0);
end intrinsic;

/*
intrinsic MarkNormalSubgroups(L::SubgroupLat)
{When we don't compute subgroup inclusions, we don't compute the normal subgroup lattice, but still need to carry out some of the same tasks done in the IncludeNormalSubgroups intrinsic}
    G := L`Grp;
    t0 := ReportStart(G, "MarkNormalSubgroups");
    // When MarkNormalSubgroups is called, no subgroups have been added below the initial index bound
    // So we can test if the subgroup is new by just comparing to the index bound.
    // Moreover, we want to use L`index_bound here rather than L`AutIndexBound since L may still contain
    // subgroups above AutIndexBound (since TrimSubgroups hasn't been called yet)
    ibnd := L`index_bound;
    if ibnd eq 0 then
        // already have all the subgroups
        for H in L`subs do
            if Get(H, "normal") then
                
*/

intrinsic IncludeMaximalSubgroups(L::SubgroupLat)
{Should only be called when L`index_bound != 0}
    G := L`Grp;
    t0 := ReportStart(G, "IncludeMaximalSubgroups");
    GG := G`MagmaGrp;
    have_norms := Get(G, "normal_subgroups_known");
    have_sylow := Get(G, "sylow_subgroups_known");
    ordbd := G`order div G`AutIndexBound;
    function is_sylow(M)
        return IsPrimePower(M`order) and Gcd(M`order, G`order div M`order) eq 1;
    end function;
    Maxs := [M`subgroup : M in MaximalSubgroups(GG) | M`order lt ordbd and not (have_norms and IsNormal(GG, M`subgroup)) and not (have_sylow and is_sylow(M))];
    if #Maxs gt 0 then
        additions := [];
        // We form a tmp SubgroupLat in order to use the LabelSubgroups function
        Lmax := New(SubgroupLat);
        Lmax`Grp := G;
        Lmax`outer_equivalence := false;
        Lmax`inclusions_known := true;
        Lmax`index_bound := 0;
        Lmax`subs := [SubgroupLatElement(Lmax, GG : i:=1)] cat [SubgroupLatElement(Lmax, Maxs[j] : i:=j+1) : j in [1..#Maxs]];
        for j in [2..#Maxs+1] do
            Lmax`subs[j]`overs[1] := true;
            Lmax`subs[1]`unders[j] := true;
        end for;
        // Now we account for automorphisms if needed
        if L`outer_equivalence then
            Lmax := CollapseLatticeByAutGrp(Lmax);
        end if;
        LabelSubgroups(Lmax);
        L`MaxLat := Lmax;
        // With labels in hand, we move the SubgroupLatElements to L
        for j in [2..#Lmax] do // skip G itself
            M := Lmax`subs[j];
            i := #L`subs+j-1;
            Mnew := SubgroupLatElement(L, M`subgroup : i:=i);
            Mnew`keep := true;
            Mnew`label := M`label * ".M";
            Mnew`MaxLatElt := M;
            Mnew`subgroup_count := Get(M, "subgroup_count");
            Mnew`cc_count := Get(M, "cc_count");
            Mnew`normal := Get(M, "normal");
            Mnew`characteristic := Get(M, "characteristic");
            if Mnew`normal then
                Mnew`normalizer := 1;
                Mnew`normal_closure := i;
            else
                Mnew`normalizer := i;
                Mnew`normal_closure := 1;
            end if;
            if Mnew`characteristic then
                Mnew`characteristic_closure := i;
            else
                Mnew`characteristic_closure := 1;
            end if;
            // Centralizer is harder, since it won't usually be maximal.
            // We're already below the index bound, so we just give up here
            Mnew`centralizer := None();
            if have_norms then Mnew`normal := false; end if;
            Append(~additions, Mnew);
        end for;
        // Have to reset by_index since we have new subgroups
        ChangeSubs(L, [], additions);
    end if;
    ReportEnd(G, "IncludeMaximalSubgroups", t0);
end intrinsic;

intrinsic IncludeSylowSubgroups(L::SubgroupLat)
{Should only be called when L`Grp`AutIndexBound != 0}
    // Easier since labeling is trivial (unique conjugacy class of Sylows)
    G := L`Grp;
    GG := G`MagmaGrp;
    N := G`order;
    ordbd := G`order div L`Grp`AutIndexBound;
    bi := Get(L, "by_index");
    additions := [];
    for pe in Factorization(N) do
        p := pe[1];
        q := p^pe[2]; Nq := N div q;
        if q lt ordbd then
            if IsDefined(bi, Nq) then
                S := bi[Nq][1];
            else
                S := SubgroupLatElement(L, SylowSubgroup(GG, p): i := #L+1);
                // This can't get information from Lat`from_conj, so we have to fill in various quantities here
                normalizer := Normalizer(GG, S`subgroup);
                S`subgroup_count := N div #normalizer;
                S`cc_count := 1;
                S`normal := (S`subgroup_count eq 1);
                S`characteristic := S`normal;
                j := SubgroupIdentify(L, normalizer : error_if_missing:=false);
                if j ne -1 then S`normalizer := j; end if;
                j := SubgroupIdentify(L, Centralizer(GG, S`subgroup) : error_if_missing:=false);
                if j ne -1 then S`centralizer := j; end if;
                j := SubgroupIdentify(L, NormalClosure(GG, S`subgroup) : error_if_missing:=false);
                if j ne -1 then S`normal_closure := j; end if;
                Append(~additions, S);
            end if;
            S`keep := true;
            S`aut_label := [Nq, 0, 1];
            if L`outer_equivalence then
                S`label := Sprintf("%o.a1", Nq);
            else
                S`label := Sprintf("%o.a1.a1", Nq);
            end if;
        end if;
    end for;
    if #additions gt 0 then
        ChangeSubs(L, [], additions);
    end if;
end intrinsic;

intrinsic core(H::SubgroupLatElt) -> Grp
{}
    return Core(H`Lat`Grp`MagmaGrp, H`subgroup);
end intrinsic;

intrinsic core_order(H::SubgroupLatElt) -> RngIntElt
{}
    return #Get(H, "core");
end intrinsic;

intrinsic ChangeSubs(L::SubgroupLat, deletions::SeqEnum, additions::SeqEnum)
{Changes L`subs and updates by_index, ordered_subs, by_index_aut, aut_class, aut_component_data, from_conj; and complements (overs and unders should not be set yet since subs are changing at the Lst level).
deletions and additions should consist of SubgroupLatElts.
any additions should already be deduplicated (so that they can just be appended to the list of subs)
Sets H`i appropriately for all subgroups in the new list.
}
    G := L`Grp;
    newsubs := L`subs;
    if #deletions gt 0 then
        to_delete := {H`i : H in deletions};
        translate := AssociativeArray();
        newsubs := [H : H in L`subs | not (H`i in to_delete)];
        for i in [1..#newsubs] do
            translate[newsubs[i]`i] := i;
        end for;
        for i in [1..#newsubs] do
            H := newsubs[i];
            // I think ChangeSubs is called early enough that aut_overs hasn't been set, but we confirm this assumption
            assert not assigned H`aut_overs;
            if assigned H`complements then
                H`complements := [translate[j] : j in H`complements];
            end if;
            for attr in ["normalizer", "centralizer", "normal_closure", "characteristic_closure", "core"] do
                if assigned H``attr and Type(H``attr) ne NoneType then
                    if IsDefined(translate, H``attr) then
                        H``attr := translate[H``attr];
                    else
                        delete H``attr;
                    end if;
                end if;
            end for;
            for attr in ["overs", "unders"] do
                if assigned H``attr and Type(H``attr) ne NoneType then
                    newattr := AssociativeArray();
                    for k->b in H``attr do
                        if IsDefined(translate, k) then
                            newattr[translate[k]] := b;
                        end if;
                    end for;
                    H``attr := newattr;
                end if;
            end for;
            for attr in ["normal_overs", "normal_unders"] do
                if assigned H``attr and Type(H``attr) ne NoneType then
                    newattr := {};
                    for k in H``attr do
                        if IsDefined(translate, k) then
                            Include(~newattr, translate[k]);
                        end if;
                    end for;
                    H``attr := newattr;
                end if;
            end for;
        end for;
        if assigned L`from_conj then
            conjL, old_lookup, old_inv_lookup := Explode(L`from_conj);
            new_lookup := AssociativeArray();
            for k->v in old_lookup do
                if IsDefined(translate, v) then
                    new_lookup[k] := translate[v];
                else
                    new_lookup[k] := -1;
                end if;
            end for;
            new_inv_lookup := AssociativeArray();
            for k->vlist in old_inv_lookup do
                if IsDefined(translate, k) then
                    new_inv_lookup[translate[k]] := vlist;
                end if;
            end for;
            L`from_conj := <conjL, new_lookup, new_inv_lookup>;
        end if;
        if assigned L`by_index_aut then
            new_bia := AssociativeArray();
            for index -> classes in L`by_index_aut do
                new_classes := [];
                for cls in classes do
                    new_cls := [H : H in cls | not (H`i in to_delete)];
                    if #new_cls gt 0 then
                        Append(~new_classes, new_cls);
                    end if;
                end for;
                if #new_classes gt 0 then
                    new_bia[index] := new_classes;
                end if;
            end for;
        end if;
    end if;
    if #additions gt 0 then
        printf "newsub extension from %o to %o\n", #newsubs, #newsubs+#additions;
        newsubs cat:= additions;
    end if;
    for i in [1..#newsubs] do
        newsubs[i]`i := i;
    end for;
    L`subs := newsubs;
    // by_index and ordered_subs are easy enough to recompute from L`subs
    if assigned L`by_index then
        L`by_index := by_index(L);
        if assigned L`ordered_subs then
            L`ordered_subs := ordered_subs(L);
        end if;
    end if;
    // aut_component_data isn't usually set when this is called, but we reset it for safety in case
    if assigned L`aut_component_data then
        L`aut_component_data := aut_component_data(L);
    end if;
    // aut_class is easily computed from L`by_index_aut
    if assigned L`aut_class then
        L`aut_class := aut_class(L);
    end if;
end intrinsic;

intrinsic SetAutCutoffs(L::SubgroupLat)
{Set AutIndexBound and AutAboveCutoff (used in setting outer_equivalence, with awkard timing to prevent infinite loops)}
    X := L`Grp;
    subs := Get(L, "ordered_subs");
    cut := NUM_SUBS_LIMIT_AUT - 1;
    ordbd := subs[NUM_SUBS_LIMIT_AUT]`order;
    while cut gt 0 and subs[cut]`order eq ordbd do
        cut -:= 1;
    end while;
    ordbd := subs[cut]`order;
    X`AutIndexBound := X`order div ordbd;
    X`AutAboveCutoff := cut;
end intrinsic;

intrinsic TrimSubgroups(L::SubgroupLat)
{Removes high-index subgroups if there are too many and sets the label for subgroups below the cutoff}
    // On input, we assume that L`subs is sorted by index
    X := L`Grp;
    t0 := ReportStart(X, "TrimSubgroups");
    subs := L`subs;
    cut := X`AutAboveCutoff;
    ordbd := subs[cut]`order;
    indbd := X`order div ordbd;
    // We will add normal, complements, Sylow and maximal subgroups back in later.
    // The only subgroups we don't want to throw away are the core-free ones with index up to 47,
    // since these will give transitive group representations
    keep := {@ H`i : H in L`subs | H`keep @};
    if not X`abelian then
        for m -> V in Get(L, "by_index") do
            if m gt indbd and m le 47 then
                ctr := 1;
                for i in [1..#V] do
                    H := V[i];
                    if Get(H, "core_order") eq 1 and H`order ne 1 then
                        Include(~keep, H`i);
                        H`label := Sprintf("%o.CF%o", m, ctr);
                        ctr +:= 1;
                    end if;
                end for;
            end if;
        end for;
    end if;
    L`index_bound := indbd;
    ChangeSubs(L, [subs[i] : i in [cut+1..#subs] | not (i in keep)], []);
    ReportEnd(X, "TrimSubgroups", t0);
end intrinsic;

intrinsic SubGrpLstByDivisorTerminate(X::LMFDBGrp) -> RngIntElt
{Can be set externally to stop computation of subgroups at a particular index}
    return 0;
end intrinsic;

intrinsic SubGrpLstAut(X::LMFDBGrp) -> SubgroupLat
    {The list of subgroups up to automorphism, cut off by an index bound if too many}
    G := X`MagmaGrp;
    N := Get(X, "order");
    trim := true;
    ordbd := 1;
    if Get(X, "solvable") and Get(X, "HaveHolomorph") then
        // In this case, we can use SubgroupsLift inside the holomorph to get autjugacy classes
        t0 := ReportStart(X, "SolvAutSubs");
        subs := SolvAutSubs(X);
        Sort(~subs, func<x, y | y`order - x`order>);
        X`number_subgroup_autclasses := #subs;
        nchar := 0; nnorm := 0; nsubs := 0; nconj := 0;
        Ambient := Get(X, "Holomorph");
        inj := Get(X, "HolInj");
        for x in subs do
            acnt := Index(Ambient, Normalizer(Ambient, inj(x`subgroup)));
            if acnt eq 1 then nchar +:= 1; end if;
            nsubs +:= acnt;
            ccnt := Index(G, Normalizer(G, x`subgroup));
            if ccnt eq 1 then nnorm +:= acnt; end if;
            nconj +:= acnt div ccnt;
        end for;
        X`number_characteristic_subgroups := nchar;
        X`number_normal_subgroups := nnorm;
        X`number_subgroups := nsubs;
        X`number_subgroup_classes := nconj;
        res := New(SubgroupLat);
        res`Grp := X;
        res`outer_equivalence := true;
        res`inclusions_known := false;
        res`index_bound := 0; // reset when trimming if appropriate
        res`subs := [SubgroupLatElement(res, subs[i]`subgroup : i:=i) : i in [1..#subs]];
        ReportEnd(X, "SolvAutSubs", t0);
    elif Get(X, "AllSubgroupsOk") then
        // In this case, we compute all subgroups and then group them by autjugacy
        tmp := Get(X, "SubGrpLst");
        t0 := ReportStart(X, "CollapseSubGrpLst");
        res := CollapseLatticeByAutGrp(tmp);
        // compute before trimming
        X`number_subgroup_autclasses := #res`subs;
        ReportEnd(X, "CollapseSubGrpLst", t0);
    else
        trim := false;
        // There may be too many subgroups, so we work by index
        // We construct a lattice to pass in to CollapseLatticeByAutGrp,
        // building the subgroups one index at a time
        t0 := ReportStart(X, "SubGrpLstByDivisor");
        // We don't know in advance how far we'll be able to get.
        // In addition to the cutoff based on the number of resulting groups,
        // we set a time cutoff in hopes of staying within our time limit.
        cutoff_time := t0 + Get(X, "SubGrpLstCutoff");
        D := Divisors(N);
        tmp := New(SubgroupLat);
        tmp`Grp := X;
        tmp`outer_equivalence := false; tmp`inclusions_known := false;
        bi := AssociativeArray(); bia := AssociativeArray();
        ccount := 0; acount := 0;
        dbreak := 0;
        terminate := Get(X, "SubGrpLstByDivisorTerminate");
        if terminate ne 0 then
            t1 := ReportStart(X, Sprintf("SubGrpLstIndexLimit (%o)", terminate));
            subs := Subgroups(G : IndexLimit:=N div terminate);
            ReportEnd(X, Sprintf("SubGrpLstIndexLimit (%o)", terminate), t1);
            for d in D do
                if d * terminate le N then
                    dsubs := [H`subgroup : H in subs | H`order eq (N div d)];
                    bi[d] := [SubgroupLatElement(tmp, dsubs[i] : i:=i+ccount) : i in [1..#dsubs]];
                    ccount +:= #dsubs;
                    // We don't want to duplicate the truncation code below, so we don't run SplitByAuts here
                end if;
            end for;
            ccount := 0; // reset
        end if;
        Reverse(~D); // Subgroups takes OrderEqual, so now we want orders decreasing rather than indices increasing
        for d in D do
            if terminate eq 0 then
                t1 := ReportStart(X, Sprintf("SubGrpLstDivisor (%o:%o:%o)", d, ccount, acount));
                dsubs := Subgroups(G : OrderEqual := d);
                ReportEnd(X, Sprintf("SubGrpLstDivisor (%o:%o:%o)", d, ccount, acount), t1);
                if #dsubs eq 0 then continue; end if;
                dsubs := [SubgroupLatElement(tmp, dsubs[i]`subgroup : i:=i+ccount) : i in [1..#dsubs]];
                bi[N div d] := dsubs;
            else
                if not IsDefined(bi, N div d) then continue; end if;
                dsubs := bi[N div d];
                if #dsubs eq 0 then continue; end if;
            end if;
            t1 := ReportStart(X, Sprintf("SubGrpLstSplitDivisor (%o)", d));
            bia[N div d] := SplitByAuts([dsubs], X : use_order := false);
            ReportEnd(X, Sprintf("SubGrpLstSplitDivisor (%o)", d), t1);
            ccount +:= #dsubs;
            acount +:= #bia[N div d];
            if acount ge NUM_SUBS_CUTOFF_AUT or Cputime() gt cutoff_time then
                if dbreak eq 0 then dbreak := N div d; end if;
                for dd -> v in bi do
                    if dd ge dbreak then
                        Remove(~bi, dd);
                        Remove(~bia, dd);
                    end if;
                end for;
                break;
            elif acount ge NUM_SUBS_LIMIT_AUT and dbreak eq 0 then
                dbreak := N div d;
                if terminate ne 0 then
                    // we've declared in advance that we're not storing all subgroups, so this is the end
                    Remove(~bi, dbreak);
                    Remove(~bia, dbreak);
                    break;
                end if;
            end if;
        end for;
        tmp`subs := &cat[bi[d] : d in Sort([k : k in Keys(bi)])];
        tmp`index_bound := Max(Keys(bi));
        if tmp`index_bound eq N then
            tmp`index_bound := 0;
        end if;
        tmp`by_index := bi;
        tmp`by_index_aut := bia;
        res := CollapseLatticeByAutGrp(tmp);
        if tmp`index_bound ne 0 then
            // Avoid computing complements since we can't easily identify subgroups.
            X`complements_known := false;
        end if;
        ReportEnd(X, "SubGrpLstByDivisor", t0);
    end if;
    AddAndTrimSubgroups(res, trim);
    return res;
end intrinsic;

intrinsic AddAndTrimSubgroups(L::SubgroupLat, trim::BoolElt)
{}
    // AutIndexBound and AutAboveCutoff are set now to prevent infinite recursion in IncludeNormalSubgroups
    X := L`Grp;
    if trim and #L`subs ge NUM_SUBS_CUTOFF_AUT then
        SetAutCutoffs(L);
    else
        X`AutIndexBound := L`index_bound;
        X`AutAboveCutoff := #L;
    end if;
    // This also adds information about normal subgroups above the index bound
    IncludeNormalSubgroups(L);
    if X`AutIndexBound ne 0 then
        if Get(X, "sylow_subgroups_known") then
            IncludeSylowSubgroups(L);
        end if;
        if Get(X, "maximal_subgroups_known") then
            IncludeMaximalSubgroups(L);
        end if;
    end if;
    if trim and #L`subs ge NUM_SUBS_CUTOFF_AUT then
        TrimSubgroups(L);
    end if;
end intrinsic;

intrinsic IncludeSpecialSubgroups(L::SubgroupLat : index_bound:=0)
{Adds to special_labels for the lattice L of normal subgroups.  If index_bound > 0, only add subgroups with index smaller than the bound; if index_bound < 0, only add subgroups with index larger than the bound}
    G := L`Grp;
    t0 := ReportStart(G, "IncludeSpecialSubgroups");
    Gord := G`order;
    GG := G`MagmaGrp;
    /* special groups labeled */
    Z := Get(G, "MagmaCenter");
    D := Get(G, "MagmaCommutator");
    F := Get(G, "MagmaFitting");
    Ph := Get(G, "MagmaFrattini");
    R := Get(G, "MagmaRadical");
    So := Socle(G);  /* run special routine in case matrix group */

    // Add series
    Un := Reverse(UpperCentralSeries(GG));
    Ln := LowerCentralSeries(GG);
    Dn := DerivedSeries(GG);
    Cn := ChiefSeries(GG);
    /* all of the special groups are normal; we record which are characteristic as the last part of the tuple */
    SpecialGrps := [<Z,"Z",true>, <D,"D",true>, <F,"F",true>, <Ph,"Phi",true>, <R,"R",true>, <So,"S",true>, <Dn[#Dn],"PC",true>];
    Series := [<Un,"U",true>, <Ln,"L",true>, <Dn,"D",true>, <Cn,"C",false>];
    for tup in Series do
        for i in [1..#tup[1]] do
            H := tup[1][i];
            Append(~SpecialGrps, <H, tup[2]*Sprint(i-1), tup[3]>);
        end for;
    end for;

    noaut := FindSubsWithoutAut(G);
    for tup in SpecialGrps do
        if (index_bound gt 0 and Gord le index_bound * #tup[1] or index_bound lt 0 and Gord gt -index_bound * #tup[1]) then continue; end if;
        i := SubgroupIdentify(L, tup[1] : use_gassman:=false, characteristic:=tup[3], error_if_missing:=not noaut);
        if i ne -1 then
            L`subs[i]`keep := true;
            if tup[3] then
                L`subs[i]`characteristic := true;
            end if;
            Append(~L`subs[i]`special_labels, tup[2]);
        end if;
    end for;
    ReportEnd(G, "IncludeSpecialSubgroups", t0);
end intrinsic;

intrinsic SubgroupLatElement(L::SubgroupLat, H::Grp : i:=false, normalizer:=false, centralizer:=false, normal:=0, normal_closure:=false, gens:=false, subgroup_count:=false, standard:=false, recurse:=0) -> SubgroupLatElt
{}
    x := New(SubgroupLatElt);
    x`Lat := L;
    x`subgroup := H;
    x`order := #H;
    x`keep := false; // has to be set to true manually
    x`special_labels := [];
    x`standard_generators := standard;
    if L`inclusions_known then
        x`overs := AssociativeArray();
        x`unders := AssociativeArray();
    end if;
    if Type(i) ne BoolElt then x`i := i; end if;
    if Type(normalizer) ne BoolElt then x`normalizer := normalizer; end if;
    if Type(centralizer) ne BoolElt then x`centralizer := centralizer; end if;
    if Type(normal_closure) ne BoolElt then x`normal_closure := normal_closure; end if;
    if Type(gens) ne BoolElt then x`gens := gens; end if;
    if Type(subgroup_count) ne BoolElt then x`subgroup_count := subgroup_count; end if;
    if Type(normal) ne RngIntElt then x`normal := normal; end if;
    if Type(recurse) ne RngIntElt then x`recurse := recurse; end if;
    return x;
end intrinsic;

intrinsic gassman_vec(x::SubgroupLatElt) -> SeqEnum
{}
    L := x`Lat;
    if L`outer_equivalence then
        return Get(x, "aut_gassman_vec");
    end if;
    return SubgroupClass(x`subgroup, Get(L`Grp, "ClassMap"));
end intrinsic;
intrinsic aut_gassman_vec(x::SubgroupLatElt) -> SeqEnum
{}
    return SubgroupClass(x`subgroup, AutClassMap(x`Lat`Grp));
end intrinsic;
intrinsic orig_gassman_vec(x::SubgroupLatElt) -> SeqEnum
{A version that just uses magma's ordering of conjugacy classes}
    return SubgroupClass(x`subgroup, Get(x`Lat`Grp, "MagmaClassMap"));
end intrinsic;
intrinsic easy_hash(x::SubgroupLatElt) -> RngIntElt
{}
    return EasyHash(x`subgroup);
end intrinsic;

function gvec_le(a, b)
    // determine whether the gassman vectors of two subsets are compatible with an inclusion
    // a and b are sorted lists of pairs [k,v] where k is a conjugacy class index and v is a count of elements in that class
    ai := 1;
    bi := 1;
    while bi le #b do
        if a[ai][1] eq b[bi][1] then
            if a[ai][2] gt b[bi][2] then
                return false;
            end if;
            ai +:= 1;
            bi +:= 1;
            if ai gt #a then
                return true; // We've seen all the entries of a
            end if;
        elif a[ai][1] gt b[bi][1] then
            // entry of b was missing in a; that's fine
            bi +:= 1;
        else
            // entry of a was missing in b, so a cannot be a subset
            return false;
        end if;
    end while;
    // We've reached the end of b, but not of a (otherwise the ai gt #a clause would have triggered)
    return false;
end function;

intrinsic SubgroupIdentify(L::SubgroupLat, H::Grp : use_hash:=true, use_gassman:=true, get_conjugator:=false, characteristic:=false, error_if_missing:=true) -> Any
{}
//Determines the index of a given subgroup among the elements of a SubgroupLat.
//Does not require by_index, subgroup_count, overs or unders on the elements to be set.
//If get_conjugator is true, returns three things: is_conj, i, conjugating element
//Otherwise, just returns i and raises an error if not found
    G := L`Grp`MagmaGrp;
    ind := #G div #H;
    by_index := Get(L, "by_index");
    function finish_not_found(compconj)
        if compconj then
            return false, 0, Identity(G);
        elif error_if_missing then
            error "Subgroup not found";
        else
            return -1;
        end if;
    end function;
    if not IsDefined(by_index, ind) then
        return finish_not_found(get_conjugator);
    end if;
    poss := by_index[#G div #H];
    // Sylow subgroups
    if not get_conjugator and #poss eq 1 and #H gt 1 and IsPrimePower(#H) and Gcd(#H, ind) eq 1 then
        return poss[1]`i;
    end if;
    if assigned L`from_conj and not get_conjugator then
        conjL, lookup, inv_lookup := Explode(L`from_conj);
        if conjL`index_bound eq 0 or #H * L`index_bound ge L`Grp`order then
            // constructed from another lattice up to conjugacy, where we can more easily identify subgroups
            i := SubgroupIdentify(conjL, H : use_hash:=use_hash, use_gassman:=use_gassman, characteristic:=characteristic, error_if_missing:=error_if_missing);
            if i eq -1 or not IsDefined(lookup, i) then return -1; end if; // missing from lattice
            return lookup[i];
        else
            // below the index bound, so we need to check a few additional possibilities:
            // 1. H is normal
            if assigned L`NormLat and (characteristic or IsNormal(G, H)) then
                i := SubgroupIdentify(L`NormLat, H : use_hash:=use_hash, use_gassman:=use_gassman, characteristic:=characteristic, error_if_missing:=error_if_missing);
                if i eq -1 then return -1; end if;
                // would have been smoother to keep an lookup table for this, but oh well
                for K in poss do
                    if assigned K`NormLatElt and K`NormLatElt`i eq i then
                        return K`i;
                    end if;
                end for;
                return finish_not_found(get_conjugator);
            end if;
            // 2. H is maximal
            if assigned L`MaxLat then
                i := SubgroupIdentify(L`MaxLat, H : use_hash:=use_hash, use_gassman:=use_gassman, characteristic:=characteristic, error_if_missing:=false);
                if i ne -1 then
                    for K in poss do
                        if assigned K`MaxLatElt and K`MaxLatElt`i eq i then
                            return K`i;
                        end if;
                    end for;
                end if;
            end if;
            // 3. It just happens to be corefree.  We don't have a good way to ID these, so we just report not found (which hopefully will just lead to a null in some column
            return finish_not_found(get_conjugator);
        end if;
    end if;
    cmap := 0; gtype := ""; // Magma compiler requires these to be defined; they will be overwritten right below if they're going to be used
    if L`outer_equivalence then
        Ambient := Get(L`Grp, "Holomorph");
        inj := Get(L`Grp, "HolInj");
        if use_gassman then
            cmap := AutClassMap(L`Grp);
            gtype := "aut_gassman_vec";
        end if;
    else
        Ambient := G;
        inj := IdentityHomomorphism(G);
        if FindSubsWithoutAut(L`Grp) then
            cmap := Get(L`Grp, "MagmaClassMap");
            gtype := "orig_gassman_vec";
        elif use_gassman then
            cmap := Get(L`Grp, "ClassMap");
            gtype := "gassman_vec";
        end if;
    end if;
    Hi := (Type(H) eq GrpPerm and H subset Ambient) select H else inj(H);
    function finish(ans, compconj)
        // if error_if_missing is false, might not actually be present, so we need to check IsConjugate
        if compconj or (L`index_bound ne 0 and ind gt L`index_bound and not error_if_missing) then
            K := ans`subgroup;
            Ki := (Type(K) eq GrpPerm and K subset Ambient) select K else inj(K);
            conj, elt := IsConjugate(Ambient, Ki, Hi);
            if not compconj then
                if conj then
                    return ans`i;
                else
                    return -1;
                end if;
            elif conj then
                return conj, ans`i, elt;
            else
                return false, 0, Identity(G);
            end if;
        end if;
        return ans`i;
    end function;
    if #poss eq 1 then
        return finish(poss[1], get_conjugator);
    end if;
    if characteristic then
        // we can just use equality testing
        for HH in poss do
            if HH`subgroup eq H then
                return finish(HH, get_conjugator);
            end if;
        end for;
    else
        if use_hash then
            refined := [];
            hsh := EasyHash(H);
            for j in [1..#poss] do
                HH := poss[j];
                HHhsh := Get(HH, "easy_hash");
                if HHhsh eq hsh then
                    Append(~refined, HH);
                end if;
            end for;
            if #refined eq 1 then
                return finish(refined[1], get_conjugator);
            end if;
            poss := refined;
        end if;
        if use_gassman then
            refined := [];
            old_poss := poss;
            if (Type(H) eq GrpPerm and H subset Ambient) then
                gvec := SubgroupClass(H@@inj, cmap);
            else
                gvec := SubgroupClass(H, cmap);
            end if;
            for j in [1..#poss] do
                HH := poss[j];
                HHvec := Get(HH, gtype);
                if HHvec eq gvec then
                    Append(~refined, HH);
                end if;
            end for;
            if #refined eq 1 then
                return finish(refined[1], get_conjugator);
            end if;
            poss := refined;
        end if;
        for HH in poss do
            conj, i, elt := finish(HH, true);
            if conj then
                if get_conjugator then
                    return true, i, elt;
                else
                    return i;
                end if;
            end if;
        end for;
    end if;
    if get_conjugator then
        return false, 0, Identity(G);
    end if;
    if error_if_missing then
        error "Subgroup not found", poss, gvec, [Get(HH, "gassman_vec") : HH in old_poss];
    else
        return -1;
    end if;
end intrinsic;

intrinsic 'eq'(x::SubgroupLatElt, y::SubgroupLatElt) -> BoolElt
{}
    return x`i eq y`i and x`Lat cmpeq y`Lat;
end intrinsic;
intrinsic IsCoercible(Lat::SubgroupLat, i::RngIntElt) -> BoolElt, SubgroupLatElt
{}
    return (0 lt i and i le #Lat`subs), Lat`subs[i];
end intrinsic;
intrinsic IsCoercible(Lat::SubgroupLat, H::Grp) -> BoolElt, SubgroupLatElt
{}
    if H subset (Lat`Grp`MagmaGrp) then
        return true, Lat`subs[SubgroupIdentify(Lat, H)];
    end if;
    return false;
end intrinsic;
intrinsic Print(x::SubgroupLatElt)
{}
    printf "%o", x`i;
end intrinsic;
intrinsic Print(Lat::SubgroupLat)
{}
    lines := ["Partially ordered set of subgroup classes",
              "-----------------------------------------",
              ""];
    if Lat`outer_equivalence then
        lines[1] *:= " up to automorphism";
    else
        lines[1] *:= " up to conjugacy";
    end if;
    n := Get(Lat`Grp, "order");
    by_index := Get(Lat, "by_index");
    for d in Sort([k : k in Keys(by_index)]) do
        m := n div d;
        for H in by_index[d] do
            if Lat`inclusions_known then
                Append(~lines, Sprintf("[%o]  Order %o  Length %o  Maximal Subgroups: %o", H`i, m, Get(H, "subgroup_count"), Join([Sprint(u) : u in Sort([j : j in Keys(H`unders)])], " ")));
            else
                Append(~lines, Sprintf("[%o]  Order %o  Length %o", H`i, m, Get(H, "subgroup_count")));
            end if;
        end for;
    end for;
    printf Join(lines, "\n");
end intrinsic;
intrinsic '#'(L::SubgroupLat) -> RngIntElt
{}
    return #L`subs;
end intrinsic;
/*intrinsic '[]'(Lat::SubgroupLat, i::RngIntElt) -> SubgroupLatElt
{}
    return Lat`subs[i];
end intrinsic;*/

intrinsic Empty(I::SubgroupLatInterval) -> BoolElt
{}
    return #I`subs eq 0;
end intrinsic;

function half_interval(x, dir, D)
    Lat := x`Lat;
    nodes := [x];
    done := 0;
    seen := {x`i};
    while done lt #nodes do
        done +:= 1;
        for m in Keys(Get(nodes[done], dir)) do
            H := Lat`subs[m];
            if (#D eq 0 or H`order in D) and not H`i in seen then
                Include(~seen, H`i);
                Append(~nodes, H);
            end if;
        end for;
    end while;
    return seen;
end function;

intrinsic get_bottom(L::SubgroupLat) -> SubgroupLatElt
{}
    // Since subgroups are not completely sorted, L`subs[#L] doesn't work.
    G := L`Grp;
    return Get(L, "by_index")[G`order][1];
end intrinsic;

intrinsic get_top(L::SubgroupLat) -> SubgroupLatElt
{}
    // L`subs[1] probably will work, but it's better to not depend on an order for L`subs
    G := L`Grp;
    return Get(L, "by_index")[1][1];
end intrinsic;

intrinsic HalfInterval(x::SubgroupLatElt : dir:="unders", D:={}) -> SubgroupLatInterval
{Nonempty D will short-circuit the breadth-first search by stopping if the order of a node is not in D.}
    I := New(SubgroupLatInterval);
    Lat := x`Lat;
    n := Get(Lat`Grp, "order");
    I`Lat := Lat;
    I`top := dir eq "unders" select x else get_top(Lat);
    I`bottom := dir eq "unders" select get_bottom(Lat) else x;
    I`subs := [Lat`subs[i] : i in half_interval(x, dir, D)];
    return I;
end intrinsic;

intrinsic Interval(top::SubgroupLatElt, bottom::SubgroupLatElt : downward:={}, upward:={}) -> SubgroupLatInterval
{}
    if not top`Lat cmpeq bottom`Lat then
        error "elements must belong to the same lattice";
    end if;
    I := New(SubgroupLatInterval);
    Lat := top`Lat;
    n := Get(Lat`Grp, "order");
    I`Lat := Lat;
    I`top := top;
    I`bottom := bottom;
    D := {d : d in Divisors(top`order) | IsDivisibleBy(d, bottom`order)};
    if #downward eq 0 then downward := half_interval(top, "unders", D); end if;
    if #upward eq 0 then upward := half_interval(bottom, "overs", D); end if;
    I`subs := [Lat`subs[i] : i in downward meet upward];
    return I;
end intrinsic;

intrinsic 'ge'(x::SubgroupLatElt, y::SubgroupLatElt) -> BoolElt
{}
    // Not all the work for Interval is necessary, but this is simple
    // we short-circuit the case that x==y for speed
    return x`i eq y`i or not Empty(Interval(x, y));
end intrinsic;
intrinsic 'gt'(x::SubgroupLatElt, y::SubgroupLatElt) -> BoolElt
{}
    return x`i ne y`i and not Empty(Interval(x, y));
end intrinsic;
intrinsic 'le'(x::SubgroupLatElt, y::SubgroupLatElt) -> BoolElt
{}
    return x`i eq y`i or not Empty(Interval(y, x));
end intrinsic;
intrinsic 'lt'(x::SubgroupLatElt, y::SubgroupLatElt) -> BoolElt
{}
    return x`i ne y`i and not Empty(Interval(y, x));
end intrinsic;

intrinsic Print(I::SubgroupLatInterval)
{}
    printf "%o->%o", I`top, I`bottom;
end intrinsic;

intrinsic NumberOfInclusions(x::SubgroupLatElt, y::SubgroupLatElt) -> RngIntElt
{The number of elements of the conjugacy class of subgroups x that lie in a fixed representative of the conjugacy class of subgroups y}
    if x`i eq y`i then return 1; end if;
    G := x`Lat`Grp;
    if x`Lat`outer_equivalence then
        Ambient := Get(G, "Holomorph");
        inj := Get(G, "HolInj");
    else
        Ambient := G`MagmaGrp;
        inj := IdentityHomomorphism(G`MagmaGrp);
    end if;
    c := x`Lat`conjugator[[x`i, y`i]];
    H := inj(y`subgroup);
    K := inj(x`subgroup)^c;
    NH := Normalizer(Ambient, H);
    NK := Normalizer(Ambient, K);
    if #NK ge #NH then
        return #[1: g in RightTransversal(Ambient, NK) | K^g subset H];
    else
        ind := #[1: g in RightTransversal(Ambient, NH) | K subset H^g];
        assert IsDivisibleBy(ind * Get(x, "subgroup_count"), Get(y, "subgroup_count"));
        return ind * x`subgroup_count div y`subgroup_count;
    end if;
    /*
    // Unfortunately, this is not correct since it's possible to have elements of G that map K into H but don't normalize H.
    NH := Normalizer(Ambient, H);
    NK := Normalizer(Ambient, K);
    return Index(NH, NH meet NK);
    */
    //return #[J : J in Conjugates(Ambient, K) | J subset H];
end intrinsic;

// Implementation adapted from Magma's Groups/GrpFin/subgroup_lattice.m
function ms(G)
    M := MaximalSubgroups(G);
    if Type(M[1]) eq Rec then return M; end if;
    res := [];
    for K in M do
	N := Normalizer(G,K);
	L := Index(G,N);
	r := rec<RF|subgroup := K, order := #K, length := L>;
	Append(~res, r);
    end for;
    return res;
end function;
// It would be better to use SubgroupLift with a Maximal option
function maximal_subgroup_classes(G, H, aut : collapse:=true)
    // Ambient = G or Holomorph(G)
    // H is a subgroup of G
    // inj is the map from G to Ambient
    // N is the normalizer of H inside Ambient
    // Returns a list of records giving maximal subgroups of H up to conjugacy in Ambient; if collapse then guaranteed to be inequivalent
    if aut then
        Ambient := Get(G, "Holomorph");
        inj := Get(G, "HolInj");
    else
        Ambient := G`MagmaGrp;
        inj := IdentityHomomorphism(G`MagmaGrp);
    end if;
    if IsTrivial(H) then return []; end if;
    function do_collapse(results)
        if collapse then
            results := SplitByAuts([results], G);
            return [rec<RF|subgroup:=r[1]`subgroup, order:=r[1]`order, length:=&+[x`length : x in r]> : r in results];
        else
            return results;
        end if;
    end function;
    if #FactoredOrder(H) gt 1 then
        return do_collapse(ms(H));
    end if;
    Hi := inj(H);
    N := Normalizer(Ambient, Hi);
    if N eq Ambient then
        return do_collapse(ms(H));
    end if;
    F := FrattiniSubgroup(H);
    Fi := inj(F);
    M, f := GModule(N, Hi, Fi);
    f := inj * f;
    d := Dimension(M) - 1;
    p := #BaseRing(M);
    ord := #H div p;
    orbs := OrbitsOfSpaces(ActionGroup(M), d);
    res := [];
    for o in orbs do
	K := sub<H|F, [(M!o[2].i)@@f:i in [1..d]]>;
	if Type(K) in {GrpPerm, GrpMat} then
	    K`Order := ord;
	end if;
	Append(~res, rec<RF|subgroup := K, order := ord, length := o[1]>);
    end for;
    return res; // already collapsed
end function;

/*
This method for computing the subgroup lattice was superceded by SubgroupLattice_edges
function SubgroupLattice(GG, aut)
    Lat := New(SubgroupLat);
    Lat`Grp := GG;
    Lat`outer_equivalence := aut;
    Lat`inclusions_known := true;
    Lat`index_bound := 0;
    G := GG`MagmaGrp;
    solv := Get(GG, "solvable");
    if solv then
        // Hall's theorem
        singleton_indexes := {d : d in Divisors(#G) | Gcd(d, #G div d) eq 1};
    elif #Factorization(#G) gt 1 then
        // On Hall subgroups of a finite group
        // Wenbin Guo and Alexander Skiba
        CS := ChiefSeries(G);
        indexes := [#CS[i] div #CS[i+1] : i in [1..#CS-1]];
        singleton_indexes := {};
        for d in Divisors(#G) do
            if Gcd(d, #G div d) eq 1 and &and[IsDivisibleBy(d, ind) or IsDivisibleBy(#G div d, ind) : ind in indexes] then
                Include(~singleton_indexes, d);
            end if;
        end for;
    else
        singleton_indexes := {1, #G};
    end if;
    if aut then
        Ambient := Get(GG, "Holomorph");
        inj := Get(GG, "HolInj");
    else
        Ambient := G;
        inj := IdentityHomomorphism(G);
    end if;
    collapsed := []; // contains one SubgroupLatElt from each equivalence class, ordered by index
    top := SubgroupLatElement(Lat, sub<G|G> : i:=1, normal_closure:=1);
    Append(~collapsed, top);
    Mlist := maximal_subgroup_classes(GG, G, aut : collapse:=true);
    maximals := AssociativeArray();
    to_add := AssociativeArray(); // groups that could have repetitions still
    tmp_indexes := AssociativeArray(); // when we add a group from the cache, we record inclusion counts
    tmp_index_base := 0;
    for d in Divisors(#G) do
        to_add[d] := [];
        maximals[d] := [];
    end for;
    for M in Mlist do
        Append(~maximals[#G div M`order], M);
    end for;
    for d in Divisors(#G) do
        // Maximal subgroups have already been added to collapsed, so we process them first, adding more subgroups to to_add
        if d eq 1 then continue; end if; // already added G
        for MM in maximals[d] do
            M := MM`subgroup;
            lab := label(M);
            //cache := LoadSubgroupCache(lab);
            cache := false; // here for magma's compiler
            if false then // Valid(cache) then // until the bugs in automorphism groups are worked around, we only save caches where outer_equivalence is false
                ok, phi := IsIsomorphic(cache`MagmaGrp, M);
                if not ok then
                    error Sprintf("Lack of isomorphism: %s for %s < %s", lab, Generators(M), GG`label);
                end if;

                // The equivalence relation for subgroups in the cache is not the one desired.  It's okay if there are duplicates (this will be cleaned up below), but we need to ensure that we hit all the classes.
                // If the subgroups in the cache are up to conjugacy, we're fine
                // Otherwise, let A_G = Holomorph(G) or G, A_M = Aut(M) and H_M = Holomorph(M)
                // N_{A_G}(M) -> A_M -> H_M / N_{H_M}(H).  A transversal of the image will give *inequivalent* reps coming from H
                if cache`outer_equivalence then // shouldn't currently trigger
                    error "Need to work around Magma bugs";
                    NM := Normalizer(Ambient, inj(M));
                    AM := Type(M) eq GrpPC select AutomorphismGroupSolubleGroup(M) else AutomorphismGroup(M);
                    HM, injM, projM := Holomorph(M, AM);
                    SM := sub<AM | [hom<M -> M | [m -> (inj(m)^f) @@ inj : m in Generators(M)]> : f in Generators(NM)]>;
                    // This doesn't work since Magma can't seem to compute preimages under proj
                    //SM := SM @@ projM;
                    // This doesn't work: it gives a runtime error in the hom constructor, even though f@@projM fixes 1 and thus should be in the complement of M specified in the docs
                    //projMinv := hom<AM -> HM | [f -> (f @@ projM) : f in Generators(M)]>;
                    // We work around it as follows
                    AMFP, fromFP := FPGroup(AM);
                    tmp := hom<AMFP -> HM | [f -> (fromFP(f) @@ projM) : f in Generators(AMFP)]>;
                    projMinv := Inverse(fromFP) * tmp;
                    // This fails
                    //auts_from_G := SM @ projMinv;
                    auts_from_G := sub<HM | [injM(m) : m in Generators(M)] cat [projMinv(f) : f in Generators(SM)]>;
                    // Now for any subgroup H of M, a transversal of HM / <auts_from_G, Normalizer(HM, H)> gives subgroups of G that are not autjugate...
                else
                    for j in [1..#cache`gens] do
                        // Todo: make sure we don't add M again
                        gens := [phi(g) : g in cache`gens[j]];
                        H := sub<G | gens>;
                        HH := SubgroupLatElement(Lat, H : i:=tmp_index_base - j, gens:=gens, standard:=cache`standard[j], recurse:=false);
                        // Need to add overs from cache, with weights
                        for pair in cache`overs do
                            HH`overs[tmp_index_base - pair[1]] := pair[2];
                        end for;
                        Append(~to_add[#G div #H], HH);
                    end for;
                    tmp_index_base -:= #cache`gens;
                end if;
            else // cache not saved
                HH := SubgroupLatElement(Lat, M : gens:=Generators(M), recurse:=true);
                HH`overs[1] := MM`length;
                Append(~to_add[#G div #M], HH);
            end if;
            //Append(~collapsed[H`order],
        end for;
        if #to_add[d] eq 0 then continue; end if; // no subgroups of this index
        this_index := [to_add[d]];
        if not d in singleton_indexes then
            this_index := SplitByAuts(this_index, GG : use_order:=false);
        end if;
        for cluster in this_index do
            // combine overs: just add weights
            H := cluster[1];
            Append(~collapsed, H);
            if assigned H`i then
                tmp_indexes[H`i] := #collapsed;
            end if;
            H`i := #collapsed;
            for k -> cnt in H`overs do
                if k lt 0 then // temp label
                    Remove(H`overs, k);
                    H`overs[tmp_indexes[k]] := cnt;
                end if;
            end for;
            for j in [2..#cluster] do
                K := cluster[j];
                if assigned K`i then
                    tmp_indexes[K`i] := #collapsed;
                end if;
                for k -> cnt in K`overs do
                    if k lt 0 then // temp label
                        kpos := tmp_indexes[k];
                    else
                        kpos := k;
                    end if;
                    if IsDefined(H`overs, kpos) then
                        H`overs[kpos] +:= cnt;
                    else
                        H`overs[kpos] := cnt;
                    end if;
                end for;
                if K`standard_generators and not H`standard_generators then
                    H`gens := K`gens;
                end if;
            end for;
            if &and[HH`recurse : HH in cluster] then
                for K in maximal_subgroup_classes(GG, H`subgroup, aut : collapse:=false) do
                    KK := SubgroupLatElement(Lat, K`subgroup : gens:=[G!g : g in Generators(K`subgroup)], recurse:=true);
                    KK`overs[#collapsed] := K`length;
                    Append(~to_add[#G div K`order], KK);
                end for;
            end if;
        end for;
    end for;
    Lat`subs := collapsed;
    // Set the counts
    for j in [1..#collapsed] do
        HH := collapsed[j];
        H := HH`subgroup;
        N := Normalizer(Ambient, inj(H));
        HH`subgroup_count := Index(Ambient, N);
        if aut then
            N := Normalizer(G, H);
            HH`cc_count := HH`subgroup_count div Index(G, N);
        else
            HH`cc_count := 1;
        end if;
        HH`normalizer := SubgroupIdentify(Lat, N);
        HH`centralizer := SubgroupIdentify(Lat, Centralizer(G, H));
        current_layer := {HH};
        while not HasAttribute(HH, "normal_closure") do
            next_layer := {};
            for cur in current_layer do
                if cur`cc_count eq cur`subgroup_count then // normal
                    HH`normal_closure := cur`i;
                    break;
                end if;
                for next in Keys(cur`overs) do
                    Include(~next_layer, Lat`subs[next]);
                end for;
            end for;
            current_layer := next_layer;
        end while;
        for k -> v in HH`overs do
            KK := collapsed[k];
            KK`unders[HH`i] := KK`subgroup_count*v div HH`subgroup_count;
        end for;
    end for;
    return Lat;
end function;
*/

procedure ComputeLatticeEdges(~L, Ambient, inj : normal_lattice:=false)
    t0 := ReportStart(L`Grp, "ComputeLatticeEdges");
    one := Identity(Ambient);
    n := L`Grp`order;
    C := AssociativeArray();
    overs := [{Integers()|} : i in [1..#L]];
    unders := [{Integers()|} : i in [1..#L]];
    // We start by adding all edges with prime order
    function prime_count(m)
        return m eq 1 select 0 else &+[pair[2] : pair in Factorization(m)];
    end function;
    pcn := prime_count(n);
    by_index := Get(L, "by_index");
    by_ndiv := IndexFibers([k : k in Keys(by_index)], prime_count);
    known_below := AssociativeArray();
    known_above := AssociativeArray();
    for i in [1..#L] do
        known_below[i] := {i};
        known_above[i] := {i};
    end for;
    //D := Reverse(Sort([k : k in Keys(by_index)]));
    //print "D", D;

    procedure add_edge(~CC, ~kb, ~ka, ~new_edges, bottom, mid, top)
        if not IsDefined(CC, [bottom, top]) then
            //print "Adding", bottom, mid, top;
            if normal_lattice then
                CC[[bottom, top]] := true;
            else
                if CC[[bottom, mid]] eq one and CC[[mid, top]] eq one then
                    CC[[bottom, top]] := one;
                elif L`subs[bottom]`subgroup subset L`subs[top]`subgroup then
                    // We want use use one whenever possible
                    CC[[bottom, top]] := one;
                else
                    CC[[bottom, top]] := CC[[bottom, mid]] * CC[[mid, top]];
                end if;
            end if;
            Include(~kb[top], bottom);
            Include(~ka[bottom], top);
            Append(~new_edges, [bottom, top]);
        end if;
    end procedure;
    procedure propogate_edges(~CC, ~kb, ~ka, edges)
        // Recursively propogate the addition of some edges to fill in all relevant new comparisons in C
        vprint User1: #edges, "edges";
        while #edges gt 0 do
            new_edges := [];
            for edge in edges do
                for bottom in kb[edge[1]] do
                    add_edge(~CC, ~kb, ~ka, ~new_edges, bottom, edge[1], edge[2]);
                end for;
                for top in ka[edge[2]] do
                    add_edge(~CC, ~kb, ~ka, ~new_edges, edge[1], edge[2], top);
                end for;
            end for;
            edges := new_edges;
        end while;
    end procedure;

    for len in [1..pcn] do
        vprint User1: Sprintf("Adding length %o edges", len);
        new_edges := [];
        for base_cnt in [pcn..len by -1] do // number of divisors of index for subgroup
            top_cnt := base_cnt - len; // number of divisors of index for supergroup
            if not (IsDefined(by_ndiv, base_cnt) and IsDefined(by_ndiv, top_cnt)) then continue; end if;
            for d in by_ndiv[base_cnt] do
                M := [m : m in by_ndiv[top_cnt] | IsDivisibleBy(d, m)];
                for sub in by_index[d] do
                    subvec := Get(sub, "gassman_vec");
                    for m in M do
                        for super in by_index[m] do
                            if IsDefined(C, [sub`i, super`i]) then continue; end if;
                            supervec := Get(super, "gassman_vec");
                            if gvec_le(subvec, supervec) then
                                if normal_lattice then
                                    // Normal subgroup inclusion is determined by gassman_vec comparison
                                    conj := true; elt := true;
                                else
                                    conj, elt := IsConjugateSubgroup(Ambient, inj(super`subgroup), inj(sub`subgroup));
                                end if;
                                if conj then
                                    C[[sub`i, super`i]] := elt;
                                    Include(~known_below[super`i], sub`i);
                                    Include(~known_above[sub`i], super`i);
                                    Append(~new_edges, [sub`i, super`i]);
                                    Include(~overs[sub`i], super`i);
                                    Include(~unders[super`i], sub`i);
                                //    print "Including", sub`i, super`i;
                                //else
                                //    print "Not including", sub`i, super`i;
                                end if;
                            end if;
                        end for;
                    end for;
                end for;
            end for;
        end for;
        propogate_edges(~C, ~known_below, ~known_above, new_edges);
        vprint User1: Sprintf("Length %o edges added", len);
    end for;
    L`conjugator := C;
    for i in [1..#L] do
        // For now we switch to AssociativeArrays for compatibility with the old code
        //L`subs[i]`overs := overs[i];
        L`subs[i]`overs := AssociativeArray();
        for j in overs[i] do
            L`subs[i]`overs[j] := true;
        end for;
        //L`subs[i]`unders := unders[i];
        L`subs[i]`unders := AssociativeArray();
        for j in unders[i] do
            L`subs[i]`unders[j] := true;
        end for;
    end for;
    ReportEnd(L`Grp, "ComputeLatticeEdges", t0);
end procedure;

intrinsic normal(H::SubgroupLatElt) -> BoolElt
{Whether this subgroup is normal}
    return Get(H, "cc_count") eq Get(H, "subgroup_count");
end intrinsic;

intrinsic characteristic(H::SubgroupLatElt) -> BoolElt
{Whether this subgroup is stabilized by all automorphisms}
    L := H`Lat;
    G := L`Grp;
    if FindSubsWithoutAut(G) then
        if not Get(H, "normal") then return false; end if;
        d := G`order div H`order;
        if L`index_bound eq 0 or d le L`index_bound then
            norms := [N : N in Get(L, "by_index")[d] | Get(N, "normal")];
            if #norms eq 1 then return true; end if;
        end if;
        // Despite calling it "FindSubsWithoutAut", we usually have access to aut_gens and thus the automorphism group
        if assigned G`aut_gens then
            HH := H`subgroup;
            for f in Generators(Get(G, "MagmaAutGroup")) do
                if f(HH) ne HH then return false; end if;
            end for;
            return true;
        end if;
        // Give up
        return None();
    end if;
    return Get(H, "subgroup_count") eq 1 and (L`outer_equivalence or #Get(L, "aut_orbit")[H`i] eq 1);
end intrinsic;

procedure SetClosures(~L)
    // Set normal and characteristic closures
    t0 := ReportStart(L`Grp, "SetClosures");
    subs := Get(L, "ordered_subs");
    subs[1]`normal_closure := 1;
    subs[1]`characteristic_closure := 1;
    ord_bnd := (L`index_bound eq 0) select 1 else (L`Grp`order div L`index_bound);
    for k in [1..#subs] do
        H := subs[k];
        if H`order lt ord_bnd then break; end if; // stop at index bound
        mark := AssociativeArray();
        for prop in ["normal", "characteristic"] do
            attr := prop * "_closure";
            mark[prop] := [];
            if Get(H, prop) then
                H``attr := H`i;
                current_layer := Keys(H`unders);
                while #current_layer gt 0 do
                    next_layer := {@ @};
                    for j in current_layer do
                        cur := L`subs[j]; // the layer indices are into L`subs rather than ordered_subs
                        if not Get(cur, prop) then
                            cur``attr := H`i;
                            next_layer join:= {@ k : k->t in cur`unders @};
                        end if;
                    end for;
                    current_layer := next_layer;
                end while;
            else
                assert assigned H``attr;
            end if;
        end for;
    end for;
    ReportEnd(L`Grp, "SetClosures", t0);
end procedure;

/*AttachSpec("spec");
SetVerbose("User1", 1);
G := MakeBigGroup("40T6148", "10240.gz");
G`pc_code := -1;
G`permutation_degree := -1;
X := PrintData(G);

Fix number_characteristic_subgroups, number_normal_subgroups, number_subgroup_autclasses, number_subgroup_classes, number_subgroups (currently set in SubGrpLstAut, but this was only called when determining blah values)
Set pc_code, permutation_degree externally
*/
function SubgroupLattice_edges(G, aut)
    // This version of SubgroupLattice constructs the subgroups first then adds edges
    GG := G`MagmaGrp;
    vprint User1: "Starting to list subgroups with aut =", aut;
    if aut then
        L := Get(G, "SubGrpLstAut");
        Ambient := Get(G, "Holomorph");
        inj := Get(G, "HolInj");
    else
        L := Get(G, "SubGrpLst");
        // This can't be put inside SubGrpLst since it would cause an infinite recursion when called from SubGrpLstAut because G`outer_equivalence is not yet set
        IncludeNormalSubgroups(L);
        Ambient := GG;
        inj := IdentityHomomorphism(GG);
    end if;
    ComputeLatticeEdges(~L, Ambient, inj);
    SetClosures(~L);
    L`inclusions_known := true;
    return L;
end function;

intrinsic number_normal_subgroups(G::LMFDBGrp) -> Any
{}
    if not Get(G, "normal_subgroups_known") then return None(); end if;
    if Get(G, "outer_equivalence") then
        L := Get(G, "NormSubGrpLatAut");
        return &+[Get(H, "subgroup_count") : H in L`subs];
    else
        return #Get(G, "NormSubGrpLat");
    end if;
end intrinsic;

intrinsic number_characteristic_subgroups(G::LMFDBGrp) -> Any
{}
    if not Get(G, "normal_subgroups_known") then return None(); end if;
    L := BestNormalSubgroupLat(G);
    num := 0;
    for H in L`subs do
        characteristic := Get(H, "characteristic");
        if Type(characteristic) eq NoneType then return None(); end if;
        if characteristic then num +:= 1; end if;
    end for;
    return num;
end intrinsic;

intrinsic number_subgroup_autclasses(G::LMFDBGrp) -> Any
{}
    if FindSubsWithoutAut(G) then return None(); end if;
    L := Get(G, "BestSubgroupLat");
    if L`index_bound ne 0 then return None(); end if;
    if L`outer_equivalence then return #L; end if;
    return &+[#classes : index -> classes in Get(L, "by_index_aut")];
end intrinsic;

intrinsic number_subgroups(G::LMFDBGrp) -> Any
{}
    L := Get(G, "BestSubgroupLat");
    if L`index_bound ne 0 then return None(); end if;
    return &+[Get(H, "subgroup_count") : H in L`subs];
end intrinsic;

intrinsic number_subgroup_classes(G::LMFDBGrp) -> Any
{}
    L := Get(G, "BestSubgroupLat");
    if L`index_bound ne 0 then return None(); end if;
    return &+[Get(H, "cc_count") : H in L`subs];
end intrinsic;

intrinsic FindSubsWithoutAut(G::LMFDBGrp) -> BoolElt
{}
    // We use the combination G`AllSubgroupsOk=false, G`outer_equivalence=false, G`subgroup_inclusions_known=false, complements_known=false
    // to specify that we want to avoid computing subgroups up to automorphism.
    // This avoids some costly computations, making it possible to compute
    // subgroups for larger G, but prevents labeling using our standard labeling
    // scheme.  It also never happens naturally, since outer_equivalence(G) returns true when AllSubgroupsOk(G) is false.
    return assigned G`outer_equivalence and assigned G`AllSubgroupsOk and assigned G`subgroup_inclusions_known and assigned G`complements_known and not G`outer_equivalence and not G`AllSubgroupsOk and not G`subgroup_inclusions_known and not G`complements_known;
end intrinsic;

intrinsic SubGrpLst(G::LMFDBGrp) -> SubgroupLat
{The list of all subgroups up to conjugacy}
    // For now, we start with index 1 rather than order 1
    t0 := ReportStart(G, "SubGrpLst");
    GG := G`MagmaGrp;
    res := New(SubgroupLat);
    res`Grp := G;
    res`outer_equivalence := false;
    res`inclusions_known := false;
    terminate := Get(G, "SubGrpLstByDivisorTerminate");
    // Doing subs := Reverse(Subgroups(GG : IndexLimit:=terminate)); is both slower (surprisingly) and leads to errors like "Too many complements!:5^16"
    if FindSubsWithoutAut(G) then
        // We use this for large groups where it was taking too much time to compute subgroups up to automorphism.  In this case we also want to work index-by-index since the full subgroup list is probably too long to store (and may be infeasible to compute)
        N := G`order;
        D := Reverse(Divisors(N));
        ccount := 0;
        prevd := -1;
        res`index_bound := 0; // will usually get overwritten below
        subs := [];
        for d in D do
            t1 := ReportStart(G, Sprintf("SubGrpLstConjDivisor (%o:%o)", d, ccount));
            dsubs := Subgroups(GG: OrderEqual := d);
            ReportEnd(G, Sprintf("SubGrpLstConjDivisor (%o:%o)", d, ccount), t1);
            if ccount + #dsubs ge NUM_SUBS_CUTOFF_CONJ then
                res`index_bound := N div prevd;
                break;
            end if;
            subs cat:= dsubs;
            ccount +:= #dsubs;
            if d eq terminate then
                res`index_bound := N div d;
                break;
            end if;
            prevd := d;
        end for;
        if prevd eq 1 then
            // made it all the way through the loop
            G`number_subgroup_classes := #subs;
            G`number_subgroups := &+[H`length : H in subs];
        else
            G`number_subgroup_classes := None();
            G`number_subgroups := None();
            G`complements_known := false;
        end if;
    else
        subs := Reverse(Subgroups(GG));
        res`index_bound := 0;
        G`number_subgroup_classes := #subs;
        G`number_subgroups := &+[H`length : H in subs];
    end if;
    res`subs := [SubgroupLatElement(res, subs[i]`subgroup : i:=i, subgroup_count:=subs[i]`length) : i in [1..#subs]];
    // It would be nice to call IncludeNormalSubgroups(res) here when G`outer_equivalence is false,
    // but it causes an infinite recursion.  So we call it on the return value in BestSubgroupLattice and SubGrpLat
    ReportEnd(G, "SubGrpLst", t0);
    return res;
end intrinsic;

function CollapseLatElement(L, subcls, i, lookup)
    A := subcls[1];
    x := SubgroupLatElement(L, A`subgroup : i:=i);
    x`cc_count := #subcls;
    x`subgroup_count := &+[Get(H, "subgroup_count") : H in subcls];
    for attr in ["normal", "characteristic", "easy_hash", "aut_gassman_vec"] do
        if assigned A``attr then
            x``attr := A``attr;
        end if;
    end for;
    x`normal := Get(A, "normal");
    if assigned A`complements then
        x`complements := [lookup[j] : j in A`complements];
    end if;
    if assigned A`normal_overs then
        x`normal_overs := {lookup[j] : j in A`normal_overs};
    end if;
    if assigned A`normal_unders then
        x`normal_unders := {lookup[j] : j in A`normal_unders};
    end if;
    if assigned A`characteristic_closure then
        x`characteristic_closure := lookup[A`characteristic_closure];
    end if;
    if assigned A`NormLatElt then
        x`NormLatElt := A`NormLatElt;
    end if;
    if assigned A`MaxLatElt then
        x`MaxLatElt := A`MaxLatElt;
    end if;
    // Certain subgroups, like complements, already have a label
    N := L`Grp`order;
    if L`index_bound ne 0 and N div A`order gt L`index_bound and assigned A`label then
        lab := Split(A`label, ".");
        if lab[#lab] in ["M", "N"] then // maximal or normal subgroups beyond index bound
            x`label := Join([lab[1], lab[2], lab[#lab]], ".");
        elif lab[#lab][1..2] in ["CF", "NC"] then // corefree or normal complement subgroup beyond index bound; it would probably be best to redo numbering so that it's 1..k, but I'm not going to worry
            x`label := A`label;
        end if;
    end if;
    N := Get(A, "normalizer");
    x`normalizer := (Type(N) eq NoneType) select None() else lookup[N];
    N := Get(A, "normal_closure");
    x`normal_closure := (Type(N) eq NoneType) select None() else lookup[N];
    C := Get(A, "centralizer");
    x`centralizer := (Type(C) eq NoneType) select None() else lookup[C];
    if assigned A`gens then
        x`gens := A`gens;
    end if;
    if L`inclusions_known then
        // still using AssociativeArrays for compatibility with older code
        for ov -> b in Get(A, "overs") do
            if Type(ov) ne NoneType and ov ne -1 then
                x`overs[lookup[ov]] := b;
            end if;
        end for;
        for un -> b in Get(A, "unders") do
            if Type(un) ne NoneType and un ne -1 then
                x`unders[lookup[un]] := b;
            end if;
        end for;
        if assigned A`mobius_sub then
            x`mobius_sub := A`mobius_sub;
        end if;
        if assigned A`mobius_quo then
            x`mobius_quo := A`mobius_quo;
        end if;
    end if;
    return x;
end function;

intrinsic CollapseLatticeByAutGrp(L::SubgroupLat) -> SubgroupLat
{Takes a lattice of subgroups up to conjugacy and produces one up to automorphism}
    t0 := ReportStart(L`Grp, "CollapseLattice");
    res := New(SubgroupLat);
    G := L`Grp;
    res`Grp := G;
    res`outer_equivalence := true;
    res`inclusions_known := L`inclusions_known;
    res`index_bound := L`index_bound;
    if assigned L`NormLat then
        res`NormLat := L`NormLat;
    end if;
    if assigned L`MaxLat then
        res`MaxLat := L`MaxLat;
    end if;
    subs := Get(L, "by_index_aut");
    subs := &cat[subs[n] : n in Sort([k : k in Keys(subs)])];
    lookup, inv_lookup, retract := Explode(Get(L, "aut_component_data"));
    // Have to make new SubgroupLatElements, since we're changing the lattice and modifying overs and unders
    t0 := ReportStart(L`Grp, "CollapsingElements");
    res`subs := [CollapseLatElement(res, subs[i], i, lookup) : i in [1..#subs]];
    ReportEnd(L`Grp, "CollapsingElements", t0);
    res`from_conj := <L, lookup, inv_lookup>;
    ReportEnd(L`Grp, "CollapseLattice", t0);
    return res;
end intrinsic;

intrinsic SubGrpLatAut(G::LMFDBGrp : edges:=true) -> SubgroupLat
{The lattice of subgroups up to automorphism}
    if Get(G, "HaveHolomorph") then
        return SubgroupLattice_edges(G, true);
    else
        L := CollapseLatticeByAutGrp(Get(G, "SubGrpLat"));
        // Have to trim extra subgroups
        AddAndTrimSubgroups(L, true);
        return L;
    end if;
end intrinsic;

intrinsic SubGrpLat(G::LMFDBGrp : edges:=true) -> SubgroupLat
{The lattice of subgroups up to conjugacy}
    return SubgroupLattice_edges(G, false);
end intrinsic;

/* Even when we don't compute the lattice of inclusions it's sometimes necessary to find inclusion relations (to break ties among Gassman equivalent subgroups for example) */

intrinsic unders(x::SubgroupLatElt) -> Assoc
{}
    Lat := x`Lat;
    GG := Lat`Grp;
    if not Get(GG, "subgroup_inclusions_known") then
        return None();
    end if;
    G := GG`MagmaGrp;
    H := x`subgroup;
    aut := Lat`outer_equivalence and Get(GG, "HaveHolomorph");
    // It's alright to have duplication below, so we set aut to false since otherwise maximal_subgroup_classes would compute the Holomorph
    ans := AssociativeArray();
    for M in maximal_subgroup_classes(GG, H, aut : collapse:=false) do
        // We don't record the weights since that's not needed for this application.  We still use an associative array so that the data type of overs and unders doesn't change.
        i := SubgroupIdentify(Lat, M`subgroup);
        ans[i] := true;
    end for;
    return ans;
end intrinsic;

intrinsic overs(x::SubgroupLatElt) -> Assoc
{}
    // We build a list of candidate supergroups using Gassman vectors, then compute their "unders" and check if this is contained therein.
    Lat := x`Lat;
    GG := Lat`Grp;
    if not Get(GG, "subgroup_inclusions_known") then
        return None();
    end if;
    n := Get(GG, "order");
    m := x`order;
    ans := AssociativeArray();
    xvec := Get(x, "gassman_vec");
    by_index := Get(Lat, "by_index");
    for p in PrimeDivisors(n div m) do
        if IsDefined(by_index, n div (m*p)) then
            for h in by_index[n div (m*p)] do
                hvec := Get(h, "gassman_vec");
                if gvec_le(xvec, hvec) then
                    unders := Get(h, "unders");
                    if IsDefined(unders, x`i) then
                        ans[h`i] := true;
                    end if;
                end if;
            end for;
        end if;
    end for;
    return ans;
end intrinsic;

intrinsic aut_overs(x::SubgroupLatElt) -> Assoc
{One entry from each autjugacy class}
    Lat := x`Lat;
    if not Get(Lat`Grp, "subgroup_inclusions_known") then
        return None();
    end if;
    overs := Get(x, "overs");
    if Lat`outer_equivalence then
        return overs;
    end if;
    aclass := Get(Lat, "aut_class");
    ans := AssociativeArray();
    for s in Keys(overs) do
        ans[aclass[s]] := true;
    end for;
    return ans;
end intrinsic;

intrinsic subgroup_count(x::SubgroupLatElt) -> RngIntElt
{}
    Lat := x`Lat;
    if assigned Lat`from_conj then
        conjL, lookup, inv_lookup := Explode(Lat`from_conj);
        orbit := inv_lookup[x`i];
        return &+[Get(conjL`subs[i], "subgroup_count") : i in orbit];
    elif Lat`outer_equivalence then
        Ambient := Get(Lat`Grp, "Holomorph");
        inj := Get(Lat`Grp, "HolInj");
    else
        Ambient := Lat`Grp`MagmaGrp;
        inj := IdentityHomomorphism(Ambient);
    end if;
    return Index(Ambient, Normalizer(Ambient, inj(x`subgroup)));
end intrinsic;

intrinsic cc_count(x::SubgroupLatElt) -> RngIntElt
{}
    Lat := x`Lat;
    if Lat`outer_equivalence then
        G := Lat`Grp`MagmaGrp;
        return Get(x, "subgroup_count") div Index(G, Normalizer(G, x`subgroup));
    else
        return 1;
    end if;
end intrinsic;

/*
// These functions were used when testing SubgroupLattice_edges
intrinsic AddConjugators(L::SubgroupLat)
{}
    G := L`Grp;
    GG := G`MagmaGrp;
    n := #GG;
    by_index := Get(L, "by_index");
    D := Sort([k : k in Keys(by_index) | k gt 1]);
    if Get(G, "outer_equivalence") then
        Ambient := Get(G, "Holomorph");
        inj := Get(G, "HolInj");
    else
        Ambient := GG;
        inj := IdentityHomomorphism(GG);
    end if;
    L`conjugator := AssociativeArray();
    for d in D do
        M := [m : m in D | m ne d and IsDivisibleBy(m, d) and m ne n];
        for sub in by_index[d] do
            subvec := Get(sub, "gassman_vec");
            for m in M do
                for super in by_index[m] do
                    supervec := Get(super, "gassman_vec");
                    if gvec_le(subvec, supervec) then
                        conj, elt := IsConjugateSubgroup(Ambient, inj(super`subgroup), inj(sub`subgroup));
                        if conj then
                            L`conjugator[[sub`i, super`i]] := elt;
                        end if;
                    end if;
                end for;
            end for;
        end for;
    end for;
end intrinsic;

intrinsic ConjugatorTiming(N, i : aut:=true)
{}
    G := MakeSmallGroup(N, i : represent:=false);
    G`subgroup_index_bound := 0;
    t0 := Cputime();
    if aut then
        L := Get(G, "SubGrpLstAut");
    else
        L := Get(G, "SubGrpLst");
    end if;
    print "List computed", Cputime() - t0;
    t0 := Cputime();
    for sub in L`subs do
        gv := Get(sub, "gassman_vec");
    end for;
    print "Gassman complete", Cputime() - t0;
    t0 := Cputime();
    AddConjugators(L);
    print "Conjugators complete", Cputime() - t0;
    G := MakeSmallGroup(N, i : represent:=false);
    G`subgroup_index_bound := 0;
    t0 := Cputime();
    if aut then
        L := Get(G, "SubGrpLatAut");
    else
        L := Get(G, "SubGrpLat");
    end if;
    print "Lattice computed", Cputime() - t0;
end intrinsic;

intrinsic test_overs_unders(N, i : aut:=true) -> LMFDBGrp
{}
    G := MakeSmallGroup(N, i : represent:=false);
    if aut then
        L1 := SubGrpLatAut(G);
    else
        L1 := SubGrpLat(G);
    end if;
    // We want the numbering of groups to be the same, so we just copy C1 and delete overs and unders
    L2 := New(SubgroupLat);
    L2`Grp := L1`Grp;
    L2`outer_equivalence := L1`outer_equivalence;
    L2`inclusions_known := false;
    subs := [];
    for x in L1`subs do
        Append(~subs, SubgroupLatElement(L2, x`subgroup : i:=x`i));
    end for;
    L2`subs := subs;
    shown := false;
    for j in [1..#subs] do
        if Keys(L1`subs[j]`overs) ne Keys(Get(L2`subs[j], "overs")) then
            if not shown then
                shown := true;
                print L1;
            end if;
            print j, "overs", Keys(L1`subs[j]`overs), Keys(Get(L2`subs[j], "overs"));
        end if;
        if Keys(L1`subs[j]`unders) ne Keys(Get(L2`subs[j], "unders")) then
            if not shown then
                shown := true;
                print L1;
            end if;
            print j, "unders", Keys(L1`subs[j]`unders), Keys(Get(L2`subs[j], "unders"));
        end if;
    end for;
    return G;
end intrinsic;
*/

intrinsic normal_closure(H::SubgroupLatElt) -> RngIntElt
{}
    // There's a faster version of this available when we have the subgroup inclusion diagram: just trace up through the subgroups containing this one with breadth-first search until a normal one is found.
    if FindSubsWithoutAut(H`Lat`Grp) then
        // This was slow for large groups
        return None();
    else
        return SubgroupIdentify(H`Lat, NormalClosure(H`Lat`Grp`MagmaGrp, H`subgroup));
    end if;
end intrinsic;

intrinsic normalizer(H::SubgroupLatElt) -> RngIntElt
{}
    if FindSubsWithoutAut(H`Lat`Grp) then
        // This was slow for large groups
        return None();
    end if;
    i := SubgroupIdentify(H`Lat, Normalizer(H`Lat`Grp`MagmaGrp, H`subgroup) : error_if_missing:=false);
    return (i eq -1 select None() else i);
end intrinsic;

intrinsic centralizer(H::SubgroupLatElt) -> Any
{}
    if FindSubsWithoutAut(H`Lat`Grp) then
        // This was slow for large groups
        return None();
    end if;
    try
        i := SubgroupIdentify(H`Lat, Centralizer(H`Lat`Grp`MagmaGrp, H`subgroup) : error_if_missing:=false);
    catch e    //dealing with a strange Magma bug in 120.5
        GenCentralizers:={Centralizer(H`Lat`Grp`MagmaGrp, h) : h in Generators(H`subgroup)};
        Cent:=&meet(GenCentralizers);
        i:=SubgroupIdentify(H`Lat, Cent : error_if_missing:=false);
    end try;

    return (i eq -1 select None() else i);
end intrinsic;

intrinsic sort_pick(H::SubgroupLatElt) -> Grp
{A canonical conjugate of H.  Also sets H`sort_conj, which conjugates H`subgroup to H`sort_pick.}
    G := H`Lat`Grp;
    GG := G`MagmaGrp;
    if H`subgroup_count eq 1 then
        H`sort_conj := Identity(GG);
        return H`subgroup;
    end if;
    gens := Get(H, "sort_gens"); // sets sort_conj
    return sub<GG|gens>;
end intrinsic;

intrinsic aut_sort_pick(H::SubgroupLatElt) -> Grp
{A canonical autjugate of H.  Also sets H`aut_sort_conj, which conjugates H`subgroup to H`sort_pick.  Note that H`aut_sort_conj will be in the Holomorph}
    L := H`Lat;
    G := L`Grp;
    GG := G`MagmaGrp;
    if H`characteristic_closure eq H`i then
        if Get(G, "HaveHolomorph") then
            H`aut_sort_conj := Identity(Get(G, "Holomorph"));
        else
            H`aut_sort_conj := Identity(Get(G, "MagmaAutGroup"));
        end if;
        return H`subgroup;
    end if;
    gens := Get(H, "aut_sort_gens"); // sets aut_sort_conj
    return sub<GG|gens>;
end intrinsic;

function sortable(H)
    if Type(H) eq GrpPCElt then
        return Eltseq(H);
    elif Type(H) eq GrpPermElt then
        return cyc(H);
    elif Type(H) eq GrpMatElt then
        return H;
    else
        error Sprintf("Type %o not implemented", Type(H));
    end if;
end function;

function comp_sort_gens(H, aut)
    L := H`Lat;
    G0 := L`Grp;
    use_hol := Get(G0, "HaveHolomorph");
    // among overs, we first prioritize the path to the normal closure (since getting there stops the recursion), then we prioritize small index (inside the over, so maximal index of the over inside the ambient), then break ties by full_label
    if aut then
        if use_hol then
            Ambient := Get(G0, "Holomorph");
            inj := Get(G0, "HolInj");
        else
            Ambient := G0`MagmaGrp;
            inj := IdentityHomomorphism(Ambient);
        end if;
        cm := AutClassMap(G0);
        N := L`subs[H`characteristic_closure];
        if N`i eq H`i then error "H must not be characteristic"; end if;
        D := {d : d in Divisors(N`order) | IsDivisibleBy(d, H`order) and d ne H`order};
        I := half_interval(N, "unders", D);
        orbit := [L`subs[i] : i in Get(L, "aut_orbit")[H`i]];
        poss := &cat[[<i, orb`i> : i in Keys(Get(orb, "overs")) | i in I] : orb in orbit];
        _, k := Min([<L`subs[i[1]]`order, L`subs[i[1]]`full_label, i[2]> : i in poss]);
        Hi := poss[k][2];
        Gi := poss[k][1];
        G := L`subs[Gi];
        GG := inj(Get(G, "aut_sort_pick"));
        if assigned L`from_conj then
            // We pick a conjugate that is contained in Gi
            conjL, lookup, inv_lookup := Explode(L`from_conj);
            Gup := inv_lookup[Gi][1];
            Hup := Rep(Keys(Get(conjL`subs[Gup], "unders")) meet {j : j in inv_lookup[Hi]});
            HH := conjL`subs[Hup]`subgroup;
            c := conjL`conjugator[[Hup, Gup]];
            if c cmpne true then // this would indicate that we're in the lattice of normal subgroups and thus don't need to conjugate
                HH := HH^c;
            end if;
        else
            HH := inj(L`subs[Hi]`subgroup);
            c := L`conjugator[[Hi, Gi]];
            if c cmpne true then // this would indicate that we're in the lattice of normal subgroups and thus don't need to conjugate
                if not L`outer_equivalence then
                    c := inj(c);
                end if;
                HH := HH^c;
            end if;
        end if;
        if use_hol then
            // we stored an element of the holomorph to conjugate by
            HH := HH^Get(G, "aut_sort_conj");
        else
            // we stored an automorphism
            f := Get(G, "aut_sort_conj");
            HH := f(HH);
        end if;
    else
        Ambient := G0`MagmaGrp;
        inj := IdentityHomomorphism(Ambient);
        cm := Get(G0, "ClassMap");
        N := L`subs[Get(H, "normal_closure")];
        if N`i eq H`i then error "H must not be normal"; end if;
        I := Interval(N, H : upward := Keys(Get(H, "overs")));
        by_index := Get(I, "by_index");
        poss := by_index[Max(Keys(by_index))];
        _, k := Min([x`full_label : x in poss]);
        G := poss[k];
        GG := Get(G, "sort_pick");
        HH := (H`subgroup)^(L`conjugator[[H`i, G`i]] * Get(G, "sort_conj"));
    end if;
    assert HH subset GG;
    // set gens
    M := #GG;
    C := ConjugacyClasses(HH); C := C[2..#C];
    X := IndexFibers([1..#C], func<i|cm(C[i][3] @@ inj)>);
    S := [k:k in Keys(X)];
    Z := [&+[M div #Centralizer(GG, C[j][3]): j in X[S[i]]] : i in [1..#S]];
    Ix := Sort([1..#S], func<a,b|Z[a] ne Z[b] select Z[a]-Z[b] else (S[a] lt S[b] select -1 else 1)>);
    S := [S[i]: i in Ix]; Z := [Z[i]: i in Ix];
    A := &cat[[h : h in Conjugates(GG, C[j][3])] : j in X[S[1]]];
    _, a := Min([sortable(h) : h in A]);
    a := A[a];
    gens := [a];
    K := sub<Ambient|gens>;
    T := Conjugates(GG, HH);
    n := 1;
    while #K lt #HH do
        if #T gt 1 then
            T := [t : t in T | K subset t];
            if #T eq 1 then
                _, g := IsConjugate(GG, HH, T[1]);
                HH := HH^g;
                C := [<c[1], c[2], c[3]^g> : c in C];
            end if;
        end if;
        for i in [n..#S] do
            if #T eq 1 then
                A := &cat[[h : h in C[j][3]^HH | not h in K]: j in X[S[i]]];
            else
                A := &cat[[h : h in C[j][3]^GG | not h in K and &or[h in t:t in T]] : j in X[S[i]]];
            end if;
            if #A eq 0 then continue; end if;
            n := i;
            _, a := Min([sortable(h) : h in A]);
            a := A[a];
            Append(~gens, a); K := sub<Ambient|gens>;
            break;
        end for;
    end while;
    if aut and not use_hol then
        b, conj := IsAutjugateSubgroup(L, H`subgroup, K); assert b;
    else
        b, conj := IsConjugate(Ambient, inj(H`subgroup), K); assert b;
    end if;
    if aut then
        H`aut_sort_conj := conj;
    else
        H`sort_conj := conj;
    end if;
    return [g @@ inj : g in gens];
end function;

intrinsic sort_gens(H::SubgroupLatElt) -> SeqEnum
{A canonical choice of generators of some conjugate.  H should not be normal}
    return comp_sort_gens(H, false);
end intrinsic;

intrinsic aut_sort_gens(H::SubgroupLatElt) -> SeqEnum
{A canonical choice of generators of some autjugate.  H should not be characteristic}
    return comp_sort_gens(H, true);
end intrinsic;

intrinsic sort_key(H::SubgroupLatElt, aut::BoolElt) -> Any
{A sortable object canonically defined by this conjugacy class}
    if aut then
        return [sortable(g) : g in Get(H, "aut_sort_gens")];
    else
        return [sortable(g) : g in Get(H, "sort_gens")];
    end if;
end intrinsic;

/* turns G`label and output of LabelSubgroups into string */

function CreateLabel(Glabel, Hlabel)
    if #Hlabel gt 0 then
        return Glabel * "." * Join([Sprint(x) : x in Hlabel], ".");
    else // used for special subgroups where there is only a suffix
        return Glabel;
    end if;
end function;

intrinsic LMFDBSubgroup(H::SubgroupLatElt : normal_lattice:=false) -> LMFDBSubGrp
{}
    Lat := H`Lat;
    G := Lat`Grp;
    res := New(LMFDBSubGrp);
    res`LatElt := H;
    if not normal_lattice and (Get(G, "subgroup_inclusions_known") or Lat`index_bound ne 0) then
        assert assigned Lat`NormLat;
        if Get(H, "normal") then
            assert assigned H`NormLatElt;
        end if;
    end if;
    res`Grp := G;
    res`MagmaAmbient := G`MagmaGrp;
    res`MagmaSubGrp := H`subgroup;
    res`standard_generators := H`standard_generators;
    res`label := G`label * "." * H`label;
    res`short_label := H`label;
    if assigned H`aut_label then
        res`aut_label := Sprintf("%o.%o%o", H`aut_label[1], CremonaCode(H`aut_label[2]), H`aut_label[3]);
        if H`label[#H`label - 1..#H`label] eq ".N" then
            res`aut_label := res`aut_label * ".N";
        end if;
    else
        // normal complements, maximal subgroups and core-free subgroups below the index bound don't have an aut_label
        res`aut_label := None();
    end if;
    res`special_labels := H`special_labels;
    res`count := Get(H, "subgroup_count");
    res`conjugacy_class_count := Get(H, "cc_count");
    res`characteristic := Get(H, "characteristic");
    res`contains := (assigned H`unders) select SortLabels([Lat`subs[k]`label : k in Keys(H`unders)]) else None();
    res`contained_in := (assigned H`overs) select SortLabels([Lat`subs[k]`label : k in Keys(H`overs)]) else None();
    res`normal_contains := (assigned H`normal_unders) select SortLabels([Lat`subs[k]`label : k in H`normal_unders]) else None();
    res`normal_contained_in := (assigned H`normal_overs) select SortLabels([Lat`subs[k]`label : k in H`normal_overs]) else None();
    res`complements := (assigned H`complements) select [Lat`subs[k] : k in H`complements] else None();
    if assigned H`split then
        res`split := H`split;
    end if;
    if not normal_lattice then
        N := Get(H, "normalizer");
        res`normalizer := (Type(N) eq NoneType) select None() else Lat`subs[N]`label;
        N := Get(H, "normal_closure");
        res`normal_closure := (Type(N) eq NoneType) select None() else Lat`subs[N]`label;
        C := Get(H, "centralizer");
        res`centralizer := (Type(C) eq NoneType) select None() else Lat`subs[C]`label;
        res`centralizer_order := (Type(C) eq NoneType) select None() else Lat`subs[C]`order;
        res`core := Get(H, "core"); // this is a subgroup rather than a SubgroupLatElt
        res`core_order := Get(H, "core_order");
    end if;
    AssignBasicAttributes(res);
    return res;
end intrinsic;

intrinsic BestSubgroupLat(G::LMFDBGrp) -> SubgroupLat
{}
    if Get(G, "outer_equivalence") then
        if Get(G, "subgroup_inclusions_known") then
            L := Get(G, "SubGrpLatAut");
        else
            L := Get(G, "SubGrpLstAut");
        end if;
    else
        if Get(G, "subgroup_inclusions_known") then
            L := Get(G, "SubGrpLat");
        else
            L := Get(G, "SubGrpLst");
            // This can't be put inside SubGrpLst since it would cause an infinite recursion when called from SubGrpLstAut because G`outer_equivalence is not yet set
            IncludeNormalSubgroups(L);
        end if;
    end if;
    return L;
end intrinsic;

intrinsic Subgroups(G::LMFDBGrp) -> SeqEnum
{The list of LMFDBSubGrps computed for this group}
    L := Get(G, "BestSubgroupLat");
    t0 := ReportStart(G, "LabelSubgroups");
    LabelSubgroups(L);
    ReportEnd(G, "LabelSubgroups", t0);
    return [LMFDBSubgroup(H) : H in Get(L, "ordered_subs")];
    /*if Get(G, "all_subgroups_known") then
        SaveSubgroupCache(G, S);
    end if;*/
end intrinsic;

intrinsic SetMobiusQuo(L::SubgroupLat)
{}
    aut := L`outer_equivalence;
    t0 := ReportStart(L`Grp, "SetMobiusQuo");
    subs := Get(L, "ordered_subs");
    subs[#L]`mobius_quo := 1;
    for i in [#L-1..1 by -1] do
        x := subs[i];
        x`mobius_quo := 0;
        for j in half_interval(x, "unders", {}) do
            y := L`subs[j]; // the layer indices are into L`subs rather than ordered_subs
            if x`i ne y`i then
                // both are normal, so there is only 1 inclusion unless working up to automorphism
                n := aut select NumberOfInclusions(y, x) else 1;
                x`mobius_quo -:= n * y`mobius_quo;
            end if;
        end for;
    end for;
    ReportEnd(L`Grp, "SetMobiusQuo", t0);
end intrinsic;

intrinsic SetMobiusSub(L::SubgroupLat)
{}
    assert L`index_bound eq 0;
    G := L`Grp;
    t0 := ReportStart(G, "MobiusSub");
    top := get_top(L);
    top`mobius_sub := 1; //μ_G(G) = 1
    subs := Get(L, "ordered_subs");
    // L`subs are not necessarily sorted by index
    for i in [2..#L] do
        x := subs[i];
        x`mobius_sub := 0;
        //print "x", x`i;
        for j in half_interval(x, "overs", {}) do
            y := L`subs[j]; // the layer indices are into L`subs rather than ordered_subs
            if x`i eq y`i then continue; end if;
            n := NumberOfInclusions(x, y);
            //print x`i, y`i, y`subgroup_count, n, y`mobius_sub, x`subgroup_count;
            x`mobius_sub -:= (y`subgroup_count * n * y`mobius_sub) div x`subgroup_count;
        end for;
    //print "mobius_sub", x`mobius_sub;
    end for;
    ReportEnd(G, "MobiusSub", t0);
end intrinsic;

intrinsic normal_order_bound(G::LMFDBGrp) -> RngIntElt
{If n, normal subgroups of order at most n are stored; if 0 no limit; if null NormSubGrpLat didn't get run appropriately.}
    return None();
end intrinsic;

intrinsic normal_index_bound(G::LMFDBGrp) -> RngIntElt
{If n, normal subgroups of index at most n are stored; if 0 no limit; if null NormSubGrpLat didn't get run appropriately.}
    return None();
end intrinsic;

intrinsic NormSubGrpLat(G::LMFDBGrp) -> SubgroupLat
{Lattice of normal subgroups}
    L := New(SubgroupLat);
    L`Grp := G;
    GG := G`MagmaGrp;
    L`outer_equivalence := false;
    L`inclusions_known := true;
    L`index_bound := 0;
    t0 := ReportStart(G, "NormSubGrpLat");
    subs := Reverse(NormalSubgroups(GG));
    nsubs := #subs;
    G`number_normal_subgroups := nsubs;
    G`normal_order_bound := 0; // overwritten below in some cases
    G`normal_index_bound := 0; // overwritten below in some cases
    D := Divisors(G`order);
    ordcnt := AssociativeArray();
    for d in D do
        ordcnt[d] := 0;
    end for;
    for H in subs do
        ordcnt[H`order] +:= 1;
    end for;
    G`normal_counts := [ordcnt[d] : d in D];
    if nsubs ge NUM_NORMALS_NOAUT_LIMIT and FindSubsWithoutAut(G) then
        // In this case we trim the normal subgroups, starting from the middle.
        // we reorder divisors based on order that we're cutting them:
        // first the sqrt, then above, below, above, below, etc (going outward).
        doublemid := #D + 1;
        cur := (#D + 2) div 2; // either the square root (if a square) or the divisor just above it otherwise
        while nsubs ge NUM_NORMALS_NOAUT_LIMIT do
            nsubs -:= ordcnt[D[cur]];
            if 2*cur eq doublemid then
                lowtop := D[cur];
                highbot := D[cur];
                cur +:= 1;
            elif 2*cur gt doublemid then
                highbot := D[cur];
                cur := doublemid - cur;
            else
                lowtop := D[cur];
                cur := doublemid - cur + 1;
            end if;
        end while;
        G`normal_order_bound := D[Index(D, lowtop) - 1];
        G`normal_index_bound := G`order div D[Index(D, highbot) + 1];
        subs := [H : H in subs | H`order lt lowtop or H`order gt highbot];
    end if;
    L`subs := [SubgroupLatElement(L, subs[i]`subgroup : i:=i, normal:=true) : i in [1..#subs]];
    ReportEnd(G, "NormSubGrpLat", t0);
    if Get(G, "subgroup_inclusions_known") then
        ComputeLatticeEdges(~L, GG, IdentityHomomorphism(GG) : normal_lattice:=true);
        SetClosures(~L);
    end if;
    return L;
end intrinsic;

// Need to set label, aut_label
intrinsic NormSubGrpLatAut(G::LMFDBGrp) -> SubgroupLat
{Lattice of normal subgroups up to automorphism}
    if Get(G, "solvable") and Get(G, "HaveHolomorph") then
        L := New(SubgroupLat);
        L`Grp := G;
        L`outer_equivalence := true;
        L`inclusions_known := true;
        L`index_bound := 0;
        t0 := ReportStart(G, "NormSubGrpLatAut");
        subs := SolvAutSubs(G : normal:=true);
        L`subs := [SubgroupLatElement(L, subs[i]`subgroup : i:=i, normal:=true) : i in [1..#subs]];
        ReportEnd(G, "NormSubGrpLatAut", t0);
        if Get(G, "subgroup_inclusions_known") then
            ComputeLatticeEdges(~L, Get(G, "Holomorph"), Get(G, "HolInj"));
            SetClosures(~L);
        end if;
        return L;
    else
        // This assumes more attributes are set than NormSubGrpLat currently does
        return CollapseLatticeByAutGrp(Get(G, "NormSubGrpLat"));
    end if;
end intrinsic;

intrinsic BestNormalSubgroupLat(G::LMFDBGrp) -> SubgroupLat
{}
    if Get(G, "outer_equivalence") then
        return Get(G, "NormSubGrpLatAut");
    else
        return Get(G, "NormSubGrpLat");
    end if;
end intrinsic;

intrinsic NormalSubgroups(G::LMFDBGrp) -> Any
{lattice of normal subgroups, or None if not computed}
    // semidirect_product: need to find complements for each (currently implemented as a LMFDBSubGrp)
    // central_product: need to get central_factor
    // direct product should probably depend on this
    // should ideally get recycled when filling in normal subgroups (especially since complements are saved)
    L := BestNormalSubgroupLat(G);
    t0 := ReportStart(G, "LabelNormalSubgroups");
    LabelNormalSubgroups(L);
    ReportEnd(G, "LabelNormalSubgroups", t0);
    return [LMFDBSubgroup(H : normal_lattice:=true) : H in L`subs];
end intrinsic;

intrinsic LowIndexSubgroups(G::LMFDBGrp, d::RngIntElt) -> SeqEnum
    {List of low index LMFDBSubGrps, or None if not computed}
    m := Get(G, "subgroup_index_bound");
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
    elif Type(HH) eq SubgroupLatElt then
        return HH`label;
    elif FindSubsWithoutAut(G) then
        // Unfortunately, some SubgroupIdentify calls are slow and we don't want to derail everything
        return "\\N";
    else
        L := Get(G, "BestSubgroupLat");
        S := Get(G, "Subgroups"); // triggers labeling
        i := SubgroupIdentify(L, HH : error_if_missing:=false);
        if i eq -1 then
            return "\\N";
        else
            return L`subs[i]`label;
        end if;
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


/*
The following code was part of an unsuccessful attempt to use the lattice to find all_minimal_chains.
It does not produce correct results and needs some additional idea to make functional.
It hasn't been deleted because it's faster than the current version of all_minimal_chains...
*/

intrinsic CyclicQuotients(top::SubgroupLatElt) -> SeqEnum
{}
    /* WARNING: This function can return incorrect results */
    Lat := top`Lat;
    H := top`subgroup;
    D := Lat!DerivedSubgroup(H);
    divs := {d : d in Divisors(top`order) | IsDivisibleBy(d, D`order)};
    down := half_interval(top, "unders", divs) meet half_interval(D, "overs", divs);
    poss := Sort([i : i in down | i ne top`i]);
    ans := [];
    while #poss gt 0 do
        i := poss[1];
        bottom := Lat`subs[i];
        if IsDefined(top`unders, i) then
            // maximal subgroup of top
            Append(~ans, bottom);
            Remove(~poss, 1);
            continue;
        end if;
        I := Interval(top, bottom : downward:=down);
        if IsProbablyCyclic(I) then
            Append(~ans, bottom);
            Remove(~poss, 1);
        else
            pruned := half_interval(bottom, "unders", divs);
            for i in pruned do
                // Faster to sort and do one pass, but unlikely to be dominant step
                Exclude(~poss, i);
            end for;
        end if;
    end while;
    return ans;
end intrinsic;

intrinsic IsProbablyCyclic(I::SubgroupLatInterval) -> BoolElt
{Whether the quotient top/bottom is cyclic.
Assumes that the quotient of the top by every intermediate node is (probably) cyclic,
and that that the bottom node contains the derived subgroup of the top.

This can fail and produce spurious results:
G := MakeSmallGroup(256, 34);
Lat := Get(G, "SubGrpLatAut");
IsProbablyCyclic(Interval(Lat!5, Lat!26));
true
IsActuallyCyclic(Interval(Lat!5, Lat!26));
false
}
    /* WARNING: This function can return incorrect results */
    if Empty(I) then return false; end if;
    n := Get(I`Lat`Grp, "order");
    D := Sort([n div d : d in Divisors(I`top`order) | IsDivisibleBy(d, I`bottom`order)]);
    by_index := Get(I, "by_index");
    for d in D do
        if not IsDefined(by_index, d) or #by_index[d] ne 1 then
            return false;
        end if;
    end for;
    // There's maybe a faster way to do this but this is simple
    bcnt := I`bottom`subgroup_count;
    for d1 in D do
        outer_prod := bcnt * by_index[d1][1]`subgroup_count;
        for d2 in D do
            if IsDivisibleBy(d2, d1) and not IsDivisibleBy(outer_prod, by_index[d2][1]`subgroup_count) then
                return false;
            end if;
        end for;
    end for;

    // I couldn't get the following reasoning to work....
    // Let NT be the normalizer of the top, and NH be the normalizer of some subgroup H in the interval
    // top is normal in NT, so if we work inside NT we need that there is only one NT-conjugacy class of subgroup conjugate to H (that contains bottom), ie H is normal inside NT or that NH contains NT. 
    return true;
end intrinsic;

intrinsic IsActuallyCyclic(I::SubgroupLatInterval) -> BoolElt
{}
    top := I`top`subgroup;
    bottom := I`bottom`subgroup;
    if bottom subset top then
        return IsNormal(top, bottom) and IsCyclic(quo<top | bottom>);
    else
        N := Normalizer(I`Lat`Grp`MagmaGrp, bottom);
        T := Transversal(I`Lat`Grp`MagmaGrp, N);
        for t in T do
            Bt := bottom^t;
            if Bt subset top then
                return IsNormal(top, Bt) and IsCyclic(quo<top | Bt>);
            end if;
        end for;
    end if;
    error "no inclusion found";
end intrinsic;

intrinsic all_minimal_chains_lat(G::LMFDBGrp) -> SeqEnum
{Aimed to return all minimal length chains of subgroups so that each is normal in the previous with cyclic quotient.
 Unfortunately, because the lattice is up to conjugacy it's difficult to predict when a quotient is cyclic just from containment information.  Here's an example:
G := SmallGroup(256, 33);
gens := PCGenerators(G);
H := sub<G|gens[1], gens[3], gens[7]*gens[8]>;
K1 := sub<G|gens[3], gens[4]>;
K2 := sub<G|gens[3] * gens[4] * gens[6] * gens[8], gens[4] * gens[7] * gens[8]>;
K1 subset H and IsNormal(H, K1);
true
K2 subset H and IsNormal(H, K2);
true
Hol, inj := Holomorph(G);
conj, elt := IsConjugate(Hol, inj(K1), inj(K2));
conj;
true
IsCyclic(H/K1);
false
IsCyclic(H/K2);
true
K1 and K2 are in the same class, but their quotients are different (the automorphism that maps K1 to K2 doesn't fix H).
}
    /* WARNING: This function can return incorrect results */
    assert Get(G, "solvable");
    //L := Get(G, "outer_equivalence") select Get(G, "SubGrpLatAut") else Get(G, "SubGrpLat");
    L := Get(G, "SubGrpLatAut");
    cycdist := AssociativeArray();
    top := L!1; // backward from how Magma internal lattices number
    bottom := L!(#L);
    cycdist[top] := 0;
    reverse_path := AssociativeArray();
    Seen := {top};
    Layer := {top};
    while true do
        NewLayer := {};
        for h in Layer do
            for x in CyclicQuotients(h) do
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
        if (bottom in Layer) then
            break;
        elif (#Layer eq 0) then
            error "Didn't reach bottom";
        end if;
    end while;
    M := cycdist[bottom];
    chains := [[bottom]];
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
end intrinsic;


intrinsic AMCCompare(N, i) -> LMFDBGrp, SubgroupLat
{Compares results of the two all_minimal_chains algorithms in the pursuit of finding bugs}
    G := MakeSmallGroup(N, i);
    t0 := Cputime();
    Lat := Get(G, "SubGrpLatAut");
    print "Lattice", Cputime() - t0;
    t0 := Cputime();
    chains1 := all_minimal_chains_lat(G);
    print "Lattice chains", Cputime() - t0;
    t0 := Cputime();
    chains2 := all_minimal_chains(G);
    print "Derived chains", Cputime() - t0;
    S1 := {[c`i : c in chain] : chain in chains1};
    S2 := {[(Lat!(c`subgroup))`i : c in chain] : chain in chains2};
    missing := S1 diff S2;
    if #missing gt 0 then
        print "Missing", #missing;
        for latchain in missing do
            print Join([Sprint(c) : c in latchain], " ");
        end for;
    end if;
    extra := S2 diff S1;
    if #extra gt 0 then
        print "Extra", #extra;
        for latchain in extra do
            print Join([Sprint(c) : c in latchain], " ");
        end for;
    end if;
    return G, Lat;
end intrinsic;

