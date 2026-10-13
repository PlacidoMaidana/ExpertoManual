#ifndef EVO_THESIS_RULES
#define EVO_THESIS_RULES
// Counts loss of previously favourable context; initial contradictions are not new deterioration.
int EvoThesisLoss(const int baseline,const int current,const int direction)
{ return baseline==direction && current!=direction?1:0; }
int EvoThesisState(const int losses,const int gains,const bool invalidated)
{ return invalidated?4:losses>=3?3:losses>0?2:gains>0?1:0; }
int EvoThesisStreak(const bool consecutive,const bool invalidated,const int previous)
{ return invalidated?(consecutive?previous+1:1):0; }
double EvoDefensiveStop(const bool buy,const double best,const double armPrice,const double frozenATR,
   const double baseMultiplier,const double recoveryATR,const double recoveredMultiplier,
   const double originalSL,const double currentSL)
{
   if(best<=0 || armPrice<=0 || frozenATR<=0 || originalSL<=0 || currentSL<=0) return currentSL;
   double recovered=(buy?best-armPrice:armPrice-best)/frozenATR;
   double multiplier=recovered>=recoveryATR?MathMin(baseMultiplier,recoveredMultiplier):baseMultiplier;
   double candidate=best+(buy?-1:1)*frozenATR*multiplier;
   return buy?MathMax(MathMax(originalSL,currentSL),candidate):MathMin(MathMin(originalSL,currentSL),candidate);
}
// MFE/MAE from observation: never decrease previously recorded extremes (GWT monotonicity).
double EvoMfeUpdate(const double previousMfe,const double moveATR)
{
   if(!MathIsValidNumber(previousMfe) || previousMfe<0) return MathIsValidNumber(moveATR)?MathMax(0.0,moveATR):0.0;
   if(!MathIsValidNumber(moveATR)) return previousMfe;
   return MathMax(previousMfe,moveATR);
}
double EvoMaeUpdate(const double previousMae,const double moveATR)
{
   if(!MathIsValidNumber(previousMae) || previousMae<0) return MathIsValidNumber(moveATR)?MathMax(0.0,-moveATR):0.0;
   if(!MathIsValidNumber(moveATR)) return previousMae;
   return MathMax(previousMae,-moveATR);
}
#endif
