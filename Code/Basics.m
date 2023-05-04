intrinsic NewLMFDBGrp(GG::Grp, lab::MonStgElt) -> LMFDBGrp
{Create a new LMFDBGrp object G with G`MagmaGrp := magma_gp and G`label := lab}
    G := New(LMFDBGrp);
    // PC groups don't have an Order attribute
    if Type(G) eq GrpMat or Type(G) eq GrpPerm then
        N := StringToInteger(Split(lab, ".")[1]);
        GG`Order := N;
    end if;
    G`MagmaGrp := GG;
    G`label := lab;
    return G;
end intrinsic;

intrinsic GetBasicAttributesGrp() -> Any
  {Outputs SeqEnum of basic attributes}
  // You shouldn't add any attribute here that depends on the specific choice of generators,
  // since this is called before RePresent.
  return [
   ["Order","order"],
   ["Exponent","exponent"],
   ["IsAbelian" , "abelian"],
   ["IsCyclic" , "cyclic"],
   ["IsSolvable" , "solvable"],
   ["IsNilpotent" , "nilpotent"],
   ["IsSimple" , "simple"],
   ["IsPerfect" , "perfect"],
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
        //    print attr;
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
     //     ["Centralizer" , "centralizer"], group 120.5 is annoying
     ["NormalClosure" , "normal_closure"],
     ["IsCentral", "central"]
      ];
  else
    return [
     ["IsCyclic" , "cyclic"],
     ["IsAbelian" , "abelian"],
     ["IsSolvable" , "solvable"],
     ["IsPerfect" , "perfect"],
     ["IsNilpotent", "nilpotent"]
      ];
  end if;
end intrinsic;

intrinsic AssignBasicAttributes(H::LMFDBSubGrp)
{Assign basic attributes. H`MagmaSubGrp must already be assigned.}
    GG := Get(H, "MagmaAmbient");
    HH := H`MagmaSubGrp;
    attrs := GetBasicAttributesSubGrp(true);
    for attr in attrs do
	//   print attr;
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
    // Have to deal with centralizer separately because of annoying magma bug
    db_attr:="centralizer";
    if not HasAttribute(H,db_attr) then
        try
            H`centralizer := Centralizer(GG,HH);
        catch e     //dealing with a strange Magma bug in 120.5
            GenCentralizers:={Centralizer(GG,h) : h in Generators(HH)};
            H`centralizer:=&meet(GenCentralizers);
        end try;
    end if;
    //return Sprintf("Basic attributes assigned to %o", H);
end intrinsic;
