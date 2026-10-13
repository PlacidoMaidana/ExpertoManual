$ErrorActionPreference='Stop'
$src=Get-Content -Raw (Join-Path (Split-Path -Parent $PSScriptRoot) 'OperationSimulator.mqh')
$start=$src.IndexOf('bool EvoSimPendingPriceValid(')
$end=$src.IndexOf('double evoSimEntry=', $start)
$method=$src.Substring($start,$end-$start).Replace('const ','').Replace('bool EvoSimPendingPriceValid','public static bool EvoSimPendingPriceValid')
$boundaryStart=$src.IndexOf('double EvoSimPendingBoundary(')
$boundaryEnd=$src.IndexOf('string EvoSimPendingGuide(', $boundaryStart)
$method+=$src.Substring($boundaryStart,$boundaryEnd-$boundaryStart).Replace('const ','').Replace('double EvoSimPendingBoundary','public static double EvoSimPendingBoundary').Replace('MathCeil(','System.Math.Ceiling(').Replace('MathFloor(','System.Math.Floor(')
$tests=@'
public static void Run() {
 double bid=100,ask=102,gap=1;
 if(!EvoSimPendingPriceValid(1,101,bid,ask,gap) || EvoSimPendingPriceValid(1,101.01,bid,ask,gap)) throw new System.Exception("Buy Limit boundary");
 if(!EvoSimPendingPriceValid(2,103,bid,ask,gap) || EvoSimPendingPriceValid(2,102.99,bid,ask,gap)) throw new System.Exception("Buy Stop boundary");
 if(!EvoSimPendingPriceValid(3,101,bid,ask,gap) || EvoSimPendingPriceValid(3,100.99,bid,ask,gap)) throw new System.Exception("Sell Limit boundary");
 if(!EvoSimPendingPriceValid(4,99,bid,ask,gap) || EvoSimPendingPriceValid(4,99.01,bid,ask,gap)) throw new System.Exception("Sell Stop boundary");
 if(EvoSimPendingPriceValid(0,100,bid,ask,gap)) throw new System.Exception("Market is not pending");
 for(int mode=1;mode<=4;mode++) {
  double boundary=EvoSimPendingBoundary(mode,100.023,100.187,.037,.05);
  if(!EvoSimPendingPriceValid(mode,boundary,100.023,100.187,.037)) throw new System.Exception("Tick rounding must stay outside broker boundary");
  if(System.Math.Abs(boundary/.05-System.Math.Round(boundary/.05))>1e-8) throw new System.Exception("Boundary must align to tick");
 }
 if(EvoSimPendingPriceValid(2,103,104,105,1)) throw new System.Exception("Quote overtaking prepared Buy Stop must invalidate it");
 if(!EvoSimPendingPriceValid(2,EvoSimPendingBoundary(2,104,105,1,.05),104,105,1)) throw new System.Exception("Updated Buy Stop must become valid");
}
'@
Add-Type -TypeDefinition ("public class PendingPrices {"+$method+$tests+"}")
[PendingPrices]::Run()
Write-Output 'PASS: four pending types use correct Bid/Ask and minimum distance boundaries.'
