// cat DATA/hash/tseptest.txt | parallel -j180 --timeout 7200 --colsep ' ' magma OrdHash:="{1}" method:="{2}" TCluster4.m

AttachSpec("hashspec");
SetColumns(0);

print OrdHash, method;
//ofile_exists, ofile := OpenTest("DATA/hash/tsepout/" * OrdHash, "r");
//if ofile_exists then
//    print "Already complete; exiting";
//    exit;
//end if;

function Syls(G)
    return [SylowSubgroup(G, p) : p in PrimeDivisors(Order(G))];
end function;
function NSyls(G)
    return [Normalizer(G, SylowSubgroup(G, p)) : p in PrimeDivisors(Order(G))];
end function;
function AutOrd(G)
    return Order(AutomorphismGroup(G));
end function;
/*
// Centers of transitive groups are usually very small, so this doesn't help enough to justify the complexity.
function Zact(G)
    Z := Center(G);
    if #Z eq #G or #Z le 2
        return [];
    end if;
    A := AutomorphismGroup(Z);
    Q, Qproj := quo<G | Z>;
    f := hom<Q -> A | [<q, hom<Z -> Z | [<z, z^(q@@Qproj)> : z in Generators(Z)]>> : q in Generators(Q)]>;
    return [* Kernel(f), Image(f) *];
end function;
*/

smethods := AssociativeArray();
smethods["frat"] := FrattiniSubgroup;
smethods["fit"] := FittingSubgroup;
smethods["rad"] := Radical;
smethods["soc"] := Socle;
smethods["cent"] := Center;
lmethods := AssociativeArray();
lmethods["syl"] := Syls;
lmethods["nsyl"] := NSyls;
lmethods["derS"] := DerivedSeries;
lmethods["centL"] := LowerCentralSeries;
lmethods["centU"] := UpperCentralSeries;
lmethods["minN"] := MinimalNormalSubgroups;
nmethods := AssociativeArray();
nmethods["degs"] := CharacterDegrees;
nmethods["aut"] := AutOrd;

order, hsh := Explode(Split(OrdHash, "."));
file_exists, ifile := OpenTest("DATA/hash/tsepout/" * OrdHash, "r"); // NOTE tsepout!
groups := [];
//lines := [];
for s in Split(Read(ifile)) do
    //Append(~lines, s);
    n, t := Explode([StringToInteger(c) : c in Split(Split(s, " ")[1], "T")]);
    Append(~groups, TransitiveGroup(n, t));
end for;

t0 := Cputime();
H := [];
Q := [];
Ts := [];
if IsDefined(smethods, method) then
    S := [smethods[method](G) : G in groups];
    Append(~Ts, Cputime() - t0);
    t0 := Cputime();
    for i in [1..#groups] do
        G := groups[i];
        K := S[i];
        if #G eq #K then
            Append(~H, -1);
            Append(~Q, -1);
            Append(~Ts, 0);
            Append(~Ts, 0);
            continue;
        end if;
        hsh := hash(K);
        Append(~H, hsh);
        Append(~Ts, Cputime() - t0);
        t0 := Cputime();
        if Index(G, K) le 10000 then
            hsh := hash(quo<G | K>);
        else
            hsh := -3;
        end if;
        Append(~Q, hsh);
        Append(~Ts, Cputime() - t0);
        t0 := Cputime();
    end for;
    success := (#{x : x in H} gt 1) or (#{x : x in Q} gt 1);
elif IsDefined(lmethods, method) then
    S := [lmethods[method](G) : G in groups];
    Append(~Ts, Cputime() - t0);
    t0 := Cputime();
    if (#{#series : series in S} gt 1) then
        success := true;
        H := [#series : series in S];
        Q := [];
    else
        for i in [1..#groups] do
            G := groups[i];
            Append(~H, []);
            Append(~Q, []);
            for j in [1..#S[1]] do
                K := S[i][j];
                if #G eq #K then
                    Append(~H[#H], -1);
                    Append(~Q[#Q], -1);
                    Append(~Ts, 0);
                    Append(~Ts, 0);
                    continue;
                end if;
                hsh := hash(K);
                Append(~H[#H], hsh);
                Append(~Ts, Cputime() - t0);
                t0 := Cputime();
                if IsNormal(G, K) then
                    if Index(G, K) le 10000 then
                        hsh := hash(quo<G | K>);
                    else
                        hsh := -3;
                    end if;
                else
                    hsh := -2;
                end if;
                Append(~Q[#Q], hsh);
                Append(~Ts, Cputime() - t0);
                t0 := Cputime();
            end for;
        end for;
        success := (#{x : x in H} gt 1) or (#{x : x in Q} gt 1);
    end if;
elif IsDefined(nmethods, method) then
    S := [nmethods[method](G) : G in groups];
    Append(~Ts, Cputime() - t0);
    success := #{x : x in S} gt 1;
end if;

if success then
    fname := Sprintf("DATA/hash/niso_succ/%o_%o", OrdHash, method);
else
    fname := Sprintf("DATA/hash/niso_fail/%o_%o", OrdHash, method);
end if;
PrintFile(fname, Sprintf("%o\n%o\n%o\n", H, Q, Ts));
