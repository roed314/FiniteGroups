// Add groups of lie type up to certain bounds
// We skip GL2 (since this was handled elsewhere, including subgroups), and skip the first few Sp4 and GSp4 (subgroups were added up to 11)
// Usage: magma -b outfolder:=/data/ lie.m

SetColumns(0);
AttachSpec("hashspec");

LPairs := [<3, 16>, <4, 8>, <5, 5>, <6, 3>, <7, 3>];
PLPairs := [<2, 32>, <3, 16>, <4, 8>, <5, 5>, <6, 3>, <7, 3>];
UPairs := [<2, 32>, <3, 16>, <4, 8>, <5, 4>, <6, 3>, <7, 2>]; // CompFac <5,5>, <7,3>
APairs := [<2, 16>, <3, 8>, <4, 5>, <5, 3>, <6, 3>];
SpPairs := [<4, 16>, <6, 5>, <8, 3>]; // CompFac <6,7> and <6,8>
O1Pairs := [<3, 32>, <5, 16>, <7, 3>];
O0Pairs := [<4, 16>, <6, 8>, <8, 3>];


// Format: family, list of pairs d, qhigh
classical := [<GL, "GL", LPairs>,
              <SL, "SL", LPairs>,
              <CU, "CU", UPairs>,
              <GU, "GU", UPairs>,
              <SU, "SU", UPairs>,
              <CSU, "CSU", UPairs>,
              <CSp, "GSp", SpPairs>,
              <Sp, "Sp", SpPairs>,
              <CO, "CO", O1Pairs>,
              <GO, "GO", [<3, 23>, <5, 8>, <7, 3>]>, // <3, 25>, <3,27>, <5,9> fail; would have liked to go to <3, 32>, <5, 16>
              <SO, "SO", O1Pairs>,
              <CSO, "CSO", O1Pairs>,
              <COPlus, "CO+", [<2, 32>] cat O0Pairs>,
              <GOPlus, "GO+", [<4, 8>, <6, 8>]>, // GO+(2, q) is D_{q-1}; <4,9> and <8,3> fail (would have liked to go to <4,16>)
              <SOPlus, "SO+", O0Pairs>, // SO+(2, q) is C_{q-1}
              <CSOPlus, "CSO+", [<2, 997>] cat O0Pairs>,
              <COMinus, "CO-", [<2, 32>] cat O0Pairs>,
              <GOMinus, "GO-", [<4, 8>, <6, 8>]>, // GO-(2, q) is D_{q+1}; <4,9> and <8,3> fail (would have liked to go to <4,16>)
              <SOMinus, "SO-", O0Pairs>, // SO-(2, q) is C_{q+1}
              <CSOMinus, "CSO-", [<2, 997>] cat O0Pairs>,
              <Omega, "Omega", O1Pairs>,
              <OmegaPlus, "Omega+", O0Pairs>,
              <OmegaMinus, "Omega-", O0Pairs>,
              <Spin, "Spin", [<5, 16>, <7, 3>]>, // Spin(3, -) errors
              <SpinPlus, "Spin+", O0Pairs>,
              <SpinMinus, "Spin-", O0Pairs>];

classical_perm := [<PGL, "PGL", PLPairs>, // PGL(7,3) has degree 1093
                   <PSL, "PSL", PLPairs>, // should all be simple
                   <PGammaL, "PGammaL", PLPairs>, // same degrees as PGL and PSL; only differs from PGL for non-primes
                   <PSigmaL, "PSigmaL", PLPairs>, // same degrees as PGL and PSL; only differs from PSL for non-primes
                   <AGL, "AGL", [<1, 43>] cat APairs>, // AGL(6, 3) has degree 729
                   <ASL, "ASL", APairs>, // ASL(6, 3) has degree 729
                   <AGammaL, "AGammaL", [<1, 43>] cat APairs>,
                   <ASigmaL, "ASigmaL", [<1, 43>] cat APairs>,
                   <ASp, "ASp", SpPairs>, // These all have large degree: ASp(4,16) has degree 65536
                   <ASigmaSp, "ASigmaSp", SpPairs>, // Same large degrees as ASp
                   <PGU, "PGU", UPairs>, // Degree PGU(4,8) is 33345
                   <PSU, "PSU", UPairs>, // same degrees
                   <PGammaU, "PGammaU", UPairs>, // same degrees
                   <PSp, "PSp", SpPairs>, // Degree PSp(4, 16) is 4369
                   <PSigmaSp, "PSigmaSp", SpPairs>, // Degree PSp(4, 16) is 4369
                   <PGO, "PGO", O1Pairs>, // Degree PGO(5, 16) is 4369
                   <PGOPlus, "PGO+", O0Pairs>, // Degree PGO+(6,8) is 4745
                   <PGOMinus, "PGO-", O0Pairs>, // Degree PGO-(6,8) is 4617
                   <PSO, "PSO", O1Pairs>, // Degree PSO(5, 16) is 4369
                   <PSOPlus, "PSO+", O0Pairs>, // Degree PGO+(6,8) is 4745
                   <PSOMinus, "PSO-", O0Pairs>, // Degree PSO+(6,8) is 4617
                   <POmega, "POmega", O1Pairs>,
                   <POmegaPlus, "POmega+", O0Pairs>,
                   <POmegaMinus, "POmega-", O0Pairs>];

smallfile := outfolder * "SmallMedLie.txt";
med := [];
meddata := [];
bigfile := outfolder * "BigLie.txt";
bigin := outfolder * "BigLie.in"; // input for hashing script
biglies := {};
for idat in classical cat classical_perm do
    func := idat[1];
    name := idat[2];
    for pair in idat[3] do
        d := pair[1];
        for q in [2..pair[2]] do
            if IsPrimePower(q) then
                print name, d, q;
                G := func(d, q);
                if CanIdentifyGroup(#G) then
                    gid := IdentifyGroup(G);
                    PrintFile(smallfile, Sprintf("%o(%o,%o) %o.%o", name, d, q, gid[1], gid[2]));
                elif #G in [512, 1152, 1536, 1920] then
                    Append(~med, G);
                    Append(~meddata, Sprintf("%o(%o,%o)", name, d, q));
                else
                    s := GroupToString(G);
                    PrintFile(bigfile, Sprintf("%o(%o,%o) %o", name, d, q, s));
                    Include(~biglies, s);
                end if;
            end if;
        end for;
    end for;
end for;
/*
for idat in semiclassical do
    func := idat[1];
    name := idat[2];
    for q in idat[3] do
        G := func(q);
        if CanIdentifyGroup(#G) then
            gid := IdentifyGroup(G);
            PrintFile(smallfile, Sprintf("%o(%o) %o.%o", name, q, gid[1], gid[2]));
        elif #G in [512, 1152, 1536, 1920] then
            Append(~med, G);
            Append(~meddata, Sprintf("%o(%o)", name, q));
        else
            PrintFile(bigfile, Sprintf("%o(%o) %o", name, q, GroupToString(G)));
        end if;
    end for;
end for;
*/
medid := IdentifyGroups(med);
for i in [1..#med] do
    PrintFile(smallfile, Sprintf("%o %o.%o", meddata[i], medid[i][1], medid[i][2]));
end for;
for s in biglies do
    PrintFile(bigin, s);
end for;
exit;
