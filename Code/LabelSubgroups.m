/*
This file implements a scheme for labeling conjugacy classes of subgroups of a finite group G.
When we refer to a subgroup H of G we always view it up to conjugacy.

The label of a subgroup takes the form n.i.j, where n=[G:H] is the index, i is an ordinal that distinguishes Gassmann equivalence classes of the same index, and j is
an ordinal that distinguishes Gassmann-equivalent conjugacy classes of subgroups.  Recall that subgroups H1 and H2 of G
are Gassmann equivalent if they intersect each G-conjugacy class with the same cardinality, equivalently, H1 and H2 have
the same index n and the permutation representations pi_H1:G->S_n and pi_H2:G->S_n have the same character (which counts
the number of cosets fixed by each conjugacy class). An equivalent condition is that the G-sets [G\H1] and [G\H2] are
isomorphic as Q[G]-modules (so think of Gassmann classes as isogeny classes).

In order to label Gassmann classes we need to fix an ordering of the conjugacy classes of elements of G.
Having fixed such an ordering it is easy to compute a unique identifier for each Gassmann class; one can use
the PermutationCharacter function in Magma (which uses whatever ordering Magma chooses for conjugacy classes), or one can
count the intersection of H with each G-conjugacy class (to do this efficiently one enumerates conjugacy classes of
elements of H (in any order) and uses an efficiently computable map from elements of G to conjugacy class identifiers
(e.g. as returned by the ClassMap function in Magma). The latter approach is used by the function SubgroupClass below.
(using PermutationCharacter takes about the same time, both are very fast).

In order to keep labels small we assume that we compute all the Gassmann classes for a given index so we can assign
ordinals to them (but we don't have to do this for all subgroups, just all with the same index).

To compute j we first order subgroups H in the same Gassmann class using the lex ordering on sorted list of labels of all (proper) supergroups of H (one can
and often does have Gassmann equivalent subgroups for which the lists of supergroups are differ).  Note that
here "supergroup" refers to inclusions in the poset of conjugacy classes of subgroups: we consider K to be
a supergroup of H if it contains any G-conjugate of H (note that we are free to fix any G-conjugate of K
provided we check all the G-conjugates of H for inclusion).  Only in cases where two or more Gassmann
equivalent subgroups have the same set of supergroups do we resort to computing permutation rep signatures,
and rather than computing sig(G,H), we are free to replace G with any supergroup K of H and instead compute
sig(K,H), which helps a lot when [K:H] is smaller then [G:H].  We need to be careful to account for the fact
that there may be two or more G-conjugates of H contained in K that are not K-conjugate, so we compute the
sorted list sig(K,H') where H' varies over G-conjugates of H in K to esure we get a signature that is
G-invariant (but computing a bunch of signatures of smaller index is much better than computing one of large
index, and we are free to choose K to minimize the index, since we know that all the subgroups we want to
distinguish have the same set of supergroups).

This approach is implemented by the function LabelSubgroups below.

PROs: Well defined mathematically meaningful labels that can be computed somehwat efficiently.
We don't need to label all subgroups, but we do need to label all with index >= m for some m.
CONs: There are still screw cases where this is hopelessly slow (e.g. PSL(2,29)), but it should be fast
enough to feasible label all the subgroups of any groups in the small groups database, and lots of
subgroups of transitive groups (at least up to a reasonable index bound).
*/

intrinsic minSn(Sn::GrpPerm, g::GrpPermElt) -> GrpPermElt
    {Given g in Sn returns h in Sn such that g^h := h^-1*g*h is minimal permutation
     with the same cycle type as g, where cycles are ordered largest to smallest,
     and then rotated to have min element first and compared lexicographically}
    if Order(g) eq 1 then return g; end if;
    C := Reverse(Sort(CycleStructure(g)));
    X := [];
    n := 0;
    for c in C do
        if c[1] gt 1 then
            for i:=1 to c[2] do
                Append(~X, {@i:i in [n+1..n+c[1]]@});
                n +:= c[1];
            end for;
        end if;
    end for;
    m := Sn!X;
    _,h := IsConjugate(Sn,g,m);
    assert g^h eq m;
    return h;
end intrinsic;

intrinsic ccmp(a::SeqEnum, b::SeqEnum) -> RngIntElt
    {When sorting cycles we put larger cycles fist so we can drop singletons off the end}
    if #a gt #b then return -1; end if;
    if #a lt #b then return 1; end if;
    if a lt b then return -1; end if;
    if a gt b then return 1; end if;
end intrinsic;

intrinsic cyc(g::GrpPermElt) -> SeqEnum
    {Given perm g return its standard cycle rep (largest cycles first, cycles start with min, equal length cycles lex order)
     Note that we are relying on the fact that Magma returns cycles rotated to have min element first}
    cc := Sort([[n:n in c] : c in CycleDecomposition(g) | #c gt 1], ccmp);
    return cc;
end intrinsic;

intrinsic perm(Sn::GrpPerm, cc::SeqEnum) -> GrpPermElt
    {Given list of cycles, returns corresponding permutation in Sn}
    return Sn![{@n:n in c@}:c in cc];
end intrinsic;

intrinsic minH(Sn::GrpPerm, H::GrpPerm, g::GrpPermElt) -> GrpPermElt
    {returns h such that c^g is the minimal rep of H-orbit of cycle rep c}
    if IsIdentity(g) then return g; end if;
    if #H gt 10^7 then printf "Enumerating conjugates in group of order %o is going to take a while...\n", #H; end if;
    m := perm(Sn, Min([cyc(x) : x in g^H]));
    _,h := IsConjugate(H, g, m);
    return h;
end intrinsic;

intrinsic opt(Sn::GrpPerm, H::GrpPerm, g::GrpPermElt) -> GrpPermElt
    {returns h such that g^h is minimal element of H-orbit of g}
    cc := cyc(g);
    s := Reverse(Sort([c[1]:c in CycleStructure(g)|c[1] gt 1]));
    h := Identity(H);
    // optimize cycles of same size together (this is necessary, we cannot optimize cycles 1-by-1)
    for n in s do
        ng := perm(Sn,[c:c in CycleDecomposition(g)|#c eq n]);
        nh := minH(Sn,H,ng);
        g := g^nh;
        h *:= nh;
        H := Centralizer(H,ng^nh);
    end for;
    return h;
end intrinsic;

intrinsic canonicalize(S::SeqEnum) -> SeqEnum
    {Given list of generators for a permutation group of degree n, returns lex-minimal Sn-conjugate list}
    if #S eq 0 then return S; end if;
    Sn := SymmetricGroup(Degree(Universe(S)));
    h := minSn(Sn, S[1]);
    S := [g^h : g in S];
    H := Centralizer(Sn, S[1]);
    for i:=2 to #S do
        //h := minH(Sn,H,S[i]);
        h := opt(Sn, H, S[i]);
        S := [g^h : g in S];
        H := Centralizer(H, S[i]);
    end for;
    return S;
end intrinsic;

intrinsic sig(G::Grp, H::Grp) -> SeqEnum
    {Given subgroup H of G returns lex-minimal images of generators of G in permutation rep [H\G]
     This uniquely identifies H up to conjugacy (and is invariant under conjugation).}
    return [cyc(g) : g in canonicalize([pi(g) : g in Generators(G)])] where pi:=CosetAction(G,H);
end intrinsic;

intrinsic SubgroupClass(H::Grp, phi::Map) -> SeqEnum
    {Given a class map phi:G->[1..n] for a group G with n conjugacy classes and a subgroup H of G returns sorted list of
     pairs [i,m] giving the positive number m of elements of H in conjugacy class i.  This is equivalent to giving the
     permutation character of G,H and uniquely determines H up to rational equivalence (Gassmann equivalence).  The map phi
     can be constructed using ClassMap(G,H), but this will order the conjugacy classes in whatever way Magma chooses,
     construct phi explicitly if you care about the ordering}
    T := AssociativeArray();
    for c in ConjugacyClasses(H) do
        k := phi(c[3]);
        if IsDefined(T, k) then T[k] +:= c[2]; else T[k] := c[2]; end if;
    end for;
    return Sort([[k, v] : k -> v in T]);
end intrinsic;

intrinsic IndexFibers(S::SeqEnum, f::UserProgram) -> Assoc
    {Given a list of objects S and a function f on S creates an associative array satisfying A[f(s)] = [t:t in S|f(t) eq f(s)]}
    A:=AssociativeArray();
    for x in S do
        y := f(x);
        A[y] := IsDefined(A,y) select Append(A[y],x) else [x];
    end for;
    return A;
end intrinsic;

intrinsic ConjugatesInSubgroup(G::Grp, H::Grp, K::Grp) -> SeqEnum
    {Given subgroups K and H of G such that K is conjugate to a subgroup of H, return such a conjugate}
    return [KK:KK in Conjugates(G,K)|KK subset H];
end intrinsic;

intrinsic Supergroups(G::Grp, L::SeqEnum, LI::SeqEnum, j::RngIntElt) -> SeqEnum
    {Given a list of subgroups L of G with indices LI returns list of indices i such that
     L[j] is conjugate to a subgroup of L[i]}
    C := Conjugates(G,L[j]);
    n := LI[j];
    return [i:i in [1..#L]|LI[i] lt n and IsDivisibleBy(n,LI[i]) and #[HH:HH in C|HH subset L[i]] gt 0];
end intrinsic;

intrinsic LabelSubgroups(G::Grp : phi:=ClassMap(G), max_index:=0) -> SeqEnum
    {}
    S := Sort(Subgroups(G:IndexLimit:=max_index),func<a,b|b`order-a`order>); // reverse sort by order to sort by index
    L := [H`subgroup:H in S]; //`
    LI := [#G div H`order:H in S]; //`
    LL := AssociativeArray();   // LL[i] will be set to the label of the subgroup L[i]
    N := IndexFibers([1..#L], func<i|LI[i]>);
    for n in Sort([n:n in Keys(N)]) do  // loop over indexes of subgroups (in increasing order)
        if max_index gt 0 and n gt max_index then break; end if;
        if #N[n] eq 1 then LL[N[n][1]] := [n,1,1]; continue; end if;
        C := IndexFibers(N[n], func<i | SubgroupClass(L[i], phi)>);
        I := [C[c] : c in Sort([c : c in Keys(C)])];
        for i:=1 to #I do
            if #I[i] eq 1 then LL[I[i][1]] := [n,i,1]; continue; end if;
            // printf "Labelling %o subgroups in Gassmann class %o.%o\n", #I[i], n, i;
            O := IndexFibers(I[i],func<j|Sort([<LL[k],k>:k in Supergroups(G,L,LI,j)])>);
            O := [[O[o],[x[2]:x in o]]: o in Sort([o:o in Keys(O)])];
            j := 1;
            for o in O do // loop over sorted list of supergroup labels
                if #o[1] eq 1 then LL[o[1][1]] := [n,i,j]; j+:=1; continue; end if;
                printf "Labelling %o subgroups in Gassmann class %o.%o with %o common overgroups\n", #o[1], n, i, #o[2];
                // we may be repeating work here (and we should really let caller specify the class map)
                psis := [ClassMap(L[k]):k in o[2]];
                S := IndexFibers(o[1],
                         func<k|[Sort([SubgroupClass(K,psi):K in ConjugatesInSubgroup(G,Domain(psi),L[k])]):psi in psis]>);
                S := [S[s]:s in Sort([s:s in Keys(S)])];
                for s in S do
                    if #s eq 1 then LL[s[1]] := [n,i,j]; j+:=1; continue; end if;
                    // last supergroup will have maximal index (and thus contain groups in s with minimal index)
                    H := L[o[2][#o[2]]];
                    printf "*** Computing signatures of %o index %o subgroups ***\n", #s, #H div #L[s[1]];
                    t := Cputime();
                    Z := Sort([<Sort([sig(H,K):K in ConjugatesInSubgroup(G,H,L[k])]),k> : k in s]);
                    for z in Z do LL[z[2]] := [n,i,j]; j+:=1; end for;
                end for;
            end for;
        end for;
    end for;
    return Sort([<LL[i],L[i]>:i in [1..#L]],func<a,b| a[1] lt b[1] select -1 else a[1] gt b[1] select 1 else 0>);
end intrinsic;

function testsig(m:index := 0)
    for n:= 4 to m do
        k := NumberOfSmallGroups(n);
        for i:=1 to k do
            G := SmallGroup(n,i);
            S := [H`subgroup:H in Subgroups(G)|#H`subgroup gt 1 and #H`subgroup lt n]; //`
            if index gt 0 then S := [H:H in S|Index(G,H) eq index]; end if;
            for j in Sort([x:x in {Index(G,H):H in S}]) do
                printf "Checking index %o subgroups of %o.%o...",j,n,i; t:=Cputime();
                T := [H:H in S|Index(G,H) eq j];
                assert #T eq #{sig(G,H):H in T};                   // check uniqueness
                for H in T do
                    assert #{sig(G,H):i in [1..5]} eq 1;           // check determinism
                    assert #{sig(G,K):K in Conjugates(G,H)} eq 1;  // check conjugacy-invariance
                end for;
                printf "%.3os\n",Cputime()-t;
            end for;
        end for;
    end for;
    return true;
end function;

function test_small(m,f:max_index:=0,quiet:=true)
    for n:= 1 to m do
        k := NumberOfSmallGroups(n);
        for i:=1 to k do
            t := Cputime();
            L := f(SmallGroup(n,i):max_index:=max_index);
            if not quiet then
                printf "Subgroups labels for %o.%o:\n", n,i;
                for x in L do printf "   %o.%o.%o\n",x[1][1],x[1][2],x[1][3]; end for;
            end if;
            printf "Computed %o subgroup labels for group %o.%o in %.3os\n", #L,n,i,Cputime()-t;
        end for;
    end for;
    return true;
end function;

function test_transitive(m,f:max_index:=0,max_size:=0,quiet:=true)
    for n:= 1 to m do
        k := NumberOfTransitiveGroups(n);
        for i:=1 to k do
            t := Cputime();
            G := TransitiveGroup(n,i);
            if max_size gt 0 and #G gt max_size then break; end if;
            L := f(G:max_index:=max_index);
            if not quiet then
                printf "Subgroups labels for %oT%o:\n", n,i;
                for x in L do printf "   %o.%o.%o\n",x[1][1],x[1][2],x[1][3]; end for;
            end if;
            printf "Computed %o subgroup labels for group %oT%o in %.3os\n", #L,n,i,Cputime()-t;
        end for;
    end for;
    return true;
end function;

function test_gl2p(m,f:max_index:=0,quiet:=true)
    for p in PrimesInInterval(1,m) do
        t := Cputime();
        L := f(GL(2,p):max_index:=max_index);
        if not quiet then
            printf "Subgroups labels for GL(2,%o):\n", p;
            for x in L do printf "   %o.%o.%o\n",x[1][1],x[1][2],x[1][3]; end for;
         end if;
        printf "Computed %o subgroup labels for group GL(2,%o) in %.3os\n", #L,p,Cputime()-t;
    end for;
    return true;
end function;

function test_psl2q(m,f:max_index:=0,quiet:=true)
    for q in [2..m] do
        if not IsPrimePower(q) then continue; end if;
        t := Cputime();
        L := f(PSL(2,q):max_index:=max_index);
        if not quiet then
            printf "Subgroups labels for PSL(2,%o):\n", q;
            for x in L do printf "   %o.%o.%o\n",x[1][1],x[1][2],x[1][3]; end for;
        end if;
        printf "Computed %o subgroup labels for groupPSL(2,%o) in %.3os\n", #L,q,Cputime()-t;
    end for;
    return true;
end function;
