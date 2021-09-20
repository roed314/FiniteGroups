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
        if type eq "solv" then // passed in via command line
            A := AutomorphismGroupSolubleGroup(G);
            filename := Sprintf("autsolv_test/%o.%o", N, i);
        elif type eq "aut" then
            A := AutomorphismGroup(G);
            filename := Sprintf("aut_test/%o.%o", N, i);
        else // represent then solv
            infile := "autsolv_prep/" * Proc * ".txt";
            s := Read(infile);
            G := (eval s)[1];
            t0 := Cputime();
            A := AutomorphismGroupSolubleGroup(G);
            filename := Sprintf("autrep_test/%o.%o", N, i);
        end if;
        t := Cputime() - t0;
        F := Open(filename, "w");
        Write(F, Sprintf("%o.%o %o\n", N, i, t));
        Flush(F);
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

exit;
