// USAGE: ls DATA/solvable.todo | parallel -j120 magma -b label:={1} SolvCheck.m

AttachSpec("spec");
SetColumns(0);
infile := "DATA/solvable.todo/" * label;
outfile := "DATA/solvable/" * label;

desc := Read(infile);
G0 := StringToGroup(desc);
if IsSolvable(G0) then
    Write(outfile, desc : Overwrite);
else
    System("rm " * infile);
end if;
exit;
