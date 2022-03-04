
// cat DATA/hashclusters/transitive_add.txt | parallel -j128 magma gp:="{1}" Explore.m

AttachSpec("hashspec");

SetColumns(0);
nTt := Split(gp, " ")[2];
n, t := Explode([StringToInteger(c) : c in Split(nTt, "T")]);
G := TransitiveGroup(n, t);

function is_small(n)
    if n le 2000 then
        return n ne 1024;
    end if;
    F := Factorization(n);
    if #F eq 1 then
        return (F[1][2] le 7 or F[1][2] eq 8 and F[1][1] eq 3);
    elif #F eq 2 then
        if F[1][2] gt 1 and F[2][2] gt 1 then
            return false;
        elif F[1][2] eq 1 and F[2][2] eq 1 then
            return true;
        elif F[1][2] eq 1 then
            p := F[1][1];
            q := F[2][1];
            n := F[2][2];
        else
            p := F[2][1];
            q := F[1][1];
            n := F[1][2];
        end if;
        return (p eq 2 and n le 8 or p eq 3 and n le 6 or p eq 5 and n le 5 or p eq 7 and n le 4);
    elif #F eq 3 then
        return &and[x[2] eq 1 : x in F];
    else
        return false;
    end if;
end function;

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
