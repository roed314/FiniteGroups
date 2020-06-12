/* IS center and commutator saved somewhere already? */
/* whether H is contained in both the center and commutator subgroups of G */
intrinsic stem(H::LMFDBSubGrp) -> BoolElt
   {Determine if a subgroup is maximal}
   GG := Get(H, "MagmaAmbient");
   HH := H`MagmaSubGrp;
   Cent:=Center(GG);
   Comm:=CommutatorSubgroup(GG);
   if HH subset Cent and HH subset Comm then
      return true;
   else
     return false;
   end if;
end intrinsic;


intrinsic conjugacy_class_count(H::LMFDBSubGrp) -> Any
    {used later}
    return None();
end intrinsic;


/* Next 4 to be added later */
intrinsic quotient_action_image(H::LMFDBSubGrp) -> Any
    {used later}
    return None();
end intrinsic;

intrinsic quotient_action_kernel(H::LMFDBSubGrp) -> Any
    {used later}
    return None();
end intrinsic;

intrinsic quotient_fusion(H::LMFDBSubGrp) -> Any
    {used later}
    return None();
end intrinsic;

intrinsic subgroup_fusion(H::LMFDBSubGrp) -> Any
    {used later}
    return None();
end intrinsic;



/* For groups */
intrinsic counter(G::LMFDBGrp) -> RngIntElt
{Second entry in label}
   lab:= Get(G,"label");
   spl:=Split(lab,".");
   return eval spl[2];
end intrinsic;


intrinsic elt_rep_type(G:LMFDBGrp) -> Any
    {type of an element of the group}
    if Type(G`MagmaGrp) eq GrpPC then
        return 0;
    elif Type(G`MagmaGrp) eq GrpPerm then
        return -Degree(G`MagmaGrp);
    elif Type(G`MagmaGrp) eq GrpMat then
        R := CoefficientRing(G);
        if R eq Integers() then
            return 1;
        elif Type(R) eq FldFin then
            return #R;
        else
            error Sprintf("Unsupported ring %o", R);
        end if;
    else
        error Sprintf("Unsupported group type %o", Type(G`MagmaGrp));
    end if;
end intrinsic;


/* should be improved when matrix groups are added */
intrinsic finite_matrix_group(G:LMFDBGrp)-> Any
{determines whether finite matrix group}
  return None();
end intrinsic;

/* placeholder for when larger groups get added */
intrinsic old_label(G:LMFDBGrp)-> Any
{graveyard for labels when they are no longer needed}  
  return None();
end intrinsic;



