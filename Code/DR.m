

intrinsic PCCode(G::LMFDBGrp) -> RngInt
    {}
    pccode := SmallGroupEncoding(G`MagmaGrp);
    return pccode;
end intrinsic;

//intrinsic Subgroups(G::LMFDBGrp) -> SeqEnum
//{}
    //
