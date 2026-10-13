$ErrorActionPreference='Stop'
$source=Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot '../ThesisRules.mqh')
$source=[regex]::Replace($source,'(?m)^#.*$','')
$source=$source.Replace('const ','').Replace('MathMin(', 'Math.Min(').Replace('MathMax(', 'Math.Max(')
$source=[regex]::Replace($source,'(?m)^(int|double) (Evo\w+)\(', 'public static $1 $2(')
$checks=@"
public static int Run() {
 if(EvoThesisLoss(-1,-1,1)!=0) throw new Exception("Initial contradiction counted");
 if(EvoThesisLoss(1,-1,1)!=1) throw new Exception("Lost BUY support");
 if(EvoThesisLoss(-1,0,-1)!=1) throw new Exception("Lost SELL support");
 if(EvoThesisState(0,0,false)!=0 || EvoThesisState(0,2,false)!=1 || EvoThesisState(1,2,false)!=2 || EvoThesisState(3,0,false)!=3 || EvoThesisState(3,0,true)!=4) throw new Exception("Health classification");
 if(EvoDefensiveStop(true,95,95,2,1,.25,.5,90,90)!=93) throw new Exception("Initial BUY protection");
 if(EvoDefensiveStop(true,97,95,2,1,.25,.5,90,93)!=96) throw new Exception("BUY rebound tightening");
 if(EvoDefensiveStop(false,105,105,2,1,.25,.5,110,110)!=107) throw new Exception("Initial SELL protection");
 if(EvoDefensiveStop(false,103,105,2,1,.25,.5,110,107)!=104) throw new Exception("SELL rebound tightening");
 if(EvoDefensiveStop(true,97,95,2,1,.25,.5,90,98)!=98) throw new Exception("Existing tighter SL loosened");
 if(EvoDefensiveStop(true,102,95,2,1,.25,.5,90,98)!=101) throw new Exception("Recovery lost defensive management");
 if(EvoDefensiveStop(true,95,95,2,1,.25,.5,0,90)!=90) throw new Exception("Missing initial stop accepted");
 Random random=new Random(7821);
 for(int i=0;i<2000;i++) {
  double sl=80+random.NextDouble()*15, best=95+random.NextDouble()*10;
  double candidate=EvoDefensiveStop(true,best,95,2,1,.25,.5,80,sl);
  if(candidate<sl || candidate<80) throw new Exception("BUY risk widened");
  double mirror=EvoDefensiveStop(false,200-best,105,2,1,.25,.5,120,200-sl);
  if(Math.Abs(candidate+mirror-200)>1e-9 || mirror>200-sl) throw new Exception("SELL asymmetry");
 }
 if(EvoThesisStreak(true,true,1)!=2) throw new Exception("Consecutive invalidation");
 if(EvoThesisStreak(false,true,8)!=1) throw new Exception("Gap retains invalidation streak");
 if(EvoThesisStreak(true,false,8)!=0) throw new Exception("Recovery fails to reset");
 return 2014;
}
"@
Add-Type -TypeDefinition ('using System; public class EvolutionThesisTests { static bool MathIsValidNumber(double value) { return !double.IsNaN(value) && !double.IsInfinity(value); }'+$source+$checks+'}')
[EvolutionThesisTests]::Run()
