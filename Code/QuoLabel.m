// Usage: ls /scratch/grp/bigid/quoin/ | parallel -j120 --timeout 120 magma -b base:=/scratch/grp/bigid/ lab:={1} QuoLabel.m
// Needs to have DATA/descriptions set.  Note that lab is the command line argument, rather than label, so as to not conflict with the intrinsic.

AttachSpec("spec");
SetColumns(0);

if base[#base] ne "/" then
    base := base * "/";
end if;
iname := base * "quoin/" * lab;
oname := base * "quoout/" * lab;
done, F := OpenTest(oname, "r");
if done then
    print "Already complete";
    quit;
end if;

desc := Read("DATA/descriptions/" * lab);
G := MakeBigGroup(desc, lab : preload:=true);

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
    Q := BestQuotient(G`MagmaGrp, HH);
    qlabel := label(Q);
    if Type(qlabel) eq NoneType then
        qlabel := "\\N";
    end if;
    PrintFile(oname, Sprintf("%o.%o|%o", lab, short_label, qlabel));
end for;
quit;
