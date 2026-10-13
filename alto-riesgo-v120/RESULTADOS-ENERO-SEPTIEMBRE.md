# Prueba continua enero–septiembre 2026 — v1.20

Periodo solicitado: 1 de enero al 20 de septiembre. Depósito único: 200 USD. XAUUSD M15. Ambos historiales concilian con los CSV entregados y los diagnósticos finales. Los parámetros del asesor solo difieren en habilitar tendencia y prefijos de salida. Ambas ejecuciones usan terminal build 6246. El Diario confirma MetaQuotes-Demo y el periodo 01/01/2026–20/09/2026.

| Preset | Operaciones | Neto USD | Saldo final USD | PF | DD saldo % | Aciertos % | Peor operación USD | Último cierre |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| 00_Control | 549 | -97.59 | 102.41 | 0.922 | 61.95 | 56.65 | -17.04 | 2026-09-07 |
| 01_Sin_entradas_tendencia | 411 | 119.05 | 319.05 | 1.138 | 31.92 | 61.80 | -12.07 | 2026-09-18 |

| Mes | Control USD | Sin tendencia USD | Cierres control | Cierres sin tendencia |
|---|---:|---:|---:|---:|
| 01/2026 | -10.12 | 62.29 | 123 | 62 |
| 02/2026 | -9.19 | -21.99 | 21 | 11 |
| 03/2026 | -7.77 | -5.25 | 18 | 12 |
| 04/2026 | 6.10 | 9.72 | 73 | 49 |
| 05/2026 | 39.62 | 71.39 | 80 | 47 |
| 06/2026 | -18.49 | 34.66 | 78 | 40 |
| 07/2026 | -35.24 | 32.49 | 56 | 102 |
| 08/2026 | -35.50 | -29.50 | 88 | 51 |
| 09/2026 | -27.00 | -34.76 | 12 | 37 |

## Alcance y siguiente paso

Esta prueba verifica continuidad de capital y estado; reutiliza periodos ya analizados y no constituye una nueva validación independiente. DD calculado con todas las ejecuciones: saldo, no equity flotante. No sumar ni agregar estas operaciones a los tests parciales superpuestos.


Mantener congelado el preset 01. No combinar cambios adicionales a partir de esta prueba. El siguiente contraste independiente puede ser una prueba forward demo con ese mismo preset y parámetros, registrando operaciones y costes.


Costes registrados, 00_Control: {'comision': 0.0, 'swap': -0.18, 'fee': 0.0}. No extrapolar a otro servidor sin comprobar sus costes.

Costes registrados, 01_Sin_entradas_tendencia: {'comision': 0.0, 'swap': -0.05, 'fee': 0.0}. No extrapolar a otro servidor sin comprobar sus costes.

## Verificación final de los informes HTML

Ambos informes coinciden con el neto y parámetros de los diagnósticos. MetaQuotes-Demo build 6246, depósito 200 USD y apalancamiento 1:200. Ambos declaran 100% ticks reales y 116.404.521 ticks. Esta calidad es la declarada por el Tester; no acredita condiciones futuras de ejecución.

| Preset | DD equity relativo | DD equity máximo USD (%) | Factor recuperación |
|---|---:|---:|---:|
| 01_Sin_entradas_tendencia | 32.59% (144.19) | 144.19 (32.59%) | 0.83 |
| 00_Control | 62.67% (166.29) | 166.29 (62.67%) | -0.59 |

La revisión de esta pareja está completa: no faltan backtests ni informes. Sin tendencia gana 119,05 USD y reduce la caída relativa de equity de 62,67% a 32,59%. La caída sigue siendo considerable. Enero y mayo aportan 133,68 USD; los otros siete meses suman -14,63 USD. Cinco de los nueve meses son negativos.

Conclusión: conservar el preset 01 sin modificaciones como candidata para contraste forward demo. Estas pruebas reproducidas no aportan un periodo nuevo fuera de muestra. No concluir que el resultado justifica aumentar riesgo. El presupuesto nominal de 10 USD representa 5% del depósito inicial de 200 USD; el mínimo de lote y los cambios de saldo impiden extrapolar directamente a una cuenta de 100 USD.

Fuentes HTML:
- Datos\Datos version 120 datos del 1 de abril a 20 de septiembre\de enero a septiembre\ReportTester-cuenta-demo 2.html
- Datos\Datos version 120 datos del 1 de abril a 20 de septiembre\de enero a septiembre\ReportTester-cuenta-demo.html