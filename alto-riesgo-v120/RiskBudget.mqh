// Riesgo previo por operacion, en moneda de cuenta. No limita gaps de ejecucion.
double EntryRiskBudget()
{
    double percentage = AccountInfoDouble(ACCOUNT_EQUITY) * InpRiskPerTradePct / 100.0;
    if(InpRiskBudgetMode == RISK_MONEY) return InpRiskMoney;
    if(InpRiskBudgetMode == RISK_BOTH) return MathMin(percentage, InpRiskMoney);
    return percentage;
}

bool EstimateStopRisk(ENUM_ORDER_TYPE side, double volume, double entry, double sl, double &risk)
{
    risk = 0.0;
    if(volume <= 0 || entry <= 0 || sl <= 0 || !MathIsValidNumber(volume)) return false;
    if((side == ORDER_TYPE_BUY && sl >= entry) || (side == ORDER_TYPE_SELL && sl <= entry)) return false;
    double stressedStop = sl + (side == ORDER_TYPE_BUY ? -1.0 : 1.0)
                              * InpRiskSlippagePoints * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double profit = 0.0;
    if(stressedStop <= 0 || !OrderCalcProfit(side, _Symbol, volume, entry, stressedStop, profit)) return false;
    risk = MathAbs(profit) + volume * InpRiskCostsPerLot;
    return MathIsValidNumber(risk) && risk > 0;
}

void ShowEntryRisk(string state, double volume, double entry, double sl, double risk, double budget)
{
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    string message = StringFormat("SignalFusion v1.20 | Ultima evaluacion %s\n%s\nSL tecnico: %.*f | Distancia: %.*f | Lote: %.8f\nPerdida estimada + provision: %.2f %s (%.2f%%)\nPresupuesto: %.2f %s | Estimacion, no perdida garantizada",
        TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), state, _Digits, sl,
        _Digits, MathAbs(entry-sl), volume, risk, AccountInfoString(ACCOUNT_CURRENCY),
        equity > 0 ? risk/equity*100.0 : 0.0, budget, AccountInfoString(ACCOUNT_CURRENCY));
    Comment("\n\n\n\n\n\n", message); // Espacio para los botones existentes.
    Print(message);
}

double RejectRiskCalculation(string reason)
{
    Comment("\n\n\n\n\n\nSignalFusion v1.20 | BLOQUEADA: ", reason);
    Print("SignalFusion v1.20 | BLOQUEADA: ", reason);
    return 0.0;
}

double CalculateBudgetLots(ENUM_ORDER_TYPE side, double entry, double sl)
{
    double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    double brokerMin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double budget = EntryRiskBudget();
    if(step <= 0 || brokerMin <= 0 || maxLot < brokerMin || budget <= 0)
        return RejectRiskCalculation("presupuesto o especificaciones de volumen invalidos");
    double minLot = NormalizeDouble(MathCeil(MathMax(brokerMin, InpLotMin)/step-1e-9)*step, 8);
    double minimumRisk = 0;
    if(minLot > maxLot || !EstimateStopRisk(side,minLot,entry,sl,minimumRisk))
        return RejectRiskCalculation("no se pudo valorar el SL con el volumen minimo");
    if(minimumRisk > budget)
    {
        ShowEntryRisk("BLOQUEADA: lote minimo excede presupuesto",minLot,entry,sl,minimumRisk,budget);
        return 0;
    }
    double requested = InpModoLote == LOT_FIJO ? InpLoteFijo : budget / minimumRisk * minLot;
    requested *= MathMin(1.0, MathMax(0.0, g_lotMultiplier));
    double lots = NormalizeDouble(MathFloor(MathMin(requested,maxLot)/step+1e-9)*step,8);
    if(lots < minLot)
    {
        ShowEntryRisk("BLOQUEADA: volumen solicitado/reducido menor al minimo",minLot,entry,sl,minimumRisk,budget);
        return 0;
    }
    double risk = 0;
    if(!EstimateStopRisk(side,lots,entry,sl,risk)) return RejectRiskCalculation("fallo al estimar perdida del lote");
    if(risk > budget && InpModoLote == LOT_RIESGO_PORCENTAJE)
    {
        lots = NormalizeDouble(lots-step,8);
        if(lots < minLot || !EstimateStopRisk(side,lots,entry,sl,risk))
            return RejectRiskCalculation("redondeo de volumen no compatible con presupuesto");
    }
    ShowEntryRisk(risk > budget ? "BLOQUEADA: lote fijo excede presupuesto" : "RIESGO APROBADO: pendiente de margen y ejecucion",
                  lots,entry,sl,risk,budget);
    return risk > budget ? 0 : lots;
}

bool CheckFinalEntryRisk(ENUM_ORDER_TYPE side, double lots, double sl, double tp)
{
    MqlTick tick;
    if(!SymbolInfoTick(_Symbol,tick)) { RejectRiskCalculation("cotizacion final no disponible"); return false; }
    double entry = side == ORDER_TYPE_BUY ? tick.ask : tick.bid;
    double risk = 0, budget = EntryRiskBudget();
    if(!EstimateStopRisk(side,lots,entry,sl,risk)) { RejectRiskCalculation("no se pudo verificar riesgo final"); return false; }
    double reward = side == ORDER_TYPE_BUY ? tp-entry : entry-tp;
    double distance = MathAbs(entry-sl);
    bool valid = budget > 0 && risk <= budget && reward > 0 && distance > 0;
    if(InpCancelarSiRRInvalido && distance > 0 && reward/distance < InpMinRRPermitido) valid = false;
    ShowEntryRisk(valid ? "RIESGO APROBADO: envio de orden" : "BLOQUEADA: riesgo o RR cambio antes del envio",
                  lots,entry,sl,risk,budget);
    return valid;
}
