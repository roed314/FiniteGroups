intrinsic IsSemidirectProduct(G::LMFDBGrp : direct := false) -> Any
  {Returns true if G is a semidirect product; otherwise returns false.}
  dirbool := false;
  GG := Get(G, "MagmaGrp");
  Ns := NormalSubgroups(GG); // TODO: this should be changed to call on subgroup database when it exists
  if direct then
    Ks := Ns;
  else
    Ks := Subgroups(GG); // this should be changed to call on subgroup database when it exists
  end if;
  for r in Ns do
    N := r`subgroup;
    comps := [el : el in Ks | el`order eq (ordG div Order(N))];
    for K in comps do
      if #(N meet K) eq 1 then
        dirbool := true;
      end if;
    end for;
  end for;
  return dirbool;
end intrinsic;

intrinsic IsDirectProduct(G::LMFDBGrp) -> Any
  {Returns true if G is a direct product; otherwise returns false.}
  return IsSemidirectProduct(G : direct := true);
end intrinsic;
