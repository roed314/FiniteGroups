

intrinsic LoadIntegerList(inp::MonStgElt) -> RngInt
    {}
    assert inp[1] eq "{" && inp[#inp-1] eq "}";
    return [StringToInteger(elt) : elt in Split(Substring(inp, 2, #inp-2), ",")]

intrinsic LoadGrpAttr(attr::MonStgElt, inp::MonStgElt) -> Any
    {}
    if attr in ["Label", "OldLabel", "Name", "TexName"] then
        return inp;
    else if attr in ["Order", "Counter", "Exponent", "pGroup", "Elementary", "Hyperelementary", "Rank", "Numeric", "Center", "Commutator", "CommutatorCount", "Frattini", "Fitting", "Radical", "Socle", "TransitiveDegree", "TransitiveSubgroup", "SmallRep", "AutOrder", "OuterOrder", "NilpotencyClass", "Ngens", "PCCode", "NumberConjugacyClasses", "NumbeSubgroupClasses", "NumberSubgroups", "NumberNormalSubgroups", "NumberCharacteristicSubgroups", "DerivedLength", "PerfectCore", "EltRepType", "SubgroupIndexBound", "CompositionLength"] then
        return StringToInteger(inp);
    else if attr in ["FactorsOfOrder", "FactorsOfAutOrder", "DerivedSeries", "ChiefSeries", "LowerCentralSeries", "UpperCentralSeries", "PrimaryAbelianInvariants", "SmithAbelianInvariants", "SchurMultiplier", "OrderStats", "PermGens", "CompositionFactors"] then
        return LoadIntegerList(inp);
    else if attr in [] then
        return [];
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

