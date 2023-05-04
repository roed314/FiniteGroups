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
if not assigned m then
    if codes eq "X" then
        print "This script requires the temporary id number of a group to label";
        quit;
    end if;
    m := ""; // Ugh; magma requires m to be defined even though that code path is not getting run.
end if;

if assigned debug or assigned verbose then
    SetVerbose("User1", 1); // for testing
end if;
if assigned debug then
    SetDebugOnError(true); // for testing
end if;

if codes in ["X", "Y"] then // identifying groups given in gps_to_id
    // Using label as a variable name gets in the way of the intrinsic, but we don't want to change the API, so we used m instead
    outfile := "DATA/computes/" * m;
    infile := "DATA/gps_to_id/" * m;
    sources, desc := Explode(Split(Read(infile), "|"));
    t0 := ReportStart(m, Sprintf("Code-%o", codes));
    G := StringToGroup(desc);
    if codes eq "X" then
        lab := label(G);
    else
        lab := label_perm_method(G);
    end if;
    if Type(lab) eq NoneType then
        PrintFile(outfile, Sprintf("%o%o|\\N", codes, m));
    else
        PrintFile(outfile, Sprintf("%o%o|%o", codes, m, lab));
    end if;
    ReportEnd(m, Sprintf("Code-%o", codes), t0);
    quit;
    index := 0; // The magma compiler is annoying
elif codes eq "y" then // trying to compute all subgroups of a given index
    label, index := Explode(Split(label, ":"));
else
    index := 0; // Stupid magma compiler requires this
end if;

outfile := "DATA/computes/" * label;
infile := "DATA/descriptions/" * label;
desc := Read(infile);

G := MakeBigGroup(desc, label : preload:=true);

// We don't use the infrastructure below for finding transitive permutation representations,
// since we just want to find as many as we can in the time allotted
if codes eq "x" then
    if not G`abelian then
        WriteTransitivePermutationRepresentations(G`MagmaGrp, outfile, label);
    end if;
    quit;
elif codes eq "y" then
    WriteAllTransitivePermutationRepresentations(G`MagmaGrp, StringToInteger(index), outfile, label);
    quit;
end if;


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
procedure run_codes()
    for code in Eltseq(codes) do
        header := code_lookup[code];
        if IsDefined(aggregate_attr, code) then
            attr := aggregate_attr[code];
            t0 := ReportStart(G, "Code-" * code);
            Agg := Get(G, attr);
            for i in [1..#Agg] do
                H := Agg[i];
                vprint User1: Sprintf("%o-%o %o/%o", attr, code, i, #Agg);
                WriteByTmpHeader(H, outfile, header);
            end for;
            ReportEnd(G, "Code-" * code, t0 : logfile:=true);
        else
            t0 := ReportStart(G, "Code-" * code);
            WriteByTmpHeader(G, outfile, header);
            ReportEnd(G, "Code-" * code, t0 : logfile:=true);
        end if;
    end for;
    ReportEnd(G, Sprintf("AllFinished(%o)", codes), tstart);
end procedure;
if assigned debug then
    run_codes();
else
    try
        run_codes();
    catch e
        print e;
        try
            print e`Traceback;
        catch ee
            print "No traceback";
        end try;
    end try;
end if;
exit;
