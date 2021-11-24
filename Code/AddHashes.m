AttachSpec("hashspec");

// parallel -j100 magma N:=512 Span:=10000 Proc:={1} AddHashes.m ::: {0..1049}
// parallel -j200 magma Ns:=1152,1920,2187,3125,15625,16807,78125,117649,161051,371293,823543,1419857,1771561,2476099,4826809,6436343,19487171,20511149,24137569,28629151,47045881,69343957,115856201,147008443,148035889,229345007,418195493,594823321,714924299,844596301,887503681,1350125107,1804229351,2073071593 Span:=100 Proc:={1} AddHashes.m ::: {0..13306}

SetColumns(0);

Ns := [StringToInteger(N) : N in Split(Ns, ",")];
Proc := StringToInteger(Proc);
Span := StringToInteger(Span);
System("mkdir -p DATA/hash");

for N in Ns do
    System(Sprintf("mkdir -p DATA/hash/run%o.%o", N, Span));
    I := NumberOfSmallGroups(N);
    if Proc*Span lt I then
        hashes := [];
        for i in [1+Proc*Span..(1+Proc)*Span] do
            try
                G := SmallGroup(N, i);
            catch e;
                break;
            end try;
            Append(~hashes, Sprintf("%o %o", i, hash(G)));
        end for;
        ofile := Sprintf("DATA/hash/run%o.%o/%o", N, Span, Proc);
        PrintFile(ofile, Join(hashes, "\n"));
        break;
    end if;
    Proc -:= ((I-1) div Span + 1) * Span;
end for;

exit;
