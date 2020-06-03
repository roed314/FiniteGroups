intrinsic Label(G::Grp) -> Any
{Assigns label for small groups only right now}
   if CanIdentifyGroup(#G) then
      id:=IdentifyGroup(G);
      label:= IntegerToString(id[1]) cat "." cat IntegerToString(id[2]);
      return label;
   else
      error "Can't Identify This Group Order!";
   end if;  
end intrinsic;


intrinsic Label(G:LMFDBGrp) -> Any
{Assign label to a LMFDBGrp type}
  return Label(G`MagmaGrp);
end intrinsic;
