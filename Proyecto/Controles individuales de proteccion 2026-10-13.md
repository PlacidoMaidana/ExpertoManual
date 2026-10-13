# Controles de protección

MIN conserva los últimos dibujos de patrones visibles; no recalcula el estudio mientras está minimizado. ABRIR restaura el tablero. Cambiar de pestaña conserva la política anterior de limpiar los dibujos de patrones.

NIVELES abre un editor compacto. Cada N1/N2/N3 puede habilitarse individualmente. ACTIVA y PROTEGE cambian en pasos de 0,05 R. R es la distancia entrada-SL de riesgo inicialmente observada y registrada por el gestor, no el ATR actual. Activa es avance favorable; protege es la ubicación de SL respecto de la entrada. Valores negativos todavía permiten pérdida.

Se exige activación positiva, protección menor que activación y orden no decreciente entre los tres niveles, incluso cuando alguno está apagado. El ajuste rechazado se avisa en pantalla y diario.

BE ON/OFF del editor es independiente de los niveles. Protec ON/OFF pausa o reanuda el conjunto seleccionado. SOLO BE activa BE, apaga N1/N2/N3 y despausa ese conjunto; no cambia los interruptores de trailing, Smart Exit o SP. RESTABLECER vuelve a los inputs iniciales de niveles y BE, conservando la pausa general existente. No retrocede un SL ya aplicado.

Los ajustes efectivos se guardan como variables del terminal para esta cuenta/gráfico. No modifican los inputs de Propiedades ni el preset .set. Requieren migración explícita si se desea trasladarlos a otro gráfico. Los EA automáticos que usan PositionManager conservan los inputs bajo su rama original; overrides solamente en monitor seguro.

Pruebas: un solo nivel, todos los niveles apagados, solo BE, SL ya más protegido y regresión de reglas compartidas (2052 comprobaciones). Compilación MQL5. Pendiente validación visual del editor en MetaTrader.

## Ajustes de BE y organización

TÁCTICA aloja ahora el riesgo manual y los controles de gestión; ANALISIS y las demás solapas conservan su información sin ese bloque inferior. NIVELES abre el editor compacto; CERRAR NIVELES regresa a TÁCTICA y pulsar otra pestaña también cierra el editor.

BE activa cambia en pasos de 0,10 ATR, mínimo cero; BE neto cambia en pasos de 0,50 de moneda de cuenta, mínimo cero. Ambos se guardan por gráfico y RESTABLECER vuelve a los inputs. El objetivo neto usa el cálculo económico existente de comisiones/swap y respeta ManualBEExtraMoney como mínimo adicional y EvoBEOffsetATR si exige una protección mayor. El SL ya colocado no retrocede al reducir valores. Estos botones ajustan umbral y objetivo, no producen un salto inmediato a BE.

Verificación actualizada: 2056 comprobaciones, incluyendo distintos umbrales BE y protección propuesta; compilación MQL5. Pendiente inspección visual en MetaTrader.
