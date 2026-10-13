#ifndef EVO_PATTERN_RULES
#define EVO_PATTERN_RULES
// Geometry is measured in ATR; one correlated MACD/ROC group is context only.
bool EvoPatternDouble(const double first,const double valley,const double second,const double atr)
{ return atr>0 && MathAbs(first-second)<=0.35*atr && MathMin(first,second)-valley>=0.75*atr; }
bool EvoPatternHCH(const double left,const double low1,const double head,const double low2,const double right,const double atr)
{ return atr>0 && MathAbs(left-right)<=0.50*atr && head-MathMax(left,right)>=0.35*atr && MathMin(left,right)-MathMax(low1,low2)>=0.50*atr; }
bool EvoPatternWick(const double open,const double high,const double low,const double close,const double atr,const int side)
{
   double range=high-low,body=MathAbs(close-open);
   if(atr<=0 || range<0.50*atr || range<=0) return false;
   double wick=side>0?MathMin(open,close)-low:high-MathMax(open,close);
   double opposite=side>0?high-MathMax(open,close):MathMin(open,close)-low;
   return wick>=MathMax(2*body,0.55*range) && opposite<=0.25*range;
}
int EvoPatternState(const int side,const double close1,const double neck1,const double close2,const double neck2,const double invalidation,const double margin)
{
   if(side*(close2-invalidation)<-margin) return 3; // Invalidation uses close, not an intrabar spike.
   bool one=side*(close1-neck1)>margin,two=side*(close2-neck2)>margin;
   return one && two?2:two?1:0;
}
// Ordinary impulse hypothesis only: no diagonals, truncation or subdivisions inferred.
int EvoElliottRules(const double p0,const double p1,const double p2,const double p3,const double p4,const double p5,const double atr)
{
   if(atr<=0 || p1-p0<.50*atr || p3-p2<.50*atr || p5-p4<.50*atr) return 0;
   if(p2<=p0 || p2>=p1) return 1;
   if(p3<=p1 || p4>=p3 || p5<=p3) return 2;
   if(p4<=p1) return 3;
   if(p3-p2<MathMin(p1-p0,p5-p4)) return 4;
   return 5;
}
int EvoWave3State(const double origin,const double top1,const double bottom2,const double latestLow,const double previousClose,const double close,const double live,const double atr)
{
   if(atr<=0 || top1-origin<.50*atr || bottom2<=origin || bottom2>=top1) return -1;
   if(latestLow<=origin) return -1;
   if(close>top1+.10*atr && previousClose>top1+.10*atr) return 3;
   if(close>top1+.10*atr) return 2;
   if(live>top1+.10*atr) return 1;
   return 0;
}
#endif
