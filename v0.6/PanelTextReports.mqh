#ifndef EVO_PANEL_TEXT_REPORTS
#define EVO_PANEL_TEXT_REPORTS
EvoSnapshot evoTextSnapshot;
EvoThesisItem evoTextThesis;
bool evoTextValid=false,evoTextHasThesis=false,evoTextFrozen=false,evoTextPending=false,evoTextThesisFresh=false;
datetime evoTextDisplayed=0;
int evoTextTab=-1;
string evoTextReport="",evoTextError="";
bool evoTextViewer=false,evoTextCopied=false;
int evoTextPage=0;
#ifdef EVO_WINDOWS_CLIPBOARD
#include "WindowsClipboard.mqh"
#endif
void EvoTextRemember(const EvoSnapshot &s,const bool valid)
{
   evoTextSnapshot=s; evoTextValid=valid; evoTextDisplayed=TimeCurrent();
   evoTextTab=evoPanelTab; evoTextFrozen=evoPanelFrozen; evoTextPending=evoPanelDataPending;
   evoTextHasThesis=false;
}
void EvoTextRememberThesis(const EvoThesisItem &t) { evoTextThesis=t; evoTextHasThesis=true; evoTextThesisFresh=t.compatible && t.evaluated>0 && t.evaluated==iTime(_Symbol,PERIOD_CURRENT,1); }
string EvoTextSafeName(const string raw)
{
   string result="";
   for(int i=0;i<StringLen(raw);i++)
   {
      ushort c=StringGetCharacter(raw,i);
      result+=(c>='0' && c<='9') || (c>='A' && c<='Z') || (c>='a' && c<='z') || c=='-' || c=='_'?StringSubstr(raw,i,1):"_";
   }
   return result;
}
string EvoTextFrame(const string name,const EvoFrameContext &f)
{ return name+": "+(!f.valid?"N/D":f.regime+" | "+EvoContextBias(f.direction)+StringFormat(" | ADX %.4f",f.adx)); }
void EvoTextButton(const int row,const int right=132)
{
#ifdef EVO_PANEL_MEMORY_REPORT_VERSION
   string name="EVO_CONTEXT_EXPORT_MD";
   EvoThesisButton(name,evoTextError!=""?"REINTENTAR MD":evoTextCopied?"COPIADO MD":"COPIAR MD",row);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,evoPanelX+EvoPanelWidth()-right);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,122); ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,evoTextError!=""?clrMaroon:evoTextCopied?C'25,90,55':C'25,75,130');
#ifdef EVO_WINDOWS_CLIPBOARD
   string tip="Copia Markdown de la lectura mostrada al portapapeles. Sin archivos ni envio a servicios externos.";
#else
   string tip="Muestra Markdown en memoria para seleccionar y copiar. Copia directa con un clic disponible en la variante Portapapeles (requiere DLL).";
#endif
   ObjectSetString(0,name,OBJPROP_TOOLTIP,tip+(evoTextError!=""?"\n"+evoTextError:""));
#endif
}
string EvoTextVisible()
{
   string text="\r\n## Lectura visible y notas del panel\r\n";
   for(int row=1;row<64;row++)
   {
      string name="EVO_CONTEXT_"+(string)row;
      if(ObjectFind(0,name)<0) continue;
      string shown=ObjectGetString(0,name,OBJPROP_TEXT),tip=ObjectGetString(0,name,OBJPROP_TOOLTIP);
      if(shown!="") text+=shown+"\r\n";
      if(tip!="" && tip!="\n" && tip!=shown) text+="  Detalle: "+tip+"\r\n";
   }
   string seen="\n";
   for(int i=0;i<ObjectsTotal(0);i++)
   {
      string name=ObjectName(0,i);
      if(StringFind(name,"EVO_CONTEXT_MATRIX_")!=0 || ObjectGetInteger(0,name,OBJPROP_TYPE)!=OBJ_RECTANGLE_LABEL) continue;
      string tip=ObjectGetString(0,name,OBJPROP_TOOLTIP);
      if(tip=="" || StringFind(seen,"\n"+tip+"\n")>=0) continue;
      text+="\r\nTarjeta:\r\n"+tip+"\r\n"; seen+=tip+"\n";
   }
   return text;
}
string EvoTextMarket(const EvoSnapshot &s)
{
   string text="\r\n## Indicadores y contexto (precision completa)\r\n";
   if(!evoTextValid) return text+"Snapshot no valido. No interpretar ceros como valores disponibles.\r\n";
   int idx=s.closedView?0:1; double atr=s.atr[idx];
   text+="Vela de referencia (hora de apertura, servidor): "+TimeToString(s.confirmed.time,TIME_DATE|TIME_SECONDS)+"\r\n";
   text+=StringFormat("Cierre: %.*f | ATR(%d): %.8f | promedio ATR(10): %.8f\r\n",_Digits,s.confirmed.close,InpATRPeriod,atr,s.average[idx]);
   text+=StringFormat("ADX(%d): %.8f | +DI %.8f | -DI %.8f\r\n",InpADXPeriod,s.adx[idx],s.closedPlusDI,s.closedMinusDI);
   text+="dADX: "+(s.deltaValid?DoubleToString(s.deltaADX,8):"N/D")+" | "+s.adxInterpretation+"\r\n";
   text+="ER: "+(s.erValid?StringFormat("%.8f | anterior %.8f | cambio %+.8f",s.er,s.erPrevious,s.er-s.erPrevious):"N/D")+" | "+s.erInterpretation+"\r\n";
   text+=StringFormat("RSI(%d): %.8f | anterior %.8f\r\nEMA(%d): %.8f | EMA(%d): %.8f | separacion: %s ATR\r\n",InpRSIPeriod,s.rsi[idx],s.rsi[idx+1],InpEmaFastPeriod,s.fast[idx],InpEmaSlowPeriod,s.slow[idx],atr>0?DoubleToString((s.fast[idx]-s.slow[idx])/atr,8):"N/D");
   text+="EMA50: "+(s.ema50Valid?DoubleToString(s.ema50,8):"N/D")+" | EMA200: "+(s.ema200Valid?DoubleToString(s.ema200,8):"N/D")+"\r\n";
   text+="Bollinger inf / media / sup: "+(s.bbValid?StringFormat("%.8f / %.8f / %.8f",s.bbLower,s.bbMiddle,s.bbUpper):"N/D")+"\r\n";
   text+="OBV "+(EvoOBVVolume==VOLUME_REAL?"REAL":"TICKS")+": "+(s.obvValid?StringFormat("%.0f | cambio(%d) %+.0f | volumen ventana %.0f",s.obv,EvoOBVLookback,s.obvDelta,s.obvVolumeSum):"N/D")+"\r\n";
   text+="MACD 12/26/9 (senal EMA9): "+(s.evidence.valid?StringFormat("linea %.8f | senal %.8f | hist %.8f | hist anterior %.8f",s.evidence.macd,s.evidence.signal,s.evidence.hist,s.evidence.previousHist):"N/D")+"\r\n";
   text+="ROC(12): "+(s.evidence.valid?StringFormat("%+.8f%% | %+.8f ATR",s.evidence.roc,s.evidence.rocATR):"N/D")+"\r\n";
   text+="Stochastic(14,3,3) SMA Low/High: "+(s.stochValid?StringFormat("K %.8f | D %.8f | K previa %.8f | D previa %.8f",s.stochK,s.stochD,s.stochPreviousK,s.stochPreviousD):"N/D")+"\r\n";
   text+="SAR(0.02,0.20): "+(s.sarValid?StringFormat("%.8f | anterior %.8f | cierre %.8f | cierre previo %.8f",s.sar,s.sarPrevious,s.sarClose,s.sarPreviousClose):"N/D")+"\r\n";
   text+="\r\n## Multi-temporal del snapshot\r\n";
   string frames[]={"M15","H1","H4"};
   for(int i=0;i<3;i++) text+=EvoTextFrame(frames[i],s.mtf[i])+"\r\n";
   if(evoTextTab==EVO_TAB_INDICADORES)
   {
      text+="\r\n## Matriz multi-temporal (cache de pantalla)\r\n";
      text+="MTF "+(evoIndicatorsMTF?"ON":"OFF: valores retenidos, no nuevos")+" | Momentum "+(evoIndicatorsMomentum?"ON":"OFF")+StringFormat(" | pagina visible %d\r\n",evoIndicatorsPage+1);
      string names[]={"M15","H1","H4","M5","M30","D1"};
      for(int i=0;i<6;i++) text+=EvoTextFrame(names[i],evoIndicatorsFrameValues[i])+" | vela "+(evoIndicatorsFrameBars[i]>0?TimeToString(evoIndicatorsFrameBars[i],TIME_DATE|TIME_MINUTES):"N/D")+"\r\n";
   }
   text+="\r\n## Estructura, sugerencia y gestion\r\n"+EvoLayerBroad(s.evidence)+"\r\n"+EvoLayerRecent(s.evidence)+"\r\n"+EvoEvidenceConfirmation(s.evidence)+"\r\n"+s.evidence.confirmationDetail+"\r\n"+s.evidence.layersDetail+"\r\n";
   text+="Regimen: "+s.localRegimeName+"\r\nSugerencia: "+s.suggestionAction+"\r\nMotivo: "+s.reason+"\r\nGestion: "+s.managementModeName+"\r\nMotivo gestion: "+s.managementReason+"\r\nPendiente: "+s.pendingAction+"\r\n";
   text+=StringFormat("Scores fuerza %d | eficiencia %d | continuidad %d | agotamiento %d | entrada %d | riesgo %d | extension %d | tactica %d | proteccion %d (no probabilidades)\r\n",s.scoreStrength,s.scoreEfficiency,s.scoreContinuation,s.scoreExhaustion,s.scoreEntryQuality,s.scoreRisk,s.scoreExtension,s.scoreTactical,s.scoreProtection);
   text+="Espacio util: "+(s.roomValid?DoubleToString(s.roomATR,8)+" ATR":"N/D")+"\r\n";
   return text;
}
string EvoTextPosition()
{
   string text="\r\n## TESIS: referencia -> ahora\r\n";
   if(!evoTextHasThesis) return text+"Sin posicion seleccionada o sin referencia evaluable.\r\n";
   EvoThesisItem t=evoTextThesis;
   bool fresh=evoTextThesisFresh;
   text+=StringFormat("Ticket %I64u | id %I64u | %s | entrada %.8f | volumen referencia %.8f\r\n",t.ticket,t.base.id,t.base.type==POSITION_TYPE_BUY?"BUY":"SELL",t.base.entry,t.base.volume);
   text+="Apertura: "+TimeToString(t.base.opened,TIME_DATE|TIME_SECONDS)+"\r\nReferencia capturada: "+TimeToString(t.base.captured,TIME_DATE|TIME_SECONDS)+(t.base.captured-t.base.opened>5?" (posterior a entrada)":" (deteccion de entrada)")+"\r\n";
   text+="Evaluacion: "+(t.evaluated>0?TimeToString(t.evaluated,TIME_DATE|TIME_SECONDS):"N/D")+" | "+(!t.compatible?"NO EVALUABLE: firma cambiada":!fresh?"SIN DATOS CERRADOS ACTUALES":EvoThesisName(t.state))+"\r\n";
   text+=StringFormat("Apoyos perdidos %d/%d | ganados %d | secuencia invalidacion %d\r\n",t.losses,t.compared,t.gains,t.streak);
   text+=StringFormat("ADX: %.8f -> %s\r\nRSI: %.8f -> %s\r\n",t.base.adx,fresh?DoubleToString(t.currentADX,8):"N/D",t.base.rsi,fresh?DoubleToString(t.currentRSI,8):"N/D");
   text+="ER: "+((t.base.validMask & 128)!=0?DoubleToString(t.base.er,8):"N/D")+" -> "+(fresh && (t.currentMask & 128)!=0?DoubleToString(t.currentER,8):"N/D")+"\r\n";
   string names[]={"DI","EMA50 precio/media","EMA200 precio/media","OBV direccion","M15","H1","H4"};
   for(int i=0;i<7;i++) text+=names[i]+": "+((t.base.validMask & (1<<i))!=0?EvoContextBias(t.base.dir[i]):"N/D")+" -> "+(fresh && (t.currentMask & (1<<i))!=0?EvoContextBias(t.nowDir[i]):"N/D")+"\r\n";
   text+=StringFormat("ATR referencia %.8f | SL referencia %.8f\r\nMFE %.8f ATR | MAE %.8f ATR desde primera observacion\r\nP/L flotante + swap %.2f %s (sin comisiones)\r\n",t.base.atr,t.base.sl,t.base.mfe,t.base.mae,t.pnl,AccountInfoString(ACCOUNT_CURRENCY));
   text+="Espacio referencia -> ahora: "+(t.base.room>=0?DoubleToString(t.base.room,8):"N/D")+" -> "+(fresh && t.room>=0?DoubleToString(t.room,8):"N/D")+" ATR de cada lectura\r\n";
   text+="Gestion de posicion: "+t.managementModeName+" | "+(EvoDiagnosticOnly?"SOLO DIAGNOSTICO":"diagnostico automatico desactivado: revisar ajustes")+"\r\n";
   text+="Referencia en disco: "+(t.saved?"SI":"NO")+"\r\nRegla INVALIDADA: DI y EMA50 antes a favor, ahora opuestos, >=3 apoyos perdidos. Confirmacion "+(string)EvoThesisConfirmBars+" cierres.\r\nProteccion extra: "+(EvoThesisProtectProfit?"ACTIVA":"DESACTIVADA")+"\r\n";
   text+="ROC/MACD solo lectura actual: no hay referencia numerica historica guardada. FIJAR afecta el snapshot de mercado; la tesis sigue el seguimiento de posicion.\r\n";
   return text;
}
void EvoTextPresentMarkdown(string report)
{
   StringReplace(report,"\r\n","  \r\n");
   evoTextReport=report; evoTextPage=0; evoTextError=""; evoTextCopied=false;
#ifdef EVO_WINDOWS_CLIPBOARD
   evoTextCopied=EvoWindowsCopy(evoTextReport,evoTextError);
   if(evoTextCopied) Print("Markdown copiado al portapapeles. Sin archivos ni envio externo.");
   else Print("No se copio Markdown: ",evoTextError);
#endif
   evoTextViewer=true; ObjectsDeleteAll(0,"EVO_CONTEXT_");
}
void EvoTextExport()
{
   if(evoTextTab!=evoPanelTab || evoTextDisplayed<=0) { evoTextError="Primero mostrar la solapa que deseas exportar"; Print(evoTextError); return; }
   string tab=evoTextTab==EVO_TAB_TESIS?"Tesis":evoTextTab==EVO_TAB_INDICADORES?"Indicadores":"Analisis";
   string report="# Monitor Evolucion - "+tab+"\r\n";
   report+="Simbolo: "+_Symbol+" | temporalidad: "+EnumToString(_Period)+" | programa: "+MQLInfoString(MQL_PROGRAM_NAME)+"\r\n";
   report+="Entorno: "+(MQLInfoInteger(MQL_TESTER)?"PROBADOR: horas simuladas":EnumToString((ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE)))+"\r\n";
   report+="Generado servidor: "+TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS)+" | TimeLocal (simulado en probador): "+TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS)+"\r\n";
   report+="Pantalla capturada: "+TimeToString(evoTextDisplayed,TIME_DATE|TIME_SECONDS)+" | FIJADO "+(evoTextFrozen?"SI":"NO")+" | datos pendientes "+(evoTextPending?"SI":"NO")+"\r\n";
   report+="Fuente: snapshot utilizado para dibujar. No se recalculan indicadores al exportar. Incluye todas las secciones disponibles, aunque alguna pagina/bloque este oculto; el anexo distingue lo visible. N/D no equivale a cero.\r\n";
   if(evoTextTab==EVO_TAB_TESIS) report+=EvoTextPosition();
   report+=EvoTextMarket(evoTextSnapshot)+EvoTextVisible();
   report+="\r\n## Notas para compartir\r\nADX/ER no indican direccion por si solos. Extremos RSI/Stochastic y cambios SAR no prueban un giro. No son probabilidades ni ordenes. Contiene solo observaciones actuales, no velas/ticks completos; no permite reconstruir un backtest.\r\nNo se enviaron datos a servicios externos. Texto generado en memoria por accion del usuario.\r\n";
   EvoTextPresentMarkdown(report);
}
void EvoTextViewerDraw()
{
   EvoPanelBackground(25);
   EvoThesisButton("EVO_CONTEXT_MD_CLOSE","VOLVER",0);
   EvoPanelLine(1,"MARKDOWN EN MEMORIA | sin archivos",clrWhite,true);
#ifdef EVO_WINDOWS_CLIPBOARD
   EvoPanelLine(2,evoTextCopied?"COPIADO: pega con Ctrl+V en tu IA":evoTextError, evoTextCopied?clrLimeGreen:clrGold);
   EvoThesisButton("EVO_CONTEXT_MD_COPY","COPIAR MD",22);
#else
   EvoPanelLine(2,"Campo superior: clic, Ctrl+A, Ctrl+C para copiar el texto",clrGold);
#endif
   string edit="EVO_CONTEXT_MD_TEXT";
   if(ObjectFind(0,edit)<0) { ObjectCreate(0,edit,OBJ_EDIT,0,0,0); ObjectSetString(0,edit,OBJPROP_TEXT,evoTextReport); }
   ObjectSetInteger(0,edit,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,edit,OBJPROP_XDISTANCE,evoPanelX+12); ObjectSetInteger(0,edit,OBJPROP_YDISTANCE,evoPanelY+10+3*EvoPanelPitch());
   ObjectSetInteger(0,edit,OBJPROP_XSIZE,EvoPanelWidth()-24); ObjectSetInteger(0,edit,OBJPROP_YSIZE,EvoPanelPitch());
   ObjectSetInteger(0,edit,OBJPROP_READONLY,true); ObjectSetInteger(0,edit,OBJPROP_FONTSIZE,8);
   ObjectSetInteger(0,edit,OBJPROP_BGCOLOR,C'28,35,42'); ObjectSetInteger(0,edit,OBJPROP_COLOR,clrWhite);
   ObjectSetString(0,edit,OBJPROP_TOOLTIP,"Texto completo en memoria. Seleccionar con Ctrl+A y copiar con Ctrl+C. El listado inferior es solo la vista paginada.");
   string lines[]; int total=StringSplit(evoTextReport,'\n',lines),size=16,pages=MathMax(1,(total+size-1)/size);
   evoTextPage=MathMax(0,MathMin(evoTextPage,pages-1));
   EvoPanelLine(4,StringFormat("Vista %d/%d | copia siempre el texto completo del campo",evoTextPage+1,pages),clrSilver);
   for(int i=0;i<size && evoTextPage*size+i<total;i++) EvoPanelLine(5+i,lines[evoTextPage*size+i],clrSilver);
   EvoThesisButton("EVO_CONTEXT_MD_PREV","ANTERIOR",23); ObjectSetInteger(0,"EVO_CONTEXT_MD_PREV",OBJPROP_XDISTANCE,evoPanelX+12);
   EvoThesisButton("EVO_CONTEXT_MD_NEXT","SIGUIENTE",23);
   EvoPanelLine(24,"VOLVER o Escape cierra esta vista; el gestor sigue funcionando",clrSilver);
}
bool EvoTextEvent(const int id,const long key,const string name)
{
   if(id==CHARTEVENT_OBJECT_CLICK && name=="EVO_CONTEXT_EXPORT_MD") { EvoTextExport(); return true; }
   if(!evoTextViewer) return false;
   if((id==CHARTEVENT_KEYDOWN && key==27) || (id==CHARTEVENT_OBJECT_CLICK && name=="EVO_CONTEXT_MD_CLOSE"))
   { evoTextViewer=false; ObjectsDeleteAll(0,"EVO_CONTEXT_"); return true; }
   if(id!=CHARTEVENT_OBJECT_CLICK) return false;
   if(name=="EVO_CONTEXT_MD_NEXT") evoTextPage++;
   else if(name=="EVO_CONTEXT_MD_PREV") evoTextPage--;
#ifdef EVO_WINDOWS_CLIPBOARD
   else if(name=="EVO_CONTEXT_MD_COPY") { evoTextCopied=EvoWindowsCopy(evoTextReport,evoTextError); }
#endif
   else return false;
   ObjectSetInteger(0,name,OBJPROP_STATE,false); return true;
}
#endif
