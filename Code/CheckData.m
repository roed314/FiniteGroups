// USAGE: ls /scratch/grp/collated | parallel -j128 --timeout 30 magma -b label:={1} CheckData.m
// This script loads data from the collated folders and checks various things:
// * that element_repr_type is correct (tested by computing sizes of conjugacy classes and subgroups using the different possibilities)
// * that subgroup labels are correct

SetColumns(0);
AttachSpec("spec");
AddAttribute(SubgroupLat, "stored_label");
N, i := Explode(Split(label, "."));
N := StringToInteger(N);
runs := Split(Pipe("ls /scratch/grp/collated/" * label, ""), "\n");
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
    for line in Split(Read(Sprintf("/scratch/grp/collated/%o/%o", label, run)), "\n") do
        code := line[1];
        base, attrs := Explode(code_lookup[code]);
        tmp := AssociativeArray();
        pieces := Split(line[2..#line], "|");
        assert #pieces eq #attrs; // TODO: better error handling
        for i in [1..#pieces] do
            tmp[attrs[i]] := pieces[i];
        end for;
        if not IsDefined(data, code) then
            data[code] := [];
        end if;
        Append(~data[code], <run, tmp>);
    end for;
end for;
assert IsDefined(data, "b"); // TODO: better error handling
by_rep := AssociativeArray();
reps := {line[2]["representations"] : line in data["b"]};
assert #reps eq 1; // TODO: better eror handling
for rep in reps do
    for rtype -> rdata in LoadJsonb(rep) do
        if rtype eq "PC" then
            // polycyclic group
            if IsDefined(rdata, "pres") then
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
                // TODO: deal with covering maps
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

// Determine the correct element_repr_type
acceptable := AssociativeArray();
for run in runs do
    acceptable[run] := Keys(by_rep);
end for;
Hs := AssociativeArray();
for pair in data["S"] do
    run, rec := Explode(pair);
    for rtype in acceptable[run] do
        G := by_rep[rtype];
        try
            gens := [LoadElt(Sprint(gen), G) : gen in rec["generators"]];
            H := sub<G | gens>;
            if #H eq rec["subgroup_order"] then
                print "SOK", rec["label"], run, rtype;
                Hs[<run, rtype, rec["label"]>] := H;
            else
                print "SNO", rec["label"], run, rtype;
                Exclude(~acceptable[run], rtype);
            end if;
        catch e
            print "SER", rec["label"], run, rtype;
            Exclude(~acceptable[run], rtype);
        end try;
    end for;
end for;
Zs := AssociativeArray();
for pair in data["J"] do
    run, rec := Explode(pair);
    for rtype in acceptable[run] do
        G := by_rep[rtype];
        try
            rep := LoadElt(Sprint(rec["representative"]), G);
            Z := Centralizer(G, rep);
            if #Z * rec["size"] eq #G then
                print "JOK", rec["label"], run, rtype;
                Zs[<run, rtype, rec["label"]>] := Z;
            else
                print "JNO", rec["label"], run, rtype;
                Exclude(~acceptable[run], rtype);
            end if;
        catch e
            print "JER", rec["label"], run, rtype;
            Exclude(~acceptable[run], rtype);
        end try;
    end for;
end for;
assert &and{#rtypes eq 1 : run -> rtypes in acceptable}; // TODO: better error handling
// TODO: Compare with stored element_repr_type
Grp := AssociativeArray();
basicdata := data["b"][1][2];
for run in runs do
    G := NewLMFDBGrp(by_rep[Representative(acceptable[run])], label);
    for attr in GetBasicAttributes do
        db_attr := attr[2];
        G``db_attr := LoadAttr(db_attr, basicdata[db_attr], G);
    end for;
    oe := {rec[2]["outer_equivalence"] : rec in data["s"] | rec[1] eq run};
    assert #oe eq 1; // TODO: better error handling
    G`outer_equivalence := LoadBool(Representative(oe));
    sik := {rec[2]["subgroup_inclusions_known"] : rec in data["s"] | rec[1] eq run};
    assert #sik eq 1; // TODO: better error handling
    G`subgroup_inclusions_known := LoadBool(Representative(sik));
    sib := {rec[2]["subgroup_index_bound"] : rec in data["s"] | rec[1] eq run};
    assert #sib eq 1; // TODO: better error handling
    G`subgroup_index_bound := StringToInteger(Representative(sib));

    Grp[run] := G;
end for;

// Check subgroup labels
Lat := AssociativeArray();
for run in runs do
    rtype := Representative(acceptable[run]);
    res := New(SubgroupLat);
    G := Grp[run];
    res`Grp := G;
    res`outer_equivalence := G`outer_equivalence;
    res`inclusions_known := G`subgroup_inclusions_known;
    res`index_bound := G`subgroup_index_bound;
    stored := [rec[2] : rec in data["S"] | rec[1] eq run];
    subs := [SubgroupLatElement(res, Hs[<run, rtype, stored[i]["label"]>], i:=i) : i in [1..#stored]];
    if res`inclusions_known then
        by_label := AssociativeArray();
        for i in [1..#stored] do
            subs[i]`stored_label := stored[i]["label"];
            by_label[stored[i]["label"]] := i;
        end for;
        for i in [1..#stored] do
            // sometimes we should be storing aut_overs instead...
            subs[i]`overs := [by_label[label] : label in LoadTextList(stored[i]["contained_in"])];
        end for;
    end if;
    LabelSubgroups(res);
    for sub in subs do
        if sub`label ne sub`stored_label then
            print run, sub`label, sub`stored_label;
        end if;
    end for;
    Lat[run] := res;
end for;
