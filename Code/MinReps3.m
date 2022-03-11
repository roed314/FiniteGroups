// cat DATA/hashclusters/transitive_add_imp.txt | parallel -j128 magma gp:="{1}" MinReps3.m

AttachSpec("spec");
SetColumns(0);

label, nTt, importance := Explode(Split(gp, " "));
outfile := "DATA/minreps/" * label;
timefile := "DATA/minrep.timings/" * label;
done, F := OpenTest(outfile, "r");
if done then
    print "Already complete";
    exit;
end if;
n, t := Explode([StringToInteger(c) : c in Split(nTt, "T")]);
G := TransitiveGroup(n, t);
t0 := Cputime();
phi, P := MinimalDegreePermutationRepresentation(G);
if Degree(P) eq n then
    // Just use the original group
    P := G;
end if;
PrintFile(outfile, Sprintf("%o|%o|%o", nTt, Degree(P), SavePerms([g : g in Generators(P)])));
PrintFile(timefile, Cputime() - t0);
exit;
