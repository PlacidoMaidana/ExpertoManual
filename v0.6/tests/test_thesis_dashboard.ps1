$ErrorActionPreference='Stop'
$src=Get-Content -Raw -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) 'ThesisDashboard.mqh')
$a=$src.IndexOf('color EvoThesisRelationInk(')
$b=$src.IndexOf('void EvoThesisDirectionRow(')
$fn=$src.Substring($a,$b-$a).Replace('const ','').Replace('color EvoThesisRelationInk(','public static string EvoThesisRelationInk(').Replace('string EvoThesisTransition(','public static string EvoThesisTransition(').Replace('clrGold','"attention"').Replace('clrLimeGreen','"favourable"').Replace('clrSalmon','"opposed"')
Add-Type -TypeDefinition ('public class ThesisDisplayChecks {'+$fn+'}')
foreach($side in @(1,-1)) {
 if([ThesisDisplayChecks]::EvoThesisRelationInk($side,$side,$true)-ne 'favourable') { throw 'Aligned direction must favour BUY and SELL' }
 if([ThesisDisplayChecks]::EvoThesisRelationInk($side,-$side,$true)-ne 'opposed') { throw 'Opposed direction' }
 if([ThesisDisplayChecks]::EvoThesisRelationInk($side,$side,$false)-ne 'attention') { throw 'Missing data must not appear healthy' }
 if([ThesisDisplayChecks]::EvoThesisTransition(-$side,$side,$side)-ne 'MEJORO') { throw 'Improved direction' }
 if([ThesisDisplayChecks]::EvoThesisTransition($side,-$side,$side)-ne 'EMPEORO') { throw 'Deteriorated direction' }
 if([ThesisDisplayChecks]::EvoThesisTransition($side,$side,$side)-ne 'SIN CAMBIO') { throw 'Stable direction' }
}
'PASS: thesis display BUY/SELL symmetry, missing data and direction transitions.'
