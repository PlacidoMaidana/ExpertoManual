//+------------------------------------------------------------------+
//|                                       SignalFusion ORO v1.11.mq5 |
//|                    Versión Micro para cuentas pequeñas (XAU/USD)  |
//|              Gestión por R: SL ATR + TP RR + BE + Trailing ATR en broker |
//+------------------------------------------------------------------+
#property copyright "SignalFusion Trading System"
#property link      ""
#property version   "1.20"
#property description "SignalFusion ORO: gestion ATR y registro automatico de cada operacion en tester y mercado real."

//--- Includes
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

#import "shell32.dll"
int ShellExecuteW(int hwnd, string lpOperation, string lpFile, string lpParameters, string lpDirectory, int nShowCmd);
#import

//--- Objetos de trading
CTrade         m_trade;
CPositionInfo  m_position;

//--- Estrategias de ratio riesgo/beneficio
//--- Conservadora: 1:1.5 | Balanceada: 1:2 | Tendencial: 1:2.5 | Personalizada: valor definido por el usuario
enum ENUM_RR_STRATEGY
{
    RR_CONSERVADORA = 0,
    RR_BALANCEADA   = 1,
    RR_TENDENCIAL   = 2,
    RR_PERSONALIZADA = 3
};

enum ENUM_SMART_EXIT_ACTION
{
    SMART_EXIT_CLOSE_FULL = 0,
    SMART_EXIT_TIGHTEN_SL = 1
};

enum ENUM_ENTRY_MODE
{
    ENTRADA_PERSONALIZADA = 0, // Usa los parametros manuales de entrada
    ENTRADA_PROTEGIDA    = 1, // Menos entradas, filtros mas estrictos
    ENTRADA_BALANCEADA   = 2, // Mas activa sin abrir demasiado el filtro
    ENTRADA_FLEXIBLE     = 3  // Maxima frecuencia de entradas
};

enum ENUM_LOT_MODE
{
    LOT_FIJO = 0,            // Usa InpLoteFijo
    LOT_RIESGO_PORCENTAJE = 1 // Calcula lote por % de equity segun distancia de SL
};

enum ENUM_RISK_BUDGET_MODE { RISK_PERCENT = 0, RISK_MONEY = 1, RISK_BOTH = 2 };
input group "=== PRESUPUESTO OBLIGATORIO POR OPERACION ==="
input ENUM_RISK_BUDGET_MODE InpRiskBudgetMode = RISK_PERCENT; // Porcentaje, dinero o el menor de ambos
input double InpRiskMoney = 1.0; // Dinero en MONEDA DE CUENTA (no siempre USD)
input double InpRiskCostsPerLot = 0.0; // Provision ida/vuelta de comision y otros costes por lote
input int InpRiskSlippagePoints = 0; // Provision adicional de deslizamiento al SL, en puntos

//--- Input Parameters
input group "=== PROTECCION DEL CIERRE DE SESION ==="
input bool InpSessionGuardEnabled = false; // Activar proteccion antes del cierre de sesion
input int InpSessionBlockMinutes = 30; // Minutos antes del cierre para bloquear entradas
input int InpSessionCloseMinutes = 10; // Minutos antes del cierre para cerrar posiciones
input bool InpSessionObservedReopen = true; // Contar espera desde primera cotizacion de la sesion
input int InpSessionWaitMinutes = 15; // Minutos de espera despues de la reapertura

input bool InpSkipUnchangedStops = true; // Evitar reenviar SL y TP ya aplicados

input group "=== REGISTRO DE DIAGNOSTICO ==="
input bool InpDiagnosticEnabled = true; // Registrar recorrido y decisiones sin cambiar reglas

input bool InpAllowTrendEntries = true; // Permitir nuevas entradas de tendencia

input group "=== PRUEBA ADX SOLO ENTRADAS DE TENDENCIA ==="
input bool InpTrendADXGateEnabled = false; // Exigir ADX adicional solo para entradas de tendencia
input double InpTrendADXGateMinimum = 25.0; // ADX debe superar este valor para entrar en tendencia

input group "=== MODO DE ENTRADA ==="
input ENUM_ENTRY_MODE InpModoEntrada = ENTRADA_FLEXIBLE; // Acceso activo al mercado con filtros minimos
//  PROTEGIDA: Menos entradas, filtros estrictos (menos pérdidas)
//  BALANCEADA: Más activo, punto medio
//  FLEXIBLE: Máxima frecuencia
//  PERSONALIZADA: Usa parámetros manuales

input group "=== GESTIÓN SIMPLE DE LOTE Y MARGEN ==="
const double   InpMarginSafetyPct = 0.0;         // Reserva de margen (70% de la equity NO se usa como margen)
const double   InpMinBalanceToTrade = 0.0;      // Balance minimo para operar (USD) - ver diagnostico "Capital minimo" del Gestor de Riesgo
input ENUM_LOT_MODE InpModoLote = LOT_RIESGO_PORCENTAJE; // Lote por riesgo %: el tamano se adapta a la distancia real del SL
input double   InpRiskPerTradePct = 1.0;          // % de equity arriesgado por operacion
const bool     InpPermitirLoteMinSiRiesgoInsuficiente = false; // Si el riesgo calculado no llega al lote minimo, NO operar (evita sobre-arriesgar cuentas chicas)
input double   InpLotMin = 0.01;                  // Lote mínimo permitido por la estrategia
input double   InpLoteFijo = 0.01;                // Lote base fijo. Solo se usa si InpModoLote = LOT_FIJO

input group "=== FRENO POR DRAWDOWN ==="
input bool     InpUsarFrenoDrawdown = false;       // Activo: corta nuevas entradas si el drawdown supera InpMaxDrawdownPct
input double   InpMaxDrawdownPct = 25.0;          // % maximo de drawdown desde equity pico
input int      InpDrawdownPauseMinutes = 240;     // Minutos de pausa tras activar freno
input int      InpDrawdownPauseMaxMinutes = 1440;  // EXP-2.1 fix v3: tope de pausa aunque escale por disparos seguidos (1440=24h)

input group "=== ESTRATEGIA RATIO RIESGO/BENEFICIO ==="
input ENUM_RR_STRATEGY InpRRStrategy = RR_BALANCEADA; // Estrategia RR
input double   InpRRPersonalizado = 2.0;          // RR usado si la estrategia es PERSONALIZADA
input double   InpMinRRPermitido = 1.20;          // Filtro: cancelar si TP/SL queda por debajo de este mínimo
input bool     InpCancelarSiRRInvalido = true;    // Cancelar operación si el RR real no es coherente

input group "=== PARÁMETROS ATR ==="
input int      InpATRPeriod = 14;                 // Período ATR
input double   InpATRMultiplier = 1.0;            // Multiplicador ATR base para SL inicial si no hay régimen específico

input group "=== FILTROS TÉCNICOS ==="
input bool     InpRequireADX = true;             // Requerir ADX > umbral
input double   InpMinADX = 15.0;                 // ADX mínimo (AGRESIVO: 15 | moderado sugerido: 18)
input int      InpADXPeriod = 14;                // Período ADX
input int      InpRSIPeriod = 14;                // Período RSI
input double   InpRSIOversold = 45.0;           // RSI sobreventa (AGRESIVO: 45 | moderado sugerido: 42 | orig: 30)
input double   InpRSIOverbought = 55.0;         // RSI sobrecompra (AGRESIVO: 55 | moderado sugerido: 58 | orig: 70)

input group "=== CONFIGURACIÓN DE REGÍMENES ==="
input double   InpTrendSLMult = 1.50; // TENDENCIA: multiplicador ATR del stop inicial
input double   InpTrendTrailingMult = 0.50; // TENDENCIA: multiplicador ATR del trailing
input double   InpLateralSLMult = 1.50; // LATERAL: multiplicador ATR del stop inicial
input double   InpLateralTrailingMult = 0.50; // LATERAL: multiplicador ATR del trailing
input double   InpTrendADXMin = 25.0;           // ADX mínimo para declarar tendencia fuerte
input double   InpLateralADXMax = 24.0;          // Si ADX supera este valor, NO operar reversión lateral
input bool     InpBloquearLateralConADXAlto = true; // Evita compras/ventas contra tendencia fuerte
input double   InpSRProximityAtrMult = 0.35;     // Cercanía real a soporte/resistencia en múltiplos de ATR
input bool     InpUsarFiltroDireccionEMA = true; // Bloquear compras si sesgo bajista y ventas si sesgo alcista
input bool     InpOperarRegimenMixto = false;     // EXP-4.0: permitir nuevas entradas cuando el regimen es MIXTO (ADX debil y ATR no contraido)

input group "=== CONFIRMACIÓN DE VELA Y COOLDOWN (NUEVO V4) ==="
input bool     InpRequireCandleConfirmation = true; // Exigir vela CERRADA para señales (no precio en vivo)
input bool     InpRequireFreshBreakout = false;      // Exigir ruptura "fresca" (AGRESIVO: false=desactivado | moderado sugerido: true)
input int      InpCooldownMinutes = 2;               // Minutos de espera tras cerrar una operación (AGRESIVO: 2 | moderado sugerido: 3-4 | antes 5)
input bool     InpCooldownOnlyAfterLoss = false;     // true=cooldown solo tras pérdida, false=tras cualquier cierre
input int      InpFailedOrderCooldownSeconds = 15;   // NUEVO V5.3: segundos de espera tras una orden rechazada por el bróker (evita spam de reintentos)
input int      InpCooldownMinSeconds = 90;           // EXP-1.1: piso duro en segundos tras CUALQUIER cierre, sin importar el modo de entrada (evita cascadas de reentrada)
input bool     InpUnaEntradaPorVela = true;          // EXP-1.2: maximo 1 entrada nueva por vela del timeframe del grafico
input bool     InpPausarTrasRachaPerdidas = true;    // EXP-1.3: pausar nuevas entradas (no solo reducir lote) tras alcanzar InpMaxConsecutiveLosses
input int      InpLossStreakPauseMinutes = 30;       // EXP-1.3: minutos de pausa cuando se activa el corte por racha de perdidas

input group "=== FILTRO EMA DE TENDENCIA ==="
input int      InpEmaFastPeriod = 20;            // EMA rápida para confirmar dirección
input int      InpEmaSlowPeriod = 50;            // EMA lenta para confirmar dirección
input double   InpMinEmaSlopeAtrMult = 2.0;      // Pendiente mínima de EMA rápida en múltiplos de ATR

input group "=== GESTIÓN DE SALIDA POR R ==="
input bool     InpUsarProteccionIncremental = true; // Usar reduccion progresiva de riesgo antes del trailing
input double   InpProteccionEtapa1TriggerR = 0.40; // Etapa 1: activar al ganar R (0 desactiva etapa)
input double   InpProteccionEtapa1StopR = -0.15; // Etapa 1: objetivo del SL en R desde entrada
input double   InpProteccionEtapa2TriggerR = 0.70; // Etapa 2: activar al ganar R (0 desactiva etapa)
input double   InpProteccionEtapa2StopR = 0.05; // Etapa 2: objetivo del SL en R desde entrada
input double   InpProteccionEtapa3TriggerR = 1.00; // Etapa 3: activar al ganar R (0 desactiva etapa)
input double   InpProteccionEtapa3StopR = 0.30; // Etapa 3: objetivo del SL en R desde entrada
input bool     InpMoverBreakEvenEn1R = true;      // Modo legacy: mover SL a break-even si no se usa proteccion incremental
input double   InpBreakEvenTriggerR = 0.0;        // No usado: SignalFusion ORO activa BE por ATR
input double   InpBreakEvenTriggerATR = 1.0;      // Gestion manual: BE al avanzar 1 ATR
input int      InpBreakEvenOffsetPoints = 0;      // Break-even exacto en el precio de entrada
input bool     InpUsarTrailingATREnBroker = true; // Trailing ATR real: modifica el SL en el broker
input double   InpTrailingATRTriggerR = 0.0;       // El trailing comienza por estado de break-even
input double   InpTrailingATRStepR = 0.0;         // La gestion manual usa paso absoluto
input int      InpMinTrailingStepPoints = 5;      // Paso mínimo absoluto para modificar SL
input bool     InpTrailingDespuesDeBreakEven = true; // No iniciar trailing mientras el SL siga en riesgo

input group "=== SMART EXIT POR AGOTAMIENTO ==="
input bool     InpUsarSmartExit = true;              // Salida inteligente si hay ganancia y agotamiento claro
input ENUM_SMART_EXIT_ACTION InpSmartExitAction = SMART_EXIT_CLOSE_FULL; // Accion al superar score (CLOSE_FULL = cierra | TIGHTEN_SL = ajusta SL)
input double   InpSmartExitMinProfitR = 0.70;        // Ganancia minima para evaluar salida inteligente
input int      InpSmartExitScoreCerrar = 5;          // Score requerido para actuar (reducido de 7 a 5 para ser más reactivo)
input int      InpSmartExitLookbackSR = 50;          // Velas para maximo/minimo relevante
input double   InpSmartExitSRProximityATR = 0.25;    // Cercania a S/R en ATR
input double   InpSmartExitAdxDrop = 8.0;            // Caida ADX vs hace 2 barras
input double   InpSmartExitAtrContractPct = 0.75;    // ATR actual menor a este % de ATR media
input int      InpSmartExitTightenPoints = 30;       // Si no cierra, ajustar SL a esta ganancia minima en puntos

input group "=== EXPORTACIÓN CSV DE OPERACIONES ==="
input bool     InpMostrarBotonExportCSV = true;      // Mostrar boton en el grafico para exportar analisis
input bool     InpExportarCSVAlFinalBacktest = true; // Exportar CSV automaticamente al finalizar backtest
input string   InpExportCSVPrefix = "SignalFusion_Riesgo114_Operaciones"; // Prefijo del archivo CSV
input bool     InpExportCSVCommonFiles = true;       // true=Common/Files, false=MQL5/Files
input string   InpExportSubFolder = "SignalFusion";  // Subcarpeta fija dentro de esa carpeta (vacio = raiz). Los botones no funcionan en el Tester; esta ruta si es predecible.
input bool     InpAbrirCarpetaAlExportar = true;     // Abrir carpeta al terminar la exportacion (solo fuera de optimizacion)
input int      InpExportLookbackDays = 30;           // Dias de historial a exportar
input int      InpExportButtonX = 12;                // Posicion X del boton
input int      InpExportButtonY = 12;                // Posicion Y del boton
input bool     InpLogOperacionesAutomatico = true;   // Registrar cada entrada/salida al confirmarse
input string   InpLogOperacionesPrefix = "SignalFusion_Riesgo114_Log"; // Prefijo de bitacora incremental

input group "=== CONTROL MANUAL DE ENTRADAS ==="
input bool     InpIniciarEntradasPausadas = false;   // Estado inicial si no existe un estado guardado
input int      InpEntryButtonX = 12;                 // Posicion X del boton de entradas
input int      InpEntryButtonY = 44;                 // Posicion Y del boton de entradas

input group "=== PROTECCIÓN POR RACHAS ==="
input int      InpMaxConsecutiveLosses = 5;       // Pérdidas seguidas antes de reducir lote (AGRESIVO: 5 | moderado sugerido: 4 | antes 3)
input double   InpMinLotMultiplier = 0.50;       // Reducción mínima del lote tras rachas (AGRESIVO: 0.50 | moderado sugerido: 0.40 | antes 0.30)
input double   InpLotMultiplierDecay = 0.10;     // Reducción por pérdida cuando supera el umbral
input double   InpLotMultiplierRecovery = 0.05;   // Recuperación por trade ganador

input group "=== FILTRO DE SPREAD ==="
input bool     InpUsarFiltroSpread = true;        // Bloquear nuevas entradas si el spread está anormalmente alto
input int      InpMaxSpreadPoints = 50;           // Spread máximo permitido en puntos para abrir una operación

input group "=== CONFIGURACIÓN GENERAL ==="
input string   InpTradeDirection = "both";        // Dirección de trading (both/buy/sell)
input int      InpMinBarsLookback = 20;          // Barras mínimas para análisis
input int      InpSupportResistancePeriod = 12;  // Período para S/R (AGRESIVO: 12 | moderado sugerido: 16 | antes 20)
input int      InpATRMediaPeriod = 50;           // Período para ATR promedio
input int      InpMagicNumber = 7132620;         // Magic exclusivo de SignalFusion ORO
input int      InpMaxSLPoints = 2000;            // Máximo StopLoss en puntos (cap para SL)
input int      InpMandatoryTPPoints = 100;       // TP mínimo técnico en puntos para evitar TP demasiado chico
input double   InpMandatoryTPAtrMult = 0.5;      // TP mínimo técnico como múltiplo de ATR

input group "=== GUARDIA DE INSTANCIA ÚNICA ==="
input bool     InpUseSingleInstanceGuard = true;    // Evita operar el mismo símbolo/magic en más de un gráfico
input int      InpInstanceHeartbeatSeconds = 30;    // Cada cuántos segundos actualizar el latido de esta instancia
input int      InpInstanceStaleSeconds = 120;       // Si otro gráfico no actualiza latido en este tiempo, se considera instancia muerta
input int      InpProtectionTimerMs = 250;           // Respaldo de gestión sin depender exclusivamente de ticks


//--- Variables globales
double   g_atrBuffer[];
double   g_adxBuffer[];
double   g_rsiBuffer[];
double   g_resistanceBuffer[];
double   g_supportBuffer[];
double   g_atrMediaBuffer[];
double   g_volumeRelBuffer[];
double   g_emaFastBuffer[];
double   g_emaSlowBuffer[];

int      g_atrHandle;
int      g_adxHandle;
int      g_rsiHandle;
int      g_maHighHandle;
int      g_maLowHandle;
int      g_atrMediaHandle;
int      g_emaFastHandle;
int      g_emaSlowHandle;

double   g_currentEquity;
string   g_currentRegime = "";
int      g_trendDirection = 0; // 1=alcista, -1=bajista, 0=sin dirección clara
int      g_regimeConfidence = 0;
double   g_slMultUsed = 1.0;
double   g_trailingMultUsed = 1.0;
int      g_lossStreak = 0;
double   g_lotMultiplier = 1.0;
datetime g_lastCloseTime = 0;
datetime g_lastFailedOrderTime = 0;
double   g_peakEquity = 0.0;
datetime g_tradingPausedUntil = 0;
bool     g_lastCloseWasLoss = false;
datetime g_lastEntryBarTime = 0;         // EXP-1.2: vela en la que se abrio la ultima entrada
datetime g_lossStreakPausedUntil = 0;    // EXP-1.3: corte activo hasta esta hora
int      g_lossStreakPauseTriggeredAt = 0; // EXP-1.3: valor de g_lossStreak que disparo la ultima pausa
double   g_ddBrakeWorstDrawdownPct = 0.0; // EXP-2.1 fix v2: peor drawdown % que ya disparo una pausa desde el ultimo maximo
int      g_ddBrakeConsecutiveTriggers = 0; // EXP-2.1 fix v3: disparos seguidos del freno sin recuperar un nuevo maximo
bool     g_instanceLocked = false;
bool     g_newEntriesPaused = false;
string   g_instanceOwnerKey = "";
string   g_instanceBeatKey = "";
double   g_instanceId = 0.0;
datetime g_lastInstanceHeartbeat = 0;

//--- Estado de gestión por R
bool     g_breakEvenAplicado = false;

//--- UI / exportacion
string   BTN_EXPORT_CSV = "SIGNALFUSION_ORO_EXPORT_CSV";
string   BTN_TOGGLE_ENTRIES = "SIGNALFUSION_ORO_TOGGLE_ENTRIES";
string   EDIT_CSV_PATH = "SIGNALFUSION_ORO_CSV_PATH";
string   g_tradeLogFileName = "";
bool     g_tradeLogUsedCommon = true;



//+------------------------------------------------------------------+
//| Verificar si esta instancia posee el candado del símbolo/magic    |
//+------------------------------------------------------------------+
bool AcquireInstanceGuard()
{
    if(!InpUseSingleInstanceGuard)
    {
        g_instanceLocked = false;
        return true;
    }

    g_instanceId = (double)ChartID();
    g_instanceOwnerKey = StringFormat("SignalFusion.Owner.%s.%d", _Symbol, InpMagicNumber);
    g_instanceBeatKey  = StringFormat("SignalFusion.Beat.%s.%d",  _Symbol, InpMagicNumber);

    datetime now = TimeCurrent();

    if(GlobalVariableCheck(g_instanceOwnerKey))
    {
        double owner = GlobalVariableGet(g_instanceOwnerKey);
        datetime beat = 0;

        if(GlobalVariableCheck(g_instanceBeatKey))
            beat = (datetime)GlobalVariableGet(g_instanceBeatKey);

        bool sameOwner = (owner == g_instanceId);
        bool ownerAlive = (beat > 0 && (now - beat) <= InpInstanceStaleSeconds);

        if(!sameOwner && ownerAlive)
        {
            g_instanceLocked = true;
            Print("⛔ EA BLOQUEADO: ya existe otra instancia activa para ", _Symbol,
                  " con Magic ", InpMagicNumber,
                  ". Gráfico dueño: ", DoubleToString(owner, 0),
                  " | Último latido hace ", (int)(now - beat), " segundos.");
            Comment("⛔ SignalFusion bloqueado\n",
                    "Ya hay otra instancia activa para ", _Symbol, "\n",
                    "Magic: ", InpMagicNumber, "\n",
                    "No abrirá nuevas operaciones desde este gráfico.");
            return false;
        }

        if(!sameOwner && !ownerAlive)
        {
            Print("⚠️ Candado anterior vencido para ", _Symbol,
                  " Magic ", InpMagicNumber, ". Se toma control de esta instancia.");
            GlobalVariableDel(g_instanceOwnerKey);
            GlobalVariableDel(g_instanceBeatKey);
        }
    }

    if(!GlobalVariableCheck(g_instanceOwnerKey))
        GlobalVariableSet(g_instanceOwnerKey, 0.0);

    if(GlobalVariableSetOnCondition(g_instanceOwnerKey, g_instanceId, 0.0) ||
       GlobalVariableGet(g_instanceOwnerKey) == g_instanceId)
    {
        GlobalVariableSet(g_instanceBeatKey, (double)now);
        g_lastInstanceHeartbeat = now;
        g_instanceLocked = false;
        Print("✅ Guardia de instancia activo | Símbolo: ", _Symbol,
              " | Magic: ", InpMagicNumber,
              " | ChartID: ", DoubleToString(g_instanceId, 0));
        return true;
    }

    g_instanceLocked = true;
    Print("⛔ EA BLOQUEADO: no se pudo adquirir el candado de instancia para ", _Symbol,
          " Magic ", InpMagicNumber, ".");
    return false;
}

//+------------------------------------------------------------------+
//| Actualizar latido de instancia única                              |
//+------------------------------------------------------------------+
void UpdateInstanceHeartbeat()
{
    if(!InpUseSingleInstanceGuard || g_instanceLocked)
        return;

    datetime now = TimeCurrent();
    if((now - g_lastInstanceHeartbeat) < InpInstanceHeartbeatSeconds)
        return;

    if(GlobalVariableCheck(g_instanceOwnerKey) && GlobalVariableGet(g_instanceOwnerKey) == g_instanceId)
    {
        GlobalVariableSet(g_instanceBeatKey, (double)now);
        g_lastInstanceHeartbeat = now;
    }
    else
    {
        g_instanceLocked = true;
        Print("⛔ Esta instancia perdió el candado. Se bloquean nuevas entradas para ", _Symbol,
              " Magic ", InpMagicNumber, ".");
    }
}

//+------------------------------------------------------------------+
//| Liberar candado si pertenece a este gráfico                       |
//+------------------------------------------------------------------+
void ReleaseInstanceGuard()
{
    if(!InpUseSingleInstanceGuard)
        return;

    if(GlobalVariableCheck(g_instanceOwnerKey) && GlobalVariableGet(g_instanceOwnerKey) == g_instanceId)
    {
        GlobalVariableDel(g_instanceOwnerKey);
        GlobalVariableDel(g_instanceBeatKey);
        Print("🔓 Guardia de instancia liberado | Símbolo: ", _Symbol,
              " | Magic: ", InpMagicNumber);
    }
}

//+------------------------------------------------------------------+
//| Detectar posición propia por símbolo y Magic                      |
//+------------------------------------------------------------------+
bool HasOwnOpenPosition()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0)
            continue;

        if(!PositionSelectByTicket(ticket))
            continue;

        string symbol = PositionGetString(POSITION_SYMBOL);
        long magic = (long)PositionGetInteger(POSITION_MAGIC);

        if(symbol == _Symbol && magic == InpMagicNumber)
            return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//| Presets de entrada                                                |
//+------------------------------------------------------------------+
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

int EntryCooldownMinutes()
{
    switch(InpModoEntrada)
    {
        case ENTRADA_PROTEGIDA:
            return 2;
        case ENTRADA_BALANCEADA:
        case ENTRADA_FLEXIBLE:
            return 0;
        case ENTRADA_PERSONALIZADA:
            return InpCooldownMinutes;
    }
    return InpCooldownMinutes;
}

int EntryFailedOrderCooldownSeconds()
{
    switch(InpModoEntrada)
    {
        case ENTRADA_PROTEGIDA:
            return 15;
        case ENTRADA_BALANCEADA:
        case ENTRADA_FLEXIBLE:
            return 5;
        case ENTRADA_PERSONALIZADA:
            return InpFailedOrderCooldownSeconds;
    }
    return InpFailedOrderCooldownSeconds;
}

//+------------------------------------------------------------------+
//| Riesgo adaptativo y freno por drawdown                            |
//+------------------------------------------------------------------+
#include "alto-riesgo-v120/Diagnostics.mqh"
#include "alto-riesgo-v120/RiskBudget.mqh"

bool IsDrawdownBrakeActive()
{
    if(!InpUsarFrenoDrawdown)
        return false;

    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    if(g_peakEquity <= 0.0)
        g_peakEquity = equity;

    if(equity > g_peakEquity)
    {
        g_peakEquity = equity;
        g_ddBrakeWorstDrawdownPct = 0.0;   // recuperacion real a un nuevo maximo: reiniciar el peor DD visto
        g_ddBrakeConsecutiveTriggers = 0;  // ...y tambien el contador de escalado de pausas
        return false;
    }

    if(g_tradingPausedUntil > TimeCurrent())
        return true;

    if(g_peakEquity <= 0.0 || InpMaxDrawdownPct <= 0.0)
        return false;

    double drawdownPct = 100.0 * (g_peakEquity - equity) / g_peakEquity;
    // EXP-2.1 fix (v1): exigir que pase el tiempo no alcanzaba -> sin operaciones abiertas el
    // equity no puede recuperarse solo, y se re-armaba en el mismo nivel de drawdown -> pausa
    // permanente tras el primer drawdown fuerte.
    // EXP-2.1 fix (v2): exigir un NUEVO PICO para rearmar tampoco alcanza -> si la cuenta nunca
    // vuelve a superar el pico original, el freno se "gasta" una sola vez y queda inerte el resto
    // del periodo aunque el drawdown se siga profundizando.
    // EXP-2.1 fix (v3, tras el hallazgo de EXP-7.1b en abril): rearmar con la MISMA pausa fija cada
    // vez que el drawdown se profundiza tampoco alcanza -> en una racha mala de varios dias, el EA
    // simplemente reintenta cada `InpDrawdownPauseMinutes` y sigue perdiendo en cuotas (9 pausas en
    // 2 dias, drawdown terminó peor que con una sola pausa). Ahora cada disparo consecutivo (sin que
    // medie una recuperacion a nuevo maximo) escala la pausa linealmente, hasta un tope, para que el
    // EA se retire mas tiempo cuanto mas seguido esta fallando, en vez de reintentar siempre igual.
    if(drawdownPct >= InpMaxDrawdownPct && drawdownPct > g_ddBrakeWorstDrawdownPct)
    {
        g_ddBrakeWorstDrawdownPct = drawdownPct;
        g_ddBrakeConsecutiveTriggers++;
        int escalatedMinutes = (int)MathMin((double)InpDrawdownPauseMinutes * g_ddBrakeConsecutiveTriggers,
                                             (double)InpDrawdownPauseMaxMinutes);
        g_tradingPausedUntil = TimeCurrent() + escalatedMinutes * 60;
        Print("⛔ Freno por drawdown activado (disparo #", g_ddBrakeConsecutiveTriggers,
              " desde el ultimo maximo) | Equity: $", DoubleToString(equity, 2),
              " | Pico: $", DoubleToString(g_peakEquity, 2),
              " | DD: ", DoubleToString(drawdownPct, 2), "%",
              " | Pausa minutos: ", escalatedMinutes);
        return true;
    }

    return false;
}

// EXP-1.3: corte real (no solo reduccion de lote) tras alcanzar InpMaxConsecutiveLosses.
// Se dispara una vez por racha (mientras g_lossStreak no supere el valor que la disparo,
// no se vuelve a extender la pausa) y se rearma solo cuando una operacion ganadora
// resetea g_lossStreak a 0.
bool IsLossStreakBrakeActive()
{
    if(!InpPausarTrasRachaPerdidas)
        return false;

    if(g_lossStreakPausedUntil > TimeCurrent())
        return true;

    if(g_lossStreak >= InpMaxConsecutiveLosses && g_lossStreak != g_lossStreakPauseTriggeredAt)
    {
        g_lossStreakPauseTriggeredAt = g_lossStreak;
        g_lossStreakPausedUntil = TimeCurrent() + InpLossStreakPauseMinutes * 60;
        Print("⛔ Corte por racha de pérdidas activado | Pérdidas seguidas: ", g_lossStreak,
              " | Pausa minutos: ", InpLossStreakPauseMinutes);
        return true;
    }

    return false;
}

string EntryPauseStateKey()
{
    return StringFormat("SignalFusionORO.EntryPause.%s.%d", _Symbol, InpMagicNumber);
}

void UpdateEntryControlButton()
{
    if(ObjectFind(0, BTN_TOGGLE_ENTRIES) < 0)
        return;

    ObjectSetString(0, BTN_TOGGLE_ENTRIES, OBJPROP_TEXT,
                    g_newEntriesPaused ? "⏸" : "▶");
    ObjectSetString(0, BTN_TOGGLE_ENTRIES, OBJPROP_TOOLTIP,
                    g_newEntriesPaused
                    ? "Entradas PAUSADAS (clic para reanudar). La gestion de posiciones abiertas sigue activa."
                    : "Entradas ACTIVAS (clic para pausar nuevas entradas).");
    ObjectSetInteger(0, BTN_TOGGLE_ENTRIES, OBJPROP_BGCOLOR,
                     g_newEntriesPaused ? clrFireBrick : clrSeaGreen);
    ObjectSetInteger(0, BTN_TOGGLE_ENTRIES, OBJPROP_BORDER_COLOR,
                     g_newEntriesPaused ? clrOrangeRed : clrLimeGreen);
    ObjectSetInteger(0, BTN_TOGGLE_ENTRIES, OBJPROP_STATE, false);
    ChartRedraw(0);
}

void SetNewEntriesPaused(bool paused, bool persist)
{
    g_newEntriesPaused = paused;
    if(persist)
        GlobalVariableSet(EntryPauseStateKey(), paused ? 1.0 : 0.0);
    UpdateEntryControlButton();
    Print(paused
          ? "Nuevas entradas PAUSADAS. La gestion de posiciones sigue activa."
          : "Nuevas entradas REANUDADAS.");
}

void CreateEntryControlButton()
{
    ObjectDelete(0, BTN_TOGGLE_ENTRIES);
    if(!ObjectCreate(0, BTN_TOGGLE_ENTRIES, OBJ_BUTTON, 0, 0, 0))
    {
        Print("No se pudo crear boton de control de entradas. Error: ", GetLastError());
        return;
    }

    ObjectSetInteger(0, BTN_TOGGLE_ENTRIES, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, BTN_TOGGLE_ENTRIES, OBJPROP_XDISTANCE, InpEntryButtonX);
    ObjectSetInteger(0, BTN_TOGGLE_ENTRIES, OBJPROP_YDISTANCE, InpEntryButtonY);
    ObjectSetInteger(0, BTN_TOGGLE_ENTRIES, OBJPROP_XSIZE, 26);
    ObjectSetInteger(0, BTN_TOGGLE_ENTRIES, OBJPROP_YSIZE, 26);
    ObjectSetInteger(0, BTN_TOGGLE_ENTRIES, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, BTN_TOGGLE_ENTRIES, OBJPROP_BACK, false);
    ObjectSetInteger(0, BTN_TOGGLE_ENTRIES, OBJPROP_HIDDEN, false);
    ObjectSetInteger(0, BTN_TOGGLE_ENTRIES, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, BTN_TOGGLE_ENTRIES, OBJPROP_FONTSIZE, 12);
    ObjectSetInteger(0, BTN_TOGGLE_ENTRIES, OBJPROP_ZORDER, 1001);
    UpdateEntryControlButton();
}

void EnsureEntryControlButton()
{
    if(ObjectFind(0, BTN_TOGGLE_ENTRIES) < 0)
        CreateEntryControlButton();
}

//+------------------------------------------------------------------+
//| Boton de exportacion CSV                                          |
//+------------------------------------------------------------------+
void CreateExportCSVButton()
{
    if(!InpMostrarBotonExportCSV)
        return;

    ObjectDelete(0, BTN_EXPORT_CSV);
    if(!ObjectCreate(0, BTN_EXPORT_CSV, OBJ_BUTTON, 0, 0, 0))
    {
        Print("No se pudo crear boton Export CSV. Error: ", GetLastError());
        return;
    }

    ObjectSetInteger(0, BTN_EXPORT_CSV, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, BTN_EXPORT_CSV, OBJPROP_XDISTANCE, InpExportButtonX);
    ObjectSetInteger(0, BTN_EXPORT_CSV, OBJPROP_YDISTANCE, InpExportButtonY);
    ObjectSetInteger(0, BTN_EXPORT_CSV, OBJPROP_XSIZE, 26);
    ObjectSetInteger(0, BTN_EXPORT_CSV, OBJPROP_YSIZE, 26);
    ObjectSetInteger(0, BTN_EXPORT_CSV, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, BTN_EXPORT_CSV, OBJPROP_BGCOLOR, clrDarkSlateGray);
    ObjectSetInteger(0, BTN_EXPORT_CSV, OBJPROP_BORDER_COLOR, clrDodgerBlue);
    ObjectSetInteger(0, BTN_EXPORT_CSV, OBJPROP_BACK, false);
    ObjectSetInteger(0, BTN_EXPORT_CSV, OBJPROP_HIDDEN, false);
    ObjectSetInteger(0, BTN_EXPORT_CSV, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, BTN_EXPORT_CSV, OBJPROP_FONTSIZE, 12);
    ObjectSetInteger(0, BTN_EXPORT_CSV, OBJPROP_ZORDER, 1000);
    ObjectSetString(0, BTN_EXPORT_CSV, OBJPROP_TEXT, "📎");
    ObjectSetString(0, BTN_EXPORT_CSV, OBJPROP_TOOLTIP,
                    "Exporta el informe CSV de operaciones. La ruta completa queda en el cuadro de al lado (clic dentro + Ctrl+A + Ctrl+C para copiarla).");

    CreateCSVPathField();
    ChartRedraw(0);
}

void CreateCSVPathField()
{
    if(!InpMostrarBotonExportCSV)
        return;

    if(ObjectFind(0, EDIT_CSV_PATH) >= 0)
        return;

    if(!ObjectCreate(0, EDIT_CSV_PATH, OBJ_EDIT, 0, 0, 0))
    {
        Print("No se pudo crear el campo de ruta del CSV. Error: ", GetLastError());
        return;
    }

    ObjectSetInteger(0, EDIT_CSV_PATH, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, EDIT_CSV_PATH, OBJPROP_XDISTANCE, InpExportButtonX + 32);
    ObjectSetInteger(0, EDIT_CSV_PATH, OBJPROP_YDISTANCE, InpExportButtonY);
    ObjectSetInteger(0, EDIT_CSV_PATH, OBJPROP_XSIZE, 420);
    ObjectSetInteger(0, EDIT_CSV_PATH, OBJPROP_YSIZE, 26);
    ObjectSetInteger(0, EDIT_CSV_PATH, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, EDIT_CSV_PATH, OBJPROP_BGCOLOR, clrBlack);
    ObjectSetInteger(0, EDIT_CSV_PATH, OBJPROP_BORDER_COLOR, clrDodgerBlue);
    ObjectSetInteger(0, EDIT_CSV_PATH, OBJPROP_BACK, false);
    ObjectSetInteger(0, EDIT_CSV_PATH, OBJPROP_HIDDEN, false);
    ObjectSetInteger(0, EDIT_CSV_PATH, OBJPROP_SELECTABLE, true);
    ObjectSetInteger(0, EDIT_CSV_PATH, OBJPROP_READONLY, false);
    ObjectSetInteger(0, EDIT_CSV_PATH, OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, EDIT_CSV_PATH, OBJPROP_ZORDER, 999);
    ObjectSetString(0, EDIT_CSV_PATH, OBJPROP_FONT, "Consolas");
    ObjectSetString(0, EDIT_CSV_PATH, OBJPROP_TEXT, "Sin exportar aun. Clic en 📎 para generar el informe.");
    ObjectSetString(0, EDIT_CSV_PATH, OBJPROP_TOOLTIP,
                    "Ruta completa del ultimo informe CSV exportado. Clic dentro, Ctrl+A y Ctrl+C para copiarla.");
    ChartRedraw(0);
}

void SetCSVPathFieldText(string path)
{
    if(!InpMostrarBotonExportCSV)
        return;

    if(ObjectFind(0, EDIT_CSV_PATH) < 0)
        CreateCSVPathField();

    ObjectSetString(0, EDIT_CSV_PATH, OBJPROP_TEXT, path);
    ChartRedraw(0);
}

void EnsureExportCSVButton()
{
    if(!InpMostrarBotonExportCSV)
        return;

    if(ObjectFind(0, BTN_EXPORT_CSV) < 0)
        CreateExportCSVButton();

    if(ObjectFind(0, EDIT_CSV_PATH) < 0)
        CreateCSVPathField();
}

string CSVFileName()
{
    string prefix = InpExportCSVPrefix;
    if(prefix == "")
        prefix = "SignalFusion_Riesgo114_Operaciones";

    return prefix + "_" + _Symbol + "_" + (string)InpMagicNumber + "_" +
           TimeToString(TimeCurrent(), TIME_DATE) + ".csv";
}

string SafeFileToken(string value)
{
    StringReplace(value, "\\", "-");
    StringReplace(value, "/", "-");
    StringReplace(value, ":", "-");
    StringReplace(value, ".", "-");
    StringReplace(value, " ", "_");
    return value;
}

string AutomaticTradeLogFolder()
{
    return GetCSVFolderPathFor(g_tradeLogUsedCommon);
}

int AutomaticTradeLogFlags(bool commonFiles)
{
    int flags = FILE_CSV | FILE_READ | FILE_WRITE | FILE_ANSI |
                FILE_SHARE_READ | FILE_SHARE_WRITE;
    if(commonFiles)
        flags |= FILE_COMMON;
    return flags;
}

void WriteTradeLogHeader(int file)
{
    FileWrite(file,
              "modo", "evento", "deal_ticket", "order_ticket", "position_id",
              "tiempo", "simbolo", "magic", "tipo", "volumen", "precio",
              "sl", "tp", "beneficio", "comision", "swap", "fee", "resultado_neto",
              "motivo", "comentario", "balance", "equity",
              "atr", "atr_media", "adx", "rsi", "ema_fast", "ema_slow",
              "soporte", "resistencia", "regimen");
}

string DealEntryText(const long entry)
{
    if(entry == DEAL_ENTRY_IN)
        return "ENTRADA";
    if(entry == DEAL_ENTRY_OUT)
        return "SALIDA";
    if(entry == DEAL_ENTRY_INOUT)
        return "REVERSA";
    if(entry == DEAL_ENTRY_OUT_BY)
        return "CIERRE_POR_OPUESTA";
    return "OTRO";
}

bool InitializeAutomaticTradeLog()
{
    if(!InpLogOperacionesAutomatico)
        return true;

    if(g_tradeLogFileName == "")
    {
        string prefix = InpLogOperacionesPrefix;
        if(prefix == "")
            prefix = "SignalFusion_Riesgo114_Log";

        datetime now = TimeCurrent();
        if(now <= 0)
            now = TimeLocal();
        string mode = MQLInfoInteger(MQL_TESTER) ? "TESTER" : "REAL";
        string stamp = SafeFileToken(TimeToString(now, TIME_DATE | TIME_SECONDS));
        g_tradeLogFileName = SafeFileToken(prefix) + "_" + SafeFileToken(_Symbol) + "_" +
                             (string)InpMagicNumber + "_" + mode + "_" + stamp + ".csv";
    }

    g_tradeLogUsedCommon = InpExportCSVCommonFiles;
    EnsureExportSubFolder(g_tradeLogUsedCommon);
    ResetLastError();
    int file = FileOpen(ExportFileArgument(g_tradeLogFileName), AutomaticTradeLogFlags(g_tradeLogUsedCommon), ';', CP_UTF8);
    if(file == INVALID_HANDLE && g_tradeLogUsedCommon)
    {
        int commonError = GetLastError();
        Print("⚠️ No se pudo crear la bitacora en Common\\Files (Error: ", commonError,
              "). Reintentando en la carpeta local MQL5\\Files...");
        g_tradeLogUsedCommon = false;
        EnsureExportSubFolder(g_tradeLogUsedCommon);
        ResetLastError();
        file = FileOpen(ExportFileArgument(g_tradeLogFileName), AutomaticTradeLogFlags(g_tradeLogUsedCommon), ';', CP_UTF8);
    }
    if(file == INVALID_HANDLE)
    {
        Print("❌ No se pudo crear la bitacora automatica de operaciones. Error: ", GetLastError());
        SetCSVPathFieldText("ERROR al crear la bitacora. Ver pestaña Expertos/Journal. Codigo: " + IntegerToString(GetLastError()));
        return false;
    }

    if(FileSize(file) == 0)
    {
        WriteTradeLogHeader(file);
        FileFlush(file);
    }

    FileClose(file);
    string logPath = AutomaticTradeLogFolder() + g_tradeLogFileName;
    Print("Bitacora automatica activa: ", logPath);
    SetCSVPathFieldText(logPath);
    return true;
}

bool AppendDealToAutomaticLog(const ulong dealTicket,
                              const MqlTradeTransaction &trans)
{
    if(!InpLogOperacionesAutomatico)
        return true;

    if(g_tradeLogFileName == "" && !InitializeAutomaticTradeLog())
        return false;

    if(!HistoryDealSelect(dealTicket))
        return false;

    ResetLastError();
    int file = FileOpen(ExportFileArgument(g_tradeLogFileName), AutomaticTradeLogFlags(g_tradeLogUsedCommon), ';', CP_UTF8);
    if(file == INVALID_HANDLE)
    {
        Print("No se pudo abrir la bitacora para registrar deal ", dealTicket,
              ". Error: ", GetLastError());
        return false;
    }

    if(FileSize(file) == 0)
        WriteTradeLogHeader(file);

    FileSeek(file, 0, SEEK_END);
    long entry = (long)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
    double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
    double commission = HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
    double swap = HistoryDealGetDouble(dealTicket, DEAL_SWAP);
    double fee = HistoryDealGetDouble(dealTicket, DEAL_FEE);
    double net = profit + commission + swap + fee;
    datetime dealTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
    ulong positionId = (ulong)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
    ulong orderTicket = (ulong)HistoryDealGetInteger(dealTicket, DEAL_ORDER);
    string mode = MQLInfoInteger(MQL_TESTER) ? "TESTER" : "REAL";

    double logAtr = IndicatorAtTime(g_atrHandle, dealTime);
    double logAtrAvg = ATRAverageAtTime(dealTime);
    double logAdx = IndicatorAtTime(g_adxHandle, dealTime);
    double logRsi = IndicatorAtTime(g_rsiHandle, dealTime);
    double logEmaFast = IndicatorAtTime(g_emaFastHandle, dealTime);
    double logEmaSlow = IndicatorAtTime(g_emaSlowHandle, dealTime);
    double logResistance = IndicatorAtTime(g_maHighHandle, dealTime);
    double logSupport = IndicatorAtTime(g_maLowHandle, dealTime);
    string logRegime = RegimeAtIndicators(logAdx, logAtr, logAtrAvg);

    FileWrite(file,
              mode,
              DealEntryText(entry),
              (string)dealTicket,
              (string)orderTicket,
              (string)positionId,
              TimeToString(dealTime, TIME_DATE | TIME_SECONDS),
              HistoryDealGetString(dealTicket, DEAL_SYMBOL),
              (string)HistoryDealGetInteger(dealTicket, DEAL_MAGIC),
              DealTypeText((long)HistoryDealGetInteger(dealTicket, DEAL_TYPE)),
              DoubleToString(HistoryDealGetDouble(dealTicket, DEAL_VOLUME), 2),
              DoubleToString(HistoryDealGetDouble(dealTicket, DEAL_PRICE), _Digits),
              trans.price_sl > 0.0 ? DoubleToString(trans.price_sl, _Digits) : "",
              trans.price_tp > 0.0 ? DoubleToString(trans.price_tp, _Digits) : "",
              DoubleToString(profit, 2),
              DoubleToString(commission, 2),
              DoubleToString(swap, 2),
              DoubleToString(fee, 2),
              DoubleToString(net, 2),
              DealExitReasonText((long)HistoryDealGetInteger(dealTicket, DEAL_REASON)),
              HistoryDealGetString(dealTicket, DEAL_COMMENT),
              DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2),
              DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2),
              DoubleToString(logAtr, _Digits),
              DoubleToString(logAtrAvg, _Digits),
              DoubleToString(logAdx, 2),
              DoubleToString(logRsi, 2),
              DoubleToString(logEmaFast, _Digits),
              DoubleToString(logEmaSlow, _Digits),
              DoubleToString(logSupport, _Digits),
              DoubleToString(logResistance, _Digits),
              logRegime);
    FileFlush(file);
    FileClose(file);

    Print("Operacion registrada en bitacora | Evento: ", DealEntryText(entry),
          " | Deal: ", dealTicket, " | Posicion: ", positionId,
          " | Neto: ", DoubleToString(net, 2));
    return true;
}

string CSVText(string value)
{
    StringReplace(value, "\"", "\"\"");
    return "\"" + value + "\"";
}

string DealTypeText(long type)
{
    if(type == DEAL_TYPE_BUY)
        return "BUY";
    if(type == DEAL_TYPE_SELL)
        return "SELL";
    return "OTHER";
}

string DealExitReasonText(long reason)
{
    if(reason == DEAL_REASON_SL)
        return "SL";
    if(reason == DEAL_REASON_TP)
        return "TP";
    if(reason == DEAL_REASON_EXPERT)
        return "EXPERT";
    if(reason == DEAL_REASON_CLIENT)
        return "CLIENT";
    if(reason == DEAL_REASON_MOBILE)
        return "MOBILE";
    if(reason == DEAL_REASON_WEB)
        return "WEB";
    return "OTHER";
}

double IndicatorAtTime(int handle, datetime moment, int bufferIndex = 0)
{
    if(handle == INVALID_HANDLE)
        return 0.0;

    int shift = iBarShift(_Symbol, PERIOD_CURRENT, moment, false);
    if(shift < 0)
        shift = 0;

    double values[];
    ArraySetAsSeries(values, true);
    if(CopyBuffer(handle, bufferIndex, shift, 1, values) != 1)
        return 0.0;

    return values[0];
}

double ATRAverageAtTime(datetime moment)
{
    int shift = iBarShift(_Symbol, PERIOD_CURRENT, moment, false);
    if(shift < 0)
        shift = 0;

    int bars = MathMax(InpATRMediaPeriod, 2);
    double values[];
    ArraySetAsSeries(values, true);
    int copied = CopyBuffer(g_atrHandle, 0, shift, bars, values);
    if(copied <= 0)
        return 0.0;

    double sum = 0.0;
    for(int i = 0; i < copied; i++)
        sum += values[i];

    return sum / copied;
}

string RegimeAtIndicators(double adx, double atr, double atrAvg)
{
    if(adx >= EntryTrendADXMin())
        return "TENDENCIA";
    if(atrAvg > 0.0 && atr < atrAvg)
        return "LATERAL";
    return "MIXTO";
}

bool FindExitDealForPosition(ulong positionId, datetime fromTime,
                             datetime &exitTime, double &exitPrice,
                             double &profit, string &exitReason)
{
    bool found = false;
    exitTime = 0;
    exitPrice = 0.0;
    profit = 0.0;
    exitReason = "";

    int total = HistoryDealsTotal();
    for(int i = 0; i < total; i++)
    {
        ulong deal = HistoryDealGetTicket(i);
        if(deal == 0 || !HistoryDealSelect(deal))
            continue;

        if((ulong)HistoryDealGetInteger(deal, DEAL_POSITION_ID) != positionId)
            continue;

        long entry = (long)HistoryDealGetInteger(deal, DEAL_ENTRY);
        if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT && entry != DEAL_ENTRY_OUT_BY)
            continue;

        datetime dealTime = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);
        if(dealTime < fromTime)
            continue;

        double net = HistoryDealGetDouble(deal, DEAL_PROFIT)
                   + HistoryDealGetDouble(deal, DEAL_SWAP)
                   + HistoryDealGetDouble(deal, DEAL_COMMISSION);

        profit += net;
        if(!found || dealTime >= exitTime)
        {
            exitTime = dealTime;
            exitPrice = HistoryDealGetDouble(deal, DEAL_PRICE);
            exitReason = DealExitReasonText((long)HistoryDealGetInteger(deal, DEAL_REASON));
            found = true;
        }
    }

    return found;
}

string NormalizedExportSubFolder()
{
    string sub = InpExportSubFolder;
    StringTrimLeft(sub);
    StringTrimRight(sub);
    if(sub == "")
        return "";

    StringReplace(sub, "/", "\\");
    while(StringLen(sub) > 0 && StringGetCharacter(sub, 0) == '\\')
        sub = StringSubstr(sub, 1);
    while(StringLen(sub) > 0 && StringGetCharacter(sub, StringLen(sub) - 1) == '\\')
        sub = StringSubstr(sub, 0, StringLen(sub) - 1);

    return sub;
}

// Nombre de archivo (con subcarpeta si esta configurada) para pasarle a FileOpen.
string ExportFileArgument(string fileName)
{
    string sub = NormalizedExportSubFolder();
    if(sub == "")
        return fileName;

    return sub + "\\" + fileName;
}

// Crea explicitamente la subcarpeta antes de escribir: no confiar en que FileOpen
// la cree solo (en Common\Files no siempre ocurre de forma consistente).
void EnsureExportSubFolder(bool commonFiles)
{
    string sub = NormalizedExportSubFolder();
    if(sub == "")
        return;

    ResetLastError();
    bool created = FolderCreate(sub, commonFiles ? FILE_COMMON : 0);
    int err = GetLastError();
    if(!created && err != 0 && err != 5019) // 5019 = la carpeta ya existe
        Print("⚠️ No se pudo crear la subcarpeta '", sub, "'. Error: ", err);
}

string GetCSVFolderPathFor(bool commonFiles)
{
    string baseFolder = commonFiles
                         ? TerminalInfoString(TERMINAL_COMMONDATA_PATH) + "\\Files\\"
                         : TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Files\\";

    string sub = NormalizedExportSubFolder();
    if(sub != "")
        baseFolder += sub + "\\";

    return baseFolder;
}

string GetCSVFolderPath()
{
    return GetCSVFolderPathFor(InpExportCSVCommonFiles);
}

string BoolText(bool value)
{
    return value ? "true" : "false";
}

string TimeframeText()
{
    return EnumToString((ENUM_TIMEFRAMES)Period());
}

void WriteConfigRow(int file, string name, string value)
{
    FileWrite(file, "CONFIG", name, value);
}

void WriteBacktestConfiguration(int file)
{
    FileWrite(file, "SECCION", "CONFIGURACION_DEL_ASESOR");
    FileWrite(file, "tipo", "parametro", "valor");

    WriteConfigRow(file, "ea_version", "SignalFusion ORO Alto Riesgo 1.20");
    WriteConfigRow(file, "symbol", _Symbol);
    WriteConfigRow(file, "timeframe", TimeframeText());
    WriteConfigRow(file, "tester", BoolText((bool)MQLInfoInteger(MQL_TESTER)));
    WriteConfigRow(file, "balance", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
    WriteConfigRow(file, "equity", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
    WriteConfigRow(file, "leverage", IntegerToString((int)AccountInfoInteger(ACCOUNT_LEVERAGE)));
    WriteConfigRow(file, "magic", IntegerToString(InpMagicNumber));
    WriteConfigRow(file, "iniciar_entradas_pausadas", BoolText(InpIniciarEntradasPausadas));

    WriteConfigRow(file, "modo_entrada", EntryModeName());
    WriteConfigRow(file, "modo_lote", InpModoLote == LOT_RIESGO_PORCENTAJE ? "LOT_RIESGO_PORCENTAJE" : "LOT_FIJO");
    WriteConfigRow(file, "risk_per_trade_pct", DoubleToString(InpRiskPerTradePct, 2));
    WriteConfigRow(file, "risk_budget_mode", EnumToString(InpRiskBudgetMode));
    WriteConfigRow(file, "trend_adx_gate_enabled", BoolText(InpTrendADXGateEnabled));
    WriteConfigRow(file, "trend_adx_gate_minimum", DoubleToString(InpTrendADXGateMinimum, 2));
    WriteConfigRow(file, "risk_money", DoubleToString(InpRiskMoney, 2));
    WriteConfigRow(file, "risk_currency", AccountInfoString(ACCOUNT_CURRENCY));
    WriteConfigRow(file, "risk_costs_per_lot", DoubleToString(InpRiskCostsPerLot, 4));
    WriteConfigRow(file, "risk_slippage_points", IntegerToString(InpRiskSlippagePoints));
    WriteConfigRow(file, "permitir_lote_min_si_riesgo_insuficiente", BoolText(InpPermitirLoteMinSiRiesgoInsuficiente));
    WriteConfigRow(file, "lote_fijo", DoubleToString(InpLoteFijo, 2));
    WriteConfigRow(file, "lote_min_estrategia", DoubleToString(InpLotMin, 2));
    WriteConfigRow(file, "margin_safety_pct", DoubleToString(InpMarginSafetyPct, 2));
    WriteConfigRow(file, "min_balance_to_trade", DoubleToString(InpMinBalanceToTrade, 2));

    WriteConfigRow(file, "usar_freno_drawdown", BoolText(InpUsarFrenoDrawdown));
    WriteConfigRow(file, "max_drawdown_pct", DoubleToString(InpMaxDrawdownPct, 2));
    WriteConfigRow(file, "drawdown_pause_minutes", IntegerToString(InpDrawdownPauseMinutes));
    WriteConfigRow(file, "drawdown_pause_max_minutes_exp2_1_v3", IntegerToString(InpDrawdownPauseMaxMinutes));

    WriteConfigRow(file, "rr_strategy", GetRRStrategyName());
    WriteConfigRow(file, "rr_objetivo", DoubleToString(GetTargetRR(), 2));
    WriteConfigRow(file, "rr_personalizado", DoubleToString(InpRRPersonalizado, 2));
    WriteConfigRow(file, "min_rr_permitido", DoubleToString(InpMinRRPermitido, 2));
    WriteConfigRow(file, "cancelar_si_rr_invalido", BoolText(InpCancelarSiRRInvalido));

    WriteConfigRow(file, "atr_period", IntegerToString(InpATRPeriod));
    WriteConfigRow(file, "atr_multiplier", DoubleToString(InpATRMultiplier, 2));
    WriteConfigRow(file, "trend_sl_mult", DoubleToString(InpTrendSLMult, 2));
    WriteConfigRow(file, "trend_trailing_mult", DoubleToString(InpTrendTrailingMult, 2));
    WriteConfigRow(file, "lateral_sl_mult", DoubleToString(InpLateralSLMult, 2));
    WriteConfigRow(file, "lateral_trailing_mult", DoubleToString(InpLateralTrailingMult, 2));

    WriteConfigRow(file, "usar_proteccion_incremental", BoolText(InpUsarProteccionIncremental));
    WriteConfigRow(file, "proteccion_etapa1_trigger_r", DoubleToString(InpProteccionEtapa1TriggerR, 2));
    WriteConfigRow(file, "proteccion_etapa1_stop_r", DoubleToString(InpProteccionEtapa1StopR, 2));
    WriteConfigRow(file, "proteccion_etapa2_trigger_r", DoubleToString(InpProteccionEtapa2TriggerR, 2));
    WriteConfigRow(file, "proteccion_etapa2_stop_r", DoubleToString(InpProteccionEtapa2StopR, 2));
    WriteConfigRow(file, "proteccion_etapa3_trigger_r", DoubleToString(InpProteccionEtapa3TriggerR, 2));
    WriteConfigRow(file, "proteccion_etapa3_stop_r", DoubleToString(InpProteccionEtapa3StopR, 2));
    WriteConfigRow(file, "break_even_trigger_r", DoubleToString(InpBreakEvenTriggerR, 2));
    WriteConfigRow(file, "break_even_trigger_atr", DoubleToString(InpBreakEvenTriggerATR, 2));
    WriteConfigRow(file, "break_even_offset_points", IntegerToString(InpBreakEvenOffsetPoints));
    WriteConfigRow(file, "usar_trailing_atr_en_broker", BoolText(InpUsarTrailingATREnBroker));
    WriteConfigRow(file, "trailing_atr_trigger_r", DoubleToString(InpTrailingATRTriggerR, 2));
    WriteConfigRow(file, "trailing_atr_step_r", DoubleToString(InpTrailingATRStepR, 2));
    WriteConfigRow(file, "min_trailing_step_points", IntegerToString(InpMinTrailingStepPoints));

    WriteConfigRow(file, "usar_smart_exit", BoolText(InpUsarSmartExit));
    WriteConfigRow(file, "smart_exit_action", InpSmartExitAction == SMART_EXIT_CLOSE_FULL ? "CLOSE_FULL" : "TIGHTEN_SL");
    WriteConfigRow(file, "smart_exit_min_profit_r", DoubleToString(InpSmartExitMinProfitR, 2));
    WriteConfigRow(file, "smart_exit_score_cerrar", IntegerToString(InpSmartExitScoreCerrar));
    WriteConfigRow(file, "smart_exit_lookback_sr", IntegerToString(InpSmartExitLookbackSR));
    WriteConfigRow(file, "smart_exit_sr_proximity_atr", DoubleToString(InpSmartExitSRProximityATR, 2));
    WriteConfigRow(file, "smart_exit_adx_drop", DoubleToString(InpSmartExitAdxDrop, 2));
    WriteConfigRow(file, "smart_exit_atr_contract_pct", DoubleToString(InpSmartExitAtrContractPct, 2));
    WriteConfigRow(file, "smart_exit_tighten_points", IntegerToString(InpSmartExitTightenPoints));

    WriteConfigRow(file, "require_adx", BoolText(InpRequireADX));
    WriteConfigRow(file, "min_adx", DoubleToString(InpMinADX, 2));
    WriteConfigRow(file, "adx_period", IntegerToString(InpADXPeriod));
    WriteConfigRow(file, "rsi_period", IntegerToString(InpRSIPeriod));
    WriteConfigRow(file, "rsi_oversold", DoubleToString(InpRSIOversold, 2));
    WriteConfigRow(file, "rsi_overbought", DoubleToString(InpRSIOverbought, 2));
    WriteConfigRow(file, "ema_fast_period", IntegerToString(InpEmaFastPeriod));
    WriteConfigRow(file, "ema_slow_period", IntegerToString(InpEmaSlowPeriod));
    WriteConfigRow(file, "usar_filtro_direccion_ema", BoolText(InpUsarFiltroDireccionEMA));
    WriteConfigRow(file, "trend_adx_min", DoubleToString(InpTrendADXMin, 2));
    WriteConfigRow(file, "lateral_adx_max", DoubleToString(InpLateralADXMax, 2));
    WriteConfigRow(file, "bloquear_lateral_con_adx_alto", BoolText(InpBloquearLateralConADXAlto));
    WriteConfigRow(file, "sr_proximity_atr_mult", DoubleToString(InpSRProximityAtrMult, 2));
    WriteConfigRow(file, "operar_regimen_mixto_exp4_0", BoolText(InpOperarRegimenMixto));

    WriteConfigRow(file, "trade_direction", InpTradeDirection);
    WriteConfigRow(file, "cooldown_minutes", IntegerToString(InpCooldownMinutes));
    WriteConfigRow(file, "cooldown_only_after_loss", BoolText(InpCooldownOnlyAfterLoss));
    WriteConfigRow(file, "failed_order_cooldown_seconds", IntegerToString(InpFailedOrderCooldownSeconds));
    WriteConfigRow(file, "cooldown_min_seconds_exp1_1", IntegerToString(InpCooldownMinSeconds));
    WriteConfigRow(file, "una_entrada_por_vela_exp1_2", BoolText(InpUnaEntradaPorVela));
    WriteConfigRow(file, "pausar_tras_racha_perdidas_exp1_3", BoolText(InpPausarTrasRachaPerdidas));
    WriteConfigRow(file, "loss_streak_pause_minutes_exp1_3", IntegerToString(InpLossStreakPauseMinutes));
    WriteConfigRow(file, "max_consecutive_losses", IntegerToString(InpMaxConsecutiveLosses));
    WriteConfigRow(file, "export_lookback_days", IntegerToString(InpExportLookbackDays));
    FileWrite(file, "");
}

void OpenCSVFolder(bool commonFiles)
{
    // En una optimizacion (miles de pasadas) no se abre el explorador de archivos;
    // en un backtest o test visual individual si queremos abrirlo para ubicar el informe.
    if(MQLInfoInteger(MQL_OPTIMIZATION))
        return;

    if(!InpAbrirCarpetaAlExportar)
        return;

    string folderPath = GetCSVFolderPathFor(commonFiles);
    Print("Carpeta de resultados del backtest: ",folderPath);
    if(!MQLInfoInteger(MQL_DLLS_ALLOWED))
    {
        Print("Apertura automatica pendiente: habilita importaciones DLL para abrir el Explorador. Los datos exportados estan en: ",folderPath);
        return;
    }
    ResetLastError();
    int result = ShellExecuteW(0, "open", folderPath, "", "", 1);
    if(result <= 32)
    {
        Print("No se pudo abrir la carpeta del CSV automaticamente. Codigo: ", result,
              " | Error: ", GetLastError(),
              " | Carpeta: ", folderPath,
              " | Verifica que 'Permitir importacion de funciones DLL' este habilitado en la pestaña General/Common del Probador de Estrategias.");
    }
}

bool ExportTradesCSV()
{
    datetime toTime = TimeCurrent();
    datetime fromTime = MQLInfoInteger(MQL_TESTER) ? (datetime)0 : toTime - (datetime)MathMax(InpExportLookbackDays, 1) * 86400;
    if(!HistorySelect(fromTime, toTime))
    {
        Print("No se pudo seleccionar historial para export CSV. Error: ", GetLastError());
        return false;
    }

    bool usedCommon = InpExportCSVCommonFiles;
    int flags = FILE_CSV | FILE_WRITE | FILE_ANSI | FILE_SHARE_READ | FILE_SHARE_WRITE;
    if(usedCommon)
        flags |= FILE_COMMON;

    string fileName = CSVFileName();
    EnsureExportSubFolder(usedCommon);
    ResetLastError();
    int file = FileOpen(ExportFileArgument(fileName), flags, ';', CP_UTF8);
    if(file == INVALID_HANDLE && usedCommon)
    {
        int commonError = GetLastError();
        Print("⚠️ No se pudo crear el CSV en Common\\Files (Error: ", commonError,
              "). Reintentando en la carpeta local MQL5\\Files...");
        usedCommon = false;
        flags = FILE_CSV | FILE_WRITE | FILE_ANSI | FILE_SHARE_READ | FILE_SHARE_WRITE;
        EnsureExportSubFolder(usedCommon);
        ResetLastError();
        file = FileOpen(ExportFileArgument(fileName), flags, ';', CP_UTF8);
    }
    if(file == INVALID_HANDLE)
    {
        int errCode = GetLastError();
        Print("❌ No se pudo crear CSV de operaciones. Error: ", errCode,
              " | Archivo: ", fileName);
        SetCSVPathFieldText("ERROR al exportar (" + IntegerToString(errCode) + "). Ver pestaña Expertos/Journal.");
        return false;
    }

    WriteBacktestConfiguration(file);

    FileWrite(file, "SECCION", "OPERACIONES");
    FileWrite(file,
              "position_id", "entrada_tiempo", "salida_tiempo", "tipo", "lote",
              "entrada_precio", "salida_precio", "resultado_neto", "resultado_r",
              "motivo_salida",
              "atr_entrada", "atr_media_entrada", "adx_entrada", "rsi_entrada", "ema_fast_entrada",
              "ema_slow_entrada", "soporte_entrada", "resistencia_entrada", "regimen_entrada", "direccion_tendencia_entrada",
              "atr_salida", "atr_media_salida", "adx_salida", "rsi_salida", "ema_fast_salida",
              "ema_slow_salida", "soporte_salida", "resistencia_salida", "regimen_salida", "direccion_tendencia_salida",
              "rr_objetivo", "sl_mult_usado", "trailing_mult_usado");

    int exported = 0;
    int total = HistoryDealsTotal();
    for(int i = 0; i < total; i++)
    {
        ulong deal = HistoryDealGetTicket(i);
        if(deal == 0 || !HistoryDealSelect(deal))
            continue;

        if(HistoryDealGetString(deal, DEAL_SYMBOL) != _Symbol)
            continue;

        if((long)HistoryDealGetInteger(deal, DEAL_MAGIC) != InpMagicNumber)
            continue;

        long entry = (long)HistoryDealGetInteger(deal, DEAL_ENTRY);
        if(entry != DEAL_ENTRY_IN && entry != DEAL_ENTRY_INOUT)
            continue;

        ulong positionId = (ulong)HistoryDealGetInteger(deal, DEAL_POSITION_ID);
        datetime entryTime = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);
        double entryPrice = HistoryDealGetDouble(deal, DEAL_PRICE);
        double lot = HistoryDealGetDouble(deal, DEAL_VOLUME);
        string typeText = DealTypeText((long)HistoryDealGetInteger(deal, DEAL_TYPE));

        datetime exitTime;
        double exitPrice;
        double profit;
        string exitReason;
        bool hasExit = FindExitDealForPosition(positionId, entryTime, exitTime, exitPrice, profit, exitReason);

        double atr = IndicatorAtTime(g_atrHandle, entryTime);
        double atrAvg = ATRAverageAtTime(entryTime);
        double adx = IndicatorAtTime(g_adxHandle, entryTime);
        double rsi = IndicatorAtTime(g_rsiHandle, entryTime);
        double emaFast = IndicatorAtTime(g_emaFastHandle, entryTime);
        double emaSlow = IndicatorAtTime(g_emaSlowHandle, entryTime);
        double resistance = IndicatorAtTime(g_maHighHandle, entryTime);
        double support = IndicatorAtTime(g_maLowHandle, entryTime);
        string regime = RegimeAtIndicators(adx, atr, atrAvg);
        string trendDirection = (emaFast > emaSlow) ? "ALCISTA" : ((emaFast < emaSlow) ? "BAJISTA" : "NEUTRAL");

        double atrExit = 0.0, atrAvgExit = 0.0, adxExit = 0.0, rsiExit = 0.0;
        double emaFastExit = 0.0, emaSlowExit = 0.0, resistanceExit = 0.0, supportExit = 0.0;
        string regimeExit = "";
        string trendDirectionExit = "";
        if(hasExit)
        {
            atrExit = IndicatorAtTime(g_atrHandle, exitTime);
            atrAvgExit = ATRAverageAtTime(exitTime);
            adxExit = IndicatorAtTime(g_adxHandle, exitTime);
            rsiExit = IndicatorAtTime(g_rsiHandle, exitTime);
            emaFastExit = IndicatorAtTime(g_emaFastHandle, exitTime);
            emaSlowExit = IndicatorAtTime(g_emaSlowHandle, exitTime);
            resistanceExit = IndicatorAtTime(g_maHighHandle, exitTime);
            supportExit = IndicatorAtTime(g_maLowHandle, exitTime);
            regimeExit = RegimeAtIndicators(adxExit, atrExit, atrAvgExit);
            trendDirectionExit = (emaFastExit > emaSlowExit) ? "ALCISTA" : ((emaFastExit < emaSlowExit) ? "BAJISTA" : "NEUTRAL");
        }

        double riskDistance = LoadInitialRisk((ulong)positionId);
        double resultR = 0.0;
        if(hasExit && riskDistance > 0.0)
        {
            double direction = (typeText == "BUY") ? 1.0 : -1.0;
            resultR = ((exitPrice - entryPrice) * direction) / riskDistance;
        }

        FileWrite(file,
                  (string)positionId,
                  TimeToString(entryTime, TIME_DATE | TIME_SECONDS),
                  hasExit ? TimeToString(exitTime, TIME_DATE | TIME_SECONDS) : "",
                  typeText,
                  DoubleToString(lot, 2),
                  DoubleToString(entryPrice, _Digits),
                  hasExit ? DoubleToString(exitPrice, _Digits) : "",
                  hasExit ? DoubleToString(profit, 2) : "",
                  hasExit ? DoubleToString(resultR, 2) : "",
                  exitReason,
                  DoubleToString(atr, _Digits),
                  DoubleToString(atrAvg, _Digits),
                  DoubleToString(adx, 2),
                  DoubleToString(rsi, 2),
                  DoubleToString(emaFast, _Digits),
                  DoubleToString(emaSlow, _Digits),
                  DoubleToString(support, _Digits),
                  DoubleToString(resistance, _Digits),
                  regime,
                  trendDirection,
                  hasExit ? DoubleToString(atrExit, _Digits) : "",
                  hasExit ? DoubleToString(atrAvgExit, _Digits) : "",
                  hasExit ? DoubleToString(adxExit, 2) : "",
                  hasExit ? DoubleToString(rsiExit, 2) : "",
                  hasExit ? DoubleToString(emaFastExit, _Digits) : "",
                  hasExit ? DoubleToString(emaSlowExit, _Digits) : "",
                  hasExit ? DoubleToString(supportExit, _Digits) : "",
                  hasExit ? DoubleToString(resistanceExit, _Digits) : "",
                  hasExit ? regimeExit : "",
                  hasExit ? trendDirectionExit : "",
                  DoubleToString(GetTargetRR(), 2),
                  DoubleToString(g_slMultUsed, 2),
                  DoubleToString(g_trailingMultUsed, 2));

        exported++;
    }

    FileClose(file);

    string folderUsed = GetCSVFolderPathFor(usedCommon);
    string physicalPath = folderUsed + fileName;
    Print("✅ CSV exportado: ", fileName, " | Operaciones: ", exported,
          " | Guardado en: ", usedCommon ? "Common\\Files (compartida entre terminales)" : "MQL5\\Files (carpeta local de esta terminal/agente)");
    Print("📁 RUTA FISICA DEL INFORME: ", physicalPath);

    //--- Dejar la ruta visible y copiable en el propio grafico (no depende del Journal)
    SetCSVPathFieldText(physicalPath);

    OpenCSVFolder(usedCommon);

    return true;
}


double NormalizePriceDown(double price)
{
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    if(tickSize <= 0.0)
        return NormalizeDouble(price, digits);
    return NormalizeDouble(MathFloor(price / tickSize) * tickSize, digits);
}

double NormalizePriceUp(double price)
{
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    if(tickSize <= 0.0)
        return NormalizeDouble(price, digits);
    return NormalizeDouble(MathCeil(price / tickSize) * tickSize, digits);
}

void ApplyBrokerStopLimits(ENUM_POSITION_TYPE posType, double &sl, double &tp)
{
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    int stopsLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    int freezeLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
    if(tickSize <= 0.0)
        tickSize = point;
    double minDistance = MathMax(stopsLevel, freezeLevel) * point + tickSize;

    if(posType == POSITION_TYPE_BUY)
    {
        if(sl > 0.0)
            sl = NormalizePriceDown(MathMin(sl, bid - minDistance));
        if(tp > 0.0)
            tp = NormalizePriceUp(MathMax(tp, ask + minDistance));
    }
    else
    {
        if(sl > 0.0)
            sl = NormalizePriceUp(MathMax(sl, ask + minDistance));
        if(tp > 0.0)
            tp = NormalizePriceDown(MathMin(tp, bid - minDistance));
    }
}

bool IsBetterStop(ENUM_POSITION_TYPE posType, double currentSL, double candidateSL)
{
    if(candidateSL <= 0.0)
        return false;
    if(currentSL <= 0.0)
        return true;
    double tickSize = MathMax(SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE),
                              SymbolInfoDouble(_Symbol, SYMBOL_POINT));
    if(posType == POSITION_TYPE_BUY)
        return candidateSL >= currentSL + tickSize * 0.5;
    return candidateSL <= currentSL - tickSize * 0.5;
}

bool ModifyPositionConfirmed(ulong ticket, ENUM_POSITION_TYPE posType,
                             double &sl, double &tp, string reason)
{
    double previousSL = 0.0;
    double previousTP = 0.0;
    if(InpSkipUnchangedStops && !PositionSelectByTicket(ticket)) return false;
    if(PositionSelectByTicket(ticket))
    {
        previousSL = PositionGetDouble(POSITION_SL);
        previousTP = PositionGetDouble(POSITION_TP);
    }

    ApplyBrokerStopLimits(posType, sl, tp);
    double tickSize = MathMax(SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE),
                              SymbolInfoDouble(_Symbol, SYMBOL_POINT));
    // Comparar valores finales ajustados a la rejilla, no el objetivo previo.
    // Tolerancia pequena: solo error numerico, nunca medio tick de mejora real.
    double epsilon = tickSize * 0.000001;
    if(InpSkipUnchangedStops && MathAbs(sl-previousSL)<=epsilon && MathAbs(tp-previousTP)<=epsilon)
    {
        sl=previousSL;tp=previousTP;
        return true; // Estado ya aplicado, sin solicitud ni confirmacion ficticia de broker.
    }
    if(previousSL > 0.0 && MathAbs(sl - previousSL) >= tickSize * 0.5 &&
       !IsBetterStop(posType, previousSL, sl))
    {
        Print("Modificacion omitida porque empeoraria el SL | Ticket: ", ticket,
              " | Motivo: ", reason);
        return false;
    }

    ResetLastError();
    bool requestOk = m_trade.PositionModify(ticket, sl, tp);
    uint retcode = m_trade.ResultRetcode();
    bool confirmed = requestOk &&
                     (retcode == TRADE_RETCODE_DONE || retcode == TRADE_RETCODE_NO_CHANGES);
    if(!confirmed)
        Print("No se pudo modificar posicion por ", reason,
              " | Ticket: ", ticket,
              " | Solicitud: ", requestOk ? "aceptada" : "rechazada",
              " | Retcode: ", retcode, " - ", m_trade.ResultRetcodeDescription(),
              " | Error: ", GetLastError());
    DxModification(ticket,previousSL,sl,tp,reason,confirmed,retcode);
    return confirmed;
}

bool ClosePositionConfirmed(ulong ticket, string reason)
{
    int diagnosticIndex=DxCapture(ticket,false);
    ulong diagnosticID=diagnosticIndex>=0?dx_positions[diagnosticIndex].id:0;
    ResetLastError();
    bool requestOk = m_trade.PositionClose(ticket);
    uint retcode = m_trade.ResultRetcode();
    bool confirmed = requestOk &&
                     (retcode == TRADE_RETCODE_DONE || retcode == TRADE_RETCODE_DONE_PARTIAL);
    if(!confirmed)
        Print("No se pudo cerrar posicion por ", reason,
              " | Ticket: ", ticket,
              " | Retcode: ", retcode, " - ", m_trade.ResultRetcodeDescription(),
              " | Error: ", GetLastError());
    DxCloseRequest(diagnosticID,ticket,reason,confirmed,retcode);
    return confirmed;
}

bool EntryRequestConfirmed(bool requestOk)
{
    uint retcode = m_trade.ResultRetcode();
    return requestOk && (retcode == TRADE_RETCODE_DONE ||
                         retcode == TRADE_RETCODE_DONE_PARTIAL ||
                         retcode == TRADE_RETCODE_PLACED);
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
bool GetEntryGateADX(int shift, double &value)
{
    double values[1];
    if(CopyBuffer(g_adxHandle, 0, shift, 1, values) != 1) return false;
    value = values[0];
    return MathIsValidNumber(value) && value != EMPTY_VALUE && value >= 0 && value <= 100;
}

#include "alto-riesgo-v120/SessionGuard.mqh"

int OnInit()
{
    if(InpSessionGuardEnabled && (InpSessionCloseMinutes<1 || InpSessionBlockMinutes<InpSessionCloseMinutes || InpSessionWaitMinutes<0 || InpSessionBlockMinutes>1440 || InpSessionWaitMinutes>1440))
    { Print("SESION120 parametros invalidos: bloqueo >= cierre >= 1; espera >= 0; maximo 1440 minutos");return INIT_PARAMETERS_INCORRECT; }

    if(InpTrendADXGateEnabled && (!MathIsValidNumber(InpTrendADXGateMinimum) ||
       InpTrendADXGateMinimum < 0 || InpTrendADXGateMinimum >= 100))
        return INIT_PARAMETERS_INCORRECT;
    if(!MathIsValidNumber(InpRiskMoney) || !MathIsValidNumber(InpRiskPerTradePct) ||
       !MathIsValidNumber(InpRiskCostsPerLot) || InpRiskCostsPerLot < 0 || InpRiskSlippagePoints < 0 ||
       (InpRiskBudgetMode != RISK_PERCENT && InpRiskMoney <= 0) ||
       (InpRiskBudgetMode != RISK_MONEY && (InpRiskPerTradePct <= 0 || InpRiskPerTradePct > 100)) ||
       !MathIsValidNumber(InpLotMin) || InpLotMin <= 0 ||
       !MathIsValidNumber(InpLoteFijo) || InpLoteFijo <= 0)
    {
        Print("Parametros de presupuesto/volumen invalidos.");
        return INIT_PARAMETERS_INCORRECT;
    }
    Comment("SignalFusion v1.20 | Presupuesto obligatorio activo | Esperando senal para calcular SL y riesgo.");
    Print("SIGNALFUSION ORO ALTO RIESGO v1.20 | presupuesto obligatorio | lote minimo nunca forzado");
    DxInit();
    DxWriteManifest();
    if(InpSessionGuardEnabled) SGRefresh(SGNow());
    //--- Configurar objetos de trading
    m_trade.SetExpertMagicNumber(InpMagicNumber);

    //--- Guardia de instancia única: permite iniciar, pero bloquea trading si ya hay otro gráfico activo
    AcquireInstanceGuard();

    string pauseKey = EntryPauseStateKey();
    if(GlobalVariableCheck(pauseKey))
        g_newEntriesPaused = (GlobalVariableGet(pauseKey) > 0.5);
    else
    {
        g_newEntriesPaused = InpIniciarEntradasPausadas;
        GlobalVariableSet(pauseKey, g_newEntriesPaused ? 1.0 : 0.0);
    }
    
    //--- Inicializar equity con el balance real de la cuenta
    g_currentEquity = AccountInfoDouble(ACCOUNT_BALANCE);
    g_peakEquity = AccountInfoDouble(ACCOUNT_EQUITY);

    Print("SignalFusion ORO 1.11 iniciado | Balance: $", NormalizeDouble(g_currentEquity,2),
          " | Modo lote: ", (InpModoLote == LOT_RIESGO_PORCENTAJE ? "RIESGO %" : "FIJO"),
          " | Lote fijo: ", DoubleToString(InpLoteFijo,2),
          " | Riesgo/trade: ", DoubleToString(InpRiskPerTradePct,2), "%",
          " | Modo entrada: ", EntryModeName(),
          " | Estrategia RR: ", GetRRStrategyName(),
          " | RR objetivo: 1:", DoubleToString(GetTargetRR(),2),
          " | Salida: Proteccion incremental + Smart Exit + Trailing ATR real en broker",
          " | Export CSV: ", InpMostrarBotonExportCSV ? "boton activo" : "boton oculto",
          " | Informe automatico backtest: ", InpExportarCSVAlFinalBacktest ? "activo" : "inactivo",
          " | Margen reservado: ", InpMarginSafetyPct*100, "%",
          " | Nuevas entradas: ", g_newEntriesPaused ? "PAUSADAS" : "ACTIVAS");
    
    //--- Crear handles de indicadores
    g_atrHandle = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);
    g_adxHandle = iADX(_Symbol, PERIOD_CURRENT, InpADXPeriod);
    g_rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, InpRSIPeriod, PRICE_CLOSE);
    g_maHighHandle = iMA(_Symbol, PERIOD_CURRENT, InpSupportResistancePeriod, 0, MODE_SMA, PRICE_HIGH);
    g_maLowHandle = iMA(_Symbol, PERIOD_CURRENT, InpSupportResistancePeriod, 0, MODE_SMA, PRICE_LOW);
    g_emaFastHandle = iMA(_Symbol, PERIOD_CURRENT, InpEmaFastPeriod, 0, MODE_EMA, PRICE_CLOSE);
    g_emaSlowHandle = iMA(_Symbol, PERIOD_CURRENT, InpEmaSlowPeriod, 0, MODE_EMA, PRICE_CLOSE);
    
    //--- Para ATR media, crear MA sobre el close y calcular ATR media manualmente
    g_atrMediaHandle = INVALID_HANDLE; // No usar handle, calcular manualmente
    
    //--- Verificar handles (excepto g_atrMediaHandle que se calcula manualmente)
    if(g_atrHandle == INVALID_HANDLE || g_adxHandle == INVALID_HANDLE || 
       g_rsiHandle == INVALID_HANDLE || g_maHighHandle == INVALID_HANDLE ||
         g_maLowHandle == INVALID_HANDLE || g_emaFastHandle == INVALID_HANDLE ||
         g_emaSlowHandle == INVALID_HANDLE)
    {
        Print("Error al crear handles de indicadores");
        return(INIT_FAILED);
    }
    
    //--- Dimensionar arrays
    ArraySetAsSeries(g_atrBuffer, true);
    ArraySetAsSeries(g_adxBuffer, true);
    ArraySetAsSeries(g_rsiBuffer, true);
    ArraySetAsSeries(g_resistanceBuffer, true);
    ArraySetAsSeries(g_supportBuffer, true);
    ArraySetAsSeries(g_atrMediaBuffer, true);
    ArraySetAsSeries(g_volumeRelBuffer, true);
    ArraySetAsSeries(g_emaFastBuffer, true);
    ArraySetAsSeries(g_emaSlowBuffer, true);

    ArrayResize(g_emaFastBuffer, 3);
    ArrayResize(g_emaSlowBuffer, 3);

    int timerMs = MathMax(InpProtectionTimerMs, 100);
    if(!EventSetMillisecondTimer(timerMs))
        Print("No se pudo iniciar temporizador de proteccion. Error: ", GetLastError());

    CreateExportCSVButton();
    CreateEntryControlButton();
    InitializeAutomaticTradeLog();
    
    Print("SignalFusion EA inicializado correctamente");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    EventKillTimer();

    if(InpExportarCSVAlFinalBacktest && MQLInfoInteger(MQL_TESTER))
    {
        Print("Backtest finalizado: generando informe CSV de OPERACIONES + CONFIGURACION.");
        Print("Codigo responsable: OnDeinit() -> ExportTradesCSV() -> WriteBacktestConfiguration().");
        ExportTradesCSV();
    }

    //--- Liberar handles
    if(g_atrHandle != INVALID_HANDLE) IndicatorRelease(g_atrHandle);
    if(g_adxHandle != INVALID_HANDLE) IndicatorRelease(g_adxHandle);
    if(g_rsiHandle != INVALID_HANDLE) IndicatorRelease(g_rsiHandle);
    if(g_maHighHandle != INVALID_HANDLE) IndicatorRelease(g_maHighHandle);
    if(g_maLowHandle != INVALID_HANDLE) IndicatorRelease(g_maLowHandle);
    if(g_emaFastHandle != INVALID_HANDLE) IndicatorRelease(g_emaFastHandle);
    if(g_emaSlowHandle != INVALID_HANDLE) IndicatorRelease(g_emaSlowHandle);
    // g_atrMediaHandle no se usa (calculado manualmente)

    //--- Liberar candado de instancia si pertenece a este gráfico
    ReleaseInstanceGuard();
    ObjectDelete(0, BTN_EXPORT_CSV);
    ObjectDelete(0, BTN_TOGGLE_ENTRIES);
    DxFinalize("deinit");
    if(dx_events!=INVALID_HANDLE) {FileClose(dx_events);dx_events=INVALID_HANDLE;}
    Comment("");
}

//+------------------------------------------------------------------+
//| Respaldo de gestion para no depender solo de nuevos ticks         |
//+------------------------------------------------------------------+
void OnTimer()
{
    DxSample();
    SGManage();
    if(!g_instanceLocked && HasOwnOpenPosition())
        ManagePosition();
}

void RecoverIndicatorHandles(int errorCode)
{
    if(errorCode != 4807)
        return;

    static ulong lastRecoveryMs = 0;
    ulong nowMs = GetTickCount64();
    if(lastRecoveryMs > 0 && nowMs - lastRecoveryMs < 1000)
        return;
    lastRecoveryMs = nowMs;

    if(g_atrHandle != INVALID_HANDLE) IndicatorRelease(g_atrHandle);
    if(g_adxHandle != INVALID_HANDLE) IndicatorRelease(g_adxHandle);
    if(g_rsiHandle != INVALID_HANDLE) IndicatorRelease(g_rsiHandle);
    if(g_maHighHandle != INVALID_HANDLE) IndicatorRelease(g_maHighHandle);
    if(g_maLowHandle != INVALID_HANDLE) IndicatorRelease(g_maLowHandle);
    if(g_emaFastHandle != INVALID_HANDLE) IndicatorRelease(g_emaFastHandle);
    if(g_emaSlowHandle != INVALID_HANDLE) IndicatorRelease(g_emaSlowHandle);

    g_atrHandle = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);
    g_adxHandle = iADX(_Symbol, PERIOD_CURRENT, InpADXPeriod);
    g_rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, InpRSIPeriod, PRICE_CLOSE);
    g_maHighHandle = iMA(_Symbol, PERIOD_CURRENT, InpSupportResistancePeriod, 0, MODE_SMA, PRICE_HIGH);
    g_maLowHandle = iMA(_Symbol, PERIOD_CURRENT, InpSupportResistancePeriod, 0, MODE_SMA, PRICE_LOW);
    g_emaFastHandle = iMA(_Symbol, PERIOD_CURRENT, InpEmaFastPeriod, 0, MODE_EMA, PRICE_CLOSE);
    g_emaSlowHandle = iMA(_Symbol, PERIOD_CURRENT, InpEmaSlowPeriod, 0, MODE_EMA, PRICE_CLOSE);

    Print("Handles de indicadores recreados despues del error 4807.");
}

//+------------------------------------------------------------------+
//| Eventos del grafico                                               |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
    if(id == CHARTEVENT_OBJECT_CLICK && sparam == BTN_EXPORT_CSV)
    {
        ObjectSetInteger(0, BTN_EXPORT_CSV, OBJPROP_STATE, false);
        ExportTradesCSV();
    }

    if(id == CHARTEVENT_OBJECT_CLICK && sparam == BTN_TOGGLE_ENTRIES)
        SetNewEntriesPaused(!g_newEntriesPaused, true);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    SGObserveTick();
    DxSample();
    EnsureExportCSVButton();
    EnsureEntryControlButton();

    //--- Mantener o respetar guardia de instancia única
    UpdateInstanceHeartbeat();
    if(g_instanceLocked)
    {
        static datetime lastLockWarn = 0;
        if(TimeCurrent() - lastLockWarn > 60)
        {
            Print("⛔ Trading bloqueado por guardia de instancia única para ", _Symbol,
                  " Magic ", InpMagicNumber, ".");
            lastLockWarn = TimeCurrent();
        }
        return;
    }

    SGManage();

    //--- 🛡️ SINCRONIZAR EQUITY (tester y real)
    if(MQLInfoInteger(MQL_TESTER))
        g_currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    else
        g_currentEquity = AccountInfoDouble(ACCOUNT_BALANCE);

    // La gestion de una posicion existente tiene prioridad sobre todos los
    // filtros que solo deben bloquear nuevas entradas.
    if(HasOwnOpenPosition())
    {
        if(GetIndicatorData())
            DetectRegime();
        ManagePosition();
        return;
    }

    // Releer la variable global en cada tick: permite que otra EA (p.ej. el
    // Gestor de Riesgo Incremental como circuit breaker de margen) pause las
    // entradas externamente, no solo el boton local.
    string pauseKeyLive = EntryPauseStateKey();
    if(GlobalVariableCheck(pauseKeyLive))
        g_newEntriesPaused = (GlobalVariableGet(pauseKeyLive) > 0.5);

    if(g_newEntriesPaused)
        return;

    // Alto riesgo: sin umbral de saldo ni reserva porcentual de margen.
    //--- Verificación de barras disponibles (menos restrictiva para trading real)
    int barsCount = Bars(_Symbol, PERIOD_CURRENT);
    int minBarsNeeded = InpMinBarsLookback + InpATRPeriod + 5; // Mínimo realista
    
    if(barsCount < minBarsNeeded)
    {
        Print("🔄 Esperando datos históricos. Disponibles: ", barsCount, ", Necesarias: ", minBarsNeeded);
        return;
    }
    
    //--- ✅ EA ACTIVO - Procesando tick
    static int tickCount = 0;
    tickCount++;
    if(tickCount % 100 == 1) // Log cada 100 ticks para diagnóstico
    {
        Print("🟢 EA activo - Tick #", tickCount, " | Barras: ", barsCount, " | Equity: $", g_currentEquity);
    }
        
    //--- Obtener datos de indicadores
    if(!GetIndicatorData())
        return;
        
    //--- Detectar régimen de mercado
    DetectRegime();

    if(g_lossStreak >= InpMaxConsecutiveLosses)
    {
        static datetime lastStreakWarn = 0;
        if(TimeCurrent() - lastStreakWarn > 1800)
        {
            Print("⚠️ Racha de pérdidas activa (", g_lossStreak, "/", InpMaxConsecutiveLosses,
                  "). El trading sigue activo con lote reducido: ", DoubleToString(g_lotMultiplier * 100.0, 0), "%.");
            lastStreakWarn = TimeCurrent();
        }
    }
    
    //--- Verificar si hay posición abierta
    if(HasOwnOpenPosition())
    {
        ManagePosition();
    }
    else
    {
        if(IsDrawdownBrakeActive())
        {
            static datetime lastDDWarn = 0;
            if(TimeCurrent() - lastDDWarn > 900)
            {
                Print("⏸️ Nuevas entradas pausadas por freno de drawdown hasta ",
                      TimeToString(g_tradingPausedUntil, TIME_DATE | TIME_SECONDS));
                lastDDWarn = TimeCurrent();
            }
            return;
        }

        if(IsLossStreakBrakeActive())
        {
            static datetime lastStreakBrakeWarn = 0;
            if(TimeCurrent() - lastStreakBrakeWarn > 900)
            {
                Print("⏸️ Nuevas entradas pausadas por corte de racha de pérdidas hasta ",
                      TimeToString(g_lossStreakPausedUntil, TIME_DATE | TIME_SECONDS));
                lastStreakBrakeWarn = TimeCurrent();
            }
            return;
        }

        //--- Buscar señal de entrada
        CheckEntrySignals();
    }
}

//+------------------------------------------------------------------+
//| Obtener datos de indicadores                                     |
//+------------------------------------------------------------------+
bool GetIndicatorData()
{
    //--- Verificación básica de barras (menos restrictiva)
    int availableBars = Bars(_Symbol, PERIOD_CURRENT);
    if(availableBars < InpATRPeriod + 5) // Mínimo básico
    {
        Print("⚠️ Datos insuficientes: ", availableBars, " barras (mínimo: ", InpATRPeriod + 5, ")");
        return false;
    }
    
    //--- Obtener ATR
    if(CopyBuffer(g_atrHandle, 0, 0, 3, g_atrBuffer) != 3)
    {
        int errorCode = GetLastError();
        Print("❌ Error obteniendo ATR: ", errorCode);
        RecoverIndicatorHandles(errorCode);
        return false;
    }
        
    //--- Obtener ADX
    if(CopyBuffer(g_adxHandle, 0, 0, 3, g_adxBuffer) != 3)
    {
        int errorCode = GetLastError();
        Print("❌ Error obteniendo ADX: ", errorCode);
        RecoverIndicatorHandles(errorCode);
        return false;
    }
        
    //--- Obtener RSI
    if(CopyBuffer(g_rsiHandle, 0, 0, 3, g_rsiBuffer) != 3)
    {
        int errorCode = GetLastError();
        Print("❌ Error obteniendo RSI: ", errorCode);
        RecoverIndicatorHandles(errorCode);
        return false;
    }

    //--- Obtener EMAs para filtro de tendencia
    if(CopyBuffer(g_emaFastHandle, 0, 0, 3, g_emaFastBuffer) != 3)
    {
        int errorCode = GetLastError();
        Print("❌ Error obteniendo EMA rápida: ", errorCode);
        RecoverIndicatorHandles(errorCode);
        return false;
    }

    if(CopyBuffer(g_emaSlowHandle, 0, 0, 3, g_emaSlowBuffer) != 3)
    {
        int errorCode = GetLastError();
        Print("❌ Error obteniendo EMA lenta: ", errorCode);
        RecoverIndicatorHandles(errorCode);
        return false;
    }
        
    //--- Obtener Resistencia (MA de máximos)
    if(CopyBuffer(g_maHighHandle, 0, 0, 3, g_resistanceBuffer) != 3) // [0]=actual, [1]=anterior
    {
        RecoverIndicatorHandles(GetLastError());
        return false;
    }
        
    //--- Obtener Soporte (MA de mínimos)
    if(CopyBuffer(g_maLowHandle, 0, 0, 3, g_supportBuffer) != 3) // [0]=actual, [1]=anterior
    {
        RecoverIndicatorHandles(GetLastError());
        return false;
    }
        
    //--- Cálculo de ATR media (simplificado y robusto)
    ArrayResize(g_atrMediaBuffer, 3);
    
    // Intentar obtener datos para ATR media
    int atrDataNeeded = MathMin(InpATRMediaPeriod, availableBars - InpATRPeriod);
    
    if(atrDataNeeded >= 10) // Mínimo 10 barras para media
    {
        double atr_extended[];
        if(CopyBuffer(g_atrHandle, 0, 0, atrDataNeeded, atr_extended) == atrDataNeeded)
        {
            ArraySetAsSeries(atr_extended, true);
            
            // Calcular ATR media con datos disponibles
            for(int i = 0; i < 3; i++)
            {
                double sum = 0;
                int count = 0;
                
                for(int j = i; j < i + atrDataNeeded - 5 && j < ArraySize(atr_extended); j++)
                {
                    sum += atr_extended[j];
                    count++;
                    if(count >= 10) break; // Suficientes datos
                }
                
                g_atrMediaBuffer[i] = (count > 0) ? sum / count : g_atrBuffer[0];
            }
        }
        else
        {
            // Fallback: usar ATR actual
            for(int i = 0; i < 3; i++)
                g_atrMediaBuffer[i] = g_atrBuffer[0];
        }
    }
    else
    {
        // No hay suficientes datos, usar ATR actual como media
        for(int i = 0; i < 3; i++)
            g_atrMediaBuffer[i] = g_atrBuffer[0];
    }
        
    //--- ✅ Calcular volumen relativo (simplificado)
    CalculateVolumeRelative();
    
    return true;
}

//+------------------------------------------------------------------+
//| Calcular volumen relativo                                        |
//+------------------------------------------------------------------+
void CalculateVolumeRelative()
{
    ArrayResize(g_volumeRelBuffer, 3);
    
    //--- Verificación de volumen simplificada
    long volume[];
    int volumeBars = MathMin(15, Bars(_Symbol, PERIOD_CURRENT)); // Reducido para ser menos restrictivo
    
    if(CopyTickVolume(_Symbol, PERIOD_CURRENT, 0, volumeBars, volume) != volumeBars)
    {
        // Valor neutro si no hay volúmenes
        for(int i = 0; i < 3; i++)
            g_volumeRelBuffer[i] = 1.0;
        return;
    }
    
    //--- Calcular promedio simple
    long avgVolume = 0;
    int avgCount = MathMax(1, volumeBars - 1);
    
    for(int i = 1; i < volumeBars; i++)
        avgVolume += volume[i];
    avgVolume = avgVolume / avgCount;
    
    //--- Calcular ratios
    for(int i = 0; i < 3 && i < volumeBars; i++)
    {
        if(avgVolume > 0)
            g_volumeRelBuffer[i] = (double)volume[i] / (double)avgVolume;
        else
            g_volumeRelBuffer[i] = 1.0;
    }
    
    // Completar si faltan valores
    for(int i = volumeBars; i < 3; i++)
        g_volumeRelBuffer[i] = 1.0;
}

//+------------------------------------------------------------------+
//| NUEVO V4: Obtener la última vela CERRADA (no la vela en formación)|
//| shift 0 = vela en formación (precio en vivo) -> la ignoramos      |
//| shift 1 = última vela cerrada -> la usamos para señales           |
//| shift 2 = vela cerrada anterior -> usada para detectar "ruptura   |
//|           fresca" (que no estuviera ya rota antes)                |
//+------------------------------------------------------------------+
bool GetConfirmedBars(MqlRates &confirmed, MqlRates &previous)
{
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    if(CopyRates(_Symbol, PERIOD_CURRENT, 0, 3, rates) != 3)
        return false;

    confirmed = rates[1]; // última vela cerrada
    previous  = rates[2]; // vela cerrada anterior
    return true;
}

//+------------------------------------------------------------------+
//| Detectar régimen de mercado                                      |
//+------------------------------------------------------------------+
void DetectRegime()
{
    int score = 0;
    string reasons = "";
    double close = 0.0;

    MqlRates confirmedBar, previousBar;
    if(InpRequireCandleConfirmation && GetConfirmedBars(confirmedBar, previousBar))
        close = confirmedBar.close;
    else
    {
        MqlRates rates[];
        if(CopyRates(_Symbol, PERIOD_CURRENT, 0, 1, rates) == 1)
            close = rates[0].close;
    }

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

    g_regimeConfidence = (int)((MathMin(score, 4) / 4.0) * 100);
    UpdateRegimeParameters();

    static datetime lastRegimeLogBar = 0;
    datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    if(currentBarTime != lastRegimeLogBar)
    {
        lastRegimeLogBar = currentBarTime;
        string dir = (g_trendDirection == 1 ? "ALCISTA" : (g_trendDirection == -1 ? "BAJISTA" : "NEUTRA"));
        Print("⚙️ Régimen: ", g_currentRegime,
              " | Dirección: ", dir,
              " | Confianza: ", g_regimeConfidence, "%",
              " | ATR: ", DoubleToString(atr, 5),
              " | ADX: ", DoubleToString(adx, 2),
              " | EMA fast/slow: ", DoubleToString(emaFast, 2), "/", DoubleToString(emaSlow, 2),
              " | Pendiente EMA: ", DoubleToString(emaSlopePrice, 5),
              " - ", reasons);
    }
}

//+------------------------------------------------------------------+
//| Señal de recuperación tras racha de pérdidas                     |
//+------------------------------------------------------------------+
bool HasRecoverySignal()
{
    MqlRates rates[];
    if(CopyRates(_Symbol, PERIOD_CURRENT, 0, 1, rates) != 1)
        return false;

    double close = rates[0].close;
    double emaSlopePct = 0.0;
    if(MathAbs(g_emaFastBuffer[2]) > 0.0)
        emaSlopePct = (g_emaFastBuffer[0] - g_emaFastBuffer[2]) / MathAbs(g_emaFastBuffer[2]);

    bool bullishRecovery = (close > g_emaFastBuffer[0] && g_emaFastBuffer[0] > g_emaSlowBuffer[0] &&
                            (g_adxBuffer[0] > 22.0 || MathAbs(emaSlopePct) > 0.0005));
    bool bearishRecovery = (close < g_emaFastBuffer[0] && g_emaFastBuffer[0] < g_emaSlowBuffer[0] &&
                            (g_adxBuffer[0] > 22.0 || MathAbs(emaSlopePct) > 0.0005));

    return (bullishRecovery || bearishRecovery);
}

//+------------------------------------------------------------------+
//| Obtener RR objetivo según estrategia seleccionada                 |
//+------------------------------------------------------------------+
double GetTargetRR()
{
    switch(InpRRStrategy)
    {
        case RR_CONSERVADORA:
            return 1.50;
        case RR_BALANCEADA:
            return 2.00;
        case RR_TENDENCIAL:
            return 2.50;
        case RR_PERSONALIZADA:
            return MathMax(InpRRPersonalizado, InpMinRRPermitido);
    }
    return 2.00;
}

//+------------------------------------------------------------------+
//| Nombre de estrategia RR                                           |
//+------------------------------------------------------------------+
string GetRRStrategyName()
{
    switch(InpRRStrategy)
    {
        case RR_CONSERVADORA:
            return "CONSERVADORA 1:1.5";
        case RR_BALANCEADA:
            return "BALANCEADA 1:2";
        case RR_TENDENCIAL:
            return "TENDENCIAL 1:2.5";
        case RR_PERSONALIZADA:
            return "PERSONALIZADA";
    }
    return "BALANCEADA 1:2";
}

//+------------------------------------------------------------------+
//| Actualizar parámetros según régimen                              |
//+------------------------------------------------------------------+
void UpdateRegimeParameters()
{
    if(g_currentRegime == "TENDENCIA")
    {
        g_slMultUsed = InpTrendSLMult;
        g_trailingMultUsed = InpTrendTrailingMult;
        // TP ya no se define por multiplicador de régimen; se define por RR.
    }
    else // LATERAL o MIXTO: se gestiona una posicion ya abierta con los parametros de LATERAL
    {
        g_slMultUsed = InpLateralSLMult;
        g_trailingMultUsed = InpLateralTrailingMult;
        // TP ya no se define por multiplicador de régimen; se define por RR.
    }
}

//+------------------------------------------------------------------+
//| Verificar señales de entrada                                     |
//+------------------------------------------------------------------+
// Reconcile broker history before entry: tick may arrive before exit callback.
bool SyncLastExitBeforeEntry()
{
    datetime now=TimeCurrent();
    int window=(int)MathMax(86400,MathMax(InpCooldownMinSeconds,EntryCooldownMinutes()*60)+60);
    if(!HistorySelect(now-window,now)) return false;
    for(int i=HistoryDealsTotal()-1;i>=0;i--)
    {
        ulong deal=HistoryDealGetTicket(i);
        if(deal==0) continue;
        datetime closed=(datetime)HistoryDealGetInteger(deal,DEAL_TIME);
        if(closed<g_lastCloseTime) break;
        if(HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol || HistoryDealGetInteger(deal,DEAL_MAGIC)!=InpMagicNumber) continue;
        long side=HistoryDealGetInteger(deal,DEAL_ENTRY);
        if(side!=DEAL_ENTRY_OUT && side!=DEAL_ENTRY_OUT_BY && side!=DEAL_ENTRY_INOUT) continue;
        if(closed>g_lastCloseTime)
        {
            g_lastCloseTime=closed;
            g_lastCloseWasLoss=(HistoryDealGetDouble(deal,DEAL_PROFIT)+HistoryDealGetDouble(deal,DEAL_COMMISSION)+HistoryDealGetDouble(deal,DEAL_SWAP)+HistoryDealGetDouble(deal,DEAL_FEE))<0;
            Print("Cooldown sincronizado desde cierre broker: ",TimeToString(closed,TIME_DATE|TIME_SECONDS));
        }
        break;
    }
    return true;
}

void CheckEntrySignals()
{
    if(!SyncLastExitBeforeEntry()) return;
    if(g_instanceLocked)
        return;

    //--- EXP-4.0: el regimen MIXTO (ADX debil y ATR sin contraer, ni tendencia ni rango real)
    //--- resulto sistematicamente el peor en el analisis de Fase 1/2 (~30% win rate en 3 backtests
    //--- distintos). Por defecto no se abren posiciones nuevas en este regimen.
    if(!InpOperarRegimenMixto && g_currentRegime == "MIXTO")
        return;

    //--- NUEVO V5.3: Cooldown tras una orden rechazada por el bróker ---
    //--- Antes, si el bróker rechazaba la orden (ej. "Invalid stops"), el EA
    //--- reintentaba en cada tick con los mismos valores, generando decenas de
    //--- intentos fallidos en pocos segundos. Ahora espera antes de reintentar.
    int failedOrderCooldownSeconds = EntryFailedOrderCooldownSeconds();
    if(failedOrderCooldownSeconds > 0 && g_lastFailedOrderTime > 0)
    {
        int secondsSinceFail = (int)(TimeCurrent() - g_lastFailedOrderTime);
        if(secondsSinceFail < failedOrderCooldownSeconds)
            return;
    }

    //--- EXP-1.1: piso duro de cooldown en segundos, SIEMPRE activo tras cualquier cierre,
    //--- sin importar el modo de entrada (evita la cascada de reentrada del modo FLEXIBLE).
    if(InpCooldownMinSeconds > 0 && g_lastCloseTime > 0)
    {
        int secondsSinceCloseHard = (int)(TimeCurrent() - g_lastCloseTime);
        if(secondsSinceCloseHard < InpCooldownMinSeconds)
            return;
    }

    //--- EXP-1.2: maximo 1 entrada nueva por vela del timeframe del grafico.
    if(InpUnaEntradaPorVela)
    {
        datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
        if(currentBarTime > 0 && currentBarTime == g_lastEntryBarTime)
            return;
    }

    //--- NUEVO V4: Cooldown tras el cierre de la última operación ---
    int cooldownMinutes = EntryCooldownMinutes();
    if(cooldownMinutes > 0 && g_lastCloseTime > 0)
    {
        bool aplicaCooldown = InpCooldownOnlyAfterLoss ? g_lastCloseWasLoss : true;
        if(aplicaCooldown)
        {
            int secondsSinceClose = (int)(TimeCurrent() - g_lastCloseTime);
            int cooldownSeconds = cooldownMinutes * 60;
            if(secondsSinceClose < cooldownSeconds)
                return; // todavía en cooldown, no buscar nuevas entradas
        }
    }

    //--- Obtener datos actuales (vela CERRADA, no la vela en formación) ---
    double close, high, low;
    MqlRates confirmedBar, previousBar;
    ZeroMemory(confirmedBar);
    ZeroMemory(previousBar);
    bool gotConfirmed = false;

    if(InpRequireCandleConfirmation)
    {
        if(!GetConfirmedBars(confirmedBar, previousBar))
            return;
        close = confirmedBar.close;
        high  = confirmedBar.high;
        low   = confirmedBar.low;
        gotConfirmed = true;
    }
    else
    {
        //--- Modo legacy: precio en vivo (no recomendado, se mantiene como opción)
        MqlRates rates[];
        if(CopyRates(_Symbol, PERIOD_CURRENT, 0, 1, rates) != 1)
            return;
        close = rates[0].close;
        high  = rates[0].high;
        low   = rates[0].low;
    }

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
    StringToLower(direction); // Usar función del sistema
    bool allowBuy = (direction == "both" || direction == "buy");
    bool allowSell = (direction == "both" || direction == "sell");
    
    bool entrySignal = false;
    ENUM_ORDER_TYPE orderType = ORDER_TYPE_BUY; // Inicializar para evitar warning
    
    //=== RÉGIMEN TENDENCIA: Momentum + Ruptura ===
    if(g_currentRegime == "TENDENCIA")
    {
        if(!InpAllowTrendEntries) return;
        // Filtro de admision independiente: no reclasificar regimen ni cambiar gestion.
        if(InpTrendADXGateEnabled)
        {
            double entryADX = 0.0;
            if(!GetEntryGateADX(gotConfirmed ? 1 : 0, entryADX)) return;
            if(entryADX <= InpTrendADXGateMinimum) return;
        }

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
            Print("Señal COMPRA TENDENCIA (vela cerrada): Close=", close, " > Resistencia=", g_resistanceBuffer[lvlIdx], " ADX=", adx);
        }
        //--- Señal de venta: la vela cerrada cierra por debajo del soporte
        else if(allowSell && allowTrendSell && close < g_supportBuffer[lvlIdx] && freshDown &&
                (!UseEntryRequireADX() || adx > EntryMinADX()))
        {
            entrySignal = true;
            orderType = ORDER_TYPE_SELL;
            Print("Señal VENTA TENDENCIA (vela cerrada): Close=", close, " < Soporte=", g_supportBuffer[lvlIdx], " ADX=", adx);
        }
    }
    //=== RÉGIMEN LATERAL: Reversión + Rango ===
    else if(g_currentRegime == "LATERAL")
    {
        //--- V6.10: corrección crítica. Antes se usaba soporte*1.05 y resistencia*0.95.
        //--- En XAUUSD eso hacía que casi cualquier precio pareciera "cerca" del nivel.
        //--- Ahora la cercanía se mide por distancia real en precio usando ATR.
        double proximity = MathMax(atr * EntrySRProximityAtrMult(), 10.0 * SymbolInfoDouble(_Symbol, SYMBOL_POINT));
        bool cercaSoporte = (MathAbs(close - g_supportBuffer[lvlIdx]) <= proximity);
        bool cercaResistencia = (MathAbs(close - g_resistanceBuffer[lvlIdx]) <= proximity);

        bool lateralPermitido = true;
        if(EntryBlockLateralHighADX() && adx > EntryLateralADXMax())
        {
            lateralPermitido = false;
            Print("⛔ Señal lateral bloqueada: ADX alto=", DoubleToString(adx,2),
                  " > ", DoubleToString(EntryLateralADXMax(),2),
                  ". Evita operar reversión contra tendencia.");
        }

        bool useEmaDirectionFilter = EntryUseEMADirectionFilter();
        bool compraBloqueadaPorDireccion = (useEmaDirectionFilter && g_trendDirection == -1);
        bool ventaBloqueadaPorDireccion  = (useEmaDirectionFilter && g_trendDirection == 1);

        //--- Señal de compra: RSI bajo, pero sólo si realmente está cerca del soporte y no hay sesgo bajista fuerte
        if(lateralPermitido && allowBuy && cercaSoporte && !compraBloqueadaPorDireccion && rsi < EntryRSIOversold())
        {
            entrySignal = true;
            orderType = ORDER_TYPE_BUY;
            Print("Señal COMPRA LATERAL validada: Close=", close,
                  " | Soporte=", g_supportBuffer[lvlIdx],
                  " | Distancia=", DoubleToString(MathAbs(close - g_supportBuffer[lvlIdx]),5),
                  " | Máx=", DoubleToString(proximity,5),
                  " | RSI=", rsi);
        }
        //--- Señal de venta: RSI alto, pero sólo si realmente está cerca de resistencia y no hay sesgo alcista fuerte
        else if(lateralPermitido && allowSell && cercaResistencia && !ventaBloqueadaPorDireccion && rsi > EntryRSIOverbought())
        {
            entrySignal = true;
            orderType = ORDER_TYPE_SELL;
            Print("Señal VENTA LATERAL validada: Close=", close,
                  " | Resistencia=", g_resistanceBuffer[lvlIdx],
                  " | Distancia=", DoubleToString(MathAbs(close - g_resistanceBuffer[lvlIdx]),5),
                  " | Máx=", DoubleToString(proximity,5),
                  " | RSI=", rsi);
        }
    }
    
    //--- Ejecutar entrada si hay señal
    if(entrySignal)
    {
        ExecuteEntry(orderType, close, atr);
    }
    else
    {
        static datetime lastNoEntryBar = 0;
        datetime diagnosticBar = gotConfirmed ? confirmedBar.time : iTime(_Symbol, PERIOD_CURRENT, 0);
        if(diagnosticBar != lastNoEntryBar)
        {
            lastNoEntryBar = diagnosticBar;
            Print("SignalFusion ORO sin entrada | Regimen: ", g_currentRegime,
                  " | Direccion EMA: ", g_trendDirection,
                  " | Close: ", DoubleToString(close, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)),
                  " | Soporte/Resistencia: ",
                  DoubleToString(g_supportBuffer[lvlIdx], 2), "/",
                  DoubleToString(g_resistanceBuffer[lvlIdx], 2),
                  " | RSI: ", DoubleToString(rsi, 2),
                  " | ADX: ", DoubleToString(adx, 2));
        }
    }
}

//+------------------------------------------------------------------+
//| Ejecutar entrada al mercado                                      |
//+------------------------------------------------------------------+
void ExecuteEntry(ENUM_ORDER_TYPE orderType, double currentPrice, double atr)
{
    if(!SGAllowEntry()) return;
    //--- 🛡️ FILTRO DE SPREAD: evita entrar cuando el spread está anormalmente ancho
    //--- (noticias, baja liquidez). Con SL tan ajustado como 0.50xATR en régimen
    //--- LATERAL, un spread inflado puede convertir una señal válida en una pérdida
    //--- inmediata o en un stop casi garantizado nada más abrir.
    if(InpUsarFiltroSpread)
    {
        long currentSpreadPoints = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
        if(currentSpreadPoints > InpMaxSpreadPoints)
        {
            Print("⛔ Entrada cancelada por spread excesivo | Spread actual: ", currentSpreadPoints,
                  " puntos | Máximo permitido: ", InpMaxSpreadPoints, " puntos");
            g_lastFailedOrderTime = TimeCurrent();
            return;
        }
    }

    //--- V6.00: gestión por R.
    //--- Se elimina el cálculo complejo de pérdida fija en dólares.
    //--- El lote es fijo. SL = ATR * multiplicador de régimen. TP = SL * RR objetivo.
    MqlTick entryTick;
    if(!SymbolInfoTick(_Symbol, entryTick) || entryTick.ask <= 0 || entryTick.bid <= 0) return;
    currentPrice = orderType == ORDER_TYPE_BUY ? entryTick.ask : entryTick.bid;
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double stopDistancePrice = g_slMultUsed * atr;

    double maxSLPrice = (double)InpMaxSLPoints * point;
    if(InpMaxSLPoints > 0 && stopDistancePrice > maxSLPrice)
    {
        Print("⚠️ SL limitado: distancia reducida de ", DoubleToString(stopDistancePrice, 5),
              " → ", DoubleToString(maxSLPrice, 5), " (max SL points: ", InpMaxSLPoints, ")");
        stopDistancePrice = maxSLPrice;
    }

    if(stopDistancePrice <= 0.0)
    {
        Print("⚠️ Distancia de SL inválida. Entrada cancelada.");
        return;
    }

    double rrObjetivo = GetTargetRR();
    if(rrObjetivo < InpMinRRPermitido)
        rrObjetivo = InpMinRRPermitido;

    double minTPDistance = MathMax((double)InpMandatoryTPPoints * point, InpMandatoryTPAtrMult * atr);
    double tpDistancePrice = stopDistancePrice * rrObjetivo;

    //--- V6: el TP se define por ratio R:R. No se usa TP por régimen.
    //--- El TP mínimo técnico nunca debe convertir el trade en peor RR.
    //--- Si el TP calculado queda menor al mínimo técnico o al ratio objetivo, se sube el TP.
    tpDistancePrice = MathMax(tpDistancePrice, minTPDistance);
    tpDistancePrice = MathMax(tpDistancePrice, stopDistancePrice * rrObjetivo);

    double rrRealPlanificado = (stopDistancePrice > 0.0) ? (tpDistancePrice / stopDistancePrice) : 0.0;
    if(InpCancelarSiRRInvalido && rrRealPlanificado < InpMinRRPermitido)
    {
        Print("⛔ Entrada CANCELADA por RR insuficiente | RR real: 1:", DoubleToString(rrRealPlanificado,2),
              " | mínimo permitido: 1:", DoubleToString(InpMinRRPermitido,2),
              " | Régimen: ", g_currentRegime);
        return;
    }

    double sl = 0.0, tp = 0.0;
    if(orderType == ORDER_TYPE_BUY)
    {
        sl = currentPrice - stopDistancePrice;
        tp = currentPrice + tpDistancePrice;
        g_breakEvenAplicado = false;
    }
    else
    {
        sl = currentPrice + stopDistancePrice;
        tp = currentPrice - tpDistancePrice;
        g_breakEvenAplicado = false;
    }

    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    sl = NormalizeDouble(sl, digits);
    tp = NormalizeDouble(tp, digits);
    ENUM_POSITION_TYPE entryPosType = (orderType == ORDER_TYPE_BUY)
                                      ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
    ApplyBrokerStopLimits(entryPosType, sl, tp);

    stopDistancePrice = MathAbs(currentPrice-sl);
    tpDistancePrice = MathAbs(tp-currentPrice);
    rrRealPlanificado = stopDistancePrice > 0 ? tpDistancePrice/stopDistancePrice : 0;
    double lots = CalculateBudgetLots(orderType, currentPrice, sl);

    if(lots <= 0.0)
    {
        Print("⛔ Lotes calculados <= 0. Operación cancelada.");
        g_lastFailedOrderTime = TimeCurrent();
        return;
    }

    double marginNeeded = 0.0;
    if(!OrderCalcMargin(orderType, _Symbol, lots, currentPrice, marginNeeded))
    {
        Print("⚠️ No se pudo calcular margen para ", DoubleToString(lots,2), " lotes. Orden cancelada.");
        g_lastFailedOrderTime = TimeCurrent();
        return;
    }

    double freeMarginNow = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    double safeMargin = freeMarginNow; // Margen real disponible; sin reserva artificial.
    if(marginNeeded > safeMargin)
    {
        Comment("SignalFusion v1.20: entrada bloqueada por margen insuficiente. Ver registro de riesgo.");
        Print("⛔ Entrada cancelada por margen insuficiente | Lote: ", DoubleToString(lots,2),
              " | Margen necesario: $", NormalizeDouble(marginNeeded,2),
              " | Margen libre seguro: $", NormalizeDouble(safeMargin,2));
        g_lastFailedOrderTime = TimeCurrent();
        return;
    }


    if(!CheckFinalEntryRisk(orderType, lots, sl, tp))
    {
        g_lastFailedOrderTime = TimeCurrent();
        return;
    }
    double approvedBudget = EntryRiskBudget();
    bool result = false;
    if(orderType == ORDER_TYPE_BUY)
        result = m_trade.Buy(lots, _Symbol, 0.0, sl, tp, StringFormat("SignalFusion ORO %s", g_currentRegime));
    else
        result = m_trade.Sell(lots, _Symbol, 0.0, sl, tp, StringFormat("SignalFusion ORO %s", g_currentRegime));

    if(EntryRequestConfirmed(result))
    {
        g_lastEntryBarTime = iTime(_Symbol, PERIOD_CURRENT, 0); // EXP-1.2

        Print("✅ Orden ejecutada - ", (orderType == ORDER_TYPE_BUY ? "COMPRA" : "VENTA"),
              " | Lotes: ", DoubleToString(lots,2),
              " | SL: ", DoubleToString(sl,digits),
              " | TP: ", DoubleToString(tp,digits),
              " | RR objetivo: 1:", DoubleToString(rrObjetivo,2),
              " | RR real planificado: 1:", DoubleToString(rrRealPlanificado,2),
              " | Estrategia: ", GetRRStrategyName(),
              " | Balance: $", NormalizeDouble(g_currentEquity, 2),
              " | Régimen: ", g_currentRegime);

        // Mantener SL tecnico enviado: no ampliar/reanclar el riesgo despues del fill.
        if(m_position.SelectByMagic(_Symbol, InpMagicNumber))
        {
            DxCapture(m_position.Ticket(),true);
            double filledPrice = m_position.PriceOpen();
            double filledSL = m_position.StopLoss();
            double filledRisk = 0;
            SaveInitialRisk(m_position.Ticket(), MathAbs(filledPrice-filledSL));
            if(EstimateStopRisk(orderType,m_position.Volume(),filledPrice,filledSL,filledRisk))
                ShowEntryRisk(filledRisk > approvedBudget ? "ALERTA: riesgo ejecutado supera presupuesto; gestion activa" : "EJECUTADA: riesgo inicial auditado",
                              m_position.Volume(),filledPrice,filledSL,filledRisk,approvedBudget);
            else
            {
                Comment("ALERTA v1.20: no se pudo auditar riesgo ejecutado. Revisar posicion y SL.");
                Print("ALERTA v1.20: no se pudo auditar riesgo ejecutado. Revisar posicion y SL.");
            }
        }

    }
    else
    {
        Comment("SignalFusion v1.20: orden rechazada por el broker. Ver registro.");
        Print("❌ Error al ejecutar orden: ", m_trade.ResultRetcode(), " - ", m_trade.ResultRetcodeDescription());
        g_lastFailedOrderTime = TimeCurrent();
    }
}

//+------------------------------------------------------------------+
//| Clave para guardar el riesgo inicial por ticket                   |
//+------------------------------------------------------------------+
string GetRiskKey(ulong ticket)
{
    return StringFormat("SignalFusion.Risk.%s.%d.%s", _Symbol, InpMagicNumber, IntegerToString((long)ticket));
}

//+------------------------------------------------------------------+
//| Guardar riesgo inicial para que 1R no cambie al mover el SL       |
//+------------------------------------------------------------------+
void SaveInitialRisk(ulong ticket, double riskDistance)
{
    if(ticket == 0 || riskDistance <= 0.0)
        return;

    GlobalVariableSet(GetRiskKey(ticket), riskDistance);
}

//+------------------------------------------------------------------+
//| Leer riesgo inicial persistido                                    |
//+------------------------------------------------------------------+
double LoadInitialRisk(ulong ticket)
{
    if(ticket == 0)
        return 0.0;

    string key = GetRiskKey(ticket);
    if(GlobalVariableCheck(key))
        return GlobalVariableGet(key);

    return 0.0;
}

//+------------------------------------------------------------------+
//| Gestionar posición abierta                                       |
//+------------------------------------------------------------------+
bool EnsurePositionProtection(double atr, ENUM_POSITION_TYPE posType, ulong ticket)
{
    double entryPrice = m_position.PriceOpen();
    double currentSL = m_position.StopLoss();
    double currentTP = m_position.TakeProfit();
    if(currentSL > 0.0 && currentTP > 0.0)
        return true;

    double riskDistance = LoadInitialRisk(ticket);
    if(riskDistance <= 0.0 && currentSL > 0.0)
        riskDistance = MathAbs(entryPrice - currentSL);
    if(riskDistance <= 0.0 && atr > 0.0)
        riskDistance = MathMax(g_slMultUsed, 0.1) * atr;
    if(entryPrice <= 0.0 || riskDistance <= 0.0)
        return false;

    double newSL = currentSL;
    double newTP = currentTP;
    double rr = MathMax(GetTargetRR(), InpMinRRPermitido);
    if(newSL <= 0.0)
        newSL = (posType == POSITION_TYPE_BUY)
                ? entryPrice - riskDistance : entryPrice + riskDistance;
    if(newTP <= 0.0)
        newTP = (posType == POSITION_TYPE_BUY)
                ? entryPrice + riskDistance * rr : entryPrice - riskDistance * rr;

    if(!ModifyPositionConfirmed(ticket, posType, newSL, newTP, "restaurar proteccion inicial"))
        return false;

    SaveInitialRisk(ticket, riskDistance);
    Print("Proteccion inicial restaurada | Ticket: ", ticket,
          " | SL: ", DoubleToString(newSL, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)),
          " | TP: ", DoubleToString(newTP, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
    return true;
}

void ManagePosition()
{
    if(!m_position.SelectByMagic(_Symbol, InpMagicNumber))
        return;

    ENUM_POSITION_TYPE posType = m_position.PositionType();
    ulong ticket = m_position.Ticket();
    double atr = (ArraySize(g_atrBuffer) > 0) ? g_atrBuffer[0] : 0.0;
    if(atr <= 0.0)
    {
        double savedRisk = LoadInitialRisk(ticket);
        if(savedRisk > 0.0)
            atr = savedRisk / MathMax(g_slMultUsed, 0.1);
    }

    DxCapture(ticket,false);
    if(!EnsurePositionProtection(atr, posType, ticket))
        return;

    if(!m_position.SelectByTicket(ticket))
        return;

    double currentPrice = (posType == POSITION_TYPE_BUY)
                          ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                          : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

    ManageExitByR(currentPrice, atr, posType, ticket);
}

//+------------------------------------------------------------------+
//| Calcular SL objetivo expresado en R desde el precio de entrada    |
//+------------------------------------------------------------------+
double BuildStopFromRiskR(double entryPrice, double riesgoInicial, double stopR,
                          ENUM_POSITION_TYPE posType, int digits)
{
    if(posType == POSITION_TYPE_BUY)
        return NormalizeDouble(entryPrice + (stopR * riesgoInicial), digits);

    return NormalizeDouble(entryPrice - (stopR * riesgoInicial), digits);
}

//+------------------------------------------------------------------+
//| Aplicar una etapa de proteccion incremental                       |
//+------------------------------------------------------------------+
bool TryApplyIncrementalProtectionStage(double profitR, double triggerR, double stopR,
                                        double entryPrice, double riesgoInicial,
                                        ENUM_POSITION_TYPE posType, double &currentSL,
                                        double currentTP, int digits, string stageName,
                                        ulong ticket)
{
    if(triggerR <= 0.0 || profitR < triggerR)
        return true;

    double targetSL = BuildStopFromRiskR(entryPrice, riesgoInicial, stopR, posType, digits);
    bool mejora = false;

    if(posType == POSITION_TYPE_BUY && targetSL > currentSL)
        mejora = true;
    if(posType == POSITION_TYPE_SELL && targetSL < currentSL)
        mejora = true;

    if(!mejora)
    {
        if((posType == POSITION_TYPE_BUY && currentSL >= targetSL) ||
           (posType == POSITION_TYPE_SELL && currentSL <= targetSL))
        {
            if(stopR >= 0.0)
                g_breakEvenAplicado = true;
        }
        return true;
    }

    if(ModifyPositionConfirmed(ticket, posType, targetSL, currentTP,
                               "proteccion incremental etapa " + stageName))
    {
        currentSL = targetSL;
        if(stopR >= 0.0)
            g_breakEvenAplicado = true;

        Print("Proteccion incremental ", stageName,
              " aplicada | SL: ", DoubleToString(targetSL, digits),
              " | Stop objetivo: ", DoubleToString(stopR, 2), "R",
              " | Ganancia: +", DoubleToString(profitR, 2), "R");
        return true;
    }

    Print("No se pudo aplicar proteccion incremental ", stageName,
          ". Retcode: ", m_trade.ResultRetcode(),
          " - ", m_trade.ResultRetcodeDescription());
    return false;
}

//+------------------------------------------------------------------+
//| Gestionar proteccion progresiva antes del trailing                |
//+------------------------------------------------------------------+
bool ManageIncrementalProtection(double profitR, double entryPrice, double riesgoInicial,
                                 ENUM_POSITION_TYPE posType, double &currentSL,
                                 double currentTP, int digits, ulong ticket)
{
    double triggerR = 0.0;
    double stopR = 0.0;
    string stageName = "";

    if(InpProteccionEtapa1TriggerR > 0.0 && profitR >= InpProteccionEtapa1TriggerR)
    {
        triggerR = InpProteccionEtapa1TriggerR;
        stopR = InpProteccionEtapa1StopR;
        stageName = "1";
    }

    if(InpProteccionEtapa2TriggerR > 0.0 && profitR >= InpProteccionEtapa2TriggerR)
    {
        triggerR = InpProteccionEtapa2TriggerR;
        stopR = InpProteccionEtapa2StopR;
        stageName = "2";
    }

    if(InpProteccionEtapa3TriggerR > 0.0 && profitR >= InpProteccionEtapa3TriggerR)
    {
        triggerR = InpProteccionEtapa3TriggerR;
        stopR = InpProteccionEtapa3StopR;
        stageName = "3";
    }

    if(stageName == "")
        return true;

    return TryApplyIncrementalProtectionStage(profitR, triggerR, stopR, entryPrice,
                                              riesgoInicial, posType, currentSL,
                                              currentTP, digits, stageName, ticket);
}

//+------------------------------------------------------------------+
//| Smart Exit: salir o endurecer SL si hay agotamiento con ganancia  |
//+------------------------------------------------------------------+
double RecentBarrierPrice(ENUM_POSITION_TYPE posType, int lookback)
{
    if(lookback <= 1)
        return 0.0;

    if(posType == POSITION_TYPE_BUY)
    {
        double highs[];
        ArraySetAsSeries(highs, true);
        int copied = CopyHigh(_Symbol, PERIOD_CURRENT, 1, lookback, highs);
        if(copied <= 0)
            return 0.0;
        int idx = ArrayMaximum(highs, 0, copied);
        return highs[idx];
    }

    double lows[];
    ArraySetAsSeries(lows, true);
    int copied = CopyLow(_Symbol, PERIOD_CURRENT, 1, lookback, lows);
    if(copied <= 0)
        return 0.0;
    int idx = ArrayMinimum(lows, 0, copied);
    return lows[idx];
}

int CalculateSmartExitScore(ENUM_POSITION_TYPE posType, double currentPrice,
                            double atr, double profitR, string &reasons)
{
    reasons = "";
    if(!InpUsarSmartExit || profitR < InpSmartExitMinProfitR || atr <= 0.0)
        return 0;

    int score = 0;
    double barrier = RecentBarrierPrice(posType, InpSmartExitLookbackSR);
    double proximity = atr * InpSmartExitSRProximityATR;

    if(barrier > 0.0 && proximity > 0.0)
    {
        bool nearBarrier = (posType == POSITION_TYPE_BUY)
                           ? (currentPrice >= barrier - proximity)
                           : (currentPrice <= barrier + proximity);
        if(nearBarrier)
        {
            score += 2;
            reasons += "S/R cercano;";
        }
    }

    MqlRates bars[];
    ArraySetAsSeries(bars, true);
    if(CopyRates(_Symbol, PERIOD_CURRENT, 1, 3, bars) == 3)
    {
        double body = MathAbs(bars[0].close - bars[0].open);
        double range = MathMax(bars[0].high - bars[0].low, SymbolInfoDouble(_Symbol, SYMBOL_POINT));
        bool strongAgainstBuy = (posType == POSITION_TYPE_BUY && bars[0].close < bars[0].open && body >= range * 0.55);
        bool strongAgainstSell = (posType == POSITION_TYPE_SELL && bars[0].close > bars[0].open && body >= range * 0.55);

        if(strongAgainstBuy || strongAgainstSell)
        {
            score += 3;
            reasons += "vela fuerte en contra;";
        }

        if(barrier > 0.0)
        {
            bool failedBuyBreak = (posType == POSITION_TYPE_BUY && bars[0].high >= barrier && bars[0].close < barrier);
            bool failedSellBreak = (posType == POSITION_TYPE_SELL && bars[0].low <= barrier && bars[0].close > barrier);
            if(failedBuyBreak || failedSellBreak)
            {
                score += 2;
                reasons += "rechazo de S/R;";
            }
        }
    }

    if(ArraySize(g_adxBuffer) >= 3 && InpSmartExitAdxDrop > 0.0 &&
       g_adxBuffer[2] - g_adxBuffer[0] >= InpSmartExitAdxDrop)
    {
        score += 2;
        reasons += "ADX cae;";
    }

    if(ArraySize(g_atrMediaBuffer) > 0 && g_atrMediaBuffer[0] > 0.0 &&
       InpSmartExitAtrContractPct > 0.0 && atr <= g_atrMediaBuffer[0] * InpSmartExitAtrContractPct)
    {
        score += 1;
        reasons += "ATR contrae;";
    }

    if(ArraySize(g_rsiBuffer) > 0)
    {
        if((posType == POSITION_TYPE_BUY && g_rsiBuffer[0] >= 75.0) ||
           (posType == POSITION_TYPE_SELL && g_rsiBuffer[0] <= 25.0))
        {
            score += 1;
            reasons += "RSI extremo;";
        }
    }

    return score;
}

bool ApplySmartExit(double currentPrice, double atr, ENUM_POSITION_TYPE posType,
                    double profitR, double entryPrice, double &currentSL,
                    double currentTP, int digits, ulong ticket)
{
    string reasons = "";
    int score = CalculateSmartExitScore(posType, currentPrice, atr, profitR, reasons);
    if(score < InpSmartExitScoreCerrar)
        return false;

    if(InpSmartExitAction == SMART_EXIT_CLOSE_FULL)
    {
        if(ClosePositionConfirmed(ticket, "Smart Exit"))
        {
            Print("Smart Exit: cierre total por agotamiento | Score: ", score,
                  " | Ganancia: +", DoubleToString(profitR, 2), "R",
                  " | Motivos: ", reasons);
            return true;
        }

        Print("No se pudo cerrar por Smart Exit. Retcode: ",
              m_trade.ResultRetcode(), " - ", m_trade.ResultRetcodeDescription());
        return false;
    }

    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double targetSL = (posType == POSITION_TYPE_BUY)
                      ? NormalizeDouble(entryPrice + InpSmartExitTightenPoints * point, digits)
                      : NormalizeDouble(entryPrice - InpSmartExitTightenPoints * point, digits);

    bool improves = (posType == POSITION_TYPE_BUY && targetSL > currentSL) ||
                    (posType == POSITION_TYPE_SELL && targetSL < currentSL);
    if(!improves)
        return false;

    if(ModifyPositionConfirmed(ticket, posType, targetSL, currentTP,
                               "Smart Exit endurecer SL"))
    {
        currentSL = targetSL;
        Print("Smart Exit: SL endurecido por agotamiento | Score: ", score,
              " | SL: ", DoubleToString(targetSL, digits),
              " | Ganancia: +", DoubleToString(profitR, 2), "R",
              " | Motivos: ", reasons);
        return false;
    }

    Print("No se pudo endurecer SL por Smart Exit. Retcode: ",
          m_trade.ResultRetcode(), " - ", m_trade.ResultRetcodeDescription());
    return false;
}

//+------------------------------------------------------------------+
//| Gestión de salida por R: BE + trailing ATR real en broker         |
//+------------------------------------------------------------------+
void ManageExitByR(double currentPrice, double atr, ENUM_POSITION_TYPE posType, ulong ticket)
{
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

    double entryPrice = m_position.PriceOpen();
    double currentSL  = m_position.StopLoss();
    double currentTP  = m_position.TakeProfit();

    if(entryPrice <= 0.0 || currentSL <= 0.0 || atr <= 0.0)
        return;

    double riesgoInicial = GetInitialRiskPriceDistance(entryPrice, currentSL, posType, ticket);
    if(riesgoInicial <= 0.0)
        return;

    double profitDistance = (posType == POSITION_TYPE_BUY)
                            ? (currentPrice - entryPrice)
                            : (entryPrice - currentPrice);

    if(profitDistance <= 0.0)
        return;

    double profitR = profitDistance / riesgoInicial;

    //--- 1) Proteccion incremental y break-even independientes.
    if(InpUsarProteccionIncremental)
        ManageIncrementalProtection(profitR, entryPrice, riesgoInicial,
                                    posType, currentSL, currentTP, digits, ticket);

    if(InpMoverBreakEvenEn1R &&
       profitDistance >= atr * MathMax(InpBreakEvenTriggerATR, 0.0))
    {
        double beOffset = (double)InpBreakEvenOffsetPoints * point;
        double beSL = (posType == POSITION_TYPE_BUY)
                      ? NormalizeDouble(entryPrice + beOffset, digits)
                      : NormalizeDouble(entryPrice - beOffset, digits);

        bool mejoraBE = false;
        if(posType == POSITION_TYPE_BUY && beSL > currentSL)
            mejoraBE = true;
        if(posType == POSITION_TYPE_SELL && beSL < currentSL)
            mejoraBE = true;

        if(mejoraBE)
        {
            if(ModifyPositionConfirmed(ticket, posType, beSL, currentTP,
                                       "break-even"))
            {
                g_breakEvenAplicado = true;
                currentSL = beSL;
                Print("🛡️ Break-even aplicado | SL: ", DoubleToString(beSL, digits),
                      " | Ganancia: +", DoubleToString(profitR,2), "R",
                      " | Offset: ", InpBreakEvenOffsetPoints, " pts");
            }
            else
            {
                Print("⚠️ No se pudo aplicar break-even. Retcode: ",
                      m_trade.ResultRetcode(), " - ", m_trade.ResultRetcodeDescription());
            }
        }
        else
        {
            // Si el SL ya está del lado de break-even, considerar protegido.
            if((posType == POSITION_TYPE_BUY && currentSL >= beSL) ||
               (posType == POSITION_TYPE_SELL && currentSL <= beSL))
                g_breakEvenAplicado = true;
        }
    }

    if(ApplySmartExit(currentPrice, atr, posType, profitR, entryPrice,
                      currentSL, currentTP, digits, ticket))
        return;

    //--- 2) Trailing ATR real en broker. No cierra por variable interna.
    if(!InpUsarTrailingATREnBroker)
        return;

    if(profitR < InpTrailingATRTriggerR)
        return;

    if(InpTrailingDespuesDeBreakEven && !g_breakEvenAplicado)
        return;

    double trailingMult = g_trailingMultUsed;
    if(trailingMult <= 0.0)
        trailingMult = 1.0;

    double trailDistance = trailingMult * atr;
    double stepDistance = MathMax(InpTrailingATRStepR * riesgoInicial,
                                  (double)InpMinTrailingStepPoints * point);

    double proposedSL = 0.0;
    bool mover = false;

    if(posType == POSITION_TYPE_BUY)
    {
        proposedSL = NormalizeDouble(currentPrice - trailDistance, digits);
        // Nunca permitir que el trailing baje el SL por debajo del break-even si ya fue protegido.
        if(g_breakEvenAplicado)
        {
            double minSL = NormalizeDouble(entryPrice + (double)InpBreakEvenOffsetPoints * point, digits);
            proposedSL = MathMax(proposedSL, minSL);
        }

        if(proposedSL > currentSL + stepDistance)
            mover = true;
    }
    else
    {
        proposedSL = NormalizeDouble(currentPrice + trailDistance, digits);
        if(g_breakEvenAplicado)
        {
            double maxSL = NormalizeDouble(entryPrice - (double)InpBreakEvenOffsetPoints * point, digits);
            proposedSL = MathMin(proposedSL, maxSL);
        }

        if(proposedSL < currentSL - stepDistance)
            mover = true;
    }

    if(!mover)
        return;

    if(ModifyPositionConfirmed(ticket, posType, proposedSL, currentTP,
                               "trailing ATR"))
    {
        Print("📍 Trailing ATR actualizado en broker | SL: ", DoubleToString(currentSL, digits),
              " → ", DoubleToString(proposedSL, digits),
              " | Precio: ", DoubleToString(currentPrice, digits),
              " | ATR: ", DoubleToString(atr, digits),
              " | Mult: ", DoubleToString(trailingMult,2),
              " | Ganancia: +", DoubleToString(profitR,2), "R");
    }
    else
    {
        Print("⚠️ Error modificando SL por trailing ATR: ", m_trade.ResultRetcode(),
              " - ", m_trade.ResultRetcodeDescription());
    }
}

//+------------------------------------------------------------------+
//| Distancia de riesgo inicial aproximada                            |
//+------------------------------------------------------------------+
double GetInitialRiskPriceDistance(double entryPrice, double currentSL, ENUM_POSITION_TYPE posType, ulong ticket)
{
    // En V6 el riesgo inicial se persiste por ticket para que 1R no cambie
    // cuando el EA mueve el SL a break-even o trailing.
    double riesgoGuardado = LoadInitialRisk(ticket);
    if(riesgoGuardado > 0.0)
        return riesgoGuardado;

    double riesgo = 0.0;

    if(posType == POSITION_TYPE_BUY)
        riesgo = entryPrice - currentSL;
    else
        riesgo = currentSL - entryPrice;

    if(riesgo <= 0.0)
    {
        // Si el SL ya está del lado ganador, usamos una referencia conservadora por ATR.
        double atr = g_atrBuffer[0];
        riesgo = MathMax(g_slMultUsed * atr, SymbolInfoDouble(_Symbol, SYMBOL_POINT));
        g_breakEvenAplicado = true;
    }

    if(riesgo > 0.0)
        SaveInitialRisk(ticket, riesgo);

    return riesgo;
}

//+------------------------------------------------------------------+
//| Registrar pérdidas consecutivas                                 |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
    if(trans.type == TRADE_TRANSACTION_DEAL_ADD) DxDeal(trans.deal,trans.position);
    if(trans.type != TRADE_TRANSACTION_DEAL_ADD)
        return;

    if(!HistoryDealSelect(trans.deal))
        return;

    string dealSymbol = HistoryDealGetString(trans.deal, DEAL_SYMBOL);
    long dealMagic = (long)HistoryDealGetInteger(trans.deal, DEAL_MAGIC);
    long dealEntry = (long)HistoryDealGetInteger(trans.deal, DEAL_ENTRY);

    if(dealSymbol != _Symbol || dealMagic != InpMagicNumber)
        return;

    AppendDealToAutomaticLog(trans.deal, trans);

    if(dealEntry == DEAL_ENTRY_IN || dealEntry == DEAL_ENTRY_INOUT)
    {
        ManagePosition();
        return;
    }

    if(dealEntry != DEAL_ENTRY_OUT && dealEntry != DEAL_ENTRY_OUT_BY)
        return;

    double dealProfit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT)
                      + HistoryDealGetDouble(trans.deal, DEAL_SWAP)
                      + HistoryDealGetDouble(trans.deal, DEAL_COMMISSION);

    //--- NUEVO V4: registrar momento del cierre y si fue pérdida (para el cooldown)
    g_lastCloseTime = (datetime)MathMax((long)g_lastCloseTime,HistoryDealGetInteger(trans.deal,DEAL_TIME));
    g_lastCloseWasLoss = (dealProfit < 0.0);

    if(dealProfit < 0.0)
    {
        g_lossStreak++;
        if(g_lossStreak >= InpMaxConsecutiveLosses)
        {
            g_lotMultiplier = MathMax(InpMinLotMultiplier, g_lotMultiplier - InpLotMultiplierDecay);
        }
    }
    else
    {
        g_lossStreak = 0;
        g_lossStreakPauseTriggeredAt = 0; // EXP-1.3: una ganadora rearma el circuito de corte
        g_lotMultiplier = MathMin(1.0, g_lotMultiplier + InpLotMultiplierRecovery);
    }

    Print("📊 Cierre registrado | Profit neto: $", DoubleToString(dealProfit, 2),
          " | Racha pérdidas: ", g_lossStreak,
          " | Multiplicador lote: ", DoubleToString(g_lotMultiplier, 2),
          " | Cooldown activo por: ", EntryCooldownMinutes(), " min");
}

//+------------------------------------------------------------------+
//| Expert Advisor finalizado correctamente                          |
//+------------------------------------------------------------------+

// Exportacion independiente al final del Tester; no modifica su secuencia de trading.
double OnTester()
{
    DxFinalize("tester");
    return 0.0;
}

void DxWriteManifest()
{
    if(!dx_ready) return;
    int f=FileOpen(dx_base+"_config.csv",FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON,';',CP_UTF8);
    if(f==INVALID_HANDLE) return;
    FileWrite(f,"parametro","valor");
    FileWrite(f,"InpRiskBudgetMode",(string)InpRiskBudgetMode);
    FileWrite(f,"InpRiskMoney",(string)InpRiskMoney);
    FileWrite(f,"InpRiskCostsPerLot",(string)InpRiskCostsPerLot);
    FileWrite(f,"InpRiskSlippagePoints",(string)InpRiskSlippagePoints);
    FileWrite(f,"InpSessionGuardEnabled",(string)InpSessionGuardEnabled);
    FileWrite(f,"InpSessionBlockMinutes",(string)InpSessionBlockMinutes);
    FileWrite(f,"InpSessionCloseMinutes",(string)InpSessionCloseMinutes);
    FileWrite(f,"InpSessionObservedReopen",(string)InpSessionObservedReopen);
    FileWrite(f,"InpSessionWaitMinutes",(string)InpSessionWaitMinutes);
    FileWrite(f,"InpSkipUnchangedStops",(string)InpSkipUnchangedStops);
    FileWrite(f,"InpDiagnosticEnabled",(string)InpDiagnosticEnabled);
    FileWrite(f,"InpAllowTrendEntries",(string)InpAllowTrendEntries);
    FileWrite(f,"InpTrendADXGateEnabled",(string)InpTrendADXGateEnabled);
    FileWrite(f,"InpTrendADXGateMinimum",(string)InpTrendADXGateMinimum);
    FileWrite(f,"InpModoEntrada",(string)InpModoEntrada);
    FileWrite(f,"InpModoLote",(string)InpModoLote);
    FileWrite(f,"InpRiskPerTradePct",(string)InpRiskPerTradePct);
    FileWrite(f,"InpLotMin",(string)InpLotMin);
    FileWrite(f,"InpLoteFijo",(string)InpLoteFijo);
    FileWrite(f,"InpUsarFrenoDrawdown",(string)InpUsarFrenoDrawdown);
    FileWrite(f,"InpMaxDrawdownPct",(string)InpMaxDrawdownPct);
    FileWrite(f,"InpDrawdownPauseMinutes",(string)InpDrawdownPauseMinutes);
    FileWrite(f,"InpDrawdownPauseMaxMinutes",(string)InpDrawdownPauseMaxMinutes);
    FileWrite(f,"InpRRStrategy",(string)InpRRStrategy);
    FileWrite(f,"InpRRPersonalizado",(string)InpRRPersonalizado);
    FileWrite(f,"InpMinRRPermitido",(string)InpMinRRPermitido);
    FileWrite(f,"InpCancelarSiRRInvalido",(string)InpCancelarSiRRInvalido);
    FileWrite(f,"InpATRPeriod",(string)InpATRPeriod);
    FileWrite(f,"InpATRMultiplier",(string)InpATRMultiplier);
    FileWrite(f,"InpRequireADX",(string)InpRequireADX);
    FileWrite(f,"InpMinADX",(string)InpMinADX);
    FileWrite(f,"InpADXPeriod",(string)InpADXPeriod);
    FileWrite(f,"InpRSIPeriod",(string)InpRSIPeriod);
    FileWrite(f,"InpRSIOversold",(string)InpRSIOversold);
    FileWrite(f,"InpRSIOverbought",(string)InpRSIOverbought);
    FileWrite(f,"InpTrendSLMult",(string)InpTrendSLMult);
    FileWrite(f,"InpTrendTrailingMult",(string)InpTrendTrailingMult);
    FileWrite(f,"InpLateralSLMult",(string)InpLateralSLMult);
    FileWrite(f,"InpLateralTrailingMult",(string)InpLateralTrailingMult);
    FileWrite(f,"InpTrendADXMin",(string)InpTrendADXMin);
    FileWrite(f,"InpLateralADXMax",(string)InpLateralADXMax);
    FileWrite(f,"InpBloquearLateralConADXAlto",(string)InpBloquearLateralConADXAlto);
    FileWrite(f,"InpSRProximityAtrMult",(string)InpSRProximityAtrMult);
    FileWrite(f,"InpUsarFiltroDireccionEMA",(string)InpUsarFiltroDireccionEMA);
    FileWrite(f,"InpOperarRegimenMixto",(string)InpOperarRegimenMixto);
    FileWrite(f,"InpRequireCandleConfirmation",(string)InpRequireCandleConfirmation);
    FileWrite(f,"InpRequireFreshBreakout",(string)InpRequireFreshBreakout);
    FileWrite(f,"InpCooldownMinutes",(string)InpCooldownMinutes);
    FileWrite(f,"InpCooldownOnlyAfterLoss",(string)InpCooldownOnlyAfterLoss);
    FileWrite(f,"InpFailedOrderCooldownSeconds",(string)InpFailedOrderCooldownSeconds);
    FileWrite(f,"InpCooldownMinSeconds",(string)InpCooldownMinSeconds);
    FileWrite(f,"InpUnaEntradaPorVela",(string)InpUnaEntradaPorVela);
    FileWrite(f,"InpPausarTrasRachaPerdidas",(string)InpPausarTrasRachaPerdidas);
    FileWrite(f,"InpLossStreakPauseMinutes",(string)InpLossStreakPauseMinutes);
    FileWrite(f,"InpEmaFastPeriod",(string)InpEmaFastPeriod);
    FileWrite(f,"InpEmaSlowPeriod",(string)InpEmaSlowPeriod);
    FileWrite(f,"InpMinEmaSlopeAtrMult",(string)InpMinEmaSlopeAtrMult);
    FileWrite(f,"InpUsarProteccionIncremental",(string)InpUsarProteccionIncremental);
    FileWrite(f,"InpProteccionEtapa1TriggerR",(string)InpProteccionEtapa1TriggerR);
    FileWrite(f,"InpProteccionEtapa1StopR",(string)InpProteccionEtapa1StopR);
    FileWrite(f,"InpProteccionEtapa2TriggerR",(string)InpProteccionEtapa2TriggerR);
    FileWrite(f,"InpProteccionEtapa2StopR",(string)InpProteccionEtapa2StopR);
    FileWrite(f,"InpProteccionEtapa3TriggerR",(string)InpProteccionEtapa3TriggerR);
    FileWrite(f,"InpProteccionEtapa3StopR",(string)InpProteccionEtapa3StopR);
    FileWrite(f,"InpMoverBreakEvenEn1R",(string)InpMoverBreakEvenEn1R);
    FileWrite(f,"InpBreakEvenTriggerR",(string)InpBreakEvenTriggerR);
    FileWrite(f,"InpBreakEvenTriggerATR",(string)InpBreakEvenTriggerATR);
    FileWrite(f,"InpBreakEvenOffsetPoints",(string)InpBreakEvenOffsetPoints);
    FileWrite(f,"InpUsarTrailingATREnBroker",(string)InpUsarTrailingATREnBroker);
    FileWrite(f,"InpTrailingATRTriggerR",(string)InpTrailingATRTriggerR);
    FileWrite(f,"InpTrailingATRStepR",(string)InpTrailingATRStepR);
    FileWrite(f,"InpMinTrailingStepPoints",(string)InpMinTrailingStepPoints);
    FileWrite(f,"InpTrailingDespuesDeBreakEven",(string)InpTrailingDespuesDeBreakEven);
    FileWrite(f,"InpUsarSmartExit",(string)InpUsarSmartExit);
    FileWrite(f,"InpSmartExitAction",(string)InpSmartExitAction);
    FileWrite(f,"InpSmartExitMinProfitR",(string)InpSmartExitMinProfitR);
    FileWrite(f,"InpSmartExitScoreCerrar",(string)InpSmartExitScoreCerrar);
    FileWrite(f,"InpSmartExitLookbackSR",(string)InpSmartExitLookbackSR);
    FileWrite(f,"InpSmartExitSRProximityATR",(string)InpSmartExitSRProximityATR);
    FileWrite(f,"InpSmartExitAdxDrop",(string)InpSmartExitAdxDrop);
    FileWrite(f,"InpSmartExitAtrContractPct",(string)InpSmartExitAtrContractPct);
    FileWrite(f,"InpSmartExitTightenPoints",(string)InpSmartExitTightenPoints);
    FileWrite(f,"InpMostrarBotonExportCSV",(string)InpMostrarBotonExportCSV);
    FileWrite(f,"InpExportarCSVAlFinalBacktest",(string)InpExportarCSVAlFinalBacktest);
    FileWrite(f,"InpExportCSVPrefix",(string)InpExportCSVPrefix);
    FileWrite(f,"InpExportCSVCommonFiles",(string)InpExportCSVCommonFiles);
    FileWrite(f,"InpExportSubFolder",(string)InpExportSubFolder);
    FileWrite(f,"InpAbrirCarpetaAlExportar",(string)InpAbrirCarpetaAlExportar);
    FileWrite(f,"InpExportLookbackDays",(string)InpExportLookbackDays);
    FileWrite(f,"InpExportButtonX",(string)InpExportButtonX);
    FileWrite(f,"InpExportButtonY",(string)InpExportButtonY);
    FileWrite(f,"InpLogOperacionesAutomatico",(string)InpLogOperacionesAutomatico);
    FileWrite(f,"InpLogOperacionesPrefix",(string)InpLogOperacionesPrefix);
    FileWrite(f,"InpIniciarEntradasPausadas",(string)InpIniciarEntradasPausadas);
    FileWrite(f,"InpEntryButtonX",(string)InpEntryButtonX);
    FileWrite(f,"InpEntryButtonY",(string)InpEntryButtonY);
    FileWrite(f,"InpMaxConsecutiveLosses",(string)InpMaxConsecutiveLosses);
    FileWrite(f,"InpMinLotMultiplier",(string)InpMinLotMultiplier);
    FileWrite(f,"InpLotMultiplierDecay",(string)InpLotMultiplierDecay);
    FileWrite(f,"InpLotMultiplierRecovery",(string)InpLotMultiplierRecovery);
    FileWrite(f,"InpUsarFiltroSpread",(string)InpUsarFiltroSpread);
    FileWrite(f,"InpMaxSpreadPoints",(string)InpMaxSpreadPoints);
    FileWrite(f,"InpTradeDirection",(string)InpTradeDirection);
    FileWrite(f,"InpMinBarsLookback",(string)InpMinBarsLookback);
    FileWrite(f,"InpSupportResistancePeriod",(string)InpSupportResistancePeriod);
    FileWrite(f,"InpATRMediaPeriod",(string)InpATRMediaPeriod);
    FileWrite(f,"InpMagicNumber",(string)InpMagicNumber);
    FileWrite(f,"InpMaxSLPoints",(string)InpMaxSLPoints);
    FileWrite(f,"InpMandatoryTPPoints",(string)InpMandatoryTPPoints);
    FileWrite(f,"InpMandatoryTPAtrMult",(string)InpMandatoryTPAtrMult);
    FileWrite(f,"InpUseSingleInstanceGuard",(string)InpUseSingleInstanceGuard);
    FileWrite(f,"InpInstanceHeartbeatSeconds",(string)InpInstanceHeartbeatSeconds);
    FileWrite(f,"InpInstanceStaleSeconds",(string)InpInstanceStaleSeconds);
    FileWrite(f,"InpProtectionTimerMs",(string)InpProtectionTimerMs);
    FileWrite(f,"symbol",_Symbol);
    FileWrite(f,"period",EnumToString(_Period));
    FileWrite(f,"currency",AccountInfoString(ACCOUNT_CURRENCY));
    FileWrite(f,"tick_size",DxNumber(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)));
    FileWrite(f,"volume_min",DxNumber(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN)));
    FileWrite(f,"volume_step",DxNumber(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP)));
    FileWrite(f,"contract_size",DxNumber(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_CONTRACT_SIZE)));
    FileWrite(f,"terminal_build",TerminalInfoInteger(TERMINAL_BUILD));
    FileClose(f);
}
