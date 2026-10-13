#ifndef EVO_MANUAL_BREAK_EVEN
#define EVO_MANUAL_BREAK_EVEN
#include "EconomicBreakEven.mqh"

ulong evoBERetryIds[];
ulong evoBERetryTimes[];
string evoBERetryErrors[];
bool EvoBERetryReady(const ulong id)
{
   ulong now=GetTickCount64();
   for(int i=0;i<ArraySize(evoBERetryIds);i++)
      if(evoBERetryIds[i]==id)
      {
         if(now-evoBERetryTimes[i]<2000) return false;
         evoBERetryTimes[i]=now; return true;
      }
   int n=ArraySize(evoBERetryIds);
   ArrayResize(evoBERetryIds,n+1); ArrayResize(evoBERetryTimes,n+1); ArrayResize(evoBERetryErrors,n+1);
   evoBERetryIds[n]=id; evoBERetryTimes[n]=now; return true;
}
string EvoBEKey() { return "EVB."+manager.Scope()+"."+(string)ChartID()+"."; }
string EvoBEPositionKey(const ulong id) { return EvoBEKey()+(string)id; }
bool EvoBEArmed()
{
   for(int i=GlobalVariablesTotal()-1;i>=0;i--)
      if(StringFind(GlobalVariableName(i),EvoBEKey())==0) return true;
   return false;
}
void EvoRunManualBE()
{
   if(evoRiskProtectionPaused) return;
   int pending=0,done=0,removed=0;
   string detail="";
   // Keys capture identifiers of existing positions; future entries are never armed implicitly.
   for(int k=GlobalVariablesTotal()-1;k>=0;k--)
   {
      string key=GlobalVariableName(k);
      if(StringFind(key,EvoBEKey())!=0) continue;
      ulong id=(ulong)StringToInteger(StringSubstr(key,StringLen(EvoBEKey()))),ticket=0;
      long type=-1;
      for(int i=PositionsTotal()-1;i>=0;i--)
      {
         ulong t=PositionGetTicket(i);
         if(t>0 && EvoMonitorSelected() && (ulong)PositionGetInteger(POSITION_IDENTIFIER)==id)
         { ticket=t; type=PositionGetInteger(POSITION_TYPE); break; }
      }
      if(ticket==0 || type+1!=(long)GlobalVariableGet(key))
      { GlobalVariableDel(key); removed++; EvoJournal("BE_MANUAL_RETIRADO",id,"cerrada, cambio de lado o fuera de seleccion"); continue; }
      pending++;
      if(!EvoManagePositions || !InpShowBreakEvenJumpButton) { detail="PAUSADO: gestion o boton desactivado"; continue; }
      double entry=PositionGetDouble(POSITION_PRICE_OPEN),volume=PositionGetDouble(POSITION_VOLUME);
      double sl=PositionGetDouble(POSITION_SL),swap=PositionGetDouble(POSITION_SWAP);
      double target=0,costs=0;
      bool buy=type==POSITION_TYPE_BUY;
      if(!EvoBECosts(id,volume,swap,costs) || !EvoBEPrice(buy,entry,volume,costs,target))
      { detail="N/D: costos/historial/calculo; sigue armado"; continue; }
      if(sl>0 && (buy?sl>=target:sl<=target))
      { GlobalVariableDel(key); pending--; done++; EvoJournal("BE_MANUAL_YA_PROTEGIDO",id,"SL existente cubre objetivo estimado"); continue; }
      MqlTick q;
      if(!SymbolInfoTick(_Symbol,q) || q.bid<=0 || q.ask<=0) { detail="N/D: cotizacion"; continue; }
      double gap=MathMax(SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL),SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL))*_Point+SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
      double required=target+(buy?gap:-gap),current=buy?q.bid:q.ask,nowProfit=0,requiredProfit=0;
      if(!OrderCalcProfit(buy?ORDER_TYPE_BUY:ORDER_TYPE_SELL,_Symbol,volume,entry,current,nowProfit) ||
         !OrderCalcProfit(buy?ORDER_TYPE_BUY:ORDER_TYPE_SELL,_Symbol,volume,entry,required,requiredProfit))
      { detail="N/D: beneficio necesario"; continue; }
      detail=StringFormat("#%I64u bruto %.2f / necesita %.2f | falta %.2f %s",ticket,nowProfit,requiredProfit,MathMax(0,requiredProfit-nowProfit),AccountInfoString(ACCOUNT_CURRENCY));
      if(buy?current<required:current>required) continue;
      // Retry failed broker requests at most once per two seconds per position.
      if(!EvoBERetryReady(id))
      {
         for(int e=0;e<ArraySize(evoBERetryIds);e++)
            if(evoBERetryIds[e]==id && evoBERetryErrors[e]!="") detail=evoBERetryErrors[e];
         continue;
      }
      if(manager.ManualStop(ticket,target,"BE manual: objetivo neto economico",true))
      { GlobalVariableDel(key); pending--; done++; EvoJournal("BE_MANUAL_EJECUTADO",id,StringFormat("SL=%.8f; costos estimados=%.2f",target,costs)); }
      else { GlobalVariableSet(key,type+1); detail="Precio apto | "+manager.LastStopError();
         for(int e=0;e<ArraySize(evoBERetryIds);e++) if(evoBERetryIds[e]==id) evoBERetryErrors[e]=detail; }
   }
   if(done>0 || removed>0) GlobalVariablesFlush();
   if(pending>0) evoBEStatus=StringFormat("BE ARMADO (%d) | ",pending)+detail;
   else if(done>0) evoBEStatus="BE PROTEGIDO: SL confirmado o posicion ya protegida";
   else if(removed>0) evoBEStatus="BE retirado: posicion cerrada o fuera de seleccion";
}
void EvoJumpBE()
{
   if(EvoBEArmed())
   {
      for(int i=GlobalVariablesTotal()-1;i>=0;i--)
      {
         string key=GlobalVariableName(i);
         if(StringFind(key,EvoBEKey())==0) GlobalVariableDel(key);
      }
      GlobalVariablesFlush();
      evoBEStatus="BE CANCELADO: el SL existente se conserva";
      EvoJournal("BE_MANUAL_CANCELADO",0,evoBEStatus); return;
   }
   if(!EvoManagePositions) { evoBEStatus="Gestion desactivada: BE no armado"; return; }
   int count=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !EvoMonitorSelected()) continue;
      ulong id=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
      GlobalVariableSet(EvoBEPositionKey(id),PositionGetInteger(POSITION_TYPE)+1);
      EvoJournal("BE_MANUAL_ARMADO",id,"Proteccion en primera oportunidad valida"); count++;
   }
   GlobalVariablesFlush();
   evoBEStatus=count>0?"BE ARMADO":"Sin posiciones seleccionadas";
   EvoRunManualBE();
}
#endif
