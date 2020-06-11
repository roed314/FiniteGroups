intrinsic MakeSmallGroup(N::RngIntElt, i::RngIntElt) -> Tup
    {Create the information for saving a small group to several files.  Returns a triple (one for each file) of lists of strings (one for each entry to be saved)}
    G := NewLMFDBGrp(SmallGroup(N, i), Sprintf("%o.%o", N, i));
    // G`subgroup_index_bound := N;
    // For now we compute everything, so we don't set
    G`subgroup_index_bound := None();
    G`all_subgroups_known := true;
    G`normal_subgroups_known := true;
    G`maximal_subgroups_known := true;
    G`sylow_subgroups_known := true;
    G`outer_equivalence := false;
    G`subgroup_inclusions_known := true;
    AssignBasicAttributes(G);
    return G;
end intrinsic;

intrinsic MakeSmallGroupData(N::RngIntElt, i::RngIntElt) -> Tup
  {}
  G := MakeSmallGroup(N,i);
  return PrintData(G);
end intrinsic;
