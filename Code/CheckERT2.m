// USAGE: parallel -a DATA/ert.todo magma -b label:={1} CheckERT2.m
// This script checks that the output of ChangeERT.m can be correctly loaded

SetColumns(0);
AttachSpec("spec");

output := Split(Read("DATA/ert_change_out/" * label), "\n");
input := Split(Read("DATA/ert_change_in/" * label), "\n");

desc := input[2];

G := MakeBigGroup(desc, label);
for line in output do
    try
        if line[1] eq "a" then
            elts := [[LoadElt(x, G) : x in Split(y, ",")] : y in Split(line[4..#line-2], "},{")];
        elif line[1] eq "S" then
            data := Split(line, "|")[2];
            elts := [LoadElt(x, G) : x in Split(data[2..#data-1], ",")];
        elif line[1] eq "j" then
            elt := LoadElt(Split(line, "|")[2], G);
        else
            error "Unexpected start character";
        end if;
    catch e
        PrintFile("DATA/ert_ugh/" * label, line);
        break;
    end try;
end for;
