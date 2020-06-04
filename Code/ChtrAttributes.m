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

// TODO
// Magma doesn't store group of character, as far as I can tell
intrinsic group(Chi::LMFDBGrpChtrCC) -> Any
  {}
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
  CChi := Get(Chi, "MagmaChtr");
  KK := Kernel(CChi);
  // need to get subgroup label for kernel
end intrinsic;

// TODO
intrinsic center(Chi::LMFDBGrpChtrCC) -> Any
  {}
  CChi := Get(Chi, "MagmaChtr");
  Z := Center(CChi);
  // need to get subgroup label for center
end intrinsic;

intrinsic faithful(Chi::LMFDBGrpChtrCC) -> BoolElt
  {}
  CChi := Get(Chi, "MagmaChtr");
  return IsFaithful(CChi);
end intrinsic;

// TODO
// want image as subgroup of GL_n(CC)
// can get abstract image using G/kernel
intrinsic image(Chi::LMFDBGrpChtrCC) -> Any
  {}
  // probably need to use associated LMFDBRepCC...
end intrinsic;
