

intrinsic pc_code(G::LMFDBGrp) -> RngInt
    {This should be updated to give a better presentation}
    pccode := SmallGroupEncoding(G`MagmaGrp);
    return pccode;
end intrinsic;
