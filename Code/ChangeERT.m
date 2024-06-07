// Called from modify_group.py; see the code there for the format of the input file

SetColumns(0);
AttachSpec("spec");

infile := "DATA/ert_change_in/" * label;
outfile := "DATA/ert_change_out/" * label;

lines := Split(Read(infile), "\n");

ajS := ["a", "j", "S"];
curdesc := lines[1];
curdesc_lookup := AssociativeArray();
Glookup := AssociativeArray();
if "&" in curdesc then
    curdesc_lookup["a"], curdesc_lookup["j"], curdesc_lookup["S"] := Explode(Split(curdesc, "&"));
    for c in ajS do
        Glookup[c] := MakeBigGroup(curdesc_lookup[c], label);
    end for;
else
    G := MakeBigGroup(curdesc, label);
    for c in ajS do
        curdesc_lookup[c] := curdesc;
        Glookup[c] := G;
    end for;
end if;

newdesc := lines[2];
H := MakeBigGroup(newdesc, label);
HH := H`MagmaGrp;

homs := AssociativeArray();

for line in lines[3..#lines] do
    code := line[1];
    data := line[2..#line];

    G := Glookup[code];
    GG := G`MagmaGrp;
    GH := <GG,HH>;
    if not IsDefined(homs, GH) then
        if GG cmpeq HH then
            homs[GH] := IdentityHomomorphism(GG);
        else
            ok, homs[GH] := IsIsomorphic(GG, HH);
        end if;
    end if;
    f := homs[GH];
    if code eq "a" then
        try
            elts := eval data;
            elts := [[(LoadElt(Sprint(x), G) @ f) : x in y] : y in elts];
            saved := [[SaveElt(x, H) : x in y] : y in elts];
            PrintFile(outfile, Sprintf("a{%o}", Join([Sprintf("{%o}", Join(y, ",")) : y in saved], ",")));
        catch e
            PrintFile(outfile, "Eloading autgens");
        end try;
    elif code eq "j" then
        repid, rorder, rep := Explode(Split(data, "|"));
        try
            elt := LoadElt(rep, G) @ f;
            if Order(elt) eq StringToInteger(rorder) then
                saved := SaveElt(elt, H);
                PrintFile(outfile, Sprintf("j%o|%o", repid, saved));
            else
                PrintFile(outfile, Sprintf("Echeck cc %o", repid));
            end if;
        catch e
            PrintFile(outfile, Sprintf("Eloading cc %o", repid));
        end try;
    elif code eq "S" then
        slabel, sorder, gens := Explode(Split(data, "|"));
        try
            elts := eval gens;
            elts := [(LoadElt(Sprint(x), G) @ f) : x in elts];
            if #sub<HH|elts> eq StringToInteger(sorder) then
                saved := [SaveElt(x, H) : x in elts];
                PrintFile(outfile, Sprintf("S%o|{%o}", slabel, Join(saved, ",")));
            else
                PrintFile(outfile, Sprintf("Echeck subgroup %o", slabel));
            end if;
        catch e
            PrintFile(outfile, Sprintf("Eloading subgroup %o", slabel));
        end try;
    end if;
end for;
