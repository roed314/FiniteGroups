// cat DATA/hash/tseptest.txt | parallel -j180 --timeout 7200 --colsep ' ' magma OrdHash:="{1}" method:="{2}" TCluster4.m

AttachSpec("hashspec");
SetColumns(0);

print OrdHash;

order, hsh := Explode(Split(OrdHash, "."));
file_exists, ifile := OpenTest("DATA/hash/tsepout/" * OrdHash, "r"); // NOTE tsepout!
groups := [];
for s in Split(Read(ifile)) do
    n, t := Explode([StringToInteger(c) : c in Split(Split(s, " ")[1], "T")]);
    Append(~groups, TransitiveGroup(n, t));
end for;
hshs := {hash2(G) : G in groups};
if #hshs gt 1 then
    fname := Sprintf("DATA/hash/hash2_succ/%o", OrdHash);
else
    fname := Sprintf("DATA/hash/hash2_fail/%o", OrdHash);
end if;
PrintFile(fname, Sprintf("%o\n", #hshs));
exit;
