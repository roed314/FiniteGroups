
AttachSpec("spec");
SetColumns(0);

infile := "DATA/descriptions/" * label;
desc := Read(infile);
SetVerbose("User1", 1); // for testing
SetDebugOnError(true); // for testing
compare := AssociativeArray();
headers := [* "basic", "labeling", "aut1", "conj", "aut2", "wreath", "charc", "charq", "name", "sub", <"ConjugacyClasses", "conjagg">, <"CCCharacters", "charcagg">, <"QQCharacters", "charqagg">, <"Subgroups", "subagg1">, <"Subgroups", "subagg2">, "schur" *];
for X in headers do
    if Type(X) eq MonStgElt then
        compare[X] := [];
    else
        compare[X[2]] := [];
    end if;
end for;
Gs := [];
for holval in [true, false] do
    holsum := holval select "Hol" else "NoHol";
    outfile := "DATA/holtest/" * label * "." * holsum;
    G := MakeBigGroup(desc, label);
    Preload(G);
    G`HaveHolomorph := holval;
    // Iteratively try to save different attributes, so that timeouts are handled gracefully
    tstart := Cputime();
    for X in headers do
        if Type(X) eq MonStgElt then
            t0 := ReportStart(G, "AllHeader" * holsum * X);
            WriteByTmpHeader(G, outfile, X);
            ReportEnd(G, "AllHeader" * holsum * X, t0);
            Append(~compare[X], Cputime() - t0);
        else
            attr, Y := Explode(X);
            t0 := ReportStart(G, "AllHeader" * Y);
            for H in Get(G, attr) do
                WriteByTmpHeader(H, outfile, Y);
            end for;
            ReportEnd(G, "AllHeader" * Y, t0);
            Append(~compare[X[2]], Cputime() - t0);
        end if;
    end for;
    ReportEnd(G, "AllFinished", tstart);
    Append(~Gs, G);
end for;
print "Timing comparison";
for X in headers do
    if Type(X) eq MonStgElt then
        print X, compare[X];
    else
        pring X, compare[X[2]];
    end if;
end for;
print "Correctness comparison";

for attr in DefaultAttributes(LMFDBGrp) do
    if Gs[1]``attr cmpne Gs[2]``attr then
        print attr;
    end if;
end for;
