/*******************************************************
This file is used for testing which of the two implementations
AutomorphismGroup or AutomorphismGroupSolubleGroup
is faster for solvable groups.

It takes command line inputs
and writes to files in the aut_test folder.

*******************************************************/

Nlower := StringToInteger(Nlower);
Nupper := StringToInteger(Nupper);
i := StringToInteger(Proc);

procedure TestSmallGroup(N, i);
    G := SmallGroup(N, i);
    if Type(G) eq GrpPC then
        t0 := Cputime();
        if solv eq "true" then // passed in via command line
            A := AutomorphismGroupSolubleGroup(G);
            filename := "autsolv_test/" * Proc * ".txt";
        else
            A := AutomorphismGroup(G);
            filename := "aut_test/" * Proc * ".txt";
        end if;
        t := Cputime() - t0;
        write(filename, Sprintf("%o.%o %o\n", N, i, t));
    end if;
end procedure;

for N in [Nlower..(Nupper-1)] do
    I := NumberOfSmallGroups(N);
    if i le I then
        TestSmallGroup(N, i);
        break;
    end if;
    i -:= I;
end for;
