#ifndef EVO_MULTI_TIMEFRAME
#define EVO_MULTI_TIMEFRAME
struct EvoFrameContext { bool valid; int direction; string regime; double adx; };
// Same regime criteria as the base evaluator, applied exclusively to closed bars.
void EvoFrameRegime(const double price,const double fast,const double olderFast,const double slow,
                    const double atr,const double average,const double adx,EvoFrameContext &r)
{
   double slope=fast-olderFast,minimum=atr*0.10*EntryMinEmaSlopeAtrMult();
   bool bull=(price>fast && fast>slow) || (price>fast && slope>minimum);
   bool bear=(price<fast && fast<slow) || (price<fast && slope< -minimum);
   r.direction=bull&&!bear?1:bear&&!bull?-1:0;
   r.regime=adx>=EntryTrendADXMin() && r.direction!=0?"TENDENCIA":atr<average?"LATERAL":"MIXTO";
   r.adx=adx; r.valid=true;
}
class CEvoMultiTimeframe
{
private:
   int h[6][4];
   int frameCount;
   ENUM_TIMEFRAMES frames[6];
   string symbol;
   bool Read(int handle,int shift,double &v)
   { double b[1]; if(CopyBuffer(handle,0,shift,1,b)!=1) return false; v=b[0]; return MathIsValidNumber(v) && v!=EMPTY_VALUE; }
public:
   CEvoMultiTimeframe() { frameCount=3; for(int i=0;i<6;i++) for(int j=0;j<4;j++) h[i][j]=INVALID_HANDLE; }
   void Release() { for(int i=0;i<6;i++) for(int j=0;j<4;j++) { if(h[i][j]!=INVALID_HANDLE) IndicatorRelease(h[i][j]); h[i][j]=INVALID_HANDLE; } }
   void Init(string sym,const bool extended=false)
   {
      Release(); symbol=sym; frameCount=extended?6:3;
      frames[0]=PERIOD_M15; frames[1]=PERIOD_H1; frames[2]=PERIOD_H4;
      frames[3]=PERIOD_M5; frames[4]=PERIOD_M30; frames[5]=PERIOD_D1;
      for(int i=0;i<frameCount;i++) {
         h[i][0]=iATR(sym,frames[i],InpATRPeriod); h[i][1]=iADX(sym,frames[i],InpADXPeriod);
         h[i][2]=iMA(sym,frames[i],InpEmaFastPeriod,0,MODE_EMA,PRICE_CLOSE);
         h[i][3]=iMA(sym,frames[i],InpEmaSlowPeriod,0,MODE_EMA,PRICE_CLOSE);
      }
   }
   void Update(int i,EvoFrameContext &r)
   {
      ZeroMemory(r);
      if(i<0 || i>=frameCount) return;
      int required=MathMax(InpEmaFastPeriod,InpEmaSlowPeriod)+3;
      if(Bars(symbol,frames[i])<required || BarsCalculated(h[i][0])<InpATRPeriod+11 ||
         BarsCalculated(h[i][1])<InpADXPeriod+2 || BarsCalculated(h[i][2])<InpEmaFastPeriod+3 ||
         BarsCalculated(h[i][3])<InpEmaSlowPeriod+1) return;
      double atr,adx,fast,older,slow; double closes[1],a[10];
      if(!Read(h[i][0],1,atr) || !Read(h[i][1],1,adx) || !Read(h[i][2],1,fast) ||
         !Read(h[i][2],3,older) || !Read(h[i][3],1,slow) || atr<=0 ||
         CopyClose(symbol,frames[i],1,1,closes)!=1 || closes[0]<=0 ||
         CopyBuffer(h[i][0],0,1,10,a)!=10) return;
      double sum=0;
      for(int j=0;j<10;j++) { if(!MathIsValidNumber(a[j]) || a[j]==EMPTY_VALUE || a[j]<=0) return; sum+=a[j]; }
      EvoFrameRegime(closes[0],fast,older,slow,atr,sum/10,adx,r);
   }
};
#endif
