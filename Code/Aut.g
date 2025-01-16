# sage -gap -b -c "label:={label};" Aut.g

# SplitString (bad style), JoinStringsWithSeparator, Concatenation
# PositionSublist("abcdefg","cdf") = fail
# Collected(Factors(Factorial(10))) -> [[2, 8], [3, 4], [5, 2], [7, 1]]
# l:= [ 1, 2, 3 ];;
#   Apply(l, i -> i^2) changes l to [1,4,9]
#   List(l, i -> i^2) return [1,4,9]
#   Perform(l, i -> i^2) executes on each entry, not returning anything
#   Filtered(l, IsPrime) returns [2, 3]
# PermListList(B, A) finds a permutation mapping A to B.
# Cartesian gives cartesian product

Read(Concatenation("DATA/gap_descriptions/", label));
# Defines G (the group to call Aut on), gens, phi and mapdir (0 for no map, 1 for G->Disp, -1 for Disp->G)

if mapdir = 1 then
    H := Image(phi, G);
elif mapdir = -1 then
    H := Domain(phi);
else
    H := G;
fi;
if IsPermGroup(H) then
    Hdeg := Size(MovedPoints(H));
fi;


IsSubstring := function(x, y)
    return PositionSublist(x, y) <> fail;
end;

Encode := function(g)
    if mapdir = 1 then
        g := Image(phi, g);
    elif mapdir = -1 then
        g := PreImagesRepresentative(phi, g);
    fi;
    if IsPerm(g) then
        return Sprint(EncodePerm(g, Hdeg));
    elif IsPcGroup(H) then
        return Sprint(EncodePcElt(g, H));
    elif IsMatrixGroup(H) then
        return Sprint(EncodeMat(g, H));
    fi;
end;

A := AutomorphismGroup(G);
Agens := GeneratorsOfGroup(A);

EncodeA := function(agen)
    return JoinStringsWithSeparator(List(gens, g -> Encode(g^agen)));
end ;

out := "{{";
Append(out, JoinStringsWithSeparator(List(gens, Encode)));
Append(out, "},{");
Append(out, JoinStringsWithSeparator(List(Agens, EncodeA), "},{"));
Append(out, "}}");
