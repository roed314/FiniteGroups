# To Do List

## Backend

### Planning
* Devise hash for determining isomorphism classes
* Labeling for subgroups
* Labeling for conjugacy classes
* Write more upload code

### Uploading data
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
  * On my (Jen) screen: http://teal.lmfdb.xyz/Groups/Abstract/24.5  the left hand side of the graph is currently cut off. So the C2xC4 subgroup should have a subscript to the left of it indicating the number of conjugate subgroups but I don't see that and I don't see part of the first C.
* Click vs. Mouseover of subgroups?
  * currently the diagram does both: mouseover for highlighting and click for showing information.
* Add list of orders of elements in the group to top
* Add special names (aliases) to *Construction* section
* Add permutation representations
* Make supergroups a searchable option
* Add special family presentations in those cases
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

## Knowls

* Series knowls
* Radical subgroup
* rename agroup and zgroup to a_group and z_group in code, same with rational versus rational_group
* Rename Meow Wolf to Tim
* RCS knowls

## Last Stage

* Should www.lmfdb.org/Group (or browse page like it) be where the breadcrumb www.lmfdb.org/Groups  goes?


