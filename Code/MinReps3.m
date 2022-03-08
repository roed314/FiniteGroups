// cat DATA/hashclusters/transitive_add.txt | parallel -j128 magma gp:="{1}" MinReps3.m

AttachSpec("spec");
SetColumns(0);

label, nTt, importance := Explode(Split(gp, " "));
n, t := Explode([StringToInteger(c) : c in Split(nTt, "T")]);
G := TransitiveGroup(n, t);
t0 := Cputime();
phi, P := MinimalDegreePermutationRepresentation(G);
PrintFile("DATA/minreps/" * label, Sprintf("%o|%o|%o", nTt, Degree(P), SavePerms([g : g in Generators(P)])));
PrintFile("DATA/minrep.timings/" * label, Cputime() - t0);
exit;
