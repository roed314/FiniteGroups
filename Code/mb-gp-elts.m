intrinsic IsValidWord(w::SeqEnum, gen_seq::SeqEnum, ord_seq::SeqEnum) -> BoolElt
  { Returns true if the number of consecutive occurrences in w of any element from gen_seq is always strictly smaller than the corresponding order specified in ord_seq.}
  if #w eq 0 then
    return true; // empty sequence represents the identity and is valid.
  elif 1 in ord_seq then
    return false; // words containing identity element (order 1) can be shortened.
  else //#w >= 1 and all generator orders > 1.
    ct := 1;
    current_ord := ord_seq[Position(gen_seq,w[1])];

    for i in [1..(#w-1)] do
      if w[i] eq w[i+1] then
        ct +:= 1;
      else // reset ct and current_ord
        ct := 1;
        current_ord := ord_seq[Position(gen_seq,w[i+1])];
      end if;

      if ct ge current_ord then  // w can be shortened using an order relation.
        return false; //w is not valid;
      end if;
    end for;
  end if;
  return true; //w is valid.
end intrinsic;


intrinsic NextWord(w::SeqEnum, gen_seq::SeqEnum, ord_seq::SeqEnum) -> SeqEnum
  {Returns the next valid word after w using lexicographic ordering induced by ordering in gen_seq. A word is valid if the number of consecutive occurrences of any element from gen_seq is always strictly smaller than the corresponding order specified in ord_seq.}
 // Infinite loop with the return inside to avoid recursion
 first_gen := gen_seq[1];
 last_gen := gen_seq[#gen_seq];
 while true do

  // We find the rightmost position i in w not containing last_gen. 
  // If last_gen does not appear, then i = 0.
  i := #w;
  while (i ge 1) do
      if w[i] ne last_gen then
        break;
      end if;
      i -:= 1;
  end while;

  // We create the next string lexicographically. This may or may not be valid.
  if i eq 0 then
    w_next := [first_gen : _ in [1..(#w + 1)]]; 
  else     
    w_next := w;
    next_gen := gen_seq[Position(gen_seq,w[i])+1];
    w_next[i] := next_gen;
    for j in [i+1..#w_next] do
      w_next[j] := first_gen;
    end for;
  end if;
  
  if IsValidWord(w_next,gen_seq,ord_seq) then 
    return w_next;
  else
    w:=w_next;
  end if;
 end while;
end intrinsic;

/* SAMPLE INPUT/OUTPUT
> gen_seq := ["a","b","c"];
> ord_seq := [2,3,3];
> 

Let's generate the first 50 valid words starting from the empty word. 
The given order information means that we skip words containing 2 consecutive "a"s or 3 consecutive "b"s or "c"s.

> w := [];
> for i in [1..50] do print w; w := NextWord(w,gen_seq,ord_seq);end for;

[]
[ a ]
[ b ]
[ c ]
[ a, b ]
[ a, c ]
[ b, a ]
[ b, b ]
[ b, c ]
[ c, a ]
[ c, b ]
[ c, c ]
[ a, b, a ]
[ a, b, b ]
[ a, b, c ]
[ a, c, a ]
[ a, c, b ]
[ a, c, c ]
[ b, a, b ]
[ b, a, c ]
[ b, b, a ]
[ b, b, c ]
[ b, c, a ]
[ b, c, b ]
[ b, c, c ]
[ c, a, b ]
[ c, a, c ]
[ c, b, a ]
[ c, b, b ]
[ c, b, c ]
[ c, c, a ]
[ c, c, b ]
[ a, b, a, b ]
[ a, b, a, c ]
[ a, b, b, a ]
[ a, b, b, c ]
[ a, b, c, a ]
[ a, b, c, b ]
[ a, b, c, c ]
[ a, c, a, b ]
[ a, c, a, c ]
[ a, c, b, a ]
[ a, c, b, b ]
[ a, c, b, c ]
[ a, c, c, a ]
[ a, c, c, b ]
[ b, a, b, a ]
[ b, a, b, b ]
[ b, a, b, c ]
[ b, a, c, a ]

*/


