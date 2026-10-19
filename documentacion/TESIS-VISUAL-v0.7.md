# Salud de posición visual — TESIS v0.7

La v0.7 incorpora tarjetas y bloques visuales. La v0.6 conserva el panel anterior. No cambia el seguimiento de tesis, archivos binarios de referencia, reglas de invalidación, cálculo MFE/MAE ni protecciones.

## Lectura

Cabecera: ticket, BUY/SELL, posición seleccionada, salud, apoyos perdidos y fecha de referencia frente a la vela cerrada evaluada. El tooltip conserva la distinción entre referencia posterior a entrada y detección de entrada. La hora de la vela es su apertura, no la hora exacta de evaluación.

Indicadores: ADX, ER y RSI muestran Referencia -> Ahora, diferencia y barra del valor actual. ADX 0-50, ER 0-1, RSI 0-100 con marcas 30/50/70. OBV conserva comparación de dirección y semáforo, sin fabricar un valor numérico histórico que no estaba guardado. ROC y MACD muestran solo Ahora, explícitamente: no hay referencia histórica almacenada. ROC barra centrada ±3 ATR; MACD histograma con señal EMA9, semáforo según magnitud/ATR e intensidad 0-0,20 ATR. Se exige que la lectura cerrada de momentum corresponda a la vela de evaluación; de lo contrario se muestra N/D.

Colores respecto a la posición: verde a favor, rojo en contra, amarillo neutral/sin datos. Una dirección bajista favorece a SELL. MEJORÓ/EMPEORÓ en filas direccionales describe cambio de apoyo respecto al lado de la posición, sin sustituir las reglas de salud. ADX y ER no tienen dirección; un aumento solo se destaca favorable cuando DI acompaña. El cambio RSI muestra desplazamiento relativo a BUY/SELL, no garantiza continuidad.

Dirección y medias: DI, precio respecto a EMA50 y EMA200, con comparación completa. No se confunde posición respecto a la media con pendiente.

Multi-temporal: M15, H1 y H4 tienen una línea propia con Referencia -> Ahora y cambio de apoyo. No se colapsan.

Rendimiento: MFE/MAE desde primera observación, P/L flotante más swap sin comisiones. GESTIÓN recibe una banda destacada y conserva SOLO DIAGNÓSTICO cuando corresponde. No es un botón de ejecución.

Detalle inferior: espacio al obstáculo con ATR de cada lectura, guardado de referencia, lectura MACD/ROC respecto a posición, regla completa de invalidación, número de cierres de confirmación, protección extra y confirmación estructural con tooltip. SIGUIENTE permite recorrer posiciones.

Si la posición cambió de firma o faltan datos actuales se marca NO EVALUABLE / SIN DATOS, sin presentar sus indicadores anteriores como actuales. Las referencias persistentes no se reinician al cambiar la presentación.

Validación: compilación y pruebas de reglas de tesis, escalas y simetría de colores BUY/SELL. Presentación visual en MetaTrader pendiente de verificación.
