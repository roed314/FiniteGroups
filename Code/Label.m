intrinsic label(G::Grp) -> Any
{Assigns label for small groups only right now}
    // There is a bug in Magma which sometimes gives #G = 0.
    if #G eq 0 then
        error Sprintf("Hit bug in Magma giving a group of order 0!");
    end if;
    if CanIdentifyGroup(#G) then
        id:=IdentifyGroup(G);
    elif #G eq 1152 or #G eq 1920 then // GAP can identify but Magma can't
        id := GAP_ID(G);
    elif #G le 2000 and #G ne 1024 then
        root := GetLMFDBRootFolder();
        h := hash(G);
        possibilities := [StringToInteger(x) : x in Split(Read(Sprintf("%oDATA/hash/%o/%o", root, #G, h)), "\n")];
        if #possibilities eq 1 then
            id := <#G, possibilities[1]>;
        else
            vprint User1: "Iterating through", #possibilities, "possible groups";
            solv := true;
            if #G eq 512 then
                G := StandardPresentation(G);
            else
                solv := IsSolvable(G);
                if solv then
                    G := PCGroup(G);
                elif Category(G) ne GrpPerm then
                    f, G := MinimalDegreePermutationRepresentation(G);
                end if;
            end if;
            for i in possibilities do
                H := SmallGroup(#G, i);
                if #G eq 512 and IsIdenticalPresentation(G, H) or #G ne 512 and (solv and IsIsomorphicSolubleGroup(G, H) or not solv and IsIsomorphic(G, H)) then
                    id := <512, i>;
                    break;
                end if;
            end for;
        end if;
    else
        h := hash(G);
        error Sprintf("Can't Identify Groups of Order %o!", #G);
    end if;
    label:= Sprintf("%o.%o", id[1], id[2]);
    return label;
end intrinsic;


intrinsic label(G::LMFDBGrp) -> Any
{Assign label to a LMFDBGrp type}
    return label(G`MagmaGrp);
end intrinsic;

// TODO: make this better; currently only for small groups
intrinsic LabelToLMFDBGrp(label::MonStgElt : represent:=true) -> LMFDBGrp
  {Given label, create corresponding LMFDBGrp, including data from file}
  n, i := Explode(Split(label, "."));
  n := eval n;
  i := eval i;
  return MakeSmallGroup(n,i : represent:=represent);
end intrinsic;

