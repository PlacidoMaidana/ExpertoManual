#ifndef EVOLUTION_MARKET_METRICS
#define EVOLUTION_MARKET_METRICS

// CopyClose entrega primero el cierre mas antiguo. ER no depende del orden.
bool EvolutionER(const string symbol, const ENUM_TIMEFRAMES timeframe,
                 const int period, const int shift, double &result)
{
   result = 0.0;
   if(period < 1 || period > 10000 || shift < 1) return false;
   double closes[];
   if(CopyClose(symbol, timeframe, shift, period + 1, closes) != period + 1)
      return false;
   double path = 0.0;
   for(int i = 0; i <= period; i++)
   {
      if(!MathIsValidNumber(closes[i]) || closes[i] == EMPTY_VALUE) return false;
      if(i > 0) path += MathAbs(closes[i] - closes[i-1]);
   }
   if(path > 0.0)
      result = MathMin(1.0, MathAbs(closes[period] - closes[0]) / path);
   return true;
}

// Closed-bar range diagnostics used by MarketRegime.mqh.
// Compression = (HH-LL)/ATR over N closed bars. Displacement = |C_t - C_{t-N}|/ATR.
bool EvolutionRangeMetrics(const string symbol, const ENUM_TIMEFRAMES timeframe,
                           const int bars, const int shift, const double atr,
                           double &compression, double &displacement)
{
   compression = 0.0;
   displacement = 0.0;
   if(bars < 2 || bars > 10000 || shift < 1 || !MathIsValidNumber(atr) || atr <= 0.0)
      return false;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(symbol, timeframe, shift, bars+1, rates) != bars+1)
      return false;
   double highest = rates[0].high;
   double lowest = rates[0].low;
   for(int i = 0; i < bars; i++)
   {
      if(!MathIsValidNumber(rates[i].high) || !MathIsValidNumber(rates[i].low) ||
         !MathIsValidNumber(rates[i].close) || rates[i].high < rates[i].low)
         return false;
      if(rates[i].high > highest) highest = rates[i].high;
      if(rates[i].low < lowest) lowest = rates[i].low;
   }
   if(!MathIsValidNumber(rates[bars].close) || rates[bars].close<=0) return false;
   compression = (highest - lowest) / atr;
   displacement = MathAbs(rates[0].close - rates[bars].close) / atr;
   return MathIsValidNumber(compression) && MathIsValidNumber(displacement);
}
#endif
