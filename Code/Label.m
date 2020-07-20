intrinsic label(G::Grp) -> Any
{Assigns label for small groups only right now}
    // There is a bug in Magma which sometimes gives #G = 0.
    if #G eq 0 then
        error Sprintf("Hit bug in Magma giving a group of order 0!");
    end if;
    if CanIdentifyGroup(#G) then
        id:=IdentifyGroup(G);
        label:= Sprintf("%o.%o", id[1], id[2]);
        return label;
    else
        error Sprintf("Can't Identify Groups of Order %o!", #G);
    end if;
end intrinsic;


intrinsic label(G::LMFDBGrp) -> Any
{Assign label to a LMFDBGrp type}
    return label(G`MagmaGrp);
end intrinsic;

