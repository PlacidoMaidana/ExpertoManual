#ifndef EVO_MARKET_ALERTS
#define EVO_MARKET_ALERTS
#include "AlertRules.mqh"
input group "Alertas de mercado - velas cerradas"
input bool EvoAlertsEnabled = true;
input bool EvoAlertRSI30 = true;
input bool EvoAlertRSI70 = true;
input bool EvoAlertADX25 = true;
input bool EvoAlertSuggestion = true;
input bool EvoAlertSemantic = true; // regimen / gestion / scores (transiciones)
input int EvoAlertCooldownBars = 1; // minimo de velas entre alertas semanticas
input bool EvoAlertPopup = true;
input bool EvoAlertSound = false; // Sonido adicional a la ventana de MetaTrader
string evoAlertStatus="iniciando";
string evoAlertSemantic="";
string evoAlertLastEvent="";
class CEvoMarketAlerts
{
private:
   datetime lastBar;
   int lastSignal;
   int lastRegime;
   int lastMgmt;
   int lastContBucket;
   int lastExhBucket;
   datetime lastSemanticBar;
public:
   CEvoMarketAlerts()
   {
      lastBar=0; lastSignal=0; lastRegime=-1; lastMgmt=-1;
      lastContBucket=-1; lastExhBucket=-1; lastSemanticBar=0;
   }
   void Poll(CEvoAnalysis &source)
   {
      if(!EvoAlertsEnabled) { evoAlertStatus="DESACTIVADAS"; return; }
      datetime bar=iTime(_Symbol,PERIOD_CURRENT,1);
      if(bar<=0) { evoAlertStatus="esperando historial"; return; }
      if(bar==lastBar) return;
      EvoSnapshot closed;
      if(!source.ClosedAlertSnapshot(closed)) { evoAlertStatus="esperando datos cerrados"; return; }
      if(closed.current.time!=bar) return; // A bar rolled over during the read: retry.
      int action=closed.needsConfirmation?2:closed.signal;
      string events="";
      string semantic="";
      if(EvoAlertTransition((long)lastBar,(long)bar,(long)closed.previous.time))
      {
         int low=EvoCross(closed.rsi[1],closed.rsi[0],30),high=EvoCross(closed.rsi[1],closed.rsi[0],70);
         if(EvoAlertRSI30 && low!=0) events+=low>0?"RSI sale de sobreventa; ":"RSI entra en sobreventa; ";
         if(EvoAlertRSI70 && high!=0) events+=high>0?"RSI entra en sobrecompra; ":"RSI sale de sobrecompra; ";
         if(EvoAlertADX25 && EvoCross(closed.adx[1],closed.adx[0],25)>0) events+="ADX supera 25; ";
         if(EvoAlertSuggestion && action!=lastSignal)
            events+="Sugerencia cerrada: "+(closed.needsConfirmation?"ESPERAR CONFIRMACION":closed.signal>0?"ENTRAR COMPRA":closed.signal<0?"ENTRAR VENTA":"NO ENTRAR")+"; ";

         if(EvoAlertSemantic)
         {
            bool cool=lastSemanticBar==0 || (bar-lastSemanticBar)>=(datetime)(MathMax(1,EvoAlertCooldownBars)*(long)PeriodSeconds(_Period));
            if(lastRegime>=0 && closed.localRegime!=lastRegime)
               semantic+=StringFormat("REGIMEN: %s -> %s; ",EvoLocalRegimeName(lastRegime),closed.localRegimeName);
            if(lastMgmt>=0 && closed.managementMode!=lastMgmt)
               semantic+=StringFormat("GESTION: %s -> %s; ",EvoManagementModeName(lastMgmt),closed.managementModeName);
            int contB=closed.scoreContinuation/20, exhB=closed.scoreExhaustion/20;
            if(lastContBucket>=0 && contB!=lastContBucket && MathAbs(contB-lastContBucket)>=1)
               semantic+=StringFormat("CONTINUIDAD ahora %d/100; ",closed.scoreContinuation);
            if(lastExhBucket>=0 && exhB!=lastExhBucket && exhB>=3 && exhB>lastExhBucket)
               semantic+=StringFormat("AGOTAMIENTO sube a %d/100; ",closed.scoreExhaustion);
            if(closed.scoreRisk>=70)
               semantic+=StringFormat("RIESGO elevado %d/100; ",closed.scoreRisk);
            if(closed.needsConfirmation && closed.signal!=0)
               semantic+="OPORTUNIDAD en espera: "+closed.pendingAction+"; ";
            if(semantic!="" && cool)
            {
               events+=semantic;
               evoAlertSemantic=semantic;
               lastSemanticBar=bar;
            }
            lastContBucket=contB; lastExhBucket=exhB;
         }
      }
      // First load/reload and gaps only seed state. No replay of old events.
      lastBar=bar; lastSignal=action;
      lastRegime=closed.localRegime; lastMgmt=closed.managementMode;
      evoAlertStatus="Cierre "+TimeToString(bar,TIME_MINUTES)+" | "+closed.suggestionAction;
      if(events=="") return;
      string tf=EnumToString((ENUM_TIMEFRAMES)_Period); StringReplace(tf,"PERIOD_","");
      string message=MQLInfoString(MQL_PROGRAM_NAME)+" | "+_Symbol+" "+tf+" | vela "+TimeToString(bar,TIME_DATE|TIME_MINUTES)+"\n"+events+
         "\n"+closed.reason+". Contexto tecnico cerrado; no confirma ejecucion ni riesgo.";
      if(closed.managementReason!="") message+="\nGestion: "+closed.managementModeName+" | "+closed.managementReason;
      Print(message);
      evoAlertLastEvent=TimeToString(bar,TIME_DATE|TIME_MINUTES)+" | "+events;
      if(!MQLInfoInteger(MQL_TESTER))
      {
         if(EvoAlertPopup) Alert(message);
         if(EvoAlertSound && !PlaySound("alert.wav")) Print("No se pudo reproducir alert.wav");
      }
   }
};
CEvoMarketAlerts evoMarketAlerts;
#endif