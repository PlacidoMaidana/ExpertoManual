#ifndef EVO_MARKET_REGIME
#define EVO_MARKET_REGIME

// Pure local-regime rules. Presentation and optional caution use these labels;
// they do not invent entries by themselves.

enum ENUM_EVO_LOCAL_REGIME
{
   EVO_REGIME_INDETERMINADO=0,
   EVO_REGIME_TENDENCIA_ALCISTA_ACTIVA=1,
   EVO_REGIME_TENDENCIA_BAJISTA_ACTIVA=2,
   EVO_REGIME_ALCISTA_CONSOLIDACION=3,
   EVO_REGIME_BAJISTA_CONSOLIDACION=4,
   EVO_REGIME_LATERAL=5,
   EVO_REGIME_TRANSICION=6
};

string EvoLocalRegimeName(const int regime)
{
   if(regime==EVO_REGIME_TENDENCIA_ALCISTA_ACTIVA) return "TENDENCIA ALCISTA ACTIVA";
   if(regime==EVO_REGIME_TENDENCIA_BAJISTA_ACTIVA) return "TENDENCIA BAJISTA ACTIVA";
   if(regime==EVO_REGIME_ALCISTA_CONSOLIDACION) return "ALCISTA EN CONSOLIDACION";
   if(regime==EVO_REGIME_BAJISTA_CONSOLIDACION) return "BAJISTA EN CONSOLIDACION";
   if(regime==EVO_REGIME_LATERAL) return "LATERAL";
   if(regime==EVO_REGIME_TRANSICION) return "TRANSICION/INDETERMINADO";
   return "INDETERMINADO";
}

string EvoADXInterpretation(const double adx,const bool deltaValid,const double deltaADX)
{
   string level=adx>=40.0?"MUY FUERTE":adx>=25.0?"FUERTE":adx>=15.0?"MODERADA":"DEBIL";
   if(!deltaValid) return level+" | dADX N/D";
   if(deltaADX<=-0.5 && adx>=25.0) return level+" PERO DEBILITANDOSE";
   if(deltaADX>=0.5 && adx>=25.0) return level+" Y CRECIENTE";
   if(deltaADX<=-0.5) return level+" Y DECRECIENTE";
   if(deltaADX>=0.5) return level+" Y CRECIENTE";
   return level+" Y ESTABLE";
}

string EvoERInterpretation(const bool erValid,const double er,const double erPrevious)
{
   if(!erValid) return "N/D";
   string level=er>=0.60?"EFICIENTE":er>=0.30?"INTERMEDIA":"RUIDOSA";
   double change=er-erPrevious;
   if(change<=-0.05) return level+" | EFICIENCIA DECRECIENTE";
   if(change>=0.05) return level+" | EFICIENCIA CRECIENTE";
   return level+" | EFICIENCIA ESTABLE";
}

bool EvoRangeIsCompressed(const bool rangeValid,const double compression,const double compressionMaxATR)
{
   return rangeValid && MathIsValidNumber(compression) && compressionMaxATR>0.0 && compression<=compressionMaxATR;
}

bool EvoRangeIsLowDisplacement(const bool rangeValid,const double displacement,const double displacementMaxATR)
{
   return rangeValid && MathIsValidNumber(displacement) && displacementMaxATR>0.0 && displacement<=displacementMaxATR;
}

// directionBias: +1 bullish context, -1 bearish, 0 neutral/unknown.
int EvoClassifyLocalRegime(const double adx,const bool deltaValid,const double deltaADX,
                           const bool erValid,const double er,const double erPrevious,
                           const bool rangeValid,const double compression,const double displacement,
                           const int directionBias,
                           const double compressionMaxATR,const double displacementMaxATR,
                           const double adxTrendMin,const double erActiveMin)
{
   if(!MathIsValidNumber(adx) || adx<0.0 || compressionMaxATR<=0.0 || displacementMaxATR<=0.0 ||
      adxTrendMin<=0.0 || erActiveMin<=0.0 || erActiveMin>1.0)
      return EVO_REGIME_INDETERMINADO;

   if(!rangeValid || !deltaValid || !erValid || !MathIsValidNumber(er) || !MathIsValidNumber(erPrevious) ||
      !MathIsValidNumber(deltaADX) || er<0 || er>1 || erPrevious<0 || erPrevious>1 || compression<0 || displacement<0)
      return EVO_REGIME_INDETERMINADO;
   bool compressed=EvoRangeIsCompressed(rangeValid,compression,compressionMaxATR);
   bool lowMove=EvoRangeIsLowDisplacement(rangeValid,displacement,displacementMaxATR);
   bool adxFalling=deltaValid && deltaADX<=-0.5;
   bool adxRising=deltaValid && deltaADX>=0.5;
   bool erFalling=erValid && (er-erPrevious)<=-0.05;
   bool erSupport=erValid && er>=erActiveMin;
   bool erWeak=erValid && er<erActiveMin;
   bool trendStrength=adx>=adxTrendMin;
   bool consolidating=compressed && lowMove && (adxFalling || erFalling || !adxRising);

   if(trendStrength && directionBias>0 && consolidating) return EVO_REGIME_ALCISTA_CONSOLIDACION;
   if(trendStrength && directionBias<0 && consolidating) return EVO_REGIME_BAJISTA_CONSOLIDACION;
   if(trendStrength && directionBias>0 && (adxRising || (!adxFalling && erSupport && !lowMove)))
      return EVO_REGIME_TENDENCIA_ALCISTA_ACTIVA;
   if(trendStrength && directionBias<0 && (adxRising || (!adxFalling && erSupport && !lowMove)))
      return EVO_REGIME_TENDENCIA_BAJISTA_ACTIVA;
   if((!trendStrength || erWeak) && compressed && lowMove) return EVO_REGIME_LATERAL;
   if(trendStrength && directionBias==0 && consolidating) return EVO_REGIME_TRANSICION;
   if(rangeValid) return EVO_REGIME_TRANSICION;
   return EVO_REGIME_INDETERMINADO;
}

bool EvoLocalRegimeIsConsolidation(const int regime)
{
   return regime==EVO_REGIME_ALCISTA_CONSOLIDACION || regime==EVO_REGIME_BAJISTA_CONSOLIDACION ||
          regime==EVO_REGIME_LATERAL;
}

// Optional soft caution for presentation. Does not invent opposite entries.
bool EvoSuggestionNeedsConfirmation(const int signal,const int localRegime,const double roomATR,const bool roomValid,const double minRoomATR)
{
   if(signal==0) return false;
   if(EvoLocalRegimeIsConsolidation(localRegime) || localRegime==EVO_REGIME_INDETERMINADO || localRegime==EVO_REGIME_TRANSICION || !roomValid) return true;
   if(roomValid && MathIsValidNumber(roomATR) && minRoomATR>0.0 && roomATR<minRoomATR) return true;
   return false;
}

string EvoSuggestionAction(const int signal,const bool needsConfirmation)
{
   if(signal==0) return "NO ENTRAR";
   if(needsConfirmation) return signal>0?"ESPERAR CONFIRMACION (sesgo compra)":"ESPERAR CONFIRMACION (sesgo venta)";
   return signal>0?"ENTRAR EN COMPRA":"ENTRAR EN VENTA";
}
#endif
