# Contraste enero–abril 2026: v1.20

Conclusión: la candidata sin entradas de tendencia mejora el neto en 62,13 USD frente al control en el periodo reservado. No gana todos los meses: enero +62,29 compensa febrero -21,99 y marzo -5,25. Mantener los parámetros congelados; el contraste es favorable pero no garantiza robustez ni rentabilidad futura.

Siguiente comprobación: ejecutar los presets 00 y 01 sin cambios del 1 de enero al 20 de septiembre de 2026, cada uno con un único depósito inicial de 200 USD, mismo servidor y modelo de ticks. Es una prueba de continuidad de estado, no otro periodo independiente. No sumar 35,05 y 84,00 para predecir el saldo final: abril se reinició en la prueba anterior y las rachas/multiplicador se arrastrarán en la continua. Revisar equity del informe, costes y bloqueos antes de considerar prueba forward demo; no incrementar riesgo.

Dos pruebas del 1 de enero al 1 de abril, XAUUSD M15, MetaQuotes-Demo, v1.20, según Diario. Depósito inicial 200 USD por prueba.

| Variante | Ops | Neto USD | Saldo final | PF | DD saldo % | Peor operación | Último cierre |
|---|---:|---:|---:|---:|---:|---:|---|
| Control | 162 | -27.08 | 172.92 | 0.927 | 35.42 | -10.23 | 2026-03-18 |
| Sin tendencia | 85 | 35.05 | 235.05 | 1.199 | 13.38 | -10.23 | 2026-03-18 |

| Variante | Enero | Febrero | Marzo | Cierres por mes |
|---|---:|---:|---:|---|
| Control | -10.12 | -9.19 | -7.77 | {1: 123, 2: 21, 3: 18} |
| Sin tendencia | 62.29 | -21.99 | -5.25 | {1: 62, 2: 11, 3: 12} |

Ambas ejecuciones concilian y solo difieren en habilitar tendencia y nombres de salida. DD calculado desde ejecuciones: saldo, no equity flotante. Enero–marzo se reservó para contrastar la selección hecha con abril–septiembre; no reutilizarlo para optimizar sin reconocer que deja de ser independiente.
