# Batería de alternativas v1.20

Selecciona **SignalFusion ORO Alternativas v1.20** en Configuración. Todos los presets están en `sets`. No cargarlos sobre v1.19: esa versión no contiene el interruptor de entradas de tendencia.

## Qué probar

| Orden / preset | Cambio respecto del control |
|---|---|
| 00_Control | Reproduce v1.19 corregida |
| 01_Sin_entradas_tendencia | Impide nuevas entradas clasificadas como tendencia; conserva la gestión de posiciones |
| 02_SL_ATR_175 | Stop inicial de ambos regímenes: 1,50 → 1,75 ATR |
| 03_SL_ATR_200 | Stop inicial de ambos regímenes: 1,50 → 2,00 ATR |
| 04_Trailing_ATR_075 | Distancia del trailing de ambos regímenes: 0,50 → 0,75 ATR |
| 05_Trailing_ATR_100 | Distancia del trailing de ambos regímenes: 0,50 → 1,00 ATR |
| 06_Sin_etapa_1 | Desactiva únicamente etapa 1 |
| 07_Sin_etapa_2 | Desactiva únicamente etapa 2 |
| 08_Sin_etapa_3 | Desactiva únicamente etapa 3 |
| 09_Etapas_mas_tardias | Activaciones 0,20/0,40/0,70 R → 0,30/0,60/1,00 R; mismos objetivos de stop |

Cada preset parte del control, no del preset anterior. El 09 prueba el calendario conjunto de las tres etapas; no permite atribuir el resultado a una etapa individual. No mezclar alternativas todavía.

## Condiciones idénticas

Una ejecución continua por preset, del **1 de abril al 20 de septiembre de 2026**, XAUUSD M15, depósito 200 USD, apalancamiento 1:200, mismo servidor y ticks reales. Optimización desactivada. No reiniciar el capital dentro de cada ejecución ni reanudar manualmente.

Todos mantienen presupuesto de 10 USD, protección de sesión 30/10/15, espera desde cotización observada, corrección de reenvíos de stops y reducción de volumen tras pérdidas. La referencia anterior del control es **129,49 USD finales y 387 operaciones**. Primero ejecuta 00; si no reproduce la referencia, revisaremos las condiciones antes de interpretar las variantes.

El SL más amplio también aleja el TP porque se conserva el RR, modifica la escala R de las protecciones y puede bloquear más entradas por lote mínimo. No se aumenta presupuesto para compensarlo. El trailing más amplio da mayor distancia al precio, pero puede devolver más beneficio.

## Parámetros por sus descripciones visibles

- **Permitir nuevas entradas de tendencia**: true en control; false solo en 01.
- **TENDENCIA: multiplicador ATR del stop inicial** y **LATERAL: multiplicador ATR del stop inicial**: presets 02 y 03.
- **TENDENCIA: multiplicador ATR del trailing** y **LATERAL: multiplicador ATR del trailing**: presets 04 y 05.
- **Etapa 1/2/3: activar al ganar R (0 desactiva etapa)**: presets 06–09.
- **Etapa 1/2/3: objetivo del SL en R desde entrada**: se conservan en -0,30 / 0,00 / +0,20 R.

R representa la distancia inicial al stop. Etapa 1 reduce el riesgo; etapa 2 lleva al precio de entrada; etapa 3 protege +0,20 R. Las etapas posteriores siguen disponibles al quitar una anterior. El asesor selecciona la etapa más alta cuyo umbral se alcanzó; no aplica necesariamente las tres en secuencia. Quitar una etapa puede cambiar cuándo el trailing reúne sus condiciones. No se activa el modo legacy de break-even en estos presets.

## Resultados y decisión

Guarda cada resultado en una carpeta con el nombre del preset, junto con informe, Diario y CSV. Los CSV habituales llevan `ALT120_00...` etc. Guarda también los diagnósticos `DX120_...` de Common/Files/SignalFusionDiagnostics; `config` identifica el preset.

Compararemos resultado neto, drawdown de equity si el informe lo aporta, drawdown de saldo, PF, operaciones, meses, peor pérdida, rechazos y periodos sin actividad. Cero o muy pocas operaciones no demuestra mejora de estrategia. No elegir por ganancia total solamente ni convertir retrospectivamente un régimen ganador en garantía de beneficio.

Estas alternativas se diseñan con datos ya vistos: sirven para investigar, no como validación independiente. Cualquier candidata necesita después un periodo no utilizado en su selección. Aún no se han ejecutado estos diez backtests.
