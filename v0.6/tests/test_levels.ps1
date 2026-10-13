$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$source=Get-Content -Raw -LiteralPath (Join-Path $root 'MonitorLevels.mqh')
$start=$source.IndexOf('void EvoNearestPivots(')
$end=$source.IndexOf('void EvoNearestLevels(')
$source=$source.Substring($start,$end-$start).Replace('void EvoNearestPivots(', 'public static void EvoNearestPivots(')
$source=$source.Replace('const MqlRates &rates[]','MqlRates[] rates').Replace('const ','')
$source=$source.Replace('double &support','out double support').Replace('double &resistance','out double resistance')
$source=$source.Replace('bool &supportFallback','out bool supportFallback').Replace('bool &resistanceFallback','out bool resistanceFallback')
$source=$source.Replace('DBL_MAX','double.MaxValue').Replace('ArraySize(rates)','rates.Length').Replace('MathMin(','Math.Min(').Replace('MathMax(','Math.Max(')
$test=@'
public struct MqlRates { public double low,high; }
static void Check(bool ok) { if(!ok) throw new Exception("Pivot test failed"); }
public static void Run() {
 double[] lows={1,9,4,8,6,9,2}, highs={100,11,10,13,10,15,16};
 MqlRates[] r=new MqlRates[7];
 for(int i=0;i<7;i++) { r[i].low=lows[i]; r[i].high=highs[i]; }
 double s,t; bool sf,tf;
 EvoNearestPivots(r,5,1,10,out s,out t,out sf,out tf);
 Check(s==6 && t==13 && !sf && !tf);
 r[0].high=1000000; r[0].low=.0001;
 EvoNearestPivots(r,5,1,10,out s,out t,out sf,out tf);
 Check(s==6 && t==13); // live bar cannot confirm a pivot
 EvoNearestPivots(r,5,1,20,out s,out t,out sf,out tf);
 Check(s==6 && t==0); // no invented resistance on wrong side
 EvoNearestPivots(r,5,1,2,out s,out t,out sf,out tf);
 Check(s==0 && t==13);
 EvoNearestPivots(r,6,1,10,out s,out t,out sf,out tf);
 Check(s==0 && t==0); // insufficient older neighbors
 for(int i=0;i<7;i++) { r[i].low=i+1; r[i].high=i+11; }
 EvoNearestPivots(r,5,1,10,out s,out t,out sf,out tf);
 Check(s==3 && t==16 && sf && tf); // same extreme fallback as old monitor
 Console.WriteLine("PASS: 6 nearest-level scenarios using MQL body with C# syntax adaptation.");
}
'@
Add-Type -TypeDefinition ('using System; public class LevelTests {'+$source+$test+'}')
[LevelTests]::Run()
