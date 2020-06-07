
intrinsic getirrreps(g::Any)->Any
  {}
  e:=Exponent(g);
  K:=CyclotomicField(e);
  try
    im:=IrreducibleModules(g,K);
    return im;
  catch e ;
  end try;
  nirr:=#Classes(g);
  im:=<>;
  ind:=1;
  ordg:=Order(g);
  while #im lt nirr do
    ind+:=1;
//"Index ", ind, "length", #im;
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

intrinsic getreps(g::Any)->Any
  {Get irreducible matrix representations}
  im:=getirrreps(g);
  result:=<>;
  for rep in im do
    nag:=Nagens(rep);
    data:= <<g . j, ActionGenerator(rep, j)> : j in [1..nag]>;
    Append(~result, data);
  end for;
  return result;
end intrinsic;

/*



*/
