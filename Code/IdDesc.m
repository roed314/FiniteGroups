// Usage parallel -j 21 magma -b n:={1} IdDesc.m ::: {1..21}

SetColumns(0);
AttachSpec("spec");
infile := Sprintf("to%o.id", n);
outfile := Sprintf("done%o.id", n);
descs := Split(Read(infile), "\n");

for desc in descs do
    PrintFile(outfile, Sprintf("%o %o", GroupToString(StringToGroup(desc)), desc));
end for;
