/*
MagmaOuterGroup, MagmaOuterProjection, MagmaClassAction, MagmaInnerGroup, MagmaAutcent, MagmaAutcentquo, OutLabelIso, AutLabelIso, OuterGenerators, InnerGenerators, OutPermGenerators, AutPermGenerators, InnPermGenerators, SkipAutMinDegRep, SkipAutFewGenerators, SkipAutLabel, SkipOutLabel, SkipAutcentLabel, SkipAutcentquoLabel, SkipInnSplit, SkipAutcentSplit
inner_order, autcent_order, autcentquo_order // numeric
autcent_group, autcentquo_group // text
inner_split, autcent_split // bool
aut_phi_ratio
inner_gens, outer_gens // numeric[]
inner_used // smallint[]
aut_gen_orders, inner_gen_orders, outer_gen_orders, outer_gen_pows // numeric[]
aut_permdeg, outer_permdeg // integer
aut_perms, outer_perms // numeric[]
// bool, bool, bool, bool, bool, numeric, bigint, text, (smallint, smallint)
aut_cyclic, aut_abelian, aut_nilpotent, aut_supersolvable, aut_solvable, aut_exponent, aut_hash, aut_tex, aut_nilpotency_class, aut_derived_length
inner_cyclic, inner_abelian, inner_nilpotent, inner_supersolvable, inner_solvable, inner_exponent, inner_hash, inner_tex
outer_cyclic, outer_abelian, outer_nilpotent, outer_supersolvable, outer_solvable, outer_exponent, outer_hash, outer_tex
autcent_cyclic, autcent_abelian, autcent_nilpotent, autcent_supersolvable, autcent_solvable, autcent_exponent, autcent_hash, autcent_tex
autcentquo_cyclic, autcentquo_abelian, autcentquo_nilpotent, autcentquo_supersolvable, autcentquo_solvable, autcentquo_exponent, autcentquo_hash, autcentquo_tex
center_order
*/

//TODO: Add mechanism for reconstructing MagmaOuterGroup, MagmaAutGroupPerm from aut_perms, outer_perms (probably in MagmaAutGroup)
//-> inner_order, center_order
//MagmaAutGroup -> aut_phi_ratio, inner_gens, inner_gen_orders
//MagmaClassAction (ClassAction, MinimalDegreePermutationRepresentation) -> aut_cyclic, aut_abelian, aut_nilpotent, aut_supersolvable, aut_solvable, aut_exponent, aut_hash, aut_tex, aut_nilpotency_class, aut_derived_length, autcent_order, autcentquo_order, inner_used, aut_permdeg, inner_cyclic, inner_abelian, inner_nilpotent, inner_supersolvable, inner_solvable, inner_exponent, inner_hash, inner_tex, autcent_cyclic, autcent_abelian, autcent_nilpotent, autcent_supersolvable, autcent_solvable, autcent_exponent, autcent_hash, autcent_tex
//LabelAutGroup -> aut_group
//AutGenerators (MagmaClassAction, FewGenerators, LabelAutGroup w/o Skip) -> aut_gens, aut_perms, aut_gen_orders
//MagmaOuterGroup (BestQuotient, MinimalDegreePermutationRepresentation w/o Skip), HasComplement -> outer_cyclic, outer_abelian, outer_nilpotent, outer_supersolvable, outer_solvable, outer_exponent, outer_hash, outer_tex, inner_split
//OuterGenerators (MagmaOuterGroup, MinimalDegreePermutationRepresentation, LabelOutGroup w/o Skip) -> outer_gens, outer_gen_orders, outer_gen_pows, outer_permdeg, outer_perms
//LabelAutcentGroup, LabelAutcentquoGroup -> autcent_group, autcentquo_group, autcent_split
//MagmaAutcentquo -> autcentquo_cyclic, autcentquo_abelian, autcentquo_nilpotent, autcentquo_supersolvable, autcentquo_solvable, autcentquo_exponent, autcentquo_hash, autcentquo_tex


//aut_gens: should match generators for aut_group when possible; if not match aut_perms
//inner_gens: always match generators for G.  Indicate somewhere which are actually needed (greedy for when each generator enlarges image in G/Z)
//outer_gens: should match generators for outer_group when possible: the map Aut(G) -> Out(G) induced by sending these generators to the chosen generators of Out(G) is a homomorphism with kernel Inn(G).  If not, match outer_perms.
// autcent is centralizer of Inn(G) in Aut(G), equal to the automorphisms that induce the identity on G/Z

function CheckValidAutGroup(A, GG)
    // Simple check that A is invalid
    // This won't always detect problems, but it has found issues in some pc-group examples
    repeat
        a := Random(GG);
        b := Random(GG);
    until Order(a) ne 1 and Order(b) ne 1;
    for f in Generators(A) do
        if f(a*b) ne f(a) * f(b) then
            return false;
        end if;
    end for;
    return true;
end function;

intrinsic MagmaAutGroup(G::LMFDBGrp) -> Grp
{Returns the automorphism group}
    // Unfortunately, both AutomorphismGroup and AutomorphismGroupSolubleGroup
    // can hang, AutomorphismGroupSolubleGroup also has the potential to raise an error,
    // and AutomorphismGroup can produce invalid results.
    // Our strategy for now is to start with AutomorphismGroup, and run some tests on the results, using AutomorphismGroupSolubleGroup if the tests fail.
    // The best we can do for now is to hard code cases where AutomorphismGroupSolubleGroup seems to be hanging.
    // Note that this often happens after calling RePresent
    /*if Get(G, "solvable") and not G`label in bad_cases then
        try
            return AutomorphismGroupSolubleGroup(G`MagmaGrp);
        catch e;
        end try;
    end if;*/
    if assigned G`aut_gens then
        ag := G`aut_gens;
        GG := G`MagmaGrp;
        gens := [LoadElt(Sprint(c), G) : c in ag[1]];
        auts := [[LoadElt(Sprint(c), G) : c in f] : f in ag[2..#ag]];
        A := AutomorphismGroup(GG, gens, auts);
    else
        t0 := ReportStart(G, "MagmaAutGroup");
        if assigned G`UseSolvAut and G`UseSolvAut and Type(G`MagmaGrp) eq GrpPC then
            A := AutomorphismGroupSolubleGroup(G`MagmaGrp);
        else
            A := AutomorphismGroup(G`MagmaGrp);
        end if;
        ReportEnd(G, "MagmaAutGroup", t0);
        if G`order ne 1 and not CheckValidAutGroup(A, G`MagmaGrp) then
            if Type(G`MagmaGrp) eq GrpPC then
                t0 := ReportStart(G, "MagmaAutGroupRedo");
                A := AutomorphismGroupSolubleGroup(G`MagmaGrp);
                ReportEnd(G, "MagmaAutGroupRedo", t0);
                if CheckValidAutGroup(A, G`MagmaGrp) then
                    return A;
                end if;
            end if;
            error "Invalid automorphism group";
        end if;
    end if;
    return A;
end intrinsic;

// We have escalating versions of some intrinsics since some desired parts of the computation may time out

intrinsic AutGenerators0(G::LMFDBGrp) -> SeqEnum
{Version 0: just take the generators of MagmaAutGroup}
    A := Get(G, "MagmaAutGroup");
    return [A.i : i in [1..Ngens(A)]];
end intrinsic;

intrinsic aut_gens0(G::LMFDBGrp) -> SeqEnum
{Version 0: just take the generators of MagmaAutGroup}
    gens := Get(G, "Generators");
    return [[SaveElt(g, G) : g in gens]] cat [[SaveElt(phi(g), G) : g in gens] : phi in Get(G, "AutGenerators0")];
end intrinsic;

intrinsic AutGenerators1(G::LMFDBGrp) -> SeqEnum
{Version 1: Compute ClassAction to get an isomorphism with a permutation group}
    m, P := Explode(Get(G, "MagmaClassAction"));
    G`AutPermGenerators1 := GeneratorsSequence(P);
    return [g @@ m : g in G`AutPermGenerators1];
end intrinsic;

intrinsic aut_gens1(G::LMFDBGrp) -> SeqEnum
{Version 1: Compute ClassAction to get an isomorphism with a permutation group}
    gens := Get(G, "Generators");
    return [[SaveElt(g, G) : g in gens]] cat [[SaveElt(phi(g), G) : g in gens] : phi in Get(G, "AutGenerators1")];
end intrinsic;

intrinsic AutGenerators2(G::LMFDBGrp) -> SeqEnum
{Version 2: Optimize permutation group with FewGenerators}
    m, P := Explode(Get(G, "MagmaClassAction"));
    t0 := ReportStart(G, "AutFewGenerators");
    G`AutPermGenerators2 := FewGenerators(P);
    ReportEnd(G, "AutFewGenerators", t0);
    return [g @@ m : g in G`AutPermGenerators2];
end intrinsic;

intrinsic aut_gens2(G::LMFDBGrp) -> SeqEnum
{Version 2: Optimize permutation group with FewGenerators}
    gens := Get(G, "Generators");
    return [[SaveElt(g, G) : g in gens]] cat [[SaveElt(phi(g), G) : g in gens] : phi in Get(G, "AutGenerators2")];
end intrinsic;

intrinsic AutGenerators3(G::LMFDBGrp) -> SeqEnum
{The chosen generators for the automorphism group.
 This can be reset to match an isomorphism with the labeled automorphism group.}
    m, P := Explode(Get(G, "MagmaClassAction"));
    autiso := Get(G, "AutLabelIso");
    if Type(autiso) eq NoneType then
        return None();
    else
        G`AutPermGenerators3 := [g @ autiso : g in GeneratorsSequence(Domain(autiso))];
    end if;
    return [g @@ m : g in G`AutPermGenerators3];
end intrinsic;

intrinsic aut_gens3(G::LMFDBGrp) -> Any
{Returns a list of lists of integers encoding elements of the group.
 The first list gives a set of generators of G, while later lists give the images of these generators under generators of the automorphism group of G}
    gens := Get(G, "Generators");
    agens := Get(G, "AutGenerators3");
    if Type(agens) eq NoneType then
        return None();
    end if;
    return [[SaveElt(g, G) : g in gens]] cat [[SaveElt(phi(g), G) : g in gens] : phi in agens];
end intrinsic;

intrinsic aut_permdeg(G::LMFDBGrp) -> RngIntElt
{}
    return Degree(MagmaAutGroupPerm(G));
end intrinsic;

intrinsic aut_perms1(G::LMFDBGrp) -> SeqEnum
{}
    dummy := Get(G, "AutGenerators1"); // sets AutPermGenerators1
    return [EncodePerm(g) : g in G`AutPermGenerators1];
end intrinsic;

intrinsic aut_perms2(G::LMFDBGrp) -> SeqEnum
{}
    dummy := Get(G, "AutGenerators2"); // sets AutPermGenerators2
    return [EncodePerm(g) : g in G`AutPermGenerators2];
end intrinsic;

intrinsic aut_perms3(G::LMFDBGrp) -> SeqEnum
{}
    dummy := Get(G, "AutGenerators3"); // sets AutPermGenerators3
    if Type(dummy) eq NoneType then
        return None();
    end if;
    return [EncodePerm(g) : g in G`AutPermGenerators3];
end intrinsic;

intrinsic aut_gen_orders0(G::LMFDBGrp) -> SeqEnum
{}
    return [Order(phi) : phi in Get(G, "AutGenerators0")];
end intrinsic;

intrinsic aut_gen_orders1(G::LMFDBGrp) -> SeqEnum
{}
    return [Order(phi) : phi in Get(G, "AutGenerators1")];
end intrinsic;

intrinsic aut_gen_orders2(G::LMFDBGrp) -> SeqEnum
{}
    return [Order(phi) : phi in Get(G, "AutGenerators2")];
end intrinsic;

intrinsic aut_gen_orders3(G::LMFDBGrp) -> SeqEnum
{}
    agens := Get(G, "AutGenerators3");
    if Type(agens) eq NoneType then
        return None();
    end if;
    return [Order(phi) : phi in agens];
end intrinsic;

intrinsic InnerGenerators(G::LMFDBGrp) -> SeqEnum
{The conjugation maps corresponding to generators of G}
    A := Get(G, "MagmaAutGroup");
    GG := G`MagmaGrp;
    gens := Get(G, "Generators");
    return [A!hom<GG -> GG|[<g, g^h> : g in gens]> : h in gens];
end intrinsic;

intrinsic InnPermGenerators(G::LMFDBGrp) -> SeqEnum
{}
    m, P := Explode(Get(G, "MagmaClassAction"));
    return [phi @ m : phi in Get(G, "InnerGenerators")];
end intrinsic;

intrinsic inner_used(G::LMFDBGrp) -> SeqEnum
{Greedy-minimally chosen indexes for InnerGenerators that generate Inn(G)}
    m, P := Explode(Get(G, "MagmaClassAction"));
    I := sub<P|>;
    Iord := 1;
    used := [];
    gens := Get(G, "InnPermGenerators");
    for i in [1..#gens] do
        I := sub<P|I, gens[i]>;
        if #I gt Iord then
            Iord := #I;
            Append(~used, i);
        end if;
    end for;
    return used;
end intrinsic;

intrinsic inner_gens(G::LMFDBGrp) -> SeqEnum
{}
    gens := Get(G, "Generators");
    return [[SaveElt(phi(g), G) : g in gens] : phi in Get(G, "InnerGenerators")];
end intrinsic;

intrinsic inner_gen_orders(G::LMFDBGrp) -> SeqEnum
{}
    return [Order(phi) : phi in Get(G, "InnerGenerators")];
end intrinsic;

intrinsic OuterGenerators0(G::LMFDBGrp) -> SeqEnum
{}
    A := Get(G, "MagmaAutGroup");
    I := sub<A|Get(G, "InnerGenerators")>;
    ogens := [];
    for i in [1..Ngens(A)] do
        if not A.i in I then
            I := sub<A|I,A.i>;
            Append(~ogens, A.i);
        end if;
    end for;
    return ogens;
end intrinsic;

intrinsic outer_gens0(G::LMFDBGrp) -> SeqEnum
{}
    gens := Get(G, "Generators");
    return [[SaveElt(phi(g), G) : g in gens] : phi in Get(G, "OuterGenerators0")];
end intrinsic;

intrinsic OuterGenerators1(G::LMFDBGrp) -> SeqEnum
{}
    A := Get(G, "MagmaAutGroup");
    GG := G`MagmaGrp;
    m, P := Explode(Get(G, "MagmaClassAction"));
    O := Get(G, "MagmaOuterGroup"); // sets G`MagmaOuterProjection
    outproj := G`MagmaOuterProjection;
    G`OutPermGenerators1 := GeneratorsSequence(O);
    return [(g @@ outproj) @@ m : g in G`OutPermGenerators1];
end intrinsic;

intrinsic outer_gens1(G::LMFDBGrp) -> SeqEnum
{}
    gens := Get(G, "Generators");
    return [[SaveElt(phi(g), G) : g in gens] : phi in Get(G, "OuterGenerators1")];
end intrinsic;

intrinsic OuterGenerators2(G::LMFDBGrp) -> SeqEnum
{}
    A := Get(G, "MagmaAutGroup");
    GG := G`MagmaGrp;
    m, P := Explode(Get(G, "MagmaClassAction"));
    O := Get(G, "MagmaOuterGroup"); // sets G`MagmaOuterProjection
    outproj := G`MagmaOuterProjection;
    G`OutPermGenerators2 := FewGenerators(O);
    return [(g @@ outproj) @@ m : g in G`OutPermGenerators2];
end intrinsic;

intrinsic outer_gens2(G::LMFDBGrp) -> SeqEnum
{}
    gens := Get(G, "Generators");
    return [[SaveElt(phi(g), G) : g in gens] : phi in Get(G, "OuterGenerators2")];
end intrinsic;

intrinsic OuterGenerators3(G::LMFDBGrp) -> SeqEnum
{}
    A := Get(G, "MagmaAutGroup");
    GG := G`MagmaGrp;
    m, P := Explode(Get(G, "MagmaClassAction"));
    O := Get(G, "MagmaOuterGroup"); // sets G`MagmaOuterProjection
    outproj := G`MagmaOuterProjection;
    outiso := Get(G, "OutLabelIso");
    if Type(outiso) eq NoneType then
        return None();
    end if;
    G`OutPermGenerators3 := [g @ outiso : g in GeneratorsSequence(Domain(outiso))];
    return [(g @@ outproj) @@ m : g in G`OutPermGenerators3];
end intrinsic;

intrinsic outer_gens3(G::LMFDBGrp) -> SeqEnum
{}
    gens := Get(G, "Generators");
    ogens := Get(G, "OuterGenerators3");
    if Type(ogens) eq NoneType then
        return None();
    end if;
    return [[SaveElt(phi(g), G) : g in gens] : phi in ogens];
end intrinsic;

intrinsic OuterGenerators(G::LMFDBGrp) -> SeqEnum
{Various computations use generators of the outer automorphism group, with runtime proportional to the number of generators.  So we want to use smaller sets of generators of possible, but don't want to spend a lot of time computing}
    if assigned G`OuterGenerators2 then
        return G`OuterGenerators2;
    elif assigned G`OuterGenerators1 then
        return G`OuterGenerators1;
    else
        return Get(G, "OuterGenerators0");
    end if;
end intrinsic;

intrinsic outer_permdeg(G::LMFDBGrp) -> RngIntElt
{}
    return Degree(Get(G, "MagmaOuterGroup"));
end intrinsic;

intrinsic outer_perms1(G::LMFDBGrp) -> SeqEnum
{}
    dummy := Get(G, "OuterGenerators1"); // sets OutPermGenerators1
    return [EncodePerm(g) : g in G`OutPermGenerators1];
end intrinsic;

intrinsic outer_perms2(G::LMFDBGrp) -> SeqEnum
{}
    dummy := Get(G, "OuterGenerators2"); // sets OutPermGenerators2
    return [EncodePerm(g) : g in G`OutPermGenerators2];
end intrinsic;

intrinsic outer_perms3(G::LMFDBGrp) -> Any
{}
    dummy := Get(G, "OuterGenerators3"); // sets OutPermGenerators3
    if Type(dummy) eq NoneType then
        return None();
    end if;
    return [EncodePerm(g) : g in G`OutPermGenerators3];
end intrinsic;

intrinsic outer_gen_orders0(G::LMFDBGrp) -> SeqEnum
{ Note that these are orders in Out(G) rather than Aut(G)}
    gens := Get(G, "OuterGenerators0");
    ords := [];
    G`outer_gen_pows0 := [];
    for g in gens do
        m := Order(g);
        ps := PrimeDivisors(m);
        inn := Identity(G`MagmaGrp);
        while #ps gt 0 do
            new_ps := [];
            for p in ps do
                m_p := m div p;
                if m_p eq 1 then
                    // We know g is not inner, so we're done
                    break;
                end if;
                h := g^m_p;
                isinn, inn0 := IsInner(h);
                if isinn then
                    m := m_p;
                    inn := inn0;
                    if m mod p eq 0 then
                        Append(~new_ps, p);
                    end if;
                end if;
                // Otherwise the order is exactly divisible by the number of ps currently in m, so we can stop dividing by p
            end for;
            ps := new_ps;
        end while;
        Append(~ords, m);
        Append(~G`outer_gen_pows0, SaveElt(inn, G));
    end for;
    return ords;
end intrinsic;

intrinsic outer_gen_orders1(G::LMFDBGrp) -> SeqEnum
{ Note that these are orders in Out(G) rather than Aut(G)}
    dummy := Get(G, "OuterGenerators1"); // sets OutPermGenerators1
    return [Order(phi) : phi in G`OutPermGenerators1];
end intrinsic;

intrinsic outer_gen_orders2(G::LMFDBGrp) -> SeqEnum
{ Note that these are orders in Out(G) rather than Aut(G)}
    dummy := Get(G, "OuterGenerators1"); // sets OutPermGenerators2
    return [Order(phi) : phi in G`OutPermGenerators2];
end intrinsic;

intrinsic outer_gen_orders3(G::LMFDBGrp) -> SeqEnum
{ Note that these are orders in Out(G) rather than Aut(G)}
    dummy := Get(G, "OuterGenerators3"); // sets OutPermGenerators3
    if Type(dummy) eq NoneType then
        return None();
    end if;
    return [Order(phi) : phi in G`OutPermGenerators3];
end intrinsic;

intrinsic outer_gen_pows0(G::LMFDBGrp) -> SeqEnum
{Each generator in outer_gens0, when raised to the corresponding power in outer_gen_orders0, yields an inner automorphism.  Here we store elements of G that induce that automorphism under conjugation}
    dummy := Get(G, "outer_gen_orders0"); // sets outer_gen_pows0
    return G`outer_gen_pows0;
end intrinsic;

intrinsic outer_gen_pows1(G::LMFDBGrp) -> SeqEnum
{Each generator in outer_gens1, when raised to the corresponding power in outer_gen_orders1, yields an inner automorphism.  Here we store elements of G that induce that automorphism under conjugation}
    gens := Get(G, "OuterGenerators1");
    ords := Get(G, "outer_gen_orders1");
    ans := [];
    for i in [1..#gens] do
        ok, g := IsInner(gens[i]^ords[i]);
        assert ok;
        Append(~ans, SaveElt(g, G));
    end for;
    return ans;
end intrinsic;

intrinsic outer_gen_pows2(G::LMFDBGrp) -> SeqEnum
{Each generator in outer_gens2, when raised to the corresponding power in outer_gen_orders2, yields an inner automorphism.  Here we store elements of G that induce that automorphism under conjugation}
    gens := Get(G, "OuterGenerators2");
    ords := Get(G, "outer_gen_orders2");
    ans := [];
    for i in [1..#gens] do
        ok, g := IsInner(gens[i]^ords[i]);
        assert ok;
        Append(~ans, SaveElt(g, G));
    end for;
    return ans;
end intrinsic;

intrinsic outer_gen_pows3(G::LMFDBGrp) -> SeqEnum
{Each generator in outer_gens3, when raised to the corresponding power in outer_gen_orders3, yields an inner automorphism.  Here we store elements of G that induce that automorphism under conjugation}
    gens := Get(G, "OuterGenerators3");
    if Type(gens) eq NoneType then
        return None();
    end if;
    ords := Get(G, "outer_gen_orders3");
    ans := [];
    for i in [1..#gens] do
        ok, g := IsInner(gens[i]^ords[i]);
        assert ok;
        Append(~ans, SaveElt(g, G));
    end for;
    return ans;
end intrinsic;

intrinsic MagmaClassAction(G::LMFDBGrp) -> Tup
{}
    aut := Get(G, "MagmaAutGroup");
    t0 := ReportStart(G, "MagmaClassAction");
    m, P, Y := ClassAction(aut);
    ReportEnd(G, "MagmaClassAction", t0);
    // It would be nice to call MinimalDegreePermutationRepresentation on P
    // but it proved to be too slow for most examples
    //if not assigned G`SkipAutMinDegRep then
    //    t0 := ReportStart(G, "MinimizeClassAction");
    //    rho, P := MinimalDegreePermutationRepresentation(P);
    //    m *:= rho;
    //    ReportEnd(G, "MinimizeClassAction", t0);
    //end if;
    assert #P eq Get(G, "aut_order");
    return <m, P>;
end intrinsic;

intrinsic MagmaAutGroupPerm(G::LMFDBGrp) -> GrpPerm
{}
    return Get(G, "MagmaClassAction")[2];
end intrinsic;

intrinsic aut_group(G::LMFDBGrp) -> MonStgElt
{returns label of the automorphism group}
    if not PossiblyLabelable(Get(G, "aut_order")) then
        return None();
    end if;
    P := MagmaAutGroupPerm(G);
    if assigned G`SkipAutLabel then
        s := None();
    else
        t0 := ReportStart(G, "LabelAutGroup");
        s, phi := label(P : hsh:=Get(G, "aut_hash"), strict:=false, giveup:=false);
        ReportEnd(G, "LabelAutGroup", t0);
    end if;
    if assigned phi then
        G`AutLabelIso := phi;
    end if;
    return s;
end intrinsic;

intrinsic AutLabelIso(G::LMFDBGrp) -> Map
{}
    s := Get(G, "aut_group");
    if Type(s) eq NoneType then
        G`AutLabelIso := None();
    elif not assigned G`AutLabelIso then
        P := MagmaAutGroupPerm(G);
        H := GroupsWithLabels([s])[1][2];
        t0 := ReportStart(G, "LabelIsoAutGroup");
        _, G`AutLabelIso := IsIsomorphic(H, P);
        ReportEnd(G, "LabelIsoAutGroup", t0);
    end if;
    return G`AutLabelIso;
end intrinsic;

intrinsic aut_order(G::LMFDBGrp) -> RngIntElt
   {returns order of automorphism group}
   return #Get(G, "MagmaAutGroup");
end intrinsic;



intrinsic factors_of_aut_order(G::LMFDBGrp) -> SeqEnum
   {returns primes in factorization of automorphism group}
   return PrimeFactors(Get(G,"aut_order"));
end intrinsic;

intrinsic inner_order(G::LMFDBGrp) -> RngIntElt
{}
    return Get(G, "order") div Get(G, "center_order");
end intrinsic;

intrinsic outer_order(G::LMFDBGrp) -> RngIntElt
    {returns order of OuterAutomorphisms }
    aut := Get(G, "MagmaAutGroup");
    return OuterOrder(aut);
end intrinsic;

intrinsic autcent_order(G::LMFDBGrp) -> RngIntElt
{}
    return #Get(G, "MagmaAutcent");
end intrinsic;

intrinsic autcentquo_order(G::LMFDBGrp) -> RngIntElt
{}
    return Get(G, "aut_order") div Get(G, "autcent_order");
end intrinsic;

intrinsic aut_phi_ratio(G::LMFDBGrp) -> FldReElt
{}
    return RealField()!(Get(G, "aut_order") / EulerPhi(Get(G, "order")));
end intrinsic;

intrinsic MagmaInnerGroup(G::LMFDBGrp) -> Grp
{Inner automorphism group as a subgroup of MagmaAutGroupPerm(G)}
    //m, P, Y := Explode(Get(G, "MagmaClassAction"));
    //inners := [P![Position(Y, y^g) : y in Y] : g in Get(G, "Generators")];
    //return sub<P | inners>;
    m, P := Explode(Get(G, "MagmaClassAction"));
    return sub<P | Get(G, "InnPermGenerators")>;
end intrinsic;

intrinsic MagmaOuterGroup(G::LMFDBGrp) -> Grp
{A permutation group isomorphic to the outer automorphism group.  Sets MagmaOuterProjection.}
    P := MagmaAutGroupPerm(G);
    if Get(G, "abelian") then
        G`MagmaOuterProjection := IdentityHomomorphism(P);
        return P;
    end if;
    inners := Get(G, "MagmaInnerGroup");
    t0 := ReportStart(G, "MagmaOuterGroup");
    out, outproj := BestQuotient(P, inners);
    ReportEnd(G, "MagmaOuterGroup", t0);
    // It would be nice to call MinimalDegreePermutationRepresentation on P
    // but it proved to be too slow for most examples
    //if not assigned G`SkipAutMinDegRep then
    //    t0 := ReportStart(G, "MinimizeOuterGroup");
    //    rho, out := MinimalDegreePermutationRepresentation(out);
    //    outproj *:= rho;
    //    ReportEnd(G, "MinimizeOuterGroup", t0);
    //end if;
    G`MagmaOuterProjection := outproj;
    return out;
end intrinsic;

intrinsic MagmaAutcent(G::LMFDBGrp) -> Grp
{}
    P := MagmaAutGroupPerm(G);
    inners := Get(G, "MagmaInnerGroup");
    return Centralizer(P, inners);
end intrinsic;

intrinsic MagmaAutcentquo(G::LMFDBGrp) -> Grp
{}
    P := MagmaAutGroupPerm(G);
    autcent := Get(G, "MagmaAutcent");
    t0 := ReportStart(G, "MagmaAutcentquo");
    Q := BestQuotient(P, autcent);
    ReportEnd(G, "MagmaAutcentquo", t0);
    return Q;
end intrinsic;

intrinsic outer_group(G::LMFDBGrp) -> Any
{returns OuterAutomorphism Group}
    if Get(G, "abelian") then
        return Get(G, "aut_group");
    end if;
    if not PossiblyLabelable(Get(G, "outer_order")) then
        return None();
    end if;
    out := Get(G, "MagmaOuterGroup");
    if assigned G`SkipOutLabel then
        s := None();
    else
        t0 := ReportStart(G, "LabelOuterGroup");
        s, phi := label(out : hsh:=Get(G, "outer_hash"), strict:=false, giveup:=false);
        ReportEnd(G, "LabelOuterGroup", t0);
    end if;
    if assigned phi then
        G`OutLabelIso := phi;
    end if;
    return s;
end intrinsic;

intrinsic OutLabelIso(G::LMFDBGrp) -> Map
{}
    if Get(G, "abelian") then
        return Get(G, "AutLabelIso");
    end if;
    outer_label := Get(G, "outer_group");
    if Type(outer_label) eq NoneType then
        G`OutLabelIso := None();
    elif not assigned G`OutLabelIso then
        // It's possible that we've identified the group but it is not in the LMFDB
        desc_exists := OpenTest("DATA/descriptions/" * outer_label, "r");
        if desc_exists then
            out := Get(G, "MagmaOuterGroup");
            O := GroupsWithLabels([outer_label])[1][2];
            t0 := ReportStart(G, "LabelIsoOutGroup");
            _, G`OutLabelIso := IsIsomorphic(O, out);
            ReportEnd(G, "LabelIsoOutGroup", t0);
        else
            G`OutLabelIso := None();
        end if;
    end if;
    return G`OutLabelIso;
end intrinsic;

intrinsic autcent_group(G::LMFDBGrp) -> Any
{}
    if Get(G, "aut_abelian") then
        return Get(G, "aut_group");
    end if;
    autcent := Get(G, "MagmaAutcent");
    if assigned G`SkipAutcentLabel or not PossiblyLabelable(#autcent) then
        return None();
    end if;
    t0 := ReportStart(G, "LabelAutcent");
    s := label(autcent : hsh:=Get(G, "autcent_hash"), strict:=false, giveup:=false);
    ReportEnd(G, "LabelAutcent", t0);
    return s;
end intrinsic;

intrinsic autcentquo_group(G::LMFDBGrp) -> Any
{}
    autcentquo := Get(G, "MagmaAutcentquo");
    N := Get(G, "autcentquo_order");
    if N eq Get(G, "aut_order") then
        return Get(G, "aut_group");
    end if;
    if assigned G`SkipAutcentquoLabel or not PossiblyLabelable(N) then
        return None();
    end if;
    t0 := ReportStart(G, "LabelAutcentquo");
    s := label(autcentquo : hsh:=Get(G, "autcentquo_hash"), strict:=false, giveup:=false);
    ReportEnd(G, "LabelAutcentquo", t0);
    return s;
end intrinsic;

intrinsic inner_split(G::LMFDBGrp) -> Any
{}
    if Gcd(Get(G, "inner_order"), Get(G, "outer_order")) eq 1 then
        // Schur-Zassenhaus
        return true;
    end if;
    if assigned G`SkipInnSplit then
        return None();
    end if;
    P := MagmaAutGroupPerm(G);
    inners := Get(G, "MagmaInnerGroup");
    t0 := ReportStart(G, "inner_split");
    is_split := HasComplement(P, inners);
    ReportEnd(G, "inner_split", t0);
    return is_split;
end intrinsic;

intrinsic autcent_split(G::LMFDBGrp) -> Any
{}
    if Gcd(Get(G, "autcent_order"), Get(G, "autcentquo_order")) eq 1 then
        // Schur-Zassenhaus
        return true;
    end if;
    if assigned G`SkipAutcentSplit then
        return None();
    end if;
    P := MagmaAutGroupPerm(G);
    autcent := Get(G, "MagmaAutcent");
    t0 := ReportStart(G, "autcent_split");
    is_split := HasComplement(P, autcent);
    ReportEnd(G, "autcent_split", t0);
    return is_split;
end intrinsic;

intrinsic complete(G::LMFDBGrp) -> BoolElt
{}
    return (Get(G, "center_order") eq 1 and Get(G, "outer_order") eq 1);
end intrinsic;

intrinsic aut_cyclic(G::LMFDBGrp) -> BoolElt
{}
    // Could also hard code answer: G must be cyclic of order 4, p^k, or 2p^k for odd p
    return IsCyclic(MagmaAutGroupPerm(G));
end intrinsic;

intrinsic aut_abelian(G::LMFDBGrp) -> BoolElt
{}
    return IsAbelian(MagmaAutGroupPerm(G));
end intrinsic;

intrinsic aut_nilpotent(G::LMFDBGrp) -> BoolElt
{}
    return IsNilpotent(MagmaAutGroupPerm(G));
end intrinsic;

intrinsic aut_supersolvable(G::LMFDBGrp) -> BoolElt
{}
    return IsSupersolvable(MagmaAutGroupPerm(G));
end intrinsic;

intrinsic aut_solvable(G::LMFDBGrp) -> BoolElt
{}
    return IsSolvable(MagmaAutGroupPerm(G));
end intrinsic;

intrinsic aut_exponent(G::LMFDBGrp) -> RngIntElt
{}
    return Exponent(MagmaAutGroupPerm(G));
end intrinsic;

intrinsic aut_hash(G::LMFDBGrp) -> RngIntElt
{}
    return hash(MagmaAutGroupPerm(G));
end intrinsic;

intrinsic aut_tex(G::LMFDBGrp) -> MonStgElt
{}
    return GroupName(MagmaAutGroupPerm(G) : TeX:=true, prodeasylimit:=2, wreathlimit:=0);
end intrinsic;

intrinsic aut_nilpotency_class(G::LMFDBGrp) -> RngIntElt
{}
    return NilpotencyClass(MagmaAutGroupPerm(G));
end intrinsic;

intrinsic aut_derived_length(G::LMFDBGrp) -> RngIntElt
{}
    return DerivedLength(MagmaAutGroupPerm(G));
end intrinsic;


intrinsic inner_cyclic(G::LMFDBGrp) -> BoolElt
{}
    return IsCyclic(Get(G, "MagmaInnerGroup"));
end intrinsic;

intrinsic inner_abelian(G::LMFDBGrp) -> BoolElt
{}
    return IsAbelian(Get(G, "MagmaInnerGroup"));
end intrinsic;

intrinsic inner_nilpotent(G::LMFDBGrp) -> BoolElt
{}
    return IsNilpotent(Get(G, "MagmaInnerGroup"));
end intrinsic;

intrinsic inner_supersolvable(G::LMFDBGrp) -> BoolElt
{}
    return IsSupersolvable(Get(G, "MagmaInnerGroup"));
end intrinsic;

intrinsic inner_solvable(G::LMFDBGrp) -> BoolElt
{}
    return IsSolvable(Get(G, "MagmaInnerGroup"));
end intrinsic;

intrinsic inner_exponent(G::LMFDBGrp) -> RngIntElt
{}
    return Exponent(Get(G, "MagmaInnerGroup"));
end intrinsic;

intrinsic inner_hash(G::LMFDBGrp) -> RngIntElt
{}
    return hash(Get(G, "MagmaInnerGroup"));
end intrinsic;

intrinsic inner_tex(G::LMFDBGrp) -> MonStgElt
{}
    return GroupName(Get(G, "MagmaInnerGroup") : TeX:=true, prodeasylimit:=2, wreathlimit:=0);
end intrinsic;


intrinsic outer_cyclic(G::LMFDBGrp) -> BoolElt
{}
    return IsCyclic(Get(G, "MagmaOuterGroup"));
end intrinsic;

intrinsic outer_abelian(G::LMFDBGrp) -> BoolElt
{}
    return IsAbelian(Get(G, "MagmaOuterGroup"));
end intrinsic;

intrinsic outer_nilpotent(G::LMFDBGrp) -> BoolElt
{}
    return IsNilpotent(Get(G, "MagmaOuterGroup"));
end intrinsic;

intrinsic outer_supersolvable(G::LMFDBGrp) -> BoolElt
{}
    return IsSupersolvable(Get(G, "MagmaOuterGroup"));
end intrinsic;

intrinsic outer_solvable(G::LMFDBGrp) -> BoolElt
{}
    return IsSolvable(Get(G, "MagmaOuterGroup"));
end intrinsic;

intrinsic outer_exponent(G::LMFDBGrp) -> RngIntElt
{}
    return Exponent(Get(G, "MagmaOuterGroup"));
end intrinsic;

intrinsic outer_hash(G::LMFDBGrp) -> RngIntElt
{}
    return hash(Get(G, "MagmaOuterGroup"));
end intrinsic;

intrinsic outer_tex(G::LMFDBGrp) -> MonStgElt
{}
    return GroupName(Get(G, "MagmaOuterGroup") : TeX:=true, prodeasylimit:=2, wreathlimit:=0);
end intrinsic;


intrinsic autcent_cyclic(G::LMFDBGrp) -> BoolElt
{}
    return IsCyclic(Get(G, "MagmaAutcent"));
end intrinsic;

intrinsic autcent_abelian(G::LMFDBGrp) -> BoolElt
{}
    return IsAbelian(Get(G, "MagmaAutcent"));
end intrinsic;

intrinsic autcent_nilpotent(G::LMFDBGrp) -> BoolElt
{}
    return IsNilpotent(Get(G, "MagmaAutcent"));
end intrinsic;

intrinsic autcent_supersolvable(G::LMFDBGrp) -> BoolElt
{}
    return IsSupersolvable(Get(G, "MagmaAutcent"));
end intrinsic;

intrinsic autcent_solvable(G::LMFDBGrp) -> BoolElt
{}
    return IsSolvable(Get(G, "MagmaAutcent"));
end intrinsic;

intrinsic autcent_exponent(G::LMFDBGrp) -> RngIntElt
{}
    return Exponent(Get(G, "MagmaAutcent"));
end intrinsic;

intrinsic autcent_hash(G::LMFDBGrp) -> RngIntElt
{}
    return hash(Get(G, "MagmaAutcent"));
end intrinsic;

intrinsic autcent_tex(G::LMFDBGrp) -> MonStgElt
{}
    return GroupName(Get(G, "MagmaAutcent") : TeX:=true, prodeasylimit:=2, wreathlimit:=0);
end intrinsic;


intrinsic autcentquo_cyclic(G::LMFDBGrp) -> BoolElt
{}
    return IsCyclic(Get(G, "MagmaAutcentquo"));
end intrinsic;

intrinsic autcentquo_abelian(G::LMFDBGrp) -> BoolElt
{}
    return IsAbelian(Get(G, "MagmaAutcentquo"));
end intrinsic;

intrinsic autcentquo_nilpotent(G::LMFDBGrp) -> BoolElt
{}
    return IsNilpotent(Get(G, "MagmaAutcentquo"));
end intrinsic;

intrinsic autcentquo_supersolvable(G::LMFDBGrp) -> BoolElt
{}
    return IsSupersolvable(Get(G, "MagmaAutcentquo"));
end intrinsic;

intrinsic autcentquo_solvable(G::LMFDBGrp) -> BoolElt
{}
    return IsSolvable(Get(G, "MagmaAutcentquo"));
end intrinsic;

intrinsic autcentquo_exponent(G::LMFDBGrp) -> RngIntElt
{}
    return Exponent(Get(G, "MagmaAutcentquo"));
end intrinsic;

intrinsic autcentquo_hash(G::LMFDBGrp) -> RngIntElt
{}
    return hash(Get(G, "MagmaAutcentquo"));
end intrinsic;

intrinsic autcentquo_tex(G::LMFDBGrp) -> MonStgElt
{}
    return GroupName(Get(G, "MagmaAutcentquo") : TeX:=true, prodeasylimit:=2, wreathlimit:=0);
end intrinsic;


// Some utility functions that are not defined for GrpAuto

intrinsic Index(G::GrpAuto, N::GrpAuto : check:=false) -> RngIntElt
{}
    if check then
        assert Group(G) eq Group(N);
        assert &and[n in G : n in Generators(N)];
    end if;
    return #G div #N;
end intrinsic;

intrinsic Random(G::GrpAuto : word_len:=40) -> GrpAutoElt
{}
    gens := [<g, Order(g)> : g in Generators(G)];
    gens := [pair : pair in gens | pair[2] ne 1];
    r := Identity(G);
    for i in [1..word_len] do
        j := Random(1,#gens);
        k := Random(0,gens[j][2]-1);
        r *:= gens[j][1]^k;
    end for;
    return r;
end intrinsic;

/* The bug in Magma's IsInner was fixed in 2.28-14
intrinsic IsInnerFixed(a :: GrpAutoElt) -> BoolElt, GrpPermElt
{Fix a bug in Magma's IsInner}
    A := Parent(a);
    if not assigned A`Group then
        error "Underlying group of automorphism group is not known";
    end if;
    G := A`Group;
    C := G;
    y := Id(G);
    gens := [g : g in Generators(G)]; // change is here: for PC groups [G.i : i in [1..Ngens(G)]] doesn't generate
    for g in [gens[i] : i in [1..#gens]] do
        yes, el := IsConjugate(C, g^y, g@a);
        if not yes then
            return false, _;
        end if;
        y := y*el;
        C := Centraliser(C, g@a);
    end for;
    return true, y;
end intrinsic;
*/

intrinsic FewGenerators(A::GrpAuto : outer:=false, Try:=1) -> SeqEnum
{}
    G := Group(A);
    m, P, Y := ClassAction(A);
    if outer then
        I := sub<P|[P![Position(Y,g^-1*y*g) : y in Y] : g in Generators(G)]>;
        D := DerivedSubgroup(P);
        DI := sub<P|D, I>;
        Q, Qproj := quo<P | DI>; // maximal abelian quotient
        if D subset I then
            // P/I is already abelian, so we can pull back generators
            return [(b @@ Qproj) @@ m : b in AbelianBasis(Q)];
        end if;
        n := #AbelianInvariants(Q);
        ogens := [f : f in Generators(A) | not IsInner(f)];
        n_opt := Infinity();
        for j in [1..Try] do
            for i in [1..Min(Degree(P), 1000)] do
                s := [Random(P) : x in [1..n+1]];
                s := [x : x in s | x ne P.0];
                if sub<P|s,I> eq P then
                    if #s eq n then
                        return [b @@ m : b in s];
                    end if;
                    n_opt := #s;
                    g_opt := s;
                end if;
            end for;
        end for;
        if n_opt lt #ogens then
            return [b @@ m : b in g_opt];
        end if;
        return ogens;
    else
        return [b @@ m : b in FewGenerators(P : Try:=Try)];
    end if;
end intrinsic;
