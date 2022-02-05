AttachSpec("hashspec");

// ls DATA/hashclusters/active | parallel -j128 --timeout 3600 magma hsh:="{1}" AddTHashes4.m

SetColumns(0);
nTt_lookup := AssociativeArray();
G_lookup := AssociativeArray();
nTts := [];
activefile := "DATA/hashclusters/active/" * hsh;
for cluster in Split(Read(activefile), "\n") do
    first := Split(cluster, " ")[1];
    nTt_lookup[first] := cluster;
    n, t := Explode([StringToInteger(c) : c in Split(first, "T")]);
    G_lookup[first] := TransitiveGroup(n, t);
    Append(~nTts, first);
end for;

if #nTts gt 3 then
    // Skip bigger clusters
    print "Exiting since", #nTts, "clusters";
    exit;
end if;

while #nTts gt 0 do
    t0 := Cputime();
    label := nTts[1];
    G := G_lookup[label];
    cluster := [nTt_lookup[label]];
    nTts := nTts[2..#nTts];
    i := 1;
    while i le #nTts do
        now := nTts[i];
        H := G_lookup[now];
        print "Checking isomorphism", label, now;
        if IsIsomorphic(G, H) then
            Append(~cluster, nTt_lookup[now]);
            Remove(~nTts, i);
        else
            i +:= 1;
        end if;
    end while;
    // Since this process may get killed, we want to write output now
    print "Writing progress";
    PrintFile("DATA/hashclusters/isotest.times/" * hsh, Sprintf("%o size %o(%o), %o", label, #cluster, &+[#Split(x, " ") : x in cluster], Cputime() - t0));
    PrintFile("DATA/hashclusters/isotest_finished/" * hsh * "." * label, Join(cluster, " "));
    if #nTts gt 0 then
        tmp := "DATA/hashclusters/tmp/" * hsh;
        PrintFile(tmp, Join([nTt_lookup[nTt] : nTt in nTts], "\n"));
        System("mv " * tmp * " " * activefile); // mv is atomic
    else
        System("rm " * activefile);
    end if;
end while;
exit;
