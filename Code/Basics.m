intrinsic GetBasicAttributesGrp() -> Any
  {Outputs SeqEnum of basic attributes}
  return [
    "Order",
    "Exponent",
    "IsAbelian",
    "IsCyclic",
    "IsSolvable",
    "IsNilpotent",
    //"IsMetaAbelian",
    "IsSimple",
    //"IsSuperSolvable",
    "IsPerfect",
    "Center",
    //"Commutator",
    //"FrattiniSubgroup",
    "Radical",
    //"Socle",
    "AutomorphismGroup",
    "NilpotencyClass",
    "Ngens",
    "DerivedSeries",
    "DerivedLength",
    "ChiefSeries",
    "LowerCentralSeries",
    "UpperCentralSeries",
    //"PrimaryAbelianInvariants", // only if abelian
    //"IsWreathProduct", // only for GrpPerm
    "CompositionFactors"
    ];
end intrinsic;

intrinsic AssignBasicAttributes(G::LMFDBGrp) -> Any
  {Assign basic attributes. G`MagmaGrp must already be assigned.}
  attrs := GetBasicAttributesGrp();
  GG := G`MagmaGrp;
  for attr in attrs do
    eval_str := Sprintf("return %o(GG);", attr);
    G``attr := eval eval_str;
  end for;
  //G`IsSuperSolvable := IsSupersoluble(GG); // thanks a lot Australia! :D; only for GrpPC...
  return Sprintf("Basic attributes assigned to %o", G);
end intrinsic;

intrinsic GetBasicAttributesSubGrp(pair::Boolean) -> Any
  {Outputs SeqEnum of basic attributes}
  if pair then
    return [
      "IsNormal",
      "Core",
      "Normalizer",
      "Centralizer",
      "NormalClosure",
      "IsCentral"
      ];
  else
    return [
      "IsCyclic",
      "IsAbelian",
      "IsPerfect"
      ];
  end if;
end intrinsic;

intrinsic AssignBasicAttributes(H::LMFDBSubGrp) -> Any
  {Assign basic attributes. G`MagmaSubGrp must already be assigned.}
  GG := H`MamgaAmbient;
  HH := H`MagmaSubGrp;
  attrs := GetBasicAttributesSubGrp(true);
  for attr in attrs do
    eval_str := Sprintf("return %o(GG, HH)", attr);
    H``attr := eval eval_str;
  end for;
  attrs := GetBasicAttributesSubGrp(false);
  for attr in attrs do
    eval_str := Sprintf("return %o(HH)", attr);
    H``attr := eval eval_str;
  end for;
  return Sprintf("Basic attributes assigned to %o", H);
end intrinsic;
