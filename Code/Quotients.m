

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

intrinsic RandomCoredSubgroup(G::Grp, N::Grp, ds::SetEnum : max_tries:=20) -> Grp
{Look for a subgroup of G with core N and index d in ds.  If failing, return N.  d should be smaller than [G:N]}
    Gord := #G;
    H := N;
    allowed_orders := &join[{m : m in Divisors(Gord div d)} : d in ds];
    tries := 1;
    while tries lt max_tries do
        g := Random(G);
        if g in H then
            continue;
        end if;
        K := sub<G|H,g>;
        if not (#K in allowed_orders) then
            tries +:= 1;
            continue;
        end if;
        if #Core(G, K) eq #N then
            if Index(G, K) in ds then
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
                    if Index(G, K) in ds then
                        return K;
                    end if;
                    H := K;
                    tries := 0;
                    break;
                end if;
            end for;
        end if;
        tries +:= 1;
    end while;
    return N; // failure
end intrinsic;

intrinsic RandomCoredSubgroups(G::Grp, N::Grp, cnt::RngIntElt : max_tries:=20) -> SeqEnum[Grp]
{}
    Nord := #N;
    I := [1..cnt];
    Hs := [N : i in I];
    Cs := [N : i in I]; // Core of the Hs
    Ccomps := [N : i in I]; // Intersection of the OTHER cores; only useful for cnt > 1
    tries := 1;
    while tries le max_tries do
        // One failure mode is that we just leave one of the Cs equal to N, so we prioritize inceasing the smallest H
        //print tries, [Index(G, H) : H in Hs];
        if cnt eq 1 then
            i := 1;
        elif Random([true, false]) then
            i := Random(I);
        else
            m := Min([#Hs[j] : j in I]);
            i := Random([j : j in I | #Hs[j] eq m]);
        end if;
        H := Hs[i];
        C := Cs[i];
        Ccomp := Ccomps[i]; // stores the intersection of Cs[j] for j != i
        g := Random(G);
        if g in H then continue; end if;
        K := sub<G|H,g>;
        Cnew := Core(G, K);
        if #K ne #G and #Cnew eq #C then
            // No change in core, so adding this element is okay
            Hs[i] := K;
            tries := 0;
        elif #K ne #G and cnt gt 1 and #(Cnew meet Ccomp) eq Nord then
            // No change in intersection of cores, so adding this element is okay
            Hs[i] := K;
            tries := 0;
            Cs[i] := Cnew;
            for j in I do
                if j ne i then
                    Ccomps[j] := &meet[Cs[k] : k in I | k ne j];
                end if;
            end for;
        else
            // try to take powers of g, since otherwise it's hard to get lower order elements
            D := Divisors(Order(g));
            for m in D[2..#D-1] do
                //print "div", m;
                h := g^m;
                if h in H then continue; end if;
                K := sub<G|H,h>;
                tt0 := Cputime();
                Cnew := Core(G, K);
                //print "time", Cputime() - tt0;
                if #K ne #G and #Cnew eq #C then
                    Hs[i] := K;
                    tries := 0;
                    break;
                elif #K ne #G and cnt gt 1 and #(Cnew meet Ccomp) eq Nord then
                    // No change in intersection of cores, so adding this element is okay
                    Hs[i] := K;
                    tries := 0;
                    Cs[i] := Cnew;
                    for j in I do
                        if j ne i then
                            Ccomps[j] := &meet[Cs[k] : k in I | k ne j];
                        end if;
                    end for;
                    break;
                end if;
            end for;
        end if;
        //assert Cs[i] eq Core(G, Hs[i]);
        //for j in I do
        //    assert Ccomps[j] eq &meet[Cs[k] : k in I | k ne j];
        //end for;
        //assert Cs[i] meet Ccomps[i] eq N;
        tries +:= 1;
    end while;
    // We now have a set of subgroups whose cores' intersection equals N.
    // We check to see if we can remove any of them
    extras := { i : i in I | #Ccomps[i] eq Nord };
    if #extras gt 1 then
        // We can omit some subset of the extras, but maybe not all of them
        if #extras le 10 then
            // The number of extras will often be small and we can brute force it
            bestXcomp := { i : i in I};
            best := &+[Index(G, Hs[i]) : i in I];
            for X in Subsets(extras) do
                Xcomp := {i : i in I | not (i in X)};
                if #Xcomp gt 0 and #&meet[Cs[i] : i in Xcomp] eq Nord then
                    cur := &+[Index(G, Hs[i]) : i in Xcomp];
                    if cur lt best then
                        best := cur;
                        bestXcomp := Xcomp;
                    end if;
                end if;
            end for;
            Hs := [Hs[i] : i in bestXcomp];
        else
            // We apply a greedy algorithm, which is not necessarily optimal but should be okay
            extras := Sort([i : i in extras], func<x,y|#Hs[x] - #Hs[y]>);
            // Now the first entry of extras corresponds to the H with largest index
            J := [i : i in I | i ne extras[1]];
            for k in [2..#extras] do
                if #J gt 1 and #&meet[Hs[j] : j in J | j ne extras[k]] eq Nord then
                    J := [j : j in J | j ne extras[k]];
                end if;
            end for;
            Hs := [Hs[j] : j in J];
        end if;
    elif cnt gt 1 and #extras eq 1 then
        Hs := [Hs[i] : i in I | not (i in extras)];
    end if;
    return Hs;
end intrinsic;

intrinsic CosetAction(G::Grp, Hs::SeqEnum[Grp]) -> Map, GrpPerm, Grp
{}
    n := 0;
    Ggens := [g : g in Generators(G)];
    Qgens := [[] : i in Ggens];
    Ks := [];
    for H in Hs do
        rho, Q, K := CosetAction(G, H);
        for i in [1..#Ggens] do
            Qgens[i] := Qgens[i] cat [n + v : v in Eltseq(rho(Ggens[i]))];
        end for;
        n +:= Degree(Q);
        Append(~Ks, K);
    end for;
    K := &meet(Ks);
    Qgens := [Sym(n)!q : q in Qgens];
    Q := sub<Sym(n) | Qgens>;
    rho := hom<G -> Q | [<Ggens[i], Qgens[i]> : i in [1..#Ggens]]>;
    return rho, Q, K;
end intrinsic;

intrinsic GoodCoredSubgroups(G::Grp, N::Grp, max_orbits::RngIntElt : low_checks:=3, max_checks:=200, max_tries:=20) -> SeqEnum[Grp]
{}
    // Note that we will keep going until degree is less than 1,000,000 even past low_checks, since otherwise CosetAction will fail (and the resulting quotient would be difficult to work with anyway).  At max_checks we give up (which will probably raise an error in MyQuotient)
    // max_tries is passed on to RandomCoredSubgroups
    cur_check := 0;
    best_degree := Index(G, N);
    best_Hs := [N];
    repeat
        cur_check +:= 1;
        Hs := RandomCoredSubgroups(G, N, max_orbits : max_tries:=max_tries);
        d := &+[Index(G, H) : H in Hs];
        vprint User1: Sprintf("Degree %o=%o (prior best %o)", d, Join(Sort([Sprint(Index(G, H)) : H in Hs]), "+"), best_degree);
        if d lt best_degree then
            cur_check := 0;
            best_degree := d;
            best_Hs := Hs;
        end if;
    until (d lt 1000000 and cur_check ge low_checks) or cur_check ge max_checks;
    return best_Hs;
end intrinsic;

intrinsic MyQuotient(G::Grp, N::Grp : max_orbits:=1, low_checks:=3, max_checks:=200, max_tries:=20) -> GrpPerm, Map
{
Find a permutation representation of G/N.
max_orbits is the maximum number of orbits in the resulting permutation group (transitive=1)
max_tries controls how hard any individual search tries to expand the cored subgroups (a successful expansion will reset to 0)
low_checks is the number of times RandomCoredSubgroups is called to check if a smaller degree is possible (low_checks=0 just returns the first output).  However, it will be called more (until max_checks is reached) if the degree is still above 1,000,000.
Note that this can be used as a less optimal but sometimes faster version of MinimalDegreePermutationRepresentation by taking N=sub<G|>
}
    best_Hs := GoodCoredSubgroups(G, N, max_orbits : low_checks:=low_checks, max_checks:=1000, max_tries:=max_tries);
    rho, Q, K := CosetAction(G, best_Hs);
    // I'm not sure where this bug came from, but I saw cases with incorrect cores so we double check.
    assert #K eq #N and #Q eq (#G div #N);
    return Q, rho;
end intrinsic;

intrinsic BestQuotient(G::Grp, N::Grp) -> Grp, Map
{Choose either quo<G|N> or MyQuotient(G, N) depending on index and type}
    if Type(G) eq GrpPC or Index(G, N) lt 1000000 then
        Q, proj := quo<G | N>;
    else
        Q, proj :=  MyQuotient(G, N : max_orbits:=4, low_checks:=3);
    end if;
    return Q, proj;
end intrinsic;


intrinsic Index(G::GrpAuto, N::GrpAuto : check:=false) -> RngIntElt
{}
    if check then
        assert Group(G) eq Group(N);
        assert &and[n in G : n in Generators(N)];
    end if;
    return #G div #N;
end intrinsic;

intrinsic Random(G::GrpAuto : word_len:=40) -> GrpAutoElt
{}
    gens := [<g, Order(g)> : g in Generators(G)];
    gens := [pair : pair in gens | pair[2] ne 1];
    r := Identity(G);
    for i in [1..word_len] do
        j := Random(1,#gens);
        k := Random(0,gens[j][2]-1);
        r *:= gens[j][1]^k;
    end for;
    return r;
end intrinsic;

intrinsic IsInnerFixed(a :: GrpAutoElt) -> BoolElt, GrpPermElt
{Fix a bug in Magma's IsInner}
    A := Parent(a);
    if not assigned A`Group then
        error "Underlying group of automorphism group is not known";
    end if;
    G := A`Group;
    C := G;
    y := Id(G);
    gens := [g : g in Generators(G)]; // change is here: for PC groups [G.i : i in [1..Ngens(G)]] doesn't generate
    for g in [gens[i] : i in [1..#gens]] do
        yes, el := IsConjugate(C, g^y, g@a);
        if not yes then
            return false, _;
        end if;
        y := y*el;
        C := Centraliser(C, g@a);
    end for;
    return true, y;
end intrinsic;

intrinsic FewGenerators(A::GrpAuto : outer:=false, Try:=1) -> SeqEnum
{}
    G := Group(A);
    m, P, Y := ClassAction(A);
    if outer then
        I := sub<P|[P![Position(Y,g^-1*y*g) : y in Y] : g in Generators(G)]>;
        D := DerivedSubgroup(P);
        DI := sub<P|D, I>;
        Q, Qproj := quo<P | DI>; // maximal abelian quotient
        if D subset I then
            // P/I is already abelian, so we can pull back generators
            return [(b @@ Qproj) @@ m : b in AbelianBasis(Q)];
        end if;
        n := #AbelianInvariants(Q);
        // IsInner is unreliable

       //JP added for gp 960.11357
       ogens:=[f : f in Generators(A)]; 
       // JP added for gp 960.11357

       //  ogens := [f : f in Generators(A) | not IsInnerFixed(f)];
        n_opt := Infinity();
        for j in [1..Try] do
            for i in [1..Min(Degree(P), 1000)] do
                s := [Random(P) : x in [1..n+1]];
                s := [x : x in s | x ne P.0];
                if sub<P|s,I> eq P then
                    if #s eq n then
                        return [b @@ m : b in s];
                    end if;
                    n_opt := #s;
                    g_opt := s;
                end if;
            end for;
        end for;
        if n_opt lt #ogens then
            return [b @@ m : b in g_opt];
        end if;
        return ogens;
    else
        return [b @@ m : b in FewGenerators(P : Try:=Try)];
    end if;
end intrinsic;
