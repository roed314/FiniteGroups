
skipnames := ["<main>",
              "MakeSmallGroupData(<RngIntElt> N, <RngIntElt> i) -> Tup",
              "SaveLMFDBObject(<Any> G) -> MonStgElt",
              "PrintData(<LMFDBGrp> G) -> Tup",
              "Get(<Any> G, <MonStgElt> attr) -> .",
              "SaveAttr(<MonStgElt> attr, <Any> val, <Any> obj) -> MonStgElt",
              "MakeSmallGroup(<RngIntElt> N, <RngIntElt> i) -> Tup"];
intrinsic ProfileSmallGroups(N::RngIntElt) -> Assoc
    {Create a profiling array for a given order of group}
    num := NumberOfSmallGroups(N);
    A := AssociativeArray();
    orig := GetProfile();
    SetProfile(true);
    for i in [1..num] do
        print Sprintf("Computing %o/%o", i, num);
        data := MakeSmallGroupData(N, i);
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
    return A;
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

intrinsic ProfileByAttr(N::RngIntElt, i::RngIntElt)
    {}
    SetVerbose("User1", 1);
    G := MakeSmallGroup(N, i);
    saved := SaveLMFDBObject(G);
    SetVerbose("User1", 0);
end intrinsic;

intrinsic ShowProfiling(N::RngIntElt, A::Assoc : cutoff := 0.01, mbound := 2)
    {Summarize timing data produced by ProfileSmallGroups}
    times := [];
    for name -> X in A do
        t := &+[x[1] : x in X];
        Append(~times, <t, name>);
    end for;
    Sort(~times);
    Reverse(~times);
    total_time := &+[x[1] : x in times];
    printf "Total time to compute groups of order %o: %.2os\n", N, total_time;
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
