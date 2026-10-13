using System; public class SafeInputsTests {
public const int EVO_TP_RR=0,EVO_TP_ATR=1;
static bool MathIsValidNumber(double x) { return !double.IsNaN(x) && !double.IsInfinity(x); }
static string StringFormat(string format,params object[] args) { return format; }
public static double EvoSLATR=1.5;
public static double EvoRR=2.0;
public static int EvoTPMode=EVO_TP_RR;
public static double EvoTPATR=3.0;
public static bool EvoSetMissingSL=true;
public static bool EvoSetMissingTP=true;
public static bool EvoIncremental=true;
public static double EvoStage1TriggerR=0.40;
public static double EvoStage1StopR=-0.15;
public static double EvoStage2TriggerR=0.70;
public static double EvoStage2StopR=0.05;
public static double EvoStage3TriggerR=1.00;
public static double EvoStage3StopR=0.30;
public static bool EvoBreakEven=true;
public static double EvoBETriggerATR=1.0;
public static double EvoBEOffsetATR=0.0;
public static bool EvoTrailing=true;
public static bool EvoTrailingAfterBE=true;
public static double EvoTrailingTriggerATR=0.0;
public static double EvoTrailingDistanceATR=0.5;
public static int EvoTrailingStepPoints=5;
public static bool EvoSmartExit=true;
public static bool EvoSmartClose=true;
public static double EvoSmartMinProfitR=0.70;
public static int EvoSmartScore=5;
public static int EvoSmartLookback=50;
public static double EvoSmartSRATR=0.25;
public static double EvoSmartADXDrop=8.0;
public static double EvoSmartATRContract=0.75;
public static double EvoSmartOffsetATR=0.0;
public static int EvoDeviationPoints=20;
public static string evoManagementInputWarning="";
public static double evoApplied_EvoSLATR=1.5;
public static double evoApplied_EvoRR=2.0;
public static int evoApplied_EvoTPMode=EVO_TP_RR;
public static double evoApplied_EvoTPATR=3.0;
public static bool evoApplied_EvoSetMissingSL=true;
public static bool evoApplied_EvoSetMissingTP=true;
public static bool evoApplied_EvoIncremental=true;
public static double evoApplied_EvoStage1TriggerR=0.40;
public static double evoApplied_EvoStage1StopR=-0.15;
public static double evoApplied_EvoStage2TriggerR=0.70;
public static double evoApplied_EvoStage2StopR=0.05;
public static double evoApplied_EvoStage3TriggerR=1.00;
public static double evoApplied_EvoStage3StopR=0.30;
public static bool evoApplied_EvoBreakEven=true;
public static double evoApplied_EvoBETriggerATR=1.0;
public static double evoApplied_EvoBEOffsetATR=0.0;
public static bool evoApplied_EvoTrailing=true;
public static bool evoApplied_EvoTrailingAfterBE=true;
public static double evoApplied_EvoTrailingTriggerATR=0.0;
public static double evoApplied_EvoTrailingDistanceATR=0.5;
public static int evoApplied_EvoTrailingStepPoints=5;
public static bool evoApplied_EvoSmartExit=true;
public static bool evoApplied_EvoSmartClose=true;
public static double evoApplied_EvoSmartMinProfitR=0.70;
public static int evoApplied_EvoSmartScore=5;
public static int evoApplied_EvoSmartLookback=50;
public static double evoApplied_EvoSmartSRATR=0.25;
public static double evoApplied_EvoSmartADXDrop=8.0;
public static double evoApplied_EvoSmartATRContract=0.75;
public static double evoApplied_EvoSmartOffsetATR=0.0;
public static int evoApplied_EvoDeviationPoints=20;
public static void EvoLoadManagementInputs()
{
   evoManagementInputWarning="";
   evoApplied_EvoSLATR=EvoSLATR;
   evoApplied_EvoRR=EvoRR;
   evoApplied_EvoTPMode=EvoTPMode;
   evoApplied_EvoTPATR=EvoTPATR;
   evoApplied_EvoSetMissingSL=EvoSetMissingSL;
   evoApplied_EvoSetMissingTP=EvoSetMissingTP;
   evoApplied_EvoIncremental=EvoIncremental;
   evoApplied_EvoStage1TriggerR=EvoStage1TriggerR;
   evoApplied_EvoStage1StopR=EvoStage1StopR;
   evoApplied_EvoStage2TriggerR=EvoStage2TriggerR;
   evoApplied_EvoStage2StopR=EvoStage2StopR;
   evoApplied_EvoStage3TriggerR=EvoStage3TriggerR;
   evoApplied_EvoStage3StopR=EvoStage3StopR;
   evoApplied_EvoBreakEven=EvoBreakEven;
   evoApplied_EvoBETriggerATR=EvoBETriggerATR;
   evoApplied_EvoBEOffsetATR=EvoBEOffsetATR;
   evoApplied_EvoTrailing=EvoTrailing;
   evoApplied_EvoTrailingAfterBE=EvoTrailingAfterBE;
   evoApplied_EvoTrailingTriggerATR=EvoTrailingTriggerATR;
   evoApplied_EvoTrailingDistanceATR=EvoTrailingDistanceATR;
   evoApplied_EvoTrailingStepPoints=EvoTrailingStepPoints;
   evoApplied_EvoSmartExit=EvoSmartExit;
   evoApplied_EvoSmartClose=EvoSmartClose;
   evoApplied_EvoSmartMinProfitR=EvoSmartMinProfitR;
   evoApplied_EvoSmartScore=EvoSmartScore;
   evoApplied_EvoSmartLookback=EvoSmartLookback;
   evoApplied_EvoSmartSRATR=EvoSmartSRATR;
   evoApplied_EvoSmartADXDrop=EvoSmartADXDrop;
   evoApplied_EvoSmartATRContract=EvoSmartATRContract;
   evoApplied_EvoSmartOffsetATR=EvoSmartOffsetATR;
   evoApplied_EvoDeviationPoints=EvoDeviationPoints;
}
public static string EvoStageInputError(double t1,double s1,double t2,double s2,double t3,double s3)
{
   if(!MathIsValidNumber(t1) || !MathIsValidNumber(t2) || !MathIsValidNumber(t3) || !MathIsValidNumber(s1) || !MathIsValidNumber(s2) || !MathIsValidNumber(s3)) return "Escalones: valor numerico no valido";
   if(t1<0 || t2<0 || t3<0) return "Escalones: TriggerR no admite negativos; StopR si puede ser negativo";
   if(t2<t1 || t3<t2) return "Escalones: TriggerR debe cumplir etapa 1 <= etapa 2 <= etapa 3";
   if(s1>=t1 || s2>=t2 || s3>=t3) return "Escalones: cada StopR debe ser menor que su TriggerR";
   if(s2<s1 || s3<s2) return "Escalones: StopR no debe retroceder entre etapas";
   return "";
}
public static void EvoManagementWarning(string message)
{
   if(evoManagementInputWarning!="") evoManagementInputWarning+="\n";
   evoManagementInputWarning+=message;
}
public static void EvoRepairManagementInputs()
{
   EvoLoadManagementInputs();
   string stageError=EvoStageInputError(evoApplied_EvoStage1TriggerR,evoApplied_EvoStage1StopR,evoApplied_EvoStage2TriggerR,evoApplied_EvoStage2StopR,evoApplied_EvoStage3TriggerR,evoApplied_EvoStage3StopR);
   if(stageError!="")
   {
      EvoManagementWarning(stageError+StringFormat(". Recibido trigger/stop: %.3f/%.3f; %.3f/%.3f; %.3f/%.3f. Aplicado: 0.40/-0.15; 0.70/0.05; 1.00/0.30 R",evoApplied_EvoStage1TriggerR,evoApplied_EvoStage1StopR,evoApplied_EvoStage2TriggerR,evoApplied_EvoStage2StopR,evoApplied_EvoStage3TriggerR,evoApplied_EvoStage3StopR));
      evoApplied_EvoStage1TriggerR=0.40; evoApplied_EvoStage1StopR=-0.15;
      evoApplied_EvoStage2TriggerR=0.70; evoApplied_EvoStage2StopR=0.05;
      evoApplied_EvoStage3TriggerR=1.00; evoApplied_EvoStage3StopR=0.30;
   }
   if(!MathIsValidNumber(evoApplied_EvoSLATR) || evoApplied_EvoSLATR<=0) { EvoManagementWarning("evoApplied_EvoSLATR incompatible: "+evoApplied_EvoSLATR.ToString()+". Aplicado predeterminado: 1.5"); evoApplied_EvoSLATR=1.5; }
   if(!MathIsValidNumber(evoApplied_EvoRR) || evoApplied_EvoRR<=0) { EvoManagementWarning("evoApplied_EvoRR incompatible: "+evoApplied_EvoRR.ToString()+". Aplicado predeterminado: 2.0"); evoApplied_EvoRR=2.0; }
   if(evoApplied_EvoTPMode!=EVO_TP_RR && evoApplied_EvoTPMode!=EVO_TP_ATR) { EvoManagementWarning("evoApplied_EvoTPMode incompatible: "+evoApplied_EvoTPMode.ToString()+". Aplicado predeterminado: EVO_TP_RR"); evoApplied_EvoTPMode=EVO_TP_RR; }
   if(!MathIsValidNumber(evoApplied_EvoTPATR) || evoApplied_EvoTPATR<=0) { EvoManagementWarning("evoApplied_EvoTPATR incompatible: "+evoApplied_EvoTPATR.ToString()+". Aplicado predeterminado: 3.0"); evoApplied_EvoTPATR=3.0; }
   if(!MathIsValidNumber(evoApplied_EvoBETriggerATR) || evoApplied_EvoBETriggerATR<0) { EvoManagementWarning("evoApplied_EvoBETriggerATR incompatible: "+evoApplied_EvoBETriggerATR.ToString()+". Aplicado predeterminado: 1.0"); evoApplied_EvoBETriggerATR=1.0; }
   if(!MathIsValidNumber(evoApplied_EvoBEOffsetATR) || evoApplied_EvoBEOffsetATR<0) { EvoManagementWarning("evoApplied_EvoBEOffsetATR incompatible: "+evoApplied_EvoBEOffsetATR.ToString()+". Aplicado predeterminado: 0.0"); evoApplied_EvoBEOffsetATR=0.0; }
   if(!MathIsValidNumber(evoApplied_EvoTrailingTriggerATR) || evoApplied_EvoTrailingTriggerATR<0) { EvoManagementWarning("evoApplied_EvoTrailingTriggerATR incompatible: "+evoApplied_EvoTrailingTriggerATR.ToString()+". Aplicado predeterminado: 0.0"); evoApplied_EvoTrailingTriggerATR=0.0; }
   if(!MathIsValidNumber(evoApplied_EvoTrailingDistanceATR) || evoApplied_EvoTrailingDistanceATR<=0) { EvoManagementWarning("evoApplied_EvoTrailingDistanceATR incompatible: "+evoApplied_EvoTrailingDistanceATR.ToString()+". Aplicado predeterminado: 0.5"); evoApplied_EvoTrailingDistanceATR=0.5; }
   if(evoApplied_EvoTrailingStepPoints<0) { EvoManagementWarning("evoApplied_EvoTrailingStepPoints incompatible: "+evoApplied_EvoTrailingStepPoints.ToString()+". Aplicado predeterminado: 5"); evoApplied_EvoTrailingStepPoints=5; }
   if(!MathIsValidNumber(evoApplied_EvoSmartMinProfitR) || evoApplied_EvoSmartMinProfitR<0) { EvoManagementWarning("evoApplied_EvoSmartMinProfitR incompatible: "+evoApplied_EvoSmartMinProfitR.ToString()+". Aplicado predeterminado: 0.70"); evoApplied_EvoSmartMinProfitR=0.70; }
   if(evoApplied_EvoSmartScore<=0) { EvoManagementWarning("evoApplied_EvoSmartScore incompatible: "+evoApplied_EvoSmartScore.ToString()+". Aplicado predeterminado: 5"); evoApplied_EvoSmartScore=5; }
   if(evoApplied_EvoSmartLookback<2 || evoApplied_EvoSmartLookback>10000) { EvoManagementWarning("evoApplied_EvoSmartLookback incompatible: "+evoApplied_EvoSmartLookback.ToString()+". Aplicado predeterminado: 50"); evoApplied_EvoSmartLookback=50; }
   if(!MathIsValidNumber(evoApplied_EvoSmartSRATR) || evoApplied_EvoSmartSRATR<0) { EvoManagementWarning("evoApplied_EvoSmartSRATR incompatible: "+evoApplied_EvoSmartSRATR.ToString()+". Aplicado predeterminado: 0.25"); evoApplied_EvoSmartSRATR=0.25; }
   if(!MathIsValidNumber(evoApplied_EvoSmartADXDrop) || evoApplied_EvoSmartADXDrop<=0) { EvoManagementWarning("evoApplied_EvoSmartADXDrop incompatible: "+evoApplied_EvoSmartADXDrop.ToString()+". Aplicado predeterminado: 8.0"); evoApplied_EvoSmartADXDrop=8.0; }
   if(!MathIsValidNumber(evoApplied_EvoSmartATRContract) || evoApplied_EvoSmartATRContract<0) { EvoManagementWarning("evoApplied_EvoSmartATRContract incompatible: "+evoApplied_EvoSmartATRContract.ToString()+". Aplicado predeterminado: 0.75"); evoApplied_EvoSmartATRContract=0.75; }
   if(!MathIsValidNumber(evoApplied_EvoSmartOffsetATR) || evoApplied_EvoSmartOffsetATR<0) { EvoManagementWarning("evoApplied_EvoSmartOffsetATR incompatible: "+evoApplied_EvoSmartOffsetATR.ToString()+". Aplicado predeterminado: 0.0"); evoApplied_EvoSmartOffsetATR=0.0; }
   if(evoApplied_EvoDeviationPoints<0) { EvoManagementWarning("evoApplied_EvoDeviationPoints incompatible: "+evoApplied_EvoDeviationPoints.ToString()+". Aplicado predeterminado: 20"); evoApplied_EvoDeviationPoints=20; }
}

static void Check(bool pass,string label) { if(!pass) throw new Exception(label); }
public static void Run() {
 EvoStage1TriggerR=-.5; EvoStage1StopR=-.8; EvoBETriggerATR=1.7;
 EvoRepairManagementInputs();
 Check(evoApplied_EvoStage1TriggerR==.4 && evoApplied_EvoStage1StopR==-.15,"negative trigger fallback");
 Check(evoApplied_EvoStage2TriggerR==.7 && evoApplied_EvoStage3TriggerR==1,"entire stage group restored");
 Check(evoApplied_EvoBETriggerATR==1.7,"valid BE preserved");
 Check(evoManagementInputWarning.Contains("negativos"),"reason visible");
 EvoStage1TriggerR=.2; EvoStage1StopR=-.8; EvoStage2TriggerR=1; EvoStage3TriggerR=.7;
 EvoRepairManagementInputs();
 Check(evoApplied_EvoStage2TriggerR==.7 && evoManagementInputWarning.Contains("etapa 3"),"order fallback");
 EvoStage2TriggerR=.4; EvoStage3TriggerR=.7; EvoStage2StopR=0; EvoStage3StopR=.2;
 EvoRepairManagementInputs();
 Check(evoApplied_EvoStage1StopR==-.8 && evoManagementInputWarning=="","negative stop valid, not corrected");
 EvoTrailingDistanceATR=-1; EvoSmartADXDrop=double.NaN;
 EvoRepairManagementInputs();
 Check(evoApplied_EvoTrailingDistanceATR==.5 && evoApplied_EvoSmartADXDrop==8,"invalid scalar fallback");
 Check(evoApplied_EvoStage2TriggerR==.4,"valid stages preserved");
 Console.WriteLine("PASS: 8 recovery checks using actual MQL load, validation and repair bodies.");
}
}