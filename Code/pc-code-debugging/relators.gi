#############################################################################
##
##  This file is part of GAP, a system for computational discrete algebra.
##  This file's authors include Bettina Eick.
##
##  Copyright of GAP belongs to its developers, whose names are too numerous
##  to list here. Please refer to the COPYRIGHT file for details.
##
##  SPDX-License-Identifier: GPL-2.0-or-later
##

#############################################################################
##
#F RelatorsCode( <code>, <size>, <gens> )
##
RelatorsCode := function( code, size, gens )
    local n1, f, l, mi, n, indices, rels, g, i, uc, ll, rr,
          t, j, z, z2;

    # get indices
    f    := Factors(Integers, size );
    Print(f);
    l    := Length( f );
    mi   := Maximum( f ) - 1;
    n    := ShallowCopy( code );
    if Length( Set( f ) ) > 1 then
        indices := CoefficientsMultiadic( List([1..l], x -> mi),
                       n mod (mi^l) ) + 2;
        n := QuoInt( n, mi^l );
    else
        indices := f;
    fi;
 
    # initialize relators
    rels := [];
    rr   := [];

    for i in [1..l] do
        rels[i]:=gens[i]^indices[i];
    od;

    ll:=l*(l+1)/2-1;
    if ll < 28 then
        uc := Reversed( CoefficientsMultiadic( List([1..ll], x -> 2 ),
                           n mod (2^ll) ) );
    else
        uc := [];
        n1 := n mod (2^ll);
           for i in [1..ll] do
               uc[i] := n1 mod 2;
                n1 := QuoInt( n1, 2 );
        od;
    fi;
    n := QuoInt( n,2^ll );

    for i in [1..Sum(uc)] do
        t := CoefficientsMultiadic( indices, n mod size );
        g := gens[1]^0;
        for j in [1..l] do
            if t[j] > 0 then 
                g := g * gens[j]^t[j];
            fi;
        od;
        Add( rr, g );
        n := QuoInt( n, size );
    od;
    z:=1;
    for i in [1..l-1] do
        if uc[i] = 1 then
            rels[i] := rels[i]/rr[z];
            z := z+1;
        fi;
    od;
    z2 := l-1;
    for i in [1..l] do
        for j in [i+1..l] do
            z2 := z2+1;
            if uc[z2] = 1 then
                Add( rels, Comm( gens[ j ], gens[ i ] ) / rr[ z ] );
                z := z+1;
            fi;
        od;
    od;

    return rels;
end;;
