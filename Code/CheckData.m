// USAGE: ls /scratch/grp/collated | parallel -j128 --timeout 30 magma -b label:={1} CheckData.m
// This script loads data from the collated folders and checks various things:
// * that element_repr_type is correct (tested by computing sizes of conjugacy classes and subgroups using the different possibilities)
// * that subgroup labels are correct
// * If the order is identifiable, that IdentifyGroup returns the right thing for each rep

SetColumns(0);
SetVerbose("User1", 1);
AttachSpec("spec");
AddAttribute(SubgroupLatElt, "stored_label");
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
errfile := Sprintf("/scratch/grp/check_errors/%o", label);
subfile := Sprintf("/scratch/grp/sub_mismatch/%o", label);
data := AssociativeArray();
for run in runs do
    for line in Split(Read(Sprintf("/scratch/grp/collated/%o/%o", label, run)), "\n") do
        code := line[1];
        base, attrs := Explode(code_lookup[code]);
        tmp := AssociativeArray();
        pieces := Split(line[2..#line], "|");
        if #pieces ne #attrs then
            PrintFile(errfile, Sprintf("%o|1|%o|%o|%o", label, code, #pieces, #attrs)); // err 1
            exit;
        end if;
        for i in [1..#pieces] do
            tmp[attrs[i]] := pieces[i];
        end for;
        if not IsDefined(data, code) then
            data[code] := [];
        end if;
        Append(~data[code], <run, tmp>);
    end for;
end for;
if not IsDefined(data, "b") then
    PrintFile(errfile, Sprintf("%o|2", label)); // err 2
    exit;
end if;
if IsDefined(data, "s") then
    sruns := [pair[1] : pair in data["s"]];
else
    sruns := [];
end if;
by_rep := AssociativeArray();
reps := {line[2]["representations"] : line in data["b"]};
if #reps ne 1 then
    PrintFile(errfile, Sprintf("%o|3", label)); // err 3
    exit;
end if;
hashes := {line[2]["hash"] : line in data["b"]};
if #hashes ne 1 then
    PrintFile(errfile, Sprintf("%o|4", label)); // err 4
    exit;
end if;
Ghash := Representative(hashes);
if Ghash ne "\\N" then
    Ghash := StringToInteger(Ghash);
end if;
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
        if #G ne N then
            PrintFile(errfile, Sprintf("%o|5|%o|%o", label, rtype, #G)); // err 5
        elif CanIdentifyGroup(N) then
            _, Gid := Explode(IdentifyGroup(G));
            if StringToInteger(i) ne Gid then
                PrintFile(errfile, Sprintf("%o|6|%o|%o", label, rtype, Gid)); // err 6
            end if;
        else
            hsh := hash(G);
            if Type(Ghash) eq RngIntElt and hsh ne Ghash then
                PrintFile(errfile, Sprintf("%o|7|%o|%o|%o", label, rtype, Ghash, hsh));
            end if;
        end if;
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
            gens := [LoadElt(Sprint(gen), G) : gen in LoadTextList(rec["generators"])];
            H := sub<G | gens>;
            if #H eq StringToInteger(rec["subgroup_order"]) then
                //print "SOK", rec["label"], run, rtype;
                Hs[<run, rtype, rec["label"]>] := H;
            else
                //print "SNO", rec["label"], run, rtype;
                Exclude(~acceptable[run], rtype);
            end if;
        catch e
            //print "SER", rec["label"], run, rtype;
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
            if #Z * StringToInteger(rec["size"]) eq #G then
                //print "JOK", rec["label"], run, rtype;
                Zs[<run, rtype, rec["label"]>] := Z;
            else
                //print "JNO", rec["label"], run, rtype;
                Exclude(~acceptable[run], rtype);
            end if;
        catch e
            //print "JER", rec["label"], run, rtype;
            Exclude(~acceptable[run], rtype);
        end try;
    end for;
end for;
if &or{#rtypes ne 1 : run -> rtypes in acceptable} then
    zero := Join([run : run -> rtypes in acceptable | # rtypes eq 0], ",");
    big := Join([run : run -> rtypes in acceptable | # rtypes gt 1], ",");
    PrintFile(errfile, Sprintf("%o|8|%o|%o", label, zero, big)); // err 8
    exit;
end if;
// TODO: Compare with stored element_repr_type
Grp := AssociativeArray();
basicdata := data["b"][1][2];
for run in sruns do
    G := NewLMFDBGrp(by_rep[Representative(acceptable[run])], label);
    for attr in GetBasicAttributesGrp() do
        db_attr := attr[2];
        G``db_attr := LoadAttr(db_attr, basicdata[db_attr], G);
    end for;
    oe := {rec[2]["outer_equivalence"] : rec in data["s"] | rec[1] eq run};
    if #oe ne 1 then
        PrintFile(errfile, Sprintf("%o|9|%o", label, run)); // err 9
        exit;
    end if;
    G`outer_equivalence := LoadBool(Representative(oe));
    sik := {rec[2]["subgroup_inclusions_known"] : rec in data["s"] | rec[1] eq run};
    if #sik ne 1 then
        PrintFile(errfile, Sprintf("%o|A|%o", label, run)); // err A
        exit;
    end if;
    G`subgroup_inclusions_known := LoadBool(Representative(sik));
    sib := {rec[2]["subgroup_index_bound"] : rec in data["s"] | rec[1] eq run};
    if #sib ne 1 then
        PrintFile(errfile, Sprintf("%o|B|%o", label, run)); // err B
        exit;
    end if;
    G`subgroup_index_bound := StringToInteger(Representative(sib));
    Grp[run] := G;
    //print run, Representative(acceptable[run]);
end for;

// Check subgroup labels
Lat := AssociativeArray();
mismatched := false;
for run in sruns do
    rtype := Representative(acceptable[run]);
    res := New(SubgroupLat);
    G := Grp[run];
    res`Grp := G;
    res`outer_equivalence := G`outer_equivalence;
    res`inclusions_known := G`subgroup_inclusions_known;
    res`index_bound := G`subgroup_index_bound;
    stored := [rec[2] : rec in data["S"] | rec[1] eq run];
    // TODO: short circuit here if the short_labels are non-canonical
    subs := [SubgroupLatElement(res, Hs[<run, rtype, stored[i]["label"]>]: i:=i) : i in [1..#stored]];
    if res`inclusions_known then
        by_label := AssociativeArray();
        for i in [1..#stored] do
            subs[i]`normal := LoadBool(stored[i]["normal"]);
            subs[i]`characteristic := LoadBool(stored[i]["characteristic"]); // TODO: better error handling if characteristic wrong
            subs[i]`stored_label := stored[i]["short_label"];
            by_label[stored[i]["short_label"]] := i;
        end for;
        for i in [1..#stored] do
            // sometimes we should be storing aut_overs instead...
            subs[i]`overs := AssociativeArray();
            for label in LoadTextList(stored[i]["contained_in"]) do
                subs[i]`overs[by_label[label]] := true;
            end for;
            subs[i]`unders := AssociativeArray();
            for label in LoadTextList(stored[i]["contains"]) do
                subs[i]`unders[by_label[label]] := true;
            end for;
        end for;
    end if;
    res`subs := subs;
    SetClosures(~res);
    LabelSubgroups(res);
    for sub in subs do
        if sub`label ne sub`stored_label then
            if not mismatched then
                mismatched := true;
                PrintFile(errfile, Sprintf("%o|C"));
            end if;
            PrintFile(subfile, Sprintf("%o|%o|%o|%o", label, run, sub`short_label, sub`stored_label));
        end if;
    end for;
    Lat[run] := res;
end for;
if not mismatched then
    PrintFile(errfile, Sprintf("%o|0", label));
end if;