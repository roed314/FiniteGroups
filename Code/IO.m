TextCols := ["label", "old_label", "name", "tex_name"];

IntegerCols := ["order", "counter", "exponent", "pgroup", "elementary", "hyperelementary", "rank", "eulerian_function", "center", "commutator", "commutator_count", "frattini", "fitting", "radical", "socle", "transitive_degree", "transitive_subgroup", "faithful_rep", "aut_order", "outer_order", "nilpotency_class", "ngens", "pc_code", "number_conjugacy_classes", "number_subgroup_classes", "number_subgroups", "number_normal_subgroups", "mumber_characteristic_subgroups", "derived_length", "perfect_core", "elt_rep_type", "subgroup_index_bound", "composition_length"];

IntegerListCols := ["factors_of_order", "factors_of_aut_order", "derived_series", "chief_series", "lower_central_series", "upper_central_series", "primary_abelian_invariants", "smith_abelian_invariants", "schur_multiplier", "order_stats", "perm_gens", "composition_factors"];

intrinsic LoadIntegerList(inp::MonStgElt) -> SeqEnum
    {}
    assert inp[1] eq "{" and inp[#inp] eq "}";
    /*
    return [StringToInteger(elt) : elt in Split(Substring(inp, 2, #inp-2), ",")];
    */
    return eval ReplaceString(~inp,["{","}"],["[","]"]);
end intrinsic;
intrinsic SaveIntegerList(out::SeqEnum) ->  MonStgElt
    {}
    return "{" * Join([IntegerToString(o) : o in out], ",") * "}";
end intrinsic;

intrinsic LoadPerms(inp::MonStgElt, n::RngInt) -> SeqEnum
    {}
    return [DecodePerm(elt, n) : elt in LoadIntegerList(inp)];
end intrinsic;
intrinsic SavePerms(out::SeqEnum) -> MonStgElt
    {}
    return SaveIntegerList([EncodePerm(o) : o in out]);
end intrinsic;

intrinsic LoadSubgroup(inp::MonStgElt) -> Any
    {Load a subgroup??}

intrinsic LoadAttr(attr::MonStgElt, inp::MonStgElt, obj::Any) -> Any
    {Load a single attribue}
    // Decomposition is a bit different for gps_crep and gps_zrep/gps_qrep
    if attr in TextCols then
        return inp;
    elif attr in IntegerCols then
        return StringToInteger(inp);
    elif attr in IntegerListCols then
        return LoadIntegerList(inp);
    elif attr in SubgroupCols then
        return [];
    end if;
end intrinsic;
intrinsic SaveAttr(attr::MonStgElt, val::Any, obj::Any, finalize::BoolElt) -> MonStgElt
    {Save a single attribute}
    if attr in TextCols then
        return val;
    elif attr in IntegerCols then
        return IntegerToString(val);
    elif attr in IntegerListCols then
        return SaveIntegerList(val);
    elif attr in SubgroupCols then
        return [];
    end if;
end intrinsic;

intrinsic SetGrp(G::LMFDBGrp)
    {Set the MagmaGrp attribute using data included in other attributes}
    if HasAttribute(G, "pccode") && HasAttribute(G, "order") then
        G`MagmaGrp := SmallGroupDecoding(G`pccode, G`order);
    elif HasAttribute(G, "perm_gens") && HasAttribute(G, "transitive_degree") then
        G`MagmaGrp := PermutationGroup<G`transitive_degree | G`perm_gens>;
    // TODO: Add matrix group case, use EltRep to decide which data to reconstruct from
    end if;
end intrinsic;

intrinsic LoadGrp(line::MonStgElt, attrs::SeqEnum: sep:="|") -> LMFDBGrp
    {Load an LMFDBGrp from a row of a file, setting stored attributes correctly}
    data := Split(line, sep: IncludeEmpty := true);
    error if #data ne #attrs, "Wrong size data line";
    G := New(LMFDBGrp);
    for i in [1..#data] do
        if data[i] ne "\\N" then
            attr := attrs[i];
            G``attr := LoadAttr(attr, data[i], G);
        end if;
    end for;
    SetGrp(G); // set MagmaGrp based on stored attributes
    return G;
end intrinsic;

intrinsic SaveGrp(G::LMFDBGrp, attrs::SeqEnum: sep:="|", finalize:=false) -> MonStgElt
    {Save an LMFDB group to a single line.  If finalize, look up subgroups in the subgroups table, otherwise store}
    return Join([SaveAttr(attr, Get(G, attr), G) : attr in attrs], sep);
end intrinsic;

GrpAttrs := [];

intrinsic PrintData(G::LMFDBGrp: sep:="|", finalize:=false) -> Tup
    {}
    return <[SaveGrp(G, GrpAttrs: sep:=sep, finalize:=finalize)],
            [SaveSubGrp(H, SubGrpAttrs: sep:=sep, finalize:=finalize) : H in Get(G, "Subgroups")],
            [SaveConjCls(cc, ConjClsAttrs: sep:=sep, finalize:=finalize) : cc in Get(G, "ConjugacyClasses")]>;
end intrinsic;
