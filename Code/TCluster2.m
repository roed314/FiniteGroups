// Users Subgroups to merge clusters of transitive groups with the same order and hash into isomorphism classes
// ls DATA/hash/tsep | parallel -j100 --timeout 7200 magma OrdHash:="{1}" TCluster2.m

SetColumns(0);

print OrdHash;
t0 := Cputime();

order, hsh := Explode(Split(OrdHash, "."));
lookup := AssociativeArray();
bound := [];
groups := [];
i := 1;
for s in Split(Read("DATA/hash/tsep/" * OrdHash)) do
    pieces := Split(s, " ");
    Append(~bound, StringToInteger(pieces[2]));
    tgps := [[StringToInteger(m) : m in Split(tgp, "T")] : tgp in [pieces[1]] cat pieces[3..#pieces]];
    Append(~groups, tgps);
    Append(~degrees, SetToMultiset({tgp[1] : tgp in tgps})); // We will be joining these below, so want all multiplicity 1 but to take unions as a multiset
    for tgp in tgps do
        lookup[tgp] := i;
    end for;
    i +:= 1;
end for;

unassigned := [1..#groups];
sibcnts := [];
while #unassigned gt 0 do
    i := unassigned[1];
    Remove(~unassigned, 1);
    n, t := Explode(groups[i][1]);
    G := TransitiveGroup(n, t);
    b := bound[i];
    this_class := groups[i]; // all transitive ids isomorphic to G
    altreps := AssociativeArray(); // keep track of sibling counts for degrees that we check
    checked := {}; // degrees that have already been checked
    remaining_degrees := &join[degrees[j] : j in unassigned]; // multiset of degrees that need to be checked
    while true do
        max_cnt := 0;
        d := 0;
        for dd -> cnt in remaining_degrees do
            if dd gt b and not dd in checked and cnt gt max_cnt then
                max_cnt := cnt;
                d := dd;
            end if;
        end for;
        if d eq 0 then break; end if;
        Include(~checked, d);
        S := Subgroups(G : IndexEqual:=d);
        // We only need subgroups with trivial core, since they yield transitive coset actions
        S := [H`subgroup : H in S | #Core(G, H`subgroup) eq 1];
        for H in S do
            _, T := CosetAction(G, H);
            t := TransitiveGroupIdentification(T);
            if IsDefined(altreps, [d,t]) then
                altreps[[d,t]] +:= 1;
            else
                i := lookup[[d,t]];
                this_class cat:= groups[i];
                for dd in degrees[i] do
                    Exclude(~remaining_degrees, dd);
                end for;
                b := Max(b, bound[i]);
                altreps[[d,t]] := 1;
                Exclude(~unassigned, i);
            end if;
        end for;
    end while;
    Append(~sibcnts, Join([Sprint(b)] cat [Sprintf("%oT%o:%o", k[1], k[2], v) : k -> v in altreps], " "));
    this_class := [Sprintf("%oT%o", pair[1], pair[2]) : pair in this_class]
    Append(~classes, Join(this_class[1..1] cat [hsh] cat this_class[2..#this_class], " "));
end while;

PrintFile("DATA/sibs/" * OrdHash, Join(sibcnts, "\n") * "\n");
PrintFile("DATA/hash/tsepout/" * OrdHash, Join(classes, "\n") * "\n");
