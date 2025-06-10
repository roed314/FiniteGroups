# To Do List

## Backend

### Planning
* Write more upload code (remaining issues are blacklist on io.m)

### Large groups

- [ ] Update `gps_special_names` to add more families (Sam)
- [ ] Come up with a numerical rating scheme for how interesting a group is
- [ ] Gather statistics on how many new groups we would need to store under various schemes (David)
- [ ] Rewrite direct_factorization to not recurse (Sam)
- [ ] Restructure the code to be able to run in multiple passes (David)
- [ ] Change NormalSubgroups so that it can be called without needing to compute all subgroups (David)

### Uploading data
* Fix bug in Magma's SmallGroupDecoding
* Store the weights in the subgroup lattice (David)
* Optimize the generating code for speed (focus on characters and subgroup lattices)
* Figure out how to reuse work between different groups for slow features (using a recursive algorithm for example)
* Design a process for adding groups outside the small groups range and assigning labels: three steps
  - find new groups of interest to add, compute their hash and specify a format to store information for the next stage
  - for each order and hash value, split the records up into isomorphism classes, determine whether each isomorphism class has already been added.  If not yet added, assign a label.  We may want to ensure that some common group families get simple labels (e.g. cyclic group is always .a)
  - With label in hand, go pass control back to the process that computes all relevant quantities about a group.  This may recurse to adding subgroups.
* Compute data for groups outside SmallGroups database, e.g., permutation groups and subgroups of finite linear groups
* Run hash on all groups of order 512, 1536, and other orders that can't be IDed.
* Add generator and relations template to families
* Add Magma coded number for families from series
* Add additional families to gps_families and gps_special_names
* Upload SmallGroup data except 512, 1024, 1536
* Very large sample examples
* Smallest n where the group is a subgroup of Sn (new Magma function)
* Improve DirectFactorization so that it doesn't need to create LMFDBGrps and compute their subgroup lattices
* Speed up IsWreathProduct to use the already computed list of subgroups
* Add complete as a property (trivial center and outer automorphism group).  More generally, check out https://en.wikipedia.org/wiki/Category:Properties_of_groups for things we might add.
* We currently compute the power map for conjugacy classes for p dividing the order of the group, but our schema suggested also including p dividing phi(exponent of G).  I'm struggling to figure out why this is sufficient to find the power map for all integers.
* Speed up monomial by using cached computations

## Frontend

* Click vs. Mouseover of subgroups?
  * currently the diagram does both: mouseover for highlighting and click for showing information.
* Add special names (aliases) to *Construction* section
* Add permutation representations
* Add special family presentations in those cases
* Data we compute but don't display yet.  Look at schema to see what we've computed.
* Magma isn't consistent about the styling on the name (SL vs C2.SL)
* Create download buttons for Magma/GAP code, data like character tables, improve downloads in other ways
* Make supergroups a searchable option (hard; can we just use the subgroup search?)
* Label characters as orthogonal, symplectic, linear, faithful on right/left or maybe in knowl as it is? Maybe some indication of these?  Update the Type code to include more info.
* Make sure we have the right indexes (try lots of reasonable searches and see what's slow.  Most likely to show up for subgroup searches since gps_groups is small right now)
* Make the subgroup lattice downloadable
* Frozen row and column headers for character tables
* Evaluate sort order for split and non-split products, don't just hide one (ie it should never say "Show all 5")
* Look at spacing/highlighting for split and non-split products (Jen)
* Add feature where user can type in a list of permutations and we try to figure out what group they generate.  This could just use GAP's `IdGroup` function in small cases, or compute a hash/do other stuff for larger cases.
* Improve the subgroup diagram layouts, via Tim's suggestions or https://sporkjs.github.io/stuff/drawlat.html for example.
* Large svgs for group pictures

## Last Stage

* Should www.lmfdb.org/Group (or browse page like it) be where the breadcrumb www.lmfdb.org/Groups  goes?


