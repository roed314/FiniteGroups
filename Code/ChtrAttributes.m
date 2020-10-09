// TODO
intrinsic label(Chi::LMFDBGrpChtrCC) -> MonStgElt
  {}
  // N.i.dcj
  // c is a lower-case letter code for the rational class of this character
  gp_label := Get(Chi, "group");
  d := Get(Chi, "dim");
  // c := ...
  j := Get(Chi, "counter");
end intrinsic;

intrinsic group(Chi::LMFDBGrpChtrCC) -> Any
    {}
    return label(Get(Chi, "Grp"));
end intrinsic;

intrinsic dim(Chi::LMFDBGrpChtrCC) -> Any
  {Dimension of the representation associated to Chi}
  CChi := Chi`MagmaChtr;
  return CChi[1];
end intrinsic;

// TODO
intrinsic counter(Chi::LMFDBGrpChtrCC) -> Any
  {}
end intrinsic;

intrinsic kernel(Chi::LMFDBGrpChtrCC) -> Any
  {}
  return Kernel(Get(Chi, "MagmaChtr"));
end intrinsic;

intrinsic center(Chi::LMFDBGrpChtrCC) -> Any
  {}
  return Center(Get(Chi, "MagmaChtr"));
end intrinsic;

intrinsic faithful(Chi::LMFDBGrpChtrCC) -> BoolElt
  {}
  return IsFaithful(Get(Chi, "MagmaChtr"));
end intrinsic;

// TODO
// want image as subgroup of GL_n(CC)
// can get abstract image using G/kernel
intrinsic image(Chi::LMFDBGrpChtrCC) -> Any
  {}
  return None();
  // need to use associated LMFDBRepCC...
end intrinsic;

intrinsic q_character(Chi::LMFDBGrpChtrCC) -> Any
  {}
  return None();
  // need to use associated LMFDBRepCC...
end intrinsic;

intrinsic image(Chi::LMFDBGrpChtrQQ) -> Any
  {}
  return None();
  // need to use associated LMFDBRepCC...
end intrinsic;

intrinsic GetGrp(C::LMFDBGrpChtrCC) -> Grp
    {This function is used by the file IO code to help identify subgroups}
    return C`Grp;
end intrinsic;
