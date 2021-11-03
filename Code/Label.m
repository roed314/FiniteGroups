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
    elif #G eq 512 then
        Gpc := PCGroup(G);
        rank := FrattiniQuotientRank(Gpc);
        pclass := pClass(Gpc);
        // The following are determined from GAP's SmallGroupsInformation(512)
        case rank:
            when 1: return "512.1";
            when 2:
                case pclass:
                    when 3: I := [2..10];
                    when 4: I := [11..386];
                    when 5: I := [387..1698];
                    when 6: I := [1699..2008];
                    when 7: I := [2009..2039];
                    when 8: I := [2040..2044];
                end case;
            when 3:
                case pclass:
                    when 2: return "512.2045";
                    when 3: I := [2046..29398] cat [30618..31239];
                    when 4: I := [29399..30617] cat [31240..56685];
                    when 5: I := [56686..60615];
                    when 6: I := [60616..60894];
                    when 7: I := [60895..60903];
                end case;
            when 4:
                case pclass:
                    when 2: I := [60904..67612];
                    when 3: I := [67613..387088];
                    when 4: I := [387089..419734];
                    when 5: I := [419735..420500];
                    when 6: I := [420501..420514];
                end case;
            when 5:
                case pclass:
                    when 2: I := [420515..6249623];
                    when 3: I := [6249624..7529606];
                    when 4: I := [7529607..7532374];
                    when 5: I := [7532375..7532392];
                end case;
            when 6:
                case pclass:
                    when 2: I := [7532393..10481221];
                    when 3: I := [10481222..10493038];
                    when 4: I := [10493039..10493061];
                end case;
            when 7:
                case pclass:
                    when 2: I := [10493062..10494173];
                    when 3: I := [10494174..10494200];
                end case;
            when 8: I := [10494201..10494212];
            when 9: return "512.10494213";
        end case;
    //elif #G eq 1536 then
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

