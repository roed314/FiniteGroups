intrinsic label(G::Grp) -> Any
{Assigns label for small groups only right now}
   if CanIdentifyGroup(#G) then
      id:=IdentifyGroup(G);
      label:= Sprintf("%o.%o", id[1], id[2]);
      return label;
   else
      error "Can't Identify This Group Order!";
   end if;
end intrinsic;


intrinsic label(G:LMFDBGrp) -> Any
{Assign label to a LMFDBGrp type}
  return label(G`MagmaGrp);
end intrinsic;
