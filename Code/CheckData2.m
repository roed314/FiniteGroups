// USAGE: ls /scratch/grp/check_input/ | parallel -j128 --timeout 30 magma -b label:={1} CheckData2.m
// This script loads data that was extracted from postgres in Python and checks various things:
// * that element_repr_type is correct (tested by computing sizes of conjugacy classes and subgroups using the different possibilities)
// * That subgroups have characteristic set correctly
// * If the order is identifiable, that IdentifyGroup returns the right thing

start_time := Cputime();
SetColumns(0);
SetVerbose("User1", 1);
AttachSpec("spec");
AddAttribute(SubgroupLatElt, "stored_label");
N, labeli := Explode(Split(label, "."));
N := StringToInteger(N);

function PrintBoth(fname, s)
    PrintFile(fname, s);
    print s;
    return true;
end function;

function noncanonical_label(lab)
    components := Split(lab, ".");
    return #components eq 4 and components[4][1] in "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
end function;

errfile := Sprintf("/scratch/grp/check_output/%o", label);
charfile := Sprintf("/scratch/grp/char_fix/%o", label);
boolfile := Sprintf("/scratch/grp/subool/%o", label);
failed := false;

// Load the postgres data
dblines := Split(Read(Sprintf("/scratch/grp/check_input/%o", label)), "\n");
db_ert := dblines[1]; // element_repr_type
db_hash := dblines[2]; // hash
if db_hash ne "\\N" then
    db_hash := StringToInteger(db_hash);
end if;
db_reps := Split(dblines[3], "|"); // inputs for StringToGroup, the first corresponding to db_ert
G_reps := [StringToGroup(rep) : rep in db_reps];
// Check IdentifyGroup and hash
for i in [1..G_reps] do
    GG := G_reps[i];
    if CanIdentifyGroup(N) then
        _, Gid := Explode(IdentifyGroup(GG));
        if StringToInteger(labeli) ne Gid then
            failed := PrintBoth(errfile, Sprintf("1|%o|%o|%o", label, Gid, db_reps[i])); // err 1: the group identification is wrong
        end if;
    elif IsInSmallGroupDatabase(N) then
        if not IsIsomorphic(GG, SmallGroup(N, labeli)) then
            failed := PrintBoth(errfile, Sprintf("2|%o|%o", label, db_reps[i])); // err 2: the group identification is wrong
        end if;
    else
        hsh := hash(GG);
        if Type(db_hash) eq RngIntElt and hsh ne db_hash then
            PrintBoth(errfile, Sprintf("%3|%o|%o|%o|%o", label, db_hash, hsh, db_reps[i])); // err 3: for unidentifiable groups, the hash value is wrong
        end if;
    end if;
end for;


GG := G_reps[1];
G := MakeBigGroup(db_reps[1], label : preload:=true);
if dblines[4] ne "\\N" then
    G`aut_gens := LoadIntegerList(dblines[4]); // aut_gens
end if;
G`outer_equivalence := LoadBool(dblines[5]); // outer_equivalence
G`subgroup_inclusions_known := LoadBool(dblines[6]); // subgroup_inclusions_known
G`subgroup_index_bound := StringToInteger(dblines[7]); // subgroup_index_bound
G`complements_known := LoadBool(dblines[8]); // complements_known
G`normal_subgroups_known := LoadBool(dblines[9]); // normal_subgroups_known
G`AllSubgroupsOk := AllSubgroupsOk(G);
// Skipping contains, contained_in

res := New(SubgroupLat);
res`outer_equivalence := G`outer_equivalence;
res`inclusions_known := G`subgroup_inclusions_known;
res`index_bound := G`subgroup_index_bound;
subgroups := [];
conj := [];
i := 1;
invalid_gen := false;
for line in dblines[10..#dblines] do
    pieces := Split(line[2..#line], "|");
    if line[1] eq "S" then
        sub_label := pieces[1];
        short_label := pieces[2];
        sub_order := StringToInteger(pieces[3]);
        normal := LoadBool(pieces[4]);
        char := LoadBool(pieces[5]);
        gens := [];
        for gen in LoadTextList(pieces[6]) do
            try
                Append(~gens, LoadElt(gen, G));
            catch e
                failed := PrintBoth(errfile, "4|%o|%o|%o|%o", label, db_reps[1], short_label, gen); // err 4: invalid subgroup generator
                invalid_gen := true;
            end try;
        end for;
        if invalid_gen then break; end if;
        H := sub<GG | gens>;
        if #H ne sub_order then
            failed := PrintBoth(errfile, "5|%o|%o|%o|%o", label, db_reps[1], short_label, pieces[6]); // err 5: incorrect subgroup order
        end if;
        latelt := SubgroupLatElement(res, H: i:=i);
        latelt`normal := normal;
        latelt`characteristic := char;
        latelt`stored_label := short_label;
        Append(~subgroups, latelt);
        i +:= 1;
    elif line[1] eq "J" then
        conj_label := pieces[1];
        size := StringToInteger(pieces[2]);
        order := StringToInteger(pieces[3]);
        try
            rep := LoadElt(pieces[4], G);
            Z := Centralizer(GG, rep);
            if #Z * size ne N then
                failed := PrintBoth(errfile, "6|%o|%o|%o|%o|%o", label, db_reps[1], conj_label, pieces[4], size); // err 6: incorrect conjugacy class size
            end if;
            if order ne Order(rep) then
                failed := PrintBoth(errfile, "7|%o|%o|%o|%o|%o", label, db_reps[1], conj_label, pieces[4], order); // err 7: incorrect conjugacy class order
            end if;
        catch e
            failed := PrintBoth(errfile, "8|%o|%o|%o|%o", label, db_reps[1], conj_label, pieces[4]); // err 8: invalid conjugacy class rep
        end try;
    end if;
end for;
if not invalid_gen then
    res`subs := subs;
    for sub in subs do
        if sub`normal and noncanonical_label(sub`stored_label) then
            actual_char := characteristic(sub);
            stored_char := sub`characteristic;
            if actual_char cmpne stored_char then
                PrintBoth(charfile, Sprintf("%o.%o|%o", label, sub`stored_label, actual_char select "t" else "f"));
            end if;
        end if;
    end for;
end if;

if not failed then
    failed := not PrintBoth(errfile, "0|%o", label);
    exit;
end if;

// element_repr_type, representations, hash, aut_gens
// For reconstructing the lattice: outer_equivalence, subgroup_inclusions_known, subgroup_index_bound, complements_known, normal_subgroups_known, contained_in, contains
// gps_subgroups: label, short_label, generators, subgroup_order, normal, characteristic
// gps_groups_cc: representative, size, order
