#ifndef EVO_HIGH_RISK_SUGGESTIONS
#define EVO_HIGH_RISK_SUGGESTIONS
input group "Sugerencias Alto Riesgo v1.13 - NO ejecutan entradas"
input bool EvoSuggest113=true; // Preparar sugerencias solo dentro de SIMULAR, sin cambiar de pantalla
input double EvoSuggest113TrendSL=1.5; // SL ATR en tendencia, como v1.13
input double EvoSuggest113LateralSL=1.5; // SL ATR en lateral, como v1.13
input double EvoSuggest113RR=2.0; // RR objetivo (minimo 1.20 como v1.13)
input int EvoSuggest113MaxSLPoints=2000; // Tope SL en puntos; 0 sin tope
input int EvoSuggest113MinTPPoints=100; // Minimo TP en puntos
input double EvoSuggest113MinTPATR=0.5; // Minimo TP en ATR
int evo113PreviousSignal=0,evo113PublishedMask=0;
datetime evo113Bar=0;
bool Evo113ValidInputs()
{
   return MathIsValidNumber(EvoSuggest113TrendSL) && EvoSuggest113TrendSL>0 &&
      MathIsValidNumber(EvoSuggest113LateralSL) && EvoSuggest113LateralSL>0 &&
      MathIsValidNumber(EvoSuggest113RR) && EvoSuggest113RR>0 &&
      EvoSuggest113MaxSLPoints>=0 && EvoSuggest113MinTPPoints>=0 &&
      MathIsValidNumber(EvoSuggest113MinTPATR) && EvoSuggest113MinTPATR>=0;
}
// New directional edge, at most once per side/bar. Persistent signals do not steal focus.
bool Evo113NewSignal(const int signal,const int previous,const int mask)
{
   int bit=signal>0?1:signal<0?2:0;
   return bit!=0 && signal!=previous && (mask & bit)==0;
}
void Evo113Distances(const double atr,const bool trend,const double point,double &sl,double &tp)
{
   sl=atr*(trend?EvoSuggest113TrendSL:EvoSuggest113LateralSL);
   if(EvoSuggest113MaxSLPoints>0) sl=MathMin(sl,EvoSuggest113MaxSLPoints*point);
   tp=MathMax(sl*MathMax(1.20,EvoSuggest113RR),MathMax(EvoSuggest113MinTPPoints*point,EvoSuggest113MinTPATR*atr));
}
void Evo113Poll(const bool valid,const EvoSnapshot &live)
{
   if(!EvoSuggest113 || !EvoShowContext || !valid) return;
   // Only an explicit SIMULAR click opens that view. Never steal focus or edits.
   if(!evoSimulationView || evoSimActive || evoDemandView || evoPanelMinimized || evoHelpOpen) return;
#ifdef EVO_SIMULATOR_V08
   if(evo08TargetKind>0) return;
#endif
   EvoSnapshot candidate=live;
   // Match v1.13's mixed indexing deliberately: closed price/levels when configured,
   // live ATR/ADX/RSI/EMAs. Do not substitute the monitor's closed display snapshot.
   EvoEvaluate(candidate,_Point,false,true);
   datetime bar=live.current.time;
   if(bar<=0) return;
   if(bar!=evo113Bar) { evo113Bar=bar; evo113PublishedMask=0; }
   int side=candidate.signal;
   bool fresh=Evo113NewSignal(side,evo113PreviousSignal,evo113PublishedMask);
   evo113PreviousSignal=side;
   if(!fresh) return;
   // No signal focus changes during position management or pending orders.
   for(int i=PositionsTotal()-1;i>=0;i--) if(PositionGetTicket(i)>0 && PositionGetString(POSITION_SYMBOL)==_Symbol) return;
   for(int i=OrdersTotal()-1;i>=0;i--) if(OrderGetTicket(i)>0 && OrderGetString(ORDER_SYMBOL)==_Symbol) return;
   MqlTick q;
   if(candidate.atr[0]<=0 || EvoSimTick()<=0 || !SymbolInfoTick(_Symbol,q) || q.bid<=0 || q.ask<=0) { evo113PreviousSignal=0; return; }
   double sl,tp; Evo113Distances(candidate.atr[0],candidate.regime=="TENDENCIA",_Point,sl,tp);
   if(sl<=0 || tp<=0) return;
   evoSimMode=0; evoSimBuy=side>0; evoSimEntry=EvoSimRound(evoSimBuy?q.ask:q.bid);
   evoSimSL=EvoSimRound(evoSimEntry-side*sl); evoSimTP=EvoSimRound(evoSimEntry+side*tp);
   evoSimActive=true;
   double risk=0,gain=0; string error="";
   if(!EvoSimValues(risk,gain,error)) { evoSimActive=false; EvoJournal("SUGERENCIA_113_INVALIDA",0,error); return; }
   evo113PublishedMask|=side>0?1:2;
   EvoSetChartLinesVisible(true); EvoSimLines();
#ifdef EVO_SIMULATOR_V08
   Evo08Init(); evo08ATR=candidate.atr[0]; Evo08SyncDistances();
#endif
   evoSimOrigin="Alto Riesgo v1.13 | "+candidate.regime+" | "+TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS);
   evoSimMessage="SUGERENCIA "+(side>0?"COMPRA":"VENTA")+" | revisar niveles antes de CONFIRMAR";
   EvoJournal("SUGERENCIA_113_SIMULADA",0,evoSimOrigin+StringFormat("; lado=%d; entrada=%.*f; SL=%.*f; TP=%.*f; lotes=%.2f; riesgo=%.2f; objetivo=%.2f",side,_Digits,evoSimEntry,_Digits,evoSimSL,_Digits,evoSimTP,EvoSimLots(),risk,gain));
   Print(evoSimOrigin," | ",evoSimMessage);
}
#endif
