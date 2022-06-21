// Remove nonsolvable groups from pcrep.todo
// ls pcrep.todo | parallel -j76 magma -b label:="{1}" OnlySolv.m

AttachSpec("spec");
SetColumns(0);
desc := Read("DATA/pcrep.todo/" * label);
G := StringToGroup(desc);
if IsSolvable(G) then
    PrintFile("DATA/pcrep.todosolv/" * label, desc);
end if;
System("rm DATA/pcrep.todo/" * label);
exit;
