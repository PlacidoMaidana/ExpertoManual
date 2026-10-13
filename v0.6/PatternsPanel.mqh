#ifndef EVO_PATTERN_PANEL
#define EVO_PATTERN_PANEL
#include "PatternRules.mqh"
struct EvoPatternPivot { int index,side; double price; };
struct EvoPatternStudy
{
   bool found;
   int side,state,endIndex,count;
   double neck,invalid;
   datetime detected;
   string name,detail;
   int pointIndex[5]; double pointPrice[5];
};
EvoPatternStudy evoPatternHCH,evoPatternDouble;
EvoPatternPivot evoPatternPivots[];
int evoElliottStart=-1,evoElliottSide=0,evoElliottMatches=0;
MqlRates evoPatternRates[];
datetime evoPatternBar=0;
double evoPatternATR=0;
string evoPatternLastEvent="";
string EvoPatternStateName(const int state)
{ return state==3?"INVALIDADO":state==2?"RUPTURA CONFIRMADA (2 cierres)":state==1?"RUPTURA INICIAL (1 cierre)":"CANDIDATO: FALTA RUPTURA"; }
void EvoPatternRead(const double atr,const datetime bar)
{
   if(bar==evoPatternBar && evoPatternATR==atr) return;
   ZeroMemory(evoPatternHCH); ZeroMemory(evoPatternDouble);
   evoElliottStart=-1; evoElliottSide=0; evoElliottMatches=0; ArrayResize(evoPatternPivots,0);
   int n=CopyRates(_Symbol,PERIOD_CURRENT,1,240,evoPatternRates);
   if(n<80 || evoPatternRates[n-1].time!=bar || atr<=0) { evoPatternBar=0; return; }
   EvoPatternPivot pivots[];
   for(int i=2;i<n-2;i++)
   {
      bool hi=true,lo=true;
      for(int j=1;j<=2;j++)
      {
         if(evoPatternRates[i].high<=evoPatternRates[i-j].high || evoPatternRates[i].high<=evoPatternRates[i+j].high) hi=false;
         if(evoPatternRates[i].low>=evoPatternRates[i-j].low || evoPatternRates[i].low>=evoPatternRates[i+j].low) lo=false;
      }
      if(hi==lo) continue; // Outside bars with ambiguous ordering are not inferred.
      int count=ArraySize(pivots),side=hi?1:-1; double price=hi?evoPatternRates[i].high:evoPatternRates[i].low;
      if(count>0 && pivots[count-1].side==side)
      {
         if(side*(price-pivots[count-1].price)>0) { pivots[count-1].price=price; pivots[count-1].index=i; }
         continue;
      }
      ArrayResize(pivots,count+1); pivots[count].index=i; pivots[count].side=side; pivots[count].price=price;
   }
   int count=ArraySize(pivots);
   ArrayResize(evoPatternPivots,count);
   for(int i=0;i<count;i++) evoPatternPivots[i]=pivots[i];
   for(int start=0;start+5<count;start++)
   {
      int side=-pivots[start].side;
      if(n-1-pivots[start+5].index>30 || pivots[start+5].index-pivots[start].index>100) continue;
      if(EvoElliottRules(side*pivots[start].price,side*pivots[start+1].price,side*pivots[start+2].price,side*pivots[start+3].price,side*pivots[start+4].price,side*pivots[start+5].price,atr)==5)
      { evoElliottStart=start; evoElliottSide=side; evoElliottMatches++; }
   }
   for(int end=2;end<count;end++)
   {
      if(n-1-pivots[end].index>30) continue;
      int direction=-pivots[end].side; // Peaks -> bearish; troughs -> bullish (mirrored prices).
      for(int kind=0;kind<2;kind++)
      {
         int points=kind==0?3:5,start=end-points+1;
         if(start<0 || pivots[end].index-pivots[start].index>100 || pivots[end].index-pivots[start].index<6) continue;
         double sign=-direction;
         bool shape=kind==0?EvoPatternDouble(sign*pivots[start].price,sign*pivots[start+1].price,sign*pivots[end].price,atr):
            EvoPatternHCH(sign*pivots[start].price,sign*pivots[start+1].price,sign*pivots[start+2].price,sign*pivots[start+3].price,sign*pivots[end].price,atr);
         if(!shape) continue;
         int first=pivots[start].index;
         bool trend=first>=5 && sign*(evoPatternRates[first].close-evoPatternRates[first-5].close)>=0.50*atr;
         if(!trend) continue;
         EvoPatternStudy study; ZeroMemory(study); study.found=true; study.side=direction; study.count=points; study.endIndex=pivots[end].index;
         study.name=kind==0?(direction<0?"DOBLE TECHO":"DOBLE SUELO"):(direction<0?"HOMBRO CABEZA HOMBRO":"HCH INVERTIDO");
         double neck1=pivots[start+1].price,slope=0; int anchor=pivots[start+1].index;
         if(kind==1) slope=(pivots[start+3].price-neck1)/(pivots[start+3].index-anchor);
         study.neck=neck1+slope*(n-1-anchor);
         study.invalid=pivots[start].price;
         for(int i=start;i<=end;i++)
         {
            study.pointIndex[i-start]=pivots[i].index; study.pointPrice[i-start]=pivots[i].price;
            if(sign*(pivots[i].price-study.invalid)>0) study.invalid=pivots[i].price;
         }
         // Both tested candles are later than the final pivot. No future prices are accessed.
         study.state=EvoPatternState(direction,evoPatternRates[n-2].close,study.neck-slope,evoPatternRates[n-1].close,study.neck,study.invalid,.10*atr);
         // A previously invalidated shape cannot be revived by a later return.
         for(int i=study.endIndex+1;i<n;i++)
            if(direction*(evoPatternRates[i].close-study.invalid)<-.10*atr) study.state=3;
         study.detected=evoPatternRates[study.endIndex+2].time;
         study.detail=StringFormat("Pivotes 2+2; referencia detectada %s; tendencia previa: desplazamiento 5 velas >=0.50 ATR. Simetria tolerada %s ATR. Margen de ruptura 0.10 ATR. Cuello actual %.5f; invalidacion por cierre mas alla de %.5f con margen. Confirmacion es de la figura, no garantia de reversion.",TimeToString(study.detected,TIME_DATE|TIME_MINUTES),kind==0?"0.35":"0.50",study.neck,study.invalid);
         if(kind==0) evoPatternDouble=study; else evoPatternHCH=study;
      }
   }
   evoPatternBar=bar; evoPatternATR=atr;
}
void EvoPatternSegment(const string name,const datetime t1,const double p1,const datetime t2,const double p2,const color ink)
{
   if(!evoPatternDrawings || !evoChartLinesVisible) return;
   ObjectCreate(0,name,OBJ_TREND,0,t1,p1,t2,p2);
   ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT,false); ObjectSetInteger(0,name,OBJPROP_RAY_LEFT,false);
   ObjectSetInteger(0,name,OBJPROP_COLOR,ink); ObjectSetInteger(0,name,OBJPROP_WIDTH,2);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false); ObjectSetInteger(0,name,OBJPROP_BACK,true);
}
void EvoPatternTag(const string key,const datetime time,const double price,const string text,const color ink)
{
   if(!evoPatternDrawings || !evoChartLinesVisible) return;
   ObjectCreate(0,key,OBJ_TEXT,0,time,price);
   ObjectSetString(0,key,OBJPROP_TEXT,text); ObjectSetInteger(0,key,OBJPROP_COLOR,ink);
   ObjectSetInteger(0,key,OBJPROP_FONTSIZE,9); ObjectSetInteger(0,key,OBJPROP_SELECTABLE,false);
   ObjectSetString(0,key,OBJPROP_TOOLTIP,text+" | "+TimeToString(time,TIME_DATE|TIME_MINUTES));
}
void EvoPatternDisplayStudy(const int row,const EvoPatternStudy &study,const int momentum,const string prefix)
{
   if(!study.found) { EvoPanelLine(row,prefix+": SIN FIGURA RECIENTE CON REGLAS CUMPLIDAS",clrSilver); return; }
   color ink=study.state==3?clrSilver:study.state==2?clrLimeGreen:clrGold;
   EvoPanelLine(row,study.name+" | "+EvoPatternStateName(study.state),ink,true);
   EvoPanelLine(row+1,StringFormat("Direccion posible %s | cuello %.*f | invalidacion %.*f",study.side>0?"ALCISTA":"BAJISTA",_Digits,study.neck,_Digits,study.invalid),clrWhite);
   EvoPanelLine(row+2,"Impulso MACD/ROC: "+(momentum==study.side?"ACOMPANA":momentum==-study.side?"CONTRARIO":"SIN CONSENSO")+" | siguiente: "+(study.state==0?"cierre fuera del cuello":study.state==1?"segundo cierre fuera del cuello":study.state==2?"vigilar continuidad / retesteo":"esperar nueva figura"),clrSilver);
   ObjectSetString(0,"EVO_CONTEXT_"+(string)row,OBJPROP_TOOLTIP,study.detail);
   int n=ArraySize(evoPatternRates);
   for(int i=0;i<study.count;i++)
   {
      string key="EVO_PATTERN_"+prefix+"_"+(string)i;
      if(i>0) EvoPatternSegment(key,evoPatternRates[study.pointIndex[i-1]].time,study.pointPrice[i-1],evoPatternRates[study.pointIndex[i]].time,study.pointPrice[i],ink);
      if(evoPatternDrawings && evoChartLinesVisible)
      {
         string label=key+"_TEXT"; ObjectCreate(0,label,OBJ_TEXT,0,evoPatternRates[study.pointIndex[i]].time,study.pointPrice[i]);
         string tag=study.count==5?(i==0?"Hombro izq":i==2?"Cabeza":i==4?"Hombro der":"Cuello"):(i==1?"cuello":i==0?"1":"2");
         ObjectSetString(0,label,OBJPROP_TEXT,tag+" "+DoubleToString(study.pointPrice[i],_Digits)); ObjectSetInteger(0,label,OBJPROP_COLOR,ink); ObjectSetInteger(0,label,OBJPROP_FONTSIZE,9); ObjectSetInteger(0,label,OBJPROP_SELECTABLE,false);
      }
   }
   EvoPatternTag("EVO_PATTERN_"+prefix+"_NECK_LABEL",evoPatternRates[n-1].time,study.neck,"Cuello "+DoubleToString(study.neck,_Digits),clrAqua);
   int anchor=study.pointIndex[1]; double slope=study.count==5?(study.pointPrice[3]-study.pointPrice[1])/(study.pointIndex[3]-anchor):0;
   EvoPatternSegment("EVO_PATTERN_"+prefix+"_NECK",evoPatternRates[anchor].time,study.pointPrice[1],evoPatternRates[n-1].time,study.neck,clrAqua);
   EvoPatternSegment("EVO_PATTERN_"+prefix+"_INVALID",evoPatternRates[study.endIndex].time,study.invalid,evoPatternRates[n-1].time,study.invalid,clrTomato);
}
bool EvoWave3Checklist(const EvoSnapshot &s,const EvoPatternPivot &p0,const EvoPatternPivot &p1,const EvoPatternPivot &p2,const int side)
{
   int n=ArraySize(evoPatternRates); double atr=s.atr[0];
   // Real volume only when every bar in the measured intervals has a positive value.
   bool real=true;
   for(int i=p0.index+1;i<n;i++) if(evoPatternRates[i].real_volume<=0) real=false;
   double vol1=0,vol2=0;
   for(int i=p0.index+1;i<=p1.index;i++) vol1+=real?(double)evoPatternRates[i].real_volume:(double)evoPatternRates[i].tick_volume;
   for(int i=p1.index+1;i<=p2.index;i++) vol2+=real?(double)evoPatternRates[i].real_volume:(double)evoPatternRates[i].tick_volume;
   vol1/=(p1.index-p0.index); vol2/=(p2.index-p1.index);
   double baseline=MathMax(vol1,vol2),volume=real?(double)evoPatternRates[n-1].real_volume:(double)evoPatternRates[n-1].tick_volume;
   double ratio=baseline>0?volume/baseline:0;
   EvoPanelLine(10,StringFormat("Volumen %s: %.2fx media por vela 1/2 | %s",real?"REAL":"TICKS",ratio,baseline<=0?"N/D":ratio>=1.30?"EXPANSION (>=1.30x)":"SIN EXPANSION"),ratio>=1.30?clrLimeGreen:clrGold);
   MqlRates last=evoPatternRates[n-1]; double range=last.high-last.low;
   bool acceleration=range>=atr && MathAbs(last.close-last.open)>=.60*range && side*(last.close-last.open)>0;
   EvoPanelLine(11,"Aceleracion ultima vela: "+(acceleration?"SI":"FALTA")+StringFormat(" | rango %.2f ATR; cuerpo >=60%%",range/atr),acceleration?clrLimeGreen:clrSilver);
   bool rsi=side>0?s.rsi[0]>=60:s.rsi[0]<=40;
   double spread=side*(s.fast[0]-s.slow[0]),old=side*(s.fast[1]-s.slow[1]); bool ema=spread>0 && spread>old;
   EvoPanelLine(12,StringFormat("RSI %.1f: %s (>=60 / <=40) | EMA: %s",s.rsi[0],rsi?"A FAVOR":"NO ACOMPANA",ema?"A FAVOR Y EXPANDIENDO":"SIN EXPANSION"),rsi && ema?clrLimeGreen:clrSilver);
   EvoPanelLine(13,"MACD/ROC: "+(s.evidence.valid && s.evidence.momentum==side?"IMPULSO A FAVOR":s.evidence.valid?"SIN APOYO CONJUNTO":"N/D")+" | un solo grupo de contexto");
   return real;
}
void EvoWave3DrawLevels(const EvoPatternPivot &p0,const EvoPatternPivot &p1,const EvoPatternPivot &p2,const int side,const double atr)
{
   double length=side*(p1.price-p0.price),trigger=p1.price+side*.10*atr;
   double f1=p2.price+side*length,f1618=p2.price+side*length*1.618,f2618=p2.price+side*length*2.618;
   EvoPatternPivot points[3]; points[0]=p0; points[1]=p1; points[2]=p2;
   for(int i=0;i<3;i++)
   {
      EvoPatternTag("EVO_PATTERN_W3_TAG_"+(string)i,evoPatternRates[points[i].index].time,points[i].price,"W"+(string)i+"? "+DoubleToString(points[i].price,_Digits),clrViolet);
      if(i>0) EvoPatternSegment("EVO_PATTERN_W3_PATH_"+(string)i,evoPatternRates[points[i-1].index].time,points[i-1].price,evoPatternRates[points[i].index].time,points[i].price,clrViolet);
   }
   double levels[5]; levels[0]=trigger; levels[1]=p0.price; levels[2]=f1; levels[3]=f1618; levels[4]=f2618;
   string names[5]={"Ruptura W1?","Origen invalida","Fibo 100%","Fibo 161.8%","Fibo 261.8%"};
   datetime from=evoPatternRates[p2.index].time,to=evoPanelFrozen?evoPatternRates[ArraySize(evoPatternRates)-1].time:TimeCurrent();
   for(int i=0;i<5;i++)
   {
      EvoPatternSegment("EVO_PATTERN_W3_LEVEL_"+(string)i,from,levels[i],to,levels[i],i==1?clrTomato:clrAqua);
      EvoPatternTag("EVO_PATTERN_W3_LEVELTEXT_"+(string)i,to,levels[i],names[i]+" "+DoubleToString(levels[i],_Digits),i==1?clrTomato:clrAqua);
   }
}
void EvoWave3Draw(const EvoSnapshot &s)
{
   ObjectDelete(0,"EVO_CONTEXT_PATTERN_WICK_NEXT");
   int count=ArraySize(evoPatternPivots),n=ArraySize(evoPatternRates),start=-1,side=0;
   // A completed 0-1-2 is a hypothesis, never a unique Elliott interpretation.
   for(int i=0;i+2<count;i++)
   {
      int direction=-evoPatternPivots[i].side;
      double a=direction*evoPatternPivots[i].price,b=direction*evoPatternPivots[i+1].price,c=direction*evoPatternPivots[i+2].price;
      if(n-1-evoPatternPivots[i+2].index>20 || evoPatternPivots[i+2].index-evoPatternPivots[i].index>100) continue;
      if(b-a>=.50*s.atr[0] && c>a && c<b) { start=i; side=direction; }
   }
   if(start<0)
   {
      EvoPanelLine(5,"ONDA 3: SIN HIPOTESIS 0-1-2 RECIENTE",clrGold,true);
      EvoPanelLine(6,"Se requieren 3 pivotes alternantes confirmados, onda 1 >=0.50 ATR.");
      EvoPanelLine(7,"Onda 2 debe retroceder sin alcanzar el origen de 1.");
      EvoPanelLine(22,"No se fuerza un conteo ni se anticipan pivotes futuros."); return;
   }
   EvoPatternPivot p0=evoPatternPivots[start],p1=evoPatternPivots[start+1],p2=evoPatternPivots[start+2];
   MqlTick q; if(!SymbolInfoTick(_Symbol,q)) { EvoPanelLine(5,"Sin precio en vivo",clrGold); return; }
   double live=evoPanelFrozen?s.confirmed.close:q.bid,atr=s.atr[0],length=side*(p1.price-p0.price),adverse=side*(side>0?evoPatternRates[p2.index].low:evoPatternRates[p2.index].high);
   bool tradedBelow2=false;
   for(int i=p2.index+1;i<n;i++)
   {
      double extreme=side>0?evoPatternRates[i].low:evoPatternRates[i].high;
      adverse=MathMin(adverse,side*extreme);
      if(side*(extreme-p2.price)<0) tradedBelow2=true;
   }
   adverse=MathMin(adverse,side*live);
   int state=EvoWave3State(side*p0.price,side*p1.price,side*p2.price,adverse,side*evoPatternRates[n-2].close,side*evoPatternRates[n-1].close,side*live,atr);
   string status=state<0?"INVALIDADA: ORIGEN ALCANZADO":state==3?"RUPTURA 1 CONFIRMADA (2 CIERRES)":state==2?"RUPTURA 1: UN CIERRE":state==1?"RUPTURA EN VIVO; FALTA CIERRE":"ESPERANDO RUPTURA DE ONDA 1";
   bool progressed=count>start+3; // Another confirmed pivot already exists after candidate 2.
   EvoPanelLine(5,"POSIBLE ONDA 3 "+EvoEvidenceDirection(side)+" | "+status,state<0?clrSalmon:state==3?clrLimeGreen:clrGold,true);
   EvoPanelLine(6,StringFormat("0 %.*f | 1 %.*f | 2 %.*f | retroceso 2 %.1f%%",_Digits,p0.price,_Digits,p1.price,_Digits,p2.price,100*side*(p1.price-p2.price)/length));
   double trigger=p1.price+side*.10*atr;
   EvoPanelLine(7,StringFormat("Activacion propuesta %s %.*f | origen invalida %.*f",side>0?">":"<",_Digits,trigger,_Digits,p0.price),clrWhite);
   EvoPanelLine(8,progressed?"Ya hay pivotes posteriores: posible onda avanzada/correccion; revisar conteo":tradedBelow2?"Onda 2 extendida: se perdio su extremo; origen aun no roto":"Onda 2 respetada desde deteccion; hipotesis aun abierta",progressed || tradedBelow2?clrGold:clrSilver);
   EvoPanelLine(9,"CHECKLIST: evidencias separadas, no probabilidad ni validacion formal",clrAqua);
   bool real=EvoWave3Checklist(s,p0,p1,p2,side);
   double f1=p2.price+side*length,f1618=p2.price+side*length*1.618,f2618=p2.price+side*length*2.618;
   EvoPanelLine(15,StringFormat("Proyecciones: 100%% %.*f | 161.8%% %.*f | 261.8%% %.*f",_Digits,f1,_Digits,f1618,_Digits,f2618),clrAqua);
   EvoPanelLine(16,"Son referencias Fibonacci; no minimos obligatorios ni TP garantizados.");
   EvoPanelLine(18,"Romper onda 1 confirma el nivel, no demuestra que sea onda 3.",clrGold);
   EvoPanelLine(19,"3 puede ser menor que 1; no la mas corta de 1/3/5 (5 aun desconocida).");
   EvoPanelLine(20,"Volumen ticks mide actividad de cotizacion, no volumen negociado.");
   EvoPanelLine(21,"No cuenta microondas ni descarta una onda C o conteos alternativos.");
   EvoPanelLine(22,"Pivotes requieren 2 cierres posteriores; precio en vivo es provisional.");
   EvoPanelLine(23,"Sin ordenes ni cambios de SL/TP. Verifica tambien estructura y riesgo.");
   EvoWave3DrawLevels(p0,p1,p2,side,atr);
   if(!evoPanelFrozen)
   {
      string key="W3:"+(string)evoPatternRates[p2.index].time+":"+(string)state+":"+(string)progressed+":"+(string)tradedBelow2;
      if(key!=evoPatternLastEvent) { evoPatternLastEvent=key; EvoJournal("ONDA3_DIAGNOSTICO",0,key+"; volumen="+(real?"real":"ticks")+"; solo_diagnostico=1"); }
   }
}
void EvoPatternsDraw(const bool valid,const EvoSnapshot &s,const bool manual)
{
   EvoPanelBackground(manual?MathMax(26,evoMonitorControlRow)+evoPanelExtraRows:26); EvoDrawTabs();
   EvoPanelLine(1,"PATRONES | "+_Symbol+" | "+EnumToString(_Period)+" | SOLO DIAGNOSTICO",clrAqua);
   EvoThesisButton("EVO_CONTEXT_PATTERN_LINES",evoPatternDrawings?"DIBUJOS ON":"DIBUJOS OFF",2);
   EvoPanelLine(2,evoPatternWave3View?"Posible Onda 3: seguimiento del precio en vivo":"Estudio de reversion por precios cerrados",clrWhite);
   EvoThesisButton("EVO_CONTEXT_PATTERN_WAVE3",evoPatternWave3View?"VER PATRONES":"VER ONDA 3",4);
   if(!valid || !s.closedView || s.atr[0]<=0 || evoPanelDataPending) { EvoPanelLine(3,"DATOS CERRADOS NO DISPONIBLES: esperar actualizacion",clrGold); return; }
   EvoPatternRead(s.atr[0],s.confirmed.time);
   if(evoPatternBar!=s.confirmed.time) { EvoPanelLine(3,"HISTORIAL INSUFICIENTE: minimo 80 velas cerradas",clrGold); return; }
   EvoPanelLine(3,StringFormat("ATR %.3f | cierre %s | pivotes requieren 2 velas posteriores",s.atr[0],TimeToString(s.confirmed.time,TIME_MINUTES)),clrSilver);
   if(evoPatternWave3View) { EvoWave3Draw(s); return; }
   EvoPatternDisplayStudy(5,evoPatternHCH,s.evidence.momentum,"HCH");
   EvoPatternDisplayStudy(9,evoPatternDouble,s.evidence.momentum,"DOBLE");
   int n=ArraySize(evoPatternRates),wickIndices[],wickSides[];
   for(int i=n-1;i>=MathMax(6,n-20);i--)
   {
      MqlRates candle=evoPatternRates[i];
      int side=EvoPatternWick(candle.open,candle.high,candle.low,candle.close,s.atr[0],1)?1:EvoPatternWick(candle.open,candle.high,candle.low,candle.close,s.atr[0],-1)?-1:0;
      if(side==0) continue;
      int count=ArraySize(wickIndices); ArrayResize(wickIndices,count+1); ArrayResize(wickSides,count+1);
      wickIndices[count]=i; wickSides[count]=side;
   }
   int wickCount=ArraySize(wickIndices);
   EvoThesisButton("EVO_CONTEXT_PATTERN_WICK_NEXT","OTRA VELA",12);
   if(wickCount==0)
   {
      EvoPanelLine(13,"VELAS NOTABLES: ninguna cumple reglas en 20 cierres",clrSilver,true);
      EvoPanelLine(14,"Mecha >=2 cuerpos y >=55% rango; opuesta <=25%.");
      EvoPanelLine(15,"Sin candidato no se dibuja una vela de rechazo.");
   }
   else
   {
      evoPatternWickOffset=evoPatternWickOffset%wickCount;
      int index=wickIndices[evoPatternWickOffset],side=wickSides[evoPatternWickOffset]; MqlRates candle=evoPatternRates[index];
      double previous=evoPatternRates[index-1].close-evoPatternRates[index-6].close;
      int prior=EvoEvidenceSign(previous,.50*s.atr[0]);
      string name=side>0?(prior<0?"MARTILLO":prior>0?"HOMBRE COLGADO":"PIN BAR INFERIOR"):(prior>0?"ESTRELLA FUGAZ":prior<0?"MARTILLO INVERTIDO":"PIN BAR SUPERIOR");
      if(MathAbs(candle.close-candle.open)<=.10*(candle.high-candle.low)) name="DOJI DE RECHAZO "+(side>0?"INFERIOR":"SUPERIOR");
      int direction=prior!=0?-prior:side;
      int state=0,confirmationIndex=-1;
      double trigger=direction>0?candle.high:candle.low,invalid=direction>0?candle.low:candle.high;
      for(int i=index+1;i<n;i++)
      {
         if(direction*(evoPatternRates[i].close-invalid)<-.10*s.atr[0]) { state=3; break; }
         if(direction*(evoPatternRates[i].close-trigger)>.10*s.atr[0]) { state=2; if(confirmationIndex<0) confirmationIndex=i; }
      }
      string status=state==3?"INVALIDADA":state==2?"RUPTURA CONFIRMADA":"ESPERA CIERRE DE CONFIRMACION";
      EvoPanelLine(13,StringFormat("VELA %d/%d | %s",evoPatternWickOffset+1,wickCount,name),clrAqua,true);
      EvoPanelLine(14,TimeToString(candle.time,TIME_DATE|TIME_MINUTES)+" | "+status,state==3?clrSilver:state==2?clrLimeGreen:clrGold);
      EvoPanelLine(15,StringFormat("Confirmar cierre %s %.*f | invalidar %s %.*f",direction>0?">":"<",_Digits,trigger+direction*.10*s.atr[0],direction>0?"<":">",_Digits,invalid-direction*.10*s.atr[0]));
      EvoPanelLine(16,"Nombre por forma/contexto; una mecha sola no confirma giro.",clrSilver);
      EvoPanelLine(17,StringFormat("Tendencia previa %s | mecha %s | %d velas posteriores",EvoEvidenceDirection(prior),side>0?"inferior":"superior",n-1-index));
      for(int k=0;k<MathMin(3,wickCount);k++)
      {
         int j=wickIndices[k]; EvoPatternTag("EVO_PATTERN_WICK_TAG_"+(string)k,evoPatternRates[j].time,wickSides[k]>0?evoPatternRates[j].low-.15*s.atr[0]:evoPatternRates[j].high+.15*s.atr[0],"Mecha "+TimeToString(evoPatternRates[j].time,TIME_MINUTES),clrGold);
      }
      EvoPatternTag("EVO_PATTERN_WICK_SELECTED",candle.time,side>0?candle.low-.30*s.atr[0]:candle.high+.30*s.atr[0],name,clrAqua);
      EvoPatternSegment("EVO_PATTERN_WICK_TRIGGER",candle.time,trigger+direction*.10*s.atr[0],evoPatternRates[n-1].time,trigger+direction*.10*s.atr[0],clrAqua);
      EvoPatternSegment("EVO_PATTERN_WICK_INVALID",candle.time,invalid-direction*.10*s.atr[0],evoPatternRates[n-1].time,invalid-direction*.10*s.atr[0],clrTomato);
      if(confirmationIndex>=0) EvoPatternTag("EVO_PATTERN_WICK_CONFIRM",evoPatternRates[confirmationIndex].time,evoPatternRates[confirmationIndex].close,"Confirma mecha",clrLimeGreen);
   }
   EvoPanelLine(19,"ELLIOTT: HIPOTESIS EXPERIMENTAL DE IMPULSO 1-2-3-4-5",clrAqua,true);
   if(evoElliottStart<0)
   {
      EvoPanelLine(20,"Sin secuencia reciente que cumpla impulso ordinario.",clrSilver);
      EvoPanelLine(21,"No se fuerza un conteo: diagonales y ondas truncadas no evaluadas.");
   }
   else
   {
      EvoPatternPivot origin=evoPatternPivots[evoElliottStart],last=evoPatternPivots[evoElliottStart+5],four=evoPatternPivots[evoElliottStart+4];
      EvoPanelLine(20,StringFormat("Hipotesis %s | %d coincidencias | ultima onda 5 %.*f",EvoEvidenceDirection(evoElliottSide),evoElliottMatches,_Digits,last.price),clrWhite);
      EvoPanelLine(21,StringFormat("Tras 5: vigilar correccion; cierre mas alla de onda 4 %.*f",_Digits,four.price),clrGold);
      for(int i=0;i<=5;i++)
      {
         EvoPatternPivot point=evoPatternPivots[evoElliottStart+i];
         EvoPatternTag("EVO_PATTERN_ELLIOTT_TAG_"+(string)i,evoPatternRates[point.index].time,point.price,"E"+(string)i+" "+DoubleToString(point.price,_Digits),clrViolet);
         if(i>0)
         {
            EvoPatternPivot before=evoPatternPivots[evoElliottStart+i-1];
            EvoPatternSegment("EVO_PATTERN_ELLIOTT_"+(string)i,evoPatternRates[before.index].time,before.price,evoPatternRates[point.index].time,point.price,clrViolet);
         }
      }
      EvoPatternSegment("EVO_PATTERN_ELLIOTT_LEVEL4",evoPatternRates[four.index].time,four.price,evoPatternRates[n-1].time,four.price,clrViolet);
   }
   EvoPanelLine(22,"Elliott: 2 no vuelve al origen; 4 no solapa 1; 3 no es menor que 1 y 5.");
   EvoPanelLine(23,"Sin subondas ni ABC: hipotesis geometrica, no conteo Elliott completo.",clrGold);
   EvoPanelLine(24,"Sin ordenes automaticas | figuras solo si cumplen reglas | dibujos ON/OFF.");
   // Show actual pivots even when no reversal pattern qualifies, with neutral labels.
   if(!evoPatternHCH.found && !evoPatternDouble.found)
   {
      int count=ArraySize(evoPatternPivots);
      for(int i=MathMax(0,count-6);i<count;i++)
      {
         EvoPatternPivot point=evoPatternPivots[i];
         EvoPatternTag("EVO_PATTERN_PIVOT_"+(string)i,evoPatternRates[point.index].time,point.price,(point.side>0?"Max ":"Min ")+DoubleToString(point.price,_Digits),clrSilver);
      }
      EvoPanelLine(7,"Sin cuello/cabeza validos; se muestran pivotes Max/Min.",clrSilver);
   }
   if(!evoPanelFrozen)
   {
      string key=(evoPatternHCH.found?(string)evoPatternHCH.detected+":"+(string)evoPatternHCH.state:"sin HCH")+"/"+
         (evoPatternDouble.found?(string)evoPatternDouble.detected+":"+(string)evoPatternDouble.state:"sin doble")+"/"+(string)wickCount+"/"+(string)evoElliottStart;
      if(key!=evoPatternLastEvent) { evoPatternLastEvent=key; EvoJournal("PATRONES_DIAGNOSTICO",0,"estado="+key+"; solo_diagnostico=1; Elliott=hipotesis_geometrica"); }
   }
}
#endif
