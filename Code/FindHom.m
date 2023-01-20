// USAGE: ls DATA/hom.todo | parallel -j80 --timeout 600 magma -b label:={1} FindHom.m
// Finds a homomorphism to fill out a GroupHom description

// Produces invalid 156250pc8,5,5,5,5,5,2,5,5,40,67203,187,210005,37229,141,490006,16830,334--193368864,107195009,70636971,158515736,95706374,138908171,2350076,177900106-->2,125Mat76,0,0,1,16,0,0,1,101,0,0,101,76,50,25,1,124,0,0,124,26,100,25,51,1,0,110,16,6,15,65,21

AttachSpec("spec");
SetColumns(0);
infile := "DATA/hom.todo/" * label;
outfile := "DATA/homs/" * label;
desc := Read(infile);
while desc[#desc] eq "\n" do
    desc := desc[1..#desc-1];
end while;
fdesc := "";
if "(" in desc and desc[1] eq "P" then
    fdesc := PStringToHomString(desc);
elif "---->" in desc then
    GG, HH := Explode(PySplit(desc, "---->"));
    G := StringToGroup(GG);
    H := StringToGroup(HH);
    assert #G eq #H;

    // Option 1: just brute force it with IsIsomorphic
    ok, f := IsIsomorphic(G, H); // this was failing

    // Option 2: Find all core-free subgroups and use CosetAction and IsConjugate
    //SG := Subgroups(G);
    //SH := Subgroups(H);
    //assert #SG eq #SH;
    //CG := [X`subgroup : X in SG | #Core(G, X`subgroup) eq 1];
    //CH := [X`subgroup : X in SH | #Core(H, X`subgroup) eq 1];
    //assert #CG eq #CH;
    //mG := Max([#X : X in CG]); // May be better to choose another order rather than the maximum, if there are fewer conjugacy classes of subgroups of that order.  Extreme case would be regular representation.
    //m := Max([#X : X in CH]);
    //assert m eq mG;
    //CG := [X : X in CG | #X eq mG];
    //CH := [X : X in CH | #X eq m];
    //assert #CG eq #CH;
    //Sn := Sym(#G div m);
    //A := CG[1];
    //rhoA := CosetAction(G, A);
    //PA := Image(rhoA);
    //ok := false;
    //for i in [1..#CH] do
    //    B := CH[i];
    //    rhoB := CosetAction(H, B);
    //    PB := Image(rhoB);
    //    ok, c := IsConjugate(Sn, PA, PB);
    //    if ok then
    //        break;
    //    end if;
    //end for;
    //assert ok;
    //f := hom<G -> H | [g -> ((g @ rhoA)^c) @@ rhoB : g in Generators(G)]>;

    // Option 3: Use stored information from minreps and pcreps
    /*
    ok := OpenTest("DATA/minreps/" * label, "r");
    permrep := "";
    if ok then
        permrep := Split(Read("DATA/minreps/" * label), "\n")[1];
    else
        error Sprintf("No minimal degree permutation rep found for %o", label);
    end if;
    odesc, deg, perm_gens := Explode(Split(permrep, "|"));
    if odesc ne HH then
        error Sprintf("Description mismatch for %o", label);
    end if;
    PP := Sprintf("%oPerm%o", deg, perm_gens[2..#perm_gens-1]);
    if PP eq GG then
        // The generators match
        f := hom<G -> H | [G.i -> H.i : i in [1..Ngens(G)]]>;
    elif "pc" in GG  or "PC" in GG then
        P := StringToGroup(PP);
        if Ngens(H) ne Ngens(P) then
            error Sprintf("Cannot match matrix and permutation representations for %o", label);
        end if;
        fHP := hom<H -> P | [H.i -> P.i : i in [1..Ngens(H)]]>;
        d := StringToInteger(deg);
        ok := OpenTest("DATA/pcreps/" * label, "r");
        pcrep := "";
        if ok then
            pcrep := Split(Read("DATA/pcreps/" * label), "\n")[1];
        else
            ok := OpenTest("DATA/pcrep_fastest/" * label, "r");
            if ok then
                pcrep := Split(Read("DATA/pcrep_fastest/" * label), "\n")[1];
            else
                error Sprintf("No stored pc representation found for %o", label);
            end if;
        end if;
        barcount := #[i : i in [1..#pcrep] | pcrep[i] eq "|"];
        if barcount eq 3 then
            pc_code, gens_used, compact, perms := Explode(Split(pcrep, "|"));
        elif barcount eq 4 then
            olabel, pc_code, gens_used, compact, perms := Explode(Split(pcrep, "|"));
        else
            error Sprintf("Ill formated pc represetation for %o", label);
        end if;
        if not GG in [Sprintf("%opc%o", #G, compact), Sprintf("%oPC%o", #G, pc_code)] then
            error Sprintf("Mismatched pc representation for %o", label);
        end if;
        Ggens := [g : g in PCGenerators(G)];
        perms := Split(perms, ",");
        gens_used := [StringToInteger(c) : c in Split(gens_used, ",")];
        assert #perms eq #gens_used;
        fGP := hom<G -> P | [Ggens[gens_used[i]] -> DecodePerm(StringToInteger(perms[i]), d) : i in [1..#perms]]>;
        fGH := fGP * Inverse(fHP);
        // Formal composites aren't very functional
        f := hom<G -> H | [Ggens[i] -> fGH(Ggens[i]) : i in [1..#Ggens]]>;
        assert #Kernel(f) eq 1;
        */
    end if;
    fdesc := GroupHomToString(f : GG:=GG, HH:=HH);
else
    error Sprintf("Unrecognized homomorphism specification for %o", label);
end if;
PrintFile(outfile, fdesc);
exit;
