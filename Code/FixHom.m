// USAGE: parallel -a homs.todo -j120 --timeout 600 magma -b label:={1} FixHom.m
// Takes a homormophism using the old Mat format, switches to the new MAT format, and checks that the resulting domain and codomain match that in the description and checks some random examples to ensure that the homomorphism is valid.

AttachSpec("spec");
SetColumns(0);
homfile := "DATA/homs_old/" * label;
if not OpenTest(homfile, "r") then
    exit;
end if;
blankfile := "DATA/descriptions/" * label;
outfile := "DATA/homs/" * label;
codfile := "DATA/homcods/" * label;
blankdesc := Split(Read(blankfile), "\n")[1];
if "---->" in blankdesc then
    blankdom, blankcod := Explode(PySplit(blankdesc, "---->"));
    homcod := "";
    for homdesc in Split(Read(homfile), "\n") do
        homdom := PySplit(homdesc, "--")[1];
        if homdom eq blankdom then
            hom := StringToGroupHom(homdesc);
            homcod := GroupToString(Codomain(hom) : use_id:=false);
            if homcod eq blankcod then
                // Test validity since we've seen some broken homomorphisms
                dom := Domain(hom);
                for trial in [1..10] do
                    a := Random(dom);
                    b := Random(dom);
                    if hom(a * b) ne hom(a) * hom(b) then
                        print "Invalid hom", homdesc, SaveElt(a), SaveElt(b);
                        exit;
                    end if;
                end for;
                Write(outfile, GroupHomToString(hom : GG:=blankdom, HH:=blankcod) : Overwrite);
                exit;
            end if;
        end if;
    end for;
    if #homcod gt 0 then
        Write(codfile, homcod : Overwrite);
    end if;
    print "No matching domain and codomain found for", label;
end if;
exit;
