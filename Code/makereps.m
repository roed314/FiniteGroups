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
    cct:=Get(G, "QQCharacters");
    ct:=<c`MagmaChtr : c in cct>;
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
    mult:= Field eq "C" select 1 else Get(cct[j], "schur_index");
    for rep in im do
      if Character(rep) eq ct[j]*mult then
        res[j]:=<cct[j], rep, tvals[j]>;
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

   Field is "Q" or "C"
 */
intrinsic getreps(G::LMFDBGrp, Field::MonStgElt: dosave:=false)->Any
  {Get irreducible matrix representations}
  im:=getirrreps(G: Field:=Field);
  cct:=Get(G, "QQCharacters");
  g:=G`MagmaGrp;
  result:=<>;
  for rep in im do
    nag:=Nagens(rep[2]);
    data:= <<g . j, ActionGenerator(rep[2], j)> : j in [1..nag]>;
    Append(~result, <rep[1], rep[3], data>);
  end for;

  /* myimages contains faithful images for this group stored as
     label -> <dimension, generator list>
  */
  myimages:=AssociativeArray(); 
  System("mkdir -p Qreps");
  result2:=<>;
  for rep in result do
    replabel:= rep_label(rep[1], [z[2] : z in rep[3]], myimages);
    r3 := [z[2] : z in rep[3]];
    if replabel eq Get(rep[1], "label") then
      r := New(LMFDBRepQQ);
      r`group := Get(G, "label");
      r`gens := [castZ(geninfo, "Q") : geninfo in r3];
      r`dim := Integers() ! Degree(Get(rep[1], "MagmaChtr"));
      r`carat_label := None();
      r`c_class := None();
      r`irreducible:= true;
      r`label := replabel;
      r`decomposition:= [<r`label, 1>];
      r`order := Get(G, "order");
      myimages[replabel] := <r`dim, r3>;
      saverep(r);
      Append(~result2, r);
      if dosave then
        Write("JJ-test/reps_qq/"*Get(G,"label"),SaveLMFDBObject(r));
      end if;
    end if;
    // Write to a file to track character label -> rep label
    write("QQchars2reps", Get(rep[1], "label") * " " *replabel);
  end for;
  return result2;
end intrinsic;

intrinsic rep_label(C::LMFDBGrpChtrQQ, r::Any, A::Assoc)->MonStgElt
 {Return the label for the image of a representation.  It might come from
  a quotient group, or from the current group but already seen, or it might
  be new.}
  qdim := Get(C, "qdim")*Get(C, "schur_index");
  bigg := GL(qdim, Integers());
  K:=sub<bigg| { g : g in r}>;
  if Get(C, "faithful") then // this group
    for k in Keys(A) do
      if A[k][1] eq qdim then
        H:=sub<bigg| A[k][2]>;
        if IsGLQConjugate(H,K) then
          return k;
        end if;
      end if;
    end for;
    return Get(C, "label");
  else // need quotient group, read from file
    try
      ker:=Kernel(Get(C,"MagmaChtr"));
      quot:=Get(C,"Grp")`MagmaGrp/ker;
      idquot:=IdentifyGroup(quot);
      oldreps:=Split(Read(Sprintf("%o/%o.%o", "Qreps", idquot[1], idquot[2])));
      for orep in oldreps do
        dat := Split(orep, " ");
        lab := dat[1];
        dm := eval(dat[2]);
        elts := eval(dat[3]);
        elts := [Matrix(qdim,qdim, z): z in elts];
        H := sub<bigg|elts>;
        if IsGLQConjugate(H,K) then
          return lab;
        end if;
      end for;
    catch e
      "Error reading old reps for ", idquot;
      return "";
    end try;
    assert false;
    return ""; // Should not get here
  end if;
end intrinsic;

intrinsic castZ(m::Any, Field::Any) -> Any
  {Take a matrix with entries in Q and cast them to Z.  They should already
   be integers.  If Field is not "Q", do nothing to entries.
   Output is a list of lists rather than a matrix.}
  if Type(m) eq AlgMatElt then
    r:=NumberOfRows(m);
    c:=NumberOfColumns(m);
    m := [[m[i,j] : i in [1..c]] : j in [1..r]];
  else
    r:= #m;
    c:= #m[1];
  end if;
  if Field eq "Q" then
    ZZ:=Integers();
    for i:= 1 to r do
      for j:= 1 to c do
        assert m[i][j] in ZZ;
      end for;
    end for;
    m:= [[ZZ!m[i][j]: i in [1..c]]: j in [1..r]];
  end if;
  return m;
end intrinsic;

/* Write a representation to a file 
   We append to the file, so make sure it is new
*/
intrinsic saverep(r::LMFDBRepQQ)
  {}
  mm:=Get(r, "gens");
  mm:=[castZ(geninfo, "Q") : geninfo in mm];
  mystr:=Sprintf("%o$%o$%o",Get(r, "label"), Get(r, "dim"), mm);
  mystr:=DelSpaces(mystr);
  mystr:=ReplaceString(mystr, "$", " ");
mystr;
  write("Qreps/"*Get(r, "group"), mystr);
end intrinsic;

/* Useful commands to lower a representation to a smaller field:
   u:= AbsoluteModuleOverMinimalField(gmodule);
   DefiningPolynomial(CoefficientRing(u));
*/
