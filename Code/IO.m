TextCols := ["Label", "OldLabel", "Name", "TexName"];

IntegerCols := ["Order", "Counter", "Exponent", "pGroup", "Elementary", "Hyperelementary", "Rank", "Numeric", "Center", "Commutator", "CommutatorCount", "Frattini", "Fitting", "Radical", "Socle", "TransitiveDegree", "TransitiveSubgroup", "SmallRep", "AutOrder", "OuterOrder", "NilpotencyClass", "Ngens", "PCCode", "NumberConjugacyClasses", "NumbeSubgroupClasses", "NumberSubgroups", "NumberNormalSubgroups", "NumberCharacteristicSubgroups", "DerivedLength", "PerfectCore", "EltRepType", "SubgroupIndexBound", "CompositionLength"];

IntegerListCols := ["FactorsOfOrder", "FactorsOfAutOrder", "DerivedSeries", "ChiefSeries", "LowerCentralSeries", "UpperCentralSeries", "PrimaryAbelianInvariants", "SmithAbelianInvariants", "SchurMultiplier", "OrderStats", "PermGens", "CompositionFactors"];

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
    if HasAttribute(G, "PCCode") and HasAttribute(G, "Order") then
        G`MagmaGrp := SmallGroupDecoding(G`PCCode, G`Order);
    elif HasAtribute(G, "PermGens") and HasAttribute(G, "TransitiveDegree") then
        G`MagmaGrp := PermutationGroup<G`TransitiveDegree | G`PermGens>;
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

intrinsic SaveGrpAttributes() -> SeqEnum
  {}
  GrpAttrs := GetAttributes(LMFDBGrp);
  DefaultAttrs := [];
  for attr in GrpAttrs do
    if Regexp("^[a-z]+", attr) then
      Append(~DefaultAttrs, attr);
    end if;
  end for;
  return DefaultAttrs;
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
