
AttachSpec("spec");
SetColumns(0);
infile := "DATA/descriptions/" * label;
outfile := "DATA/basics/" * label;
desc := Read(infile);
G := MakeBigGroup(desc, label);
Preload(G);
t0 := Cputime();
WriteByTmpHeader(G, outfile, "basic");
print label, Cputime() - t0;
exit;
