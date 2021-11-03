AttachSpec("hashspec");

// parallel -j128 magma N:=512 Span:=10000 Proc:={1} AddHashes.m ::: {0..1049}

SetColumns(0);

N := StringToInteger(N);
start := StringToInteger(Proc);
Span := StringToInteger(Span);
System("mkdir -p DATA/hash");
System(Sprintf("mkdir -p DATA/hash/run%o.%o", N, Span));

hashes := [];
for i in [1+start*Span..(1+start)*Span] do
    try
        G := SmallGroup(N, i);
    catch e;
        break;
    end try;
    Append(~hashes, Sprintf("%o %o", i, hash(G)));
end for;
ofile := Sprintf("DATA/hash/run%o.%o/%o", N, Span, start);
PrintFile(ofile, Join(hashes, "\n"));
