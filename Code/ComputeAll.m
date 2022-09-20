
AttachSpec("spec");
SetColumns(0);
infile := "DATA/descriptions/" * label;
outfile := "DATA/computes/" * label;
desc := Read(infile);
SetVerbose("User1", 1); // for testing
G := MakeBigGroup(desc, label);
Preload(G);
headers := [* "basic", "labeling", "aut", "conj", <"ConjugacyClasses", "conjagg">, "schur", "wreath", "charc", <"CCCharacters", "charcagg">, "charq", <"QQCharacters", "charqagg">, "sub", <"Subgroups", "subagg">, "name" *];
t0 := Cputime();
// Iteratively try to save different attributes, so that timeouts are handled gracefully
for X in headers do
    print "Starting", X, Cputime() - t0;
    if Type(X) eq MonStgElt then
        WriteByTmpHeader(G, outfile, X);
    else
        attr, Y := Explode(X);
        s := Join([WriteByTmpHeader(H, outfile, Y) : H in Get(G, attr)], "\n");
        PrintFile(outfile, s);
    end if;
end for;
print "Done", label, Cputime() - t0;
exit;
