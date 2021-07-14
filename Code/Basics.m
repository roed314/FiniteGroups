intrinsic NewLMFDBGrp(GG::Grp, lab::MonStgElt) -> LMFDBGrp
  {Create a new LMFDBGrp object G with G`MagmaGrp := magma_gp and G`label := lab}
  G := New(LMFDBGrp);
  G`MagmaGrp := GG;
  G`label := lab;
  return G;
end intrinsic;

intrinsic GetBasicAttributesGrp() -> Any
  {Outputs SeqEnum of basic attributes}
  return [
   ["Order","order"],
   ["Exponent","exponent"],
   ["IsAbelian" , "abelian"],
   ["IsCyclic" , "cyclic"],
   ["IsSolvable" , "solvable"],
   ["IsNilpotent" , "nilpotent"],
   ["IsSimple" , "simple"],
   ["IsPerfect" , "perfect"],
   ["Center" , "MagmaCenter"],
   ["Radical" , "MagmaRadical"],
   ["AutomorphismGroup" , "MagmaAutGroup"],
   ["NilpotencyClass" , "nilpotency_class"],
   ["Ngens" , "ngens"],
   ["DerivedLength" , "derived_length"]
    ];
end intrinsic;

intrinsic AssignBasicAttributes(G::LMFDBGrp)
  {Assign basic attributes. G`MagmaGrp must already be assigned.}
  attrs := GetBasicAttributesGrp();
  GG := G`MagmaGrp;
  for attr in attrs do
    mag_attr:=attr[1];
    db_attr:=attr[2];
    if not HasAttribute(G, db_attr) then
      eval_str := Sprintf("return %o(GG);", mag_attr);
      G``db_attr := eval eval_str;
    end if;
  end for;
  //G`IsSuperSolvable := IsSupersoluble(GG); // thanks a lot Australia! :D; only for GrpPC...
  //return Sprintf("Basic attributes assigned to %o", G);
end intrinsic;

intrinsic GetBasicAttributesSubGrp(pair::BoolElt) -> Any
  {Outputs SeqEnum of basic attributes}
  if pair then
    return [
     ["IsNormal" , "normal"],
     ["Core" , "core"],
     ["Normalizer" , "normalizer"],
     ["Centralizer" , "centralizer"],
     ["NormalClosure" , "normal_closure"],
     ["IsCentral", "central"],
     ["IsMaximal","maximal"]
      ];
  else
    return [
     ["IsCyclic" , "cyclic"],
     ["IsAbelian" , "abelian"],
     ["IsSolvable" , "solvable"],
     ["IsPerfect" , "perfect"]
      ];
  end if;
end intrinsic;

intrinsic AssignBasicAttributes(H::LMFDBSubGrp)
  {Assign basic attributes. H`MagmaSubGrp must already be assigned.}
  GG := Get(H, "MagmaAmbient");
  HH := H`MagmaSubGrp;
  attrs := GetBasicAttributesSubGrp(true);
  for attr in attrs do
    mag_attr:=attr[1];
    db_attr:=attr[2];
    if not HasAttribute(H, db_attr) then
      eval_str := Sprintf("return %o(GG, HH)", mag_attr);
      H``db_attr := eval eval_str;
    end if;
  end for;
  attrs := GetBasicAttributesSubGrp(false);
  for attr in attrs do
    mag_attr:=attr[1];
    db_attr:=attr[2];
    if not HasAttribute(H, db_attr) then
      eval_str := Sprintf("return %o(HH)", mag_attr);
      H``db_attr := eval eval_str;
    end if;
  end for;
  //return Sprintf("Basic attributes assigned to %o", H);
end intrinsic;
