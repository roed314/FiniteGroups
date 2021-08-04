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

intrinsic CollapseIntList(L::RngIntElt) -> RngIntElt
    {Base case}
    return L mod REDP;
end intrinsic;

intrinsic EasyHash(GG::Grp) -> RngIntElt
    {Hash that's not supposed to take a long time}
    if CanIdentifyGroup(Order(GG)) then
        return IdentifyGroup(GG)[2];
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
    if assigned G`MagmaOptimized then
        HD`MagmaGrp := G`MagmaOptimized;
        HD`gens_used := G`gens_used;
        HD`gens_fixed := true;
    else
        HD`MagmaGrp := G`MagmaGrp;
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
    if assigned G`MagmaOptimized then
        GG := G`MagmaOptimized;
    else
        GG := G`MagmaGrp;
    end if;
    return ReplaceString(Sprintf("%m", GG), ["\n", " "], ["", ""]);
end intrinsic;

intrinsic description(HD::LMFDBHashData) -> MonStgElt
{}
    return ReplaceString(Sprintf("%m", HD`MagmaGrp), ["\n", " "], ["", ""]);
end intrinsic;
