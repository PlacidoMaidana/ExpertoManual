$ErrorActionPreference='Stop'
$src=Get-Content -Raw (Join-Path (Split-Path -Parent $PSScriptRoot) 'MarketEvidence.mqh')
$a=$src.IndexOf('void EvoRecentBreak('); $b=$src.IndexOf('string EvoRecentBreakText(', $a)
$method=$src.Substring($a,$b-$a).Replace('const ','').Replace('void EvoRecentBreak','public static void EvoRecentBreak').Replace('MqlRates &rates[]','MqlRates[] rates').Replace('EvoMarketEvidence &e','EvoMarketEvidence e').Replace('ArraySize(rates)','rates.Length').Replace('MathMin(','Math.Min(').Replace('MathMax(','Math.Max(').Replace('DBL_MAX','double.MaxValue')
$checks=@'
public class MqlRates { public double high,low,close; public long time; }
public class EvoMarketEvidence { public int recentBreakSide,recentBreakPhase; public long recentBreakTime; public double recentBreakLevel; }
public static void Run() {
 foreach(int side in new int[]{-1,1}) {
  var bars=new MqlRates[32]; for(int i=0;i<32;i++) bars[i]=new MqlRates{high=101,low=99,close=100,time=i};
  var none=new EvoMarketEvidence(); EvoRecentBreak(bars,1,none); if(none.recentBreakSide!=0) throw new Exception("No invented break");
  for(int i=24;i<32;i++) { bars[i].close=100+side*3; bars[i].low=Math.Min(99,bars[i].close); bars[i].high=Math.Max(101,bars[i].close); }
  var e=new EvoMarketEvidence(); EvoRecentBreak(bars,1,e);
  if(e.recentBreakSide!=side || e.recentBreakTime!=24 || e.recentBreakPhase!=2) throw new Exception("Break persists after moving window absorbs move");
  bars[31].close=100;
  e=new EvoMarketEvidence(); EvoRecentBreak(bars,1,e); if(e.recentBreakPhase!=3) throw new Exception("Recovered level identified");
 }
}
'@
Add-Type -TypeDefinition ('using System; public class RecentBreakTests {'+$method+$checks+'}')
[RecentBreakTests]::Run()
Write-Output 'PASS: persistent recent breakout, recovered level, BUY/SELL symmetry and no false flat-range break.'
