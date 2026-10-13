# Manual actual del gestor — 13/10/2026

## Protección

En TÁCTICA, NIVELES abre un editor compacto. N1/N2/N3 se habilitan por separado. ACTIVA expresa avance favorable en R y PROTEGE expresa dónde propone el SL respecto de entrada. R es la distancia de riesgo inicial observada. Valores negativos de protección permiten todavía una pérdida.

BE activa cambia en 0,10 ATR y BE neto en 0,50 de moneda de cuenta. El BE es automático: no mueve el stop al pulsar ON, espera el umbral y espacio del broker. El objetivo neto incluye costos estimados y conserva pisos adicionales configurados. SOLO BE apaga escalones, pero no cambia TS, Smart ni SP. Protec ON/OFF pausa el conjunto seleccionado. Desactivar o reducir valores nunca aleja un SL ya colocado.

TS después de BE espera un SL económico confirmado. La distancia es ATR multiplicado por el valor mostrado, limitada por stops/freeze del broker; no es una velocidad. SP acerca un stop defensivo, no cierra inmediatamente; Detener TS también pausa SP. Requiere posición adversa con SL existente.

CERRAR NIVELES regresa a TÁCTICA. Pulsar otra pestaña cierra el editor. Las preferencias de pantalla se guardan por gráfico/cuenta en el terminal, no dentro del preset. RESTABLECER vuelve a inputs del asesor y no cambia el SL existente.

## Simular y pendientes

TIPO alterna mercado y Buy Limit/Buy Stop/Sell Limit/Sell Stop. CALCULAR prepara; los botones cambian entrada y SL/TP. ENTRADA VÁLIDA reubica la pendiente y traslada sus SL/TP manteniendo distancias: revisar presupuesto antes de COLOCAR. No coloca automáticamente.

Pendientes se dejan GTC donde el broker lo permite. EN ESPERA muestra ticket y niveles; CANCELAR #ticket elimina la elegida, OTRA PENDIENTE cambia selección. El simulador bloquea nuevas entradas si hay una posición o pendiente en el símbolo. SALIR A MERCADO cierra la única posición seleccionada del símbolo; no cancela una pendiente.

Después de colocar, muestra importes de SL/TP del broker. Una propuesta nueva ocupa esos campos mientras se prepara. Las estimaciones no garantizan el resultado ejecutado y el broker puede aplicar spread, deslizamiento y costos.

## Análisis y patrones

Canal amplio es una regresión, no certifica estructura vigente. La estructura reciente utiliza pivotes confirmados y dos cierres para confirmar rupturas. PATRONES y ONDA 3 son diagnósticos, sin autoridad sobre órdenes. Se distinguen precio en vivo provisional y cierres confirmados. Los conteos Elliott son hipótesis geométricas sin subondas/ABC.

MIN conserva dibujos de la última lectura y oculta el tablero. Esos dibujos no se actualizan mientras está minimizado. OCULTAR/DIBUJOS permiten reducir marcas.

## Informes y presets

EvoManualReports habilita CSV de configuración/ejecuciones y HTML `_resumen.html` en la carpeta común de MetaTrader `Files/EvolucionManual`. La página resume posiciones completas y separa historia parcial. El HTML nativo del probador y el HTML del gestor son productos distintos.

Presets manuales actualizados: Base, TrailingAmplio, Diagnostico y dos ensayos específicos (BE 0,50 ATR y TP 1,50 R). Son configuraciones de estudio, no optimizaciones nuevas. La versión 1.20 usa exclusivamente sus diez presets de alternativas.
