#ifndef EVO_TRADE_DATASET
#define EVO_TRADE_DATASET
input group "Dataset experimental v0.5"
input bool EvoWriteTradeDataset = true;
input bool EvoDatasetCommon = true;
input bool EvoDiagnosticOnly = true; // true: modos adaptativos solo registran; no cierran ni mueven SL/TP por modo
input double EvoTacticalERMax = 0.30; // ER bajo => captura tactica
input double EvoExtensionERMin = 0.60; // ER alto => extension
input double EvoTacticalMfeArmATR = 0.40; // umbral diagnostico MFE para WOULD_ACTIVATE táctico
input double EvoProtectionMinR = 0.50; // umbral diagnostico de beneficio en R

bool EvoValidDatasetInputs()
{
   return MathIsValidNumber(EvoTacticalERMax) && EvoTacticalERMax>=0 && EvoTacticalERMax<=1 &&
          MathIsValidNumber(EvoExtensionERMin) && EvoExtensionERMin>0 && EvoExtensionERMin<=1 &&
          EvoTacticalERMax<EvoExtensionERMin &&
          MathIsValidNumber(EvoTacticalMfeArmATR) && EvoTacticalMfeArmATR>0 && EvoTacticalMfeArmATR<=10 &&
          MathIsValidNumber(EvoProtectionMinR) && EvoProtectionMinR>=0 && EvoProtectionMinR<=20;
}

string EvoDatasetFile()
{
   return StringFormat("EvolucionDataset_%I64d_%I64d.csv",AccountInfoInteger(ACCOUNT_LOGIN),ChartID());
}

void EvoDatasetWrite(const string event,const ulong ticket,const string details)
{
   if(!EvoWriteTradeDataset) return;
   string file=EvoDatasetFile();
   int flags=FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_SHARE_READ;
   if(EvoDatasetCommon) flags|=FILE_COMMON;
   int h=FileOpen(file,flags,';');
   if(h==INVALID_HANDLE) { Print("Evolucion v0.5: no se pudo abrir dataset ",file," error=",GetLastError()); return; }
   if(FileSize(h)==0)
      FileWrite(h,"hora_servidor","programa","simbolo","evento","ticket","detalle");
   FileSeek(h,0,SEEK_END);
   FileWrite(h,TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),MQLInfoString(MQL_PROGRAM_NAME),_Symbol,event,(string)ticket,details);
   FileFlush(h); FileClose(h);
}

void EvoDatasetWould(const string action,const ulong ticket,const string details)
{
   EvoDatasetWrite("WOULD_"+action,ticket,details+(EvoDiagnosticOnly?"; diagnostic_only=1":"; diagnostic_only=0"));
}
#endif
