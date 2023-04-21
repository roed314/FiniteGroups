// Input: an integer N which serves as an identifier and also the filename containing string describing a group to be identified

SetColumns(0);
AttachSpec("spec");

s := Read("DATA/gps_to_id/" * N);
G := StringToGroup(s);
lab := label(G);
if Type(lab) eq NoneType then
    PrintFile("output", Sprintf("%o|\\N", N));
else
    PrintFile("output", Sprintf("%o|%o", N, lab));
end if;
exit;
