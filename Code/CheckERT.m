// USAGE: ls DATA/ert_check | parallel -j128 magma -b label:={1} CheckERT.m
// This script determines which element_repr_type is correct for the three columns elements
// are stored (aut_gens in gps_groups, representative in gps_conj_classes, generators in gps_subgroups)
// It takes as input a file DATA/ert_check/<LABEL> where the first three lines store comma separated lists
// of encoded elements (in some encoding), and later lines give descriptions of the representations of
// the group (hopefully matching the encoding), expressed as <TYPE>|<DESC>
// It outputs a file DATA/ert_out/<LABEL> with three lines, each consisting of the
// <TYPE> strings that match (separated by commas), or ? if there is no valid match.
// If the corresponding input line was blank, the output line will be blank as well.

SetColumns(0);
AttachSpec("hashspec");

lines := PySplit(Read("DATA/ert_check/" * label), "\n");

Gs := AssociativeArray();
for line in lines[4..#lines] do
    if #line gt 0 then
        name, desc := Explode(Split(line, "|"));
        Gs[name] := StringToGroup(desc);
    end if;
end for;

System("mkdir -p DATA/ert_out");
outfile := "DATA/ert_out/" * label;
for line in lines[1..3] do
    if #line eq 0 then
        PrintFile(outfile, "");
    else
        codes := Split(line, ",");
        valid := {k : k->v in Gs};
        for code in codes do
            if #valid eq 0 then
                PrintFile(outfile, "?");
                break;
            end if;
            for typ in valid do
                try
                    g := LoadElt(code, Gs[typ]);
                catch e
                    Exclude(~valid, typ);
                end try;
            end for;
        end for;
        if #valid gt 0 then
            PrintFile(outfile, Join(Sort(SetToSequence(valid)), ","));
        end if;
    end if;
end for;
