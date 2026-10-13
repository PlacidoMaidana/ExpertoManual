#ifndef EVO_OPERATION_SIMULATOR
#define EVO_OPERATION_SIMULATOR
input group "Simulacion y entrada manual"
input double EvoSimulationLots=0.01; // Volumen usado por simulacion y confirmacion
input int EvoSimulationPriceTolerancePoints=20; // Maximo cambio de entrada sin nueva revision
input double EvoSimulationRiskTolerancePct=2.0; // Maximo aumento del riesgo estimado
bool EvoSimWithinTolerance(const double distance,const double maxDistance,const double oldRisk,const double newRisk,const double riskPct)
{
   return distance<=maxDistance+1e-9 && oldRisk>0 && newRisk>0 && newRisk<=oldRisk*(1.0+riskPct/100.0)+1e-8;
}
void EvoSimStatus(const string message)
{
   evoSimMessage=message;
   Print("Simulador: ",message);
   EvoJournal("SIMULADOR_ESTADO",0,message);
}
bool evoSimBuy=true,evoSimActive=false;
int evoSimMode=0; // 0 market, 1 Buy Limit, 2 Buy Stop, 3 Sell Limit, 4 Sell Stop
string EvoSimModeName() { return evoSimMode==1?"BUY LIMIT":evoSimMode==2?"BUY STOP":evoSimMode==3?"SELL LIMIT":evoSimMode==4?"SELL STOP":"MERCADO"; }
ENUM_ORDER_TYPE EvoSimOrderType() { return evoSimMode==1?ORDER_TYPE_BUY_LIMIT:evoSimMode==2?ORDER_TYPE_BUY_STOP:evoSimMode==3?ORDER_TYPE_SELL_LIMIT:evoSimMode==4?ORDER_TYPE_SELL_STOP:evoSimBuy?ORDER_TYPE_BUY:ORDER_TYPE_SELL; }
bool EvoSimPendingPriceValid(const int mode,const double entry,const double bid,const double ask,const double gap)
{ return mode==1?entry<=ask-gap:mode==2?entry>=ask+gap:mode==3?entry>=bid+gap:mode==4?entry<=bid-gap:false; }

double evoSimEntry=0,evoSimSL=0,evoSimTP=0;
string evoSimOrigin="Preparacion manual";
string evoSimMessage="Elige lado y pulsa CALCULAR. No abre hasta CONFIRMAR.";
CTrade evoSimTrade;

double EvoSimTick() { return SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE); }
double EvoSimRound(const double p) { double t=EvoSimTick(); return t>0?NormalizeDouble(MathRound(p/t)*t,_Digits):p; }
// Round away from the quote so a tick boundary never makes a pending invalid.
double EvoSimPendingBoundary(const int mode,const double bid,const double ask,const double gap,const double tick)
{
   if(tick<=0) return 0;
   double quote=mode<=2?ask:bid;
   bool above=mode==2 || mode==3;
   return above?MathCeil((quote+gap)/tick)*tick:MathFloor((quote-gap)/tick)*tick;
}
string EvoSimPendingGuide(const MqlTick &q,const double gap)
{
   double boundary=NormalizeDouble(EvoSimPendingBoundary(evoSimMode,q.bid,q.ask,gap,EvoSimTick()),_Digits);
   return EvoSimModeName()+StringFormat(" entrada %s %.*f | preparada %.*f",evoSimMode==2 || evoSimMode==3?">=":"<=",_Digits,boundary,_Digits,evoSimEntry);
}
void EvoSimUpdateQuote()
{
   if(!evoSimActive) { EvoSimStatus("Pulsa CALCULAR antes de actualizar"); return; }
   MqlTick q; double atr=0,tick=EvoSimTick();
   if(tick<=0 || !SymbolInfoTick(_Symbol,q) || q.ask<=0 || q.bid<=0) { EvoSimStatus("Sin cotizacion valida"); return; }
   if(evoSimMode==0)
   { evoSimEntry=EvoSimRound(evoSimBuy?q.ask:q.bid); EvoSimLines(); EvoSimStatus("Entrada actualizada; SL/TP conservados, revisa riesgo"); return; }
   if(!analysis.ATR(atr) || atr<=0) { EvoSimStatus("Sin ATR para preparar pendiente"); return; }
   double gap=SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point+tick;
   double offset=MathMax(gap,atr*0.5);
   double next=NormalizeDouble(EvoSimPendingBoundary(evoSimMode,q.bid,q.ask,offset,tick),_Digits);
   double shift=next-evoSimEntry;
   if(next<=0 || evoSimSL+shift<=0 || evoSimTP+shift<=0) { EvoSimStatus("Niveles no validos para actualizar"); return; }
   evoSimEntry=next; evoSimSL=EvoSimRound(evoSimSL+shift); evoSimTP=EvoSimRound(evoSimTP+shift);
   EvoSimLines(); EvoSimStatus("Pendiente actualizada con SL/TP trasladados. Revisa importes y pulsa COLOCAR.");
}
void EvoSimLine(const string name,const double price,const color ink)
{
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_HLINE,0,0,price);
   EvoApplyLineVisibility(name);
   ObjectSetDouble(0,name,OBJPROP_PRICE,price);
   ObjectSetInteger(0,name,OBJPROP_COLOR,ink);
   ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_DASH);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,true);
   ObjectSetInteger(0,name,OBJPROP_SELECTED,true);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,name+" | arrastrar para simular");
}
void EvoSimLines()
{
   EvoSimLine("EVO_SIM_ENTRADA",evoSimEntry,clrDeepSkyBlue);
   EvoSimLine("EVO_SIM_SL",evoSimSL,clrTomato);
   EvoSimLine("EVO_SIM_TP",evoSimTP,clrLimeGreen);
}
bool EvoSimValues(double &risk,double &gain,string &error)
{
   double minLot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN),maxLot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX),step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(!MathIsValidNumber(EvoSimulationLots) || step<=0 || EvoSimulationLots<minLot || EvoSimulationLots>maxLot || MathAbs(EvoSimulationLots/step-MathRound(EvoSimulationLots/step))>1e-7)
   { error="Volumen no admitido por el simbolo; revisa EvoSimulationLots"; return false; }
   if(!evoSimActive || evoSimEntry<=0 || evoSimSL<=0 || evoSimTP<=0 || (evoSimBuy?(evoSimSL>=evoSimEntry || evoSimTP<=evoSimEntry):(evoSimSL<=evoSimEntry || evoSimTP>=evoSimEntry)))
   { error="Niveles invalidos: SL al lado de perdida y TP al de ganancia"; return false; }
   double pnl=0;
   if(!OrderCalcProfit(evoSimBuy?ORDER_TYPE_BUY:ORDER_TYPE_SELL,_Symbol,EvoSimulationLots,evoSimEntry,evoSimSL,pnl) ||
      !OrderCalcProfit(evoSimBuy?ORDER_TYPE_BUY:ORDER_TYPE_SELL,_Symbol,EvoSimulationLots,evoSimEntry,evoSimTP,gain))
   { error="No se pudo calcular importe en moneda de cuenta"; return false; }
   risk=-pnl; return risk>0 && gain>0;
}
void EvoSimCalculate()
{
   evoSimOrigin="Preparacion manual";
   evoSimActive=false; ObjectsDeleteAll(0,"EVO_SIM_");
   double atr=0; MqlTick q;
   if(!analysis.ATR(atr) || atr<=0 || !SymbolInfoTick(_Symbol,q) || q.ask<=0 || q.bid<=0 || EvoSimTick()<=0)
   { evoSimMessage="Faltan ATR o cotizacion: no se calcula"; return; }
   evoSimEntry=EvoSimRound(evoSimBuy?q.ask:q.bid);
   if(evoSimMode>0)
   {
      double offset=MathMax(atr*0.5,SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point+2*EvoSimTick());
      evoSimEntry=NormalizeDouble(EvoSimPendingBoundary(evoSimMode,q.bid,q.ask,offset,EvoSimTick()),_Digits);
   }
   double sign=evoSimBuy?1:-1,dist=atr*EvoSLATR;
   evoSimSL=EvoSimRound(evoSimEntry-sign*dist);
   evoSimTP=EvoSimRound(evoSimEntry+sign*EvoTargetDistance(EvoTPMode==EVO_TP_ATR,atr,EvoTPATR,MathAbs(evoSimEntry-evoSimSL),EvoRR));
   evoSimActive=true; EvoSimLines();
   evoSimMessage="Ajusta ENTRADA, SL y TP. CONFIRMAR envia "+EvoSimModeName()+".";
}
void EvoSimConfirm()
{
   evoSimulationView=true;
   double risk=0,gain=0; string error="";
   if(!EvoSimValues(risk,gain,error)) { EvoSimStatus(error); return; }
   // Prevent netting/addition and accidental double entries on this symbol.
   for(int i=PositionsTotal()-1;i>=0;i--) if(PositionGetTicket(i)>0 && PositionGetString(POSITION_SYMBOL)==_Symbol)
   { EvoSimStatus("Ya hay posicion en este simbolo; no se agrega otra"); return; }
   for(int i=OrdersTotal()-1;i>=0;i--) if(OrderGetTicket(i)>0 && OrderGetString(ORDER_SYMBOL)==_Symbol)
   { EvoSimStatus("Hay pendiente: selecciona EN ESPERA y pulsa CANCELAR antes de otra entrada"); return; }
   MqlTick q; if(!SymbolInfoTick(_Symbol,q)) { EvoSimStatus("Sin cotizacion"); return; }
   if(q.bid<=0 || q.ask<=0 || EvoSimTick()<=0) { EvoSimStatus("Cotizacion invalida"); return; }
   double live=EvoSimRound(evoSimBuy?q.ask:q.bid),oldEntry=evoSimEntry,oldRisk=risk;
   if(evoSimMode==0) evoSimEntry=live;
   EvoSimLines();
   if(!EvoSimValues(risk,gain,error)) { EvoSimStatus(error); return; }
   if(evoSimMode==0 && !EvoSimWithinTolerance(MathAbs(live-oldEntry),EvoSimulationPriceTolerancePoints*_Point,oldRisk,risk,EvoSimulationRiskTolerancePct))
   {
      EvoSimStatus(StringFormat("Cambio fuera de tolerancia: riesgo %.2f -> %.2f. Revisa y CONFIRMA",oldRisk,risk)); return;
   }
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED) || !AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) || !AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
   { EvoSimStatus("Trading no permitido por terminal, asesor o cuenta"); return; }
   double gap=SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point+EvoSimTick();
   if(evoSimMode>0 && !EvoSimPendingPriceValid(evoSimMode,evoSimEntry,q.bid,q.ask,gap))
   { EvoSimStatus(EvoSimPendingGuide(q,gap)+". Pulsa ACTUALIZAR o ajusta ENTRADA."); return; }
   if(evoSimMode>0 && (SymbolInfoInteger(_Symbol,SYMBOL_ORDER_MODE) & ((evoSimMode==1 || evoSimMode==3)?SYMBOL_ORDER_LIMIT:SYMBOL_ORDER_STOP))==0)
   { EvoSimStatus("El broker no admite este tipo de pendiente"); return; }
   double reference=evoSimMode>0?evoSimEntry:(evoSimBuy?q.bid:q.ask);
   if(evoSimBuy?(evoSimSL>reference-gap || evoSimTP<reference+gap):(evoSimSL<reference+gap || evoSimTP>reference-gap))
   { EvoSimStatus("SL/TP demasiado cerca para el broker; ajusta las lineas"); return; }
   double margin=0;
   if(!OrderCalcMargin(evoSimBuy?ORDER_TYPE_BUY:ORDER_TYPE_SELL,_Symbol,EvoSimulationLots,evoSimEntry,margin) || margin>AccountInfoDouble(ACCOUNT_MARGIN_FREE))
   { EvoSimStatus("Margen insuficiente o calculo no disponible"); return; }
   evoSimTrade.SetExpertMagicNumber(InpManageManualOnly?0:InpMagicToManage);
   evoSimTrade.SetDeviationInPoints(EvoSimulationPriceTolerancePoints); // Request no price deviation; execution mode may still allow slippage.
   evoSimTrade.SetTypeFillingBySymbol(_Symbol);
   bool ok=false;
   if(evoSimMode>0)
   {
      if((SymbolInfoInteger(_Symbol,SYMBOL_EXPIRATION_MODE) & SYMBOL_EXPIRATION_GTC)==0)
      { EvoSimStatus("El simbolo no admite pendiente sin vencimiento (GTC)"); return; }
      evoSimTrade.SetTypeFilling(ORDER_FILLING_RETURN);
      ok=evoSimTrade.OrderOpen(_Symbol,EvoSimOrderType(),EvoSimulationLots,0,evoSimEntry,evoSimSL,evoSimTP,ORDER_TIME_GTC,0,"Monitor pendiente");
   }
   else ok=evoSimBuy?evoSimTrade.Buy(EvoSimulationLots,_Symbol,0,evoSimSL,evoSimTP,"Monitor entrada confirmada"):evoSimTrade.Sell(EvoSimulationLots,_Symbol,0,evoSimSL,evoSimTP,"Monitor entrada confirmada");
   uint rc=evoSimTrade.ResultRetcode();
   EvoSimStatus(StringFormat("Resultado %u: %s",rc,evoSimTrade.ResultRetcodeDescription()));
   EvoJournal("ENTRADA_CONFIRMADA_SOLICITUD",evoSimTrade.ResultOrder(),StringFormat("lado=%s; lotes=%.4f; riesgo_est=%.2f; retorno=%u; enviada=%d",evoSimBuy?"BUY":"SELL",EvoSimulationLots,risk,rc,(int)ok));
   EvoJournal("TIPO_ENTRADA_SOLICITADA",evoSimTrade.ResultOrder(),StringFormat("tipo=%s; entrada=%.8f; SL=%.8f; TP=%.8f; retorno=%u",EvoSimModeName(),evoSimEntry,evoSimSL,evoSimTP,rc));
   bool accepted=ok && (rc==TRADE_RETCODE_DONE || rc==TRADE_RETCODE_PLACED || rc==TRADE_RETCODE_DONE_PARTIAL);
   if(accepted) { evoSimActive=false; ObjectsDeleteAll(0,"EVO_SIM_"); }
   else EvoSimStatus(StringFormat("Orden no aceptada (%u): %s. Propuesta conservada para revisar.",rc,evoSimTrade.ResultRetcodeDescription()));
}
void EvoSimButton(const string name,const string caption,const int slot)
{
   EvoButton(name,2,caption,C'35,60,80');
   int w=(EvoPanelWidth()-28)/4;
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,evoPanelX+12+slot*(w+1));
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
}
// Buttons also work when the visual tester does not deliver line-drag events.
void EvoSimAdjust(const bool stop,const bool farther,const bool fine)
{
   if(!evoSimActive) { EvoSimStatus("Pulsa CALCULAR antes de ajustar SL/TP"); return; }
   double atr=0,tick=EvoSimTick();
   if(tick<=0 || (!fine && (!analysis.ATR(atr) || atr<=0))) { EvoSimStatus("Sin ATR/tick para ajustar"); return; }
   double step=fine?tick:MathMax(tick,EvoSimRound(atr*0.1));
   double side=evoSimBuy?1:-1;
   double old=stop?evoSimSL:evoSimTP;
   double next=EvoSimRound(old+(stop?-side:side)*(farther?1:-1)*step);
   if(next<=0 || (stop?side*(evoSimEntry-next)<=0:side*(next-evoSimEntry)<=0))
   { EvoSimStatus("Ajuste rechazado: SL/TP debe conservar su lado de la entrada"); return; }
   if(stop) evoSimSL=next; else evoSimTP=next;
   EvoSimLines(); EvoSimStatus(StringFormat("%s preparado: %.*f -> %.*f. Revisa presupuesto y CONFIRMA",stop?"SL":"TP",_Digits,old,_Digits,next));
}
void EvoSimExit()
{
   ulong target=0; int count=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      long magic=PositionGetInteger(POSITION_MAGIC);
      if(InpManageManualOnly?magic!=0:magic!=InpMagicToManage) continue;
      target=ticket; count++;
   }
   if(count!=1) { EvoSimStatus(count==0?"Sin posicion gestionada para salir":"Hay varias posiciones: salir requiere una unica posicion gestionada en este simbolo"); return; }
   evoSimTrade.SetDeviationInPoints(EvoDeviationPoints); evoSimTrade.SetTypeFillingBySymbol(_Symbol);
   bool ok=evoSimTrade.PositionClose(target);
   uint rc=evoSimTrade.ResultRetcode();
   EvoJournal("SALIDA_MANUAL_SOLICITUD",target,StringFormat("enviada=%d; retorno=%u; %s",(int)ok,rc,evoSimTrade.ResultRetcodeDescription()));
   EvoSimStatus(StringFormat("Salida #%I64u: %u %s",target,rc,evoSimTrade.ResultRetcodeDescription()));
}
ulong evoSimPendingSelected=0;
bool EvoSimPendingSelectedOrder()
{
   if(OrderGetString(ORDER_SYMBOL)!=_Symbol) return false;
   long magic=OrderGetInteger(ORDER_MAGIC);
   if(InpManageManualOnly?magic!=0:magic!=InpMagicToManage) return false;
   ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
   return type==ORDER_TYPE_BUY_LIMIT || type==ORDER_TYPE_BUY_STOP || type==ORDER_TYPE_SELL_LIMIT || type==ORDER_TYPE_SELL_STOP || type==ORDER_TYPE_BUY_STOP_LIMIT || type==ORDER_TYPE_SELL_STOP_LIMIT;
}
int EvoSimPendingTickets(ulong &tickets[])
{
   ArrayResize(tickets,0);
   for(int i=0;i<OrdersTotal();i++)
   {
      ulong ticket=OrderGetTicket(i); if(ticket==0 || !EvoSimPendingSelectedOrder()) continue;
      int n=ArraySize(tickets); ArrayResize(tickets,n+1); tickets[n]=ticket;
   }
   ArraySort(tickets); return ArraySize(tickets);
}
void EvoSimPendingPanel(const bool next=false)
{
   ulong tickets[]; int count=EvoSimPendingTickets(tickets),index=-1;
   for(int i=0;i<count;i++) if(tickets[i]==evoSimPendingSelected) index=i;
   if(count==0)
   {
      evoSimPendingSelected=0; EvoPanelLine(18,"EN ESPERA: ninguna orden gestionada de este simbolo",clrSilver);
      EvoPanelLine(19,"CANCELAR elimina una orden; SALIR cierra una posicion.",clrSilver); return;
   }
   index=index<0?0:next?(index+1)%count:index;
   evoSimPendingSelected=tickets[index];
   if(!OrderSelect(evoSimPendingSelected) || !EvoSimPendingSelectedOrder()) return;
   string type=EnumToString((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)); StringReplace(type,"ORDER_TYPE_","");
   EvoPanelLine(18,StringFormat("EN ESPERA %d/%d | #%I64u %s | entrada %.*f",index+1,count,evoSimPendingSelected,type,_Digits,OrderGetDouble(ORDER_PRICE_OPEN)),clrAqua);
   EvoPanelLine(19,StringFormat("SL %.*f | TP %.*f | CANCELAR #%I64u elimina esta orden",_Digits,OrderGetDouble(ORDER_SL),_Digits,OrderGetDouble(ORDER_TP),evoSimPendingSelected),clrGold);
   ObjectSetString(0,"EVO_CONTEXT_SIM_CANCEL",OBJPROP_TEXT,"CANCELAR #"+(string)evoSimPendingSelected);
   ObjectSetString(0,"EVO_CONTEXT_SIM_CANCEL",OBJPROP_TOOLTIP,"Elimina solo la orden pendiente seleccionada en EN ESPERA. Para varias, selecciona con OTRA PENDIENTE. No cierra posiciones.");
}
void EvoSimCancelPending()
{
   // Cancel exactly the ticket displayed to the user, never an automatically substituted order.
   ulong target=evoSimPendingSelected;
   if(target==0 || !OrderSelect(target) || !EvoSimPendingSelectedOrder())
   { EvoSimStatus("No hay pendiente seleccionada vigente. Revisa EN ESPERA."); return; }
   bool ok=evoSimTrade.OrderDelete(target); uint rc=evoSimTrade.ResultRetcode();
   EvoJournal("CANCELAR_PENDIENTE_SOLICITUD",target,StringFormat("enviada=%d; retorno=%u",(int)ok,rc));
   if(ok && rc==TRADE_RETCODE_DONE)
   { evoSimPendingSelected=0; EvoSimStatus(StringFormat("Pendiente #%I64u cancelada. Puedes preparar y confirmar otra entrada.",target)); }
   else EvoSimStatus(StringFormat("No se confirmo cancelacion #%I64u: %u %s",target,rc,evoSimTrade.ResultRetcodeDescription()));
}
void EvoSimMoveEntry(const bool up,const bool fine)
{
   if(!evoSimActive || evoSimMode==0) { EvoSimStatus("Entrada ajustable por botones para pendientes: selecciona tipo y CALCULAR"); return; }
   double atr=0,tick=EvoSimTick(); if(tick<=0 || (!fine && !analysis.ATR(atr))) return;
   double next=EvoSimRound(evoSimEntry+(up?1:-1)*(fine?tick:MathMax(tick,atr*.1)));
   if(next<=0) return;
   MqlTick q;
   if(!SymbolInfoTick(_Symbol,q) || q.ask<=0 || q.bid<=0) { EvoSimStatus("Sin cotizacion valida"); return; }
   double gap=SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point+tick;
   if(!EvoSimPendingPriceValid(evoSimMode,next,q.bid,q.ask,gap))
   {
      EvoSimStatus((evoSimMode==1 || evoSimMode==4?"BAJA":"SUBE")+StringFormat(" la entrada de %s. Usa ENTRADA VALIDA; el ajuste solicitado queda fuera del rango.",EvoSimModeName()));
      return;
   }
   // Absolute SL/TP are retained so the budget reflects the edited entry.
   evoSimEntry=next; EvoSimLines(); EvoSimStatus("Entrada preparada; SL/TP conservados. Revisa presupuesto.");
}
void EvoSimAdjustButton(const string name,const string text,const int slot,const int row)
{
   EvoSimButton(name,text,slot);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,evoPanelY+10+row*EvoPanelPitch());
   ObjectSetString(0,name,OBJPROP_TOOLTIP,"Ajusta la propuesta, no la posicion abierta. CONFIRMAR usa el SL/TP preparado. Cerca/lejos respecto de entrada.");
}
// After submitting, show current broker levels rather than a discarded proposal.
bool EvoSimDrawBrokerAmounts()
{
   int count=0; double entry=0,sl=0,tp=0,volume=0; bool buy=false; string label="";
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i); if(ticket==0 || PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      long magic=PositionGetInteger(POSITION_MAGIC); if(InpManageManualOnly?magic!=0:magic!=InpMagicToManage) continue;
      count++; entry=PositionGetDouble(POSITION_PRICE_OPEN); sl=PositionGetDouble(POSITION_SL); tp=PositionGetDouble(POSITION_TP);
      volume=PositionGetDouble(POSITION_VOLUME); buy=PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY;
      label="POSICION #"+(string)ticket;
   }
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      ulong ticket=OrderGetTicket(i); if(ticket==0 || OrderGetString(ORDER_SYMBOL)!=_Symbol) continue;
      long magic=OrderGetInteger(ORDER_MAGIC); if(InpManageManualOnly?magic!=0:magic!=InpMagicToManage) continue;
      ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(type!=ORDER_TYPE_BUY_LIMIT && type!=ORDER_TYPE_BUY_STOP && type!=ORDER_TYPE_SELL_LIMIT && type!=ORDER_TYPE_SELL_STOP) continue;
      count++; entry=OrderGetDouble(ORDER_PRICE_OPEN); sl=OrderGetDouble(ORDER_SL); tp=OrderGetDouble(ORDER_TP); volume=OrderGetDouble(ORDER_VOLUME_CURRENT);
      buy=type==ORDER_TYPE_BUY_LIMIT || type==ORDER_TYPE_BUY_STOP; label="PENDIENTE #"+(string)ticket;
   }
   if(count==0) return false;
   if(count>1) { EvoPanelLine(3,"Varias posiciones/ordenes: importes individuales no disponibles aqui",clrGold); EvoPanelLine(4,""); EvoPanelLine(5,""); return true; }
   string currency=AccountInfoString(ACCOUNT_CURRENCY); double stopProfit=0,targetProfit=0;
   bool stopOK=sl>0 && OrderCalcProfit(buy?ORDER_TYPE_BUY:ORDER_TYPE_SELL,_Symbol,volume,entry,sl,stopProfit);
   bool targetOK=tp>0 && OrderCalcProfit(buy?ORDER_TYPE_BUY:ORDER_TYPE_SELL,_Symbol,volume,entry,tp,targetProfit);
   EvoPanelLine(3,stopOK?StringFormat("%s SL: %.2f %s",stopProfit>=0?"BENEFICIO PROTEGIDO EN":"PERDIDA PREVISTA EN",MathAbs(stopProfit),currency):sl<=0?"SL: SIN STOP COLOCADO":"SL: importe no disponible",stopOK && stopProfit>=0?clrLimeGreen:clrSalmon);
   EvoPanelLine(4,targetOK?StringFormat("RESULTADO PREVISTO EN TP: %+.2f %s",targetProfit,currency):tp<=0?"TP: SIN OBJETIVO COLOCADO":"TP: importe no disponible",targetOK && targetProfit>=0?clrLimeGreen:clrGold);
   EvoPanelLine(5,label+StringFormat(" | Entrada %.*f | SL %.*f | TP %.*f",_Digits,entry,_Digits,sl,_Digits,tp));
   ObjectSetString(0,"EVO_CONTEXT_3",OBJPROP_TOOLTIP,"Resultado estimado desde entrada al SL actual del broker; se actualiza si BE o trailing mueven el stop. Sin comisiones, swap ni deslizamiento.");
   return true;
}
void EvoSimDraw()
{
   EvoPanelBackground(20); EvoDrawTabs();
   EvoPanelLine(1,"SIMULACION | "+(evoSimBuy?"COMPRA":"VENTA")+StringFormat(" | %.4f lotes",EvoSimulationLots),clrAqua);
   EvoSimButton("EVO_CONTEXT_SIDE",evoSimBuy?"LADO: COMPRA":"LADO: VENTA",0);
   EvoSimButton("EVO_CONTEXT_CALC","CALCULAR",1);
   EvoSimButton("EVO_CONTEXT_QUOTE","ACTUALIZAR",2);
   ObjectSetString(0,"EVO_CONTEXT_QUOTE",OBJPROP_TOOLTIP,"Mercado: actualiza solo entrada. Pendiente: reubica entrada a 0.5 ATR o minimo broker y traslada SL/TP conservando distancias. No envia ordenes.");
   EvoSimButton("EVO_CONTEXT_CONFIRM",evoSimMode>0?"COLOCAR "+EvoSimModeName():evoSimBuy?"CONFIRMAR BUY":"CONFIRMAR SELL",3);
   EvoSimAdjustButton("EVO_CONTEXT_SIM_SL_NEAR","SL cerca 0.1 ATR",0,10);
   EvoSimAdjustButton("EVO_CONTEXT_SIM_SL_FAR","SL lejos 0.1 ATR",1,10);
   EvoSimAdjustButton("EVO_CONTEXT_SIM_TP_NEAR","TP cerca 0.1 ATR",2,10);
   EvoSimAdjustButton("EVO_CONTEXT_SIM_TP_FAR","TP lejos 0.1 ATR",3,10);
   EvoSimAdjustButton("EVO_CONTEXT_SIM_SL_NEAR_TICK","SL cerca 1 tick",0,11);
   EvoSimAdjustButton("EVO_CONTEXT_SIM_SL_FAR_TICK","SL lejos 1 tick",1,11);
   EvoSimAdjustButton("EVO_CONTEXT_SIM_TP_NEAR_TICK","TP cerca 1 tick",2,11);
   EvoSimAdjustButton("EVO_CONTEXT_SIM_TP_FAR_TICK","TP lejos 1 tick",3,11);
   EvoSimAdjustButton("EVO_CONTEXT_SIM_EXIT","SALIR A MERCADO",0,12);
   ObjectSetInteger(0,"EVO_CONTEXT_SIM_EXIT",OBJPROP_BGCOLOR,clrMaroon);
   ObjectSetString(0,"EVO_CONTEXT_SIM_EXIT",OBJPROP_TOOLTIP,"Cierra inmediatamente la unica posicion gestionada del simbolo, con ganancia o perdida. No depende de Gestion ACTIVA.");
   EvoSimAdjustButton("EVO_CONTEXT_SIM_MODE","TIPO: "+EvoSimModeName(),0,14);
   ObjectSetString(0,"EVO_CONTEXT_SIM_MODE",OBJPROP_TOOLTIP,"Alterna MERCADO, BUY LIMIT, BUY STOP, SELL LIMIT, SELL STOP. Cambiar tipo borra la propuesta; pulsa CALCULAR.");
   EvoSimAdjustButton("EVO_CONTEXT_SIM_CANCEL","CANCELAR PENDIENTE",1,14);
   EvoSimAdjustButton("EVO_CONTEXT_SIM_VALID","ENTRADA VALIDA",2,14);
   EvoSimAdjustButton("EVO_CONTEXT_SIM_PENDING_NEXT","OTRA PENDIENTE",3,14);
   ObjectSetInteger(0,"EVO_CONTEXT_SIM_CANCEL",OBJPROP_BGCOLOR,clrMaroon);
   EvoSimPendingPanel();
   ObjectSetString(0,"EVO_CONTEXT_SIM_VALID",OBJPROP_TOOLTIP,"Prepara una entrada del lado correcto del precio actual y traslada SL/TP conservando sus distancias. Revisa el presupuesto y pulsa COLOCAR. No envia ordenes.");
   EvoSimAdjustButton("EVO_CONTEXT_SIM_ENTRY_UP","Entrada +0.1 ATR",0,15);
   EvoSimAdjustButton("EVO_CONTEXT_SIM_ENTRY_DOWN","Entrada -0.1 ATR",1,15);
   EvoSimAdjustButton("EVO_CONTEXT_SIM_ENTRY_UP_TICK","Entrada +1 tick",2,15);
   EvoSimAdjustButton("EVO_CONTEXT_SIM_ENTRY_DOWN_TICK","Entrada -1 tick",3,15);
   MqlTick pendingQuote;
   if(evoSimMode>0 && evoSimActive && SymbolInfoTick(_Symbol,pendingQuote))
   {
      double gap=SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point+EvoSimTick();
      bool ready=EvoSimPendingPriceValid(evoSimMode,evoSimEntry,pendingQuote.bid,pendingQuote.ask,gap);
      EvoPanelLine(16,EvoSimPendingGuide(pendingQuote,gap),ready?clrLimeGreen:clrSalmon);
      EvoPanelLine(17,ready?"ENTRADA VALIDA: revisa SL/TP y pulsa COLOCAR":(evoSimMode==1 || evoSimMode==4?"BAJA":"SUBE")+" la entrada o pulsa ENTRADA VALIDA; despues COLOCAR",ready?clrSilver:clrGold);
   }
   else
   {
      EvoPanelLine(16,"Tipo: "+EvoSimModeName()+" | pendientes GTC: hasta ejecucion o cancelacion",clrAqua);
      EvoPanelLine(17,"Limit: retroceso | Stop: ruptura. SL/TP absolutos preparados.",clrSilver);
   }
   EvoPanelLine(13,"SL/TP preparados se envian al entrar; luego actuan las protecciones activas.",clrSilver);
   double risk=0,gain=0; string error="";
   if(EvoSimValues(risk,gain,error))
   {
      string currency=AccountInfoString(ACCOUNT_CURRENCY); double eq=AccountInfoDouble(ACCOUNT_EQUITY);
      EvoPanelLine(3,StringFormat("PERDIDA SL: %.2f %s | %.2f%% equity",risk,currency,eq>0?100*risk/eq:0),clrSalmon);
      EvoPanelLine(4,StringFormat("GANANCIA TP: %.2f %s | B/R %.2f:1",gain,currency,gain/risk),clrLimeGreen);
      EvoPanelLine(5,StringFormat("Entrada %.*f | SL %.*f | TP %.*f",_Digits,evoSimEntry,_Digits,evoSimSL,_Digits,evoSimTP));
   }
   else if(evoSimActive || !EvoSimDrawBrokerAmounts())
   {
      EvoPanelLine(3,evoSimActive?error:"Sin propuesta ni posicion. CALCULAR prepara los niveles.",clrGold);
      EvoPanelLine(4,"TP: prepara niveles validos para calcular el importe"); EvoPanelLine(5,"");
   }
   EvoPanelLine(6,evoSimMessage,clrWhite);
   EvoPanelLine(8,evoSimOrigin,clrAqua);
   EvoPanelLine(9,"Propuesta editable. Solo CONFIRMAR envia una orden.",clrGold);
   EvoPanelLine(7,"Estimado sin comision/swap/deslizamiento. Gestion: "+(EvoManagePositions?"ACTIVA":"OFF"));
}
bool EvoSimEvent(const int id,const string name)
{
   if(!EvoShowContext) return false;
   if(id==CHARTEVENT_OBJECT_DRAG && StringFind(name,"EVO_SIM_")==0 && evoSimActive)
   {
      evoSimEntry=EvoSimRound(ObjectGetDouble(0,"EVO_SIM_ENTRADA",OBJPROP_PRICE));
      evoSimSL=EvoSimRound(ObjectGetDouble(0,"EVO_SIM_SL",OBJPROP_PRICE));
      evoSimTP=EvoSimRound(ObjectGetDouble(0,"EVO_SIM_TP",OBJPROP_PRICE));
      EvoSimLines(); return true;
   }
   if(id!=CHARTEVENT_OBJECT_CLICK) return false;
   if(StringFind(name,"EVO_CONTEXT_TAB_")==0 && (evoSimulationView || evoPanelMinimized))
   {
      evoPanelMinimized=false; evoSimulationView=false;
      ObjectsDeleteAll(0,"EVO_CONTEXT_");
      return false; // Let the normal tab handler select the requested page.
   }
   if(name=="EVO_CONTEXT_MIN") { evoPanelMinimized=!evoPanelMinimized; ObjectsDeleteAll(0,"EVO_CONTEXT_"); return true; }
   if(name=="EVO_CONTEXT_SIM") { evoSimulationView=!evoSimulationView; if(evoSimulationView) { EvoSetChartLinesVisible(true); if(evoSimActive) EvoSimLines(); } ObjectsDeleteAll(0,"EVO_CONTEXT_"); return true; }
   if(name=="EVO_CONTEXT_SIDE") { evoSimOrigin="Preparacion manual"; evoSimBuy=!evoSimBuy; evoSimMode=0; evoSimActive=false; ObjectsDeleteAll(0,"EVO_SIM_"); evoSimMessage="Lado cambiado: pulsa CALCULAR"; }
   else if(name=="EVO_CONTEXT_CALC") EvoSimCalculate();
   else if(name=="EVO_CONTEXT_QUOTE" || name=="EVO_CONTEXT_SIM_VALID") EvoSimUpdateQuote();
   else if(name=="EVO_CONTEXT_CONFIRM") EvoSimConfirm();
   else if(name=="EVO_CONTEXT_SIM_MODE")
   {
      evoSimMode=(evoSimMode+1)%5; if(evoSimMode>0) evoSimBuy=evoSimMode<=2;
      evoSimActive=false; ObjectsDeleteAll(0,"EVO_SIM_"); EvoSimStatus("Tipo "+EvoSimModeName()+": pulsa CALCULAR");
   }
   else if(name=="EVO_CONTEXT_SIM_PENDING_NEXT") EvoSimPendingPanel(true);
   else if(name=="EVO_CONTEXT_SIM_CANCEL") EvoSimCancelPending();
   else if(StringFind(name,"EVO_CONTEXT_SIM_ENTRY_")==0) EvoSimMoveEntry(StringFind(name,"_UP")>=0,StringFind(name,"_TICK")>=0);
   else if(name=="EVO_CONTEXT_SIM_EXIT") EvoSimExit();
   else if(StringFind(name,"EVO_CONTEXT_SIM_SL_")==0 || StringFind(name,"EVO_CONTEXT_SIM_TP_")==0)
      EvoSimAdjust(StringFind(name,"_SL_")>=0,StringFind(name,"_FAR")>=0,StringFind(name,"_TICK")>=0);
   else return false;
   ObjectSetInteger(0,name,OBJPROP_STATE,false); return true;
}
#endif
