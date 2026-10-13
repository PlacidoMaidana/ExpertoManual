#ifndef EVO_ECONOMIC_BREAK_EVEN
#define EVO_ECONOMIC_BREAK_EVEN
input group "BE economico - ganancia neta por posicion"
double evoBEMinOverride=-1;
double EvoEffectiveBEMoney() { return evoBEMinOverride>=0?evoBEMinOverride:EvoBEMinNetProfit; }
input double EvoBEMinNetProfit=2.0; // Moneda de cuenta; objetivo neto estimado de ambos BE
input group "BE manual anticipado - costos estimados"
input bool ManualBEIncludeCommission=true;
input bool ManualBEIncludeSwap=true;
input double ManualBEExtraMoney=0.0; // Margen en moneda de cuenta, por posicion
input double ManualBEExitCommissionPerLot=0.0; // 0: estimar con comision de entrada por lote

// Return a price whose gross profit covers the requested account-currency amount.
bool EvoBEPrice(const bool buy,const double entry,const double volume,const double money,double &target)
{
   double tick=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tick<=0 || entry<=0 || volume<=0 || !MathIsValidNumber(money) || money<0) return false;
   double lo=0,hi=tick,profit=0;
   bool found=false;
   for(int i=0;i<60;i++)
   {
      double price=entry+(buy?hi:-hi);
      if(price<=0 || !OrderCalcProfit(buy?ORDER_TYPE_BUY:ORDER_TYPE_SELL,_Symbol,volume,entry,price,profit)) return false;
      if(profit>=money) { found=true; break; }
      hi*=2;
   }
   if(!found) return false;
   for(int i=0;i<60;i++)
   {
      double mid=(lo+hi)*0.5;
      if(!OrderCalcProfit(buy?ORDER_TYPE_BUY:ORDER_TYPE_SELL,_Symbol,volume,entry,entry+(buy?mid:-mid),profit)) return false;
      if(profit>=money) hi=mid; else lo=mid;
   }
   double raw=entry+(buy?hi:-hi);
   target=(buy?MathCeil(raw/tick-1e-8):MathFloor(raw/tick+1e-8))*tick;
   if(!OrderCalcProfit(buy?ORDER_TYPE_BUY:ORDER_TYPE_SELL,_Symbol,volume,entry,target,profit)) return false;
   if(profit+1e-8<money) target+=(buy?tick:-tick);
   return target>0;
}
bool EvoBECosts(const ulong id,const double volume,const double swap,double &costs)
{
   costs=MathMax(EvoEffectiveBEMoney(),ManualBEExtraMoney)+(ManualBEIncludeSwap?MathMax(0,-swap):0);
   if(!ManualBEIncludeCommission) return true;
   if(!HistorySelectByPosition(id)) return false;
   double paid=0,inVolume=0; bool found=false;
   for(int i=0;i<HistoryDealsTotal();i++)
   {
      ulong deal=HistoryDealGetTicket(i);
      long type=HistoryDealGetInteger(deal,DEAL_TYPE);
      if(type!=DEAL_TYPE_BUY && type!=DEAL_TYPE_SELL) continue;
      long side=HistoryDealGetInteger(deal,DEAL_ENTRY);
      if(side==DEAL_ENTRY_INOUT) return false; // Reversal costs cannot be allocated reliably.
      if(side==DEAL_ENTRY_IN)
      {
         found=true; inVolume+=HistoryDealGetDouble(deal,DEAL_VOLUME);
         paid+=MathMax(0,-HistoryDealGetDouble(deal,DEAL_COMMISSION));
         paid+=MathMax(0,-HistoryDealGetDouble(deal,DEAL_FEE));
      }
   }
   if(!found || inVolume<=0) return false;
   double rate=paid/inVolume;
   costs+=volume*(rate+(ManualBEExitCommissionPerLot>0?ManualBEExitCommissionPerLot:rate));
   return MathIsValidNumber(costs) && costs>=0;
}
#endif
