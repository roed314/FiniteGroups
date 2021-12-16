// cat DATA/hash/to_check.txt | parallel -j16 magma Cluster:={1} TCheck.m

AttachSpec("hashspec");
SetColumns(0);
nTts := Split(Cluster, "_");
ordhash := nTts[1];
nTts := nTts[2..#nTts];
cl, HC := MakeClusters(nTts);
if #cl eq #nTts then // fully split, as expected
    PrintFile("DATA/hash/hashcert/" * ordhash, Join([Sprintf("%o %o", nTts[i], Join([Sprint(hsh) : hsh in HC`hashes[i]], ",")) : i in [1..#nTts]], "\n"));
else
    PrintFile("DATA/hash/certproblem/" * ordhash, Join([Sprintf("%o %o", nTts[i], Join([Sprint(hsh) : hsh in HC`hashes[i]], ",")) : i in [1..#nTts]], "\n"));
end if;
exit;
