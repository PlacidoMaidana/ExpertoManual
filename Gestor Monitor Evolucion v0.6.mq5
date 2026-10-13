#property strict
#property version "1.60"
#property description "Monitor Evolucion v0.6: tablero decision multi-solapa + scores/candidatos + alertas semanticas. Incluye simulacion y entrada solo por confirmacion manual."
#define EVO_MONITOR_SAFE_INPUTS
#include "v0.6/SignalAnalysis.mqh"
#include "v0.6/ThesisTracker.mqh"
#include "v0.6/PositionManager.mqh"
#include "v0.6/MarketAlerts.mqh"
#include "v0.6/ContextPanel.mqh"

input group "Posiciones del monitor"
input bool EvoManagePositions = true;
input bool InpManageManualOnly = true;
input long InpMagicToManage = 0; // Usado solo si manual-only es false
input int InpProtectionTimerMs = 250;
input group "Simulacion manual - no envia ordenes"
input bool ManualBuy = true;
input double ManualEntry = 0.0; // 0: ask BUY / bid SELL actual
input double ManualStop = 0.0; // Precio tecnico elegido por el operador
input double ManualLots = 0.01;
input double InpRiskPerTradePct = 1.0; // Referencia informativa del limite del EA

CEvoAnalysis analysis;
CEvoPositionManager manager;
EvoSnapshot snapshot,viewSnapshot;
bool lastAnalysisValid=false,viewValid=false;
ulong lastVisualRefresh=0;
#include "v0.6/MonitorControls.mqh"
#include "v0.6/ManualReports.mqh"
#include "v0.6/OperationSimulator.mqh"
#include "v0.6/OnDemandAnalysis.mqh"
#include "v0.6/HighRiskSuggestions.mqh"
#include "v0.6/JournalPanel.mqh"

void ShowManualRisk()
{
   if(!EvoShowContext) return;

   EvoPanelLine(evoMonitorControlRow-1,"Gestion: "+(EvoManagePositions?"ACTIVA para posiciones seleccionadas":"DESACTIVADA")+" | simbolo del grafico");
   EvoPanelLine(evoRiskStart+0,"RIESGO MANUAL | "+(ManualStop>0?(ManualBuy?"BUY":"SELL"):"sin propuesta"),clrWhite);
   MqlTick q;
   if(!SymbolInfoTick(_Symbol,q) || q.bid<=0 || q.ask<=0) { EvoPanelLine(evoRiskStart+1,"N/D: cotizacion no disponible"); return; }
   double entry=ManualEntry>0?ManualEntry:(ManualBuy?q.ask:q.bid);
   double distance=ManualBuy?entry-ManualStop:ManualStop-entry;
   if(ManualStop<=0 || distance<=0 || ManualLots<=0)
   { EvoPanelLine(evoRiskStart+1,"Configura ManualStop al lado de riesgo y ManualLots > 0."); return; }
   double minLot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN), maxLot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP), tick=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(step<=0 || tick<=0 || ManualLots<minLot || ManualLots>maxLot || MathAbs(ManualLots/step-MathRound(ManualLots/step))>1e-7)
   { EvoPanelLine(evoRiskStart+1,StringFormat("Volumen no admitido: min %.4f | max %.4f | paso %.4f",minLot,maxLot,step)); return; }
   if(MathAbs(ManualStop/tick-MathRound(ManualStop/tick))>1e-6 || MathAbs(entry/tick-MathRound(entry/tick))>1e-6)
   { EvoPanelLine(evoRiskStart+1,"Precio/SL no alineado al tick del simbolo; no se ajusta automaticamente."); return; }
   double profit=0;
   if(!OrderCalcProfit(ManualBuy?ORDER_TYPE_BUY:ORDER_TYPE_SELL,_Symbol,ManualLots,entry,ManualStop,profit))
   { EvoPanelLine(evoRiskStart+1,"N/D: fallo del calculo de riesgo del broker"); return; }
   double risk=MathAbs(profit), equity=AccountInfoDouble(ACCOUNT_EQUITY);
   EvoPanelLine(evoRiskStart+1,StringFormat("Entrada %.5f | SL %.5f | lotes %.4f | distancia %.5f",entry,ManualStop,ManualLots,distance));
   EvoPanelLine(evoRiskStart+2,equity>0?StringFormat("Riesgo %.2f %s | %.2f%% | ref. EA %.2f%% %s",risk,AccountInfoString(ACCOUNT_CURRENCY),100*risk/equity,InpRiskPerTradePct,100*risk/equity>InpRiskPerTradePct?"SUPERIOR":""):"Riesgo porcentual N/D: equity no positiva",clrGold);
   double sign=ManualBuy?1:-1;
   double tpDistance=EvoTargetDistance(EvoTPMode==EVO_TP_ATR,snapshot.atr[0],EvoTPATR,distance,EvoRR);
   EvoPanelLine(evoRiskStart+3,tpDistance>0?StringFormat("TP teorico %s %.5f | sin comision ni deslizamiento",EvoTPMode==EVO_TP_ATR?"ATR":"RR",entry+sign*tpDistance):"TP teorico N/D: ATR no disponible");
   double gap=SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   bool closeStop=ManualBuy?ManualStop>q.bid-gap:ManualStop<q.ask+gap;
   string relative=snapshot.atr[0]>0?StringFormat("%.2f ATR",distance/snapshot.atr[0]):"ATR N/D";
   EvoPanelLine(evoRiskStart+4,relative+" | "+(closeStop?"SL incompatible con distancia minima actual.":"SL tecnico conservado; simulacion sin ordenes."));
   EvoPanelLine(evoRiskStart+5,"v0.6: "+snapshot.managementModeName+" | F"+IntegerToString(snapshot.scoreStrength)+" E"+IntegerToString(snapshot.scoreEfficiency)+" C"+IntegerToString(snapshot.scoreContinuation)+" A"+IntegerToString(snapshot.scoreExhaustion)+(EvoDiagnosticOnly?" | DiagnosticOnly":"")+" | dataset="+(EvoWriteTradeDataset?"ON":"OFF"),clrDeepSkyBlue);
}

void RenderMonitor(const bool force=false)
{
   ulong now=GetTickCount64();
   if(!force && lastVisualRefresh>0 && now-lastVisualRefresh<(ulong)EvoPanelRefreshMs) return;
   lastVisualRefresh=now;
   evoPanelDataPending=!lastAnalysisValid;
   if(!evoPanelFrozen && lastAnalysisValid)
   {
      if(InpRequireCandleConfirmation || evoPanelTab==EVO_TAB_INDICADORES || evoPanelTab==EVO_TAB_PATRONES)
      {
         EvoSnapshot closedView;
         if(analysis.ClosedAlertSnapshot(closedView)) { viewSnapshot=closedView; viewValid=true; }
         else evoPanelDataPending=true;
      }
      else { viewSnapshot=snapshot; viewValid=true; }
   }
   EvoPanelInit();
   evoPanelExtraRows=4+(InpShowBreakEvenJumpButton?1:0)+(InpUseLossExitButton?1:0)+(evoLevelsExpanded?11:1);
   if(EvoShowContext && evoPanelMinimized) { EvoPanelDrawMinimized(EvoManagePositions); return; }
   evoRiskStart=evoPanelTab==EVO_TAB_INDICADORES?EvoIndicatorsRiskRow(ManualStop>0):evoPanelTab==EVO_TAB_TACTICA?18:evoPanelTab==EVO_TAB_ALERTAS?15:evoPanelTab==EVO_TAB_ANALISIS?29:26;
   evoMonitorControlRow=evoRiskStart+(ManualStop>0?7:3);
   if(evoPanelTab!=EVO_TAB_TACTICA && !evoLevelsExpanded) { evoPanelExtraRows=0; evoMonitorControlRow=0; }
   EvoBeginFrame();
   if(EvoShowContext && evoPanelTab==EVO_TAB_REGISTRO && !evoSimulationView && !evoPanelMinimized && !evoDemandView) { EvoLogDraw(); EvoEndFrame(); return; }
   ObjectsDeleteAll(0,"EVO_CONTEXT_LOG_");
   if(EvoShowContext && evoSimulationView)
   {
      EvoSimDraw(); EvoEndFrame(); return;
   }
   if(EvoShowContext && evoDemandView) { EvoDemandDraw(); EvoEndFrame(); return; }
   if(EvoShowContext && evoLevelsExpanded)
   {
      // Use a compact editor so controls do not fall below a dense analysis panel.
      evoRiskStart=2; evoMonitorControlRow=2;
      ObjectsDeleteAll(0,"EVO_CONTEXT_PATTERN_");
      EvoPanelBackground(21); EvoDrawTabs();
      EvoPanelLine(1,"PROTECCIONES | R = distancia inicial entrada-SL | ajuste por grafico",clrAqua);
      EvoDrawControls(); EvoEndFrame(); return;
   }
   EvoPanelContext(viewValid,viewSnapshot,true);
   if(evoPanelTab==EVO_TAB_TACTICA) { ShowManualRisk(); EvoDrawControls(); }
   EvoEndFrame();
}

void Refresh()
{
   bool valid=analysis.Update(snapshot);
   evoThesis.Update(analysis,InpManageManualOnly,InpMagicToManage);
   evoMarketAlerts.Poll(analysis);
   lastAnalysisValid=valid;
   EvoValidateLoss();
   Evo113Poll(valid,snapshot);
   RenderMonitor();
   if(!EvoManagePositions) return;
   if(!valid && !analysis.ATR(snapshot.atr[0])) return;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      long magic=PositionGetInteger(POSITION_MAGIC);
      if(InpManageManualOnly?magic!=0:magic!=InpMagicToManage) continue;
      // Adaptive management modes do not auto-close while EvoDiagnosticOnly=true.
      manager.Process(ticket,snapshot,valid);
   }
   EvoRunLoss(snapshot.atr[0]);
}
int OnInit()
{
   // Hide every indicator handle created later, including on-demand and MTF reads.
   // Tester template is already clean; calculations and live chart visibility are unchanged.
   if(MQLInfoInteger(MQL_TESTER)) TesterHideIndicators(true);
   EvoRepairManagementInputs();
   if(!Evo113ValidInputs()) return INIT_PARAMETERS_INCORRECT;
   if(EvoSimulationPriceTolerancePoints<0 || !MathIsValidNumber(EvoSimulationRiskTolerancePct) || EvoSimulationRiskTolerancePct<0 || EvoSimulationRiskTolerancePct>100) return INIT_PARAMETERS_INCORRECT;
   if(!MathIsValidNumber(EvoSimulationLots) || EvoSimulationLots<=0) return INIT_PARAMETERS_INCORRECT;
   if(!EvoValidPanelInputs() || !EvoValidAnalysisInputs() || !EvoValidManagementInputs() || !evoThesis.ValidInputs() || EvoPanelFont<6 ||
      InpProtectionTimerMs<100 || InpRiskPerTradePct<0) return INIT_PARAMETERS_INCORRECT;
   if(!MathIsValidNumber(EvoLossRecoveryATR) || EvoLossRecoveryATR<0 || !MathIsValidNumber(EvoLossRecoveredTrailATR) || EvoLossRecoveredTrailATR<=0 || InpLossExitTrailingATRMultiplier<=0 || InpLossExitStepPoints<0) return INIT_PARAMETERS_INCORRECT;
   if(!MathIsValidNumber(ManualBEExtraMoney) || ManualBEExtraMoney<0 || !MathIsValidNumber(ManualBEExitCommissionPerLot) || ManualBEExitCommissionPerLot<0) return INIT_PARAMETERS_INCORRECT;
   evoPanelExtraRows=4+(InpShowBreakEvenJumpButton?1:0)+(InpUseLossExitButton?1:0);
   if(!MathIsValidNumber(EvoReportSLATR) || EvoReportSLATR<=0 || !MathIsValidNumber(EvoReportRR) || EvoReportRR<=0) return INIT_PARAMETERS_INCORRECT;
   EvoDemandInit();
   EvoLoadLoss();
   if(!analysis.Init(_Symbol,PERIOD_CURRENT)) return INIT_FAILED;
   if(!EventSetMillisecondTimer(InpProtectionTimerMs)) return INIT_FAILED;
   Print("Monitor Evolucion v0.6 | DiagnosticOnly=",EvoDiagnosticOnly," | dataset=",EvoWriteTradeDataset,
         " | ER tactico<",EvoTacticalERMax," extension>=",EvoExtensionERMin,
         " | candidato>=",EvoCandidateScoreMin," commit>=",EvoCommitScoreMin,
         " | solapas TACTICA/ANALISIS/TESIS/ALERTAS");
   EvoReportInit();
   if(evoManagementInputWarning!="")
   {
      Print("PARAMETROS CORREGIDOS: ",evoManagementInputWarning);
      EvoJournal("PARAMETROS_CORREGIDOS",0,evoManagementInputWarning+" | Se usan valores efectivos; editar Propiedades para guardarlos en el preset.");
      if(!MQLInfoInteger(MQL_TESTER)) Alert("Monitor sigue activo. Parametros corregidos:\n",evoManagementInputWarning,"\nLos inputs visibles conservan lo escrito; el registro indica los valores aplicados.");
   }
   if(evoPanelTab==EVO_TAB_REGISTRO) EvoLogLoad();
   Refresh();
   EvoPanelMove(evoPanelX,evoPanelY);
   return INIT_SUCCEEDED;
}
void OnTick() { Refresh(); }
void OnTimer() { Refresh(); }
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
   if(id==CHARTEVENT_OBJECT_CLICK && (StringFind(sparam,"EVO_CONTEXT_TAB_")==0 || sparam=="EVO_CONTEXT_SIM"))
   {
      evoLevelsExpanded=false; ObjectsDeleteAll(0,"EVO_CONTEXT_");
   }
   if(id==CHARTEVENT_OBJECT_CLICK && EvoShowContext)
   {
      if(sparam=="EVO_CONTEXT_LINES")
      {
         EvoSetChartLinesVisible(!evoChartLinesVisible);
         ObjectSetInteger(0,sparam,OBJPROP_STATE,false); RenderMonitor(true); return;
      }
      if(sparam=="EVO_CONTEXT_ANALYZE" || sparam=="EVO_CONTEXT_TAB_ANALISIS") EvoSetChartLinesVisible(true);
   }
   if(EvoDemandEvent(id,sparam)) { RenderMonitor(true); return; }
   if(id==CHARTEVENT_OBJECT_CLICK && EvoShowContext && sparam=="EVO_CONTEXT_ANALYZE") { EvoDemandCapture(); RenderMonitor(true); return; }
   if(id==CHARTEVENT_OBJECT_CLICK && (StringFind(sparam,"EVO_CONTEXT_TAB_")==0 || sparam=="EVO_CONTEXT_SIM"))
   {
      if(evoDemandView) { evoDemandView=false; ObjectsDeleteAll(0,"EVO_CONTEXT_"); ObjectsDeleteAll(0,"EVO_DEMAND_"); }
   }
   if(EvoLogEvent(id,sparam)) { RenderMonitor(true); return; }
   if(EvoSimEvent(id,sparam)) { RenderMonitor(true); return; }
   if(EvoPanelEvent(id,lparam,dparam,sparam)) { RenderMonitor(true); return; }
   if(id==CHARTEVENT_CHART_CHANGE) { RenderMonitor(true); return; }
   if(id!=CHARTEVENT_OBJECT_CLICK || !EvoShowContext) return;
   if(EvoLevelsEvent(sparam)) { RenderMonitor(true); return; }
   if(EvoAdjustTrailing(sparam)) { RenderMonitor(true); return; }
   if(sparam=="EVO_CONTEXT_BE" && InpShowBreakEvenJumpButton) EvoToggleRiskProtection();
   else if(sparam=="EVO_CONTEXT_SMART") EvoToggleSmartExit();
   else if(sparam=="EVO_CONTEXT_LOSS" && InpUseLossExitButton) EvoToggleLoss();
   else return;
   ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
   RenderMonitor(true);
}
void OnTradeTransaction(const MqlTradeTransaction &trans,const MqlTradeRequest &request,const MqlTradeResult &result)
{
   if(trans.type==TRADE_TRANSACTION_POSITION && trans.symbol==_Symbol)
   {
      EvoJournal("CAMBIO_POSICION_NOTIFICADO",trans.position,
         StringFormat("SL=%.8f; TP=%.8f; origen no atribuido (terminal/otro asesor/gestor)",trans.price_sl,trans.price_tp));
      return;
   }
   if(trans.type!=TRADE_TRANSACTION_DEAL_ADD || !HistoryDealSelect(trans.deal)) return;
   if(HistoryDealGetString(trans.deal,DEAL_SYMBOL)!=_Symbol) return;
   long magic=HistoryDealGetInteger(trans.deal,DEAL_MAGIC);
   if(InpManageManualOnly?magic!=0:magic!=InpMagicToManage) return;
   EvoReportDeal(trans.deal);
   evoThesis.Update(analysis,InpManageManualOnly,InpMagicToManage);
   HistoryDealSelect(trans.deal);
   EvoJournal("DEAL",trans.deal,StringFormat("posicion=%I64d; entrada_tipo=%d; volumen=%.4f; precio=%.8f; neto=%.2f",
              HistoryDealGetInteger(trans.deal,DEAL_POSITION_ID),(int)HistoryDealGetInteger(trans.deal,DEAL_ENTRY),
              HistoryDealGetDouble(trans.deal,DEAL_VOLUME),HistoryDealGetDouble(trans.deal,DEAL_PRICE),
              HistoryDealGetDouble(trans.deal,DEAL_PROFIT)+HistoryDealGetDouble(trans.deal,DEAL_COMMISSION)+HistoryDealGetDouble(trans.deal,DEAL_SWAP)));
}
void OnDeinit(const int reason) { EvoReportHTML(); EvoDemandRelease(); ObjectsDeleteAll(0,"EVO_DEMAND_"); ObjectsDeleteAll(0,"EVO_SIM_"); evoThesis.Flush(); EventKillTimer(); manager.Release(); analysis.Release(); EvoPanelDelete(); }






