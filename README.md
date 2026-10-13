# ExpertoManual

Estado de continuidad al **13 de octubre de 2026**. Este repositorio conserva dos proyectos actuales, con sus fuentes y dependencias:

| Proyecto | Archivo principal | Dependencias / presets |
|---|---|---|
| Gestor manual | `Gestor Monitor Evolucion v0.6.mq5` | `v0.6/`, `v0.6/sets/` |
| Asesor de alternativas | `SignalFusion ORO Alternativas v1.20.mq5` | `alto-riesgo-v120/`, `alto-riesgo-v120/sets/` |

El gestor conserva el nombre de archivo v0.6; su propiedad interna de compilación es 1.60. No son dos asesores diferentes.

## Instalar y compilar

1. En MetaTrader 5, abrir **Archivo → Abrir carpeta de datos**.
2. Copiar los dos archivos `.mq5` y las carpetas `v0.6` y `alto-riesgo-v120` a una misma carpeta dentro de `MQL5/Experts`, manteniendo esa estructura.
3. Abrir cada archivo principal en MetaEditor y compilar con F7. Las librerías `<Trade/...>` pertenecen a MetaTrader, no a este repositorio.
4. Cargar el asesor adecuado y luego un preset de su propia carpeta. No intercambiar presets entre ambos proyectos.

Los ejecutables `.ex5`, los logs y los datos de cuenta no se versionan. Se generan localmente. Usar cuenta demo y probador visual para verificar cambios antes de aplicarlos en otras sesiones.

## Funciones actuales del gestor

- TÁCTICA: controles de trailing, Smart, salida en pérdida y editor NIVELES.
- ANÁLISIS: ATR/ER, canal amplio, estructura reciente, confirmaciones y detalle de indicadores.
- INDICADORES: tablero matricial; TESIS: comparación de contexto; ALERTAS y REGISTRO: eventos.
- SIMULAR: preparación, ajustes de entrada/SL/TP, órdenes de mercado y pendientes, selección/cancelación de pendientes y salida manual.
- PATRONES: HCH, dobles techos/suelos, velas notables y conteos Elliott geométricos experimentales. VER ONDA 3 estudia hipótesis 0–1–2; no identifica una Onda 3 definitiva ni ejecuta operaciones.
- MIN conserva los últimos dibujos de patrones. Son la última lectura dibujada, no un estudio que sigue recalculándose mientras está minimizado.
- Informes HTML/CSV de sesión en la carpeta común `Files/EvolucionManual`.

## Ajustes y continuidad

Los presets conservan los inputs. Los cambios hechos en pantalla (BE, niveles y pausas) se guardan como variables del terminal **por cuenta y gráfico**, y no se exportan automáticamente dentro de un `.set`. Al cambiar de PC o gráfico hay que reproducirlos o ajustar los inputs del preset. Detalles en [manual actual](documentacion/MANUAL-ACTUAL.md).

Mantener un único gráfico responsable de cada posición. Los botones explícitos de gestión pueden transferir el control entre gráficos; el panel avisa cuando otro gráfico controla la posición.

## Validar cambios

Ejecutar las pruebas PowerShell de `v0.6/tests/`. Algunas pruebas Python producen adaptadores C# locales antes de ejecutar la comprobación. Estas pruebas verifican reglas y cálculos, no la rentabilidad ni la ejecución del broker.

`python alto-riesgo-v120/build.py` verifica y regenera únicamente los presets v1.20 desde el control actual, sin requerir versiones antiguas ni modificar el asesor. Los analizadores requieren datos locales: `SIGNALFUSION_REPORTS` y `SIGNALFUSION_DIAGNOSTICS` permiten indicar sus carpetas.

## Documentación

- [Manual actual](documentacion/MANUAL-ACTUAL.md): guía vigente y límites.
- [Continuar desarrollo](documentacion/CONTINUAR.md): estado, verificaciones y pendientes.
- [Alternativas v1.20](alto-riesgo-v120/LEEME.md): presets y comparaciones de esa versión.
- `Proyecto/`: especificaciones recientes de patrones, Onda 3, contexto y controles.
- Los manuales técnicos anteriores incluidos se conservan como referencia; ante discrepancias manda el manual actual y el código.

Las versiones anteriores se conservaron fuera del repositorio público en el workspace original y en un respaldo local, sin eliminar archivos originales.
