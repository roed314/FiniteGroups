// Usage: cat important.txt | parallel -j 64 --timeout 1200 magma -b desc:={1} autone.m > aut_finished.txt

SetColumns(0);
AttachSpec("hashspec");

// We know the answer for Alt(n) and Sym(n), so we do them separately since they get huge
if "T" in desc then
    n, t := Explode([StringToInteger(c) : c in Split(desc, "T")]);
    maxt := NumberOfTransitiveGroups(n);
    if n ne 6 and t in [maxt-1, maxt] then // Sym(n) or Alt(n)
        printf "%o %o \\N %oT%o\n", desc, Factorial(n), n, maxt;
        exit;
    end if;
end if;
G := StringToGroup(desc);
//A := AutomorphismGroup(G);
P := PermutationGroup(G);
printf "%o %o %o %o\n", desc, #G, GroupToString(G), GroupToString(P);
exit;
