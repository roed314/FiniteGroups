TextCols := ["abelian_quotient", "acted", "actor", "ambient", "aut_group", "bravais_class", "c_class", "center_label", "central_quotient", "commutator_label", "coset_action_label", "crystal_symbol", "factor1", "factor2", "family", "frattini_label", "frattini_quotient", "group", "image", "knowl", "label", "short_label", "aut_label", "magma_cmd", "name", "old_label", "outer_group", "product", "proj_label", "projective_image", "q_class", "quotient", "quotient_action_image", "subgroup", "tex_name", "q_character", "carat_label", "subgroup_tex", "ambient_tex", "quotient_tex", "weyl_group", "aut_weyl_group", "quotient_action_kernel", "element_repr_type"];

IntegerCols := ["alias_spot", "arith_equiv", "aut_counter", "auts", "cdim", "commutator_count", "counter", "counter_by_index", "cyc_order_mat", "cyc_order_traces", "cyclotomic_n", "degree", "diagram_x", "diagram_aut_x", "diagram_norm_x", "dim", "elementary", "exponent", "extension_counter", "hyperelementary", "indicator", "multiplicity", "n", "number_characteristic_subgroups", "number_conjugacy_classes", "number_autjugacy_classes", "number_divisions", "number_normal_subgroups", "number_subgroup_classes", "number_subgroup_autclasses", "number_subgroups", "parity", "priority", "q", "qdim", "quotients_complenetess", "rep", "schur_index", "sibling_completeness", "size", "smallrep", "t", "transitive_degree", "irrC_degree", "irrQ_degree", "linC_degree", "linQ_degree", "linFp_degree", "linFq_degree", "permutation_degree"];
SmallintCols := ["elt_rep_type", "composition_length", "derived_length", "ngens", "nilpotency_class", "pgroup", "sylow", "easy_rank", "rank", "pc_rank", "subgroup_index_bound", "solvability_type", "backup_solvability_type"];
BigintCols := ["mobius_sub", "mobius_quo", "hash", "subgroup_hash", "quotient_hash"];
NumericCols := ["hall", "eulerian_function", "order", "aut_order", "outer_order", "ambient_order", "subgroup_order", "quotient_order", "quotient_action_kernel_order", "aut_centralizer_order", "aut_weyl_index", "aut_stab_index", "aut_quo_index", "count", "conjugacy_class_count", "pc_code", "core_order", "centralizer_order", "SubGrpLstByDivisorTerminate"];

TextListCols := ["composition_factors", "special_labels", "wreath_data"];

IntegerListCols := ["cycle_type", "denominators", "factors_of_aut_order", "faithful_reps", "powers", "primary_abelian_invariants", "schur_multiplier", "smith_abelian_invariants", "subgroup_fusion", "nt","qvalues", "trace_field"];
SmallintListCols := ["factors_of_order", "gens_used", "exponents_of_order", "diagramx"];
NumericListCols := ["order_stats","cc_stats","div_stats","aut_stats","irrep_stats","ratrep_stats","field","perm_gens", "aut_gens"];

BoolCols := ["Agroup", "Zgroup", "abelian", "all_subgroups_known", "complex_characters_known", "rational_characters_known", "almost_simple", "central", "central_product", "characteristic", "cyclic", "direct", "direct_product", "faithful", "indecomposible", "irreducible", "maximal", "maximal_normal", "maximal_subgroups_known", "metabelian", "metacyclic", "minimal", "minimal_normal", "monomial", "nilpotent", "normal", "normal_subgroups_known", "complements_known", "outer_equivalence", "perfect", "prime", "primitive", "quasisimple", "rational", "semidirect_product", "simple", "solvable", "split", "stem", "subgroup_inclusions_known", "supersolvable", "sylow_subgroups_known", "wreath_product", "standard_generators", "quotient_cyclic", "quotient_abelian", "quotient_solvable", "proper", "complete", "central_factor", "AllSubgroupsOk"];

// creps has a gens which is not integer[]
JsonbCols := ["quotient_fusion", "decomposition", "traces", "gens", "values", "direct_factorization", "representations"];

SubgroupCols := ["centralizer", "kernel", "core", "center", "normal_closure", "normalizer", "sub1", "sub2"];
SubgroupListCols := ["complements", "contains", "contained_in", "normal_contains", "normal_contained_in", "charc_centers", "charc_kernels", "conj_centralizers"];

EltCols := ["representative"];
EltListCols := ["generators", "charc_center_gens", "charc_kernel_gens", "conj_centralizer_gens"];
//QuotListCols := ["generator_images"];

// The following is to be able to have a global variable
declare type LMFDBRootFolderCache;
declare attributes LMFDBRootFolderCache:
    folder;
LMFDBRootFolder := New(LMFDBRootFolderCache);
LMFDBRootFolder`folder := "";
intrinsic GetLMFDBRootFolderCache() -> LMFDBRootFolderCache
{}
    return LMFDBRootFolder;
end intrinsic;
intrinsic SetLMFDBRootFolder(folder::MonStgElt)
{}
    cache := GetLMFDBRootFolderCache();
    cache`folder := folder;
end intrinsic;
intrinsic GetLMFDBRootFolder() -> MonStgElt
{}
    cache := GetLMFDBRootFolderCache();
    return cache`folder;
end intrinsic;

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
    //return "{" * Join([IntegerToString(o) : o in out], ",") * "}";
    out_str := Sprint(out);
    ReplaceString(~out_str, ["[","]","<",">"," ","\n"],["{","}","{","}","", ""]);
    if out_str eq "{{}}" then out_str := "{}"; end if; // Postgres can't handle nested lists of length 0....
    return out_str;
end intrinsic;

// For text lists, we don't currently support nesting because it's not needed
intrinsic LoadTextList(inp::MonStgElt) -> SeqEnum
    {}
    assert inp[1] eq "{" and inp[#inp] eq "}";
    return Split(Substring(inp, 2, #inp-2), ",");
end intrinsic;
intrinsic SaveTextList(out::SeqEnum) ->  MonStgElt
    {}
    return "{\"" * Join(out, "\",\"") * "\"}";
end intrinsic;


intrinsic SaveJsonb(inp::MonStgElt) -> MonStgElt
{Save a string by wrapping with quotes}
    return "\"" * inp * "\"";
end intrinsic;
intrinsic SaveJsonb(inp::RngIntElt) -> MonStgElt
{Save an integer}
    return Sprint(inp);
end intrinsic;
intrinsic SaveJsonb(inp::FldRatElt) -> MonStgElt
{Save an integer}
    assert Denominator(inp) eq 1;
    return Sprint(inp);
end intrinsic;
intrinsic SaveJsonb(inp::List) ->  MonStgElt
{assuming list of strings or integers (or embedded lists of these) only}
    return "[" * Join([SaveJsonb(x) : x in inp], ",") * "]";
end intrinsic;
intrinsic SaveJsonb(inp::SeqEnum) ->  MonStgElt
{assuming list of strings or integers (or embedded lists of these) only}
    return "[" * Join([SaveJsonb(x) : x in inp], ",") * "]";
end intrinsic;
intrinsic SaveJsonb(inp::Tup) -> MonStgElt
{assuming list of strings or integers (or embedded lists of these) only}
    return "[" * Join([SaveJsonb(x) : x in inp], ",") * "]";
end intrinsic;
intrinsic SaveJsonb(inp::Assoc) -> MonStgElt
{saving a dictionary}
    return "{" * Join([Sprintf("%o:%o", SaveJsonb(k), SaveJsonb(v)) : k -> v in inp], ",") * "}";
end intrinsic;

function splitagg(inp, spliton)
    level := 0;
    strlevel := Integers(2)!0; // strings don't nest: they're just on or off
    out := [];
    i := 1;
    for j in [1..#inp] do
        if inp[j] in ["[", "{"] then
            level +:= 1;
        elif inp[j] in ["]", "}"] then
            level -:= 1;
        elif inp[j] eq "\"" then
            strlevel +:= 1;
        elif level eq 0 and strlevel eq 0 and inp[j] eq spliton then
            Append(~out, inp[i..j-1]);
            i := j+1;
        end if;
    end for;
    if i le #inp then
        Append(~out, inp[i..#inp]);
    end if;
    return out;
end function;
intrinsic LoadJsonb(inp::MonStgElt) -> Any
{Supports lists and dictionaries (iteratively), with strings and integers as leaves}
    i := 1; k := #inp;
    while inp[i] eq " " do i +:= 1; end while;
    while inp[k] eq " " do k -:= 1; end while;
    if inp[i] eq "[" and inp[k] eq "]" then
        // Need to strip interior whitespace to handle empty list [  ] appropriately
        while inp[i+1] eq " " do i +:= 1; end while;
        while inp[k-1] eq " " do k -:= 1; end while;
        out := [* LoadJsonb(x) : x in splitagg(inp[i+1..k-1], ",") *];
        try
            return [x : x in out];
        catch e;
            return out;
        end try;
    elif inp[i] eq "{" and inp[k] eq "}" then
        // Need to strip interior whitespace to handle empty dict { } appropriately
        while inp[i+1] eq " " do i +:= 1; end while;
        while inp[k-1] eq " " do k -:= 1; end while;
        out := AssociativeArray();
        for x in splitagg(inp[i+1..k-1], ",") do
            yz := splitagg(x, ":"); assert #yz eq 2;
            out[LoadJsonb(yz[1])] := LoadJsonb(yz[2]);
        end for;
        return out;
    elif inp[i] eq "\"" and inp[k] eq "\"" and &and[inp[j] ne "\"" : j in [i+1..k-1]] then
        return inp[i+1..k-1];
    else
        return StringToInteger(inp);
    end if;
end intrinsic;


intrinsic LoadPerms(inp::MonStgElt, n::RngIntElt) -> SeqEnum
    {}
    return [DecodePerm(elt, n) : elt in LoadIntegerList(inp)];
end intrinsic;
intrinsic SavePerms(out::SeqEnum) -> MonStgElt
    {}
    return SaveIntegerList([EncodePerm(o) : o in out]);
end intrinsic;

intrinsic LoadElt(inp::MonStgElt, GG::Grp) -> Any
{}
    if Type(GG) eq GrpPC then
        n := StringToInteger(inp);
        v := [];
        Ps := PCPrimes(GG);
        for p in Ps do
            n, r := Quotrem(n, p);
            Append(~v, r);
        end for;
        return GG!v;
    elif Type(GG) eq GrpPerm then
        n := Degree(GG);
        return GG!DecodePerm(StringToInteger(inp), n);
    elif Type(GG) eq GrpMat then
        d := Degree(GG);
        Rcode := CoefficientRingCode(CoefficientRing(GG));
        if Rcode eq "0" then
            inp, b := Explode(Split(inp, "."));
            b := Reverse(b);
        else
            b := ""; // b not used
        end if;
        L, R := SplitMATRIXCodes(inp, d, Rcode, b);
        return GG!(L[1]);
    else
        error "Other group types not supported";
    end if;
end intrinsic;

intrinsic LoadElt(inp::MonStgElt, G::LMFDBGrp) -> Any
{}
    if assigned G`ElementReprCovers then
        assert assigned G`ElementReprHom;
        cover := G`ElementReprCovers;
        f := G`ElementReprHom;
        if cover then
            GG := Domain(f);
        else
            GG := Codomain(f);
        end if;
    else
        GG := G`MagmaGrp;
    end if;
    // For PCGroups, we have loaded the group from its pc_code since we're using a different presentation
    inp := LoadElt(inp, GG);
    if assigned G`ElementReprCovers then
        if cover then
            inp := inp @ f;
        else
            inp := inp @@ f;
        end if;
    end if;
    return inp;
end intrinsic;

intrinsic SaveElt(out::GrpElt) -> MonStgElt
{}
    GG := Parent(out);
    if Type(out) eq GrpPCElt then
        n := 0;
        v := Reverse(ElementToSequence(out));
        Ps := Reverse(PCPrimes(GG));
        for i in [1..#Ps] do
            n *:= Ps[i];
            n +:= v[i];
        end for;
        return IntegerToString(n);
    elif Type(out) eq GrpPermElt then
        return IntegerToString(EncodePerm(out));
    elif Type(out) eq GrpMatElt then
        L, R := MatricesToIntegers([Matrix(out)], CoefficientRing(out));
        R := Split(R, ",");
        if #R eq 2 then // characteristic 0, where we need to explicitly record b
            return Sprintf("%o.%o", L[1], Reverse(R[2]));
        else
            return Sprint(L[1]);
        end if;
    else
        error "Other group types not supported";
    end if;
end intrinsic;

intrinsic SaveElt(out::GrpElt, G::LMFDBGrp) -> MonStgElt
{}
    if assigned G`ElementReprCovers then
        assert assigned G`ElementReprHom;
        f := G`ElementReprHom;
        if G`ElementReprCovers then
            out := out @@ f;
        else
            out := out @ f;
        end if;
    end if;
    return SaveElt(out);
end intrinsic;

intrinsic LoadEltList(inp::MonStgElt, G::LMFDBGrp) -> SeqEnum
{}
    i := 1; k := #inp;
    while inp[i] eq " " do i +:= 1; end while;
    while inp[k] eq " " do k -:= 1; end while;
    if inp[1] eq "{" and inp[#inp] eq "}" then
        // Need to strip interior whitespace to handle empty list [  ] appropriately
        while inp[i+1] eq " " do i +:= 1; end while;
        while inp[k-1] eq " " do k -:= 1; end while;
        return [LoadEltList(x) : x in splitagg(inp[i+1..k-1], ",")];
    else
        return LoadElt(inp, G);
    end if;
end intrinsic;
intrinsic SaveEltList(out::SeqEnum, G::LMFDBGrp) -> MonStgElt
{}
    return "{" * Join([SaveEltList(x, G) : x in out], ",") * "}";
end intrinsic;
intrinsic SaveEltList(out::GrpElt, G::LMFDBGrp) -> MonStgElt
{base case}
    return SaveElt(out, G);
end intrinsic;

intrinsic LoadSubgroupList(inp::MonStgElt, G::LMFDBGrp) -> SeqEnum
    {}
    assert inp[1] eq "{" and inp[#inp] eq "}";
    return [LookupSubgroup(G, x) : x in Split(Substring(inp, 2, #inp-2), ",")];
end intrinsic;
intrinsic SaveSubgroupList(out::SeqEnum, G::LMFDBGrp) -> MonStgElt
    {}
    return "{" * Join([LookupSubgroupLabel(G, H) : H in out], ",") * "}";
end intrinsic;

intrinsic LoadAttr(attr::MonStgElt, inp::MonStgElt, obj::Any) -> Any
    {Load a single attribue}
    // Decomposition is a bit different for gps_crep and gps_zrep/gps_qrep
    if inp eq "\\N" then
        return None();
    elif attr in TextCols then
        return inp;
    elif attr in IntegerCols or attr in SmallintCols or attr in BigintCols or attr in NumericCols then
        return StringToInteger(inp);
    elif attr in BoolCols then
        return LoadBool(inp);
    elif attr in JsonbCols then
        return LoadJsonb(inp);
    elif attr in IntegerListCols or attr in SmallintListCols or attr in NumericListCols then
        return LoadIntegerList(inp);
    elif attr in TextListCols then
        return LoadTextList(inp);
    elif attr in EltCols then
        return LoadElt(inp, GetGrp(obj));
    elif attr in EltListCols then
        return LoadEltList(inp, GetGrp(obj));
    //elif attr in QuotListCols then
    //    return LoadEltList(inp, GetQuot(obj));
    elif attr in SubgroupCols then
        if attr eq "sub1" then
            G := Get(obj, "G1");
        elif attr eq "sub2" then
            G := Get(obj, "G2");
        else
            G := GetGrp(obj);
        end if;
        return LookupSubgroup(G, inp);
    elif attr in SubgroupListCols then
        return LoadSubgroupList(GetGrp(obj), inp);
    else
        error Sprintf("Unknown attribute %o", attr);
    end if;
end intrinsic;
intrinsic SaveAttr(attr::MonStgElt, val::Any, obj::Any) -> MonStgElt
    {Save a single attribute}
//"Save",attr, val, obj;
    if Type(val) eq NoneType then
        return "\\N";
    elif attr in TextCols then
        return val;
    elif attr in IntegerCols or attr in SmallintCols or attr in BigintCols or attr in NumericCols then
        return IntegerToString(val);
    elif attr in BoolCols then
        return SaveBool(val);
    elif attr in JsonbCols then
        return SaveJsonb(val);
    elif attr in IntegerListCols or attr in SmallintListCols or attr in NumericListCols then
        return SaveIntegerList(val);
    elif attr in TextListCols then
        return SaveTextList(val);
    elif attr in EltCols then
        return SaveElt(val, GetGrp(obj));
    elif attr in EltListCols then
        return SaveEltList(val, GetGrp(obj));
    elif attr in SubgroupCols then
        if attr eq "sub1" then
            G := Get(obj, "G1");
        elif attr eq "sub2" then
            G := Get(obj, "G2");
        else
            G := GetGrp(obj);
        end if;
        return LookupSubgroupLabel(G, val);
    elif attr in SubgroupListCols then
        return SaveSubgroupList(val, GetGrp(obj));
    else
        error Sprintf("Unknown attribute %o", attr);
    end if;
end intrinsic;

intrinsic SetGrp(G::LMFDBGrp)
    {Set the MagmaGrp attribute using data included in other attributes}
    if HasAttribute(G, "pc_code") and HasAttribute(G, "order") then
        G`MagmaGrp := SmallGroupDecoding(G`pc_code, G`order);
    elif HasAttribute(G, "perm_gens") and HasAttribute(G, "transitive_degree") then
        G`MagmaGrp := PermutationGroup<G`transitive_degree | G`perm_gens>;
    // TODO: Add matrix group case, use EltRep to decide which data to reconstruct from
    end if;
end intrinsic;

intrinsic LoadGrp(line::MonStgElt, attrs::SeqEnum : sep:="|") -> LMFDBGrp
    {Load an LMFDBGrp from a row of a file, setting stored attributes correctly}
    data := Split(line, sep: IncludeEmpty := true);
    error if #data ne #attrs, "Wrong size data line";
    G := New(LMFDBGrp);
    for i in [1..#data] do
        attr := attrs[i];
        G``attr := LoadAttr(attr, data[i], G);
    end for;
    SetGrp(G); // set MagmaGrp based on stored attributes.  Need to change the order: some attributes require presence of MagmaGrp.
    return G;
end intrinsic;

intrinsic TransitiveLMFDBGrp(n::RngIntElt, t::RngIntElt) -> LMFDBGrp
{}
    G := NewLMFDBGrp(TransitiveGroup(n, t), "TEST.1");
    AssignBasicAttributes(G);
    return G;
end intrinsic;

intrinsic TestTransitive(n::RngIntElt, cnt::RngIntElt)
{}
    M := NumberOfTransitiveGroups(n);
    for x in [1..cnt] do
        t := Random(1,M);
        printf "%oT%o\n", n, t;
        G := TransitiveLMFDBGrp(n, t);
        s := SaveLMFDBObject(G);
    end for;
end intrinsic;

intrinsic DefaultAttributes(c::Cat) -> SeqEnum
    {List of attributes that should be saved to disc for postgres}
    if c eq LMFDBGrp then
        defaults := ["Agroup", "Zgroup"]; // need transitive_degree, elt_rep_type early
    else
        defaults := [];
    end if;
    all_attrs := GetAttributes(c);
    for attr in all_attrs do
        if attr in defaults then continue; end if;
        // Blacklist attributes that shouldn't be included
        blacklist := [
                      // Temporary attributes (used to help divide up the computation into multiple jobs)
                      "charc_center_gens",
                      "charc_centers",
                      "charc_kernel_gens",
                      "charc_kernels",
                      "conj_centralizer_gens",
                      "conj_centralizers",
                      "easy_rank",
                      "backup_solvability_type",

                      // Deprecated attributes
                      "elt_rep_type",
                      "pc_code",
                      "perm_gens",
                      "smallrep",
                      "gens_used",
                      "finite_matrix_group",

                      // Group attributes

                      // Subgroup attributes
                      "alias_spot",
                      "aut_counter",
		      "extension_counter"
		      //  "diagram_x", returns 0 now
		      //"generators",
		      //"standard_generators"

                      // Conjugacy class attributes
                      //"representative" // Need to be able to encode GrpPCElts - DR


                      // This attributes are TEMPORARILY blacklisted while we try to figure out
                      // which are difficult for large groups
/*                      "transitive_degree", // should be set in advance for the actual transitive groups
                      "almost_simple", // NormalSubgroups -> Subgroups
                      "aut_group", // Sometimes MagmaAutGroup is slow
                      "aut_order", // Sometimes MagmaAutGroup is slow
                      "central_product", // NormalSubgroups -> Subgroups
                      "central_quotient", // can't take large quotients or identify large groups
                      "commutator_count", // Don't have a character table
                      "commutator_label", // CommutatorSubgroup was slow AND can't identify large groups
                      "complete", // Requires outer_order
                      "composition_factors", // Can't compute label for large factors
                      "composition_length", // Current implementation calls composition_factors
                      "direct_factorization", // Needs NormalSubgroups -> Subgroups, also recursive in an unfortunate way
                      "direct_product", // NormalSubgroups -> Subgroups
                      "eulerian_function", // hopeless: needs full subgroup lattice with mobius function
                      "factors_of_aut_order", // Sometimes MagmaAutGroup is slow
                      "faithful_reps", // can be slow, though usually finishes in a few seconds
                      "frattini_label", // Can't label large groups
                      "frattini_quotient", // can't take large quotients or identify large groups
                      "gens_used", // didn't call RePresent
                      "hash", // should get set in advance since we've already computed it
                      "monomial", // requires character table except in easy cases
                      "name", // GroupName can be very slow
                      "number_autjugacy_classes", // CCAutCollapse -> Holomorph
                      "number_characteristic_subgroups", // supposed to be set in SubGrpLstAut
                      "number_divisions", // ConjugacyClasses does more than just compute this
                      "number_normal_subgroups", // supposed to be set in SubGrpLstAut
                      "number_subgroup_autclasses", // supposed to be set in SubGrpLstAut
                      "number_subgroup_classes", // supposed to be set in SubGrpLstAut
                      "number_subgroups", // supposed to be set in SubGrpLstAut
                      "outer_group", // Sometimes MagmaAutGroup is slow
                      "outer_order", // Sometimes MagmaAutGroup is slow
                      "pc_code", // Need to switch to a PC group for transitive groups (but RePresent will probably be infeasible)
                      "quasisimple", // Can't quotient by center since quotient is too large
                      "rational", // Rational character table can be slow even if few characters.  Example: 44T1485 and 44T1538 took about a minute each
                      "schur_multiplier", // pMultiplicator: Cohomology failed
                      "semidirect_product", // Subgroups
                      "solvability_type", // Can fail on monomial
                      "smallrep", // faithful_reps None
                      "tex_name", // GroupName can be very slow
                      "wreath_data", // IsWreathProduct is slow
                      "wreath_product" // IsWreathProduct is slow*/
                      ];

        greylist := [
	     // Attributes which return none and need to be worked on later

                     // Subgroup attributes
                     "quotient_fusion",
                     "subgroup_fusion",
                     "generator_images"

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
    saved_attrs := [];
    //vprint User1: "***", Type(G);
    for attr in attrs do
        // "Attr", attr;
        //vprint User1: attr;
        t := Cputime();
        try
            val := Get(G, attr);
        catch e
            if assigned e`Traceback then
                print e`Traceback;
            end if;
            print "error saving", attr;
            val := None();
        end try;
        saved := SaveAttr(attr, val, G);
        t := Cputime(t);
        //if t gt 0.1 then
        //    vprintf User1: "%o time: %.3o\n", attr, t;
        //end if;
        if Type(saved) ne MonStgElt then
            print attr, Type(SaveAttr(attr, Get(G, attr), G));
        end if;
        Append(~saved_attrs, saved);
    end for;
//"Saving";
    return Join(saved_attrs, sep);
end intrinsic;

intrinsic AttrType(attr::MonStgElt) -> MonStgElt
    {Type of a single attribute}
//"Save",attr, val, obj;
    if attr in TextCols then
        return "text";
    elif attr in IntegerCols then
        return "integer";
    elif attr in SmallintCols then
        return "smallint";
    elif attr in BigintCols then
        return "bigint";
    elif attr in NumericCols then
        return "numeric";
    elif attr in BoolCols then
        return "boolean";
    elif attr in JsonbCols then
        return "jsonb";
    elif attr in IntegerListCols then
        return "integer[]";
    elif attr in SmallintListCols then
        return "smallint[]";
    elif attr in NumericListCols then
        return "numeric[]";
    elif attr in TextListCols then
        return "text[]";
    elif attr in EltCols then
        return "numeric";
    elif attr in EltListCols then
        return "numeric[]";
    elif attr in SubgroupCols then
        return "text";
    elif attr in SubgroupListCols then
        return "text[]";
    else
        error Sprintf("Unknown attribute %o", attr);
    end if;
end intrinsic;

intrinsic WriteHeaders(typ::Any : attrs:=[], sep:="|", filename:="")
{Write a file with headers for one of our types}
    if attrs eq [] then
        attrs := DefaultAttributes(typ);
    end if;
    if filename eq "" then
        filename:=Sprintf("%o.header", typ);
    end if;
    s1:=Join([attr  : attr in attrs], sep);
    s2:=Join([AttrType(attr)  : attr in attrs], sep);
    write(filename, s1 * "\n"*s2*"\n": rewrite:=true);
end intrinsic;

intrinsic PrintData(G::LMFDBGrp: sep:="|") -> Tup
    {}
    return <[SaveLMFDBObject(G: sep:=sep)],
            [SaveLMFDBObject(H: sep:=sep) : H in Get(G, "Subgroups")],
            [SaveLMFDBObject(cc: sep:=sep) : cc in Get(G, "ConjugacyClasses")],
            [SaveLMFDBObject(cr: sep:=sep) : cr in Get(G, "CCCharacters")],
            [SaveLMFDBObject(cr: sep:=sep) : cr in Get(G, "QQCharacters")]>;
end intrinsic;

intrinsic PrintGLnData(G::LMFDBGrp: sep:="|") -> Tup
    {}
    qreps := Get(G, "QQReps");
    creps := Get(G, "CCReps");
    if HasAttribute(G, "QQRepsAsCC") then
        other:= G`QQRepsAsCC;
        creps := creps cat other;
    end if;
    return <[SaveLMFDBObject(qr: sep:=sep) : qr in qreps],
            [SaveLMFDBObject(cr: sep:=sep) : cr in creps]>;
end intrinsic;

intrinsic WriteByTmpHeader(G::Any, filename::MonStgElt, header::MonStgElt: sep:="|")
{}
    code, attrs := Explode(Split(Read(header * ".tmpheader"), "\n"));
    attrs := Split(attrs, sep);
    s := code * SaveLMFDBObject(G: attrs:=attrs, sep:=sep);
    PrintFile(filename, s);
end intrinsic;

intrinsic Preload(G::LMFDBGrp : sep:="|")
{Load attributes from DATA/preload/label}
    data := "";
    havedata, F := OpenTest("DATA/preload/" * G`label, "r");
    if havedata then
        header, data := Explode(Split(Read(F), "\n"));
        header := Split(header, sep);
        data := Split(data, sep: IncludeEmpty := true);
        assert #header eq #data;
        for i in [1..#data] do
            attr := header[i];
            G``attr := LoadAttr(attr, data[i], G);
        end for;
    end if;
end intrinsic;

intrinsic ReportStart(G::LMFDBGrp, job::MonStgElt) -> FldReElt
{}
    msg := "Starting " * job;
    System("mkdir -p DATA/timings/");
    PrintFile("DATA/timings/" * G`label, msg);
    vprint User1: msg;
    return Cputime();
end intrinsic;

intrinsic ReportEnd(G::LMFDBGrp, job::MonStgElt, t0::FldReElt)
{}
    msg := Sprintf("Finished %o in %o", job, Cputime() - t0);
    System("mkdir -p DATA/timings/");
    PrintFile("DATA/timings/" * G`label, msg);
    vprint User1: msg;
end intrinsic;
