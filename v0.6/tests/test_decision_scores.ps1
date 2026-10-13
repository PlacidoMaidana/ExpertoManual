$ErrorActionPreference="Stop"
$mgmtPath = Join-Path $PSScriptRoot "..\ManagementMode.mqh"
$regimePath = Join-Path $PSScriptRoot "..\MarketRegime.mqh"
$scoresPath = Join-Path $PSScriptRoot "..\DecisionScores.mqh"
$rulesPath = Join-Path $PSScriptRoot "..\ThesisRules.mqh"

function Convert-Mqh([string]$path) {
  $source = Get-Content -Raw -LiteralPath $path
  $source = [regex]::Replace($source,"(?m)^#.*$","")
  $source = $source.Replace("const ","")
  $source = [regex]::Replace($source,"(?s)enum ENUM_EVO_\w+\s*\{.*?\};","")
  $source = $source.Replace("MathIsValidNumber(","IsFinite(")
  $source = $source.Replace("MathMin(","Math.Min(").Replace("MathMax(","Math.Max(")
  $source = $source.Replace("MathRound(","Math.Round(").Replace("MathAbs(","Math.Abs(")
  $source = [regex]::Replace($source,"(?m)^(int|double|bool|string|void) (Evo\w+)\(", 'public static $1 $2(')
  $source = $source.Replace("erTacticalMax,erExtensionMin,extensionScore,tacticalScore,protectionScore", "erTacticalMax,erExtensionMin,ref extensionScore,ref tacticalScore,ref protectionScore")
  # C# ref params
  $source = [regex]::Replace($source,"int &(\w+)",'ref int $1')
  $source = [regex]::Replace($source,'\bout\b','scoreText')
  $source = [regex]::Replace($source,'\bbase\b','basis')
  return $source
}

$regime = Convert-Mqh $regimePath
$mgmt = Convert-Mqh $mgmtPath
$mgmt = $mgmt -replace "MarketRegime\.mqh",""
$scores = Convert-Mqh $scoresPath
$scores = $scores -replace "MarketRegime\.mqh","" -replace "ManagementMode\.mqh",""
# Strip MQL input group leftovers
$scores = [regex]::Replace($scores,"(?m)^input group.*$","")
$scores = [regex]::Replace($scores,"(?m)^input int EvoCandidateScoreMin.*$","public static int EvoCandidateScoreMin = 55;")
$scores = [regex]::Replace($scores,"(?m)^input int EvoCommitScoreMin.*$","public static int EvoCommitScoreMin = 72;")
$scores = [regex]::Replace($scores,"(?m)^input int EvoScoreBarWidth.*$","public static int EvoScoreBarWidth = 10;")
$rules = Convert-Mqh $rulesPath

$constants = @"
public const int EVO_REGIME_INDETERMINADO=0;
public const int EVO_REGIME_TENDENCIA_ALCISTA_ACTIVA=1;
public const int EVO_REGIME_TENDENCIA_BAJISTA_ACTIVA=2;
public const int EVO_REGIME_ALCISTA_CONSOLIDACION=3;
public const int EVO_REGIME_BAJISTA_CONSOLIDACION=4;
public const int EVO_REGIME_LATERAL=5;
public const int EVO_REGIME_TRANSICION=6;
public const int EVO_MGMT_NORMAL=0;
public const int EVO_MGMT_EXTENSION=1;
public const int EVO_MGMT_TACTICAL=2;
public const int EVO_MGMT_PROTECTION=3;
public const int EVO_MGMT_WAIT=4;
public const int EVO_MGMT_EXTENSION_CAND=5;
public const int EVO_MGMT_TACTICAL_CAND=6;
public const int EVO_MGMT_PROTECTION_CAND=7;
public static string StringFormat(string format,params object[] args) {
 foreach(object value in args) {
  var token=System.Text.RegularExpressions.Regex.Match(format,@"%[+\-.0-9]*[dfs]");
  if(!token.Success) break;
  format=format.Substring(0,token.Index)+Convert.ToString(value,System.Globalization.CultureInfo.InvariantCulture)+format.Substring(token.Index+token.Length);
 }
 return format;
}
public static bool IsFinite(double value) { return !double.IsNaN(value) && !double.IsInfinity(value); }
"@

$checks = @"
public static int Run() {
  int e=0,t=0,p=0;
  // GWT-020 hard extension still works via scored path when hard fires
  int m=EvoClassifyManagementModeScored(EVO_REGIME_TENDENCIA_ALCISTA_ACTIVA,38,true,1.2,true,0.72,0.60,1,0.30,0.60,55,72,ref e,ref t,ref p);
  if(m!=EVO_MGMT_EXTENSION) throw new Exception("GWT-020 scored extension missed: "+m+" E"+e+" T"+t+" P"+p);

  // GWT-021 noisy tactical hard
  m=EvoClassifyManagementModeScored(EVO_REGIME_TENDENCIA_BAJISTA_ACTIVA,36,true,1.0,true,0.13,0.20,-1,0.30,0.60,55,72,ref e,ref t,ref p);
  if(m!=EVO_MGMT_TACTICAL) throw new Exception("GWT-021 scored tactical missed: "+m);

  // GWT-022 protection hard
  m=EvoClassifyManagementModeScored(EVO_REGIME_TENDENCIA_ALCISTA_ACTIVA,30,true,-1.0,true,0.40,0.55,1,0.30,0.60,55,72,ref e,ref t,ref p);
  if(m!=EVO_MGMT_PROTECTION) throw new Exception("GWT-022 scored protection missed: "+m);

  // GWT-030 intermediate ER rising + strong DI context -> EXTENSION CANDIDATE (not hard)
  // ER 0.43 rising from 0.35, ADX 37 rising — no hard extension (ER<0.60), no hard tactical (ER>=0.30)
  m=EvoClassifyManagementModeScored(EVO_REGIME_TENDENCIA_ALCISTA_ACTIVA,37,true,1.0,true,0.43,0.35,1,0.30,0.60,55,72,ref e,ref t,ref p);
  if(m!=EVO_MGMT_EXTENSION_CAND && m!=EVO_MGMT_EXTENSION) throw new Exception("GWT-030 intermediate ER candidate expected, got "+m+" E"+e+" T"+t+" P"+p);
  if(!EvoManagementIsCandidate(m) && m!=EVO_MGMT_EXTENSION) throw new Exception("GWT-030 should be candidate or commit");
  string reason=EvoManagementReason(m,37,true,1.0,true,0.43,0.35,70,100,e,t,p);
  if(string.IsNullOrEmpty(reason) || reason.IndexOf("ER")<0) throw new Exception("Reason empty/no ER: "+reason);

  // Consolidation wait
  m=EvoClassifyManagementModeScored(EVO_REGIME_ALCISTA_CONSOLIDACION,38,true,-1.0,true,0.60,0.68,1,0.30,0.60,55,72,ref e,ref t,ref p);
  if(m!=EVO_MGMT_WAIT && m!=EVO_MGMT_PROTECTION && m!=EVO_MGMT_PROTECTION_CAND) throw new Exception("Consolid wait-like missed: "+m);

  // Score clamps
  if(EvoClampScore(-5)!=0 || EvoClampScore(150)!=100 || EvoClampScore(50.4)!=50) throw new Exception("Clamp");
  if(EvoStrengthScore(50,true,0)<90) throw new Exception("Strength high ADX");
  if(EvoEfficiencyScore(true,0.13,0.20)>30) throw new Exception("Efficiency low ER");
  if(EvoDiDominanceScore(40,5)<70) throw new Exception("DI dominance");
  if(EvoMtfAlignmentScore(true,1,true,1,true,1)!=100) throw new Exception("MTF align");
  if(EvoMtfAlignmentScore(true,1,true,-1,true,1)!=20) throw new Exception("MTF conflict");

  string bar=EvoScoreBar(50,10);
  if(bar.Length!=10 || bar.IndexOf("#")<0) throw new Exception("Score bar");

  string pend=EvoPendingConfirmationText(true,1,EVO_REGIME_LATERAL,true,0.2,0.5);
  if(pend.IndexOf("pendiente")<0) throw new Exception("Pending text");

  // Candidate name helpers
  if(EvoManagementModeName(EVO_MGMT_EXTENSION_CAND).IndexOf("CANDIDATA")<0) throw new Exception("Cand name");
  if(!EvoManagementIsCandidate(EVO_MGMT_TACTICAL_CAND)) throw new Exception("IsCandidate");
  if(EvoManagementIsCandidate(EVO_MGMT_NORMAL)) throw new Exception("Normal not candidate");

  return 16;
}
"@

$code = "using System; public class EvolutionDecisionScoresTests {" + $constants + $regime + $mgmt + $scores + $rules + $checks + "}"
try {
  Add-Type -TypeDefinition $code -ErrorAction Stop
  $result = [EvolutionDecisionScoresTests]::Run()
  Write-Host "OK decision scores tests: $result"
} catch {
  Write-Host "COMPILE/RUN ERROR:"
  Write-Host $_.Exception.Message
  if($_.Exception.InnerException){ Write-Host $_.Exception.InnerException.Message }
  # dump first errors if TypeLoad
  $err = $_.Exception.ToString()
  if($err.Length -gt 2000){ $err = $err.Substring(0,2000) }
  Write-Host $err
  exit 1
}