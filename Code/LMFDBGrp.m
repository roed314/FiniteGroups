// see https://github.com/roed314/FiniteGroups/blob/master/ProposedSchema.md
declare verbose LMFDBGrp, 1;
declare type LMFDBGrp;
declare attributes LMFDBGrp:
  MagmaGrp,
  PermutationGrp,
  HomToPermutationGrp,
  ElementReprHom,
  ElementReprCovers,
  Subgroups,
  NormalSubgroups,
  SubGrpLst,
  SubGrpLat,
  SubGrpLstAut,
  SubGrpLatAut,
  BestSubgroupLat,
  NormSubGrpLat,
  NormSubGrpLatAut,
  Holomorph,
  HolInj,
  HaveHolomorph,
  HaveAutomorphisms,
  UseSolvAut,
  ConjugacyClasses,
  CCAutCollapse,
  GeneratorsSequence,
  MagmaGenerators,
  MagmaConjugacyClasses,
  MagmaDivisions,
  ClassMap,
  MagmaClassMap,
  MagmaPowerMap,
  MagmaCharacterTable,
  MagmaRationalCharacterTable,
  MagmaCharacterMatching,
  MagmaLowerCentralSeries,
  MagmaUpperCentralSeries,
  MagmaChiefSeries,
  MagmaDerivedSeries,
  CycEltCache,
  CCpermutation,
  CCpermutationInv,
  CCCharacters,
  CCRepLabels,
  QQCharacters,
  Generators,
  QQReps,
  CCReps,
  QQRepsAsCC,
  Characters,
  AllSubgroupsOk,
  SubGrpLstByDivisorTerminate,
  IsoToOldPresentation, // set by the various RePresent intrinsics in Presentation.m
  SubByGass, // used in MinReps.m
  label,
  old_label,
  name,
  tex_name,
  order,
  counter,
  factors_of_order,
  exponents_of_order,
  exponent,
  abelian,
  cyclic,
  solvable,
  supersolvable,
  solvability_type,
  backup_solvability_type,
  nilpotent,
  metacyclic,
  metabelian,
  simple,
  almost_simple,
  quasisimple,
  perfect,
  monomial,
  rational,
  Zgroup,
  Agroup,
  pgroup,
  elementary,
  hyperelementary,
  easy_rank,
  rank,
  eulerian_function,
  EulerianTimesAut,
  MagmaCenter,
  center_label,
  center_order,
  central_quotient,
  MagmaCommutator,
  commutator_label,
  abelian_quotient,
  commutator_count,
  MagmaFrattini,
  frattini_label,
  frattini_quotient,
  MagmaFitting,
  MagmaRadical,
  transitive_degree,
  permutation_degree,
  irrC_degree,
  //irrFp_degree,
  //irrFq_degree,
  irrQ_degree,
  linC_degree,
  linFp_degree,
  linFq_degree,
  linQ_degree,
  pc_rank,
  MagmaTransitiveSubgroup,
  faithful_reps,
  smallrep, // old style; to be removed
        aut_order, aut_group, aut_gens, aut_gen_orders, aut_permdeg, aut_perms, aut_cyclic, aut_abelian, aut_nilpotent, aut_supersolvable, aut_solvable, aut_exponent, aut_hash, aut_tex, aut_nilpotency_class, aut_derived_length, aut_phi_ratio,
        AutGenerators0, AutGenerators1, AutGenerators2, AutGenerators3, aut_gens0, aut_gens1, aut_gens2, aut_gens3, AutPermGenerators1, AutPermGenerators2, AutPermGenerators3, aut_perms1, aut_perms2, aut_perms3, aut_gen_orders0, aut_gen_orders1, aut_gen_orders2, aut_gen_orders3, OuterGenerators0, OuterGenerators1, OuterGenerators2, OuterGenerators3, OutPermGenerators1, OutPermGenerators2, OutPermGenerators3, outer_gens0, outer_gens1, outer_gens2, outer_gens3, outer_perms1, outer_perms2, outer_perms3, outer_gen_orders0, outer_gen_orders1, outer_gen_orders2, outer_gen_orders3, outer_gen_pows0, outer_gen_pows1, outer_gen_pows2, outer_gen_pows3,
  inner_order, inner_gens, inner_gen_orders, inner_used, inner_split, inner_cyclic, inner_abelian, inner_nilpotent, inner_supersolvable, inner_solvable, inner_exponent, inner_hash, inner_tex,
  outer_order, outer_group, outer_gens, outer_gen_orders, outer_gen_pows, outer_permdeg, outer_perms, outer_cyclic, outer_abelian, outer_nilpotent, outer_supersolvable, outer_solvable, outer_exponent, outer_hash, outer_tex,
  autcent_order, autcent_group, autcent_split, autcent_cyclic, autcent_abelian, autcent_nilpotent, autcent_supersolvable, autcent_solvable, autcent_exponent, autcent_hash, autcent_tex,
  autcentquo_order, autcentquo_group, autcentquo_cyclic, autcentquo_abelian, autcentquo_nilpotent, autcentquo_supersolvable, autcentquo_solvable, autcentquo_exponent, autcentquo_hash, autcentquo_tex,
  MagmaAutGroup, MagmaOuterGroup, MagmaOuterProjection, MagmaClassAction, MagmaInnerGroup, MagmaAutcent, MagmaAutcentquo, OutLabelIso, AutLabelIso, AutGenerators, OuterGenerators, InnerGenerators, OutPermGenerators, AutPermGenerators, InnPermGenerators, SkipAutMinDegRep, SkipAutFewGenerators, SkipAutLabel, SkipOutLabel, SkipAutcentLabel, SkipAutcentquoLabel, SkipInnSplit, SkipAutcentSplit,
  factors_of_aut_order,
  complete,
  nilpotency_class,
  ngens,
  pc_code, // old style; to be removed
  gens_used, // old style; to be removed
  number_conjugacy_classes,
  number_autjugacy_classes,
  number_divisions,
  number_subgroup_autclasses,
  number_subgroup_classes,
  number_subgroups,
  number_normal_subgroups,
  number_characteristic_subgroups,
  derived_length,
  primary_abelian_invariants,
  smith_abelian_invariants,
  schur_multiplier,
  order_stats,
  cc_stats,
  div_stats,
  aut_stats,
  irrep_stats,
  ratrep_stats,
  elt_rep_type, // old style; to be removed
  representations, // A dictionary with keys in "Perm", "PC", "GLZ", "GLFp", "GLZq", "GLZN", "PGLFp", "PGLFq", and values a dictionary giving the defining parameters
  element_repr_type, // string, explains which repr type ("PC", "Perm", "GLZ", "GLFp", "GLZq", "GLZN", "GLFq", "PGLFp", "PGLFq") to be used in representing elements
  perm_gens, // old style; to be removed
  hash,
  HashData,
  all_subgroups_known,
  complex_characters_known,
  rational_characters_known,
  normal_subgroups_known,
  normal_index_bound,
  normal_order_bound,
  normal_counts,
  complements_known,
  maximal_subgroups_known,
  sylow_subgroups_known,
  subgroup_inclusions_known,
  outer_equivalence,
  subgroup_index_bound,
  AutAboveCutoff,
  AutIndexBound,
  SubGrpLstCutoff,
  MagmaSylowSubgroups,
  MagmaMinimalNormalSubgroups,
  MagmaMaximalSubgroups,
  Zgroup,
  Agroup,
  charc_center_gens,
  charc_kernel_gens,
  charc_centers,
  charc_kernels,
  conj_centralizer_gens,
  conj_centralizers,
  //ModDecompUniq,
  wreath_product,
  wreath_data,
  central_product,
  direct_product,
  direct_factorization,
  semidirect_product,
  composition_factors,
  composition_length,
  subgroup_label_info, // For loading subgroup identifications when recomputing data
  quotient_label_info; // For loading quotient identifications when recomputing data
intrinsic Print(G::LMFDBGrp)
  {Print LMFDBGrp}
  printf "LMFDBGrp %o:\n", Get(G, "label");
  //printf "  Name %o\n", Get(G, "name");
  printf "  Order %o", Get(G, "order");
end intrinsic;

declare verbose LMFDBGrpPerm, 1;
declare type LMFDBGrpPerm;
declare attributes LMFDBGrpPerm:
  MagmaGrp,
  label, // label like 9.3T2x3.12.a
  group, // abstract label like 2048.a
  sn_subgroup, // short label as subgroup of S_n, like 10.a1.a1
  n, // the degree
  t, // if transitive, the T-number.  If not, NULL
  order, // order of the group
  parity, // 1 if contained in A_n, -1 otherwise
  orbits, // number of orbits for the standard action on {1..n}
  transitive, // whether transitive
  primitive, // whether primitive
  abelian, // whether abelian
  cyclic, // whether cyclic
  solvable, // whether solvable
  nilpotency_class, // -1 for not nilpotent
  auts, // the number of automorphisms of a degree n etale algebra with this as its Galois group
  arith_equiv, // number of arithmetically equivalent fields for number fields with this Galois group
  sibling_completeness,
  quotients_completeness,
  subs, // Galois groups of proper non-trivial subgroups of a field with this Galois group given as a list of pairs, the group and its multiplicity
  quotients, // List of Galois groups of subfields which are proper quotients of this group, given as pairs of the group and the multiplicity
  generators; // encoded generators

intrinsic Print(G::LMFDBGrpPerm)
  {Print LMFDBGrpPerm}
  printf "LMFDBGrpPerm %o:\n", Get(G, "label");
  printf "  Order %o", Get(G, "order");
end intrinsic;

declare verbose LMFDBSubGrp, 1;
declare type LMFDBSubGrp;
declare attributes LMFDBSubGrp:
  Grp, // input
  Quotient, // quotient as a magma Grp
  MagmaAmbient, // derived from Grp
  MagmaSubGrp, // input
  QuotientMap, // homomorphism from MagmaAmbient to Quotient
  LatElt, // underlying SubgroupLatElt, used to delay computation of mobius_sub and mobius_quo
  label, // process
  short_label,
  aut_label,
  stored_label, // used in relabeling
  special_labels,
  outer_equivalence, // input
  aut_counter,
  extension_counter,
  subgroup,
  subgroup_order,
  subgroup_hash,
  ambient,
  ambient_order,
  quotient,
  quotient_order,
  quotient_hash,
  normal,
  characteristic,
  cyclic,
  abelian,
  solvable,
  quotient_cyclic,
  quotient_abelian,
  quotient_solvable,
  nilpotent,
  perfect,
  sylow,
  hall,
  maximal,
  maximal_normal,
  minimal,
  minimal_normal,
  mobius_sub,
  mobius_quo,
  split,
  complements,
  central_factor,
  direct,
  central,
  stem,
  count,
  conjugacy_class_count,
  core,
  core_order,
  coset_action_label,
  normalizer,
  centralizer,
  centralizer_order,
  normal_closure,
  QuotientActionMap, // if split, Q -> Aut(N); otherwise Q -> Out(N)
  quotient_action_kernel,
  quotient_action_kernel_order,
  quotient_action_image,
  contains,
  contained_in,
  normal_contains,
  normal_contained_in,
  quotient_fusion,
  subgroup_fusion,
  alias_spot,
  generators,
  //generator_images,
  standard_generators,
  diagram_x,
  diagram_aut_x,
  diagram_norm_x,
  diagramx,
  projective_image,
  subgroup_tex,
  ambient_tex,
  quotient_tex,
  weyl_group,
  AutStab,
  aut_weyl_group,
  aut_weyl_index,
  aut_stab_index,
  aut_quo_index,
  aut_centralizer_order,
  proper,
  Agroup,
  Zgroup,
  metabelian,
  metacyclic,
  supersolvable,
  simple,
  quotient_nilpotent,
  quotient_Agroup,
  quotient_metabelian,
  quotient_supersolvable,
  quotient_simple,
  MagmaCentralizer;  // added to deal with magma bug with 120.5

intrinsic Print(H::LMFDBSubGrp)
  {Print LMFDBSubGrp}
  printf "LMFDBSubGrp %o:\n", Get(H, "label");
  printf "  Group label %o\n", Get(H, "ambient");
  printf "  Order %o\n", Get(H, "subgroup_order");
  printf "  Normal? %o", Get(H, "normal");
end intrinsic;

declare verbose LMFDBCtrlProd, 1;
declare type LMFDBCtrlProd;
declare attributes LMFDBCtrlProd:
  factor1,
  factor2,
  sub1,
  sub2,
  product,
//label,
  alias_spot;

intrinsic Print(P::LMFDBCtrlProd)
  {Print LMFDBCtrlProd}
  printf "LMFDBCtrlProd %o:\n", Get(P, "label");
  printf "  Central product of %o and %o", Get(P, "factor1"), Get(P, "factor2");
end intrinsic;

declare verbose LMFDBWrthProd, 1;
declare type LMFDBWrthProd;
declare attributes LMFDBWrthProd:
  acted,
  actor,
  product,
//Label,
  alias_spot;

intrinsic Print(P::LMFDBWrthProd)
  {Print LMFDBWrthProd}
  printf "LMFDBWrthProd %o:\n", Get(P, "label");
  printf " Wreath product of %o by %o", Get(P, "acted"), Get(P, "actor");
end intrinsic;

declare verbose LMFDBRepQQ, 1;
declare type LMFDBRepQQ;
declare attributes LMFDBRepQQ:
  MagmaGrp,
  label,
  carat_label,
  dim,
  order,
  c_class,
  irreducible,
  group,
  gens,
  decomposition;

intrinsic Print(Rho::LMFDBRepQQ)
  {Print LMFDBRepQQ}
  printf "LMFDBRepQQ %o:\n", Get(Rho, "label");
  printf "  Dimension %o:\n", Get(Rho, "dim");
  printf "  Group %o:\n", Get(Rho, "group");
  printf "  Irreducible? %o", Get(Rho, "irreducible");
end intrinsic;

declare verbose LMFDBRepZZ, 1;
declare type LMFDBRepZZ;
declare attributes LMFDBRepZZ:
  MagmaGrp,
  label,
  dim,
  order,
  group,
  q_class,
  c_class,
  bravais_class,
  crystal_symbol,
  indecomposable,
  irreducible,
  decomposition,
  gens;

intrinsic Print(Rho::LMFDBRepZZ)
  {Print LMFDBRepZZ}
  printf "LMFDBRepZZ %o:\n", Get(Rho, "label");
  printf "  Dimension %o:\n", Get(Rho, "dim");
  printf "  Group %o:\n", Get(Rho, "group");
  printf "  Irreducible? %o", Get(Rho, "irreducible");
end intrinsic;

declare verbose LMFDBRepCC, 1;
declare type LMFDBRepCC;
declare attributes LMFDBRepCC:
  MagmaRep, // Magma GModule
  MagmaGrp, // Magma matrix group
  E, // Exponent of the group.  Initially, reps are in Q(zeta_E)
  label,
  dim,
  order,
  group,
  irreducible,
  decomposition,
  indicator,
  schur_index,
  cyc_order_mat,
  trace_field,
  cyc_order_traces,
  denominators,
  gens,
  traces;

intrinsic Print(Rho::LMFDBRepCC)
  {Print LMFDBRepCC}
  printf "LMFDBRepCC %o:\n", Get(Rho, "label");
  printf "  Dimension %o:\n", Get(Rho, "dim");
  printf "  Group %o:\n", Get(Rho, "group");
  printf "  Irreducible? %o", Get(Rho, "irreducible");
end intrinsic;

declare verbose LMFDBRepP, 1;
declare type LMFDBRepP;
declare attributes LMFDBRepP:
  label,
  dim,
  q,
  prime,
  ambient,
  counter,
  projective_image,
  gens,
  proj_label;

intrinsic Print(Rho::LMFDBRepP)
  {Print LMFDBRepP}
  printf "LMFDBRepP %o:\n", Get(Rho, "label");
  printf "  Dimension %o:\n", Get(Rho, "dim");
  printf "  Ambient %o:", Get(Rho, "ambient");
end intrinsic;

declare verbose LMFDBRepPNames, 1;
declare type LMFDBRepPNames;
declare attributes LMFDBRepPNames:
  group,
  dim,
  q,
  family,
  name,
  tex_name;

intrinsic Print(s::LMFDBRepPNames)
  {Print LMFDBRepPNames}
  printf "LMFDBRepPNames %o:\n", Get(Rho, "name");
  printf "  Dimension %o:\n", Get(Rho, "dim");
  printf "  Group %o:", Get(Rho, "group");
end intrinsic;

declare verbose LMFDBGrpConjCls, 1;
declare type LMFDBGrpConjCls;
declare attributes LMFDBGrpConjCls:
  Grp,
  MagmaConjCls,
  label,
  aut_label,
  group,
  size,
  counter,
  order,
  centralizer,
  powers,
  representative;

intrinsic Print(C::LMFDBGrpConjCls)
  {Print LMFDBGrpConjCls}
  printf "LMFDBGrpConjCls %o:\n", Get(C, "label");
  printf "  Size %o:\n", Get(C, "size");
  printf "  Representative %o", Get(C, "representative");
  printf "  Group %o:\n", Get(C, "group");
end intrinsic;

declare verbose LMFDBGrpPermConjCls, 1;
declare type LMFDBGrpPermConjCls;
declare attributes LMFDBGrpPermConjCls:
  Grp,
  MagmaConjCls,
  label,
  group,
  degree,
  counter,
  size,
  order,
  centralizer,
  cycle_type,
  rep;

intrinsic Print(C::LMFDBGrpPermConjCls)
  {Print LMFDBGrpConjCls}
  printf "LMFDBGrpPermConjCls %o:\n", Get(C, "label");
  printf "  Size %o:\n", Get(C, "size");
  printf "  Representative %o", Get(C, "representative");
  printf "  Group %o:\n", Get(C, "group");
end intrinsic;

declare verbose LMFDBGrpChtrCC, 1;
declare type LMFDBGrpChtrCC;
declare attributes LMFDBGrpChtrCC:
  Grp,
  MagmaChtr,
  cyclotomic_n,
  q_character,
  values,
  Image_object,
  label,
  group,
  dim,
  counter,
  kernel,
  center,
  faithful,
  counter,
  nt,
  field,
  indicator,
  image;

intrinsic Print(Chi::LMFDBGrpChtrCC)
  {Print LMFDBGrpChtrCC}
  printf "LMFDBGrpChtrCC: %o\n", Get(Chi, "label");
  printf "  Dimension: %o\n", Get(Chi, "dim");
  printf "  Group %o\n", GetGrp(Chi);
  printf "  Values: %o", Get(Chi,"MagmaChtr");
end intrinsic;

declare verbose LMFDBGrpChtrQQ, 1;
declare type LMFDBGrpChtrQQ;
declare attributes LMFDBGrpChtrQQ:
  Grp,
  MagmaChtr,
  qvalues,
  Image_object,
  label,
  group,
  cdim,
  qdim,
  multiplicity,
  faithful,
  schur_index,
  image,
  counter,
  nt;

intrinsic Print(Chi::LMFDBGrpChtrQQ)
  {Print LMFDBGrpChtrQQ}
  printf "LMFDBGrpChtrQQ %o:\n", Get(Chi, "label");
  printf "  Rational Dimension %o:\n", Get(Chi, "qdim");
//  printf "  Group %o:", Get(Chi, "group"); // Chi does not have a group defined
end intrinsic;

// include hashing function? see https://magma.maths.usyd.edu.au/magma/handbook/text/27

declare type NoneType;
_None := New(NoneType);

intrinsic None() -> Any
{None}
 return _None;
end intrinsic;

intrinsic Print(None)
  {Print none}
  printf "none";
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

intrinsic GetGrp(G::LMFDBGrp) -> LMFDBGrp
{For compatibility for other GetGrp functions}
    return G;
end intrinsic;
