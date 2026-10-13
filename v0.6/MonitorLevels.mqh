#ifndef EVOLUTION_MONITOR_LEVELS
#define EVOLUTION_MONITOR_LEVELS
#include "MarketEvidence.mqh"
// Presentation only: preserve prices and simulation state when hiding drawings.
bool evoChartLinesVisible=true;
bool EvoIsMonitorLine(const string name)
{
   return name=="EVO_SIM_ENTRADA" || name=="EVO_SIM_SL" || name=="EVO_SIM_TP" ||
      name=="EVO_SR_SUPPORT" || name=="EVO_SR_RESISTANCE" || StringFind(name,"EVO_DEMAND_")==0 || StringFind(name,"EVO_CHANNEL_")==0;
}
void EvoApplyLineVisibility(const string name)
{
   if(ObjectFind(0,name)>=0 && (ObjectGetInteger(0,name,OBJPROP_TYPE)==OBJ_HLINE || ObjectGetInteger(0,name,OBJPROP_TYPE)==OBJ_TREND) && EvoIsMonitorLine(name))
      ObjectSetInteger(0,name,OBJPROP_TIMEFRAMES,evoChartLinesVisible?OBJ_ALL_PERIODS:OBJ_NO_PERIODS);
}
void EvoSetChartLinesVisible(const bool visible)
{
   evoChartLinesVisible=visible;
   for(int i=ObjectsTotal(0)-1;i>=0;i--) EvoApplyLineVisibility(ObjectName(0,i));
   ChartRedraw(0);
}
input group "Contexto visual del monitor"
input bool EvoShowChannels = true; // Canal historico sobre velas cerradas
input bool EvoShowSRLines = true; // Lineas de los niveles cercanos, independientes del panel
input int InpMonitorSRLookback = 100;
input int InpMonitorSRPivotBars = 2;
input double InpMonitorLateralADXMax = 20.0;

// rates is a series: index 0 is the live bar. Confirmed pivots start at p+1.
void EvoNearestPivots(const MqlRates &rates[],const int count,const int p,const double price,
                      double &support,double &resistance,bool &supportFallback,bool &resistanceFallback)
{
   support=0; resistance=0; supportFallback=false; resistanceFallback=false;
   if(p<1 || count<=2*p || ArraySize(rates)<=count+p || price<=0) return;
   double fallbackLow=DBL_MAX,fallbackHigh=-DBL_MAX;
   for(int shift=p+1;shift<=count;shift++)
   {
      double low=rates[shift].low,high=rates[shift].high;
      if(low<=0 || high<=0) continue;
      fallbackLow=MathMin(fallbackLow,low); fallbackHigh=MathMax(fallbackHigh,high);
      bool pivotLow=true,pivotHigh=true;
      for(int side=1;side<=p;side++)
      {
         if(low>=rates[shift-side].low || low>rates[shift+side].low) pivotLow=false;
         if(high<=rates[shift-side].high || high<rates[shift+side].high) pivotHigh=false;
      }
      if(pivotLow && low<price && (support<=0 || low>support)) support=low;
      if(pivotHigh && high>price && (resistance<=0 || high<resistance)) resistance=high;
   }
   if(support<=0 && fallbackLow<DBL_MAX && fallbackLow<price) { support=fallbackLow; supportFallback=true; }
   if(resistance<=0 && fallbackHigh> -DBL_MAX && fallbackHigh>price) { resistance=fallbackHigh; resistanceFallback=true; }
}

void EvoNearestLevels(const double price,double &support,double &resistance,bool &sf,bool &rf)
{
   support=0; resistance=0; sf=false; rf=false;
   int p=InpMonitorSRPivotBars;
   if(p<1 || p>1000 || InpMonitorSRLookback<10 || InpMonitorSRLookback>10000) return;
   int count=MathMin(MathMax(InpMonitorSRLookback,p*2+5),Bars(_Symbol,PERIOD_CURRENT)-p-1);
   if(count<=p*2) return;
   MqlRates rates[]; ArraySetAsSeries(rates,true);
   int needed=count+p+1;
   if(CopyRates(_Symbol,PERIOD_CURRENT,0,needed,rates)!=needed) return;
   EvoNearestPivots(rates,count,p,price,support,resistance,sf,rf);
}
// Separate names from the screen panel: dragging the panel never moves price levels.
void EvoDeleteSRLines()
{
   ObjectsDeleteAll(0,"EVO_CHANNEL_");
   ObjectDelete(0,"EVO_SR_SUPPORT");
   ObjectDelete(0,"EVO_SR_RESISTANCE");
}
void EvoDrawSRLine(const string name,const double price,const bool support,const bool fallback)
{
   if(!EvoShowSRLines || price<=0 || !MathIsValidNumber(price)) { ObjectDelete(0,name); return; }
   if(ObjectFind(0,name)<0 && !ObjectCreate(0,name,OBJ_HLINE,0,0,price)) return;
   EvoApplyLineVisibility(name);
   ObjectSetDouble(0,name,OBJPROP_PRICE,price);
   ObjectSetInteger(0,name,OBJPROP_COLOR,support?clrDeepSkyBlue:clrTomato);
   ObjectSetInteger(0,name,OBJPROP_STYLE,fallback?STYLE_DOT:STYLE_DASH);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,1);
   ObjectSetInteger(0,name,OBJPROP_BACK,true);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
   string tf=EnumToString((ENUM_TIMEFRAMES)_Period); StringReplace(tf,"PERIOD_","");
   string label=(support?"SOPORTE CERCANO":"RESISTENCIA CERCANA")+" "+tf+" | "+DoubleToString(price,_Digits)+
      (fallback?" | extremo de respaldo":" | pivote confirmado");
   ObjectSetString(0,name,OBJPROP_TEXT,label);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,label);
}
void EvoDrawMarketChannel(const string prefix,const EvoMarketEvidence &e,const bool lateral)
{
   if(!EvoShowChannels || !e.valid || e.first<=0 || e.bar<=e.first)
   { ObjectsDeleteAll(0,prefix); return; }
   double first=lateral?(e.rangeHigh+e.rangeLow)*0.5:e.channelFirst;
   double last=lateral?first:e.channelLast;
   double low=lateral?e.rangeLow-first:e.channelLowOffset;
   double high=lateral?e.rangeHigh-first:e.channelHighOffset;
   string suffix[]={"LOW","MID","HIGH"}; double offset[]={low,0,high};
   for(int i=0;i<3;i++)
   {
      string name=prefix+suffix[i];
      if(ObjectFind(0,name)<0 && !ObjectCreate(0,name,OBJ_TREND,0,e.first,first+offset[i],e.bar,last+offset[i])) continue;
      ObjectMove(0,name,0,e.first,first+offset[i]); ObjectMove(0,name,1,e.bar,last+offset[i]);
      ObjectSetInteger(0,name,OBJPROP_RAY_LEFT,false); ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT,false);
      ObjectSetInteger(0,name,OBJPROP_COLOR,i==1?clrSilver:lateral?clrGold:last>=first?clrDeepSkyBlue:clrSalmon);
      ObjectSetInteger(0,name,OBJPROP_STYLE,i==1?STYLE_DOT:STYLE_DASH);
      ObjectSetInteger(0,name,OBJPROP_WIDTH,1); ObjectSetInteger(0,name,OBJPROP_BACK,true);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetString(0,name,OBJPROP_TOOLTIP,(lateral?"Rango horizontal":"Canal de regresion con envolvente de maximos/minimos")+
         " | "+(string)EvoChannelLookback+" velas cerradas | historico, no prediccion | hasta "+TimeToString(e.bar,TIME_DATE|TIME_MINUTES));
      EvoApplyLineVisibility(name);
   }
}

#endif
