#ifndef EVO_ANALYSIS_DASHBOARD
#define EVO_ANALYSIS_DASHBOARD
bool evoDecisionOnly=false;
int evoDashboardDetailsPage=0;
double EvoDashboardFraction(const double value,const double ceiling)
{ return ceiling>0?MathMax(0.0,MathMin(1.0,value/ceiling)):0; }
int EvoDashboardCross(const double current,const double signal,const double previous,const double previousSignal)
{ return current>signal && previous<=previousSignal?1:current<signal && previous>=previousSignal?-1:0; }
int EvoDashboardSARSide(const double close,const double sar)
{ return close>sar?1:close<sar?-1:0; }
string EvoDashboardRSIEvent(const double current,const double previous)
{
   if(previous<=30 && current>30) return "SALE DE SOBREVENTA";
   if(previous>=70 && current<70) return "SALE DE SOBRECOMPRA";
   if(previous<=50 && current>50) return "CRUZA 50 ARRIBA";
   if(previous>=50 && current<50) return "CRUZA 50 ABAJO";
   return "SIN CRUCE NUEVO";
}
void EvoDashboardRect(const string name,const int x,const int y,const int w,const int h,const color fill,const color border)
{
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,MathMax(1,w)); ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,fill); ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,border);
   ObjectSetInteger(0,name,OBJPROP_BACK,false); ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
}
void EvoDashboardCard(const int row,const int col,const string title,const string value,const string state,
                      const string detail,const color ink,const double fraction,const bool rsi=false,const bool caution=false,const int signedDirection=0,const bool stochastic=false)
{
   int pitch=EvoPanelPitch(),w=(EvoPanelWidth()-32)/3,x=evoPanelX+10+col*(w+6),y=evoPanelY+10+row*pitch;
   string key="EVO_CONTEXT_MATRIX_D"+(string)row+"_"+(string)col;
   EvoDashboardRect(key,x,y,w,4*pitch-4,caution?C'48,40,22':C'26,32,39',caution?clrGold:C'58,66,73');
   int font=MathMax(7,MathMin(10,EvoPanelFont));
   string tip=title+"\n"+value+"\n"+state+"\n"+detail;
   EvoIndicatorsText(key+"T",x+7,y+2,w-14,title,clrSilver,font,false,tip);
   EvoIndicatorsText(key+"V",x+7,y+pitch-1,w-14,value,clrWhite,font+2,true,tip);
   EvoIndicatorsText(key+"S",x+7,y+2*pitch,w-14,state,ink,font,false,tip);
   int barWidth=w-16,barY=y+3*pitch+4;
   EvoDashboardRect(key+"B",x+8,barY,barWidth,7,C'55,61,67',C'55,61,67');
   if(fraction>=0)
   {
      if(rsi)
      {
         EvoDashboardRect(key+"Z1",x+8,barY,(int)(barWidth*(stochastic?.2:.3)),7,C'70,45,38',C'70,45,38');
         EvoDashboardRect(key+"Z2",x+8+(int)(barWidth*(stochastic?.8:.7)),barY,(int)(barWidth*(stochastic?.2:.3)),7,C'70,45,38',C'70,45,38');
         for(int i=0;i<3;i++)
         { double mark=i==0?(stochastic?.2:.3):i==1?.5:(stochastic?.8:.7); EvoDashboardRect(key+"M"+(string)i,x+8+(int)(barWidth*mark),barY-1,1,9,clrSilver,clrSilver); }
         EvoDashboardRect(key+"P",x+8+(int)((barWidth-3)*fraction),barY-2,3,11,ink,ink);
      }
      else if(signedDirection!=0)
      {
         int half=barWidth/2,extent=(int)(half*fraction);
         if(extent>0) EvoDashboardRect(key+"F",x+8+half+(signedDirection<0?-extent:0),barY,extent,7,ink,ink);
         EvoDashboardRect(key+"ZERO",x+8+half,barY-1,1,9,clrSilver,clrSilver);
      }
      else if(fraction>0) EvoDashboardRect(key+"F",x+8,barY,MathMax(1,(int)(barWidth*fraction)),7,ink,ink);
   }
   ObjectSetString(0,key,OBJPROP_TOOLTIP,tip);
}
void EvoDashboardContext(const EvoSnapshot &s,const bool paged)
{
   string lines[8];
   lines[0]=EvoLayerBroad(s.evidence); lines[1]=EvoLayerRecent(s.evidence); lines[2]=EvoSituation(s);
   double support=0,resistance=0; bool sf=false,rf=false; EvoNearestLevels(s.confirmed.close,support,resistance,sf,rf);
   lines[3]="SOPORTE "+(support>0?DoubleToString(support,_Digits):"N/D")+" | RESISTENCIA "+(resistance>0?DoubleToString(resistance,_Digits):"N/D");
   lines[4]="REGIMEN: "+s.localRegimeName; lines[5]="GESTION: "+s.managementModeName;
   lines[6]="ESPACIO: "+(s.roomValid?DoubleToString(s.roomATR,2)+" ATR":"N/D");
   lines[7]="STOCH y SAR: contexto; no confirman por si solos correccion ni giro.";
   EvoPanelLine(27,paged?StringFormat("CONTEXTO | pagina %d/2",evoDashboardDetailsPage+1):"CONTEXTO | no sustituye la vela activa",clrWhite,true);
   if(paged)
   {
      for(int i=0;i<4;i++) EvoPanelLine(28+i,lines[4*evoDashboardDetailsPage+i],clrSilver);
      EvoThesisButton("EVO_CONTEXT_DETAILS_PAGE","OTRO DETALLE",32);
      ObjectSetString(0,"EVO_CONTEXT_DETAILS_PAGE",OBJPROP_TOOLTIP,"Recorre todo el contexto en pantallas bajas. M15/H1/H4 siempre visibles.");
   }
   else
   {
      ObjectDelete(0,"EVO_CONTEXT_DETAILS_PAGE");
      for(int i=0;i<7;i++) EvoPanelLine(28+i,lines[i],clrSilver);
   }
}
void EvoDashboardDraw(const bool valid,const EvoSnapshot &s)
{
   ObjectDelete(0,"EVO_CONTEXT_CONCLUSION_BG");
   bool paged=!evoDecisionOnly && (int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS)<650;
   EvoPanelBackground(evoDecisionOnly?28:paged?33:35); EvoDrawTabs();
   EvoTextRemember(s,valid);
   EvoTextButton(5,288);
   EvoPanelLine(1,"ANALISIS v0.7 | "+_Symbol+" | "+EnumToString(_Period)+(evoPanelFrozen?" | FIJADO":s.closedView?" | indicadores cerrados":" | lectura mixta: ver ayudas"),clrWhite);
   EvoThesisButton("EVO_CONTEXT_DECISION_MODE",evoDecisionOnly?"VER CONTEXTO":"SOLO DECISION",5);
   ObjectSetInteger(0,"EVO_CONTEXT_DECISION_MODE",OBJPROP_XDISTANCE,evoPanelX+EvoPanelWidth()-154);
   ObjectSetInteger(0,"EVO_CONTEXT_DECISION_MODE",OBJPROP_XSIZE,144);
   ObjectSetInteger(0,"EVO_CONTEXT_DECISION_MODE",OBJPROP_FONTSIZE,9);
   ObjectSetString(0,"EVO_CONTEXT_DECISION_MODE",OBJPROP_TOOLTIP,"Oculta o muestra contexto. No cambia filtros, protecciones ni ordenes.");
   if(!valid) { EvoPanelLine(2,"DATOS NO DISPONIBLES | esperando indicadores",clrGold); return; }
   int idx=s.closedView?0:1;
   double atr=s.atr[idx],adx=s.adx[idx],rsi=s.rsi[idx];
   if(atr<=0) { EvoPanelLine(2,"ATR NO DISPONIBLE",clrGold); return; }
   int live=EvoLivePanel(2,s);
   EvoPanelLine(5,"INDICADORES CERRADOS",clrSilver);
   double ratio=s.average[idx]>0?atr/s.average[idx]:0;
   EvoDashboardCard(6,0,"ATR("+(string)InpATRPeriod+")",DoubleToString(atr,_Digits),ratio>0?StringFormat("%.2fx promedio ATR(10)",ratio):"PROMEDIO N/D",
      "Volatilidad, no direccion. Barra: ATR/promedio de 10 ATR; escala 0 a 2x, saturada por encima. Precio en unidades del simbolo.",clrWhite,ratio>0?EvoDashboardFraction(ratio,2):-1);
   string erState=!s.erValid?"N/D":s.er<.25?"RUIDOSA":s.er<.6?"INTERMEDIA":"EFICIENTE";
   EvoDashboardCard(6,1,"ER("+(string)EvoERPeriod+")",s.erValid?DoubleToString(s.er,2):"N/D",erState,
      "Escala 0-1. Umbral visual de ruido <0.25; no sustituye los umbrales del motor ni cambia la sugerencia. Eficiencia sin direccion.",s.erValid && s.er>=.6?clrLimeGreen:clrGold,s.erValid?EvoDashboardFraction(s.er,1):-1,false,s.erValid && s.er<.25);
   int rocSide=s.evidence.rocATR>0?1:s.evidence.rocATR<0?-1:0;
   EvoDashboardCard(6,2,"ROC(12) | VELOCIDAD",s.evidence.valid?StringFormat("%+.2f%%",s.evidence.roc):"N/D",
      s.evidence.valid?StringFormat("%+.2f ATR",s.evidence.rocATR):"SIN DATOS",
      "Barra centrada en cero: -3 a +3 ATR de desplazamiento en 12 velas; saturada fuera de escala. Valor principal ROC porcentual. No es probabilidad ni aceleracion.",rocSide>0?clrLimeGreen:rocSide<0?clrSalmon:clrGold,s.evidence.valid?EvoDashboardFraction(MathAbs(s.evidence.rocATR),3):-1,false,false,rocSide<0?-1:1);
   string force=adx<20?"DEBIL":adx<25?"MODERADA":adx<=40?"FUERTE":"MUY FUERTE";
   string di=s.closedPlusDI>s.closedMinusDI?"DI ALCISTA":s.closedMinusDI>s.closedPlusDI?"DI BAJISTA":"DI NEUTRO";
   EvoDashboardCard(10,0,"ADX("+(string)InpADXPeriod+") | FUERZA",DoubleToString(adx,1),force+" | "+di,
      "ADX no es direccion. Barra 0-50, saturada por encima. "+(s.deltaValid?StringFormat("dADX %+.2f; ",s.deltaADX):"dADX N/D; ")+StringFormat("+DI %.1f / -DI %.1f",s.closedPlusDI,s.closedMinusDI),adx<20?clrSilver:adx<25?clrGold:clrLimeGreen,EvoDashboardFraction(adx,50));
   string rsiState=rsi<=30?"SOBREVENTA":rsi>=70?"SOBRECOMPRA":"NEUTRO";
   EvoDashboardCard(10,1,"RSI("+(string)InpRSIPeriod+")",DoubleToString(rsi,1),rsiState,
      "Escala 0-100; marcas 30/50/70. "+EvoDashboardRSIEvent(rsi,s.rsi[idx+1])+". Extremos no obligan a giro.",rsi<=30 || rsi>=70?clrGold:rsi>50?clrLimeGreen:rsi<50?clrSalmon:clrSilver,EvoDashboardFraction(rsi,100),true);
   double histATR=s.evidence.valid?s.evidence.hist/atr:0;
   int macdSide=!s.evidence.valid || MathAbs(histATR)<EvoMomentumMinHistATR?0:histATR>0?1:-1;
   color macdInk=macdSide>0?clrLimeGreen:macdSide<0?clrSalmon:clrGold;
   EvoDashboardCard(10,2,"MACD | SEMAFORO",s.evidence.valid?DoubleToString(s.evidence.hist,MathMax(5,_Digits)):"N/D",
      !s.evidence.valid?"SIN DATOS":macdSide>0?"ALCISTA":macdSide<0?"BAJISTA":"NEUTRO / DEBIL",
      StringFormat("Histograma MACD(12,26,9), senal EMA9. Semaforo neutro si |hist/ATR| < %.3f. Barra: intensidad |hist|/ATR de 0 a 0.20, saturada por encima. No detecta divergencias ni confirma un cruce nuevo.",EvoMomentumMinHistATR),macdInk,s.evidence.valid?EvoDashboardFraction(MathAbs(histATR),.20):-1);
   int ledWidth=(EvoPanelWidth()-32)/3;
   EvoDashboardRect("EVO_CONTEXT_MATRIX_MACD_LED",evoPanelX+10+2*(ledWidth+6)+ledWidth-17,evoPanelY+10+10*EvoPanelPitch()+4,10,10,macdInk,macdInk);
   double diff=s.fast[idx]-s.slow[idx],previous=s.fast[idx+1]-s.slow[idx+1];
   bool up=diff>0 && previous<=0,down=diff<0 && previous>=0;
   string cross=up?"CRUCE ALCISTA NUEVO":down?"CRUCE BAJISTA NUEVO":"SIN CRUCE NUEVO";
   EvoDashboardCard(14,0,StringFormat("EMA %d/%d",InpEmaFastPeriod,InpEmaSlowPeriod),diff>0?"ALCISTA":diff<0?"BAJISTA":"NEUTRO",StringFormat("%+.2f ATR | ",diff/atr)+(up?"CRUCE +":down?"CRUCE -":"SIN CRUCE"),
      cross+". Se comparan las dos ultimas velas cerradas; no se inventa antiguedad. Distancia con signo = (EMA rapida - lenta)/ATR.",diff>0?clrLimeGreen:diff<0?clrSalmon:clrSilver,-1);
   string badge=EvoDashboardRSIEvent(rsi,s.rsi[idx+1]);
   double flow=s.obvValid && s.obvVolumeSum>0?s.obvDelta/s.obvVolumeSum:0;
   int obvSide=flow>0?1:flow<0?-1:0;
   EvoDashboardCard(14,1,"OBV | "+(EvoOBVVolume==VOLUME_REAL?"REAL":"TICKS"),s.obvValid?DoubleToString(s.obv,0):"N/D",
      s.obvValid?StringFormat("%s %+.0f",obvSide>0?"SUBE":obvSide<0?"BAJA":"PLANO",s.obvDelta):"SIN DATOS",
      StringFormat("OBV acumulado y cambio de %d velas cerradas. Barra centrada -100%% a +100%% = cambio OBV / suma de volumen de las mismas velas. %.1f%% neto. No mide liquidez ni intensidad frente a otras sesiones.",EvoOBVLookback,100*flow),obvSide>0?clrLimeGreen:obvSide<0?clrSalmon:clrGold,s.obvValid && s.obvVolumeSum>0?EvoDashboardFraction(MathAbs(flow),1):-1,false,false,obvSide<0?-1:1);
   EvoDashboardCard(14,2,"LECTURA CONJUNTA",s.erValid && s.er<.25?"RUIDO ALTO":"CONTEXTO",badge,
      "ATR, ER, ADX, RSI y EMA describen aspectos diferentes. No son una probabilidad ni una orden. Los cambios de RSI son sobre velas cerradas.",s.erValid && s.er<.25?clrGold:clrSilver,-1,false,s.erValid && s.er<.25);
   int stochCross=s.stochValid?EvoDashboardCross(s.stochK,s.stochD,s.stochPreviousK,s.stochPreviousD):0;
   string stochZone=!s.stochValid?"SIN DATOS":s.stochK>80?"SOBRECOMPRA":s.stochK<20?"SOBREVENTA":"NEUTRO";
   EvoDashboardCard(18,0,"STOCH(14,3,3)",s.stochValid?StringFormat("K %.1f D %.1f",s.stochK,s.stochD):"N/D",
      stochCross>0?"CRUCE K/D ALCISTA":stochCross<0?"CRUCE K/D BAJISTA":stochZone,
      stochZone+". Cruce de K/D entre dos velas cerradas. SMA, precios Low/High, K14/D3/slowing3. Barra K 0-100, marcas 20/50/80. Extremos no garantizan retroceso; no bloquea entradas ni modifica stops.",stochCross>0?clrLimeGreen:stochCross<0?clrSalmon:s.stochValid && (s.stochK>80 || s.stochK<20)?clrGold:clrSilver,s.stochValid?EvoDashboardFraction(s.stochK,100):-1,true,s.stochValid && (s.stochK>80 || s.stochK<20),0,true);
   int sarSide=s.sarValid?EvoDashboardSARSide(s.sarClose,s.sar):0;
   int oldSarSide=s.sarValid?EvoDashboardSARSide(s.sarPreviousClose,s.sarPrevious):0;
   bool sarChange=s.sarValid && sarSide!=0 && oldSarSide!=0 && sarSide!=oldSarSide;
   double sarDistance=s.sarValid?(s.sarClose-s.sar)/atr:0;
   EvoDashboardCard(18,1,"SAR(0.02,0.20)",s.sarValid?StringFormat("%+.2f ATR",sarDistance):"N/D",
      !s.sarValid?"SIN DATOS":sarChange?(sarSide>0?"CAMBIO A ALCISTA":"CAMBIO A BAJISTA"):sarSide>0?"DEBAJO | ALCISTA":sarSide<0?"ENCIMA | BAJISTA":"AL CIERRE",
      "Parabolic SAR nativo; step 0.02, maximo 0.20. Lado respecto al cierre de cada vela, no a la vela activa. Distancia (cierre-SAR)/ATR: positiva debajo, negativa encima. Cambio de lado entre dos cierres no confirma por si solo correccion o reversion. Valor SAR "+(s.sarValid?DoubleToString(s.sar,_Digits):"N/D"),sarChange?clrGold:sarSide>0?clrLimeGreen:sarSide<0?clrSalmon:clrSilver,-1,false,sarChange);
   EvoDashboardCard(18,2,"LECTURA DE GIROS",!s.stochValid && !s.sarValid?"N/D":stochCross!=0 || sarChange?"CAMBIO RECIENTE":s.stochValid && s.sarValid?"SIN CAMBIO NUEVO":"DATOS PARCIALES",sarChange?"SAR CAMBIO DE LADO":stochCross!=0?"STOCH CRUZO K/D":"VER ESTRUCTURA",
      "Un extremo, un cruce de estocastico o un cambio de SAR son contexto. Comparar canal, pivotes, ruptura y momentum. No afirman un giro confirmado ni que el precio deba rebotar.",stochCross!=0 || sarChange?clrGold:clrSilver,-1);
   string action=s.suggestionAction!=""?s.suggestionAction:"ESPERAR / SIN SUGERENCIA";
   for(int frame=0;frame<3;frame++)
   {
      string names[]={"M15","H1","H4"};
      int side=s.mtf[frame].valid?s.mtf[frame].direction:0;
      EvoPanelLine(22+frame,EvoFrameText(names[frame],s.mtf[frame]),side>0?clrLimeGreen:side<0?clrSalmon:clrSilver);
      ObjectSetString(0,"EVO_CONTEXT_"+(string)(22+frame),OBJPROP_TOOLTIP,EvoFrameText(names[frame],s.mtf[frame])+" | Contexto multi-temporal; se mantiene visible tambien en Solo decision.");
   }
   EvoPanelLine(25,"SUGERENCIA TECNICA: "+action,clrGold,true);
   string notice=s.erValid && s.er<.25 && s.deltaValid && s.deltaADX>0?"ADX CRECE + ER BAJO: fuerza creciente, avance ruidoso; confirmar":s.reason;
   if(MathAbs(live)>=2) notice="VELA ACTIVA FUERTE: lectura provisional; revisar presion sobre SL";
   EvoPanelLine(26,notice,clrGold);
   if(evoDecisionOnly) return;
   EvoDashboardContext(s,paged);
}
#endif
