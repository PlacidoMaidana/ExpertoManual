#ifndef EVOLUTION_SIGNAL_ANALYSIS
#define EVOLUTION_SIGNAL_ANALYSIS
#include "SignalAnalysisInputs.mqh"
#include "MarketMetrics.mqh"
#include "MarketRegime.mqh"
#include "ManagementMode.mqh"
#include "DecisionScores.mqh"
#include "TradeDataset.mqh"
#include "MultiTimeframe.mqh"
#include "BollingerRules.mqh"
#include "MonitorLevels.mqh"
#include "MarketEvidence.mqh"
input group "Bollinger compartido"
input int EvoBBPeriod = 20;
input double EvoBBDeviation = 2.0;
input bool EvoUseBBFilter = false; // false: contexto; true: confirmacion adicional por regimen
input group "OBV compartido"
input ENUM_APPLIED_VOLUME EvoOBVVolume = VOLUME_TICK; // Seleccion explicita; sin sustituir real por ticks
input int EvoOBVLookback = 5; // Cambio entre cierres, no periodo de suavizado
input bool EvoUseOBVFilter = false; // Confirmacion adicional; nunca genera entradas
input group "ER compartido"
input int EvoERPeriod = 14;
input int EvoDeltaBars = 5;
input bool EvoUseERFilter = false; // Filtro opcional de entrada automatica
input double EvoMinER = 0.30;
input group "Regimen local - contexto"
input int EvoRegimeLookback = 8; // Velas cerradas para compresion/desplazamiento
input double EvoCompressionMaxATR = 1.20; // HH-LL/ATR bajo este umbral = rango comprimido
input double EvoDisplacementMaxATR = 0.45; // |C_t-C_t-n|/ATR bajo este umbral = poco avance neto
input double EvoMinRoomATR = 0.60; // Espacio al obstaculo para cautela compartida
input bool EvoCautionOnConsolidation = true; // true: esperar y bloquear entrada automatica v0.4 mientras haya cautela

struct EvoSnapshot
{
   EvoMarketEvidence evidence;
   double atr[3], adx[3], rsi[3], fast[3], slow[3], support[3], resistance[3], average[3];
   double plusDI, minusDI, closedPlusDI, closedMinusDI, er, erPrevious, deltaADX;
   bool erValid, deltaValid;
   double ema50, ema200;
   bool ema50Valid, ema200Valid;
   double bbLower,bbMiddle,bbUpper,bbPreviousLower,bbPreviousUpper;
   bool bbValid,bbPreviousValid;
   EvoFrameContext mtf[3];
   double obv, obvDelta, obvPriceDelta,obvVolumeSum;
   bool stochValid,sarValid;
   double stochK,stochD,stochPreviousK,stochPreviousD,sar,sarPrevious,sarClose,sarPreviousClose;
   bool obvValid;
   MqlRates current, confirmed, previous;
   bool closedView; // Arrays start at shift 1 for a fully closed snapshot.
   string regime, reason, buyChecks, sellChecks;
   int direction, confidence, signal; // +1 BUY, -1 SELL, 0 sin configuracion tecnica
   // Local market-regime context (presentation / optional caution). Independent of base EA regime.
   double compression, displacement, roomATR;
   bool rangeValid, roomValid, needsConfirmation;
   int localRegime, biasDirection;
   string localRegimeName, adxInterpretation, erInterpretation, suggestionAction;
   // Management style is independent from entry signal / local regime label.
   int managementMode;
   string managementModeName, managementModeHint, managementReason, pendingAction;
   // Decision scores 0..100 (diagnostic, not calibrated probabilities).
   int scoreStrength, scoreEfficiency, scoreContinuation, scoreExhaustion;
   int scoreEntryQuality, scoreRisk, scoreDiDominance, scoreMtf;
   int scoreExtension, scoreTactical, scoreProtection;
};

bool EvoValidAnalysisInputs()
{
   return EvoChannelLookback>=10 && EvoChannelLookback<=500 && MathIsValidNumber(EvoMomentumMinHistATR) && EvoMomentumMinHistATR>0 &&
          MathIsValidNumber(EvoMomentumMinMoveATR) && EvoMomentumMinMoveATR>0 && EvoOBVLookback>=1 && EvoOBVLookback<=10000 &&
          (EvoOBVVolume==VOLUME_TICK || EvoOBVVolume==VOLUME_REAL) && EvoBBPeriod>=2 && EvoBBPeriod<=10000 && MathIsValidNumber(EvoBBDeviation) && EvoBBDeviation>0 && EvoBBDeviation<=10 &&
          InpATRPeriod>0 && InpADXPeriod>0 && InpRSIPeriod>0 &&
          InpEmaFastPeriod>0 && InpEmaSlowPeriod>0 && InpSupportResistancePeriod>0 &&
          InpATRMediaPeriod>=10 && EvoERPeriod>0 && EvoERPeriod<=10000 &&
          EvoDeltaBars>0 && EvoDeltaBars<=10000 && EvoMinER>=0 && EvoMinER<=1 &&
          EvoRegimeLookback>=2 && EvoRegimeLookback<=500 &&
          MathIsValidNumber(EvoCompressionMaxATR) && EvoCompressionMaxATR>0 && EvoCompressionMaxATR<=20 &&
          MathIsValidNumber(EvoDisplacementMaxATR) && EvoDisplacementMaxATR>0 && EvoDisplacementMaxATR<=20 &&
          MathIsValidNumber(EvoMinRoomATR) && EvoMinRoomATR>=0 && EvoMinRoomATR<=20 &&
          EvoValidDatasetInputs() &&
          EvoCandidateScoreMin>=1 && EvoCandidateScoreMin<=100 &&
          EvoCommitScoreMin>=1 && EvoCommitScoreMin<=100 &&
          EvoCandidateScoreMin<=EvoCommitScoreMin &&
          EvoScoreBarWidth>=4 && EvoScoreBarWidth<=20;
}

void EvoEvaluate(EvoSnapshot &s, const double point, const bool closedOnly=false,const bool baseOnly=false)
{
   double close=closedOnly?s.current.close:(InpRequireCandleConfirmation?s.confirmed.close:s.current.close);
   double slope=s.fast[0]-s.fast[2];
   double minSlope=s.atr[0]*0.10*EntryMinEmaSlopeAtrMult();
   bool bull=(close>s.fast[0] && s.fast[0]>s.slow[0]) || (close>s.fast[0] && slope>minSlope);
   bool bear=(close<s.fast[0] && s.fast[0]<s.slow[0]) || (close<s.fast[0] && slope< -minSlope);
   s.direction=(bull&&!bear)?1:((bear&&!bull)?-1:0);
   int score=(s.adx[0]>=EntryTrendADXMin()?2:(s.adx[0]>20?1:0));
   if(s.direction!=0) score++;
   if(s.atr[0]>s.average[0] && s.average[0]>0) score++;
   s.confidence=(int)(MathMin(score,4)/4.0*100);
   s.regime=(s.adx[0]>=EntryTrendADXMin() && s.direction!=0)?"TENDENCIA":
            ((s.atr[0]<s.average[0] && s.atr[0]>0)?"LATERAL":"MIXTO");
   s.signal=0; s.reason="Sin confluencia tecnica de entrada";
   int idx=closedOnly?0:(InpRequireCandleConfirmation?1:0);
   string dir=InpTradeDirection; StringToLower(dir);
   bool buy=(dir=="both" || dir=="buy"), sell=(dir=="both" || dir=="sell");
   bool ema=EntryUseEMADirectionFilter();
   s.buyChecks=buy?"":"direccion; "; s.sellChecks=sell?"":"direccion; ";
   if(ema && s.direction<0) s.buyChecks+="sesgo EMA; ";
   if(ema && s.direction>0) s.sellChecks+="sesgo EMA; ";
   if(s.regime=="TENDENCIA")
   {
      bool freshUp=!InpRequireFreshBreakout || !InpRequireCandleConfirmation || s.previous.close<=s.resistance[closedOnly?1:2];
      bool freshDown=!InpRequireFreshBreakout || !InpRequireCandleConfirmation || s.previous.close>=s.support[closedOnly?1:2];
      bool adxOK=!UseEntryRequireADX() || s.adx[0]>EntryMinADX();
      if(close<=s.resistance[idx]) s.buyChecks+="ruptura; ";
      if(close>=s.support[idx]) s.sellChecks+="ruptura; ";
      if(!freshUp) s.buyChecks+="ruptura fresca; ";
      if(!freshDown) s.sellChecks+="ruptura fresca; ";
      if(!adxOK) { s.buyChecks+="ADX; "; s.sellChecks+="ADX; "; }
      if(buy && (!ema || s.direction>=0) && close>s.resistance[idx] && freshUp && adxOK) s.signal=1;
      else if(sell && (!ema || s.direction<=0) && close<s.support[idx] && freshDown && adxOK) s.signal=-1;
      if(!adxOK) s.reason="ADX inferior al umbral efectivo";
   }
   else if(s.regime=="LATERAL")
   {
      double proximity=MathMax(s.atr[0]*EntrySRProximityAtrMult(),10*point);
      bool lateral=!EntryBlockLateralHighADX() || s.adx[0]<=EntryLateralADXMax();
      if(!lateral) { s.buyChecks+="ADX lateral; "; s.sellChecks+="ADX lateral; "; }
      if(MathAbs(close-s.support[idx])>proximity) s.buyChecks+="lejos soporte; ";
      if(MathAbs(close-s.resistance[idx])>proximity) s.sellChecks+="lejos resistencia; ";
      if(s.rsi[0]>=EntryRSIOversold()) s.buyChecks+="RSI; ";
      if(s.rsi[0]<=EntryRSIOverbought()) s.sellChecks+="RSI; ";
      if(lateral && buy && (!ema || s.direction!=-1) && MathAbs(close-s.support[idx])<=proximity && s.rsi[0]<EntryRSIOversold()) s.signal=1;
      else if(lateral && sell && (!ema || s.direction!=1) && MathAbs(close-s.resistance[idx])<=proximity && s.rsi[0]>EntryRSIOverbought()) s.signal=-1;
      if(!lateral) s.reason="Reversion bloqueada por ADX alto";
   }
   else { s.reason="Regimen mixto: estrategia base sin patron de entrada"; s.buyChecks+="regimen mixto; "; s.sellChecks+="regimen mixto; "; }
   if(s.signal!=0) s.reason="Confluencia tecnica "+s.regime+" "+(s.signal==1?"BUY":"SELL");
   if(baseOnly) return; // v1.13 technical patterns, without additional monitor filters.
   if(EvoUseERFilter && (!s.erValid || s.er<EvoMinER))
   { s.signal=0; s.reason=s.erValid?"ER inferior al minimo configurado":"ER no disponible"; s.buyChecks+="ER; "; s.sellChecks+="ER; "; }
   if(EvoUseBBFilter)
   {
      bool bbBuy=EvoBollingerAllows(1,s.regime,s.bbValid,close,s.bbLower,s.bbMiddle,s.bbUpper);
      bool bbSell=EvoBollingerAllows(-1,s.regime,s.bbValid,close,s.bbLower,s.bbMiddle,s.bbUpper);
      if(!bbBuy) s.buyChecks+="Bollinger; ";
      if(!bbSell) s.sellChecks+="Bollinger; ";
      if((s.signal>0 && !bbBuy) || (s.signal<0 && !bbSell))
      { s.signal=0; s.reason=s.bbValid?"Bollinger no confirma el patron del regimen":"Bollinger sin datos disponibles"; }
      else if(s.signal!=0) s.reason+="; Bollinger confirma";
   }
   if(EvoUseOBVFilter)
   {
      bool obvBuy=s.obvValid && s.obvDelta>0;
      bool obvSell=s.obvValid && s.obvDelta<0;
      if(!obvBuy) s.buyChecks+="OBV; ";
      if(!obvSell) s.sellChecks+="OBV; ";
      if((s.signal>0 && !obvBuy) || (s.signal<0 && !obvSell))
      { s.signal=0; s.reason=s.obvValid?"OBV no confirma la direccion de entrada":"OBV sin datos de volumen disponibles"; }
      else if(s.signal!=0) s.reason+="; OBV confirma";
   }
   if(s.buyChecks=="") s.buyChecks="condiciones tecnicas cumplidas";
   if(s.sellChecks=="") s.sellChecks="condiciones tecnicas cumplidas";
}

void EvoFillLocalRegime(EvoSnapshot &s,const string symbol,const ENUM_TIMEFRAMES timeframe,const bool closedView)
{
   s.compression=0; s.displacement=0; s.roomATR=-1;
   s.rangeValid=false; s.roomValid=false; s.needsConfirmation=false;
   s.localRegime=EVO_REGIME_INDETERMINADO; s.biasDirection=0;
   s.localRegimeName=EvoLocalRegimeName(s.localRegime);
   s.adxInterpretation=EvoADXInterpretation(s.adx[0],s.deltaValid,s.deltaADX);
   s.erInterpretation=EvoERInterpretation(s.erValid,s.er,s.erPrevious);
   s.suggestionAction=EvoSuggestionAction(s.signal,false);
   s.managementMode=EVO_MGMT_NORMAL;
   s.managementModeName=EvoManagementModeName(s.managementMode);
   s.managementModeHint=EvoManagementModeHint(s.managementMode);
   s.managementReason=""; s.pendingAction="";
   s.scoreStrength=0; s.scoreEfficiency=0; s.scoreContinuation=0; s.scoreExhaustion=0;
   s.scoreEntryQuality=0; s.scoreRisk=0; s.scoreDiDominance=0; s.scoreMtf=0;
   s.scoreExtension=0; s.scoreTactical=0; s.scoreProtection=0;
   if(s.atr[0]<=0) return;

   int idx=closedView?0:1;
   double atrForRange=s.atr[idx],adxForRange=s.adx[idx];
   EvoReadMarketEvidence(symbol,timeframe,atrForRange,s.evidence);
   s.rangeValid=EvolutionRangeMetrics(symbol,timeframe,EvoRegimeLookback,1,atrForRange,s.compression,s.displacement);
   double plus=closedView?s.plusDI:s.closedPlusDI,minus=closedView?s.minusDI:s.closedMinusDI;
   int di=plus>minus+1?1:minus>plus+1?-1:0;
   int ema=s.fast[idx]>s.slow[idx]?1:s.fast[idx]<s.slow[idx]?-1:0;
   s.biasDirection=ema!=0?ema:di;

   double price=s.confirmed.close>0?s.confirmed.close:s.current.close;
   double support=0,resistance=0; bool sf=false,rf=false;
   if(price>0)
   {
      EvoNearestLevels(price,support,resistance,sf,rf);
      double obstacle=0;
      int side=s.signal!=0?s.signal:s.biasDirection;
      if(side>0) obstacle=resistance;
      else if(side<0) obstacle=support;
      if(obstacle>0 && s.atr[0]>0)
      {
         s.roomATR=MathAbs(obstacle-price)/atrForRange;
         s.roomValid=MathIsValidNumber(s.roomATR);
      }
   }

   s.localRegime=EvoClassifyLocalRegime(adxForRange,s.deltaValid,s.deltaADX,s.erValid,s.er,s.erPrevious,
                                        s.rangeValid,s.compression,s.displacement,s.biasDirection,
                                        EvoCompressionMaxATR,EvoDisplacementMaxATR,EntryTrendADXMin(),MathMax(EvoMinER,0.30));
   s.localRegimeName=EvoLocalRegimeName(s.localRegime);
   s.adxInterpretation=EvoADXInterpretation(adxForRange,s.deltaValid,s.deltaADX);
   s.erInterpretation=EvoERInterpretation(s.erValid,s.er,s.erPrevious);
   bool caution=EvoCautionOnConsolidation && EvoSuggestionNeedsConfirmation(s.signal,s.localRegime,s.roomATR,s.roomValid,EvoMinRoomATR);
   s.needsConfirmation=caution;
   s.suggestionAction=EvoSuggestionAction(s.signal,caution);
   s.pendingAction=EvoPendingConfirmationText(caution,s.signal,s.localRegime,s.roomValid,s.roomATR,EvoMinRoomATR);
   // Predictors + scored management (candidates included). Presentation only; does not trade.
   bool adxRising=s.deltaValid && s.deltaADX>=0.5;
   bool adxFalling=s.deltaValid && s.deltaADX<=-0.5;
   bool erRising=s.erValid && (s.er-s.erPrevious)>=0.05;
   bool erFalling=s.erValid && (s.er-s.erPrevious)<=-0.05;
   bool roomTight=s.roomValid && s.roomATR<EvoMinRoomATR;
   bool obvOpposed=s.obvValid && s.obvDelta!=0 && s.biasDirection!=0 &&
                   ((s.biasDirection>0 && s.obvDelta<0) || (s.biasDirection<0 && s.obvDelta>0));
   s.scoreStrength=EvoStrengthScore(adxForRange,s.deltaValid,s.deltaADX);
   s.scoreEfficiency=EvoEfficiencyScore(s.erValid,s.er,s.erPrevious);
   s.scoreDiDominance=EvoDiDominanceScore(plus,minus);
   s.scoreMtf=EvoMtfAlignmentScore(s.mtf[0].valid,s.mtf[0].direction,s.mtf[1].valid,s.mtf[1].direction,s.mtf[2].valid,s.mtf[2].direction);
   s.scoreContinuation=EvoContinuationScore(s.scoreStrength,s.scoreEfficiency,s.scoreDiDominance,s.scoreMtf,adxRising,erRising);
   s.scoreExhaustion=EvoExhaustionScore(adxForRange,s.deltaValid,s.deltaADX,s.erValid,s.er,s.erPrevious,obvOpposed,roomTight);
   s.scoreEntryQuality=EvoEntryQualityScore(s.signal,s.scoreStrength,s.scoreContinuation,s.scoreExhaustion,
                                            s.roomValid,s.roomATR,EvoMinRoomATR,s.displacement,s.rangeValid);
   bool mtfConflict=s.scoreMtf>0 && s.scoreMtf<=25;
   s.scoreRisk=EvoRiskScore(s.scoreExhaustion,s.scoreEntryQuality,s.roomValid,s.roomATR,EvoMinRoomATR,caution,mtfConflict);
#ifdef EVO_MONITOR_SAFE_INPUTS
   // Diagnostic momentum group is bounded; correlated MACD/ROC count once.
   if(s.evidence.valid)
   {
      bool structureOpposed=s.evidence.structure!=0 && s.biasDirection!=0 && s.evidence.structure!=s.biasDirection;
      int adjust=structureOpposed?-10:EvoEvidenceAdjustment(s.biasDirection,s.evidence.momentum);
      s.scoreContinuation=EvoClampScore(s.scoreContinuation+adjust);
      s.scoreEntryQuality=EvoClampScore(s.scoreEntryQuality+EvoEvidenceAdjustment(s.signal,s.evidence.momentum));
      s.scoreRisk=EvoClampScore(s.scoreRisk-adjust*0.5);
      if(structureOpposed)
      {
         s.needsConfirmation=true;
         s.suggestionAction="ESPERAR: PIVOTES Y SESGO EMA/DI EN CONFLICTO";
         s.pendingAction="La estructura reciente difiere del sesgo de medias; esperar alineacion.";
      }
      else if(s.signal!=0 && s.evidence.momentum==-s.signal)
      {
         s.needsConfirmation=true;
         s.suggestionAction="ESPERAR: MACD Y ROC CONTRARIOS AL SETUP";
         s.pendingAction="Esperar que el impulso cerrado se alinee; no es una inversion confirmada.";
      }
   }
#endif
   s.managementMode=EvoClassifyManagementModeScored(s.localRegime,adxForRange,s.deltaValid,s.deltaADX,
                                                    s.erValid,s.er,s.erPrevious,s.biasDirection,
                                                    EvoTacticalERMax,EvoExtensionERMin,
                                                    EvoCandidateScoreMin,EvoCommitScoreMin,
                                                    s.scoreExtension,s.scoreTactical,s.scoreProtection);
   s.managementModeName=EvoManagementModeName(s.managementMode);
   s.managementModeHint=EvoManagementModeHint(s.managementMode);
   s.managementReason=EvoManagementReason(s.managementMode,adxForRange,s.deltaValid,s.deltaADX,
                                          s.erValid,s.er,s.erPrevious,s.scoreDiDominance,s.scoreMtf,
                                          s.scoreExtension,s.scoreTactical,s.scoreProtection);
}

class CEvoAnalysis
{
private:
   CEvoMultiTimeframe higher;
   int handles[11];
   int visualStoch,visualSAR;
   string symbol;
   ENUM_TIMEFRAMES timeframe;
   bool Read(const int h,const int buffer,const int shift,double &v)
   {
      double x[1];
      if(CopyBuffer(h,buffer,shift,1,x)!=1) return false;
      v=x[0]; return MathIsValidNumber(v) && v!=EMPTY_VALUE;
   }
   void ReadVisualClosed(EvoSnapshot &s)
   {
      s.stochValid=false; s.sarValid=false;
#ifdef EVO_ANALYSIS_DASHBOARD_VERSION
      datetime bar=iTime(symbol,timeframe,1);
      s.stochValid=visualStoch!=INVALID_HANDLE && BarsCalculated(visualStoch)>=20 &&
         Read(visualStoch,0,1,s.stochK) && Read(visualStoch,1,1,s.stochD) &&
         Read(visualStoch,0,2,s.stochPreviousK) && Read(visualStoch,1,2,s.stochPreviousD) &&
         s.stochK>=0 && s.stochK<=100 && s.stochD>=0 && s.stochD<=100 &&
         s.stochPreviousK>=0 && s.stochPreviousK<=100 && s.stochPreviousD>=0 && s.stochPreviousD<=100;
      MqlRates rates[]; ArraySetAsSeries(rates,true);
      s.sarValid=visualSAR!=INVALID_HANDLE && BarsCalculated(visualSAR)>=3 &&
         Read(visualSAR,0,1,s.sar) && Read(visualSAR,0,2,s.sarPrevious) &&
         s.sar>0 && s.sarPrevious>0 && CopyRates(symbol,timeframe,1,2,rates)==2;
      if(s.sarValid) { s.sarClose=rates[0].close; s.sarPreviousClose=rates[1].close; s.sarValid=rates[0].time==bar; }
      if(bar<=0 || iTime(symbol,timeframe,1)!=bar) { s.stochValid=false; s.sarValid=false; }
#endif
   }
public:
   CEvoAnalysis() { visualStoch=INVALID_HANDLE; visualSAR=INVALID_HANDLE; for(int i=0;i<11;i++) handles[i]=INVALID_HANDLE; }
   bool ATR(double &value) { return Read(handles[0],0,0,value) && value>0; }
   void Release() { higher.Release(); if(visualStoch!=INVALID_HANDLE) IndicatorRelease(visualStoch); if(visualSAR!=INVALID_HANDLE) IndicatorRelease(visualSAR); visualStoch=INVALID_HANDLE; visualSAR=INVALID_HANDLE; for(int i=0;i<11;i++) { if(handles[i]!=INVALID_HANDLE) IndicatorRelease(handles[i]); handles[i]=INVALID_HANDLE; } }
   bool Init(const string sym,const ENUM_TIMEFRAMES tf)
   {
      Release(); symbol=sym; timeframe=tf;
      if(!EvoValidAnalysisInputs()) return false;
      handles[0]=iATR(sym,tf,InpATRPeriod); handles[1]=iADX(sym,tf,InpADXPeriod);
      handles[2]=iRSI(sym,tf,InpRSIPeriod,PRICE_CLOSE);
      handles[3]=iMA(sym,tf,InpEmaFastPeriod,0,MODE_EMA,PRICE_CLOSE);
      handles[4]=iMA(sym,tf,InpEmaSlowPeriod,0,MODE_EMA,PRICE_CLOSE);
      handles[5]=iMA(sym,tf,InpSupportResistancePeriod,0,MODE_SMA,PRICE_LOW);
      handles[6]=iMA(sym,tf,InpSupportResistancePeriod,0,MODE_SMA,PRICE_HIGH);
      for(int i=0;i<7;i++) if(handles[i]==INVALID_HANDLE) { Release(); return false; }
      handles[7]=iMA(sym,tf,50,0,MODE_EMA,PRICE_CLOSE);
      handles[8]=iMA(sym,tf,200,0,MODE_EMA,PRICE_CLOSE);
      handles[9]=iBands(sym,tf,EvoBBPeriod,0,EvoBBDeviation,PRICE_CLOSE);
      if(EvoUseBBFilter && handles[9]==INVALID_HANDLE) { Release(); return false; }
      higher.Init(sym);
      handles[10]=iOBV(sym,tf,EvoOBVVolume);
      if(EvoUseOBVFilter && handles[10]==INVALID_HANDLE) { Release(); return false; }
#ifdef EVO_ANALYSIS_DASHBOARD_VERSION
      // Optional visual context: unavailable indicators do not block management.
      visualStoch=iStochastic(sym,tf,14,3,3,MODE_SMA,STO_LOWHIGH);
      visualSAR=iSAR(sym,tf,0.02,0.20);
#endif
      return true;
   }
   // Independent closed-bar view for alerts; never replaces the live trading snapshot.
   bool ClosedAlertSnapshot(EvoSnapshot &s)
   {
      datetime closedTime=iTime(symbol,timeframe,1);
      if(!Update(s)) return false;
      for(int i=0;i<3;i++)
      {
         int shift=i+1;
         if(!Read(handles[0],0,shift,s.atr[i]) || !Read(handles[1],0,shift,s.adx[i]) ||
            !Read(handles[2],0,shift,s.rsi[i]) || !Read(handles[3],0,shift,s.fast[i]) ||
            !Read(handles[4],0,shift,s.slow[i]) || !Read(handles[5],0,shift,s.support[i]) ||
            !Read(handles[6],0,shift,s.resistance[i])) return false;
         double a[10],sum=0;
         if(CopyBuffer(handles[0],0,shift,10,a)!=10) return false;
         for(int j=0;j<10;j++) { if(!MathIsValidNumber(a[j]) || a[j]==EMPTY_VALUE || a[j]<=0) return false; sum+=a[j]; }
         s.average[i]=sum/10;
      }
      MqlRates b[]; ArraySetAsSeries(b,true);
      if(CopyRates(symbol,timeframe,1,2,b)!=2 || s.atr[0]<=0) return false;
      if(closedTime<=0 || b[0].time!=closedTime) return false;
      s.current=b[0]; s.confirmed=b[0]; s.previous=b[1];
      s.closedView=true;
      if(!Read(handles[1],1,1,s.plusDI) || !Read(handles[1],2,1,s.minusDI)) return false;
      s.bbValid=BarsCalculated(handles[9])>=EvoBBPeriod+1 &&
         Read(handles[9],0,1,s.bbMiddle) && Read(handles[9],1,1,s.bbUpper) && Read(handles[9],2,1,s.bbLower) &&
         s.bbUpper>=s.bbMiddle && s.bbMiddle>=s.bbLower;
      s.closedPlusDI=s.plusDI; s.closedMinusDI=s.minusDI;
      s.bbPreviousValid=BarsCalculated(handles[9])>=EvoBBPeriod+2 &&
         Read(handles[9],1,2,s.bbPreviousUpper) && Read(handles[9],2,2,s.bbPreviousLower);
      // Missing optional-filter data is not a technical NO ENTRAR transition.
      if((EvoUseBBFilter && !s.bbValid) || (EvoUseERFilter && !s.erValid) || (EvoUseOBVFilter && !s.obvValid)) return false;
      EvoEvaluate(s,SymbolInfoDouble(symbol,SYMBOL_POINT),true);
      EvoFillLocalRegime(s,symbol,timeframe,true);
      return iTime(symbol,timeframe,1)==closedTime;
   }
   bool Update(EvoSnapshot &s)
   {
      ZeroMemory(s);
      for(int i=0;i<3;i++)
         if(!Read(handles[0],0,i,s.atr[i]) || !Read(handles[1],0,i,s.adx[i]) ||
            !Read(handles[2],0,i,s.rsi[i]) || !Read(handles[3],0,i,s.fast[i]) ||
            !Read(handles[4],0,i,s.slow[i]) || !Read(handles[5],0,i,s.support[i]) ||
            !Read(handles[6],0,i,s.resistance[i])) return false;
      if(s.atr[0]<=0 || !Read(handles[1],1,0,s.plusDI) || !Read(handles[1],2,0,s.minusDI)) return false;
      if(!Read(handles[1],1,1,s.closedPlusDI) || !Read(handles[1],2,1,s.closedMinusDI)) return false;
      MqlRates bars[]; ArraySetAsSeries(bars,true);
      if(CopyRates(symbol,timeframe,0,3,bars)!=3) return false;
      s.current=bars[0]; s.confirmed=bars[1]; s.previous=bars[2];
      // Preserve the base EA's ATR average (at most ten samples).
      int n=MathMin(InpATRMediaPeriod,Bars(symbol,timeframe)-InpATRPeriod);
      double values[]; ArraySetAsSeries(values,true);
      bool hasAverage=n>=10 && CopyBuffer(handles[0],0,0,n,values)==n;
      for(int i=0;i<3;i++)
      {
         double sum=0; int count=0;
         if(hasAverage) for(int j=i;j<i+n-5 && j<n && count<10;j++) { sum+=values[j]; count++; }
         s.average[i]=count>0?sum/count:s.atr[0];
      }
      s.erValid=EvolutionER(symbol,timeframe,EvoERPeriod,1,s.er) &&
                EvolutionER(symbol,timeframe,EvoERPeriod,1+EvoDeltaBars,s.erPrevious);
      double older=0;
      s.deltaValid=Read(handles[1],0,1+EvoDeltaBars,older);
      if(s.deltaValid) s.deltaADX=s.adx[1]-older;
      // Context only: insufficient EMA200 history never blocks the entry engine.
      s.ema50Valid=BarsCalculated(handles[7])>=51 && Read(handles[7],0,1,s.ema50);
      s.ema200Valid=BarsCalculated(handles[8])>=201 && Read(handles[8],0,1,s.ema200);
      int bbShift=InpRequireCandleConfirmation?1:0;
      s.bbValid=BarsCalculated(handles[9])>=EvoBBPeriod+bbShift &&
                Read(handles[9],0,bbShift,s.bbMiddle) && Read(handles[9],1,bbShift,s.bbUpper) && Read(handles[9],2,bbShift,s.bbLower) &&
                s.bbUpper>=s.bbMiddle && s.bbMiddle>=s.bbLower;
      s.bbPreviousValid=BarsCalculated(handles[9])>=EvoBBPeriod+bbShift+1 &&
                        Read(handles[9],1,bbShift+1,s.bbPreviousUpper) && Read(handles[9],2,bbShift+1,s.bbPreviousLower);
      // OBV always uses closed bars, even when the base strategy evaluates live prices.
      MqlRates obvBars[]; ArraySetAsSeries(obvBars,true);
      double obvOlder=0;
      if(CopyRates(symbol,timeframe,1,EvoOBVLookback+1,obvBars)==EvoOBVLookback+1 &&
         BarsCalculated(handles[10])>=EvoOBVLookback+2 &&
         Read(handles[10],0,1,s.obv) && Read(handles[10],0,1+EvoOBVLookback,obvOlder))
      {
         double volumeSum=0;
         for(int j=0;j<EvoOBVLookback;j++)
            volumeSum+=(double)(EvoOBVVolume==VOLUME_REAL?obvBars[j].real_volume:obvBars[j].tick_volume);
         s.obvValid=volumeSum>0;
         s.obvVolumeSum=volumeSum;
         s.obvDelta=s.obv-obvOlder;
         s.obvPriceDelta=obvBars[0].close-obvBars[EvoOBVLookback].close;
      }
      for(int frame=0;frame<3;frame++) higher.Update(frame,s.mtf[frame]);
      ReadVisualClosed(s);
      EvoEvaluate(s,SymbolInfoDouble(symbol,SYMBOL_POINT));
      EvoFillLocalRegime(s,symbol,timeframe,false);
      return true;
   }
};
#endif
