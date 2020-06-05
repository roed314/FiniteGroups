
intrinsic num2letters(n::RngIntElt) -> MonStgElt
  {Convert a positive integer into a string of letters as a counter}
  s := "";
  while n gt 0 do
    r := (n-1) mod 26;
    s := CodeToString(r+65)*s;
    n := (n-1) div 26;
  end while;
  return s;
end intrinsic;

/* Pass in the group data */
intrinsic ordercc(g::Any,cc::Any,cm::Any,pm::Any,gens::Any) -> Any
  {}
  ncc:=#cc;
  gens:=[z : z in gens];
  step1:=AssociativeArray();
  for j:=1 to ncc do
    c:=cc[j];
    if IsDefined(step1, [c[1],c[2]]) then
        Include(~step1[[c[1],c[2]]], j);
    else
      step1[[c[1],c[2]]] := {j};
    end if;
  end for;
  ismax:=[true : z in cc];
  for j:=1 to ncc do
    dlist := Divisors(cc[j][1]);
    for k:=2 to #dlist-1 do
      ismax[pm(j, dlist[k])] := false;
    end for;
    // Just in case the identity is not first
    if j eq 1 then ismax[pm(1, cc[1][1])] := false; end if;
  end for;

  makedivs := function(li)
    if #li eq 1 then return [li]; end if;
    divs:=[];
    while #li gt 0 do
      r:=Rep(li);
      newdiv:={r};
      Exclude(~li, r);
      for j:=1 to cc[r][1]-1 do
        if GCD(j, cc[r][1]) eq 1 then
          c:=pm(r, j);
          Include(~newdiv, c);
          Exclude(~li, c);
        end if;
        if #li eq 0 then break; end if;
      end for;
      Append(~divs, newdiv);
    end while;
    return divs;
  end function;

  // Now partition into divisions
  for k->v in step1 do
    step1[k] := makedivs(step1[k]);
  end for;

  // Break based on [order of rep, size of class, size of divisions]
  step2:=AssociativeArray();
  revmap := [* 0 : z in cc *];
  for k->v in step1 do
    for divi in v do
      ky := [k[1],k[2],#divi];
      if IsDefined(step2, ky) then
        Include(~step2[ky], divi);
      else
        step2[ky] := {divi};
      end if;
      for u in divi do
        revmap[u] := ky;
      end for;
    end for;
  end for;

  /* Do initialization first */
  ResetRandomSeed();
  rlist:=[gener : gener in gens];
  rlist:= rlist cat [gens[1] : z in [1..5]];
  for rl in [1..20] do
    ii:=ourrand(#rlist)+1;
    jj:=ourrand(#rlist)+1;
    if ii ne jj then rlist[ii] *:= rlist[jj]; end if;
  end for;
  randelt := function(rlist)
    ii:=0;jj:=0;
    while ii eq jj do
      ii:=ourrand(#rlist)+1;
      jj:=ourrand(#rlist)+1;
    end while;
    rlist[ii] *:= rlist[jj];
    return rlist, rlist[ii];
  end function;

  priorities:= [ncc + 1 : z in cc];
  cnt:=1;
  expos := [0:z in cc];
  finalkeys:= [[0,0,0,0] : z in cc];

  kys:=Sort([z : z in Keys(step2)]);
//"Keys", kys;
  // utility for below, gen is a class index
  setpriorities:=function(adiv,val,gen,priorities,expos)
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
            priorities[ac]:=val;
            expos[ac] := sgn*pcnt;
            val+:=1;
          end if;
        end for;
      end if;
      pcnt+:=1;
    end while;
    return priorities, val, expos;
  end function;

  for k in kys do
    if #step2[k] eq 1 and #Rep(step2[k]) eq 1 then
      ; /* nothing to do */
    else
      /* random group elements until we hit a class we need */
      needmoregens:=true;
      while needmoregens do
        needmoregens:=false;
        for divi in step2[k] do
          if priorities[Rep(divi)] gt ncc then
            needmoregens:=true;
//"Want", Rep(divi);
            break;
          end if;
        end for;
        if needmoregens then
          rlist, ggcl:=randelt(rlist);
          gcl:=cm(ggcl);
          if ismax[gcl] and priorities[gcl] gt ncc then
            mydivkey:=revmap[gcl];
            for dd in step2[mydivkey] do
              if gcl in dd then
                priorities, cnt, expos:=setpriorities(dd,cnt,gcl,priorities,expos);
                break;
              end if;
            end for;
            divisors:=Divisors(cc[gcl][1]);
            for kk:=2 to #divisors-1 do
              newgen:=pm(gcl,divisors[kk]);
              powerdiv:=revmap[newgen];
              for dd in step2[powerdiv] do
                if newgen in dd then
                  priorities, cnt, expos:=setpriorities(dd,cnt,newgen,priorities,expos);
                  break;
                end if;
              end for;
            end for;
          end if;
        end if;
      end while;
    end if;
    // We now have enough apex generators for these divisions
    for divi in step2[k] do
      for aclass in divi do
        finalkeys[aclass] := [k[1],k[2],k[3], priorities[aclass],expos[aclass]];
      end for;
    end for;
  end for; /* End of keys loop */
  ParallelSort(~finalkeys,~cc);
  labels:=["" : z in cc];
  divcnt:=0;
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
  return cc,finalkeys, labels;
end intrinsic;

intrinsic testCCs(g::Any)->Any
  {}
  cc:=ConjugacyClasses(g);
  cm:=ClassMap(g);
  pm:=PowerMap(g);
  gens:=Generators(g); // Get this from the LMFDBGrp?
  return ordercc(g,cc,cm,pm,gens);
end intrinsic;

