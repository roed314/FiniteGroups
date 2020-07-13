/* Main function is getreps.  If g is a magma group,
   getreps(g) for complex representations or
   getreps(g:Field:="Q")
   for rational representations
*/

/* Not used
intrinsic firstip(chr::Any, pc::Any) -> Any
  {First permutation character containing chr from the list pc}
  cnt:=1;
  while InnerProduct(chr, pc[cnt]) eq 0 do cnt:=cnt+1; end while;
  return cnt;
end intrinsic;
*/

intrinsic myti(g::Any,sub::Any) -> Any
  {Transitive group identification for sub, a subgroup of g}
  inn := Index(g,sub);
  if inn gt 47 then
    return [Index(g,sub),0];
  end if;
  a,b := TransitiveGroupIdentification(CosetImage(g,sub));
  return [b,a];
end intrinsic;

/* g is a magma group, ct is its character table */
intrinsic getgoodsubs(g::Any,ct::Any)->Any
  {Get optimal subgroups s.t. the permutation representations contain the irreducible representations.  Also capture the t-numbers of the permutation representations.}
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

// Any other field type produces rationals
intrinsic getirrreps(G::LMFDBGrp: Field:="C")->Any
  {}
  g:=G`MagmaGrp;
  if Field eq "C" then
      e:=Exponent(g);
      K:=CyclotomicField(e);
      cct:=Get(G, "CCCharacters");
      ct:=<c`MagmaChtr : c in cct>;
  else
    K:=Rationals();
    comp_ct:=CharacterTable(g);
    cct:=Get(G, "QQCharacters");
    ct:=<c`MagmaChtr : c in cct>;
    //ct:=Get(G, "MagmaRationalCharacterTable");
    //matching:=Get(G, "MagmaCharacterMatching");
  end if;
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
    //mult:= Field eq "C" select 1 else SchurIndex(comp_ct[matching[j][1]]);
    mult:= Field eq "C" select 1 else Get(cct[j], "schur_index");
    for rep in im do
      if Character(rep) eq ct[j]*mult then
        res[j]:=<ct[j], rep, tvals[j]>;
        Exclude(~im, rep);
        break;
      end if;
    end for;
    assert Type(res[j]) ne RngIntElt;
  end for;
  return <z : z in res>;
end intrinsic;

/* Returns a list of trips 
   <character, minimal <n,t>, list of generators and images> 

   Beware, if the field type is Rational, then some reps have
   characters which are multiples of the values in the rational
   character table.
 */
intrinsic getreps(G::LMFDBGrp: Field:="C")->Any
  {Get irreducible matrix representations}
  im:=getirrreps(G: Field:=Field);
  g:=G`MagmaGrp;
  result:=<>;
  for rep in im do
    nag:=Nagens(rep[2]);
    data:= <<g . j, castZ(ActionGenerator(rep[2], j), Field)> : j in [1..nag]>;
    Append(~result, <rep[1], rep[3], data>);
  end for;
  return result;
end intrinsic;

intrinsic castZ(m::Any, Field::Any) -> Any
  {Take a matrix with entries in Q and cast them to Z.  They should already
   be integers.  If Field is not "Q", do nothing.}
  if Field ne "Q" then return m; end if;
  r:=NumberOfRows(m);
  c:=NumberOfColumns(m);
  ZZ:=Integers();
  for i:= 1 to r do
    for j:= 1 to c do
      assert m[i,j] in ZZ;
    end for;
  end for;
  return Matrix(ZZ,r,c,[[ZZ!m[i,j]: j in [1..c]]:i in [1..r]]);
end intrinsic;

/* Useful commands to lower a representation to a smaller field:
   u:= AbsoluteModuleOverMinimalField(gmodule);
   DefiningPolynomial(CoefficientRing(u));
*/
