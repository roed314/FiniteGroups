intrinsic indicator(M::LMFDBRepCC) -> FldRatElt
  {Computes the Frobenius-Schur indicator}
  MM := M`MagmaRep;
  Mat := MatrixGroup(MM);
  ind := 0;
  for g in Mat do
    ind +:= Trace(g^2);
  end for;
  return (1/Get(M,'order'))*ind;
end intrinsic;


//u:= AbsoluteModuleOverMinimalField(gmodule);    DefiningPolynomial(CoefficientRing(u));
