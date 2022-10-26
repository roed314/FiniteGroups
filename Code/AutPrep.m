AttachSpec("spec");

Nlower := StringToInteger(Nlower);
Nupper := StringToInteger(Nupper);
i := StringToInteger(Proc);
//SetVerbose("User1", 1);

procedure PrepSmallGroup(N, i)
    G := NewLMFDBGrp(SmallGroup(N, i), Sprintf("%o.%o", N, i));
    if Type(G`MagmaGrp) eq GrpPC then
        filename := Sprintf("RePresentations/%o.%o", N, i);
        done, F := OpenTest(filename, "r");
        print N, i, done;
        if not done then
            F := Open("RePresentations/log", "a");
            Write(F, Sprintf("%o.%o\n", N, i));
            Flush(F);
            AssignBasicAttributes(G);
            t0 := Cputime();
            RePresent(G : reset_attrs:=false);
            t := Cputime() - t0;
            F := Open(filename, "w");
            Write(F, Sprintf("<PCGroup(%o), %o, %o>", CompactPresentation(G`MagmaGrp), Get(G, "gens_used"), t));
            Flush(F);
        end if;
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
