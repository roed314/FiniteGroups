// Add groups of lie type up to certain bounds
// We skip GL2 (since this was handled elsewhere, including subgroups), and skip the first few Sp4 and GSp4 (subgroups were added up to 11)
// Usage: magma -b outfolder:=/data/ lie.m

SetColumns(0);
AttachSpec("hashspec");

// Format: family, list of pairs d, qhigh
classical := [<GL, "GL", [<3, 16>, <4, 8>, <5, 5>, <6, 3>, <7, 3>]>,
              <SL, "SL", [<3, 16>, <4, 8>, <5, 5>, <6, 3>, <7, 3>]>,
              <PGL, "PGL", [<2, 32>, <3, 16>, <4, 8>, <5, 5>, <6, 3>]>, // PGL(7,3) has degree 1093
              <AGL, "AGL", [<1, 43>, <2, 16>, <3, 8>, <4, 5>, <5, 3>]>, // AGL(6, 3) has degree 729
              <ASL, "ASL", [<2, 16>, <3, 8>, <4, 5>, <5, 3>]>, // ASL(6, 3) has degree 729
              <CU, "CU", [<2, 32>, <3, 16>, <4, 7>, <5, 4>, <6, 2>, <7, 2>]>, // <4,8>, <5,5>, <6,3> and <7,3> fail
              <GU, "GU", [<2, 32>, <3, 16>, <4, 8>, <5, 4>, <6, 2>, <7, 2>]>, // CompFac <5,5>, <6,3> and <7,3> fail
              <SU, "SU", [<2, 32>, <3, 16>, <4, 8>, <5, 5>, <6, 3>, <7, 3>]>,
              <CSU, "CSU", [<2, 32>, <3, 16>, <4, 8>, <5, 4>, <6, 2>, <7, 2>]>, // CompFac for <5,5>, <7,3>; error for <6,3>
              <CSp, "GSp", [<4, 16>, <6, 5>, <8, 3>]>, // CompFac for <6,7> and <6,8>
              <Sp, "Sp", [<4, 16>, <6, 5>, <8, 3>]>, // <6,7> and <6,7> fail
              <CO, "CO", [<3, 32>, <5, 16>, <7, 3>]>,
              <GO, "GO", [<3, 23>, <5, 8>, <7, 3>]>, // <3, 25>, <3,27>, <5,9> fail; would have liked to go to <3, 32>, <5, 16>
              <SO, "SO", [<3, 32>, <5, 16>, <7, 3>]>,
              <CSO, "CSO", [<3, 32>, <5, 16>, <7, 3>]>,
              <COPlus, "CO+", [<2, 32>, <4, 16>, <6, 8>, <8, 3>]>,
              <GOPlus, "GO+", [<4, 8>, <6, 8>]>, // GO+(2, q) is D_{q-1}; <4,9> fails (would have liked to go to <4,16>)
              <SOPlus, "SO+", [<4, 16>, <6, 8>]>, // SO+(2, q) is C_{q-1}
              <CSOPlus, "CSO+", [<2, 997>, <4, 16>, <6, 8>]>,
              <COMinus, "CO-", [<2, 32>, <4, 16>, <6, 8>, <8, 3>]>,
              <GOMinus, "GO-", [<4, 16>, <6, 8>]>, // GO-(2, q) is D_{q+1}; <4,9> fails (would have liked to go to <4,16>)
              <SOMinus, "SO-", [<4, 16>, <6, 8>]>, // SO-(2, q) is C_{q+1}
              <CSOMinus, "CSO-", [<2, 997>, <4, 16>, <6, 8>]>,
              <Omega, "Omega", [<3, 32>, <5, 16>, <7, 3>]>,
              <OmegaPlus, "Omega+", [<4, 16>, <6, 8>]>,
              <OmegaMinus, "Omega-", [<4, 16>, <6, 8>]>,
              <Spin, "Spin", [<5, 16>, <7, 3>]>,
              <SpinPlus, "Spin+", [<4, 16>, <6, 8>]>,
              <SpinMinus, "Spin-", [<4, 16>, <6, 8>]>];

semiclassical := [<SuzukiGroup, "Suz", [2, 8, 32]>]; // CompFac for 128, 512
                  //<ReeGroup, "Ree", [27, 243, 2187]>, all fail
                  //<LargeReeGroup, "Ree", [8]>]; all fail

smallfile := outfolder * "SmallMedLie.txt";
med := [];
meddata := [];
bigfile := outfolder * "BigLie.txt";
for idat in classical do
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
                    PrintFile(bigfile, Sprintf("%o(%o,%o) %o", name, d, q, GroupToString(G)));
                end if;
            end if;
        end for;
    end for;
end for;
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
medid := IdentifyGroups(med);
for i in [1..#med] do
    PrintFile(smallfile, Sprintf("%o %o.%o", meddata[i], medid[i][1], medid[i][2]));
end for;
exit;
