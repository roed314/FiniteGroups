// USAGE: ls DATA/pcrep_fast.todo | parallel -j100 --timeout 600 magma -b label:={1} PCreps.m

AttachSpec("spec");
SetColumns(0);
infile := "DATA/pcrep_fast.todo/" * label;
outfile := "DATA/pcreps_fast/" * label;
timefile := "DATA/pcrep_fast.timings/" * label;
homfile := "DATA/homs/" * label;
N := StringToInteger(Split(label, ".")[1]);

done, F := OpenTest(outfile, "r");
if done then
    exit;
end if;

G0 := StringToGroup(Read(infile));
if Type(G0) eq GrpMat and Type(CoefficientRing(G0)) eq RngIntRes then
    G0, psi := MatGroupToPermGroup(G0);
else
    psi := IdentityHomomorphism(G0);
end if;
G := NewLMFDBGrp(G0, label);
AssignBasicAttributes(G);
if not Get(G, "solvable") then
    System("rm " * infile);
    exit;
end if;

procedure SavePCGrp(A, t, phi)
    gens := PCGenerators(A`MagmaGrp);
    PrintFile(outfile, Sprintf("%o|%o|%o|%o", SmallGroupEncoding(A`MagmaGrp), Join([Sprint(c) : c in Get(A, "gens_used")], ","), Join([Sprint(c) : c in CompactPresentation(A`MagmaGrp)], ","), Join([SaveElt(phi(gens[i])) : i in Get(A, "gens_used")], ",")));
    Write(homfile, GroupHomToString(phi) : Overwrite);
    PrintFile(timefile, Sprint(Cputime() - t));
end procedure;
t0 := Cputime();
RePresentFast(G);
SavePCGrp(G, t0, G`IsoToOldPresentation * Inverse(psi));
System("rm " * infile);
exit;
