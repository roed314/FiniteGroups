
intrinsic MagmaPowerMap(G::LMFDBGrp) -> Any
  {Return Magma's powermap.}
  return PowerMap(G`MagmaGrp);
end intrinsic;

intrinsic MagmaClassMap(G::LMFDBGrp) -> Any
  {Return Magma's ClassMap.}
  return ClassMap(G`MagmaGrp);
end intrinsic;

intrinsic MagmaConjugacyClasses(G::LMFDBGrp) -> Any
  {Return Magma's Conjugacy classes.}
  return ConjugacyClasses(G`MagmaGrp);
end intrinsic;

intrinsic MagmaGenerators(G::LMFDBGrp) -> Any
  {Like magma command GeneratorsSequence, but works for small groups too.
   It should change to use our recorded generators.}
  g:=G`MagmaGrp;
  ng:=NumberOfGenerators(g);
  return [g . j : j in [1..ng]];
end intrinsic;

intrinsic name(G::LMFDBGrp) -> Any
  {Returns Magma's name for the group.}
  g:=G`MagmaGrp;
  return GroupName(g);
end intrinsic;

intrinsic tex_name(G::LMFDBGrp) -> Any
  {Returns Magma's name for the group.}
  g:=G`MagmaGrp;
  return GroupName(g: TeX:=true);
end intrinsic;

intrinsic Socle(G::LMFDBGrp) -> Any
  {Returns the socle of a group.}
  g:=G`MagmaGrp;
  try
    s:=Socle(g);
    return s;
  catch e  ;
  end try;
  nl:=NormalLattice(g);
  mins:=[z : z in MinimalOvergroups(Bottom(nl))];
  spot:= IntegerRing() ! mins[#mins];
  // Can't believe there is no support of join of subgroups
  while spot le #nl do
    fail := false;
    for j:=1 to #mins do
      if not ((nl ! spot) ge (nl ! mins[j])) then
        fail:=true;
        break;
      end if;
    end for;
    if fail then spot +:= 1; else break; end if;
  end while;
  assert spot le #nl;
  return nl! spot;
end intrinsic;

intrinsic coset_action_label(H::LMFDBSubGrp) -> Any
  {Determine the transitive classification for G/H}
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  if Order(Core(GG,HH)) eq 1 then
    if Index(GG,HH) gt 47 then
      return None();
    end if;
    ca:=CosetImage(GG,HH);
    t,n:=TransitiveGroupIdentification(ca);
    return Sprintf("%oT%o", n, t);
  else
    return None();
  end if;
end intrinsic;

intrinsic MagmaCharacterTable(G::LMFDBGrp) -> Any
  {Return Magma's character table.}
  return CharacterTable(G`MagmaGrp);
end intrinsic;

intrinsic MagmaCharacterMatching(G::LMFDBGrp) -> Any
  {Return the list of list showing which complex characters go with each rational character.}
  u:=Get(G,"MagmaRationalCharacterTable");
  return G`MagmaCharacterMatching; // Set as side effect
end intrinsic;


intrinsic MagmaRationalCharacterTable(G::LMFDBGrp) -> Any
  {Return Magma's rational character table.}
  u,v:= RationalCharacterTable(G`MagmaGrp);
  G`MagmaCharacterMatching:=v;
  return u;
end intrinsic;

intrinsic complexconjindex(ct::Any, gorb::Any, achar::Any) -> Any
  {Find the complex conj of achar among indeces in gorb all from 
   character table ct (which is now a list of lists).}
  findme:=[ComplexConjugate(achar[z]) : z in [1..#achar]];
  gorbvals:=[ct[z] : z in gorb];
  myind:= Index(gorbvals, findme);
  return gorb[myind];
end intrinsic;

intrinsic characters_add_sort_and_labels(G::LMFDBGrp, cchars::Any, rchars::Any) -> Any
  {Order characters and make labels for them.  This does complex and rational
   characters together since the ordering and labelling are connected.}
  g:=G`MagmaGrp;
  ct:=Get(G,"MagmaCharacterTable");
  rct:=Get(G,"MagmaRationalCharacterTable");
  matching:=Get(G,"MagmaCharacterMatching");
  perm:=Get(G, "CCpermutationInv"); // perm[j] is the a Magma index
  glabel:=Get(G, "label");
  // Need outer sort for rct, and then an inner sort for ct
  goodsubs:=getgoodsubs(g, ct); // gives <subs, tvals>
  ntlist:= goodsubs[2];
  // Need the list which takes complex chars and gives index of rational char
  comp2rat:=[0 : z in ct];
  for j:=1 to #matching do
    for k:=1 to #matching[j] do
      comp2rat[matching[j][k]]:=j;
    end for;
  end for;
  // Want sort list to be <degree, n, t, lex info, counter ...>
  // We give rational character values first, then complex
  // Priorities by lex sort
  forlexsortrat:=Flat(<<rct[comp2rat[j]][perm[k]] : j in [1..#rct]> : k in [1..#ct]>);
  forlexsort:=<Flat(<<Round(10^29*Real(ct[j,perm[k]])), Round(10^29*Imaginary(ct[j,perm[k]]))> : k in [1..#ct]>) : j in [1..#ct]>;
  // We add three fields at the end. The last is old index, before sorting.
  // Before that is the old index in the rational table
  // Before that is the old index of its complex conjugate
  sortme:=<<Degree(ct[j]), ntlist[j][1], ntlist[j][2], #matching[comp2rat[j]]> cat forlexsortrat
     cat forlexsort[j] cat <0,0,0> : j in [1..#ct]>;
  len:=#sortme[1];
  for j:=1 to #ct do 
    sortme[j][len] := j; 
  end for;
  allvals := [[ct[j][k] : k in [1..#ct]] : j in [1..#ct]];
  for j:=1 to #matching do
    for k:=1 to #matching[j] do
      sortme[matching[j][k]][len-1] := j;
      sortme[matching[j][k]][len-2]:= complexconjindex(allvals, matching[j], ct[matching[j][k]]);
    end for;
  end for;
  sortme:= [[a : a in b] : b in sortme];
  Sort(~sortme);
  // Now step through to figure out the order
  donec:={};
  doneq:={};
  olddim:=-1;
  rcnt:=0;
  rtotalcnt:=0;
  ccnt:=0;
  ctotalcnt:=0;
  for j:=1 to #sortme do
    dat:=sortme[j];
    if dat[1] ne olddim then
      olddim := dat[1];
      rcnt:=0;
      ccnt:=0;
    end if;
    if dat[len] notin donec then // New C character
      if dat[len-1] notin doneq then // New Q character
        rcnt+:=1;
        ccnt:=0;
        rtotalcnt+:=1;
        rcode:=num2letters(rcnt: Case:="lower");
        Include(~doneq, dat[len-1]);
        rindex:=Integers()!dat[len-1];
        rchars[rindex]`counter :=rtotalcnt;
        rchars[rindex]`label:=Sprintf("%o.%o%o.%o",glabel,dat[1],rcode,dat[4]);
        rchars[rindex]`nt:=[dat[2],dat[3]];
      end if;
      ccnt+:=1;
      ctotalcnt+:=1;
      Include(~donec, dat[len]);
      cindex:=Integers()!dat[len];
      cchars[cindex]`counter:=ctotalcnt;
      cchars[cindex]`nt:=[dat[2],dat[3]];
      cextra:= (dat[4] eq 1) select "" else Sprintf("%o", ccnt);
      cchars[cindex]`label:=Sprintf("%o.%o%o", glabel, dat[1],rcode)*cextra;
      if dat[len-2] notin donec then
        ccnt+:=1;
        ctotalcnt+:=1;
        cindex:=Integers()!dat[len-2];
        Include(~donec, dat[len-2]);
        cchars[cindex]`counter:=ctotalcnt;
        cchars[cindex]`nt:=[dat[2],dat[3]];
        cextra:= (dat[4] eq 1) select "" else Sprintf("%o", ccnt);
        cchars[cindex]`label:=Sprintf("%o.%o%o", glabel, dat[1],rcode)*cextra;
      end if;
    end if;
  end for;
  
  return <cchars, rchars>;
end intrinsic;

