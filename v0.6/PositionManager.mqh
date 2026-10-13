#ifndef EVOLUTION_POSITION_MANAGER
#define EVOLUTION_POSITION_MANAGER
#include <Trade/Trade.mqh>
#include "PositionRules.mqh"
#include "TargetRules.mqh"
#include "EvolutionJournal.mqh"
input group "Gestion compartida - SL / TP"
input double EvoSLATR = 1.5;
input double EvoRR = 2.0;
enum ENUM_EVO_TP_MODE { EVO_TP_RR=0, EVO_TP_ATR=1 };
input ENUM_EVO_TP_MODE EvoTPMode = EVO_TP_RR;
input double EvoTPATR = 3.0; // Distancia TP independiente del SL cuando el modo es ATR
input bool EvoSetMissingSL = true;
input bool EvoSetMissingTP = true;
input group "Gestion compartida - Proteccion incremental"
input bool EvoIncremental = true;
input double EvoStage1TriggerR = 0.40;
input double EvoStage1StopR = -0.15;
input double EvoStage2TriggerR = 0.70;
input double EvoStage2StopR = 0.05;
input double EvoStage3TriggerR = 1.00;
input double EvoStage3StopR = 0.30;
input group "Gestion compartida - BE y trailing"
input bool EvoBreakEven = true;
input double EvoBETriggerATR = 1.0;
input double EvoBEOffsetATR = 0.0;
input bool EvoTrailing = true;
input bool EvoTrailingAfterBE = true;
input double EvoTrailingTriggerATR = 0.0;
input double EvoTrailingDistanceATR = 0.5;
input int EvoTrailingStepPoints = 5;
input group "Gestion compartida - Smart Exit"
input bool EvoSmartExit = true;
input bool EvoSmartClose = true; // false: proteger SL
input double EvoSmartMinProfitR = 0.70;
input int EvoSmartScore = 5;
input int EvoSmartLookback = 50;
input double EvoSmartSRATR = 0.25;
input double EvoSmartADXDrop = 8.0;
input double EvoSmartATRContract = 0.75;
input double EvoSmartOffsetATR = 0.0;
input int EvoDeviationPoints = 20;

#include "SafeManagementInputs.mqh"
#ifdef EVO_MONITOR_SAFE_INPUTS
#include "EconomicBreakEven.mqh"
#endif

// Optional per-instance monitor override; automatic advisors retain their input.
bool evoTrailingPaused=false;
bool evoRiskProtectionPaused=false;
bool evoSmartExitPaused=false;
double evoTrailingOverride=0.0;
double evoBETriggerOverride=1.0;
bool evoLevelsInitialized=false,evoPanelBEEnabled=true;
bool evoStageEnabled[3];
double evoStageTrigger[3],evoStageStop[3];
void EvoInitLevels()
{
   if(evoLevelsInitialized) return;
   evoLevelsInitialized=true; evoPanelBEEnabled=EvoBreakEven; evoBETriggerOverride=EvoBETriggerATR;
#ifdef EVO_MONITOR_SAFE_INPUTS
   evoBEMinOverride=EvoBEMinNetProfit;
#endif
   for(int i=0;i<3;i++) evoStageEnabled[i]=EvoIncremental;
   evoStageTrigger[0]=EvoStage1TriggerR; evoStageTrigger[1]=EvoStage2TriggerR; evoStageTrigger[2]=EvoStage3TriggerR;
   evoStageStop[0]=EvoStage1StopR; evoStageStop[1]=EvoStage2StopR; evoStageStop[2]=EvoStage3StopR;
}
bool EvoLevelsValid(const double &triggers[],const double &stops[])
{
   for(int i=0;i<3;i++)
   {
      if(!MathIsValidNumber(triggers[i]) || !MathIsValidNumber(stops[i]) || triggers[i]<=0 || stops[i]>=triggers[i]) return false;
      if(i>0 && (triggers[i]<triggers[i-1] || stops[i]<stops[i-1])) return false;
   }
   return true;
}
double EvoEffectiveTrailingATR() { return evoTrailingOverride>0?evoTrailingOverride:EvoTrailingDistanceATR; }

bool EvoValidManagementInputs()
{
#ifdef EVO_MONITOR_SAFE_INPUTS
   if(!MathIsValidNumber(EvoBEMinNetProfit) || EvoBEMinNetProfit<0) return false;
#endif
   return (EvoTPMode==EVO_TP_RR || EvoTPMode==EVO_TP_ATR) && MathIsValidNumber(EvoTPATR) && EvoTPATR>0 && EvoSLATR>0 && EvoRR>0 && EvoBETriggerATR>=0 && EvoBEOffsetATR>=0 &&
          EvoTrailingTriggerATR>=0 && EvoTrailingDistanceATR>0 && EvoTrailingStepPoints>=0 &&
          EvoStage1TriggerR>=0 && EvoStage2TriggerR>=EvoStage1TriggerR && EvoStage3TriggerR>=EvoStage2TriggerR &&
          EvoStage1StopR<EvoStage1TriggerR && EvoStage2StopR<EvoStage2TriggerR && EvoStage3StopR<EvoStage3TriggerR &&
          EvoStage2StopR>=EvoStage1StopR && EvoStage3StopR>=EvoStage2StopR &&
          EvoSmartMinProfitR>=0 && EvoSmartScore>0 && EvoSmartLookback>1 && EvoSmartLookback<=10000 &&
          EvoSmartSRATR>=0 && EvoSmartADXDrop>0 && EvoSmartATRContract>=0 && EvoSmartOffsetATR>=0 && EvoDeviationPoints>=0;
}

int EvoExitEvidence(const string symbol,const bool buy,const double price,const EvoSnapshot &s,
                    bool &confirmed,datetime &closedBar,string &details)
{
   confirmed=false; closedBar=0; details="";
   if(!EvoSmartExit) return 0;
   MqlRates bars[]; ArraySetAsSeries(bars,true);
   if(CopyRates(symbol,PERIOD_CURRENT,1,MathMax(3,EvoSmartLookback),bars)!=MathMax(3,EvoSmartLookback)) return -1;
   double barrier=buy?bars[0].high:bars[0].low;
   for(int i=1;i<EvoSmartLookback;i++) barrier=buy?MathMax(barrier,bars[i].high):MathMin(barrier,bars[i].low);
   closedBar=bars[0].time;
   confirmed=EvoSmartDeterioration(buy,bars[0].open,bars[0].close,bars[1].open,bars[1].close,bars[2].low,bars[2].high);
   int score=0;
   if(EvoSmartSRATR>0 && (buy?price>=barrier-s.atr[0]*EvoSmartSRATR:price<=barrier+s.atr[0]*EvoSmartSRATR)) { score+=2; details+="zona extremo +2; "; }
   double body=MathAbs(bars[0].close-bars[0].open), range=bars[0].high-bars[0].low;
   if(range>0 && body>=range*0.55 && (buy?bars[0].close<bars[0].open:bars[0].close>bars[0].open)) { score+=3; details+="vela contraria fuerte +3; "; }
   if(buy?(bars[0].high>=barrier && bars[0].close<barrier):(bars[0].low<=barrier && bars[0].close>barrier)) { score+=2; details+="rechazo extremo +2; "; }
   if(s.adx[2]-s.adx[0]>=EvoSmartADXDrop) { score+=2; details+="caida ADX +2; "; }
   if(s.average[0]>0 && s.atr[0]<=s.average[0]*EvoSmartATRContract) { score++; details+="contraccion ATR +1; "; }
   if(buy?s.rsi[0]>=75:s.rsi[0]<=25) { score++; details+="RSI extremo +1; "; }
   return score;
}

int EvoExitScore(const string symbol,const bool buy,const double price,const EvoSnapshot &s)
{
   bool confirmed; datetime closedBar; string details;
   return EvoExitEvidence(symbol,buy,price,s,confirmed,closedBar,details);
}

class CEvoPositionManager
{
private:
   CTrade trader;
   string owned[];
   datetime lastWarning;
   string lastStopError;
   double Owner() { return (double)(ChartID()%9007199254740991); }
   string AccountScope()
   {
      string server=AccountInfoString(ACCOUNT_SERVER);
      uint hash=2166136261;
      for(int i=0;i<StringLen(server);i++) hash=(hash^(uint)StringGetCharacter(server,i))*16777619;
      return StringFormat("%u.%I64d",hash,AccountInfoInteger(ACCOUNT_LOGIN));
   }
   void Warn(const ulong ticket,const string reason)
   {
      lastStopError=reason;
      if(TimeCurrent()-lastWarning<30) return;
      lastWarning=TimeCurrent(); Print("Evolucion | ",ticket," | gestion pendiente: ",reason);
      EvoJournal("PENDIENTE",ticket,reason);
   }
   string RiskKey(const ulong id,const long type)
   { return StringFormat("EVR.%s.%I64u.%d",AccountScope(),id,(int)type); }
   bool Claim(const ulong id,const bool manualPriority=false)
   {
      string key=StringFormat("EVL.%s.%I64u",AccountScope(),id);
      // Terminal event handlers are serial per EA; CAS arbitrates across charts.
      if(!GlobalVariableCheck(key)) GlobalVariableTemp(key);
      double owner=GlobalVariableGet(key);
      if(owner==Owner()) return true;
      if(owner!=0)
      {
         long chart=ChartFirst(); bool live=false;
         while(chart>=0) { if((double)(chart%9007199254740991)==owner) { live=true; break; } chart=ChartNext(chart); }
         if(live && !manualPriority) { Warn(id,"otro grafico es responsable de esta posicion"); return false; }
      }
      if(!GlobalVariableSetOnCondition(key,Owner(),owner)) { Warn(id,"control cambiado por otro grafico; reintentando"); return false; }
      if(manualPriority && owner!=0) EvoJournal("CONTROL_MANUAL_GESTION",id,"Control transferido a este grafico por accion explicita del operador");
      int n=ArraySize(owned); ArrayResize(owned,n+1); owned[n]=key; return true;
   }
   bool Modify(const ulong ticket,const string symbol,const bool buy,double sl,const double tp,const string reason)
   {
      if(!PositionSelectByTicket(ticket)) return false;
      double old=PositionGetDouble(POSITION_SL), point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      double tick=SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE);
      if(tick<=0 || point<=0) return false;
      sl=NormalizeDouble((buy?MathFloor(sl/tick+1e-8):MathCeil(sl/tick-1e-8))*tick,(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS));
      MqlTick q; if(!SymbolInfoTick(symbol,q) || q.bid<=0 || q.ask<=0) return false;
      double gap=(double)MathMax(SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL),SymbolInfoInteger(symbol,SYMBOL_TRADE_FREEZE_LEVEL))*point+tick;
      if(reason=="Trailing ATR")
      {
         // Follow at the closest legal distance when requested ATR is inside broker limits.
         double limit=buy?MathFloor((q.bid-gap)/tick+1e-8)*tick:MathCeil((q.ask+gap)/tick-1e-8)*tick;
         sl=NormalizeDouble(buy?MathMin(sl,limit):MathMax(sl,limit),(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS));
      }
      if(sl<=0 || (old>0 && (MathAbs(sl-old)<tick*0.5 || !EvoBetter(buy,old,sl)))) return false;
      if(buy?(sl>q.bid-gap):(sl<q.ask+gap)) { Warn(ticket,"SL fuera de stops/freeze; se conserva la propuesta tecnica"); return false; }
      if(tp>0 && (buy?tp<q.bid+gap:tp>q.ask-gap)) { Warn(ticket,"TP dentro de stops/freeze"); return false; }
      bool ok=trader.PositionModify(ticket,sl,tp);
      uint rc=trader.ResultRetcode();
      bool accepted=ok && (rc==TRADE_RETCODE_DONE || rc==TRADE_RETCODE_NO_CHANGES);
      bool confirmed=accepted && PositionSelectByTicket(ticket) && MathAbs(PositionGetDouble(POSITION_SL)-sl)<tick*0.5;
      Print("Evolucion | ",ticket," | ",reason," | SL=",sl," | confirmado=",confirmed," | retcode=",rc);
      EvoJournal(confirmed?"SL_CONFIRMADO":"SL_FALLO",ticket,
                 StringFormat("%s; anterior=%.8f; propuesto=%.8f; TP=%.8f; retcode=%u",reason,old,sl,tp,rc));
      if(!confirmed) lastStopError=StringFormat("Broker %u: %s",rc,trader.ResultRetcodeDescription());
      return confirmed;
   }
public:
   string LastStopError() { return lastStopError; }
   bool HasControl(const ulong ticket)
   {
      if(!PositionSelectByTicket(ticket)) return false;
      string key=StringFormat("EVL.%s.%I64u",AccountScope(),(ulong)PositionGetInteger(POSITION_IDENTIFIER));
      if(!GlobalVariableCheck(key)) return true;
      double owner=GlobalVariableGet(key);
      return owner==0 || owner==Owner();
   }
   bool TakeManualControl(const ulong ticket)
   {
      if(!PositionSelectByTicket(ticket) || PositionGetString(POSITION_SYMBOL)!=_Symbol) return false;
      return Claim((ulong)PositionGetInteger(POSITION_IDENTIFIER),true);
   }
   string Scope() { return AccountScope(); }
   bool ManualStop(const ulong ticket,const double proposed,const string reason,const bool manualPriority=false)
   {
      lastStopError="Posicion no disponible o SL sin mejora";
      if(!PositionSelectByTicket(ticket) || PositionGetString(POSITION_SYMBOL)!=_Symbol) return false;
      ulong id=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
      if(!Claim(id,manualPriority)) return false;
      long type=PositionGetInteger(POSITION_TYPE); bool buy=type==POSITION_TYPE_BUY;
      double sl=PositionGetDouble(POSITION_SL),entry=PositionGetDouble(POSITION_PRICE_OPEN);
      if(!EvoBetter(buy,sl,proposed)) return false;
      // Preserve initial R before a manual jump crosses the entry price.
      string key=RiskKey(id,type);
      double risk=buy?entry-sl:sl-entry;
      if(sl>0 && risk>0 && !GlobalVariableCheck(key)) GlobalVariableSet(key,risk);
      trader.SetExpertMagicNumber(PositionGetInteger(POSITION_MAGIC));
      trader.SetDeviationInPoints(EvoDeviationPoints); trader.SetTypeFillingBySymbol(_Symbol);
      return Modify(ticket,_Symbol,buy,proposed,PositionGetDouble(POSITION_TP),reason);
   }
   void Release()
   {
      for(int i=0;i<ArraySize(owned);i++)
         GlobalVariableSetOnCondition(owned[i],0,Owner());
      ArrayResize(owned,0);
   }
   void Process(const ulong ticket,const EvoSnapshot &s,const bool analysisValid=true)
   {
      if(!PositionSelectByTicket(ticket)) return;
      string symbol=PositionGetString(POSITION_SYMBOL);
      if(symbol!=_Symbol || s.atr[0]<=0) return;
      ulong id=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
      if(!Claim(id)) return;
      trader.SetDeviationInPoints(EvoDeviationPoints); trader.SetTypeFillingBySymbol(symbol);
      trader.SetExpertMagicNumber(PositionGetInteger(POSITION_MAGIC));
      long type=PositionGetInteger(POSITION_TYPE); bool buy=type==POSITION_TYPE_BUY;
      double entry=PositionGetDouble(POSITION_PRICE_OPEN), sl=PositionGetDouble(POSITION_SL), tp=PositionGetDouble(POSITION_TP);
      double sign=buy?1.0:-1.0, atr=s.atr[0], point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      double tick=SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE);
      if(tick<=0 || entry<=0) return;
      MqlTick q; if(!SymbolInfoTick(symbol,q) || q.bid<=0 || q.ask<=0) return;
      double price=buy?q.bid:q.ask;
      string key=RiskKey(id,type);
      double risk=GlobalVariableCheck(key)?GlobalVariableGet(key):0;
      // Reductions keep original R; additions/repricing need a new explicit baseline.
      double volume=PositionGetDouble(POSITION_VOLUME);
      if(GlobalVariableCheck(key+".E") &&
         (MathAbs(GlobalVariableGet(key+".E")-entry)>tick*0.5 ||
          volume>GlobalVariableGet(key+".V")+1e-8))
      { Warn(ticket,"volumen aumentado o entrada recalculada; revisar base de riesgo"); return; }
      if(!GlobalVariableCheck(key+".E"))
      { GlobalVariableSet(key+".E",entry); GlobalVariableSet(key+".V",volume); }
      else if(volume<GlobalVariableGet(key+".V")) GlobalVariableSet(key+".V",volume);
      // Persist only an observed initial risk-side stop; never infer R from a protected stop.
      if(risk<=0 && sl>0 && sign*(entry-sl)>0)
      { risk=sign*(entry-sl); GlobalVariableSet(key,risk); }
      double targetSL=sl, targetTP=tp;
      if(sl<=0 && EvoSetMissingSL) targetSL=entry-sign*atr*EvoSLATR;
      double initialRisk=targetSL>0?sign*(entry-targetSL):0;
      if(tp<=0 && EvoSetMissingTP && (EvoTPMode==EVO_TP_ATR || risk>0 || initialRisk>0))
         targetTP=NormalizeDouble(MathRound((entry+sign*EvoTargetDistance(EvoTPMode==EVO_TP_ATR,atr,EvoTPATR,(risk>0?risk:initialRisk),EvoRR))/tick)*tick,(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS));
      if(targetSL!=sl || targetTP!=tp)
      {
         if(Modify(ticket,symbol,buy,targetSL,targetTP,"SL/TP inicial"))
         {
            if(PositionSelectByTicket(ticket))
            {
               sl=PositionGetDouble(POSITION_SL);
               if(risk<=0 && sign*(entry-sl)>0) GlobalVariableSet(key,sign*(entry-sl));
            }
         }
         return;
      }
      if(risk<=0) { Warn(ticket,"riesgo inicial desconocido; SL protegido sin historial Evolucion"); return; }
      EvoProtection p;
      p.incremental=EvoIncremental && !evoRiskProtectionPaused; p.t1=EvoStage1TriggerR; p.s1=EvoStage1StopR;
      p.t2=EvoStage2TriggerR; p.s2=EvoStage2StopR; p.t3=EvoStage3TriggerR; p.s3=EvoStage3StopR;
      p.be=EvoBreakEven && !evoRiskProtectionPaused; p.beTrigger=EvoBETriggerATR; p.beOffset=EvoBEOffsetATR*atr;
#ifdef EVO_MONITOR_SAFE_INPUTS
      EvoInitLevels();
      p.incremental=!evoRiskProtectionPaused;
      p.t1=evoStageEnabled[0]?evoStageTrigger[0]:0; p.s1=evoStageStop[0];
      p.t2=evoStageEnabled[1]?evoStageTrigger[1]:0; p.s2=evoStageStop[1];
      p.t3=evoStageEnabled[2]?evoStageTrigger[2]:0; p.s3=evoStageStop[2];
      p.be=evoPanelBEEnabled && !evoRiskProtectionPaused; p.beTrigger=evoBETriggerOverride;
#endif
      p.trailing=EvoTrailing && !evoTrailingPaused; p.afterBE=EvoTrailingAfterBE; p.trailTrigger=EvoTrailingTriggerATR;
      p.trailDistance=EvoEffectiveTrailingATR(); p.step=EvoTrailingStepPoints*point;
#ifdef EVO_MONITOR_SAFE_INPUTS
      // Both BE paths use account-currency profit plus estimated costs.
      double economicBE=0,beMoney=0;
      bool economicValid=EvoBECosts(id,volume,PositionGetDouble(POSITION_SWAP),beMoney) &&
         EvoBEPrice(buy,entry,volume,beMoney,economicBE);
      if(economicValid)
      {
         p.beOffset=MathMax(p.beOffset,sign*(economicBE-entry));
         double beTarget=entry+sign*p.beOffset;
         double beGap=(double)MathMax(SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL),SymbolInfoInteger(symbol,SYMBOL_TRADE_FREEZE_LEVEL))*point+tick;
         if(sign*(price-beTarget)<beGap) p.be=false;
      }
      else
      {
         p.be=false;
         if(p.afterBE) p.trailing=false;
         if(EvoBreakEven) Warn(ticket,"BE economico pendiente: costos o precio no disponibles");
      }
#endif
      p.smart=EvoSmartExit; p.closeSmart=EvoSmartClose; p.smartThreshold=EvoSmartScore;
      p.smartMinR=EvoSmartMinProfitR; p.smartOffset=EvoSmartOffsetATR*atr;
      int smartScore=-1; bool smartConfirmed=false; datetime smartBar=0; string smartDetails="";
      if(analysisValid && p.smart && !evoSmartExitPaused)
         smartScore=EvoExitEvidence(symbol,buy,price,s,smartConfirmed,smartBar,smartDetails);
#ifdef EVO_MONITOR_SAFE_INPUTS
      p.smart=p.smart && !evoSmartExitPaused && economicValid;
      if(p.smart)
      {
         p.smartOffset=MathMax(p.smartOffset,sign*(economicBE-entry));
         double smartTarget=entry+sign*p.smartOffset;
         double smartGap=(double)MathMax(SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL),SymbolInfoInteger(symbol,SYMBOL_TRADE_FREEZE_LEVEL))*point+tick;
         bool protectedNet=sl>0 && sign*(sl-smartTarget)>=-tick*0.01;
         double liveGross=0;
         bool netNow=OrderCalcProfit(buy?ORDER_TYPE_BUY:ORDER_TYPE_SELL,symbol,volume,entry,price,liveGross) && liveGross>=beMoney;
         // Protect first; only a previously confirmed broker stop unlocks closing.
         p.closeSmart=EvoSmartMayClose(p.closeSmart,smartConfirmed,protectedNet,netNow);
         if(!protectedNet && sign*(price-smartTarget)<smartGap) p.smart=false;
         if(smartScore>=p.smartThreshold && sign*(price-entry)>=p.smartMinR*risk &&
            (!GlobalVariableCheck(key+".SE") || GlobalVariableGet(key+".SE")!=(double)smartBar))
         {
            GlobalVariableSet(key+".SE",(double)smartBar);
            EvoJournal("SMART_EXIT_EVIDENCIA",ticket,StringFormat("score=%d; confirmacion=%d; SL_neto_confirmado=%d; cierre_habilitado=%d; objetivo_bruto=%.2f; %s",smartScore,(int)smartConfirmed,(int)protectedNet,(int)p.closeSmart,beMoney,smartDetails));
         }
      }
#endif
      EvoProposal r=EvoPropose(buy,entry,price,sl,risk,atr,smartScore,p);
#ifdef EVO_MONITOR_SAFE_INPUTS
      if(r.close || r.reason=="Smart Exit proteger")
         r.reason+=StringFormat(" | score=%d; confirmacion=%d; %s",smartScore,(int)smartConfirmed,smartDetails);
#endif
      if(!r.close && EvoThesisProtectProfit && analysisValid && evoThesis.State(ticket)>=3 && sign*(price-entry)>=EvoSmartMinProfitR*risk)
      {
         double protective=entry+sign*EvoSmartOffsetATR*atr;
         if(EvoBetter(buy,r.sl,protective)) { r.sl=protective; r.reason="Tesis deteriorada: proteger ganancia"; }
      }
      if(r.close)
      {
         bool ok=trader.PositionClose(ticket); uint rc=trader.ResultRetcode();
         Print("Evolucion | ",ticket," | Smart Exit | solicitud=",ok," | retcode=",rc,
               " | cierre total=",(ok && rc==TRADE_RETCODE_DONE && !PositionSelectByTicket(ticket)));
         EvoJournal("SMART_EXIT_SOLICITUD",ticket,StringFormat("aceptada=%d; retcode=%u; %s",(int)ok,rc,r.reason));
      }
      else if(EvoBetter(buy,sl,r.sl)) Modify(ticket,symbol,buy,r.sl,tp,r.reason);
   }
};
#endif
