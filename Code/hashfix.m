// Usage: ls hashfix | parallel -j 80 magma -b label:={1} hashfix.m

SetColumns(0);
AttachSpec("hashspec");

desc := Split(Read("hashfix.todo/" * label), "\n")[1];
G := StringToGroup(desc);
hsh := hash(G);
Write("hashfix.out/" * label, Sprint(hsh) : Overwrite);
exit;
