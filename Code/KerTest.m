

SetColumns(0);
AttachSpec("spec");

badies := [];

function MakeKernel(ker_spots, G);
    CCs := Get(G, "ConjugacyClasses");
    GG := G`MagmaGrp;
    return NormalClosure(GG, sub<GG|[CCs[i]`representative : i in ker_spots]>);
end function;

for N in [4..64] do
    for i in [1..NumberOfSmallGroups(N)] do
        Grp := Sprintf("%o.%o", N, i);
        G := New(LMFDBGrp);
        Gdata := Split(Read("DATA/groups/" * Grp), "|");
        outer_equivalence := (Gdata[58] eq "t");
        solvable := (Gdata[75] eq "t");
        if solvable then
            G`pc_code := StringToInteger(Gdata[61]);
            G`order := StringToInteger(Gdata[56]);
        else
            G`transitive_degree := StringToInteger(Gdata[4]);
            G`perm_gens := [DecodePerm(g, G`transitive_degree) : g in LoadIntegerList(Gdata[63])];
        end if;
        try
            SetGrp(G);
            AssignBasicAttributes(G);
        catch e
            // Bug in Magma's SmallGroupDecoding
            G := MakeSmallGroup(G`order, StringToInteger(Gdata[19]));
        end try;
        CCs := Get(G, "ConjugacyClasses");
        for line in Split(Read("DATA/characters_qq/" * Grp)) do
            Qdata := Split(line, "|");
            vals := LoadIntegerList(Qdata[10]);
            qchar := Qdata[6];
            Ker := [i : i in [1..#vals] | vals[i] eq vals[1]];
            size := &+[CCs[i]`size : i in Ker];
            K := MakeKernel(Ker, G);
            if #K ne size then
                print Grp, qchar, #K, size;
                Append(~badies, <G, Ker, K, size>);
            end if;
        end for;
    end for;
end for;
