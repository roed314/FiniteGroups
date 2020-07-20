/*
function ReplaceStringFunc(s,fs,ts)
  if Type(fs) eq SeqEnum then
    for i:=1 to #fs do
      s:=ReplaceStringFunc(s,fs[i],ts[i]);
    end for;
    return s;
  end if;
  s:=CodeToString(255) cat Sprint(s) cat CodeToString(255);
  while Position(s,fs) ne 0 do
    p:=Position(s,fs);
    p:=[p-1,#fs,#s-p-#fs+1];
    s1,s2,s3:=Explode(Partition(Eltseq(s),p));
    s:=&cat(s1) cat ts cat &cat(s3);
  end while;
  return s[[2..#s-1]];
end function;
*/

intrinsic ReplaceString(s::MonStgElt, fs::MonStgElt, ts::MonStgElt) -> MonStgElt
  {Return a string obtained from the string s by replacing all occurences of fs with ts.}
     // fs and ts are case sensitive
     i:=Position(s,fs);
     if i eq 0 then
         strg:=s;  // nothing to find
      elif (i+#fs-1) eq #s   then // if fs is at end
         strg:=Substring(s,1,i-1) cat ts; 
     elif i eq 1 then
         strg:=ts cat $$(Substring(s,i+#fs,#s-i),fs,ts);
     else
         strg:=Substring(s,1,i-1) cat ts cat $$(Substring(s,i+#fs,#s-i),fs,ts); 
    end if;   
    return strg;
end intrinsic;

intrinsic ReplaceString(s::MonStgElt, fs::[MonStgElt], ts::[MonStgElt]) -> MonStgElt
  {Return a string obtained from the string s by replacing all occurences of strings in fs with strings in ts.}
  // assert not (true in [ts[i] in s : i in [1..#ts]]);
  for i:=1 to #fs do
    s:=ReplaceString(s,fs[i],ts[i]);
  end for;
  return s;
end intrinsic;

// procedure versions
intrinsic ReplaceString(~s::MonStgElt, fs::MonStgElt, ts::MonStgElt)
  {In the string s, replace all occurences of fs with ts.}
  s := ReplaceString(s,fs,ts);
end intrinsic;

intrinsic ReplaceString(~s::MonStgElt, fs::[MonStgElt], ts::[MonStgElt])
  {In the string s, replace all occurences of strings in fs with strings in ts.}
  for i:=1 to #fs do
    ReplaceString(~s,fs[i],ts[i]);
  end for;
end intrinsic;

// More code from Tim
intrinsic PrintRelExtElement(r::Any) -> Any
  {For storing character values as lists}
  K:=Parent(r);
  QQ:=Rationals();
  return K eq BaseRing(K)
    select QQ!r
    else   [PrintRelExtElement(u): u in Eltseq(r)];
end intrinsic;

intrinsic DelSpaces(s::MonStgElt) ->MonStgElt
  {Delete spaces from a string s}
  return &cat([x: x in Eltseq(Sprint(s)) | (x ne " ") and (x ne "\n")]);
end intrinsic;

intrinsic Polredabs(f::Any) -> Any
  {Have gp compute polredabs}
  R<x>:=PolynomialRing(Rationals());
  out := Sprintf("/tmp/polredabs%o.out", Random(10^30));
  txt := Sprintf("/tmp/polredabs%o.txt", Random(10^30));
  //f:=R!f * Denominator(VectorContent(Coefficients(f)));
  // Avoid hardwiring gp path
  write(txt,Sprintf("polredabs(%o)",f): rewrite:=true);
  System("which gp>"*out);
  gppath:= DelSpaces(Read(out));
  System("rm "* out);
  System(gppath*" -f -q --default parisizemax=1G <"*txt*">"*out);
  //try
  f:=eval DelSpaces(Read(out));
  //catch e;
  //end try;
  System("rm "* out);
  System("rm "* txt);
  return f;
end intrinsic;

intrinsic write(filename::MonStgElt,str::MonStgElt: console:=false, rewrite:=false)
  {Write str to file filename as a line
   rewrite:= true means we overwrite the file, default is to append to it
   console:= true means we echo the string as well.
   If the filename is the empty string, don't write it.}
  if console then str; end if;
  if filename ne "" then
    F:=Open(filename,rewrite select "w" else "a");
    WriteBytes(F,[StringToCode(c): c in Eltseq(Sprint(str)*"\n")]);
    Flush(F);
  end if;
end intrinsic;

