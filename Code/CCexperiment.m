// The goal is to find examples where ConjugacyClasses, or CyclicSubgroups is slow
// seq 2000 | parallel -j20 magma -b CCexperiment.m

AttachSpec("spec");
SetColumns(0);
i := 1 + Random(544801);
data := Split(Read("DATA/to_add.txt"), "\n")[i];
pieces := Split(data, " ");
label := pieces[1];
if #pieces eq 1 then
    desc := pieces[1];
else
    desc := pieces[#pieces];
end if;
G := StringToGroup(desc);
startfile := "DATA/ccstart/" * label;
PrintFile(startfile, desc);
donefile := "DATA/ccdone/" * label;
t0 := Cputime();
C := ConjugacyClasses(G);
PrintFile(donefile, Sprintf("%o %o", #C, Cputime() - t0));
t0 := Cputime();
Z := CyclicSubgroups(G);
PrintFile(donefile, Sprintf("%o %o", #Z, Cputime() - t0));
System("rm " * startfile);
exit;
