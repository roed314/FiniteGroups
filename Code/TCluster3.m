// ls DATA/hash/tsep | parallel -j100 --timeout 7200 magma OrdHash:="{1}" TCluster2.m

SMALL_TRIES := 40;
function SmallJump(G, H, N, M)
    // G -- ambient group
    // H -- current subgroup
    // N -- the normalizer of H
    // M -- the desired order of a subgroup of G
    // output -- a corefree subgroup K, H < K < G, with the order of K dividing M
    //           if no such subgroup found, returns H
    //        -- the normalizer of K
    for ctr in [1..SMALL_TRIES] do
        g := Random(N);
        K := sub<G|H,g>;
        if GCD(#K, M) ne #H then
            toofar := #K div GCD(M, #K);
            if toofar gt 1 then
                g := g^toofar;
                K := sub<G|H,g>;
            end if;
            // Expand K repeatedly when forced:
            // if the index of K in its normalizer is prime
            N1 := Normalizer(G, K);
            C := Core(G, K);
            while IsPrime(Index(N1, K)) do
                if #K eq M and #C eq 1 then
                    return K, N1;
                end if;
                K := N1;
                N1 := Normalizer(G, K);
                C := Core(G, K);
            end while;
            if #C eq 1 then
                //print "Small jump successful, #K", #K, "#N", #N1;
                return K, N1;
            end if;
        end if;
    end for;
    //print "Small jump failed";
    return H, N;
end function;

BIG_TRIES := 400;
function BigJump(G, H, N, M)
    // G -- ambient group
    // H -- current subgroup
    // N -- the normalizer of H
    // M -- the desired order of a subgroup of G
    // output -- a corefree subgroup K, H < K < G, with the order of K dividing M
    //           if no such subgroup found, returns H
    //        -- the normalizer of K
    for ctr in [1..BIG_TRIES] do
        g := Random(G);
        K := sub<G|H,g>;
        if #K gt #H and IsDivisibleBy(M, #K) and #Core(G, K) eq 1 then
            N := Normalizer(G, K);
            //print "Big jump successful, #K", #K, "#N", #N;
            return K, N;
        end if;
    end for;
    //print "Big jump failed";
    return H, N;
end function;

function RandomCorelessSubgroup(G, m)
    assert IsDivisibleBy(#G, m);
    M := #G div m;
    while true do
        // start at the trivial group
        H := sub<G|>;
        N := G;
        while true do
            K, N := SmallJump(G, H, N, M);
            if #K eq #H then
                // small jump failed
                K, N := BigJump(G, H, N, M);
                if #K eq #H then
                    //big jump also failed, so start anew
                    //print "Restarting";
                    break;
                end if;
            end if;
            if #K eq M then
                //print "All done!";
                return K;
            end if;
            H := K;
        end while;
    end while;
end function;

SetColumns(0);

print OrdHash;
ofile_exists, ofile := OpenTest("DATA/hash/tsepout/" * OrdHash, "r");
if ofile_exists then
    print "Already complete; exiting";
    exit;
end if;

t0 := Cputime();
order, hsh := Explode(Split(OrdHash, "."));
file_exists, ifile := OpenTest("DATA/hash/tsep/" * OrdHash, "r");
lookup := AssociativeArray();
bound := [];
groups := [];
degrees := [];
i := 1;
for s in Split(Read(ifile)) do
    pieces := Split(s, " ");
    Append(~bound, StringToInteger(pieces[2]));
    tgps := [[StringToInteger(m) : m in Split(tgp, "T")] : tgp in [pieces[1]] cat pieces[3..#pieces]];
    Append(~groups, tgps);
    Append(~degrees, {tgp[1] : tgp in tgps}); // We will be joining these below, so want all multiplicity 1 but to take unions as a multiset
    for tgp in tgps do
        lookup[tgp] := i;
    end for;
    i +:= 1;
end for;
// We actually need the degrees of the OTHER groups
degrees := [&join[degrees[j] : j in [1..#degrees] | j ne i] : i in [1..#degrees]];

active := [1..#groups]; // As we find isomorphisms, we'll choose only one i from each pair of isomorphic groups
while #active gt 1 do
    i := Random(active);
    n, t := Explode(groups[i][1]);
    G := TransitiveGroup(n, t);
    m := Random(degrees[i]);
    H := RandomCorelessSubgroup(G, m);
    s := TransitiveGroupIdentification(Image(CosetAction(G, H)));
    j := lookup[[m, s]];
    if i ne j then
        i, j := Explode([Min(i,j), Max(i,j)]);
        groups[i] := Sort(groups[i] cat groups[j]);
        groups[j] := [];
        for k -> v in lookup do
            if v eq j then
                lookup[k] := i;
            end if;
        end for;
        bound[i] := Max(bound[i], bound[j]);
        Remove(~active, j);
        lines := Join([Sprintf("%oT%o %o %o", groups[k][1][1], groups[k][1][2], bound[k], Join([Sprintf("%oT%o", tgp[1], tgp[2]) : tgp in groups[k][2..#groups[k]]], " ")) : k in active], "\n");
        PrintFile("DATA/hash/tsep/" * OrdHash, lines : Overwrite:=true);
        print "Isomorphism found, ", #active, "clusters remaining";
    end if;
end while;
line := Join([Sprintf("%oT%o %o %o", groups[k][1][1], groups[k][1][2], hsh, Join([Sprintf("%oT%o", tgp[1], tgp[2]) : tgp in groups[k][2..#groups[k]]], " ")) : k in active], "\n");
PrintFile("DATA/hash/tsepout/" * OrdHash, line : Overwrite:=true);
