$ErrorActionPreference='Stop'
$src=Get-Content -Raw (Join-Path (Split-Path -Parent $PSScriptRoot) 'MarketEvidence.mqh')
$a=$src.IndexOf('int EvoLayerState('); $b=$src.IndexOf('void EvoEvidenceLayers(', $a)
$method=$src.Substring($a,$b-$a).Replace('const ','').Replace('int EvoLayerState','public static int EvoLayerState')
$tests=@'
public static void Run() {
 if(EvoLayerState(-1,105,106,110,100,.1)!=1) throw new System.Exception("Bounce is not reversal");
 if(EvoLayerState(-1,110.2,110.3,110,100,.1)!=3) throw new System.Exception("Two closes confirm opposing break");
 if(EvoLayerState(-1,109,110.3,110,100,.1)==3) throw new System.Exception("Single close cannot confirm");
 if(EvoLayerState(-1,99.8,99.7,110,100,.1)!=4) throw new System.Exception("Downward continuation");
 if(EvoLayerState(1,105,104,110,100,.1)!=1) throw new System.Exception("Bullish pullback symmetry");
 if(EvoLayerState(1,99.8,99.7,110,100,.1)!=3) throw new System.Exception("Bullish structure breakdown");
 if(EvoLayerState(1,110.2,110.3,110,100,.1)!=4) throw new System.Exception("Upward continuation");
 if(EvoLayerState(0,105,106,110,100,.1)!=0 || EvoLayerState(1,105,106,0,0,.1)!=0) throw new System.Exception("Unknown structure stays unknown");
}
'@
Add-Type -TypeDefinition ('public class LayerTests {'+$method+$tests+'}')
[LayerTests]::Run()
Write-Output 'PASS: bounce, pullback, two-close confirmation, continuation, symmetry and missing structure.'
