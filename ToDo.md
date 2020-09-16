# To Do List

## Backend

### Planning
* ~Choosing generators (solvable, permutation and matrix cases)~
* ~Labeling for conjugacy classes~
* ~Labeling for subgroups~
* How to deal with "bad" generator lists from polycyclic (in progress: David)
* Write more upload code (remaining issues are blacklist on io.m)

### Uploading data
* ~Create framework for computing LmfdbGroup attributes from a Magma group with a few small examples~
* ~Make a list of attributes that can't be directly imported from the Magma group~
* ~Port over implementations from generate.py for some of these~
* ~Figure out how to compute others in Magma~
* ~Implement hash for determining isomorphism classes~
* Run timing tests to determine which attributes are slow (in progress)
* Streamline Magma code that may redundantly call Magma functions which are now attributes.
* Figure out how to reuse work between different groups for slow features (using a recursive algorithm for example)
* Figure out criterion/heuristic for when to compute difficult/space-intensive things (lattice of subgroups, etc).
* Design a process for adding groups outside the small groups range and assigning labels: three steps
  - find new groups of interest to add, compute their hash and specify a format to store information for the next stage
  - for each order and hash value, split the records up into isomorphism classes, determine whether each isomorphism class has already been added.  If not yet added, assign a label.  We may want to ensure that some common group families get simple labels (e.g. cyclic group is always .a)
  - With label in hand, go pass control back to the process that computes all relevant quantities about a group.  This may recurse to adding subgroups.
* Run hash on all groups of order 512, 1536, and other orders that can't be IDed.
* Add generator and relations template to families
* Add Magma coded number for families from series
* Add additional families to gps_families and gps_special_names
* Upload SmallGroup data except 512, 1024, 1536
* Very large sample examples


## Frontend

* Character tables visible or add conjugacy classes (and order statistics)
* Create subgroup lattice as graph
  * I added a version of this using a canvas.  Here are some notes
  * Subgroups have an intial layout which might not be great, but it could be worse, and they are dragable
  * Clicking on a subgroup gives information about that subgroup below the canvas
  * Subgroups have typeset pretty names
  * On the downside, the typesetting is done beforehand and are png's included in static/graphs/img.  There are ~17000 of them
  * This covers over 17,000 groups because there are many duplicates
  * Putting them by other means probably means using foreignobject on the canvas.  I can do that with formatted html, but it looks worse and does not work as well
  * Using katex looks pretty complicated right now (just getting katex html does not work)
  * Using mathjax might be an option, but then we have mathjax and katex, and it still might not work/look good.  There is some hope of using svg output from mathjax, especially with version 3
  * We could generate images on the fly. I have done this with WeBWorK problems, and it worked ok there.  But, I am not sure I want to put the time in to set it up if we don't want to go in that direction
  * On my (Jen) screen: http://teal.lmfdb.xyz/Groups/Abstract/24.5  the left hand side of the graph is currently cut off. So the C2xC4 subgroup should have a subscript to the left of it indicating the number of conjugate subgroups but I don't see that and I don't see part of the first C. (Update: was fixed and now issue again on 8/10/20)
* Click vs. Mouseover of subgroups? (Still needs to be fixed in new version in 2020?)
  * currently the diagram does both: mouseover for highlighting and click for showing information.
* Add list of orders of elements in the group to top
* Add special names (aliases) to *Construction* section
* Add permutation representations
* Make supergroups a searchable option
* Add special family presentations in those cases
* Data we compute but don't display yet.  Look at schema to see what we've computed. 
* Change group characteristics list to be more like:  "cyclic (and so abelian, solvable, nilpotent, and monomial)"  instead of just full list
    * Z-group means metacyclic, supersolvable, and monomial
    * Cyclic hence abelian, solvable, nilpotent, and monomial
    * Abelian hence solvable, nilpotent, and monomial
    * Metabelian hence solvable
    * Metacyclic hence metabelian, supersolvable, and monomial
    * Monomial hence solvable 
    * Supersolvable hence monomial
* Create download buttons for Magma/GAP code
* Improve searches
* For complex characters, writing entries in a more efficient way. EX:  https://groups.lmfdb.xyz/Groups/Abstract/21.2  reduce some of them via trace reduction. Perhaps consider naming one recurring "phrase" as a variable.  Maybe long term toggle back and forth.
* Label characters as orthogonal, symplectic, linear, faithful on right/left or maybe in knowl as it is? Maybe some indication of these?
* Cutoff for pre-displaying character table.


## Knowls

* ~Series knowls~
* ~Radical subgroup~
* rename agroup and zgroup to a_group and z_group in code, same with rational versus rational_group
* Rename Meow Wolf to Tim
* RCS knowls
* Dynamic Knowls edited

## Last Stage

* Should www.lmfdb.org/Group (or browse page like it) be where the breadcrumb www.lmfdb.org/Groups  goes?


