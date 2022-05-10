// USAGE: ls DATA/minrep.todo | parallel -j128 --timeout 600 magma -b label:={1} MinReps4.m

AttachSpec("hashspec");
SetColumns(0);
infile := "DATA/minrep.todo/" * label;
outfile := "DATA/minreps/" * label;
timefile := "DATA/minrep.timings/" * label;
done, F := OpenTest(outfile, "r");
if done then
    print "Already complete";
    exit;
end if;
desc := Read(infile);
G := StringToGroup(desc);
t0 := Cputime();
phi, P := MinimalDegreePermutationRepresentation(G);
if Type(G) eq GrpPerm and Degree(P) eq Degree(G) then
    // Just use the original group
    P := G;
    phi := IdentityHomomorphism(G);
    gens := Generators(G);
elif Type(G) eq GrpPC then
    gens := PCGenerators(G);
else
    gens := Generators(G);
end if;
PrintFile(outfile, Sprintf("%o|%o|%o", desc, Degree(P), SavePerms([phi(g) : g in gens])));
PrintFile(timefile, Cputime() - t0);
System("rm " * infile);
exit;
