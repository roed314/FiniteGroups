// We normally store transitive permutation groups in the nTt format, but it's helpful to have them sometimes in the Perm format (since this specifies the generators)
// Usage: parallel -j64 magma -b file:=FILE outfolder:=FOLD n:={1} total:=64 UpdatePerm.m :: {1..64}

SetColumns(0);
AttachSpec("spec");

outfile := outfolder * "/" * n;
n := StringToInteger(n);
total := StringToInteger(total);

lines := Split(Read(file), "\n");
for i in [n..#lines by total] do
    line := lines[i];
    desc := GroupToString(StringToGroup(line) : use_id:=false);
    PrintFile(outfile, line * " " * desc);
end for;
exit;
