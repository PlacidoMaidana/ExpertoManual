$ErrorActionPreference='Stop'
$source=Get-Content -Raw -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) 'OnDemandAnalysis.mqh')
$start=$source.IndexOf('int EvoReportEntryScore(')
$end=$source.IndexOf('void EvoReportOpportunity(')
$methods=$source.Substring($start,$end-$start).Replace('const ','').Replace('int &confidence','ref int confidence')
$methods=$methods.Replace('int EvoReportEntryScore(','public static int EvoReportEntryScore(').Replace('double EvoReportMarketScore(','public static double EvoReportMarketScore(')
$methods=$methods.Replace('MathAbs(','Math.Abs(').Replace('MathMin(','Math.Min(').Replace('MathMax(','Math.Max(')
$test=@"
static void Check(bool ok,string name) { if(!ok) throw new Exception(name); }
public static void Run() {
 int confidence=0;
 double score=EvoReportMarketScore(4279.08,6.708,39.95,4298.44,4275.01,19.42,11.2,17.2,-0.46113,-0.16,4295.27,ref confidence);
 Check(score==0 && confidence==30,"Attached report: neutral / 30");
 int buy=EvoReportEntryScore(3,3,25,1,90,90,110,ref confidence);
 int sell=EvoReportEntryScore(-3,-3,75,-1,110,90,110,ref confidence);
 Check(buy==11 && sell==-11,"SELL confirmation must be symmetric with BUY");
 int neutral=EvoReportEntryScore(0,0,25,1,90,90,110,ref confidence);
 Check(neutral==0,"No invented directional confirmation without SR bias");
 Check(EvoReportEntryScore(-3,0,39.95,-0.46113,4279.08,4275.01,4298.44,ref confidence)==-3,"Sample with correctly normalized bearish MTF");
 score=EvoReportMarketScore(110,2,75,111,89,35,90,90,1,6,100,ref confidence);
 Check(score==3 && confidence==62,"Trend: RSI/Stoch contextual, ROC active");
 Console.WriteLine("PASS: attached report, signed SELL/BUY, neutral SR, corrected MTF, trend scoring.");
}
"@
Add-Type -TypeDefinition ('using System; public class AdvancedReportTests {'+$methods+$test+'}')
[AdvancedReportTests]::Run()
$cases=python (Join-Path $PSScriptRoot 'report_reference_cases.py') | ConvertFrom-Json
if($LASTEXITCODE -ne 0) { throw 'Python reference failed' }
foreach($case in $cases) {
  $a=$case.args; $confidence=0
  $score=[AdvancedReportTests]::EvoReportMarketScore($a[0],$a[1],$a[2],$a[3],$a[4],$a[5],$a[6],$a[7],$a[8],$a[9],$a[10],[ref]$confidence)
  if([Math]::Abs($score-$case.score) -gt 0.000001 -or $confidence -ne $case.confidence) { throw 'Mismatch with original Python scoring' }
}
Write-Output "PASS: 300 cases matched original advanced_signal_analysis (same indicator values)."
