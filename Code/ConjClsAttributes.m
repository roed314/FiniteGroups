intrinsic label(C::LMFDBGrpConjCls) -> MonStgElt
  {}
  gp_label := Get(C, "group");
  o := Get(C, "MagmaConjCls")[1];
  // J := capital_letter_code(C) ? TODO
  //return Sprintf("%o.%o%o", gp_label, o, J);
  return Sprintf("%o.%o", gp_label, o);
end intrinsic;

intrinsic group(C::LMFDBGrpConjCls) -> MonStgElt
    {return label of ambient group of C}
    return label(C`Grp);
end intrinsic;

intrinsic size(C::LMFDBGrpConjCls) -> Any
  {}
  CC := Get(C, "MagmaConjCls");
  return CC[2];
end intrinsic;

// TODO
intrinsic counter(C::LMFDBGrpConjCls) -> Any
  {}
  return false;
end intrinsic;

intrinsic order(C::LMFDBGrpConjCls) -> Any
  {}
  CC := Get(C, "MagmaConjCls");
  return CC[1];
end intrinsic;

// TODO
// not sure how to do this...
// Currently returns the subgroup rather than its label
intrinsic centralizer(C::LMFDBGrpConjCls) -> Any
  {}
  gp_label := Get(C, "group");
  //G := LoadGrp(gp_label, );
  g := Get(C, "representative");
  return Centralizer(Parent(g), g);
end intrinsic;

// TODO
intrinsic powers(C::LMFDBGrpConjCls) -> Any
  {}
  return None();
end intrinsic;

intrinsic representative(C::LMFDBGrpConjCls) -> Any
  {}
  CC := Get(C, "MagmaConjCls");
  return CC[3]; // this may need to change depending on how elts are represented in ambient group
end intrinsic;

intrinsic GetGrp(C::LMFDBGrpConjCls) -> Grp
    {This function is used by the file IO code to help idenify subgroups}
    return C`Grp;
end intrinsic;

intrinsic GetGrp(C::LMFDBGrpPermConjCls) -> Grp
    {This function is used by the file IO code to help identify subgroups}
    return C`Grp;
end intrinsic;

