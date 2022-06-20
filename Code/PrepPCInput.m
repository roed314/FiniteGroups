// ls DATA/pcrep.toprep/ | parallel -j76 magma -b label:="{1}" PrepPCInput.m

AttachSpec("spec");
SetColumns(0);
desc := Read("DATA/pcrep.toprep/" * label);
G := StringToGroup(desc);
t0 := Cputime();
Q, phi := MyQuotient(G, sub<G|> : max_orbits:=8, num_checks:=8);
PrintFile("DATA/pcrep.todo/" * label, Sprintf("%oPerm%o", Degree(Q), Join([Sprint(EncodePerm(g)) : g in Generators(Q)], ",")));
PrintFile("DATA/pcrep.preptimings/" * label, Sprintf("%o %o %o", Cputime() - t0, Degree(Q), desc));
System("rm DATA/pcrep.toprep/" * label);
exit;
