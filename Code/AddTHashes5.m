AttachSpec("hashspec");

// ls DATA/hashclusters/active | parallel -j96 --timeout 7200 --memfree 100G --joblog DATA/hashclusters/sibs.log magma hsh:="{1}" AddTHashes5.m

SetColumns(0);
cluster_lookup := AssociativeArray();
first_lookup := AssociativeArray();
G_lookup := AssociativeArray();
nTts := [];
ns := {};
activefile := "DATA/hashclusters/active/" * hsh;
for cluster in Split(Read(activefile), "\n") do
    first := Split(cluster, " ")[1];
    cluster_lookup[first] := cluster;
    for nTt in Split(cluster, " ") do
        pair := [StringToInteger(c) : c in Split(nTt, "T")];
        first_lookup[pair] := first;
    end for;
    n, t := Explode([StringToInteger(c) : c in Split(first, "T")]);
    G_lookup[first] := TransitiveGroup(n, t);
    Append(~nTts, first);
    // The active clusters can all be handled by considering a single index: 36, 40 or 44.  Some of the 40 clusters have degree 20 siblings mixed in.
    if n eq 20 then
        for nTt in Split(cluster, " ") do
            if nTt[1..3] eq "40T" then
                n := 40;
                break;
            end if;
        end for;
    end if;
    Include(~ns, n);
end for;

assert #ns eq 1;

while #nTts gt 0 do
    t0 := Cputime();
    label := nTts[1];
    G := G_lookup[label];
    S := Subgroups(G : IndexEqual:=n);
    cnt1 := #S;
    S := [H`subgroup : H in S | #Core(G, H`subgroup) eq 1];
    cnt2 := #S;
    ts := [TransitiveGroupIdentification(Image(CosetAction(G, H))) : H in S];
    sibs := AssociativeArray();
    for t in ts do
        if not IsDefined(sibs, [n,t]) then
            first := first_lookup[[n,t]];
            Exclude(~nTts, first);
            cluster := cluster_lookup[first];
            for nTt in Split(cluster, " ") do
                sibs[[StringToInteger(c) : c in Split(nTt, "T")]] := 0;
            end for;
        end if;
        sibs[[n,t]] +:= 1;
    end for;
    // Since this process may get killed, we want to write output now
    print "Writing progress";
    PrintFile("DATA/hashclusters/sibs.times/" * hsh, Sprintf("Subs(%o) -> %o -> %o -> %o in %o", label, cnt1, cnt2, #sibs, Cputime() - t0));
    sibs := [<k, v> : k -> v in sibs];
    Sort(~sibs);
    withcount := Join([Sprintf("%oT%o:%o", x[1][1], x[1][2], x[2]) : x in sibs], " ");
    nocount := Join([Sprintf("%oT%o", x[1][1], x[1][2]) : x in sibs], " ");
    PrintFile("DATA/hashclusters/sibs_finished/" * hsh * "." * label, nocount);
    PrintFile("DATA/hashclusters/sibs_with_count/" * hsh * "." * label, withcount);
    if #nTts gt 0 then
        tmp := "DATA/hashclusters/tmp/" * hsh;
        PrintFile(tmp, Join([cluster_lookup[nTt] : nTt in nTts], "\n"));
        System("mv " * tmp * " " * activefile); // mv is atomic
    else
        System("rm " * activefile);
    end if;
end while;
exit;
