G := MakeSmallGroup(192,181);
//GG := SmallGroup(192,181);
PrintData(G);
//c := 908908544103344226767159255808012832;
/*
  iso := G`OptimizedIso;
  GG_opt := Codomain(iso);
  IsIsomorphic(GG,GG_opt);
  SmallGroupEncoding(GG_opt);
*/

function RelatorsFromCode_test(code, size, gens)
    ff := Factorisation(size);
    f := &cat [ [x[1]: i in [1 .. x[2]]]: x in ff];
    l := #f;
    mi := Maximum(f) - 1;
    n := code;
    if #Set(f) gt 1 then
	n, n1 := Quotrem(n, mi^l);
	indices := [];
	for i in [1 .. l] do
	    n1, r := Quotrem(n1, mi);
	    indices[i] := r + 2;
	end for;
	indices := Reverse(indices);
    else
	indices := f;
    end if;

    rels := [];
    rr := [];

    id := gens[1]^0;
    for i in [1 .. l] do
	rels[i] := (gens[i]^indices[i] = id);
    end for;

    ll := l * (l + 1) div 2 - 1;
    uc := [Integers() | ];
    n, n1 := Quotrem(n, 2^ll);
    for i in [1 .. ll] do
	n1, r := Quotrem(n1, 2);
	uc[i] := r;
    end for;

    for i in [1 .. &+ uc] do
	n, n1 := Quotrem(n, size);
	g := id;
	for j in [l .. 1 by -1] do
	    n1, r := Quotrem(n1, indices[j]);
	    if r gt 0 then
		g := gens[j]^r * g;
	    end if;
	end for;
	Append(~rr, g);
    end for;
    z := 1;
    for i in [1 .. l - 1] do
	if uc[i] eq 1 then
	    rels[i] := (LHS(rels[i]) = RHS(rels[i]) * rr[z]);
	    z +:= 1;
	end if;
    end for;
    z2 := l - 1;
    for i in [1 .. l] do
	for j in [i + 1 .. l] do
	    z2 +:= 1;
	    if uc[z2] eq 1 then
		Append(~rels, (gens[j], gens[i]) = rr[z]);
		z +:= 1;
	    end if;
	end for;
    end for;
    return rels;
end function;

code := Get(G, "pc_code");
size := 192;
F := FreeGroup(&+ [Integers() | x[2]: x in Factorisation(size)]);
gens := [F.i: i in [1 .. Ngens(F)]];
RelatorsFromCode_test(code, size, gens);
