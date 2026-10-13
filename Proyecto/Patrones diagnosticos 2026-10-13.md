# Pestaña PATRONES

Estudios diagnósticos: HCH normal e invertido, doble techo/suelo y rechazo por mechas. No crean señales de trading ni modifican posiciones.

- 240 velas cerradas solicitadas, mínimo 80. Pivotes estrictos 2+2; descarta velas que simultáneamente sean máximo y mínimo local y consolida pivotes consecutivos del mismo signo.
- Última figura válida por familia cuyo último extremo esté dentro de las últimas 30 velas. Duración entre 6 y 100 velas.
- Contexto previo: desplazamiento de 5 velas de al menos 0,50 ATR hacia el primer extremo. Es una regla operativa, no una garantía estadística.
- Doble: diferencia de extremos <=0,35 ATR, profundidad >=0,75 ATR. HCH: hombros dentro de 0,50 ATR, cabeza sobresale >=0,35 ATR, cuello al menos 0,50 ATR bajo ambos hombros (reglas reflejadas para figuras alcistas).
- Cuello horizontal para dobles y recta de los dos valles/picos intermedios para HCH. Últimos dos cierres se comparan con el cuello correspondiente a cada vela, con margen 0,10 ATR. Invalida por cierre más allá del extremo de la figura con el mismo margen; no revive una figura invalidada dentro del historial revisado.
- Mechas: penúltima vela cerrada, rango >=0,50 ATR, mecha >=2 cuerpos y >=55% del rango, opuesta <=25%. Última vela cerrada confirma por ruptura con margen 0,10 ATR. Muestra tendencia previa opuesta y distancia a nivel actual cercano; este nivel no representa necesariamente el soporte/resistencia histórico de la vela.
- Tolerancias se normalizan con ATR de la lectura actual: una nueva lectura puede cambiar la clasificación. FIJAR conserva la lectura; no se presenta como referencia inmutable de entrada.
- MACD/ROC se muestran como un grupo de contexto; no se suman como dos confirmaciones independientes ni crean probabilidades.
- Dibujos visibles solo en PATRONES, con interruptor propio y respetando OCULTAR global. Se borran al salir o minimizar.
- Registra transiciones en el diario con PATRONES_DIAGNOSTICO solo mientras esta pestaña se consulta y no está fijada. No es un escáner continuo ni reconstruye detecciones ocurridas mientras la solapa estuvo cerrada.
- Confirmación de figura no demuestra que la tendencia vaya a revertir. No hay conteo Elliott en esta fase.

Verificación: pruebas de geometría, mechas, estados y simetría; compilación MQL5. No se ha realizado validación de rentabilidad ni inspección visual del panel dentro de MetaTrader.

## Ampliación de lectura visual

Se amplió mechas a las últimas 20 velas cerradas, con OTRA VELA para recorrerlas. Se etiqueta la forma y el contexto: martillo, hombre colgado, estrella fugaz, martillo invertido, pin bar y doji de rechazo. La confirmación se evalúa hacia el lado contrario de la tendencia previa cuando existe contexto; sin tendencia clara se usa el lado geométrico del rechazo. Se muestran precios exactos de confirmación e invalidación con margen 0,10 ATR y la primera vela que cumple confirmación; una invalidación posterior prevalece.

Se muestran hasta tres marcas de mechas recientes y la vela seleccionada. Sin HCH/doble válido se etiquetan los últimos seis pivotes como Max/Min; no se inventan cuello ni cabeza. Los rótulos de figuras válidas incluyen nombres completos y precios.

Elliott se incorporó como hipótesis geométrica experimental de impulso ordinario E0–E5: seis pivotes alternantes; cada impulso >=0,50 ATR; onda 2 dentro de onda 1; onda 3 supera 1 y no es la más corta; onda 4 no solapa 1; onda 5 supera 3. Se informa cuántas secuencias cumplen y se dibuja la más reciente dentro de 30 velas, duración <=100 velas. No incluye subdivisiones, grados, ABC, diagonales ni quintas truncadas. Por ello no es un análisis Elliott completo y puede omitir conteos válidos bajo otras reglas. No predice el siguiente movimiento.

Referencia de reglas: https://www.elliottwave.com/articles/elevate-your-elliott-wave-analysis/
