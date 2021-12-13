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

intrinsic SmallLMFDBGroup(n::RngIntElt, i::RngIntElt) -> LMFDBGrp
    {Make an LMFDB group from the small group database}
    G := New(LMFDBGrp);
    G`Label := Sprint(n) cat "." cat Sprint(i);
    G`MagmaGrp := SmallGroup(n, i);
    return G;
end intrinsic;

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
    elif IsAbelian(GG) then
        return CollapseIntList(AbelianInvariants(GG));
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
    E := [EasySubHash(G, H) : H in S];
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
    E := [EasySubHash(G, H) : H in S] cat [CollapseIntList(pair) : pair in CharacterDegrees(G)];
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
    E := [hash(H) : H in S];
    return CollapseIntList(E);
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
