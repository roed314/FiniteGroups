# This file implements functions for loading string descriptions into GAP.

#StringToGroupHom := function(s)
#    local a,b,c;
#    if  then
#        
#    elif  then
#        
#    else
#        
#    fi;
#end;

IV_merge_and_countv := function(ivA_A, ivB_B)
    local ivA, A, ivB, B, ivC, C, i, j, lA, lB;
    ivA := ivA_A[1];
    A := ivA_A[2];
    ivB := ivB_B[1];
    B := ivB_B[2];
    C := [];
    ivC := [];
    i := 1;
    j := 1;
    lA := Length(A);
    lB := Length(B);
    while i <= lA and j <= lB do
        if B[j] < A[i] then
            Append(C, [B[j]]);
            Append(ivC, [ivB[j] + lA - i + 1]); # checkme off-by-one
            j := j+1;
        else
            Append(C, [A[i]]);
            Append(ivC, [ivA[i]]);
            i := i+1;
        fi;
    od;
    if i <= lA then
        Append(C, A{[i..lA]});
        Append(ivC, ivA{[i..lA]});
    else
        Append(C, B{[j..lB]});
        Append(ivC, ivB{[j..lB]});
    fi;
    return [ivC, C];
end;

IV_base_case := function(L)
    local i, j, s, n, dpi, perm, iv, checked;
    n := Length(L);
    s := ShallowCopy(L);
    perm := Sortex(s);
    iv := ListWithIdenticalEntries(n, 0);
    checked := ListWithIdenticalEntries(n, 1);
    for i in [n, n-1..1] do
        dpi := i^perm;
        checked[dpi] := 0;
        iv[dpi] := Sum([dpi+1..n], j->checked[j]);
    od;
    return [iv, s];
end;

IV_sort_and_countv := function(L)
    local l, n;
    n := Length(L);
    if n < 250 then
        return IV_base_case(L);
    fi;
    l := QuoInt(n, 2);
    return IV_merge_and_countv(IV_sort_and_countv(L{[1..l]}), IV_sort_and_countv(L{[l+1..n]}));
end;

ToInversionVector := function(g, n)
    local i;
    return IV_sort_and_countv(List([1..n], i->i^g))[1];
end;


LehmerCodeSmall := function(g, n)
    local i, j, pi, lehmer, checked;
    lehmer := [];
    checked := ListWithIdenticalEntries(n, 1);
    for i in [1..n] do
        pi := i^g;
        checked[pi] := 0;
        Append(lehmer, [Sum([1..pi-1], j->checked[j])]);
    od;
    return lehmer;
end;

LehmerCode := function(g, n)
    if n < 250 then
        return LehmerCodeSmall(g, n);
    fi;
    return ToInversionVector(Inverse(g), n);
end;

LehmerCodeToRank := function(lehmer)
    local i, n, rank;
    rank := 0;
    n := Length(lehmer);
    for i in [n-1,n-2..0] do
        rank := rank + lehmer[n-i] * Factorial(i);
    od;
    return rank;
end;

RankToLehmerCode := function(x, n)
    local lehmer, j;
    lehmer := [];
    for j in [1..n] do
        Append(lehmer, [x mod j]);
        x := QuoInt(x, j);
    od;
    return List([0..n-1], j->lehmer[n-j]);
end;

LehmerCodeToPermutation := function(lehmer)
    local n, i, j, p_seq, open_spots;
    n := Length(lehmer);
    p_seq := [];
    open_spots := [1..n];
    for i in [1..n] do
        j := lehmer[i] + 1;
        Append(p_seq, [open_spots[j]]);
        Remove(open_spots, j);
    od;
    return PermList(p_seq);
end;

EncodePerm := function(g, n)
    return LehmerCodeToRank(LehmerCode(g, n));
end;

DecodePerm := function(x, n)
    if x >= Factorial(n) then
        ErrorNoReturn("Input larger than n!");
    fi;
    return LehmerCodeToPermutation(RankToLehmerCode(x, n));
end;

EncodePcElt := function(g, H)
    local i, n, pcgs, v, Ps;
    n := 0;
    pcgs := Pcgs(H);
    v := Reversed(ExponentsOfPcElement(pcgs, g));
    Ps := Reversed(RelativeOrders(pcgs));
    for i in [1..Length(Ps)] do
        n := n * Ps[i];
        n := n + v[i];
    od;
    return n;
end;

DecodePcElt := function(x, H)
    local r, pcgs, v, p, Ps;
    v := [];
    pcgs := Pcgs(H);
    Ps := RelativeOrders(pcgs);
    for p in Ps do
        r := RemInt(x, p);
        x := QuoInt(x, p);
        Append(v, [r]);
    od;
    if x <> 0 then
        ErrorNoReturn("Invalid input");
    fi;
    return PcElementByExponents(pcgs, v);
end;

SequenceToInteger := function(L, b)
    local n, x;
    n := 0;
    for x in Reversed(L) do
        n := b * n;
        n := n + x;
    od;
    return n;
end;

Pad := function(L, n)
    if Length(L) >= n then
        return L;
    fi;
    return Concatenation(L, ListWithIdenticalEntries(n - Length(L), 0));
end;

dbcFromdR := function(dR)
    local d, Rcode, b;
    dR := SplitString(dR, ",");
    d := Int(dR[1]);
    Rcode := dR[2];
    if Rcode = "0" then
        b := Int(dR[3]);
    else
        b := 0;
    fi;
    return [d, b, Rcode];
end;

EncodeMat := function(g, H)
    local R, b, m, M, shift, B, x, y;
    g := Flat(g);
    R := DefaultFieldOfMatrixGroup(H);
    b := Characteristic(R);
    if b = 0 then
        # For now, we only support integer matrices in characteristic 0
        if not IsIntegerMatrixGroup(H) then
            ErrorNoReturn("Only integer matrices are supported in characteristic 0");
        fi;
        m := Minimum(g);
        M := Maximum(g);
        if AbsoluteValue(M) > AbsoluteValue(m) then
            b := 2 * AbsoluteValue(M);
        else
            b := 2 * AbsoluteValue(m) + 1;
        fi;
        # b = 2 supports 0,1; b=3 supports -1,0,1; b=4 supports -1,0,1,2
        shift := QuoInt(b - 1, 2);
        g := g + shift;
    else
        b := Characteristic(R);
        if IsField(R) and not IsPrime(Size(R)) then
            B := Basis(R);
            g := Concatenation(List(g, x->Coefficients(B, x)));
        fi;
        g := List(g, Int);
    fi;
    return SequenceToInteger(g, b);
end;

DecodeMat := function(x, d, Rcode, b)
    local shif, q, p, B, k, L, i, m, N;
    if Rcode = "0" then
        shif := QuoInt(b - 1, 2);
    elif Rcode[1] = 'q' then
        q := Int(Rcode{[2..Length(Rcode)]});
        p := SmallestRootInt(q);
        B := Basis(GF(q));
        k := LogInt(q, p);
        b := p;
    else
        N := Int(Rcode);
        b := N;
    fi;
    L := CoefficientsQadic(x, b);
    if Rcode[1] = 'q' then
        L := Pad(L, k*d^2);
        L := List([0..d^2-1], i->Sum(List([1..k], m->B[m] * L[m + k*i])));
    elif Rcode = "0" then
        L := Pad(L, d^2) - shif;
    else
        L := Pad(L, d^2);
        L := List([1..d^2], i->ZmodnZObj(L[i], N));
    fi;
    return List([0..d-1], i->L{[i*d+1..(i+1)*d]});
end;

StringToGroup := function(s)
    local i, dR, L, n, N, dbc, code, cmd, pieces, q, GAP_translation;
    NormalizeWhitespace(s);
    i := PositionSublist(s, "MAT");
    if i <> fail then
        dR := s{[1..i-1]};
        L := SplitString(s{[i+3..Length(s)]}, ",");
        dbc := dbcFromdR(dR);
        return Group(List(L, x->DecodeMat(Int(x), dbc[1], dbc[3], dbc[2])));
    fi;
    i := PositionSublist(s, "Perm");
    if i <> fail then
        n := Int(s{[1..i-1]});
        L := SplitString(s{[i+4..Length(s)]}, ",");
        return Group(List(L, x->DecodePerm(Int(x), n)));
    fi;
    i := PositionSublist(s, "PC");
    if i <> fail then
        N := Int(s{[1..i-1]});
        code := Int(s{[i+2..Length(s)]});
        return PcGroupCode(code, N);
    fi;
    if s[Length(s)] = ')' then
        pieces := SplitString(s{[1..Length(s)-1]}, "(");
        if Length(pieces) = 2 then
            cmd := pieces[1];
            # SOPlus, SOMinus -> SO(1, n, q), SO(-1, n, q)
            # OmegaPlus, OmegaMinus -> Omega(1, n, q), Omega(-1, n, q)
            # GOPlus, GOMinus, PGOPlus, PGOMinus, PSOPlus, PSOMinus, POmegaPlus, POmegaMinus
            # Missing: CSp, CSO, CSOPlus, CSOMinus, CSU, CO, COPlus, COMinus, CU
            # Missing: Spin, SpinPlus, SpinMinus, PSigmaSp, PGammaU, AGL, ASL, ASp, AGammaL, ASigmaL, ASigmaSp
            # OK, but bumping since there are different conventions around which form to use: "Sp", "SO", "SU", "GO", "GU", "PGL", "PSL", "PGU", "PSU", "PSp", "PGO", "PSO", "POmega", "PGammaL", "PSigmaL"
            if cmd in ["GL", "SL"] then
                pieces := SplitString(pieces[2], ",");
                n := Int(pieces[1]);
                q := Int(pieces[2]);
                if cmd = "GL" then
                    return GL(n,q);
                else
                    return SL(n,q);
                fi;
            fi;
        fi;
    fi;
    if '.' in s then
        pieces := SplitString(s, ".");
        return SmallGroup(Int(pieces[1]), Int(pieces[2]));
    fi;
    if 'T' in s then
        pieces := SplitString(s, "T");
        return TransitiveGroup(Int(pieces[1]), Int(pieces[2])); # fails in degree 32
    fi;
    #GAP_translation := LoadTranslation(s);
    #if GAP_translation <> fail then
    #    return StringToGroup(GAP_translation);
    #fi;
    # TODO: THIS FUNCTION HAS NOT BEEN FINISHED
end;
