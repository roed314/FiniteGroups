

intrinsic characteristic(H::LMFDBSubGrp) -> Any
  {Returns true if H is a characteristic subgroup of G}
  if not Get(H, "normal") then
    return false;
  end if;
  G := H`Grp;
  HH := H`MagmaSubGrp;
  A:=Get(G, "MagmaAutGroup");
  gens:=Generators(A); //we only need to check the generators
  Hgens:=Generators(HH);
  for aut in gens do
    for h in Hgens do
      if not(aut(h) in HH) then
        return false;
      end if;
    end for;
  end for;
  return true;
end intrinsic;






intrinsic number_characteristic_subgroups(G::LMFDBGrp) -> Any
    {Compute the number of characteristic subgroups}
    S:=Get(G, "Subgroups");
    return #[H : H in S | Get(H, "characteristic")];
end intrinsic;






intrinsic number_subgroup_classes(G::LMFDBGrp) -> Any
  {Calculates the number of subgroups of the group, up to conjugation by G}
  return #Get(G,"Subgroups");
end intrinsic;







intrinsic number_subgroups(G::LMFDBGrp) -> Any
  {Calculates the number of subgroups of the group}
  S:=Get(G,"Subgroups");
  total:=0;
  for s in S do //the AllSubgroups function is pretty slow, we try not to call it
    total+:=#Conjugates(Get(G, "MagmaGrp"), Get(s, "MagmaSubGrp"));
  end for;
  return total;
end intrinsic;






intrinsic number_normal_subgroups(G::LMFDBGrp) -> Any
  {Calculates the number of normal subgroups of the group}
  S:=Get(G,"Subgroups");
  total:=0;
  for s in S do
    if Get(s,"normal") then
      total+:=1;
    end if;
  end for;
  return total;
end intrinsic;










intrinsic mobius_function(G::LMFDBGrp) -> Any
  {Calculates the images of the subgroup-Mobius function on subgroups of G}
    if G`all_subgroups_known and G`subgroup_inclusions_known then
      L:=G`SubGrpLat;
      MobiusImages:=[[#L,1]]; //μ_G(G) = 1

      for i in [1..#L-1] do
        sum:=0;
        for m in MobiusImages do
          if L!(#L-i) subset L!m[1] then
            sum+:=Length(L!m[1])* NumberOfInclusions(L!(#L-i),L!m[1]) * m[2] / Length(L!(#L-i)); //counts inclusions
          end if;
        end for;
        Append(~MobiusImages,[(#L-i),-sum]);
      end for;

      S:=Get(G,"Subgroups");

      conj_mobii:=[];
      subgps_new := [];
      for s in S do //loops over the subgroups and adds the Mobius function data to each one
        s_new := s;
        H:=s_new`MagmaSubGrp;
        for m in MobiusImages do
          if IsConjugate(G`MagmaGrp,H,L[m[1]]) then
            Append(~conj_mobii,[*s,m[2]*]);
            s_new`mobius_function := m[2];
            Append(~subgps_new,s_new);
            break m;
          end if;
        end for;
      end for;
      G`Subgroups := subgps_new;
      //printf "Mobius function values assigned to subgroups of %o\n", G;
      return 1;
    else
      return None();
    end if;
end intrinsic;



intrinsic eulerian_function(G::LMFDBGrp) -> Any
  {Calculates the Eulerian function of G for n = rank(G)}
  if not assigned G`mobius_function then 
    fix:=mobius_function(G);
  end if;
  if Get(G, "order") eq 1 then return 1; end if;
  n:=Get(G,"rank");
  sum:=0;
  subs:=G`Subgroups;
  for s in subs do
    sum+:=(#s`MagmaSubGrp)^n * s`mobius_function * #Conjugates(G`MagmaGrp,s`MagmaSubGrp);
  end for;
  aut := G`aut_order;
  assert sum mod aut eq 0;
  return sum div aut;
end intrinsic;



intrinsic rank(G::LMFDBGrp) -> Any
  {Calculates the rank of the group G}
  if Get(G, "order") eq 1 then return 0; end if;
  if Get(G,"cyclic") then
    return 1;
  else
    r:=2;
    subs:=Get(G,"Subgroups");
    while r le #G`MagmaGrp+1 do
      sum:=0;
      for s in subs do
        sum+:=(#s`MagmaSubGrp)^r * s`mobius_function;
      end for;
      if sum gt 0 then
        return r;
      end if;
      r+:=1;
    end while;
    return -1; //this means something went wrong, maybe a real error should be thrown here instead?
  end if;
end intrinsic;





//intrinsic complements(H::LMFDBSubGrp) -> Any
  //{Returns the subgroups K of G such that H ∩ K = e and G=HK}
  //if not Get(H,"normal") then
    //return [];
  //else
    //return Complements(Get(H,"MagmaAmbient"),H`MagmaSubGrp);
  //end if;
//end intrinsic;
