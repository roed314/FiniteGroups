// Usage: ls DATA/descriptions | parallel -j120 --timeout 2 magma -b label:={1} CCcount.m

AttachSpec("spec");
SetColumns(0);
infile := "DATA/descriptions/" * label;
outfile := "DATA/cccount/" * label;

s := Read(infile);
if "--" in s then
    if ">>" in s then
        s := PySplit(s, "-->>")[2];
    else
        s := PySplit(s, "--")[1];
    end if;
end if;
G := StringToGroup(s);
n := Nclasses(G);
Write(outfile, Sprint(n) : Overwrite);
exit;
