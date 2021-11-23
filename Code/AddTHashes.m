AttachSpec("hashspec");

// parallel -j100 magma Span:=100 Proc:={1} AddTHashes.m ::: {0..5126}

SetColumns(0);
Proc := StringToInteger(Proc);
Span := StringToInteger(Span);
start := 1+Proc*Span;
System("mkdir -p DATA/hash");
System(Sprintf("mkdir -p DATA/hash/trun%o", Span));

hashes := [];
cur := 0;
for n in [1..47] do
    if n eq 32 then continue; end if;
    I := NumberOfTransitiveGroups(n);
    if cur+I ge start then
        for i in [Max(1,start-cur)..Min(start-cur+Span-1,I)] do
            try
                G := TransitiveGroup(n, i);
            catch e;
                break;
            end try;
            Append(~hashes, Sprintf("%o %o %o %o", n, i, Order(G), hash(G)));
        end for;
    end if;
    if cur+I ge start+Span then
        break;
    end if;
    cur +:= I;
end for;
ofile := Sprintf("DATA/hash/trun%o/%o", Span, Proc);
PrintFile(ofile, Join(hashes, "\n"));

exit;
