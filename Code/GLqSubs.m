// Usage parallel -j 19 magma -b q:={1} GLqSubs.m ::: 4 8 9 16 25 27 32 49 64 81 121 125 128 169 243 256 289 343 361 > GLq.txt

SetColumns(0);
AttachSpec("hashspec");

G := GL(2, StringToInteger(q));
for H in Subgroups(G) do
    if H`order gt 2000 or H`order gt 500 and Valuation(H`order, 2) gt 6 then
        printf "%o %o\n", H`order, GroupToString(H`subgroup);
    end if;
end for;
exit;
