
intrinsic order(H::LMFDBRepQQ) -> Any
  {The size of the group}
  HH := H`MagmaGrp;
  return Order(HH);
end intrinsic;