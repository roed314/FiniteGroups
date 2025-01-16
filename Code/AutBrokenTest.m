// Search for examples of a Magma bug in AutomorphismGroup

AttachSpec("spec");
SetColumns(0);
s := Read("DATA/descriptions/" * label);
if "pc" in s or "PC" in s then
    G := StringToGroup(s);
    A := AutomorphismGroupSolubleGroup(G);
    outs := [f : f in Generators(A) | not IsInner(f)];
    a := Random(G);
    b := Random(G);
    for f in outs do
        if f(a*b) ne f(a) * f(b) then
            print label;
            break;
        end if;
    end for;
    Write("DATA/aut_broken_done/" * label, label);
end if;
exit;
