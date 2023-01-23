// Usage: ls DATA/descriptions | parallel -j120 magma -b label:={1} CCcount.m

AttachSpec("spec");
SetColumns(0);
infile := "DATA/descriptions/" * label;
outfile := "DATA/cccount/" * label;

G := StringToGroup(Read(infile));
n := Nclasses(G);
Write(outfile, Sprint(n) : Overwrite);
exit;
