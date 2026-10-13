# Comparación de diez presets v1.20

## Interpretación

Los diez tests corresponden a XAUUSD M15, MetaQuotes-Demo, v1.20 y periodo 1 de abril a 20 de septiembre, según el Diario del Tester del 6 de octubre. El control reproduce los 387 registros de posiciones de la referencia a nivel de ejecuciones numéricas y saldo 129,49 USD.

La primera candidata para validación es 01_Sin_entradas_tendencia: +84 USD, 326 operaciones, PF 1,122 y drawdown de saldo 34,69%. Su mejora contra control es 154,51 USD. Sigue activa hasta el 18 de septiembre. No es robusta todavía: agosto/septiembre suman -64,26 USD; sin mayo, el neto total queda en +12,61 USD. No proponer aumentar capital/riesgo a partir de esta selección.

07_Sin_etapa_2 tiene +55,63 USD y menor DD registrado, pero su último cierre es el 10 de julio; junio, agosto y septiembre no aportan resultado realizado. La menor exposición impide tratar su aparente estabilidad como evidencia suficiente. Investigar bloqueos y estados antes de seleccionarla; no se certifica aquí la causa exacta de la inactividad.

09_Etapas_mas_tardias gana 33,04 USD con PF 1,032, pero pierde en julio/agosto/septiembre y deja poco margen. No combina automáticamente con 01: las interacciones deben probarse separadamente.

Ampliar el stop inicial a 1,75 ATR empeora el resultado. SL 2 ATR y trailing 1 ATR tienen solo 20 y 15 operaciones, respectivamente. Un neto menos negativo debido a muy poca actividad no demuestra una mejora operativa. Trailing 0,75 ATR también pierde y no supera al control en resultado neto.

Quitar etapa 1 mejora el neto respecto al control, pero sigue perdiendo y el DD de saldo no mejora. Quitar etapa 3 produce los mismos totales mensuales y saldo que el control; esto no demuestra que nunca sea útil fuera de este periodo ni atribuye causalidad sin revisar cada cambio de stop.

## Próximo paso concreto

Congelar 01_Sin_entradas_tendencia y contrastarla con 00_Control en un periodo anterior no usado para estas decisiones, por ejemplo 1 de enero a 1 de abril de 2026 si el servidor tiene ticks reales completos. Mantener XAUUSD M15, 200 USD, 1:200 y presupuesto 10 USD. No optimizar en ese periodo. Después revisar ambos resultados, continuidad de actividad, calidad de datos y costes antes de decidir combinaciones. Esta es una propuesta de validación, no una nueva prueba ya realizada.

Control: historial de ejecuciones igual a v1.19 excluyendo identificador de ejecución y comentarios: True. Comparación numérica de todas las ejecuciones, no solo saldo. Los diez presets coinciden con sus parámetros guardados y concilian saldo/historial. Se excluye la prueba EURUSD anterior.

| Preset | Ops | Neto USD | Final USD | PF | DD saldo % | Último cierre |
|---|---:|---:|---:|---:|---:|---|
| 00_Control | 387 | -70.51 | 129.49 | 0.92 | 56.15 | 2026-09-07 |
| 01_Sin_entradas_tendencia | 326 | 84.00 | 284.00 | 1.122 | 34.69 | 2026-09-18 |
| 02_SL_ATR_175 | 229 | -90.07 | 109.93 | 0.849 | 62.52 | 2026-09-16 |
| 03_SL_ATR_200 | 20 | -20.00 | 180.00 | 0.71 | 20.83 | 2026-07-10 |
| 04_Trailing_ATR_075 | 173 | -81.74 | 118.26 | 0.816 | 47.51 | 2026-09-17 |
| 05_Trailing_ATR_100 | 15 | -13.28 | 186.72 | 0.674 | 17.81 | 2026-07-10 |
| 06_Sin_etapa_1 | 490 | -46.22 | 153.78 | 0.964 | 56.44 | 2026-09-18 |
| 07_Sin_etapa_2 | 110 | 55.63 | 255.63 | 1.202 | 19.12 | 2026-07-10 |
| 08_Sin_etapa_3 | 387 | -70.51 | 129.49 | 0.92 | 56.15 | 2026-09-07 |
| 09_Etapas_mas_tardias | 391 | 33.04 | 233.04 | 1.032 | 34.27 | 2026-09-07 |

## Distribución mensual (resultado realizado)

| Preset | Abril | Mayo | Junio | Julio | Agosto | Septiembre |
|---|---:|---:|---:|---:|---:|---:|
| 00_Control | 6.10 | 39.62 | -18.49 | -35.24 | -35.50 | -27.00 |
| 01_Sin_entradas_tendencia | 9.72 | 71.39 | 34.66 | 32.49 | -29.50 | -34.76 |
| 02_SL_ATR_175 | 6.56 | 16.66 | -23.94 | -27.00 | -40.66 | -21.69 |
| 03_SL_ATR_200 | 18.01 | -19.91 | -15.96 | -2.14 | 0.00 | 0.00 |
| 04_Trailing_ATR_075 | -14.88 | -5.31 | -22.74 | -0.87 | 0.82 | -38.76 |
| 05_Trailing_ATR_100 | -12.99 | -0.27 | 0.00 | -0.02 | 0.00 | 0.00 |
| 06_Sin_etapa_1 | -80.65 | 55.18 | 9.95 | 21.91 | -83.86 | 31.25 |
| 07_Sin_etapa_2 | 38.25 | 18.97 | 0.00 | -1.59 | 0.00 | 0.00 |
| 08_Sin_etapa_3 | 6.10 | 39.62 | -18.49 | -35.24 | -35.50 | -27.00 |
| 09_Etapas_mas_tardias | 50.29 | 42.04 | 1.39 | -20.30 | -13.42 | -26.96 |

El DD aquí es de saldo, no equity flotante. Las variantes con pocos cierres o último cierre temprano no demuestran estabilidad por quedarse inactivas. La batería usa datos ya utilizados para diseñar cambios; no es validación fuera de muestra. Los parámetros de presupuesto y recuperación de volumen se conservaron.
