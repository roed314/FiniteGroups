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

