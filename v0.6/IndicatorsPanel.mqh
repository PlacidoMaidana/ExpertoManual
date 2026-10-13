#ifndef EVO_INDICATORS_PANEL
#define EVO_INDICATORS_PANEL
// Presentation-only view. Existing ANALISIS and the trading evaluator are retained.
int evoIndicatorsPage=0;
bool evoIndicatorsEffectiveCompact=false;
bool evoIndicatorsCompact=false,evoIndicatorsMTF=true,evoIndicatorsMomentum=true;
bool evoIndicatorsFramesReady=false;
CEvoMultiTimeframe evoIndicatorsFrames;
EvoFrameContext evoIndicatorsFrameValues[6];
datetime evoIndicatorsFrameBars[6];
void EvoIndicatorsRelease()
{
   evoIndicatorsFrames.Release(); evoIndicatorsFramesReady=false;
   for(int i=0;i<6;i++) { evoIndicatorsFrameBars[i]=0; ZeroMemory(evoIndicatorsFrameValues[i]); }
}
bool EvoIndicatorsEvent(const string name)
{
   if(evoPanelTab!=EVO_TAB_INDICADORES) return false;
   if(name=="EVO_CONTEXT_IND_PREV") evoIndicatorsPage--;
   else if(name=="EVO_CONTEXT_IND_NEXT") evoIndicatorsPage++;
   else if(name=="EVO_CONTEXT_IND_COMPACT") { evoIndicatorsCompact=!evoIndicatorsCompact; evoIndicatorsPage=0; }
   else if(name=="EVO_CONTEXT_IND_MTF") { evoIndicatorsMTF=!evoIndicatorsMTF; evoIndicatorsPage=0; }
   else if(name=="EVO_CONTEXT_IND_MOM") { evoIndicatorsMomentum=!evoIndicatorsMomentum; evoIndicatorsPage=0; }
   else return false;
   ObjectSetInteger(0,name,OBJPROP_STATE,false); return true;
}
// Reserve space for the existing manual-risk and management controls below the grid.
int EvoIndicatorsGroupsPerPage(const int chartHeight,const bool detailedRisk,const bool compact)
{
   int groupRows=compact?3:4;
   int reserved=5+(detailedRisk?7:3)+evoPanelExtraRows+1;
   int pitch=18; // Same minimum as EvoPanelPitch: pagination leaves room for controls.
   return MathMax(2,MathMin(7,(chartHeight-24-reserved*pitch)/(groupRows*pitch)));
}
int EvoIndicatorsRiskRow(const bool detailedRisk)
{
   int chartHeight=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS);
   int minimumExpandedRows=5+8+1+(detailedRisk?7:3)+evoPanelExtraRows;
   evoIndicatorsEffectiveCompact=evoIndicatorsCompact || chartHeight<20+minimumExpandedRows*18;
   int groups=4+(evoIndicatorsMTF?2:0)+(evoIndicatorsMomentum?1:0);
   int shown=MathMin(groups,EvoIndicatorsGroupsPerPage((int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS),detailedRisk,evoIndicatorsEffectiveCompact));
   return 5+shown*(evoIndicatorsEffectiveCompact?3:4)+1;
}
int EvoIndicatorsPageGroup(const int item,const int bodyShown,const int page)
{ return item==0?0:1+page*bodyShown+item-1; }
string EvoIndicatorsClip(const string text,const int chars)
{ return StringLen(text)<=chars?text:StringSubstr(text,0,MathMax(1,chars-3))+"..."; }
color EvoIndicatorsInk(const int direction)
{ return direction>0?clrLimeGreen:direction<0?clrSalmon:clrSilver; }
void EvoIndicatorsText(const string name,const int x,const int y,const int width,const string text,
                       const color ink,const int font,const bool bold,const string tooltip)
{
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,font); ObjectSetInteger(0,name,OBJPROP_COLOR,ink);
   ObjectSetInteger(0,name,OBJPROP_BACK,false); ObjectSetInteger(0,name,OBJPROP_ZORDER,25);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetString(0,name,OBJPROP_FONT,bold?"Consolas Bold":"Consolas");
   int chars=MathMax(5,(int)(width/MathMax(5.0,font*0.85)));
   ObjectSetString(0,name,OBJPROP_TEXT,EvoIndicatorsClip(text,chars));
   ObjectSetString(0,name,OBJPROP_TOOLTIP,tooltip);
}
void EvoIndicatorsCell(const int row,const int column,const string title,const string value,
                       const string state,const string note,const color ink,const bool priority=false)
{
   int pitch=EvoPanelPitch(),colWidth=(EvoPanelWidth()-28)/3;
   int x=evoPanelX+10+column*(colWidth+4),y=evoPanelY+10+row*pitch;
   int height=(evoIndicatorsEffectiveCompact?3:4)*pitch-4;
   string key="EVO_CONTEXT_MATRIX_"+(string)row+"_"+(string)column;
   ObjectCreate(0,key,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,key,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,key,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,key,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,key,OBJPROP_XSIZE,colWidth); ObjectSetInteger(0,key,OBJPROP_YSIZE,height);
   ObjectSetInteger(0,key,OBJPROP_BGCOLOR,priority?C'31,48,58':C'24,30,36');
   ObjectSetInteger(0,key,OBJPROP_BORDER_COLOR,C'55,65,75');
   ObjectSetInteger(0,key,OBJPROP_BACK,false); ObjectSetInteger(0,key,OBJPROP_ZORDER,2);
   ObjectSetInteger(0,key,OBJPROP_SELECTABLE,false);
   string detail=title+"\n"+value+"\n"+state+"\n"+note;
   ObjectSetString(0,key,OBJPROP_TOOLTIP,detail);
   int font=MathMax(7,MathMin(EvoPanelFont,10)),valueFont=priority?MathMin(12,font+1):font;
   EvoIndicatorsText(key+"_T",x+6,y+2,colWidth-12,title,clrSilver,font,false,detail);
   EvoIndicatorsText(key+"_V",x+6,y+pitch,colWidth-12,value,clrWhite,valueFont,true,detail);
   EvoIndicatorsText(key+"_S",x+6,y+2*pitch,colWidth-12,state,ink,font,false,detail);
   if(!evoIndicatorsEffectiveCompact) EvoIndicatorsText(key+"_N",x+6,y+3*pitch,colWidth-12,note,clrSilver,MathMax(7,font-1),false,detail);
}
void EvoIndicatorsButton(const string name,const string text,const int slot)
{
   int width=(EvoPanelWidth()-24)/5;
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,evoPanelX+12+slot*width);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,evoPanelY+10+3*EvoPanelPitch());
   ObjectSetInteger(0,name,OBJPROP_XSIZE,width-3); ObjectSetInteger(0,name,OBJPROP_YSIZE,EvoPanelPitch()-2);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8); ObjectSetInteger(0,name,OBJPROP_BGCOLOR,C'35,60,80');
   ObjectSetInteger(0,name,OBJPROP_COLOR,clrWhite); ObjectSetInteger(0,name,OBJPROP_ZORDER,30);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false); ObjectSetString(0,name,OBJPROP_TEXT,text);
}
void EvoIndicatorsUpdateFrames()
{
   if(evoPanelFrozen) return;
   if(!evoIndicatorsFramesReady) { evoIndicatorsFrames.Init(_Symbol,true); evoIndicatorsFramesReady=true; }
   ENUM_TIMEFRAMES frames[]={PERIOD_M15,PERIOD_H1,PERIOD_H4,PERIOD_M5,PERIOD_M30,PERIOD_D1};
   for(int i=0;i<6;i++)
   {
      datetime bar=iTime(_Symbol,frames[i],1);
      if(bar<=0 || (bar==evoIndicatorsFrameBars[i] && evoIndicatorsFrameValues[i].valid)) continue;
      EvoFrameContext value; evoIndicatorsFrames.Update(i,value);
      if(iTime(_Symbol,frames[i],1)!=bar) ZeroMemory(value);
      evoIndicatorsFrameValues[i]=value; evoIndicatorsFrameBars[i]=bar;
   }
}
void EvoIndicatorsFrameCell(const int row,const int col,const string title,const int index)
{
   EvoFrameContext f=evoIndicatorsFrameValues[index];
   EvoIndicatorsCell(row,col,title,f.valid?f.regime:"N/D",f.valid?EvoEvidenceDirection(f.direction):"Cargando historial",
      f.valid?StringFormat("ADX %.1f | %s",f.adx,TimeToString(evoIndicatorsFrameBars[index],TIME_MINUTES)):"Sin datos: no se inventa sesgo",EvoIndicatorsInk(f.direction));
}
void EvoIndicatorsDraw(const bool valid,const EvoSnapshot &s,const bool manual)
{
   ObjectDelete(0,"EVO_CONTEXT_CONCLUSION_BG"); ObjectDelete(0,"EVO_CONTEXT_NEXT");
   ObjectDelete(0,"EVO_CONTEXT_PAGE");
   EvoPanelBackground(manual?evoMonitorControlRow+evoPanelExtraRows:evoRiskStart);
   EvoDrawTabs();
   EvoPanelLine(1,"INDICADORES | "+_Symbol+" | "+EnumToString(_Period)+(evoPanelFrozen?" | FIJADO":" | cierres"),clrWhite);
   EvoIndicatorsButton("EVO_CONTEXT_IND_PREV","< ANTERIOR",0);
   EvoIndicatorsButton("EVO_CONTEXT_IND_NEXT","SIGUIENTE >",1);
   EvoIndicatorsButton("EVO_CONTEXT_IND_COMPACT",evoIndicatorsCompact?"EXPANDIR":evoIndicatorsEffectiveCompact?"AUTO COMPACTO":"COMPACTAR",2);
   EvoIndicatorsButton("EVO_CONTEXT_IND_MTF",evoIndicatorsMTF?"MTF ON":"MTF OFF",3);
   EvoIndicatorsButton("EVO_CONTEXT_IND_MOM",evoIndicatorsMomentum?"MOM ON":"MOM OFF",4);
   if(!valid) { EvoPanelLine(2,"N/D: esperando lectura de indicadores",clrGold); return; }
   if(evoIndicatorsMTF) EvoIndicatorsUpdateFrames();
   int groups[7],count=0;
   for(int i=0;i<4;i++) groups[count++]=i;
   if(evoIndicatorsMTF) { groups[count++]=4; groups[count++]=5; }
   if(evoIndicatorsMomentum) groups[count++]=6;
   int groupRows=evoIndicatorsEffectiveCompact?3:4;
   int shown=MathMax(1,MathMin(count,(evoRiskStart-6)/groupRows));
   int bodyShown=MathMax(1,shown-1);
   int pages=(count-1+bodyShown-1)/bodyShown;
   evoIndicatorsPage=MathMax(0,MathMin(evoIndicatorsPage,pages-1));
   EvoPanelLine(2,"AMPLIO "+EvoEvidenceDirection(s.evidence.broadSide)+" | RECIENTE "+EvoEvidenceDirection(s.evidence.recentSide),s.evidence.broadSide!=s.evidence.recentSide?clrGold:clrAqua);
   ObjectSetString(0,"EVO_CONTEXT_2",OBJPROP_TOOLTIP,EvoLayerBroad(s.evidence)+"\n"+EvoLayerRecent(s.evidence)+"\n"+EvoLayerConfirmation(s.evidence)+"\n"+s.evidence.layersDetail);
   string action=s.suggestionAction!=""?s.suggestionAction:"SIN SETUP";
   EvoPanelLine(4,StringFormat("Pagina %d/%d | ",evoIndicatorsPage+1,pages)+EvoIndicatorsClip(action,65),clrGold);
   ObjectSetString(0,"EVO_CONTEXT_4",OBJPROP_TOOLTIP,action+"\nRegimen: "+s.localRegimeName+"\nCalidad de entrada "+(string)s.scoreEntryQuality+"/100 (diagnostico, no probabilidad).");
   int idx=s.closedView?0:1;
   double atr=s.atr[idx],price=s.confirmed.close;
   double support=0,resistance=0; bool sf=false,rf=false;
   EvoNearestLevels(price,support,resistance,sf,rf);
   EvoDrawMarketChannel("EVO_CHANNEL_",s.evidence,s.localRegime==EVO_REGIME_LATERAL);
   EvoDrawSRLine("EVO_SR_SUPPORT",support,true,sf); EvoDrawSRLine("EVO_SR_RESISTANCE",resistance,false,rf);
   int di=EvoEvidenceSign(s.closedPlusDI-s.closedMinusDI,1);
   int ema=EvoEvidenceSign(s.fast[idx]-s.slow[idx],0);
   for(int item=0;item<shown;item++)
   {
      int at=EvoIndicatorsPageGroup(item,bodyShown,evoIndicatorsPage); if(at>=count) break;
      int row=5+item*groupRows,group=groups[at];
      if(group==0)
      {
         EvoIndicatorsCell(row,0,"ATR("+(string)InpATRPeriod+")",DoubleToString(atr,MathMax(3,_Digits)),"UNIDAD DE DISTANCIA","Volatilidad; no indica direccion",clrAqua,true);
         EvoIndicatorsCell(row,1,"ER("+(string)EvoERPeriod+")",s.erValid?DoubleToString(s.er,2):"N/D",s.erValid?s.erInterpretation:"Historial insuficiente",s.erValid?StringFormat("Cambio %+.2f",s.er-s.erPrevious):"Eficiencia, no direccion",s.erValid && s.er>=.6?clrLimeGreen:clrGold,true);
         string regime=s.localRegime==EVO_REGIME_TRANSICION?"TRANSICION":s.localRegime==EVO_REGIME_LATERAL?"LATERAL":s.localRegime==EVO_REGIME_INDETERMINADO?"INDETERMINADO":"DIRECCIONAL";
         EvoIndicatorsCell(row,2,"REGIMEN",regime,s.localRegimeName,"Calidad setup "+(string)s.scoreEntryQuality+"/100",s.needsConfirmation?clrGold:EvoIndicatorsInk(s.biasDirection));
      }
      if(group==1)
      {
         EvoIndicatorsCell(row,0,"ADX("+(string)InpADXPeriod+")",DoubleToString(s.adx[idx],1),s.adxInterpretation,"DI: "+EvoEvidenceDirection(di)+StringFormat(" | dADX %+.2f",s.deltaADX),s.deltaValid && s.deltaADX<0?clrGold:clrAqua);
         EvoIndicatorsCell(row,1,"RSI("+(string)InpRSIPeriod+")",DoubleToString(s.rsi[idx],1),s.rsi[idx]>55?"IMPULSO ALCISTA":s.rsi[idx]<45?"IMPULSO BAJISTA":"NEUTRO",StringFormat("+DI %.1f / -DI %.1f",s.closedPlusDI,s.closedMinusDI),EvoIndicatorsInk(EvoEvidenceSign(s.rsi[idx]-50,5)));
         EvoIndicatorsCell(row,2,"BB("+(string)EvoBBPeriod+","+DoubleToString(EvoBBDeviation,1)+") "+(s.bbValid?EvoEvidenceDirection(EvoEvidenceSign(price-s.bbMiddle,0)):"N/D"),s.bbValid?"Inf "+DoubleToString(s.bbLower,_Digits):"N/D",s.bbValid?"Med "+DoubleToString(s.bbMiddle,_Digits):"Sin datos",s.bbValid?"Sup "+DoubleToString(s.bbUpper,_Digits):"Esperando historial",s.bbValid?EvoIndicatorsInk(EvoEvidenceSign(price-s.bbMiddle,0)):clrSilver);
      }
      if(group==2)
      {
         EvoIndicatorsCell(row,0,"SOPORTE CERCANO",support>0?DoubleToString(support,_Digits):"N/D",support>0?StringFormat("-%.2f ATR",(price-support)/atr):"Sin nivel confirmado",sf?"Extremo de respaldo":"Pivote confirmado",clrDeepSkyBlue);
         EvoIndicatorsCell(row,1,"RESISTENCIA CERCANA",resistance>0?DoubleToString(resistance,_Digits):"N/D",resistance>0?StringFormat("+%.2f ATR",(resistance-price)/atr):"Sin nivel confirmado",rf?"Extremo de respaldo":"Pivote confirmado",clrSalmon);
         EvoIndicatorsCell(row,2,"ESPACIO UTIL",s.roomValid?DoubleToString(s.roomATR,2)+" ATR":"N/D",s.roomValid && s.roomATR<EvoMinRoomATR?"ESPACIO BAJO":"HASTA OBSTACULO",s.roomValid?"Direccion "+EvoEvidenceDirection(s.signal!=0?s.signal:s.biasDirection):"Falta obstaculo en esa direccion",s.roomValid && s.roomATR<EvoMinRoomATR?clrGold:clrSilver);
      }
      if(group==3)
      {
         EvoIndicatorsCell(row,0,"EMA "+(string)InpEmaFastPeriod+"/"+(string)InpEmaSlowPeriod,EvoEvidenceDirection(ema),StringFormat("DI-dom %d | MTF %d",s.scoreDiDominance,s.scoreMtf),"Contexto; no abre posiciones",EvoIndicatorsInk(ema));
         int e50=s.ema50Valid?EvoEvidenceSign(price-s.ema50,0):0,e200=s.ema200Valid?EvoEvidenceSign(price-s.ema200,0):0;
         EvoIndicatorsCell(row,1,"EMA50",s.ema50Valid?DoubleToString(s.ema50,_Digits):"N/D",EvoEvidenceDirection(e50),s.ema50Valid?StringFormat("Precio a %+.2f ATR",(price-s.ema50)/atr):"Esperando historial",EvoIndicatorsInk(e50));
         EvoIndicatorsCell(row,2,"EMA200",s.ema200Valid?DoubleToString(s.ema200,_Digits):"N/D",EvoEvidenceDirection(e200),s.ema200Valid?StringFormat("Precio a %+.2f ATR",(price-s.ema200)/atr):"Esperando historial",EvoIndicatorsInk(e200));
      }
      if(group==4) { EvoIndicatorsFrameCell(row,0,"M5",3); EvoIndicatorsFrameCell(row,1,"M15",0); EvoIndicatorsFrameCell(row,2,"M30",4); }
      if(group==5) { EvoIndicatorsFrameCell(row,0,"H1",1); EvoIndicatorsFrameCell(row,1,"H4",2); EvoIndicatorsFrameCell(row,2,"D1",5); }
      if(group==6)
      {
         EvoIndicatorsCell(row,0,"MACD 12/26/9",s.evidence.valid?"h "+DoubleToString(s.evidence.hist,3):"N/D",s.evidence.valid?EvoEvidenceDirection(EvoEvidenceSign(s.evidence.hist/atr,EvoMomentumMinHistATR)):"Sin datos","Senal EMA9; detalle en ANALISIS",EvoIndicatorsInk(s.evidence.valid?EvoEvidenceSign(s.evidence.hist,0):0));
         EvoIndicatorsCell(row,1,"ROC(12)",s.evidence.valid?StringFormat("%+.2f%%",s.evidence.roc):"N/D",s.evidence.valid?StringFormat("%+.2f ATR",s.evidence.rocATR):"Sin datos",s.evidence.valid?EvoEvidenceDirection(EvoEvidenceSign(s.evidence.rocATR,EvoMomentumMinMoveATR)):"Velas cerradas",EvoIndicatorsInk(s.evidence.valid?EvoEvidenceSign(s.evidence.rocATR,EvoMomentumMinMoveATR):0));
         EvoIndicatorsCell(row,2,"OBV "+(EvoOBVVolume==VOLUME_REAL?"REAL":"TICKS"),s.obvValid?DoubleToString(s.obv,0):"N/D",s.obvValid?EvoEvidenceDirection(EvoEvidenceSign(s.obvDelta,0)):"Sin datos de volumen",s.obvValid?StringFormat("Cambio(%d) %+.0f",EvoOBVLookback,s.obvDelta):"No se sustituye el tipo de volumen",EvoIndicatorsInk(s.obvValid?EvoEvidenceSign(s.obvDelta,0):0));
      }
   }
}
#endif
