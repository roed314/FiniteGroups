Table name: `gps_small`

Abstract groups up to isomorphism, as in GAP and Magma.

Column            | Type    | Notes
------------------|---------|------
perfect           | boolean | 
abelian           | boolean | 
derived_group     | text    | Label for the isomorphism class of the derived group
exponent          | integer | 
name              | text    | As in GAP's StructureDescription
cyclic            | boolean | 
simple            | boolean | 
center            | text    | Label for the isomoprhism class of the center
maximal_subgroups | jsonb   | List of pairs `(H, m)`, where `H` is the label for a maximal subgroup (up to isomorphism), and `m` is the number of such subgroups
abelian_quotient  | text    | Label for the isomorphism class of the maximal abelian quotient
label             | text    | GAP ID encoded as a string `N.n`, where `N` is the order of the group and `n` distinguishes groups of the same order (as determined in GAP)
pretty            | text    | LaTeXed version of `name`
normal_subgroups  | jsonb   | List of pairs `(H, m)`, where `H` is the label for a normal subgroup (up to isomorphism), and `m` is the number of such subgroups
solvable          | boolean | 
order             | integer | 
clases            | jsonb   | List of triples of integers giving information about conjugacy classes?

Table name: `gps_transitive`

Transitive group labels, as in GAP and Magma.

Column        | Type     | Notes
--------------|----------|------
parity        | smallint | 1 if the group is a subgroup of A_n, otherwise -1
ab            | smallint | Whether or not the group is abelian: 1 if yes, 0 if no
prim          | smallint | Whether or not the permutation representation is primitive, 1 for yes, 0 for no
name          | text     | The name given by GAP (also used by Pari, Magma, Sage, etc)
gapid         | bigint   | The GAP id for the group, 0 if not known
gapidfull     | text     | GAP id of the group as a pair [order, number], or empty string if it is not available
moddecompuniq | jsonb    | ????
label         | text     | Label is of the form `nTt` where `n` is the degree and `t` is the "t-number"
cyc           | smallint | 1 if the group is cyclic, otherwise 0
arith_equiv   | smallint | Number of arithmetically equivalent fields for number fields with this Galois group
resolve       | jsonb    | Low degree resolvents, up to isomorphism, for the a field with this Galois group
auts          | smallint | The number of automorphisms of a degree `n` field with this as its Galois group
pretty        | text     | latex of a nicer name for this group (including $)
repns         | jsonb    | If `K` is a degree `n` field with this Galois group, this gives other small degree fields with the same Galois closure, up to isomorphism, in terms of their Galois groups.  List of pairs `[n, t]`
solv          | smallint | 1 if the group is solvable, otherwise 0
t             | integer  | The `t`-number, a standard index for conjugacy classes of subgroups of `S_n`
n             | smallint | The degree (`n` from `S_n`)
order         | numeric  | The size of the group
subs          | jsonb    | If `K` is a degree `n` field with this Galois group, this gives the subfields up to isomorphism in terms of their Galois groups

Table name: `gps_gmodules`

Finite dimensional representations of transitive groups

Column   | Type     | Notes
---------|----------|------
dim      | smallint | 
complete | smallint | 
index    | smallint | 
gens     | jsonb    | 
n        | smallint | 
t        | smallint | 
name     | text     | 

Table name: `gps_sato_tate`

Sato-Tate groups

Column             | Type     | Notes
-------------------|----------|------
real_dimension     | smallint | 
trace_zero_density | text     | 
identity_component | text     | 
name               | text     | 
degree             | smallint | 
trace_histogram    | text     | 
moments            | jsonb    | 
components         | smallint | 
gens               | jsonb    | 
weight             | smallint | 
label              | text     | 
supgroups          | jsonb    | 
rational           | boolean  | 
counts             | jsonb    | 
pretty             | text     | 
component_group    | text     | 
subgroups          | jsonb    | 

Table name: `gps_sato_tate0`

Identity components of Sato-Tate groups

Column         | Type     | Notes
---------------|----------|------
description    | text     | 
degree         | smallint | 
label          | text     | 
pretty         | text     | 
real_dimension | smallint | 
name           | text     | 

