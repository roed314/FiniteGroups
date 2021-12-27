// ls DATA/groups | sort -g | parallel -j 128 --timeout 86400 magma Grp:={1} MinReps2.m

SetColumns(0);
AttachSpec("spec");

print Grp;
N, i := Explode([StringToInteger(c) : c in Split(Grp, ".")]);
t0 := Cputime();
Gdata := Split(Read("DATA/groups/" * Grp), "|");
outer_equivalence := (Gdata[58] eq "t");
solvable := (Gdata[75] eq "t");
G := New(LMFDBGrp);
if solvable then
    G`pc_code := StringToInteger(Gdata[61]);
    G`order := StringToInteger(Gdata[56]);
    G`gens_used := LoadIntegerList(Gdata[34]);
else
    G`transitive_degree := StringToInteger(Gdata[4]);
    G`perm_gens := [DecodePerm(g, G`transitive_degree) : g in LoadIntegerList(Gdata[63])];
end if;
try
    SetGrp(G);
catch e
    // Bug in Magma's SmallGroupDecoding
    PrintFile("DATA/SmallGroupDecodingBug.txt", Grp);
    G := MakeSmallGroup(G`order, StringToInteger(Gdata[19]));
end try;

phi := MinimalDegreePermutationRepresentation(G`MagmaGrp);
if solvable then
    gens := SetToSequence(PCGenerators(G`MagmaGrp));
    gens := [gens[i] : i in G`gens_used];
else
    gens := SetToSequence(Generators(G`MagmaGrp));
end if;
d := Degree(Image(phi));
print d;

PrintFile("DATA/minreps/"*Grp, Sprintf("%o|{%o}", d, Join([Sprint(EncodePerm(phi(g))) : g in gens], ",")));
exit;
