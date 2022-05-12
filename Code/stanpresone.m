// Find the standard presentation for a p-group
// Usage cat twopow.txt | parallel -j 64 --timeout 86400 magma -b data:="{1}" stanpresone.m > twopow.finished

SetColumns(0);
AttachSpec("hashspec");
ordhsh, desc := Explode(Split(data, " "));
N := StringToInteger(Split(ordhsh, ".")[1]);
if IsPrimePower(N) then
    G := StringToGroup(desc);
    P := PCGroup(G);
    S := StandardPresentation(P);
    print Sprintf("%o %o %o", ordhsh, desc, GroupToString(S));
end if;
exit;
