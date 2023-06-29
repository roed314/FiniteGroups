// Usage: ls /scratch/grp/smallid/subin/ | parallel -j120 --timeout 120 magma -b base:=/scratch/grp/smallid/ label:={1} SubID.m
// Needs to have DATA/descriptions set

AttachSpec("spec");
SetColumns(0);

if base[#base] ne "/" then
    base := base * "/";
end if;
iname := base * "subin/" * label;
oname := base * "subout/" * label;
done, F := OpenTest(oname, "r");
if done then
    print "Already complete";
    quit;
end if;

desc := Read("DATA/descriptions/" * label);
G := MakeBigGroup(desc, label : preload:=true);

subs := Split(Read(iname), "\n");
for H in subs do
    if H[#H] eq "|" then
        short_label := H[1..#H-1];
        HH := sub<G`MagmaGrp|>;
    else
        short_label, gens := Explode(Split(H, "|"));
        gens := Split(gens, ",");
        HH := sub<G`MagmaGrp | [LoadElt(g, G) : g in gens]>;
    end if;
    Hid := IdentifyGroup(HH);
    PrintFile(oname, Sprintf("%o.%o|%o.%o", label, short_label, Hid[1], Hid[2]));
end for;
quit;
