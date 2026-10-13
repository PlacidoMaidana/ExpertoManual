$ErrorActionPreference='Stop'
$s=Get-Content -Raw 'v0.6/OperationSimulator.mqh'
$a=$s.IndexOf('bool EvoSimWithinTolerance(')
$b=$s.IndexOf('void EvoSimStatus(', $a)
$f=$s.Substring($a,$b-$a).Replace('const ','').Replace('bool EvoSimWithinTolerance(', 'public static bool EvoSimWithinTolerance(')
Add-Type -TypeDefinition ('public class SimTolerance {'+$f+'}')
if(-not [SimTolerance]::EvoSimWithinTolerance(0.1,0.2,10,10.1,2)){throw 'normal move blocked'}
if([SimTolerance]::EvoSimWithinTolerance(0.21,0.2,10,10,2)){throw 'price limit bypassed'}
if([SimTolerance]::EvoSimWithinTolerance(0.1,0.2,10,10.3,2)){throw 'risk limit bypassed'}
if(-not [SimTolerance]::EvoSimWithinTolerance(0.1,0.2,10,9,2)){throw 'lower risk blocked'}
if([SimTolerance]::EvoSimWithinTolerance(0.1,0,10,10,2)){throw 'zero tolerance bypassed'}
Write-Output 'PASS: 5 cases on actual tolerance function.'
