// Usage: ls /scratch/grp/subtex/subin/ | parallel -j120 --timeout 120 magma -b base:=/scratch/grp/subtex/ label:={1} SubTex.m
// Needs to have DATA/descriptions set

AttachSpec("spec");
SetColumns(0);

if base[#base] ne "/" then
    base := base * "/";
end if;

iname := base * "subin/" * label;
subs := Split(Read(iname), "\n");

oname := base * "subout/" * label;
done, F := OpenTest(oname, "r");
if done then
    osubs := Read(oname);
    include_last := (osubs[#osubs] eq "\n");
    osubs := Split(osubs, "\n");
    if not include_last then
        // Writing was interrupted without finishing a line, so we have to update the output file
        osubs := osubs[1..#osubs-1];
        PrintFile(oname, Join(osubs, "\n") : Overwrite:=true);
    end if;
    if #subs eq #osubs then
        print "Already complete";
        quit;
    else
        subs := subs[#osubs+1..#subs];
    end if;
end if;

desc := Read("DATA/descriptions/" * label);
G := MakeBigGroup(desc, label : preload:=true);

for H in subs do
    if H[#H] eq "|" then
        short_label := H[1..#H-1];
        HH := sub<G`MagmaGrp|>;
    else
        short_label, gens := Explode(Split(H, "|"));
        gens := Split(gens, ",");
        HH := sub<G`MagmaGrp | [LoadElt(g, G) : g in gens]>;
    end if;
    Htex := GroupName(HH: prodeasylimit:=2, wreathlimit:=0, TeX:=true);
    PrintFile(oname, Sprintf("%o.%o|%o", label, short_label, Htex));
end for;
quit;
