// We use several formats for saving matrix groups.  This script loads in lines in the old format and writes them out in the new format
// Usage: parallel -j64 magma -b file:=FILE outfolder:=FOLD n:={1} total:=64 UpdateMAT.m ::: {1..64}

SetColumns(0);
AttachSpec("spec");

outfile := outfolder * "/" * n;
n := StringToInteger(n);
total := StringToInteger(total);

lines := Split(Read(file), "\n");
for i in [1..#lines by total] do
    line := lines[i];
    label, desc := Explode(Split(line, " "));
    if "Mat" in desc then
        desc := GroupToString(StringToGroup(desc) : use_id:=false);
    end if;
    PrintFile(outfile, label * " " * desc);
end for;
exit;
