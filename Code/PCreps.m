// USAGE: ls DATA/pcrep.todo | parallel -j100 --timeout 600 magma -b label:={1} PCreps.m

AttachSpec("spec");
SetColumns(0);
infile := "DATA/pcrep.todo/" * label;
outfile := "DATA/pcreps/" * label;
timefile := "DATA/pcrep.timings/" * label;
N := StringToInteger(Split(label, ".")[1]);

done, F := OpenTest(outfile, "r");
if done then
    exit;
    /*
    lines := Split(Read(outfile), "\n");
    stage := #lines;
    if stage eq 3 then
        print "Already complete";
        exit;
    end if;
    */
end if;

G := MakeBigGroup(Read(infile), label);
if not Get(G, "solvable") then
    System("rm " * infile);
    exit;
end if;
G0 := G`MagmaGrp;

procedure SavePCGrp(A, t, phi)
    gens := PCGenerators(A`MagmaGrp);
    PrintFile(outfile, Sprintf("%o|%o|%o|%o|%o", label, SmallGroupEncoding(A`MagmaGrp), Join([Sprint(c) : c in Get(A, "gens_used")], ","), Join([Sprint(c) : c in CompactPresentation(A`MagmaGrp)], ","), Join([SaveElt(phi(gens[i])) : i in Get(A, "gens_used")], ",")));
    PrintFile(timefile, Sprint(Cputime() - t));
end procedure;
//t0 := Cputime();
//RePresentRand(G);
//SavePCGrp(G, t0, G`IsoToOldPresentation);
//System("rm " * infile);
//G`MagmaGrp := G0;
if Type(G0) eq GrpPerm then
    //t0 := Cputime();
    //RePresentFast(G);
    //SavePCGrp(G, t0, G`IsoToOldPresentation);
    //G`MagmaGrp := G0;
    t0 := Cputime();
    RePresent(G: reset_attrs:=false, use_aut:=false);
    SavePCGrp(G, t0, G`IsoToOldPresentation);
    System("rm " * infile);
end if;
exit;
