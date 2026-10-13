#ifndef EVOLUTION_ANALYSIS_INPUTS
#define EVOLUTION_ANALYSIS_INPUTS
enum ENUM_ENTRY_MODE
{
    ENTRADA_PERSONALIZADA = 0, // Usa los parametros manuales de entrada
    ENTRADA_PROTEGIDA    = 1, // Menos entradas, filtros mas estrictos
    ENTRADA_BALANCEADA   = 2, // Mas activa sin abrir demasiado el filtro
    ENTRADA_FLEXIBLE     = 3  // Maxima frecuencia de entradas
};
input group "Analisis compartido SignalFusion / Monitor"
input ENUM_ENTRY_MODE InpModoEntrada = ENTRADA_FLEXIBLE; // Acceso activo al mercado con filtros minimos
input int      InpATRPeriod = 14;                 // Período ATR
input bool     InpRequireADX = true;             // Requerir ADX > umbral
input double   InpMinADX = 15.0;                 // ADX mínimo (AGRESIVO: 15 | moderado sugerido: 18)
input int      InpADXPeriod = 14;                // Período ADX
input int      InpRSIPeriod = 14;                // Período RSI
input double   InpRSIOversold = 45.0;           // RSI sobreventa (AGRESIVO: 45 | moderado sugerido: 42 | orig: 30)
input double   InpRSIOverbought = 55.0;         // RSI sobrecompra (AGRESIVO: 55 | moderado sugerido: 58 | orig: 70)
input double   InpTrendADXMin = 25.0;           // ADX mínimo para declarar tendencia fuerte
input double   InpLateralADXMax = 24.0;          // Si ADX supera este valor, NO operar reversión lateral
input bool     InpBloquearLateralConADXAlto = true; // Evita compras/ventas contra tendencia fuerte
input double   InpSRProximityAtrMult = 0.35;     // Cercanía real a soporte/resistencia en múltiplos de ATR
input bool     InpUsarFiltroDireccionEMA = true; // Bloquear compras si sesgo bajista y ventas si sesgo alcista
input bool     InpOperarRegimenMixto = false;     // EXP-4.0: permitir nuevas entradas cuando el regimen es MIXTO (ADX debil y ATR no contraido)
input bool     InpRequireCandleConfirmation = true; // Exigir vela CERRADA para señales (no precio en vivo)
input bool     InpRequireFreshBreakout = false;      // Exigir ruptura "fresca" (AGRESIVO: false=desactivado | moderado sugerido: true)
input int      InpEmaFastPeriod = 20;            // EMA rápida para confirmar dirección
input int      InpEmaSlowPeriod = 50;            // EMA lenta para confirmar dirección
input double   InpMinEmaSlopeAtrMult = 2.0;      // Pendiente mínima de EMA rápida en múltiplos de ATR
input string   InpTradeDirection = "both";        // Dirección de trading (both/buy/sell)
input int      InpSupportResistancePeriod = 12;  // Período para S/R (AGRESIVO: 12 | moderado sugerido: 16 | antes 20)
input int      InpATRMediaPeriod = 50;           // Período para ATR promedio

string EntryModeName()
{
    switch(InpModoEntrada)
    {
        case ENTRADA_PROTEGIDA:
            return "PROTEGIDA";
        case ENTRADA_BALANCEADA:
            return "BALANCEADA";
        case ENTRADA_FLEXIBLE:
            return "FLEXIBLE";
        case ENTRADA_PERSONALIZADA:
            return "PERSONALIZADA";
    }
    return "BALANCEADA";
}

bool UseEntryRequireADX()
{
    switch(InpModoEntrada)
    {
        case ENTRADA_PROTEGIDA:
            return true;
        case ENTRADA_BALANCEADA:
        case ENTRADA_FLEXIBLE:
            return false;
        case ENTRADA_PERSONALIZADA:
            return InpRequireADX;
    }
    return InpRequireADX;
}

double EntryMinADX()
{
    switch(InpModoEntrada)
    {
        case ENTRADA_PROTEGIDA:
            return 15.0;
        case ENTRADA_BALANCEADA:
            return 12.0;
        case ENTRADA_FLEXIBLE:
            return 10.0;
        case ENTRADA_PERSONALIZADA:
            return InpMinADX;
    }
    return InpMinADX;
}

double EntryTrendADXMin()
{
    switch(InpModoEntrada)
    {
        case ENTRADA_PROTEGIDA:
            return 25.0;
        case ENTRADA_BALANCEADA:
            return 20.0;
        case ENTRADA_FLEXIBLE:
            return 18.0;
        case ENTRADA_PERSONALIZADA:
            return InpTrendADXMin;
    }
    return InpTrendADXMin;
}

double EntryLateralADXMax()
{
    switch(InpModoEntrada)
    {
        case ENTRADA_PROTEGIDA:
            return 24.0;
        case ENTRADA_BALANCEADA:
            return 30.0;
        case ENTRADA_FLEXIBLE:
            return 35.0;
        case ENTRADA_PERSONALIZADA:
            return InpLateralADXMax;
    }
    return InpLateralADXMax;
}

bool EntryBlockLateralHighADX()
{
    switch(InpModoEntrada)
    {
        case ENTRADA_PROTEGIDA:
            return true;
        case ENTRADA_BALANCEADA:
        case ENTRADA_FLEXIBLE:
            return false;
        case ENTRADA_PERSONALIZADA:
            return InpBloquearLateralConADXAlto;
    }
    return InpBloquearLateralConADXAlto;
}

double EntrySRProximityAtrMult()
{
    switch(InpModoEntrada)
    {
        case ENTRADA_PROTEGIDA:
            return 0.35;
        case ENTRADA_BALANCEADA:
            return 0.60;
        case ENTRADA_FLEXIBLE:
            return 0.80;
        case ENTRADA_PERSONALIZADA:
            return InpSRProximityAtrMult;
    }
    return InpSRProximityAtrMult;
}

bool EntryUseEMADirectionFilter()
{
    switch(InpModoEntrada)
    {
        case ENTRADA_PROTEGIDA:
            return true;
        case ENTRADA_BALANCEADA:
        case ENTRADA_FLEXIBLE:
            return false;
        case ENTRADA_PERSONALIZADA:
            return InpUsarFiltroDireccionEMA;
    }
    return InpUsarFiltroDireccionEMA;
}

double EntryMinEmaSlopeAtrMult()
{
    switch(InpModoEntrada)
    {
        case ENTRADA_PROTEGIDA:
            return 2.0;
        case ENTRADA_BALANCEADA:
            return 1.0;
        case ENTRADA_FLEXIBLE:
            return 0.7;
        case ENTRADA_PERSONALIZADA:
            return InpMinEmaSlopeAtrMult;
    }
    return InpMinEmaSlopeAtrMult;
}

double EntryRSIOversold()
{
    switch(InpModoEntrada)
    {
        case ENTRADA_PROTEGIDA:
            return 45.0;
        case ENTRADA_BALANCEADA:
            return 48.0;
        case ENTRADA_FLEXIBLE:
            return 50.0;
        case ENTRADA_PERSONALIZADA:
            return InpRSIOversold;
    }
    return InpRSIOversold;
}

double EntryRSIOverbought()
{
    switch(InpModoEntrada)
    {
        case ENTRADA_PROTEGIDA:
            return 55.0;
        case ENTRADA_BALANCEADA:
            return 52.0;
        case ENTRADA_FLEXIBLE:
            return 50.0;
        case ENTRADA_PERSONALIZADA:
            return InpRSIOverbought;
    }
    return InpRSIOverbought;
}

#endif
