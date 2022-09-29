// Usage parallel -j 14 "magma -b dq:={1} GLqSmallSubs.m > DATA/GLq/GLq{1}.txt" ::: 4 8 9 16 25 27 32 49 64 81 121 125 128 169 243 256 289 343 361 3,2 3,3 3,4 3,5 3,7 3,8 3,9 3,11 3,13 4,2 4,3 4,4 4,5 5,2

SetColumns(0);
AttachSpec("spec");

if "," in dq then
    d, q := Explode([StringToInteger(c) : c in Split(dq, ",")]);
else
    d := 2;
    q := StringToInteger(dq);
end if;

G := GL(d, q);
for H in Subgroups(G) do
    if H`order gt 1 and H`order le 2000 and (H`order le 500 or Valuation(H`order, 2) le 6) then
        printf "%o %o\n", GroupToString(H`subgroup), GroupToString(H`subgroup : use_id:=false);
    end if;
end for;
exit;
