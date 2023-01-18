// Usage: ls DATA/hashfix.todo | parallel -j 80 magma -b label:={1} hashfix.m

SetColumns(0);
AttachSpec("hashspec");

desc := Split(Read("DATA/hashfix.todo/" * label), "\n")[1];
G := StringToGroup(desc);
t0 := Cputime();
hsh := hash(G);
Write("DATA/hashfix.out/" * label, Sprint(hsh) : Overwrite);
Write("DATA/hashfix.timings/" * label, Sprint(Cputime() - t0) : Overwrite);
exit;
