// ls DATA/groups | sort -g | parallel -j 128 --timeout 86400 magma Grp:={1} MinReps.m
// TODO: MAKE THIS WORK FOR outer_equivalence=True

SetColumns(0);
AttachSpec("spec");

print Grp;
N, i := Explode([StringToInteger(c) : c in Split(Grp, ".")]);
t0 := Cputime();
Gdata := Split(Read("DATA/groups/" * Grp), "|");
outer_equivalence := (Gdata[58] eq "t");
solvable := (Gdata[75] eq "t");
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
end if;
Core := AssociativeArray();
CoreLabels := AssociativeArray();
MinTransitiveDegree := N; // permutation precision
Normals := [];
NormalsAbove := AssociativeArray();
Injed := AssociativeArray();
Index := AssociativeArray();
Scount := AssociativeArray();
mobius := AssociativeArray();
for x in Split(Read("DATA/subgroups/" * Grp)) do
    Sdata := Split(x, "|");
    short_label := Sdata[50]; // short label of this subgroup
    core := Sdata[16]; // short label for core
    if not IsDefined(Core, core) then
        CoreLabels[core] := [];
    end if;
    Append(~CoreLabels[core], short_label);
    m := StringToInteger(Sdata[47]); // index
    Index[short_label] := m;
    trivial_core := (StringToInteger(Split(core, ".")[1]) eq N);
    //conjugacy_class_count := StringToInteger(Sdata[13]);
    normal := (Sdata[33] eq "t");
    if trivial_core and m lt MinTransitiveDegree then
        MinTransitiveDegree := m;
    end if;
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
        H := inj(sub<G`MagmaGrp|[LoadElt(g, G) : g in gens]>);
        Injed[short_label] := H;
        Scount[short_label] := StringToInteger(Sdata[18]);
    else
        /*if not IsDefined(Core[core], m) then
            Core[core][m] := 0;
        end if;
        Core[core][m] +:= 1;*/
        Scount[short_label] := 1;
    end if;
end for;
function NumberInclusions(supergroup, subgroup)
    K := Injed[subgroup];
    H := Injed[supergroup];
    NK := Normalizer(Ambient, K);
    NH := Normalizer(Ambient, H);
    conj, elt := IsConjugateSubgroup(Ambient, H, K);
    assert conj;
    H := H^(elt^-1);
    if #NH ge #NK then
        cnt := #[1: g in RightTransversal(Ambient, NH) | K subset H^g];
        //print "A", cnt;
    else
        ind := #[1: g in RightTransversal(Ambient, NK) | K^g subset H];
        assert IsDivisibleBy(ind * Scount[supergroup], Scount[subgroup]);
        cnt := ind * Scount[supergroup] div Scount[subgroup];
        //print "B", cnt, ind, Scount[supergroup], Scount[subgroup];
    end if;
    return cnt;
end function;
/*if outer_equivalence then
    for label in Normals do
        indexes := [];
        K := Injed[label];
        NK := Normalizer(Ambient, K);
        for supergroup in CoreLabels[label] do
            H := Injed[supergroup];
            conj, elt := IsConjugateSubgroup(Ambient, H, K);
            assert conj;
            H := H^(elt^-1);
            NH := Normalizer(Ambient, H);
            print "Normalizers", #H, #NH, #K, #NK;
            if #NH ge #NK then
                cnt := #[1: g in RightTransversal(Ambient, NH) | K subset H^g];
                print "A", cnt;
            else
                ind := #[1: g in RightTransversal(Ambient, NK) | K^g subset H];
                assert IsDivisibleBy(ind * Scount[supergroup], Scount[label]);
                cnt := ind * Scount[supergroup] div Scount[label];
                print "B", cnt, ind, Scount[supergroup], Scount[label];
            end if;
            m := Index[supergroup];
            if not IsDefined(Core[label], m) then
                Core[label][m] := 0;
            end if;
            Core[label][m] +:= cnt;
        end for;
    end for;
end if;*/
R<x> := PowerSeriesRing(Integers(), MinTransitiveDegree);
f := R!0;
Invs := AssociativeArray();
//function autlab(x)
//    return Join(Split(x, ".")[1..2], ".");
//end function;
for label in Normals do
    mu := mobius[label];
    if mu ne 0 then
        g := R!1;
        for H in NormalsAbove[label] do
            for supergroup in CoreLabels[H] do
                if outer_equivalence then
                    cnt := NumberInclusions(supergroup, label);
                else
                    cnt := 1;
                end if;
                d := Index[supergroup];
                if not IsDefined(Invs, d) then
                    Invs[d] := (1 - x^d)^(-1);
                end if;
                g *:= Invs[d]^cnt;
                if d eq 2 and Split(label, ".")[2] eq "a1" and Split(label, ".")[1] ne "64" then
                    print label, supergroup, Scount[label], mu, cnt;
                end if;
            end for;
            //print "inner", label, H, CoreLabels[H];
        end for;
        //print label, mu, Scount[label], g;
        //print label, Scount[label]*mu*g + O(x^3);
        f +:= Scount[label]*mu*g;
    end if;
end for;
print Valuation(f), Cputime() - t0;
t0 := Cputime();
print Degree(Image(MinimalDegreePermutationRepresentation(SmallGroup(N, i)))), Cputime() - t0;


