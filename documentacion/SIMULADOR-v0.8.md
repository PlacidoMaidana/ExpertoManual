# Gestor Monitor Evolucion v0.8 — simulador y gestión por ticket

Archivo principal nuevo: `Gestor Monitor Evolucion v0.8.mq5`, versión interna 1.80. Conserva los paneles de v0.7 y sus indicadores. v0.7 permanece disponible sin sustituir su simulador. Las dependencias siguen en `v0.6/`. Se reutilizan las comprobaciones de entradas del simulador anterior; la nueva interfaz y gestión están en `SimulatorV08.mqh`. No modifica las reglas automáticas del gestor ni los inputs de presets existentes.

## Preparar una entrada

1. Seleccionar MERCADO BUY / MERCADO SELL / BUY LIMIT / BUY STOP / SELL LIMIT / SELL STOP. Cambiar tipo descarta la propuesta anterior y vuelve a valores de distancia de los inputs.
2. Subir o bajar microlotes con los botones de volumen. 1 microlote = 0,01 lote; se respetan mínimo, máximo y paso del broker. El selector nativo de MetaTrader es independiente.
3. Editar SL ATR y TP ATR con punto o coma decimal. Seleccionar el destino de atajos (SL o TP) y pulsar 0,5 / 1 / 1,5 / 2 / 2,5 / 3. El atajo sustituye la distancia del campo elegido, no suma esa cantidad.
4. Para pendientes editar el precio exacto. Un precio 0 permite preparar automáticamente un nivel legal a 0,5 ATR o al mínimo del broker. Para mercado la entrada es automática al preparar; se revalida al confirmar. Las líneas de entrada de mercado no se arrastran.
5. CALCULAR NIVELES toma un ATR de referencia y prepara precios. Cambiar campos después recalcula la propuesta con ese ATR; CALCULAR permite refrescarlo. Los precios se ajustan al tick del símbolo. Se muestran distancias efectivas tras redondear, relación R:R e importes en moneda de cuenta.
6. Revisar los importes y CONFIRMAR. Si hay cambios de campos sin preparar, el primer clic solo prepara para revisión. Si el precio se movió fuera de tolerancia, se conserva la propuesta y se requiere otra revisión. Se mantienen las restricciones de una posición o pendiente por símbolo para nuevas entradas, permisos de trading, margen y distancias del broker.

Editar o calcular nunca envía órdenes. SL/TP nuevos se envían solo mediante CONFIRMAR, o ACTUALIZAR cuando se cargó un ticket. Los importes excluyen comisiones, swap y deslizamiento y no garantizan la pérdida final.

### Importes prioritarios en la cabecera

Debajo del volumen se muestran RIESGO AL SL en rojo y GANANCIA AL TP en verde, con importe en moneda de cuenta. En cuenta USD son dólares. El riesgo negativo desde entrada se muestra como cantidad positiva de pérdida y porcentaje del equity actual. Si el stop protege beneficio se muestra GANANCIA PROTEGIDA SL, en lugar de llamarlo pérdida.

Sin propuesta activa ni tickets se calcula una vista previa a partir de campos, cotización y ATR actuales, sin activar niveles ni enviar nada. CALCULAR prepara niveles fijos para revisión. Después de una entrada aceptada, si hay un único ticket gestionado se muestran sus SL/TP actuales y volumen real, incluyendo los cambios de BE/trailing; con varios tickets se requiere cargar uno. Al editar un ticket, los importes corresponden a CAMBIOS PROPUESTOS, no a una modificación ya enviada. El origen y precios exactos se conservan en el tooltip de los importes. Los datos faltantes se muestran como NO DISPONIBLE / SIN STOP / SIN TP, nunca como riesgo cero ficticio.

## Modificar una operación existente

CARGAR POSICIÓN selecciona un ticket del símbolo y del filtro de magic del gestor. Si hay varios, pulsar de nuevo recorre los tickets. CARGAR PENDIENTE hace lo mismo con órdenes pendientes. El número y tipo del objetivo se muestran en pantalla. No se sustituye automáticamente un ticket desaparecido por otro.

Se cargan entrada, SL, TP y un ATR de referencia. Si falta un nivel se prepara uno según los inputs, pero no se coloca todavía. Los campos siguen editables. La entrada de una posición abierta es fija; la activación de una pendiente sí puede editarse. ACTUALIZAR SL/TP aplica la propuesta al ticket cargado, previa validación de símbolo, magic, dirección, entrada de posición y límites stops/freeze. Las pendientes conservan su vencimiento existente. La actualización de Stop Limit no está incluida; se gestionan los cuatro tipos Limit/Stop indicados.

El SL existente no se aleja: BUY nuevo SL >= SL anterior; SELL nuevo SL <= SL anterior. Si se quiere modificar solo TP, mantener el SL cargado. En una posición con stop ya en beneficio, la distancia SL desde entrada es negativa y se conserva: por ejemplo SL ATR -0,50 significa un stop protegido 0,50 ATR del lado favorable. R:R inicial no aplica cuando SL ya protege beneficio. La interfaz no elimina SL o TP introduciendo cero.

Los botones de volumen afectan únicamente una nueva entrada. Los importes de gestión usan el volumen real del ticket; no modifican sus lotes. BE, trailing y demás protecciones siguen habilitados según sus interruptores y pueden volver a acercar el stop. La modificación aceptada de una posición solicita el control manual de esa posición para este gráfico.

NUEVA PROPUESTA abandona la edición del ticket y prepara otra entrada; las comprobaciones existentes bloquean agregar otra si ya hay posición o pendiente en el símbolo. No cierra ni cancela por sí solo.

## Cerrar y cancelar

CERRAR #ticket envía el cierre completo únicamente del ticket visible en el botón y vigente. Si hay una sola posición gestionada y no se está editando otro ticket, el botón la identifica automáticamente: no exige CARGAR previamente. Con varias posiciones hay que elegir una mediante CARGAR POSICIÓN; ELEGIR POSICIÓN A CERRAR solo carga una para revisión y requiere otra pulsación sobre CERRAR #ticket. Un ticket cargado que dejó de ser válido nunca se sustituye automáticamente por otro. El cierre es inmediato al pulsar el botón rojo con un ticket. No interpreta el campo volumen como cierre parcial.

El botón de entrada se destaca en verde para BUY, rojo para SELL y azul para pendientes. Dice ENTRAR BUY/SELL A MERCADO o COLOCAR el tipo de pendiente. Si todavía no hay niveles muestra PREPARAR ENTRADA en atención; si existe otra posición/pendiente o hay un ticket cargado, aparece gris y explica el bloqueo.

CANCELAR PENDIENTES muestra el número de órdenes gestionadas del símbolo. La primera pulsación guarda la lista de tickets; la segunda, antes de diez segundos, confirma su cancelación. Se revalida cada ticket. Las órdenes aparecidas después no se agregan silenciosamente al lote de cancelación. Se informa cantidad cancelada, fallida o ya no vigente. No afecta posiciones abiertas ni otros símbolos/magic. Si una orden ya se ejecutó, su nueva posición no se cierra mediante cancelar.

Los resultados del broker se revisan por retcode, no solo por el booleano de CTrade. Las solicitudes de modificación, cierre y cancelación quedan en el diario. Fallos o rechazos no se presentan como éxitos.

## Ayuda e instalación

AYUDA página 7 describe la v0.8. La página está identificada como exclusiva de esa versión; v0.6/v0.7 conservan sus interfaces anteriores. Compilar el archivo v0.8 en la misma carpeta de dependencias y cargarlo en el gráfico elegido, reemplazando al gestor anterior de ese gráfico. No cargar dos gestores para competir por la misma posición.

Al cambiar de versión o volver a cargar, comprobar pausas y ajustes de pantalla del gráfico. Los campos del simulador son de sesión y no se guardan como una referencia histórica. Los presets actuales son compatibles; revisar sus valores antes de usar.

## Validación

Compilación v0.8 sin errores ni advertencias. Pruebas de cálculo ATR BUY/SELL, stops protegidos con signo, validación numérica, no ampliar SL, límites de cuatro tipos pendientes y tolerancias de confirmación. No se enviaron operaciones durante las pruebas. Pendientes: prueba visual en MetaTrader/probador, eventos de edición de campos, ejecución de modificaciones y cancelaciones frente al broker y comportamiento bajo stops/freeze dinámicos.
