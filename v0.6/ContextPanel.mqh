#ifndef EVOLUTION_CONTEXT_PANEL
#define EVOLUTION_CONTEXT_PANEL
#include "MonitorLevels.mqh"
#include "ManagementMode.mqh"
#include "DecisionScores.mqh"
#include "TradeDataset.mqh"
input group "Panel de contexto compartido"
input bool EvoShowContext = true;
input int EvoPanelX = 350;
input int EvoPanelY = 20;
input int EvoPanelFont = 9;
input int EvoPanelRefreshMs = 1000; // Solo dibujo; no cambia el ciclo de proteccion
// 0=TACTICA 1=ANALISIS 2=TESIS 3=ALERTAS — solo presentacion; no recalcula motor.
enum ENUM_EVO_PANEL_TAB { EVO_TAB_TACTICA=0, EVO_TAB_ANALISIS=1, EVO_TAB_TESIS=2, EVO_TAB_ALERTAS=3, EVO_TAB_REGISTRO=4, EVO_TAB_INDICADORES=5, EVO_TAB_PATRONES=6 };
bool EvoValidPanelInputs()
{
   return EvoPanelRefreshMs>=100 && EvoPanelRefreshMs<=10000 && EvoPanelFont>=6 && EvoPanelFont<=30 && InpMonitorSRLookback>=10 &&
          InpMonitorSRLookback<=10000 && InpMonitorSRPivotBars>=1 && InpMonitorSRPivotBars<=1000 &&
          InpMonitorLateralADXMax>0;
}
int evoMonitorControlRow=21,evoRiskStart=25;
bool evoPatternDrawings=true;
int evoPatternWickOffset=0;
bool evoPatternWave3View=false;
bool evoDemandView=false;
bool evoPanelMinimized=false,evoSimulationView=false;
bool evoPanelFrozen=false,evoPanelDataPending=false;
bool evoHelpOpen=false;
int evoHelpPage=0;
bool evoRowsUsed[64];
int EvoPanelPitch() { return MathMax(18,MathMin(EvoPanelFont+12,((int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS)-24)/MathMax(1,evoPanelRows))); }
void EvoBeginFrame() { ObjectsDeleteAll(0,"EVO_PATTERN_"); if(evoPanelTab!=EVO_TAB_PATRONES || evoDemandView || evoSimulationView || evoPanelMinimized) { ObjectDelete(0,"EVO_CONTEXT_PATTERN_LINES"); ObjectDelete(0,"EVO_CONTEXT_PATTERN_WICK_NEXT"); ObjectDelete(0,"EVO_CONTEXT_PATTERN_WAVE3"); } for(int i=0;i<64;i++) evoRowsUsed[i]=false; ObjectsDeleteAll(0,"EVO_CONTEXT_MATRIX_"); if(evoPanelTab!=EVO_TAB_INDICADORES || evoDemandView || evoSimulationView || evoPanelMinimized) ObjectsDeleteAll(0,"EVO_CONTEXT_IND_"); }
void EvoEndFrame()
{
#ifdef EVO_MONITOR_SAFE_INPUTS
   if(evoManagementInputWarning!="")
   {
      EvoPanelLine(1,"AJUSTES CORREGIDOS | ver REGISTRO / Expertos",clrOrange);
      ObjectSetString(0,"EVO_CONTEXT_1",OBJPROP_TOOLTIP,evoManagementInputWarning);
   }
#endif
   for(int i=0;i<64;i++) if(!evoRowsUsed[i]) ObjectDelete(0,"EVO_CONTEXT_"+(string)i);
   ChartRedraw(0);
}
int evoPanelX=0,evoPanelY=0,evoPanelRows=16,evoPanelExtraRows=0;
int evoPanelTab=EVO_TAB_TACTICA;
int evoThesisIndex=0;
bool evoPanelInitialized=false,evoPanelDragging=false,evoPanelMouseDown=false;
bool evoPanelOldForeground=false,evoPanelOldMouseMove=false,evoPanelOldScroll=true;
int evoPanelOffsetX=0,evoPanelOffsetY=0;

int EvoPanelWidth() { return MathMax(280,MathMin(620,(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS)-16)); }
int EvoPanelHeight() { return 20+evoPanelRows*EvoPanelPitch(); }
string EvoPanelKey() { return StringFormat("EVP.%I64d.",ChartID()); }
void EvoPanelStopDrag()
{
   if(!evoPanelDragging) return;
   evoPanelDragging=false;
   ChartSetInteger(0,CHART_MOUSE_SCROLL,evoPanelOldScroll);
   GlobalVariableSet(EvoPanelKey()+"X",evoPanelX);
   GlobalVariableSet(EvoPanelKey()+"Y",evoPanelY);
}
void EvoPanelInit()
{
   if(evoPanelInitialized || !EvoShowContext) return;
   ObjectsDeleteAll(0,"EVO_TAB_");
   evoPanelInitialized=true; evoPanelX=EvoPanelX; evoPanelY=EvoPanelY;
   if(GlobalVariableCheck(EvoPanelKey()+"X")) evoPanelX=(int)GlobalVariableGet(EvoPanelKey()+"X");
   if(GlobalVariableCheck(EvoPanelKey()+"Y")) evoPanelY=(int)GlobalVariableGet(EvoPanelKey()+"Y");
   if(GlobalVariableCheck(EvoPanelKey()+"TAB"))
   {
      int t=(int)GlobalVariableGet(EvoPanelKey()+"TAB");
      if(t>=EVO_TAB_TACTICA && t<=EVO_TAB_PATRONES) evoPanelTab=t;
   }
   evoPanelOldForeground=(bool)ChartGetInteger(0,CHART_FOREGROUND);
   evoPanelOldMouseMove=(bool)ChartGetInteger(0,CHART_EVENT_MOUSE_MOVE);
   ChartSetInteger(0,CHART_FOREGROUND,false);
   ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,true);
}
// The minimized view is only a restore button; no background, tabs or simulation.
void EvoPanelDrawMinimized(const bool managementActive)
{
   string restore="EVO_CONTEXT_MIN";
   for(int i=ObjectsTotal(0)-1;i>=0;i--)
   {
      string name=ObjectName(0,i);
      if(StringFind(name,"EVO_CONTEXT_")==0 && name!=restore) ObjectDelete(0,name);
   }
   int x=MathMax(0,MathMin(evoPanelX,(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS)-80));
   int y=MathMax(0,MathMin(evoPanelY,(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS)-24));
   if(ObjectFind(0,restore)<0) ObjectCreate(0,restore,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,restore,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,restore,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,restore,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,restore,OBJPROP_XSIZE,80); ObjectSetInteger(0,restore,OBJPROP_YSIZE,24);
   ObjectSetInteger(0,restore,OBJPROP_BGCOLOR,clrDarkSlateGray); ObjectSetInteger(0,restore,OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,restore,OBJPROP_FONTSIZE,9); ObjectSetInteger(0,restore,OBJPROP_ZORDER,40);
   ObjectSetInteger(0,restore,OBJPROP_BACK,false); ObjectSetInteger(0,restore,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,restore,OBJPROP_STATE,false); ObjectSetString(0,restore,OBJPROP_TEXT,"ABRIR");
   ObjectSetString(0,restore,OBJPROP_TOOLTIP,"Restaurar el tablero. Gestion de posiciones: "+(managementActive?"ACTIVA":"OFF")+". Minimizar solo oculta el panel.");
   ChartRedraw(0);
}
void EvoPanelMove(int x,int y)
{
   x=MathMax(0,MathMin(x,(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS)-EvoPanelWidth()));
   y=MathMax(0,MathMin(y,(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0)-EvoPanelHeight()));
   int dx=x-evoPanelX,dy=y-evoPanelY;
   for(int i=ObjectsTotal(0)-1;i>=0;i--)
   {
      string name=ObjectName(0,i);
      if(StringFind(name,"EVO_CONTEXT_")!=0) continue;
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,ObjectGetInteger(0,name,OBJPROP_XDISTANCE)+dx);
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,ObjectGetInteger(0,name,OBJPROP_YDISTANCE)+dy);
   }
   evoPanelX=x; evoPanelY=y;
   ChartRedraw(0);
}
bool EvoPanelEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
#ifdef EVO_ANALYSIS_DASHBOARD_VERSION
   if(id==CHARTEVENT_OBJECT_CLICK && sparam=="EVO_CONTEXT_DETAILS_PAGE")
   { evoDashboardDetailsPage=1-evoDashboardDetailsPage; ObjectsDeleteAll(0,"EVO_CONTEXT_"); return true; }
   if(id==CHARTEVENT_OBJECT_CLICK && sparam=="EVO_CONTEXT_DECISION_MODE")
   { evoDecisionOnly=!evoDecisionOnly; ObjectsDeleteAll(0,"EVO_CONTEXT_"); return true; }
#endif
   if(!EvoShowContext || !evoPanelInitialized) return false;
   if(id==CHARTEVENT_OBJECT_CLICK)
   {
      if(sparam=="EVO_CONTEXT_FREEZE") { evoPanelFrozen=!evoPanelFrozen; ObjectSetInteger(0,sparam,OBJPROP_STATE,false); return true; }
      if(sparam=="EVO_CONTEXT_TAB_TACTICA") { evoPanelTab=EVO_TAB_TACTICA; GlobalVariableSet(EvoPanelKey()+"TAB",evoPanelTab); ObjectSetInteger(0,sparam,OBJPROP_STATE,false); return true; }
      if(sparam=="EVO_CONTEXT_TAB_ANALISIS") { evoPanelTab=EVO_TAB_ANALISIS; GlobalVariableSet(EvoPanelKey()+"TAB",evoPanelTab); ObjectSetInteger(0,sparam,OBJPROP_STATE,false); return true; }
      if(sparam=="EVO_CONTEXT_TAB_INDICADORES") { evoPanelTab=EVO_TAB_INDICADORES; GlobalVariableSet(EvoPanelKey()+"TAB",evoPanelTab); ObjectSetInteger(0,sparam,OBJPROP_STATE,false); return true; }
      if(sparam=="EVO_CONTEXT_TAB_PATRONES") { evoPanelTab=EVO_TAB_PATRONES; GlobalVariableSet(EvoPanelKey()+"TAB",evoPanelTab); ObjectSetInteger(0,sparam,OBJPROP_STATE,false); return true; }
      if(sparam=="EVO_CONTEXT_PATTERN_LINES") { evoPatternDrawings=!evoPatternDrawings; ObjectSetInteger(0,sparam,OBJPROP_STATE,false); return true; }
      if(sparam=="EVO_CONTEXT_PATTERN_WAVE3") { evoPatternWave3View=!evoPatternWave3View; ObjectSetInteger(0,sparam,OBJPROP_STATE,false); return true; }
      if(sparam=="EVO_CONTEXT_PATTERN_WICK_NEXT") { evoPatternWickOffset++; ObjectSetInteger(0,sparam,OBJPROP_STATE,false); return true; }
      if(EvoIndicatorsEvent(sparam)) return true;
      if(sparam=="EVO_CONTEXT_TAB_TESIS") { evoPanelTab=EVO_TAB_TESIS; GlobalVariableSet(EvoPanelKey()+"TAB",evoPanelTab); ObjectSetInteger(0,sparam,OBJPROP_STATE,false); return true; }
      if(sparam=="EVO_CONTEXT_TAB_ALERTAS") { evoPanelTab=EVO_TAB_ALERTAS; GlobalVariableSet(EvoPanelKey()+"TAB",evoPanelTab); ObjectSetInteger(0,sparam,OBJPROP_STATE,false); return true; }
      if(sparam=="EVO_CONTEXT_NEXT") { evoThesisIndex++; ObjectSetInteger(0,sparam,OBJPROP_STATE,false); return true; }
   }
   if(id==CHARTEVENT_CHART_CHANGE) { if(!evoPanelMinimized) EvoPanelMove(evoPanelX,evoPanelY); return false; }
   if(id!=CHARTEVENT_MOUSE_MOVE) return false;
   int x=(int)lparam,y=(int)dparam;
   bool down=((int)StringToInteger(sparam)&1)!=0;
   if(down && !evoPanelMouseDown && x>=evoPanelX && x<=evoPanelX+EvoPanelWidth() && y>=evoPanelY+28 && y<=evoPanelY+10+2*EvoPanelPitch())
   {
      evoPanelDragging=true; evoPanelOffsetX=x-evoPanelX; evoPanelOffsetY=y-evoPanelY;
      evoPanelOldScroll=(bool)ChartGetInteger(0,CHART_MOUSE_SCROLL);
      ChartSetInteger(0,CHART_MOUSE_SCROLL,false);
   }
   bool handled=evoPanelDragging;
   if(evoPanelDragging && down) EvoPanelMove(x-evoPanelOffsetX,y-evoPanelOffsetY);
   if(!down) EvoPanelStopDrag();
   evoPanelMouseDown=down; return handled;
}

void EvoPanelDelete()
{
   ObjectsDeleteAll(0,"EVO_PATTERN_");
   EvoIndicatorsRelease();
   EvoDeleteSRLines();
   EvoPanelStopDrag();
   ObjectsDeleteAll(0,"EVO_CONTEXT_");
   if(evoPanelInitialized)
   {
      ChartSetInteger(0,CHART_FOREGROUND,evoPanelOldForeground);
      ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,evoPanelOldMouseMove);
   }
   evoPanelInitialized=false;
}

void EvoPanelLine(const int row,const string text,const color ink=clrSilver,const bool emphasis=false)
{
   string name="EVO_CONTEXT_"+IntegerToString(row);
   if(text=="") return;
   if(row>=0 && row<64) evoRowsUsed[row]=true;
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,evoPanelX+12);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,evoPanelY+10+row*EvoPanelPitch());
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,1);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,MathMin(EvoPanelFont,EvoPanelPitch()-10));
   ObjectSetInteger(0,name,OBJPROP_COLOR,ink);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   string face=emphasis?"Arial Black":"Consolas";
   ObjectSetString(0,name,OBJPROP_FONT,face);
   // Measure rendered text (DPI-aware) rather than guessing character width.
   int font=MathMin(EvoPanelFont+(emphasis?2:0),EvoPanelPitch()-8); uint width=0,height=0;
   string shown=text;
   TextSetFont(face,-font*10);
   while(StringLen(shown)>4 && TextGetSize(shown,width,height) && width>(uint)(EvoPanelWidth()-24))
      shown=StringSubstr(shown,0,StringLen(shown)-4)+"...";
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,font);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,text);
   ObjectSetString(0,name,OBJPROP_TEXT,shown);
}

int EvoContextDirection(const double value,const double reference)
{ return value>reference?1:value<reference?-1:0; }
string EvoContextRelation(const bool valid,const int direction,const int signal)
{
   if(!valid) return "SIN DATOS";
   if(direction==0) return "NO CONFIRMA";
   if(signal==0) return "SIN ENTRADA A COMPARAR";
   return direction==signal?"APOYA "+(signal>0?"COMPRA":"VENTA"):"CONTRADICE "+(signal>0?"COMPRA":"VENTA");
}
string EvoContextBias(const int direction)
{ return direction>0?"ALCISTA":direction<0?"BAJISTA":"NEUTRAL"; }
string EvoBBRelation(const EvoSnapshot &s)
{
   if(!s.bbValid) return "SIN DATOS";
   if(s.signal==0) return "SIN ENTRADA A COMPARAR";
   double price=InpRequireCandleConfirmation?s.confirmed.close:s.current.close;
   return EvoBollingerAllows(s.signal,s.regime,s.bbValid,price,s.bbLower,s.bbMiddle,s.bbUpper)?
      "APOYA "+(s.signal>0?"COMPRA":"VENTA"):"NO CONFIRMA "+(s.signal>0?"COMPRA":"VENTA");
}
string EvoContextOpposition(const EvoSnapshot &s)
{
   if(s.signal==0) return "";
   string result="";
   if(s.ema50Valid && EvoContextDirection(s.confirmed.close,s.ema50)==-s.signal) result+="EMA50 ";
   if(s.ema200Valid && EvoContextDirection(s.confirmed.close,s.ema200)==-s.signal) result+="EMA200 ";
   if(s.obvValid && EvoContextDirection(s.obvDelta,0)==-s.signal) result+="OBV ";
   string frames[3]={"M15","H1","H4"};
   for(int i=0;i<3;i++) if(s.mtf[i].valid && s.mtf[i].direction==-s.signal) result+=frames[i]+" ";
   return result;
}

void EvoFinalSuggestion(const bool valid,const EvoSnapshot &s)
{
   int signal=valid?s.signal:0;
   bool caution=valid && signal!=0 && s.needsConfirmation;
   color ink=caution?clrGold:signal>0?clrLime:signal<0?clrSalmon:clrGold;
   string name="EVO_CONTEXT_CONCLUSION_BG";
   if(ObjectFind(0,name)<0)
   {
      ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0);
      // Keep the text in front even if the strip was recreated independently.
      ObjectDelete(0,"EVO_CONTEXT_20");
   }
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,evoPanelX+6);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,evoPanelY+8+20*EvoPanelPitch());
   ObjectSetInteger(0,name,OBJPROP_XSIZE,EvoPanelWidth()-12);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,EvoPanelPitch());
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,caution?C'65,52,15':signal>0?C'15,65,35':signal<0?C'75,25,25':C'65,52,15');
   ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,ink);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   string action=!valid?"NO ENTRAR":(s.suggestionAction!=""?s.suggestionAction:EvoSuggestionAction(signal,false));
   EvoPanelLine(20,"SUGERENCIA TECNICA: "+action,ink,true);
   string why=!valid?"NO ENTRAR: faltan datos":signal==0?"NO ENTRAR: "+s.reason:
      (signal>0?"COMPRA: ":"VENTA: ")+(s.regime=="TENDENCIA"?
      (signal>0?"ruptura sobre media maxima":"ruptura bajo media minima"):
      (signal>0?"cerca de media minima + RSI":"cerca de media maxima + RSI"))+"; filtros cumplidos";
   if(caution)
      why="ESPERAR: "+s.localRegimeName+(s.roomValid?StringFormat(" | espacio %.2f ATR",s.roomATR):"")+
          " | el patron base sigue activo pero el contexto local pide confirmacion";
   string opposition=valid?EvoContextOpposition(s):"";
   string contextDetail="";
   if(valid && signal!=0)
   {
      contextDetail=opposition!=""?"Contexto opuesto: "+opposition:"Sin oposicion en EMA50/200, OBV y M15/H1/H4 disponibles; no implica confirmacion completa.";
      if(opposition!="") why+=" | OJO: "+opposition;
   }
   EvoPanelLine(21,why,ink);
   string detail=why+"\n"+contextDetail+"\nLa conclusion respeta los filtros activos del asesor; no activa filtros deshabilitados."+
                 "\nEl riesgo, margen, spread y otros controles de ejecucion se evaluan aparte. No envia una orden desde el monitor.";
   if(valid)
   {
      detail+="\n"+s.reason+"\nBUY: "+s.buyChecks+"\nSELL: "+s.sellChecks;
      detail+="\nRegimen local: "+s.localRegimeName+(s.rangeValid?StringFormat(" | compresion %.2f ATR | desplazamiento %.2f ATR",s.compression,s.displacement):" | rango N/D");
      detail+="\nGestion sugerida: "+s.managementModeName+" | "+s.managementModeHint+(EvoDiagnosticOnly?" | SOLO DIAGNOSTICO":"");
      if(s.managementReason!="") detail+="\nMotivo gestion: "+s.managementReason;
      if(s.pendingAction!="") detail+="\nPendiente: "+s.pendingAction;
      detail+=StringFormat("\nScores F%d Efi%d Cont%d Agot%d Ent%d Ries%d | E%d T%d P%d",
         s.scoreStrength,s.scoreEfficiency,s.scoreContinuation,s.scoreExhaustion,s.scoreEntryQuality,s.scoreRisk,
         s.scoreExtension,s.scoreTactical,s.scoreProtection);
      detail+="\nBollinger: "+EvoBBRelation(s)+" | "+(EvoUseBBFilter?"filtro de entrada activo":"solo contexto; no cambia esta sugerencia");
      detail+="\nOBV: "+(EvoUseOBVFilter?"filtro activo":"solo contexto")+" | "+(!s.obvValid?"N/D":s.obvDelta>0?"ascendente":s.obvDelta<0?"descendente":"plano");
      if(s.deltaValid) detail+=StringFormat("\nDelta ADX cerrado: %+.2f",s.deltaADX);
      if(caution) detail+="\nLa cautela por consolidacion/espacio no crea ni invierte la senal base; no sustituye GESTION SUGERIDA.";
   }
   ObjectSetString(0,"EVO_CONTEXT_20",OBJPROP_TOOLTIP,detail);
   ObjectSetString(0,"EVO_CONTEXT_21",OBJPROP_TOOLTIP,detail);
}

void EvoPanelBackground(const int rows)
{
     EvoPanelInit(); evoPanelRows=rows;
     evoPanelX=MathMax(0,MathMin(evoPanelX,(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS)-EvoPanelWidth()));
     evoPanelY=MathMax(0,MathMin(evoPanelY,(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS)-EvoPanelHeight()));
   string name="EVO_CONTEXT_BG";
   if(ObjectFind(0,name)<0)
   {
      ObjectsDeleteAll(0,"EVO_CONTEXT_");
      ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0);
   }
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,evoPanelX);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,evoPanelY);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,EvoPanelWidth());
   ObjectSetInteger(0,name,OBJPROP_YSIZE,20+rows*EvoPanelPitch());
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,C'18,22,27');
   ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,clrSlateGray);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,0);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,"Arrastra el titulo para mover el panel");
}

string EvoFrameText(const string name,const EvoFrameContext &r)
{
   if(!r.valid) return name+": SIN DATOS";
   return name+": "+r.regime+(r.direction>0?" ALCISTA":r.direction<0?" BAJISTA":" NEUTRO");
}

void EvoThesisButton(const string name,const string text,const int row)
{
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,evoPanelX+EvoPanelWidth()-112);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,evoPanelY+6+row*EvoPanelPitch());
   ObjectSetInteger(0,name,OBJPROP_XSIZE,102); ObjectSetInteger(0,name,OBJPROP_YSIZE,20);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,clrDarkSlateGray); ObjectSetInteger(0,name,OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,30); ObjectSetString(0,name,OBJPROP_TEXT,text);
}
string EvoTabHelp(const string name,const string caption)
{
   if(name=="EVO_CONTEXT_TAB_TACTICA") return "TACTICA: resumen de mercado y controles de riesgo, BE, niveles, trailing y salida en perdida.";
   if(name=="EVO_CONTEXT_TAB_ANALISIS") return "ANALISIS: tablero de indicadores, vela activa, canal, estructura y contexto multi-temporal. No es el informe solicitado de ANALIZAR.";
   if(name=="EVO_CONTEXT_TAB_INDICADORES") return "INDICADORES: matriz de volatilidad, fuerza, medias, soportes/resistencias, momentum y temporalidades. Copiar MD comparte los datos en memoria.";
   if(name=="EVO_CONTEXT_TAB_PATRONES") return "PATRONES: estudio diagnostico de HCH, dobles, velas notables y ondas geometricas. Dibujos y niveles; no ejecuta entradas.";
   if(name=="EVO_CONTEXT_TAB_TESIS") return "TESIS: salud de la posicion seleccionada. Referencia -> Ahora, apoyos, MFE/MAE, gestion y M15/H1/H4. Copiar MD comparte esta lectura.";
   if(name=="EVO_CONTEXT_TAB_ALERTAS") return "ALERTAS: eventos y cambios de contexto detectados. No son ordenes automaticas de compra o venta.";
   if(name=="EVO_CONTEXT_TAB_REGISTRO") return "REGISTRO: historial de eventos, solicitudes y resultados de gestion para revisar lo ocurrido.";
   if(name=="EVO_CONTEXT_FREEZE") return caption+": fija o reanuda la lectura visual del mercado. No pausa la gestion, el BE ni el trailing de las posiciones.";
   if(name=="EVO_CONTEXT_MIN") return caption+": minimizar o volver a desplegar el tablero. Las protecciones siguen funcionando.";
   if(name=="EVO_CONTEXT_SIM") return "SIMULAR: preparar mercado Buy/Sell o pendientes Limit/Stop, volumen, SL/TP e importes; confirmar, modificar, cerrar o cancelar mediante botones explicitos.";
   if(name=="EVO_CONTEXT_ANALYZE") return "ANALIZAR: genera un informe avanzado solicitado, fijo hasta volver a pulsar ANALIZAR. Esta despues de SIMULAR. Copiar MD incluye todas sus paginas; no envia ordenes.";
   if(name=="EVO_CONTEXT_LINES") return caption+": ocultar o mostrar dibujos y niveles del monitor. No elimina SL/TP reales ni pausa protecciones.";
   if(name=="EVO_CONTEXT_HELP") return "AYUDA: glosario y guias de indicadores, rupturas, correcciones, microlotes y uso del simulador.";
   return caption;
}
void EvoTabButton(const string name,const string text,const int slot,const bool active)
{
   int actualSlot=slot==12?12:slot==11?3:slot>=3?slot+1:slot;
   double unit=(EvoPanelWidth()-16)/136.0;
   int w=(int)MathRound(unit*(slot==2?16:10))-2;
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,evoPanelX+8+(int)MathRound(unit*(actualSlot*10+(actualSlot>2?6:0))));
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,evoPanelY+6);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w); ObjectSetInteger(0,name,OBJPROP_YSIZE,20);
   bool selected=active;
   if((name=="EVO_CONTEXT_TAB_ANALISIS" || name=="EVO_CONTEXT_TAB_TESIS") && (evoSimulationView || evoDemandView || evoHelpOpen)) selected=false;
   color tabFill=selected?clrDarkSlateBlue:clrDarkSlateGray;
   if(name=="EVO_CONTEXT_TAB_ANALISIS") tabFill=selected?C'35,125,205':C'25,75,130';
   else if(name=="EVO_CONTEXT_TAB_TESIS") tabFill=selected?C'145,75,190':C'90,40,125';
   else if(name=="EVO_CONTEXT_SIM") tabFill=selected?C'195,110,25':C'120,65,15';
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,tabFill);
   ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,selected?clrWhite:C'80,95,105');
   ObjectSetInteger(0,name,OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,w<90?7:9);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,40); ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,EvoTabHelp(name,text));
}
void EvoDrawTabs()
{
   EvoTabButton("EVO_CONTEXT_HELP","AYUDA",12,evoHelpOpen);
   EvoTabButton("EVO_CONTEXT_LINES",evoChartLinesVisible?"OCULTAR":"MOSTRAR",10,!evoChartLinesVisible);
   EvoTabButton("EVO_CONTEXT_TAB_TACTICA","TACTICA",0,evoPanelTab==EVO_TAB_TACTICA);
   EvoTabButton("EVO_CONTEXT_TAB_ANALISIS","ANALISIS",1,evoPanelTab==EVO_TAB_ANALISIS);
   EvoTabButton("EVO_CONTEXT_TAB_INDICADORES","INDICADORES",2,evoPanelTab==EVO_TAB_INDICADORES);
   EvoTabButton("EVO_CONTEXT_TAB_PATRONES","PATRONES",11,evoPanelTab==EVO_TAB_PATRONES);
   EvoTabButton("EVO_CONTEXT_TAB_TESIS","TESIS",3,evoPanelTab==EVO_TAB_TESIS);
   EvoTabButton("EVO_CONTEXT_TAB_ALERTAS","ALERTAS",4,evoPanelTab==EVO_TAB_ALERTAS);
   EvoTabButton("EVO_CONTEXT_TAB_REGISTRO","REGISTRO",9,evoPanelTab==EVO_TAB_REGISTRO);
   EvoTabButton("EVO_CONTEXT_FREEZE",evoPanelFrozen?"SEGUIR":"FIJAR",5,evoPanelFrozen);
   EvoTabButton("EVO_CONTEXT_MIN",evoPanelMinimized?"ABRIR":"MIN",6,evoPanelMinimized);
   EvoTabButton("EVO_CONTEXT_SIM","SIMULAR",7,evoSimulationView);
   EvoTabButton("EVO_CONTEXT_ANALYZE","ANALIZAR",8,evoDemandView);
}
void EvoHelpDraw()
{
   EvoPanelBackground(21);
   EvoTabButton("EVO_CONTEXT_HELP_PREV","ANTERIOR",0,false);
   EvoTabButton("EVO_CONTEXT_HELP_NEXT","SIGUIENTE",2,false);
   EvoTabButton("EVO_CONTEXT_HELP_CLOSE","CERRAR",12,false);
   EvoPanelLine(1,StringFormat("AYUDA | MERCADO Y SIMULADOR | %d/7",evoHelpPage+1),clrAqua,true);
   string lines[];
   if(evoHelpPage==0)
   {
      string content="RUPTURAS: SIEMPRE INDICAR EL NIVEL\nSoporte: zona que puede frenar una caida.\nResistencia: zona que puede frenar una subida.\nPRESION SOBRE SOPORTE / RESISTENCIA\nEl precio se acerca con fuerza; aun no rompe.\nINTENTO DE RUPTURA\nLa vela activa atraviesa el nivel. Puede volver\nantes de cerrar: lectura provisional.\nRUPTURA PENDIENTE DE CONFIRMACION\nHay un cierre fuera; faltan reglas adicionales.\nRUPTURA CONFIRMADA\nCumple cierres, margen y filtros definidos.\nPuede fallar despues; no garantiza continuidad.\nEN ESTE ESTUDIO DE ESTRUCTURA\nConfirmar exige dos cierres contra pivote y\ncanal previo, margen 0.10 ATR y MACD/ROC alineados.\nNo confundir con las reglas de cada patron.";
      StringSplit(content,'\n',lines);
   }
   else if(evoHelpPage==1)
   {
      string content="RECHAZO, REBOTE, CORRECCION Y GIRO\nRECHAZO EN UN NIVEL\nEl precio toca o atraviesa el nivel y vuelve.\nUna mecha puede mostrarlo; sola no confirma giro.\nPOSIBLE REBOTE DESDE SOPORTE\nRechazo y recuperacion; falta continuidad.\nPOSIBLE CAIDA DESDE RESISTENCIA\nRechazo y movimiento bajista; falta continuidad.\nPuede llegar con fuerza y aun asi rebotar.\nCORRECCION\nMovimiento contrario dentro de la tendencia previa.\nPOSIBLE GIRO\nRuptura de estructura relevante y otras evidencias.\nRomper un soporte menor no prueba un giro completo.\nESTRUCTURA PREVIA NO ES DIRECCION ACTUAL\nEjemplo: ruptura BAJISTA de estructura antes ALCISTA.\nEl canal principal y la vela activa pueden diferir.";
      StringSplit(content,'\n',lines);
   }
   else if(evoHelpPage==2)
   {
      string content="INDICADORES Y VELA ACTIVA\nATR: unidad para comparar distancias y rangos.\nER: eficiencia del recorrido, NO direccion.\nER bajo: ruido / recorrido poco eficiente.\nNo valida por si solo un nivel ni un rebote.\nADX: fuerza de tendencia; no compra ni venta.\nDI ayuda a interpretar direccion del movimiento.\nRSI: momentum; sobrecompra no obliga a caer.\nMEDIAS: sesgo y cruces; pueden llevar retraso.\nOBV: contexto de volumen; puede usar ticks,\nno necesariamente volumen real negociado.\nVELA ACTIVA: lectura provisional hasta su cierre.\nFuerza aqui = desplazamiento / ATR, no ADX.\nModerada >=0.25; fuerte >=1; excepcional >=2 ATR.\nDISTANCIA AL SL: margen al stop real de la posicion.\nCerca del SL <=0.25 ATR; no predice que sera tocado.\nEsta ayuda no envia ni modifica ordenes.";
      StringSplit(content,'\n',lines);
   }
   else if(evoHelpPage==3)
   {
      string content="SIMULAR: SUBIR Y BAJAR MICROLOTES\n1 microlote = 0.01 lote.\n0.10 lotes = 10 microlotes.\nEl boton + aumenta el volumen de la propuesta.\nEl boton - reduce el volumen de la propuesta.\nNormalmente cada pulsacion cambia 1 microlote.\nSi el broker exige un paso mayor, el boton\nindica cuantos microlotes cambia por pulsacion.\nSe respetan el minimo y maximo del simbolo.\nEl total se muestra arriba en lotes y microlotes.\nSL y TP monetarios se recalculan al cambiarlo.\nCon los mismos niveles, mas volumen implica\nmas ganancia potencial y tambien mas perdida.\nCONFIRMAR o COLOCAR usa ese mismo volumen.\nNo cambia posiciones ni pendientes existentes.\nEs independiente del selector de MetaTrader.\nAl recargar vuelve al valor EvoSimulationLots.";
      StringSplit(content,'\n',lines);
   }
   else if(evoHelpPage==4)
   {
      string content="BARRAS ROC / OBV Y SEMAFORO MACD\nROC: velocidad; numero en porcentaje.\nBarra con cero al centro, escala -3 a +3 ATR.\nVerde: avance positivo. Rojo: negativo.\nOBV: valor acumulado y cambio reciente.\nBarra = cambio / volumen de las mismas velas.\nEscala centrada -100% a +100%; no es liquidez.\nIndica TICKS o REAL segun volumen configurado.\nMACD: numero = histograma, no linea MACD.\nSemaforo verde alcista; rojo bajista.\nAmarillo si es debil respecto al umbral ATR.\nBarra = magnitud del histograma / ATR.\nEscala 0 a 0.20 ATR, saturada por encima.\nNo detecta divergencias ni garantiza una entrada.\nM15, H1 y H4 siguen visibles en Solo decision.\nPasar el mouse muestra el detalle de cada tarjeta.\nEscalas visuales no cambian filtros ni ordenes.";
      StringSplit(content,'\n',lines);
   }
   else if(evoHelpPage==5)
   {
      string content="ESTOCASTICO Y PARABOLIC SAR\nSTOCH(14,3,3): K y D en velas cerradas.\nBarra K 0-100, marcas 20/50/80.\nK >80 sobrecompra; K <20 sobreventa.\nExtremo no significa que deba girar el precio.\nCRUCE K/D compara las dos ultimas velas cerradas.\nPuede haber cruces falsos; no confirma un giro.\nSAR(0.02,0.20): puntos respecto al cierre.\nDEBAJO: sesgo alcista; ENCIMA: sesgo bajista.\nDistancia = (cierre - SAR) / ATR.\nPositiva debajo; negativa encima.\nCAMBIO indica cambio de lado entre dos cierres.\nNo prueba por si solo correccion ni reversion.\nComparar con canal, pivotes y momentum.\nSon contexto: no abren ni modifican SL/TP.\nOTRO DETALLE recorre contexto en graficos bajos.\nM15, H1 y H4 permanecen visibles.";
      StringSplit(content,'\n',lines);
   }
   else
   {
      string content="SIMULADOR NUEVO | DISPONIBLE EN v0.8\n1. Elegir Mercado Buy/Sell o Limit/Stop.\n2. Editar SL y TP en ATR; atajos para SL o TP.\nPendientes: precio exacto; 0 calcula automatico.\nMercado: precio al calcular, revalidado al enviar.\n3. CALCULAR prepara; CONFIRMAR envia la orden.\n4. CARGAR POSICION / PENDIENTE elige un ticket.\nOtra pulsacion recorre los tickets gestionados.\nEditar campos NO modifica el broker.\nACTUALIZAR SL/TP aplica al ticket cargado.\nNo permite alejar un SL existente.\nSL ATR negativo: stop protegido respecto a entrada.\nCERRAR #ticket: unica automatica; varias elegir.\nCANCELAR PENDIENTES: segunda pulsacion antes de 10s.\nSolo cancela simbolo y magic de esta gestion.\nBE/trailing siguen activos tras modificar SL/TP.\nNueva propuesta vuelve a preparar una entrada.";
      StringSplit(content,'\n',lines);
   }
   for(int i=0;i<ArraySize(lines);i++) EvoPanelLine(i+3,lines[i],i==0?clrGold:clrSilver,i==0);
   EvoPanelLine(20,"Anterior / Siguiente | Cerrar o Escape vuelve al tablero",clrAqua);
}
bool EvoHelpEvent(const int id,const long &key,const string name)
{
   if(id==CHARTEVENT_OBJECT_CLICK && name=="EVO_CONTEXT_HELP")
   { evoHelpOpen=true; evoHelpPage=0; ObjectsDeleteAll(0,"EVO_CONTEXT_"); return true; }
   if(!evoHelpOpen) return false;
   if((id==CHARTEVENT_KEYDOWN && key==27) || (id==CHARTEVENT_OBJECT_CLICK && name=="EVO_CONTEXT_HELP_CLOSE"))
   { evoHelpOpen=false; ObjectsDeleteAll(0,"EVO_CONTEXT_"); return true; }
   if(id==CHARTEVENT_OBJECT_CLICK && name=="EVO_CONTEXT_HELP_NEXT") evoHelpPage=(evoHelpPage+1)%7;
   if(id==CHARTEVENT_OBJECT_CLICK && name=="EVO_CONTEXT_HELP_PREV") evoHelpPage=(evoHelpPage+6)%7;
   return id==CHARTEVENT_OBJECT_CLICK || id==CHARTEVENT_KEYDOWN;
}
string EvoDirLabel(const int di)
{
   return di>0?"▲ COMPRA":di<0?"▼ VENTA":"= NEUTRO";
}
#include "IndicatorsPanel.mqh"
#include "PatternsPanel.mqh"

void EvoTacticalPanel(const bool valid,const EvoSnapshot &s)
{
   ObjectDelete(0,"EVO_CONTEXT_CONCLUSION_BG");
   ObjectDelete(0,"EVO_CONTEXT_NEXT");
   if(!valid)
   {
      EvoPanelLine(6,"N/D: esperando indicadores",clrGold);
      EvoPanelLine(7,"Tablero táctico no inventa datos.",clrSilver);
      return;
   }
   EvoLivePanel(2,s);
   EvoPanelLine(5,EvoRecentBreakText(s.evidence),s.evidence.recentBreakSide<0?clrTomato:s.evidence.recentBreakSide>0?clrLimeGreen:clrSilver,true);
   ObjectSetString(0,"EVO_CONTEXT_5",OBJPROP_TOOLTIP,"Busca en los ultimos 8 cierres rupturas del rango de las 24 velas anteriores a cada evento, margen 0.10 ATR. Mantiene el nivel historico aunque la ventana actual absorba la caida. Ruptura no equivale a entrada ni a giro de tendencia amplio.");
   int di=s.plusDI>s.minusDI+1?1:s.minusDI>s.plusDI+1?-1:0;
   bool adxRising=s.deltaValid && s.deltaADX>=0.5;
   bool adxFalling=s.deltaValid && s.deltaADX<=-0.5;
   bool erRising=s.erValid && (s.er-s.erPrevious)>=0.05;
   bool erFalling=s.erValid && (s.er-s.erPrevious)<=-0.05;
   color dirColor=di>0?clrLimeGreen:di<0?clrTomato:clrSilver;
   EvoPanelLine(6,"DI DEL ULTIMO CIERRE "+EvoDirLabel(di)+" | "+s.localRegimeName,dirColor,true);
   EvoPanelLine(7,StringFormat("FUERZA %s %d %s | EFIC %s %d %s",
      EvoScoreBar(s.scoreStrength,EvoScoreBarWidth),s.scoreStrength,EvoScoreArrow(adxRising,adxFalling),
      EvoScoreBar(s.scoreEfficiency,EvoScoreBarWidth),s.scoreEfficiency,EvoScoreArrow(erRising,erFalling)),clrWhite);
   EvoPanelLine(8,StringFormat("CONTINUIDAD %s %d | AGOTAMIENTO %s %d",
      EvoScoreBar(s.scoreContinuation,EvoScoreBarWidth),s.scoreContinuation,
      EvoScoreBar(s.scoreExhaustion,EvoScoreBarWidth),s.scoreExhaustion),
      s.scoreExhaustion>=60?clrTomato:s.scoreContinuation>=60?clrLimeGreen:clrGold);
   EvoPanelLine(9,StringFormat("CALIDAD ENTRADA %s %d | RIESGO %s %d",
      EvoScoreBar(s.scoreEntryQuality,EvoScoreBarWidth),s.scoreEntryQuality,
      EvoScoreBar(s.scoreRisk,EvoScoreBarWidth),s.scoreRisk),
      s.scoreEntryQuality>=60?clrLimeGreen:s.scoreRisk>=60?clrTomato:clrGold);
   EvoPanelLine(10,StringFormat("MTF %d/100 | DI-dom %d/100 | scores no son probabilidad",
      s.scoreMtf,s.scoreDiDominance),clrSilver);
   color mgmtColor=s.managementMode==EVO_MGMT_EXTENSION||s.managementMode==EVO_MGMT_EXTENSION_CAND?clrLimeGreen:
      (s.managementMode==EVO_MGMT_TACTICAL||s.managementMode==EVO_MGMT_TACTICAL_CAND?clrOrange:
       s.managementMode==EVO_MGMT_PROTECTION||s.managementMode==EVO_MGMT_PROTECTION_CAND?clrTomato:
       s.managementMode==EVO_MGMT_WAIT?clrGold:clrSilver);
   EvoPanelLine(11,"GESTION: "+s.managementModeName+(EvoDiagnosticOnly?" | SOLO DIAGNOSTICO":""),mgmtColor,true);
   EvoPanelLine(12,StringFormat("E%d T%d P%d | %s",s.scoreExtension,s.scoreTactical,s.scoreProtection,
      s.managementMode==EVO_MGMT_TACTICAL||s.managementMode==EVO_MGMT_TACTICAL_CAND?"DIRECCION FUERTE PERO RUIDOSA":s.managementModeHint),clrDeepSkyBlue);
   EvoPanelLine(13,"Motivo: "+s.managementReason,clrSilver);
   ObjectSetString(0,"EVO_CONTEXT_13",OBJPROP_TOOLTIP,s.managementReason+"\nTrazable en solapa ANALISIS. No cierra posiciones.");
   string action=s.suggestionAction!=""?s.suggestionAction:EvoSuggestionAction(s.signal,s.needsConfirmation);
   color actColor=s.needsConfirmation?clrGold:s.signal>0?clrLime:s.signal<0?clrSalmon:clrGold;
   EvoPanelLine(14,s.evidence.valid?StringFormat("IMPULSO %s | MACD hist %.3f | ROC %+.2f%%",EvoEvidenceDirection(s.evidence.momentum),s.evidence.hist,s.evidence.roc):"IMPULSO MACD/ROC: N/D",s.evidence.momentum==0?clrGold:clrAqua);
   EvoPanelLine(15,"ACCION: "+action,actColor,true);
   EvoPanelLine(16,s.pendingAction,clrSilver);
   string room=s.roomValid?StringFormat("espacio util %.2f ATR",s.roomATR):(s.biasDirection<0?"soporte/obstaculo N/D en ventana":"resistencia/obstaculo N/D");
   EvoPanelLine(17,"Espacio: "+room+(s.roomValid && s.roomATR<EvoMinRoomATR?" BAJO":""),s.roomValid && s.roomATR<EvoMinRoomATR?clrGold:clrSilver);
   EvoPanelLine(18,StringFormat("ADX %.1f d%+.1f | ER %s | +DI %.0f / -DI %.0f",
      s.adx[s.closedView?0:1],s.deltaValid?s.deltaADX:0.0,s.erValid?DoubleToString(s.er,2):"N/D",s.plusDI,s.minusDI),clrWhite);
   EvoPanelLine(19,"Detalle completo en ANALISIS | snapshot en TESIS | eventos en ALERTAS",clrDimGray);
   EvoPanelLine(20,EvoDiagnosticOnly?"DiagnosticOnly: modos no mueven SL/TP ni cierran.":"DiagnosticOnly OFF — revisar antes de automatizar.",EvoDiagnosticOnly?clrSilver:clrGold);
}
void EvoThesisPanel(const EvoSnapshot &s)
{
#ifdef EVO_ANALYSIS_DASHBOARD_VERSION
   EvoThesisDashboardDraw(s); return;
#endif
   ObjectDelete(0,"EVO_CONTEXT_CONCLUSION_BG");
   int count=evoThesis.Count();
   if(count==0) { ObjectDelete(0,"EVO_CONTEXT_NEXT"); EvoPanelLine(2,EvoTrackThesis?"TESIS: sin posiciones seleccionadas o esperando datos":"TESIS: seguimiento desactivado",clrGold); return; }
   evoThesisIndex=evoThesisIndex%count;
   EvoThesisItem t; if(!evoThesis.Get(evoThesisIndex,t)) return;
   EvoPanelLine(1,"SALUD DE POSICION #"+(string)t.ticket+" | "+(t.base.type==POSITION_TYPE_BUY?"BUY":"SELL")+StringFormat(" | %d/%d",evoThesisIndex+1,count),clrWhite);
   bool fresh=t.evaluated==iTime(_Symbol,PERIOD_CURRENT,1);
   EvoPanelLine(2,!t.compatible?"NO EVALUABLE: volumen aumentado / entrada o direccion cambiada":!fresh?"SIN DATOS CERRADOS ACTUALES":EvoThesisName(t.state)+StringFormat(" | apoyos perdidos %d/%d",t.losses,t.compared),!fresh||!t.compatible?clrGold:t.state>=3?clrTomato:t.state==2?clrGold:clrLimeGreen,true);
   EvoPanelLine(3,"Referencia: "+TimeToString(t.base.captured,TIME_DATE|TIME_SECONDS)+(t.base.captured-t.base.opened>5?" | POSTERIOR A ENTRADA":" | DETECCION DE ENTRADA"),clrSilver);
   EvoPanelLine(4,"Indicador                 REFERENCIA -> AHORA (cerrado)",clrWhite);
   EvoPanelLine(5,StringFormat("ADX: %.2f -> %.2f | diferencia %+.2f",t.base.adx,t.currentADX,t.currentADX-t.base.adx));
   EvoPanelLine(6,(t.base.validMask & 128)!=0?"ER: "+DoubleToString(t.base.er,2)+" -> "+((t.currentMask & 128)!=0?DoubleToString(t.currentER,2):"N/D"):"ER: referencia N/D");
   EvoPanelLine(7,StringFormat("RSI: %.2f -> %.2f",t.base.rsi,t.currentRSI));
   string labels[7]={"DI","EMA50 (posicion precio)","EMA200 (posicion precio)","OBV","M15","H1","H4"};
   for(int i=0;i<7;i++) EvoPanelLine(8+i,labels[i]+": "+((t.base.validMask & (1<<i))!=0?EvoContextBias(t.base.dir[i]):"N/D")+" -> "+(fresh && (t.currentMask & (1<<i))!=0?EvoContextBias(t.nowDir[i]):"N/D"));
   EvoPanelLine(15,StringFormat("MFE %.2f ATR | MAE %.2f ATR | desde primera observacion",t.base.mfe,t.base.mae),clrDeepSkyBlue);
   EvoPanelLine(16,StringFormat("P/L flotante + swap: %.2f %s | sin comisiones",t.pnl,AccountInfoString(ACCOUNT_CURRENCY)));
   string thesisMode=t.managementModeName!=""?t.managementModeName:"N/D";
   color thesisModeColor=t.managementMode==EVO_MGMT_TACTICAL||t.managementMode==EVO_MGMT_TACTICAL_CAND?clrOrange:
      t.managementMode==EVO_MGMT_EXTENSION||t.managementMode==EVO_MGMT_EXTENSION_CAND?clrLimeGreen:
      t.managementMode==EVO_MGMT_PROTECTION||t.managementMode==EVO_MGMT_PROTECTION_CAND?clrTomato:clrSilver;
   EvoPanelLine(17,"GESTION: "+thesisMode+(EvoDiagnosticOnly?" | SOLO DIAGNOSTICO":""),thesisModeColor,true);
   EvoPanelLine(18,"Espacio al obstaculo: "+(t.base.room>=0?DoubleToString(t.base.room,2):"N/D")+" -> "+(t.room>=0?DoubleToString(t.room,2):"N/D")+" ATR (ATR de cada lectura)");
   EvoPanelLine(19,t.saved?"Referencia guardada para este grafico / cuenta / configuracion":"AVISO: referencia no guardada en disco",t.saved?clrSilver:clrGold);
   EvoPanelLine(20,s.evidence.valid?"MACD/ROC: "+EvoEvidencePosition(t.base.type==POSITION_TYPE_BUY?1:-1,s.evidence.momentum)+" | lectura actual, no referencia de entrada":"MACD/ROC: datos cerrados no disponibles",s.evidence.valid && s.evidence.momentum==(t.base.type==POSITION_TYPE_BUY?-1:1)?clrGold:clrSilver);
   EvoPanelLine(21,"INVALIDADA: DI y EMA50 antes a favor, ahora opuestos; >=3 perdidas.");
   EvoPanelLine(22,"Confirmacion: "+(string)EvoThesisConfirmBars+" cierres. Cambiar solapa no reinicia MFE/MAE.");
   EvoPanelLine(24,EvoEvidenceConfirmation(s.evidence),s.evidence.confirmation>=2?clrGold:clrAqua);
   ObjectSetString(0,"EVO_CONTEXT_24",OBJPROP_TOOLTIP,s.evidence.confirmationDetail);
   EvoPanelLine(23,"Proteccion extra en ganancia: "+(EvoThesisProtectProfit?"ACTIVA":"DESACTIVADA"));
   EvoThesisButton("EVO_CONTEXT_NEXT","SIGUIENTE",24);
}

void EvoAlertsPanel(const bool valid,const EvoSnapshot &s)
{
   ObjectDelete(0,"EVO_CONTEXT_CONCLUSION_BG");
   ObjectDelete(0,"EVO_CONTEXT_NEXT");
   EvoPanelLine(2,"CENTRO DE EVENTOS | no es un log de cada tick",clrWhite,true);
   EvoPanelLine(3,"Estado motor: "+evoAlertStatus,EvoAlertsEnabled?clrDeepSkyBlue:clrSilver);
   EvoPanelLine(5,evoAlertLastEvent!=""?"HISTORICO: "+evoAlertLastEvent:"Sin eventos registrados en esta sesion",clrSilver);
   EvoPanelLine(4,EvoAlertsEnabled?"Alertas cerradas + semanticas v0.6 (transiciones).":"Alertas desactivadas.",clrSilver);
   if(!valid) { EvoPanelLine(6,"N/D: sin snapshot para resumir eventos.",clrGold); return; }
   EvoPanelLine(6,"Ultimo resumen semantico:",clrWhite);
   EvoPanelLine(7,evoAlertSemantic!=""?evoAlertSemantic:"(sin transicion reciente)",evoAlertSemantic!=""?clrGold:clrDimGray);
   EvoPanelLine(9,"Familias: OPORTUNIDAD | REGIMEN | GESTION | RIESGO",clrDeepSkyBlue);
   EvoPanelLine(10,StringFormat("Regimen actual: %s | gestion %s",s.localRegimeName,s.managementModeName),clrSilver);
   EvoPanelLine(11,StringFormat("Continuidad %d | Agotamiento %d | Riesgo %d",s.scoreContinuation,s.scoreExhaustion,s.scoreRisk),clrSilver);
   EvoPanelLine(12,"Cooldown: solo cambios significativos de estado (cooldown / vela cerrada).",clrDimGray);
   EvoPanelLine(13,"Detalle de indicadores: solapa ANALISIS. Tesis abierta: solapa TESIS.",clrDimGray);
   ObjectSetString(0,"EVO_CONTEXT_7",OBJPROP_TOOLTIP,evoAlertSemantic!=""?evoAlertSemantic:evoAlertStatus);
}

string EvoSituation(const EvoSnapshot &s)
{
   if(!s.evidence.valid) return "ESCENARIO: SIN DATOS CERRADOS";
   if(s.closedView && !evoPanelDataPending) EvoPatternRead(s.atr[0],s.confirmed.time);
   int broad=s.evidence.broadSide,recent=s.evidence.recentSide;
   bool pattern=evoPatternBar==s.confirmed.time && ((evoPatternHCH.found && evoPatternHCH.state==2 && evoPatternHCH.side==-broad) ||
      (evoPatternDouble.found && evoPatternDouble.state==2 && evoPatternDouble.side==-broad));
   if(broad!=0 && pattern) return "POSIBLE GIRO CONTRA CANAL: FIGURA CON RUPTURA CONFIRMADA";
   if(broad!=0 && s.evidence.recentBreakSide==-broad)
      return "RUPTURA CONTRA CANAL; CORRECCION O GIRO AUN POR DISTINGUIR";
   if(broad!=0 && recent==-broad) return "CORRECCION POSIBLE CONTRA CANAL; FALTA GIRO CONFIRMADO";
   if(s.evidence.recentBreakSide!=0) return EvoRecentBreakText(s.evidence);
   return EvoLayerConfirmation(s.evidence);
}
int EvoLivePanel(const int row,const EvoSnapshot &s)
{
   MqlTick q; MqlRates bars[];
   int copied=CopyRates(_Symbol,PERIOD_CURRENT,0,2,bars);
   double atr=s.atr[s.closedView?0:1];
   if(copied!=2 || !SymbolInfoTick(_Symbol,q) || q.bid<=0 || atr<=0 || q.time<bars[1].time)
   { EvoPanelLine(row,"EN VIVO: DATOS NO DISPONIBLES; no usar lectura anterior",clrGold,true); return 0; }
   double move=q.bid-bars[0].close,body=q.bid-bars[1].open,range=MathMax(bars[1].high,q.bid)-MathMin(bars[1].low,q.bid);
   int direction=EvoLiveDirection(move/atr),strength=EvoLiveStrength(move/atr);
   string force=strength==3?"EXCEPCIONAL":strength==2?"FUERTE":strength==1?"MODERADO":"PEQUENO";
   color ink=direction<0?clrTomato:direction>0?clrLimeGreen:clrSilver;
   EvoPanelLine(row,"AHORA "+(direction<0?"BAJISTA":direction>0?"ALCISTA":"SIN DESPLAZAMIENTO")+" "+force+StringFormat(" | %+.2f ATR desde ultimo cierre",move/atr),ink,true);
   EvoPanelLine(row+1,StringFormat("Precio %.*f | cuerpo %+.2f ATR | rango %.2f ATR | PROVISIONAL",_Digits,q.bid,body/atr,range/atr),ink);
   bool old=s.confirmed.time!=iTime(_Symbol,PERIOD_CURRENT,1);
   string detail=StringFormat("Tick: %s. Vela en formacion desde %s. Desplazamiento desde cierre anterior %.8f. Fuerza describe magnitud/ATR, no ADX ni probabilidad. Umbrales: pequeno <0.25, moderado >=0.25, fuerte >=1, excepcional >=2 ATR. No confirma giro hasta cierre. ATR de referencia %.8f; snapshot %s%s.",TimeToString(q.time,TIME_DATE|TIME_SECONDS),TimeToString(bars[1].time,TIME_DATE|TIME_MINUTES),move,atr,TimeToString(s.confirmed.time,TIME_DATE|TIME_MINUTES),old?" ATR/indicadores atrasados o fijados":"");
   ObjectSetString(0,"EVO_CONTEXT_"+(string)row,OBJPROP_TOOLTIP,detail); ObjectSetString(0,"EVO_CONTEXT_"+(string)(row+1),OBJPROP_TOOLTIP,detail);
   double nearest=DBL_MAX; ulong nearestTicket=0; bool adverse=false;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i); if(ticket==0 || PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      long magic=PositionGetInteger(POSITION_MAGIC); if(InpManageManualOnly?magic!=0:magic!=InpMagicToManage) continue;
      bool buy=PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY; double stop=PositionGetDouble(POSITION_SL);
      if(stop<=0) continue;
      double distance=(buy?q.bid-stop:stop-q.ask)/atr;
      if(distance<nearest) { nearest=distance; nearestTicket=ticket; adverse=direction==(buy?-1:1); }
   }
   string risk=nearestTicket==0?"POSICION: sin SL seleccionado para evaluar margen":StringFormat("#%I64u margen SL %.2f ATR | %s",nearestTicket,nearest,nearest<=0?"PRECIO EN ZONA DEL SL":nearest<=.25?"CERCA DEL SL":adverse?"VELA CONTRARIA A POSICION":"SIN PRESION CONTRARIA ACTUAL");
   EvoPanelLine(row+2,risk,nearestTicket>0 && (nearest<=.25 || adverse)?clrTomato:clrSilver,true);
   ObjectSetString(0,"EVO_CONTEXT_"+(string)(row+2),OBJPROP_TOOLTIP,"Distancia al SL real: Bid para BUY, Ask para SELL. Si hay varias posiciones muestra el margen menor. No predice ejecucion ni cierra ordenes; faltan spread variable y deslizamiento para garantizar un resultado.");
   return direction*strength;
}
#ifdef EVO_ANALYSIS_DASHBOARD_VERSION
#include "AnalysisDashboard.mqh"
#include "ThesisDashboard.mqh"
#endif
#include "PanelTextReports.mqh"
void EvoPanelContext(const bool valid,const EvoSnapshot &s,const bool manual)
{
   if(evoPanelTab==EVO_TAB_PATRONES) { EvoPatternsDraw(valid,s,false); return; }
   if(evoPanelTab==EVO_TAB_INDICADORES) { EvoIndicatorsDraw(valid,s,false); return; }
   double support=0,resistance=0; bool sf=false,rf=false;
   double levelPrice=valid?s.current.close:0;
   if(levelPrice<=0) { MqlTick quote; if(SymbolInfoTick(_Symbol,quote)) levelPrice=quote.bid; }
   if(levelPrice>0) EvoNearestLevels(levelPrice,support,resistance,sf,rf);
   EvoDrawMarketChannel("EVO_CHANNEL_",s.evidence,valid && s.localRegime==EVO_REGIME_LATERAL);
   EvoDrawSRLine("EVO_SR_SUPPORT",support,true,sf);
   EvoDrawSRLine("EVO_SR_RESISTANCE",resistance,false,rf);
#ifdef EVO_ANALYSIS_DASHBOARD_VERSION
   // Refresh chart drawings before the dashboard returns; applies to every symbol.
   if(EvoShowContext && evoPanelTab==EVO_TAB_ANALISIS && !evoPanelMinimized)
   { EvoDashboardDraw(valid,s); return; }
#endif
   if(!EvoShowContext) return;
   int baseRows=evoPanelTab==EVO_TAB_TACTICA?22:(evoPanelTab==EVO_TAB_ALERTAS?15:evoPanelTab==EVO_TAB_ANALISIS?32:26);
   EvoPanelBackground(manual && evoPanelTab==EVO_TAB_TACTICA?MathMax(baseRows,evoMonitorControlRow)+evoPanelExtraRows:baseRows);
   string tf=EnumToString((ENUM_TIMEFRAMES)_Period); StringReplace(tf,"PERIOD_","");
   // Title sits below tab row (row 1); tabs occupy header buttons.
   EvoPanelLine(0,""); // reserved visually under tabs
   EvoPanelLine(1,(manual?"MONITOR":"SF")+" v0.6 | "+_Symbol+" | "+tf+(evoPanelFrozen?" | MERCADO FIJADO":evoPanelDataPending?" | DATOS PENDIENTES (ultima lectura)":(s.closedView?" | cierre "+TimeToString(s.confirmed.time,TIME_MINUTES):" | EN FORMACION")),clrWhite);
   EvoDrawTabs();
   ObjectDelete(0,"EVO_CONTEXT_PAGE");
   if(evoPanelTab==EVO_TAB_TACTICA) { EvoTacticalPanel(valid,s); return; }
   if(evoPanelTab==EVO_TAB_TESIS) { EvoThesisPanel(s); return; }
   if(evoPanelTab==EVO_TAB_ALERTAS) { EvoAlertsPanel(valid,s); return; }
   // ANALISIS — full technical detail preserved
   ObjectDelete(0,"EVO_CONTEXT_NEXT");
   EvoPanelLine(30,valid && s.evidence.valid?StringFormat("MACD h %.3f | ROC %+.2f%% (%+.2f ATR) | ATR %.3f",s.evidence.hist,s.evidence.roc,s.evidence.rocATR,s.atr[s.closedView?0:1]):"ALERTAS: "+evoAlertStatus,clrDeepSkyBlue);
   ObjectSetString(0,"EVO_CONTEXT_30",OBJPROP_TOOLTIP,"MACD(12,26,9): senal EMA9 del original, no SMA9 de MT5. ROC(12) normalizado por ATR. Grupo diagnostico +/-10; no cambia ordenes. Alertas: "+evoAlertStatus);
   if(!valid)
   {
      for(int i=2;i<24;i++) EvoPanelLine(i,i==2?"N/D: esperando indicadores":"");
      EvoFinalSuggestion(false,s);
      return;
   }
   string mobility=s.atr[0]>s.atr[1]*1.01?"CRECIENTE":s.atr[0]<s.atr[1]*0.99?"DECRECIENTE":"ESTABLE";
   int di=s.plusDI>s.minusDI+1?1:s.minusDI>s.plusDI+1?-1:0;
   string direction=di>0?"ALCISTA":di<0?"BAJISTA":"NEUTRA";
   color trendColor=di>0?clrLimeGreen:di<0?clrTomato:clrSilver;
   // Row 1 = version title. Rows 20-21 reserved for EvoFinalSuggestion. Full sensors preserved.
   EvoPanelLine(2,StringFormat("ATR(%d) %.*f | ER(%d) %s",InpATRPeriod,MathMax(3,_Digits),s.atr[s.closedView?0:1],EvoERPeriod,s.erValid?DoubleToString(s.er,2)+" "+(s.er>=.6?"EFICIENTE":s.er>=.3?"INTERMEDIA":"RUIDOSA"):"N/D"),clrAqua,true);
   int liveImpulse=EvoLivePanel(3,s);

   EvoPanelLine(6,EvoLayerBroad(s.evidence),clrAqua);
   EvoPanelLine(7,EvoLayerRecent(s.evidence),s.evidence.recentSide<0?clrSalmon:s.evidence.recentSide>0?clrLimeGreen:clrGold);
   EvoPanelLine(8,EvoSituation(s),s.evidence.recentState==3?clrGold:clrWhite,true);
   for(int layer=6;layer<=8;layer++) ObjectSetString(0,"EVO_CONTEXT_"+(string)layer,OBJPROP_TOOLTIP,s.evidence.layersDetail+StringFormat("\nPara confirmar arriba: dos cierres > %.5f. Abajo: dos cierres < %.5f.",s.evidence.recentHigh+.10*s.atr[s.closedView?0:1],s.evidence.recentLow-.10*s.atr[s.closedView?0:1]));

   ObjectSetString(0,"EVO_CONTEXT_2",OBJPROP_TOOLTIP,"ATR: unidad para las distancias; ultima vela cerrada. Volatilidad "+mobility+". ER: eficiencia del recorrido, no direccion. Detalle y cambio en la linea ER.");
   EvoPanelLine(31,EvoEvidenceConfirmation(s.evidence),s.evidence.confirmation>=2?clrGold:clrAqua);
   ObjectSetString(0,"EVO_CONTEXT_31",OBJPROP_TOOLTIP,s.evidence.confirmationDetail);
   bool adxFalling=s.deltaValid && s.deltaADX<=-0.5;
   string closedDirection=s.closedPlusDI>s.closedMinusDI+1?"ALCISTA":s.closedMinusDI>s.closedPlusDI+1?"BAJISTA":"NEUTRA";
   EvoPanelLine(9,StringFormat("ULTIMO CIERRE: ADX(%d) %.1f | %s | DI %s",InpADXPeriod,s.adx[s.closedView?0:1],s.adxInterpretation,closedDirection)+(s.deltaValid?StringFormat(" | dADX %+.2f",s.deltaADX):""),adxFalling?clrGold:s.adx[s.closedView?0:1]>=25?clrLimeGreen:s.adx[s.closedView?0:1]>=15?clrGold:clrSilver,true);
   string momentum=s.rsi[0]>=70?"SOBRECOMPRA":s.rsi[0]<=30?"SOBREVENTA":s.rsi[0]>55?"IMPULSO ALCISTA":s.rsi[0]<45?"IMPULSO BAJISTA":"NEUTRO";
   EvoPanelLine(10,StringFormat("RSI(%d): %.1f | %s | +DI %.1f / -DI %.1f",InpRSIPeriod,s.rsi[0],momentum,s.plusDI,s.minusDI),s.rsi[0]>=70?clrTomato:s.rsi[0]<=30?clrDeepSkyBlue:s.rsi[0]>55?clrLimeGreen:s.rsi[0]<45?clrOrange:clrSilver,true);
   int ema=s.fast[0]>s.slow[0]?1:s.fast[0]<s.slow[0]?-1:0;
   int previousEMA=s.fast[1]>s.slow[1]?1:s.fast[1]<s.slow[1]?-1:0;
   string emaCross=s.closedView && ema!=0 && previousEMA==-ema?(ema>0?"CRUCE ALCISTA CERRADO":"CRUCE BAJISTA CERRADO"):"SIN CRUCE NUEVO";
   bool weak=ema>0?s.current.close<s.fast[0]:ema<0?s.current.close>s.fast[0]:false;
   string emaTrend=ema>0?"ALCISTA":ema<0?"BAJISTA":"NEUTRA";
   EvoPanelLine(11,StringFormat("EMA %d/%d: %s%s | DI-dom %d | MTF %d",InpEmaFastPeriod,InpEmaSlowPeriod,emaTrend+" | "+emaCross,weak?" DEBIL":"",s.scoreDiDominance,s.scoreMtf),weak?clrSilver:ema>0?clrLimeGreen:ema<0?clrTomato:clrSilver,true);
   string bias=di==1&&ema==1?"COMPRA":di==-1&&ema==-1?"VENTA":di==0&&ema==0?"SIN SESGO":"CONTRADICTORIO";
   if(di!=0 && di==ema) bias+=s.adx[0]>=20?" (confirmado)":" (debil)";
   color regimeColor=EvoLocalRegimeIsConsolidation(s.localRegime)?clrGold:
      (s.localRegime==EVO_REGIME_TENDENCIA_ALCISTA_ACTIVA?clrLimeGreen:
       s.localRegime==EVO_REGIME_TENDENCIA_BAJISTA_ACTIVA?clrTomato:clrSilver);
   EvoPanelLine(12,"REGIMEN LOCAL: "+s.localRegimeName+" | SESGO "+bias,regimeColor,true);
   ObjectSetString(0,"EVO_CONTEXT_12",OBJPROP_TOOLTIP,
      "Clasificacion local independiente del regimen TENDENCIA/LATERAL/MIXTO del asesor.\n"+
      "Usa ADX, dADX, ER, compresion (HH-LL)/ATR y desplazamiento neto/ATR sobre "+(string)EvoRegimeLookback+" velas cerradas.\n"+
      (s.rangeValid?StringFormat("Compresion %.2f ATR | desplazamiento %.2f ATR\n",s.compression,s.displacement):"Rango local N/D\n")+
      "No genera entradas. Con EvoCautionOnConsolidation muestra ESPERAR CONFIRMACION.\n"+
      "El modo de GESTION es una capa aparte: no sustituye al regimen ni abre operaciones.");
   color mgmtColor=s.managementMode==EVO_MGMT_EXTENSION||s.managementMode==EVO_MGMT_EXTENSION_CAND?clrLimeGreen:
      (s.managementMode==EVO_MGMT_TACTICAL||s.managementMode==EVO_MGMT_TACTICAL_CAND?clrOrange:
       s.managementMode==EVO_MGMT_PROTECTION||s.managementMode==EVO_MGMT_PROTECTION_CAND?clrTomato:
       s.managementMode==EVO_MGMT_WAIT?clrGold:clrSilver);
   string mgmtLine="GESTION: "+s.managementModeName;
   if(s.managementMode==EVO_MGMT_TACTICAL||s.managementMode==EVO_MGMT_TACTICAL_CAND) mgmtLine+=" | RUIDOSA";
   if(EvoDiagnosticOnly) mgmtLine+=" | SOLO DIAGNOSTICO";
   EvoPanelLine(13,mgmtLine,mgmtColor,true);
   ObjectSetString(0,"EVO_CONTEXT_13",OBJPROP_TOOLTIP,
      s.managementModeHint+"\nMotivo: "+s.managementReason+"\n"+
      StringFormat("Scores gestion E%d T%d P%d (candidato>=%d commit>=%d)\n",s.scoreExtension,s.scoreTactical,s.scoreProtection,EvoCandidateScoreMin,EvoCommitScoreMin)+
      "Separa el regimen de mercado del estilo de gestion.\n"+
      "Con EvoDiagnosticOnly=true no cierra ni mueve SL/TP por estos modos; solo registra WOULD_*.\n"+
      StringFormat("Umbrales ER tactico < %.2f | extension >= %.2f",EvoTacticalERMax,EvoExtensionERMin));
   EvoPanelLine(14,StringFormat("SCORES F%d E%d C%d A%d ENT%d R%d | gest E%d T%d P%d",
      s.scoreStrength,s.scoreEfficiency,s.scoreContinuation,s.scoreExhaustion,s.scoreEntryQuality,s.scoreRisk,
      s.scoreExtension,s.scoreTactical,s.scoreProtection),clrDeepSkyBlue);
   ObjectSetString(0,"EVO_CONTEXT_14",OBJPROP_TOOLTIP,
      "Scores 0-100 diagnosticos, NO probabilidad calibrada.\n"+s.managementReason+"\nPendiente: "+s.pendingAction);
   bool erFalling=s.erValid && (s.er-s.erPrevious)<=-0.05;
   EvoPanelLine(15,s.erValid?StringFormat("ER(%d): %.2f | %s | cambio %+.2f",EvoERPeriod,s.er,s.erInterpretation,s.er-s.erPrevious)+(EvoUseERFilter?" | FILTRO":" | CONTEXTO"):StringFormat("ATR(%d) %.*f | ER: N/D",InpATRPeriod,MathMax(3,_Digits),s.atr[s.closedView?0:1]),s.erValid?(erFalling?clrGold:s.er>=.6?clrLimeGreen:s.er>=.3?clrGold:clrOrange):clrSilver);
   int ema50Direction=EvoContextDirection(s.confirmed.close,s.ema50),ema200Direction=EvoContextDirection(s.confirmed.close,s.ema200);
   EvoPanelLine(16,"EMA50: "+(s.ema50Valid?DoubleToString(s.ema50,_Digits)+" "+EvoContextBias(ema50Direction):"N/D")+" | "+EvoContextRelation(s.ema50Valid,ema50Direction,s.signal)+" | CONTEXTO",!s.ema50Valid?clrSilver:ema50Direction>0?clrLimeGreen:ema50Direction<0?clrTomato:clrSilver);
   EvoPanelLine(17,"EMA200: "+(s.ema200Valid?DoubleToString(s.ema200,_Digits)+" "+EvoContextBias(ema200Direction):"N/D")+" | "+EvoContextRelation(s.ema200Valid,ema200Direction,s.signal)+" | CONTEXTO",!s.ema200Valid?clrSilver:ema200Direction>0?clrLimeGreen:ema200Direction<0?clrTomato:clrSilver);
   ObjectSetString(0,"EVO_CONTEXT_15",OBJPROP_TOOLTIP,"ATR: unidad para distancias, ultima vela cerrada. ER cambio "+DoubleToString(s.er-s.erPrevious,2)+". ER sin direccion: mide eficiencia, no compra/venta. Filtro activo exige minimo ER; contexto no bloquea entradas. ER bajo con ADX/DI fuertes sugiere CAPTURA TACTICA, no solo ESPERAR. Comparacion a "+(string)EvoDeltaBars+" velas.");
   ObjectSetString(0,"EVO_CONTEXT_16",OBJPROP_TOOLTIP,"EMA50: "+(s.ema50Valid?DoubleToString(s.ema50,_Digits):"N/D")+". Sesgo por cierre encima/debajo de la media, no por pendiente. No filtra entradas.");
   ObjectSetString(0,"EVO_CONTEXT_17",OBJPROP_TOOLTIP,"EMA200: "+(s.ema200Valid?DoubleToString(s.ema200,_Digits):"N/D")+". Sesgo por cierre encima/debajo de la media, no por pendiente. No filtra entradas.");

   EvoPanelLine(18,support>0?"SOPORTE CERCANO: "+DoubleToString(support,_Digits)+StringFormat(" | -%.2f ATR%s",(s.current.close-support)/s.atr[0],sf?" (extremo)":" (pivote)"):"SOPORTE CERCANO: no encontrado en ventana",clrDeepSkyBlue);
   string roomText=s.roomValid?StringFormat(" | espacio util %.2f ATR%s",s.roomATR,s.roomATR<EvoMinRoomATR?" BAJO":""):"";
   EvoPanelLine(19,resistance>0?"RESISTENCIA CERCANA: "+DoubleToString(resistance,_Digits)+StringFormat(" | +%.2f ATR%s",(resistance-s.current.close)/s.atr[0],rf?" (extremo)":" (pivote)")+roomText:"RESISTENCIA CERCANA: no encontrada en ventana"+roomText,s.roomValid && s.roomATR<EvoMinRoomATR?clrGold:clrTomato);
   int idx=InpRequireCandleConfirmation?1:0;
   double close=InpRequireCandleConfirmation?s.confirmed.close:s.current.close;
   string reading=close>s.resistance[idx]?"ruptura alcista":close<s.support[idx]?"ruptura bajista":"dentro del canal";
   // Rows 20-21 reserved for final suggestion strip.
   EvoFinalSuggestion(true,s);
   if(MathAbs(liveImpulse)>=2 && (s.signal==0 || (liveImpulse>0?1:-1)!=s.signal))
   {
      EvoPanelLine(20,"ALERTA EN VIVO: "+(liveImpulse<0?"CAIDA":"SUBIDA")+" FUERTE | revisar antes de decidir",liveImpulse<0?clrTomato:clrLimeGreen,true);
      EvoPanelLine(21,"Movimiento provisional contradice/no confirma el resumen cerrado.",clrGold);
      ObjectSetString(0,"EVO_CONTEXT_20",OBJPROP_TOOLTIP,"No es una orden de entrada/salida. Contexto cerrado: "+s.suggestionAction+" | "+s.reason);
   }
   ObjectSetString(0,"EVO_CONTEXT_19",OBJPROP_TOOLTIP,
      "SMA("+IntegerToString(InpSupportResistancePeriod)+") "+DoubleToString(s.support[idx],_Digits)+" / "+DoubleToString(s.resistance[idx],_Digits)+
      " | "+reading+" | "+s.pendingAction+"\n"+
      (InpRequireCandleConfirmation?"Precio y niveles: ultima vela cerrada.":"Precio y niveles: vela en formacion."));
   string srInfo=StringFormat("S/R %s | %d velas | pivotes %d | precio %.*f",tf,InpMonitorSRLookback,InpMonitorSRPivotBars,_Digits,s.current.close);
   ObjectSetString(0,"EVO_CONTEXT_18",OBJPROP_TOOLTIP,srInfo+". CONTEXTO: posible zona de apoyo o freno a una caida; no confirma compra por si sola. No es el nivel SMA de entrada.");
   // resistance tooltip already set via EVO_CONTEXT_13 above for room/levels composite.
   if(!s.bbValid)
   {
      EvoPanelLine(22,"BOLLINGER: N/D (esperando historial)",clrSilver);
      EvoPanelLine(23,"Bollinger: "+(EvoUseBBFilter?"FILTRO ACTIVO":"SOLO CONTEXTO"));
      EvoPanelLine(24,"");
   }
   else
   {
      double width=s.bbUpper-s.bbLower,oldWidth=s.bbPreviousUpper-s.bbPreviousLower;
      string zone=close>s.bbUpper?"FUERA POR ARRIBA":close<s.bbLower?"FUERA POR ABAJO":close>=s.bbMiddle?"MITAD SUPERIOR":"MITAD INFERIOR";
      string expansion=!s.bbPreviousValid?"N/D":width>oldWidth*1.01?"EXPANSION":width<oldWidth*.99?"CONTRACCION":"ESTABLE";
      EvoPanelLine(22,"BB("+(string)EvoBBPeriod+","+DoubleToString(EvoBBDeviation,1)+") inf/med/sup: "+DoubleToString(s.bbLower,_Digits)+" / "+DoubleToString(s.bbMiddle,_Digits)+" / "+DoubleToString(s.bbUpper,_Digits),clrDeepSkyBlue);
      EvoPanelLine(23,width>0?"BB: "+(close>s.bbMiddle?"SESGO ALCISTA":close<s.bbMiddle?"SESGO BAJISTA":"NEUTRAL")+" | "+EvoBBRelation(s):"BB: SIN AMPLITUD | NO CONFIRMA",width<=0?clrSilver:close>=s.bbMiddle?clrLimeGreen:clrTomato);
      EvoPanelLine(24,"Canal "+expansion+" | "+(EvoUseBBFilter?"FILTRO ACTIVO":"SOLO CONTEXTO")+" | "+(InpRequireCandleConfirmation?"vela cerrada":"en vivo"),expansion=="EXPANSION"?clrLimeGreen:expansion=="CONTRACCION"?clrGold:clrSilver);
      string bbInfo="Zona: "+zone+". Sesgo por precio respecto a la central; no es una orden. La confirmacion considera el regimen: en lateral se evalua extension hacia bandas externas.\nBandas sobre cierres; central=SMA, externas=desviaciones configuradas. %B: 0 inferior, 1 superior; puede salir de [0,1].\n"+
                    "Expansion/contraccion compara ancho con la vela anterior (+/-1%). No clasifica squeeze historico ni indica giro por si sola.\n"+
                    "En tendencia, tocar o superar una banda puede ser continuidad. En rango puede aportar contexto de extension; requiere confirmacion.\n"+
                    "Filtro opcional: TENDENCIA BUY sobre central / SELL bajo central; LATERAL BUY en/bajo inferior / SELL en/sobre superior. No crea entradas por si solo.";
      if(width>0) bbInfo+=StringFormat("\n%%B %.2f",(close-s.bbLower)/width);
      bbInfo+="\nAncho en precio: "+DoubleToString(width,_Digits);
      if(MathAbs(s.bbMiddle)>0) bbInfo+=StringFormat(" | ancho relativo %.2f%%",100*width/MathAbs(s.bbMiddle));
      ObjectSetString(0,"EVO_CONTEXT_23",OBJPROP_TOOLTIP,bbInfo);
      ObjectSetString(0,"EVO_CONTEXT_24",OBJPROP_TOOLTIP,bbInfo);
   }
   string volumeType=EvoOBVVolume==VOLUME_REAL?"REAL":"TICKS";
   string obvMode=EvoUseOBVFilter?"FILTRO ACTIVO":"CONTEXTO";
   if(!s.obvValid)
   {
      EvoPanelLine(25,"OBV "+volumeType+": N/D | sin historial o volumen disponible",clrSilver);
      EvoPanelLine(26,"OBV: "+obvMode+" | velas cerradas",clrSilver,true);
   }
   else
   {
      string obvDirection=s.obvDelta>0?"SUBE (ALCISTA)":s.obvDelta<0?"BAJA (BAJISTA)":"PLANO (NEUTRAL)";
      bool aligned=(s.obvDelta>0 && s.obvPriceDelta>0) || (s.obvDelta<0 && s.obvPriceDelta<0);
      bool opposed=(s.obvDelta>0 && s.obvPriceDelta<0) || (s.obvDelta<0 && s.obvPriceDelta>0);
      string interpretation=aligned?"ACOMPANA AL PRECIO":opposed?"OPUESTO AL PRECIO":"SIN CONFIRMACION DIRECCIONAL";
      EvoPanelLine(25,StringFormat("OBV %s: %.0f | %s | cambio(%d) %+.0f",volumeType,s.obv,obvDirection,EvoOBVLookback,s.obvDelta),s.obvDelta>0?clrLimeGreen:s.obvDelta<0?clrTomato:clrSilver);
      EvoPanelLine(26,EvoContextRelation(true,EvoContextDirection(s.obvDelta,0),s.signal)+" | "+obvMode,aligned?clrLimeGreen:opposed?clrGold:clrSilver,true);
   }
   string obvInfo="OBV nativo acumulado; el signo del valor absoluto no indica compra/venta. Fuente: "+volumeType+
      ". "+(s.obvValid?((s.obvDelta*s.obvPriceDelta>0)?"ACOMPANA AL PRECIO":(s.obvDelta*s.obvPriceDelta<0)?"OPUESTO AL PRECIO":"SIN CONFIRMACION DIRECCIONAL"):"SIN DATOS")+". Comparacion de la ultima vela cerrada con "+(string)EvoOBVLookback+" velas atras.\n"+
      "Precio y OBV se comparan en la misma ventana cerrada. Opuesto al precio no equivale a divergencia de pivotes confirmada.\n"+
      "Filtro opcional: BUY requiere cambio OBV positivo, SELL negativo. Plano o sin datos no confirma. No genera senales por si solo.";
   ObjectSetString(0,"EVO_CONTEXT_25",OBJPROP_TOOLTIP,obvInfo);
   ObjectSetString(0,"EVO_CONTEXT_26",OBJPROP_TOOLTIP,obvInfo);

   bool complete=s.mtf[0].valid && s.mtf[1].valid && s.mtf[2].valid;
   bool up=false,down=false;
   for(int i=0;i<3;i++) { if(s.mtf[i].valid && s.mtf[i].direction>0) up=true; if(s.mtf[i].valid && s.mtf[i].direction<0) down=true; }
   bool aligned=complete && s.mtf[0].direction!=0 && s.mtf[0].direction==s.mtf[1].direction && s.mtf[1].direction==s.mtf[2].direction;
   string alignment=!complete?"SIN DATOS COMPLETOS":up&&down?"EN CONFLICTO":aligned?"DIRECCIONES ALINEADAS":"SIN ALINEACION DIRECCIONAL";
   string frameNames[3]={"M15","H1","H4"};
   for(int i=0;i<3;i++) EvoPanelLine(27+i,EvoFrameText(frameNames[i],s.mtf[i])+" | "+EvoContextRelation(s.mtf[i].valid,s.mtf[i].direction,s.signal)+" | CONTEXTO",
      !s.mtf[i].valid?clrSilver:s.mtf[i].direction>0?clrLimeGreen:s.mtf[i].direction<0?clrTomato:clrSilver);
   string mtfInfo=alignment+"\nContexto cerrado independiente del timeframe del grafico. Criterios EMA/ADX/ATR del asesor; media ATR de 10 cierres.\n"+
      "La direccion EMA se muestra incluso en lateral o mixto. Direcciones alineadas no implica tres regimenes de tendencia. No es filtro de entrada.\n"+
      "El panel principal conserva la convencion original de datos en formacion; puede diferir del contexto cerrado M15.";
   for(int i=27;i<=29;i++) ObjectSetString(0,"EVO_CONTEXT_"+(string)i,OBJPROP_TOOLTIP,mtfInfo);
}
#endif
