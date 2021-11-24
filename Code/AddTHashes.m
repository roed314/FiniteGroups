AttachSpec("hashspec");

// parallel -j100 magma Span:=100 Proc:={1} AddTHashes.m ::: {0..5126}

System("mkdir -p DATA/hash");
System(Sprintf("mkdir -p DATA/hash/trun%o", Span));

SetColumns(0);
Proc := StringToInteger(Proc);
//Span := StringToInteger(Span);
//start := 1+Proc*Span;

skipped := [409, 1621, 1622, 1625, 4784, 4879, 4899, 4900, 5003, 5009, 5010];
start := skipped[1 + (Proc div 100)] * 100 + (Proc mod 100);
Span := 1;

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
