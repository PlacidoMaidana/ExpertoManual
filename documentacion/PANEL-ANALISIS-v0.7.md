# Panel de análisis v0.7

Asesor separado: `Gestor Monitor Evolucion v0.7.mq5`, versión interna 1.70. Mantiene las dependencias en v0.6 para conservar compatibilidad. La v0.6 conserva su análisis de texto: la nueva vista se activa únicamente al compilar el asesor v0.7. No se cambian cálculos de entradas ni protecciones por este rediseño.

## Distribución

- Cabecera con símbolo, temporalidad y estado de lectura.
- Vela activa y presión sobre el SL, separadas de los indicadores cerrados.
- Tarjetas en tres columnas: ATR / ER / ROC; ADX / RSI / MACD; EMA / OBV / lectura conjunta.
- Sugerencia técnica del motor y aviso de contexto, sin traducir colores en órdenes.
- M15, H1 y H4 mantienen una línea independiente cada uno, siempre visible, incluso en SOLO DECISIÓN.
- Bloque inferior de canal, estructura, situación, soporte/resistencia, régimen, gestión y espacio útil.
- Botón SOLO DECISIÓN oculta ese bloque inferior; VER CONTEXTO lo recupera. Conserva las tarjetas y M15/H1/H4. El cambio no modifica órdenes ni filtros. La vista comienza expandida al recargar.

## Escalas y términos

ATR es un valor en unidades de precio del símbolo. Su barra compara con el promedio de diez lecturas ATR, con escala de 0 a 2 veces y saturación por encima. No es un percentil de volatilidad ni indica dirección.

ER: escala 0-1, ruido visual por debajo de 0,25; intermedio hasta 0,60; eficiente desde 0,60. Estos umbrales visuales no cambian los del motor. ER no determina dirección ni bloquea entradas por sí solo. ADX creciente con ER bajo se describe como fuerza creciente y recorrido ruidoso, sin declarar tendencia naciente confirmada.

ADX: barra 0-50 saturada por encima; débil <20, moderada 20-25, fuerte 25-40 y muy fuerte >40. DI muestra dirección separadamente. El tooltip incluye delta ADX y ambos DI.

RSI: escala 0-100, marcas 30/50/70 y posición actual. La tarjeta de lectura conjunta destaca cruce de 50 o salida de extremos comparando las dos últimas velas cerradas. Extremos no prueban giro.

EMA: muestra orden de medias, distancia con signo (rápida-lenta)/ATR y cruce entre las últimas dos velas cerradas. No inventa una antigüedad del cruce ni cuenta cruces de varias velas atrás. Tooltip con detalle. Se usan los periodos configurados, no se fuerzan 20/50.

## Uso y validación

ROC: valor porcentual y desplazamiento en ATR; barra centrada en cero con escala de -3 a +3 ATR. Positivo verde, negativo rojo; saturación fuera de escala. No describe aceleración.

OBV: valor acumulado y cambio del periodo configurado. Fuerza relativa de la barra = cambio OBV dividido por suma del volumen de esas mismas velas cerradas. Escala -100% a +100%; mide balance neto direccional, no actividad absoluta ni liquidez. Se conserva el tipo de volumen TICKS/REAL. Si faltan datos no se muestra una fuerza inventada. La suma se guarda en el snapshot para respetar FIJAR y evitar mezclar ventanas de tiempo.

MACD: número del histograma, semáforo verde/rojo según su signo si supera el umbral configurado de magnitud/ATR; amarillo por debajo, sin inventar divergencias. Barra no direccional de intensidad abs(histograma)/ATR, escala 0 a 0,20 ATR saturada por encima. Es histograma con señal EMA9. No afirma haber observado un cruce nuevo.

Las escalas se documentan en tooltips y en AYUDA, página 5. No son porcentajes de probabilidad. La presentación se actualiza en la v0.7; el motor de entrada y las protecciones conservan sus reglas.

Seleccionar v0.7 en el navegador y abrir ANÁLISIS. Utiliza los presets actuales. No mantener dos gestores compitiendo por la misma posición; conservar la v0.6 como alternativa y reemplazarla en el gráfico elegido al probar la v0.7.

Compilación v0.7: cero errores y cero advertencias. Pruebas de límites de barras y cruces RSI aprobadas. Presentación visual, DPI y distribución en una corrida de MetaTrader pendientes de verificación. Los textos largos se abrevian con tooltip, como en los paneles actuales. Ninguna prueba envía operaciones.
