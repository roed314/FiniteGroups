AttachSpec("spec");

// Call using gnu parallel as follows, for computing groups of order up to 511, using a total of 128 processes and timing out after an hour, into the folder DATA (which will create subfolders as necessary)
// values are processed by magma in the order given, so the file must come last
// parallel -j128 --timeout 3600 magma Folder:=DATA Nlower:=1 Nupper:=512 Proc:={1} AddSmallGroups.m ::: {1..92804}

// We use the following variables passed in from the command line
// Folder: folder for containing the results
// Nlower: an overall lower bound for the order of the groups being added in this run
// Nupper: an overall upper bound for the order of the groups being added in this run (upper bound not included)
// Proc: the current process (determines which N, i will be computed by this process)

//System("mkdir -p " * Folder * "/labels");


SetColumns(0);

if Folder[#Folder] ne "/" then
    Folder := Folder * "/";
end if;
SetLMFDBRootFolder(Folder);

logfile := Folder * "logs/overall";

for f in ["groups", "subgroups", "groups_cc", "characters_cc", "characters_qq", "logs", "glnc", "glnq", "RePresentations"] do
  System("mkdir -p "* Folder * f);
end for;
System("mkdir -p " * Folder * "SUBCACHE");

Nlower := StringToInteger(Nlower);
Nupper := StringToInteger(Nupper);
i := StringToInteger(Proc);

// We skip the following groups since RePresent took longer than an hour in these cases
skip := Split("256.31887 256.31977 256.34703 256.34815 256.34850 256.36305 256.36405 256.36567 256.36781 256.36968 256.37611 256.39106 256.39782 256.40191 256.41187 256.41294 256.42185 256.44886 256.52508", " ");
procedure WriteSmallGroup(N, i)
    label := Sprintf("%o.%o", N, i);
    files := [Sprintf("%ogroups/%o", Folder, label),
              Sprintf("%osubgroups/%o", Folder, label),
              Sprintf("%ogroups_cc/%o", Folder, label),
              Sprintf("%ocharacters_cc/%o", Folder, label),
              Sprintf("%ocharacters_qq/%o", Folder, label)];
    timingfile := Sprintf("%ologs/%o", Folder, label);
    if not label in skip then
        print label;
        PrintFile(logfile, "Starting small group "*label);
        print_data, timings := MakeSmallGroupData(N, i);
        for j in [1..5] do
            for line in print_data[j] do
                PrintFile(files[j], line);
            end for;
        end for;
        PrintFile(timingfile, Sprintf("%o %o", label, Join([Sprint(t) : t in timings], " ")));
    end if;
end procedure;

procedure WriteSmallGroupGLnx(N, i) // May use later
    label := Sprintf("%o.%o", N, i);
    files := [Sprintf("%oglnc/%o", Folder, label),
              Sprintf("%oglnq/%o", Folder, label)];
    timingfile := Sprintf("%ologs/GLN%o", Folder, label);
    if not label in skip then
        PrintFile(logfile, Sprintf("Starting GLn small group %o", label));
        t0 := Cputime();
        print_data := MakeSmallGroupGLnData(N, i);
        t1 := Cputime();
        for j in [1..2] do
            for line in print_data[j] do
                PrintFile(files[j], line);
            end for;
        end for;
        PrintFile(timingfile, Sprintf("GLn small group %o.%o took %o s", N, i, t1-t0));
    end if;
end procedure;

// We have processes do every-Nth group rather than consecutive blocks in order to balance the time between different processes.
for N in [Nlower..(Nupper-1)] do
    I := NumberOfSmallGroups(N);
    if i le I then
        WriteSmallGroup(N, i);
        break;
    end if;
    i -:= I;
end for;

exit;
