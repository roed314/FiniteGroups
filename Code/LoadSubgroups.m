// Load subgroup data into a SubgroupLat
// Usage magma -b label:=4332.n fname:=/scratch/grp/consistency_problems/4332.n.1 LoadSubgroups.m


AttachSpec("spec");
_, cols := Explode(Split(Read("subagg1.tmpheader"), "\n"));
agg_cols := Split(cols, "|");
short_label_i := Index(agg_cols, "short_label");
gens_i := Index(agg_cols, "generators");
contained_in_i := Index(agg_cols, "contained_in");
quo_i := Index(agg_cols, "quotient_order");
_, cols := Explode(Split(Read("sub.tmpheader"), "\n"));
sub_cols := Split(cols, "|");
out_eq_i := Index(sub_cols, "outer_equivalence");
inc_known_i := Index(sub_cols, "subgroup_inclusions_known");
index_bound_i := Index(sub_cols, "subgroup_index_bound");
desc := Read("DATA/descriptions/" * label);
G := MakeBigGroup(desc, label : preload:=true);
GG := G`MagmaGrp;
by_label := AssociativeArray();
contained_in := AssociativeArray();
res := New(SubgroupLat);
res`Grp := G;
res`subs := [];
lines := [Split(H, "|") : H in Split(Read(fname), "\n")];
inds := [StringToInteger(data[quo_i]) : data in lines];
ParallelSort(~inds, ~lines);
for data in lines do
    if data[1] eq "s" * label then
        res`outer_equivalence := LoadBool(data[out_eq_i]);
        res`inclusions_known := LoadBool(data[inc_known_i]);
        res`index_bound := StringToInteger(data[index_bound_i]);
    elif data[1] eq "S" * label then
        gens := LoadEltList(data[gens_i], G);
        short_label := data[short_label_i];
        contained_in[short_label] := LoadTextList(data[contained_in_i]);
        HH := sub<GG|gens>;
        elt := SubgroupLatElement(res, HH : i:=1+#res);
        Append(~res`subs, elt);
        by_label[short_label] := elt;
    end if;
end for;
for short_label in Keys(by_label) do
    elt := by_label[short_label];
    elt`overs := Sort([by_label[x]`i : x in contained_in[short_label]]);
end for;
LabelSubgroups(res);
