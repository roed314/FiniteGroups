// Confirm that the the given special subgroup has been identified correctly
// Usage: ls DATA/check_special_in/ | parallel -j128 --timeout 600 magma -b label:={1} CheckSpecial.m

AttachSpec("spec");
SetColumns(0);

desc := Read("DATA/descriptions/"*label);
G := MakeBigGroup(desc, label);
GG := G`MagmaGrp;

todo := Split(Read("DATA/check_special_in/"*label),"\n");
outfile := "DATA/check_special_out/"*label;
codes := AssociativeArray();
codes["Z"] := "MagmaCenter";
codes["D"] := "MagmaCommutator";
codes["Phi"] := "MagmaFrattini";

for line in todo do
    code, label, sublabel, quolabel, gens := Explode(PySplit(line, "|"));
    C := Get(G, codes[code]);
    if sublabel eq "\\N" then
        PrintFile(outfile, Sprintf("%o|\\N|\\N", code));
    else
        rightlabel := label_subgroup(G, C);
        if Type(rightlabel) eq NoneType then
            rightlabel := "\\N";
            equal := "f";
        else
            equal := (sublabel eq rightlabel) select "t" else "f";
        end if;
        PrintFile(outfile, Sprintf("%o|%o|%o", code, equal, rightlabel));
    end if;
    if quolabel eq "\\N" then
        PrintFile(outfile, Sprintf("%oQ|\\N|\\N", code));
    else
        rightlabel := label_quotient(G, C);
        if Type(rightlabel) eq NoneType then
            rightlabel := "\\N";
            equal := "f";
        else
            equal := (quolabel eq rightlabel) select "t" else "f";
        end if;
        PrintFile(outfile, Sprintf("%oQ|%o|%o", code, equal, rightlabel));
    end if;
    if gens eq "\\N" then
        PrintFile(outfile, Sprintf("%oG|\\N|\\N", code));
    else
        H := sub<G`MagmaGrp|[LoadElt(g, G) : g in Split(gens, ",")]>;
        PrintFile(outfile, Sprintf("%oG|%o|%o|%o", code, label, (C eq H) select "t" else "f", Join([SaveElt(GG!g, G) : g in Generators(C)], ",")));
    end if;
end for;
quit;
