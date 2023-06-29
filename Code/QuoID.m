// Usage: ls /scratch/grp/smallid/quoin/ | parallel -j120 --timeout 120 magma -b base:=/scratch/grp/smallid/ label:={1} QuoID.m
// Needs to have DATA/descriptions set

AttachSpec("spec");
SetColumns(0);

if base[#base] ne "/" then
    base := base * "/";
end if;
iname := base * "quoin/" * label;
oname := base * "quoout/" * label;
done, F := OpenTest(oname, "r");
if done then
    print "Already complete";
    quit;
end if;

desc := Read("DATA/descriptions/" * label);
G := MakeBigGroup(desc, label : preload:=true);

subs := Split(Read(iname), "\n");
for H in subs do
    short_label, gens := Explode(Split(H, "|"));
    gens := Split(gens, ",");
    HH := sub<G`MagmaGrp | [LoadElt(g, G) : g in gens]>;
    Q := quo<G`MagmaGrp | HH>;
    Hid := IdentifyGroup(Q);
    PrintFile(oname, Sprintf("%o.%o|%o.%o", label, short_label, Hid[1], Hid[2]));
end for;
quit;
