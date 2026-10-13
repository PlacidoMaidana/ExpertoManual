"""Build a syntax adapter comparing the shared evaluator to the archived v0.1 EA.

Only pure regime / technical entry rules are executed; no terminal or broker emulation.
"""
from pathlib import Path
import re
root=Path(__file__).resolve().parent.parent
base=(root.parent/'SignalFusion ORO Alto Riesgo v1.13.mq5').read_text(encoding='utf-8-sig')
shared=(root/'SignalAnalysis.mqh').read_text(encoding='utf-8-sig')
inputs=(root/'SignalAnalysisInputs.mqh').read_text(encoding='utf-8-sig')

def function(text,name):
    m=re.search(r'^(?:void|bool|double|int|string) '+name+r'\([^;]*?\)\s*\{',text,re.M)
    i=m.end(); n=1
    while n:
        n+=(text[i]=='{')-(text[i]=='}'); i+=1
    return text[m.start():i]

def adapt(s):
    s=re.sub(r'(?m)^#.*$','',s)
    s=re.sub(r'(?m)^input group.*$','',s)
    s=s.replace('input ','public static ').replace('enum ENUM_ENTRY_MODE','public enum ENUM_ENTRY_MODE')
    s=re.sub(r'(?m)^(void|bool|double|int|string) (\w+)\(',r'public static \1 \2(',s)
    s=s.replace('const ','').replace('&s','s').replace('&r','r')
    s=s.replace('StringToLower(dir);','dir=dir.ToLower();').replace('StringToLower(direction);','direction=direction.ToLower();')
    s=s.replace('MathMin(','Math.Min(').replace('MathMax(','Math.Max(').replace('MathAbs(','Math.Abs(')
    for name in ['ENTRADA_PERSONALIZADA','ENTRADA_PROTEGIDA','ENTRADA_BALANCEADA','ENTRADA_FLEXIBLE']:
        # C# enum members require qualification, except inside enum declaration.
        end=s.find('};')
        if end>=0:
            s=s[:end+2]+re.sub(r'\b'+name+r'\b','ENUM_ENTRY_MODE.'+name,s[end+2:])
    return s

regime=function(base,'DetectRegime')
regime=regime[regime.index('    double emaFast'):regime.index('    UpdateRegimeParameters();')]
regime='public static void OriginalRegime(double close) { int score=0; string reasons="";\n'+regime+'\n}'
entry=function(base,'CheckEntrySignals')
entry=entry[entry.index('    double atr = g_atrBuffer[0];'):entry.index('    //--- Ejecutar entrada')]
entry=re.sub(r'Print\(.*?\);','',entry,flags=re.S)
entry=entry.replace('ENUM_ORDER_TYPE orderType','int orderType')
entry='''public static int OriginalEntry(EvoSnapshot s) {
bool gotConfirmed=InpRequireCandleConfirmation;
MqlRates previousBar=s.previous;
double close=gotConfirmed?s.confirmed.close:s.current.close;
'''+entry+'\nreturn entrySignal?(orderType==ORDER_TYPE_BUY?1:-1):0;\n}'

support='''
public const int ORDER_TYPE_BUY=0, ORDER_TYPE_SELL=1;
public static bool EvoUseERFilter=false;
public static double EvoMinER=.3;
public static bool EvoUseBBFilter=false;
public static bool EvoUseOBVFilter=false;
public class EvoFrameContext { public bool valid; public int direction; public string regime; public double adx; }
public struct MqlRates { public double close; }
public class EvoSnapshot {
 public double[] atr=new double[3], adx=new double[3], rsi=new double[3], fast=new double[3], slow=new double[3], support=new double[3], resistance=new double[3], average=new double[3];
 public MqlRates current,confirmed,previous;
 public string regime,reason,buyChecks,sellChecks;
 public int direction,confidence,signal;
 public double er; public bool erValid;
 public bool obvValid; public double obvDelta;
 public bool bbValid;
 public double bbLower,bbMiddle,bbUpper;
}
static double[] g_atrBuffer,g_adxBuffer,g_rsiBuffer,g_emaFastBuffer,g_emaSlowBuffer,g_supportBuffer,g_resistanceBuffer,g_atrMediaBuffer;
static string g_currentRegime; static int g_trendDirection,g_regimeConfidence;
static int ArraySize(double[] a) { return a.Length; }
static double SymbolInfoDouble(string symbol,int property) { return .01; }
const string _Symbol="SYNTHETIC"; const int SYMBOL_POINT=0;
public static int Run() {
 Random r=new Random(7132601);
 for(int n=0;n<5000;n++) {
  InpModoEntrada=(ENUM_ENTRY_MODE)(n%4); InpRequireADX=n%2==0;
  InpRequireCandleConfirmation=n%3!=0; InpRequireFreshBreakout=n%5!=0;
  InpUsarFiltroDireccionEMA=n%7!=0; InpBloquearLateralConADXAlto=n%11!=0;
  InpTradeDirection=new string[]{"both","buy","sell","invalid"}[n%4];
  EvoSnapshot s=new EvoSnapshot();
  for(int i=0;i<3;i++) {
   s.atr[i]=1+r.NextDouble()*10; s.adx[i]=r.NextDouble()*60; s.rsi[i]=r.NextDouble()*100;
   s.fast[i]=90+r.NextDouble()*20; s.slow[i]=90+r.NextDouble()*20;
   s.support[i]=90+r.NextDouble()*10; s.resistance[i]=100+r.NextDouble()*10;
   s.average[i]=1+r.NextDouble()*10;
  }
  s.current.close=85+r.NextDouble()*30; s.confirmed.close=85+r.NextDouble()*30; s.previous.close=85+r.NextDouble()*30;
  g_atrBuffer=s.atr; g_adxBuffer=s.adx; g_rsiBuffer=s.rsi;
  g_emaFastBuffer=s.fast; g_emaSlowBuffer=s.slow; g_supportBuffer=s.support;
  g_resistanceBuffer=s.resistance; g_atrMediaBuffer=s.average;
  OriginalRegime(InpRequireCandleConfirmation?s.confirmed.close:s.current.close);
  int old=OriginalEntry(s);
  EvoEvaluate(s,.01,false,true);
  if(old!=s.signal || g_currentRegime!=s.regime || g_trendDirection!=s.direction || g_regimeConfidence!=s.confidence)
    throw new Exception("Analysis mismatch sample "+n);
 }
 // Integration: optional Bollinger confirms or blocks, never originates a signal.
 InpModoEntrada=ENUM_ENTRY_MODE.ENTRADA_PERSONALIZADA;
 InpTradeDirection="both"; InpRequireFreshBreakout=false; InpRequireCandleConfirmation=true;
 EvoSnapshot b=new EvoSnapshot();
 for(int i=0;i<3;i++) { b.atr[i]=2; b.adx[i]=30; b.rsi[i]=50; b.fast[i]=100; b.slow[i]=99; b.support[i]=95; b.resistance[i]=105; b.average[i]=2; }
 b.current.close=110; b.confirmed.close=110; b.previous.close=109;
 b.bbValid=true; b.bbLower=100; b.bbMiddle=111; b.bbUpper=120;
 EvoEvaluate(b,.01); if(b.signal!=1) throw new Exception("Base BUY missing");
 EvoUseBBFilter=true; EvoEvaluate(b,.01); if(b.signal!=0) throw new Exception("BB failed to block");
 b.bbMiddle=108; EvoEvaluate(b,.01); if(b.signal!=1) throw new Exception("BB failed to confirm");
 b.bbValid=false; EvoEvaluate(b,.01); if(b.signal!=0) throw new Exception("Missing BB did not block");
 EvoUseBBFilter=false; EvoEvaluate(b,.01); if(b.signal!=1) throw new Exception("Context BB changed entry");
 if(!EvoBollingerAllows(-1,"TENDENCIA",true,90,80,100,120)) throw new Exception("Trend SELL");
 if(!EvoBollingerAllows(1,"LATERAL",true,80,80,100,120)) throw new Exception("Range BUY boundary");
 if(!EvoBollingerAllows(-1,"LATERAL",true,120,80,100,120)) throw new Exception("Range SELL boundary");
 if(EvoBollingerAllows(1,"TENDENCIA",true,100,100,100,100)) throw new Exception("Flat BB passed");
 // OBV integration: context preserves BUY; enabled filter confirms, blocks and cannot originate entries.
 b.obvValid=true; b.obvDelta=-10; EvoEvaluate(b,.01); if(b.signal!=1) throw new Exception("OBV context changed BUY");
 EvoUseOBVFilter=true; EvoEvaluate(b,.01); if(b.signal!=0) throw new Exception("Opposing OBV passed BUY");
 b.obvDelta=10; EvoEvaluate(b,.01); if(b.signal!=1) throw new Exception("Rising OBV blocked BUY");
 b.obvDelta=0; EvoEvaluate(b,.01); if(b.signal!=0) throw new Exception("Flat OBV passed");
 b.obvDelta=10; b.obvValid=false; EvoEvaluate(b,.01); if(b.signal!=0) throw new Exception("Missing OBV passed");
 b.obvValid=true; b.support[1]=111; b.resistance[1]=120; EvoEvaluate(b,.01); if(b.signal!=0) throw new Exception("OBV created entry");
 for(int i=0;i<3;i++) { b.fast[i]=100; b.slow[i]=101; b.support[i]=95; b.resistance[i]=105; }
 b.current.close=90; b.confirmed.close=90; b.previous.close=91; b.obvDelta=-10;
 EvoEvaluate(b,.01); if(b.signal!=-1) throw new Exception("Falling OBV blocked SELL");
 b.obvDelta=10; EvoEvaluate(b,.01); if(b.signal!=0) throw new Exception("Rising OBV passed SELL");
 EvoUseOBVFilter=false; EvoEvaluate(b,.01); if(b.signal!=-1) throw new Exception("OBV context changed SELL");
 // Closed-context regimes and TP modes execute the production pure functions.
 EvoFrameContext f=new EvoFrameContext();
 EvoFrameRegime(110,105,104,100,2,2,30,f); if(!f.valid || f.regime!="TENDENCIA" || f.direction!=1) throw new Exception("MTF bullish");
 EvoFrameRegime(90,95,96,100,2,2,30,f); if(f.regime!="TENDENCIA" || f.direction!=-1) throw new Exception("MTF bearish");
 EvoFrameRegime(100,100,100,100,1,2,10,f); if(f.regime!="LATERAL" || f.direction!=0) throw new Exception("MTF lateral");
 EvoFrameRegime(100,100,100,100,2,1,10,f); if(f.regime!="MIXTO") throw new Exception("MTF mixed");
 if(EvoTargetDistance(false,8,3,12,2)!=24) throw new Exception("RR changed");
 if(EvoTargetDistance(true,8,3,12,2)!=24) throw new Exception("ATR target");
 if(EvoTargetDistance(true,8,3,5,9)!=24) throw new Exception("ATR depends on risk/RR");
 if(EvoTargetDistance(false,8,3,5,2)!=10) throw new Exception("RR ignores risk");
 // Closed-only evaluation uses index zero as the closed breakout level.
 b.current.close=110; b.confirmed.close=90; b.previous.close=104;
 for(int i=0;i<3;i++) { b.fast[i]=100; b.slow[i]=99; b.adx[i]=30; b.support[i]=95; b.resistance[i]=105; }
 b.resistance[1]=120; InpRequireCandleConfirmation=true;
 EvoEvaluate(b,.01,true); if(b.signal!=1) throw new Exception("Closed signal used wrong candle/level");
 EvoEvaluate(b,.01); if(b.signal==1) throw new Exception("Live evaluator changed");
 return 5028;
}
'''
bb=(root/'BollingerRules.mqh').read_text(encoding='utf-8-sig')
result='using System; public class EvolutionAnalysisTests {\n'+adapt(inputs)+support+adapt(regime)+adapt(entry)+adapt(function(bb,'EvoBollingerAllows'))+adapt(function(shared,'EvoEvaluate'))+adapt(function((root/'MultiTimeframe.mqh').read_text(encoding='utf-8-sig'),'EvoFrameRegime'))+adapt(function((root/'TargetRules.mqh').read_text(encoding='utf-8-sig'),'EvoTargetDistance'))+'\n}'
(root/'tests/Analysis113Adapter.cs').write_text(result,encoding='utf-8-sig')
