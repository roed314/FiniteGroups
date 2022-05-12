// Usage: cat tohash.txt | parallel -j 64 magma -b desc:={1} hashone.m > hashed.txt

SetColumns(0);
AttachSpec("hashspec");

G := StringToGroup(desc);
printf "%o %o.%o\n", desc, #G, hash(G);
exit;
