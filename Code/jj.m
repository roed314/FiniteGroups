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

intrinsic character_labels(G::LMFDBGrp, ct::Any, rct::Any, matching::Any) -> Any
  {Order characters and make labels for them.  This does complex and rational
   characters together since the ordering and labelling are connected.}
  g:=G`MagmaGrp;
  // Need outer sort for rct, and then an inner sort for ct
  goodsubs:=getgoodsubs(g, ct); // gives <subs, tvals>
  ntlist:= goodsubs[2];
  // Want sort list to be <degree, n, t, lex info, counter ...>
  // Priorities by lex sort
  forlexsort:=<Flat(<<Round(10^29*Real(ct[j,k])), Round(10^29*Imaginary(ct[j,k]))> : k in [1..#ct]>) : j in [1..#ct]>;
  sortme:=<<Degree(ct[j]), ntlist[j][1], ntlist[j][2]> cat forlexsort[j] cat <0,0> : j in [1..#ct]>;
  for j:=1 to #ct do 
    sortme[j][#sortme[j]] := j; 
  end for;
  for j:=1 to #matching do
    for k:=1 to #matching[j] do
      sortme[ matching[j][k] ][#sortme[j]-1] := j;
    end for;
  end for;
  // To use index on to find complex conj's
  allvals := [[ct[j][k] : k in [1..#ct]] : j in [1..#ct]];
  //Last entry is the old index
  //Second to last is the rat character
  sortme:= [[a : a in b] : b in sortme];
  Sort(~sortme);
  ctlabels:=<"" : z in [1..#ct]>;
  rctlabels:=<"" : z in [1..#rct]>;
  // Now step through to figure out the order
  done:={};
  for j:=1 to #ct do
    ;
  end for;
  
  return <<Degree(ct[j]), ntlist[j]> : j in [1..#ct]>;
end intrinsic;

