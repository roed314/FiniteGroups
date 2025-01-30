# FiniteGroups
Repository for finite groups in the LMFDB



## Sample Code

To run the code in this repository, first navigate to the Code folder and type the following in Magma: 
```
AttachSpec("spec");
```

To create groups, we type  
```
G:=MakeBigGroup("description","label")
```

If an attribute for the particular group is already assigned, it can be called with a command like:
```
G`attribute
```
Otherwise, the following call will compute the attribute if it is not yet computed and then return the attribute.
```
Get(G,"attribute");
```
Attributes can be found in the LMFDBGrp.m file. 

Here is an example using the group 7T7 from the  transitive group database.
```
G:=MakeBigGroup("7T7", "5040.w");
n:=Get(G,"order");
cc:=Get(G,"number_conjugacy_classes"); 
n; cc;
Get(G,"transitive_degree");
S:=Get(G,"Subgroups");
```
This should return 96 subgroups.  

And here is a group from the small groups database. 
```
G:=MakeBigGroup("24.10","24.10");
H:=G`MagmaGrp;
T:=Get(G,"ConjugacyClasses");
```

### Defining a unique string for each group

We have functionality to  produce a string from which a group can be reconstructed, up to isomorphism. Note that it does not guarantee the same presentation or choice of generators.
```
G:=SL(2,13);
str:=GroupToString(G);
K:=StringToGroup(str);
IsIsomorphic(G,K);
```

And given a stored string, we can produce the group. For example, this permutation group is the group 1536.408544622.
```
G := StringToGroup("18Perm3909035769,9251075123055,36697503,5813630607504594,210629534583033,965711180568,220694196784756,210629864803832,3588449545742302,390");
```

### Other sources of groups

Here are some other sample groups demonstrating different  sources for groups. 

An example of a non-simple perfect group:
```
G:=MakeBigGroup("Perf286", "2160.a");
Get(G,"simple");
```

A PC group given by a code
```
G:=MakeBigGroup("549PC7347719","549.4");
```

A PC group given by CompactPresentation
```
G:=MakeBigGroup("3721pc2,-61,61","3721.2");
```

An arbitrary permutation group
```
G:=MakeBigGroup("21Perm29207796265332120292,7544853758254297717", "1680.397");
Get(G,"Generators");
```

A matrix group over a finite prime field
```
G:=MakeBigGroup("2,5MAT454,49,252", "96.67");
Get(G,"Generators");
```

A matrix group over a finite non-prime field
```
G:=MakeBigGroup("2,q8MAT3263,2565,73", "3528.a");
```

A matrix group over Z
```
G:=MakeBigGroup("4,0,3MAT15503524,994920", "576.8277");
```

A group of Lie type
```
G:=MakeBigGroup("SL(4,5)","29016000000.a");
```

Finally, you can pass in maps between isomorphic groups.
```
G:=MakeBigGroup("2401pc4,-7,7,7,7--117993,117692,5058950,2657222-->2,49MAT117993,2657222,117692,5058950","2401.15");
```
The elements in the case  will be saved as elements of the codomain (a matrix subgroup of GL(2,49)) but computations will be done in the domain (a pc group).  And then to see the map and the generators of the group in the codomain:
```
hom:=G`ElementReprHom;
LoadElt("117993", Codomain(hom));
LoadElt("2657222", Codomain(hom));
LoadElt("117692", Codomain(hom));
LoadElt("5058950", Codomain(hom));
```

### Database requirements

For some of the groups,  additional  databases from Magma need to be installed.
* Trn32IdData, which needs to go in libs/data/TrnGps/Trn32IdData
* TrnGps32, which extracts into libs/data/TrnGps (adding files trans32.dat and trans32.ind).
* Atlas, which extracts into libs/data/Atlas.
* data3to8, which extracts into libs/data/data3to8.




## Current process for adding groups

1. Create input files in the `Code/DATA` folder by labeling and concatenating files from various sources.
  * `to_add.txt` with lines consisting of the groups to add, formatted as either a label (for groups with a small group id) or a space separated list of [a label, the hash, a display string and a string for computing with] (e.g. `1024.dig 8786600968869603230 32T65262 32T65262`)
  * `aliases.txt` and `mat_aliases.txt` with lines consisting of a label, a space, and a description (e.g. `512.1 2,257MAT10224231` and `2.1 2,6MAT560`)
  * `TinyLie.txt` in the same format, with groups of Lie type that have small group ids (e.g. `180.19 GL(2,4)`)
  * `PerfChevSpor.txt` giving translations of Perf, Chev and sporadic group codes into concrete permutation and matrix group descriptions (e.g. `Perf1 5Perm8,25`)
  * `LieGens.txt` consisting of group descriptions (and thus explicit generators) for classical groups of Lie type, with each line consisting of a magma command, a space, and a description (e.g. `GL(2,9) 2,q9MAT173,732`)
  * `nTt_to_Perm.txt` consisting of explicit generators for transitive permutation groups (e.g. `16T1085 16Perm12526722811577,5606450467177,14002566278422`)
  * `abelian.txt` lists the labels of the abelian groups to be added, used so that abelian groups always prioritize their polycyclic presentation over a permutation representation.
  * In the `homs` folder, add maps to permutation groups and polycyclic groups from groups that are harder to compute with, such as matrix groups over Z/N (e.g. `homs/1024.bf` contains `1024pc10,2,2,2,2,2,2,2,2,2,2,20,12602,1942,11843,3143,113,624,144,7866,2836,206--21513,48261,54373,61575,15427-->2,16Mat1,8,0,1,1,4,0,1,1,2,0,1,9,0,0,1,3,0,0,1,9,0,0,9,1,8,8,9,7,12,4,3,13,12,4,5,3,12,4,3`)
  * In the `pcreps` folder, give polycyclic presentations by listing the output of `SmallGroupEncoding`, the generators used, and the output of `CompactPresentation` (e.g. `pcreps/1024.bo` contains `24137635498254323920630793634327656083180394407851|1,2,4,6,8|10,2,2,2,2,2,2,2,2,2,2,7680,601,51,602,113,21125,175,40326,26257,1657,237,268|17800996435040569003106554739653241,35031083215738271150547183770583655,26340829465340581229718422655917118,34580164663022324854485395269967086,66960863642116864457196449188071078`).  The `pcreps_fast` and `pcreps_fastest` contain files with the same format, but produced by algorithms that are faster to run.
  * In the `RePresentations` folder, give the output of `CompactPresentation`, along with generators used and a time spent (e.g. `RePresentations/100.10` contains `<PCGroup([ 4, -2, -2, -5, -5, 8, 98, 102, 1283 ]), [ 4, 3, 1 ], 0.240>`)
  * In the `minreps` folder, give the minimal degree permutation representations, giving the label, a description, the degree, and encoded generators for permutations in that degree (e.g. `minreps/1024.bo` contains `1024.bo|2,16Mat1,8,0,1,1,4,0,1,1,2,0,1,9,0,0,1,3,1,0,1,9,0,0,9,1,8,8,9,13,8,8,5,7,12,4,3,3,12,4,3|32|{97575703332664760306835443712000,17800996435040569003106554739653241,43069475033578083881057708593152000,26278631729877200938898280140268692,35092986950487841343844644183560602,43069475033578083881063516986888602,42989583273087273728074402253135086,9090923229567031635381750036860221,26349671180800888109669597755820520,26871335136546588359936854917464802}`)
2. Use `create_descriptions.py` to create cloud input data:
  * The `descriptions` folder, with files named by label and contents the output of `StringToGroup` on a group with that label
  * The `preload` folder, with files named by label and contents the quantities for that group that have already been created (label, hash, representations, element_repr_type, transitive degree, permutation degree, pc rank, name, tex_name, some others in certain cases).  These files are used to prepopulate quantities that are already known.
  * The `hash_lookup` folder, with subfolders for each label, files for each hash containing lines with the labels having that order and hash.
3. Use `cloud_prep.py` to create a tarball containing all of the code needed for running in the cloud.  This currently needs a bit of cleaning up.
4. Extract the tarball anywhere you like, then run `./cloud_compute.py M`, where `M` is an integer from 1 to the number of groups (you can also run multiple such commands in parallel).  This will copy all output to the `output` file, labeled with a prefix.
5. If running computations on multiple machines, collect all the output files and concatenate them into one large output file.  Then run `cloud_collect.py` to produce upload files for postgres (this file needs a bit more work).





## Census of Files

In addition to the data files described above, which are not committed to the repository, the following code files exist:

### Magma code files in the spec

* LMFDBGrp.m - the LMFDB type definitions, along with the `Get` intrinsic.
* Basics.m - Assigning basic attributes that just correspond to a magma function.
* GrpAttributes.m - Attributes for groups, including some nontrivial functions.
* SubGrpAttributes.m - Attributes for subgroups, including some nontrivial functions.
* Subgroups.m - Code for computing subgroup lattices (including up to automorphism)
* Hash.m - Code for hashing groups and identifying groups with order 512, 1536, 1152, 1920, etc.
* Label.m - Code for labeling a group, including testing isomorphism with stored groups having the same hash.
* LabelSubgroups.m - Code for labeling subgroups.
* Presentation.m - Code for computing human readable polycyclic presentations.
* orderCC.m - new code for ordering conjugacy classes.
* utils.m - Utility functions, including `GroupToString` and `StringToGroup`.  Also includes descriptions for sporadic groups, which should probably be removed (they're needed for `StringToGroup("He")` to work, but that's probably not needed if we construct the `descriptions` and `preload` folders correctly.
* IO.m - core code for reading and writing data to disk
* ConjClsAttributes.m - Attributes for conjugacy classes.
* ChtrAttributes.m - Some basic attributes for complex and rational characters, though many attributes are set explicitly on creation.
* RepAttributes.m - Attributes for complex and rational LMFDB matrix groups.  Not currently in the code path for the cloud computation.
* makereps.m - Code for producing complex and rational LMFDB matrix groups.  Not currently in the code path for the cloud computation.
* random.m - our pseudorandom number generator
* lehmer.m - encoding and decoding permutaations as integers
* BigGroups.m - contains `MakeBigGroup`, which is intended to generalize `MakeSmallGroup` to the case where we need to pass in a description.  The other two intrinsics are not currently used, and I'm using this file as an impromptu todo list (which should change).
* creplabels.m - labeling complex reps
* counter.m - implements an `inc_counter` intrinsic which is used in writing cyclotomic elements
* Quotients.m - Code for constructing permutation representations of quotient groups
* SmallGroups.m - Code for constructing small groups.  I don't think these intrinsics are used in the current cloud code path.
* ProfileSmallGroups.m - profiling code for trying to find slow functions.  Not used in production.
* Intransitive.m - experimental code for producing labels of intransitive groups; not currently used, but may be useful for a future census of all subgroups of S_n.
* LC.m - Lewis' code, currently all commented out
* mb.m - Michael's code; no intrinsics, so can be removed from the spec
* mb-gp-elts.m - some code of Michael's that's not currently used (would be used if `ordercc` was ever called with `dorandom=false`)
* Samples.m - Old code that was used for testing.

### Magma scripts

#### Current main magma script

* ComputeCodes.m

#### Scripts for producing groups for inclusion in `to_add.txt`

* GLqSmallSubs.m - Code that produces matrix groups over finite fields (currently modified to only give ones that have a small group id, for finding aliases)
* GLqSubs.m - Code for producing matrix groups over finite fields
* GLZNSmallSubs.m - Code for extracting subgroups of GL(2, Z/N) from data provided by Drew
* lie.m - Code for adding classical groups of Lie type up to certain bounds


#### Other scripts

* AddHashes.m - a script for computing hashes of small groups in parallel (this was used to compute the hashes of groups of order 1536)
* HardIdDesc.m - script for identifying groups where Magma's `IdentifyGroup` fails with "coset table too large", such as `StringToGroup("2,983MAT949863071,560418631335,23746552176")`.


#### Old, experimental, and unused scripts

Some of these were used in producing the input folders for the cloud process or in older processes, but none of them are in the direct computation path now.  Some of these should be deleted, while others should be kept.

* AddSmallGroups.m - The old script for computing data, before the cloud process was created.
* ArithEquiv.m - Script for determining the `arith_equiv` column of `gps_transitive`.
* autone.m - Script for computing the automorphism groups of transitive groups.
* AutPrep.m - Script for recomputing optimized presentations
* AutTest.m - Testing whether AutomorphismGroup or AutomorphismGroupSolubleGroup is faster for solvable groups.
* CCexperiment.m - Looking for cases where ConjugacyClasses or CyclicSubgroups is slow
* CheckMinrep.m - Search for bugs in Magma's MinimalDegreePermutationRepresentation by using MyQuotient to randomly try to find a smaller permutation representation
* ComputeAll.m - An earlier version of the master cloud script that just ran through all of the attributes needed and computed them sequentially.
* ComputeBasic.m - The first of a sequence of scripts designed to split up the computation, made obsolete by `ComputeCodes.m`
* config.m - This just attaches the spec?  I'm not sure why it exists.
* decoding_test.m - Testing the magma decoding bug for 192.181.
* Explore.m - Some code for testing what iteratively adding various characteristic subgroups would look like (it turned out to yield too many groups for the moment, though it may be worth it in the future)
* FindHom.m - an attempt to reconstruct a homomorphism from a polycyclic group to a matrix group from stored output.  Produces an invalid homomorphism currently (f(gg') != f(g)f(g') for random g,g'), for reasons I don't understand.
* generators.m - experimental code that grew up into `Presentation.m`
* hashmany.m - another script for hashing small groups
* hashone.m - hash a single description at the command line
* IdDesc.m - Script that identifies small and transitive groups from a description
* Irreps.m - Experimental code for attempting to use `IrreducibleModules` to produce mod-p representations.
* KerTest.m - Function for testing a magma bug in the kernel of a character that has now been fixed.
* MakePCInput.m - Preparatory code for running `Presentation.m` at scale (since some of the intrinsics there need a permutation group as input)
* Matreps.m - Experimental code for finding faithful representations as a matrix group
* MinimalDegreeTest.m - Another script for testing Magma's `MinimalDegreePermutationRepresentation` by iterating over small groups
* minimizeone.m - Used for parallelizing the computation of `MinimalDegreePermutationRepresentation`.
* MinReps.m - Experimental code for checking `MinimalDegreePermutationRepresentation` using generating functions.
* MinReps2.m - Obsolete script for computing `MinimalDegreePermutationRepresentation` based on the postgres output files
* MinReps3.m - Obsolete script for computing `MinimalDegreePermutationRepresentation`
* MinReps4.m - Current script for computing `MinimalDegreePermutationRepresentation` in parallel (tracks images of generators)
* OnlySolv.m - Simple script for removing nonsolvable groups from the todo list for computing polycyclic presentations.
* PCbug.m - Tries to print out the compact presentations for pc groups; will fail when it runs into the magma bug in SmallGroupDecoding.
* PCreps_fast.m - Script for constructing the `pcrep_fast` folder, using `RePresentFast` from `Presentation.m`.
* PCreps.m - Script for constructing the `pcreps` folder, using `RePresent` from `Presentation.m`.
* Permreps.m - Script for computing a (non-minimal) permutation representation, for inputs that require such.
* PrepPCInput.m - Script that prepares for the PCreps computations by writing permutation group descriptions to the relevant folders todo folders.
* redo_direct.m - Script for fixing the `direct_product` column directly, since there was a bug in an earlier version of the code and we wanted to update the database without having to wait for the new computations.
* rep-test.m - Simple experimental script for showing cyclotomic elements in character table
* stanpresone.m - Experimental script for testing how fast the sandard presentation of a p-group is.
* TCheck.m - Script for splitting up clusters of transitive groups (should probably have been split off into https://github.com/roed314/TransitiveClusters along with other code).
* test_attrs.m - Simple test script for checking which attributes are succeeding.
* TestHolomorph.m - Script for testing whether the output is the same when using holomorphs as when using a graph-based method.
* transitive_autone.m - Uses the normalizer in Sym(n) to attempt to find the automorphism group of a permutation group
* trivial-test.m - test for the trivial group
* UpdateMAT.m - The format for saving matrix groups changed at some point; this script updates from the old format to the new
* UpdatePerm.m - Explicitly stores generators in the description, even for transitive permutation groups


