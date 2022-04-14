// Usage: cat nTt.txt | parallel -j 64 --timeout 1200 magma -b desc:={1} transitive_autone.m > aut_finished.txt
// Uses the normalizer in Sym(n) to attempt to find the automorphism group of a permutation group.  Prints nothing if the result does not give the full automorphism group, or if quotienting by the center is not possible (quotient order too large).

SetColumns(0);
AttachSpec("hashspec");

if desc[#desc-1..#desc] eq "-A" then
    desc := desc[1..#desc-2];
end if;
H := StringToGroup(desc);
A := AutomorphismGroup(H);
n := Degree(H);
Sn := Sym(n);
N := Normalizer(Sn, H);
T := Centralizer(Sn, H);
if #N eq #T * #A then
    // got the full automorphism group as N/T
    if #T eq 1 then
        printf "%o-A %o\n", desc, GroupToString(N);
    elif #A lt 1000000 then
        Q := quo<N | T>;
        printf "%o-A %o\n", desc, GroupToString(Q);
    elif IsSolvable(N) then
        N, phi := PCGroup(N);
        T := phi(T);
        Q := quo<N | T>;
        printf "%o-A %o\n", desc, GroupToString(Q);
    end if;
end if;
exit;
