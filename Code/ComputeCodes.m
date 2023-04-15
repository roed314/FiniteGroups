// Compute a specified set of columns, based on which one-letter codes are included (these codes are also used as line headers in the ouptut)

AttachSpec("spec");
SetColumns(0);

if not assigned codes then
    // default order for computing invariants
    codes := "blajJzcCrqQsvSLWhtguoIimw";
end if;
if not assigned label then
    if codes ne "X" then
        print "This script requires the label of the group as input, something like magma label:=1024.a ComputeCodes.m";
        quit;
    end if;
end if;

if assigned debug or assigned verbose then
    SetVerbose("User1", 1); // for testing
end if;
if assigned debug then
    SetDebugOnError(true); // for testing
end if;

if codes eq "X" then // identifying groups given in gps_to_id
    // Using label as a variable name gets in the way of the intrinsic, but we don't want to change the API, so we used m instead
    outfile := "DATA/computes/" * m;
    infile := "DATA/gps_to_id/" * m;
    sources, s := Explode(Split(Read(infile), "|"));
    G := StringToGroup(s);
    lab := label(G);
    if Type(lab) eq NoneType then
        PrintFile(outfile, Sprintf("X%o|\\N", m));
    else
        PrintFile(outfile, Sprintf("X%o|%o", m, lab));
    end if;
    quit;
end if;

outfile := "DATA/computes/" * label;
infile := "DATA/descriptions/" * label;
desc := Read(infile);
G := MakeBigGroup(desc, label : preload:=true);
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
aggregate_attr["W"] := "Subgroups";
aggregate_attr["I"] := "Subgroups";

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
ReportEnd(G, Sprintf("AllFinished(%o)", codes), tstart);
exit;
