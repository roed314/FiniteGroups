
BIG_THRESHOLD := 2000;
SMALL_SCALE := 10;
SMALL_THRESHOLD := 20000;
MAXIMAL_EXCLUDE_THRESHOLD := 1000;

declare type MaximalSubgroupTree;
declare attributes MaximalSubgroupTree:
        G,
        subs,
        transversals,
        rlists,
        pregens,
        gens;

intrinsic NewMaximalSubgroupTree(G::Grp) -> MaximalSubgroupTree
{}
    T := New(MaximalSubgroupTree);
    T`G := G;
    dummy := AssociativeArray();
    dummy[[0]] := 0;
    U := Universe(dummy);
    T`subs := AssociativeArray(U);
    T`transversals := AssociativeArray(U);
    T`rlists := AssociativeArray(U);
    T`pregens := AssociativeArray(U);
    T`gens := AssociativeArray(U);
    return T;
end intrinsic;

intrinsic initRandomizer(~H::Grp, gens::SeqEnum, ~rlist::SeqEnum)
{Create an initial state object for computing pseudorandom elements of H}
    ResetRandomSeed(~H);
    rlist := [g : g in gens];
    // A paper says to add 5 extra entries for better results
    rlist cat:= [gens[1 + (z mod #gens)] : z in [0..4]];
    dummy := rlist[1];
    for rl in [1..20] do
        randomG(~H, ~rlist, ~dummy);
    end for;
end intrinsic;

intrinsic randomG(~H::Grp, ~rlist::SeqEnum, ~result::GrpElt)
{Produce the next pseudorandom group element, updating rlist in the process}
    i, H`randval := ourrand(#rlist, H);
    repeat
        j, H`randval := ourrand(#rlist, H);
    until i ne j;
    rlist[i] *:= rlist[j];
    result := rlist[i];
end intrinsic;

intrinsic subs(T::MaximalSubgroupTree, path::SeqEnum) -> SeqEnum
{Returns a sorted list of chosen representatives from the H-conjugacy classes of maximal subgroups in H}
    if IsDefined(T`subs, path) then return T`subs[path]; end if;
    H := sub(T, path);
    Hord := #H;
    gens := gens(T, path);
    rlist := [];
    initRandomizer(~H, gens, ~rlist);
    //t0 := Cputime();
    //vprint User1: "Starting MaximalSubgroups", path;
    Ms := MaximalSubgroups(H);
    // We skip maximal subgroups of very large index since they will require a lot of work to pick a specific conjugate
    //vprint User1: "MaximalSubgroups done", #Ms, Cputime() - t0;
    Ms := [M : M in Ms | M`order * MAXIMAL_EXCLUDE_THRESHOLD ge Hord or IsNormal(H, M`subgroup)];
    Cs := [[C : C in Conjugates(H, M`subgroup)] : M in Ms];
    pregens := AssociativeArray();
    for CC in Cs do for C in CC do pregens[C] := []; end for; end for;
    sorter := [[M`order] : M in Ms];
    unordered := AssociativeArray();
    for j in [1..#sorter] do
        ord := sorter[j][1];
        if not IsDefined(unordered, ord) then unordered[ord] := []; end if;
        Append(~unordered[ord], j);
    end for;
    for n -> jlist in unordered do
        if #jlist eq 1 then
            Remove(~unordered, n);
        end if;
    end for;
    h := rlist[1];
    //t1 := Cputime();
    //vprint User1: "Starting repeat", [Hord div M`order : M in Ms];
    //ctr := 0;
    repeat
        randomG(~H, ~rlist, ~h);
        //ctr +:= 1;
        //if ctr gt 16 and IsPowerOf(ctr, 2) then
        //    vprint User1: "Ordering M", ctr, sprint([#CC : CC in Cs]), #unordered, Cputime() - t1;
        //end if;
        jcontain := [];
        for j in [1..#Cs] do
            contain := [k : k in [1..#Cs[j]] | h in Cs[j][k]];
            for k in contain do
                Append(~pregens[Cs[j][k]], h);
            end for;
            if 0 lt #contain and #contain lt #Cs[j] then
                Cs[j] := [Cs[j][k] : k in contain];
            end if;
            Append(~jcontain, #contain);
        end for;
        for n -> jlist in unordered do
            //vprint User1: "Unordered", n, sprint(jlist), sprint(jcontain);
            count := AssociativeArray();
            for j in jlist do
                if not IsDefined(count, jcontain[j]) then count[jcontain[j]] := 0; end if;
                count[jcontain[j]] +:= 1;
            end for;
            if #count gt 1 then // able to distinguish between some pair of subgroups
                seen := AssociativeArray();
                for j in jlist do
                    Append(~sorter[j], jcontain[j]);
                    if not IsDefined(seen, sorter[j]) then
                        seen[sorter[j]] := [j];
                    else
                        Append(~seen[sorter[j]], j);
                    end if;
                end for;
                keep := [];
                for sortkey -> js in seen do
                    if #js gt 1 then
                        keep cat:= js;
                    end if;
                end for;
                if #keep eq 0 then
                    Remove(~unordered, n);
                else
                    unordered[n] := keep;
                end if;
            end if;
        end for;
    until #unordered eq 0 and &and[#CC eq 1 : CC in Cs];
    //vprint User1: "Sub done", sprint(path), Cputime() - t0;
    Cs := [CC[1] : CC in Cs];
    ParallelSort(~sorter, ~Cs);
    for j in [1..#Cs] do
        T`pregens[path cat [j]] := pregens[Cs[j]];
    end for;
    T`subs[path] := Cs;
    T`rlists[path] := rlist;
    return Cs;
end intrinsic;

intrinsic sub(T::MaximalSubgroupTree, path::SeqEnum) -> Grp
{The subgroup corresponding to a path of integers}
    if #path eq 0 then return T`G; end if;
    prefix := path[1..#path-1];
    last := path[#path];
    return subs(T, prefix)[last];
end intrinsic;

intrinsic gens(T::MaximalSubgroupTree, path::SeqEnum) -> SeqEnum
{Return a list of generators for the subgroup H}
    if IsDefined(T`gens, path) then return T`gens[path]; end if;
    if #path eq 0 then
        gens := [g : g in Generators(T`G)];
    else
        prefix := path[1..#path-1];
        last := path[#path];
        S := subs(T, prefix);
        H := S[last];
        G := sub(T, prefix);
        pregens := T`pregens[path];
        gens := [];
        H0 := sub<H|>;
        for i in [1..#pregens] do
            H1 := sub<H|gens cat [pregens[i]]>;
            if #H1 gt #H0 then
                Append(~gens, pregens[i]);
                H0 := H1;
                if #H1 eq #H then
                    break;
                end if;
            end if;
        end for;
        rlist := T`rlists[prefix];
        h := rlist[1];
        while #H0 ne #H do
            // Need more generators
            randomG(~G, ~rlist, ~h);
            contain := [j : j in [1..#S] | h in S[j]];
            for j in [1..#S] do
                if h in S[j] then
                    Append(~T`pregens[prefix cat [j]], h);
                    if j eq last then
                        H1 := sub<H|gens cat [h]>;
                        if #H1 gt #H0 then
                            Append(~gens, h);
                            H0 := H1;
                        end if;
                    end if;
                end if;
            end for;
        end while;
        T`rlists[prefix] := rlist;
    end if;
    T`gens[path] := gens;
    return gens;
end intrinsic;

intrinsic transversal(T::MaximalSubgroupTree, path::SeqEnum) -> SeqEnum
{A right transversal for the normalizer of the subgroup corresponding to a nonempty path, inside the subgroup corresponding to the path omitting the last entry}
    if IsDefined(T`transversals, path) then return T`transversals[path]; end if;
    assert #path gt 0;
    prefix := path[1..#path-1];
    G := sub(T, prefix);
    H := sub(T, path);
    if IsNormal(G, H) then
        trans := {@ Identity(G) @};
    else
        trans := RightTransversal(G, H);
    end if;
    T`transversals[path] := trans;
    return trans;
end intrinsic;

intrinsic narrow(T::MaximalSubgroupTree, rep::GrpElt) -> RngIntElt, SeqEnum, SeqEnum, SeqEnum
{The number of elements that need to be iterated through in order to find a canonical representative for the conjugacy class containing rep.
Also returns
 * the path to the subgroup H to be intersected with,
 * a sequence of conjugates of rep, all contained in H and the union of whose H-conjugacy classes equals the intersection of H with the G-conjugacy class of rep
 * the centralizers within H of the prior sequence}
    path := [];
    reps := [rep];
    Zs := [Centralizer(T`G, rep)];
    cnt := #(T`G) div # Zs[1];
    while cnt gt SMALL_THRESHOLD do
        //t0 := Cputime();
        //vprint User1: "Narrowing", cnt, sprint(path), #Zs, #reps;
        G := sub(T, path);
        //vprint User1: "Gdone", Cputime() - t0;
        S := subs(T, path);
        //vprint User1: "S found", #S, Cputime() - t0;
        bestnewreps := [];
        bestcnt := cnt + 1;
        for j in [1..#S] do
            //t1 := Cputime();
            //vprint User1: "j-loop", j;
            newreps := [];
            newZs := [];
            H := S[j];
            trans := transversal(T, path cat [j]);
            //vprint User1: "Transversal found", #trans, Cputime() - t1;
            //t2 := Cputime();
            for k in [1..#reps] do
                x := reps[k];
                Z := Zs[k];
                for t in trans do
                    y := x^t;
                    if y in H then
                        Append(~newreps, y);
                        Append(~newZs, Z^t meet H);
                    end if;
                end for;
            end for;
            if #newZs eq 0 then
                //vprint User1: "Continuing (no new)", Cputime() - t2;
                continue;
            end if;
            newcnt := &+[#H div #ZH : ZH in newZs];
            if newcnt gt 0 and newcnt lt bestcnt then
                //vprint User1: "Improving", newcnt, #newreps, #newZs, Cputime() - t2;
                bestcnt := newcnt;
                bestreps := newreps;
                bestZs := newZs;
                bestj := j;
            end if;
        end for;
        if bestcnt gt cnt then // no conjugate contained any rep, so this is the end
            break;
        end if;
        cnt := bestcnt;
        reps := bestreps;
        Zs := bestZs;
        Append(~path, bestj);
        //vprint User1: "Narrow complete", Cputime() - t0;
    end while;
    return cnt, path, reps, Zs;
end intrinsic;

intrinsic minrep(T::MaximalSubgroupTree, path::SeqEnum, reps::SeqEnum, Zs::SeqEnum) -> GrpElt
{Find the best representative, using the data returned by narrow}
    H := sub(T, path);
    best := reps[1];
    b := Eltseq(best);
    for i in [1..#reps] do
        rep := reps[i];
        for x in Conjugates(H, rep) do
            z := Eltseq(x);
            if z lt b then
                best := x;
                b := z;
            end if;
        end for;
    end for;
    return best;
end intrinsic;

intrinsic num2letters(n::RngIntElt: Case:="upper") -> MonStgElt
  {Convert a positive integer into a string of letters as a counter}
  s := "";
  base:= Case eq "upper" select 65 else 97;
  while n gt 0 do
    r := (n-1) mod 26;
    s := CodeToString(r+base)*s;
    n := (n-1) div 26;
  end while;
  return s;
end intrinsic;

intrinsic initRandomGroupElement(gens::Any) -> Any
  {Initialize our random element of group thing.  The state for it
   is rlist}
  // Initialize the random number generator first
  rlist:=[gener : gener in gens];
  // A paper says to add 5 extra entries for better results
  rlist:= rlist cat [gens[1 + (z mod #gens)] : z in [0..4]];
  for rl in [1..20] do
    ii := ourrand(#rlist)+1;
    jj := ii;
    while ii eq jj do
      jj := ourrand(#rlist)+1;
    end while;
    rlist[ii] *:= rlist[jj];
  end for;
  return rlist;
end intrinsic;


intrinsic randomG(~rlist::Any,~result::Any)
  {Produce the next random group element updating rlist in the process}
  ii:=ourrand(#rlist)+1;
  jj:=ii;
  while ii eq jj do
    jj:=ourrand(#rlist)+1;
  end while;
  rlist[ii] *:= rlist[jj];
  result := rlist[ii];
end intrinsic;

intrinsic nonrandomG(~state::Any, gen_seq::SeqEnum, ord_seq::SeqEnum, ~result::Any)
  {Produce the next group element in a lexicalgraphic way.}
  state:= NextWord(state, gen_seq, ord_seq);
  result:=state[1];
  for j:=1 to #state do
    result *:= state[j];
  end for;
end intrinsic;

function makedivs(v, C, pm)
    // v is a set of integers, indexing into C
    // C = ConjugacyClasses(G)
    // pm = PowerMap(G)
    if #v eq 1 then return [v]; end if;
    divs := [];
    while #v gt 0 do
        r := Rep(v);
        newdiv := {r};
        Exclude(~v, r);
        for j:=1 to C[r][1]-1 do
            if GCD(j, C[r][1]) eq 1 then
                c := pm(r, j);
                Include(~newdiv, c);
                Exclude(~v, c);
            end if;
            if #v eq 0 then break; end if;
        end for;
        Append(~divs, newdiv);
    end while;
    return divs;
end function;

intrinsic MagmaDivisions(G::LMFDBGrp) -> SeqEnum
{A list of triples [o, s, D], where o is the order of elements in the division, s is the size of a CONJUGACY CLASS in the division, and D is a set of indexes into the list of conjugacy classes}
    C := Get(G, "MagmaConjugacyClasses");
    pm := Get(G, "MagmaPowerMap");
    // Step 1 partitions the classes based on the order of a generator
    // and the size of the class
    by_ordsize := AssociativeArray();
    for j:= 1 to #C do
        c := C[j];
        os := [c[1], c[2]];
        if IsDefined(by_ordsize, os) then
            Include(~by_ordsize[os], j);
        else
            by_ordsize[os] := {j};
        end if;
    end for;
    // Separate a set of classes into divisions
    // The order of a rep is cc[r][1].  This could be more efficient
    // if we used generators for (Z/nZ)^* where n=cc[r][1]
    divisions := [];
    for os in Sort([k : k in Keys(by_ordsize)]) do
        for division in makedivs(by_ordsize[os], C, pm) do
            Append(~divisions, <os[1], os[2], division>);
        end for;
    end for;
    return divisions;
end intrinsic;

// Pass in the group data
intrinsic ordercc(G::LMFDBGrp, gens::SeqEnum: dorandom:=true) -> Any
{Take an LMFDB group, and a sequence of generators and return ordered classes and labels.}
    t1 := ReportStart(G, "ordercc");
    g := G`MagmaGrp;
    cc := Get(G, "MagmaConjugacyClasses");
    cm := Get(G, "MagmaClassMap");
    pm := Get(G, "MagmaPowerMap");
    t0 := ReportStart(G, "ordercc");
    ncc:=#cc;
    if gens eq [] then
        gens := [Id(g)];
    end if;
    // List indicating which classes are maximal w.r.t. powering
    ismax:=[true : z in cc];
    for j:=1 to ncc do
        dlist := Divisors(cc[j][1]);
        for k:=2 to #dlist-1 do
            ismax[pm(j, dlist[k])] := false;
        end for;
        // Just in case the identity is not first
        if j eq 1 then ismax[pm(1, cc[1][1])] := false; end if;
    end for;
    ReportEnd(G, "ismax", t0);
    step1 := AssociativeArray();
    for division in Get(G, "MagmaDivisions") do
        os := [division[1], division[2]];
        if IsDefined(step1, os) then
            Append(~step1[os], division[3]);
        else
            step1[os] := [division[3]];
        end if;
    end for;
    ReportEnd(G, "ordercc-step1", t0);

  // Step2 partitions based on [order of rep, size of class, size of divisions]
  step2:=AssociativeArray();
  revmap := [* 0 : z in cc *];
  for k->v in step1 do
    for divi in v do
      ky := [k[1],k[2],#divi];
      if IsDefined(step2, ky) then
        Append(~step2[ky], divi);
      else
        step2[ky] := [divi];
      end if;
      for u in divi do
        revmap[u] := ky;
      end for;
    end for;
  end for;
  ReportEnd(G, "ordercc-step2", t0);
  // Within a division, or between divisions which are as yet
  // unordered, we break ties via the priority, which is essentially
  // the order they appear in the random generation phase
  priorities:= [ncc + 1 : z in cc];
  cnt:=1;
  // We track the expos for labels within a division
  expos := [0:z in cc];
  // Just the key to step 2 plus the priority
  finalkeys:= [[0,0,0,0] : z in cc];
  // utility for below, gen is a class index
  setpriorities:=function(adiv,cnt,gen,priorities,expos)
    notdone:=0;
    for j in adiv do
      if priorities[j] gt ncc then notdone+:=1; end if;
    end for;
    pcnt:=1;
    while notdone gt 0 do
      if GCD(pcnt, cc[gen][1]) eq 1 then
        for sgn in [1,-1] do
          ac := pm(gen, sgn*pcnt);
//"Testing", gen, " to ", sgn*pcnt," got ", ac, priorities;
          if priorities[ac] gt ncc then
            notdone -:=1;
            priorities[ac]:=cnt;
            expos[ac] := sgn*pcnt;
            cnt+:=1;
          end if;
        end for;
      end if;
      pcnt+:=1;
    end while;
    return priorities, cnt, expos;
  end function;
  setpriorities_recursive := function(adiv, cnt, gen, priorities, expos)
    priorities, cnt, expos := setpriorities(adiv, cnt, gen, priorities, expos);
    divisors := Divisors(cc[gen][1]);
    for k:=2 to #divisors-1 do
      newgen := pm(gen, divisors[k]);
      powerdiv := revmap[newgen];
      for divi in step2[powerdiv] do
        if newgen in divi then
          priorities, cnt, expos := setpriorities(divi, cnt, newgen, priorities, expos);
          break;
        end if;
      end for;
    end for;
    return priorities, cnt, expos;
  end function;

  // We divide keys into those that should be labeled by enumeration (small)
  // and those that should be labeled through the random process (big)
  big_keys := [];
  small_keys := [];
  T := NewMaximalSubgroupTree(g);
  for ky -> divilist in step2 do
      if #divilist eq 1 and #Rep(divilist) eq 1 then
          continue; // nothing to do
      end if;
      //t2 := Cputime();
      //tn := 0;
      //tm := 0;
      //vprint User1: "Starting ky", sprint(ky), #divilist, #Rep(divilist);
      size := ky[2];
      if size * BIG_THRESHOLD ge G`order and (size gt SMALL_THRESHOLD or size^2 gt G`order) then // size^2 > |G| iff index smaller than size
          Append(~big_keys, ky);
          continue;
      end if;
      cs := [];
      paths := [];
      repss := [];
      Zss := [];
      for divi in divilist do
          if not ismax[Rep(divi)] then continue; end if;
          for u in divi do
              //t3 := Cputime();
              c, path, reps, Zs := narrow(T, cc[u][3]);
              //tn +:= Cputime() - t3;
              Append(~cs, c);
              Append(~paths, path);
              Append(~repss, reps);
              Append(~Zss, Zs);
          end for;
      end for;
      // It's possible that none of the divisions in divilist were maximal, in which case cs is empty
      if #cs eq 0 then continue; end if;
      small_cnt := Max(cs);
      small := (small_cnt le SMALL_THRESHOLD or small_cnt * size le SMALL_SCALE * G`order);
      if small then
          dctr := 1;
          for divi in divilist do
              mreps := [];
              diviL := [u : u in divi];
              for u in diviL do
                  //t3 := Cputime();
                  Append(~mreps, Eltseq(minrep(T, paths[dctr], repss[dctr], Zss[dctr])));
                  //tm +:= Cputime() - t3;
                  dctr +:= 1;
              end for;
              mseq, loc := Min(mreps);
              priorities, cnt, expos := setpriorities_recursive(divi, cnt, diviL[loc], priorities, expos);
          end for;
          Append(~small_keys, ky);
          //vprint User1: "Completed ky", sprint(ky), Cputime() - t2, tn, tm;
      else
          Append(~big_keys, ky);
      end if;
  end for;
  Sort(~big_keys);
  ReportEnd(G, "small_keys loop", t0);

  // Initialization for random group elements
  if dorandom then
    cache := sub<g|>;
    rlist := [];
    initRandomizer(~cache, gens, ~rlist);
  else
    order_seq := [Order(z) : z in gens];
    state := [];
  end if;

  //vprint User1: "Starting big_keys loop", #big_keys, dorandom;
  //ctr := 0;
  for k in big_keys do
    //ctr +:= 1;
    // random group elements until we hit a class we need
    //vprint User1: "ctr", ctr;
    needmoregens:=true;
    //pwrctr := 0;
    while needmoregens do
      //if IsPowerOf(pwrctr, 2) then
      //  vprint User1: "pwrctr", pwrctr;
      //end if;
      //pwrctr +:= 1;
      needmoregens:=false;
      for divi in step2[k] do
        if priorities[Rep(divi)] gt ncc then
          needmoregens:=true;
          break;
        end if;
      end for;
      if needmoregens then
        if dorandom then
          ggcl := rlist[1];
          randomG(~cache, ~rlist, ~ggcl);
        else
          ggcl := Id(g);
          nonrandomG(~state, gens, order_seq, ~ggcl);
        end if;
        gcl:=cm(ggcl);
        if ismax[gcl] and priorities[gcl] gt ncc then
          mydivkey:=revmap[gcl];
          for dd in step2[mydivkey] do
            if gcl in dd then
              priorities, cnt, expos:=setpriorities_recursive(dd,cnt,gcl,priorities,expos);
              break;
            end if;
          end for;
        end if;
      end if;
    end while;
  end for; // End of keys loop
  for k -> divilist in step2 do
    // We now have enough apex generators for all divisions
    for divi in divilist do
      for aclass in divi do
        finalkeys[aclass] := [k[1],k[2],k[3], priorities[aclass],expos[aclass]];
      end for;
    end for;
  end for;
  ReportEnd(G, "ordercc-keys-loop", t0);
  ParallelSort(~finalkeys,~cc);
  labels:=["" : z in cc]; divcnt:=0;
  oord:=0;
  divcntdown:=0;
  // if a new order, reset order and division
  // if just a new division, reset that
  for j:=1 to #cc do
    if oord ne finalkeys[j][1] then
      oord:=finalkeys[j][1];
      divcnt:=1;
      divcntdown:=finalkeys[j][3];
    end if;
    if divcntdown eq 0 then
      divcnt +:=1;
      divcntdown:=finalkeys[j][3];
    end if;
    divcntdown -:= 1;
    if finalkeys[j][3] gt 1 then
      labels[j]:=Sprintf("%o%o%o", finalkeys[j][1], num2letters(divcnt),finalkeys[j][5]);
    else
      labels[j]:=Sprintf("%o%o", finalkeys[j][1], num2letters(divcnt));
    end if;
  end for;
  cc:=[c[3] : c in cc];
  return cc, finalkeys, labels;
  ReportEnd(G, "ordercc", t1);
end intrinsic;

intrinsic testCCs(G::LMFDBGrp: dorandom:=true)->Any
{}
    g := G`MagmaGrp;
    ngens:=NumberOfGenerators(g);
    gens:=[g . j : j in [1..ngens]];

    if not dorandom and #g gt 100 then
        /* Add extra generator whose shortest representation as a word in the existing generators is at least length_bound if such a word exists.
           length_bound is set to some value that seems reasonable (currently a fixed constant). Something adaptive like Floor(Log(#g)/Log(#gens)) might be better, but this was slightly slower during limited testing..
        */
        length_bound := 7;
        gen_ords := [Order(x) : x in gens];

        /*  element_set is constructed so it contains all group elements represented by words of length less than length_bound. */
        element_set := {Id(g)};
        w := [];
        while (#element_set lt #g) and (#w lt length_bound) do
            w := NextWord(w,gens,gen_ords);
            Include(~element_set,&*w);
        end while;

        /* Find next valid word w not in element_set. */
        if (#element_set lt #g) then
            found := false;
            while not found do
                if not (&*w in element_set) then
                    found := true;
                else
                    w := NextWord(w,gens,gen_ords);
                end if;
            end while;

            /* Add the group element represented by w as an extra generator to the list gens. */
            Append(~gens,&*w);
        end if;
    end if;
    return ordercc(G, gens: dorandom:=dorandom);
end intrinsic;


