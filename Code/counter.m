/* Implement a counter function.
   Give it an associative array
   */

intrinsic inc_counter(A::Assoc, a::Any)->Assoc
  {Given an associative array A whose values count things specified by keys, increment the counter for a.}
  bool, val:=IsDefined(A,a);
  if bool then
    A[a] +:= 1;
  else
    A[a] := 1;
  end if;
  return A;
end intrinsic;
