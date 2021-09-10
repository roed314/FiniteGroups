
skipnames := ["<main>",
              "MakeSmallGroupData(<RngIntElt> N, <RngIntElt> i) -> Tup",
              "SaveLMFDBObject(<Any> G) -> MonStgElt",
              "PrintData(<LMFDBGrp> G) -> Tup",
              "Get(<Any> G, <MonStgElt> attr) -> .",
              "SaveAttr(<MonStgElt> attr, <Any> val, <Any> obj) -> MonStgElt",
              "MakeSmallGroup(<RngIntElt> N, <RngIntElt> i) -> Tup"];
intrinsic ProfileSmallGroups(N::RngIntElt : which:=false, step:=1) -> Assoc, SeqEnum
    {Create a profiling array for a given order of group}
    num := NumberOfSmallGroups(N);
    if Type(which) eq BoolElt then
        which := [1..num by step];
    end if;
    A := AssociativeArray();
    orig := GetProfile();
    SetProfile(true);
    ts := [];
    for i in which do
        print Sprintf("Computing %o/%o", i, num);
        t0 := Cputime();
        data := MakeSmallGroupData(N, i);
        Append(~ts, Cputime() - t0);
        V := Vertices(ProfileGraph());
        for j in [1..#V] do
            fc := Label(V!j);
            t := fc`Time;
            name := fc`Name;
            if not name in skipnames then
                if not IsDefined(A, name) then
                    A[name] := [];
                end if;
                Append(~A[name], <t, fc`Count, i>);
            end if;
        end for;
        ProfileReset();
    end for;
    SetProfile(orig);
    return A, ts;
end intrinsic;

intrinsic ProfileSmallGroup(N::RngIntElt, i::RngIntElt : cutoff := 0.01)
    {}
    orig := GetProfile();
    SetProfile(true);
    data :=MakeSmallGroupData(N, i);
    V := Vertices(ProfileGraph());
    times := [];
    for j in [1..#V] do
        fc := Label(V!j);
        t := fc`Time;
        name := fc`Name;
        if not name in skipnames then
            Append(~times, <t, name, fc`Count>);
        end if;
    end for;
    ProfileReset();
    SetProfile(orig);
    Sort(~times);
    Reverse(~times);
    total_time := &+[x[1] : x in times];
    cutoff *:= total_time;
    for tup in times do
        tot := tup[1]; name := tup[2];
        if tot gt cutoff then
            printf "%o took %.2os in %.1o calls\n", name, tot, tup[3];
        end if;
    end for;
end intrinsic;

intrinsic ProfileByAttr(N::RngIntElt, i::RngIntElt : crash:=false)
    {}
    SetVerbose("User1", crash select 2 else 1);
    G := MakeSmallGroup(N, i);
    saved := PrintData(G);
    SetVerbose("User1", 0);
end intrinsic;

intrinsic ShowProfiling(N::RngIntElt, A::Assoc : total_time := false, cutoff := 0.01, mbound := 2)
    {Summarize timing data produced by ProfileSmallGroups}
    times := [];
    for name -> X in A do
        t := &+[x[1] : x in X];
        Append(~times, <t, name>);
    end for;
    Sort(~times);
    Reverse(~times);
    if Type(total_time) eq BoolElt then
        // This is very misleading, since there's a lot of overlap between function calls
        total_time := &+[x[1] : x in times];
    end if;
    grp_cnt := #A[times[1][2]];
    avg_time := total_time / grp_cnt;
    printf "Computed %o groups of order %o in %.2os (%.2os avg)\n", grp_cnt, N, total_time, avg_time;
    cutoff *:= total_time;
    for tup in times do
        tot := tup[1]; name := tup[2];
        if tot gt cutoff then
            X := Reverse(Sort(A[name]));
            meant := tot / #X;
            meanc := Real(&+[x[2] : x in X] / #X);
            bad := [x : x in X | x[1] gt mbound * meant];
            bad := [Sprintf("%oG%o: %.1o", N, x[3], x[1] / meant) : x in bad];
            printf "%o averaged %.2os in %.1o calls (%o)\n", name, meant, meanc, Join(bad, ", ");
        end if;
    end for;
end intrinsic;

intrinsic ProfileSample(Ns::[RngIntElt] : cnt := 10, cutoff := 0.01, mbound := 2)
{Profile groups of the given orders.  cnt determines approximately how many of each order}
    for N in Ns do
        print "Profiling order", N;
        step := Floor(NumberOfSmallGroups(N) / cnt);
        A, ts := ProfileSmallGroups(N : step:=step);
        ShowProfiling(N, A : total_time:=&+ts, cutoff:=cutoff, mbound:=mbound);
    end for;
end intrinsic;

intrinsic ProfileSpecific(Nis::SeqEnum : cutoff := 0.02, mbound := 2) -> SeqEnum, FldReElt
{}
    timing_data := [];
    estimate := 0;
    for Ndata in Nis do
        N := Ndata[1];
        which := Ndata[2];
        counts := [which[j+1] - which[j] : j in [1..#which-1]];
        Append(~counts, NumberOfSmallGroups(N)+1 - which[#which]);
        print "Profiling order", N;
        A, ts := ProfileSmallGroups(N : which:=which);
        ShowProfiling(N, A : total_time:=&+ts, cutoff:=cutoff, mbound:=mbound);
        for j in [1..#which] do
            Append(~timing_data, [N, which[j], ts[j]]);
            estimate +:= ts[j] * counts[j];
        end for;
    end for;
    return timing_data, estimate;
end intrinsic;
