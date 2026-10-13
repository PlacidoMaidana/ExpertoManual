# Manual práctico de gestión y parámetros — Gestor Monitor Evolución v0.6

Edición: 22 de septiembre de 2026. Verificado contra los archivos del proyecto. Los valores siguientes son los iniciales del código: un archivo `.set` puede cambiarlos. Este manual explica comportamiento de software; los ejemplos no son un set validado para operar.

## 1. Dónde modificar y guardar la configuración

En el gráfico que contiene el asesor, abre sus propiedades (F7) y la pestaña de parámetros de entrada. Localiza el nombre exacto que aparece en las tablas. Guarda una copia de tu configuración con «Guardar» antes de cambiarla; utiliza «Cargar» para recuperar un `.set`. Guarda por separado cada variante, indicando versión, símbolo y temporalidad. Cambiar parámetros reinicializa el asesor y puede afectar a posiciones abiertas en el siguiente ciclo de gestión.

El monitor no abre entradas: analiza y gestiona posiciones seleccionadas. `ManualEntry`, `ManualStop` y `ManualLots` pertenecen a la calculadora informativa: NO envían ni modifican órdenes. Cambiar `ManualStop` no cambia el SL de una posición.

El último SignalFusion automático con fuente en este proyecto es v0.4, que incluye sus propios módulos v0.4. Comparte nombres como EvoSLATR, EvoRR y EvoTrailingDistanceATR, pero no incorpora automáticamente los botones nuevos del monitor v0.6. Este manual toma v0.6 como referencia; no se deben trasladar todas sus opciones a otras versiones sin comprobarlas.

## 2. Cuatro unidades que no deben confundirse

- **Precio:** una cotización como 4400,00.
- **ATR:** distancia de precio que estima volatilidad. Con ATR=10, 0,5 ATR son 5 unidades de precio. El período se configura con `InpATRPeriod` (14). El monitor usa la temporalidad del gráfico.
- **R:** distancia de riesgo inicial reconocida por el gestor. Entrada 4400 y SL 4380 en BUY → 1R=20 unidades de precio. El gestor conserva esa referencia al acercar el SL; no convierte cada stop nuevo en un R distinto.
- **Puntos:** múltiplos de `_Point` del símbolo. Si `_Point=0,01`, 5 puntos son 0,05 de precio. No son necesariamente 5 pips ni 5 dólares de beneficio. El tick negociable también condiciona el redondeo.

El riesgo monetario depende además del volumen y de las especificaciones del contrato. R en este código representa distancia, no un importe fijo en dinero. Si el gestor encuentra un SL ya protegido y no conoce el riesgo inicial, puede detener la gestión normal con «riesgo inicial desconocido».

## 3. Respuestas rápidas

| Quiero… | Qué modificar | Qué NO hace |
|---|---|---|
| SL inicial más lejano | Aumentar `EvoSLATR` | No aleja un SL existente |
| SL inicial más cercano | Disminuir `EvoSLATR` | No recoloca automáticamente un SL existente |
| TP más lejano por riesgo | `EvoTPMode=EVO_TP_RR`, aumentar `EvoRR` | No reemplaza un TP ya colocado |
| TP independiente del SL | `EvoTPMode=EVO_TP_ATR`, ajustar `EvoTPATR` | EvoRR deja de fijar esa distancia |
| Trailing más cercano | Bajar `EvoTrailingDistanceATR` o botón −0,10 | No garantiza ejecución si bloquean BE/broker |
| Trailing con más espacio | Subirlo o botón +0,10 | No retrocede el SL ya confirmado |
| Trailing que empiece antes | Bajar `EvoTrailingTriggerATR`; revisar `EvoTrailingAfterBE` | Bajar el trigger no elimina el requisito de BE |
| Ajustes del trailing más pequeños/frecuentes | Bajar `EvoTrailingStepPoints` | No cambia la distancia ATR |
| Menos modificaciones pequeñas | Subir `EvoTrailingStepPoints` | No es un temporizador |
| Mover el SL por tramos | Configurar `EvoStage1/2/3TriggerR` y `StopR` | No realiza cierres parciales |

## 4. SL y TP iniciales

| Parámetro | Inicial | Función |
|---|---:|---|
| `EvoSLATR` | 1,5 | Distancia inicial del SL: ATR × multiplicador |
| `EvoSetMissingSL` | true | Intenta poner SL cuando falta |
| `EvoTPMode` | EVO_TP_RR | Selecciona TP por R o por ATR |
| `EvoRR` | 2,0 | TP por riesgo: R × multiplicador |
| `EvoTPATR` | 3,0 | TP por ATR: ATR × multiplicador |
| `EvoSetMissingTP` | true | Intenta poner TP cuando falta |

Con BUY en 4400, ATR=10 y EvoSLATR=1,5, el SL teórico es 4385: distancia 15. En modo RR, EvoRR=2 propone TP 4430. En modo ATR, EvoTPATR=4 propone TP 4440. Para SELL se invierten los signos: SL por encima de entrada y TP por debajo.

En el monitor, estos parámetros completan niveles ausentes; no son controles para recolocar los niveles existentes. El TP normal no sigue al precio. Para editar un SL/TP existente se usa la modificación de la posición en MetaTrader; las protecciones activas del asesor pueden volver a acercar el SL posteriormente. No es necesario quitar un stop para cambiarlo.

En SignalFusion automático v0.4, EvoSLATR y el modo de TP intervienen al preparar nuevas entradas. Su cálculo de lote por riesgo puede cambiar el volumen al variar la distancia del SL. Eso no ocurre en la calculadora ManualLots del monitor.

## 5. Los tres niveles de protección incremental

`EvoIncremental=true` activa el mecanismo. Cada nivel tiene dos números: **TriggerR**, avance favorable desde entrada que lo habilita, y **StopR**, lugar donde propone el stop respecto de entrada, medido en R.

| Nivel | Trigger inicial | Stop inicial | Interpretación |
|---|---:|---:|---|
| 1 | `EvoStage1TriggerR=0,40` | `EvoStage1StopR=-0,15` | Al avanzar 0,40R, reduce pérdida posible a 0,15R |
| 2 | `EvoStage2TriggerR=0,70` | `EvoStage2StopR=0,05` | Al avanzar 0,70R, protege 0,05R antes de costos |
| 3 | `EvoStage3TriggerR=1,00` | `EvoStage3StopR=0,30` | Al avanzar 1R, protege 0,30R antes de costos |

Ejemplo BUY: entrada 4400, SL inicial 4380, R=20.

| Nivel alcanzado | Precio de activación | SL propuesto |
|---|---:|---:|
| 1 | 4408 | 4397 |
| 2 | 4414 | 4401 |
| 3 | 4420 | 4406 |

Ejemplo SELL: entrada 4400, SL inicial 4420, R=20. Los precios de activación son 4392, 4386 y 4380; los stops propuestos son 4403, 4399 y 4394.

Un StopR negativo conserva parte de la pérdida posible; cero corresponde al precio de entrada; positivo propone ganancia bruta. No equivale necesariamente a BE económico después de costos.

Para proteger antes, reduce TriggerR. Para proteger más al activarse, aumenta StopR. Para dejar más espacio, reduce StopR. Ejemplo puramente mecánico: cambiar StopR del nivel 1 de −0,15 a −0,30 deja una pérdida posible de 0,30R en vez de 0,15R.

Los triggers deben ser no negativos y ordenados de menor a mayor. Los StopR deben ser crecientes o iguales y menores que su propio trigger. TriggerR=0 deshabilita ese nivel, no lo activa de inmediato; sigue sujeto a la validación del orden y del StopR. Para desactivar todos, usa EvoIncremental=false.

Si el precio salta varios umbrales, se propone el nivel habilitado más alto. Nunca se vuelve a un stop peor al retroceder el precio. El broker puede impedir una modificación demasiado próxima a la cotización. Otras protecciones pueden imponer un SL aún más cercano.

## 6. Break even automático y botón manual

| Parámetro automático | Inicial | Efecto |
|---|---:|---|
| `EvoBreakEven` | true | Activa BE automático |
| `EvoBETriggerATR` | 1,0 | Avance necesario: ATR × trigger |
| `EvoBEOffsetATR` | 0,0 | Desplazamiento desde entrada a favor: ATR × offset |

Con BUY en 4400 y ATR=10, trigger=1 y offset=0,2, al avanzar hasta 4410 se propone SL 4402. Ese offset no calcula comisiones automáticamente.

El botón **PROTEGER EN BE LO ANTES POSIBLE** ignora el trigger estratégico y queda armado hasta poder ejecutar. Incluye costos estimados según ManualBEIncludeCommission y ManualBEIncludeSwap; ManualBEExtraMoney añade margen en moneda de cuenta por posición. ManualBEExitCommissionPerLot permite indicar comisión de salida por lote; cero estima a partir de entrada. La segunda pulsación cancela pendientes y conserva el stop colocado. La orden manual puede transferir el control de la posición desde otro gráfico a este monitor.

## 7. Trailing: distancia, inicio, paso y frecuencia

Son cuatro controles diferentes:

| Parámetro | Inicial | Qué gobierna |
|---|---:|---|
| `EvoTrailing` | true | Habilitar seguimiento normal |
| `EvoTrailingDistanceATR` | 0,5 | Distancia del SL respecto del precio de cierre actual |
| `EvoTrailingTriggerATR` | 0,0 | Avance desde entrada requerido para iniciar |
| `EvoTrailingAfterBE` | true | Exigir SL ya confirmado al nivel de BE/offset o mejor |
| `EvoTrailingStepPoints` | 5 | Mejora mínima respecto del SL actual; debe superarla |
| `InpProtectionTimerMs` | 250 | Ciclo temporizado de gestión del monitor; también procesa ticks |
| `EvoPanelRefreshMs` | 1000 | Refresco visual, NO velocidad de gestión |

Para BUY: propuesta = Bid − ATR × distancia. Para SELL: propuesta = Ask + ATR × distancia. El trailing normal usa el ATR disponible en cada ciclo, a diferencia de la salida defensiva, que congela el ATR de activación.

Ejemplo BUY: precio actual 4420 y ATR=10. Distancia 0,3 → propuesta 4417; 0,5 → 4415; 1,0 → 4410. **Si el SL ya está en 4416, subir a 1,0 no lo baja a 4410**: conserva 4416 hasta que una nueva propuesta lo mejore.

Con `_Point=0,01`, paso 5 requiere una mejora superior a 0,05 de precio. Paso 20 exige más de 0,20 y omite pequeños avances. Reducir el paso puede aumentar las solicitudes, pero las restricciones del broker y la llegada de cotizaciones siguen vigentes.

Para inicio más temprano, revisa ambos EvoTrailingTriggerATR y EvoTrailingAfterBE. Trigger=0 no fuerza una actuación en pérdida: la gestión normal por reglas retorna sin propuesta si no existe avance favorable. AfterBE=true espera un SL confirmado que cubra entrada más offset, aunque EvoBreakEven esté desactivado; otra protección o intervención puede alcanzar ese nivel. No usa un BE todavía propuesto como si ya estuviera colocado.

El temporizador admite desde 100 ms. Bajarlo de 250 a 100 revisa más a menudo, pero no garantiza ejecución más rápida ni modifica la distancia; también hay gestión en cada tick. FIJAR congela la lectura visual, no la gestión.

Los botones ±0,10 ATR modifican únicamente el trailing normal de esta instancia. El mínimo elegible es 0,10. Restablecer recupera EvoTrailingDistanceATR. Al reinicializar el asesor se pierde el ajuste de sesión y vuelve el valor de entrada.

## 8. Qué mecanismo tiene prioridad

Las protecciones no son fases exclusivas. Los niveles, BE, Smart Exit protector y trailing pueden estar activos juntos. Se conserva la propuesta más protectora; el stop no retrocede. Un cierre total por Smart Exit tiene prioridad sobre las propuestas normales de SL.

**DiagnosticOnly no apaga la gestión normal.** El diagnóstico de modos es distinto de EvoIncremental, EvoBreakEven, EvoTrailing y EvoSmartExit. Para desactivar toda gestión del monitor se usa EvoManagePositions=false; los SL/TP ya alojados en el broker permanecen.

| Parámetro | Inicial | Efecto |
|---|---:|---|
| `EvoSmartExit` | true | Activa evaluación de salida por deterioro |
| `EvoSmartClose` | true | Cierre total; false propone proteger SL |
| `EvoSmartMinProfitR` | 0,70 | Beneficio mínimo en R |
| `EvoSmartScore` | 5 | Puntuación necesaria |
| `EvoSmartLookback` | 50 | Velas para extremos de referencia |
| `EvoSmartSRATR` | 0,25 | Proximidad al extremo en ATR |
| `EvoSmartADXDrop` | 8,0 | Caída ADX que aporta puntuación |
| `EvoSmartATRContract` | 0,75 | Contracción ATR respecto de su referencia |
| `EvoSmartOffsetATR` | 0,0 | Offset de SL si SmartClose=false; también protección por tesis |
| `EvoThesisProtectProfit` | false | Protección adicional por deterioro de tesis |

El score Smart Exit suma: proximidad al extremo 2; vela contraria con cuerpo al menos 55% del rango 3; rechazo del extremo 2; caída ADX 2; contracción ATR 1; RSI extremo 1. No es probabilidad de pérdida. Subir el umbral exige más evidencia; puede volver la condición inalcanzable si se exagera. La protección por tesis exige estado deteriorado y beneficio mínimo, y no implica por sí misma cierre total.

Si amplías el trailing y el stop sigue cerca, revisa primero niveles, BE, protección de tesis y salida defensiva. Si una posición cierra antes del TP, revisa Smart Exit y si alcanzó el SL; el TP no es la única salida.

## 9. Salida en pérdida: otro trailing

Activa seguimiento sobre una posición en pérdida con SL existente. Si hay varias, selecciona la peor por distancia adversa de precio dentro de las posiciones gestionadas. Conserva el ATR al armar y sigue el mejor precio observado desde entonces.

| Parámetro | Inicial | Uso |
|---|---:|---|
| `InpUseLossExitButton` | true | Habilita botón/ejecución |
| `InpLossExitTrailingATRMultiplier` | 1,0 | Distancia defensiva inicial |
| `EvoLossRecoveryATR` | 0,25 | Recuperación desde armado para estrechar seguimiento |
| `EvoLossRecoveredTrailATR` | 0,5 | Distancia tras recuperación; nunca supera la base |
| `InpLossExitStepPoints` | 10 | Mejora mínima requerida |
| `EvoLossContinueAfterRecovery` | true | Continuar aun al volver a beneficio |

No es cierre inmediato, no promete salir sin pérdida y no espera necesariamente BE. Los botones de trailing normal no alteran estos parámetros. Cancelar conserva el último SL. Esta ruta todavía no tiene la prioridad manual entre gráficos añadida al BE: otro gestor puede bloquearla. No confundir «preparada» con «SL confirmado».

## 10. Selección, bloqueos y comprobaciones

EvoManagePositions=true habilita la gestión. InpManageManualOnly=true selecciona posiciones con magic 0 del símbolo del gráfico. Si se cambia a false, usa InpMagicToManage. No equivale a gestionar todas las operaciones de la cuenta.

Ante un SL que no se mueve, comprueba: posición seleccionada; gestión activa; avance/trigger; BE ya confirmado si se exige; mejora mayor que el paso; riesgo inicial conocido; ATR válido; otro gráfico propietario; permisos de trading y conexión; distancias mínimas y congelación del broker. Un TP demasiado próximo también puede bloquear la modificación conjunta SL/TP. Consulta el estado del panel y las pestañas Expertos/Diario. EvoDeviationPoints=20 configura desviación, no distancia del trailing ni un control de frecuencia.

## 11. Cómo probar un cambio sin confundir su efecto

1. Guarda el set actual y anota versión, símbolo, timeframe y valores realmente cargados.
2. En una prueba demo, cambia una familia de parámetros cada vez.
3. Para estudiar niveles, observa sus activaciones sin atribuirles movimientos producidos por otros mecanismos; documenta cuáles están habilitados.
4. Para estudiar trailing, separa distancia, trigger, requisito BE y paso. Anota ATR, SL anterior, propuesta y motivo registrado.
5. Compara operaciones equivalentes y costos. Un stop más cercano reduce espacio disponible, pero puede aumentar salidas por fluctuaciones normales; un stop más amplio no implica mejores resultados.
6. Guarda el nuevo set con otro nombre. Los ejemplos de este manual no han sido optimizados ni validados como estrategia.

## 12. Referencias del proyecto

Reglas verificadas: v0.6/PositionManager.mqh, PositionRules.mqh, TargetRules.mqh, MonitorControls.mqh, ManualBreakEven.mqh, ThesisRules.mqh y archivo principal Gestor Monitor Evolucion v0.6.mq5. Para todos los nombres y valores de entrada, consulta [Inventario v0.6](PARAMETROS-v06-INVENTARIO.md). Las guías antiguas tituladas v0.2 describen aquella versión.
