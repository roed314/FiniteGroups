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
LAT_CUTOFF := 4096; // if G has less than this many subgroups up to automorphism, we compute inclusion relations for the lattices of subgroups (both up-to-automorphism and, if present, up-to-conjugacy)

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

function SplitByAuts(L, H, inj : use_order:=true, use_hash:=true, use_gassman:=false)
    // L is a list of lists of records or SubgroupLatElts, including `order and `subgroup
    // Gassman class is slow in holomorphs
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
    if use_hash then
        newL := [];
        for chunk in L do
            if #chunk gt 1 then
                by_hash := AssociativeArray();
                for j in [1..#chunk] do
                    s := chunk[j];
                    hsh := EasyHash(s`subgroup);
                    if IsDefined(by_hash, hsh) then
                        Append(~by_hash[hsh], s);
                    else
                        by_hash[hsh] := [s];
                    end if;
                end for;
                newL cat:= [x : x in by_hash];
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
                for j in [1..#chunk] do
                    s := chunk[j];
                    if "gassman_vec" in GetAttributes(Type(s)) then
                        if assigned s`gassman_vec then
                            gvec := s`gassman_vec;
                        else
                            gvec := SubgroupClass(s`subgroup, cmap);
                            s`gassman_vec := gvec;
                        end if;
                    else
                        gvec := SubgroupClass(s`subgroup, cmap);
                    end if;
                    if IsDefined(by_gass, gvec) then
                        Append(~by_gass[gvec], s);
                    else
                        by_gass[gvec] := [s];
                    end if;
                end for;
                newL cat:= [x : x in by_gass];
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
                j := 1;
                while j le #new_chunk do
                    x := new_chunk[j];
                    if IsConjugate(H, inj(s`subgroup), inj(x[1]`subgroup)) then
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
        Lat,
        subgroup,
        order,
        gens,
        i, // can be negative during construction, but set to the index in subs when complete
        full_label,
        short_label,
        unders, // other subs this sub contains maximally, as an associative array i->cnt, where i is the index in subs and cnt is the number of reps in that class contained in a single rep of this class
        overs, // other subs this sub is contained in minimally, in the same format
        subgroup_count, // the number of subgroups in this conjugacy class of subgroups
        cc_count, // the number of conjugacy classes in this autjugacy class of subgroups
        recurse,
        standard_generators,
        gassman_vec, // for identification
        easy_hash, // for identification
        normalizer,
        centralizer,
        normal_closure;

declare type SubgroupLat;
declare attributes SubgroupLat:
        Grp,
        outer_equivalence,
        subs,
        by_index;

declare type SubgroupLatInterval;
declare attributes SubgroupLatInterval:
        Lat,
        top,
        bottom,
        by_index;

intrinsic SubgroupLatIdentify(Lat::SubgroupLat, H::Grp : use_hash:=true, use_gassman:=false) -> RngIntElt
{Determines the index of a given subgroup among the elements of the lattice.
 Requires by_index to be set, but not subgroup_count, overs or unders on the elements}
    G := Lat`Grp`MagmaGrp;
    poss := Lat`by_index[Index(G, H)];
    if #poss eq 1 then
        return poss[1]`i;
    end if;
    if Lat`outer_equivalence then
        Ambient := Get(Lat`Grp, "Holomorph");
        inj := Get(Lat`Grp, "HolInj");
        cmap := inj * ClassMap(Ambient);
    else
        Ambient := G;
        inj := IdentityHomomorphism(G);
        cmap := ClassMap(G);
    end if;
    if use_hash then
        refined := [];
        hsh := EasyHash(H);
        for j in [1..#poss] do
            HH := poss[j];
            if not assigned HH`easy_hash then
                HH`easy_hash := EasyHash(HH`subgroup);
            end if;
            if HH`easy_hash eq hsh then
                Append(~refined, HH);
            end if;
        end for;
        if #refined eq 1 then
            return refined[1]`i;
        end if;
        poss := refined;
    end if;
    if use_gassman then
        refined := [];
        gvec := SubgroupClass(H, cmap);
        for j in [1..#poss] do
            HH := poss[j];
            if not assigned HH`gassman_vec then
                HH`gassman_vec := SubgroupClass(HH`subgroup, cmap);
            end if;
            if HH`gassman_vec eq gvec then
                Append(~refined, HH);
            end if;
        end for;
        if #refined eq 1 then
            return refined[1]`i;
        end if;
        poss := refined;
    end if;
    Hi := inj(H);
    for HH in poss do
        if IsConjugate(Ambient, Hi, inj(HH`subgroup)) then
            return HH`i;
        end if;
    end for;
    error "Subgroup not found";
end intrinsic;

intrinsic 'eq'(L::SubgroupLat, M::SubgroupLat) -> BoolElt
{}
    return L`Grp`MagmaGrp eq M`Grp`MagmaGrp and L`outer_equivalence eq M`outer_equivalence;
end intrinsic;
intrinsic 'eq'(x::SubgroupLatElt, y::SubgroupLatElt) -> BoolElt
{}
    return x`i eq y`i and x`Lat eq y`Lat;
end intrinsic;
intrinsic IsCoercible(Lat::SubgroupLat, i::RngIntElt) -> BoolElt, SubgroupLatElt
{}
    return (0 lt i and i le #Lat`subs), Lat`subs[i];
end intrinsic;
intrinsic IsCoercible(Lat::SubgroupLat, H::Grp) -> BoolElt, SubgroupLatElt
{}
    return H subset (Lat`Grp`MagmaGrp), Lat`subs[SubgroupLatIdentify(Lat, H)];
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
    for d in Sort([k : k in Keys(Lat`by_index)]) do
        m := n div d;
        for H in Lat`by_index[d] do
            Append(~lines, Sprintf("[%o]  Order %o  Length %o  Maximal Subgroups: %o", H`i, m, H`subgroup_count, Join([Sprint(u) : u in Sort([j : j in Keys(H`unders)])], " ")));
        end for;
    end for;
    printf Join(lines, "\n");
end intrinsic;

intrinsic Empty(I::SubgroupLatInterval) -> BoolElt
{}
    return #I`by_index eq 0;
end intrinsic;

intrinsic Interval(top::SubgroupLatElt, bottom::SubgroupLatElt) -> SubgroupLatInterval
{}
    if top`Lat ne bottom`Lat then
        error "elements must belong to the same lattice";
    end if;
    I := New(SubgroupLatInterval);
    Lat := top`Lat;
    n := Get(Lat`Grp, "order");
    I`Lat := Lat;
    I`top := top;
    I`bottom := bottom;
    I`by_index := AssociativeArray();
    D := {d : d in Divisors(top`order) | IsDivisibleBy(d, bottom`order)};
    halves := AssociativeArray();
    seen := AssociativeArray();
    for dir in ["overs", "unders"] do
        e := dir eq "overs" select bottom else top;
        halves[dir] := [e];
        done := 0;
        seen[dir] := {e`i};
        while done lt #halves[dir] do
            done +:= 1;
            for m in Keys(halves[dir][done]``dir) do
                H := Lat`subs[m];
                if H`order in D and not H`i in seen[dir] then
                    Include(~seen[dir], H`i);
                    Append(~halves[dir], H);
                end if;
            end for;
        end while;
        if not (top`i in seen[dir] and bottom`i in seen[dir]) then
            return I;
        end if;
    end for;
    for i in seen["overs"] do
        if i in seen["unders"] then
            // Perhaps it would be better to create new SubgroupLatElts so that the lengths would be correct, but for now we just do what's simple and use the elements from Lat
            cur := Lat`subs[i];
            ind := n div cur`order;
            if IsDefined(I`by_index, ind) then
                Append(~I`by_index[ind], cur);
            else
                I`by_index[ind] := [cur];
            end if;
        end if;
    end for;
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

intrinsic IsCyclic(I::SubgroupLatInterval) -> BoolElt
{Whether the quotient top/bottom is cyclic.  If so, also returns an element that conjugates the bottom into an actual subgroup of the top.}
    if Empty(I) then return false; end if;
    D := {d : d in Divisors(I`top`order) | IsDivisibleBy(d, I`bottom`order)};
    for d in D do
        if not IsDefined(I`by_index, d) or #I`by_index[d] ne 1 then
            return false;
        end if;
    end for;
    // Let NT be the normalizer of the top, and NH be the normalizer of some subgroup H in the interval
    // top is normal in NT, so if we work inside NT we need that there is only one NT-conjugacy class of subgroup conjugate to H (that contains bottom), ie H is normal inside NT or that NH contains NT. 
    /*P := PrimeDivisors(I`top`order div I`bottom`order);
    for d in D do
        X := I`by_index[d][q];
        if 
        for p in P do
            if d div p in D then
                below := I`by_index[d div p][1]`i;
                if not (IsDefined(X[1]`unders, below) and X[1]`unders[below] eq 1) then
                    print d, p, below, Keys(X[1]`unders);//, X[1]`unders[below];
                    return false;
                end if;
            end if;
        end for;
    end for;*/
    return true;
end intrinsic;

intrinsic IsActuallyCyclic(I::SubgroupLatInterval) -> BoolElt
{}
    top := I`top`subgroup;
    bottom := I`bottom`subgroup;
    if bottom subset top then
        return IsCyclic(quo<top | bottom>);
    else
        N := Normalizer(I`Lat`Grp`MagmaGrp, bottom);
        T := Transversal(I`Lat`Grp`MagmaGrp, N);
        for t in T do
            Bt := bottom^t;
            if Bt subset top then
                return IsCyclic(quo<top | Bt>);
            end if;
        end for;
    end if;
    error "no inclusion found";
end intrinsic;

intrinsic IsConvex(I::SubgroupLatInterval) -> BoolElt
{}
    if not IsCyclic(I) then return false; end if;
    for a in Keys(I`by_index) do
        for b in Keys(I`by_index) do
            if a eq b or not IsDivisibleBy(b, a) then continue; end if;
            for c in Keys(I`by_index) do
                if b eq c or not IsDivisibleBy(c, b) then continue; end if;
                if not IsDivisibleBy(I`by_index[a][1]`subgroup_count*I`by_index[c][1]`subgroup_count, I`by_index[b][1]`subgroup_count) then
                    return false;
                end if;
            end for;
        end for;
    end for;
    return true;
end intrinsic;

intrinsic Print(I::SubgroupLatInterval)
{}
    s := IsActuallyCyclic(I) select "C" else "N";
    printf "%o%o:%o->%o:[%o]", s, I`top`order div I`bottom`order, I`top, I`bottom, Join([Sprint(I`by_index[d][1]`subgroup_count) : d in Sort([k : k in Keys(I`by_index)])], ",");
end intrinsic;

intrinsic AllLongCyclicIntervals(Lat::SubgroupLat) -> SeqEnum
{}
    top := Lat`subs[1];
    ans := [];
    cur_tops := {top};
    seen_tops := {top`i};
    while #cur_tops gt 0 do
        next_tops := {};
        for ctop in cur_tops do
            cur_bots := {};
            for i in Keys(ctop`unders) do
                if not i in seen_tops then
                    Include(~next_tops, Lat`subs[i]);
                    Include(~seen_tops, i);
                end if;
                Include(~cur_bots, Lat`subs[i]);
            end for;
            while #cur_bots gt 0 do
                next_bots := {};
                for bot in cur_bots do
                    for i in Keys(bot`unders) do
                        cbot := Lat`subs[i];
                        if not cbot in next_bots then
                            I := Interval(ctop, cbot);
                            if IsCyclic(I) then
                                Append(~ans, I);
                                Include(~next_bots, cbot);
                            end if;
                        end if;
                    end for;
                end for;
                cur_bots := next_bots;
            end while;
        end for;
        cur_tops := next_tops;
    end while;
    return ans;
end intrinsic;

intrinsic CollectCyclicInfo(low, high) -> SeqEnum, SeqEnum, SeqEnum
{}
    cycs := {};
    ncycs := {};
    examples := [];
    for n in [low..high] do
        print "Starting", n;
        for i in [1..NumberOfSmallGroups(n)] do
            GG := MakeSmallGroup(n, i);
            Lat := SubGrpLat(GG);
            for I in AllLongCyclicIntervals(Lat) do
                d := I`top`order div I`bottom`order;
                cnts := [I`by_index[d][1]`subgroup_count : d in Sort([k : k in Keys(I`by_index)])];
                cyc := IsActuallyCyclic(I);
                cvx := IsConvex(I);
                if cyc and not cvx then
                    print "cyc", n, i, I;
                    Include(~cycs, <d, cnts>);
                    Append(~examples, I);
                elif not cyc and cvx then
                    print "ncyc", n, i, I;
                    Include(~ncycs, <d, cnts>);
                    Append(~examples, I);
                end if;
            end for;
        end for;
    end for;
    return Sort([x : x in cycs]), Sort([x : x in ncycs]), examples;
end intrinsic;

// Implementation adapted from Magma's Groups/GrpFin/subgroup_lattice.m
RF := recformat<subgroup, order, length, gens, recurse>;
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
function maximal_subgroup_classes(Ambient, H, inj : collapse:=true)
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
function SubgroupLattice(GG, aut)
    // subgroup, gens, i, full_label, short_label, unders (other subs this sub contains maximally as i->cnt), overs, subgroup_count, cc_count, normalizer, centralizer, normal_closure
    Lat := New(SubgroupLat);
    Lat`Grp := GG;
    Lat`outer_equivalence := aut;
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
    top := New(SubgroupLatElt);
    top`Lat := Lat;
    top`subgroup := sub<G|G>;
    top`order := #G;
    top`i := 1;
    top`overs := AssociativeArray();
    top`normal_closure := 1; // base case for normal_closure computation
    Append(~collapsed, top);
    Mlist := maximal_subgroup_classes(Ambient, G, inj : collapse:=true);
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
            cache := LoadSubgroupCache(lab);
            if Valid(cache) then // until the bugs in automorphism groups are worked around, we only save caches where outer_equivalence is false
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
                        HH := New(SubgroupLatElt);
                        HH`Lat := Lat;
                        // subgroup, gens, i, full_label, short_label, unders (other subs this sub contains maximally as i->cnt), overs, subgroup_count, cc_count, standard_generators, recurse, normalizer, centralizer, normal_closure
                        HH`subgroup := H;
                        HH`order := #H;
                        // Need to add overs from cache, with weights
                        HH`i := tmp_index_base - j;
                        HH`overs := AssociativeArray();
                        for pair in cache`overs do
                            HH`overs[tmp_index_base - pair[1]] := pair[2];
                        end for;
                        HH`gens := gens;
                        HH`standard_generators := cache`standard[j];
                        HH`recurse := false;
                        Append(~to_add[#G div #H], HH);
                    end for;
                    tmp_index_base -:= #cache`gens;
                end if;
            else // cache not saved
                HH := New(SubgroupLatElt);
                HH`Lat := Lat;
                HH`subgroup := M;
                HH`order := MM`order;
                HH`overs := AssociativeArray();
                HH`overs[1] := MM`length;
                HH`gens := Generators(M);
                HH`standard_generators := false;
                HH`recurse := true;
                Append(~to_add[#G div #M], HH);
            end if;
            //Append(~collapsed[H`order],
        end for;
        if #to_add[d] eq 0 then continue; end if; // no subgroups of this index
        this_index := [to_add[d]];
        if not d in singleton_indexes then
            this_index := SplitByAuts(this_index, Ambient, inj : use_order:=false);
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
                for K in maximal_subgroup_classes(Ambient, H`subgroup, inj : collapse:=false) do
                    // subgroup, gens, i, full_label, short_label, unders (other subs this sub contains maximally as i->cnt), overs, subgroup_count, cc_count, standard_generators, recurse, normalizer, centralizer, normal_closure
                    KK := New(SubgroupLatElt);
                    KK`Lat := Lat;
                    KK`subgroup := K`subgroup;
                    KK`order := K`order;
                    KK`overs := AssociativeArray();
                    KK`overs[#collapsed] := K`length;
                    KK`gens := [G!g : g in Generators(G)];
                    KK`standard_generators := false;
                    KK`recurse := true;
                    Append(~to_add[#G div K`order], KK);
                end for;
            end if;
        end for;
    end for;
    Lat`subs := collapsed;
    Lat`by_index := AssociativeArray();
    for j in [1..#collapsed] do
        HH := collapsed[j];
        index := #G div HH`order;
        if not IsDefined(Lat`by_index, index) then
            Lat`by_index[index] := [];
        end if;
        Append(~Lat`by_index[index], HH);
        HH`unders := AssociativeArray();
    end for;
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
        HH`normalizer := SubgroupLatIdentify(Lat, N);
        HH`centralizer := SubgroupLatIdentify(Lat, Centralizer(G, H));
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
        //printf "%o subgroups up to automorphism (min order %o, ok %o), so not computing up to conjugacy\n", #byA, byA[1]`order, AllSubgroupsOk(GG);
        G`outer_equivalence := true;
    else
        byC := Get(G, "SubGrpList");
        //print #byA, "subgroups up to automorphism,", #byC, "subgroups up to conjugacy";
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
                // if we use Magma's built in SubGrpLat type, we'll need to compute normal closures here
                /*seen := {};
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
                end while;*/
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
    if max_index eq 0 and not G`outer_equivalence then // Remove G`outer_equivalence once Magma bugs around automorphisms are fixed or worked around
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
