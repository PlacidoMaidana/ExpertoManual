# Estocástico y Parabolic SAR — ANÁLISIS v0.7

Se incorporan dos tarjetas de contexto con los indicadores nativos de MetaTrader, sin modificar señales, puntuaciones, BE, trailing ni reglas de gestión. No se agregan filtros de entrada. Si faltan datos se muestra N/D y la gestión existente puede continuar. La v0.6 mantiene su panel anterior.

## Estocástico

Parámetros 14/3/3, media simple, precios Low/High. %K y %D corresponden a la última vela cerrada. Barra %K 0-100 con marcas 20/50/80. Sobrecompra si K>80, sobreventa si K<20, neutro en otro caso. Fondo de atención en extremos.

Un cruce alcista exige K actual > D actual y K previa <= D previa; bajista exige lo contrario. No se presenta como cruce nuevo una relación K>D que ya existía. El estado puede destacar el cruce; el tooltip conserva zona y definición. Un extremo no demuestra agotamiento ni un retroceso inevitable.

La fórmula rápida de referencia es 100*(cierre-mínimo14)/(máximo14-mínimo14); la tarjeta usa el cálculo suavizado 14/3/3 nativo, no sustituye ese resultado por la fórmula rápida sin suavizar.

## SAR

Step 0,02 y máximo 0,20. Se compara el valor SAR con el cierre de cada una de las dos últimas velas cerradas. Precio por encima de SAR: DEBAJO / ALCISTA; precio por debajo de SAR: ENCIMA / BAJISTA; igualdad: AL CIERRE. La distancia con signo es (cierre-SAR)/ATR cerrado. El valor de precio SAR se conserva en tooltip.

CAMBIO A ALCISTA/BAJISTA exige que ambos lados sean definidos y opuestos. Se destaca con atención. Esto no equivale a confirmar corrección ni reversión; también puede ser ruido. No se interpreta que ENCIMA sea siempre una corrección: en una tendencia bajista puede acompañar su continuidad.

La recurrencia básica SAR siguiente = SAR actual + AF*(extremo-SAR actual) es orientativa; el cálculo nativo también incluye sus reglas de aceleración, límites y reversión.

## Organización y lectura

Se conservan las tarjetas existentes y se añade una fila con STOCH, SAR y lectura de cambios recientes. M15, H1 y H4 siguen en líneas independientes y visibles incluso en Solo decisión. No se dibujan nuevas ventanas de indicadores ni se agregan puntos SAR al gráfico en este cambio.

En gráficos de altura inferior a 650 píxeles, el contexto inferior expandido usa dos páginas con OTRO DETALLE. Se conservan canal, estructura, situación, soporte/resistencia, régimen, gestión y espacio. En Solo decisión se oculta ese bloque, como antes. FIJAR conserva los valores de ambos indicadores dentro del snapshot.

AYUDA página 6 explica el uso. Las afirmaciones del documento de propuesta sobre anticipación o confirmación automática de correcciones no se implementan como certezas.

Validación: pruebas de cruces K/D, igualdad, ausencia de cruce nuevo por extremo, lado SAR, escalas y reglas de tesis. Compilación del asesor. Pendiente validar la disposición visual y los valores frente a los indicadores de MetaTrader en una corrida visual.

Fuentes oficiales: [iStochastic](https://www.mql5.com/en/docs/indicators/istochastic), [iSAR](https://www.mql5.com/en/docs/indicators/isar).
