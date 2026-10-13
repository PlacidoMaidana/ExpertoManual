#ifndef EVO_JOURNAL_PANEL
#define EVO_JOURNAL_PANEL
string evoLogRows[],evoLogPath="",evoLogNotice="";
int evoLogIndex=0;
string EvoLogSourceName() { return StringFormat("Evolucion_%I64d_%I64d.csv",AccountInfoInteger(ACCOUNT_LOGIN),ChartID()); }
string EvoLogRoot() { return EvoJournalCommon?TerminalInfoString(TERMINAL_COMMONDATA_PATH)+"\\Files\\":TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL5\\Files\\"; }
void EvoLogLoad()
{
   ObjectsDeleteAll(0,"EVO_CONTEXT_LOG_");
   ArrayResize(evoLogRows,0); evoLogIndex=0; evoLogPath=EvoLogRoot()+EvoLogSourceName();
   evoLogNotice="Lectura fija. ACTUALIZAR obtiene los ultimos movimientos.";
   int h=FileOpen(EvoLogSourceName(),FILE_READ|FILE_TXT|FILE_ANSI|FILE_SHARE_READ|FILE_SHARE_WRITE|(EvoJournalCommon?FILE_COMMON:0));
   if(h==INVALID_HANDLE) { evoLogNotice="No se pudo leer el registro. Error "+(string)GetLastError(); return; }
   // Bounded tail: do not block position protection scanning an entire large journal.
   long size=(long)FileSize(h);
   if(size>262144) { FileSeek(h,size-262144,SEEK_SET); FileReadString(h); }
   while(!FileIsEnding(h)) {
      string line=FileReadString(h); if(line=="" || StringFind(line,"hora_servidor;")==0) continue;
      int n=ArraySize(evoLogRows);
      if(n>=60) { for(int i=1;i<n;i++) evoLogRows[i-1]=evoLogRows[i]; n=59; }
      else ArrayResize(evoLogRows,n+1);
      evoLogRows[n]=line;
   }
   FileClose(h); evoLogIndex=MathMax(0,ArraySize(evoLogRows)-1);
   ObjectsDeleteAll(0,"EVO_CONTEXT_LOG_");
}
void EvoLogEdit(const string suffix,const int row,const string value)
{
   string name="EVO_CONTEXT_LOG_"+suffix;
   bool created=ObjectFind(0,name)<0;
   if(created) ObjectCreate(0,name,OBJ_EDIT,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,evoPanelX+12);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,evoPanelY+10+row*EvoPanelPitch());
   ObjectSetInteger(0,name,OBJPROP_XSIZE,EvoPanelWidth()-24);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,EvoPanelPitch());
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,9);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clrWhite); ObjectSetInteger(0,name,OBJPROP_BGCOLOR,C'35,45,55');
   ObjectSetInteger(0,name,OBJPROP_READONLY,false); ObjectSetInteger(0,name,OBJPROP_ZORDER,30);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,"Clic dentro, Ctrl+A y Ctrl+C. Editar aqui NO modifica el archivo.");
   if(created) ObjectSetString(0,name,OBJPROP_TEXT,value);
}
void EvoLogExport()
{
   string name=StringFormat("ResumenMonitor_%I64d_%I64d_%I64d.txt",AccountInfoInteger(ACCOUNT_LOGIN),ChartID(),(long)TimeCurrent());
   int h=FileOpen(name,FILE_WRITE|FILE_TXT|FILE_UNICODE|(EvoJournalCommon?FILE_COMMON:0));
   if(h==INVALID_HANDLE) { evoLogNotice="No se pudo exportar. Error "+(string)GetLastError(); return; }
   FileWrite(h,"REGISTRO RECIENTE SIGNALFUSION | "+_Symbol+" | "+EnumToString(_Period));
   FileWrite(h,"Exportado: "+TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS)+" (hora servidor)");
   FileWrite(h,"Origen: "+EvoLogRoot()+EvoLogSourceName());
   FileWrite(h,"Hasta 60 eventos del grafico, dentro de los ultimos 256 KiB. No es el historial completo.");
   FileWrite(h,"Eventos capturados al pulsar ACTUALIZAR; posiciones consultadas al exportar.");
   FileWrite(h,"CONFIGURACION ACTUAL AL EXPORTAR (puede diferir de la de entrada)");
   FileWrite(h,StringFormat("SL_ATR=%.2f; TP_modo=%d; RR=%.2f; TP_ATR=%.2f",EvoSLATR,(int)EvoTPMode,EvoRR,EvoTPATR));
   FileWrite(h,StringFormat("Incremental=%d; etapas trigger/stop R: %.2f/%.2f, %.2f/%.2f, %.2f/%.2f",(int)EvoIncremental,EvoStage1TriggerR,EvoStage1StopR,EvoStage2TriggerR,EvoStage2StopR,EvoStage3TriggerR,EvoStage3StopR));
   FileWrite(h,StringFormat("BE=%d; BE_trigger_ATR=%.2f; trailing=%d; distancia_ATR=%.2f; trigger_ATR=%.2f; tras_BE=%d; paso_puntos=%d; SmartExit=%d",(int)EvoBreakEven,EvoBETriggerATR,(int)EvoTrailing,EvoEffectiveTrailingATR(),EvoTrailingTriggerATR,(int)EvoTrailingAfterBE,EvoTrailingStepPoints,(int)EvoSmartExit));
   FileWrite(h,"POSICIONES ACTUALES DEL SIMBOLO");
   for(int i=PositionsTotal()-1;i>=0;i--) {
      ulong t=PositionGetTicket(i); if(t==0 || PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      FileWrite(h,StringFormat("ticket=%I64u; %s; lotes=%.4f; entrada=%.8f; SL=%.8f; TP=%.8f; actual=%.8f; flotante=%.2f; swap=%.2f; moneda=%s",t,EnumToString((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)),PositionGetDouble(POSITION_VOLUME),PositionGetDouble(POSITION_PRICE_OPEN),PositionGetDouble(POSITION_SL),PositionGetDouble(POSITION_TP),PositionGetDouble(POSITION_PRICE_CURRENT),PositionGetDouble(POSITION_PROFIT),PositionGetDouble(POSITION_SWAP),AccountInfoString(ACCOUNT_CURRENCY)));
   }
   FileWrite(h,"EVENTOS (del mas antiguo al mas reciente)");
   for(int i=0;i<ArraySize(evoLogRows);i++) FileWrite(h,evoLogRows[i]);
   FileClose(h); evoLogPath=EvoLogRoot()+name;
   evoLogNotice="TXT exportado. Copia la ruta inferior para abrirlo o compartirlo.";
   ObjectDelete(0,"EVO_CONTEXT_LOG_PATH"); Print("Resumen para compartir: ",evoLogPath);
}
void EvoLogDraw()
{
   if(evoLogPath=="") EvoLogLoad();
   EvoPanelBackground(17); EvoDrawTabs();
   EvoPanelLine(1,"REGISTRO DE OPERACIONES | "+_Symbol,clrWhite);
   EvoSimButton("EVO_CONTEXT_LOG_REFRESH","ACTUALIZAR",0);
   EvoSimButton("EVO_CONTEXT_LOG_PREV","< ANTERIOR",1);
   EvoSimButton("EVO_CONTEXT_LOG_NEXT","SIGUIENTE >",2);
   EvoSimButton("EVO_CONTEXT_LOG_EXPORT","EXPORTAR TXT",3);
   int n=ArraySize(evoLogRows); evoLogIndex=MathMax(0,MathMin(evoLogIndex,n-1));
   EvoPanelLine(3,StringFormat("Evento %d de %d | horas del servidor",n>0?evoLogIndex+1:0,n),clrAqua);
   string selected=n>0?evoLogRows[evoLogIndex]:"Sin eventos disponibles";
   int width=MathMax(20,(EvoPanelWidth()-32)/MathMax(5,(int)MathCeil(EvoPanelFont*0.85)));
   for(int i=0;i<6;i++) EvoPanelLine(4+i,StringSubstr(selected,MathMin(StringLen(selected),i*width),width));
   EvoPanelLine(10,"Evento completo: clic dentro, Ctrl+A y Ctrl+C",clrGold);
   EvoLogEdit("EVENT",11,selected);
   EvoPanelLine(12,"Ruta del archivo: clic dentro, Ctrl+A y Ctrl+C",clrGold);
   EvoLogEdit("PATH",13,evoLogPath);
   EvoPanelLine(14,evoLogNotice,clrAqua);
   EvoPanelLine(15,"Para compartir varios eventos: EXPORTAR TXT y adjuntar el archivo.");
   EvoPanelLine(16,"Registro "+(EvoWriteJournal?"ACTIVO":"DESACTIVADO")+" | gestion "+(EvoManagePositions?"ACTIVA":"OFF")+" | editar estos campos no altera operaciones.");
}
bool EvoLogEvent(const int id,const string name)
{
   if(id!=CHARTEVENT_OBJECT_CLICK || !EvoShowContext) return false;
   if(name=="EVO_CONTEXT_TAB_REGISTRO") { evoPanelTab=4; evoSimulationView=false; evoPanelMinimized=false; evoDemandView=false; GlobalVariableSet(EvoPanelKey()+"TAB",4); ObjectsDeleteAll(0,"EVO_CONTEXT_"); EvoLogLoad(); return true; }
   if(evoPanelTab!=4) return false;
   if(name=="EVO_CONTEXT_LOG_REFRESH") EvoLogLoad();
   else if(name=="EVO_CONTEXT_LOG_PREV") { evoLogIndex--; ObjectDelete(0,"EVO_CONTEXT_LOG_EVENT"); }
   else if(name=="EVO_CONTEXT_LOG_NEXT") { evoLogIndex++; ObjectDelete(0,"EVO_CONTEXT_LOG_EVENT"); }
   else if(name=="EVO_CONTEXT_LOG_EXPORT") EvoLogExport();
   else return false;
   ObjectSetInteger(0,name,OBJPROP_STATE,false); return true;
}
#endif
