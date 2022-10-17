// Add groups of lie type up to certain bounds
// We skip GL2 (since this was handled elsewhere, including subgroups), and skip the first few Sp4 and GSp4 (subgroups were added up to 11)
// Usage: magma -b lie.m

SetColumns(0);
AttachSpec("hashspec");

LPairs := [<2, 2719>, <3, 19>, <4, 8>, <5, 5>, <6, 3>, <7, 3>];
PLPairs := [<2, 2719>, <3, 19>, <4, 8>, <5, 5>, <6, 3>, <7, 3>];
UPairs := [<2, 32>, <3, 19>, <4, 7>, <5, 4>, <6, 3>, <7, 2>, <8, 2>]; // CompFac <5,5>, <7,3>
APairs := [<2, 19>, <3, 8>, <4, 5>, <5, 3>, <6, 3>];
SpPairs := [<4, 19>, <6, 5>, <8, 3>, <10, 2>]; // CompFac <6,7> and <6,8>, we have Sp(4,2/3/5) elsewhere
ASpPairs := [<4, 5>, <6, 3>, <8, 2>];
O1Pairs := [<3, 32>, <5, 16>, <7, 3>, <9, 3>];
O0Pairs := [<4, 16>, <6, 8>, <8, 3>, <10, 2>];

// Format: family, list of pairs <d, qhigh>
// Earlier entries will take priority when there are exceptional isomorphisms
classical := [<GL, "GL", LPairs>,
              <SL, "SL", LPairs>,
              <Sp, "Sp", SpPairs>,
              <SO, "SO", O1Pairs>,
              <SOPlus, "SOPlus", O0Pairs>, // SO+(2, q) is C_{q-1}
              <SOMinus, "SOMinus", O0Pairs>, // SO-(2, q) is C_{q+1}
              <SU, "SU", UPairs>,
              <GO, "GO", [<3, 23>, <5, 8>, <7, 3>, <9,3>]>, // <3, 25>, <3,27>, <5,9> fail; would have liked to go to <3, 32>, <5, 16>
              <GOPlus, "GOPlus", [<4, 8>, <6, 8>]>, // GO+(2, q) is D_{q-1}; <4,9> and <8,3> fail (would have liked to go to <4,16>)
              <GOMinus, "GOMinus", [<4, 8>, <6, 8>]>, // GO-(2, q) is D_{q+1}; <4,9> and <8,3> fail (would have liked to go to <4,16>)
              <GU, "GU", UPairs>,
              <CSp, "CSp", SpPairs>,
              <CSO, "CSO", O1Pairs>,
              <CSOPlus, "CSOPlus", [<2, 997>] cat O0Pairs>,
              <CSOMinus, "CSOMinus", [<2, 997>] cat O0Pairs>,
              <CSU, "CSU", UPairs>,
              <CO, "CO", O1Pairs>,
              <COPlus, "COPlus", [<2, 32>] cat O0Pairs>,
              <COMinus, "COMinus", [<2, 32>] cat O0Pairs>,
              <CU, "CU", UPairs>,
              <Omega, "Omega", O1Pairs>,
              <OmegaPlus, "OmegaPlus", O0Pairs>,
              <OmegaMinus, "OmegaMinus", O0Pairs>,
              <Spin, "Spin", [<5, 16>, <7, 3>]>, // Spin(3, -) errors
              <SpinPlus, "SpinPlus", O0Pairs>,
              <SpinMinus, "SpinMinus", O0Pairs>
              ];

classical_perm := [<PSL, "PSL", PLPairs>, // should all be simple
                   <PGL, "PGL", PLPairs>, // PGL(7,3) has degree 1093
                   <PSp, "PSp", SpPairs>, // Degree PSp(4, 16) is 4369
                   <PSO, "PSO", O1Pairs>, // Degree PSO(5, 16) is 4369
                   <PSOPlus, "PSOPlus", O0Pairs>, // Degree PGO+(6,8) is 4745
                   <PSOMinus, "PSOMinus", O0Pairs>, // Degree PSO+(6,8) is 4617
                   <PSU, "PSU", UPairs>, // Degree PSU(4,8) is 33345
                   <PGO, "PGO", O1Pairs>, // Degree PGO(5, 16) is 4369
                   <PGOPlus, "PGOPlus", O0Pairs>, // Degree PGO+(6,8) is 4745
                   <PGOMinus, "PGOMinus", O0Pairs>, // Degree PGO-(6,8) is 4617
                   <PGU, "PGU", UPairs>, // Degree PGU(4,8) is 33345
                   <POmega, "POmega", O1Pairs>,
                   <POmegaPlus, "POmegaPlus", O0Pairs>,
                   <POmegaMinus, "POmegaMinus", O0Pairs>,
                   <PGammaL, "PGammaL", PLPairs>, // same degrees as PGL and PSL; only differs from PGL for non-primes
                   <PSigmaL, "PSigmaL", PLPairs>, // same degrees as PGL and PSL; only differs from PSL for non-primes
                   <PSigmaSp, "PSigmaSp", SpPairs>, // Degree PSp(4, 16) is 4369
                   <PGammaU, "PGammaU", UPairs>, // same degrees as PGU
                   <AGL, "AGL", [<1, 43>] cat APairs>, // AGL(6, 3) has degree 729
                   <ASL, "ASL", APairs>, // ASL(6, 3) has degree 729
                   <ASp, "ASp", ASpPairs>, // These all have large degree: ASp(4,16) has degree 65536
                   <AGammaL, "AGammaL", [<1, 43>] cat APairs>,
                   <ASigmaL, "ASigmaL", [<1, 43>] cat APairs>,
                   <ASigmaSp, "ASigmaSp", ASpPairs> // Same large degrees as ASp
                   ];

chevalley := ["ChevE,6,2", "ChevE,7,2", "ChevF,4,2", "ChevG,2,2", "ChevG,2,3", "ChevG,2,4", "ChevG,2,5", "Chev2B,2,2", "Chev2B,2,8", "Chev2B,2,32", "Chev3D,4,2", "Chev2E,6,2", "Chev2F,4,2", "Chev2F,4,2-D", "Chev2G,2,3", "Chev2G,2,27"]; // CompFac Chev3D,4,3
sporadic := ["J1", "J2", "HS", "J3", "McL", "He", "Ru", "Co3", "Co2"]; // Can't compute order of Co1...
// the Mathieu groups are in the transitive database
// Could also include (in increasing order of ugliness) Suz, F22, Ly, J4, HN, ON, Th, E(8,2), Fi23; Fi24, B and M aren't really reasonable

tinyfile := "DATA/TinyLie.txt";
smallmedfile := "DATA/SmallMedLie.txt";
aliasfile := "DATA/LieAliases.txt";
gensfile := "DATA/LieGens.txt";
med := [];
meddata := [];
medperm := [];
medpermdata := [];
bigfile := "DATA/BigLie.txt"; // input for hashing script
sizes := AssociativeArray();
// Fill in missing orders from the groups that we've skipped
sizes["GO(3,25)"] := #GO(3,25);
sizes["GO(3,27)"] := #GO(3,27);
sizes["GO(3,29)"] := #GO(3,29);
sizes["GO(3,31)"] := #GO(3,31);
sizes["GO(3,32)"] := #GO(3,32);
sizes["GO(5,9)"] := #GO(5,9);
sizes["GO(5,11)"] := #GO(5,11);
sizes["GO(5,13)"] := #GO(5,13);
sizes["GO(5,16)"] := #GO(5,16);
sizes["GOPlus(4,9)"] := #GOPlus(4,9);
sizes["GOPlus(4,11)"] := #GOPlus(4,11);
sizes["GOPlus(4,13)"] := #GOPlus(4,13);
sizes["GOPlus(4,16)"] := #GOPlus(4,16);
sizes["GOPlus(8,2)"] := #GOPlus(8,2);
sizes["GOPlus(8,3)"] := #GOPlus(8,3);
sizes["GOPlus(10,2)"] := #GOPlus(10,2);
sizes["GOMinus(4,9)"] := #GOMinus(4,9);
sizes["GOMinus(4,11)"] := #GOMinus(4,11);
sizes["GOMinus(4,13)"] := #GOMinus(4,13);
sizes["GOMinus(4,16)"] := #GOMinus(4,16);
sizes["GOMinus(8,2)"] := #GOMinus(8,2);
sizes["GOMinus(8,3)"] := #GOMinus(8,3);
sizes["GOMinus(10,2)"] := #GOMinus(10,2);
descriptions := AssociativeArray();
groups := [* *];
for idat in classical cat classical_perm do
    func := idat[1];
    name := idat[2];
    for pair in idat[3] do
        d := pair[1];
        for q in [2..pair[2]] do
            if IsPrimePower(q) then
                fullname := Sprintf("%o(%o,%o)", name, d, q);
                print "Const", fullname;
                // Ugh, Magma doesn't support GrpMat for ASp, AGL(1,q)
                if name[1] eq "A" and not (name eq "AGL" and d eq 1 or name eq "ASp") then
                    G := func(GrpMat, d, q);
                else
                    G := func(d, q);
                end if;
                if name[1] eq "P" then
                    if "amma" in name or "igma" in name then
                        lift := name[2] * name[#name];
                    else
                        lift := name[2..#name];
                    end if;
                    lift := eval lift;
                    lift := lift(d, q);
                else
                    lift := G;
                end if;
                Append(~groups, <fullname, G, lift>);
            end if;
        end for;
    end for;
end for;
for desc in chevalley cat sporadic do
    print "Const", desc;
    G := StringToGroup(desc);
    Append(~groups, <desc, G, G>);
end for;
for trip in groups do
    fullname := trip[1];
    G := trip[2];
    LG := trip[3];
    print fullname;
    sizes[fullname] := #G;
    PrintFile(gensfile, Sprintf("%o %o", fullname, GroupToString(LG : use_id:=false)));
    if CanIdentifyGroup(#G) then
        gid := IdentifyGroup(G);
        gid := Sprintf("%o.%o", gid[1], gid[2]);
        PrintFile(aliasfile,  Sprintf("%o %o", fullname, gid));
        if #G gt 2000 or #G gt 500 and Valuation(#G,2) gt 6 then
            PrintFile(smallmedfile, gid);
        else
            // The Lie descriptions for tiny groups were skipped in the original run
            PrintFile(tinyfile, Sprintf("%o %o", gid, fullname));
        end if;
/*    elif #G in [512, 1152, 1536, 1920] then
        if Type(G) eq GrpPerm then
            Append(~medperm, G);
            Append(~medpermdata, fullname);
        else
            Append(~med, G);
            Append(~meddata, fullname);
        end if;
    else
        liftname := fullname[2..#fullname];
        if fullname[1] eq "P" and IsDefined(sizes, liftname) and #G eq sizes[liftname] then
            PrintFile(aliasfile, Sprintf("%o %o", fullname, liftname));
            continue;
        end if;
        s := GroupToString(G);
        if IsDefined(descriptions, s) then
            PrintFile(aliasfile, Sprintf("%o %o", fullname, descriptions[s]));
            continue;
        end if;
        descriptions[s] := fullname;
        PrintFile(bigfile, fullname);*/
    end if;
end for;
/*medid := IdentifyGroups(med);
for i in [1..#med] do
    label := Sprintf("%o.%o", medid[i][1], medid[i][2]);
    PrintFile(aliasfile, Sprintf("%o %o", meddata[i], label)
    PrintFile(smallmedfile, label);
end for;
medid := IdentifyGroups(medperm);
for i in [1..#medperm] do
    label := Sprintf("%o.%o", medid[i][1], medid[i][2]);
    PrintFile(aliasfile, Sprintf("%o %o", medpermdata[i], label)
    PrintFile(smallmedfile, label);
end for;*/
exit;
