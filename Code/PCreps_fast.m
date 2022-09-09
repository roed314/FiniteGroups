// USAGE: ls DATA/pcrep_fast.todo | parallel -j100 --timeout 600 magma -b label:={1} PCreps.m

AttachSpec("spec");
SetColumns(0);
infile := "DATA/pcrep_fast.todo/" * label;
outfile := "DATA/pcrep_fasts/" * label;
timefile := "DATA/pcrep_fast.timings/" * label;
N := StringToInteger(Split(label, ".")[1]);

done, F := OpenTest(outfile, "r");
if done then
    exit;
end if;

G := MakeBigGroup(Read(infile), label);
if not Get(G, "solvable") then
    System("rm " * infile);
    exit;
end if;
G0 := G`MagmaGrp;

procedure SavePCGrp(A, t, phi)
    gens := PCGenerators(A`MagmaGrp);
    PrintFile(outfile, Sprintf("%o|%o|%o|%o", SmallGroupEncoding(A`MagmaGrp), Join([Sprint(c) : c in A`gens_used], ","), Join([Sprint(c) : c in CompactPresentation(A`MagmaGrp)], ","), Join([SaveElt(phi(gens[i])) : i in A`gens_used], ",")));
    PrintFile(timefile, Sprint(Cputime() - t));
end procedure;
t0 := Cputime();
RePresentFast(G);
SavePCGrp(G, t0, G`IsoToOldPresentation);
System("rm " * infile);
exit;
