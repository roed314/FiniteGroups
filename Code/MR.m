
intrinsic order(H::LMFDBRepQQ) -> Any
  {The size of the group}
  return Order(H`MagmaGrp);
end intrinsic;

intrinsic group(H::LMFDBRepQQ) -> Any
  {returns the LMFDB id for the abstract group}
  return label(H`MagmaGrp);
end intrinsic;


intrinsic order(H::LMFDBRepZZ) -> Any
  {The size of the group}
  return Order(H`MagmaGrp);
end intrinsic;

intrinsic group(H::LMFDBRepZZ) -> Any
  {returns the LMFDB id for the abstract group}
  return label(H`MagmaGrp);
end intrinsic;