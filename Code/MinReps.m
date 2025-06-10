// ls DATA/groups | sort -g | parallel -j 128 --timeout 86400 magma Grp:={1} MinReps.m

SetColumns(0);
AttachSpec("spec");

ZZ := Integers();

print Grp;
N, i := Explode([StringToInteger(c) : c in Split(Grp, ".")]);
phiN := EulerPhi(N);
F := Factorization(N);
p := 0;
q := 0;
N_is_p := false;
N_is_pq := false;
if #F eq 1 then
    N_is_p := true;
elif #F eq 2 and F[1][2] eq 1 and F[2][2] eq 1 then
    N_is_pq := true;
    p := F[2][1];
    q := F[1][1];
end if;
t0 := Cputime();
Gdata := Split(Read("DATA/groups/" * Grp), "|");
outer_equivalence := (Gdata[58] eq "t");
solvable := (Gdata[75] eq "t");
cyclic := (Gdata[20] eq "t");
G := New(LMFDBGrp);
inj := 0; // Magma can't deal with inj not being defined in the non-outer-equivalence case
if outer_equivalence then
    if solvable then
        G`pc_code := StringToInteger(Gdata[61]);
        G`order := StringToInteger(Gdata[56]);
    else
        G`transitive_degree := StringToInteger(Gdata[4]);
        G`perm_gens := [DecodePerm(g, G`transitive_degree) : g in LoadIntegerList(Gdata[63])];
    end if;
    try
        SetGrp(G);
    catch e
        // Bug in Magma's SmallGroupDecoding
        G := MakeSmallGroup(G`order, StringToInteger(Gdata[19]));
    end try;
    Ambient := Get(G, "Holomorph");
    inj := Get(G, "HolInj");
    G`SubByGass := AssociativeArray();
end if;
CoreLabels := AssociativeArray();
prP := N+1; // permutation precision
Normals := [];
NormalsAbove := AssociativeArray();
Injed := AssociativeArray();
Index := AssociativeArray();
Scount := AssociativeArray();
mobius := AssociativeArray();
SubBySize := AssociativeArray();
compute_permdeg := true;
for line in Split(Read("DATA/subgroups/" * Grp)) do
    Sdata := Split(line, "|");
    short_label := Sdata[50]; // short label of this subgroup
    m := StringToInteger(Sdata[47]); // index
    Index[short_label] := m;
    core := Sdata[16]; // short label for core
    if core eq "\\N" then
        compute_permdeg := false;
    else
        if not IsDefined(CoreLabels, core) then
            CoreLabels[core] := [];
        end if;
        Append(~CoreLabels[core], short_label);
        trivial_core := (StringToInteger(Split(core, ".")[1]) eq N);
        //conjugacy_class_count := StringToInteger(Sdata[13]);
        if trivial_core and m lt prP then
            prP := m+1;
        end if;
    end if;
    normal := (Sdata[33] eq "t");
    contains := Sdata[15];
    contains := Split(contains[2..#contains-1], ",");
    if m eq 1 then
        NormalsAbove[short_label] := {};
    end if;
    Norms := NormalsAbove[short_label];
    if normal then
        Include(~NormalsAbove[short_label], short_label);
        Append(~Normals, short_label);
        mobius[short_label] := StringToInteger(Sdata[30]);
        Norms join:= {short_label};
    end if;
    for sub in contains do
        if not IsDefined(NormalsAbove, sub) then
            NormalsAbove[sub] := {};
        end if;
        NormalsAbove[sub] join:= Norms;
    end for;
    if outer_equivalence then
        gens := Sdata[23];
        gens := Split(gens[2..#gens-1], ",");
        H := sub<G`MagmaGrp|[LoadElt(g, G) : g in gens]>;
        Injed[short_label] := inj(H);
        Scount[short_label] := StringToInteger(Sdata[18]);
        size := N div m;
        if not IsDefined(SubBySize, size) then SubBySize[size] := []; end if;
        Append(~SubBySize[size], <short_label, H>);
    else
        Scount[short_label] := 1;
    end if;
end for;

Cdegs := AssociativeArray();
Rdegs := AssociativeArray();
Qdegs := AssociativeArray();
Kernel := AssociativeArray();
KerId := AssociativeArray();
function KerClass(ker_spots)
    collapse := Get(G, "CCAutCollapse");
    CCs := Get(G, "ConjugacyClasses");
    T := AssociativeArray();
    for i in ker_spots do
        k := collapse(i);
        if not IsDefined(T, k) then T[k] := 0; end if;
        T[k] +:= CCs[i]`size;
    end for;
    return Sort([[k, v] : k -> v in T]);
end function;
function MakeKernel(ker_spots, size);
    CCs := Get(G, "ConjugacyClasses");
    GG := G`MagmaGrp;
    for i in [#ker_spots..1 by -1] do
        K := NormalClosure(GG, sub<GG|[CCs[ker_spots[j]]`representative : j in [i..#ker_spots]]>);
        if #K eq size then
            return K;
        end if;
    end for;
end function;
function IdentifyKernel(ker_spots, G)
    CCs := Get(G, "ConjugacyClasses");
    acm := AutClassMap(G);
    size := &+[CCs[i]`size : i in ker_spots];
    poss := SubBySize[size];
    if #poss eq 1 then
        return poss[1][1];
    end if;
    if not IsDefined(G`SubByGass, size) then
        G`SubByGass[size] := AssociativeArray();
        for pair in poss do
            label, H := Explode(pair);
            gvec := SubgroupClass(H, acm);
            if not IsDefined(G`SubByGass[size], gvec) then G`SubByGass[size][gvec] := []; end if;
            Append(~G`SubByGass[size][gvec], pair);
        end for;
    end if;
    K := MakeKernel(ker_spots, size);
    gvec := SubgroupClass(K, acm);
    print "IdKer", size, gvec;
    poss := G`SubByGass[size][gvec];
    if #poss eq 1 then
        return poss[1][1];
    end if;
    for pair in poss do
        label, H := Explode(pair);
        if IsConjugate(Ambient, inj(H), inj(K)) then
            return label;
        end if;
    end for;
end function;

if cyclic and (N_is_p or N_is_pq) then
    prC := 2;
    prR := (N eq 2) select 2 else 3;
    prQ := phiN + 1;
elif N_is_pq then
    prC := q + 1;
    prR := 2*q + 1;
    prQ := p;
elif outer_equivalence then
    // Load the values here, since it's easier to compute the kernel from the rational character
    for line in Split(Read("DATA/characters_qq/" * Grp)) do
        Qdata := Split(line, "|");
        vals := LoadIntegerList(Qdata[10]);
        qchar := Qdata[6];
        Ker := [i : i in [1..#vals] | vals[i] eq vals[1]];
        if not IsDefined(KerId, Ker) then KerId[Ker] := IdentifyKernel(Ker, G); end if;
        Kernel[qchar] := KerId[Ker];
    end for;
else
    prC := N+1;
    prR := N+1;
    prQ := N+1;
    for line in Split(Read("DATA/characters_cc/" * Grp)) do
        Cdata := Split(line, "|");
        //qchar := Cdata[13]; // would be nice, but currently NULL
        label := Cdata[11];
        labre := "^([0-9]+.[0-9]+.[0-9]+[a-z]+)[0-9]*$";
        ok, ignored, qchar := Regexp(labre, label);
        qchar := qchar[1];
        if outer_equivalence then
            ker := Kernel[qchar];
        else
            ker := Cdata[10];
            Kernel[qchar] := ker;
        end if;
        faithful := (StringToInteger(Split(ker, ".")[1]) eq N);
        ind := Cdata[9];

        d := StringToInteger(Cdata[4]);
        if not IsDefined(Cdegs, ker) then Cdegs[ker] := AssociativeArray(); end if;
        if not IsDefined(Cdegs[ker], d) then Cdegs[ker][d] := 0; end if;
        Cdegs[ker][d] +:= 1;
        if faithful and d lt prC then prC := d+1; end if;

        if ind ne "1" then d *:= 2; end if;
        if not IsDefined(Rdegs, ker) then Rdegs[ker] := AssociativeArray(); end if;
        if not IsDefined(Rdegs[ker], d) then Rdegs[ker][d] := 0; end if;
        if ind eq "0" then
            Rdegs[ker][d] +:= 1/2; // count character and its conjugate once
        else
            Rdegs[ker][d] +:= 1;
        end if;
        if faithful and d lt prR then prR := d+1; end if;
    end for;

    for line in Split(Read("DATA/characters_qq/" * Grp)) do
        Qdata := Split(line, "|");
        qchar := Qdata[6];
        ker := Kernel[qchar];
        faithful := (StringToInteger(Split(ker, ".")[1]) eq N);
        qdim := StringToInteger(Qdata[9]);
        sch_ind := StringToInteger(Qdata[11]);
        d := qdim * sch_ind;
        if not IsDefined(Qdegs, ker) then Qdegs[ker] := AssociativeArray(); end if;
        if not IsDefined(Qdegs[ker], d) then Qdegs[ker][d] := 0; end if;
        Qdegs[ker][d] +:= 1;
        //print "Qdata", qchar, ker, qdim, sch_ind, faithful;
        if faithful and d lt prQ then prQ := d+1; end if;
    end for;
end if;

function NumberInclusions(supergroup, subgroup)
    K := Injed[subgroup];
    H := Injed[supergroup];
    conj, elt := IsConjugateSubgroup(Ambient, H, K);
    assert conj;
    H := H^(elt^-1);
    NK := Normalizer(Ambient, K);
    NH := Normalizer(Ambient, H);
    if #NH ge #NK then
        cnt := #[1: g in RightTransversal(Ambient, NH) | K subset H^g];
        //print "A", cnt;
    else
        ind := #[1: g in RightTransversal(Ambient, NK) | K^g subset H];
        assert IsDivisibleBy(ind * Scount[supergroup], Scount[subgroup]);
        cnt := (ind * Scount[supergroup]) div Scount[subgroup];
        //print "B", cnt, ind, Scount[supergroup], Scount[subgroup];
    end if;
    return cnt;
end function;
ZZx<x> := PowerSeriesRing(Integers(), Max([prP, prC, prR, prQ]));

// We have to do some of these by hand since we didn't compute all of the characters
if cyclic and (N_is_p or N_is_pq) then
    if N_is_p then // cyclic, prime
        fP := x^N + O(x^(N+1)); // permutation representation is regular
    else
        fP := x^(p + q) + O(x^(p+q+1)); // direct product of two cyclic reps
    end if;
    fC := phiN * x + O(x^2); // phi(N) 1-dimensional faithful reps
    if N eq 2 then
        fR := x + O(x^2); // sign rep faithful
    else
        fR := (phiN div 2) * x^2 + O(x^3);
    end if;
    fQ := x^phiN + O(x^prQ); // sum of all of the nontrivial characters
elif N_is_pq then
    fP := x^p + O(x^(p+1)); // semidirect product of C_p and C_q, and the C_q has trivial core.
    fC := ((p-1) div q) * x^q + O(x^(q+1));
    fR := ((p-1) div (2*q)) * x^(2*q) + O(x^(2*q+1));
    fQ := x^(p-1) + O(x^p);
else
    fP := ZZx!0;
    fC := ZZx!0;
    fR := ZZx!0;
    fQ := ZZx!0;
    Invs := AssociativeArray();
    for label in Normals do
        mu := mobius[label];
        if mu ne 0 then
            gP := ZZx!1;
            gC := ZZx!1;
            gR := ZZx!1;
            gQ := ZZx!1;
            for H in NormalsAbove[label] do
                for supergroup in CoreLabels[H] do
                    d := Index[supergroup];
                    if d ge prP then continue; end if;
                    if outer_equivalence then
                        cnt := NumberInclusions(supergroup, label);
                    else
                        cnt := 1;
                    end if;
                    if not IsDefined(Invs, d) then Invs[d] := (1 - x^d)^(-1); end if;
                    gP *:= (Invs[d] + O(x^prP))^cnt;
                end for;
                if IsDefined(Cdegs, H) then
                    for d -> cnt in Cdegs[H] do
                        if not IsDefined(Invs, d) then Invs[d] := (1 - x^d)^(-1); end if;
                        gC *:= (Invs[d] + O(x^prC))^cnt;
                    end for;
                end if;
                if IsDefined(Rdegs, H) then
                    for d -> cnt in Rdegs[H] do
                        if not IsDefined(Invs, d) then Invs[d] := (1 - x^d)^(-1); end if;
                        gR *:= (Invs[d] + O(x^prR))^(ZZ!cnt);
                    end for;
                end if;
                if IsDefined(Qdegs, H) then
                    for d -> cnt in Qdegs[H] do
                        if not IsDefined(Invs, d) then Invs[d] := (1 - x^d)^(-1); end if;
                        gQ *:= (Invs[d] + O(x^prQ))^cnt;
                    end for;
                end if;
                //print "inner", label, H, CoreLabels[H];
            end for;
            //print label, mu, Scount[label], gP;
            fP +:= Scount[label]*mu*gP;
            fC +:= Scount[label]*mu*gC;
            fR +:= Scount[label]*mu*gR;
            fQ +:= Scount[label]*mu*gQ;
        end if;
    end for;
end if;
fP := fP + O(x^(Valuation(fP)+1));
fC := fC + O(x^(Valuation(fC)+1));
fR := fR + O(x^(Valuation(fR)+1));
fQ := fQ + O(x^(Valuation(fQ)+1));
print "Permutation", fP;
print "Cdim", fC;
print "Rdim", fR;
print "Qdim", fQ;
