Table name: `gps_small`

Abstract groups up to isomorphism, as in GAP and Magma.

Column            | Type    | Notes
------------------|---------|------
perfect           | boolean | 
abelian           | boolean | 
derived_group     | text    | 
exponent          | integer | 
name              | text    | 
cyclic            | boolean | 
simple            | boolean | 
center            | text    | 
maximal_subgroups | jsonb   | 
abelian_quotient  | text    | 
label             | text    | 
pretty            | text    | 
normal_subgroups  | jsonb   | 
solvable          | boolean | 
order             | integer | 
clases            | jsonb   | 

Table name: `gps_transitive`

Transitive group labels, as in GAP and Magma.

Column        | Type     | Notes
--------------|----------|------
parity        | smallint | 
ab            | smallint | 
prim          | smallint | 
name          | text     | 
gapid         | bigint   | 
gapidfull     | text     | 
moddecompuniq | jsonb    | 
label         | text     | 
cyc           | smallint | 
arith_equiv   | smallint | 
resolve       | jsonb    | 
auts          | smallint | 
pretty        | text     | 
repns         | jsonb    | 
solv          | smallint | 
t             | integer  | 
n             | smallint | 
order         | numeric  | 
subs          | jsonb    | 

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

