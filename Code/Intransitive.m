

intrinsic it_label(H) -> MonStgElt
{H is a permutation group}
    orbs := Orbits(H);
    if #orbs eq 1 then
        label := [];
    else
        label := [Sprint(Degree(H))];
    end if;
    tlabels := [];
    tprod := 1;
    for O in orbs do
        f, A := OrbitAction(H, O);
        tprod *:= #A;
        i, n := TransitiveGroupIdentification(A);
        Append(~tlabels, [-n, i]);
    end for;
    Sort(~tlabels);
    tlabels := [Sprintf("%oT%o", -T[1], T[2]) : T in tlabels];
    counted := [];
    prev := tlabels[1];
    c := 1;
    for T in tlabels[2..#tlabels] do
        if T eq prev then
            c +:= 1;
        else
            if c eq 1 then
                Append(~counted, prev);
            else
                Append(~counted, Sprintf("%ox%o", prev, c));
            end if;
            prev := T;
            c := 1;
        end if;
    end for;
    if c eq 1 then
        Append(~counted, prev);
    else
        Append(~counted, Sprintf("%ox%o", prev, c));
    end if;
    Append(~label, Join(counted, "-"));
    if tprod ne #H then
        Append(~label, Sprint(tprod div #H));
    end if;
    if tprod div #H gt 19 then
        print label;
    end if;
    return Join(label, ".");
end intrinsic;

intrinsic ct_counts(H, ct_lookup, vlen) -> SeqEnum
{}
    C := [0 : _ in [1..vlen]];
    for c in ConjugacyClasses(H) do
        cs := CycleStructure(c[3]);
        C[ct_lookup[cs]] +:= c[2];
    end for;
    return C;
end intrinsic;

intrinsic it_labels(S) -> SeqEnum
{S should be the output of Subgroups(Sym(n))}
    SS := [H`subgroup : H in S];
    D := IndexFibers([1..#S], func<i|it_label(SS[i])>);
    labels := AssociativeArray();
    N := Degree(SS[1]);
    ctypes := [CycleStructure(c[3]) : c in ConjugacyClasses(Sym(N))];
    ct_lookup := AssociativeArray();
    for i in [1..#ctypes] do
        ct_lookup[ctypes[i]] := i;
    end for;
    Sort(~ctypes);
    for prelab in Keys(D) do
        L := D[prelab];
        if #L eq 1 then
            labels[L[1]] := prelab;
        else
            E := IndexFibers(L, func<i|ct_counts(SS[i], ct_lookup, #ctypes)>);
            ctr := 0;
            for cvec in Sort([k : k in Keys(E)]) do
                M := E[cvec];
                if #M eq 1 then
                    labels[M[1]] := prelab * "." * CremonaCode(ctr);
                else
                    dups := [];
                    for j in [1..#M] do
                        // We randomly assign the last component for the moment
                        labels[M[j]] := prelab * "." * CremonaCode(ctr) * "." * Sprint(j);
                        print labels[M[j]];
                        Append(~dups, M[j]);
                    end for;
                    print dups;
                end if;
                ctr +:= 1;
            end for;
        end if;
    end for;
    return [labels[i] : i in [1..#S]];
end intrinsic;

intrinsic count_intransitive(n::RngIntElt) -> RngIntElt
{}
    return #Subgroups(Sym(n)) - #Subgroups(Sym(n-1));
end intrinsic;

function gvec(H)
    T := AssociativeArray();
    for c in ConjugacyClasses(H) do
        k := Sort([#cyc : cyc in CycleDecomposition(c[3])]);
        if IsDefined(T, k) then T[k] +:= c[2]; else T[k] := c[2]; end if;
    end for;
    return Sort([<k, v> : k -> v in T]);
end function;

intrinsic count_intransitive(n::RngIntElt, order_bound::RngIntElt) -> RngIntElt
{}
    Sn := Sym(n);
    Tgps := [];
    filtered := AssociativeArray();
    for i in [1..NumberOfTransitiveGroups(n)] do
        print "i", i;
        T := TransitiveGroup(n, i);
        if #T gt order_bound then
            break;
        end if;
        for H in Subgroups(T) do
            gv := gvec(H`subgroup);
            if IsDefined(filtered, gv) then
                found := false;
                for K in filtered[gv] do
                    if IsConjugate(Sn, H`subgroup, K) then
                        found := true;
                        break;
                    end if;
                end for;
                if not found then
                    Append(~filtered[gv], H`subgroup);
                end if;
            else
                filtered[gv] := [H`subgroup];
            end if;
        end for;
    end for;
    total := 0;
    by_fixed := AssociativeArray();
    for gv -> L in filtered do
        for K in L do
            fixed := #Fix(K);
            if not IsDefined(by_fixed, fixed) then
                by_fixed[fixed] := 0;
            end if;
            by_fixed[fixed] +:= 1;
            total +:= 1;
        end for;
    end for;
    for fixed in Sort([k : k in Keys(by_fixed)]) do
        print n - fixed, by_fixed[fixed];
    end for;
    return total;
end intrinsic;
