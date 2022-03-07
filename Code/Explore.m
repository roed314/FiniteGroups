
// cat DATA/hashclusters/transitive_add.txt | parallel -j128 magma gp:="{1}" Explore.m

AttachSpec("hashspec");

SetColumns(0);
label, nTt, importance := Explode(Split(gp, " "));
n, t := Explode([StringToInteger(c) : c in Split(nTt, "T")]);
G := TransitiveGroup(n, t);
if IsSolvable(G) then
    G := PCGroup(G);
end if;

// Fast:
// order|solvable|simple|derived_length|index of derived sub|index of center
// iterative closure orders (derived, center, frattini, fitting, radical, socle, Sylow)

// Slower:
// num max subs|num large max subs|num normal subs|num large normal subs
// iterative closure ordhashes

function MyQuo(H, K)
    if #K eq 1 then
        return H;
    elif #K eq #H then
        return sub<H|>;
    elif Type(G) eq GrpPC or Index(H, K) lt 1000000 then
        return quo<H|K>;
    else
        S := Subgroups(H : IndexEqual := #K);
        for X in S do
            if #(X`subgroup meet K) eq 1 then
                return X`subgroup;
            end if;
        end for;
    end if;
end function;

function CentQuo(H)
    return MyQuo(H, Center(H));
end function;

function FratQuo(H)
    return MyQuo(H, FrattiniSubgroup(H));
end function;

function FitQuo(H)
    return MyQuo(H, FittingSubgroup(H));
end function;

function RadQuo(H)
    if Type(H) eq GrpPerm then
        return RadicalQuotient(H);
    end if;
    return MyQuo(H, Radical(H));
end function;

function SocQuo(H)
    if Type(H) eq GrpPerm and #FittingSubgroup(H) eq 1 then
        return SocleQuotient(H);
    end if;
    return MyQuo(H, Socle(H));
end function;

N := Order(G);
solv := IsSolvable(G) select "t" else "f";
simp := IsSimple(G) select "t" else "f";
PrintFile("DATA/TExplore/" * nTt, Sprintf("%o|%o|%o|%o|%o|%o", Order(G), solv, simp, DerivedLength(G), Index(G, DerivedSubgroup(G)), Index(G, Center(G))));
Subs := {@ G @};
Const := [""];
StrToFunc := AssociativeArray();
StrToFunc["A"] := AutomorphismGroup; // We don't actually compute this yet because it often takes a long time
StrToFunc["D"] := DerivedSubgroup;
StrToFunc["Z"] := Center;
StrToFunc["ZQ"] := CentQuo;
StrToFunc["P"] := FrattiniSubgroup;
StrToFunc["PQ"] := FratQuo;
StrToFunc["F"] := FittingSubgroup;
StrToFunc["FQ"] := FitQuo;
StrToFunc["R"] := Radical;
StrToFunc["RQ"] := RadQuo;
StrToFunc["S"] := Socle;
StrToFunc["SQ"] := SocQuo;
i := 1;
while i le #Subs do
    H := Subs[i];
    constructions := ["D", "Z", "P", "F", "R", "S"];
    if i eq 1 or importance eq "1" and not ("-" in Const[i][2..#Const[i]]) then
        constructions cat:= ["ZQ", "PQ", "FQ", "RQ", "SQ"];
    end if;
    for const in constructions do
        F := StrToFunc[const];
        K := F(H);
        if not IsInSmallGroupDatabase(#K) or #K lt 2000 and #K ge 512 and Valuation(#K, 2) ge 7 then
            m := #Subs;
            Include(~Subs, K);
            if #Subs gt m then
                Append(~Const, Const[i] * "-" * const);
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
hashes := [];
timings := [];
for H in Subs[2..#Subs] do
    t0 := Cputime();
    hsh := hash(H);
    Append(~hashes, Sprintf("%o.%o", #H, hsh));
    Append(~timings, Sprint(Cputime() - t0));
end for;
PrintFile("DATA/TExplore/" * nTt, Join(hashes, "|"));
PrintFile("DATA/TExplore/" * nTt, Join(timings, "|"));
exit;
