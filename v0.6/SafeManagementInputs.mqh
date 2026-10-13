#ifndef EVO_SAFE_MANAGEMENT_INPUTS
#define EVO_SAFE_MANAGEMENT_INPUTS
string evoManagementInputWarning="";
#ifdef EVO_MONITOR_SAFE_INPUTS
double evoApplied_EvoSLATR=1.5;
double evoApplied_EvoRR=2.0;
ENUM_EVO_TP_MODE evoApplied_EvoTPMode=EVO_TP_RR;
double evoApplied_EvoTPATR=3.0;
bool evoApplied_EvoSetMissingSL=true;
bool evoApplied_EvoSetMissingTP=true;
bool evoApplied_EvoIncremental=true;
double evoApplied_EvoStage1TriggerR=0.40;
double evoApplied_EvoStage1StopR=-0.15;
double evoApplied_EvoStage2TriggerR=0.70;
double evoApplied_EvoStage2StopR=0.05;
double evoApplied_EvoStage3TriggerR=1.00;
double evoApplied_EvoStage3StopR=0.30;
bool evoApplied_EvoBreakEven=true;
double evoApplied_EvoBETriggerATR=1.0;
double evoApplied_EvoBEOffsetATR=0.0;
bool evoApplied_EvoTrailing=true;
bool evoApplied_EvoTrailingAfterBE=true;
double evoApplied_EvoTrailingTriggerATR=0.0;
double evoApplied_EvoTrailingDistanceATR=0.5;
int evoApplied_EvoTrailingStepPoints=5;
bool evoApplied_EvoSmartExit=true;
bool evoApplied_EvoSmartClose=true;
double evoApplied_EvoSmartMinProfitR=0.70;
int evoApplied_EvoSmartScore=5;
int evoApplied_EvoSmartLookback=50;
double evoApplied_EvoSmartSRATR=0.25;
double evoApplied_EvoSmartADXDrop=8.0;
double evoApplied_EvoSmartATRContract=0.75;
double evoApplied_EvoSmartOffsetATR=0.0;
int evoApplied_EvoDeviationPoints=20;
void EvoLoadManagementInputs()
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
#define EvoSLATR evoApplied_EvoSLATR
#define EvoRR evoApplied_EvoRR
#define EvoTPMode evoApplied_EvoTPMode
#define EvoTPATR evoApplied_EvoTPATR
#define EvoSetMissingSL evoApplied_EvoSetMissingSL
#define EvoSetMissingTP evoApplied_EvoSetMissingTP
#define EvoIncremental evoApplied_EvoIncremental
#define EvoStage1TriggerR evoApplied_EvoStage1TriggerR
#define EvoStage1StopR evoApplied_EvoStage1StopR
#define EvoStage2TriggerR evoApplied_EvoStage2TriggerR
#define EvoStage2StopR evoApplied_EvoStage2StopR
#define EvoStage3TriggerR evoApplied_EvoStage3TriggerR
#define EvoStage3StopR evoApplied_EvoStage3StopR
#define EvoBreakEven evoApplied_EvoBreakEven
#define EvoBETriggerATR evoApplied_EvoBETriggerATR
#define EvoBEOffsetATR evoApplied_EvoBEOffsetATR
#define EvoTrailing evoApplied_EvoTrailing
#define EvoTrailingAfterBE evoApplied_EvoTrailingAfterBE
#define EvoTrailingTriggerATR evoApplied_EvoTrailingTriggerATR
#define EvoTrailingDistanceATR evoApplied_EvoTrailingDistanceATR
#define EvoTrailingStepPoints evoApplied_EvoTrailingStepPoints
#define EvoSmartExit evoApplied_EvoSmartExit
#define EvoSmartClose evoApplied_EvoSmartClose
#define EvoSmartMinProfitR evoApplied_EvoSmartMinProfitR
#define EvoSmartScore evoApplied_EvoSmartScore
#define EvoSmartLookback evoApplied_EvoSmartLookback
#define EvoSmartSRATR evoApplied_EvoSmartSRATR
#define EvoSmartADXDrop evoApplied_EvoSmartADXDrop
#define EvoSmartATRContract evoApplied_EvoSmartATRContract
#define EvoSmartOffsetATR evoApplied_EvoSmartOffsetATR
#define EvoDeviationPoints evoApplied_EvoDeviationPoints
string EvoStageInputError(const double t1,const double s1,const double t2,const double s2,const double t3,const double s3)
{
   if(!MathIsValidNumber(t1) || !MathIsValidNumber(t2) || !MathIsValidNumber(t3) || !MathIsValidNumber(s1) || !MathIsValidNumber(s2) || !MathIsValidNumber(s3)) return "Escalones: valor numerico no valido";
   if(t1<0 || t2<0 || t3<0) return "Escalones: TriggerR no admite negativos; StopR si puede ser negativo";
   if(t2<t1 || t3<t2) return "Escalones: TriggerR debe cumplir etapa 1 <= etapa 2 <= etapa 3";
   if(s1>=t1 || s2>=t2 || s3>=t3) return "Escalones: cada StopR debe ser menor que su TriggerR";
   if(s2<s1 || s3<s2) return "Escalones: StopR no debe retroceder entre etapas";
   return "";
}
void EvoManagementWarning(const string message)
{
   if(evoManagementInputWarning!="") evoManagementInputWarning+="\n";
   evoManagementInputWarning+=message;
}
void EvoRepairManagementInputs()
{
   EvoLoadManagementInputs();
   string stageError=EvoStageInputError(EvoStage1TriggerR,EvoStage1StopR,EvoStage2TriggerR,EvoStage2StopR,EvoStage3TriggerR,EvoStage3StopR);
   if(stageError!="")
   {
      EvoManagementWarning(stageError+StringFormat(". Recibido trigger/stop: %.3f/%.3f; %.3f/%.3f; %.3f/%.3f. Aplicado: 0.40/-0.15; 0.70/0.05; 1.00/0.30 R",EvoStage1TriggerR,EvoStage1StopR,EvoStage2TriggerR,EvoStage2StopR,EvoStage3TriggerR,EvoStage3StopR));
      EvoStage1TriggerR=0.40; EvoStage1StopR=-0.15;
      EvoStage2TriggerR=0.70; EvoStage2StopR=0.05;
      EvoStage3TriggerR=1.00; EvoStage3StopR=0.30;
   }
   if(!MathIsValidNumber(EvoSLATR) || EvoSLATR<=0) { EvoManagementWarning("EvoSLATR incompatible: "+(string)EvoSLATR+". Aplicado predeterminado: 1.5"); EvoSLATR=1.5; }
   if(!MathIsValidNumber(EvoRR) || EvoRR<=0) { EvoManagementWarning("EvoRR incompatible: "+(string)EvoRR+". Aplicado predeterminado: 2.0"); EvoRR=2.0; }
   if(EvoTPMode!=EVO_TP_RR && EvoTPMode!=EVO_TP_ATR) { EvoManagementWarning("EvoTPMode incompatible: "+(string)EvoTPMode+". Aplicado predeterminado: EVO_TP_RR"); EvoTPMode=EVO_TP_RR; }
   if(!MathIsValidNumber(EvoTPATR) || EvoTPATR<=0) { EvoManagementWarning("EvoTPATR incompatible: "+(string)EvoTPATR+". Aplicado predeterminado: 3.0"); EvoTPATR=3.0; }
   if(!MathIsValidNumber(EvoBETriggerATR) || EvoBETriggerATR<0) { EvoManagementWarning("EvoBETriggerATR incompatible: "+(string)EvoBETriggerATR+". Aplicado predeterminado: 1.0"); EvoBETriggerATR=1.0; }
   if(!MathIsValidNumber(EvoBEOffsetATR) || EvoBEOffsetATR<0) { EvoManagementWarning("EvoBEOffsetATR incompatible: "+(string)EvoBEOffsetATR+". Aplicado predeterminado: 0.0"); EvoBEOffsetATR=0.0; }
   if(!MathIsValidNumber(EvoTrailingTriggerATR) || EvoTrailingTriggerATR<0) { EvoManagementWarning("EvoTrailingTriggerATR incompatible: "+(string)EvoTrailingTriggerATR+". Aplicado predeterminado: 0.0"); EvoTrailingTriggerATR=0.0; }
   if(!MathIsValidNumber(EvoTrailingDistanceATR) || EvoTrailingDistanceATR<=0) { EvoManagementWarning("EvoTrailingDistanceATR incompatible: "+(string)EvoTrailingDistanceATR+". Aplicado predeterminado: 0.5"); EvoTrailingDistanceATR=0.5; }
   if(EvoTrailingStepPoints<0) { EvoManagementWarning("EvoTrailingStepPoints incompatible: "+(string)EvoTrailingStepPoints+". Aplicado predeterminado: 5"); EvoTrailingStepPoints=5; }
   if(!MathIsValidNumber(EvoSmartMinProfitR) || EvoSmartMinProfitR<0) { EvoManagementWarning("EvoSmartMinProfitR incompatible: "+(string)EvoSmartMinProfitR+". Aplicado predeterminado: 0.70"); EvoSmartMinProfitR=0.70; }
   if(EvoSmartScore<=0) { EvoManagementWarning("EvoSmartScore incompatible: "+(string)EvoSmartScore+". Aplicado predeterminado: 5"); EvoSmartScore=5; }
   if(EvoSmartLookback<2 || EvoSmartLookback>10000) { EvoManagementWarning("EvoSmartLookback incompatible: "+(string)EvoSmartLookback+". Aplicado predeterminado: 50"); EvoSmartLookback=50; }
   if(!MathIsValidNumber(EvoSmartSRATR) || EvoSmartSRATR<0) { EvoManagementWarning("EvoSmartSRATR incompatible: "+(string)EvoSmartSRATR+". Aplicado predeterminado: 0.25"); EvoSmartSRATR=0.25; }
   if(!MathIsValidNumber(EvoSmartADXDrop) || EvoSmartADXDrop<=0) { EvoManagementWarning("EvoSmartADXDrop incompatible: "+(string)EvoSmartADXDrop+". Aplicado predeterminado: 8.0"); EvoSmartADXDrop=8.0; }
   if(!MathIsValidNumber(EvoSmartATRContract) || EvoSmartATRContract<0) { EvoManagementWarning("EvoSmartATRContract incompatible: "+(string)EvoSmartATRContract+". Aplicado predeterminado: 0.75"); EvoSmartATRContract=0.75; }
   if(!MathIsValidNumber(EvoSmartOffsetATR) || EvoSmartOffsetATR<0) { EvoManagementWarning("EvoSmartOffsetATR incompatible: "+(string)EvoSmartOffsetATR+". Aplicado predeterminado: 0.0"); EvoSmartOffsetATR=0.0; }
   if(EvoDeviationPoints<0) { EvoManagementWarning("EvoDeviationPoints incompatible: "+(string)EvoDeviationPoints+". Aplicado predeterminado: 20"); EvoDeviationPoints=20; }
}
#endif
#endif
