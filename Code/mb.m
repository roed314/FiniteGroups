/* Added to GrpAttributes.m */

intrinsic pgroup(G::LMFDBGrp) -> RngInt
    {1 if trivial group, p if order a power of p, otherwise 0}
    if G`Order eq 1 then
        return 1;
    else
        fac := Factorization(G`Order);
        if #fac gt 1 then
           /* #G has more than one prime divisor. */ 
           return 0;
        else
            /* First component in fac[1] is unique prime divisor. */
            return fac[1][1]; 
        end if;
    end if;
end intrinsic;

intrinsic IsCentralProduct(G::LMFDBGrp) -> BoolElt
    {Checks if the group G is a central product.}
    GG := G`MagmaGrp;
    is_central_product := false; 
    if IsAbelian(GG) then
        /* G abelian will not be a central product <=> it is cyclic of prime power order (including trivial group). */
        if not (IsCyclic(GG) and #FactoredOrder(GG) in {0,1}) then
            is_central_product := true;
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
                    /* |CN| = |C||N|/|C_meet_N|. We check if |CN| = |G| and set
		      the boolean is_central_product to true if this is the case and break out of the loop. */
                    if #C*#N eq #C_meet_N*#GG then
                        is_central_product := true;
                        break ent;
                    end if;
		end if;
            end if;
        end for;
    end if;
    return is_central_product;
end intrinsic;


