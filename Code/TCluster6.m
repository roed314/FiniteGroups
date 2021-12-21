// cat DATA/hash/hashin.txt | parallel -j64 --timeout 1800 --colsep ' ' magma OrdHash:="{1}" gps:="{2}" TCluster5.m

AttachSpec("hashspec");
SetColumns(0);

print OrdHash, gps;
ofile_exists, ofile := OpenTest("DATA/hash/t6_split/" * OrdHash, "r");
if ofile_exists then
    print "Already complete; exiting";
    exit;
end if;
t0 := Cputime();
gps := Split(gps, "_");
cl, HC := MakeClusters(gps);
if #cl eq #gps then
    fname := Sprintf("DATA/hash/t6_split/%o", OrdHash);
else
    fname := Sprintf("DATA/hash/t6_unsplit/%o", OrdHash);
end if;
for C in cl do
    PrintFile(fname, Join(C, " "));
end for;
PrintFile("DATA/hash/t6_hashes/" * OrdHash, Join([gps[i] * " " * Join([Sprint(hsh) : hsh in HC`hashes[i]], " ") : i in [1..#gps]], "\n"));
print Cputime() - t0;
exit;
