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
        return [* <labels[i], StringToGroup(descs[i])> : i in [1..#labels] *];
    else
        return [* *];
    end if;
end intrinsic;

intrinsic PossiblyLabelable(N::RngIntElt) -> BoolElt
{Returns false when label will always return None for groups of order N}
    return CanIdentifyGroup(N) or N in SmallhashOrders() or HaveKnownHashes(N);
end intrinsic;

intrinsic label(G::Grp : hsh:=0) -> Any
{Assigns label for small groups using IdentifyGroup}
    // There is a bug in Magma which sometimes gives #G = 0.
    N := #G;
    if N eq 0 then
        error Sprintf("Hit bug in Magma giving a group of order 0!");
    elif N eq 1 then
        // work around bug in IdentifyGroup
        return "1.1";
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
        return None();
    else
        if hsh eq 0 then hsh := hash(G); end if;
        Hs := GroupsWithHash(N, hsh);
        for pair in Hs do
            label, H := Explode(pair);
            if IsIsomorphic(G, H) then
                return label;
            end if;
        end for;
        return None();
    end if;
    label:= Sprintf("%o.%o", id[1], id[2]);
    return label;
end intrinsic;


intrinsic label(G::LMFDBGrp) -> Any
{Assign label to a LMFDBGrp}
    return label(G`MagmaGrp);
end intrinsic;

intrinsic label_subgroup(G::LMFDBGrp, H::Grp : hsh:=0) -> Any
{Given a group G and a subgroup H, returns the label of H as an abstract group}
    if #H eq G`order then
        return Get(G, "label");
    end if;
    return label(H : hsh:=hsh);
end intrinsic;

intrinsic label_quotient(G::LMFDBGrp, N::Grp : GN:=0, hsh:=0) -> Any
{Given a group G and a normal subgroup N, returns the label of G/N as an abstract group}
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
        GN := BestQuotient(GG, N);
    end if;
    return label(GN : hsh:=hsh);
end intrinsic;

// TODO: make this better; currently only for small groups
intrinsic LabelToLMFDBGrp(label::MonStgElt : represent:=true) -> LMFDBGrp
  {Given label, create corresponding LMFDBGrp, including data from file}
  n, i := Explode(Split(label, "."));
  n := eval n;
  i := eval i;
  return MakeSmallGroup(n,i : represent:=represent);
end intrinsic;

