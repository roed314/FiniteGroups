/*
G := New(LMFDBGrp);
G`MagmaGrp := SmallGroup(24,3);
G`label := "24.3";
*/
G := NewLMFDBGrp(SmallGroup(24,3), "24.3");
AssignBasicAttributes(G);
// NOTE: DefaultAttributes does not currently include all attributes: there is a blacklist
// see IO.m to modify blacklist
test_attrs := DefaultAttributes(LMFDBGrp);
errs := [];
for attr in test_attrs do
  print attr;
  try
    Get(G, attr);
  catch e
    printf "%o causes error\n", attr;
    Append(~errs, attr);
  end try;
end for;
//SaveLMFDBObject(G : attrs:=test_attrs, sep:="|");
errs;
