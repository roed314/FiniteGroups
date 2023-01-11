// Usage: parallel -j 80 magma -b N:=6561 span:=1000 i0:={1} hashmany.m ::: {1..1397}

SetColumns(0);
AttachSpec("hashspec");

N := StringToInteger(N);
span := StringToInteger(span);
outfile := Sprintf("DATA/hash%o/%o", N, i0);
i0 := span * (StringToInteger(i0) - 1) + 1;
i1 := Min(i0 + span - 1, NumberOfSmallGroups(N));
for i in [i0..i1] do
    G := SmallGroup(N, i);
    PrintFile(outfile, Sprintf("%o.%o %o.%o", N, i, N, hash(G)));
end for;
exit;
