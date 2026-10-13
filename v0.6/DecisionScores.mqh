#ifndef EVO_DECISION_SCORES
#define EVO_DECISION_SCORES
#include "MarketRegime.mqh"
#include "ManagementMode.mqh"

// Decision-oriented predictors. Scores are 0..100 diagnostics, NOT calibrated probabilities.
// Every score must remain explainable from raw indicators on the ANÁLISIS tab.

input group "Tablero de decision v0.6"
input int EvoCandidateScoreMin = 55;   // score minimo para modo *_CANDIDATE
input int EvoCommitScoreMin = 72;      // score minimo para modo comprometido
input int EvoScoreBarWidth = 10;       // ancho visual de barras en panel

int EvoClampScore(const double value)
{
   if(!MathIsValidNumber(value)) return 0;
   if(value<=0.0) return 0;
   if(value>=100.0) return 100;
   return (int)MathRound(value);
}

string EvoScoreBar(const int score,const int width)
{
   int w=width>0 && width<=20?width:10;
   int filled=EvoClampScore(score)*w/100;
   string out="";
   for(int i=0;i<w;i++) out+=(i<filled?"#":".");
   return out;
}

string EvoScoreArrow(const bool rising,const bool falling)
{
   if(rising && !falling) return "↑";
   if(falling && !rising) return "↓";
   return "=";
}

// ADX + delta -> fuerza de tendencia (sin direccion).
int EvoStrengthScore(const double adx,const bool deltaValid,const double deltaADX)
{
   if(!MathIsValidNumber(adx) || adx<0) return 0;
   double base=MathMin(100.0,adx*2.0); // 50 ADX ~ 100
   if(deltaValid)
   {
      if(deltaADX>=0.5) base=MathMin(100.0,base+MathMin(20.0,deltaADX*2.0));
      else if(deltaADX<=-0.5) base=MathMax(0.0,base-MathMin(20.0,(-deltaADX)*2.0));
   }
   return EvoClampScore(base);
}

// ER + delta -> eficiencia del camino.
int EvoEfficiencyScore(const bool erValid,const double er,const double erPrevious)
{
   if(!erValid || !MathIsValidNumber(er) || er<0 || er>1) return 0;
   double base=er*100.0;
   if(MathIsValidNumber(erPrevious))
   {
      double d=er-erPrevious;
      if(d>=0.05) base=MathMin(100.0,base+15.0);
      else if(d<=-0.05) base=MathMax(0.0,base-15.0);
   }
   return EvoClampScore(base);
}

// Dominance of +DI/-DI (0..100).
int EvoDiDominanceScore(const double plusDI,const double minusDI)
{
   if(!MathIsValidNumber(plusDI) || !MathIsValidNumber(minusDI)) return 0;
   double sum=plusDI+minusDI;
   if(sum<=0) return 0;
   double dom=MathAbs(plusDI-minusDI)/sum; // 0..1
   return EvoClampScore(dom*100.0);
}

int EvoMtfAlignmentScore(const bool m0,const int d0,const bool m1,const int d1,const bool m2,const int d2)
{
   int valid=0,up=0,down=0;
   if(m0){ valid++; if(d0>0) up++; else if(d0<0) down++; }
   if(m1){ valid++; if(d1>0) up++; else if(d1<0) down++; }
   if(m2){ valid++; if(d2>0) up++; else if(d2<0) down++; }
   if(valid==0) return 0;
   if(up==valid || down==valid) return 100;
   if((up>0 && down==0) || (down>0 && up==0)) return 60;
   if(up>0 && down>0) return 20;
   return 40;
}

// Continuation: strength + efficiency + DI + MTF (not a probability).
int EvoContinuationScore(const int strength,const int efficiency,const int diDominance,const int mtfAlign,
                         const bool adxRising,const bool erRising)
{
   double s=0.35*strength+0.25*efficiency+0.20*diDominance+0.20*mtfAlign;
   if(adxRising) s+=5.0;
   if(erRising) s+=5.0;
   return EvoClampScore(s);
}

// Exhaustion: opposite of healthy extension.
int EvoExhaustionScore(const double adx,const bool deltaValid,const double deltaADX,
                       const bool erValid,const double er,const double erPrevious,
                       const bool obvOpposed,const bool roomTight)
{
   double s=0.0;
   if(MathIsValidNumber(adx) && adx>=25.0) s+=15.0; // already extended strength can fatigue
   if(deltaValid && deltaADX<=-0.5) s+=25.0+MathMin(15.0,(-deltaADX)*2.0);
   if(erValid && MathIsValidNumber(erPrevious) && (er-erPrevious)<=-0.05) s+=25.0;
   if(erValid && er<0.30) s+=10.0;
   if(obvOpposed) s+=15.0;
   if(roomTight) s+=15.0;
   return EvoClampScore(s);
}

// Entry quality: good direction/setup but not chasing (room + not overextended).
int EvoEntryQualityScore(const int signal,const int strength,const int continuation,const int exhaustion,
                         const bool roomValid,const double roomATR,const double minRoomATR,
                         const double displacement,const bool rangeValid)
{
   if(signal==0) return EvoClampScore(35.0+0.15*continuation); // no base pattern
   double s=40.0+0.25*strength+0.20*continuation;
   s-=0.35*exhaustion;
   if(roomValid && MathIsValidNumber(roomATR) && minRoomATR>0)
   {
      if(roomATR>=minRoomATR) s+=15.0;
      else s-=MathMin(30.0,(minRoomATR-roomATR)/minRoomATR*30.0);
   }
   else s-=10.0;
   if(rangeValid && MathIsValidNumber(displacement) && displacement>=2.0) s-=20.0; // extended move
   else if(rangeValid && displacement>=1.2) s-=10.0;
   return EvoClampScore(s);
}

// Risk for taking a new entry now (higher = worse).
int EvoRiskScore(const int exhaustion,const int entryQuality,const bool roomValid,const double roomATR,
                 const double minRoomATR,const bool needsConfirmation,const bool mtfConflict)
{
   double s=0.40*exhaustion+0.30*(100-entryQuality);
   if(needsConfirmation) s+=15.0;
   if(mtfConflict) s+=15.0;
   if(roomValid && MathIsValidNumber(roomATR) && minRoomATR>0 && roomATR<minRoomATR)
      s+=MathMin(20.0,(minRoomATR-roomATR)/minRoomATR*20.0);
   return EvoClampScore(s);
}

// Management mode scores (0..100 each). Independent of entry permission.
void EvoManagementScores(const int localRegime,const double adx,const bool deltaValid,const double deltaADX,
                         const bool erValid,const double er,const double erPrevious,const int directionBias,
                         const double erTacticalMax,const double erExtensionMin,
                         int &extensionScore,int &tacticalScore,int &protectionScore)
{
   extensionScore=0; tacticalScore=0; protectionScore=0;
   if(!MathIsValidNumber(adx) || adx<0) return;
   if(erTacticalMax<0 || erTacticalMax>1 || erExtensionMin<=0 || erExtensionMin>1 || erTacticalMax>=erExtensionMin) return;

   bool adxRising=deltaValid && deltaADX>=0.5;
   bool adxFalling=deltaValid && deltaADX<=-0.5;
   bool erRising=erValid && (er-erPrevious)>=0.05;
   bool erFalling=erValid && (er-erPrevious)<=-0.05;
   bool directed=directionBias!=0 ||
      localRegime==EVO_REGIME_TENDENCIA_ALCISTA_ACTIVA || localRegime==EVO_REGIME_TENDENCIA_BAJISTA_ACTIVA ||
      localRegime==EVO_REGIME_ALCISTA_CONSOLIDACION || localRegime==EVO_REGIME_BAJISTA_CONSOLIDACION;
   bool active=localRegime==EVO_REGIME_TENDENCIA_ALCISTA_ACTIVA || localRegime==EVO_REGIME_TENDENCIA_BAJISTA_ACTIVA;
   bool consolid=EvoLocalRegimeIsConsolidation(localRegime) || localRegime==EVO_REGIME_TRANSICION || localRegime==EVO_REGIME_INDETERMINADO;

   // Extension: clean trend path.
   if(active || (directed && adx>=25.0))
   {
      double ext=20.0;
      if(active) ext+=25.0;
      if(adxRising) ext+=15.0;
      if(erValid && er>=erExtensionMin) ext+=25.0;
      else if(erValid && er>=(erExtensionMin+erTacticalMax)*0.5) ext+=12.0; // intermediate ER still can candidate
      if(erRising) ext+=10.0;
      if(adxFalling) ext-=20.0;
      if(erFalling) ext-=15.0;
      extensionScore=EvoClampScore(ext);
   }

   // Tactical: strong direction, noisy path.
   if(directed && (active || adx>=20.0))
   {
      double tac=15.0;
      if(adx>=25.0) tac+=20.0;
      if(adxRising) tac+=15.0;
      if(erValid && er<erTacticalMax) tac+=35.0;
      else if(erValid && er<(erTacticalMax+0.15)) tac+=15.0;
      if(erFalling) tac+=5.0;
      if(erValid && er>=erExtensionMin) tac-=25.0;
      tacticalScore=EvoClampScore(tac);
   }

   // Protection: structure losing steam.
   if(directed && adx>=15.0)
   {
      double pro=10.0;
      if(adxFalling) pro+=30.0;
      if(erFalling) pro+=25.0;
      if(adx>=25.0 && adxFalling) pro+=15.0;
      if(consolid) pro+=10.0;
      if(adxRising && erRising) pro-=20.0;
      protectionScore=EvoClampScore(pro);
   }

   if(consolid)
   {
      extensionScore=EvoClampScore(extensionScore*0.35);
      tacticalScore=EvoClampScore(tacticalScore*0.40);
   }
}

string EvoManagementReason(const int mode,const double adx,const bool deltaValid,const double deltaADX,
                           const bool erValid,const double er,const double erPrevious,
                           const int diDominance,const int mtfAlign,const int extensionScore,
                           const int tacticalScore,const int protectionScore)
{
   string r="";
   if(deltaValid && deltaADX>=0.5) r+="ADX fuerte/creciente; ";
   else if(deltaValid && deltaADX<=-0.5) r+="ADX debilitandose; ";
   else if(MathIsValidNumber(adx) && adx>=25.0) r+="ADX elevado; ";
   if(erValid)
   {
      if(er<0.30) r+="ER ruidoso; ";
      else if(er>=0.60) r+="ER eficiente; ";
      else r+="ER intermedio; ";
      double d=er-erPrevious;
      if(d>=0.05) r+="ER creciendo; ";
      else if(d<=-0.05) r+="ER cayendo; ";
   }
   if(diDominance>=60) r+="DI dominante; ";
   if(mtfAlign>=90) r+="MTF alineado; ";
   else if(mtfAlign<=25) r+="MTF en conflicto; ";
   r+=StringFormat("scores E%d/T%d/P%d; ",extensionScore,tacticalScore,protectionScore);
   if(mode==EVO_MGMT_EXTENSION || mode==EVO_MGMT_EXTENSION_CAND)
      r+="camino limpio favorece dejar correr";
   else if(mode==EVO_MGMT_TACTICAL || mode==EVO_MGMT_TACTICAL_CAND)
      r+="direccion fuerte pero ruidosa";
   else if(mode==EVO_MGMT_PROTECTION || mode==EVO_MGMT_PROTECTION_CAND)
      r+="estructura perdiendo capacidad";
   else if(mode==EVO_MGMT_WAIT)
      r+="consolidacion/transicion: no forzar extension";
   else
      r+="sin umbral de modo comprometido";
   return r;
}

// Pick committed / candidate / wait / normal from scores + legacy hard rules.
int EvoClassifyManagementModeScored(const int localRegime,
                                    const double adx,const bool deltaValid,const double deltaADX,
                                    const bool erValid,const double er,const double erPrevious,
                                    const int directionBias,
                                    const double erTacticalMax,const double erExtensionMin,
                                    const int candidateMin,const int commitMin,
                                    int &extensionScore,int &tacticalScore,int &protectionScore)
{
   EvoManagementScores(localRegime,adx,deltaValid,deltaADX,erValid,er,erPrevious,directionBias,
                       erTacticalMax,erExtensionMin,extensionScore,tacticalScore,protectionScore);

   // Hard wait for pure consolidation/transition.
   if(EvoLocalRegimeIsConsolidation(localRegime) || localRegime==EVO_REGIME_TRANSICION || localRegime==EVO_REGIME_INDETERMINADO)
   {
      if(protectionScore>=commitMin) return EVO_MGMT_PROTECTION;
      if(protectionScore>=candidateMin) return EVO_MGMT_PROTECTION_CAND;
      return EVO_MGMT_WAIT;
   }

   int best=EVO_MGMT_NORMAL,bestScore=0;
   if(protectionScore>=extensionScore && protectionScore>=tacticalScore) { bestScore=protectionScore; best=EVO_MGMT_PROTECTION; }
   else if(tacticalScore>=extensionScore) { bestScore=tacticalScore; best=EVO_MGMT_TACTICAL; }
   else { bestScore=extensionScore; best=EVO_MGMT_EXTENSION; }

   // Prefer legacy hard classification when it fires, then overlay candidates.
   int hard=EvoClassifyManagementMode(localRegime,adx,deltaValid,deltaADX,erValid,er,erPrevious,directionBias,erTacticalMax,erExtensionMin);
   if(hard==EVO_MGMT_PROTECTION || hard==EVO_MGMT_TACTICAL || hard==EVO_MGMT_EXTENSION || hard==EVO_MGMT_WAIT)
      return hard;

   if(bestScore>=commitMin)
   {
      if(best==EVO_MGMT_PROTECTION) return EVO_MGMT_PROTECTION;
      if(best==EVO_MGMT_TACTICAL) return EVO_MGMT_TACTICAL;
      return EVO_MGMT_EXTENSION;
   }
   if(bestScore>=candidateMin)
   {
      if(best==EVO_MGMT_PROTECTION) return EVO_MGMT_PROTECTION_CAND;
      if(best==EVO_MGMT_TACTICAL) return EVO_MGMT_TACTICAL_CAND;
      return EVO_MGMT_EXTENSION_CAND;
   }
   return EVO_MGMT_NORMAL;
}

string EvoPendingConfirmationText(const bool needsConfirmation,const int signal,const int localRegime,
                                  const bool roomValid,const double roomATR,const double minRoomATR)
{
   if(!needsConfirmation)
   {
      if(signal>0) return "patron base BUY activo";
      if(signal<0) return "patron base SELL activo";
      return "sin confluencia de entrada";
   }
   string p="pendiente: ";
   if(EvoLocalRegimeIsConsolidation(localRegime) || localRegime==EVO_REGIME_TRANSICION)
      p+="salida de consolidacion/transicion; ";
   if(!roomValid) p+="espacio al obstaculo N/D; ";
   else if(roomATR<minRoomATR) p+=StringFormat("espacio %.2f < %.2f ATR; ",roomATR,minRoomATR);
   p+="cierre que confirme el sesgo";
   return p;
}
#endif
