
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
        res := BitwiseXor(x, (1000003*res) mod (2^64));
    end for;
    // Postgres only has signed bigints
    if res ge 2^63 then
        res -:= 2^64;
    end if;
    return res;
end intrinsic;

intrinsic CollapseIntList(L::RngIntElt) -> RngIntElt
    {Base case}
    L := L mod 2^64;
    if L ge 2^63 then
        L -:= 2^64;
    end if;
    return L;
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

intrinsic Hash(G::LMFDBGrp) -> RngIntElt
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
    GG := G`MagmaGrp;
    if CanIdentifyGroup(Order(GG)) then
        return IdentifyGroup(GG)[2];
    elif IsAbelian(GG) then
        return CollapseIntList(AbelianInvariants(GG));
    else
        return CollapseIntList(Sort([EasyHash(H`subgroup) : H in MaximalSubgroups(GG)]));
    end if;
end intrinsic;
