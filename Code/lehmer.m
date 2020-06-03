intrinsic EncodePerm(x::GrpPermElt) -> RngIntElt
    {return rank of permutation x}
    return LehmerCodeToRank(LehmerCode(x));
end intrinsic;

intrinsic DecodePerm(x::RngIntElt, n::RngIntElt) -> GrpPermElt
    {Given rank x, return corresponding permutation in Sym(n)}
    return LehmerCodeToPermutation(RankToLehmerCode(x,n));
end intrinsic;

intrinsic LehmerCodeToRank(lehmer::SeqEnum) -> RngIntElt
  {Convert Lehmer code to integer}
  rank := 0;
  n := #lehmer;
  for i := n-1 to 0 by -1 do
    rank +:= lehmer[n-i]*Factorial(i);
  end for;
  return rank;
end intrinsic;

intrinsic RankToLehmerCode(x::RngIntElt, n::RngIntElt) -> SeqEnum
  {Returns the Lehmer code for rank x}
  lehmer := [];
  for j in [1..n] do
    Append(~lehmer, x mod j);
    x := x div j;
  end for;
  Reverse(~lehmer);
  return lehmer;
end intrinsic;

intrinsic LehmerCodeToPermutation(lehmer::SeqEnum) -> GrpPermElt
  {Returns permutation corresponding to Lehmer code.}
  n := #lehmer;
  lehmer := [el + 1 : el in lehmer];
  p_seq := [];
  open_spots := [1..n];
  for j in lehmer do
    Append(~p_seq, open_spots[j]);
    Remove(~open_spots,j);
  end for;
  return Sym(n)!p_seq;
end intrinsic;
