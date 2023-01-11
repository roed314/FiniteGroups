// Compute a specified set of columns, based on which one-letter codes are included (these codes are also used as line headers in the ouptut)

AttachSpec("spec");
SetColumns(0);

if not assigned label then
    print "This script requires the label of the group as input, something like magma label:=1024.a ComputeCodes.m";
    quit;
end if;
if not assigned codes then
    // default order for computing invariants
    codes := "blajJzcCrqQsSLhtguomw";
end if;

infile := "DATA/descriptions/" * label;
outfile := "DATA/computes/" * label;
desc := Read(infile);
SetVerbose("User1", 1); // for testing
SetDebugOnError(true); // for testing
G := MakeBigGroup(desc, label);
Preload(G);
files := Split(Pipe("ls", ""), "\n");
code_lookup := AssociativeArray();
for fname in files do
    if #fname gt 10 and fname[#fname-9..#fname] eq ".tmpheader" then
        base := fname[1..#fname-10];
        code := Split(Read(fname), "\n")[1];
        code_lookup[code] := base;
    end if;
end for;
// The default is that a tmpheader gives columns of gps_groups (attributes of LMFDBGrp); we record exceptions here
// Note that E and T are reserved for errors and timing information respectively
aggregate_attr := AssociativeArray();
aggregate_attr["J"] := "ConjugacyClasses";
aggregate_attr["C"] := "CCCharacters";
aggregate_attr["Q"] := "QQCharacters";
aggregate_attr["S"] := "Subgroups";
aggregate_attr["L"] := "Subgroups";

tstart := Cputime();
for code in Eltseq(codes) do
    header := code_lookup[code];
    if IsDefined(aggregate_attr, code) then
        attr := aggregate_attr[code];
        t0 := ReportStart(G, "Code-" * code);
        for H in Get(G, attr) do
            WriteByTmpHeader(H, outfile, header);
        end for;
        ReportEnd(G, "Code-" * code, t0);
    else
        t0 := ReportStart(G, "Code-" * code);
        WriteByTmpHeader(G, outfile, header);
        ReportEnd(G, "Code-" * code, t0);
    end if;
end for;
ReportEnd(G, "AllFinished", tstart);
exit;
