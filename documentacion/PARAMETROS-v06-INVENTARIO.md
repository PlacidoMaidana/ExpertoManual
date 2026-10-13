# Inventario de parámetros — Monitor v0.6

Extraído del código el 22/09/2026. Valores iniciales, no valores del gráfico ni de un set. Consulte el [manual práctico](MANUAL-GESTION-PARAMETROS-v06.md) para interpretar gestión, unidades y prioridades.

| Parámetro | Inicial | Grupo | Nota del código | Fuente |
|---|---|---|---|---|
| `InpModoEntrada` | `ENTRADA_FLEXIBLE` | Analisis compartido SignalFusion / Monitor | Acceso activo al mercado con filtros minimos | `v0.6\SignalAnalysisInputs.mqh` |
| `InpATRPeriod` | `14` | Analisis compartido SignalFusion / Monitor | Período ATR | `v0.6\SignalAnalysisInputs.mqh` |
| `InpRequireADX` | `true` | Analisis compartido SignalFusion / Monitor | Requerir ADX > umbral | `v0.6\SignalAnalysisInputs.mqh` |
| `InpMinADX` | `15.0` | Analisis compartido SignalFusion / Monitor | ADX mínimo (AGRESIVO: 15 / moderado sugerido: 18) | `v0.6\SignalAnalysisInputs.mqh` |
| `InpADXPeriod` | `14` | Analisis compartido SignalFusion / Monitor | Período ADX | `v0.6\SignalAnalysisInputs.mqh` |
| `InpRSIPeriod` | `14` | Analisis compartido SignalFusion / Monitor | Período RSI | `v0.6\SignalAnalysisInputs.mqh` |
| `InpRSIOversold` | `45.0` | Analisis compartido SignalFusion / Monitor | RSI sobreventa (AGRESIVO: 45 / moderado sugerido: 42 / orig: 30) | `v0.6\SignalAnalysisInputs.mqh` |
| `InpRSIOverbought` | `55.0` | Analisis compartido SignalFusion / Monitor | RSI sobrecompra (AGRESIVO: 55 / moderado sugerido: 58 / orig: 70) | `v0.6\SignalAnalysisInputs.mqh` |
| `InpTrendADXMin` | `25.0` | Analisis compartido SignalFusion / Monitor | ADX mínimo para declarar tendencia fuerte | `v0.6\SignalAnalysisInputs.mqh` |
| `InpLateralADXMax` | `24.0` | Analisis compartido SignalFusion / Monitor | Si ADX supera este valor, NO operar reversión lateral | `v0.6\SignalAnalysisInputs.mqh` |
| `InpBloquearLateralConADXAlto` | `true` | Analisis compartido SignalFusion / Monitor | Evita compras/ventas contra tendencia fuerte | `v0.6\SignalAnalysisInputs.mqh` |
| `InpSRProximityAtrMult` | `0.35` | Analisis compartido SignalFusion / Monitor | Cercanía real a soporte/resistencia en múltiplos de ATR | `v0.6\SignalAnalysisInputs.mqh` |
| `InpUsarFiltroDireccionEMA` | `true` | Analisis compartido SignalFusion / Monitor | Bloquear compras si sesgo bajista y ventas si sesgo alcista | `v0.6\SignalAnalysisInputs.mqh` |
| `InpOperarRegimenMixto` | `false` | Analisis compartido SignalFusion / Monitor | EXP-4.0: permitir nuevas entradas cuando el regimen es MIXTO (ADX debil y ATR no contraido) | `v0.6\SignalAnalysisInputs.mqh` |
| `InpRequireCandleConfirmation` | `true` | Analisis compartido SignalFusion / Monitor | Exigir vela CERRADA para señales (no precio en vivo) | `v0.6\SignalAnalysisInputs.mqh` |
| `InpRequireFreshBreakout` | `false` | Analisis compartido SignalFusion / Monitor | Exigir ruptura "fresca" (AGRESIVO: false=desactivado / moderado sugerido: true) | `v0.6\SignalAnalysisInputs.mqh` |
| `InpEmaFastPeriod` | `20` | Analisis compartido SignalFusion / Monitor | EMA rápida para confirmar dirección | `v0.6\SignalAnalysisInputs.mqh` |
| `InpEmaSlowPeriod` | `50` | Analisis compartido SignalFusion / Monitor | EMA lenta para confirmar dirección | `v0.6\SignalAnalysisInputs.mqh` |
| `InpMinEmaSlopeAtrMult` | `2.0` | Analisis compartido SignalFusion / Monitor | Pendiente mínima de EMA rápida en múltiplos de ATR | `v0.6\SignalAnalysisInputs.mqh` |
| `InpTradeDirection` | `"both"` | Analisis compartido SignalFusion / Monitor | Dirección de trading (both/buy/sell) | `v0.6\SignalAnalysisInputs.mqh` |
| `InpSupportResistancePeriod` | `12` | Analisis compartido SignalFusion / Monitor | Período para S/R (AGRESIVO: 12 / moderado sugerido: 16 / antes 20) | `v0.6\SignalAnalysisInputs.mqh` |
| `InpATRMediaPeriod` | `50` | Analisis compartido SignalFusion / Monitor | Período para ATR promedio | `v0.6\SignalAnalysisInputs.mqh` |
| `EvoCandidateScoreMin` | `55` | Tablero de decision v0.6 | score minimo para modo *_CANDIDATE | `v0.6\DecisionScores.mqh` |
| `EvoCommitScoreMin` | `72` | Tablero de decision v0.6 | score minimo para modo comprometido | `v0.6\DecisionScores.mqh` |
| `EvoScoreBarWidth` | `10` | Tablero de decision v0.6 | ancho visual de barras en panel | `v0.6\DecisionScores.mqh` |
| `EvoWriteTradeDataset` | `true` | Dataset experimental v0.5 |  | `v0.6\TradeDataset.mqh` |
| `EvoDatasetCommon` | `true` | Dataset experimental v0.5 |  | `v0.6\TradeDataset.mqh` |
| `EvoDiagnosticOnly` | `true` | Dataset experimental v0.5 | true: modos adaptativos solo registran; no cierran ni mueven SL/TP por modo | `v0.6\TradeDataset.mqh` |
| `EvoTacticalERMax` | `0.30` | Dataset experimental v0.5 | ER bajo => captura tactica | `v0.6\TradeDataset.mqh` |
| `EvoExtensionERMin` | `0.60` | Dataset experimental v0.5 | ER alto => extension | `v0.6\TradeDataset.mqh` |
| `EvoTacticalMfeArmATR` | `0.40` | Dataset experimental v0.5 | umbral diagnostico MFE para WOULD_ACTIVATE táctico | `v0.6\TradeDataset.mqh` |
| `EvoProtectionMinR` | `0.50` | Dataset experimental v0.5 | umbral diagnostico de beneficio en R | `v0.6\TradeDataset.mqh` |
| `EvoShowSRLines` | `true` | Contexto visual del monitor | Lineas de los niveles cercanos, independientes del panel | `v0.6\MonitorLevels.mqh` |
| `InpMonitorSRLookback` | `100` | Contexto visual del monitor |  | `v0.6\MonitorLevels.mqh` |
| `InpMonitorSRPivotBars` | `2` | Contexto visual del monitor |  | `v0.6\MonitorLevels.mqh` |
| `InpMonitorLateralADXMax` | `20.0` | Contexto visual del monitor |  | `v0.6\MonitorLevels.mqh` |
| `EvoBBPeriod` | `20` | Bollinger compartido |  | `v0.6\SignalAnalysis.mqh` |
| `EvoBBDeviation` | `2.0` | Bollinger compartido |  | `v0.6\SignalAnalysis.mqh` |
| `EvoUseBBFilter` | `false` | Bollinger compartido | false: contexto; true: confirmacion adicional por regimen | `v0.6\SignalAnalysis.mqh` |
| `EvoOBVVolume` | `VOLUME_TICK` | OBV compartido | Seleccion explicita; sin sustituir real por ticks | `v0.6\SignalAnalysis.mqh` |
| `EvoOBVLookback` | `5` | OBV compartido | Cambio entre cierres, no periodo de suavizado | `v0.6\SignalAnalysis.mqh` |
| `EvoUseOBVFilter` | `false` | OBV compartido | Confirmacion adicional; nunca genera entradas | `v0.6\SignalAnalysis.mqh` |
| `EvoERPeriod` | `14` | ER compartido |  | `v0.6\SignalAnalysis.mqh` |
| `EvoDeltaBars` | `5` | ER compartido |  | `v0.6\SignalAnalysis.mqh` |
| `EvoUseERFilter` | `false` | ER compartido | Filtro opcional de entrada automatica | `v0.6\SignalAnalysis.mqh` |
| `EvoMinER` | `0.30` | ER compartido |  | `v0.6\SignalAnalysis.mqh` |
| `EvoRegimeLookback` | `8` | Regimen local - contexto | Velas cerradas para compresion/desplazamiento | `v0.6\SignalAnalysis.mqh` |
| `EvoCompressionMaxATR` | `1.20` | Regimen local - contexto | HH-LL/ATR bajo este umbral = rango comprimido | `v0.6\SignalAnalysis.mqh` |
| `EvoDisplacementMaxATR` | `0.45` | Regimen local - contexto | /C_t-C_t-n//ATR bajo este umbral = poco avance neto | `v0.6\SignalAnalysis.mqh` |
| `EvoMinRoomATR` | `0.60` | Regimen local - contexto | Espacio al obstaculo para cautela compartida | `v0.6\SignalAnalysis.mqh` |
| `EvoCautionOnConsolidation` | `true` | Regimen local - contexto | true: esperar y bloquear entrada automatica v0.4 mientras haya cautela | `v0.6\SignalAnalysis.mqh` |
| `EvoTrackThesis` | `true` | Seguimiento de tesis - contexto cerrado |  | `v0.6\ThesisTracker.mqh` |
| `EvoThesisADXDrop` | `5.0` | Seguimiento de tesis - contexto cerrado |  | `v0.6\ThesisTracker.mqh` |
| `EvoThesisERDrop` | `0.15` | Seguimiento de tesis - contexto cerrado |  | `v0.6\ThesisTracker.mqh` |
| `EvoThesisConfirmBars` | `2` | Seguimiento de tesis - contexto cerrado |  | `v0.6\ThesisTracker.mqh` |
| `EvoThesisProtectProfit` | `false` | Seguimiento de tesis - contexto cerrado | Proteccion adicional opcional, nunca cierre por diagnostico | `v0.6\ThesisTracker.mqh` |
| `EvoWriteJournal` | `true` | Registro comun Evolucion |  | `v0.6\EvolutionJournal.mqh` |
| `EvoJournalCommon` | `true` | Registro comun Evolucion |  | `v0.6\EvolutionJournal.mqh` |
| `EvoSLATR` | `1.5` | Gestion compartida - SL / TP |  | `v0.6\PositionManager.mqh` |
| `EvoRR` | `2.0` | Gestion compartida - SL / TP |  | `v0.6\PositionManager.mqh` |
| `EvoTPMode` | `EVO_TP_RR` | Gestion compartida - SL / TP |  | `v0.6\PositionManager.mqh` |
| `EvoTPATR` | `3.0` | Gestion compartida - SL / TP | Distancia TP independiente del SL cuando el modo es ATR | `v0.6\PositionManager.mqh` |
| `EvoSetMissingSL` | `true` | Gestion compartida - SL / TP |  | `v0.6\PositionManager.mqh` |
| `EvoSetMissingTP` | `true` | Gestion compartida - SL / TP |  | `v0.6\PositionManager.mqh` |
| `EvoIncremental` | `true` | Gestion compartida - Proteccion incremental |  | `v0.6\PositionManager.mqh` |
| `EvoStage1TriggerR` | `0.40` | Gestion compartida - Proteccion incremental |  | `v0.6\PositionManager.mqh` |
| `EvoStage1StopR` | `-0.15` | Gestion compartida - Proteccion incremental |  | `v0.6\PositionManager.mqh` |
| `EvoStage2TriggerR` | `0.70` | Gestion compartida - Proteccion incremental |  | `v0.6\PositionManager.mqh` |
| `EvoStage2StopR` | `0.05` | Gestion compartida - Proteccion incremental |  | `v0.6\PositionManager.mqh` |
| `EvoStage3TriggerR` | `1.00` | Gestion compartida - Proteccion incremental |  | `v0.6\PositionManager.mqh` |
| `EvoStage3StopR` | `0.30` | Gestion compartida - Proteccion incremental |  | `v0.6\PositionManager.mqh` |
| `EvoBreakEven` | `true` | Gestion compartida - BE y trailing |  | `v0.6\PositionManager.mqh` |
| `EvoBETriggerATR` | `1.0` | Gestion compartida - BE y trailing |  | `v0.6\PositionManager.mqh` |
| `EvoBEOffsetATR` | `0.0` | Gestion compartida - BE y trailing |  | `v0.6\PositionManager.mqh` |
| `EvoTrailing` | `true` | Gestion compartida - BE y trailing |  | `v0.6\PositionManager.mqh` |
| `EvoTrailingAfterBE` | `true` | Gestion compartida - BE y trailing |  | `v0.6\PositionManager.mqh` |
| `EvoTrailingTriggerATR` | `0.0` | Gestion compartida - BE y trailing |  | `v0.6\PositionManager.mqh` |
| `EvoTrailingDistanceATR` | `0.5` | Gestion compartida - BE y trailing |  | `v0.6\PositionManager.mqh` |
| `EvoTrailingStepPoints` | `5` | Gestion compartida - BE y trailing |  | `v0.6\PositionManager.mqh` |
| `EvoSmartExit` | `true` | Gestion compartida - Smart Exit |  | `v0.6\PositionManager.mqh` |
| `EvoSmartClose` | `true` | Gestion compartida - Smart Exit | false: proteger SL | `v0.6\PositionManager.mqh` |
| `EvoSmartMinProfitR` | `0.70` | Gestion compartida - Smart Exit |  | `v0.6\PositionManager.mqh` |
| `EvoSmartScore` | `5` | Gestion compartida - Smart Exit |  | `v0.6\PositionManager.mqh` |
| `EvoSmartLookback` | `50` | Gestion compartida - Smart Exit |  | `v0.6\PositionManager.mqh` |
| `EvoSmartSRATR` | `0.25` | Gestion compartida - Smart Exit |  | `v0.6\PositionManager.mqh` |
| `EvoSmartADXDrop` | `8.0` | Gestion compartida - Smart Exit |  | `v0.6\PositionManager.mqh` |
| `EvoSmartATRContract` | `0.75` | Gestion compartida - Smart Exit |  | `v0.6\PositionManager.mqh` |
| `EvoSmartOffsetATR` | `0.0` | Gestion compartida - Smart Exit |  | `v0.6\PositionManager.mqh` |
| `EvoDeviationPoints` | `20` | Gestion compartida - Smart Exit |  | `v0.6\PositionManager.mqh` |
| `EvoAlertsEnabled` | `true` | Alertas de mercado - velas cerradas |  | `v0.6\MarketAlerts.mqh` |
| `EvoAlertRSI30` | `true` | Alertas de mercado - velas cerradas |  | `v0.6\MarketAlerts.mqh` |
| `EvoAlertRSI70` | `true` | Alertas de mercado - velas cerradas |  | `v0.6\MarketAlerts.mqh` |
| `EvoAlertADX25` | `true` | Alertas de mercado - velas cerradas |  | `v0.6\MarketAlerts.mqh` |
| `EvoAlertSuggestion` | `true` | Alertas de mercado - velas cerradas |  | `v0.6\MarketAlerts.mqh` |
| `EvoAlertSemantic` | `true` | Alertas de mercado - velas cerradas | regimen / gestion / scores (transiciones) | `v0.6\MarketAlerts.mqh` |
| `EvoAlertCooldownBars` | `1` | Alertas de mercado - velas cerradas | minimo de velas entre alertas semanticas | `v0.6\MarketAlerts.mqh` |
| `EvoAlertPopup` | `true` | Alertas de mercado - velas cerradas |  | `v0.6\MarketAlerts.mqh` |
| `EvoAlertSound` | `false` | Alertas de mercado - velas cerradas | Sonido adicional a la ventana de MetaTrader | `v0.6\MarketAlerts.mqh` |
| `EvoShowContext` | `true` | Panel de contexto compartido |  | `v0.6\ContextPanel.mqh` |
| `EvoPanelX` | `350` | Panel de contexto compartido |  | `v0.6\ContextPanel.mqh` |
| `EvoPanelY` | `20` | Panel de contexto compartido |  | `v0.6\ContextPanel.mqh` |
| `EvoPanelFont` | `9` | Panel de contexto compartido |  | `v0.6\ContextPanel.mqh` |
| `EvoPanelRefreshMs` | `1000` | Panel de contexto compartido | Solo dibujo; no cambia el ciclo de proteccion | `v0.6\ContextPanel.mqh` |
| `EvoManagePositions` | `true` | Posiciones del monitor |  | `Gestor Monitor Evolucion v0.6.mq5` |
| `InpManageManualOnly` | `true` | Posiciones del monitor |  | `Gestor Monitor Evolucion v0.6.mq5` |
| `InpMagicToManage` | `0` | Posiciones del monitor | Usado solo si manual-only es false | `Gestor Monitor Evolucion v0.6.mq5` |
| `InpProtectionTimerMs` | `250` | Posiciones del monitor |  | `Gestor Monitor Evolucion v0.6.mq5` |
| `ManualBuy` | `true` | Simulacion manual - no envia ordenes |  | `Gestor Monitor Evolucion v0.6.mq5` |
| `ManualEntry` | `0.0` | Simulacion manual - no envia ordenes | 0: ask BUY / bid SELL actual | `Gestor Monitor Evolucion v0.6.mq5` |
| `ManualStop` | `0.0` | Simulacion manual - no envia ordenes | Precio tecnico elegido por el operador | `Gestor Monitor Evolucion v0.6.mq5` |
| `ManualLots` | `0.01` | Simulacion manual - no envia ordenes |  | `Gestor Monitor Evolucion v0.6.mq5` |
| `InpRiskPerTradePct` | `1.0` | Simulacion manual - no envia ordenes | Referencia informativa del limite del EA | `Gestor Monitor Evolucion v0.6.mq5` |
| `InpShowBreakEvenJumpButton` | `true` | Botones manuales del monitor |  | `v0.6\MonitorControls.mqh` |
| `InpUseLossExitButton` | `true` | Botones manuales del monitor |  | `v0.6\MonitorControls.mqh` |
| `InpLossExitTrailingATRMultiplier` | `1.0` | Botones manuales del monitor |  | `v0.6\MonitorControls.mqh` |
| `InpLossExitStepPoints` | `10` | Botones manuales del monitor |  | `v0.6\MonitorControls.mqh` |
| `EvoLossRecoveryATR` | `0.25` | Botones manuales del monitor | Rebote desde armado para usar distancia mas corta | `v0.6\MonitorControls.mqh` |
| `EvoLossRecoveredTrailATR` | `0.5` | Botones manuales del monitor |  | `v0.6\MonitorControls.mqh` |
| `EvoLossContinueAfterRecovery` | `true` | Botones manuales del monitor |  | `v0.6\MonitorControls.mqh` |
| `ManualBEIncludeCommission` | `true` | BE manual anticipado - costos estimados |  | `v0.6\ManualBreakEven.mqh` |
| `ManualBEIncludeSwap` | `true` | BE manual anticipado - costos estimados |  | `v0.6\ManualBreakEven.mqh` |
| `ManualBEExtraMoney` | `0.0` | BE manual anticipado - costos estimados | Margen en moneda de cuenta, por posicion | `v0.6\ManualBreakEven.mqh` |
| `ManualBEExitCommissionPerLot` | `0.0` | BE manual anticipado - costos estimados | 0: estimar con comision de entrada por lote | `v0.6\ManualBreakEven.mqh` |
