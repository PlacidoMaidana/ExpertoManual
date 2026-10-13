$ErrorActionPreference='Stop'
$src=Get-Content -Raw (Join-Path (Split-Path -Parent $PSScriptRoot) 'PatternRules.mqh')
$src=$src.Substring($src.IndexOf('bool EvoPatternDouble('))
$src=$src.Replace('#endif','').Replace('const ','').Replace('MathAbs(','Math.Abs(').Replace('MathMin(','Math.Min(').Replace('MathMax(','Math.Max(')
$src=[regex]::Replace($src,'(?m)^(bool|int) (Evo(?:Pattern|Elliott|Wave3)\w+)\(','public static $1 $2(')
$tests=@'
static void Check(bool ok,string message) { if(!ok) throw new Exception(message); }
public static void Run() {
 Check(EvoWave3State(100,110,105,104,109,109,111,1)==1,"Live breakout is provisional");
 Check(EvoWave3State(100,110,105,104,109,111,111,1)==2,"Only one closed breakout");
 Check(EvoWave3State(100,110,105,104,111,112,112,1)==3,"Two closed breakouts");
 Check(EvoWave3State(100,110,105,100,111,112,112,1)==-1,"Origin violation overrides breakout");
 Check(EvoWave3State(100,110,99,98,111,112,112,1)==-1,"Wave 2 beyond origin invalid");
 Check(EvoWave3State(100,110,105,104,109,109,109,1)==0,"Wait below trigger");
 Check(EvoElliottRules(0,3,1,6,4,8,1)==5,"Impulse geometric hypothesis");
 Check(EvoElliottRules(0,3,-1,6,4,8,1)==1,"Wave 2 cannot cross origin");
 Check(EvoElliottRules(0,3,1,2,4,8,1)==2,"Wave 3 must exceed wave 1");
 Check(EvoElliottRules(0,3,1,6,2,8,1)==3,"Ordinary wave 4 overlap rejected");
 Check(EvoElliottRules(0,4,3,6,5,10,1)==4,"Wave 3 cannot be shortest");
 Check(EvoElliottRules(0,.1,.05,.3,.2,.4,1)==0,"Small fluctuations rejected");
 Check(EvoPatternDouble(10,8,10.2,1),"Double top valid");
 Check(!EvoPatternDouble(10,9.8,10.2,1),"Shallow consolidation rejected");
 Check(!EvoPatternDouble(10,8,10.5,1),"Asymmetric double rejected");
 Check(EvoPatternHCH(10,8,11,8.1,10.2,1),"HCH valid");
 Check(!EvoPatternHCH(10,8,10.2,8.1,10.1,1),"Head too small");
 Check(!EvoPatternHCH(10,9.9,11,9.9,10.2,1),"Neck too shallow");
 Check(!EvoPatternHCH(10,8,11,8.1,9,1),"Shoulders too unequal");
 Check(EvoPatternWick(9.7,10,8,9.8,1,1),"Lower wick qualifies");
 Check(EvoPatternWick(-9.7,-8,-10,-9.8,1,-1),"Upper wick symmetry");
 Check(!EvoPatternWick(9,10,8,10,1,1),"Ordinary candle rejected");
 Check(!EvoPatternWick(9.97,10,9.8,9.98,1,1),"Tiny range rejected");
 Check(!EvoPatternWick(10,10,10,10,1,1),"Zero range safe");
 for(int side=-1;side<=1;side+=2) {
  Check(EvoPatternState(side,side*7.8,side*8,side*7.9,side*8,-side*11,.1)==0,"No breakout");
  Check(EvoPatternState(side,side*7.8,side*8,side*8.3,side*8,-side*11,.1)==1,"Single close only");
  Check(EvoPatternState(side,side*8.2,side*8,side*8.3,side*8,-side*11,.1)==2,"Two closes confirm");
  Check(EvoPatternState(side,side*8.2,side*8,-side*11.2,side*8,-side*11,.1)==3,"Invalidation takes priority");
 }
}
'@
Add-Type -TypeDefinition ('using System; public class PatternTests {'+$src+$tests+'}')
[PatternTests]::Run()
Write-Output 'PASS: 32 shape, wick, Elliott geometry, confirmation and invalidation checks.'
