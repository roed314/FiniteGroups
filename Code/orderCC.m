
intrinsic ordercc(G::Any) -> Any
  {}
  g:=G;
  if Type(G) eq LMFDBGrp then
    g:=G`MagmaGrp;
  end if;
  cc:=ConjugacyClasses(g);
  ncc:=#cc;
  cm:=ClassMap(g);
  pm:=PowerMap(g);
gens:=[h : h in Generators(g)];
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
  labels := [* "" : z in cc *];
  ordering := [0:z in cc];
  finalkeys:= [[0,0,0,0] : z in cc];

  kys:=Sort([z : z in Keys(step2)]);
//"Keys", kys;
  /* utility for below, gen is a class index */
  setpriorities:=function(adiv,val,gen,priorities)
    notdone:=0;
    for j in adiv do
      if priorities[j] gt ncc then notdone+:=1; end if;
    end for;
    pcnt:=1;
    while notdone gt 0 do
      for sgn in [1,-1] do
        ac := pm(gen, sgn*pcnt);
//"Testing", gen, " to ", sgn*pcnt," got ", ac, priorities;
        if priorities[ac] gt ncc then 
          notdone -:=1; 
          priorities[ac]:=val;
          val+:=1;
        end if;
      end for;
      pcnt+:=1;
    end while;
    return priorities, val;
  end function;

  for k in kys do
//"Key ",k, step2[k];
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
                priorities, cnt:=setpriorities(dd,cnt,gcl,priorities);
                break;
              end if;
            end for;
            divisors:=Divisors(cc[gcl][1]);
            for kk:=2 to #divisors-1 do
              newgen:=pm(gcl,divisors[kk]);
              powerdiv:=revmap[newgen];
              for dd in step2[powerdiv] do
                if newgen in dd then
                  priorities, cnt:=setpriorities(dd,cnt,newgen,priorities);
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
        finalkeys[aclass] := [k[1],k[2],k[2], priorities[aclass]];
      end for;
    end for;
  end for; /* End of keys loop */

  return cc,finalkeys;
end intrinsic;
