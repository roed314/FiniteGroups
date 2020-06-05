

intrinsic MakeSmallGroup(N::RngIntElt, i::RngIntElt) -> Tup
    {Create the information for saving a small group to several files.  Returns a triple (one for each file) of lists of strings (one for each entry to be saved)}
    G := New(LMFDBGrp);
    G`MagmaGrp := SmallGroup(N, i);
    G`label := Sprintf("%o.%o", N, i);
    // G`subgroup_index_bound := N;
    // For now we compute everything, so we don't set
    G`subgroup_index_bound := None();
    G`all_subgroups_known := true;
    G`normal_subgroups_known := true;
    G`maximal_subgroups_known := true;
    G`sylow_subgroups_known := true;
    G`outer_equivalence := false;
    G`subgroup_inclusions_known := false; // TODO: change to true
    AssignBasicAttributes(G);
    return PrintData(G);
end intrinsic;
