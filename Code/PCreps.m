// USAGE: ls DATA/pcrep.todo | parallel -j100 --timeout 600 magma -b label:={1} PCreps.m

AttachSpec("spec");
SetColumns(0);
infile := "DATA/pcrep.todo/" * label;
outfile := "DATA/pcreps/" * label;
timefile := "DATA/pcrep.timings/" * label;
N := StringToInteger(Split(label, ".")[1]);
done, F := OpenTest(outfile, "r");
if done then
    lines := Split(Read(outfile), "\n");
    stage := #lines;
    if stage eq 2 then
        print "Already complete";
        exit;
    end if;
end if;
G := MakeBigGroup(Read(infile), label);
if not Get(G, "solvable") then
    System("rm " * infile);
    exit;
end if;
if Type(G) eq GrpPC then
    phi := IdentityHomomorphism(G);
else
    G`MagmaGrp, phi := PCGroup(G`MagmaGrp);
end if;
t0 := Cputime();
RePresent(G, reset_attrs:=false);
PrintFile(outfile, Sprint("%o|%o|%o", SamllGroupEncoding(G`MagmaGrp), Join([Sprint(c) : c in G`gens_used], ","), Join([Sprint(c) : c in CompactPresentation(G`MagmaGrp)], ",")));
PrintFile(timefile, Sprint(Cputime() - t0));
System("rm " * infile);
exit;
