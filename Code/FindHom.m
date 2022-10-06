// USAGE: ls DATA/hom.todo | parallel -j80 --timeout 600 magma -b label:={1} FindHom.m
// Finds a homomorphism to fill out a GroupHom description

AttachSpec("spec");
SetColumns(0);
infile := "DATA/hom.todo/" * label;
outfile := "DATA/homs/" * label;
desc := Read(infile);
while desc[#desc] eq "\n" do
    desc := desc[1..#desc-1];
end while;
fdesc := "";
if "(" in desc and desc[1] eq "P" then
    fdesc := PStringToHomString(desc);
elif "---->" in desc then
    GG, HH := Explode(PySplit(desc, "---->"));
    G := StringToGroup(GG);
    H := StringToGroup(HH);
    ok, f := IsIsomorphic(G, H);
    assert ok;
    fdesc := GroupHomToString(f : GG:=GG, HH:=HH);
else
    error "Unrecognized homomorphism specification";
end if;
PrintFile(outfile, fdesc);
exit;
