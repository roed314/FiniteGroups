// Run a test on the group 1701.307 to check if subgroup labeling is deterministic

SetColumns(0);
AttachSpec("spec");
label := "1701.307";
desc := Read("DATA/descriptions/"*label);
G := MakeBigGroup(desc, label : preload:=true);
//SetVerbose("User1",true);
G`UseSolvAut := true;
S := Get(G, "Subgroups");
reps := Join([Sprint(SaveElt(Get(C, "representative"))) : C in Get(G, "ConjugacyClasses")], ",");
for H in S do
    if H`label eq "1701.307.9.k1" then
        h := Get(H, "subgroup");
        if eq "189.5" then
            PrintFile("DATA/1701.307.9.k1.5", reps);
        else
            PrintFile("DATA/1701.307.9.k1.3", reps);
        end if;
        break;
    end if;
end for;
quit;
