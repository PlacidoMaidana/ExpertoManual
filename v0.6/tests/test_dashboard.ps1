$ErrorActionPreference='Stop'
$src=Get-Content -Raw -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) 'AnalysisDashboard.mqh')
$a=$src.IndexOf('double EvoDashboardFraction(')
$b=$src.IndexOf('void EvoDashboardRect(')
$fn=$src.Substring($a,$b-$a).Replace('const ','').Replace('double EvoDashboardFraction(','public static double EvoDashboardFraction(').Replace('string EvoDashboardRSIEvent(','public static string EvoDashboardRSIEvent(').Replace('MathMax(','Math.Max(').Replace('MathMin(','Math.Min(')
$fn=$fn.Replace('int EvoDashboardCross(','public static int EvoDashboardCross(').Replace('int EvoDashboardSARSide(','public static int EvoDashboardSARSide(')
Add-Type -TypeDefinition ('using System; public class DashboardChecks {'+$fn+'}')
if([DashboardChecks]::EvoDashboardFraction(75,50)-ne 1) { throw 'Upper scale clamp' }
if([DashboardChecks]::EvoDashboardFraction(-1,50)-ne 0) { throw 'Lower scale clamp' }
if([DashboardChecks]::EvoDashboardFraction(1,0)-ne 0) { throw 'Unavailable scale' }
if([DashboardChecks]::EvoDashboardFraction(0.15,1)-ne 0.15) { throw 'ER scale' }
if([DashboardChecks]::EvoDashboardRSIEvent(51,49)-ne 'CRUZA 50 ARRIBA') { throw 'RSI up' }
if([DashboardChecks]::EvoDashboardRSIEvent(49,51)-ne 'CRUZA 50 ABAJO') { throw 'RSI down' }
if([DashboardChecks]::EvoDashboardRSIEvent(31,29)-ne 'SALE DE SOBREVENTA') { throw 'Exit oversold' }
if([DashboardChecks]::EvoDashboardRSIEvent(69,71)-ne 'SALE DE SOBRECOMPRA') { throw 'Exit overbought' }
if([DashboardChecks]::EvoDashboardRSIEvent(55,54)-ne 'SIN CRUCE NUEVO') { throw 'No false event' }
if([DashboardChecks]::EvoDashboardCross(82,79,75,78)-ne 1) { throw 'Stochastic cross up' }
if([DashboardChecks]::EvoDashboardCross(19,22,24,21)-ne -1) { throw 'Stochastic cross down' }
if([DashboardChecks]::EvoDashboardCross(90,85,88,84)-ne 0) { throw 'Extreme alone is not a cross' }
if([DashboardChecks]::EvoDashboardCross(50,50,49,50)-ne 0) { throw 'Equality is not a cross' }
if([DashboardChecks]::EvoDashboardSARSide(101,100)-ne 1) { throw 'SAR below price' }
if([DashboardChecks]::EvoDashboardSARSide(99,100)-ne -1) { throw 'SAR above price' }
if([DashboardChecks]::EvoDashboardSARSide(100,100)-ne 0) { throw 'SAR at price' }
'PASS: dashboard bounds, RSI transitions, Stochastic crosses and SAR direction.'
