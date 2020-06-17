
cycquos := function(Lat, h)
    H := Group(h);
    D := DerivedSubgroup(H);
    A, fA := quo<H | D>; // Can maybe make this more efficient by switching to GrpAb and using Dual
    n := Order(A);
    ans := {};
    for B in Subgroups(A) do
        if B`order eq n then
            continue;
        end if;
        Bsub := B`subgroup;
        if IsCyclic(A / Bsub) then
            Include(~ans, Lat!(Bsub@@fA));
        end if;
    end for;
    return ans;
end function;

all_minimal_chains := function(G)
    assert IsSolvable(G);
    Lat := SubgroupLattice(G);
    cycdist := AssociativeArray();
    top := Lat!(#Lat);
    bottom := Lat!1;
    cycdist[top] := 0;
    reverse_path := AssociativeArray();
    cqsubs := AssociativeArray();
    Seen := {top};
    Layer := {top};
    while true do
        NewLayer := {};
        for h in Layer do
            cq := cycquos(Lat, h);
            cqsubs[h] := cq;
            for x in cq do
                if not IsDefined(cycdist, x) or cycdist[x] gt cycdist[h] + 1 then
                    cycdist[x] := cycdist[h] + 1;
                    reverse_path[x] := {h};
                elif cycdist[x] eq cycdist[h] + 1 then
                    Include(~(reverse_path[x]), h);
                end if;
                if not (x in Seen) then
                    Include(~NewLayer, x);
                    Include(~Seen, x);
                end if;
            end for;
        end for;
        Layer := NewLayer;
        if bottom in Layer then
            break;
        end if;
    end while;
    M := cycdist[bottom];
    chains := [[bottom]];
    /* The following was brainstorming that I don't think works yet....

       For now, we just use centralizers of already chosen elements.
       At each step (while adding a subgroup H above a subgroup J),
       compute the normalizer N of H and the orbits for the action of N on H.
       Similarly, the normalizer M of J and the orbits for the action of M on J.
       Those of J map to those of H, and places where the count increase
       are possible conjugacy classes from which we can choose a generator.
       We aim for those where the size of the conjugacy class is small,
       since that will yield a large centralizer with lots of commuting relations.
    */
    for i in [1..M] do
        new_chains := [];
        for chain in chains do
            for x in reverse_path[chain[i]] do
                Append(~new_chains, Append(chain, x));
            end for;
        end for;
        chains := new_chains;
    end for;
    return chains;
end function;

alphabet := "abcdefghijklmnopqrstuvwxyz";
chain_to_gens := function(chain)
    ans := [];
    G := Group(chain[#chain]);
    A := Group(chain[1]);
    for i in [2..#chain] do
        B := Group(chain[i]);
        r := IntegerRing()!(#B / #A);
        if not (A subset B) then
            // have to conjugate
            N := Normalizer(G, B);
            T := Transversal(G, N);
            for t in T do
                if A subset B^t then
                    B := B^t;
                    break;
                end if;
            end for;
        end if;
        Q, fQ := quo<B | A>;
        C, fC := AbelianGroup(Q);
        gens := Generators(C);
        assert #gens eq 1;
        g := G!((Rep(gens)@@fC)@@fQ);
        Append(~ans, <g, r, alphabet[i-1], B>);
        A := B;
    end for;
    return ans;
end function;

print_exp := function(let, a)
    if a eq 0 then
        return "1";
    elif a eq 1 then
        return let;
    else
        return let cat "^" cat Sprint(a);
    end if;
end function;

expvec := function(elt, filtration)
    if Order(elt) eq 1 then
        return [0 : _ in [1..#filtration]];
    end if;
    tup := filtration[#filtration];
    g := tup[1];
    r := tup[2];
    if #filtration eq 1 then
        H := sub<tup[4] | >;
    else
        H := filtration[#filtration-1][4];
    end if;
    for a in [0..r-1] do
        x := elt * g^(-a);
        if x in H then
            return $$(x, Prune(filtration)) cat [a];
        end if;
    end for;
end function;

normal_form := function(elt, filtration)
    if Order(elt) eq 1 then
        return "1";
    end if;
    g, r, let, H := Explode(filtration[#filtration]);
    if #filtration eq 1 then
        for a in [1..r-1] do
            if elt eq g^a then
                return print_exp(let, a);
            end if;
        end for;
        assert false;
    end if;
    H0 := filtration[#filtration-1][4];
    for a in [0..r-1] do
        x := elt * g^(-a);
        if Order(x) eq 1 then
            return print_exp(let, a);
        elif x in H0 then
            s := $$(x, Prune(filtration));
            if a eq 0 then
                return s;
            else
                return s cat "*" cat print_exp(let, a);
            end if;
        end if;
    end for;
end function;

gens_to_presentation := function(gens)
    ans := "<" cat gens[1][3];
    for i in [2..#gens] do
        ans cat:= "," cat gens[i][3];
    end for;
    ans cat:= " | ";
    for i in [1..#gens] do
        ans cat:= gens[i][3] cat "^" cat Sprint(gens[i][2]) cat "=" cat normal_form(gens[i][1]^gens[i][2], gens[1..i-1]) cat ", ";
    end for;
    for j in [2..#gens] do
        for i in [1..j-1] do
            g1 := gens[j][1];
            g2 := gens[i][1];
            if g2^g1 ne g2 then
                let1 := gens[j][3];
                let2 := gens[i][3];
                ans cat:= let2 cat "^" cat let1 cat "=" cat normal_form(g2^g1, gens[1..j-1]) cat ", ";
            end if;
        end for;
    end for;
    return Substring(ans, 1, #ans - 2) cat ">";
end function;

adjust_powers := function(gens)
    rel_powers := [];
    for i in [1..#gens] do
        g, r, let, H := Explode(gens[i]);
        Append(~rel_powers, expvec(g^r, gens[1..i-1]));
    end for;
    com_rel := [];
    for j in [2..#gens] do
        for i in [1..j-1] do
            g1 := gens[j][1];
            g2 := gens[i][1];
            Append(~com_rel, <normal_form(g2, gens[1..i]), normal_form(g1, gens[1..j]), expvec(g2^g1, gens[1..j-1])>);
        end for;
    end for;
    return rel_powers, com_rel;
end function;

show_presentations := procedure(G)
    for chain in all_minimal_chains(G) do
        print gens_to_presentation(chain_to_gens(chain));
    end for;
end procedure;

centralizer_sizes := function(G)
    return {* <Order(Centralizer(G, C[3])), C[2]> : C in Classes(G) *};
end function;

gen_types := function(G, m)
ngens := #FewGenerators(G);
N := Order(G);
cyc_data := AssociativeArray();
for i in [1..m] do
    gens := [];
    for j in [1..ngens] do
        Append(~gens, Random(G));
    end for;
    H := sub<G|gens>;
    if Order(H) eq N then
        cyc_types := Sort([CycleStructure(g) : g in gens]);
        if not IsDefined(cyc_data, cyc_types) then
            cyc_data[cyc_types] := 0;
        end if;
        cyc_data[cyc_types] +:= 1;
    end if;
end for;
return cyc_data;
end function;
