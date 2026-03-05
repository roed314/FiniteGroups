// Usage: parallel -j120 -a desc.todo magma -b label:={1} write_gap_description.m

SetColumns(0);
AttachSpec("spec");

infile := "DATA/descriptions/" * label;
outfile := "DATA/gap_descriptions/" * label;
System("rm " * outfile);

function Gapize(s)
    if "MAT" in s or "Perm" in s or "PC" in s then
        return s;
    end if;
    return GroupToString(StringToGroup(s) : use_id:=false);
end function;

function Gapizef(GG, ff, cover, HH)
    G := StringToGroup(GG);
    Ggens := [g : g in Generators(G)];
    H := StringToGroup(HH);
    f := [LoadElt(x, H) : x in Split(ff, ",")];
    f := hom<G -> H | [<Ggens[i], f[i]> : i in [1..#f]]>;
    f := [(G.i) @ f : i in [1..NPCgens(G)]];
    ff := Join([SaveElt(h) : h in f], ",");
    GG := GroupToString(G : use_id:=false);
    HH := GroupToString(H : use_id:=false);
    return GG * "--" * ff * "--" * cover * HH;
end function;

desc := Split(Read(infile), "\n")[1];
if "--" in desc then
    pieces := PySplit(desc, "--");
    G, f, HH := Explode(pieces);
    if HH[2] eq ">" then
        cover := ">>";
        HH := HH[3..#HH];
    else
        cover := ">";
        HH := HH[2..#HH];
    end if;
    if "pc" in G or "PC" in G then
        desc := Gapizef(G, f, cover, HH);
    else
        desc := Gapize(G) * "--" * f * "--" * cover * Gapize(HH);
    end if;
else
    desc := Gapize(desc);
end if;

PrintFile(outfile, desc);
exit;
