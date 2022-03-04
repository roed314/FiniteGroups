
// cat DATA/hashclusters/transitive_add.txt | parallel -j128 magma gp:="{1}" Explore.m

AttachSpec("hashspec");

SetColumns(0);
nTt := Split(gp, " ")[2];
n, t := Explode([StringToInteger(c) : c in Split(nTt, "T")]);
G := TransitiveGroup(n, t);

// Fast:
// order|solvable|simple|derived_length|index of derived sub|index of center
// iterative closure orders (derived, center, frattini, fitting, radical, socle, Sylow)

// Slower:
// num max subs|num large max subs|num normal subs|num large normal subs
// iterative closure ordhashes

N := Order(G);
solv := IsSolvable(G) select "t" else "f";
simp := IsSimple(G) select "t" else "f";
PrintFile("DATA/TExplore/" * nTt, Sprintf("%o|%o|%o|%o|%o|%o", Order(G), solv, simp, DerivedLength(G), Index(G, DerivedSubgroup(G)), Index(G, Center(G))));
Subs := {@ G @};
Const := [""];
FuncToStr := AssociativeArray();
FuncToStr[DerivedSubgroup] := "D";
FuncToStr[Center] := "Z";
FuncToStr[FrattiniSubgroup] := "P";
FuncToStr[FittingSubgroup] := "F";
FuncToStr[Radical] := "R";
FuncToStr[Socle] := "S";
i := 1;
while i le #Subs do
    H := Subs[i];
    for F in [DerivedSubgroup, Center, FrattiniSubgroup, FittingSubgroup, Radical, Socle] do
        K := F(H);
        if not IsInSmallGroupDatabase(#K) or #K lt 2000 and #K ge 512 and Valuation(#K, 2) ge 7 then
            m := #Subs;
            Include(~Subs, K);
            if #Subs gt m then
                Append(~Const, Const[i] * "-" * FuncToStr[F]);
            end if;
        end if;
    end for;
    for pe in Factorization(#H) do
        K := SylowSubgroup(H, pe[1]);
        if not IsInSmallGroupDatabase(#K) or #K lt 2000 and #K ge 512 and Valuation(#K, 2) ge 7 then
            m := #Subs;
            Include(~Subs, K);
            if #Subs gt m then
                Append(~Const, Const[i] * "-" * Sprint(pe[1]));
            end if;
        end if;
    end for;
    i +:= 1;
end while;
PrintFile("DATA/TExplore/" * nTt, Sprint(#Subs - 1));
PrintFile("DATA/TExplore/" * nTt, Join([Sprint(#H) : H in Subs[2..#Subs]], "|"));
PrintFile("DATA/TExplore/" * nTt, Join([x[2..#x] : x in Const[2..#Const]], "|"));
exit;
