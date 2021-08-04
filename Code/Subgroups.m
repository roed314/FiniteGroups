/**********************************************************
This file supports computation of subgroups of abstract groups.

Which subgroups we compute and store is determined by the function
SetSubgroupParameters
**********************************************************/

VS_QUOTIENT_CUTOFF := 5; // if G has a subquotient vector space of dimension larger than this, we always compute up to automorphism;
NUM_SUBS_RATCHECK := 128; // if G has less than this many subgroups up to conjugacy, we definitely compute them up to conjugacy (and the orbits under Aut(G)
NUM_SUBS_RATIO := 2; // if G has between NUM_SUBS_RATCHECK and NUM_SUBS_CUTOFF_CONJ subgroups up to conjugacy, we record up to conjugacy (and the orbits under Aut(G))
NUM_SUBS_CUTOFF_CONJ := 1024; // if G has at least this many subgroups up to conjugacy, we definitely compute subgroups up to automorphism
NUM_SUBS_CUTOFF_AUT := 4096; // if G has at least this many subgroups up to automorphism, we only compute subgroups up to automorphism, and up to an index bound
NUM_SUBS_LIMIT_AUT := 1024; // if we compute up to an index bound, we set it so that less than this many subgroups up to automorphism are stored
LAT_CUTOFF := 128; // if G has less than this many subgroups up to automorphism, we compute inclusion relations for the lattices of subgroups (both up-to-automorphism and, if present, up-to-conjugacy)

declare type LMFDBSubgroupCache;
declare attributes LMFDBSubgroupCache:
        MagmaGrp,
        Subgroups,
        outer_equivalence, // true if up to automorphism
        description, // a string usable to reconstruct the ambient group
        labels, // a list of labels of subgroups
        gens, // a list of lists of elements generating the subgroups
        standard; // a list of booleans; whether the generators correspond to the standard generators for that abstract group

declare type LMFDBSubgroupCacheCollection;
declare attributes LMFDBSubgroupCacheCollection:
        cache;
subgroup_cache := New(LMFDBSubgroupCacheCollection);
subgroup_cache`cache := AssociativeArray();

intrinsic GetGrp(C::LMFDBSubgroupCache) -> LMFDBGrp
{}
    G := New(LMFDBGrp);
    G`MagmaGrp := C`MagmaGrp;
    return G;
end intrinsic;

intrinsic LoadSubgroupCache(label::MonStgElt : sep:=":") -> LMFDBSubgroupCache
{}
    if IsDefined(subgroup_cache`cache, label) then
        return subgroup_cache`cache[label];
    end if;
    C := New(LMFDBSubgroupCache);
    folder := GetLMFDBRootFolder();
    if #folder ne 0 then
        cache := folder * "SUBCACHE/" * label;
        ok, I := OpenTest(cache, "r");
        if ok then
            data := Read(I);
            data := Split(data, sep: IncludeEmpty := true);
            attrs := ["outer_equivalence", "labels", "gens", "standard"];
            error if #data ne (#attrs + 1), "Wrong size data line";
            C`description := data[1];
            C`MagmaGrp := eval data[1];
            for i in [2..#attrs] do
                attr := attrs[i-i];
                C``attr := LoadAttr(attr, data[i], C);
            end for;
        end if;
    end if;
    subgroup_cache`cache[label] := C;
    return C;
end intrinsic;

intrinsic SaveSubgroupCache(G::LMFDBGrp, subs::SeqEnum : sep:=":")
{We only save subgroup caches when complete (no index bound)}
    folder := GetLMFDBRootFolder();
    if #folder ne 0 then
        C := New(LMFDBSubgroupCache);
        C`outer_equivalence := G`outer_equivalence;
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

function AllSubgroupsOk(G)
    // A simple heuristic on whether Subgroups(G) might take a very long time
    E := ElementaryAbelianSeriesCanonical(G);
    for i in [1..#E-1] do
        if Factorization(Order(E[i]) div Order(E[i+1]))[1][2] gt VS_QUOTIENT_CUTOFF then
            return false;
        end if;
    end for;
    return true;
end function;

function SplitByAuts(L, H, inj : use_order:=true, use_gassman:=true)
    // L is a list of lists of records, including `order and `subgroup
    function check_done(M)
        return &and[#x eq 1 : x in M];
    end function;
    if check_done(L) then return L; end if;
    if use_order then
        newL := [];
        for chunk in L do
            if #chunk gt 1 then
                by_ord := AssociativeArray();
                for s in chunk do
                    n := s`order;
                    if IsDefined(by_ord, n) then
                        Append(~by_ord[n], s);
                    else
                        by_ord[n] := [s];
                    end if;
                end for;
                newL cat:= [x : x in by_ord];
            else
                Append(~newL, chunk);
            end if;
        end for;
        L := newL;
        if check_done(L) then return L; end if;
    end if;
    if use_gassman then
        cmap := inj * ClassMap(H);
        newL := [];
        for chunk in L do
            if #chunk gt 1 then
                by_gass := AssociativeArray();
                for s in chunk do
                    gvec := SubgroupClass(s`subgroup, cmap);
                    if IsDefined(by_gass, gvec) then
                        Append(~by_gass[gvec], s);
                    else
                        by_gass[gvec] := [s];
                    end if;
                    newL cat:= [x : x in by_gass];
                end for;
            else
                Append(~newL, chunk);
            end if;
        end for;
        L := newL;
        if check_done(L) then return L; end if;
    end if;
    newL := [];
    for chunk in L do
        if #chunk gt 1 then
            new_chunk := [];
            for s in chunk do
                found := false;
                for x in new_chunk do
                    if IsConjugate(H, inj(s`subgroup), inj(x[1]`subgroup)) then
                        found := true;
                        break;
                    end if;
                end for;
                if found then
                    Append(~x, s);
                else
                    Append(~new_chunk, [s]);
                end if;
            end for;
            newL cat:= new_chunk;
        else
            Append(~newL, chunk);
        end if;
    end for;
    return newL;
end function;

intrinsic Holomorph(X::LMFDBGrp) -> Grp
{}
    G := X`MagmaGrp;
    A := Type(G) eq GrpPC select AutomorphismGroupSolubleGroup(G) else AutomorphismGroup(G);
    H, inj := Holomorph(G, A);
    X`HolInj := inj;
    return H;
end intrinsic;

intrinsic HolInj(X::LMFDBGrp) -> HomGrp
{}
    _ := Holomorph(X); // computes the injection
    return X`HolInj;
end intrinsic;

intrinsic SubGrpListAut(X::LMFDBGrp) -> SeqEnum
    {The list of subgroups up to automorphism, cut off by an index bound if too many}
    G := X`MagmaGrp;
    N := Get(X, "order");
    H := Get(X, "Holomorph");
    inj := Get(X, "HolInj");
    GG := inj(G);
    RF := recformat< subgroup : Grp, order : Integers() >;
    if Get(X, "solvable") then
        E := ElementaryAbelianSeriesCanonical(G);
        EE := [inj(e) : e in E];
        subs := Subgroups(sub<GG|> : Presentation:=true);
        for i in [1..#EE-1] do
            subs := SubgroupsLift(H,EE[i],EE[i+1],subs);
        end for;
        subs := [ rec< RF | subgroup := s`subgroup @@ inj, order := s`order> : s in subs ];
        Sort(~subs, func<x, y | x`order - y`order>);
    else
        if AllSubgroupsOk(G) then
            subs := Get(X, "SubGrpList");
            subs := SplitByAuts([subs], H, inj);
        else
            // There may be too many subgroups, so we work by index
            N := Get(X, "order");
            D := Reverse(Divisors(N));
            subs := [];
            extra_subs := [];
            count := 0;
            for d in D do
                dsubs := Subgroups(G : OrderEqual := d);
                dsubs := SplitByAuts([dsubs], H, inj : use_order := false);
                count +:= #dsubs;
                if count ge NUM_SUBS_CUTOFF_AUT then
                    break;
                elif count ge NUM_SUBS_LIMIT_AUT then
                    extra_subs cat:= dsubs;
                else
                    subs cat:= dsubs;
                end if;
            end for;
            if count lt NUM_SUBS_CUTOFF_AUT then
                subs cat:= extra_subs;
            end if;
        end if;
        X`SubGrpAutOrbits := subs;
        subs := [x[1] : x in subs];
    end if;
    if #subs ge NUM_SUBS_CUTOFF_AUT then
        cut := #subs;
        for i in [1..NUM_SUBS_LIMIT_AUT-1] do
            if subs[#subs-i]`order ne subs[cut]`order then
                cut := #subs - i + 1;
            end if;
        end for;
        subs := subs[cut..#subs];
    end if;
    return subs;
end intrinsic;

declare type SubgroupLatElt;
declare attributes SubgroupLatElt:
        subgroup,
        order,
        gens,
        i,
        full_label,
        short_label,
        over, // other subs this sub contains maximally, as an associative array i->cnt, where i is the index in subs and cnt is the number of reps in that class contained in a single rep of this class
        under, // other subs this sub is contained in minimally, in the same format
        subgroup_count, // the number of subgroups in this conjugacy class of subgroups
        cc_count, // the number of conjugacy classes in this autjugacy class of subgroups
        normalizer,
        centralizer,
        normal_closure;

declare type SubgroupLat;
declare attributes SubgroupLat:
        subs;

// Implementation adapted from Magma's Groups/GrpFin/subgroup_lattice.m
RF := recformat<subgroup, order, length>;
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
function maximal_subgroup_classes(Ambient, H, inj, N : collapse:=true)
    // Ambient = G or Holomoprph(G)
    // H is a subgroup of G
    // inj is the map from G to Ambient
    // N is the normalizer of H inside Ambient
    // Returns a list of records giving maximal subgroups of H up to conjugacy in Ambient; if collapse then guaranteed to be inequivalent
    if IsTrivial(H) then return []; end if;
    function do_collapse(results)
        if collapse then
            results := SplitByAuts([results], Ambient, inj);
            return [rec<RF|subgroup:=r[1]`subgroup, order:=r[1]`order, length:=&+[x`length : x in r]> : r in results];
        else
            return results;
        end if;
    end function;
    if #FactoredOrder(H) gt 1 then
        return do_collapse(ms(H));
    end if;
    N := Normalizer(Ambient, inj(H));
    if N eq Ambient then
        return do_collapse(ms(H));
    end if;
    F := FrattiniSubgroup(H);
    M, f := GModule(N, H, F);
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
function SubgroupLattice(GG, aut)
    // sub, gens, i, full_label, short_label, over (other subs this sub contains maximally as i->cnt), under, subgroup_count, cc_count, normalizer, centralizer, normal_closure
    G := GG`MagmaGrp;
    solv := Get(GG, "solvable");
    if solv then
        // Hall's theorem
        singleton_orders := {d : d in Divisors(#G) | Gcd(d, #G div d) eq 1};
    elif #Factorization(#G) gt 1
        // On Hall subgroups of a finite group
        // Wenbin Guo and Alexander Skiba
        CS := ChiefSeries(G);
        indexes := [#CS[i] div #CS[i+1] : i in [1..#CS-1]];
        singleton_orders := {};
        for d in Divisors(#G) do
            if Gcd(d, #G div d) eq 1 and &and[IsDivisibleBy(d, ind) or IsDivisibleBy(#G div d, ind) : ind in indexes] then
                Include(~singleton_orders, d);
            end if;
        end for;
    else
        singleton_orders := {1, #G};
    end if;
    if aut then
        Ambient := Get(GG, "Holomorph");
        inj := Get(GG, "HolInj");
    else
        Ambient := G;
        inj := IdentityHomomorphism(G);
    end if;
    Mlist := maximal_subgroup_classes(Ambient, G, inj : collapse:=true);
    collapsed := AssociativeArray();
    top := New(SubgroupLatElt);
    top`subgroup := sub<G|G>;
    top`order := #G;
    collapsed[#G] := [top];
    to_add := AssociativeArray();
    for MM in Mlist do
        M := MM`subgroup;
        lab := label(M);
        cache := LoadSubgroupCache(lab);
        if Valid(cache) then
            ok, phi := IsIsomorphic(cache`MagmaGrp, M);
            if not ok then
                error, Sprintf("Lack of isomorphism: %s for %s < %s", lab, Generators(M), GG`label);
            end if;
            if not IsDefined(collapsed, MM`order) then collapsed[MM`order] := []; end if;
            // The equivalence relation for subgroups in the cache is not the one desired.  It's okay if there are duplicates (this will be cleaned up below), but we need to ensure that we hit all the classes.
            // If the subgroups in the cache are up to conjugacy, we're fine
            // Otherwise, let A_G = Holomorph(G) or G, A_M = Aut(M) and H_M = Holomorph(M)
            // N_{A_G}(M) -> A_M -> H_M / N_{H_M}(H).  A transversal of the image will give *inequivalent* reps coming from H
            if cache`outer_equivalence then
                NM := Normalizer(Ambient, inj(M));
                AM := Type(M) eq GrpPC select AutomorphismGroupSolubleGroup(M) else AutomorphismGroup(M);
                HM, injM, projM := Holomorph(M, AM);
                SM := sub<AM | [hom<M -> M | [proj(f)(m) : m in Generators(M)]> : f in Generators(NM)]>;
                SM := SM @@ projM;
            end if;
            //Append(~collapsed[H`order],
        end if;
    end for;
    orders := {@ #G @};
    grps := [G];
    grp_with_order := [[1]];
    incls := {@ @}; /* edges of lattice graph (Hasse diagram) */
    weights := [ ]; /* weights of corresponding edges */
    done := 0;
end intrinsic;

intrinsic SubGrpList(G::LMFDBGrp) -> SeqEnum, boolean
    {The list of subgroups up to conjugacy, as computed by Magma}
    return Subgroups(G`MagmaGrp);
end intrinsic;

intrinsic SubGrpLatAut(G::LMFDBGrp) -> SubgroupLat
{The lattice of subgroups up to automorphism}
    return SubgroupLattice(G, true);
end intrinsic;

intrinsic SubGrpLat(G::LMFDBGrp) -> SubgroupLat
{The lattice of subgroups up to conjugacy}
    return SubgroupLattice(G, false);
end intrinsic;

intrinsic SetSubgroupParameters(G::LMFDBGrp)
    {Set the parameters for which subgroups to compute (and do some initial computations)}
    GG := G`MagmaGrp;
    byA := Get(G, "SubGrpListAut");
    if #byA ge NUM_SUBS_CUTOFF_CONJ or byA[1]`order ne 1 or not AllSubgroupsOk(GG) then
        // too many subgroups up to automorphism, so we don't need to compute the list up to conjugacy
        G`outer_equivalence := true;
    else
        byC := Get(G, "SubGrpList");
        G`outer_equivalence := (#byC ge NUM_SUBS_RATCHECK and #byC ge NUM_SUBS_RATIO * #byA);
    end if;
    if G`outer_equivalence and byA[1]`order ne 1 then
        G`subgroup_index_bound := byA[1]`order;
        G`all_subgroups_known := false;
    else
        G`subgroup_index_bound := 0;
        G`all_subgroups_known := true;
    end if;
    G`normal_subgroups_known := true;
    G`maximal_subgroups_known := true;
    G`sylow_subgroups_known := true;
    G`subgroup_inclusions_known := (#byA lt LAT_CUTOFF and byA[1]`order eq 1);
end intrinsic;

/* turns G`label and output of LabelSubgroups into string */

function CreateLabel(Glabel, Hlabel)
    if #Hlabel gt 0 then
        return Glabel * "." * Join([Sprint(x) : x in Hlabel], ".");
    else // used for special subgroups where there is only a suffix
        return Glabel;
    end if;
end function;


intrinsic Subgroups(G::LMFDBGrp) -> SeqEnum
    {The list of subgroups computed for this group}
    t0 := Cputime();
    S := [];
    GG := G`MagmaGrp;
    function MakeSubgroups(SubLabels, GG, orig: suffixes := "")
        // SubLabels is a SeqEnum of triples (label, subgroup, index in orig)
        // orig may be a SubGrpLat or a SeqEnum of records
        S := [];
        initial := false;
        if Type(suffixes) eq MonStgElt then
            initial = (suffixes eq "");
            suffixes := [suffixes : _ in SubLabels];
        end if;
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
            // we may eventually need to stop creating isomorphisms with the abstract subgroup, but for now we do it.
            H`standard_generators := true;
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
    vprint User1: "XXXXXXXXXX Conj computed", Cputime(t0);
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
    G`gens_used := []; // need to be present in order to save; overwritten in RePresentLat for solvable groups
    RF := recformat< subgroup : Grp, order : Integers() >;
    all_sylow:=G`sylow_subgroups_known;
    if G`subgroup_inclusions_known then
        if max_index ne 0 then
            error "Must include all subgroups before providing inclusions";
        end if;
        Orig := SubgroupLattice(GG : Centralizers := true, Normalizers := true);
        vprint User1: "XXXXXXXXXX Lat computed", Cputime(t0);
        // the following sets PresentationIso and GeneratorIndexes
        if IsSolvable(GG) then
            RePresentLat(G, Orig);
            vprint User1: "XXXXXXXXXX Represented lat", Cputime(t0);
        end if;
        G`SubGrpLat := Orig;
        Subs := [rec< RF | subgroup := Orig[i], order := Order(Orig!i) > : i in [1..#Orig]];
        SubLabels := LabelSubgroups(GG, Subs : phi:=newphi);
    else
        Orig := Subgroups(GG: IndexLimit:=max_index);
        vprint User1: "XXXXXXXXXX Subs computed", Cputime(t0);

        // the following sets PresentationIso and GeneratorIndexes
        if IsSolvable(GG) then
            RePresent(G);
            vprint User1: "XXXXXXXXXX Represented subs", Cputime(t0);
        end if;
        /* assign Sylows beyond index bound */
        if max_index ne 0 and all_sylow then /* some unlabeled */
            for pe in Factorization(Get(G,"order")) do
                p := pe[1];
                q := p^pe[2];
                if q lt ordbd then
                    Append(~Orig, rec< RF | subgroup := SylowSubgroup(GG, p), order := q >);
                end if;
            end for;
        end if;
        Sort(~Orig, func<x, y | x`order - y`order>);
        SubLabels:= LabelSubgroups(GG, Orig : phi:=newphi);
    end if;
    vprint User1: "XXXXXXXXXX Subgroups labelled", Cputime(t0);

    vprint User1: "XXXXXXXXXX Subgroups made", Cputime(t0);
    S := MakeSubgroups(SubLabels, GG, Orig);
    /* assign the normal beyond index bound */
    all_normal:=G`normal_subgroups_known;
    if max_index ne 0 and all_normal then /* some unlabeled */

        N := NormalSubgroups(GG);

        UnLabeled := [n : n in N | n`order lt ordbd and (not all_sylow or #Factorization(n`order) gt 1)];
        SubLabels := LabelSubgroups(GG, UnLabeled : phi:=newphi);
        S cat:= MakeSubgroups(SubLabels, GG, Orig : suffixes := ".N");
    end if;
    vprint User1: "XXXXXXXXXX Normals done", Cputime(t0);

    /* assign the maximal beyond index bound */
    all_maximal:=G`maximal_subgroups_known;
    if max_index ne 0 and all_maximal then /* some unlabeled */
        M := MaximalSubgroups(GG);

        UnLabeled := [m : m in M | m`order lt ordbd and (not all_sylow or #Factorization(m`order) gt 1)];
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
       S cat:= MakeSubgroups(NewSubLabels, GG, Orig : suffixes := ".M");
    end if;
    vprint User1: "XXXXXXXXXX Maximals done", Cputime(t0);

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
    vprint User1: "XXXXXXXXXX Specials done", Cputime(t0);
    S cat:= MakeSubgroups(NewSubLabels, GG, Orig : suffixes := NewSuffixes);
    if max_index eq 0 then
        SaveSubgroupCache(G, S);
    end if;
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
