#ifndef EVO_MANAGEMENT_MODE
#define EVO_MANAGEMENT_MODE
#include "MarketRegime.mqh"

// Management style is independent from entry permission.
// v0.5 defaults to diagnosis only: classify and log, do not auto-close from these modes.

enum ENUM_EVO_MGMT_MODE
{
   EVO_MGMT_NORMAL=0,
   EVO_MGMT_EXTENSION=1,
   EVO_MGMT_TACTICAL=2,
   EVO_MGMT_PROTECTION=3,
   EVO_MGMT_WAIT=4,
   EVO_MGMT_EXTENSION_CAND=5,
   EVO_MGMT_TACTICAL_CAND=6,
   EVO_MGMT_PROTECTION_CAND=7
};

string EvoManagementModeName(const int mode)
{
   if(mode==EVO_MGMT_EXTENSION) return "EXTENSION";
   if(mode==EVO_MGMT_TACTICAL) return "CAPTURA TACTICA";
   if(mode==EVO_MGMT_PROTECTION) return "PROTECCION";
   if(mode==EVO_MGMT_WAIT) return "ESPERAR / SIN EXTENSION";
   if(mode==EVO_MGMT_EXTENSION_CAND) return "EXTENSION CANDIDATA";
   if(mode==EVO_MGMT_TACTICAL_CAND) return "CAPTURA TACTICA CANDIDATA";
   if(mode==EVO_MGMT_PROTECTION_CAND) return "PROTECCION CANDIDATA";
   return "NORMAL";
}

string EvoManagementModeHint(const int mode)
{
   if(mode==EVO_MGMT_EXTENSION) return "TENDENCIA LIMPIA — dejar correr (diagnostico)";
   if(mode==EVO_MGMT_TACTICAL) return "DIRECCION FUERTE PERO RUIDOSA — capturar impulsos (diagnostico)";
   if(mode==EVO_MGMT_PROTECTION) return "ESTRUCTURA DEBILITANDOSE — proteger (diagnostico)";
   if(mode==EVO_MGMT_WAIT) return "CONSOLIDACION/TRANSICION — no forzar extension";
   if(mode==EVO_MGMT_EXTENSION_CAND) return "Candidata a extension — ER/fuerza mejorando sin umbral pleno";
   if(mode==EVO_MGMT_TACTICAL_CAND) return "Candidata a captura tactica — ruido parcial con direccion";
   if(mode==EVO_MGMT_PROTECTION_CAND) return "Candidata a proteccion — primeros signos de deterioro";
   return "GESTION ESTANDAR — ver scores y motivo";
}

bool EvoManagementIsCandidate(const int mode)
{
   return mode==EVO_MGMT_EXTENSION_CAND || mode==EVO_MGMT_TACTICAL_CAND || mode==EVO_MGMT_PROTECTION_CAND;
}

// Pure classifier used by panel, thesis and dataset. Does not trade.
// erTacticalMax: below this with strong direction => tactical (default 0.30).
// erExtensionMin: at/above this with rising strength => extension (default 0.60).
int EvoClassifyManagementMode(const int localRegime,
                              const double adx,const bool deltaValid,const double deltaADX,
                              const bool erValid,const double er,const double erPrevious,
                              const int directionBias,
                              const double erTacticalMax,const double erExtensionMin)
{
   if(!MathIsValidNumber(adx) || adx<0) return EVO_MGMT_NORMAL;
   if(erTacticalMax<0 || erTacticalMax>1 || erExtensionMin<=0 || erExtensionMin>1 || erTacticalMax>=erExtensionMin)
      return EVO_MGMT_NORMAL;

   bool adxRising=deltaValid && deltaADX>=0.5;
   bool adxFalling=deltaValid && deltaADX<=-0.5;
   bool erRising=erValid && (er-erPrevious)>=0.05;
   bool erFalling=erValid && (er-erPrevious)<=-0.05;
   bool erLow=erValid && er<erTacticalMax;
   bool erHigh=erValid && er>=erExtensionMin;
   bool directed=directionBias!=0 ||
      localRegime==EVO_REGIME_TENDENCIA_ALCISTA_ACTIVA || localRegime==EVO_REGIME_TENDENCIA_BAJISTA_ACTIVA ||
      localRegime==EVO_REGIME_ALCISTA_CONSOLIDACION || localRegime==EVO_REGIME_BAJISTA_CONSOLIDACION;

   if(EvoLocalRegimeIsConsolidation(localRegime) || localRegime==EVO_REGIME_TRANSICION || localRegime==EVO_REGIME_INDETERMINADO)
      return EVO_MGMT_WAIT;

   // Protection: previously strong structure losing both strength and efficiency.
   if(directed && adxFalling && erFalling && adx>=15.0)
      return EVO_MGMT_PROTECTION;

   // Tactical: direction present / active trend, but path is noisy (low ER).
   // Matches the noisy bearish capture case: ADX up, DI dominant, ER very low.
   if(directed && erLow && (adxRising || adx>=25.0) &&
      (localRegime==EVO_REGIME_TENDENCIA_ALCISTA_ACTIVA || localRegime==EVO_REGIME_TENDENCIA_BAJISTA_ACTIVA || adx>=25.0))
      return EVO_MGMT_TACTICAL;

   // Extension: clean efficient trend.
   if((localRegime==EVO_REGIME_TENDENCIA_ALCISTA_ACTIVA || localRegime==EVO_REGIME_TENDENCIA_BAJISTA_ACTIVA) &&
      erHigh && (adxRising || (!adxFalling && !erFalling)))
      return EVO_MGMT_EXTENSION;

   if(erHigh && adxRising && directed) return EVO_MGMT_EXTENSION;
   if(erLow && directed && adx>=20.0) return EVO_MGMT_TACTICAL;
   return EVO_MGMT_NORMAL;
}

// Hypothetical tactical arm when MFE already reached a threshold (diagnostic only).
bool EvoTacticalWouldArm(const int mode,const double mfeATR,const double minMfeATR)
{
   return mode==EVO_MGMT_TACTICAL && MathIsValidNumber(mfeATR) && MathIsValidNumber(minMfeATR) &&
          minMfeATR>0 && mfeATR>=minMfeATR;
}

bool EvoProtectionWouldArm(const int mode,const double openProfitR,const double minProfitR)
{
   return mode==EVO_MGMT_PROTECTION && MathIsValidNumber(openProfitR) && MathIsValidNumber(minProfitR) &&
          openProfitR>=minProfitR;
}

// Hard safety used by any future adaptive stop proposal (GWT-060).
double EvoNeverWidenStop(const bool buy,const double currentSL,const double candidate)
{
   if(currentSL<=0 || !MathIsValidNumber(currentSL)) return candidate;
   if(!MathIsValidNumber(candidate) || candidate<=0) return currentSL;
   return buy?MathMax(currentSL,candidate):MathMin(currentSL,candidate);
}
#endif
