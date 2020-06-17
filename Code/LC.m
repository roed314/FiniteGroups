

intrinsic characteristic(H::LMFDBSubGrp) -> Any
  {Returns true if H is a characteristic subgroup of G}
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  A:=AutomorphismGroup(GG);
  gens:=Generators(A); //we only need to check the generators
  IsChar:=true;
  for aut in gens do
    for h in HH do
      if not(aut(h) in HH) then
        IsChar:=false;
        break aut;
      end if;
    end for;
  end for;
  return IsChar;
end intrinsic;






intrinsic number_characteristic_subgroups(G::LMFDBGrp) -> Any
  {Compute the number of characteristic subgroups}
  S:=Subgroups(G`MagmaGrp);
  total:=0;
  for s in S do
    H:=New(LMFDBSubGrp);
    H`Grp:=G;
    H`MagmaSubGrp:=s`subgroup;
    if Get(H,"characteristic") then
      total+:=1;
    end if;
  end for;
  return total;
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









intrinsic MobiusFunction(G::LMFDBGrp) -> Any
  {Calculates the images of the Mobius subgroup function of the group on its subgroups}
  if Get(G,"all_subgroups_known") then
    S:=AllSubgroups(G`MagmaGrp); //sorry, future person who has to edit this code to make it more efficient
    Reverse(~S); //we start from the top of the subgroup lattice
    MobiusImages:=[[*S[1],1*]]; //μ_G(G) = 1
    Exclude(~S,S[1]);

    for s in S do //calculates the images
      sum:=0;
      for m in MobiusImages do
        if s subset m[1] then
          sum+:=m[2];
        end if;
      end for;
      Append(~MobiusImages,[*s,-sum*]);
    end for;

    L:=Get(G,"Subgroups");

    conj_mobii:=[];
    subgps_new := [];
    for s in L do //converts the data to [<conjugacy class label, group>, mobius image] format
      s_new := s;
      H:=s_new`MagmaSubGrp;
      for m in MobiusImages do
        if IsConjugate(G`MagmaGrp,H,m[1]) then
          Append(~conj_mobii,[*s,m[2]*]);
          s_new`mobius_function := m[2];
          Append(~subgps_new,s_new);
          break m;
        end if;
      end for;
    end for;
    G`Subgroups := subgps_new;
    //printf "Mobius function values assigned to subgroups of %o\n", G;
    return conj_mobii;
  else
    return None();
  end if;
end intrinsic;

intrinsic eulerian_function(G::LMFDBGrp) -> Any
  {Calculates the Eulerian function of G for n = rank(G)}
  n:=Get(G,"rank");
  sum:=0;
  mobius_images:= MobiusFunction(G);
  for m in mobius_images do
    sum+:=(#m[1]`MagmaSubGrp)^n * m[2] * #Conjugates(G`MagmaGrp,m[1]`MagmaSubGrp);
  end for;
  aut := #AutomorphismGroup(G`MagmaGrp);
  assert sum mod aut eq 0;
  return sum div aut;
end intrinsic;



intrinsic rank(G::LMFDBGrp) -> Any
  {Calculates the rank of the group G}
  if Get(G,"cyclic") then
    return 1;
  else
    r:=2;
    mobius_images:= MobiusFunction(G);
    while r le #G`MagmaGrp+1 do
      sum:=0;
      for m in mobius_images do
        sum+:=(#m[1]`MagmaSubGrp)^r * m[2];
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
