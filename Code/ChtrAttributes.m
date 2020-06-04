// TODO
intrinsic label(Chi::LMFDBGrpChrtCC) -> MonStgElt
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
intrinsic group(Chi::LMFDBGrpChrtCC) -> Any
  {}
end intrinsic;

intrinsic dim(Chi::LMFDBGrpChrtCC) -> Any
  {Dimension of the representation associated to Chi}
  CChi := Chi`MagmaChtr;
  return CChi[1];
end intrinsic;

// TODO
intrinsic counter(Chi::LMFDBGrpChrtCC) -> Any
  {}
end intrinsic;

intrinsic kernel(Chi::LMFDBGrpChrtCC) -> Any
  {}
  CChi := Get(Chi, "MagmaChtr");
  KK := Kernel(CChi);
  // need to get subgroup label for kernel
end intrinsic;

// TODO
intrinsic center(Chi::LMFDBGrpChrtCC) -> Any
  {}
  CChi := Get(Chi, "MagmaChtr");
  Z := Center(CChi);
  // need to get subgroup label for center
end intrinsic;

intrinsic faithful(Chi::LMFDBGrpChrtCC) -> BoolElt
  {}
  CChi := Get(Chi, "MagmaChtr");
  return IsFaithful(CChi);
end intrinsic;

// TODO
// want image as subgroup of GL_n(CC)
// can get abstract image using G/kernel
intrinsic image(Chi::LMFDBGrpChrtCC) -> Any
  {}
  // probably need to use associated LMFDBRepCC...
end intrinsic;
