
intrinsic MakeBigGroup(desc::MonStgElt, label::MonStgElt) -> LMFDBGrp
    {Create an LMFDBGrp object for StringToGroup(desc)}
    G := NewLMFDBGrp(StringToGroup(desc), label);
    AssignBasicAttributes(G);
    return G;
end intrinsic;

intrinsic GetComputeDescription(label::MonStgElt) -> LMFDBGrp
{Returns a version of the isomorphism class with the given label that has good runtime, but may not be the best to display}
    desc := Read("DATA/descriptions/compute/" * label);
    return MakeBigGroup(desc, label);
end intrinsic;

intrinsic GetDisplayDescription(label::MonStgElt) -> LMFDBGrp
{Returns a version of the isomorphism class with the given label that has the DisplayMap attribute set}
    cdesc := Read("DATA/descriptions/compute/" * label);
    dexists := OpenTest("DATA/descriptions/display/" * label, "r");
    if dexists then
        ddesc := Read("DATA/descriptions/display/" * label);
    end if;
    return MakeBigGroup(ddesc, label); // not right!
end intrinsic;

/***********
Try to find minimal permutation rep (have a lot of this data).  This is likely the best to compute with.
Run IrreducibleModules(G, K) for K=Q and for K a small finite fields.  Save this!  Derive character table and rational character table (and rational).  Use MaxDegree parameter (char 0) or DimLim (char p)
Complex characters, resulting quantities (monomial, faithful reps)
Find automorphism group and save it (make sure to use existing computations)
Try to find the holomorph, and the consequences up to autjugacy (probably only feasible for somewhat small groups)
Find normal subgroups (and resulting quantities, like direct product factorization).  This probably involves rewriting the NormalSubgroups intrinsic to not call Subgroups.
Find all subgroups (and resulting quantities, like semidirect products, rank, eulerian function, better group names)

Generate a list of subs/quos for hashing and identification (don't add them, but it would be good to know if they're already there)
Other stuff (schur_multiplier, wreath_data)

BASIC
label|Agroup|Zgroup|elt_rep_type|abelian|center_label|composition_factors|composition_length|counter|cyclic|derived_length|elementary|exponent|exponents_of_order|factors_of_order|gens_used|hash|hyperelementary|metabelian|metacyclic|ngens|nilpotency_class|nilpotent|old_label|order|pc_code|perfect|perm_gens|pgroup|primary_abelian_invariants|quasisimple|simple|smith_abelian_invariants|solvable|supersolvable|sylow_subgroups_known|finite_matrix_group
LABELING
label|abelian_quotient|central_quotient|commutator_label|frattini_label|frattini_quotient
AUT STUFF
label|aut_group|aut_order|complete|factors_of_aut_order|number_autjugacy_classes|outer_equivalence|outer_group|outer_order
SCHUR
label|schur_multiplier
WREATH
label|wreath_data|wreath_product

NAME
label|name|tex_name

CONJUGACY CLASSES (and write groups_cc)
label|number_conjugacy_classes|number_divisions|order_stats

NORMAL SUBGROUPS (only run when SUBGROUPS times out, write appropriate subgroups)
label|almost_simple|central_product|direct_factorization|direct_product|number_characteristic_subgroups|normal_subgroups_known|number_normal_subgroups

SUBGROUPS (and write subgroups)
label|transitive_degree|all_subgroups_known|eulerian_function|maximal_subgroups_known|number_subgroup_autclasses|number_subgroup_classes|number_subgroups|rank|semidirect_product|subgroup_inclusions_known|subgroup_index_bound

CHARACTERS (and write characters_cc)
label|commutator_count|faithful_reps|monomial|smallrep|solvability_type
RATIONAL CHARACTERS (and write characters_qq)
label|rational

new stuff (permutation degree, linear degree, etc)....
check status on number_divisions
make sure ngens, gens_used, pc_code, perm_gens ok in basic
organize which columns are preloaded (hash, gens_used, pc_code...)
deciding on outer_equivalence
store permutation generators in a separate table?
Can use Complements to do find semidirect decompositions from NormalSubgroups
Use semidirect products to select a better name
Write StringToGroupHom and GroupHomToString in order to deal with things like PGL
Write cloud_collect.py to collect results
Write another job that modifies a full record along a group hom by mapping/lifting all elements

finite_matrix_group shouldn't be a column probably
metacyclic might be slow for basic


***********/

intrinsic GetNormalData(G::LMFDBGrp) -> Any
{}
    G`normal_subgroups_known := true;
    G`outer_equivalence := false; // we might be able to work up to automorphism....
end intrinsic;
