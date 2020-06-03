TextCols := ["Label", "OldLabel", "Name", "TexName"];

IntegerCols := ["Order", "Counter", "Exponent", "pGroup", "Elementary", "Hyperelementary", "Rank", "Numeric", "Center", "Commutator", "CommutatorCount", "Frattini", "Fitting", "Radical", "Socle", "TransitiveDegree", "TransitiveSubgroup", "SmallRep", "AutOrder", "OuterOrder", "NilpotencyClass", "Ngens", "PCCode", "NumberConjugacyClasses", "NumbeSubgroupClasses", "NumberSubgroups", "NumberNormalSubgroups", "NumberCharacteristicSubgroups", "DerivedLength", "PerfectCore", "EltRepType", "SubgroupIndexBound", "CompositionLength"];

IntegerListCols := ["FactorsOfOrder", "FactorsOfAutOrder", "DerivedSeries", "ChiefSeries", "LowerCentralSeries", "UpperCentralSeries", "PrimaryAbelianInvariants", "SmithAbelianInvariants", "SchurMultiplier", "OrderStats", "PermGens", "CompositionFactors"];

intrinsic LoadIntegerList(inp::MonStgElt) -> RngInt
    {}
    assert inp[1] eq "{" && inp[#inp-1] eq "}";
    return [StringToInteger(elt) : elt in Split(Substring(inp, 2, #inp-2), ",")];
end intrinsic;
intrinsic SaveIntegerList(out::SeqEnum) ->  MonStgElt
    {}
    return "{" * Join([IntegerToString(o) : o in out], ",") * "}";
end intrinsic;

intrinsic EncodePerm(x::GrpPermElt) -> RngInt
    {}
    n := Degree(Parent(x));
    // TODO: Implement to_lehmer_code from sage/combinat/permutation.py
end intrinsic;
intrinsic DecodePerm(x::RngInt, n::RngInt) -> GrpPermElt
    {}
    // TODO: Implement from_lehmer_code from sage/combinat/permutation.py
end intrinsic;
intrinsic LoadPerms(inp::MonStgElt, n::RngInt) -> SeqEnum
    {}
    return [DecodePerm(elt, n) : elt in LoadIntegerList(inp)];
end instrinsic;
intrinsic SavePerms(out::SeqEnum) -> MonStgElt
    {}
    return SaveIntegerList([EncodePerm(o) : o in out]);
end intrinsic;

intrinsic LoadGrpAttr(attr::MonStgElt, inp::MonStgElt) -> Any
    {Load a group with its attributes}
    if attr in TextCols then
        return inp;
    else if attr in IntegerCols then
        return StringToInteger(inp);
    else if attr in IntegerListCols then
        return LoadIntegerList(inp);
    else if attr in SubgroupCols then
        return [];
    end if;
end intrinsic;

intrinsic SetGrp(G::LMFDBGrp)
    {Set the MagmaGrp attribute using data included in other attributes}
    if HasAttribute(G, "PCCode") && HasAttribute(G, "Order") then
        G`MagmaGrp := SmallGroupDecoding(G`PCCode, G`Order);
    else if HasAtribute(G, "PermGens") && HasAttribute(G, "TransitiveDegree") then
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
            G``attr := LoadGrpAttr(attr, data[i]);
        end if;
    end for;
    SetGrp(G); // set MagmaGrp based on stored attributes
    return G;
end intrinsic;

