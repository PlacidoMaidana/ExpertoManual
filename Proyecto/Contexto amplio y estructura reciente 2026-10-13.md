# Lectura por capas

ANÁLISIS conserva ATR y ER arriba y agrega tres filas: pendiente del canal amplio, estructura reciente y confirmación local. Se desplazaron las filas anteriores sin retirar indicadores. INDICADORES resume ambas direcciones y permite ver el detalle al pasar el mouse.

El contexto amplio usa el desplazamiento de la regresión sobre EvoChannelLookback (64 por defecto), con umbral 0,25 ATR; describe pendiente, no prueba una tendencia vigente.

La estructura reciente se calcula con los dos últimos máximos y mínimos de pivotes 2+2 dentro de una referencia de 24 cierres que excluye las dos últimas velas evaluadas. Las direcciones mixtas o pivotes insuficientes quedan sin confirmación. Esto introduce el retraso necesario para confirmar los pivotes.

Un cierre que avanza contra la dirección reciente es rebote/retroceso todavía sin ruptura confirmada. Dos cierres consecutivos más allá del último pivote contrario con margen 0,10 ATR confirman ruptura contraria local; dos fuera del pivote favorable confirman continuación. Se muestran umbrales de precio, con detalle en tooltip. Ruptura local no equivale a cambio confirmado del contexto amplio.

Las ventanas y referencias son móviles. No se conserva aquí la tesis de entrada ni se generan órdenes o cambios de SL/TP. MACD/ROC se mantienen como contexto separado. Las reglas son simétricas para mercados alcistas y bajistas.

Pruebas: estados, simetría, rechazo de confirmación con una sola vela y datos insuficientes; regresión de MarketEvidence. Compilación MQL5. Pendiente inspección visual en MetaTrader.
