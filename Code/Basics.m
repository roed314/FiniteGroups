intrinsic NewLMFDBGrp(GG::Grp, lab::MonStgElt) -> LMFDBGrp
{Create a new LMFDBGrp object G with G`MagmaGrp := magma_gp and G`label := lab}
    G := New(LMFDBGrp);
    // PC groups don't have an Order attribute
    if Type(G) eq GrpMat or Type(G) eq GrpPerm then
        N := StringToInteger(Split(lab, ".")[1]);
        GG`Order := N;
    end if;
    G`MagmaGrp := GG;
    G`label := lab;
    return G;
end intrinsic;

intrinsic order(G::LMFDBGrp) -> RngIntElt
{Order of the group}
    return #(G`MagmaGrp);
end intrinsic;

intrinsic exponent(G::LMFDBGrp) -> RngIntElt
{Exponent of the group}
    return Exponent(G`MagmaGrp);
end intrinsic;

intrinsic abelian(G::LMFDBGrp) -> BoolElt
{Whether the group is abelian}
    return IsAbelian(G`MagmaGrp);
end intrinsic;

intrinsic cyclic(G::LMFDBGrp) -> BoolElt
{Whether the group is cyclic}
    return IsCyclic(G`MagmaGrp);
end intrinsic;

intrinsic solvable(G::LMFDBGrp) -> BoolElt
{Whether the group is solvable}
    return IsSolvable(G`MagmaGrp);
end intrinsic;

intrinsic nilpotent(G::LMFDBGrp) -> BoolElt
{Whether the group is nilpotent}
    return IsNilpotent(G`MagmaGrp);
end intrinsic;

intrinsic simple(G::LMFDBGrp) -> BoolElt
{Whether the group is simple}
    return IsSimple(G`MagmaGrp);
end intrinsic;

intrinsic perfect(G::LMFDBGrp) -> BoolElt
{Whether the group is perfect}
    return IsPerfect(G`MagmaGrp);
end intrinsic;

intrinsic nilpotency_class(G::LMFDBGrp) -> RngIntElt
{Nilpotency class of the group}
    return NilpotencyClass(G`MagmaGrp);
end intrinsic;

intrinsic ngens(G::LMFDBGrp) -> RngIntElt
{Number of generators of the group in this presentation}
    return Ngens(G`MagmaGrp);
end intrinsic;

intrinsic derived_length(G::LMFDBGrp) -> RngIntElt
{Derived length of the group: length of the derived series}
    return DerivedLength(G`MagmaGrp);
end intrinsic;

intrinsic subgroup_order(H::LMFDBSubGrp) -> RngIntElt
{Order of the subgroup}
    return #(H`MagmaSubGrp);
end intrinsic;

intrinsic abelian(H::LMFDBSubGrp) -> BoolElt
{Whether the subgroup is abelian}
    return IsAbelian(H`MagmaSubGrp);
end intrinsic;

intrinsic cyclic(H::LMFDBSubGrp) -> BoolElt
{Whether the subgroup is cyclic}
    return IsCyclic(H`MagmaSubGrp);
end intrinsic;

intrinsic solvable(H::LMFDBSubGrp) -> BoolElt
{Whether the subgroup is solvable}
    return IsSolvable(H`MagmaSubGrp);
end intrinsic;

intrinsic nilpotent(H::LMFDBSubGrp) -> BoolElt
{Whether the subgroup is nilpotent}
    return IsNilpotent(H`MagmaSubGrp);
end intrinsic;

intrinsic perfect(H::LMFDBSubGrp) -> BoolElt
{Whether the subgroup is perfect}
    return IsPerfect(H`MagmaSubGrp);
end intrinsic;

intrinsic normal(H::LMFDBSubGrp) -> BoolElt
{Whether the subgroup is normal}
    return IsNormal(H`MagmaAmbient, H`MagmaSubGrp);
end intrinsic;

intrinsic central(H::LMFDBSubGrp) -> BoolElt
{Whether the subgroup is central}
    return IsCentral(H`MagmaAmbient, H`MagmaSubGrp);
end intrinsic;

intrinsic core(H::LMFDBSubGrp) -> Grp
{Core of this subgroup}
    return Core(H`MagmaAmbient, H`MagmaSubGrp);
end intrinsic;

intrinsic normalizer(H::LMFDBSubGrp) -> Grp
{Normalizer of this subgroup}
    return Normalizer(H`MagmaAmbient, H`MagmaSubGrp);
end intrinsic;

intrinsic centralizer(H::LMFDBSubGrp) -> Grp
{Centralizer of this subgroup}
    GG := H`MagmaAmbient;
    HH := H`MagmaSubGrp;
    try
        return Centralizer(GG,HH);
    catch e     //dealing with a strange Magma bug in 120.5
        GenCentralizers:={Centralizer(GG,h) : h in Generators(HH)};
        return &meet(GenCentralizers);
    end try;
end intrinsic;

intrinsic normal_closure(H::LMFDBSubGrp) -> Grp
{Normal closure of this subgroup}
    return NormalClosure(H`MagmaAmbient, H`MagmaSubGrp);
end intrinsic;
