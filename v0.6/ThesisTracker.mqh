#ifndef EVO_THESIS_TRACKER
#define EVO_THESIS_TRACKER
#include "ThesisRules.mqh"
#include "MonitorLevels.mqh"
#include "ManagementMode.mqh"
#include "TradeDataset.mqh"
input group "Seguimiento de tesis - contexto cerrado"
input bool EvoTrackThesis = true;
input double EvoThesisADXDrop = 5.0;
input double EvoThesisERDrop = 0.15;
input int EvoThesisConfirmBars = 2;
input bool EvoThesisProtectProfit = false; // Proteccion adicional opcional, nunca cierre por diagnostico
struct EvoThesisData
{
   int version;
   bool invalidSignature;
   ulong id;
   long type;
   datetime opened,captured,bar;
   double entry,volume,lastVolume,atr,sl,adx,deltaADX,er,rsi,plusDI,minusDI,room,mfe,mae;
   int regime,validMask,dir[7];
};
struct EvoThesisItem
{
   EvoThesisData base;
   ulong ticket;
   bool seen,compatible,saved;
   int state,losses,gains,compared,streak,currentMask;
   datetime evaluated;
   double currentADX,currentER,currentRSI,room,pnl;
   int nowDir[7];
   int managementMode;
   string managementModeName;
   bool wouldLogged;
};
string EvoThesisName(int state)
{ return state==4?"INVALIDADA (regla tecnica)":state==3?"DETERIORADA":state==2?"DEBILITANDOSE":state==1?"FORTALECIDA":"INTACTA"; }
int EvoThesisSign(double value) { return value>0?1:value<0?-1:0; }
class CEvoThesisTracker
{
private:
   EvoThesisItem items[];
   EvoSnapshot closed;
   datetime lastRead;
   string Scope()
   {
      string settings=AccountInfoString(ACCOUNT_SERVER)+_Symbol+MQLInfoString(MQL_PROGRAM_NAME)+
         (string)_Period+"/"+(string)InpATRPeriod+"/"+(string)InpADXPeriod+"/"+(string)InpRSIPeriod+
         "/"+(string)InpEmaFastPeriod+"/"+(string)InpEmaSlowPeriod+"/"+(string)EvoERPeriod+"/"+(string)EvoDeltaBars+
         "/"+(string)EvoOBVLookback+"/"+(string)EvoOBVVolume+"/"+EntryModeName()+"/"+(string)EntryTrendADXMin()+
         "/"+(string)EntryMinEmaSlopeAtrMult()+"/"+(string)InpMonitorSRLookback+"/"+(string)InpMonitorSRPivotBars;
      uint hash=2166136261;
      for(int i=0;i<StringLen(settings);i++) hash=(hash^(uint)StringGetCharacter(settings,i))*16777619;
      return StringFormat("EvoThesis_%I64d_%I64d_%u_",AccountInfoInteger(ACCOUNT_LOGIN),ChartID(),hash);
   }
   string FileName(ulong id) { return Scope()+(string)id+".bin"; }
   bool Save(EvoThesisData &data)
   {
      int h=FileOpen(FileName(data.id),FILE_WRITE|FILE_BIN);
      if(h==INVALID_HANDLE) return false;
      bool ok=FileWriteStruct(h,data)==sizeof(EvoThesisData); FileFlush(h); FileClose(h); return ok;
   }
   bool Load(ulong id,EvoThesisData &data)
   {
      int h=FileOpen(FileName(id),FILE_READ|FILE_BIN|FILE_SHARE_READ);
      if(h==INVALID_HANDLE) return false;
      bool ok=FileSize(h)==sizeof(EvoThesisData) && FileReadStruct(h,data)==sizeof(EvoThesisData);
      FileClose(h); return ok && data.version==1 && data.id==id && MathIsValidNumber(data.atr) && data.atr>0 && data.entry>0 && data.lastVolume>0;
   }
   void Context(EvoSnapshot &s,int &directions[],int &mask)
   {
      mask=1;
      directions[0]=s.plusDI>s.minusDI+1?1:s.minusDI>s.plusDI+1?-1:0;
      directions[1]=EvoThesisSign(s.confirmed.close-s.ema50); if(s.ema50Valid) mask|=2;
      directions[2]=EvoThesisSign(s.confirmed.close-s.ema200); if(s.ema200Valid) mask|=4;
      directions[3]=EvoThesisSign(s.obvDelta); if(s.obvValid) mask|=8;
      for(int j=0;j<3;j++) { directions[j+4]=s.mtf[j].direction; if(s.mtf[j].valid) mask|=(1<<(j+4)); }
      if(s.erValid) mask|=128;
   }
public:
   CEvoThesisTracker() { lastRead=0; }
   bool ValidInputs() { return MathIsValidNumber(EvoThesisADXDrop) && EvoThesisADXDrop>0 && MathIsValidNumber(EvoThesisERDrop) && EvoThesisERDrop>0 && EvoThesisERDrop<=1 && EvoThesisConfirmBars>=1 && EvoThesisConfirmBars<=20; }
   int Count() { return ArraySize(items); }
   bool Get(int index,EvoThesisItem &item) { if(index<0 || index>=ArraySize(items)) return false; item=items[index]; return true; }
   int State(ulong ticket) { for(int i=0;i<ArraySize(items);i++) if(items[i].ticket==ticket && items[i].compatible && items[i].evaluated==lastRead) return items[i].state; return -1; }
   void Update(CEvoAnalysis &source,bool manualOnly,long magic)
   {
      if(!EvoTrackThesis) { ArrayResize(items,0); return; }
      datetime bar=iTime(_Symbol,PERIOD_CURRENT,1);
      bool valid=bar>0;
      if(valid && bar!=lastRead)
      {
         valid=source.ClosedAlertSnapshot(closed);
         if(valid) { valid=closed.confirmed.time==bar; if(valid) lastRead=bar; }
      }
      valid=valid && lastRead==bar;
      // DI also belongs to the closed view, not the live snapshot.
      for(int i=0;i<ArraySize(items);i++) items[i].seen=false;
      for(int n=PositionsTotal()-1;n>=0;n--)
      {
         ulong ticket=PositionGetTicket(n); if(ticket==0 || PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
         long selectedMagic=PositionGetInteger(POSITION_MAGIC);
         if(manualOnly?selectedMagic!=0:selectedMagic!=magic) continue;
         ulong id=(ulong)PositionGetInteger(POSITION_IDENTIFIER); int index=-1;
         for(int i=0;i<ArraySize(items);i++) if(items[i].base.id==id) { index=i; break; }
         bool created=index<0;
         if(created)
         {
            if(!valid) continue;
            index=ArraySize(items); ArrayResize(items,index+1); ZeroMemory(items[index]);
            if(!Load(id,items[index].base))
            {
               EvoThesisData d; ZeroMemory(d); d.version=1; d.id=id; d.type=PositionGetInteger(POSITION_TYPE);
               d.opened=(datetime)PositionGetInteger(POSITION_TIME); d.captured=TimeCurrent(); d.bar=bar;
               d.entry=PositionGetDouble(POSITION_PRICE_OPEN); d.volume=PositionGetDouble(POSITION_VOLUME);
               d.lastVolume=d.volume; d.deltaADX=closed.deltaADX;
               d.sl=PositionGetDouble(POSITION_SL); d.atr=closed.atr[0]; d.adx=closed.adx[0]; d.er=closed.er;
               d.rsi=closed.rsi[0]; d.plusDI=closed.plusDI; d.minusDI=closed.minusDI;
               d.regime=closed.regime=="TENDENCIA"?1:closed.regime=="LATERAL"?2:0;
               Context(closed,d.dir,d.validMask);
               double support,resistance; bool sf,rf; EvoNearestLevels(d.entry,support,resistance,sf,rf);
               double obstacle=d.type==POSITION_TYPE_BUY?resistance:support;
               d.room=obstacle>0?MathAbs(obstacle-d.entry)/d.atr:-1;
               items[index].base=d; items[index].saved=Save(items[index].base);
               items[index].managementMode=closed.managementMode;
               items[index].managementModeName=closed.managementModeName;
               EvoDatasetWrite("OPEN",ticket,StringFormat(
                  "id=%I64d;tipo=%s;entrada=%.8f;atr=%.8f;regimen=%s;modo=%s;mfe_atr=0;mae_atr=0;diagnostic=%d",
                  id,d.type==POSITION_TYPE_BUY?"BUY":"SELL",d.entry,d.atr,closed.localRegimeName,closed.managementModeName,(int)EvoDiagnosticOnly));
            }
            else items[index].saved=true;
         }
         items[index].ticket=ticket; items[index].seen=true;
         double entry=PositionGetDouble(POSITION_PRICE_OPEN),volume=PositionGetDouble(POSITION_VOLUME);
         items[index].compatible=!items[index].base.invalidSignature && PositionGetInteger(POSITION_TYPE)==items[index].base.type &&
            MathAbs(entry-items[index].base.entry)<_Point*0.5 && volume<=items[index].base.lastVolume+1e-8;
         if(!items[index].compatible) {
            if(!items[index].base.invalidSignature) { items[index].base.invalidSignature=true; items[index].saved=Save(items[index].base); }
            continue;
         }
         items[index].base.lastVolume=volume;
         MqlTick q; if(!SymbolInfoTick(_Symbol,q)) continue;
         int side=items[index].base.type==POSITION_TYPE_BUY?1:-1;
         double price=side>0?q.bid:q.ask; if(price<=0) continue;
         double move=side*(price-entry)/items[index].base.atr;
         items[index].base.mfe=EvoMfeUpdate(items[index].base.mfe,move);
         items[index].base.mae=EvoMaeUpdate(items[index].base.mae,move);
         items[index].pnl=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
         // Live management mode from last closed snapshot when available.
         if(valid)
         {
            items[index].managementMode=closed.managementMode;
            items[index].managementModeName=closed.managementModeName;
         }
         double openR=items[index].base.atr>0?items[index].base.mfe:0; // proxy in ATR units from observation
         if(EvoDiagnosticOnly && !items[index].wouldLogged)
         {
            if(EvoTacticalWouldArm(items[index].managementMode,items[index].base.mfe,EvoTacticalMfeArmATR))
            {
               EvoDatasetWould("TACTICAL_CAPTURE",ticket,StringFormat(
                  "mfe_atr=%.4f;umbral=%.4f;modo=%s;regimen=%s;accion=NO_AUTO_CLOSE",
                  items[index].base.mfe,EvoTacticalMfeArmATR,items[index].managementModeName,closed.localRegimeName));
               items[index].wouldLogged=true;
            }
            else if(EvoProtectionWouldArm(items[index].managementMode,openR,EvoProtectionMinR) && items[index].state>=2)
            {
               EvoDatasetWould("PROTECTION",ticket,StringFormat(
                  "mfe_atr=%.4f;estado=%s;modo=%s;accion=NO_AUTO_SL",
                  items[index].base.mfe,EvoThesisName(items[index].state),items[index].managementModeName));
               items[index].wouldLogged=true;
            }
         }
         if(!valid) { items[index].evaluated=0; continue; }
         if(items[index].evaluated==bar) continue;
         int mask=0,dirs[7]; Context(closed,dirs,mask); items[index].currentMask=mask;
         int losses=0,gains=0,compared=0;
         for(int j=0;j<7;j++) {
            items[index].nowDir[j]=dirs[j];
            if((mask & items[index].base.validMask & (1<<j))==0) continue;
            compared++; losses+=EvoThesisLoss(items[index].base.dir[j],dirs[j],side);
            if(items[index].base.dir[j]!=side && dirs[j]==side) gains++;
         }
         if(items[index].base.regime==1) {
            compared++; if(items[index].base.adx-closed.adx[0]>=EvoThesisADXDrop) losses++;
            else if(closed.adx[0]-items[index].base.adx>=EvoThesisADXDrop) gains++;
            if((mask & items[index].base.validMask & 128)!=0) {
               compared++; if(items[index].base.er-closed.er>=EvoThesisERDrop) losses++;
               else if(closed.er-items[index].base.er>=EvoThesisERDrop) gains++;
            }
         }
         bool invalid=(mask & items[index].base.validMask & 3)==3 &&
            items[index].base.dir[0]==side && items[index].base.dir[1]==side && dirs[0]==-side && dirs[1]==-side && losses>=3;
         items[index].streak=EvoThesisStreak(items[index].evaluated==closed.previous.time,invalid,items[index].streak);
         items[index].state=EvoThesisState(losses,gains,items[index].streak>=EvoThesisConfirmBars);
         items[index].losses=losses; items[index].gains=gains; items[index].compared=compared;
         items[index].currentADX=closed.adx[0]; items[index].currentER=closed.er; items[index].currentRSI=closed.rsi[0];
         double support,resistance; bool sf,rf; EvoNearestLevels(price,support,resistance,sf,rf);
         double obstacle=side>0?resistance:support; items[index].room=obstacle>0?MathAbs(obstacle-price)/closed.atr[0]:-1;
         items[index].evaluated=bar; items[index].saved=Save(items[index].base);
         EvoDatasetWrite("UPDATE",ticket,StringFormat(
            "estado=%s;perdidas=%d;mfe_atr=%.4f;mae_atr=%.4f;regimen=%s;modo=%s;room=%.4f;pnl=%.2f",
            EvoThesisName(items[index].state),items[index].losses,items[index].base.mfe,items[index].base.mae,
            closed.localRegimeName,items[index].managementModeName,items[index].room,items[index].pnl));
      }
      for(int i=ArraySize(items)-1;i>=0;i--) if(!items[i].seen)
      {
         EvoDatasetWrite("CLOSE",items[i].ticket,StringFormat(
            "id=%I64d;mfe_atr=%.4f;mae_atr=%.4f;estado=%s;modo=%s;diagnostic=%d",
            items[i].base.id,items[i].base.mfe,items[i].base.mae,EvoThesisName(items[i].state),
            items[i].managementModeName,(int)EvoDiagnosticOnly));
         Save(items[i].base);
         for(int j=i;j<ArraySize(items)-1;j++) items[j]=items[j+1];
         ArrayResize(items,ArraySize(items)-1);
      }
   }
   void Flush() { for(int i=0;i<ArraySize(items);i++) Save(items[i].base); }
};
CEvoThesisTracker evoThesis;
#endif
