#ifndef EVO_MARKET_EVIDENCE
#define EVO_MARKET_EVIDENCE
input group "Lectura de impulso y canal - diagnostico"
input int EvoChannelLookback=64; // Velas cerradas; envolvente de regresion, no prediccion
input double EvoMomentumMinHistATR=0.02;
input double EvoMomentumMinMoveATR=0.25;
struct EvoMarketEvidence
{
   bool valid;
   datetime bar,first;
   double macd,signal,hist,previousHist,roc,rocATR;
   double channelFirst,channelLast,channelLowOffset,channelHighOffset,rangeLow,rangeHigh;
   int momentum,structure,pivotHighs,pivotLows;
   int referenceSide,confirmation,breakCloses;
   double invalidation,confirmationMargin;
   string confirmationDetail;
   int broadSide,recentSide,recentHighs,recentLows,recentState;
   double recentHigh,recentLow;
   string layersDetail;
   int recentBreakSide,recentBreakPhase;
   datetime recentBreakTime;
   double recentBreakLevel;
};
int EvoLiveDirection(const double displacementATR)
{ return displacementATR>.05?1:displacementATR<-.05?-1:0; }
int EvoLiveStrength(const double displacementATR)
{ double magnitude=MathAbs(displacementATR); return magnitude>=2?3:magnitude>=1?2:magnitude>=.25?1:0; }
int EvoEvidenceSign(const double value,const double threshold)
{ return value>threshold?1:value< -threshold?-1:0; }
int EvoEvidenceMomentum(const double histATR,const double moveATR)
{
   int h=EvoEvidenceSign(histATR,EvoMomentumMinHistATR),r=EvoEvidenceSign(moveATR,EvoMomentumMinMoveATR);
   return h!=0 && h==r?h:0;
}
int EvoEvidenceAdjustment(const int side,const int momentum)
{ return side==0 || momentum==0?0:side==momentum?10:-10; }
string EvoEvidenceDirection(const int side)
{ return side>0?"ALCISTA":side<0?"BAJISTA":"SIN CONSENSO"; }
string EvoEvidencePosition(const int side,const int momentum)
{ return momentum==0?"impulso mixto/debil":side==momentum?"impulso a favor":"impulso contrario: vigilar retroceso"; }
// Diagnostic decision gate: indicators alone never create an actionable setup.
int EvoEvidenceEntryGate(const bool regimeReady,const int side,const int momentum,const bool mtfMissing,
                         const bool mtfOpposed,const bool levelReady,const bool candleReady,
                         const bool roomReady,const double roomATR,const double minRoomATR)
{
   if(mtfMissing) return 1;
   if(!regimeReady || side==0) return 2;
   if(mtfOpposed) return 3;
   if(momentum!=side) return 4;
   if(!levelReady) return 5;
   if(!candleReady) return 6;
   if(!roomReady || roomATR<minRoomATR) return 7;
   return 0;
}
string EvoEvidenceGateReason(const int gate)
{
   if(gate==1) return "FALTAN DATOS CERRADOS";
   if(gate==2) return "TRANSICION O CONSOLIDACION: ESPERAR ESTRUCTURA";
   if(gate==3) return "CONFLICTO DE ESTRUCTURA O TEMPORALIDADES";
   if(gate==4) return "MACD/ROC NO CONFIRMAN LA DIRECCION";
   if(gate==5) return "LEJOS DEL NIVEL: NO PERSEGUIR PRECIO";
   if(gate==6) return "FALTA CONFIRMACION DE VELA EN EL NIVEL";
   if(gate==7) return "ESPACIO AL OBSTACULO INSUFICIENTE O N/D";
   return "CONFLUENCIA CERRADA; EVALUAR PLAN Y RIESGO";
}
void EvoEvidenceEMA(const double &values[],const int period,double &result[])
{
   int n=ArraySize(values); ArrayResize(result,n); ArrayInitialize(result,0);
   if(n<period) return;
   double sum=0; for(int i=0;i<period;i++) sum+=values[i]; result[period-1]=sum/period;
   for(int i=period;i<n;i++) result[i]=result[i-1]+2.0/(period+1)*(values[i]-result[i-1]);
}
// Chronological closed bars; no future pivot or live bar is accepted.
void EvoEvidenceStructure(const MqlRates &rates[],const int start,int &side,int &highs,int &lows)
{
   side=0; highs=0; lows=0;
   double highOld=0,highNew=0,lowOld=0,lowNew=0;
   int n=ArraySize(rates);
   for(int i=start+2;i<n-2;i++)
   {
      bool hi=true,lo=true;
      for(int j=1;j<=2;j++)
      {
         if(rates[i].high<=rates[i-j].high || rates[i].high<rates[i+j].high) hi=false;
         if(rates[i].low>=rates[i-j].low || rates[i].low>rates[i+j].low) lo=false;
      }
      if(hi) { highOld=highNew; highNew=rates[i].high; highs++; }
      if(lo) { lowOld=lowNew; lowNew=rates[i].low; lows++; }
   }
   if(highs>=2 && lows>=2)
      side=highNew>highOld && lowNew>lowOld?1:highNew<highOld && lowNew<lowOld?-1:0;
}
void EvoEvidenceChannel(const MqlRates &rates[],const int start,EvoMarketEvidence &e)
{
   int n=ArraySize(rates),count=n-start;
   double meanX=(count-1)*0.5,meanY=0,num=0,den=0;
   for(int i=start;i<n;i++) meanY+=rates[i].close;
   meanY/=count;
   for(int i=start;i<n;i++) { double x=i-start-meanX; num+=x*(rates[i].close-meanY); den+=x*x; }
   double slope=den>0?num/den:0;
   e.channelFirst=meanY-slope*meanX; e.channelLast=e.channelFirst+slope*(count-1);
   e.channelLowOffset=DBL_MAX; e.channelHighOffset=-DBL_MAX;
   e.rangeLow=DBL_MAX; e.rangeHigh=-DBL_MAX;
   for(int i=start;i<n;i++)
   {
      double center=e.channelFirst+slope*(i-start);
      e.channelLowOffset=MathMin(e.channelLowOffset,rates[i].low-center);
      e.channelHighOffset=MathMax(e.channelHighOffset,rates[i].high-center);
      e.rangeLow=MathMin(e.rangeLow,rates[i].low); e.rangeHigh=MathMax(e.rangeHigh,rates[i].high);
   }
   e.first=rates[start].time;
}
EvoMarketEvidence evoEvidenceCache;
string evoEvidenceCacheSymbol="";
ENUM_TIMEFRAMES evoEvidenceCachePeriod=PERIOD_CURRENT;
// Reference excludes the two candles being checked: the envelope cannot absorb their break.
void EvoEvidenceConfirm(const MqlRates &rates[],const double atr,EvoMarketEvidence &e)
{
   int n=ArraySize(rates),count=EvoChannelLookback;
   MqlRates prior[]; ArrayResize(prior,count);
   for(int i=0;i<count;i++) prior[i]=rates[n-count-2+i];
   int highs=0,lows=0,side=0;
   EvoEvidenceStructure(prior,0,side,highs,lows); e.referenceSide=side;
   if(side==0 || highs<2 || lows<2) { e.confirmationDetail="Sin tendencia previa confirmada por dos maximos y minimos. No distinguir retroceso/reversion."; return; }
   double pivot=0;
   for(int i=2;i<count-2;i++)
   {
      bool valid=true;
      for(int j=1;j<=2;j++)
         if(side<0?(prior[i].high<=prior[i-j].high || prior[i].high<prior[i+j].high):(prior[i].low>=prior[i-j].low || prior[i].low>prior[i+j].low)) valid=false;
      if(valid) pivot=side<0?prior[i].high:prior[i].low;
   }
   EvoMarketEvidence channel; ZeroMemory(channel); EvoEvidenceChannel(prior,0,channel);
   double slope=(channel.channelLast-channel.channelFirst)/(count-1);
   e.invalidation=pivot; e.confirmationMargin=0.10*atr;
   int channelBreaks=0;
   for(int i=0;i<2;i++)
   {
      double close=rates[n-2+i].close;
      double edge=channel.channelLast+slope*(i+1)+(side<0?channel.channelHighOffset:channel.channelLowOffset);
      if(-side*(close-pivot)>e.confirmationMargin) e.breakCloses++;
      if(-side*(close-edge)>e.confirmationMargin) channelBreaks++;
   }
   bool adverse=side*(rates[n-1].close-rates[n-2].close)<0;
   e.confirmation=e.breakCloses==2 && channelBreaks==2 && e.momentum==-side?3:
      e.breakCloses>0 || channelBreaks>0?2:adverse?1:4;
   e.confirmationDetail=StringFormat("Referencia %s: %s. Pivote %.5f; margen 0.10 ATR (%.5f). Cierres contra pivote %d/2; contra canal previo %d/2; MACD/ROC %s. Canal calculado antes de las dos velas evaluadas. Diagnostico local, no tesis de entrada ni orden de cierre.",
      EvoEvidenceDirection(side),TimeToString(prior[count-1].time,TIME_DATE|TIME_MINUTES),pivot,e.confirmationMargin,e.breakCloses,channelBreaks,EvoEvidenceDirection(e.momentum));
}
string EvoEvidenceConfirmation(const EvoMarketEvidence &e)
{
   if(!e.valid || e.referenceSide==0) return "CONFIRMACION: DATOS / ESTRUCTURA INSUFICIENTES";
   string prior=" | estructura previa "+EvoEvidenceDirection(e.referenceSide);
   string opposite=EvoEvidenceDirection(-e.referenceSide);
   if(e.confirmation==3) return "RUPTURA "+opposite+" CONFIRMADA; POSIBLE GIRO"+prior;
   if(e.confirmation==2) return "POSIBLE RUPTURA "+opposite+"; FALTA CONFIRMACION"+prior;
   if(e.confirmation==1) return "MOVIMIENTO "+opposite+"; POSIBLE CORRECCION, SIN RUPTURA"+prior;
   return "SIN RUPTURA CONTRARIA"+prior;
}
int EvoLayerState(const int side,const double previous,const double close,const double high,const double low,const double margin)
{
   if(side==0 || high<=0 || low<=0) return 0;
   bool up=previous>high+margin && close>high+margin;
   bool down=previous<low-margin && close<low-margin;
   if(side<0) return up?3:down?4:close>previous?1:2;
   return down?3:up?4:close<previous?1:2;
}
void EvoEvidenceLayers(const MqlRates &rates[],const double atr,EvoMarketEvidence &e)
{
   int n=ArraySize(rates); e.broadSide=EvoEvidenceSign((e.channelLast-e.channelFirst)/atr,.25);
   MqlRates local[]; ArrayResize(local,24);
   // Last two closed candles are checked against a reference that excludes them.
   for(int i=0;i<24;i++) local[i]=rates[n-26+i];
   EvoEvidenceStructure(local,0,e.recentSide,e.recentHighs,e.recentLows);
   for(int i=2;i<22;i++)
   {
      bool high=true,low=true;
      for(int j=1;j<=2;j++)
      {
         if(local[i].high<=local[i-j].high || local[i].high<local[i+j].high) high=false;
         if(local[i].low>=local[i-j].low || local[i].low>local[i+j].low) low=false;
      }
      if(high) e.recentHigh=local[i].high;
      if(low) e.recentLow=local[i].low;
   }
   e.recentState=EvoLayerState(e.recentSide,rates[n-2].close,rates[n-1].close,e.recentHigh,e.recentLow,.10*atr);
   e.layersDetail=StringFormat("Contexto amplio: pendiente del canal en %d cierres, desplazamiento minimo 0.25 ATR; no implica estructura vigente. Reciente: 24 cierres de referencia excluyendo los dos evaluados, dos maximos/minimos confirmados 2+2. Ultimo maximo %.5f; minimo %.5f. Confirmacion: dos cierres fuera del pivote + margen 0.10 ATR (%.5f). No exige MACD/ROC; se muestran aparte. Referencia movil, no tesis de entrada.",EvoChannelLookback,e.recentHigh,e.recentLow,.10*atr);
}
string EvoLayerBroad(const EvoMarketEvidence &e)
{ return !e.valid?"CONTEXTO AMPLIO: N/D":"CANAL "+(string)EvoChannelLookback+": "+(e.broadSide==0?"LATERAL / SIN PENDIENTE":EvoEvidenceDirection(e.broadSide))+" | canal principal"; }
string EvoLayerRecent(const EvoMarketEvidence &e)
{ return !e.valid?"ESTRUCTURA RECIENTE: N/D":"ESTRUCTURA 24: "+(e.recentHighs<2 || e.recentLows<2?"PIVOTES INSUFICIENTES":EvoEvidenceDirection(e.recentSide))+((e.recentHigh>0 && e.recentLow>0)?StringFormat(" | > %.*f / < %.*f",_Digits,e.recentHigh+e.confirmationMargin,_Digits,e.recentLow-e.confirmationMargin):""); }
string EvoLayerConfirmation(const EvoMarketEvidence &e)
{
   if(!e.valid || e.recentState==0) return "CONFIRMACION: estructura mixta o insuficiente";
   if(e.recentState==3) return "RUPTURA CONTRARIA CONFIRMADA; POSIBLE GIRO LOCAL";
   if(e.recentState==4) return "CONTINUACION LOCAL CONFIRMADA";
   if(e.recentState==1) return e.recentSide<0?"REBOTE ALCISTA AUN SIN CONFIRMAR":"RETROCESO BAJISTA AUN SIN RUPTURA";
   return "SIN NUEVA RUPTURA; VIGILAR PIVOTES";
}
void EvoRecentBreak(const MqlRates &rates[],const double atr,EvoMarketEvidence &e)
{
   int n=ArraySize(rates);
   for(int i=n-8;i<n;i++)
   {
      double low=DBL_MAX,high=-DBL_MAX;
      for(int j=i-24;j<i;j++) { low=MathMin(low,rates[j].low); high=MathMax(high,rates[j].high); }
      int side=rates[i].close<low-.10*atr?-1:rates[i].close>high+.10*atr?1:0;
      if(side==0) continue;
      e.recentBreakSide=side; e.recentBreakTime=rates[i].time; e.recentBreakLevel=side<0?low:high;
      e.recentBreakPhase=1;
      for(int j=i+1;j<n;j++)
      {
         if(side*(rates[j-1].close-e.recentBreakLevel)>.10*atr && side*(rates[j].close-e.recentBreakLevel)>.10*atr) e.recentBreakPhase=2;
      }
      if(side*(rates[n-1].close-e.recentBreakLevel)<-.10*atr) e.recentBreakPhase=3;
   }
}
string EvoRecentBreakText(const EvoMarketEvidence &e)
{
   if(!e.valid || e.recentBreakSide==0) return "RUPTURA RECIENTE: ninguna por cierre en 8 velas";
   return StringFormat("RUPTURA %s %s | nivel %.*f | %s",e.recentBreakSide<0?"BAJISTA":"ALCISTA",TimeToString(e.recentBreakTime,TIME_MINUTES),_Digits,e.recentBreakLevel,e.recentBreakPhase==3?"NIVEL RECUPERADO":e.recentBreakPhase==2?"2 CIERRES FUERA":"1 CIERRE FUERA");
}
bool EvoReadMarketEvidence(const string symbol,const ENUM_TIMEFRAMES timeframe,const double atr,EvoMarketEvidence &e)
{
   ZeroMemory(e);
   datetime bar=iTime(symbol,timeframe,1);
   if(bar<=0 || atr<=0) return false;
   if(evoEvidenceCache.valid && evoEvidenceCache.bar==bar && evoEvidenceCacheSymbol==symbol && evoEvidenceCachePeriod==timeframe)
   { e=evoEvidenceCache; return true; }
   MqlRates rates[]; int n=CopyRates(symbol,timeframe,1,MathMax(1000,EvoChannelLookback+2),rates);
   if(n<MathMax(250,EvoChannelLookback+2) || rates[n-1].time!=bar) return false;
   double closes[],fast[],slow[],macds[],signal[];
   ArrayResize(closes,n); for(int i=0;i<n;i++) closes[i]=rates[i].close;
   EvoEvidenceEMA(closes,12,fast); EvoEvidenceEMA(closes,26,slow); ArrayResize(macds,n-25);
   for(int i=25;i<n;i++) macds[i-25]=fast[i]-slow[i];
   EvoEvidenceEMA(macds,9,signal);
   e.macd=macds[n-26]; e.signal=signal[n-26]; e.hist=e.macd-e.signal;
   e.previousHist=macds[n-27]-signal[n-27];
   e.roc=(closes[n-1]/closes[n-13]-1)*100; e.rocATR=(closes[n-1]-closes[n-13])/atr;
   e.momentum=EvoEvidenceMomentum(e.hist/atr,e.rocATR);
   EvoEvidenceStructure(rates,n-EvoChannelLookback,e.structure,e.pivotHighs,e.pivotLows);
   EvoEvidenceChannel(rates,n-EvoChannelLookback,e);
   EvoEvidenceConfirm(rates,atr,e);
   EvoEvidenceLayers(rates,atr,e);
   EvoRecentBreak(rates,atr,e);
   if(iTime(symbol,timeframe,1)!=bar) return false;
   e.bar=bar; e.valid=true;
   evoEvidenceCache=e; evoEvidenceCacheSymbol=symbol; evoEvidenceCachePeriod=timeframe;
   return true;
}
#endif
