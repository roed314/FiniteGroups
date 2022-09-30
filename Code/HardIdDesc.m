// Usage parallel -j 5 magma -b n:={1} IdDesc.m ::: {1..21}
// Inputs should be in DATA/hardN.id, outputs written to DATA/hardoneN.id

// There are some groups where Magma's IdentifyGroup fails with "coset table too large"
// e.g. StringToGroup("2,983MAT949863071,560418631335,23746552176")
// The method here is tailored to the groups that were found to fail IdentifyGroup,
// and may not work in general

SetColumns(0);
AttachSpec("spec");
infile := Sprintf("DATA/hard%o.id", n);
outfile := Sprintf("DATA/hardone%o.id", n);
descs := Split(Read(infile), "\n");

for desc in descs do
    G := StringToGroup(desc);
    assert CanIdentifyGroup(#G);
    imax := NumberOfSmallGroups(#G);
    C := [H`subgroup : H in Subgroups(G) | #Core(G, H`subgroup) eq 1];
    Gs := [SmallGroup(#G, i) : i in [1..imax]];
    Cs := [[H`subgroup : H in Subgroups(Gs[i]) | #Core(Gs[i], H`subgroup) eq 1] : i in [1..imax]];
    goodi := [i : i in [1..imax] | #C eq #Cs[i]];
    assert #goodi eq 1;
    PrintFile(outfile, Sprintf("%o.%o %o", #G, goodi[1], desc));
end for;
exit;
