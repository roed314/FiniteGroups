// Find faithful representations as a matrix group
// ls DATA/matrep0.todo | parallel -j76 --timeout 120 magma -b label:={1} Matreps.m

AttachSpec("spec");
SetColumns(0);
desc := Read("DATA/matrep0.todo/" * label);
G := StringToGroup(desc);

CT := CharacterTable(G);
by_kernel := AssociativeArray();
min_faithful_irrdeg := #G; // larger than any possible degree of an irreducible rep
min_faithful_deg := #G;
min_faithful := [];
for chi in CT do
    K := Kernel(chi);
    d := Degree(chi);
    F := CoefficientField(chi); // a cyclotomic field
    m := CyclotomicOrder(F);
    if #K ne 1 then
        if not IsDefined(by_kernel, K) then
            by_kernel[K] := AssociativeArray();
        end if;
        if not IsDefined(by_kernel[K], d) then
            by_kernel[K][d] := AssociativeArray();
        end if;
        // We only need one chi, so it's fine if we overwrite what was there before
        by_kernel[K][d][m] := chi;
    else
        if d lt min_faithful_irrdeg then
            min_faithful_irrdeg := d;
            min_faithful := [<m, chi>];
        elif d eq min_faithful_irrdeg then
            Append(~min_faithful, <m, chi>);
        end if;
    end if;
end for;

function first_prime(m)
    // Finds the first prime that splits completely in Q(zeta_m)
    k := 1;
    while true do
        p := k*m + 1;
        if IsPrime(p) and not IsDivisibleBy(#G, p) then
            return p;
        end if;
        k +:= 1;
    end while;
end function;

if min_faithful_irrdeg ne #G then
    // there was some irreducible faithful character
    PrintFile("DATA/matrep0s/" * label, Sprintf("%o %o", min_faithful_irrdeg, Min([pair[1] : pair in min_faithful])));
    // First we check the rational characters to see if any correspond to an actual rational representation
    rational := [pair[2] : pair in min_faithful | pair[1] eq 1];
    found := false;
    Ms := [];
    p := 0;
    if #rational gt 0 then
        for chi in rational do
            M := GModule(chi);
            if Degree(BaseRing(M)) eq 1 then
                // found rational representation
                Ms := [M];
                found := true;
                break;
            end if;
            Append(~Ms, M);
        end for;
    end if;
    if #Ms eq 0 then
        // We make a small effort to minimize p, but not to the extent of calling GModule more than once
        irrational := [pair : pair in min_faithful | pair[1] ne 1];
        irrp := [first_prime(pair[1]) : pair in irrational];
        p, i := Min(irrp);
        m, chi := Explode(irrational[i]);
        M := GModule(chi);
        F := BaseRing(M);
        O := MaximalOrder(F); // May be able to use a smaller order, but I don't know how the code for finding completely split primes will behave for a non-maximal order
        if Degree(F) eq EulerPhi(m) then
            P := Factorization(p * O)[1][1];
        else
            // The Schur index wasn't 1, so we may need to change p.
            // We just iterate through primes that are 1 mod m and factor, looking for completely split cases
            k := (p - 1) div m;
            while true do
                p := k*m + 1;
                if IsPrime(p) and not IsDivisibleBy(#G, p) then
                    // F may not be Galois over Q, so we check for a prime of degree 1 rather than p being completely split
                    Ps := [tup[1] : tup in Factorization(p * O) | tup[2] eq 1 and Degree(tup[1]) eq 1];
                    if #Ps gt 0 then
                        P := Ps[1];
                        break;
                    end if;
                end if;
                k +:= 1;
            end while;
        end if;
    elif not found then
        // There were rational characters but no rational representations, so we search for the smallest degree 1 prime in any base ring
        Os := [MaximalOrder(BaseRing(M)) : M in Ms];
        p := 2;
        while true do
            if not IsDivisibleBy(#G, p) then
                for i in [1..#Ms] do
                    O := Os[i];
                    M := Ms[i];
                    Ps := [tup[1] : tup in Factorization(p * O) | tup[2] eq 1 and Degree(tup[1]) eq 1];
                    if #Ps gt 0 then
                        P := Ps[1];
                        found := true;
                        break;
                    end if;
                end for;
                if found then
                    break;
                end if;
            end if;
            p := NextPrime(p);
        end while;
    end if;
    if p eq 0 then
        M := Ms[1];
    else
        Fbar, red := ResidueClassField(P);
        M := ChangeRing(M, red);
        if not IsIrreducible(M) then
            PrintFile("DATA/matrep.errors", Sprintf("%o %o", label, p, Dimension(M)));
            exit;
        end if;
    end if;
    PrintFile("DATA/matrep0s/" * label, GroupToString(MatrixGroup(M) : use_id:=false));
else
    PrintFile("DATA/matrep0s/" * label, "0 0");
end if;

System("rm DATA/matrep0.todo/" * label);
exit;

// Now we try to find a smaller representation which is not necessarily irreducible
// It would be nice to have a way to relate the minimal linear degree for GxH to that of G and H
// but it doesn't seem easy: C2 x C3 for example.  Maybe direct product of coprime subgroups works (ok for nilpotent groups)?  Can we build from p-Sylows more generally?  Probably not when not normal....
// Look at line 1331 of Subgroups.m, modify to compute mobius_quo for NormalSubgroups


// First we get the minimal dimension using power series, by computing the Mobius function for the lattice of normal subgroups

/*
by_d := AssociativeArray();
for K -> dA in by_kernel do
    mind := Min(Keys(dA));
    if not IsDefined(by_d, mind) then
        by_d[mind] := [];
    end if;
    Append(~by_d[mind], <K, dA[mind]>);
end for;
*/

