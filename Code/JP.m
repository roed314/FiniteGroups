intrinsic IsMaximal(H::LMFDBSubGrp) -> BoolElt
  {Determine if a subgroup is maximal}
  GG := H`MagmaAmbient;
  HH := H`MagmaSubGrp;
  return IsMaximal(GG, HH);
end intrinsic;
