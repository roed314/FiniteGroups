// cat DATA/hash/hashin.txt | parallel -j180 --timeout 7200 --colsep ' ' magma OrdHash:="{1}" gps:="{2}" TCluster5.m

AttachSpec("hashspec");
SetColumns(0);

print OrdHash, gps;
groups := [];
tgps := [];
for nTt in Split(gps, "_") do
    Append(~tgps, nTt);
    n, t := Explode([StringToInteger(c) : c in Split(nTt, "T")]);
    Append(~groups, TransitiveGroup(n, t));
end for;

clusters := [[1..#groups]];
fname := Sprintf("DATA/hash/t5_unsplit/%o", OrdHash);

for hashfunc in [hash2, hash3, hash4] do
    new_clusters := [];
    for C in clusters do
        if #C eq 1 then
            Append(~new_clusters, C);
        else
            A := AssociativeArray();
            for i in C do
                hsh := hashfunc(groups[i]);
                if IsDefined(A, hsh) then
                    Append(~A[hsh], i);
                else
                    A[hsh] := [i];
                end if;
            end for;
            for k -> nC in A do
                Append(~new_clusters, nC);
            end for;
        end if;
    end for;
    clusters := new_clusters;
    if #clusters eq #groups then
        fname := Sprintf("DATA/hash/t5_split/%o", OrdHash);
        break;
    end if;
end for;

PrintFile(fname, Join([Join([tgps[i] : i in C], " ") : C in clusters], "\n") * "\n");
