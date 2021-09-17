AttachSpec("spec");

Nlower := StringToInteger(Nlower);
Nupper := StringToInteger(Nupper);
i := StringToInteger(Proc);

procedure PrepSmallGroup(N, i)
    G := NewLMFDBGrp(SmallGroup(N, i), Sprintf("%o.%o", N, i));
    if Type(G`MagmaGrp) eq GrpPC then
        AssignBasicAttributes(G);
        RePresent(G : reset_attrs:=false);
        F := Open("autsolv_prep/" * Proc * ".txt", "w");
        Write(F, Sprintf("<PCGroup(%o), %o>", CompactPresentation(G`MagmaGrp), G`gens_used));
        Flush(F);
    end if;
end procedure;

for N in [Nlower..(Nupper-1)] do
    I := NumberOfSmallGroups(N);
    if i le I then
        PrepSmallGroup(N, i);
        break;
    end if;
    i -:= I;
end for;

exit;
