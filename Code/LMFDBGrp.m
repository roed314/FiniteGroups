// see https://github.com/roed314/FiniteGroups/blob/master/ProposedSchema.md
declare verbose LMFDBGrp, 1;
declare type LMFDBGrp;
declare attributes LMFDBGrp:
  MagmaGrp,
  Label,
  OldLabel,
  Name,
  TeXName,
  Order,
  Counter,
  FactorsOfOrder,
  Exponent,
  IsAbelian,
  IsCyclic,
  IsSolvable,
  IsSupersolvable,
  IsNilpotent,
  IsMetacyclic,
  IsMetabelian,
  IsSimple,
  IsAlmostSimple,
  IsQuasiSimple,
  IsPerfect,
  IsMonomial,
  IsRational,
  IsZGroup,
  IsAGroup,
  pGroup,
  Elementary,
  Hyperelementary,
  Rank,
  EulerianFunction,
  Center,
  CenterLabel,
  CentralQuotient,
  Commutator,
  CommutatorLabel,
  AbelianQuotient,
  CommutatorCount,
  FrattiniSubgroup,
  FrattiniLabel,
  FrattiniQuotient,
  FittingSubgroup,
  Radical,
  Socle,
  TransitiveDegree,
  TransitiveSubgroup,
  SmallRep,
  AutOrder,
  AutomorphismGroup,
  OuterOrder,
  OuterGroup,
  FactorsOfAutOrder,
  NilpotencyClass,
  Ngens,
  PCCode,
  // TODO: check rest of these for basic attrs
  NumberOfConjugacyClasses,
  NumberOfSubgroupClasses,
  NumberOfSubgroups,
  NumberOfNormalSubgroups,
  NumberOfCharacteristicSubgroups,
  DerivedSeries,
  DerivedLength,
  PerfectCore,
  ChiefSeries,
  LowerCentralSeries,
  UpperCentralSeries,
  PrimaryAbelianInvariants,
  SmithAbelianInvariants,
  SchurMultiplier,
  OrderStats,
  EltRepType,
  PermGens,
  AllSubgroupsKnown,
  NormalSubgroupsKnown,
  MaximalSubgroupsKnown,
  SylowSubgroupsKnown,
  SubgroupInclusionsKnown,
  OuterEquivalence,
  SubgroupIndexBound,
  SylowSubgroups,
  //IsZgroup,
  //IsAgroup,
  //ModDecompUniq,
  IsWreathProduct,
  IsCentralProduct,
  IsFiniteMatrixGroup,
  IsDirectProduct,
  IsSemidirectProduct,
  CompositionFactors,
  CompositionLength;
intrinsic Print(G::LMFDBGrp)
  {Print LMFDBGrp}
  printf "LMFDBDGrp %o:\n", G`Label;
  //printf "  Name %o\n", G`Name;
  //printf "  Order %o", G`Order;
end intrinsic;

declare verbose LMFDBGrpPerm, 1;
declare type LMFDBGrpPerm;
declare attributes LMFDBGrpPerm:
  Label,
  Group,
  n,
  t,
  Order,
  Parity,
  IsAbelian,
  IsCyclic,
  IsSolvable,
  IsPrimitive,
  Auts,
  ArithmeticEquivalent,
  SiblingCompleteness,
  QuotientsCompleteness,
  SubFields,
  Quotients,
  Generators;

intrinsic Print(G::LMFDBGrpPerm)
  {Print LMFDBGrpPerm}
  printf "LMFDBDGrpPerm %o:\n", G`Label;
  printf "  Order %o", G`Order;
end intrinsic;

declare verbose LMFDBSubGrp, 1;
declare type LMFDBSubGrp;
declare attributes LMFDBSubGrp:
  MagmaAmbient, // input
  MagmaSubGrp, // input
  Label, // process
  OuterEquivalence, // input
  Counter,
  CounterByIndex,
  AutomorphismCounter,
  ExtensionCounter,
  Subgroup,
  SubgroupOrder,
  Ambient,
  AmbientOrder,
  Quotient,
  QuotientOrder,
  IsNormal,
  IsCharacteristic,
  IsCyclic,
  IsAbelian,
  IsPerfect,
  Sylow,
  Hall,
  IsMaximal,
  IsMaximalNormal,
  IsMinimal,
  IsMinimalNormal,
  IsSplit,
  Complements,
  IsDirectProduct,
  IsCentral,
  IsStem,
  Count,
  ConjugacyClassCount,
  Core,
  CosetActionLabel,
  Normalizer,
  Centralizer,
  NormalClosure,
  QuotientActionKernel,
  QuotientActionImage,
  Contains,
  ContainedIn,
  QuotientFusion,
  SubgroupFusion,
  AliasSpot,
  Generators,
  ProjectiveImage;

intrinsic Print(H::LMFDBSubGrp)
  {Print LMFDBGrp}
  printf "LMFDBDSubGrp %o:\n", H`Label;
  printf "  Group label%o\n ", H`Ambient;
  printf "  Order %o\n", H`SubgroupOrder;
  printf "  Normal? %o", H`IsNormal;
end intrinsic;

declare verbose LMFDBCtrlProd, 1;
declare type LMFDBCtrlProd;
declare attributes LMFDBCtrlProd:
  Factor1,
  Factor2,
  Sub1,
  Sub2,
  //Product,
  Label,
  AliasSpot;

intrinsic Print(P::LMFDBCtrlProd)
  {Print LMFDBCtrlProd}
  printf "LMFDBCtrlProd %o:\n", P`Label;
  printf "  Central product of %o and %o", P`Factor1, P`Factor2;
end intrinsic;

declare verbose LMFDBWrthProd, 1;
declare type LMFDBWrthProd;
declare attributes LMFDBWrthProd:
  Acted,
  Actor,
  //Product,
  Label,
  AliasSpot;

intrinsic Print(P::LMFDBWrthProd)
  {Print LMFDBWrthProd}
  printf "LMFDBWrthProd %o:\n", P`Label;
  printf " Wreath product of %o by %o", P`Acted, P`Actor;
end intrinsic;

declare verbose LMFDBRepQQ, 1;
declare type LMFDBRepQQ;
declare attributes LMFDBRepQQ:
  Label,
  Dim,
  Order,
  Group,
  CCClass,
  IsIrreducible,
  Decomposition;

intrinsic Print(Rho::LMFDBRepQQ)
  {Print LMFDBRepQQ}
  printf "LMFDBRepQQ %o:\n", Rho`Label;
  printf "  Dimension %o:\n", Rho`Dim;
  printf "  Group %o:\n", Rho`Group;
  printf "  Irreducible? %o", Rho`IsIrreducible;
end intrinsic;

declare verbose LMFDBRepZZ, 1;
declare type LMFDBRepZZ;
declare attributes LMFDBRepZZ:
  Label,
  Dim,
  Order,
  Group,
  QQClass,
  CCClass,
  BravaisClass,
  CrystalSymbol,
  IsIndecomposable,
  IsIrreducible,
  Decomposition,
  Generators;

intrinsic Print(Rho::LMFDBRepZZ)
  {Print LMFDBRepZZ}
  printf "LMFDBRepZZ %o:\n", Rho`Label;
  printf "  Dimension %o:\n", Rho`Dim;
  printf "  Group %o:\n", Rho`Group;
  printf "  Irreducible? %o", Rho`IsIrreducible;
end intrinsic;

declare verbose LMFDBRepCC, 1;
declare type LMFDBRepCC;
declare attributes LMFDBRepCC:
  Label,
  Dim,
  Order,
  Group,
  IsIrreducible,
  Decomposition,
  Indicator,
  SchurIndex,
  CyclotomicOrderMat,
  TraceField,
  CyclotomicOrderTraces,
  Denominators,
  Generators,
  Traces;

intrinsic Print(Rho::LMFDBRepCC)
  {Print LMFDBRepCC}
  printf "LMFDBRepCC %o:\n", Rho`Label;
  printf "  Dimension %o:\n", Rho`Dim;
  printf "  Group %o:\n", Rho`Group;
  printf "  Irreducible? %o", Rho`IsIrreducible;
end intrinsic;

declare verbose LMFDBRepP, 1;
declare type LMFDBRepP;
declare attributes LMFDBRepP:
  Label,
  Dim,
  q,
  IsPrime,
  Ambient,
  Counter,
  ProjectiveImage,
  Generators,
  ProjectiveImageLabel;

intrinsic Print(Rho::LMFDBRepP)
  {Print LMFDBRepP}
  printf "LMFDBRepP %o:\n", Rho`Label;
  printf "  Dimension %o:\n", Rho`Dim;
  printf "  Ambient %o:", Rho`Ambient;
end intrinsic;

declare verbose LMFDBRepPNames, 1;
declare type LMFDBRepPNames;
declare attributes LMFDBRepPNames:
  Group,
  Dim,
  q,
  Family,
  Name,
  TeXName;

intrinsic Print(s::LMFDBRepPNames)
  {Print LMFDBRepPNames}
  printf "LMFDBRepPNames %o:\n", Rho`Name;
  printf "  Dimension %o:\n", Rho`Dim;
  printf "  Group %o:", Rho`Group;
end intrinsic;

declare verbose LMFDBGrpConjCls, 1;
declare type LMFDBGrpConjCls;
declare attributes LMFDBGrpConjCls:
  Label,
  Group,
  Size,
  Counter,
  Order,
  Centralizer,
  Powers,
  Representative;

intrinsic Print(C::LMFDBGrpConjCls)
  {Print LMFDBGrpConjCls}
  printf "LMFDBGrpConjCls %o:\n", C`Label;
  printf "  Size %o:\n", C`Size;
  printf "  Representative %o", C`Representative;
  printf "  Group %o:\n", C`Group;
end intrinsic;

declare verbose LMFDBGrpPermConjCls, 1;
declare type LMFDBGrpPermConjCls;
declare attributes LMFDBGrpPermConjCls:
  Label,
  Group,
  Degree,
  Counter,
  Size,
  Order,
  Centralizer,
  CycleType,
  Representative;

intrinsic Print(C::LMFDBGrpPermConjCls)
  {Print LMFDBGrpConjCls}
  printf "LMFDBGrpPermConjCls %o:\n", C`Label;
  printf "  Size %o:\n", C`Size;
  printf "  Representative %o", C`Representative;
  printf "  Group %o:\n", C`Group;
end intrinsic;

declare verbose LMFDBGrpChtrCC, 1;
declare type LMFDBGrpChtrCC;
declare attributes LMFDBGrpChtrCC:
  Label,
  Group,
  Dim,
  Counter,
  Kernel,
  Center,
  Faithful,
  Image;

intrinsic Print(Chi::LMFDBGrpChtrCC)
  {Print LMFDBGrpChtrCC}
  printf "LMFDBGrpChtrCC %o:\n", Chi`Label;
  printf "  Dimension %o:\n", Chi`Dim;
  printf "  Group %o:", Chi`Group;
end intrinsic;

declare verbose LMFDBGrpChtrQQ, 1;
declare type LMFDBGrpConjChtrQQ;
declare attributes LMFDBGrpConjChtrQQ:
  Label,
  Group,
  CDim,
  QDim,
  Multiplicity,
  Indicator,
  SchurIndex;

intrinsic Print(Chi::LMFDBGrpChtrQQ)
  {Print LMFDBGrpChtrQQ}
  printf "LMFDBGrpChtrQQ %o:\n", Chi`Label;
  printf "  Rational Dimension %o:\n", Chi`RationalDim;
  printf "  Group %o:", Chi`Group;
end intrinsic;

// include hashing function? see https://magma.maths.usyd.edu.au/magma/handbook/text/27

declare type NoneType;
_None := New(NoneType);

intrinsic None() -> Any
{None}
 return _None;
end intrinsic;

// This function returns the value of an attribute, computing it and caching it using the function of the same name if necessary.
intrinsic Get(G::Any, attr::MonStgElt) -> Any
  {}
  if HasAttribute(G, attr) then
    return G``attr;
  else
    val := eval attr*"(G)";
    G``attr := val;
    return val;
  end if;
end intrinsic;

