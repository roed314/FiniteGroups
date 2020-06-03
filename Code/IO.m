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
def rank(self):
    r"""
    Return the rank of ``self`` in the lexicographic ordering on the
    symmetric group to which ``self`` belongs.

    EXAMPLES::

        sage: Permutation([1,2,3]).rank()
        0
        sage: Permutation([1, 2, 4, 6, 3, 5]).rank()
        10
        sage: perms = Permutations(6).list()
        sage: [p.rank() for p in perms] == list(range(factorial(6)))
        True
    """
    n = len(self)

    factoradic = self.to_lehmer_code()

    #Compute the index
    rank = 0
    for i in reversed(range(0, n)):
        rank += factoradic[n-1-i]*factorial(i)

    return rank
*/
intrinsic LehmerCodeToRank(lehmer::SeqEnum) -> RngIntElt
  {Convert Lehmer code to integer}
  rank := 0;
  n := #lehmer;
  for i := n-1 to 0 by -1 do
    rank +:= lehmer[n-i]*Factorial(i);
  end for;
  return rank;
end intrinsic;
/*
#Find the factoradic of rank
    factoradic = [None] * n
    for j in range(1,n+1):
        factoradic[n-j] = Integer(rank % j)
        rank = int(rank) // j

    return from_lehmer_code(factoradic, Permutations(n))
*/
intrinsic RankToLehmerCode(x::RngIntElt, n::RngIntElt) -> SeqEnum
  {Returns the Lehmer code for rank x}
  lehmer := [];
  for j in [1..n] do
    Append(~lehmer, x mod j);
    //Insert(~lehmer, 1, x mod j);
    x := x div j;
  end for;
  Reverse(~lehmer);
  return lehmer;
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
    return LehmerCodeToPermutation(RankToLehmerCode(x,n));
end intrinsic;

intrinsic LoadPerms(inp::MonStgElt, n::RngInt) -> SeqEnum
    {}
    return [DecodePerm(elt, n) : elt in LoadIntegerList(inp)];
end intrinsic;
intrinsic SavePerms(out::SeqEnum) -> MonStgElt
    {}
    return SaveIntegerList([EncodePerm(o) : o in out]);
end intrinsic;

intrinsic LoadAttr(attr::MonStgElt, inp::MonStgElt, c::Cat) -> Any
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
intrinsic SaveAttr(attr::MonStgElt, val::Any, c::Cat, finalize::BoolElt) -> MonStgElt
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
