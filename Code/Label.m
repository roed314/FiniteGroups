intrinsic HaveKnownHashes(N::RngIntElt) -> BoolElt
{Whether there are any stored hashes for groups of the given order}
    return System(Sprintf("test -d DATA/hash_lookup/%o", N)) eq 0;
end intrinsic;

intrinsic GroupsWithHash(N::RngIntElt, h::RngIntElt) -> List
{Loads groups from the hash folder}
    hfile := Sprintf("DATA/hash_lookup/%o/%o", N, h);
    ok := OpenTest(hfile, "r");
    if ok then
        labels := Split(Read(hfile), "\n");
        descs := [strip(Read("DATA/descriptions/" * label)) : label in labels];
        homs := [* StringToGroupHom(descs[i]) : i in [1..#labels] *];
        return [* <labels[i], ">>" in descs[i] select Codomain(homs[i]) else Domain(homs[i])> : i in [1..#labels] *];
    else
        return [* *];
    end if;
end intrinsic;

intrinsic PossiblyLabelable(N::RngIntElt) -> BoolElt
{Returns false when label will always return None for groups of order N}
    return CanIdentifyGroup(N) or N in SmallhashOrders() or HaveKnownHashes(N);
end intrinsic;

intrinsic label(G::Grp : hsh:=0, strict:=true, giveup:=false) -> Any, Map
{Assigns label for small groups using IdentifyGroup, and for larger groups by using hashes.
Because of Magma bugs in IsIsomorphic, when strict is false this may return None even when there is a known group that matches.  If strict is true, it will raise an error.
If giveup is true, then rather than running through options with the right hash (which can be very expensive), it will just return GroupToString (surrounded by ? in order to facilitate later replacement) of the input for later labeling.
}
    // There is a bug in Magma which sometimes gives #G = 0.
    N := #G;
    if N eq 0 then
        error Sprintf("Hit bug in Magma giving a group of order 0!");
    elif N eq 1 then
        // work around bug in IdentifyGroup
        return "1.1", _;
    end if;
    if CanIdentifyGroup(N) then
        if hsh ne 0 then
            id := <N, hsh>;
        else
            id := IdentifyGroup(G);
        end if;
    elif N in SmallhashOrders() then
        if hsh eq 0 then hsh := hash(G); end if;
        id := IdentifyGroups([G] : hashes:=[hsh])[1];
    elif not HaveKnownHashes(N) then
        return None(), _;
    else
        if giveup then
            return "?" * GroupToString(G : use_id:=false) * "?", _;
        end if;
        if hsh eq 0 then hsh := hash(G); end if;
        Hs := GroupsWithHash(N, hsh);
        for pair in Hs do
            label, H := Explode(pair);
            if strict then
                // In some cases (such as adding new groups), we don't want to skip over groups if IsIsomorphic fails since that might yield isomorphic groups with the same label
                found, phi := IsIsomorphic(H, G);
            else
                try
                    // There's a bug in IsIsomorphic (Runtime error in 'ConstructOneOrbitInternal': matrix has too many columns)
                    found, phi := IsIsomorphic(H, G);
                catch e
                    // In other cases (such as trying to label the automorphism group), we'd rather gracefully fail with None.
                    print e;
                    print "Warning: Label->IsIsomorphic failed";
                    continue;
                end try;
            end if;
            if found then
                return label, phi;
            end if;
        end for;
        return None(), _;
    end if;
    label:= Sprintf("%o.%o", id[1], id[2]);
    return label, _;
end intrinsic;

declare type TData;
declare attributes TData:
  label,
  small_opts,
  med_opts,
  med_complete;

intrinsic TransitiveData(label::MonStgElt) -> TData
{}
    T := New(TData);
    T`label := label;
    T`small_opts := {};
    T`med_opts := AssociativeArray();
    fname := "DATA/treps/" * label;
    ok := OpenTest(fname);
    if ok then
        complete, reps := Explode(Split(Read(fname), "|"));
        T`med_complete := (complete eq "t");
        if "T" in reps then
            T`small_opts := {<StringToInteger(m) : m in Split(P, "T")> : P in Split(reps, ":")};
        else
            for P in Split(reps, ":") do
                chsh, PP := Explode(Split(P, "#"));
                PP := StringToGroup(P);
                n := Degree(PP);
                chsh := StringToInteger(chsh);
                if not IsDefined(T`med_opts, n) then
                    T`med_opts[n] := AssociativeArray();
                end if;
                if not IsDefined(T`med_opts[n], chsh) then
                    T`med_opts[n][chsh] := [];
                end if;
                Append(~T`med_opts[n][chsh], PP);
            end for;
        end if;
    end if;
    return T;
end intrinsic;

intrinsic WriteTransitivePermutationRepresentations(G::Grp, fname::MonStgElt, label::MonStgElt : max_tries:=20)
{Search for transitive permutation representations of G, writing them to the file
 specified by fname, only stopping when killed.  Will only write permutation representations of degree at most the best already found, }
    triv := sub<G|>;
    // We don't allow representations with enormous degree,
    // since they're not going to be practical for isomorphism testing
    // and will take a lot of space to store.  We start with 1024 as a
    // guess for what is "reasonable"
    d := 1024;
    Sd := Sym(d);
    best := [];
    t0 := Cputime();
    since_success := 0;
    ever_successful := false;
    while true do
        if since_success gt 100 and not ever_successful then
            d := Min(2 * d, #G);
            Sd := Sym(d);
            since_success := 0;
        end if;
        H := RandomCoredSubgroups(G, triv, 1 : max_tries:=max_tries)[1];
        dd := Index(G, H);
        if dd gt d or #H eq 1 then
            since_success +:= 1;
            continue;
        end if;
        rho, P := CosetAction(G, H);
        chsh := CycleHash(P);
        if dd lt d then
            best := [];
            d := dd;
            Sd := Sym(d);
        end if;
        if &or[(chsh eq pair[1] and IsConjugate(Sd, P, pair[2])) : pair in best] then
            since_success +:= 1;
            continue;
        end if;
        ever_successful := true;
        PrintFile(fname, Sprintf("x%o|%o|%o|%o|%o#%o", label, dd, Cputime() - t0, Join([SaveElt(g):g in Generators(H)], ","), chsh, GroupToString(P)));
        Append(~best, <chsh, P>);
    end while;
end intrinsic;

intrinsic WriteAllTransitivePermutationRepresentations(G::Grp, d::RngIntElt, fname::MonStgElt, label::MonStgElt)
{}
    t0 := ReportStart(label, "Code-y");
    N := #G div d;
    t1 := ReportStart(label, "AllSubsOrderN");
    S := Subgroups(G : OrderEqual:=N);
    ReportEnd(label, "AllSubsOrderN", t1);
    t1 := ReportStart(label, "CorefreeSubsOrderN");
    S := [H`subgroup : H in S | #Core(G, H`subgroup) eq 1];
    ReportEnd(label, "CorefreeSubsOrderN", t1);
    best := [];
    Sd := Sym(d);
    for H in S do
        rho, P := CosetAction(G, H);
        chsh := CycleHash(P);
        if &or[(chsh eq pair[1] and IsConjugate(Sd, P, pair[2])) : pair in best] then
            continue;
        end if;
        Append(~best, <chsh, P, H>);
    end for;
    for data in best do
        chsh, P, H := Explode(data);
        PrintFile(fname, Sprintf("y%o|%o|%o|%o#%o", label, d, Join([SaveElt(g):g in Generators(H)], ","), chsh, GroupToString(P)));
    end for;
    ReportEnd(label, "Code-y", t0);
end intrinsic;

intrinsic TransitivePermutationRepresentation(G::Grp, ns::SetEnum) -> Map, GrpPerm
{}
    triv := sub<G|>;
    while true do
        H := RandomCoredSubgroup(G, triv, ns);
        if Index(G, H) in ns then
            rho, P := CosetAction(G, H);
            return rho, P;
        end if;
    end while;
end intrinsic;

intrinsic label_perm_method(G::Grp: hsh:=0) -> Any
{Attempts to find the label of a group G using stored transitive permutation representations.}
    N := #G;
    if hsh eq 0 then hsh := hash(G); end if;
    Ts := [TransitiveData(pair[1]) : pair in GroupsWithHash(N, hsh)];
    skips := [T`label : T in Ts | #T`small_opts eq 0 and #T`med_opts eq 0];
    if #skips gt 0 then
        print("Skipped labels:", Join(skips, ","));
    end if;
    Ts := [T : T in Ts | #T`small_opts gt 0 or #T`med_opts gt 0];
    while true do
        if #Ts eq 0 then
            // This could happen if we didn't have available permutation representations to begin with,
            // or if they were all eliminated below using med_complete
            return None();
        end if;
        ns := &join([Keys(T`med_opts) : T in Ts]) join &join[{nt[1] : nt in T`small_opts} : T in Ts]; // Collect degrees n that we're looking for
        // Randomly choose a transitive representation of an appropriate degree
        // Note that this could hang if there are no representatios of degree among the ns, or if it's just hard to find one.
        rho, GG := TransitivePermutationRepresentation(G, ns);
        n := Degree(GG);
        if n le 47 and (n ne 32 or N lt 512 or N gt 40000000000) then
            t, n := TransitiveGroupIdentification(GG);
            for T in Ts do
                if <n, t> in T`small_opts then
                    return T`label;
                end if;
            end for;
            // We can conclude that G is not present, since the enumeration of transitive groups in this range is complete.
            return None();
        else
            poss := [T : T in Ts | IsDefined(T`med_opts, n)];
            if #poss gt 0 then
                chsh := CycleHash(GG);
                poss := [T : T in poss | IsDefined(T`med_opts[n], chsh)];
                if #poss gt 0 then
                    Sn := Sym(n);
                    for T in poss do
                        for HH in T`med_opts[n][chsh] do
                            if IsConjugate(Sn, GG, HH) then
                                return T`label;
                            end if;
                        end for;
                    end for;
                end if;
            end if;
            // When we know all of the transitive representations of degree n (recorded using med_complete), so we may be able to remove some options
            Ts := [T : T in Ts | not (T`med_complete and IsDefined(T`med_opts, n))];
        end if;
    end while;
end intrinsic;

intrinsic label(G::LMFDBGrp : strict:=true, giveup:=false) -> Any
{Assign label to a LMFDBGrp}
    // This is usually set at object creation, so doesn't get called
    return label(G`MagmaGrp : strict:=strict, giveup:=giveup);
end intrinsic;

intrinsic label_subgroup(G::LMFDBGrp, H::Grp : hsh:=0, strict:=false, giveup:=false) -> Any
{Given a group G and a subgroup H, returns the label of H as an abstract group}
    // We default to false on strict since this won't usually be used for checking if a group already has a label
    if #H eq G`order then
        return Get(G, "label");
    end if;
    return label(H : hsh:=hsh, strict:=strict, giveup:=giveup);
end intrinsic;

intrinsic label_quotient(G::LMFDBGrp, N::Grp : GN:=0, hsh:=0, strict:=false, giveup:=false) -> Any
{Given a group G and a normal subgroup N, returns the label of G/N as an abstract group}
    // We default to false on strict since this won't usually be used for checking if a group already has a label
    if #N eq 1 then
        return Get(G, "label");
    elif #N eq G`order then
        return "1.1";
    end if;
    GG := G`MagmaGrp;
    nGN := Index(GG, N);
    if IsPrime(nGN) then
        return Sprintf("%o.1", nGN);
    elif GN cmpeq 0 then
        try
            GN := BestQuotient(GG, N);
        catch e
            print "Warning: failure to compute quotient";
            return None();
        end try;
    end if;
    return label(GN : hsh:=hsh, strict:=strict, giveup:=giveup);
end intrinsic;

// TODO: make this better; currently only for small groups
intrinsic LabelToLMFDBGrp(label::MonStgElt : represent:=true) -> LMFDBGrp
  {Given label, create corresponding LMFDBGrp, including data from file}
  n, i := Explode(Split(label, "."));
  n := eval n;
  i := eval i;
  return MakeSmallGroup(n,i : represent:=represent);
end intrinsic;

