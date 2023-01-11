// Usage: ls DATA/direct.todo | parallel -j76 -- timeout 600 magma -b label:={1} redo_direct.m

AttachSpec("spec");
SetColumns(0);
N, i := Explode([StringToInteger(c) : c in Split(label, ".")]);
G := SmallGroup(N, i);
fac := direct_factorization(G);
if fac eq [] then
    PrintFile("DATA/direct/" * label, label * "|f|[]");
else
    PrintFile("DATA/direct/" * label, label * "|t|[" * Join([Sprintf("[\"%o\",%o]", c[1], c[2]) : c in fac], ",") * "]");
end if;
System("rm DATA/direct.todo/" * label);
exit;
