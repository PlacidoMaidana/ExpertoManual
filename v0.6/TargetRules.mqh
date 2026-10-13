#ifndef EVO_TARGET_RULES
#define EVO_TARGET_RULES
double EvoTargetDistance(const bool byATR,const double atr,const double multiplier,const double risk,const double rr)
{ return byATR?atr*multiplier:risk*rr; }
#endif
