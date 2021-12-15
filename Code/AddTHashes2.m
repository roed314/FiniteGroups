AttachSpec("hashspec");

// cat DATA/hash/needhash.txt | parallel -j64 magma nTt:={1} AddTHashes2.m

SetColumns(0);
n, t := Explode([StringToInteger(c) : c in Split(nTt, "T")]);
G := TransitiveGroup(n, t);
PrintFile("DATA/hash/trun.extra/" * nTt, Sprintf("%o.%o", Order(G), hash(G)));
