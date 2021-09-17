AttachSpec("spec");

// Call using gnu parallel as follows, for computing groups of order up to 500, using a total of 1000 processes, into the folder $FOLDER (which will create subfolders as necessary)
// values are processed by magma in the order given, so the file must come last
// parallel magma Folder:=$FOLDER Nlower:=1 Nupper:=501 NumProc:=1000 Proc:={1} AddSmallGroups.m ::: {0..999}

// We use the following variables passed in from the command line
// Folder: folder for containing the results
// Nlower: an overall lower bound for the order of the groups being added in this run
// Nupper: an overall upper bound for the order of the groups being added in this run (upper bound not included)
// NumProc: the number of processes being used in this run
// Proc: the current process (determines which N, i will be computed by this process)

//System("mkdir -p " * Folder * "/labels");


SetColumns(0);

if Folder[#Folder] ne "/" then
    Folder := Folder * "/";
end if;
SetLMFDBRootFolder(Folder);

files := [Folder * "groups/" * Proc * ".txt",
          Folder * "subgroups/" * Proc * ".txt",
          Folder * "groups_cc/" * Proc * ".txt",
          Folder * "characters_cc/" * Proc * ".txt",
          Folder * "characters_qq/" * Proc * ".txt",
          Folder * "glnc/" * Proc * ".txt",
          Folder * "glnq/" * Proc * ".txt" ];
logfile := Folder * "logs/" * Proc * ".txt";

for f in ["groups", "subgroups", "groups_cc", "characters_cc", "characters_qq", "logs","glnc","glnq"] do
  System("mkdir -p "* Folder * f);
end for;
System("mkdir -p " * Folder * "SUBCACHE");

Nlower := StringToInteger(Nlower);
Nupper := StringToInteger(Nupper);
NumProc := StringToInteger(NumProc);
assert NumProc gt 0;
Proc := StringToInteger(Proc);
assert 0 le Proc and Proc lt NumProc;

procedure WriteSmallGroup(N, i)
    PrintFile(logfile, Sprintf("Starting small group %o.%o", N, i));
    t0 := Cputime();
    print_data := MakeSmallGroupData(N, i);
    t1 := Cputime();
    PrintFile(logfile, Sprintf("Small group %o.%o took %o s", N, i, t1-t0));
    for j in [1..5] do
        for line in print_data[j] do
            PrintFile(files[j], line);
        end for;
    end for;
end procedure;

procedure WriteSmallGroupGLnx(N, i) // May use later
    PrintFile(logfile, Sprintf("Starting GLn small group %o.%o", N, i));
    t0 := Cputime();
    print_data := MakeSmallGroupGLnData(N, i);
    t1 := Cputime();
    PrintFile(logfile, Sprintf("GLn small group %o.%o took %o s", N, i, t1-t0));
    for j in [1..2] do
        for line in print_data[j] do
            PrintFile(files[5+j], line);
        end for;
    end for;
end procedure;


// We have processes do every-Nth group rather than consecutive blocks in order to balance the time between different processes.
ctr := 0;
for N in [Nlower..(Nupper-1)] do
    for i in [1..NumberOfSmallGroups(N)] do
        if ctr eq Proc then
            WriteSmallGroup(N, i);
        end if;
        ctr +:= 1;
        if ctr eq NumProc then ctr := 0; end if;
    end for;
end for;

exit;
