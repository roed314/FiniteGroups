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

intrinsic label(G::Grp : hsh:=0, strict:=true) -> Any, Map
{Assigns label for small groups using IdentifyGroup, and for larger groups by using hashes.
Because of Magma bugs in IsIsomorphic, when strict is false this may return None even when there is a known group that matches.  If strict is true, it will raise an error.
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
        id := IdentifyGroups([G])[1];
    elif not HaveKnownHashes(N) then
        return None(), _;
    else
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


intrinsic label(G::LMFDBGrp : strict:=true) -> Any
{Assign label to a LMFDBGrp}
    // This is usually set at object creation, so doesn't get called
    return label(G`MagmaGrp : strict:=strict);
end intrinsic;

intrinsic label_subgroup(G::LMFDBGrp, H::Grp : hsh:=0, strict:=false) -> Any
{Given a group G and a subgroup H, returns the label of H as an abstract group}
    // We default to false on strict since this won't usually be used for checking if a group already has a label
    if #H eq G`order then
        return Get(G, "label");
    end if;
    return label(H : hsh:=hsh, strict:=strict);
end intrinsic;

intrinsic label_quotient(G::LMFDBGrp, N::Grp : GN:=0, hsh:=0, strict:=false) -> Any
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
    return label(GN : hsh:=hsh, strict:=strict);
end intrinsic;

// TODO: make this better; currently only for small groups
intrinsic LabelToLMFDBGrp(label::MonStgElt : represent:=true) -> LMFDBGrp
  {Given label, create corresponding LMFDBGrp, including data from file}
  n, i := Explode(Split(label, "."));
  n := eval n;
  i := eval i;
  return MakeSmallGroup(n,i : represent:=represent);
end intrinsic;

