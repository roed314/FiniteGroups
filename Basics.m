intrinsic GetBasicAttributes() -> Any
  {Outputs SeqEnum of basic attributes}

end intrinsic;

intrinsic AssignBasicAttributes(G::LMFDBGrp) -> Any
  {Assign basic attributes}
  attrs := GetBasicAttributes();  
  GG := G`MagmaGrp
  for attr in attrs do
    eval_str := Sprintf("return %o(GG);", attr);
G
  end for;
  G`IsSuperSolvable := IsSupersoluble(GG) // thanks a lot Australia! :D
  return Sprintf("Basic attributes assigned to %o", G);
end intrinsic;
