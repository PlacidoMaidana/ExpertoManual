$ErrorActionPreference='Stop'
$src=Get-Content -Raw (Join-Path (Split-Path -Parent $PSScriptRoot) 'HighRiskSuggestions.mqh')
$a=$src.IndexOf('bool Evo113NewSignal('); $b=$src.IndexOf('void Evo113Poll(')
$methods=$src.Substring($a,$b-$a).Replace('const ','').Replace('double &sl','out double sl').Replace('double &tp','out double tp')
$methods=$methods.Replace('bool Evo113NewSignal(', 'public static bool Evo113NewSignal(').Replace('void Evo113Distances(', 'public static void Evo113Distances(').Replace('MathMin(','Math.Min(').Replace('MathMax(','Math.Max(')
$tests=@'
static double EvoSuggest113TrendSL=1.5,EvoSuggest113LateralSL=2,EvoSuggest113RR=2,EvoSuggest113MinTPATR=.5;
static int EvoSuggest113MaxSLPoints=2000,EvoSuggest113MinTPPoints=100;
static void Check(bool ok,string reason) { if(!ok) throw new Exception(reason); }
public static void Run() {
 Check(Evo113NewSignal(1,0,0),"First BUY");
 Check(!Evo113NewSignal(1,1,0),"Persistent signal must not steal focus on next bar");
 Check(!Evo113NewSignal(1,0,1),"Repeated BUY within bar");
 Check(Evo113NewSignal(-1,1,1),"Opposite SELL may be proposed");
 Check(!Evo113NewSignal(0,1,0),"Neutral must not open simulator");
 Check(!Evo113NewSignal(-1,0,3),"Both sides consumed");
 double sl,tp;
 Evo113Distances(4,true,.01,out sl,out tp); Check(sl==6 && tp==12,"Trend ATR/RR");
 Evo113Distances(4,false,.01,out sl,out tp); Check(sl==8 && tp==16,"Lateral ATR/RR");
 Evo113Distances(30,true,.01,out sl,out tp); Check(sl==20 && tp==40,"SL points cap");
 EvoSuggest113RR=.5; Evo113Distances(4,true,.01,out sl,out tp); Check(Math.Abs(tp-7.2)<1e-9,"Minimum 1.2 RR");
 EvoSuggest113MinTPPoints=2000; Evo113Distances(4,true,.01,out sl,out tp); Check(tp==20,"Minimum technical TP");
 Console.WriteLine("PASS: 11 edge/deduplication and v1.13 SL/TP scenarios.");
}
'@
Add-Type -TypeDefinition ('using System; public class Suggestion113Tests {'+$methods+$tests+'}')
[Suggestion113Tests]::Run()
if($src -match '\.(Buy|Sell|PositionOpen)\s*\(' -or $src -match 'EvoSimConfirm\s*\(' -or $src -match 'OrderSend\s*\(') { throw 'Suggestion must never execute orders' }
Write-Output 'PASS: proposal module has no order submission or confirmation calls.'
