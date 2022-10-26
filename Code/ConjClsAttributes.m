intrinsic label(C::LMFDBGrpConjCls) -> MonStgElt
  {}
  gp_label := Get(C, "group");
  o := Get(C, "MagmaConjCls")[1];
  // J := capital_letter_code(C) ? TODO
  //return Sprintf("%o.%o%o", gp_label, o, J);
  return Sprintf("%o.%o", gp_label, o);
end intrinsic;

intrinsic aut_label(C::LMFDBGrpConjCls) -> MonStgElt
{}
    col := Get(C`Grp, "number_autjugacy_classes"); // sets aut_label
    return C`aut_label;
end intrinsic;

intrinsic group(C::LMFDBGrpConjCls) -> MonStgElt
    {return label of ambient group of C}
    return (C`Grp)`label;
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

intrinsic degree(C::LMFDBGrpPermConjCls) -> Any
    {the degree of the group, n in Sn}
    CC := Get(C, "MagmaConjCls"); 
    P:=Parent(CC[3]); // For a magma class CC, CC[3] gives a representative.
    return Degree(P);
end intrinsic;

intrinsic centralizer(C::LMFDBGrpPermConjCls) -> Any
  {Label for the isomorphism class of the centralizer of an element in this conjugacy class}
  CC := Get(C, "MagmaConjCls");
  C1:=Centralizer(Parent(CC[3]), CC[3]); //For a magma class CC, CC[3] gives a representative.
  return label(C1);
end intrinsic;

intrinsic size(C::LMFDBGrpPermConjCls) -> RingIntElt
  {Number of elements in this conjugacy class}
  CC := Get(C, "MagmaConjCls");
  return CC[2]; // For a magma class CC, CC[2] gives its size
end intrinsic;

intrinsic order(C::LMFDBGrpPermConjCls) -> RingIntElt
  {Number of elements in this conjugacy class}
  CC := Get(C, "MagmaConjCls");
  return CC[1];// For a magma class CC, CC[1] gives the order of an element
end intrinsic;

intrinsic Representative(C::LMFDBGrpPermConjCls) -> Any
  {}
  CC := Get(C, "MagmaConjCls");
  return CC[3];
end intrinsic; 

intrinsic rep(C::LMFDBGrpPermConjCls) -> Any
  {a representative element, as the index in the lexicographic ordering of S_n}
  g := Get(C, "representative");
  return EncodePerm(g); 
end intrinsic;


intrinsic cycle_type(C::LMFDBGrpPermConjCls) -> Any
  {A list of sizes of the cycles in a permutation in this class, in descending order and omitting 1s}
  CC := Get(C, "MagmaConjCls");
  s:=CycleStructure(CC[3]);
  L:=[];
  for i in [1..#s] do
    for j in [1..s[i][2]] do
      if s[i][1] ne 1 then
        Append(~L, s[i][1]);
      end if;
    end for;
  end for;
  return L;      
end intrinsic;

