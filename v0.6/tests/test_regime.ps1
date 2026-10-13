$ErrorActionPreference='Stop'
$source=Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot '../MarketRegime.mqh')
$source=[regex]::Replace($source,'(?m)^#.*$','')
$source=$source.Replace('const ','')
# Keep numeric constants only; C# enums do not compare freely with int.
$source=[regex]::Replace($source,'(?s)enum ENUM_EVO_LOCAL_REGIME\s*\{.*?\};','')
$source=$source.Replace('MathIsValidNumber(','IsFinite(').Replace('MathMin(','Math.Min(').Replace('MathMax(','Math.Max(')
$source=[regex]::Replace($source,'(?m)^(int|double|bool|string) (Evo\w+)\(', 'public static $1 $2(')
$constants=@"
public const int EVO_REGIME_INDETERMINADO=0;
public const int EVO_REGIME_TENDENCIA_ALCISTA_ACTIVA=1;
public const int EVO_REGIME_TENDENCIA_BAJISTA_ACTIVA=2;
public const int EVO_REGIME_ALCISTA_CONSOLIDACION=3;
public const int EVO_REGIME_BAJISTA_CONSOLIDACION=4;
public const int EVO_REGIME_LATERAL=5;
public const int EVO_REGIME_TRANSICION=6;
"@
$source=$constants+$source
$checks=@"
public static bool IsFinite(double value) { return !double.IsNaN(value) && !double.IsInfinity(value); }
public static int Run() {
  // Capture case: ADX still high but falling, ER efficient but falling, compressed range.
  int r=EvoClassifyLocalRegime(38,true,-1.24,true,0.60,0.68,true,0.90,0.25,1,1.20,0.45,25,0.30);
  if(r!=EVO_REGIME_ALCISTA_CONSOLIDACION) throw new Exception("Bull consolidation missed: "+r);
  if(!EvoLocalRegimeIsConsolidation(r)) throw new Exception("Consolidation flag");
  if(!EvoSuggestionNeedsConfirmation(1,r,0.55,true,0.60)) throw new Exception("Caution expected");
  if(EvoSuggestionAction(1,true)!="ESPERAR CONFIRMACION (sesgo compra)") throw new Exception("Action text");
  // Active trend: rising ADX, efficient ER, not compressed.
  r=EvoClassifyLocalRegime(38,true,1.50,true,0.72,0.60,true,2.40,1.20,1,1.20,0.45,25,0.30);
  if(r!=EVO_REGIME_TENDENCIA_ALCISTA_ACTIVA) throw new Exception("Active bull missed: "+r);
  if(EvoSuggestionNeedsConfirmation(1,r,1.50,true,0.60)) throw new Exception("Active trend over-cautioned");
  // Bear consolidation.
  r=EvoClassifyLocalRegime(32,true,-0.80,true,0.55,0.70,true,1.00,0.30,-1,1.20,0.45,25,0.30);
  if(r!=EVO_REGIME_BAJISTA_CONSOLIDACION) throw new Exception("Bear consolidation missed: "+r);
  // True lateral: weak ADX + compression.
  r=EvoClassifyLocalRegime(12,true,-0.20,true,0.20,0.25,true,0.80,0.20,0,1.20,0.45,25,0.30);
  if(r!=EVO_REGIME_LATERAL) throw new Exception("Lateral missed: "+r);
  // Room-only caution without consolidation label.
  if(!EvoSuggestionNeedsConfirmation(1,EVO_REGIME_TENDENCIA_ALCISTA_ACTIVA,0.40,true,0.60))
    throw new Exception("Room caution missed");
  if(EvoADXInterpretation(38,true,-1.24).IndexOf("DEBILITANDOSE")<0) throw new Exception("ADX text");
  if(EvoERInterpretation(true,0.60,0.68).IndexOf("DECRECIENTE")<0) throw new Exception("ER text");
  if(EvoLocalRegimeName(EVO_REGIME_ALCISTA_CONSOLIDACION)!="ALCISTA EN CONSOLIDACION") throw new Exception("Name");
  if(EvoClassifyLocalRegime(38,true,1,true,.7,.6,false,0,0,1,1.2,.45,25,.3)!=0) throw new Exception("Missing range called active");
  if(!EvoSuggestionNeedsConfirmation(1,1,0,false,.6)) throw new Exception("Missing room passed");
  if(EvoSuggestionNeedsConfirmation(0,3,.4,true,.6)) throw new Exception("Created suggestion");
  if(EvoClassifyLocalRegime(38,true,1,true,.7,.6,true,2,1,-1,1.2,.45,25,.3)!=2) throw new Exception("Bear symmetry");
  return 16;
}
"@
Add-Type -TypeDefinition ('using System; public class EvolutionRegimeTests {'+$source+$checks+'}')
[EvolutionRegimeTests]::Run()
