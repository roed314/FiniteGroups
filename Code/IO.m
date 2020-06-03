TextCols := ["Label", "OldLabel", "Name", "TexName"];

IntegerCols := ["Order", "Counter", "Exponent", "pGroup", "Elementary", "Hyperelementary", "Rank", "Numeric", "Center", "Commutator", "CommutatorCount", "Frattini", "Fitting", "Radical", "Socle", "TransitiveDegree", "TransitiveSubgroup", "SmallRep", "AutOrder", "OuterOrder", "NilpotencyClass", "Ngens", "PCCode", "NumberConjugacyClasses", "NumbeSubgroupClasses", "NumberSubgroups", "NumberNormalSubgroups", "NumberCharacteristicSubgroups", "DerivedLength", "PerfectCore", "EltRepType", "SubgroupIndexBound", "CompositionLength"];

IntegerListCols := ["FactorsOfOrder", "FactorsOfAutOrder", "DerivedSeries", "ChiefSeries", "LowerCentralSeries", "UpperCentralSeries", "PrimaryAbelianInvariants", "SmithAbelianInvariants", "SchurMultiplier", "OrderStats", "PermGens", "CompositionFactors"];

intrinsic LoadIntegerList(inp::MonStgElt) -> SeqEnum
    {}
    assert inp[1] eq "{" and inp[#inp-1] eq "}";
    return [StringToInteger(elt) : elt in Split(Substring(inp, 2, #inp-2), ",")];
end intrinsic;
intrinsic SaveIntegerList(out::SeqEnum) ->  MonStgElt
    {}
    return "{" * Join([IntegerToString(o) : o in out], ",") * "}";
end intrinsic;

intrinsic EncodePerm(x::GrpPermElt) -> RngInt
    {return Lehmer code for permutation x}
    return LehmerCode(x);
end intrinsic;

/*
7121     p = []
7122     open_spots = list(range(1,len(lehmer)+1))
7123     for ivi in lehmer:
7124         p.append(open_spots.pop(ivi))
7125 
7126     if parent is None:
7127         parent = Permutations()
7128     return parent(p)
*/
intrinsic IntegerToLehmerCode(x::RngIntElt, n::RngIntElt) -> SeqEnum
  {Returns the Lehmer code for x as a permutation in Sym(n)}
  return false;
end intrinsic;

intrinsic LehmerCodeToPermutation(lehmer::SeqEnum) -> GrpPermElt
  {Returns permutation corresponding to Lehmer code.}
  n := #lehmer;
  lehmer := [el + 1 : el in lehmer];
  p_seq := [];
  open_spots := [1..n];
  for j in lehmer do
    Append(~p_seq, open_spots[j]);
    Remove(~open_spots,j);
  end for;
  return Sym(n)!p_seq;
end intrinsic;

intrinsic DecodePerm(x::RngInt, n::RngInt) -> GrpPermElt
    {Given Lehmer Code, return corresponding permutation}
    // TODO: Implement from_lehmer_code from sage/combinat/permutation.py
    return LehmerCodeToPermutation(IntegerToLehmerCode(x,n));
end intrinsic;

intrinsic LoadPerms(inp::MonStgElt, n::RngInt) -> SeqEnum
    {}
    return [DecodePerm(elt, n) : elt in LoadIntegerList(inp)];
end intrinsic;
intrinsic SavePerms(out::SeqEnum) -> MonStgElt
    {}
    return SaveIntegerList([EncodePerm(o) : o in out]);
end intrinsic;

intrinsic LoadAttr(attr::MonStgElt, inp::MonStgElt, cat::Cat) -> Any
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
intrinsic SaveAttr(attr::MonStgElt, val::Any, cat::Cat, finalize::BoolElt) -> MonStgElt
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
            G``attr := LoadAttr(attr, data[i], LMFDBGrp);
        end if;
    end for;
    SetGrp(G); // set MagmaGrp based on stored attributes
    return G;
end intrinsic;

intrinsic SaveGrp(G::LMFDBGrp, attrs::SeqEnum: sep:="|", finalize:=false) -> MonStgElt
    {}
    return Join([SaveAttr(attr, G``attr, LMFDBGrp, finalize) : attr in attrs], sep);
end intrinsic;
