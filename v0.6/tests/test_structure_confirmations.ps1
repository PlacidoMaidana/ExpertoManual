$ErrorActionPreference='Stop'
$src=Get-Content -Raw -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) 'MarketEvidence.mqh')
$start=$src.IndexOf('int EvoEvidenceSign(')
$end=$src.IndexOf('EvoMarketEvidence evoEvidenceCache;')
$methods=$src.Substring($start,$end-$start)
$confirm=$src.Substring($src.IndexOf('void EvoEvidenceConfirm('),$src.IndexOf('string EvoEvidenceConfirmation(')-$src.IndexOf('void EvoEvidenceConfirm('))
$confirm=[regex]::Replace($confirm,'e.confirmationDetail=StringFormat\([\s\S]*?EvoEvidenceDirection\(e.momentum\)\);','')
$confirm=[regex]::Replace($confirm,'e.confirmationDetail="[^"]*";','')
$confirm=$confirm.Replace('MqlRates prior[]; ArrayResize(prior,count);','MqlRates[] prior=new MqlRates[count];').Replace('EvoMarketEvidence channel; ZeroMemory(channel);','EvoMarketEvidence channel=new EvoMarketEvidence();').Replace('EvoEvidenceStructure(prior,0,side,highs,lows);','EvoEvidenceStructure(prior,0,ref side,ref highs,ref lows);')
$methods+=$confirm

$methods=$methods.Replace('const ','').Replace('MqlRates &rates[]','MqlRates[] rates').Replace('double &values[]','double[] values').Replace('double &result[]','ref double[] result').Replace('EvoMarketEvidence &e','EvoMarketEvidence e')
$methods=$methods.Replace('int &side','ref int side').Replace('int &highs','ref int highs').Replace('int &lows','ref int lows')
$methods=[regex]::Replace($methods,'(?m)^(int|bool|string|void) (Evo\w+)\(','public static $1 $2(')
$methods=$methods.Replace('MathAbs(','Math.Abs(').Replace('MathMin(','Math.Min(').Replace('MathMax(','Math.Max(').Replace('ArraySize(rates)','rates.Length').Replace('ArraySize(values)','values.Length')
$methods=$methods.Replace('ArrayResize(result,n); ArrayInitialize(result,0);','result=new double[n];').Replace('DBL_MAX','double.MaxValue')
$test=@'
public const double EvoMomentumMinHistATR=.02,EvoMomentumMinMoveATR=.25; public const int EvoChannelLookback=64;
public class MqlRates { public double high,low,close,open; public long time; }
public class EvoMarketEvidence { public double channelFirst,channelLast,channelLowOffset,channelHighOffset,rangeLow,rangeHigh; public long first; public int referenceSide,confirmation,breakCloses,momentum; public double invalidation,confirmationMargin; }
static void Check(bool ok,string message) { if(!ok) throw new Exception(message); }
public static void Run() {
 foreach(int direction in new int[]{1,-1}) {
  var bars=new MqlRates[66];
  for(int i=0;i<64;i++) { double center=100+i*.5+2*Math.Sin(i*Math.PI/4); bars[i]=new MqlRates{close=direction*center,high=direction*center+.4,low=direction*center-.4}; }
  for(int i=64;i<66;i++) bars[i]=new MqlRates{close=direction*50,high=direction*50+.4,low=direction*50-.4};
  var evidence=new EvoMarketEvidence{momentum=-direction};
  EvoEvidenceConfirm(bars,1,evidence);
  Check(evidence.referenceSide==direction && evidence.confirmation==3 && evidence.breakCloses==2,"Confirmed structural break symmetric");
  evidence=new EvoMarketEvidence{momentum=0}; EvoEvidenceConfirm(bars,1,evidence);
  Check(evidence.confirmation==2,"Unconfirmed momentum cannot confirm reversal");
  bars[64].close=direction*131; bars[65].close=direction*130;
  evidence=new EvoMarketEvidence{momentum=-direction}; EvoEvidenceConfirm(bars,1,evidence);
  Check(evidence.confirmation==1,"Adverse candle inside structure is only possible pullback");
 }

 Check(EvoEvidenceMomentum(.05,.4)==1,"Aligned BUY");
 Check(EvoEvidenceMomentum(-.05,-.4)==-1,"Aligned SELL");
 Check(EvoEvidenceMomentum(.05,-.4)==0,"Conflict must be neutral");
 Check(EvoEvidenceMomentum(.01,.1)==0,"Weak must be neutral");
 Check(EvoEvidenceAdjustment(1,-1)==-10 && EvoEvidenceAdjustment(-1,1)==-10,"Opposed penalty symmetric");
 Check(EvoEvidenceEntryGate(true,1,1,false,false,true,true,true,4,3)==0,"Complete setup accepted");
 Check(EvoEvidenceEntryGate(true,-1,-1,false,false,true,true,true,4,3)==0,"SELL symmetric");
 Check(EvoEvidenceEntryGate(true,1,1,true,false,true,true,true,4,3)==1,"Missing data blocks");
 Check(EvoEvidenceEntryGate(false,1,1,false,false,true,true,true,4,3)==2,"Transition blocks");
 Check(EvoEvidenceEntryGate(true,1,1,false,true,true,true,true,4,3)==3,"MTF conflict blocks");
 Check(EvoEvidenceEntryGate(true,1,-1,false,false,true,true,true,4,3)==4,"Opposed momentum blocks");
 Check(EvoEvidenceEntryGate(true,1,1,false,false,false,true,true,4,3)==5,"No level blocks");
 Check(EvoEvidenceEntryGate(true,1,1,false,false,true,false,true,4,3)==6,"No candle blocks");
 Check(EvoEvidenceEntryGate(true,1,1,false,false,true,true,true,2,3)==7,"Insufficient room blocks");
 Check(EvoEvidenceEntryGate(true,1,1,false,false,true,true,false,4,3)==7,"Unknown room blocks");
 MqlRates[] rates=new MqlRates[64];
 for(int i=0;i<rates.Length;i++) rates[i]=new MqlRates {close=100+i*.5+Math.Sin(i)*.2,high=101+i*.5,low=99+i*.5,time=i+1};
 var e=new EvoMarketEvidence(); EvoEvidenceChannel(rates,0,e);
 Check(e.channelLast>e.channelFirst,"Rising regression");
 for(int i=0;i<rates.Length;i++) {
  double center=e.channelFirst+(e.channelLast-e.channelFirst)*i/(rates.Length-1);
  Check(center+e.channelLowOffset<=rates[i].low+1e-8 && center+e.channelHighOffset>=rates[i].high-1e-8,"Envelope covers highs/lows");
 }
 for(int i=0;i<rates.Length;i++) {rates[i].close=200-rates[i].close;double hi=rates[i].high;rates[i].high=200-rates[i].low;rates[i].low=200-hi;}
 EvoEvidenceChannel(rates,0,e); Check(e.channelLast<e.channelFirst,"Falling regression");
 for(int i=0;i<rates.Length;i++) {
  rates[i].close=100+i*.1+Math.Sin(i*Math.PI/4)*2;
  rates[i].high=rates[i].close+.3; rates[i].low=rates[i].close-.3;
 }
 int trendSide=0,trendHighs=0,trendLows=0;
 EvoEvidenceStructure(rates,0,ref trendSide,ref trendHighs,ref trendLows);
 Check(trendSide==1 && trendHighs>=2 && trendLows>=2,"Higher highs/lows detected");
 for(int i=0;i<rates.Length;i++) {double hi=rates[i].high;rates[i].high=200-rates[i].low;rates[i].low=200-hi;}
 EvoEvidenceStructure(rates,0,ref trendSide,ref trendHighs,ref trendLows);
 Check(trendSide==-1,"Lower highs/lows detected symmetrically");
 double[] ema=null; EvoEvidenceEMA(new double[]{1,2,3,4,5},3,ref ema);
 Check(Math.Abs(ema[2]-2)<1e-8 && Math.Abs(ema[3]-3)<1e-8 && Math.Abs(ema[4]-4)<1e-8,"EMA seed and recurrence");
 for(int i=0;i<rates.Length;i++) {rates[i].close=100;rates[i].low=99;rates[i].high=101;}
 EvoEvidenceChannel(rates,0,e); Check(Math.Abs(e.channelLast-e.channelFirst)<1e-8,"Horizontal range");
 int side=0,highs=0,lows=0; EvoEvidenceStructure(rates,0,ref side,ref highs,ref lows);
 Check(side==0,"Flat data cannot invent structure");
 rates[63].high=999;rates[63].low=1;
 EvoEvidenceStructure(rates,0,ref side,ref highs,ref lows); Check(side==0 && highs==0 && lows==0,"Unconfirmed endpoint excluded");
 Console.WriteLine("PASS: momentum, entry blockers, BUY/SELL symmetry, regression envelopes, confirmed pivots.");
}
'@
Add-Type -TypeDefinition ('using System; public class MarketEvidenceTests {'+$methods+$test+'}')
[MarketEvidenceTests]::Run()
