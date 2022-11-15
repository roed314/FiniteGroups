
AttachSpec("spec");
SetColumns(0);

infile := "DATA/descriptions/" * label;
outfile := "DATA/computes/" * label;
desc := Read(infile);
//SetVerbose("User1", 1); // for testing
//SetDebugOnError(true); // for testing
G := MakeBigGroup(desc, label);
Preload(G);
headers := [* "basic", "labeling", "aut1", "conj", "aut2", "wreath", "charc", "charq", "name", "sub", <"ConjugacyClasses", "conjagg">, <"CCCharacters", "charcagg">, <"QQCharacters", "charqagg">, <"Subgroups", "subagg1">, <"Subgroups", "subagg2", "schur"> *];
// The following attributes depend on the Subgroup lattice, introducing an annoying dependence
// ConjugacyClasses: centralizer
// CCCharacters: center, kernel (could represent these in terms of conjugacy classes
// Iteratively try to save different attributes, so that timeouts are handled gracefully
tstart := Cputime();
for X in headers do
    if Type(X) eq MonStgElt then
        t0 := ReportStart(G, "AllHeader" * X);
        WriteByTmpHeader(G, outfile, X);
        ReportEnd(G, "AllHeader" * X, t0);
    else
        attr, Y := Explode(X);
        t0 := ReportStart(G, "AllHeader" * Y);
        for H in Get(G, attr) do
            WriteByTmpHeader(H, outfile, Y);
        end for;
        ReportEnd(G, "AllHeader" * Y, t0);
    end if;
end for;
ReportEnd(G, "AllFinished", tstart);
exit;
