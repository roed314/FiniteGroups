
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

intrinsic pc_code(G::LMFDBGrp) -> RngInt
    {This should be updated to give a better presentation}
    pccode := SmallGroupEncoding(G`MagmaGrp);
    return pccode;
end intrinsic;
