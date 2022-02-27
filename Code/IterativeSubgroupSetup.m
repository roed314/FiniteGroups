// Given a transitive group as input, set up the files used to find all core-free subgroups of specific indexes (40 or 44).  Used in trying to resolve the last few outstanding cases.

SetColumns(0);
n, t := Explode([StringToInteger(c) : c in Split(nTt, "T")]);
G := TransitiveGroup(n, t);
P := SylowSubgroup(G, 2);
t0 := Cputime();
Hs := [H`subgroup : H in Subgroups(P : IndexEqual := 2)];
msg := Sprintf("Computed %o index 2 subgroups of %o in %o", #Hs, nTt, Cputime() - t0);
print msg;
PrintFile("DATA/hashclusters/last.times", msg);
if n eq 40 then
    m := 4;
else
    m := 2;
end if;
for i in [1..#Hs] do
    slab := nTt * "." * Sprint(i);
    F := "DATA/hashclusters/last/" * slab * ".m";
    PrintFile(F, "SetColumns(0);");
    PrintFile(F, Sprintf("checkfile := \"DATA/hashclusters/lastdone/%o\";", slab));
    PrintFile(F, "file_exists, ifile := OpenTest(checkfile, \"r\");");
    PrintFile(F, "if file_exists then");
    PrintFile(F, "    print \"Already done\";");
    PrintFile(F, "    exit;");
    PrintFile(F, "end if;");
    PrintFile(F, Sprintf("G := TransitiveGroup(%o, %o);", n, t));
    PrintFile(F, Sprintf("H := %m;", Hs[i]));
    PrintFile(F, "t0 := Cputime();");
    PrintFile(F, Sprintf("S := [K`subgroup : K in Subgroups(H : IndexEqual:=%o)];", m));
    PrintFile(F, "PrintFile(\"DATA/hashclusters/last.times\", Sprintf(\"Found %o subgroups within " * slab * " in %o\", #S, Cputime() - t0));");
    PrintFile(F, "t0 := Cputime();");
    PrintFile(F, "c := 0;");
    PrintFile(F, "for K in S do");
    PrintFile(F, "    if #Core(G, K) eq 1 then");
    PrintFile(F, "        c +:= 1;");
    PrintFile(F, "        t := TransitiveGroupIdentification(Image(CosetAction(G, K)));");
    PrintFile(F, Sprintf("        if t eq %o then", t));
    PrintFile(F, "            PrintFile(\"DATA/hashclusters/last.selfsib/"*nTt*"\", Sprintf(\"%o\", Generators(K)));");
    PrintFile(F, "        else");
    PrintFile(F, "            PrintFile(\"DATA/hashclusters/last.osib/"*nTt*"\", Sprintf(\"%o\", Generators(K)));");
    PrintFile(F, "        end if;");
    PrintFile(F, "    end if;");
    PrintFile(F, "end for;");
    PrintFile(F, "PrintFile(\"DATA/hashclusters/last.times\", Sprintf(\"Finished checking %o subgroups within " * slab * " in %o\", #S, Cputime() - t0));");
    PrintFile(F, "PrintFile(checkfile, Sprint(c));");
    PrintFile(F, "exit;");
end for;
exit;
