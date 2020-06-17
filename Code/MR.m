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