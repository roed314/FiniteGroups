// Presentations are loaded from the folder representations
intrinsic MakeSmallGroup(N::RngIntElt, i::RngIntElt : represent:=true) -> Any
    {Create an LMFDBGrp object for SmallGroup(N,i) and compute attributes}
    G := NewLMFDBGrp(SmallGroup(N, i), Sprintf("%o.%o", N, i));
    G`order := N;
    if represent then
        repfile := Sprintf("RePresentations/%o.%o", N, i);
        stored, F := OpenTest(repfile, "r");
        if stored then
            vprint User1: "Looking up stored presentation";
            data := eval Read(F);
            G`MagmaGrp := data[1];
        else
            RePresent(G);
            vprint User1: "New presentation found";
        end if;
    end if;
    return G;
end intrinsic;

// The timing data has the following structure:
// [MakeSmallGroup (mostly RePresent if not loaded from a file),
//  [[SetSubgroupParameters (mostly SubGrpLstAut and SubGrpLst)]] - old,
//  Subgroups (inclusions and labeling),
//  Characters (esp. characters_add_sort_and_labels),
//  faithful_reps,
//  computing and writing the rest of the attributes
intrinsic MakeSmallGroupData(N::RngIntElt, i::RngIntElt) -> Tup, SeqEnum
{Create the information for saving a small group to several files.  Returns a triple (one for each file) of lists of strings (one for each entry to be saved), together with a sequence of timings}
    t0 := Cputime();
    G := MakeSmallGroup(N, i);
    ts := [Cputime() - t0];
    t0 := Cputime();
    tasks := ["Subgroups", "Characters", "faithful_reps"];
    for task in tasks do
        vprint User1: "Starting", task;
        t0 := Cputime();
        val := Get(G, task);
        Append(~ts, Cputime() - t0);
        vprint User1: "Finished", task, "in", Cputime() - t0;
    end for;
    t0 := Cputime();
    data := PrintData(G);
    Append(~ts, Cputime() - t0);
    return data, ts;
end intrinsic;

intrinsic MakeSmallGroupGLnData(N::RngIntElt, i::RngIntElt) -> Tup
  {Create the information for saving a small group to several files.  Returns a triple (one for each file) of lists of strings (one for each entry to be saved)}
  G := MakeSmallGroup(N,i);
  return PrintGLnData(G);
end intrinsic;

/* Sorry, made by copy/paste and tailored to me */
Folder:="DATA/";
Proc:="0";
files := [Folder * "groups/" * Proc * ".txt",
          Folder * "subgroups/" * Proc * ".txt",
          Folder * "groups_cc/" * Proc * ".txt",
          Folder * "characters_cc/" * Proc * ".txt",
          Folder * "characters_qq/" * Proc * ".txt",
          Folder * "glnq/" * Proc * ".txt",
          Folder * "glnc/" * Proc * ".txt"];
logfile:= Folder * "logs/" * Proc * ".txt";

intrinsic WriteSmallGroupGLn(N::RngIntElt, i::RngIntElt)
    {}
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
end intrinsic;

intrinsic WriteSmallGLnOrder(N::RngIntElt)
  {}
  for j:=1 to NumberOfSmallGroups(N) do
    WriteSmallGroupGLn(N,j);
  end for;
end intrinsic;

/*
intrinsic CheckLogs(: Folder:="DATA")
{}
    i := 0;
    lasts := [];
    while true do
        filename := Folder * "/logs/" * Sprint(i) * ".txt";
        try
            contents := Split(Read(filename), "\n");
            j := #contents;
            while j gt 0 and contents[j][1..20] ne "Starting small group" do
                j -:= 1;
            end while;
            if j eq 0 then
                print i, "not started";
            end if;
            gid := Split(contents[j][22..#contents[j]], ".");
            Append(~lasts, <StringToInteger(gid[1]), StringToInteger(gid[2])>);
        catch e;
            break;
        end try;
        i +:= 1;
    end while;
    Sort(~lasts);
    lasts := [Sprintf("%o.%o", x[1], x[2]) : x in lasts];
    s := Join(lasts, " ");
    print s;
end intrinsic;
*/

intrinsic allrankslist(n::Any)->Any
  {}
  l:=[];
  for j:=1 to n do
    for k:=1 to NumberOfSmallGroups(j) do
      [j,k];
      g:=MakeSmallGroup(j,k);
      Append(~l, <j,k,Get(g,"rank")>);
    end for;
  end for;
  return l;
end intrinsic;
