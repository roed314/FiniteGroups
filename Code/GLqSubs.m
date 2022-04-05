// Usage parallel -j 19 magma -b q:={1} GLqSubs.m > GLq.txt

SetColumns(0);
AttachSpec("hashspec");

G := GL(2, StringToInteger(q));
for H in Subgroups(G) do
    if #H gt 2000 or #H gt 500 and Valuation(#H, 2) gt 6 then
        printf "%o %o\n", #H, GroupToString(H);
    end if;
end for;
exit;
