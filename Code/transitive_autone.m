// Usage: cat nTt.txt | parallel -j 64 --timeout 1200 magma -b desc:={1} transitive_autone.m > aut_finished.txt
// Uses the normalizer in Sym(n) to attempt to find the automorphism group of a permutation group.  Prints nothing if the result does not give the full automorphism group, or if quotienting by the center is not possible (quotient order too large).

SetColumns(0);
AttachSpec("hashspec");

if desc[#desc-1..#desc] eq "-A" then
    desc := desc[1..#desc-2];
end if;
H := StringToGroup(desc);
A := AutomorphismGroup(H);
P, autdesc := AutPermRep(A);
printf "%o-A %o %o\n", desc, autdesc, GroupToString(P);
exit;
