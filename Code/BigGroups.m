
intrinsic MakeBigGroup(desc::MonStgElt, label::MonStgElt) -> LMFDBGrp
    {Create an LMFDBGrp object for StringToGroup(desc)}
    f, cover := StringToGroupHom(desc);
    if cover then
        G := Codomain(f);
    else
        G := Domain(f);
    end if;
    G := NewLMFDBGrp(G, label);
    AssignBasicAttributes(G);
    G`ElementReprHom := f;
    G`ElementReprCovers := cover;
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

Path to finishing computations:
1. Finish creating the to_add file that will be fed into google cloud.
 a. List of groups is finalized
 b. PCreps are done enough: optimized reps for 257,936+51,565 groups, fast reps for 203,654 groups; 31,647 nonsolvable
 c. Minreps are done enough: minimal degree permutation rep for 532,960 groups; 11,842 missing (of which 11,444 have a smallish permutation representation)
 d. Matreps are in progress: nxn matrix groups over Fq found for n=2 and q<1000, n=3 and q<15, n=4 and q < 6, n=5 and q=2, 2x2 matrix groups over Z/N from Drew are identified except for Z/72, have code for optimizing generators.
 e. Have been using StringToGroup and GroupToString; recently created StringToGroupHom and GroupHomToString for GL(n,q) -> PGL(n,q), Sp -> PSp, SL -> PSL, SO -> PSO, etc and matrix groups over Z/N
 f. Need to pick heuristics for which representation to choose in displaying elements.  Plan: use pc for abelian and 2-generator, then compare (pc ngens) ~ (perm deg)^(3/5) ~ (mat deg).  Note that this heuristic doesn't include matrix base ring (add one?)
2. Modify code to run in cloud
 a. Have created cloud_prep.py, which makes a tarball with everything needed for a run
 b. Then cloud_start.py just takes an integer and uses a manifest file to translate that to a particular magma script.  We've already used this to compute some minreps and pcreps.  For main computation, have split up the tasks into parts which can be run independently (first we'll do a run with a shortish timeout that goes through these tasks sequentially, then another where they're split up, then a final one falling back to normal subgroups if all subgroups was infeasible)
 c. Need to use Complements to find semidirect decompositions from NormalSubgroups
 d. Use 

Harmonize the various place column names show up (IO.m, .tmpheader, .header, LMFDBGrp.m, postgres table...)
Refine labeling: it may be too slow
organize which columns are preloaded (hash, data from gps_transitive...)
Don't priorize weird Lie groups
Compute and save automorphism group beforehand
Create hash_lookup folder (see Label.m)
Run for matrix groups to test (Frattini seems to fail for example)
Direct product broken for outer_equivalence

Change Presentation.m to not use Holomoprh
Use semidirect products to select a better name (postprocess step so that we can work up from the bottom and include Lie group names if not stupid); make sure to modify other places names show up (subgroups table); make sure status variables like complex_characters_known are accurate (might have tried and failed)
Write cloud_collect.py to collect results
Write another job that modifies a full record along a group hom by mapping/lifting all elements
Write scripts for adding more groups later

Talk to Drew: Make sure that the version of Magma installed in the cloud has the appropriate libraries installed (Atlas, Trans32Id for example), and that LMFDB access is okay
Columns to remove: finite_matrix_group, elt_rep_type, perm_gens, pc_code, gens_used, smallrep (replaced by irrC_degree)
For discussion:
 * ngens (not very mathematically meaningful)
 * MinimalDegreePermutationRepresentation (could be wrong); improved by modifying magma to fix bug
 * Some affine groups displayed as permutation groups

Send a message about todo items on Large Groups list
Think about whether there are more sections that need to be added to paper

Done:
finish representations jsonb column
Make SaveElt work for matrix groups
hashes for subgroups and quotients (things that might not have labels)
new stuff (permutation degree, linear degree, etc)....
Check permutation_degree (rerun in progress)
Check status of LoadSubgroupCache (used in SubgroupLattice)
Separate computation of complex and rational character tables? (linked by labeling characters, so can't)

***********/
