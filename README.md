# FiniteGroups
Repository for finite groups in the LMFDB

Adding Groups
=============
To add all groups of a given order in the SmallGroups database, use the `AddSmallGroups.m` file.

To add groups, you first need to determine their labels and labels for any subgroups/quotients that should also be added.

Step 1: generate a file with a line for each group you want to add.  Each line should be of the following form:
`G outer_equivalences index_bounds numsub_limits normals maximals sylows CTbounds RCTbounds`
where
- `G` is a string with no spaces evaluating to the desired group in Magma,
- `outer_equivalences` is a comma separated list of either `t`, `f` or `auto` determining whether to compute subgroups up to automorphism at each level of recursion.  `auto` uses `index_bounds` and `numsub_limits`