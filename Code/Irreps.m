// USAGE: ls DATA/irrep.todo | parallel -j100 --timeout 600 magma -b label:={1} Irreps.m

// Only reports on FAITHFUL irreps that either have dimension at most 8 or are the smallest dimensional irrep for the group

AttachSpec("spec");
SetColumns(0);
infile := "DATA/irrep.todo/" * label;
outfile := "DATA/irreps/" * label;
timefile := "DATA/irrep.timings/" * label;
N := StringToInteger(Split(label, ".")[1]);
// For now, only try this for fairly small groups
if N gt 10000 then
    exit;
end if;
ps := PrimeDivisors(N);
done, F := OpenTest(outfile, "r");
if done then
    lines := Split(Read(outfile), "\n");
    doneps := {Factorization(StringToInteger(Split(line, "|")[1]))[1][1] : line in lines};
    ps := [p : p in ps | not p in doneps];
    if #ps eq 0 then
        print "Already complete";
        exit;
    end if;
end if;
desc := Read(infile);
G := StringToGroup(desc);
for p in ps do
    t0 := Cputime();
    Ms := [AbsolutelyIrreducibleModule(M) : M in IrreducibleModules(G, GF(p))];
    //Ks := [Kernel(M) : M in Ms];
    //mats := [MatricesToHexlist(ActionGenerators(M), CoefficientRing(M)) : M in Ms];
    //ds := [Dimension(Ms[i]) : i in [1..#Ms] | #Ks[i] eq 1];
    //dmin := #ds eq 0 select -1 else Min(ds);
    //for i in [1..#Ms] do
        //M := Ms[i];
        //K := Ks[i];
        //L := mats[i];
    for M in Ms do
        if ExistsConwayPolynomial(p, Degree(CoefficientRing(M))) then
            L := &*MatricesToHexlist(ActionGenerators(M), CoefficientRing(M));
        else
            L := "\\N";
        end if;
        K := Kernel(M);
        d := Dimension(M);
        q := #CoefficientRing(M);
        PrintFile(outfile, Sprintf("%o|%o|%o|%o|%o|%o", q, d, #K, Index(G, K), SubgroupToString(G, K), L));
    end for;
    PrintFile(timefile, Sprintf("%o %o", p, Cputime() - t0));
end for;
//System("rm " * infile);
exit;
