/* Some functions which compute the action of Aut(G) on the conjugacy classes of subgroups of G.
The idea is to compute the action of the generators of Aut(G) on a list of conjugacy classes as
permutations of the indices of the classes. Then uses Magma's built in OrbitRepresentative function.

WARNING: get_index is written for abelian groups. Edit the comments to get a version for 
non-abelian groups.
*/


// locates H_aut in subgrp_list upto conjugacy.
// Assumes G is abelian. Edit comments below to get general version for non-abelian groups.
get_index := function(subgrp_list, H_aut)
     index := -1;
     for k in [1..#subgrp_list] do
        K := subgrp_list[k];
     // if IsConjugate(G,H_aut,K`subgroup) then
     // Can use "eq" rather than "IsConjugate" if group is abelian.
     if (H_aut eq K`subgroup) then  
            index := k;
            break k;
        end if;
     end for;
     return index;
end function;

// Computes action of aut on subgrp_list (= conjugacy classes).
// Uses indices as labels for subgroups/classes and returns sequence of permuted indices.
get_index_perm_seq := function(aut, subgrp_list)
     index_perm_seq := []; // records how aut acts on the subgroups using indices as labels
     for j in [1..#subgrp_list] do
       H_aut := (subgrp_list[j]`subgroup)@aut;
       // We now search for H_aut in subgrp_list (upto conjugacy).
       index := get_index(subgrp_list,H_aut);
       if index eq -1 then
         print "Error: H_aut has not been found in subgroup list (upto conjugacy).";
       else
         Append(~index_perm_seq, index);
       end if;
     end for;
     return(index_perm_seq);
end function;


// Computes action of Aut(G) on subgroups.
find_aut_action := function(G)
   A := AutomorphismGroup(G);

   S := Subgroups(G);

   P := SymmetricGroup(#S);
   auts_as_perms_list := [];

   for i in [1..Ngens(A)] do
     aut := A.i;
     index_perm_seq := get_index_perm_seq(aut, S);
     Append(~auts_as_perms_list, P!index_perm_seq); // Coercion turns permuted list of indices into an element of P.
  end for;

  orbits := OrbitRepresentatives(sub<P | auts_as_perms_list>);
  return(orbits);
end function;


// Computes action of Aut(G) on subgroups.
// Splits subgroup/conjugacy list up into smaller lists containing subgroups of the same order.
// Makes construction permutation slightly more complicated at the end.
// Note: Small speed up, but not by much on the small number of examples considered.
find_aut_action_v2 := function(G)
   A := AutomorphismGroup(G);

   S := Subgroups(G);
   subgrp_orders := {ent`order : ent in S};
   subgrps_by_order := [[ent : ent in S | ent`order eq i] : i in subgrp_orders];

   P := SymmetricGroup(#S);
   auts_as_perms_list := [];

   for i in [1..Ngens(A)] do
     aut := A.i;
     aut_as_perm := [];
     for subgrp_list in subgrps_by_order do 
       Append(~aut_as_perm, get_index_perm_seq(aut, subgrp_list));
     end for;
     // We merge permutations on subgroups of the same order.
     // Need to translate indices so we get a permutation on {1..#S}.
     subgrp_order_stats := [#subgrp_list : subgrp_list in subgrps_by_order];
     translation_list := [0] cat [&+subgrp_order_stats[1..j] : j in [1..(#subgrp_order_stats-1)]];
     aut_as_perm_translated := [[x + translation_list[j] : x in aut_as_perm[j]] : j in [1..#aut_as_perm]];
     Append(~auts_as_perms_list, P!(&cat(aut_as_perm_translated)));
  end for;

  orbits := OrbitRepresentatives(sub<P | auts_as_perms_list>);
  return(orbits);
end function;


SAMPLE INPUT/OUTPUT
-------------------

for d in [1..7] do
 print "************* d = ",d;
 G := PCGroup(AbelianGroup([2 : i in [1..d]]));  // G = product of d copies of C_2
 time find_aut_action(G);
end for;



************* d =  1
[ <1, 1>, <1, 2> ]
Time: 0.020
************* d =  2
[ <1, 1>, <1, 5>, <3, 2> ]
Time: 0.020
************* d =  3
[ <1, 1>, <1, 16>, <7, 2>, <7, 9> ]
Time: 0.010
************* d =  4
[ <1, 1>, <1, 67>, <15, 2>, <15, 52>, <35, 17> ]
Time: 0.060
************* d =  5
[ <1, 1>, <1, 374>, <31, 2>, <31, 343>, <155, 33>, <155, 188> ]
Time: 0.800
************* d =  6
[ <1, 1>, <1, 2825>, <63, 2>, <63, 2762>, <651, 65>, <651, 2111>, <1395, 716> ]
Time: 26.440
************* d =  7
^C^C
[Interrupted]


for d in [1..7] do
 print "************* d = ",d;
 G := PCGroup(AbelianGroup([2 : i in [1..d]])); // G = product of d copies of C_2
 time find_aut_action_v2(G);
end for;

************* d =  1
[ <1, 1>, <1, 2> ]
Time: 0.020
************* d =  2
[ <1, 1>, <1, 5>, <3, 2> ]
Time: 0.010
************* d =  3
[ <1, 1>, <1, 16>, <7, 2>, <7, 9> ]
Time: 0.030
************* d =  4
[ <1, 1>, <1, 52>, <15, 2>, <15, 53>, <35, 17> ]
Time: 0.050
************* d =  5
[ <1, 1>, <1, 374>, <31, 2>, <31, 188>, <155, 33>, <155, 219> ]
Time: 0.340
************* d =  6
[ <1, 1>, <1, 2762>, <63, 2>, <63, 2763>, <651, 65>, <651, 716>, <1395, 1367> ]
Time: 15.190
************* d =  7
^C^C
[Interrupted]

*/
