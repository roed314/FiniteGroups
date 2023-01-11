// Usage parallel -j 21 magma -b n:={1} IdDesc.m ::: {1..21}
// Inputs should be in DATA/toN.id, output written to DATA/doneN.id

SetColumns(0);
AttachSpec("spec");
infile := Sprintf("DATA/to%o.id", n);
outfile := Sprintf("DATA/done%o.id", n);
descs := Split(Read(infile), "\n");

for desc in descs do
    PrintFile(outfile, Sprintf("%o %o", GroupToString(StringToGroup(desc)), desc));
end for;
exit;
