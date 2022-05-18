// USAGE: ls DATA/permrep.todo | parallel -j100 --timeout 600 magma -b label:={1} PCreps.m

AttachSpec("spec");
SetColumns(0);
infile := "DATA/permrep.todo/" * label;
outfile := "DATA/permreps/" * label;
timefile := "DATA/permrep.timings/" * label;
N := StringToInteger(Split(label, ".")[1]);
done, F := OpenTest(outfile, "r");
if done then
    exit;
end if;
desc := Read(infile);
if StringIsPermGroup(desc) then
    PrintFile(outfile, desc);
    System("rm " * infile);
    exit;
end if;
t0 := Cputime();
G := StringToPermGroup(desc);
n := Degree(G);
s := GroupToString(G);
PrintFile(outfile, s);
PrintFile(timefile, Sprint(Cputime() - t0));
System("rm " * infile);
exit;
