// Usage: ls DATA/LieCovers.todo | parallel -j120 magma -b label:={1} LieCover.m

AttachSpec("spec");
SetColumns(0);
infile := "DATA/LieCovers.todo/" * label;
outfile := "DATA/homs/" * label;
desc := Read(infile);
edesc := PStringToHomString(desc);
Write(outfile, edesc : Overwrite);
exit;
