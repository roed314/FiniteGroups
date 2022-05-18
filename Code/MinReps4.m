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
print desc;
G0 := StringToGroup(desc);
G := G0;
t0 := Cputime();
if Type(G0) eq GrpMat and Type(CoefficientRing(G0)) eq RngIntRes then
    // MinimalDegreePermutationRepresentation fails
    if IsField(CoefficientRing(G0)) then
        G0 := ChangeRing(G0, GF(#CoefficientRing(G0)));
        G := G0;
        psi := IdentityHomomorphism(G);
    else
        if IsSolvable(G0) then
            G, psi := PCGroup(G0);
        else
            G, psi := MatGroupToPermGroup(G0);
        end if;
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
