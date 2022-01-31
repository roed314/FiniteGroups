// ls DATA/hashclusters/active | parallel -j100 --timeout 7200 magma hsh:="{1}" TCluster3.m

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

function RandomCorelessSubgroup(G, m : max_tries:=40)
    // If m was chosen incorrectly, there may be no coreless subgroups of index m
    // Given that this is just part of a loop below where we try different G and m,
    // we just give up after a certain number of tries
    assert IsDivisibleBy(#G, m);
    M := #G div m;
    tries := 0;
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
                    tries +:= 1;
                    if tries ge max_tries then
                        //printf "Giving up after %o tries\n", tries;
                        return -1, tries;
                    end if;
                    break;
                end if;
            end if;
            if #K eq M then
                //printf "Done after %o tries\n", tries;
                return K, tries;
            end if;
            H := K;
        end while;
    end while;
end function;

SetColumns(0);

print hsh;
file_exists, ifile := OpenTest("DATA/hashclusters/active/" * hsh, "r");
if not file_exists then
    print "File for", hsh, "does not exist!";
    exit;
end if;
lookup := AssociativeArray();
groups := [];
degrees := [];
i := 1;
for s in Split(Read(ifile)) do
    labels := Split(s, " ");
    nTts := [[StringToInteger(m) : m in Split(label, "T")] : label in labels];
    Append(~groups, nTts);
    Append(~degrees, {nTt[1] : nTt in nTts});
    for nTt in nTts do
        lookup[nTt] := i;
    end for;
    i +:= 1;
end for;
// We actually need the degrees of the OTHER groups
degrees := [&join[degrees[j] : j in [1..#degrees] | j ne i] : i in [1..#degrees]];

active := [1..#groups]; // As we find isomorphisms, we'll choose only one i from each pair of isomorphic groups
t0 := Cputime();
progress_ctr := 0;
max_tries := 40;
failures := 0;
total_restarts := 0;
while true do
    progress_ctr +:= 1;
    i := Random(active);
    n, t := Explode(groups[i][1]);
    G := TransitiveGroup(n, t);
    m := Random(degrees[i]);
    H, restarts := RandomCorelessSubgroup(G, m : max_tries:=max_tries);
    total_restarts +:= restarts;
    if H cmpeq -1 then
        failures +:= 1;
        continue;
    end if;
    s := TransitiveGroupIdentification(Image(CosetAction(G, H)));
    j := lookup[[m, s]];
    if i ne j then
        i, j := Explode([Min(i,j), Max(i,j)]);
        PrintFile("DATA/hashclusters/merge.timings/" * hsh, Sprintf("%oT%o=%oT%o %o %o %o %o", groups[i][1][1], groups[i][1][2], groups[j][1][1], groups[j][1][2], progress_ctr, failures, total_restarts, Cputime() - t0));
        groups[i] := Sort(groups[i] cat groups[j]);
        groups[j] := [];
        for k -> v in lookup do
            if v eq j then
                lookup[k] := i;
            end if;
        end for;
        Exclude(~active, j);
        lines := Join([Join([Sprintf("%oT%o", tgp[1], tgp[2]) : tgp in groups[k]], " ") : k in active], "\n");
        activefile := "DATA/hashclusters/active/" * hsh;
        if #active eq 1 then
            PrintFile("DATA/hashclusters/merge_finished/" * hsh, lines);
            System("rm " * activefile);
            print "Finished!";
            break;
        else
            tmp := "DATA/hashclusters/tmp/" * hsh;
            PrintFile(tmp, lines);
            System("mv " * tmp * " " * activefile); // mv is atomic
        end if;
        printf "Isomorphism found after %o tries and %o seconds, %o clusters remaining\n", progress_ctr, Cputime() - t0, #active;
        progress_ctr := 0;
        t0 := Cputime();
        failures +:= 0;
        total_restarts := 0;
        max_tries := 40;
    elif progress_ctr mod 10 eq 0 then
        printf "Not yet successful; on loop %o\n", progress_ctr;
        max_tries +:= 1;
    end if;
end while;

exit;
