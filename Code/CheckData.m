// USAGE: ls /scratch/gps/collated | parallel -j128 --timeout 30 magma -b label:={1} CheckData.m
// This script loads data from the collated folders and checks various things:
// * that element_repr_type is correct (tested by computing sizes of conjugacy classes and subgroups using the different possibilities)
// * that subgroup labels are correct

AttachSpec("spec");
N, i := Explode(Split(label, "."));
N := StringToInteger(N);
runs := Split(Pipe("ls /scratch/gps/collated/" * label, ""), "\n");
files := Split(Pipe("ls", ""), "\n");
code_lookup := AssociativeArray();
for fname in files do
    if #fname gt 10 and fname[#fname-9..#fname] eq ".tmpheader" then
        base := fname[1..#fname-10];
        code, attrs := Explode(Split(Read(fname), "\n"));
        attrs := Split(attrs, "|");
        code_lookup[code] := <base, attrs>;
    end if;
end for;
data := AssociativeArray();
for run in runs do
    for line in Split(Read(Sprintf("/scratch/gps/collated/%o/%o", label, run)), "\n") do
        code := line[1];
        line := line[2..#line];
        base, attrs := Explode(code_lookup[code]);
        tmp := AssociativeArray();
        pieces := Split(line, "|");
        assert #pieces eq #attrs; // TODO: better error handling
        for i in [1..#pieces] do
            tmp[attrs[i]] := pieces[i];
        end for;
        if not HasKey(data, code) then
            data[code] := [];
        end if;
        Append(~data[code], <run, tmp>);
    end for;
end for;
assert HasKey(data, "b"); // TODO: better error handling
by_rep := AssociativeArray();
reps := {line[2]["representations"] : line in data["b"]};
assert #reps eq 1; // TODO: better eror handling
for rep in reps do
    for rtype -> rdata in LoadJsonb(rep) do
        if rtype eq "PC" then
            // polycyclic group
            if HasKey(rdata, "pres") then
                G := PCGroup(rdata["pres"]);
            else
                G := SmallGroupDecoding(rdata["code"], N);
            end if;
        else
            d := rdata["d"];
            gens := rdata["gens"];
            if rtype eq "Perm" then
                // permutation group
                G := PermutationGroup<d | [DecodePerm(c, d) : c in gens]>;
            elif rtype eq "Lie" then
                q := rdata["q"];
                cmd := rdata["family"];
                assert cmd in ["GL", "SL", "Sp", "SO", "SOPlus", "SOMinus", "SU", "GO", "GOPlus", "GOMinus", "GU", "CSp", "CSO", "CSOPlus", "CSOMinus", "CSU", "CO", "COPlus", "COMinus", "CU", "Omega", "OmegaPlus", "OmegaMinus", "Spin", "SpinPlus", "SpinMinus", "PGL", "PSL", "PSp", "PSO", "PSOPlus", "PSOMinus", "PSU", "PGO", "PGOPlus", "PGOMinus", "PGU", "POmega", "POmegaPlus", "POmegaMinus", "PGammaL", "PSigmaL", "PSigmaSp", "PGammaU", "AGL", "ASL", "ASp", "AGammaL", "ASigmaL", "ASigmaSp"];
                CMD := eval cmd;
                if cmd in ["AGL", "ASL"] then
                    G := CMD(GrpMat, d, q);
                else
                    G := CMD(d, q);
                end if;
            else
                // matrix group
                if rtype eq "GLZ" then
                    b := rdata["b"];
                    R := Integers();
                elif rtype eq "GLFq" then
                    q := rdata["q"];
                    _, b := IsPrimePower(q);
                    R := GF(q);
                else
                    b := (rtype eq "GLZq") select rdata["q"] else rdata["p"];
                    if rtype eq "GLFp" then
                        R := GF(b);
                    else
                        R := Integers(b);
                    end if;
                end if;
                L := [IntegerToSequence(mat, b) : mat in gens];
                if rtype eq "GLFq" then
                    k := Degree(R);
                    L := [Pad(mat, k*d^2) : mat in L];
                    L := [[R!mat[i..i+k-1] : i in [1..#mat by k]] : mat in L];
                elif rtype eq "GLZ" then
                    shift := (b - 1) div 2;
                    L := [[c - shift : c in Pad(mat, d^2)] : mat in L];
                else
                    L := [Pad(mat, d^2) : mat in L];
                end if;
                G := MatrixGroup<d, R | L>;
            end if;
        end if;
        assert #G eq N; // TODO: better error handling
        by_rep[rtype] := G;
    end for;
end for;
