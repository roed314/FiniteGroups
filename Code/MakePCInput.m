// seq 544802 | parallel -j128 magma -b i:="{1}" MakePCInput.m

AttachSpec("spec");
SetColumns(0);
i := StringToInteger(i);
data := Split(Read("DATA/to_add.txt"), "\n")[i];
pieces := Split(data, " ");
if #pieces eq 1 then
    N, i := Explode(Split(pieces[1], "."));
    N := StringToInteger(N);
    if N le 2000 and (N le 500 or Valuation(N, 2) le 6) then
        // we already have an optimized pc representation available
        exit;
    end if;
    desc := pieces[1];
else
    desc := pieces[#pieces];
end if;
label := pieces[1];
if "(" in desc or "Chev" in desc then
    // not solvable, so don't even try
    exit;
end if;
// See if we have a minimal permutation representation available
done, F := OpenTest("DATA/minreps/" * label, "r");
if done then
    mrep := Read("DATA/minreps/" * label);
    pieces := Split(mrep, "|");
    if "T" in pieces[1] and Split(pieces[1], "T")[1] eq pieces[2] then
        // transitive rep was smallest degree possible
        desc := pieces[1];
    else
        // Use the smaller degree permutation rep
        desc := Sprintf("%oPerm%o", pieces[2], pieces[3][2..#pieces[3]-1]);
    end if;
elif not ("T" in desc or "Perm" in desc) then
    G := StringToGroup(desc);
    if IsSolvable(G) then
        PrintFile("DATA/pcrep.toprep/" * label, desc);
    end if;
    exit;
end if;
// already a permutation group, which is what we want for finding a good pc rep
PrintFile("DATA/pcrep.todo/" * label, desc);
exit;
