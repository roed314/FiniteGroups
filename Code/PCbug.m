// USAGE: ls DATA/pcbug.todo | parallel -j100 --timeout 20 magma -b label:={1} PCbug.m

AttachSpec("spec");
SetColumns(0);
infile := "DATA/pcbug.todo/" * label;
outfile := "DATA/pcbugs/" * label;

G := StringToGroup(Read(infile));
if IsSolvable(G) then
    compact := Sprintf("%opc%o", #G, Join([Sprint(c) : c in CompactPresentation(G)], ","));
    PrintFile(outfile, compact);
end if;
System("rm " * infile);
exit;
