
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
label|Agroup|Zgroup|elt_rep_type|abelian|center_label|composition_factors|composition_length|counter|cyclic|derived_length|elementary|exponent|exponents_of_order|factors_of_order|gens_used|hash|hyperelementary|metabelian|metacyclic|ngens|nilpotency_class|nilpotent|old_label|order|pc_code|perfect|perm_gens|pgroup|primary_abelian_invariants|quasisimple|simple|smith_abelian_invariants|solvable|supersolvable|sylow_subgroups_known
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

Set diagramx
deal with real_problems and fake_problems
Fix overly aggressive preloading of tex_name (F5, S5)
*Profile for HaveHolomorph, double check that the two methods give same results.
Slow LabelConjugacyClasses: 564221981491200.i
E46656.hz(+7)|Subgroups.m:668:23(Hnew := L`subs[j];)|Runtime error in '[]': Sequence index 987 should be in the range 1 to 822
Save to preload things like LabeledConjugacyClasses

Use semidirect products to select a better name and fix latex errors (postprocess step so that we can work up from the bottom and include Lie group names if not stupid); make sure to modify other places names show up (subgroups table); make sure status variables like complex_characters_known are accurate (might have tried and failed)
Write cloud_collect.py to collect results (combine rank and easy_rank, solvability_type and backup_solvability_type; fill in nulls)

Magma bugs:
E230496.r(+0)|GrpAttributes.m:776:17(inners := [P![Position(Y,g^-1*y*g) : y in Y] : g in Generators(GG)];)|Runtime error in '!': Illegal coercion
Bug in Complements (reported to Magma): Segfaults on 40.12, 1696.201, 390624.d, 192720.b, 18000000.u, 1632586752.fi, 13060694016.zk, 13060694016.pu, 52242776064.um, 4553936640000.a, 78364164096.dm, 142818689064960.g, 564221981491200.i
E80000.ze|Internal error in permc_random_base_change_basim_sub() at permc/chbase.c, line 488


Known errors:
E162.54,324.175|misc.m", line 61, column 21 (outer_group constructing coset table)
E2684354560.fb|Runtime error: Index too large for coset enumeration - giving up (in MagmaAutGrp)
E50824368.bp|Current total memory usage: 157699.9MB, failed memory request: 211106232508416.0MB
E256.56086(+155)|package/Group/GrpPerm/aut/grpauto.m:28:21(F, phi := FPGroup(P);)|Runtime error in 'FPGroup': Group too large for regular representation
E4299816960000.de(+0)|GrpAttributes.m:740:27(m, P, Y := ClassAction(aut);)|Runtime error in 'ClassAction': Set cardinality too large (>=2^31)
E2937600.a=CSp(4,4)(+0)|package/Group/GrpMat/ClassicalConj/GOConjugacy.m(cc, L := ClassicalConjugacyClasses(tp,d,q);)|Runtime error in 'ClassicalConjugacyClasses': Type must be one of { GO, O+, Omega-, SO+, Sp, GL, Omega, GU, GO+, SO, Omega+, O-, SL, SO-, O, SU, GO- }
E53130.1(+1)|package/RepThry/AlgChtr/Char0/General/ChtrTable/chtr_table.m:2259:34(T := LinearCharacters(G);)|Runtime error in 'LinearCharacters': Monomial overflow (too many monomials to be represented)

Heisenbugs:
E504.157(+8)|Subgroups.m:1780:22(x := subs[i];)|Runtime error in '[]': Sequence index 36 should be in the range 1 to 35"
E1728.37907(+0)|package/Group/GrpPerm/aut/grpauto.m:55:12(x := P![Position(Y,g^-1*y*g) : y in Y ];)|Runtime error in '!': Illegal coercion
E120.5,336.114|SymmetricBilinearForm: G must be irreducible (heisenbug?  Don't see now)
E16000.bp|Runtime error in 'FPGroup': Incorrect group order detected


Change Presentation.m to not use Holomoprh

Add new columns:

db.gps_groups.add_column("linFp_degree", "integer", "The minimum size matrix group over a finite prime field where this group arises as a subgroup")
db.gps_groups.add_column("representations", "jsonb", "Dictionary containing best representations of each type: polycyclic, permutation, matrix/Z, matrix/Fp, matrix/Fq, matrix/Zn, Lie.  The keys are strings: PC, Perm, GLZ, GLFp, GLFq, GLZn, Lie.  The values give enough information to reconstruct the representation, including some subset of gens (generators encoded as integers except for PC, when it gives the positions of the polycyclic generators that are not powers of other generators), code (for PC gives an integer encoding the structure as in GAP's PcGroupCode or Magma's SmallGroupDecoding), d (gives the degree for permutation and matrix groups), p or q (size of base ring for matrix groups), pres (for PC gives a list of integers to be input to Magma's PCGroup), family (for Lie groups gives a string describing a classical name for the family), b (for GLZ gives an integer so that entries are encoded in the range 0..b-1 and shifted by b//2)")
db.gps_groups.add_column("complements_known", "boolean", "Whether complements are stored for all normal subgroups")
db.gps_groups.add_column("irrC_degree", "integer", "the smallest degree of a faithful irreducible complex representation, or -1 if there is none")
db.gps_groups.add_column("linC_degree", "integer", "the smallest degree of a faithful complex representation")
db.gps_groups.add_column("irrQ_degree", "integer", "the smallest degree of a faithful irreducible rational representation, or -1 if there is none")
db.gps_groups.add_column("linQ_degree", "integer", "the smallest degree of a faithful rational representation")
db.gps_groups.add_column("irrep_stats", "numeric[]", "The list of pairs [d,m] where m is the number of complex irreducible representations of G of dimension d")
db.gps_groups.add_column("div_stats", "numeric[]", "The list of quadruples [o, s, k, m] where m is the number of divisions of order o containing k conjugacy classes of size s")
db.gps_groups.add_column("aut_stats", "numeric[]", "The list of quadruples [o, s, k, m] where m is the number of autjugacy classes of order o containing k conjugacy classes of size s")
db.gps_groups.add_column("ratrep_stats", "numeric[]", "The list of pairs [d,m] where m is the number of rational irreducible representations of G of dimension d")
db.gps_groups.add_column("cc_stats", "numeric[]", "The list of triples [o, s, m] where m is the number of conjugacy classes of order o and size s")
db.gps_groups.add_column("rational_characters_known", "boolean", "Whether the rational character table is stored")
db.gps_groups.add_column("complex_characters_known", "boolean", "Whether the complex character table is stored")
db.gps_groups.add_column("permutation_degree", "integer", "the minimum degree where this group arises as a subgroup of Sn")
db.gps_groups.add_column("aut_gens", "numeric[]", "Generators of the automorphism group, encoded as a list of lists of integers (or decimals if GLZ); the first gives a list of generators of G and the others give the images of these generators under a sequence of automorphisms generating the automorphism group")
db.gps_groups.add_column("pc_rank", "smallint", "The smallest number of generators needed for a polycyclic presentation of this group; null if unknown or not solvable")
db.gps_groups.add_column("element_repr_type", "text", "A string giving one of the keys of the representations dictionary, showing which representation is used in displaying elements")
db.gps_groups.drop_column("elt_rep_type")
db.gps_groups.drop_column("finite_matrix_group")
db.gps_groups.drop_column("pc_code")
db.gps_groups.drop_column("perm_gens")
db.gps_groups.drop_column("smallrep")
db.gps_groups.drop_column("gens_used")

db.gps_groups.drop_column("hash")
db.gps_groups.add_column("hash", "bigint", "Isomorphism-invariant hash for the group")

db.gps_subgroups.add_column("centralizer_order", "numeric", "The order of the centralizer of this subgroup")
db.gps_subgroups.add_column("core_order", "numeric", "The order of the core of this subgroup")
db.gps_subgroups.add_column("subgroup_hash", "bigint", "The hash of the subgroup")
db.gps_subgroups.add_column("quotient_hash", "bigint", "The hash of the quotient (null if not normal)")
db.gps_subgroups.add_column("normal_contains", "text[]", "The labels of the normal subgroups minimally contained in this one (null if this subgroup is not normal)")
db.gps_subgroups.add_column("normal_contained_in", "text[]", "The labels of the normal subgroups minimally containing this one (null if this subgroup is not normal)")
db.gps_subgroups.add_column("aut_stab_index", "numeric", "The index of Stab_A(H) in Aut(G); 1 for characteristic subgroups")
db.gps_subgroups.add_column("aut_quo_index", "numeric", "The index of the image of Stab_A(H) in Aut(G/H)")
db.gps_subgroups.add_column("central_factor", "boolean", "H is a central factor of G if it is nontrivial, noncentral, normal and generates G together with its centralizer.  In such a case, G will be a nontrivial central product of H with its centralizer.  Moreover, any nonabelian group that has some nontrivial central product decomposition will have one of this form")

 * gps_subgroups (aut_quo_index aut_stab_index central_factor centralizer_order core_order normal_contained_in normal_contains quotient_hash subgroup_hash)
Remove columns:
 * finite_matrix_group, elt_rep_type, perm_gens, pc_code, gens_used, smallrep (replaced by irrC_degree)
Regenerate .header files
Write another job that modifies a full record along a group hom by mapping/lifting all elements
Write scripts for adding more groups later

Talk to Drew: Make sure that the version of Magma installed in the cloud has the appropriate libraries installed (Atlas, Trans32Id for example), and that LMFDB access is okay
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
update identify.py to only use psycopg2 rather than lmfdb (not require Sage)
Caching polredabs data (for now, just copied manually)
E5184.su triggering error "subgroups not closed under automorphism" on line 340 of Subgroups.m (from Comps := [C[1] : C in SplitByAuts([Comps], G : use_order:=false)];)

***********/
