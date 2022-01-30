AttachSpec("hashspec");

// ls DATA/hashclusters/active | parallel -j128 magma hsh:="{1}" AddTHashes3.m

SetColumns(0);
nTt_lookup := AssociativeArray();
nTts := [];
for cluster in Split(Read("DATA/hashclusters/active/" * hsh), "\n") do
    first := Split(cluster, " ")[1];
    nTt_lookup[first] := cluster;
    Append(~nTts, first);
end for;
t0 := Cputime();
collator := DistinguishingHashes(nTts);
PrintFile("DATA/hash/refining.times/" * hsh, Sprint(Cputime() - t0));
for hashes -> gps in collator do
    newhsh := hsh * "." * Sprint(CollapseIntList(hashes));
    folder := (#gps eq 1) select "refined_unique/" else "active/";
    PrintFile("DATA/hashclusters/" * folder * newhsh, Join([nTt_lookup[gp] : gp in gps], "\n"));
end for;
System("mv DATA/hashclusters/active/" * hsh * " DATA/hashclusters/inactive/");
exit;
