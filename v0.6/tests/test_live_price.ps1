$ErrorActionPreference='Stop'
$src=Get-Content -Raw (Join-Path (Split-Path -Parent $PSScriptRoot) 'MarketEvidence.mqh')
$a=$src.IndexOf('int EvoLiveDirection('); $b=$src.IndexOf('int EvoEvidenceSign(', $a)
$methods=$src.Substring($a,$b-$a).Replace('const ','').Replace('MathAbs(','System.Math.Abs(').Replace('int EvoLive','public static int EvoLive')
$checks=@'
public static void Run() {
 if(EvoLiveDirection(-2.5)!=-1 || EvoLiveStrength(-2.5)!=3) throw new System.Exception("Crash must be bearish exceptional");
 if(EvoLiveDirection(2.5)!=1 || EvoLiveStrength(2.5)!=3) throw new System.Exception("Rally symmetry");
 if(EvoLiveStrength(-1)!=2 || EvoLiveStrength(.25)!=1 || EvoLiveStrength(.249)!=0) throw new System.Exception("Threshold boundaries");
 if(EvoLiveDirection(.05)!=0 || EvoLiveDirection(-.05)!=0 || EvoLiveDirection(0)!=0) throw new System.Exception("Small displacement must remain neutral");
 if(EvoLiveDirection(-.1)!=-1 || EvoLiveStrength(-.1)!=0) throw new System.Exception("Small bearish move is not strong");
}
'@
Add-Type -TypeDefinition ('public class LivePriceTests {'+$methods+$checks+'}')
[LivePriceTests]::Run()
Write-Output 'PASS: live direction, crash/rally symmetry and strength thresholds.'
