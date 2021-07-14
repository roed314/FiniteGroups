/* turns G`label and output of LabelSubgroups into string */

function CreateLabel(Glabel, Hlabel);
    if #Hlabel gt 0 then
        return Glabel * "." * Join([Sprint(x) : x in Hlabel], ".");
    else // used for special subgroups where there is only a suffix
        return Glabel;
    end if;
end function;


intrinsic Subgroups(G::LMFDBGrp) -> SeqEnum
    {The list of subgroups computed for this group}
    t0 := Cputime();
    S := [];
    GG := G`MagmaGrp;
    function MakeSubgroups(SubLabels, GG, orig: suffixes := "")
        // SubLabels is a SeqEnum of triples (label, subgroup, index in orig)
        // orig may be a SubGrpLat or a SeqEnum of records
        S := [];
        if Type(suffixes) eq MonStgElt then
            suffixes := [suffixes : _ in SubLabels];
        end if;
        initial := (Type(suffixes) eq MonStgElt and suffixes eq "");
        if initial then
            // These counters allow us to determine the normal/maximal label as we iterate
            // normal subgroups have distinct Gassman classes, so just indexed by index
            normal_counter := AssociativeArray();
            // set of Gassman classes that have shown up in each index
            maximal_gclasses := AssociativeArray();
            // indexed by pairs, index and Gassman class
            maximal_counter := AssociativeArray();
        end if;
        if Type(orig) eq SubGrpLat then
            EltLabel := AssociativeArray();
            for tup in SubLabels do
                // no suffix, since we only use the subgroup lattice
                EltLabel[orig!(tup[3])] := CreateLabel(G`label, tup[1]);
            end for;
        end if;
        for i in [1..#SubLabels] do
            tup := SubLabels[i];
            suffix := suffixes[i];
            H := New(LMFDBSubGrp);
            H`Grp := G;
            H`MagmaAmbient := GG;
            H`MagmaSubGrp := tup[2];
            // we may eventually need to stop creating isomorphisms with the abstract subgroup, but for now we do it.
            H`standard_generators := true;
            if #suffix gt 0 then
                H`label := None();
                H`special_labels := [CreateLabel(G`label, tup[1]) * suffix];
            else
                H`label := CreateLabel(G`label, tup[1]);
                H`special_labels:=[];
            end if;
            if Type(orig) eq SubGrpLat then
                elt := orig!(tup[3]);
                top := orig!(#orig);
                H`count := Length(elt);
                H`contains := [EltLabel[j] : j in MaximalSubgroups(elt)];
                H`contained_in := [EltLabel[j] : j in MinimalOvergroups(elt)];
                H`normalizer := EltLabel[Normalizer(top, elt)];
                H`centralizer := EltLabel[Centralizer(top, elt)];
                // breadth first search on overgroups to find normal closure
                seen := {};
                current_layer := {elt};
                while not HasAttribute(H, "normal_closure") do
                    next_layer := {};
                    for cur in current_layer do
                        if Normalizer(top, cur) eq top then
                            H`normal_closure := EltLabel[cur];
                            break;
                        end if;
                        for next in MinimalOvergroups(cur) do
                            Include(~next_layer, next);
                        end for;
                    end for;
                    current_layer := next_layer;
                end while;
            else // SeqEnum of records
                H`count := orig[tup[3]]`length;
                H`contains := None();
                H`contained_in := None();
            end if;
            AssignBasicAttributes(H);
            if initial then
                n := tup[1][1]; // index
                /* Add normal and maximal label to special_labels */
                if H`normal then
                    if not IsDefined(normal_counter, n) then
                        normal_counter[n] := 0;
                    end if;
                    normal_counter[n] +:= 1;
                    nlabel := CreateLabel(G`label, [n, normal_counter[n], 1]) * ".N";
                    Append(~H`special_labels, nlabel);
	        end if;

                if H`maximal then
                    m := tup[1][2];
                    if not IsDefined(maximal_gclasses, n) then
                        maximal_gclasses[n] := {};
                    end if;
                    Include(~(maximal_gclasses[n]), m);
                    if not IsDefined(maximal_counter, <n, m>) then
                        maximal_counter[<n, m>] := 0;
                    end if;
                    maximal_counter[<n, m>] +:= 1;
                    mlabel := CreateLabel(G`label, [n, #maximal_gclasses[n], maximal_counter[<n, m>]]) * ".M";
                    Append(~H`special_labels, mlabel);
	        end if;
            end if;
            Append(~S, H);
        end for;
        return S;
    end function;
    max_index := G`subgroup_index_bound;
    if max_index ne 0 then
        ordbd := Get(G,"order") div max_index;
    end if;
    // Need to include the conjugacy class ordering
    lmfdbcc := ConjugacyClasses(G);
    vprint User1: "XXXXXXXXXX Conj computed", Cputime(t0);
    cccounters := [c`counter : c in lmfdbcc];
    ccreps := [c`representative : c in lmfdbcc];
    ParallelSort(~cccounters, ~ccreps);
    cm:=Get(G, "MagmaClassMap");
    perm := {};
    for j := 1 to #ccreps do
        res:=cm(ccreps[j]);
        Include(~perm, <res, j>);
    end for;
    sset := {j : j in cccounters};
    perm := map<sset->sset | perm>;
    newphi := cm*perm; // Magma does composition backwards!
    G`gens_used := []; // need to be present in order to save; overwritten in RePresentLat for solvable groups
    if G`subgroup_inclusions_known and max_index eq 0 then
        Orig := SubgroupLattice(GG : Centralizers := true, Normalizers := true);
        vprint User1: "XXXXXXXXXX Lat computed", Cputime(t0);
        // the following sets PresentationIso and GeneratorIndexes
        if IsSolvable(GG) then
            RePresentLat(G, Orig);
            vprint User1: "XXXXXXXXXX Represented lat", Cputime(t0);
        end if;
        G`SubGrpLat := Orig;
        RF := recformat< subgroup : Grp, order : Integers() >;
        Subs := [rec< RF | subgroup := Orig[i], order := Order(Orig!i) > : i in [1..#Orig]];
        SubLabels := LabelSubgroups(GG, Subs : phi:=newphi);
    else
        Orig := Subgroups(GG: IndexLimit:=max_index);
        vprint User1: "XXXXXXXXXX Subs computed", Cputime(t0);

        // the following sets PresentationIso and GeneratorIndexes
        if IsSolvable(GG) then
            RePresent(G);
            vprint User1: "XXXXXXXXXX Represented subs", Cputime(t0);
        end if;
        SubLabels:= LabelSubgroups(GG, Orig : phi:=newphi);
    end if;
    vprint User1: "XXXXXXXXXX Subgroups labelled", Cputime(t0);

    S := MakeSubgroups(SubLabels, GG, Orig);
    vprint User1: "XXXXXXXXXX Subgroups made", Cputime(t0);
    /* assign the normal beyond index bound */
    all_normal:=G`normal_subgroups_known;
    if max_index ne 0 and all_normal then /* some unlabeled */

        N := NormalSubgroups(GG);

        UnLabeled := [n : n in N | n`order lt ordbd];
        SubLabels := LabelSubgroups(GG, UnLabeled : phi:=newphi);
        S cat:= MakeSubgroups(SubLabels, GG, Orig : suffixes := ".N");
    end if;
    vprint User1: "XXXXXXXXXX Normals done", Cputime(t0);

    /* assign the maximal beyond index bound */
    all_maximal:=G`maximal_subgroups_known;
    if max_index ne 0 and all_maximal then /* some unlabeled */
        M := MaximalSubgroups(GG);

        UnLabeled := [m : m in M | m`order lt ordbd];
        SubLabels := LabelSubgroups(GG, UnLabeled);
        NewSubLabels := [];
        for tup in SubLabels do
            if all_normal and IsNormal(GG, tup[2]) then  /* need to match up to Normal special label */
                for i in [1..#S] do
                    H := S[i];
                    if not H`normal then continue; end if;
		    if tup[2] eq H`MagmaSubGrp then // normal, so can just use equality

                        mlabel := CreateLabel(G`label, tup[1]) * ".M";
		        Append(~H`special_labels, mlabel);
                        break;
                  end if;
	      end for;
          else
              Append(~NewSubLabels, tup);
           end if;
       end for;
       S cat:= MakeSubgroups(NewSubLabels, GG, Orig : suffixes := ".M");
    end if;
    vprint User1: "XXXXXXXXXX Maximals done", Cputime(t0);

    /* special groups labeled */
    Z := Center(GG);
    D := CommutatorSubgroup(GG);
    F := FittingSubgroup(GG);
    Ph := FrattiniSubgroup(GG);
    R := Radical(GG);
    So := Socle(G);  /* run special routine in case matrix group */

    // Add series
    Un := Reverse(UpperCentralSeries(GG));
    Ln := LowerCentralSeries(GG);
    Dn := DerivedSeries(GG);
    Cn := ChiefSeries(GG);
    SpecialGrps := [<Z,"Z">, <D,"D">, <F,"F">, <Ph,"Phi">, <R,"R">, <So,"S">, <Dn[#Dn],"PC">];
    Series := [<Un,"U">, <Ln,"L">, <Dn,"D">, <Cn,"C">];
    for tup in Series do
        for i in [1..#tup[1]] do
            H := tup[1][i];
            Append(~SpecialGrps, <H, tup[2]*Sprint(i-1)>);
        end for;
    end for;

    /* all of the special groups are normal */
    NewSubLabels := [];
    NewSuffixes := [];
    for tup in SpecialGrps do
        n := G`order div Order(tup[1]);
        found := false;
        // Check if we have the subgroup, and just need to add the special label
        for i in [1..#S] do
            H := S[i];
            if not H`normal then continue; end if;
            if tup[1] eq H`MagmaSubGrp then // normal, so can just use equality
                slabel := CreateLabel(G`label, [tup[2]]);
                Append(~H`special_labels, slabel);
                found := true;
                break;
            end if;
        end for;
        if not found then
            Append(~NewSubLabels, <[], tup[1], 1>);
            Append(~NewSuffixes, "."*tup[2]);
        end if;
    end for;
    vprint User1: "XXXXXXXXXX Specials done", Cputime(t0);
    S cat:= MakeSubgroups(NewSubLabels, GG, Orig : suffixes := NewSuffixes);

    return S;
end intrinsic;

intrinsic NormalSubgroups(G::LMFDBGrp) -> Any
    {List of normal LMFDBSubGrps, or None if not computed}
    if not G`normal_subgroups_known then
        return None();
    end if;
    return [H : H in Get(G, "Subgroups") | H`normal];
end intrinsic;

intrinsic LowIndexSubgroups(G::LMFDBGrp, d::RngIntElt) -> SeqEnum
    {List of low index LMFDBSubGrps, or None if not computed}
    m := G`subgroup_index_bound;
    if d eq 0 then
        if m eq 0 then
            return Get(G, "Subgroups");
        else
            return None();
        end if;
    end if;
    if m eq 0 or d le m then
        LIS := [];
        ordbd := Get(G, "order") div d;
        for H in Get(G, "Subgroups") do
            if Get(H, "subgroup_order") gt ordbd then
                Append(~LIS, H);
            end if;
        end for;
        return LIS;
    else;
        return None();
    end if;
end intrinsic;

intrinsic LookupSubgroupLabel(G::LMFDBGrp, HH::Any) -> Any
    {Find a subgroup label for H, or return None if H is not labeled}
    if Type(HH) eq MonStgElt then
        // already labeled
        return HH;
    else
        S := Get(G, "Subgroups");
        GG := Get(G, "MagmaGrp");
        for K in S do
            KK := Get(K, "MagmaSubGrp");
            if IsConjugate(GG, HH, KK) then
                v := Get(K, "label");
                if Type(v) eq NoneType then
                    v := Get(K, "special_label")[1];
                end if;
                return v;
            end if;
        end for;
        return None();
    end if;
end intrinsic;

intrinsic LookupSubgroup(G::LMFDBGrp, label::MonStgElt) -> Grp
{Find a subgroup with a given label}
    S := Get(G, "Subgroups");
    for K in S do
        if label eq Get(K, "label") or label in Get(K, "special_labels") then
            return Get(K, "MagmaSubGrp");
        end if;
    end for;
    error Sprintf("Subgroup with label %o not found", label);
end intrinsic;
