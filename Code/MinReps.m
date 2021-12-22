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
if outer_equivalence then
    G := New(LMFDBGrp);
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
        Core[core] := AssociativeArray();
    end if;
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
        H := inj(sub<G`MagmaGrp|[DecodePerm(StringToInteger(g), G`transitive_degree) : g in gens]>);
        Injed[short_label] := H;
        Append(~Core[core], short_label);
        Scount[short_label] := StringToInteger(Sdata[18]);
    else
        if not IsDefined(Core[core], m) then
            Core[core][m] := 0;
        end if;
        Core[core][m] +:= 1;
        Scount[short_label] := 1;
    end if;
end for;
if outer_equivalence then
    for label in Normals do
        indexes := [];
        N := Injed[label];
        NN := Normalizer(Ambient, N);
        for supergroup in Core[label] do
            H := Injed[supergroup];
            conj, elt := IsConjugateSubgroup(Ambient, H, N);
            assert conj;
            H := H^(c^-1);
            NH := Normalizer(Ambient, H);
            if #NH ge NN then
                cnt := #[1: g in RightTransversal(Ambient, NH) | N subset H^g];
            else
                ind := #[1: g in RightTransversal(Ambient, NN) | N^g subset H];
                assert IsDivisibleBy(ind * Scount[supergroup], Scount[label]);
                cnt := ind * Scount[supergroup] div Scount[label];
            end if;
            m := Index[supergroup];
            if not IsDefined(Core[label], m) then
                Core[label][m] := 0;
            end if;
            Core[label][m] +:= cnt;
        end for;
    end for;
end if;
R<x> := PowerSeriesRing(Integers(), MinTransitiveDegree);
f := R!0;
Invs := AssociativeArray();
for label in Normals do
    mu := mobius[label];
    if mu ne 0 then
        g := R!1;
        for N in NormalsAbove[label] do
            print "inner", label, N, Core[N];
            for d -> cnt in Core[N] do
                if not IsDefined(Invs, d) then
                    Invs[d] := (1 - x^d)^(-1);
                end if;
                g *:= Invs[d]^cnt;
            end for;
        end for;
        print label, mu, g;
        f +:= Scount[label]*mu*g;
    end if;
end for;
print f;
print Cputime() - t0;
t0 := Cputime();
print Degree(Image(MinimalDegreePermutationRepresentation(SmallGroup(N, i))));
print Cputime() - t0;
