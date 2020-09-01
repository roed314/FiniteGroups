TextCols := ["abelian_quotient", "acted", "actor", "ambient", "aut_group", "bravais_class", "c_class", "center_label", "central_quotient", "commutator_label", "coset_action_label", "crystal_symbol", "factor1", "factor2", "family", "frattini_label", "frattini_quotient", "group", "image", "knowl", "label", "magma_cmd", "name", "old_label", "outer_group", "product", "proj_label", "projective_image", "q_class", "quotient", "quotient_action_image", "subgroup", "tex_name", "q_character","carat_label"];

IntegerCols := ["alias_spot", "ambient_order", "arith_equiv", "aut_counter", "aut_order", "auts", "cdim", "commutator_count", "composition_length", "conjugacy_class_count", "count", "counter", "counter_by_index", "cyc_order_mat", "cyc_order_traces", "cyclotomic_n", "degree", "derived_length", "diagram_x", "dim", "elementary", "elt_rep_type", "eulerian_function", "exponent", "extension_counter", "hall", "hyperelementary", "indicator", "mobius_function", "multiplicity", "n", "ngens", "nilpotency_class", "number_characteristic_subgroups", "number_conjugacy_classes", "number_normal_subgroups", "number_subgroup_classes", "number_subgroups", "order", "outer_order", "parity", "pc_code", "pgroup", "priority", "q", "qdim", "quotient_action_kernel", "quotient_order", "quotients_complenetess", "rank", "rep", "schur_index", "sibling_completeness", "size", "smallrep", "subgroup_index_bound", "subgroup_order", "sylow", "t", "transitive_degree"];

TextListCols := ["composition_factors", "direct_factorization", "special_labels"];

IntegerListCols := ["contained_in", "contains", "cycle_type", "denominators", "factors_of_aut_order", "factors_of_order", "faithful_reps", "order_stats", "powers", "primary_abelian_invariants", "schur_multiplier", "smith_abelian_invariants", "subgroup_fusion", "nt","qvalues","field","trace_field", "gens_used"];

BoolCols := ["Agroup", "Zgroup", "abelian", "all_subgroups_known", "almost_simple", "central", "central_product", "characteristic", "cyclic", "direct", "direct_product", "faithful", "finite_matrix_group", "indecomposible", "irreducible", "maximal", "maximal_normal", "maximal_subgroups_known", "metabelian", "metacyclic", "minimal", "minimal_normal", "monomial", "nilpotent", "normal", "normal_subgroups_known", "outer_equivalence", "perfect", "prime", "primitive", "quasisimple", "rational", "semidirect_product", "simple", "solvable", "split", "stem", "subgroup_inclusions_known", "supersolvable", "sylow_subgroups_known", "wreath_product", "standard_generators"];

// creps has a gens which is not integer[]
JsonbCols := ["quotient_fusion","decomposition","traces", "gens","values"];

PermsCols := ["perm_gens"];
SubgroupCols := ["centralizer", "kernel", "core", "center", "normal_closure", "normalizer", "sub1", "sub2"];
SubgroupListCols := ["complements"];

EltCols := ["representative"];
EltListCols := ["generators"];
//QuotListCols := ["generator_images"];

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


intrinsic LoadPerms(inp::MonStgElt, n::RngInt) -> SeqEnum
    {}
    return [DecodePerm(elt, n) : elt in LoadIntegerList(inp)];
end intrinsic;
intrinsic SavePerms(out::SeqEnum) -> MonStgElt
    {}
    return SaveIntegerList([EncodePerm(o) : o in out]);
end intrinsic;

intrinsic LoadElt(inp::MonStgElt, G::LMFDBGrp) -> Any
    {}
    // For PCGroups, we have loaded the group from its pc_code, so we don't need
    // to invert the OptimizedIso
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
        // We first apply the isomorphism to a group with a nicer human-readable presentation
        opt := G`OptimizedIso(out);
        n := 0;
        v := ElementToSequence(opt);
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
    elif attr in IntegerCols then
        return StringToInteger(inp);
    elif attr in BoolCols then
        return LoadBool(inp);
    elif attr in JsonbCols then
        return LoadJsonb(inp);
    elif attr in IntegerListCols then
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
    elif attr in IntegerCols then
        return IntegerToString(val);
    elif attr in BoolCols then
        return SaveBool(val);
    elif attr in JsonbCols then
        return SaveJsonb(val);
    elif attr in IntegerListCols then
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
    if HasAttribute(G, "pccode") and HasAttribute(G, "order") then
        G`MagmaGrp := SmallGroupDecoding(G`pccode, G`order);
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

intrinsic DefaultAttributes(c::Cat) -> SeqEnum
    {List of attributes that should be saved to disc for postgres}
    if c eq LMFDBGrp then
        defaults := ["Agroup", "Zgroup", "elt_rep_type", "transitive_degree"]; // need transitive_degree, elt_rep_type early
    else
        defaults := [];
    end if;
    all_attrs := GetAttributes(c);
    for attr in all_attrs do
        if attr in defaults then continue; end if;
        // Blacklist attributes that aren't working
        blacklist := [
                      // Group attributes
                      //"eulerian_function",
                      //"rank",
                      //"mobius_function_known",
    
                      // Subgroup attributes
                      "alias_spot",
                      "aut_counter",
                      "mobius_function",
		      "extension_counter",
		      //  "diagram_x", returns 0 now
		      "generators",
		      "standard_generators"

                      // Conjugacy class attributes
                      //"representative" // Need to be able to encode GrpPCElts - DR
                      ];

        greylist := [
	     // Attributes which return none and need to be worked on later

                     // Group attributes
                     "finite_matrix_group",

                     // Subgroup attributes
                     "conjugacy_class_count",
                     "quotient_action_image",
                     "quotient_action_kernel",
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
    vprint User1, 2: "***", Type(G);
    for attr in attrs do
        // "Attr", attr;
        vprint User1, 2: attr;
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
    elif attr in BoolCols then
        return "boolean";
    elif attr in JsonbCols then
        return "jsonb";
    elif attr in IntegerListCols then
        return "integer[]";
    elif attr in TextListCols then
        return "text[]";
    elif attr in PermsCols then
        return "integer[]";
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
