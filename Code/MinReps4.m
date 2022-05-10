// USAGE: ls DATA/minrep.todo | parallel -j128 --timeout 600 magma -b label:={1} MinReps4.m

AttachSpec("spec");
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
G0 := StringToGroup(desc);
G := G0;
t0 := Cputime();
if Type(G0) eq GrpMat and not IsField(CoefficientRing(G0)) then
    // MinimalDegreePermutationRepresentation fails
    if IsSolvable(G0) then
        G, psi := PCGroup(G0);
    else
        V := RSpace(G0);
        x := Random(V);
        T := {x};
        psi, G, K := OrbitAction(G0, T);
        while #K ne 1 do
            x := Random(V);
            Include(~T, x);
            psi, G, K := OrbitAction(G0, T);
        end while;
    end if;
else
    psi := IdentityHomomorphism(G);
end if;
phi, P := MinimalDegreePermutationRepresentation(G);
if Type(G0) eq GrpPerm and Degree(P) eq Degree(G0) then
    // Just use the original group
    P := G0;
    phi := IdentityHomomorphism(G0);
    gens := Generators(G);
elif Type(G0) eq GrpPC then
    gens := PCGenerators(G0);
else
    gens := Generators(G0);
end if;
PrintFile(outfile, Sprintf("%o|%o|%o", desc, Degree(P), SavePerms([phi(psi(g)) : g in gens])));
PrintFile(timefile, Cputime() - t0);
System("rm " * infile);
exit;
