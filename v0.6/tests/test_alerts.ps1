$ErrorActionPreference='Stop'
$source=Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot '../AlertRules.mqh')
$source=[regex]::Replace($source,'(?m)^#.*$','')
$source=$source.Replace('const ','').Replace('int EvoCross(', 'public static int EvoCross(').Replace('bool EvoAlertTransition(', 'public static bool EvoAlertTransition(')
$checks=@"
public static int Run() {
 if(EvoCross(29,31,30)!=1) throw new System.Exception("RSI exit oversold");
 if(EvoCross(31,29,30)!=-1) throw new System.Exception("RSI enter oversold");
 if(EvoCross(69,71,70)!=1) throw new System.Exception("RSI enter overbought");
 if(EvoCross(71,69,70)!=-1) throw new System.Exception("RSI exit overbought");
 if(EvoCross(24,26,25)!=1) throw new System.Exception("ADX rise");
 if(EvoCross(26,27,25)!=0) throw new System.Exception("Repeated ADX");
 if(EvoCross(30,30,30)!=0) throw new System.Exception("Unchanged threshold");
 if(EvoCross(30,31,30)!=1) throw new System.Exception("Boundary crossing");
 if(EvoAlertTransition(0,100,90)) throw new System.Exception("Startup replay");
 if(EvoAlertTransition(100,100,90)) throw new System.Exception("Same bar replay");
 if(!EvoAlertTransition(100,110,100)) throw new System.Exception("New bar ignored");
 if(EvoAlertTransition(100,130,120)) throw new System.Exception("Gap replay");
 if(EvoAlertTransition(110,100,90)) throw new System.Exception("Old bar replay");
 int emitted=0; long last=100;
 for(int tick=0;tick<1000;tick++) { if(EvoAlertTransition(last,110,100)) emitted++; last=110; }
 if(emitted!=1) throw new System.Exception("Tick deduplication");
 return 14;
}
"@
Add-Type -TypeDefinition ('public class EvolutionAlertTests {'+$source+$checks+'}')
[EvolutionAlertTests]::Run()
