
AttachSpec("spec");
SetColumns(0);
infile := "DATA/descriptions/" * label;
outfile := "DATA/basics/" * label;
desc := Read(infile);
G := MakeBigGroup(desc, label);
Preload(G);
G`gens_used := []; // DELETE
SetVerbose("User1",1); // DELETE
t0 := Cputime();
WriteByTmpHeader(G, outfile, "basic");
print label, Cputime() - t0;
exit;
