
intrinsic firstip(chr::Any, pc::Any) -> Any
  {}
  cnt:=1;
  while InnerProduct(chr, pc[cnt]) eq 0 do cnt:=cnt+1; end while;
  return cnt;
end intrinsic;

intrinsic myti(g::Any,sub::Any) -> Any
  {}
  inn := Index(g,sub);
  if inn gt 47 then
    return [Index(g,sub),0];
  end if;
  a,b := TransitiveGroupIdentification(CosetImage(g,sub));
  return [b,a];
end intrinsic;

intrinsic getgoodsubs(g::Any,ct::Any)->Any
  {Get optimal subgroups s.t. the permutation representations contian the irreducible representations.  Also capture the t-numbers of the permutation representations.}
  subs:=[* 0 : z in ct *];
  tvals :=[ [0,0] : z in ct ];
  notdone := {z : z in [1..#ct]};
  ind:=1;
  ordg:=Order(g);
  while not IsEmpty(notdone) do
    if (ordg mod ind) eq 0 then
      sg:=Subgroups(g: OrderEqual:= ordg div ind);
      sg:=[z`subgroup : z in sg];
      pc := [ <PermutationCharacter(g,z),z> : z in sg];
      // Sort them based on t number
      if ind lt 48 then
        tnums:=[TransitiveGroupIdentification(CosetImage(g,z)) : z in sg];
        ParallelSort(~tnums, ~pc);
        pc:= [<pc[j],[ind,tnums[j]]> : j in [1..#sg]];
      else
        pc:= [<pc[j],[ind,0]> : j in [1..#sg]];
      end if;
      newlydone:={};
      for k in notdone do
        for cnt:=1 to #pc do
          if InnerProduct(ct[k], pc[cnt][1][1]) ne 0 then
            subs[k]:= pc[cnt][1][2];
            tvals[k]:=pc[cnt][2];
            Include(~newlydone, k);
            break;
          end if;
        end for;
      end for;
      notdone := notdone diff newlydone;
    end if;
    ind +:= 1;
  end while;
  subs:=Set([z:z in subs]);
  return <subs, tvals>;
end intrinsic;

intrinsic getirrreps(g::Any)->Any
  {}
  e:=Exponent(g);
  K:=CyclotomicField(e);
  ct:=CharacterTable(g);
  gs:=getgoodsubs(g, ct);
  subs:=gs[1];
  tvals:=gs[2];
  im:={};
  for s in subs do
    pm:=PermutationModule(g,s,K);
    ds:=DirectSumDecomposition(pm);
    for rep in ds do
      good:=true;
      for orep in im do
        if IsIsomorphic(rep, orep) then
          good:=false;
          break;
        end if;
      end for;
      if good then Include(~im, rep); end if;
    end for;
  end for;
  res:=[*0 : z in ct*];
  for j:=1 to #ct do
    for rep in im do
      if Character(rep) eq ct[j] then
        res[j]:=<ct[j], rep, tvals[j]>;
        Exclude(~im, rep);
        break;
      end if;
    end for;
    assert Type(res[j]) ne RngIntElt;
  end for;
  return <z : z in res>;
end intrinsic;

intrinsic getirrrepsold(g::Any)->Any
  {}
  e:=Exponent(g);
  K:=CyclotomicField(e);
  try
    im:=IrreducibleModules(g,K);
    return im;
  catch e ;
  end try;
  /* Step through low index subgroups capturing
     irreducible reps when they occur in permutation
     representations.

     This could be a little more efficient if we kept
     track of characters and only decomposed a rep
     if a character computation showed that a new rep
     was in it */
  nirr:=#Classes(g);
  im:=<>;
  ind:=1;
  ordg:=Order(g);
  while #im lt nirr do
    ind+:=1;
"Index ", ind, "length", #im;
    if (ordg mod ind) eq 0 then
      sg:=Subgroups(g: OrderEqual:= ordg div ind);
      sg:=[z`subgroup : z in sg];
      cands:= [PermutationModule(g,h,K) : h in sg];
      for cand in cands do
        ds:=DirectSumDecomposition(cand);
        for newim in ds do
          skip:=false;
          for old in im do
            if IsIsomorphic(old, newim) then
              skip:=true;
              break;
            end if;
          end for;
          if not skip then Append(~im, newim); end if;
        end for;
      end for;
    end if;
  end while;
  return [z : z in im];
end intrinsic;

/* Returns a list of trips 
   <character, minimal <n,t>, list of generators and images> 
 */
intrinsic getreps(g::Any)->Any
  {Get irreducible matrix representations}
  im:=getirrreps(g);
  result:=<>;
  for rep in im do
    nag:=Nagens(rep[2]);
    data:= <<g . j, ActionGenerator(rep[2], j)> : j in [1..nag]>;
    Append(~result, <rep[1], rep[3], data>);
  end for;
  return result;
end intrinsic;

