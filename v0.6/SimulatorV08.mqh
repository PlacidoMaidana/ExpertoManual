#ifndef EVO_SIMULATOR_V08
#define EVO_SIMULATOR_V08
// Explicit proposals only: field edits never send trading requests.
int evo08TargetKind=0; // 0 new entry, 1 loaded position, 2 loaded pending
ulong evo08Target=0,evo08CancelTickets[];
ulong evo08CloseTarget=0;
ulong evo08CancelArmed=0;
double evo08ATR=0,evo08SLATR=0,evo08TPATR=0;
bool evo08Initialized=false,evo08QuickTP=false;

bool Evo08Number(string text,double &value)
{
   StringTrimLeft(text); StringTrimRight(text); StringReplace(text,",",".");
   int digits=0,dots=0;
   for(int i=0;i<StringLen(text);i++)
   {
      ushort c=StringGetCharacter(text,i);
      if(c>='0' && c<='9') digits++;
      else if(c=='.' && ++dots<=1) continue;
      else if((c=='-' || c=='+') && i==0) continue;
      else return false;
   }
   if(digits==0) return false;
   value=StringToDouble(text); return MathIsValidNumber(value);
}
bool Evo08Levels(const bool buy,const double entry,const double atr,const double slATR,const double tpATR,const double tick,double &sl,double &tp)
{
   if(!MathIsValidNumber(entry) || !MathIsValidNumber(atr) || !MathIsValidNumber(slATR) || !MathIsValidNumber(tpATR) || tick<=0 || atr<=0 || entry<=0) return false;
   double side=buy?1:-1;
   sl=MathRound((entry-side*slATR*atr)/tick)*tick;
   tp=MathRound((entry+side*tpATR*atr)/tick)*tick;
   return sl>0 && tp>0 && side*(tp-sl)>0;
}
bool Evo08DoesNotWiden(const bool buy,const double oldSL,const double newSL,const double tick)
{ return oldSL<=0 || (buy?newSL>=oldSL-tick*.1:newSL<=oldSL+tick*.1); }
ulong Evo08ChooseCloseTarget(const int targetKind,const ulong loaded,const bool loadedValid,const ulong onlyPosition,const int count)
{ return targetKind==1?(loadedValid?loaded:0):targetKind==0 && count==1?onlyPosition:0; }
void Evo08Init()
{
   if(evo08Initialized) return;
   evo08Initialized=true; evo08SLATR=EvoSLATR;
   evo08TPATR=EvoTPMode==EVO_TP_ATR?EvoTPATR:EvoSLATR*EvoRR;
}
bool Evo08PositionSelected()
{
   if(PositionGetString(POSITION_SYMBOL)!=_Symbol) return false;
   long magic=PositionGetInteger(POSITION_MAGIC);
   return InpManageManualOnly?magic==0:magic==InpMagicToManage;
}
bool Evo08TargetValid()
{
   if(evo08TargetKind==1) return evo08Target>0 && PositionSelectByTicket(evo08Target) && Evo08PositionSelected() &&
      (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)==evoSimBuy && MathAbs(PositionGetDouble(POSITION_PRICE_OPEN)-evoSimEntry)<EvoSimTick()*.5;
   if(evo08TargetKind==2) return evo08Target>0 && OrderSelect(evo08Target) && EvoSimPendingSelectedOrder() &&
      OrderGetInteger(ORDER_TYPE)==(long)EvoSimOrderType();
   return false;
}
bool Evo08TradingAllowed()
{
   bool allowed=TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && MQLInfoInteger(MQL_TRADE_ALLOWED) && AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) && AccountInfoInteger(ACCOUNT_TRADE_EXPERT);
   if(!allowed) EvoSimStatus("Trading no permitido por terminal, asesor o cuenta");
   return allowed;
}
void Evo08FieldsSync()
{
   if(ObjectFind(0,"EVO_CONTEXT_V08_SL")>=0) ObjectSetString(0,"EVO_CONTEXT_V08_SL",OBJPROP_TEXT,DoubleToString(evo08SLATR,3));
   if(ObjectFind(0,"EVO_CONTEXT_V08_TP")>=0) ObjectSetString(0,"EVO_CONTEXT_V08_TP",OBJPROP_TEXT,DoubleToString(evo08TPATR,3));
   if(ObjectFind(0,"EVO_CONTEXT_V08_ENTRY")>=0) ObjectSetString(0,"EVO_CONTEXT_V08_ENTRY",OBJPROP_TEXT,DoubleToString(evoSimEntry,_Digits));
}
void Evo08SyncDistances()
{
   if(evo08ATR>0 && evoSimActive)
   {
      double side=evoSimBuy?1:-1;
      evo08SLATR=side*(evoSimEntry-evoSimSL)/evo08ATR;
      evo08TPATR=side*(evoSimTP-evoSimEntry)/evo08ATR;
   }
   Evo08FieldsSync();
}
void Evo08New(const int mode,const bool buy)
{
   evo08TargetKind=0; evo08Target=0; evo08ATR=0;
   evoSimMode=mode; evoSimBuy=mode>0?mode<=2:buy;
   evoSimActive=false; evoSimEntry=0; ObjectsDeleteAll(0,"EVO_SIM_");
   evo08SLATR=EvoSLATR; evo08TPATR=EvoTPMode==EVO_TP_ATR?EvoTPATR:EvoSLATR*EvoRR;
   Evo08FieldsSync(); EvoSimStatus("Nueva propuesta: ajusta ATR y pulsa CALCULAR NIVELES. No envia ordenes.");
}
bool Evo08ReadFields(double &sl,double &tp,double &entry)
{
   if(!Evo08Number(ObjectGetString(0,"EVO_CONTEXT_V08_SL",OBJPROP_TEXT),sl) ||
      !Evo08Number(ObjectGetString(0,"EVO_CONTEXT_V08_TP",OBJPROP_TEXT),tp))
   { EvoSimStatus("SL/TP: escribe numeros validos en ATR (punto o coma decimal)"); return false; }
   entry=evoSimEntry;
   if(evoSimMode>0 && !Evo08Number(ObjectGetString(0,"EVO_CONTEXT_V08_ENTRY",OBJPROP_TEXT),entry))
   { EvoSimStatus("Precio pendiente invalido; 0 permite preparar un precio automatico"); return false; }
   if(evo08TargetKind!=1 && (sl<=0 || tp<=0))
   { EvoSimStatus("Nueva entrada / pendiente: SL y TP deben ser mayores que cero ATR"); return false; }
   if(entry<0) { EvoSimStatus("El precio no puede ser negativo"); return false; }
   return true;
}
bool Evo08Build(const bool refreshATR=false)
{
   Evo08Init(); double slATR=0,tpATR=0,entry=0;
   if(!Evo08ReadFields(slATR,tpATR,entry)) return false;
   if(evo08TargetKind>0 && !Evo08TargetValid()) { EvoSimStatus("El ticket cargado ya no esta disponible o no pertenece a esta gestion"); return false; }
   MqlTick q; double atr=evo08ATR;
   if((refreshATR || atr<=0) && (!analysis.ATR(atr) || atr<=0)) { EvoSimStatus("Sin ATR valido"); return false; }
   if(!SymbolInfoTick(_Symbol,q) || q.ask<=0 || q.bid<=0 || EvoSimTick()<=0) { EvoSimStatus("Sin cotizacion / tick valido"); return false; }
   if(evo08TargetKind==1) entry=PositionGetDouble(POSITION_PRICE_OPEN);
   else if(evoSimMode==0) entry=evoSimBuy?q.ask:q.bid;
   else if(entry<=0)
   {
      double offset=MathMax(.5*atr,SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point+2*EvoSimTick());
      entry=EvoSimPendingBoundary(evoSimMode,q.bid,q.ask,offset,EvoSimTick());
   }
   double stop=0,target=0;
   if(!Evo08Levels(evoSimBuy,entry,atr,slATR,tpATR,EvoSimTick(),stop,target)) { EvoSimStatus("Niveles invalidos; revisa distancias y lado SL/TP"); return false; }
   evo08ATR=atr; evo08SLATR=slATR; evo08TPATR=tpATR;
   evoSimEntry=EvoSimRound(entry); evoSimSL=EvoSimRound(stop); evoSimTP=EvoSimRound(target);
   evoSimActive=true; EvoSimLines(); Evo08SyncDistances();
   EvoSimStatus(evo08TargetKind>0?"Cambios preparados. ACTUALIZAR SL/TP aplica al ticket cargado.":"Niveles preparados. Revisa importes y CONFIRMA la orden.");
   return true;
}
bool Evo08FieldsChanged()
{
   double sl=0,tp=0,entry=0;
   if(!Evo08ReadFields(sl,tp,entry)) return true;
   return MathAbs(sl-evo08SLATR)>.00051 || MathAbs(tp-evo08TPATR)>.00051 || (evoSimMode>0 && MathAbs(entry-evoSimEntry)>EvoSimTick()*.1);
}
void Evo08Load(const bool pending)
{
   ulong tickets[]; ArrayResize(tickets,0);
   if(pending) EvoSimPendingTickets(tickets);
   else for(int i=0;i<PositionsTotal();i++)
   {
      ulong ticket=PositionGetTicket(i); if(ticket==0 || !Evo08PositionSelected()) continue;
      int n=ArraySize(tickets); ArrayResize(tickets,n+1); tickets[n]=ticket;
   }
   ArraySort(tickets); int count=ArraySize(tickets);
   if(count==0) { EvoSimStatus(pending?"Sin pendientes gestionadas en este simbolo":"Sin posiciones gestionadas en este simbolo"); return; }
   int chosen=0;
   for(int i=0;i<count;i++) if(tickets[i]==evo08Target) chosen=(i+1)%count;
   ulong ticket=tickets[chosen]; double entry=0,stop=0,tp=0;
   if(pending)
   {
      if(!OrderSelect(ticket) || !EvoSimPendingSelectedOrder()) return;
      ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(type==ORDER_TYPE_BUY_STOP_LIMIT || type==ORDER_TYPE_SELL_STOP_LIMIT) { EvoSimStatus("Stop Limit no editable aqui; solo Buy/Sell Limit/Stop"); return; }
      evoSimMode=type==ORDER_TYPE_BUY_LIMIT?1:type==ORDER_TYPE_BUY_STOP?2:type==ORDER_TYPE_SELL_LIMIT?3:4;
      evoSimBuy=evoSimMode<=2; entry=OrderGetDouble(ORDER_PRICE_OPEN); stop=OrderGetDouble(ORDER_SL); tp=OrderGetDouble(ORDER_TP);
   }
   else
   {
      if(!PositionSelectByTicket(ticket) || !Evo08PositionSelected()) return;
      evoSimMode=0; evoSimBuy=PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY;
      entry=PositionGetDouble(POSITION_PRICE_OPEN); stop=PositionGetDouble(POSITION_SL); tp=PositionGetDouble(POSITION_TP);
   }
   double atr=0; if(!analysis.ATR(atr) || atr<=0) { EvoSimStatus("Sin ATR para cargar gestion"); return; }
   evo08Target=ticket; evo08TargetKind=pending?2:1; evo08ATR=atr; evoSimEntry=entry;
   evoSimSL=stop>0?stop:EvoSimRound(entry-(evoSimBuy?1:-1)*atr*EvoSLATR);
   evoSimTP=tp>0?tp:EvoSimRound(entry+(evoSimBuy?1:-1)*atr*(EvoTPMode==EVO_TP_ATR?EvoTPATR:EvoSLATR*EvoRR));
   evoSimActive=true; Evo08SyncDistances(); EvoSimLines();
   EvoSimStatus(StringFormat("Cargado #%I64u (%d/%d). Editar no envia cambios; usar ACTUALIZAR SL/TP.",ticket,chosen+1,count));
}
void Evo08Apply()
{
   if(evo08TargetKind==0) { EvoSimStatus("Primero CARGAR POSICION o CARGAR PENDIENTE"); return; }
   if(!Evo08TargetValid()) { EvoSimStatus("Ticket cargado no vigente; no se sustituye por otro"); return; }
   if(Evo08FieldsChanged()) { if(Evo08Build()) EvoSimStatus("Campos preparados. Revisa y pulsa ACTUALIZAR SL/TP otra vez."); return; }
   if(!evoSimActive || !Evo08TradingAllowed()) return;
   MqlTick q; if(!SymbolInfoTick(_Symbol,q) || q.bid<=0 || q.ask<=0) { EvoSimStatus("Sin cotizacion valida"); return; }
   double tick=EvoSimTick(); if(tick<=0) return;
   double gap=MathMax(SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL),SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL))*_Point+tick;
   bool buy=evo08TargetKind==1?PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY:evoSimMode<=2;
   double oldSL=evo08TargetKind==1?PositionGetDouble(POSITION_SL):OrderGetDouble(ORDER_SL);
   if(!Evo08DoesNotWiden(buy,oldSL,evoSimSL,tick)) { EvoSimStatus("Cambio rechazado: el SL existente no se aleja ni amplia el riesgo"); return; }
   double reference=evo08TargetKind==1?(buy?q.bid:q.ask):evoSimEntry;
   if(evoSimSL<=0 || evoSimTP<=0 || (buy?(evoSimSL>reference-gap || evoSimTP<reference+gap):(evoSimSL<reference+gap || evoSimTP>reference-gap)))
   { EvoSimStatus("SL/TP fuera de lado o demasiado cerca del precio para stops/freeze del broker"); return; }
   bool ok=false; ulong target=evo08Target;
   evoSimTrade.SetExpertMagicNumber(InpManageManualOnly?0:InpMagicToManage);
   if(evo08TargetKind==1) ok=evoSimTrade.PositionModify(target,evoSimSL,evoSimTP);
   else
   {
      if(!EvoSimPendingPriceValid(evoSimMode,evoSimEntry,q.bid,q.ask,gap)) { EvoSimStatus(EvoSimPendingGuide(q,gap)); return; }
      ENUM_ORDER_TYPE_TIME time=(ENUM_ORDER_TYPE_TIME)OrderGetInteger(ORDER_TYPE_TIME);
      datetime expiry=(datetime)OrderGetInteger(ORDER_TIME_EXPIRATION);
      ok=evoSimTrade.OrderModify(target,evoSimEntry,evoSimSL,evoSimTP,time,expiry,OrderGetDouble(ORDER_PRICE_STOPLIMIT));
   }
   uint rc=evoSimTrade.ResultRetcode();
   EvoJournal("SIM08_MODIFICAR_SLTP",target,StringFormat("tipo=%d; entrada=%.8f; SL=%.8f; TP=%.8f; enviada=%d; retorno=%u",evo08TargetKind,evoSimEntry,evoSimSL,evoSimTP,(int)ok,rc));
   if(ok && (rc==TRADE_RETCODE_DONE || rc==TRADE_RETCODE_NO_CHANGES))
   {
      if(evo08TargetKind==1) manager.TakeManualControl(target);
      EvoSimStatus("SL/TP procesados para #"+(string)target+". BE/trailing/protecciones siguen activos.");
   }
   else EvoSimStatus(StringFormat("No se confirmo modificacion #%I64u: %u %s",target,rc,evoSimTrade.ResultRetcodeDescription()));
}
void Evo08Close()
{
   ulong ticket=evo08CloseTarget; // Exactly the ticket displayed on the red button.
   if(ticket==0)
   {
      Evo08Load(false);
      if(evo08TargetKind==1 && Evo08TargetValid()) EvoSimStatus("Posicion seleccionada #"+(string)evo08Target+". Revisa el ticket y pulsa CERRAR para salir.");
      return;
   }
   if(!PositionSelectByTicket(ticket) || !Evo08PositionSelected() || (evo08TargetKind==1 && (!Evo08TargetValid() || evo08Target!=ticket)))
   { EvoSimStatus("La posicion mostrada para cerrar ya no esta vigente. Revisa el ticket; no se sustituye por otro."); return; }
   if(!Evo08TradingAllowed()) return;
   evoSimTrade.SetExpertMagicNumber(InpManageManualOnly?0:InpMagicToManage);
   evoSimTrade.SetDeviationInPoints(EvoDeviationPoints); evoSimTrade.SetTypeFillingBySymbol(_Symbol);
   bool ok=evoSimTrade.PositionClose(ticket); uint rc=evoSimTrade.ResultRetcode();
   EvoJournal("SIM08_CERRAR_POSICION",ticket,StringFormat("enviada=%d; retorno=%u",(int)ok,rc));
   EvoSimStatus(StringFormat("Cerrar #%I64u: %u %s",ticket,rc,evoSimTrade.ResultRetcodeDescription()));
   if(ok && rc==TRADE_RETCODE_DONE) { evo08CloseTarget=0; evoSimActive=false; ObjectsDeleteAll(0,"EVO_SIM_"); }
}
void Evo08CancelAll()
{
   ulong now=GetTickCount64();
   if(evo08CancelArmed==0 || now-evo08CancelArmed>10000)
   {
      int count=EvoSimPendingTickets(evo08CancelTickets);
      if(count==0) { EvoSimStatus("Sin pendientes gestionadas de este simbolo para cancelar"); return; }
      evo08CancelArmed=now;
      EvoSimStatus(StringFormat("Cancelar %d pendientes de %s: pulsa CONFIRMAR CANCELAR antes de 10 segundos. No cierra posiciones.",count,_Symbol)); return;
   }
   if(!Evo08TradingAllowed()) return;
   int done=0,failed=0,missing=0; evo08CancelArmed=0;
   evoSimTrade.SetExpertMagicNumber(InpManageManualOnly?0:InpMagicToManage);
   for(int i=0;i<ArraySize(evo08CancelTickets);i++)
   {
      ulong ticket=evo08CancelTickets[i];
      if(!OrderSelect(ticket) || !EvoSimPendingSelectedOrder()) { missing++; continue; }
      bool ok=evoSimTrade.OrderDelete(ticket); uint rc=evoSimTrade.ResultRetcode();
      if(ok && rc==TRADE_RETCODE_DONE) done++; else failed++;
      EvoJournal("SIM08_CANCELAR_PENDIENTE",ticket,StringFormat("enviada=%d; retorno=%u",(int)ok,rc));
   }
   EvoSimStatus(StringFormat("Pendientes: canceladas %d; fallidas %d; ya no vigentes %d. Revisa el broker.",done,failed,missing));
}
void Evo08Button(const string name,const string text,const int row,const int col,const int columns,const bool red=false,const bool active=false)
{
   int width=(EvoPanelWidth()-24)/columns;
   EvoButton(name,row,text,red?clrMaroon:active?clrDarkSlateBlue:C'35,60,80');
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,evoPanelX+12+col*width);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,evoPanelY+10+row*EvoPanelPitch());
   ObjectSetInteger(0,name,OBJPROP_YSIZE,EvoPanelPitch()-2);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,width-3); ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
}
void Evo08Edit(const string name,const string value,const int row,const int x,const int width,const bool readonly=false)
{
   if(ObjectFind(0,name)<0)
   {
      ObjectCreate(0,name,OBJ_EDIT,0,0,0); ObjectSetString(0,name,OBJPROP_TEXT,value);
   }
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,evoPanelX+x); ObjectSetInteger(0,name,OBJPROP_YDISTANCE,evoPanelY+10+row*EvoPanelPitch());
   ObjectSetInteger(0,name,OBJPROP_XSIZE,width); ObjectSetInteger(0,name,OBJPROP_YSIZE,EvoPanelPitch()-1);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,9); ObjectSetInteger(0,name,OBJPROP_BGCOLOR,C'30,37,44');
   ObjectSetInteger(0,name,OBJPROP_COLOR,clrWhite); ObjectSetInteger(0,name,OBJPROP_READONLY,readonly);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,35); ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
}
void Evo08DrawMoney()
{
   double entry=evoSimEntry,sl=evoSimSL,tp=evoSimTP,volume=EvoSimLots();
   bool buy=evoSimBuy,levels=evoSimActive && (evo08TargetKind==0 || Evo08TargetValid());
   string source="PROPUESTA";
   if(levels && evo08TargetKind>0)
   {
      volume=evo08TargetKind==1?PositionGetDouble(POSITION_VOLUME):OrderGetDouble(ORDER_VOLUME_CURRENT);
      source="CAMBIOS PROPUESTOS #"+(string)evo08Target;
   }
   if(!evoSimActive && evo08TargetKind==0)
   {
      int count=0;
      for(int i=0;i<PositionsTotal();i++)
      {
         ulong ticket=PositionGetTicket(i); if(ticket==0 || !Evo08PositionSelected()) continue;
         count++; entry=PositionGetDouble(POSITION_PRICE_OPEN); sl=PositionGetDouble(POSITION_SL); tp=PositionGetDouble(POSITION_TP);
         volume=PositionGetDouble(POSITION_VOLUME); buy=PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY;
         source="POSICION ACTUAL #"+(string)ticket;
      }
      for(int i=0;i<OrdersTotal();i++)
      {
         ulong ticket=OrderGetTicket(i); if(ticket==0 || !EvoSimPendingSelectedOrder()) continue;
         count++; entry=OrderGetDouble(ORDER_PRICE_OPEN); sl=OrderGetDouble(ORDER_SL); tp=OrderGetDouble(ORDER_TP);
         volume=OrderGetDouble(ORDER_VOLUME_CURRENT);
         long type=OrderGetInteger(ORDER_TYPE); buy=type==ORDER_TYPE_BUY_LIMIT || type==ORDER_TYPE_BUY_STOP || type==ORDER_TYPE_BUY_STOP_LIMIT;
         source="PENDIENTE ACTUAL #"+(string)ticket;
      }
      levels=count==1;
      if(count>1) source="VARIOS TICKETS: CARGAR UNO PARA VER IMPORTES";
      if(count==0)
      {
         // Preview only: never activates a proposal or sends a request.
         double atr=0,slATR=evo08SLATR,tpATR=evo08TPATR,price=0; MqlTick q;
         bool fields=ObjectFind(0,"EVO_CONTEXT_V08_SL")<0 || (Evo08Number(ObjectGetString(0,"EVO_CONTEXT_V08_SL",OBJPROP_TEXT),slATR) && Evo08Number(ObjectGetString(0,"EVO_CONTEXT_V08_TP",OBJPROP_TEXT),tpATR));
         bool priceField=evoSimMode==0 || ObjectFind(0,"EVO_CONTEXT_V08_ENTRY")<0 || Evo08Number(ObjectGetString(0,"EVO_CONTEXT_V08_ENTRY",OBJPROP_TEXT),price);
         if(fields && priceField && slATR>0 && tpATR>0 && analysis.ATR(atr) && atr>0 && SymbolInfoTick(_Symbol,q) && q.ask>0 && q.bid>0 && EvoSimTick()>0)
         {
            if(evoSimMode==0) price=buy?q.ask:q.bid;
            else if(price==0) price=EvoSimPendingBoundary(evoSimMode,q.bid,q.ask,MathMax(.5*atr,SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point+2*EvoSimTick()),EvoSimTick());
            entry=EvoSimRound(price); levels=Evo08Levels(buy,entry,atr,slATR,tpATR,EvoSimTick(),sl,tp);
         }
         source="VISTA PREVIA | CALCULAR fija los niveles";
      }
   }
   string money=AccountInfoString(ACCOUNT_CURRENCY); double atSL=0,atTP=0;
   bool stopOK=levels && sl>0 && OrderCalcProfit(buy?ORDER_TYPE_BUY:ORDER_TYPE_SELL,_Symbol,volume,entry,sl,atSL);
   bool targetOK=levels && tp>0 && OrderCalcProfit(buy?ORDER_TYPE_BUY:ORDER_TYPE_SELL,_Symbol,volume,entry,tp,atTP);
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   string risk=stopOK?(atSL<0?StringFormat("RIESGO AL SL: %.2f %s",-atSL,money):StringFormat("GANANCIA PROTEGIDA SL: %.2f %s",atSL,money)):"RIESGO AL SL: "+(levels && sl<=0?"SIN STOP":"NO DISPONIBLE");
   if(stopOK && atSL<0 && equity>0) risk+=StringFormat(" | %.2f%% equity",-atSL/equity*100);
   string gain=targetOK?(atTP>=0?StringFormat("GANANCIA AL TP: %.2f %s",atTP,money):StringFormat("RESULTADO AL TP: %.2f %s",atTP,money)):"GANANCIA AL TP: "+(levels && tp<=0?"SIN TP":"NO DISPONIBLE");
   EvoPanelLine(3,risk,stopOK && atSL>=0?clrLimeGreen:clrSalmon,true);
   EvoPanelLine(4,gain,targetOK && atTP>=0?clrLimeGreen:clrGold,true);
   string detail=source+StringFormat("\nVolumen %.4f lotes. Entrada %.*f; SL %.*f; TP %.*f.\n",volume,_Digits,entry,_Digits,sl,_Digits,tp)+"Importes desde entrada, en moneda de cuenta. Sin comisiones, swap ni deslizamiento. No son resultados garantizados. Vista previa puede variar con cotizacion y ATR; CALCULAR prepara niveles fijos.";
   ObjectSetString(0,"EVO_CONTEXT_3",OBJPROP_TOOLTIP,detail); ObjectSetString(0,"EVO_CONTEXT_4",OBJPROP_TOOLTIP,detail);
   EvoPanelLine(17,source,clrSilver); ObjectSetString(0,"EVO_CONTEXT_17",OBJPROP_TOOLTIP,detail);
}
void EvoSimDraw()
{
   Evo08Init(); EvoPanelBackground(31); EvoDrawTabs();
   if(evoSimMode==0 && ObjectFind(0,"EVO_SIM_ENTRADA")>=0)
   { ObjectSetInteger(0,"EVO_SIM_ENTRADA",OBJPROP_SELECTABLE,false); ObjectSetInteger(0,"EVO_SIM_ENTRADA",OBJPROP_SELECTED,false); }
   EvoPanelLine(1,"SIMULACION Y GESTION v0.8 | "+_Symbol,clrWhite,true);
   EvoPanelLine(2,StringFormat("Volumen NUEVA orden: %.4f lotes = %.2f microlotes",EvoSimLots(),EvoSimLots()/.01),clrWhite);
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP),increment=step>0?MathCeil(.01/step-1e-8)*step:.01;
   Evo08Button("EVO_CONTEXT_V08_VOL_MINUS",StringFormat("-%.2f microlote(s)",increment/.01),5,0,2);
   Evo08Button("EVO_CONTEXT_V08_VOL_PLUS",StringFormat("+%.2f microlote(s)",increment/.01),5,1,2);
   EvoPanelLine(6,"1. TIPO DE NUEVA ORDEN | cambiar tipo descarta propuesta",clrWhite,true);
   string modes[]={"MERCADO BUY","MERCADO SELL","BUY LIMIT","BUY STOP","SELL LIMIT","SELL STOP"};
   int codes[]={0,0,1,2,3,4};
   for(int i=0;i<6;i++) Evo08Button("EVO_CONTEXT_V08_MODE_"+(string)i,modes[i],7+i/3,i%3,3,false,evo08TargetKind==0 && evoSimMode==codes[i] && (i>=2 || evoSimBuy==(i==0)));
   EvoPanelLine(9,"2. DISTANCIAS | ATR editables",clrWhite,true);
   EvoPanelLine(10,"SL ATR",clrSilver);
   int half=(EvoPanelWidth()-24)/2;
   Evo08Edit("EVO_CONTEXT_V08_SL",DoubleToString(evo08SLATR,3),10,90,half-100);
   Evo08Edit("EVO_CONTEXT_V08_TP",DoubleToString(evo08TPATR,3),10,half+90,half-100);
   string label="EVO_CONTEXT_V08_TP_LABEL";
   EvoIndicatorsText(label,evoPanelX+half+12,evoPanelY+10+10*EvoPanelPitch(),70,"TP ATR",clrSilver,9,false,"Distancia en ATR desde entrada");
   EvoPanelLine(11,evoSimMode>0?"Precio pendiente":"Entrada automatica",clrSilver);
   Evo08Edit("EVO_CONTEXT_V08_ENTRY",DoubleToString(evoSimEntry,_Digits),11,190,EvoPanelWidth()-204,evoSimMode==0);
   ObjectSetString(0,"EVO_CONTEXT_V08_ENTRY",OBJPROP_TOOLTIP,"Pendientes: precio exacto; 0 prepara automatico. Mercado: precio al calcular; se revalida al confirmar. Posicion cargada: entrada real no editable.");
   EvoPanelLine(12,"Atajos ATR para: "+(evo08QuickTP?"TP":"SL"),clrSilver);
   Evo08Button("EVO_CONTEXT_V08_QUICK_TARGET",evo08QuickTP?"USAR EN SL":"USAR EN TP",12,2,3);
   for(int i=0;i<6;i++) Evo08Button("EVO_CONTEXT_V08_QUICK_"+(string)i,DoubleToString(.5*(i+1),1),13,i,6);
   EvoPanelLine(14,evo08ATR>0?StringFormat("ATR ref %.*f | R:R 1:%.2f | %s",_Digits,evo08ATR,evo08SLATR>0?evo08TPATR/evo08SLATR:0,evo08TargetKind==1 && evo08SLATR<=0?"SL PROTEGIDO: R:R no aplica":"distancias desde entrada"):"ATR pendiente: CALCULAR NIVELES",clrSilver);
   EvoPanelLine(15,"3. ACCIONES DE PROPUESTA",clrWhite,true);
   Evo08Button("EVO_CONTEXT_V08_CALC","CALCULAR NIVELES",16,0,2);
   int managedPositions=0; ulong onlyPosition=0; bool anyPosition=false,anyPending=false;
   for(int i=0;i<PositionsTotal();i++)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      anyPosition=true;
      if(Evo08PositionSelected()) { managedPositions++; onlyPosition=ticket; }
   }
   for(int i=0;i<OrdersTotal();i++) if(OrderGetTicket(i)>0 && OrderGetString(ORDER_SYMBOL)==_Symbol) anyPending=true;
   bool entryBlocked=evo08TargetKind>0 || anyPosition || anyPending;
   string entryCaption=evo08TargetKind>0?"TICKET CARGADO: USAR ACTUALIZAR":anyPosition?"YA HAY POSICION":anyPending?"YA HAY PENDIENTE":!evoSimActive?"PREPARAR ENTRADA":evoSimMode>0?"COLOCAR "+EvoSimModeName():evoSimBuy?"ENTRAR BUY A MERCADO":"ENTRAR SELL A MERCADO";
   Evo08Button("EVO_CONTEXT_V08_CONFIRM",entryCaption,16,1,2);
   ObjectSetInteger(0,"EVO_CONTEXT_V08_CONFIRM",OBJPROP_BGCOLOR,entryBlocked?clrDimGray:!evoSimActive?C'115,80,15':evoSimMode>0?clrRoyalBlue:evoSimBuy?C'0,115,60':C'170,35,45');
   ObjectSetInteger(0,"EVO_CONTEXT_V08_CONFIRM",OBJPROP_BORDER_COLOR,entryBlocked?clrSilver:clrWhite);
   ObjectSetInteger(0,"EVO_CONTEXT_V08_CONFIRM",OBJPROP_FONTSIZE,9);
   ObjectSetString(0,"EVO_CONTEXT_V08_CONFIRM",OBJPROP_TOOLTIP,entryBlocked?"No agrega otra entrada mientras exista una posicion/pendiente del simbolo o se edite un ticket. Usar gestion abajo.":"Envia una orden real en mercado, o simulada por el probador. Primero revisar volumen, SL/TP e importes. Si no hay propuesta lista, la primera pulsacion solo prepara.");
   Evo08DrawMoney();
   EvoPanelLine(18,evoSimMessage,clrGold);
   EvoPanelLine(19,"4. GESTION | cargar ticket para editar SL/TP",clrWhite,true);
   Evo08Button("EVO_CONTEXT_V08_LOAD_POS","CARGAR POSICION",20,0,3);
   Evo08Button("EVO_CONTEXT_V08_LOAD_PENDING","CARGAR PENDIENTE",20,1,3);
   Evo08Button("EVO_CONTEXT_V08_NEW","NUEVA PROPUESTA",20,2,3);
   bool valid=evo08TargetKind>0 && Evo08TargetValid();
   EvoPanelLine(21,evo08TargetKind==0?"Objetivo: NUEVA ENTRADA":StringFormat("Objetivo: %s #%I64u | %s",evo08TargetKind==1?"POSICION":"PENDIENTE",evo08Target,valid?"vigente":"NO VIGENTE"),valid?clrWhite:clrGold);
   EvoPanelLine(22,"Editar campos solo prepara; ACTUALIZAR envia al ticket cargado.",clrSilver);
   Evo08Button("EVO_CONTEXT_V08_APPLY","ACTUALIZAR SL/TP",23,0,2);
   evo08CloseTarget=Evo08ChooseCloseTarget(evo08TargetKind,evo08Target,valid,onlyPosition,managedPositions);
   Evo08Button("EVO_CONTEXT_V08_CLOSE",evo08CloseTarget>0?"CERRAR #"+(string)evo08CloseTarget:managedPositions>0?"ELEGIR POSICION A CERRAR":"SIN POSICION PARA CERRAR",23,1,2,true);
   ObjectSetInteger(0,"EVO_CONTEXT_V08_CLOSE",OBJPROP_BGCOLOR,evo08CloseTarget>0?C'185,30,30':clrDimGray);
   ObjectSetString(0,"EVO_CONTEXT_V08_CLOSE",OBJPROP_TOOLTIP,"Con ticket visible: cierra inmediatamente esa posicion completa. Si hay una sola posicion y no estas editando otro ticket, se muestra automaticamente. Con varias, elegir mediante CARGAR POSICION. No modifica ni cancela pendientes.");
   ulong pending[]; int count=EvoSimPendingTickets(pending);
   bool armed=evo08CancelArmed>0 && GetTickCount64()-evo08CancelArmed<=10000;
   Evo08Button("EVO_CONTEXT_V08_CANCEL",armed?"CONFIRMAR CANCELAR "+(string)ArraySize(evo08CancelTickets):"CANCELAR PENDIENTES ("+(string)count+")",24,0,2,true);
   EvoPanelLine(25,"CARGAR de nuevo recorre tickets del simbolo y magic seleccionado.",clrSilver);
   EvoPanelLine(26,"SL no se aleja; BE/trailing pueden seguir ajustandolo despues.",clrSilver);
   EvoPanelLine(27,"SL ATR negativo = protegido, solo para posicion cargada.",clrSilver);
   EvoPanelLine(28,"Importes sin comision/swap/deslizamiento. No son riesgo garantizado.",clrSilver);
   EvoPanelLine(29,"Volumen propio de SIMULAR. No cambia lotes de tickets existentes.",clrSilver);
   EvoPanelLine(30,"Pendientes: Limit = retroceso | Stop = ruptura | GTC al crear.",clrSilver);
}
bool EvoSimEvent(const int id,const string name)
{
   if(!EvoShowContext) return false;
   if(id==CHARTEVENT_OBJECT_ENDEDIT && StringFind(name,"EVO_CONTEXT_V08_")==0) { Evo08Build(); return true; }
   if(id==CHARTEVENT_OBJECT_DRAG && StringFind(name,"EVO_SIM_")==0)
   {
      bool handled=EvoSimLegacyEvent(id,name); if(handled) Evo08SyncDistances(); return handled;
   }
   if(id!=CHARTEVENT_OBJECT_CLICK || StringFind(name,"EVO_CONTEXT_V08_")!=0) return EvoSimLegacyEvent(id,name);
   Evo08Init();
   if(name!="EVO_CONTEXT_V08_CANCEL") evo08CancelArmed=0;
   if(name=="EVO_CONTEXT_V08_VOL_MINUS" || name=="EVO_CONTEXT_V08_VOL_PLUS") EvoSimChangeVolume(name=="EVO_CONTEXT_V08_VOL_PLUS");
   else if(StringFind(name,"EVO_CONTEXT_V08_MODE_")==0)
   { int n=(int)StringToInteger(StringSubstr(name,StringLen("EVO_CONTEXT_V08_MODE_"))); int mode=n<2?0:n-1; Evo08New(mode,n==0); }
   else if(name=="EVO_CONTEXT_V08_NEW") Evo08New(0,evoSimBuy);
   else if(name=="EVO_CONTEXT_V08_CALC") Evo08Build(true);
   else if(name=="EVO_CONTEXT_V08_QUICK_TARGET") evo08QuickTP=!evo08QuickTP;
   else if(StringFind(name,"EVO_CONTEXT_V08_QUICK_")==0)
   {
      int n=(int)StringToInteger(StringSubstr(name,StringLen("EVO_CONTEXT_V08_QUICK_")));
      if(n<0 || n>5) return true;
      ObjectSetString(0,evo08QuickTP?"EVO_CONTEXT_V08_TP":"EVO_CONTEXT_V08_SL",OBJPROP_TEXT,DoubleToString(.5*(n+1),3)); Evo08Build();
   }
   else if(name=="EVO_CONTEXT_V08_CONFIRM")
   {
      if(evo08TargetKind>0) EvoSimStatus("Ticket cargado: usar ACTUALIZAR SL/TP; NUEVA PROPUESTA prepara otra entrada");
      else if(Evo08FieldsChanged() || !evoSimActive) Evo08Build();
      else { EvoSimConfirm(); if(evoSimActive) Evo08SyncDistances(); }
   }
   else if(name=="EVO_CONTEXT_V08_LOAD_POS") Evo08Load(false);
   else if(name=="EVO_CONTEXT_V08_LOAD_PENDING") Evo08Load(true);
   else if(name=="EVO_CONTEXT_V08_APPLY") Evo08Apply();
   else if(name=="EVO_CONTEXT_V08_CLOSE") Evo08Close();
   else if(name=="EVO_CONTEXT_V08_CANCEL") Evo08CancelAll();
   else return false;
   ObjectSetInteger(0,name,OBJPROP_STATE,false); return true;
}
#endif
