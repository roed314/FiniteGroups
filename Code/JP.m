/* IS center and commutator saved somewhere already? */
/* whether H is contained in both the center and commutator subgroups of G */
intrinsic stem(H::LMFDBSubGrp) -> BoolElt
   {Determine if a subgroup is maximal}
   GG := H`MagmaAmbient;
   HH := H`MagmaSubGrp;
   Cent:=Center(GG);
   Comm:=CommutatorSubgroup(GG);
   if HH in Cent and HH in Comm then
      return true;
   else
     return fales;
   end if;
end intrinsic;


/* For groups */
intrinsic counter(G::LMFDBGrp) -> RngIntElt
{Second entry in label}
   lab:= Get(G,"label");
   spl:=Split(lab,".");
   return spl[2];
end intrinsic;


