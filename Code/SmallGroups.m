

intrinsic MakeSmallGroup(N::RngIntElt, i::RngIntElt) -> SeqEnum
    G := New(LMFDBGrp);
    G`MagmaGrp := SmallGroup(N, i);
    G`subgroup_index_bound := N;
    // For now we compute everything, so we don't set
    // subgroup_index_bound
    G`all_subgroups_known := true;
    G`normal_subgroups_known := true;
    G`maximal_subgroups_known := true;
    G`sylow_subgroups_known := true;
    G`outer_equivalence := false;
    return PrintData(G);
end intrinsic;
