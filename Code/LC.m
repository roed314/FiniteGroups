/*
These have been moved to Subgroups.m and GrpAttributes.m

intrinsic mobius_sub(G::LMFDBGrp) -> Any
{Calculates the images of the subgroup-Mobius function on subgroups of G}
    if G`all_subgroups_known and G`subgroup_inclusions_known then
        L := G`outer_equivalence select Get(G, "SubGrpLatAut") else Get(G, "SubGrpLat");
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
            s_new`mobius_sub := m[2];
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
  if not assigned G`mobius_sub then 
    fix:=mobius_sub(G);
  end if;
  if Get(G, "order") eq 1 then return 1; end if;
  n:=Get(G,"rank");
  sum:=0;
  subs:=G`Subgroups;
  for s in subs do
    sum+:=(#s`MagmaSubGrp)^n * s`mobius_sub * #Conjugates(G`MagmaGrp,s`MagmaSubGrp);
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
    r := 2;
    subs := Get(G,"Subgroups");
    while r le #G`MagmaGrp+1 do
      sum := 0;
      for s in subs do
        sum +:= (#s`MagmaSubGrp)^r * s`mobius_sub;
      end for;
      if sum gt 0 then
        return r;
      end if;
      r +:= 1;
    end while;
    return -1; //this means something went wrong, maybe a real error should be thrown here instead?
  end if;
end intrinsic;


*/


//intrinsic complements(H::LMFDBSubGrp) -> Any
  //{Returns the subgroups K of G such that H ∩ K = e and G=HK}
  //if not Get(H,"normal") then
    //return [];
  //else
    //return Complements(Get(H,"MagmaAmbient"),H`MagmaSubGrp);
  //end if;
//end intrinsic;
