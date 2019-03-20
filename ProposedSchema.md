Table name: `gps_small`

Abstract groups up to isomorphism, as in GAP and Magma.

Column            | Type    | Notes
------------------|---------|------
label             | text    | GAP ID encoded as a string `N.n`, where `N` is the order of the group and `n` distinguishes groups of the same order (as determined in GAP)
name              | text    | As in GAP's StructureDescription
pretty            | text    | LaTeXed version of `name`
order             | integer | 
exponent          | integer | 
perfect           | boolean | 
abelian           | boolean | 
cyclic            | boolean | 
simple            | boolean | 
solvable          | boolean | 
center            | text    | Label for the isomoprhism class of the center
abelian_quotient  | text    | Label for the isomorphism class of the maximal abelian quotient
derived_group     | text    | Label for the isomorphism class of the derived subgroup
maximal_subgroups | jsonb   | List of pairs `(H, m)`, where `H` is the label for a maximal subgroup (up to isomorphism), and `m` is the number of such subgroups
normal_subgroups  | jsonb   | List of pairs `(H, m)`, where `H` is the label for a normal subgroup (up to isomorphism), and `m` is the number of such subgroups
clases            | jsonb   | List of triples of integers giving information about conjugacy classes?

Table name: `gps_transitive`

Transitive group labels, as in GAP and Magma.

Column        | Type     | Notes
--------------|----------|------
label         | text     | Label is of the form `nTt` where `n` is the degree and `t` is the "t-number"
name          | text     | The name given by GAP (also used by Pari, Magma, Sage, etc)
pretty        | text     | latex of a nicer name for this group (including $)
n             | smallint | The degree (`n` from `S_n`)
t             | integer  | The `t`-number, a standard index for conjugacy classes of subgroups of `S_n`
order         | numeric  | The size of the group
gapid         | bigint   | The GAP id for the group, 0 if not known
parity        | smallint | 1 if the group is a subgroup of A_n, otherwise -1
abelian       | boolean  | 
cyclic        | boolean  | 
solvable      | boolean  | 
primitive     | boolean  | 
auts          | smallint | The number of automorphisms of a degree `n` field with this as its Galois group
arith_equiv   | smallint | Number of arithmetically equivalent fields for number fields with this Galois group
repns         | jsonb    | If `K` is a degree `n` field with this Galois group, this gives other small degree fields with the same Galois closure, up to isomorphism, in terms of their Galois groups.  List of pairs `[n, t]`
subs          | jsonb    | If `K` is a degree `n` field with this Galois group, this gives the subfields up to isomorphism in terms of their Galois groups
resolve       | jsonb    | Low degree resolvents, up to isomorphism, for the a field with this Galois group
moddecompuniq | jsonb    | ????

Table name: `gps_bravais`

Finite subgroups of GL_n(Z), up to Bravais equivalence:
For G < GL_n(Z), let F(G) be the set of symmetric nxn real matrices F with g^t F g = F for all g in G.
Let B(G) be the set of b in GL_n(Z) with b^t F b = F for all F in F(G).  Then G and G' are Bravais equivalent if B(G) is conjugate to B(G').

dim


Table name: `gps_qrep`

Finite subgroups of GL_n(Z), up to GL_n(Q) conjugacy

label          | text      | ???
dim            | smallint
order          | numeric   | The size of the group
gapid          | bigint    | The GAP id for the group, 0 if not known
trans_ids      | integer[] | List of transitive group IDs isomorphic to this finite group
abelian        | boolean
cyclic         | boolean
solvable       | boolean
irreducible    | boolean
decomposition  | jsonb     | List of pairs (lab, n) giving the decomposition as a direct sum of irreducible Q-reps.  lab is the label for the corresponding GL_n(Q)-class, and n the multiplicity
gens           | integer[] | List of matrices generating group

Table name: `gps_zrep`

Finite subgroups of GL_n(Z), up to GL_n(Z) conjugacy

label          | text     | ???
dim            | smallint
order          | numeric  | The size of the group
gapid          | bigint   | The GAP id for the group, 0 if not known
q_class        | text     | the label for the GL_n(Q) class containing this conjugacy class
indecomposible | boolean
irreducible    | boolean
decomposition  | jsonb    | List of pairs (lab, n) 
