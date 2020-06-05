AttachSpec("spec");

// Call using gnu parallel as follows, for computing groups of order up to 500, using a total of 1000 processes, into the folder $FOLDER (which will create subfolders as necessary)
// parallel magma AddSmallGroups.m Folder:=$FOLDER Nlower:=1 Nupper:=501 NumProc:=1000 Proc:={1} ::: {0..999}

// We use the following variables passed in from the command line
// Folder: folder for containing the results
// Nlower: an overall lower bound for the order of the groups being added in this run
// Nupper: an overall upper bound for the order of the groups being added in this run (upper bound not included)
// NumProc: the number of processes being used in this run
// Proc: the current process (determines which N, i will be computed by this process)

//System("mkdir -p " * Folder * "/labels");

if Folder[#Folder] ne "/" then
    Folder := Folder * "/";
end if;
files := [Folder * "groups/" * Proc * ".txt",
          Folder * "subgroups/" * Proc * ".txt",
          Folder * "groups_cc/" * Proc * ".txt"];

Nlower := StringToInteger(Nlower);
Nupper := StringToInteger(Nupper);
NumProc := StringToInteger(NumProc);
Proc := StringToInteger(NumProc);
NumGroups := &+[NumberOfSmallGroups(N) : N in [Nlower..(Nupper-1)]];
Start := Floor((NumGroups-1) * Proc / NumProc);
End := Floor((NumGroups-1) * (Proc + 1) / NumProc);

function WriteSmallGroup(N, i)
    print_data := MakeSmallGroupData(N, i);
    for j in [1..3] do
        for line in print_data[j] do
            PrintFile(files[j], print_data[j]);
        end for;
    end for;
end function;

for N in [Nlower..(Nupper-1)] do
    ThisN := NumberOfSmallGroups(N);
    if Start lt ThisN then
        if End lt ThisN then
            // Small Group indexing is 1-based
            for i in [Start+1..End+1] do
                WriteSmallGroup(N, i);
            end for;
            break;
        else
            // Small Group indexing is 1-based
            for i in [Start+1..ThisN] do
                WriteSmallGroup(N, i);
            end for;
        end if;
        Start := 0;
    else
        Start -:= ThisN;
    end if;
    End -:= ThisN;
end for;
