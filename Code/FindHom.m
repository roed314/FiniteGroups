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
    assert #G eq #H;
    //ok, f := IsIsomorphic(G, H); // this was failing
    SG := Subgroups(G);
    SH := Subgroups(H);
    assert #SG eq #SH;
    CG := [X`subgroup : X in SG | #Core(G, X`subgroup) eq 1];
    CH := [X`subgroup : X in SH | #Core(H, X`subgroup) eq 1];
    assert #CG eq #CH;
    mG := Max([#X : X in CG]); // May be better to choose another order rather than the maximum, if there are fewer conjugacy classes of subgroups of that order.  Extreme case would be regular representation.
    m := Max([#X : X in CH]);
    assert m eq mG;
    CG := [X : X in CG | #X eq mG];
    CH := [X : X in CH | #X eq m];
    assert #CG eq #CH;
    Sn := Sym(#G div m);
    A := CG[1];
    rhoA := CosetAction(G, A);
    PA := Image(rhoA);
    ok := false;
    for i in [1..#CH] do
        B := CH[i];
        rhoB := CosetAction(H, B);
        PB := Image(rhoB);
        ok, c := IsConjugate(Sn, PA, PB);
        if ok then
            break;
        end if;
    end for;
    assert ok;
    f := hom<G -> H | [g -> ((g @ rhoA)^c) @@ rhoB : g in Generators(G)]>;
    fdesc := GroupHomToString(f : GG:=GG, HH:=HH);
else
    error "Unrecognized homomorphism specification";
end if;
PrintFile(outfile, fdesc);
exit;
