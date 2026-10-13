#ifndef EVOLUTION_JOURNAL
#define EVOLUTION_JOURNAL
input group "Registro comun Evolucion"
input bool EvoWriteJournal = true;
input bool EvoJournalCommon = true;

void EvoJournal(const string event,const ulong ticket,const string details)
{
   if(!EvoWriteJournal) return;
   string file=StringFormat("Evolucion_%I64d_%I64d.csv",AccountInfoInteger(ACCOUNT_LOGIN),ChartID());
   int flags=FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_SHARE_READ;
   if(EvoJournalCommon) flags|=FILE_COMMON;
   int h=FileOpen(file,flags,';');
   if(h==INVALID_HANDLE) { Print("Evolucion: no se pudo abrir bitacora ",file," error=",GetLastError()); return; }
   if(FileSize(h)==0) FileWrite(h,"hora_servidor","programa","simbolo","evento","ticket","detalle");
   FileSeek(h,0,SEEK_END);
   FileWrite(h,TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),MQLInfoString(MQL_PROGRAM_NAME),_Symbol,event,ticket,details);
   FileClose(h);
}
#endif
