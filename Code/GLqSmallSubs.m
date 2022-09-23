// Usage parallel -j 19 "magma -b q:={1} GLqSmallSubs.m > DATA/GLq{1}.txt" ::: 4 8 9 16 25 27 32 49 64 81 121 125 128 169 243 256 289 343 361

SetColumns(0);
AttachSpec("hashspec");

G := GL(2, StringToInteger(q));
for H in Subgroups(G) do
    if H`order le 2000 and (H`order le 500 or Valuation(H`order, 2) le 6) then
        printf "%o %o\n", GroupToString(H`subgroup), GroupToString(H`subgroup : use_id:=false);
    end if;
end for;
exit;
