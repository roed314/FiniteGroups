TextCols := ["abelian_quotient", "acted", "actor", "ambient", "aut_group", "bravais_class", "c_class", "center_label", "central_quotient", "commutator_label", "coset_action_label", "crystal_symbol", "factor1", "factor2", "family", "frattini_label", "frattini_quotient", "group", "image", "knowl", "label", "magma_cmd", "name", "old_label", "outer_group", "product", "proj_label", "projective_image", "q_class", "quotient", "quotient_action_image", "subgroup", "tex_name", "trace_field"];

IntegerCols := ["alias_spot", "ambient_order", "arith_equiv", "aut_counter", "aut_order", "auts", "cdim", "centralizer", "commutator_count", "composition_length", "conjugacy_class_count", "core", "count", "counter", "counter_by_index", "cyc_order_mat", "cyc_order_traces", "degree", "derived_length", "diagram_x", "dim", "elementary", "elt_rep_type", "eulerian_function", "exponent", "extension_counter", "hall", "hyperelementary", "indicator", "kernel", "multiplicity", "n", "ngens", "nilpotency_class", "normal_closure", "normalizer", "number_characteristic_subgroups", "number_conjugacy_classes", "number_normal_subgroups", "number_subgroup_classes", "number_subgroups", "order", "outer_order", "parity", "pc_code", "perfect_core", "pgroup", "priority", "q", "qdim", "quotient_action_kernel", "quotient_order", "quotients_complenetess", "rank", "rep", "representative", "schur_index", "sibling_completeness", "size", "smallrep", "sub1", "sub2", "subgroup_index_bound", "subgroup_order", "sylow", "t", "transitive_degree"];

TextListCols := ["composition_factors", "special_labels"];

IntegerListCols := ["complements", "contained_in", "contains", "cycle_type", "denominators", "factors_of_aut_order", "factors_of_order", "faithful_reps", "generators", "gens", "order_stats", "perm_gens", "powers", "primary_abelian_invariants", "schur_multiplier", "smith_abelian_invariants", "subgroup_fusion"];

BoolCols := ["Agroup", "Zgroup", "abelian", "all_subgroups_known", "almost_simple", "central", "central_product", "characteristic", "cyclic", "direct", "direct_product", "faithful", "finite_matrix_group", "indecomposible", "irreducible", "maximal", "maximal_normal", "maximal_subgroups_known", "metabelian", "metacyclic", "minimal", "minimal_normal", "monomial", "nilpotent", "normal", "normal_subgroups_known", "outer_equivalence", "perfect", "prime", "primitive", "quasisimple", "rational", "semidirect_product", "simple", "solvable", "split", "stem", "subgroup_inclusions_known", "supersolvable", "sylow_subgroups_known", "wreath_product"];

intrinsic LoadBool(inp::MonStgElt) -> BoolElt
    {}
    assert inp in ["t", "f"];
    return (inp eq "t");
end intrinsic;
intrinsic SaveBool(out::BoolElt) -> MonStgElt
    {}
    return (out select "t" else "f");
end intrinsic;

intrinsic LoadIntegerList(inp::MonStgElt) -> SeqEnum
    {}
    assert inp[1] eq "{" and inp[#inp] eq "}";
    /*
    return [StringToInteger(elt) : elt in Split(Substring(inp, 2, #inp-2), ",")];
    */
    ReplaceString(~inp,["{","}"],["[","]"]);
    return eval inp;
end intrinsic;
intrinsic SaveIntegerList(out::SeqEnum) ->  MonStgElt
    {}
    return "{" * Join([IntegerToString(o) : o in out], ",") * "}";
end intrinsic;

// For text lists, we don't currently support nesting because it's not needed
intrinsic LoadTextList(inp::MonStgElt) -> SeqEnum
    {}
    assert inp[1] eq "{" and inp[#inp] eq "}";
    return Split(Substring(inp, 2, #inp-2), ",");
end intrinsic;
intrinsic SaveTextList(out::SeqEnum) ->  MonStgElt
    {}
    return "{" * Join(out, ",") * "}";
end intrinsic;

intrinsic LoadPerms(inp::MonStgElt, n::RngInt) -> SeqEnum
    {}
    return [DecodePerm(elt, n) : elt in LoadIntegerList(inp)];
end intrinsic;
intrinsic SavePerms(out::SeqEnum) -> MonStgElt
    {}
    return SaveIntegerList([EncodePerm(o) : o in out]);
end intrinsic;

intrinsic LoadAttr(attr::MonStgElt, inp::MonStgElt, obj::Any) -> Any
    {Load a single attribue}
    // Decomposition is a bit different for gps_crep and gps_zrep/gps_qrep
    if inp eq "\\N" then
        return None();
    elif attr in TextCols then
        return inp;
    elif attr in IntegerCols then
        return StringToInteger(inp);
    elif attr in BoolCols then
        return LoadBool(inp);
    elif attr in IntegerListCols then
        return LoadIntegerList(inp);
    elif attr in TextListCols then
        return LoadTextList(inp);
    else
        error "Unknown attribute type";
    end if;
end intrinsic;
intrinsic SaveAttr(attr::MonStgElt, val::Any, obj::Any) -> MonStgElt
    {Save a single attribute}
    if Type(val) eq NoneType then
        return "\\N";
    elif attr in TextCols then
        return val;
    elif attr in IntegerCols then
        return IntegerToString(val);
    elif attr in BoolCols then
        return SaveBool(val);
    elif attr in IntegerListCols then
        return SaveIntegerList(val);
    elif attr in TextListCols then
        return SaveTextList(val);
    else
        error "Unknown attribute type";
    end if;
end intrinsic;

intrinsic SetGrp(G::LMFDBGrp)
    {Set the MagmaGrp attribute using data included in other attributes}
    if HasAttribute(G, "pccode") and HasAttribute(G, "order") then
        G`MagmaGrp := SmallGroupDecoding(G`pccode, G`order);
    elif HasAttribute(G, "perm_gens") and HasAttribute(G, "transitive_degree") then
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
        attr := attrs[i];
        G``attr := LoadAttr(attr, data[i], G);
    end for;
    SetGrp(G); // set MagmaGrp based on stored attributes
    return G;
end intrinsic;

intrinsic DefaultAttributes(c::Cat) -> SeqEnum
    {List of attributes that should be saved to disc for postgres}
    if c eq LMFDBGrp then
        defaults := ["Agroup", "Zgroup"];
    else
        defaults := [];
    end if;
    all_attrs := GetAttributes(c);
    for attr in all_attrs do
        // Blacklist attributes that aren't working
        blacklist := [
                      "central_product",
                      "all_subgroups_known"
                    ];
        if attr in blacklist then
            continue;
        end if;
        if Regexp("^[a-z]+", attr) then
            Append(~defaults, attr);
        end if;
    end for;
    return defaults;
end intrinsic;

intrinsic SaveLMFDBObject(G::Any : attrs:=[], sep:="|") -> MonStgElt
{Save an LMFDB object to a single line}
    if attrs eq [] then
        attrs := DefaultAttributes(Type(G));
    end if;
    return Join([SaveAttr(attr, Get(G, attr), G) : attr in attrs], sep);
end intrinsic;

intrinsic PrintData(G::LMFDBGrp: sep:="|") -> Tup
    {}
    return <[SaveLMFDBObject(G: sep:=sep)],
            [SaveLMFDBObject(H: sep:=sep) : H in Get(G, "Subgroups")],
            [SaveLMFDBObject(cc: sep:=sep) : cc in Get(G, "ConjugacyClasses")]>;
end intrinsic;
