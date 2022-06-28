print "Testing direct product code";

print "Testing products that gave incorrect output in the past";
gp_strings :=
[
  "C_2^5",
  "C_4^3",
  "D_4^2",
  "C_2^6",
  "C_3^4",
  "C_2^7",
  "S_3^3",
  "C_3^5",
  "C_4^4",
  "D_8^2",
  "Q_{16}^2",
  "C_2^8",
  "D_{12}^2",
  "C_5^4",
  "C_9^3",
  "C_3^6",
  "C_{11}^3",
  "D_{20}^2"
];

facts := 
[
  [ <"2.1", 5> ],
  [ <"4.1", 3> ],
  [ <"8.3", 2> ],
  [ <"2.1", 6> ],
  [ <"3.1", 4> ],
  [ <"2.1", 7> ],
  [ <"6.1", 3> ],
  [ <"3.1", 5> ],
  [ <"4.1", 4> ],
  [ <"16.7", 2> ],
  [ <"16.9", 2> ],
  [ <"2.1", 8> ],
  [ <"24.6", 2> ],
  [ <"5.1", 4> ],
  [ <"9.1", 3> ],
  [ <"3.1", 6> ],
  [ <"11.1", 3> ],
  [ <"40.6", 2> ]
];

for i := 1 to #gp_strings do
  name := gp_strings[i];
  printf "Testing %o\n", name;
  GG := Group(name);
  assert DirectFactorization(GG);
  assert direct_factorization(GG) eq facts[i];
end for;

GG := SmallGroup(1296,3538);
assert DirectFactorization(GG);
assert direct_factorization(GG) eq [ <"6.1", 4> ];

print "Testing some big abelian groups";
names := ["C_2^12", "C_3^8", "C_5^7", "C_210", "C_2310"];
facts :=
[
  [ <"2.1", 12> ],
  [ <"3.1", 8> ],
  [ <"5.1", 7> ],
  [ <"2.1", 1>, <"3.1", 1>, <"5.1", 1>, <"7.1", 1> ],
  [ <"11.1", 1>, <"2.1", 1>, <"3.1", 1>, <"5.1", 1>, <"7.1", 1> ]
  ];
for i := 1 to #names do
  name := names[i];
  GG := Group(name);
  t0 := Cputime();
  facts_test := direct_factorization(GG);
  t1 := Cputime();
  printf "%o took %o seconds\n", name, t1-t0;
  assert facts_test eq facts[i];
end for;

print "Testing non-direct semidirect products";
for GG in [* Sym(4), DihedralGroup(53), SmallGroup(1000,30) *] do
  assert SemidirectFactorization(GG);
  assert not DirectFactorization(GG);
end for;

print "Testing non-semidirect products";
for GG in [* CyclicGroup(1009), SmallGroup(1296,707), SmallGroup(1320,13) *] do
  assert not SemidirectFactorization(GG);
  assert not DirectFactorization(GG);
end for;
