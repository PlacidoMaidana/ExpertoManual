$ErrorActionPreference='Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
# Prefer local v0.5 modules
$mgmtPath = Join-Path $PSScriptRoot '..\ManagementMode.mqh'
$regimePath = Join-Path $PSScriptRoot '..\MarketRegime.mqh'
$rulesPath = Join-Path $PSScriptRoot '..\ThesisRules.mqh'

function Convert-Mqh([string]$path) {
  $source = Get-Content -Raw -LiteralPath $path
  $source = [regex]::Replace($source,'(?m)^#.*$','')
  $source = $source.Replace('const ','')
  $source = [regex]::Replace($source,'(?s)enum ENUM_EVO_\w+\s*\{.*?\};','')
  $source = $source.Replace('MathIsValidNumber(','IsFinite(')
  $source = $source.Replace('MathMin(','Math.Min(').Replace('MathMax(','Math.Max(')
  $source = [regex]::Replace($source,'(?m)^(int|double|bool|string) (Evo\w+)\(', 'public static $1 $2(')
  return $source
}

$regime = Convert-Mqh $regimePath
# ManagementMode includes MarketRegime; strip include already by # removal but keep only mgmt functions
$mgmt = Convert-Mqh $mgmtPath
# Remove leftover bare include residue if any
$mgmt = $mgmt -replace 'MarketRegime\.mqh',''
$rules = Convert-Mqh $rulesPath
# ThesisRules has defensive stop - keep pure MFE helpers and stop helpers

$constants = @'
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
public static bool IsFinite(double value) { return !double.IsNaN(value) && !double.IsInfinity(value); }
'@

$checks = @'
public static int Run() {
  // GWT-020: clean bullish extension — active regime, rising ADX, high ER
  int m=EvoClassifyManagementMode(EVO_REGIME_TENDENCIA_ALCISTA_ACTIVA,38,true,1.2,true,0.72,0.60,1,0.30,0.60);
  if(m!=EVO_MGMT_EXTENSION) throw new Exception("GWT-020 extension missed: "+m);

  // GWT-021: noisy bearish capture — active bearish, ADX rising/high, ER very low 0.13
  m=EvoClassifyManagementMode(EVO_REGIME_TENDENCIA_BAJISTA_ACTIVA,36,true,1.0,true,0.13,0.20,-1,0.30,0.60);
  if(m!=EVO_MGMT_TACTICAL) throw new Exception("GWT-021 tactical missed: "+m);
  if(EvoManagementModeName(m)!="CAPTURA TACTICA") throw new Exception("Name tactical");
  if(EvoManagementModeHint(m).IndexOf("RUIDOSA")<0) throw new Exception("Hint noisy");

  // GWT-022: protection when directed + ADX falling + ER falling
  m=EvoClassifyManagementMode(EVO_REGIME_TENDENCIA_ALCISTA_ACTIVA,30,true,-1.0,true,0.40,0.55,1,0.30,0.60);
  if(m!=EVO_MGMT_PROTECTION) throw new Exception("GWT-022 protection missed: "+m);

  // Consolidation => wait (not extension)
  m=EvoClassifyManagementMode(EVO_REGIME_ALCISTA_CONSOLIDACION,38,true,-1.0,true,0.60,0.68,1,0.30,0.60);
  if(m!=EVO_MGMT_WAIT) throw new Exception("Consolidation should wait: "+m);

  // Lateral wait
  m=EvoClassifyManagementMode(EVO_REGIME_LATERAL,12,true,-0.2,true,0.20,0.25,0,0.30,0.60);
  if(m!=EVO_MGMT_WAIT) throw new Exception("Lateral wait missed: "+m);

  // Tactical would-arm diagnostic threshold
  if(!EvoTacticalWouldArm(EVO_MGMT_TACTICAL,0.45,0.40)) throw new Exception("Tactical arm missed");
  if(EvoTacticalWouldArm(EVO_MGMT_TACTICAL,0.20,0.40)) throw new Exception("Tactical arm too early");
  if(EvoTacticalWouldArm(EVO_MGMT_EXTENSION,1.0,0.40)) throw new Exception("Extension should not tactical-arm");

  // Never widen stop
  if(EvoNeverWidenStop(true,100,99)!=100) throw new Exception("BUY widen blocked");
  if(EvoNeverWidenStop(true,100,101)!=101) throw new Exception("BUY tighten allowed");
  if(EvoNeverWidenStop(false,100,101)!=100) throw new Exception("SELL widen blocked");
  if(EvoNeverWidenStop(false,100,99)!=99) throw new Exception("SELL tighten allowed");

  // MFE/MAE monotonicity
  double mfe=0;
  mfe=EvoMfeUpdate(mfe,0.5); if(mfe!=0.5) throw new Exception("MFE set");
  mfe=EvoMfeUpdate(mfe,0.3); if(mfe!=0.5) throw new Exception("MFE decreased");
  mfe=EvoMfeUpdate(mfe,0.8); if(mfe!=0.8) throw new Exception("MFE increase");
  double mae=0;
  mae=EvoMaeUpdate(mae,-0.4); if(Math.Abs(mae-0.4)>1e-9) throw new Exception("MAE adverse");
  mae=EvoMaeUpdate(mae,0.2); if(Math.Abs(mae-0.4)>1e-9) throw new Exception("MAE must keep max adverse");
  mae=EvoMaeUpdate(mae,-0.9); if(Math.Abs(mae-0.9)>1e-9) throw new Exception("MAE worse");

  // Invalid thresholds fall back to NORMAL
  m=EvoClassifyManagementMode(EVO_REGIME_TENDENCIA_ALCISTA_ACTIVA,38,true,1,true,0.7,0.6,1,0.70,0.60);
  if(m!=EVO_MGMT_NORMAL) throw new Exception("Bad thresholds should NORMAL");

  return 12;
}
'@

$code = 'using System; public class EvolutionManagementModeTests {' + $constants + $regime + $mgmt + $rules + $checks + '}'
Add-Type -TypeDefinition $code
$result = [EvolutionManagementModeTests]::Run()
Write-Host "OK management mode tests: $result"
