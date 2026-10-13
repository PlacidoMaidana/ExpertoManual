#ifndef EVOLUTION_POSITION_RULES
#define EVOLUTION_POSITION_RULES
// Pure proposal: no broker calls and no optimistic state changes.
struct EvoProtection
{
   bool incremental, be, trailing, afterBE, smart, closeSmart;
   double t1,s1,t2,s2,t3,s3,beTrigger,beOffset,trailTrigger,trailDistance,step,smartMinR,smartOffset;
   int smartThreshold;
};
struct EvoProposal { double sl; bool close; string reason; };

bool EvoBetter(const bool buy,const double oldSL,const double newSL)
{ return newSL>0 && (oldSL<=0 || (buy?newSL>oldSL:newSL<oldSL)); }

double EvoLossStop(const bool buy,const double entry,const double price,const double sl,
                   const double atr,const double multiplier,const double step)
{
   if(entry<=0 || price<=0 || atr<=0 || multiplier<=0 || step<0) return sl;
   if((buy?price-entry:entry-price)>0) return sl;
   double candidate=price+(buy?-1:1)*atr*multiplier;
   if(!EvoBetter(buy,sl,candidate) || (sl>0 && (buy?candidate-sl:sl-candidate)<=step)) return sl;
   return candidate;
}

bool EvoSmartMayClose(const bool enabled,const bool confirmed,const bool protectedNet,const bool netNow)
{ return enabled && confirmed && protectedNet && netNow; }

// Confirmation uses three CLOSED bars: newest, previous and baseline.
bool EvoSmartDeterioration(const bool buy,const double open0,const double close0,
                          const double open1,const double close1,const double low2,const double high2)
{
   return buy?(close0<open0 && close1<open1 && close0<close1 && close0<low2):
              (close0>open0 && close1>open1 && close0>close1 && close0>high2);
}

EvoProposal EvoPropose(const bool buy,const double entry,const double current,
                      const double sl,const double risk,const double atr,
                      const int smartScore,const EvoProtection &p)
{
   EvoProposal r; r.sl=sl; r.close=false; r.reason="Sin cambio";
   if(entry<=0 || current<=0 || risk<=0 || atr<=0) return r;
   double sign=buy?1.0:-1.0, gain=sign*(current-entry), profitR=gain/risk;
   if(gain<=0) return r;
   if(p.smart && profitR>=p.smartMinR && smartScore>=p.smartThreshold && p.closeSmart)
   { r.close=true; r.reason="Smart Exit"; return r; }
   if(p.incremental)
   {
      double level=0; bool active=false;
      if(p.t1>0 && profitR>=p.t1) { level=p.s1; active=true; }
      if(p.t2>0 && profitR>=p.t2) { level=p.s2; active=true; }
      if(p.t3>0 && profitR>=p.t3) { level=p.s3; active=true; }
      double candidate=entry+sign*level*risk;
      if(active && EvoBetter(buy,r.sl,candidate)) { r.sl=candidate; r.reason="Proteccion incremental"; }
   }
   double bePrice=entry+sign*p.beOffset;
   if(p.be && gain>=atr*p.beTrigger && EvoBetter(buy,r.sl,bePrice))
   { r.sl=bePrice; r.reason="Break even"; }
   if(p.smart && profitR>=p.smartMinR && smartScore>=p.smartThreshold)
   {
      double candidate=entry+sign*p.smartOffset;
      if(EvoBetter(buy,r.sl,candidate)) { r.sl=candidate; r.reason="Smart Exit proteger"; }
   }
   // Use the confirmed broker SL to unlock trailing, not a pending BE proposal.
   bool protectedBE=sl>0 && sign*(sl-bePrice)>=0;
   if(p.trailing && p.trailDistance>0 && gain>=atr*p.trailTrigger && (!p.afterBE || protectedBE))
   {
      double candidate=current-sign*atr*p.trailDistance;
      if(protectedBE) candidate=buy?MathMax(candidate,bePrice):MathMin(candidate,bePrice);
      if(EvoBetter(buy,r.sl,candidate) && (sl<=0 || sign*(candidate-sl)>p.step))
      { r.sl=candidate; r.reason="Trailing ATR"; }
   }
   return r;
}
#endif
