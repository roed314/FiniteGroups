// Uses IsIsomorphic to merge clusters of transitive groups with the same order and hash into isomorphism classes
// ls DATA/hash/tsep | parallel -j100 --timeout 86400 magma OrdHash:="{1}" TCluster.m

SetColumns(0);

print OrdHash;
t0 := Cputime();

function nTt(s)
    x := Split(s, "T");
    return TransitiveGroup(StringToInteger(x[1]), StringToInteger(x[2]));
end function;

hsh := Split(OrdHash, ".")[2];
input := [Split(s, " ") : s in Split(Read("DATA/hash/tsep/" * OrdHash))];
input := [<nTt(s[1]), StringToInteger(s[2]), s[1..1] cat s[3..#s]> : s in input];
output := [input[1]];
for i in [2..#input] do
    found := false;
    Ti := input[i][1];
    bi := input[i][2];
    for j in [1..#output] do
        Tj := output[j][1];
        bj := output[j][2];
        if bi lt Degree(Tj) and bj lt Degree(Ti) then
            if IsIsomorphic(Ti, Tj) then
                found := true;
                output[j][2] := Max(bi, bj);
                output[j][3] cat:= input[i][3];
                break;
            end if;
        end if;
    end for;
    if not found then
        Append(~output, input[i]);
    end if;
end for;

PrintFile("DATA/hash/tsepout/" * OrdHash, Join([x[3][1] * " " * hsh * " " * Join(x[3][2..#x[3]], " ") : x in output], "\n"));
print "Done in", Cputime() - t0;
