# parallel -j 88 -a DATA/gapaut1.todo --timeout 3600 --results DATA/autresults 'gap -b -c "label:=\"{}\";" Aut.g'

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

Read("IO.g");
s := ReadAll(InputTextFile(Concatenation("DATA/gap_descriptions/", label)));
phicov := StringToGroupHom(s);
phi := phicov[1]; mapdir := phicov[2];
# mapdir: 0 for no map, 1 for G->Disp, -1 for Disp->G
# Disp = H is how elements should be displayed, G is the actual group that we compute with.
if mapdir = -1 then
    H := Source(phi);
    G := Range(phi);
else
    H := Range(phi);
    G := Source(phi);
fi;
gens := GeneratorsOfGroup(G);

if IsPermGroup(H) then
    Hdeg := Size(MovedPoints(H));
else
    Hdeg := 0;
fi;


EncodeB := function(g)
    if mapdir = 1 then
        g := Image(phi, g);
    elif mapdir = -1 then
        g := PreImagesRepresentative(phi, g);
    fi;
    if IsPerm(g) then
        return String(EncodePerm(g, Hdeg));
    elif IsPcGroup(H) then
        return String(EncodePcElt(g, H));
    elif IsMatrixGroup(H) then
        return String(EncodeMat(g, H));
    fi;
end;

A := AutomorphismGroup(G);
Agens := GeneratorsOfGroup(A);

EncodeA := function(agen)
    return JoinStringsWithSeparator(List(gens, g -> EncodeB(g^agen)));
end ;

out := Concatenation([String(Size(A)), "|{{", JoinStringsWithSeparator(List(gens, EncodeB)), "},{", JoinStringsWithSeparator(List(Agens, EncodeA), "},{"), "}}\n"]);

WriteAll(OutputTextFile(Concatenation("DATA/gap_autgroup/", label), false), out);
QuitGap(0);

