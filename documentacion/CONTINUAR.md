# Continuidad de desarrollo

Esta base captura las fuentes exactas de los dos asesores al 13/10/2026. `tools/snapshot-sha256.json` identifica los archivos copiados antes de la normalización documental. Los archivos principales y módulos MQL no se cambiaron al preparar GitHub.

## Preservado

Gestión económica de BE; controles individuales; bloqueo y transferencia de control entre gráficos; trailing limitado por broker; salida defensiva y persistencia; simulación/pendientes/cancelación; informes de sesión; patrones y lectura por capas. Incluye los tests usados durante el desarrollo y todas las dependencias locales.

## Pendientes materiales

- Validación visual y funcional completa en probador visual: navegación, etiquetas superpuestas, pendientes/cancelación, controles BE/niveles y funcionamiento al reiniciar.
- Reconstrucción y pruebas con broker: no confundir pruebas de reglas con verificación de ejecución real.
- Confirmación estructural contra referencias de entrada persistentes. Los estudios actuales usan ventanas móviles.
- Presupuesto monetario con bloqueo antes de confirmar y aviso de ampliación de riesgo: hay estimación y referencia informativa, no un límite universal.
- Mínimo económico común entre escalones y BE: los escalones pueden proteger menos que el objetivo BE; no afirmar que todos aseguran el mismo importe.
- Exportación de ajustes por gráfico a presets: todavía manual.
- Elliott no es un conteo completo ni garantiza Onda 3. No automatizar por esas etiquetas sin validación adicional.

## Flujo de trabajo

Trabajar en este repositorio, compilar los dos archivos principales cuando cambien sus dependencias, ejecutar pruebas relevantes y guardar cada mejora en un commit. No reconstruir v1.20 desde scripts de versiones anteriores; la fuente actual es la base. No incluir historiales de cuenta, capturas ni credenciales.

El respaldo local y las versiones históricas originales siguen fuera del repositorio; no fueron borrados para depurar la publicación.
