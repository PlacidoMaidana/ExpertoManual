using System; public class EvolutionAnalysisTests {


public enum ENUM_ENTRY_MODE
{
    ENTRADA_PERSONALIZADA = 0, // Usa los parametros manuales de entrada
    ENTRADA_PROTEGIDA    = 1, // Menos entradas, filtros mas estrictos
    ENTRADA_BALANCEADA   = 2, // Mas activa sin abrir demasiado el filtro
    ENTRADA_FLEXIBLE     = 3  // Maxima frecuencia de entradas
};

public static ENUM_ENTRY_MODE InpModoEntrada = ENUM_ENTRY_MODE.ENTRADA_FLEXIBLE; // Acceso activo al mercado con filtros minimos
public static int      InpATRPeriod = 14;                 // Período ATR
public static bool     InpRequireADX = true;             // Requerir ADX > umbral
public static double   InpMinADX = 15.0;                 // ADX mínimo (AGRESIVO: 15 | moderado sugerido: 18)
public static int      InpADXPeriod = 14;                // Período ADX
public static int      InpRSIPeriod = 14;                // Período RSI
public static double   InpRSIOversold = 45.0;           // RSI sobreventa (AGRESIVO: 45 | moderado sugerido: 42 | orig: 30)
public static double   InpRSIOverbought = 55.0;         // RSI sobrecompra (AGRESIVO: 55 | moderado sugerido: 58 | orig: 70)
public static double   InpTrendADXMin = 25.0;           // ADX mínimo para declarar tendencia fuerte
public static double   InpLateralADXMax = 24.0;          // Si ADX supera este valor, NO operar reversión lateral
public static bool     InpBloquearLateralConADXAlto = true; // Evita compras/ventas contra tendencia fuerte
public static double   InpSRProximityAtrMult = 0.35;     // Cercanía real a soporte/resistencia en múltiplos de ATR
public static bool     InpUsarFiltroDireccionEMA = true; // Bloquear compras si sesgo bajista y ventas si sesgo alcista
public static bool     InpOperarRegimenMixto = false;     // EXP-4.0: permitir nuevas entradas cuando el regimen es MIXTO (ADX debil y ATR no contraido)
public static bool     InpRequireCandleConfirmation = true; // Exigir vela CERRADA para señales (no precio en vivo)
public static bool     InpRequireFreshBreakout = false;      // Exigir ruptura "fresca" (AGRESIVO: false=desactivado | moderado sugerido: true)
public static int      InpEmaFastPeriod = 20;            // EMA rápida para confirmar dirección
public static int      InpEmaSlowPeriod = 50;            // EMA lenta para confirmar dirección
public static double   InpMinEmaSlopeAtrMult = 2.0;      // Pendiente mínima de EMA rápida en múltiplos de ATR
public static string   InpTradeDirection = "both";        // Dirección de trading (both/buy/sell)
public static int      InpSupportResistancePeriod = 12;  // Período para S/R (AGRESIVO: 12 | moderado sugerido: 16 | antes 20)
public static int      InpATRMediaPeriod = 50;           // Período para ATR promedio

public static string EntryModeName()
{
    switch(InpModoEntrada)
    {
        case ENUM_ENTRY_MODE.ENTRADA_PROTEGIDA:
            return "PROTEGIDA";
        case ENUM_ENTRY_MODE.ENTRADA_BALANCEADA:
            return "BALANCEADA";
        case ENUM_ENTRY_MODE.ENTRADA_FLEXIBLE:
            return "FLEXIBLE";
        case ENUM_ENTRY_MODE.ENTRADA_PERSONALIZADA:
            return "PERSONALIZADA";
    }
    return "BALANCEADA";
}

public static bool UseEntryRequireADX()
{
    switch(InpModoEntrada)
    {
        case ENUM_ENTRY_MODE.ENTRADA_PROTEGIDA:
            return true;
        case ENUM_ENTRY_MODE.ENTRADA_BALANCEADA:
        case ENUM_ENTRY_MODE.ENTRADA_FLEXIBLE:
            return false;
        case ENUM_ENTRY_MODE.ENTRADA_PERSONALIZADA:
            return InpRequireADX;
    }
    return InpRequireADX;
}

public static double EntryMinADX()
{
    switch(InpModoEntrada)
    {
        case ENUM_ENTRY_MODE.ENTRADA_PROTEGIDA:
            return 15.0;
        case ENUM_ENTRY_MODE.ENTRADA_BALANCEADA:
            return 12.0;
        case ENUM_ENTRY_MODE.ENTRADA_FLEXIBLE:
            return 10.0;
        case ENUM_ENTRY_MODE.ENTRADA_PERSONALIZADA:
            return InpMinADX;
    }
    return InpMinADX;
}

public static double EntryTrendADXMin()
{
    switch(InpModoEntrada)
    {
        case ENUM_ENTRY_MODE.ENTRADA_PROTEGIDA:
            return 25.0;
        case ENUM_ENTRY_MODE.ENTRADA_BALANCEADA:
            return 20.0;
        case ENUM_ENTRY_MODE.ENTRADA_FLEXIBLE:
            return 18.0;
        case ENUM_ENTRY_MODE.ENTRADA_PERSONALIZADA:
            return InpTrendADXMin;
    }
    return InpTrendADXMin;
}

public static double EntryLateralADXMax()
{
    switch(InpModoEntrada)
    {
        case ENUM_ENTRY_MODE.ENTRADA_PROTEGIDA:
            return 24.0;
        case ENUM_ENTRY_MODE.ENTRADA_BALANCEADA:
            return 30.0;
        case ENUM_ENTRY_MODE.ENTRADA_FLEXIBLE:
            return 35.0;
        case ENUM_ENTRY_MODE.ENTRADA_PERSONALIZADA:
            return InpLateralADXMax;
    }
    return InpLateralADXMax;
}

public static bool EntryBlockLateralHighADX()
{
    switch(InpModoEntrada)
    {
        case ENUM_ENTRY_MODE.ENTRADA_PROTEGIDA:
            return true;
        case ENUM_ENTRY_MODE.ENTRADA_BALANCEADA:
        case ENUM_ENTRY_MODE.ENTRADA_FLEXIBLE:
            return false;
        case ENUM_ENTRY_MODE.ENTRADA_PERSONALIZADA:
            return InpBloquearLateralConADXAlto;
    }
    return InpBloquearLateralConADXAlto;
}

public static double EntrySRProximityAtrMult()
{
    switch(InpModoEntrada)
    {
        case ENUM_ENTRY_MODE.ENTRADA_PROTEGIDA:
            return 0.35;
        case ENUM_ENTRY_MODE.ENTRADA_BALANCEADA:
            return 0.60;
        case ENUM_ENTRY_MODE.ENTRADA_FLEXIBLE:
            return 0.80;
        case ENUM_ENTRY_MODE.ENTRADA_PERSONALIZADA:
            return InpSRProximityAtrMult;
    }
    return InpSRProximityAtrMult;
}

public static bool EntryUseEMADirectionFilter()
{
    switch(InpModoEntrada)
    {
        case ENUM_ENTRY_MODE.ENTRADA_PROTEGIDA:
            return true;
        case ENUM_ENTRY_MODE.ENTRADA_BALANCEADA:
        case ENUM_ENTRY_MODE.ENTRADA_FLEXIBLE:
            return false;
        case ENUM_ENTRY_MODE.ENTRADA_PERSONALIZADA:
            return InpUsarFiltroDireccionEMA;
    }
    return InpUsarFiltroDireccionEMA;
}

public static double EntryMinEmaSlopeAtrMult()
{
    switch(InpModoEntrada)
    {
        case ENUM_ENTRY_MODE.ENTRADA_PROTEGIDA:
            return 2.0;
        case ENUM_ENTRY_MODE.ENTRADA_BALANCEADA:
            return 1.0;
        case ENUM_ENTRY_MODE.ENTRADA_FLEXIBLE:
            return 0.7;
        case ENUM_ENTRY_MODE.ENTRADA_PERSONALIZADA:
            return InpMinEmaSlopeAtrMult;
    }
    return InpMinEmaSlopeAtrMult;
}

public static double EntryRSIOversold()
{
    switch(InpModoEntrada)
    {
        case ENUM_ENTRY_MODE.ENTRADA_PROTEGIDA:
            return 45.0;
        case ENUM_ENTRY_MODE.ENTRADA_BALANCEADA:
            return 48.0;
        case ENUM_ENTRY_MODE.ENTRADA_FLEXIBLE:
            return 50.0;
        case ENUM_ENTRY_MODE.ENTRADA_PERSONALIZADA:
            return InpRSIOversold;
    }
    return InpRSIOversold;
}

public static double EntryRSIOverbought()
{
    switch(InpModoEntrada)
    {
        case ENUM_ENTRY_MODE.ENTRADA_PROTEGIDA:
            return 55.0;
        case ENUM_ENTRY_MODE.ENTRADA_BALANCEADA:
            return 52.0;
        case ENUM_ENTRY_MODE.ENTRADA_FLEXIBLE:
            return 50.0;
        case ENUM_ENTRY_MODE.ENTRADA_PERSONALIZADA:
            return InpRSIOverbought;
    }
    return InpRSIOverbought;
}



public const int ORDER_TYPE_BUY=0, ORDER_TYPE_SELL=1;
public static bool EvoUseERFilter=false;
public static double EvoMinER=.3;
public static bool EvoUseBBFilter=false;
public static bool EvoUseOBVFilter=false;
public class EvoFrameContext { public bool valid; public int direction; public string regime; public double adx; }
public struct MqlRates { public double close; }
public class EvoSnapshot {
 public double[] atr=new double[3], adx=new double[3], rsi=new double[3], fast=new double[3], slow=new double[3], support=new double[3], resistance=new double[3], average=new double[3];
 public MqlRates current,confirmed,previous;
 public string regime,reason,buyChecks,sellChecks;
 public int direction,confidence,signal;
 public double er; public bool erValid;
 public bool obvValid; public double obvDelta;
 public bool bbValid;
 public double bbLower,bbMiddle,bbUpper;
}
static double[] g_atrBuffer,g_adxBuffer,g_rsiBuffer,g_emaFastBuffer,g_emaSlowBuffer,g_supportBuffer,g_resistanceBuffer,g_atrMediaBuffer;
static string g_currentRegime; static int g_trendDirection,g_regimeConfidence;
static int ArraySize(double[] a) { return a.Length; }
static double SymbolInfoDouble(string symbol,int property) { return .01; }
const string _Symbol="SYNTHETIC"; const int SYMBOL_POINT=0;
public static int Run() {
 Random r=new Random(7132601);
 for(int n=0;n<5000;n++) {
  InpModoEntrada=(ENUM_ENTRY_MODE)(n%4); InpRequireADX=n%2==0;
  InpRequireCandleConfirmation=n%3!=0; InpRequireFreshBreakout=n%5!=0;
  InpUsarFiltroDireccionEMA=n%7!=0; InpBloquearLateralConADXAlto=n%11!=0;
  InpTradeDirection=new string[]{"both","buy","sell","invalid"}[n%4];
  EvoSnapshot s=new EvoSnapshot();
  for(int i=0;i<3;i++) {
   s.atr[i]=1+r.NextDouble()*10; s.adx[i]=r.NextDouble()*60; s.rsi[i]=r.NextDouble()*100;
   s.fast[i]=90+r.NextDouble()*20; s.slow[i]=90+r.NextDouble()*20;
   s.support[i]=90+r.NextDouble()*10; s.resistance[i]=100+r.NextDouble()*10;
   s.average[i]=1+r.NextDouble()*10;
  }
  s.current.close=85+r.NextDouble()*30; s.confirmed.close=85+r.NextDouble()*30; s.previous.close=85+r.NextDouble()*30;
  g_atrBuffer=s.atr; g_adxBuffer=s.adx; g_rsiBuffer=s.rsi;
  g_emaFastBuffer=s.fast; g_emaSlowBuffer=s.slow; g_supportBuffer=s.support;
  g_resistanceBuffer=s.resistance; g_atrMediaBuffer=s.average;
  OriginalRegime(InpRequireCandleConfirmation?s.confirmed.close:s.current.close);
  int old=OriginalEntry(s);
  EvoEvaluate(s,.01,false,true);
  if(old!=s.signal || g_currentRegime!=s.regime || g_trendDirection!=s.direction || g_regimeConfidence!=s.confidence)
    throw new Exception("Analysis mismatch sample "+n);
 }
 // Integration: optional Bollinger confirms or blocks, never originates a signal.
 InpModoEntrada=ENUM_ENTRY_MODE.ENTRADA_PERSONALIZADA;
 InpTradeDirection="both"; InpRequireFreshBreakout=false; InpRequireCandleConfirmation=true;
 EvoSnapshot b=new EvoSnapshot();
 for(int i=0;i<3;i++) { b.atr[i]=2; b.adx[i]=30; b.rsi[i]=50; b.fast[i]=100; b.slow[i]=99; b.support[i]=95; b.resistance[i]=105; b.average[i]=2; }
 b.current.close=110; b.confirmed.close=110; b.previous.close=109;
 b.bbValid=true; b.bbLower=100; b.bbMiddle=111; b.bbUpper=120;
 EvoEvaluate(b,.01); if(b.signal!=1) throw new Exception("Base BUY missing");
 EvoUseBBFilter=true; EvoEvaluate(b,.01); if(b.signal!=0) throw new Exception("BB failed to block");
 b.bbMiddle=108; EvoEvaluate(b,.01); if(b.signal!=1) throw new Exception("BB failed to confirm");
 b.bbValid=false; EvoEvaluate(b,.01); if(b.signal!=0) throw new Exception("Missing BB did not block");
 EvoUseBBFilter=false; EvoEvaluate(b,.01); if(b.signal!=1) throw new Exception("Context BB changed entry");
 if(!EvoBollingerAllows(-1,"TENDENCIA",true,90,80,100,120)) throw new Exception("Trend SELL");
 if(!EvoBollingerAllows(1,"LATERAL",true,80,80,100,120)) throw new Exception("Range BUY boundary");
 if(!EvoBollingerAllows(-1,"LATERAL",true,120,80,100,120)) throw new Exception("Range SELL boundary");
 if(EvoBollingerAllows(1,"TENDENCIA",true,100,100,100,100)) throw new Exception("Flat BB passed");
 // OBV integration: context preserves BUY; enabled filter confirms, blocks and cannot originate entries.
 b.obvValid=true; b.obvDelta=-10; EvoEvaluate(b,.01); if(b.signal!=1) throw new Exception("OBV context changed BUY");
 EvoUseOBVFilter=true; EvoEvaluate(b,.01); if(b.signal!=0) throw new Exception("Opposing OBV passed BUY");
 b.obvDelta=10; EvoEvaluate(b,.01); if(b.signal!=1) throw new Exception("Rising OBV blocked BUY");
 b.obvDelta=0; EvoEvaluate(b,.01); if(b.signal!=0) throw new Exception("Flat OBV passed");
 b.obvDelta=10; b.obvValid=false; EvoEvaluate(b,.01); if(b.signal!=0) throw new Exception("Missing OBV passed");
 b.obvValid=true; b.support[1]=111; b.resistance[1]=120; EvoEvaluate(b,.01); if(b.signal!=0) throw new Exception("OBV created entry");
 for(int i=0;i<3;i++) { b.fast[i]=100; b.slow[i]=101; b.support[i]=95; b.resistance[i]=105; }
 b.current.close=90; b.confirmed.close=90; b.previous.close=91; b.obvDelta=-10;
 EvoEvaluate(b,.01); if(b.signal!=-1) throw new Exception("Falling OBV blocked SELL");
 b.obvDelta=10; EvoEvaluate(b,.01); if(b.signal!=0) throw new Exception("Rising OBV passed SELL");
 EvoUseOBVFilter=false; EvoEvaluate(b,.01); if(b.signal!=-1) throw new Exception("OBV context changed SELL");
 // Closed-context regimes and TP modes execute the production pure functions.
 EvoFrameContext f=new EvoFrameContext();
 EvoFrameRegime(110,105,104,100,2,2,30,f); if(!f.valid || f.regime!="TENDENCIA" || f.direction!=1) throw new Exception("MTF bullish");
 EvoFrameRegime(90,95,96,100,2,2,30,f); if(f.regime!="TENDENCIA" || f.direction!=-1) throw new Exception("MTF bearish");
 EvoFrameRegime(100,100,100,100,1,2,10,f); if(f.regime!="LATERAL" || f.direction!=0) throw new Exception("MTF lateral");
 EvoFrameRegime(100,100,100,100,2,1,10,f); if(f.regime!="MIXTO") throw new Exception("MTF mixed");
 if(EvoTargetDistance(false,8,3,12,2)!=24) throw new Exception("RR changed");
 if(EvoTargetDistance(true,8,3,12,2)!=24) throw new Exception("ATR target");
 if(EvoTargetDistance(true,8,3,5,9)!=24) throw new Exception("ATR depends on risk/RR");
 if(EvoTargetDistance(false,8,3,5,2)!=10) throw new Exception("RR ignores risk");
 // Closed-only evaluation uses index zero as the closed breakout level.
 b.current.close=110; b.confirmed.close=90; b.previous.close=104;
 for(int i=0;i<3;i++) { b.fast[i]=100; b.slow[i]=99; b.adx[i]=30; b.support[i]=95; b.resistance[i]=105; }
 b.resistance[1]=120; InpRequireCandleConfirmation=true;
 EvoEvaluate(b,.01,true); if(b.signal!=1) throw new Exception("Closed signal used wrong candle/level");
 EvoEvaluate(b,.01); if(b.signal==1) throw new Exception("Live evaluator changed");
 return 5028;
}
public static void OriginalRegime(double close) { int score=0; string reasons="";
    double emaFast = g_emaFastBuffer[0];
    double emaSlow = g_emaSlowBuffer[0];
    double atr = g_atrBuffer[0];
    double adx = g_adxBuffer[0];

    double emaSlopePrice = 0.0;
    if(ArraySize(g_emaFastBuffer) > 2)
        emaSlopePrice = emaFast - g_emaFastBuffer[2];

    double minSlopePrice = 0.0;
    if(atr > 0.0)
        minSlopePrice = atr * 0.10 * EntryMinEmaSlopeAtrMult(); // pendiente mínima ajustada por modo de entrada

    bool bullishStack = (close > emaFast && emaFast > emaSlow);
    bool bearishStack = (close < emaFast && emaFast < emaSlow);
    bool bullishImpulse = (close > emaFast && emaSlopePrice > minSlopePrice);
    bool bearishImpulse = (close < emaFast && emaSlopePrice < -minSlopePrice);

    bool bullishBias = (bullishStack || bullishImpulse);
    bool bearishBias = (bearishStack || bearishImpulse);

    g_trendDirection = 0;
    if(bullishBias && !bearishBias)
        g_trendDirection = 1;
    else if(bearishBias && !bullishBias)
        g_trendDirection = -1;

    if(adx >= EntryTrendADXMin())
    {
        score += 2;
        reasons += "ADX tendencia fuerte ";
    }
    else if(adx > 20.0)
    {
        score++;
        reasons += "ADX medio ";
    }

    if(g_trendDirection == 1)
    {
        score++;
        reasons += "sesgo alcista EMA ";
    }
    else if(g_trendDirection == -1)
    {
        score++;
        reasons += "sesgo bajista EMA ";
    }

    if(atr > g_atrMediaBuffer[0] && g_atrMediaBuffer[0] > 0)
    {
        score++;
        reasons += "ATR expandido ";
    }

    //--- Clasificación corregida:
    //--- Si ADX es alto y existe sesgo direccional, no debe tratarse como lateral.
    //--- EXP-4.0: antes, cualquier caso que no fuera TENDENCIA caia en LATERAL, aunque el ATR no
    //--- estuviera realmente contraido (ADX debil + rango sin contraerse = mercado sin sesgo claro,
    //--- ni en tendencia ni en rango real). Ese tercer caso ("MIXTO") resulto ser sistematicamente
    //--- el peor de los tres en el analisis de los backtests de Fase 1/2 (~30% win rate).
    if(adx >= EntryTrendADXMin() && g_trendDirection != 0)
        g_currentRegime = "TENDENCIA";
    else if(atr > 0.0 && g_atrMediaBuffer[0] > 0.0 && atr < g_atrMediaBuffer[0])
        g_currentRegime = "LATERAL";
    else
        g_currentRegime = "MIXTO";

    g_regimeConfidence = (int)((Math.Min(score, 4) / 4.0) * 100);

}public static int OriginalEntry(EvoSnapshot s) {
bool gotConfirmed=InpRequireCandleConfirmation;
MqlRates previousBar=s.previous;
double close=gotConfirmed?s.confirmed.close:s.current.close;
    double atr = g_atrBuffer[0];
    double adx = g_adxBuffer[0];
    double rsi = g_rsiBuffer[0];

    //--- NUEVO V4: si usamos vela cerrada (shift1), el nivel de soporte/resistencia
    //--- correspondiente también es el de shift1 (índice 1 del buffer), no el de la
    //--- vela en formación (índice 0). Para la vela anterior (shift2) usamos índice 2.
    int lvlIdx  = gotConfirmed ? 1 : 0;
    int prevIdx = gotConfirmed ? 2 : 1;
    
    //--- Verificar dirección permitida
    string direction = InpTradeDirection;
    direction=direction.ToLower(); // Usar función del sistema
    bool allowBuy = (direction == "both" || direction == "buy");
    bool allowSell = (direction == "both" || direction == "sell");
    
    bool entrySignal = false;
    int orderType = ORDER_TYPE_BUY; // Inicializar para evitar warning
    
    //=== RÉGIMEN TENDENCIA: Momentum + Ruptura ===
    if(g_currentRegime == "TENDENCIA")
    {
        //--- NUEVO V4: ruptura "fresca" = la vela anterior NO estaba ya rota
        bool freshUp = true;
        bool freshDown = true;
        if(InpRequireFreshBreakout && gotConfirmed)
        {
            if(prevIdx < ArraySize(g_resistanceBuffer))
                freshUp = (previousBar.close <= g_resistanceBuffer[prevIdx]);
            if(prevIdx < ArraySize(g_supportBuffer))
                freshDown = (previousBar.close >= g_supportBuffer[prevIdx]);
        }

        bool useEmaDirectionFilter = EntryUseEMADirectionFilter();
        bool allowTrendBuy = (!useEmaDirectionFilter || g_trendDirection >= 0);
        bool allowTrendSell = (!useEmaDirectionFilter || g_trendDirection <= 0);

        //--- Señal de compra: la vela cerrada cierra por encima de la resistencia y no hay sesgo bajista
        if(allowBuy && allowTrendBuy && close > g_resistanceBuffer[lvlIdx] && freshUp &&
           (!UseEntryRequireADX() || adx > EntryMinADX()))
        {
            entrySignal = true;
            orderType = ORDER_TYPE_BUY;
            
        }
        //--- Señal de venta: la vela cerrada cierra por debajo del soporte
        else if(allowSell && allowTrendSell && close < g_supportBuffer[lvlIdx] && freshDown &&
                (!UseEntryRequireADX() || adx > EntryMinADX()))
        {
            entrySignal = true;
            orderType = ORDER_TYPE_SELL;
            
        }
    }
    //=== RÉGIMEN LATERAL: Reversión + Rango ===
    else if(g_currentRegime == "LATERAL")
    {
        //--- V6.10: corrección crítica. Antes se usaba soporte*1.05 y resistencia*0.95.
        //--- En XAUUSD eso hacía que casi cualquier precio pareciera "cerca" del nivel.
        //--- Ahora la cercanía se mide por distancia real en precio usando ATR.
        double proximity = Math.Max(atr * EntrySRProximityAtrMult(), 10.0 * SymbolInfoDouble(_Symbol, SYMBOL_POINT));
        bool cercaSoporte = (Math.Abs(close - g_supportBuffer[lvlIdx]) <= proximity);
        bool cercaResistencia = (Math.Abs(close - g_resistanceBuffer[lvlIdx]) <= proximity);

        bool lateralPermitido = true;
        if(EntryBlockLateralHighADX() && adx > EntryLateralADXMax())
        {
            lateralPermitido = false;
            
        }

        bool useEmaDirectionFilter = EntryUseEMADirectionFilter();
        bool compraBloqueadaPorDireccion = (useEmaDirectionFilter && g_trendDirection == -1);
        bool ventaBloqueadaPorDireccion  = (useEmaDirectionFilter && g_trendDirection == 1);

        //--- Señal de compra: RSI bajo, pero sólo si realmente está cerca del soporte y no hay sesgo bajista fuerte
        if(lateralPermitido && allowBuy && cercaSoporte && !compraBloqueadaPorDireccion && rsi < EntryRSIOversold())
        {
            entrySignal = true;
            orderType = ORDER_TYPE_BUY;
            
        }
        //--- Señal de venta: RSI alto, pero sólo si realmente está cerca de resistencia y no hay sesgo alcista fuerte
        else if(lateralPermitido && allowSell && cercaResistencia && !ventaBloqueadaPorDireccion && rsi > EntryRSIOverbought())
        {
            entrySignal = true;
            orderType = ORDER_TYPE_SELL;
            
        }
    }
    

return entrySignal?(orderType==ORDER_TYPE_BUY?1:-1):0;
}public static bool EvoBollingerAllows(int direction,string regime,bool valid,
                        double price,double lower,double middle,double upper)
{
   if(!valid || upper<=lower || middle<lower || middle>upper) return false;
   if(regime=="TENDENCIA") return direction>0?price>middle:price<middle;
   if(regime=="LATERAL") return direction>0?price<=lower:price>=upper;
   return false;
}public static void EvoEvaluate(EvoSnapshot s, double point, bool closedOnly=false,bool baseOnly=false)
{
   double close=closedOnly?s.current.close:(InpRequireCandleConfirmation?s.confirmed.close:s.current.close);
   double slope=s.fast[0]-s.fast[2];
   double minSlope=s.atr[0]*0.10*EntryMinEmaSlopeAtrMult();
   bool bull=(close>s.fast[0] && s.fast[0]>s.slow[0]) || (close>s.fast[0] && slope>minSlope);
   bool bear=(close<s.fast[0] && s.fast[0]<s.slow[0]) || (close<s.fast[0] && slope< -minSlope);
   s.direction=(bull&&!bear)?1:((bear&&!bull)?-1:0);
   int score=(s.adx[0]>=EntryTrendADXMin()?2:(s.adx[0]>20?1:0));
   if(s.direction!=0) score++;
   if(s.atr[0]>s.average[0] && s.average[0]>0) score++;
   s.confidence=(int)(Math.Min(score,4)/4.0*100);
   s.regime=(s.adx[0]>=EntryTrendADXMin() && s.direction!=0)?"TENDENCIA":
            ((s.atr[0]<s.average[0] && s.atr[0]>0)?"LATERAL":"MIXTO");
   s.signal=0; s.reason="Sin confluencia tecnica de entrada";
   int idx=closedOnly?0:(InpRequireCandleConfirmation?1:0);
   string dir=InpTradeDirection; dir=dir.ToLower();
   bool buy=(dir=="both" || dir=="buy"), sell=(dir=="both" || dir=="sell");
   bool ema=EntryUseEMADirectionFilter();
   s.buyChecks=buy?"":"direccion; "; s.sellChecks=sell?"":"direccion; ";
   if(ema && s.direction<0) s.buyChecks+="sesgo EMA; ";
   if(ema && s.direction>0) s.sellChecks+="sesgo EMA; ";
   if(s.regime=="TENDENCIA")
   {
      bool freshUp=!InpRequireFreshBreakout || !InpRequireCandleConfirmation || s.previous.close<=s.resistance[closedOnly?1:2];
      bool freshDown=!InpRequireFreshBreakout || !InpRequireCandleConfirmation || s.previous.close>=s.support[closedOnly?1:2];
      bool adxOK=!UseEntryRequireADX() || s.adx[0]>EntryMinADX();
      if(close<=s.resistance[idx]) s.buyChecks+="ruptura; ";
      if(close>=s.support[idx]) s.sellChecks+="ruptura; ";
      if(!freshUp) s.buyChecks+="ruptura fresca; ";
      if(!freshDown) s.sellChecks+="ruptura fresca; ";
      if(!adxOK) { s.buyChecks+="ADX; "; s.sellChecks+="ADX; "; }
      if(buy && (!ema || s.direction>=0) && close>s.resistance[idx] && freshUp && adxOK) s.signal=1;
      else if(sell && (!ema || s.direction<=0) && close<s.support[idx] && freshDown && adxOK) s.signal=-1;
      if(!adxOK) s.reason="ADX inferior al umbral efectivo";
   }
   else if(s.regime=="LATERAL")
   {
      double proximity=Math.Max(s.atr[0]*EntrySRProximityAtrMult(),10*point);
      bool lateral=!EntryBlockLateralHighADX() || s.adx[0]<=EntryLateralADXMax();
      if(!lateral) { s.buyChecks+="ADX lateral; "; s.sellChecks+="ADX lateral; "; }
      if(Math.Abs(close-s.support[idx])>proximity) s.buyChecks+="lejos soporte; ";
      if(Math.Abs(close-s.resistance[idx])>proximity) s.sellChecks+="lejos resistencia; ";
      if(s.rsi[0]>=EntryRSIOversold()) s.buyChecks+="RSI; ";
      if(s.rsi[0]<=EntryRSIOverbought()) s.sellChecks+="RSI; ";
      if(lateral && buy && (!ema || s.direction!=-1) && Math.Abs(close-s.support[idx])<=proximity && s.rsi[0]<EntryRSIOversold()) s.signal=1;
      else if(lateral && sell && (!ema || s.direction!=1) && Math.Abs(close-s.resistance[idx])<=proximity && s.rsi[0]>EntryRSIOverbought()) s.signal=-1;
      if(!lateral) s.reason="Reversion bloqueada por ADX alto";
   }
   else { s.reason="Regimen mixto: estrategia base sin patron de entrada"; s.buyChecks+="regimen mixto; "; s.sellChecks+="regimen mixto; "; }
   if(s.signal!=0) s.reason="Confluencia tecnica "+s.regime+" "+(s.signal==1?"BUY":"SELL");
   if(baseOnly) return; // v1.13 technical patterns, without additional monitor filters.
   if(EvoUseERFilter && (!s.erValid || s.er<EvoMinER))
   { s.signal=0; s.reason=s.erValid?"ER inferior al minimo configurado":"ER no disponible"; s.buyChecks+="ER; "; s.sellChecks+="ER; "; }
   if(EvoUseBBFilter)
   {
      bool bbBuy=EvoBollingerAllows(1,s.regime,s.bbValid,close,s.bbLower,s.bbMiddle,s.bbUpper);
      bool bbSell=EvoBollingerAllows(-1,s.regime,s.bbValid,close,s.bbLower,s.bbMiddle,s.bbUpper);
      if(!bbBuy) s.buyChecks+="Bollinger; ";
      if(!bbSell) s.sellChecks+="Bollinger; ";
      if((s.signal>0 && !bbBuy) || (s.signal<0 && !bbSell))
      { s.signal=0; s.reason=s.bbValid?"Bollinger no confirma el patron del regimen":"Bollinger sin datos disponibles"; }
      else if(s.signal!=0) s.reason+="; Bollinger confirma";
   }
   if(EvoUseOBVFilter)
   {
      bool obvBuy=s.obvValid && s.obvDelta>0;
      bool obvSell=s.obvValid && s.obvDelta<0;
      if(!obvBuy) s.buyChecks+="OBV; ";
      if(!obvSell) s.sellChecks+="OBV; ";
      if((s.signal>0 && !obvBuy) || (s.signal<0 && !obvSell))
      { s.signal=0; s.reason=s.obvValid?"OBV no confirma la direccion de entrada":"OBV sin datos de volumen disponibles"; }
      else if(s.signal!=0) s.reason+="; OBV confirma";
   }
   if(s.buyChecks=="") s.buyChecks="condiciones tecnicas cumplidas";
   if(s.sellChecks=="") s.sellChecks="condiciones tecnicas cumplidas";
}public static void EvoFrameRegime(double price,double fast,double olderFast,double slow,
                    double atr,double average,double adx,EvoFrameContext r)
{
   double slope=fast-olderFast,minimum=atr*0.10*EntryMinEmaSlopeAtrMult();
   bool bull=(price>fast && fast>slow) || (price>fast && slope>minimum);
   bool bear=(price<fast && fast<slow) || (price<fast && slope< -minimum);
   r.direction=bull&&!bear?1:bear&&!bull?-1:0;
   r.regime=adx>=EntryTrendADXMin() && r.direction!=0?"TENDENCIA":atr<average?"LATERAL":"MIXTO";
   r.adx=adx; r.valid=true;
}public static double EvoTargetDistance(bool byATR,double atr,double multiplier,double risk,double rr)
{ return byATR?atr*multiplier:risk*rr; }
}