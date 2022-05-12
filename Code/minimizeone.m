// Call MinimalDegreePermutationRepresentation when needed on the output of autone.m
// Usage: cat important.txt | parallel -j 64 --timeout 1200 magma -b data:="{1}" minimizeone.m > aut_finished.txt

SetColumns(0);
AttachSpec("hashspec");
pieces := Split(data, " ");
if "T" in pieces[#pieces] then
    print data;
else
    G := StringToGroup(pieces[#pieces]);
    M := Image(MinimalDegreePermutationRepresentation(G));
    print Join(pieces[1..#pieces-1], " ") * " " * GroupToString(M);
end if;
exit;
