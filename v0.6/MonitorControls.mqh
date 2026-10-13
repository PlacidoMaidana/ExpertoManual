#ifndef EVOLUTION_MONITOR_CONTROLS
#define EVOLUTION_MONITOR_CONTROLS
input group "Botones manuales del monitor"
input bool InpShowBreakEvenJumpButton = true;
input bool InpUseLossExitButton = true;
input double InpLossExitTrailingATRMultiplier = 1.0;
input int InpLossExitStepPoints = 10;
input double EvoLossRecoveryATR = 0.25; // Rebote desde armado para usar distancia mas corta
input double EvoLossRecoveredTrailATR = 0.5;
input bool EvoLossContinueAfterRecovery = true;
double evoLossATR=0,evoLossArmPrice=0,evoLossBest=0,evoLossOriginalSL=0,evoLossEntry=0,evoLossVolume=0;
ulong evoLossId=0;
long evoLossType=-1;
string evoBEStatus="BE manual: listo",evoLossStatus="Salida en perdida: sin preparar";

bool EvoMonitorSelected()
{
   if(PositionGetString(POSITION_SYMBOL)!=_Symbol) return false;
   long magic=PositionGetInteger(POSITION_MAGIC);
   return InpManageManualOnly?magic==0:magic==InpMagicToManage;
}
#include "ManualBreakEven.mqh"

// Retire pending requests from the former one-shot BE button.
void EvoClearLegacyBE()
{
   for(int i=GlobalVariablesTotal()-1;i>=0;i--)
   {
      string key=GlobalVariableName(i);
      if(StringFind(key,EvoBEKey())==0) GlobalVariableDel(key);
   }
   GlobalVariablesFlush();
}
bool evoLevelsExpanded=false;
string evoLevelsStatus="SOLO BE desactiva escalones; TS, Smart y SP conservan sus interruptores.";
string EvoRiskProtectionStatus()
{
   return evoRiskProtectionPaused?"BE + niveles 1/2/3: PAUSADOS | SL existente conservado":
      "Proteccion ACTIVA | BE "+(evoPanelBEEnabled?"ON":"OFF")+" | N1 "+(evoStageEnabled[0]?"ON":"OFF")+" N2 "+(evoStageEnabled[1]?"ON":"OFF")+" N3 "+(evoStageEnabled[2]?"ON":"OFF");
}
void EvoToggleRiskProtection()
{
   evoRiskProtectionPaused=!evoRiskProtectionPaused;
   GlobalVariableSet("EVX."+manager.Scope()+"."+(string)ChartID()+".riskPaused",evoRiskProtectionPaused?1.0:0.0);
   EvoClearLegacyBE();
   if(!evoRiskProtectionPaused)
   {
      for(int i=PositionsTotal()-1;i>=0;i--)
      {
         ulong ticket=PositionGetTicket(i);
         if(ticket>0 && EvoMonitorSelected()) manager.TakeManualControl(ticket);
      }
   }
   EvoJournal("BE_NIVELES_PAUSA_MANUAL",0,EvoRiskProtectionStatus());
}

string EvoLossKey() { return "EVX."+manager.Scope()+"."+(string)ChartID()+"."; }
void EvoToggleSmartExit()
{
   evoSmartExitPaused=!evoSmartExitPaused;
   GlobalVariableSet(EvoLossKey()+"smartPaused",evoSmartExitPaused?1.0:0.0);
   GlobalVariablesFlush();
   EvoJournal("SMART_EXIT_PAUSA_MANUAL",0,evoSmartExitPaused?"Smart Exit pausado: sin proteccion ni cierre; SL existente conservado":"Smart Exit reanudado segun parametros");
}
void EvoSaveLoss()
{
   GlobalVariableSet(EvoLossKey()+"hi",(double)(evoLossId>>32));
   GlobalVariableSet(EvoLossKey()+"lo",(double)(evoLossId&0xFFFFFFFF));
   GlobalVariableSet(EvoLossKey()+"type",(double)evoLossType);
   GlobalVariableSet(EvoLossKey()+"atr",evoLossATR);
   GlobalVariableSet(EvoLossKey()+"arm",evoLossArmPrice);
   GlobalVariableSet(EvoLossKey()+"best",evoLossBest);
   GlobalVariableSet(EvoLossKey()+"sl",evoLossOriginalSL);
   GlobalVariableSet(EvoLossKey()+"entry",evoLossEntry);
   GlobalVariableSet(EvoLossKey()+"volume",evoLossVolume);
   GlobalVariablesFlush();
}
void EvoLoadLoss()
{
   EvoLoadLevels();
   evoSmartExitPaused=GlobalVariableCheck(EvoLossKey()+"smartPaused") && GlobalVariableGet(EvoLossKey()+"smartPaused")>0;
   evoRiskProtectionPaused=GlobalVariableCheck(EvoLossKey()+"riskPaused") && GlobalVariableGet(EvoLossKey()+"riskPaused")>0;
   EvoClearLegacyBE();
   evoTrailingPaused=GlobalVariableCheck(EvoLossKey()+"tsPaused") && GlobalVariableGet(EvoLossKey()+"tsPaused")>0;
   if(!GlobalVariableCheck(EvoLossKey()+"type")) return;
   evoLossId=((ulong)GlobalVariableGet(EvoLossKey()+"hi")<<32)|(ulong)GlobalVariableGet(EvoLossKey()+"lo");
   evoLossType=(long)GlobalVariableGet(EvoLossKey()+"type");
   evoLossATR=GlobalVariableGet(EvoLossKey()+"atr"); evoLossArmPrice=GlobalVariableGet(EvoLossKey()+"arm");
   evoLossBest=GlobalVariableGet(EvoLossKey()+"best"); evoLossOriginalSL=GlobalVariableGet(EvoLossKey()+"sl");
   evoLossEntry=GlobalVariableGet(EvoLossKey()+"entry"); evoLossVolume=GlobalVariableGet(EvoLossKey()+"volume");
   if(evoLossId!=0 && (evoLossATR<=0 || evoLossOriginalSL<=0 || evoLossEntry<=0))
      { evoLossId=0; evoLossType=-1; evoLossStatus="Rearmar salida: referencia anterior incompatible"; }
}
void EvoDisarmLoss(const string reason)
{
   EvoJournal("SALIDA_PERDIDA_DESARMADA",evoLossId,reason);
   evoLossId=0; evoLossType=-1; evoLossStatus=reason; EvoSaveLoss();
}
ulong EvoFindLossTicket()
{
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket>0 && EvoMonitorSelected() && (ulong)PositionGetInteger(POSITION_IDENTIFIER)==evoLossId &&
         PositionGetInteger(POSITION_TYPE)==evoLossType) return ticket;
   }
   return 0;
}
void EvoValidateLoss()
{
   if(evoLossId!=0 && EvoFindLossTicket()==0) EvoDisarmLoss("Salida desarmada: posicion cerrada o fuera de seleccion");
}
void EvoButton(const string name,const int row,const string text,const color bg)
{
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,evoPanelX+12);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,evoPanelY+10+row*EvoPanelPitch());
   ObjectSetInteger(0,name,OBJPROP_XSIZE,EvoPanelWidth()-24);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,EvoPanelPitch()+2);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,EvoPanelFont);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,20);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
}
void EvoTakeSelectedControl()
{
   if(!EvoManagePositions) return;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket>0 && EvoMonitorSelected()) manager.TakeManualControl(ticket);
   }
}
string EvoSelectedControlStatus()
{
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket>0 && EvoMonitorSelected() && !manager.HasControl(ticket))
         return "CONTROL: OTRO GRAFICO | activa BE o reanuda/ajusta TS aqui";
   }
   return "";
}
bool EvoAdjustTrailing(const string name)
{
   if(name=="EVO_CONTEXT_TRAIL_PAUSE")
   {
      evoTrailingPaused=!evoTrailingPaused;
      if(!evoTrailingPaused) EvoTakeSelectedControl();
      GlobalVariableSet(EvoLossKey()+"tsPaused",evoTrailingPaused?1.0:0.0);
      ObjectSetInteger(0,name,OBJPROP_STATE,false);
      EvoJournal("TRAILING_PAUSA_MANUAL",0,evoTrailingPaused?"TS normal y salida en perdida pausados; BE/niveles segun su boton":"Seguimiento TS reanudado");
      return true;
   }
   if(name!="EVO_CONTEXT_TRAIL_MINUS" && name!="EVO_CONTEXT_TRAIL_PLUS" && name!="EVO_CONTEXT_TRAIL_RESET") return false;
   EvoTakeSelectedControl();
   double old=EvoEffectiveTrailingATR();
   if(name=="EVO_CONTEXT_TRAIL_RESET") evoTrailingOverride=0;
   else evoTrailingOverride=NormalizeDouble(MathMax(0.1,old+(name=="EVO_CONTEXT_TRAIL_PLUS"?0.1:-0.1)),8);
   ObjectSetInteger(0,name,OBJPROP_STATE,false);
   EvoJournal("TRAILING_MANUAL_ATR",0,StringFormat("anterior=%.4f; nuevo=%.4f; SL existente no retrocede",old,EvoEffectiveTrailingATR()));
   return true;
}
void EvoDrawTrailing(const int row)
{
   string state=!EvoManagePositions?"GESTION OFF":evoTrailingPaused?"PAUSADO":!EvoTrailing?"TRAILING OFF":EvoTrailingAfterBE?"tras BE":"habilitado";
   EvoPanelLine(row,StringFormat("TRAILING %.2f ATR | %s | ajuste de esta sesion",EvoEffectiveTrailingATR(),state),clrAqua);
   MqlTick trailQuote; double trailATR=0;
   if(SymbolInfoTick(_Symbol,trailQuote) && analysis.ATR(trailATR) && trailATR>0)
   {
      double minimum=MathMax(SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL),SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL))*_Point+SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
      string detail=StringFormat("Distancia pedida %.5f (%.2f ATR). Minimo broker stops/freeze %.5f. Distancia efectiva al menos %.5f. Tras BE exige SL economico ya confirmado; actualiza con ticks/timer, no al cierre de vela.",trailATR*EvoEffectiveTrailingATR(),EvoEffectiveTrailingATR(),minimum,MathMax(trailATR*EvoEffectiveTrailingATR(),minimum));
      ObjectSetString(0,"EVO_CONTEXT_"+(string)row,OBJPROP_TOOLTIP,detail);
      if(minimum>trailATR*EvoEffectiveTrailingATR()) EvoPanelLine(row,StringFormat("TRAILING %.2f ATR | minimo broker %.3f precio | %s",EvoEffectiveTrailingATR(),minimum,state),clrGold);
   }
   string names[]={"EVO_CONTEXT_TRAIL_MINUS","EVO_CONTEXT_TRAIL_PLUS","EVO_CONTEXT_TRAIL_RESET"};
   string captions[]={"-0.10 ATR cerca","+0.10 ATR lejos","Restablecer"};
   int width=(EvoPanelWidth()-28)/3;
   for(int i=0;i<3;i++)
   {
      EvoButton(names[i],row+1,captions[i],C'35,60,80');
      ObjectSetInteger(0,names[i],OBJPROP_XDISTANCE,evoPanelX+12+i*(width+2));
      ObjectSetInteger(0,names[i],OBJPROP_XSIZE,width);
      ObjectSetInteger(0,names[i],OBJPROP_YSIZE,EvoPanelPitch());
      ObjectSetInteger(0,names[i],OBJPROP_FONTSIZE,MathMin(9,EvoPanelFont));
   }
   EvoPanelLine(row+2,evoTrailingPaused?"TS pausado; BE/niveles segun boton; otras protecciones activas.":"SL no retrocede; otras protecciones pueden acercarlo.",clrSilver);
}
void EvoDrawControls()
{
   if(!EvoShowContext) return;
   int row=evoMonitorControlRow;
   EvoDrawTrailing(row); row+=3;
   int count=2+(InpShowBreakEvenJumpButton?1:0)+(InpUseLossExitButton?1:0);
   int width=(EvoPanelWidth()-24-4*(count-1))/count,index=0;
   string names[]={"EVO_CONTEXT_TRAIL_PAUSE","EVO_CONTEXT_BE","EVO_CONTEXT_LOSS","EVO_CONTEXT_SMART"};
   for(int i=0;i<4;i++)
   {
      if(i==1 && !InpShowBreakEvenJumpButton) continue;
      if(i==2 && !InpUseLossExitButton) continue;
      string caption=i==0?(evoTrailingPaused?"Reanudar TS":"Detener TS"):
         i==1?(evoRiskProtectionPaused?"Protec OFF":"Protec ON"):i==2?(evoLossId==0?"Preparar SP":"Cancelar SP"):(!EvoSmartExit || evoSmartExitPaused?"Smart OFF":"Smart ON");
      string tip=i==0?(evoTrailingPaused?"Reanudar trailing normal y salida en perdida.":"Pausar trailing normal y salida en perdida hasta otro clic. BE/niveles segun boton; otras protecciones independientes."):
         i==1?(evoRiskProtectionPaused?"Activar las protecciones seleccionadas en NIVELES; no salta inmediatamente a BE.":"Pausar BE y los niveles seleccionados. Conserva el SL existente. Trailing, Smart Exit y salida en perdida tienen controles independientes."):
         i==2?(evoLossId==0?"Preparar salida en perdida: acerca el SL de la posicion mas adversa cuando es posible, sin ampliarlo. Detener TS tambien pausa SP. No cierra a mercado.":"Cancelar salida en perdida; conservar el SL existente."):
         (evoSmartExitPaused?"Reanudar Smart Exit segun parametros: proteger objetivo neto y cerrar solo tras confirmacion.":"Pausar proteccion y cierre Smart Exit. SL existente conservado; BE y trailing independientes.");
      EvoButton(names[i],row,caption,i==0?(evoTrailingPaused?clrMaroon:C'35,60,80'):i==1?(evoRiskProtectionPaused?clrMaroon:C'35,60,80'):i==2?(evoLossId==0?C'85,50,25':clrMaroon):(!EvoSmartExit || evoSmartExitPaused?clrMaroon:C'35,60,80'));
      ObjectSetInteger(0,names[i],OBJPROP_XDISTANCE,evoPanelX+12+index*(width+4));
      ObjectSetInteger(0,names[i],OBJPROP_XSIZE,index==count-1?EvoPanelWidth()-24-index*(width+4):width);
      ObjectSetInteger(0,names[i],OBJPROP_YSIZE,EvoPanelPitch());
      ObjectSetInteger(0,names[i],OBJPROP_FONTSIZE,MathMin(9,EvoPanelFont));
      ObjectSetString(0,names[i],OBJPROP_TOOLTIP,tip);
      index++;
   }
   row++;
   string controlStatus=EvoSelectedControlStatus();
   if(InpShowBreakEvenJumpButton) EvoPanelLine(row++,controlStatus!=""?controlStatus:EvoRiskProtectionStatus(),controlStatus!=""?clrGold:clrSilver);
   if(InpUseLossExitButton) EvoPanelLine(row++,evoLossId==0?evoLossStatus:"#"+(string)evoLossId+" | "+evoLossStatus);
   EvoDrawLevels(row);
}
void EvoSaveLevels()
{
   GlobalVariableSet(EvoLossKey()+"levels.BE",evoPanelBEEnabled?1:0);
   GlobalVariableSet(EvoLossKey()+"levels.beTrigger",evoBETriggerOverride);
   GlobalVariableSet(EvoLossKey()+"levels.beMoney",EvoEffectiveBEMoney());
   for(int i=0;i<3;i++)
   {
      string key=EvoLossKey()+"levels."+(string)i;
      GlobalVariableSet(key+".on",evoStageEnabled[i]?1:0);
      GlobalVariableSet(key+".trigger",evoStageTrigger[i]); GlobalVariableSet(key+".stop",evoStageStop[i]);
   }
   GlobalVariablesFlush();
}
void EvoLoadLevels()
{
   EvoInitLevels();
   if(GlobalVariableCheck(EvoLossKey()+"levels.beTrigger")) { double value=GlobalVariableGet(EvoLossKey()+"levels.beTrigger"); if(MathIsValidNumber(value) && value>=0) evoBETriggerOverride=value; }
   if(GlobalVariableCheck(EvoLossKey()+"levels.beMoney")) { double value=GlobalVariableGet(EvoLossKey()+"levels.beMoney"); if(MathIsValidNumber(value) && value>=0) evoBEMinOverride=value; }
   double triggers[3],stops[3];
   for(int i=0;i<3;i++)
   {
      string key=EvoLossKey()+"levels."+(string)i;
      triggers[i]=GlobalVariableCheck(key+".trigger")?GlobalVariableGet(key+".trigger"):evoStageTrigger[i];
      stops[i]=GlobalVariableCheck(key+".stop")?GlobalVariableGet(key+".stop"):evoStageStop[i];
      if(GlobalVariableCheck(key+".on")) evoStageEnabled[i]=GlobalVariableGet(key+".on")>0;
   }
   if(EvoLevelsValid(triggers,stops)) for(int i=0;i<3;i++) { evoStageTrigger[i]=triggers[i]; evoStageStop[i]=stops[i]; }
   if(GlobalVariableCheck(EvoLossKey()+"levels.BE")) evoPanelBEEnabled=GlobalVariableGet(EvoLossKey()+"levels.BE")>0;
}
void EvoLevelButton(const string name,const string text,const int row,const int slot,const int columns)
{
   int width=(EvoPanelWidth()-24)/columns;
   EvoButton(name,row,text,C'35,60,80');
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,evoPanelX+12+slot*width);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,width-3); ObjectSetInteger(0,name,OBJPROP_YSIZE,EvoPanelPitch()-2);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,"Ajuste por grafico, guardado. R es la distancia de riesgo inicial observado. Desactivar o reducir proteccion no retrocede el SL existente.");
}
void EvoDrawLevels(const int row)
{
   EvoInitLevels();
   EvoLevelButton("EVO_CONTEXT_LEVELS_OPEN",evoLevelsExpanded?"CERRAR NIVELES":"NIVELES",row,0,4);
   EvoLevelButton("EVO_CONTEXT_LEVELS_BE",evoPanelBEEnabled?"BE ON":"BE OFF",row,1,4);
   EvoLevelButton("EVO_CONTEXT_LEVELS_ONLYBE","SOLO BE",row,2,4);
   EvoLevelButton("EVO_CONTEXT_LEVELS_RESET","RESTABLECER",row,3,4);
   if(!evoLevelsExpanded) { ObjectsDeleteAll(0,"EVO_CONTEXT_LEVEL_STAGE_"); ObjectDelete(0,"EVO_CONTEXT_LEVELS_BETM"); ObjectDelete(0,"EVO_CONTEXT_LEVELS_BETP"); ObjectDelete(0,"EVO_CONTEXT_LEVELS_BEMM"); ObjectDelete(0,"EVO_CONTEXT_LEVELS_BEMP"); return; }
   EvoPanelLine(row+1,StringFormat("BE activa %.2f ATR | protege neto estimado %.2f %s",evoBETriggerOverride,EvoEffectiveBEMoney(),AccountInfoString(ACCOUNT_CURRENCY)),clrAqua);
   EvoLevelButton("EVO_CONTEXT_LEVELS_BETM","BE activa -0.10 ATR",row+2,0,4);
   EvoLevelButton("EVO_CONTEXT_LEVELS_BETP","BE activa +0.10 ATR",row+2,1,4);
   EvoLevelButton("EVO_CONTEXT_LEVELS_BEMM","BE neto -0.50",row+2,2,4);
   EvoLevelButton("EVO_CONTEXT_LEVELS_BEMP","BE neto +0.50",row+2,3,4);
   EvoPanelLine(row+3,"BE requiere espacio broker. Niveles: ACTIVA / PROTEGE en R.",clrSilver);
   for(int i=0;i<3;i++)
   {
      int at=row+4+i*2; string key="EVO_CONTEXT_LEVEL_STAGE_"+(string)i+"_";
      EvoPanelLine(at,StringFormat("N%d %s | activa %.2f R | protege %+.2f R",i+1,evoStageEnabled[i]?"ON":"OFF",evoStageTrigger[i],evoStageStop[i]),evoStageEnabled[i]?clrWhite:clrSilver);
      EvoLevelButton(key+"ON",evoStageEnabled[i]?"DESACTIVAR":"ACTIVAR",at+1,0,5);
      EvoLevelButton(key+"TM","Activa -0.05R",at+1,1,5); EvoLevelButton(key+"TP","Activa +0.05R",at+1,2,5);
      EvoLevelButton(key+"SM","Protege -0.05R",at+1,3,5); EvoLevelButton(key+"SP","Protege +0.05R",at+1,4,5);
   }
   EvoPanelLine(row+10,evoLevelsStatus,clrGold);
}
bool EvoLevelsEvent(const string name)
{
   if(StringFind(name,"EVO_CONTEXT_LEVEL")!=0) return false;
   EvoInitLevels();
   if(name=="EVO_CONTEXT_LEVELS_OPEN") evoLevelsExpanded=!evoLevelsExpanded;
   else if(name=="EVO_CONTEXT_LEVELS_BETM") evoBETriggerOverride=NormalizeDouble(MathMax(0,evoBETriggerOverride-.10),2);
   else if(name=="EVO_CONTEXT_LEVELS_BETP") evoBETriggerOverride=NormalizeDouble(evoBETriggerOverride+.10,2);
   else if(name=="EVO_CONTEXT_LEVELS_BEMM") evoBEMinOverride=NormalizeDouble(MathMax(0,EvoEffectiveBEMoney()-.50),2);
   else if(name=="EVO_CONTEXT_LEVELS_BEMP") evoBEMinOverride=NormalizeDouble(EvoEffectiveBEMoney()+.50,2);
   else if(name=="EVO_CONTEXT_LEVELS_BE") evoPanelBEEnabled=!evoPanelBEEnabled;
   else if(name=="EVO_CONTEXT_LEVELS_ONLYBE") { for(int i=0;i<3;i++) evoStageEnabled[i]=false; evoPanelBEEnabled=true; evoRiskProtectionPaused=false; GlobalVariableSet(EvoLossKey()+"riskPaused",0); }
   else if(name=="EVO_CONTEXT_LEVELS_RESET") { evoLevelsInitialized=false; EvoInitLevels(); }
   else
   {
      bool handled=false;
      for(int i=0;i<3;i++)
      {
         string key="EVO_CONTEXT_LEVEL_STAGE_"+(string)i+"_";
         if(StringFind(name,key)!=0) continue;
         string action=StringSubstr(name,StringLen(key)); handled=true;
         if(action=="ON") evoStageEnabled[i]=!evoStageEnabled[i];
         else
         {
            double triggers[3],stops[3]; for(int j=0;j<3;j++) { triggers[j]=evoStageTrigger[j]; stops[j]=evoStageStop[j]; }
            if(action=="TM") triggers[i]-=.05; else if(action=="TP") triggers[i]+=.05;
            else if(action=="SM") stops[i]-=.05; else if(action=="SP") stops[i]+=.05; else return false;
            for(int j=0;j<3;j++) { triggers[j]=NormalizeDouble(triggers[j],2); stops[j]=NormalizeDouble(stops[j],2); }
            if(!EvoLevelsValid(triggers,stops)) { evoLevelsStatus="Ajuste rechazado: mantener orden entre niveles y proteger menos que activar."; EvoJournal("NIVELES_AJUSTE_RECHAZADO",0,"Conserva orden de activacion/proteccion; proteccion debe estar bajo activacion"); ObjectSetInteger(0,name,OBJPROP_STATE,false); return true; }
            for(int j=0;j<3;j++) { evoStageTrigger[j]=triggers[j]; evoStageStop[j]=stops[j]; }
         }
      }
      if(!handled) return false;
   }
   evoLevelsStatus="Ajustes guardados. El SL existente no retrocede.";
   EvoJournal("BE_AJUSTE_PANTALLA",0,StringFormat("activa_atr=%.2f; objetivo_neto_estimado=%.2f %s; SL existente no retrocede",evoBETriggerOverride,EvoEffectiveBEMoney(),AccountInfoString(ACCOUNT_CURRENCY)));
   EvoSaveLevels(); if(name!="EVO_CONTEXT_LEVELS_OPEN" && !evoRiskProtectionPaused) EvoTakeSelectedControl();
   EvoJournal("NIVELES_MANUAL",0,StringFormat("BE=%d; N1=%d %.2f/%.2f; N2=%d %.2f/%.2f; N3=%d %.2f/%.2f; SL existente conservado",(int)evoPanelBEEnabled,(int)evoStageEnabled[0],evoStageTrigger[0],evoStageStop[0],(int)evoStageEnabled[1],evoStageTrigger[1],evoStageStop[1],(int)evoStageEnabled[2],evoStageTrigger[2],evoStageStop[2]));
   ObjectSetInteger(0,name,OBJPROP_STATE,false); return true;
}
void EvoToggleLoss()
{
   if(evoLossId!=0) { EvoDisarmLoss("Salida cancelada por el operador; el SL existente se conserva"); return; }
   if(!EvoManagePositions) { evoLossStatus="Gestion desactivada"; return; }
   double referenceATR=0;
   if(!analysis.ATR(referenceATR) || referenceATR<=0) { evoLossStatus="No se arma: ATR no disponible"; return; }
   double worst=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !EvoMonitorSelected()) continue;
      MqlTick q; if(!SymbolInfoTick(_Symbol,q) || q.bid<=0 || q.ask<=0) continue;
      long type=PositionGetInteger(POSITION_TYPE);
      double entry=PositionGetDouble(POSITION_PRICE_OPEN);
      double distance=type==POSITION_TYPE_BUY?q.bid-entry:entry-q.ask;
      // Preserve original selection: worst adverse PRICE distance, not money.
      if(distance<worst && PositionGetDouble(POSITION_SL)>0) {
         worst=distance; evoLossId=(ulong)PositionGetInteger(POSITION_IDENTIFIER); evoLossType=type;
         evoLossATR=referenceATR; evoLossOriginalSL=PositionGetDouble(POSITION_SL);
         evoLossArmPrice=type==POSITION_TYPE_BUY?q.bid:q.ask; evoLossBest=evoLossArmPrice;
         evoLossEntry=entry; evoLossVolume=PositionGetDouble(POSITION_VOLUME);
      }
   }
   evoLossStatus=evoLossId==0?"No hay posicion en perdida con SL existente":evoTrailingPaused?"SP PAUSADA por Detener TS: pulsa Reanudar TS":"Preparada; esperando mejora del SL";
   EvoSaveLoss();
   if(evoLossId!=0)
   {
      ulong ticket=EvoFindLossTicket();
      if(ticket>0 && !manager.TakeManualControl(ticket)) evoLossStatus="SP bloqueada: "+manager.LastStopError();
      EvoJournal("SALIDA_PERDIDA_ARMADA",evoLossId,"Seguimiento ATR habilitado por el operador; control solicitado en este grafico");
   }
}
void EvoRunLoss(const double atr)
{
   if(evoLossId==0 || !InpUseLossExitButton) return;
   if(!EvoManagePositions) { evoLossStatus="SP PAUSADA: gestion desactivada"; return; }
   if(evoTrailingPaused) { evoLossStatus="SP PAUSADA por Detener TS: pulsa Reanudar TS"; return; }
   ulong ticket=EvoFindLossTicket(); if(ticket==0) return;
   MqlTick q; if(!SymbolInfoTick(_Symbol,q) || q.bid<=0 || q.ask<=0) return;
   bool buy=evoLossType==POSITION_TYPE_BUY;
   double entry=PositionGetDouble(POSITION_PRICE_OPEN),price=buy?q.bid:q.ask;
   double volume=PositionGetDouble(POSITION_VOLUME);
   if(MathAbs(entry-evoLossEntry)>_Point*0.5 || volume>evoLossVolume+1e-8)
   { EvoDisarmLoss("Salida desarmada: entrada o volumen cambiado; revisar y rearmar"); return; }
   if(volume<evoLossVolume) { evoLossVolume=volume; EvoSaveLoss(); }
   if(!EvoLossContinueAfterRecovery && (buy?price-entry:entry-price)>0)
   { EvoDisarmLoss("Precio recuperado: continua gestion normal"); return; }
   double sl=PositionGetDouble(POSITION_SL),step=InpLossExitStepPoints*_Point;
   if(sl<=0) { EvoDisarmLoss("Salida desarmada: falta SL de proteccion"); return; }
   double best=buy?MathMax(evoLossBest,price):MathMin(evoLossBest,price);
   if(best!=evoLossBest) { evoLossBest=best; EvoSaveLoss(); }
   double candidate=EvoDefensiveStop(buy,evoLossBest,evoLossArmPrice,evoLossATR,InpLossExitTrailingATRMultiplier,
      EvoLossRecoveryATR,EvoLossRecoveredTrailATR,evoLossOriginalSL,sl);
   if(!EvoBetter(buy,sl,candidate) || (buy?candidate-sl:sl-candidate)<=step)
   { evoLossStatus=StringFormat("SP espera mejora | SL %.5f | candidato %.5f",sl,candidate); return; }
   bool applied=manager.ManualStop(ticket,candidate,"salida defensiva: mejor precio y ATR de armado");
   evoLossStatus=applied?"SL defensivo confirmado":"SP bloqueada: "+manager.LastStopError();

}
#endif

