declare verbose LMFDBGrp, 1;
declare type LMFDBGrp;
declare attributes LMFDBGrp:
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
  IsSuperSolvable,
  IsNilpotent,
  IsMetaCyclic,
  IsMetaAbelian,
  IsSimple,
  IsAlmostSimple,
  IsQuasiSimple,
  IsPerfect,
  IsMonomial,
  IsRational,
  ZGroup,
  AGroup,
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
  Frattini,
  FrattiniLabel,
  FrattiniQuotient,
  Fitting,
  Radical,
  Socle,
  TransitiveDegree,
  TransitiveSubgroup,
  SmallRep,
  AutOrder,
  AutGroup,
  OuterOrder,
  OuterGroup,
  FactorsOfAutOrder,
  NilpotencyClass,
  Ngens,
  PCCode,
  NumberConjugacyClasses,
  NumberSubgroupClasses,
  NumberSubgroups,
  NumberNormalSubgroups,
  NumberCharacteristicSubgroups,
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
  //ModDecompUniq,
  IsWreathProduct,
  IsCentralProduct,
  IsFiniteMatrixGroup,
  IsDirectProduct,
  IsSemidirectProduct,
  CompositionFactors,
  CompositionLength;

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

declare verbose LMFDBSubGrp, 1;
declare type LMFDBSubGrp;
declare attributes LMFDBSubGrp:
  Label,
  OuterEquivalence,
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

declare verbose LMFDBCtrlProd, 1;
declare type LMFDBCtrlProd;
declare attributes LMFDBCtrlProd:
  Factor1,
  Factor2,
  Sub1,
  Sub2,
  Product,
  AliasSpot;

declare verbose LMFDBWrthProd, 1;
declare type LMFDBWrthProd;
declare attributes LMFDBWrthProd:
  Acted,
  Actor,
  Product,
  AliasSpot;

declare verbose LMFDBRepQQ, 1;
declare type LMFDBRepQQ;
declare attributes LMFDBRepQQ:
  Label,
  Dimension,
  Order,
  Group,
  CCClass,
  IsIrreducible,
  Decomposition;

declare verbose LMFDBRepZZ, 1;
declare type LMFDBRepZZ;
declare attributes LMFDBRepZZ:
  Label,
  Dimension,
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

declare verbose LMFDBRepCC, 1;
declare type LMFDBRepCC;
declare attributes LMFDBRepCC:
  Label,
  Dimension,
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

declare verbose LMFDBRepp, 1;
declare type LMFDBRepp;
declare attributes LMFDBRepp:
  Label,
  Dimension,
  q,
  IsPrime,
  Ambient,
  Counter,
  ProjectiveImage,
  Generators,
  ProjectiveImageLabel;

declare verbose LMFDBReppNames, 1;
declare type LMFDBReppNames;
declare attributes LMFDBReppNames:
  Group,
  Dimension,
  q,
  Family,
  Name,
  TeXName;

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

declare verbose LMFDBGrpPermConjCls, 1;
declare type LMFDBGrpPermConjCls;
declare attributes LMFDBGrpPermConjCls:
  Label,
  Groups,
  Degree,
  Counter,
  Size,
  Order,
  Centralizer,
  CycleType,
  Representative;

declare verbose LMFDBGrpChtr, 1;
declare type LMFDBGrpConjChtr;
declare attributes LMFDBGrpConjChtr:
  Label,
  Group,
  Dimension,
  Counter,
  Kernel,
  Center,
  Faithful,
  Image;

declare verbose LMFDBGrpChtrQQ, 1;
declare type LMFDBGrpConjChtrQQ;
declare attributes LMFDBGrpConjChtrQQ:
  Label,
  ComplexDimension,
  RationalDimension,
  Multiplicity,
  Indicator,
  SchurIndex;
