# To Do List
**Bold** items indicate requirements to get to beta.

## Backend

### Planning
* How to deal with "bad" generator lists from polycyclic (in progress: David)
* Write more upload code (remaining issues are blacklist on io.m)

### Uploading data
* Fix bug in Magma's SmallGroupDecoding
* **Work around Magma's SmallGroupDecoding bug by using %m**
* **Rerun the basic computation up to 511: currently have SmallGroups up to order 383, excluding a few hard groups** (John, do last)
* **Make sure we use given generators to order conjugacy classes and subgroups.** (David)
* **Revise subgroup labels** (David)
* **Store the weights in the subgroup lattice** (David)
* Run timing tests to determine which attributes are slow (in progress)
* Streamline Magma code that may redundantly call Magma functions which are now attributes.
* Figure out how to reuse work between different groups for slow features (using a recursive algorithm for example)
* **Evaluate our criterion/heuristic for when to compute difficult/space-intensive things (lattice of subgroups, etc)**
* Timing dictionary saved to output
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
* Write to Tim Dokchitser about status on adding his group names to Magma
* Smallest n where the group is a subgroup of Sn (new Magma function)

## Frontend

* **Display the rank and Eulerian function information** (Lewis)
* Character tables visible or add conjugacy classes (and order statistics)
* Cutoff for pre-displaying character table.
* Click vs. Mouseover of subgroups? (Still needs to be fixed in new version in 2020?)
  * currently the diagram does both: mouseover for highlighting and click for showing information.
* **Add list of orders of elements in the group to top** (Manami)
* **Add list of dimensions of irreducible representations just below** (Manami)
* **Make Schur multiplier prettier (look at direction factorization code)** (Manami)
* Add special names (aliases) to *Construction* section
* Add permutation representations
* Add special family presentations in those cases
* Data we compute but don't display yet.  Look at schema to see what we've computed.
* Magma isn't consistent about the styling on the name (SL vs C2.SL)
* Create download buttons for Magma/GAP code, data like character tables
* Improve searches (add more things to search on)
* Make supergroups a searchable option
* Label characters as orthogonal, symplectic, linear, faithful on right/left or maybe in knowl as it is? Maybe some indication of these?  Update the Type code to include more info.
* Make sure we have the right indexes
* Figure out why advanced search options open by default
* **Make a big version of the subgroup lattice, a la xkcd** (John)
* Make the subgroup lattice downloadable
* Frozen row and column headers for character tables
* Evaluate sort order for split and non-split products, don't just hide one
* Look at spacing/highlighting for split and non-split products (Jen - not for beta)
* **Merge with master** (once almost ready to get into beta)
* **Check that the presentation is correct** (Jen, David)


## Knowls
* **RCS knowls (after we upload the data) and update credits after merging with master**

## Last Stage

* Should www.lmfdb.org/Group (or browse page like it) be where the breadcrumb www.lmfdb.org/Groups  goes?


