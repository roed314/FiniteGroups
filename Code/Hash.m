/*
Hashing is important for adding and identifying groups outside the range where IdentifyGroup works.
*/

REDP := 9223372036854775783; // largest prime below 2^63, since Postgres only has signed bigints

declare type LMFDBHashData;
declare attributes LMFDBHashData:
    MagmaGrp,
    hash,
    label,
    description, // string to reconstruct the group
    gens_used, // a list of integers: which generators are displayed to the user (others obtained by exponentiation)
    gens_fixed, // whether the list of generators has been fixed in the database
    hard_hash; // a list of integers designed to break up hash collisions; possibly tailored to groups in this hash cluster, only computed when needed (initially set to [])

declare type LMFDBHashCluster;
declare attributes LMFDBHashCluster:
    nTts,
    Grps,
    hashes;

intrinsic CollapseIntList(L::SeqEnum) -> RngIntElt
    {Combine a list of integers into a single integer}
    L := [CollapseIntList(x) : x in L];
    res := 997 * #L;
    for x in L do
        res := BitwiseXor(x, (1000003*res) mod REDP);
    end for;
    return res;
end intrinsic;

intrinsic CollapseIntList(L::Tup) -> RngIntElt
{Combine a tuple of integers into a single integer}
    L := [CollapseIntList(x) : x in L];
    res := 997 * #L;
    for x in L do
        res := BitwiseXor(x, (1000003*res) mod REDP);
    end for;
    return res;
end intrinsic;

intrinsic CollapseIntList(L::RngIntElt) -> RngIntElt
    {Base case}
    return L mod REDP;
end intrinsic;

intrinsic EasyHash(GG::Grp) -> RngIntElt
    {Hash that's not supposed to take a long time}
    if CanIdentifyGroup(Order(GG)) then
        return IdentifyGroup(GG)[2];
    //elif IsAbelian(GG) then
    //    return CollapseIntList(AbelianInvariants(GG));
    else
        data := AssociativeArray();
        for C in ConjugacyClasses(GG) do
            if not IsDefined(data, <C[1], C[2]>) then
                data[<C[1], C[2]>] := 0;
            end if;
            data[<C[1], C[2]>] +:= 1;
        end for;
        data := Sort([[k[1], k[2], v] : k -> v in data]);
        return CollapseIntList(data);
    end if;
end intrinsic;

intrinsic CycleHash(GG:GrpPerm) -> RngIntElt
{A variant on EasyHash that uses the cycle type rather than the order.  Note that this is NOT ISOMORPHISM INVARIANT,
 but only invariant up to conjugacy within the ambient symmetric group.  It is used in RandomizedMerge.m}
    data := AssociativeArray();
    for C in ConjugacyClasses(GG) do
        cs := CycleStructure(C[3]);
        if not IsDefined(data, <cs, C[2]>) then
            data[<cs, C[2]>] := 0;
        end if;
        data[<cs, C[2]>] +:= 1;
    end for;
    data := Sort([<k, v> : k -> v in data]);
    return CollapseIntList(data);
end intrinsic;

intrinsic EasySubHash(Amb::Grp, G:Grp) -> RngIntElt
{A modification of EasyHash to better handle abelian groups and the case where G is the full ambient group}
    if #G eq #Amb then
        return -1;
    else
        return EasyHash(G);
    end if;
end intrinsic;

intrinsic hash(G::Grp) -> RngIntElt
{
Hash value is invariant under isomorphism
Estimates on how long it will take to run for the small group orders
512 : 5 days
1152 : 2 hours
1536 : 4.3 years
1920 : 4 hours
2187 : 1 hour
6561 : 1 day
15625 : 2 minutes
16807 : 5 seconds (63 hashes of 83 groups, largest cluster is 4)
78125 : 2 hours
}
    if CanIdentifyGroup(Order(G)) then
        return IdentifyGroup(G)[2];
    elif IsAbelian(G) then
        return CollapseIntList(AbelianInvariants(G));
    else
        return CollapseIntList(Sort([[Order(G), EasyHash(G)]] cat [[H`order, EasyHash(H`subgroup)] : H in MaximalSubgroups(G)]));
    end if;
end intrinsic;

function NQ(G, H)
    // Either the normalizer or the quotient (or G if index too large)
    if IsNormal(G, H) then
        if Index(G, H) lt 1000000 then
            return G / H;
        else
            return G;
        end if;
    else
        return Normalizer(G, H);
    end if;
end function;

// The following sequence of hash functions includes more and more information in an attempt to distinguish groups.

intrinsic hash2(G::Grp) -> RngIntElt
{
Hash from Sylow subgroups, derived series and minimal normal subgroups.
}
    S := [SylowSubgroup(G, p) : p in PrimeDivisors(Order(G))];
    S cat:= DerivedSeries(G);
    S cat:= MinimalNormalSubgroups(G);
    S := [H : H in S | #H ne 1 and #H ne #G];
    E := Sort([EasySubHash(G, H) : H in S]);
    return CollapseIntList(E);
end intrinsic;

intrinsic hash3(G::Grp) -> RngIntElt
{
Hash from Sylow normalizers, quotients by derived series, maximal quotients, and character degrees.
}
    S := [SylowSubgroup(G, p) : p in PrimeDivisors(Order(G))];
    S cat:= DerivedSeries(G);
    S cat:= MinimalNormalSubgroups(G);
    S := [NQ(G, H) : H in S];
    S := [H : H in S | #H ne 1 and #H ne #G];
    E := Sort([EasySubHash(G, H) : H in S]) cat [CollapseIntList(pair) : pair in CharacterDegrees(G)];
    return CollapseIntList(E);
end intrinsic;

intrinsic hash4(G::Grp) -> RngIntElt
{
Hash using ingredients of both hash2 and hash3 but with a finer distinction (hash rather than EasySubHash).
}
    S := [SylowSubgroup(G, p) : p in PrimeDivisors(Order(G))];
    S cat:= DerivedSeries(G);
    S cat:= MinimalNormalSubgroups(G);
    S cat:= [NQ(G, H) : H in S];
    S := [H : H in S | #H ne 1 and #H ne #G];
    E := Sort([hash(H) : H in S]);
    return CollapseIntList(E);
end intrinsic;

// The goal of hash(G) is to produce a single integer, allowing for the clustering of groups into smaller collections
// Within each small cluster, we want to compute invariants iteratively, only going as far as neccessary to distinguish the groups.

intrinsic HashCluster(nTts::[MonStgElt]) -> LMFDBHashCluster
{}
    HC := New(LMFDBHashCluster);
    assert #nTts gt 0;
    Grps := [];
    for nTt in nTts do
        n, t := Explode([StringToInteger(c) : c in Split(nTt, "T")]);
        Append(~Grps, TransitiveGroup(n, t));
    end for;
    HC`nTts := nTts;
    HC`Grps := Grps;
    HC`hashes := [[] : _ in Grps];
    return HC;
end intrinsic;

intrinsic Refine(H::LMFDBHashCluster)
{Compute hashes until all groups are distinguished or the hashes run out}
    // We use ElementaryAbelianSeriesCanonical
    N := #H`Grps[1];
    n := #H`hashes[1];
    active := { 1..#H`Grps };
    EA := [];
    EAcnt := [];
    hashers := [func<i|hash2(H`Grps[i])>, func<i|hash3(H`Grps[i])>];
    collator := AssociativeArray();
    for i in active do
        EA[i] := [A : A in ElementaryAbelianSeriesCanonical(H`Grps[i]) | #A ne 1 and #A ne N];
        EAcnt[i] := CollapseIntList([#H : H in EA[i]]);
        if not IsDefined(collator, EAcnt[i]) then
            collator[EAcnt[i]] := 0;
        end if;
        collator[EAcnt[i]] +:= 1;
    end for;
    NEA := 0;
    for i in active do
        if collator[EAcnt[i]] eq 1 then
            Exclude(~active, i);
        else
            NEA := Max(NEA, #EA[i]);
        end if;
    end for;
    for j in [1..NEA] do
        function hsher(i)
            if j gt #EA[i] then return 0; end if;
            K := EA[i][j];
            G := H`Grps[i];
            g := 1;
            while #G div #K gt 1000000 do
                G := EA[i][g];
                g +:= 1;
            end while;
            if #G eq #K then return 1; end if;
            GK := G / K;
            //print i, j, #GK, hash(GK), hash4(GK);
            //return CollapseIntList([hash(GK), hash4(GK)]);
            return hash(GK);
        end function;
        Append(~hashers, hsher);
    end for;
    //Append(~hashers, func<i|hash4(H`Grps[i])>);
    while #active gt 0 and n lt #hashers do
        n +:= 1;
        collator := AssociativeArray();
        for i in active do
            Append(~H`hashes[i], hashers[n](i));
            if not IsDefined(collator, H`hashes[i]) then
                collator[H`hashes[i]] := 0;
            end if;
            collator[H`hashes[i]] +:= 1;
        end for;
        for i in active do
            //print i, H`hashes[i];
            if collator[H`hashes[i]] eq 1 then
                Exclude(~active, i);
            end if;
        end for;
    end while;
end intrinsic;

intrinsic DistinguishingHashes(nTts::[MonStgElt]) -> Assoc, LMFDBHashCluster
{}
    H := HashCluster(nTts);
    Refine(H);
    collator := AssociativeArray();
    for i in [1..#nTts] do
        if not IsDefined(collator, H`hashes[i]) then
            collator[H`hashes[i]] := [];
        end if;
        Append(~collator[H`hashes[i]], nTts[i]);
    end for;
    return collator, H;
end intrinsic;

intrinsic MakeClusters(nTts::[MonStgElt]) -> SeqEnum, LMFDBHashCluster
{}
    collator, H := DistinguishingHashes(nTts);
    clusters := [v : k -> v in collator];
    return clusters, H;
end intrinsic;

intrinsic power_hash(G::Grp) -> RngIntElt
{
Hash using the power map on conjugacy classes.  Unfortunately this is both slow and not very helpful (after several hours, only 6 cases of interest complete and in none of them was power_hash able to distinguish non-isomorphic groups).
}
    // Conjugacy classes together with the power map gives a graph, with vertices labeled
    // by order/size and edges labeled by integers.  This allows us to refine the
    // order/size pair associated to a conjugacy class into [order, size, [p1, sizeA, sizeB], [p2, sizeC, ...],...]
    // declaring that there is a conjugacy class of size sizeA and order order*p1
    // whose p1th power is this class, etc.
    pm := PowerMap(G);
    cc := ConjugacyClasses(G);
    incoming := AssociativeArray();
    for i in [2..#cc] do
        incoming[i] := AssociativeArray();
    end for;
    for i in [2..#cc] do
        order := cc[i][1];
        size := cc[i][2];
        if IsPrime(order) then continue; end if;
        for p in PrimeDivisors(order) do
            A := incoming[pm(i,p)];
            if not IsDefined(A, p) then
                A[p] := [];
            end if;
            Append(~A[p], size);
        end for;
    end for;
    // Now recursively count as in EasyHash
    counts := AssociativeArray();
    for i in [2..#cc] do
        key := <cc[i][1], cc[i][2], Sort([[p] cat Sort(sizes) : p -> sizes in incoming[i]])>;
        if not IsDefined(counts, key) then
            counts[key] := 0;
        end if;
        counts[key] +:= 1;
    end for;
    data := Sort([<k[1], k[2], k[3], v> : k -> v in counts]);
    return CollapseIntList(data);
end intrinsic;

intrinsic hash(HD::LMFDBHashData) -> RngIntElt
{}
    return hash(HD`MagmaGrp);
end intrinsic;

intrinsic hash(G::LMFDBGrp) -> RngIntElt
{}
    return hash(G`MagmaGrp);
end intrinsic;

intrinsic HashData(G::LMFDBGrp) -> LMFDBHashData
{}
    HD := New(LMFDBHashData);
    HD`MagmaGrp := G`MagmaGrp;
    if assigned G`gens_used then
        HD`gens_used := G`gens_used;
        HD`gens_fixed := true;
    else
        HD`gens_used := [];
        HD`gens_fixed := not Get(G, "solvable");
    end if;
    HD`label := G`label;
    HD`hash := Get(G, "hash");
    HD`hard_hash := [];
end intrinsic;

intrinsic HashData(n::RngIntElt, i::RngIntElt) -> LMFDBGrp
    {Make HashData from the small group database}
    G := New(LMFDBHashData);
    G`MagmaGrp := SmallGroup(n, i);
    G`gens_used := [];
    G`gens_fixed := false;
    G`label := Sprint(n) cat "." cat Sprint(i);
    G`hard_hash := [];
    return G;
end intrinsic;

// Not an attribute since it isn't saved to the database
intrinsic description(G::LMFDBGrp) -> MonStgElt
{}
    return ReplaceString(Sprintf("%m", G`MagmaGrp), ["\n", " "], ["", ""]);
end intrinsic;

intrinsic description(HD::LMFDBHashData) -> MonStgElt
{}
    return ReplaceString(Sprintf("%m", HD`MagmaGrp), ["\n", " "], ["", ""]);
end intrinsic;


// Testing whether we can find core-free subgroups using SubgroupsLift and filtering each time faster than filtering at the end

intrinsic CoreFreeSubs(G::Grp, index::RngIntElt : show:=true) -> SeqEnum
{}
    E := ElementaryAbelianSeriesCanonical(G);
    subs := Subgroups(sub<G|> : Presentation:=true);
    N := #G div index;
    for i in [1..#E-1] do
        nlow := N div Gcd(N, #E[i+1]);
        subs := SubgroupsLift(G, E[i], E[i+1], subs : OrderMultipleOf:=nlow, OrderDividing:=N);
        subs := [S : S in subs | Core(G, S`subgroup) subset E[i+1]];
    end for;
    if show and #subs gt 0 then
        Ts := [TransitiveGroupIdentification(Image(CosetAction(G, H`subgroup))) : H in subs];
        Sort(~Ts);
        ctr := [[Ts[1],1]];
        for i in [2..#Ts] do
            if Ts[i] eq Ts[i-1] then
                ctr[#ctr][2] +:= 1;
            else
                Append(~ctr, [Ts[i], 1]);
            end if;
        end for;
        print Join([p[2] gt 1 select Sprintf("%oT%o x%o", index, p[1], p[2]) else Sprintf("%oT%o", index, p[1]) : p in ctr], ", ");
    end if;
    return subs;
end intrinsic;

intrinsic SpeedTest(G::Grp, index::RngIntElt) -> SeqEnum, SeqEnum, BoolElt
{}
    t0 := Cputime();
    sub1 := CoreFreeSubs(G, index : show:=false);
    print "Iterative", Cputime() - t0;
    t0 := Cputime();
    sub2 := Subgroups(G : IndexEqual := index);
    sub2 := [H : H in sub2 | #Core(G, H`subgroup) eq 1];
    print "Post", Cputime() - t0;
    return sub1, sub2, (#sub1 eq #sub2);
end intrinsic;





intrinsic ReduceByOrbits(G::GrpPerm) -> GrpPerm
{}
    N := Degree(G);
    singletons := [X[1] : X in Orbits(G) | #X eq 1];
    if #singletons eq 0 then
        return G;
    end if;
    smalls := [x : x in singletons | x le N-#singletons];
    bigs := [x : x in [N-#singletons+1..N] | not x in singletons];
    assert #smalls eq #bigs;
    swap := Sym(N)!1;
    for i in [1..#smalls] do
        swap *:= Sym(N)!(smalls[i], bigs[i]);
    end for;
    n := N - #singletons;
    H := sub<Sym(n)|[Eltseq(g^swap)[1..n] : g in Generators(G)]>;
    return H;
end intrinsic;

SMALLHASH_ORDERS := [512, 1152, 1536, 1920, 2187, 6561, 15625, 16807, 78125, 161051];
intrinsic IdentifyGroups(Glist::SeqEnum : hashes:=0) -> SeqEnum
{Identify groups if small it will use IdentifyGroup; if medium lookup in gps_smallhash; if large currently raise an error (eventually will use hashes stored in gps_groups)}
    if hashes cmpeq 0 then
        hashes := [hash(G) : G in Glist];
    else
        assert Type(hashes) eq SeqEnum and #hashes eq #Glist and &and[Type(hsh) eq RngIntElt : hsh in hashes];
    end if;
    // First use IdentifyGroup
    ans := [];
    translate := [];
    toid := [];
    for i in [1..#Glist] do
        G := Glist[i];
        if CanIdentifyGroup(#G) then
            ans[i] := IdentifyGroup(G);
        elif #G in SMALLHASH_ORDERS then
            ordhsh := Sprintf("%o.%o", #G, hashes[i]);
            j := Index(toid, ordhsh);
            if j eq 0 then
                Append(~toid, ordhsh);
                translate[i] := #toid;
            else
                translate[i] := j;
            end if;
        else
            error "IdentifyGroups does not yet support order", #G;
        end if;
    end for;
    toid := [x : x in toid];
    if #toid gt 0 then
        fname := Sprintf("DATA/tmp%o", CollapseIntList(hashes));
        PrintFile(fname, Join(toid, "\n"));
        System(Sprintf("./identify.py --input %o --output %o.out", fname, fname));
        possibilities := [[<StringToInteger(c) : c in Split(label, ".")> : label in Split(x, "|")] : x in Split(Read(fname * ".out"), "\n") | #x gt 0];
        System(Sprintf("rm %o %o.out", fname, fname));
        assert #possibilities eq #toid;
        // This will need to be updated when we add support for large orders
        for i in [1..#Glist] do
            G := Glist[i];
            if #G in SMALLHASH_ORDERS then
                poss := possibilities[translate[i]];
                if #poss eq 1 then
                    if poss[1][2] eq 0 then
                        print G;
                        error "Could not identify group";
                    end if;
                    ans[i] := poss[1];
                else
                    vprint User1: Sprintf("%o/%o: Iterating through %o possible groups", i, #Glist, #poss);
                    if IsPrimePower(#G) then
                        solv := true;
                        if Category(G) ne GrpPC then
                            G := PCGroup(G);
                        end if;
                        G := StandardPresentation(G);
                    else
                        solv := IsSolvable(G);
                        if solv then
                            if Category(G) ne GrpPC then
                                G := PCGroup(G);
                            end if;
                        elif Category(G) ne GrpPerm then
                            f, G := MinimalDegreePermutationRepresentation(G);
                        end if;
                    end if;
                    for pair in poss do
                        H := SmallGroup(pair[1], pair[2]);
                        if IsPrimePower(#G) and IsIdenticalPresentation(G, H) or not IsPrimePower(#G) and (solv and IsIsomorphicSolubleGroup(G, H) or not solv and IsIsomorphic(G, H)) then
                            ans[i] := pair;
                            break;
                        end if;
                    end for;
                    if not IsDefined(ans, i) then
                        print "WARNING, no id found for group of order", #G, "in position", i;
                    end if;
                end if;
            end if;
        end for;
    end if;
    return ans;
end intrinsic;

intrinsic IdentifyMediumFile(infile::MonStgElt, outfile::MonStgElt)
{}
    Gps := [StringToGroup(line) : line in Split(Read(infile), "\n")];
    for gid in IdentifyGroups(Gps) do
        PrintFile(outfile, Sprintf("%o.%o", gid[1], gid[2]));
    end for;
end intrinsic;
