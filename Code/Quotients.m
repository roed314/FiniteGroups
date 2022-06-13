

intrinsic RandomCoredSubgroup(G::Grp, H::Grp, N::Grp, B::RngIntElt : max_tries:=20) -> Grp
    {H should have core N, G != N; may fail, in which case H is returned}
    H0 := H;
    tries := 1;
    while tries le max_tries do
        g := Random(G);
        if g in H then
            continue;
        end if;
        K := sub<G|H,g>;
        if #Core(G, K) eq #N then
            if Index(G, K) le B then
                return K; // success
            end if;
            H := K;
            tries := 0;
        else
            // try to take powers of g, since otherwise it's hard to get lower order elements
            D := Divisors(Order(g));
            for m in D[2..#D-1] do
                h := g^m;
                if h in H then
                    continue;
                end if;
                K := sub<G|H,h>;
                if #Core(G, K) eq #N then
                    if Index(G, K) le B then
                        return K; // success
                    end if;
                    H := K;
                    tries := 0;
                    break;
                end if;
            end for;
        end if;
        tries +:= 1;
    end while;
    return H0; // failure
end intrinsic;


intrinsic MyQuotient(G::Grp, N::Grp : max_orbits:=0, max_tries:=20) -> GrpPerm, Map
{max_orbits is the maximum number of orbits in the resulting permutation group (transitive=1), with 0 as no limit}
    ind := Index(G, N);
    if ind le 10000 then
        GN, pi := quo<G| N>;
        return GN, pi;
    end if;
    H0 := N;
    B := 1000;
    while #H0 eq #N and B lt ind do
        // Back off until we find a good initial option
        B *:= 10;
        H0 := RandomCoredSubgroup(G, N, N, B : max_tries:=max_tries);
    end while;
    if B lt ind then
        // We found something better than the regular representation, so we try to improve it
        ctr := 0;
        repeat
            B := Index(G, H0) + 1;
            H := RandomCoredSubgroup(G, N, N, B : max_tries:=max_tries);
            if #H le #H0 then
                ctr +:= 1;
            else
                ctr := 0;
                H0 := H;
            end if;
        until ctr ge 3;
    end if;
    rho, GN := CosetAction(G, H0);
    return GN, rho;
end intrinsic;
