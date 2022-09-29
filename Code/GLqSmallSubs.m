// Usage parallel -j 20 "magma -b dq:={1} GLqSmallSubs.m" ::: 4 8 9 16 25 27 32 49 64 81 121 125 128 169 243 256 289 343 361 529 625 729 841 961 3,2 3,3 3,4 3,5 3,7 3,8 3,9 3,11 3,13 4,2 4,3 4,4 4,5 5,2

SetColumns(0);
AttachSpec("spec");

if "," in dq then
    d, q := Explode([StringToInteger(c) : c in Split(dq, ",")]);
else
    d := 2;
    q := StringToInteger(dq);
end if;

function savable(n)
    return n gt 1 and CanIdentifyGroup(n) and not (n le 2000 and (n le 500 or Valuation(n, 2) le 6));
end function;

if IsPrime(q) then
    outfile := Sprintf("DATA/GLq/GL%oZ%o.txt", d, q);
else
    outfile := Sprintf("DATA/GLq/GL%oq%o.txt", d, q);
end if;
G := GL(d, q);
if &or[savable(d) : d in Divisors(#G)] then
    for H in Subgroups(G) do
        if savable(H`order) then
            PrintFile(outfile, "%o %o", GroupToString(H`subgroup), GroupToString(H`subgroup : use_id:=false));
        end if;
    end for;
end if;
exit;
