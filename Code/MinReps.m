// ls DATA/groups | sort -g | parallel -j 128 --timeout 86400 magma Grp:={1} MinReps.m
// TODO: MAKE THIS WORK FOR outer_equivalence=True

SetColumns(0);

print Grp;
N, i := Explode([StringToInteger(c) : c in Split(Grp, ".")]);
t0 := Cputime();
Gdata := Split(Read("DATA/groups/" * Grp), "|");
Core := AssociativeArray();
ByCore := AssociativeArray();
Lattice := AssociativeArray();
MinTransitiveDegree := N; // permutation precision
Active := AssociativeArray();
Normals := [];
NormalsAbove := AssociativeArray();
Index := AssociativeArray();
mobius := AssociativeArray();
for x in Split(Read("DATA/subgroups/" * Grp)) do
    Sdata := Split(x, "|");
    short_label := Sdata[50]; // short label of this subgroup
    core := Sdata[16]; // short label for core
    if not IsDefined(Core, core) then
        Core[core] := [];
    end if;
    m := StringToInteger(Sdata[47]); // index
    Append(~Core[core], m);
    trivial_core := (StringToInteger(Split(core, ".")[1]) eq N);
    //conjugacy_class_count := StringToInteger(Sdata[13]);
    normal := (Sdata[33] eq "t");
    if trivial_core and m lt MinTransitiveDegree then
        MinTransitiveDegree := m;
        //if not IsDefined(ByCore, core) then ByCore[core] := []; end if;
        //Append(~ByCore[core], m); // FIXME: there could be multiplicities
    end if;
    contains := Sdata[15];
    contains := Split(contains[2..#contains-1], ",");
    if m eq 1 then
        NormalsAbove[short_label] := {};
    end if;
    Norms := NormalsAbove[short_label];
    if normal then
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
    // have to remove normals from Active[short_label] that contain another in the list
end for;
R<x> := PowerSeriesRing(Integers(), MinTransitiveDegree);
f := R!0;
Invs := AssociativeArray();
for label in Normals do
    mu := mobius[label];
    if mu ne 0 then
        g := R!1;
        for N in NormalsAbove[label] do
            for d in Core[N] do
                if not IsDefined(Invs, d) then
                    Invs[d] := (1 - x^d)^(-1);
                end if;
                g *:= Invs[d];
            end for;
        end for;
        f +:= mu*g;
    end if;
end for;
print f;
print Cputime() - t0;
t0 := Cputime();
print Degree(Image(MinimalDegreePermutationRepresentation(SmallGroup(N, i))));
print Cputime() - t0;
