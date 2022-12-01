/* our random number generator
   Call ResetRandomSeed(), and then make a sequence of calls to ourrand(n).

   It is just a linear multiplier modulo a big prime (just under 2^128).
   The values were taken from a paper purporting that these are good
   values.

   We can run RNGs with different states by attaching them to groups.
*/

AddAttribute(FldRat, "randval");
AddAttribute(Grp, "randval");

intrinsic ResetRandomSeed()
  {Reset the random number generator}
  q:=Rationals();
  q`randval := 123;
end intrinsic;

intrinsic ourrand(n::RngIntElt) -> Any
  {Give a random number between 0 and n-1}
  m:=340282366920938463463374607431768211297;
  q:=Rationals();
  v:=(q`randval *25096281518912105342191851917838718629) mod m;
  q`randval := v;
  return v mod n;
end intrinsic;

intrinsic ResetRandomSeed(~H::Grp)
{Reset the random number generator associated to H}
    H`randval := 123;
end intrinsic;

intrinsic ourrand(n::RngIntElt, H::Grp) -> RngIntElt, RngIntElt
{Give a pseudorandom number between 1 and n}
    m:=340282366920938463463374607431768211297;
    v:=(H`randval *25096281518912105342191851917838718629) mod m;
    return (v mod n) + 1, v;
end intrinsic;
