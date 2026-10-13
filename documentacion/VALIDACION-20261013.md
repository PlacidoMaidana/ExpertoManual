# Validación del paquete — 13/10/2026

- 38 archivos MQL (dos entradas y módulos actuales) idénticos por SHA-256 al workspace original.
- Resolución recursiva de includes locales: 33 archivos en la dependencia del gestor, 5 para v1.20, sin rutas a versiones anteriores.
- Compilación desde esta copia: gestor y v1.20, ambos 0 errores y 0 advertencias.
- 2056 comprobaciones de reglas compartidas de protección.
- 32 comprobaciones de patrones, geometría Elliott y confirmación.
- Pruebas de lectura por capas, tipos de pendientes/límites y estructura/impulso: PASS.
- Generador de diez presets v1.20 ejecutado desde el control actual sin versiones anteriores.
- Cinco presets manuales actualizados a 142 inputs actuales, conservando sus elecciones previas. Datos binarios UTF-16 de presets no se normalizan por Git.
- Respaldo local ZIP verificado íntegro; no se sube a GitHub.

Estos checks no sustituyen la inspección visual en MetaTrader, el replay de decisiones humanas ni la verificación de rentabilidad o ejecución del broker.
