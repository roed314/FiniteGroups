// Check for bugs in Magma's MinimalDegreePermutationRepresentation using MyQuotient
// USAGE: ls DATA/minreps | parallel -j128 --timeout 300 magma -b label:={1} CheckMinrep.m

AttachSpec("spec");
SetColumns(0);
infile := "DATA/minreps/" * label;
bugfile := "DATA/minrep.bugs/" * label;
timefile := "DATA/minrep.bugtimings/" * label;
done, F := OpenTest(timefile, "r");
if done then
    print "Already complete";
    exit;
end if;
desc, deg, gens := Explode(Split(Read(infile), "|"));
deg := StringToInteger(deg);
G := StringToGroup(desc);
t0 := Cputime();
Hs := GoodCoredSubgroups(G, sub<G|>, 5 : num_checks:=10);
Hdeg := &+[Index(G, H) : H in Hs];
if Hdeg lt deg then
    PrintFile(bugfile, Sprintf("%o|%o|%o|%o|%o", desc, Hdeg, deg, Join([Sprint(Index(G, H)) : H in Hs], ","), Join([SubgroupToString(G, H) : H in Hs], "&")));
end if;
PrintFile(timefile, Sprint(Cputime() - t0));
exit;
