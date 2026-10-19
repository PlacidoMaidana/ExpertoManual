# Compartir indicadores y tesis como Markdown, en memoria

Disponible en la v0.8: botón COPIAR MD en INDICADORES y TESIS. También se incorpora al análisis visual y al informe avanzado solicitado con ANALIZAR (después de SIMULAR). No crea archivos TXT ni envía información a servicios externos. Las bitácoras y referencias del gestor conservan su comportamiento habitual; esta función nueva no escribe reportes en disco.

En ANALIZAR, COPIAR MD sustituye RUTA TXT y copia todas las líneas originales del informe, no solo la página visible ni las líneas recortadas por ancho de pantalla. Identifica fecha de la lectura y de la copia; no ejecuta un nuevo análisis ni mezcla sus datos con el snapshot del tablero ANÁLISIS. La v0.8 ya no llama al guardado automático TXT de ese informe. Las versiones anteriores sin esta función conservan su guardado previo.

Todos los botones de la barra superior incluyen nombre completo y descripción al pasar el mouse. ANALISIS identifica el tablero continuo; ANALIZAR identifica el informe solicitado y fijo. Las ayudas de FIJAR y MIN indican que no pausan las protecciones.

## Dos opciones

**Gestor Monitor Evolucion v0.8** sigue sin importar DLL. COPIAR MD prepara el texto en memoria y abre una vista paginada con un campo seleccionable que contiene el reporte completo. Para copia manual: pulsar el campo superior, Ctrl+A y Ctrl+C, luego pegar en la IA. El listado inferior es una vista de lectura: no representa todo el texto de una página como informe independiente. La selección/copia del control debe comprobarse visualmente en la instalación de MetaTrader.

**Gestor Monitor Evolucion v0.8 Portapapeles** es una compilación opcional que importa funciones de user32.dll y kernel32.dll de Windows. Requiere habilitar **Permitir importación de DLL** en las propiedades de ese asesor; no se cambia el permiso global del terminal ni se activa automáticamente. Al pulsar COPIAR MD, copia Unicode al portapapeles y muestra COPIADO solo si Windows aceptó los datos. Si está ocupado, informa el fallo y permite reintentar. La copia sustituye el contenido anterior del portapapeles; no lo lee ni lo envía a la red.

No cargar ambas versiones sobre la misma posición. Reemplazar el asesor del gráfico elegido y revisar sus parámetros. Si no se quiere habilitar DLL, conservar la versión normal.

La distinción importa: MetaTrader usa enlace temprano para las importaciones; una compilación que importa DLL no puede prometer funcionar igual sin ese permiso. Por eso el ejecutable normal no las importa. Referencia: [Permisos de aplicaciones MQL5](https://www.mql5.com/en/book/common/environment/env_permissions) y [Ayuda de MetaTrader](https://www.metatrader5.com/en/terminal/help/algotrading/trade_robots_indicators).

## Contenido

- Símbolo, temporalidad, programa, entorno real/demo/probador, fecha de generación y fecha de la pantalla.
- Estado FIJADO/datos pendientes y vela de referencia con su hora de apertura.
- ATR, ER, ADX, DI, RSI, medias, Bollinger, OBV, MACD, ROC, Estocástico y SAR, con valores disponibles y N/D cuando corresponde.
- M15/H1/H4 del snapshot y, en INDICADORES, la caché de M5/M15/M30/H1/H4/D1 con fecha de vela y bloques activados/desactivados. No se recalcula esa caché al exportar.
- Todas las secciones disponibles del snapshot, aunque alguna página esté oculta; un anexo conserva texto visible y tooltips para distinguir la presentación concreta.
- En TESIS: ticket, lado, fecha de apertura y referencia, salud, apoyos, comparación de ADX/ER/RSI y dirección de DI/EMA50/EMA200/OBV/M15/H1/H4, MFE/MAE, P/L más swap, gestión, reglas de invalidación y confirmación.
- No inventa referencias numéricas de ROC/MACD/OBV que no se guardaron. FIJAR afecta al snapshot de mercado, mientras el seguimiento de tesis continúa; ambos tiempos se identifican.

La generación usa una copia del snapshot dibujado. No captura automáticamente un nuevo análisis ni cambia órdenes, SL/TP o filtros. La vista de memoria se cierra con VOLVER o Escape; ticks y temporizador de gestión siguen ejecutándose. No utiliza diálogos bloqueantes ni pausas.

## Validación y límites

Comprobaciones de fuente: módulo de reportes sin FileOpen/FileWrite/FolderCreate, sin solicitudes de trading, importaciones Windows limitadas a la compilación opcional y botón integrado en las solapas. Compilación de ambas variantes. Pendiente validación visual del control seleccionable y copia/pegado nativos en MetaTrader, incluido probador. No se sobrescribió el portapapeles real durante las pruebas de desarrollo.
