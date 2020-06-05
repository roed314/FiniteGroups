intrinsic central_product(G::LMFDBGrp) -> BoolElt
    {Checks if the group G is a central product.}
    GG := G`MagmaGrp;
    if IsAbelian(GG) then
        /* G abelian will not be a central product <=> it is cyclic of prime power order (including trivial group). */
        if not (IsCyclic(GG) and #FactoredOrder(GG) in {0,1}) then
            return true;
        end if;
    else
        /* G is not abelian. We run through the proper nontrivial normal subgroups N and consider whether or not
the centralizer C = C_G(H) together with N form a central product decomposition for G. We skip over N which are
central (C = G) since if a complement C' properly contained in C = G exists, then it cannot also be central if G
is not abelian. Since C' must itself be normal (NC' = G), we will encounter C' (with centralizer smaller than G)
somewhere else in the loop. */

        normal_list := NormalSubgroups(GG);
        for ent in normal_list do
            N := ent`subgroup;
            if (#N gt 1) and (#N lt #GG) then
                C := Centralizer(GG,N);
		if (#C lt #GG) then  /* C is a proper subgroup of G. */
		    C_meet_N := C meet N;
                    // |CN| = |C||N|/|C_meet_N|. We check if |CN| = |G| and return true if so.
                    if #C*#N eq #C_meet_N*#GG then
                        return true;
                    end if;
		end if;
            end if;
        end for;
    end if;
    return false;
end intrinsic;


/* Modified version of Sam's function in sam.m that will handle most (small) finite groups.*/
intrinsic schur_multiplier(G::LMFDBGrp) -> Any
  {}
  invs := [];
  ps := factors_of_order(G);
  GG := Get(G, "MagmaGrp"))); 
  if Type(GG) ne GrpPerm then
       // This conversion should make the pMultiplicator function calls further below work for all (small) finite groups.
       GG := PermutationGroup(FPGroup(GG));
  end if;
  for p in ps do 
    for el in pMultiplicator(GG,p) do 
      if el gt 1 then
        Append(~invs, el);
      end if;
    end for;
  end for;
  return AbelianInvariants(AbelianGroup(invs));
end intrinsic;


/* New version to replace version in sam.m */
intrinsic wreath_product(G::LMFDBGrp) -> Any
  {Returns true if G is a wreath product; otherwise returns false.}
  GG := Get(G, "MagmaGrp");
  return IsWreathProduct(PermutationGroup(FPGroup(GG)));
end intrinsic;


