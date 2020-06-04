// see https://github.com/roed314/FiniteGroups/blob/master/ProposedSchema.md
declare verbose LMFDBGrp, 1;
declare type LMFDBGrp;
declare attributes LMFDBGrp:
  MagmaGrp,
  label,
  old_label,
  name,
  tex_name,
  order,
  counter,
  factors_of_order,
  exponent,
  abelian,
  cyclic,
  solvable,
  supersolvable,
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
  rank,
  eulerian_function,
  MagmaCenter,
  center_label,
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
  MagmaTransitiveSubgroup,
  faithful_reps,
  aut_order,
  MagmaAutGroup,
  outer_order,
  outer_group,
  factors_of_aut_order,
  nilpotency_class,
  ngens,
  pc_code,
  number_conjugacy_classes,
  number_subgroup_classes,
  number_subgroups,
  number_normal_subgroups,
  number_characteristic_subgroups,
  derived_length,
  perfect_core,
  primary_abelian_invariants,
  smith_abelian_invariants,
  schur_multiplier,
  order_stats,
  elt_rep_type,
  perm_gens,
  all_subgroups_known,
  normal_subgroups_known,
  maximal_subgroups_known,
  sylow_subgroups_known,
  subgroup_inclusions_known,
  outer_equivalence,
  subgroup_index_bound,
  MagmaSylowSubgroups,
  Zgroup,
  Agroup,
  //ModDecompUniq,
  wreath_product,
  central_product,
  finite_matrix_group,
  direct_product,
  semidirect_product,
  composition_factors,
  composition_length;
intrinsic Print(G::LMFDBGrp)
  {Print LMFDBGrp}
  printf "LMFDBDGrp %o\n", G`label;
  //printf "  Name %o\n", G`name;
  //printf "  Order %o", G`order;
end intrinsic;

declare verbose LMFDBGrpPerm, 1;
declare type LMFDBGrpPerm;
declare attributes LMFDBGrpPerm:
  label,
  group,
  n,
  t,
  order,
  parity,
  abelian,
  cyclic,
  solvable,
  primitive,
  auts,
  arith_equiv,
  sibling_completeness,
  quotients_completeness,
  subs,
  quotients,
  generators;

intrinsic Print(G::LMFDBGrpPerm)
  {Print LMFDBGrpPerm}
  printf "LMFDBDGrpPerm %o:\n", G`label;
  printf "  Order %o", G`order;
end intrinsic;

declare verbose LMFDBSubGrp, 1;
declare type LMFDBSubGrp;
declare attributes LMFDBSubGrp:
  MagmaAmbient, // input
  MagmaSubGrp, // input
  label, // process
  outer_equivalence, // input
  counter,
  counter_by_index,
  aut_counter,
  extension_counter,
  subgroup,
  subgroup_order,
  ambient,
  ambient_order,
  quotient,
  quotient_order,
  normal,
  characteristic,
  cyclic,
  abelian,
  perfect,
  sylow,
  hall,
  maximal,
  maximal_normal,
  minimal,
  minimal_normal,
  split,
  complements,
  direct,
  central,
  stem,
  count,
  conjugacy_class_count,
  core,
  coset_action_label,
  normalizer,
  centralizer,
  normal_closure,
  quotient_action_kernel,
  quotient_action_image,
  contains,
  contained_in,
  quotient_fusion,
  subgroup_fusion,
  alias_spot,
  generators,
  projective_image;

intrinsic Print(H::LMFDBSubGrp)
  {Print LMFDBGrp}
  printf "LMFDBDSubGrp %o:\n", H`label;
  printf "  Group label%o\n ", H`ambient;
  printf "  Order %o\n", H`subgroup_order;
  printf "  Normal? %o", H`normal;
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
  printf "LMFDBCtrlProd %o:\n", P`label;
  printf "  Central product of %o and %o", P`factor1, P`factor2;
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
  printf "LMFDBWrthProd %o:\n", P`label;
  printf " Wreath product of %o by %o", P`acted, P`actor;
end intrinsic;

declare verbose LMFDBRepQQ, 1;
declare type LMFDBRepQQ;
declare attributes LMFDBRepQQ:
  label,
  dim,
  order,
  group,
  c_class,
  irreducible,
  decomposition;

intrinsic Print(Rho::LMFDBRepQQ)
  {Print LMFDBRepQQ}
  printf "LMFDBRepQQ %o:\n", Rho`label;
  printf "  Dimension %o:\n", Rho`dim;
  printf "  Group %o:\n", Rho`group;
  printf "  Irreducible? %o", Rho`irreducible;
end intrinsic;

declare verbose LMFDBRepZZ, 1;
declare type LMFDBRepZZ;
declare attributes LMFDBRepZZ:
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
  printf "LMFDBRepZZ %o:\n", Rho`label;
  printf "  Dimension %o:\n", Rho`dim;
  printf "  Group %o:\n", Rho`group;
  printf "  Irreducible? %o", Rho`irreducible;
end intrinsic;

declare verbose LMFDBRepCC, 1;
declare type LMFDBRepCC;
declare attributes LMFDBRepCC:
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
  printf "LMFDBRepCC %o:\n", Rho`label;
  printf "  Dimension %o:\n", Rho`dim;
  printf "  Group %o:\n", Rho`group;
  printf "  Irreducible? %o", Rho`irreducible;
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
  printf "LMFDBRepP %o:\n", Rho`label;
  printf "  Dimension %o:\n", Rho`dim;
  printf "  Ambient %o:", Rho`ambient;
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
  printf "LMFDBRepPNames %o:\n", Rho`name;
  printf "  Dimension %o:\n", Rho`dim;
  printf "  Group %o:", Rho`group;
end intrinsic;

declare verbose LMFDBGrpConjCls, 1;
declare type LMFDBGrpConjCls;
declare attributes LMFDBGrpConjCls:
  MagmaConjCls,
  label,
  group,
  size,
  counter,
  order,
  centralizer,
  powers,
  representative;

intrinsic Print(C::LMFDBGrpConjCls)
  {Print LMFDBGrpConjCls}
  printf "LMFDBGrpConjCls %o:\n", C`label;
  printf "  Size %o:\n", C`size;
  printf "  Representative %o", C`representative;
  printf "  Group %o:\n", C`group;
end intrinsic;

declare verbose LMFDBGrpPermConjCls, 1;
declare type LMFDBGrpPermConjCls;
declare attributes LMFDBGrpPermConjCls:
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
  printf "LMFDBGrpPermConjCls %o:\n", C`label;
  printf "  Size %o:\n", C`size;
  printf "  Representative %o", C`representative;
  printf "  Group %o:\n", C`group;
end intrinsic;

declare verbose LMFDBGrpChtrCC, 1;
declare type LMFDBGrpChtrCC;
declare attributes LMFDBGrpChtrCC:
  MagmaChtr,
  label,
  group,
  dim,
  counter,
  kernel,
  center,
  faithful,
  image;

intrinsic Print(Chi::LMFDBGrpChtrCC)
  {Print LMFDBGrpChtrCC}
  printf "LMFDBGrpChtrCC %o:\n", Chi`Llbel;
  printf "  Dimension %o:\n", Chi`dim;
  printf "  Group %o:", Chi`group;
end intrinsic;

declare verbose LMFDBGrpChtrQQ, 1;
declare type LMFDBGrpConjChtrQQ;
declare attributes LMFDBGrpConjChtrQQ:
  label,
  group,
  cdim,
  qdim,
  multiplicity,
  indicator,
  schur_index;

intrinsic Print(Chi::LMFDBGrpChtrQQ)
  {Print LMFDBGrpChtrQQ}
  printf "LMFDBGrpChtrQQ %o:\n", Chi`label;
  printf "  Rational Dimension %o:\n", Chi`qdim;
  printf "  Group %o:", Chi`group;
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
