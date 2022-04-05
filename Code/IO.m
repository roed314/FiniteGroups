TextCols := ["abelian_quotient", "acted", "actor", "ambient", "aut_group", "bravais_class", "c_class", "center_label", "central_quotient", "commutator_label", "coset_action_label", "crystal_symbol", "factor1", "factor2", "family", "frattini_label", "frattini_quotient", "group", "image", "knowl", "label", "short_label", "aut_label", "magma_cmd", "name", "old_label", "outer_group", "product", "proj_label", "projective_image", "q_class", "quotient", "quotient_action_image", "subgroup", "tex_name", "q_character", "carat_label", "subgroup_tex", "ambient_tex", "quotient_tex", "weyl_group", "aut_weyl_group", "quotient_action_kernel"];

IntegerCols := ["alias_spot", "arith_equiv", "aut_counter", "auts", "cdim", "commutator_count", "counter", "counter_by_index", "cyc_order_mat", "cyc_order_traces", "cyclotomic_n", "degree", "diagram_x", "diagram_aut_x", "dim", "elementary", "exponent", "extension_counter", "hyperelementary", "indicator", "multiplicity", "n", "number_characteristic_subgroups", "number_conjugacy_classes", "number_autjugacy_classes", "number_divisions", "number_normal_subgroups", "number_subgroup_classes", "number_subgroup_autclasses", "number_subgroups", "parity", "priority", "q", "qdim", "quotients_complenetess", "rep", "schur_index", "sibling_completeness", "size", "smallrep", "t", "transitive_degree", "hash"];
SmallintCols := ["elt_rep_type", "composition_length", "derived_length", "ngens", "nilpotency_class", "pgroup", "sylow", "rank", "subgroup_index_bound", "solvability_type"];
BigintCols := ["mobius_sub", "mobius_quo"];
NumericCols := ["hall", "eulerian_function", "order", "aut_order", "outer_order", "ambient_order", "subgroup_order", "quotient_order", "quotient_action_kernel_order", "aut_centralizer_order", "aut_weyl_index", "count", "conjugacy_class_count", "pc_code", "core_order", "normalizer_index", "centralizer_order"];

TextListCols := ["composition_factors", "special_labels", "wreath_data"];

IntegerListCols := ["cycle_type", "denominators", "factors_of_aut_order", "faithful_reps", "powers", "primary_abelian_invariants", "schur_multiplier", "smith_abelian_invariants", "subgroup_fusion", "nt","qvalues","trace_field"];
SmallintListCols := ["factors_of_order", "gens_used", "exponents_of_order"];
NumericListCols := ["order_stats","field"];

BoolCols := ["Agroup", "Zgroup", "abelian", "all_subgroups_known", "almost_simple", "central", "central_product", "characteristic", "cyclic", "direct", "direct_product", "faithful", "finite_matrix_group", "indecomposible", "irreducible", "maximal", "maximal_normal", "maximal_subgroups_known", "metabelian", "metacyclic", "minimal", "minimal_normal", "monomial", "nilpotent", "normal", "normal_subgroups_known", "outer_equivalence", "perfect", "prime", "primitive", "quasisimple", "rational", "semidirect_product", "simple", "solvable", "split", "stem", "subgroup_inclusions_known", "supersolvable", "sylow_subgroups_known", "wreath_product", "standard_generators", "quotient_cyclic", "quotient_abelian", "quotient_solvable", "proper", "complete"];

// creps has a gens which is not integer[]
JsonbCols := ["quotient_fusion","decomposition","traces", "gens","values","direct_factorization"];

PermsCols := ["perm_gens"];
SubgroupCols := ["centralizer", "kernel", "core", "center", "normal_closure", "normalizer", "sub1", "sub2"];
SubgroupListCols := ["complements", "contains", "contained_in"];

EltCols := ["representative"];
EltListCols := ["generators"];
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
    ReplaceString(~out_str, ["[","]"," ","\n"],["{","}","", ""]);
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
    return "{" * Join(out, ",") * "}";
end intrinsic;


strgsave:=function(strg);
   if Type(strg) eq MonStgElt then
      return "\"" cat strg cat "\"";
   else
      return strg;
   end if;
end function;

listprocess:=function(L);
   newout:="[ ";
   for i in [1..#L] do
      subL:=L[i];
      if Type(subL) eq SeqEnum or Type(subL) eq List or Type(subL) eq Tup then
         out_piece:=$$(subL);   
      else 
         out_piece:=Sprint(strgsave(subL));  
      end if;
      if i ne #L then
         out_piece:=out_piece cat ", ";
      end if;
      newout:=newout cat out_piece;
   end for;
   newout  := newout cat " ]";
   return newout;
end function;


removestars:=function(L);
   for i in [1..#L] do
      if Type(L[i]) eq List then
          L[i]:=$$(L[i]);
      end if;
   end for;
   typeL:={Type(L[i]) : i in [1..#L]};
   if #typeL eq 1 then
      newL:=[L[i] : i in [1..#L]];
   else 
      newL:=L;
   end if;
   return newL;
end function;

intrinsic LoadJsonb(inp::MonStgElt) -> List
    {assuming lists of strings or integers only}
    assert inp[1] eq "[" and inp[#inp] eq "]";
    ReplaceString(~inp,["[","]"],["[*","*]"]);
    magma_inp:=eval inp;
    return removestars(magma_inp);
end intrinsic;
intrinsic SaveJsonb(out::List) ->  MonStgElt
{assuming list of strings or integers (or embedded lists of these) only}
    return listprocess(out);
end intrinsic;
intrinsic SaveJsonb(out::SeqEnum[List]) ->  MonStgElt
{assuming list of strings or integers (or embedded lists of these) only}
    return listprocess(out);
end intrinsic;
intrinsic SaveJsonb(out::SeqEnum) ->  MonStgElt
{assuming list of strings or integers (or embedded lists of these) only}
    return listprocess(out);
end intrinsic;


intrinsic LoadPerms(inp::MonStgElt, n::RngIntElt) -> SeqEnum
    {}
    return [DecodePerm(elt, n) : elt in LoadIntegerList(inp)];
end intrinsic;
intrinsic SavePerms(out::SeqEnum) -> MonStgElt
    {}
    return SaveIntegerList([EncodePerm(o) : o in out]);
end intrinsic;

intrinsic LoadElt(inp::MonStgElt, G::LMFDBGrp) -> Any
    {}
    // For PCGroups, we have loaded the group from its pc_code since we're using a different presentation
    GG := G`MagmaGrp;
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
        return GG!DecodePerm(inp, n);
    else
        error "Other group types not yet supported";
    end if;
end intrinsic;
intrinsic SaveElt(out::Any, G::LMFDBGrp) -> MonStgElt
    {}
    GG := G`MagmaGrp;
    if Type(GG) eq GrpPC then
        n := 0;
        v := Reverse(ElementToSequence(out));
        Ps := Reverse(PCPrimes(GG));
        for i in [1..#Ps] do
            n *:= Ps[i];
            n +:= v[i];
        end for;
        return IntegerToString(n);
    elif Type(GG) eq GrpPerm then
        return IntegerToString(EncodePerm(out));
    else
        error "Other group types not yet supported";
    end if;
end intrinsic;

intrinsic LoadEltList(inp::MonStgElt, G::LMFDBGrp) -> SeqEnum
    {}
    assert inp[1] eq "{" and inp[#inp] eq "}";
    return [LoadElt(x, G) : x in Split(Substring(inp, 2, #inp-2), ",")];
end intrinsic;
intrinsic SaveEltList(out::SeqEnum, G::LMFDBGrp) -> MonStgElt
    {}
    return "{" * Join([SaveElt(x, G) : x in out], ",") * "}";
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
    elif attr in PermsCols then
        return LoadPerms(inp, Get(obj, "transitive_degree"));
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
    elif attr in PermsCols then
        return SavePerms(val);
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
    SetBigSubgroupParameters(G);
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
        // Blacklist attributes that aren't working
        blacklist := [
                      // Group attributes

                      // Subgroup attributes
                      "alias_spot",
                      "aut_counter",
		      "extension_counter",
		      //  "diagram_x", returns 0 now
		      //"generators",
		      //"standard_generators"

                      // Conjugacy class attributes
                      //"representative" // Need to be able to encode GrpPCElts - DR


                      // This attributes are TEMPORARILY blacklisted while we try to figure out
                      // which are difficult for large groups
                      "transitive_degree", // should be set in advance for the actual transitive groups
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
                      "wreath_product" // IsWreathProduct is slow
                      ];

        greylist := [
	     // Attributes which return none and need to be worked on later

                     // Group attributes
                     "finite_matrix_group",

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
    vprint User1: "***", Type(G);
    for attr in attrs do
        // "Attr", attr;
        vprint User1: attr;
        t := Cputime();
        saved := SaveAttr(attr, Get(G, attr), G);
        t := Cputime(t);
        if t gt 0.1 then
            vprintf User1: "%o time: %.3o\n", attr, t;
        end if;
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
    elif attr in PermsCols then
        return "numeric[]";
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

