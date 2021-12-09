// cat DATA/hash/tseptest.txt | parallel -j180 --timeout 3600 magma OrdHash:="{1}" Hash3Test.m

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
hshs := {hash3(G) : G in groups};
if #hshs gt 1 then
    fname := Sprintf("DATA/hash/hash3_succ/%o", OrdHash);
else
    fname := Sprintf("DATA/hash/hash3_fail/%o", OrdHash);
end if;
PrintFile(fname, Sprintf("%o\n", #hshs));
exit;
