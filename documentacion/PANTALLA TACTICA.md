```COMENTARIO
Sí. Para el manual conviene que este capítulo no sea sólo una descripción de campos, sino una **guía de lectura y decisión**. La idea central debería ser enseñar que el tablero se lee de arriba hacia abajo y que **dirección, calidad de tendencia y calidad de entrada son conceptos diferentes**.

Te propongo este capítulo listo para incorporar al manual:
```

# Capítulo — Pestaña TÁCTICA: tablero de indicadores para la toma de decisiones

## 1. Objetivo de la pestaña

La pestaña **TÁCTICA** es el tablero de decisión rápida del Monitor Evolución.

Su objetivo no es reemplazar el análisis técnico detallado disponible en **ANÁLISIS**, sino responder rápidamente:

1. **¿Hacia dónde tiene sesgo el mercado?**
2. **¿En qué régimen se encuentra?**
3. **¿Qué tan fuerte y eficiente es el movimiento?**
4. **¿Existen condiciones para que continúe?**
5. **¿Está apareciendo agotamiento?**
6. **¿Es éste un buen momento para entrar?**
7. **¿Qué riesgo técnico supone hacerlo?**
8. **Si ya existe una posición, cómo convendría gestionarla?**

Por ello, la pantalla debe interpretarse en capas:

$$
\boxed{\text{Dirección}} \rightarrow \boxed{\text{Calidad del movimiento}} \rightarrow \boxed{\text{Calidad de entrada}} \rightarrow \boxed{\text{Acción}} \rightarrow \boxed{\text{Gestión}}
$$
> **Regla fundamental:** una tendencia excelente no implica necesariamente una entrada excelente.

---

# 2. DIRECCIÓN y RÉGIMEN

En la parte superior aparece, por ejemplo:

```
DIRECCION ▼ VENTA | TRANSICION/INDETERMINADO
```

Son dos informaciones relacionadas pero diferentes.

### DIRECCIÓN

Indica el sesgo predominante detectado:

- `▲ COMPRA`
- `▼ VENTA`
- `NEUTRAL`

La dirección se obtiene de la combinación de información direccional, como DI, medias, estructura y contexto.

**No significa por sí sola que deba abrirse una operación.**

### RÉGIMEN

Describe cómo se está comportando actualmente el mercado.

Puede identificar situaciones como:

```
TENDENCIA ALCISTA ACTIVA
TENDENCIA BAJISTA ACTIVA
ALCISTA EN CONSOLIDACIÓN
BAJISTA EN CONSOLIDACIÓN
LATERAL
TRANSICIÓN/INDETERMINADO
```

Por ejemplo:

```
DIRECCION ▼ VENTA
TRANSICION/INDETERMINADO
```

significa:

> Existe todavía un sesgo bajista, pero las condiciones actuales ya no permiten considerar al movimiento como una tendencia bajista limpia y estable.

Esto exige más prudencia que:

```
DIRECCION ▼ VENTA
TENDENCIA BAJISTA ACTIVA
```

---

# 3. FUERZA

Ejemplo:

```
FUERZA 46 ↓
```

Es un score de:

$$
0\rightarrow100
$$

que sintetiza principalmente la fortaleza direccional del movimiento.

ADX y su evolución tienen una participación importante.

No debe confundirse:

$$
ADX\ alto
$$

con:

$$
\text{entrada buena}
$$

El ADX puede seguir siendo elevado después de un gran movimiento aunque la tendencia esté comenzando a agotarse.

Por eso Evolución también analiza:

$$
\Delta ADX
$$

Ejemplo:

```
ADX 24.9
dADX -2.1
```

indica que la fuerza está disminuyendo.

### Lectura práctica

Una fuerza alta y creciente favorece continuidad.

Una fuerza alta pero decreciente requiere observar agotamiento y ER.

Una fuerza baja indica que no existe suficiente evidencia de tendencia.

---

# 4. EFICIENCIA — ER

Ejemplo:

```
EFIC 0 ↓
```

La eficiencia deriva principalmente del **Efficiency Ratio de Kaufman (ER)**.

Conceptualmente:

$$
ER= \frac{\text{desplazamiento neto}} {\text{recorrido total}}
$$

Su rango teórico es:

$$
0\le ER\le1
$$

Un movimiento aproximadamente así:

$$
100\rightarrow101\rightarrow102\rightarrow103\rightarrow104
$$

tiene alta eficiencia.

Uno como:

$$
100\rightarrow103\rightarrow99\rightarrow102\rightarrow98\rightarrow101
$$

es mucho más ruidoso.

Por eso:

$$
ER\rightarrow1
$$

indica movimiento limpio/direccional, mientras:

$$
ER\rightarrow0
$$

indica movimiento ruidoso.

El tablero convierte esta información a una escala visual `0–100`.

### ΔER

También se considera si la eficiencia:

$$
ER\uparrow
$$

está aumentando, o:

$$
ER\downarrow
$$

está deteriorándose.

Esto permite distinguir entre una tendencia que **se está limpiando** y una que comienza a perder calidad.

---

# 5. CONTINUIDAD

Ejemplo:

```
CONTINUIDAD 22
```

Este predictor responde:

> **¿Cuántos de los factores actuales favorecen la continuación del movimiento dominante?**

Puede combinar fuerza, eficiencia, DI, estructura, contexto MTF, volumen y otros elementos.

Un valor alto indica una fuerte confluencia favorable a continuidad.

Sin embargo:

> **CONTINUIDAD 80/100 no significa 80 % de probabilidad.**

Los scores son índices internos de confluencia, **no probabilidades estadísticas calibradas**.

Ésta es la razón de la advertencia:

```
scores no son probabilidad
```

---

# 6. AGOTAMIENTO

Ejemplo de la captura:

```
AGOTAMIENTO 94
```

Este indicador responde:

> **¿Existen evidencias de que el movimiento actual está perdiendo capacidad para continuar?**

Es especialmente importante después de movimientos fuertes.

Puede aumentar cuando aparecen combinaciones como:

$$
ADX\downarrow
$$ $$
ER\downarrow
$$ $$
momentum\downarrow
$$ $$
MTF\ perdiendo\ alineación
$$ $$
estructura\ deteriorándose
$$

o proximidad a zonas técnicas relevantes.

### Lectura

```
AGOTAMIENTO BAJO
```

favorece dejar desarrollar el movimiento.

```
AGOTAMIENTO MEDIO
```

requiere vigilancia.

```
AGOTAMIENTO ALTO
```

aconseja evitar perseguir el precio y, si existe una posición, estudiar protección.

En la captura:

$$
Agotamiento=94
$$

es una advertencia extremadamente importante.

---

# 7. CALIDAD DE ENTRADA

Este indicador merece especial atención.

Ejemplo:

```
CALIDAD ENTRADA 0
```

No evalúa si la tendencia es buena.

Evalúa:

> **¿Es conveniente entrar AHORA y a ESTE precio?**

Podemos tener:

$$
Fuerza=90
$$ $$
Continuidad=85
$$

pero:

$$
CalidadEntrada=25
$$

Esto significa:

> La tendencia puede ser excelente, pero el punto de entrada es deficiente.

Puede suceder porque el precio ya está demasiado extendido, está próximo a soporte/resistencia, el espacio restante es insuficiente o el RR potencial es desfavorable.

Éste es uno de los indicadores que más debe pesar en una **entrada manual**.

---

# 8. RIESGO

Ejemplo:

```
RIESGO 100
```

Este score representa **riesgo técnico/contextual**, no necesariamente el riesgo monetario de la cuenta.

No debe confundirse con:

```
RIESGO MANUAL
```

que posteriormente calcula dólares, lote y porcentaje de capital.

Un riesgo técnico alto puede provenir de:

- agotamiento;
- régimen incierto;
- entrada tardía;
- poco espacio disponible;
- contradicciones;
- pérdida de eficiencia;
- estructura desfavorable.

Por eso en la captura:

```
CALIDAD ENTRADA 0
RIESGO 100
```

constituye una combinación muy clara:

$$
\boxed{\text{NO ES UN BUEN MOMENTO PARA PERSEGUIR LA VENTA}}
$$

aunque todavía exista `SESGO VENTA`.

---

# 9. MTF — Multi-Timeframe

Ejemplo:

```
MTF 20/100
```

Resume la alineación de las diferentes temporalidades analizadas.

Un valor elevado significa que M15, H1, H4 u otras temporalidades configuradas presentan mayor coherencia.

Un valor bajo significa contradicción o pérdida de alineación.

En tu captura:

$$
MTF=20
$$

refuerza la clasificación:

```
TRANSICION/INDETERMINADO
```

---

# 10. DI-dom — dominancia direccional

Ejemplo:

```
DI-dom 10/100
```

Resume la diferencia entre:

$$
+DI
$$

y:

$$
-DI
$$

Cuando uno domina claramente al otro existe mayor evidencia direccional.

En la captura:

```
+DI 17
-DI 21
```

la diferencia es pequeña.

Por eso:

```
DI-dom 10/100
```

indica una dominancia bajista débil.

Esto es muy diferente de:

```
+DI 5
-DI 33
```

que representaría una clara presión vendedora.

---

# 11. GESTIÓN SUGERIDA

La gestión responde una pregunta diferente a la entrada:

> **Si existe una posición, ¿qué estilo de gestión corresponde al mercado actual?**

Los principales modos son:

### EXTENSIÓN

Tendencia fuerte y eficiente.

Objetivo:

> dejar correr el movimiento evitando un trailing innecesariamente ajustado.

### CAPTURA TÁCTICA

Existe dirección pero el movimiento es ruidoso.

Objetivo:

> prestar mayor atención a excursiones favorables pequeñas porque la continuidad limpia es menos confiable.

### PROTECCIÓN

El contexto de la posición se está deteriorando.

Objetivo:

> preservar capital o beneficio frente a pérdida de las condiciones originales.

### NORMAL

No existe suficiente evidencia para aplicar uno de los modos anteriores.

---

## 12. Los scores E/T/P

En la captura:

```
E0 T22 P75
```

puede leerse como:

```
EXTENSIÓN        0
CAPTURA TÁCTICA 22
PROTECCIÓN      75
```

Por eso la conclusión es:

```
GESTIÓN: PROTECCIÓN
```

Esto es muy coherente con:

```
ADX debilitándose
ER ruidoso
ER cayendo
MTF en conflicto
Agotamiento 94
```

El sistema está diciendo:

> **Este contexto no favorece dejar correr agresivamente una posición; favorece protegerla.**

---

# 13. `SOLO DIAGNÓSTICO`

En la fase actual aparece:

```
GESTION: PROTECCION | SOLO DIAGNOSTICO
```

Esto es fundamental durante las pruebas.

Significa que el sistema **detectó que utilizaría PROTECCIÓN**, pero todavía:

- no mueve automáticamente el SL;
- no modifica TP;
- no cierra la posición.

Está observando qué habría hecho.

Esto permite validar la lógica antes de delegarle decisiones reales.

---

# 14. ACCIÓN

Ejemplo:

```
ACCION: ESPERAR CONFIRMACION (sesgo venta)
```

Ésta es probablemente la línea más importante para la decisión manual inmediata.

No dice:

> Comprar.

Ni:

> Vender.

Dice:

> Existe un sesgo vendedor, pero las condiciones actuales no justifican todavía una entrada.

Debajo aparece algo todavía más importante:

```
pendiente: salida de consolidacion/transicion;
espacio 0.05 < 0...
```

La pantalla intenta responder:

> **¿Qué estoy esperando?**

En este caso:

1. que el mercado abandone la transición/consolidación;
2. que aparezca nuevamente espacio operativo suficiente;
3. que los indicadores vuelvan a confirmar una estructura coherente.

---

# 15. ESPACIO OPERATIVO

Ejemplo:

```
Espacio útil 0.05 ATR BAJO
```

Ésta es una métrica crítica.

Expresa aproximadamente cuánto recorrido existe hasta el próximo obstáculo técnico relevante, normalizado por ATR:

$$
Espacio= \frac{DistanciaAlObstáculo}{ATR}
$$

Con sólo:

$$
0.05ATR
$$

el espacio es prácticamente inexistente.

Por eso una tendencia puede ser bajista y, sin embargo, **no convenir vender en ese punto**.

La pregunta no es solamente:

> ¿Hacia dónde va?

También:

> **¿Cuánto espacio queda si entro ahora?**

---

# 16. Estrategia recomendada para leer el tablero

No recomiendo comenzar mirando ADX o ER.

La lectura correcta es jerárquica:

### Paso 1 — ¿Cuál es el régimen?

Primero:

```
TENDENCIA ACTIVA
CONSOLIDACIÓN
LATERAL
TRANSICIÓN
```

Si aparece:

```
TRANSICIÓN/INDETERMINADO
```

la exigencia para entrar debe aumentar.

### Paso 2 — ¿Existe dirección?

Mirar:

```
DIRECCIÓN
DI-dom
MTF
```

No alcanza con que aparezca `VENTA`: debe observarse cuán respaldada está.

### Paso 3 — ¿El movimiento tiene calidad?

Mirar conjuntamente:

$$
FUERZA + EFICIENCIA + CONTINUIDAD
$$

La combinación ideal para continuidad sería:

$$
Fuerza\uparrow + ER\uparrow + Continuidad\uparrow
$$

### Paso 4 — ¿Está agotándose?

Mirar:

```
AGOTAMIENTO
```

Una tendencia fuerte con agotamiento alto exige cautela.

### Paso 5 — ¿Es buena la entrada?

Ahora mirar:

```
CALIDAD ENTRADA
RIESGO
ESPACIO
```

Esta etapa puede **vetar una entrada aunque todo lo anterior sea favorable**.

### Paso 6 — Leer ACCIÓN

Finalmente:

```
ENTRAR
ESPERAR CONFIRMACIÓN
EVITAR
```

y especialmente la condición pendiente.

---

# 17. Regla práctica de decisión

Podemos resumir la filosofía del tablero así:

$$
\boxed{ Dirección + Régimen + Calidad + Espacio + Riesgo \Rightarrow Decisión }
$$

Nunca:

$$
ADX\ alto\Rightarrow entrar
$$

ni:

$$
ER\ alto\Rightarrow entrar
$$

ni siquiera:

$$
Continuidad=100\Rightarrow entrar
$$

La entrada requiere **confluencia y geometría favorable**.

---

# 18. Interpretación de la captura del ejemplo

En la pantalla mostrada tenemos aproximadamente:

```
Dirección:          VENTA
Régimen:            TRANSICIÓN/INDETERMINADO

Fuerza:             46 ↓
Eficiencia:          0 ↓
Continuidad:        22
Agotamiento:        94

Calidad entrada:     0
Riesgo:             100

MTF:                20
DI-dom:             10

Gestión:
PROTECCIÓN

Acción:
ESPERAR CONFIRMACIÓN

Espacio:
0.05 ATR — BAJO
```

La interpretación estratégica es muy clara:

> **El mercado conserva cierto sesgo bajista, pero la estructura que justificaba una venta fuerte se ha deteriorado. La fuerza disminuye, la eficiencia es pobre, existe escasa alineación temporal, la dominancia vendedora es débil, el agotamiento es muy alto y prácticamente no queda espacio operativo.**

Por tanto:

$$
\boxed{\text{NO VENDER SIMPLEMENTE PORQUE EL SESGO SEA BAJISTA}}
$$

La conducta indicada es:

$$
\boxed{\text{ESPERAR}}
$$

hasta que aparezca una nueva estructura coherente.

---

## 19. Relación entre las pestañas

La estrategia general del Monitor Evolución debe ser:

**TÁCTICA** → *¿qué hago ahora?*

**ANÁLISIS** → *¿por qué el sistema está viendo eso?*

**TESIS** → *¿siguen vigentes las razones por las que entré?*

**ALERTAS** → *¿qué cambió y requiere mi atención?*

Por eso la pestaña TÁCTICA no reemplaza el análisis técnico. Lo **resume para la decisión inmediata**, mientras que ANÁLISIS conserva los indicadores completos.

Creo que este capítulo ya puede incorporarse al manual casi tal cual. También agregaría más adelante un segundo capítulo específico llamado **“Lectura de escenarios típicos”**, mostrando 5 casos: *tendencia limpia*, *tendencia ruidosa*, *consolidación*, *agotamiento* y *transición*. Sería muy útil para aprender a utilizar el tablero sin terminar tomando los scores como señales mecánicas.

Sí. Yo agregaría una subsección al capítulo de la pestaña **TÁCTICA**, porque este control tiene una función distinta a los indicadores: permite que el operador adapte rápidamente la gestión al comportamiento que está observando.

Puedes incorporar este texto:

[## Ajuste rápido del Trailing Stop por ATR]{estilo=3-TITULO}

La pestaña **TÁCTICA** permite modificar durante la operación el **multiplicador de ATR utilizado por el Trailing Stop**, sin necesidad de ingresar nuevamente a la configuración del asesor. Esta función está pensada para adaptar rápidamente la distancia de protección al ritmo que presenta el mercado.

El Trailing Stop basado en ATR utiliza la volatilidad actual como referencia. Conceptualmente, su distancia se determina mediante:

$$
\text{Distancia Trailing} = ATR \times Multiplicador
$$

Por ejemplo, si el ATR es `8.00` y el multiplicador vigente es `1.50`, la distancia utilizada por el seguimiento será de aproximadamente `12.00` unidades de precio. Un multiplicador menor acerca el seguimiento al precio; uno mayor le proporciona más espacio para fluctuar.

Los controles disponibles permiten modificar el multiplicador en pasos de **0,10 ATR**:

- **−0,10 ATR:** acerca el Trailing Stop.
- **+0,10 ATR:** aleja el Trailing Stop.
- **Restablecer:** recupera el multiplicador establecido originalmente en la configuración del asesor.

El panel muestra permanentemente el **multiplicador vigente**, de modo que el operador pueda conocer qué configuración está utilizando la gestión en ese momento. La modificación se aplica en el siguiente ciclo de gestión y continúa siendo efectiva aunque la lectura visual del monitor se encuentre fijada.

### ¿Cuándo acercar o alejar el Trailing?

Este control no debería utilizarse simplemente porque una operación está ganando o perdiendo. Su utilización debe relacionarse con la **estructura y ritmo del mercado** que muestra el propio tablero.

En una tendencia fuerte, eficiente y con buenas condiciones de continuidad, un trailing demasiado próximo puede cerrar prematuramente una operación por un retroceso normal. En este contexto puede resultar razonable proporcionar mayor espacio al precio:

```
FUERZA          ALTA ↑
EFICIENCIA      ALTA ↑
CONTINUIDAD     ALTA
AGOTAMIENTO     BAJO
GESTIÓN         EXTENSIÓN
```

La interpretación sería:

> **La tesis continúa fuerte; permitir respiración al precio y evitar que una corrección normal expulse prematuramente la posición.**

Por el contrario, cuando comienzan a aparecer deterioro, agotamiento o pérdida de continuidad:

```
FUERZA          ↓
EFICIENCIA      ↓
CONTINUIDAD     ↓
AGOTAMIENTO     ↑
TESIS           DEBILITÁNDOSE
GESTIÓN         PROTECCIÓN
```

puede ser conveniente utilizar un multiplicador menor para que el seguimiento quede progresivamente más próximo al precio.

### Una distinción importante: acercar no significa cerrar

Reducir el multiplicador del trailing significa **proteger más estrechamente la posición**, pero no necesariamente cerrarla inmediatamente. El precio todavía dispone del margen determinado por el ATR y el multiplicador seleccionado.

Por ello, el operador puede pensar en tres niveles conceptuales:

```
EXTENSIÓN
        ↓
Trailing más holgado
        ↓
dejar respirar la tendencia

NORMAL
        ↓
Trailing normal

PROTECCIÓN
        ↓
Trailing más próximo
        ↓
proteger beneficio/capital
```

Estos niveles son una **guía de lectura**, no una regla automática fija: deben considerarse junto con estructura, soporte/resistencia, MFE, salud de tesis y demás información disponible.

## Regla de seguridad: el Stop Loss nunca retrocede

Existe una protección especialmente importante al utilizar el botón **+0,10 ATR**.

**Alejar el multiplicador no hace retroceder un Stop Loss que ya fue colocado.**

Por ejemplo, si en una posición SELL el trailing ya protegió la operación llevando el SL desde `4400` hasta `4385`, aumentar posteriormente el multiplicador de ATR no debe devolver el SL a `4390` o `4400`.

El nuevo multiplicador modifica solamente la **distancia utilizada para los futuros avances del trailing**.

Esto mantiene el principio:

$$
\boxed{\text{La protección alcanzada no se devuelve al mercado}}
$$

Para una posición BUY, el SL gestionado sólo puede mantenerse o subir. Para una SELL, sólo puede mantenerse o bajar.

## Relación con el tablero TÁCTICO y la pestaña TESIS

El ajuste manual del ATR permite combinar dos niveles de decisión. La pestaña **TÁCTICA** informa sobre las condiciones actuales del mercado y permite reaccionar rápidamente; la pestaña **TESIS** permite verificar si continúan vigentes las condiciones que justificaron originalmente la operación.

Por ejemplo, ante una posición ganadora puede observarse:

```
TÁCTICA
Gestión: EXTENSIÓN
Continuidad: 88
Agotamiento: 18

TESIS
Estado: INTACTA
MFE: +0.65 ATR
```

En ese escenario puede tener sentido permitir mayor respiración al trailing. Si posteriormente aparece:

```
TÁCTICA
Gestión: PROTECCIÓN
Continuidad: 35 ↓
Agotamiento: 81 ↑

TESIS
Estado: DEBILITÁNDOSE
MFE: +1.10 ATR
```

el operador dispone del control `−0,10 ATR` para aumentar progresivamente la protección sin tener que modificar parámetros externos al Monitor.

### Persistencia del ajuste

El cambio realizado desde el Monitor es **operativo y temporal**. Permanece vigente mientras funciona esa instancia del asesor, pero al reiniciarlo se recupera el multiplicador configurado originalmente.

Esto permite utilizar el control como una adaptación táctica durante la operación sin alterar accidentalmente la configuración base del sistema.

---

Yo añadiría además una pequeña advertencia visual en el propio Monitor, si todavía hay espacio, del estilo:

```
TRAIL ATR: 1.50x   [-0.10] [+0.10] [RESET]
                 ↑ cerca   ↑ lejos

SL PROTEGIDO: nunca retrocede
```

Hay una idea interesante para una versión posterior: que **EXTENSIÓN / NORMAL / PROTECCIÓN sugieran un multiplicador de ATR**, pero que inicialmente no lo cambien. Por ejemplo: `Actual 1.50x | Sugerido 1.80x`. Eso permitiría comprobar durante el modo diagnóstico si las recomendaciones adaptativas realmente mejoran la gestión antes de automatizarlas.

[​]{estilo=1-limones oscuro celeste en sombra}

El botón **«PREPARAR SALIDA EN PÉRDIDA» activa un trailing defensivo** para reducir la pérdida posible. **No cierra la operación al pulsarlo ni espera obligatoriamente a llegar a break even.**

Funciona así:

1. **Selecciona una posición en pérdida que ya tenga SL.** Si hay varias dentro de la selección del monitor, elige la más alejada de su entrada en contra, por distancia de precio, no por pérdida monetaria.
2. Guarda el **ATR y el precio del momento de activación**.
3. Sigue el mejor precio favorable alcanzado desde entonces y propone acercar el SL. Puede hacerlo desde el primer ciclo si ya mejora el stop existente.
4. **Nunca vuelve a alejar el SL.** Si el mercado retrocede y alcanza ese stop, se cierra la operación, posiblemente con una pérdida menor.

Con los valores predeterminados del código:

| Momento | Distancia del stop defensivo |
|---|---|
| Al activarlo | **1 ATR** desde el mejor precio observado |
| Tras avanzar a favor **0,25 ATR** desde la activación | Se reduce a **0,5 ATR** |

Ese ATR queda fijo durante el seguimiento. Los botones **«+ / − ATR» del trailing normal no modifican estas distancias**.

Si vuelves a pulsarlo, **cancelas el seguimiento defensivo, pero conservas el SL que ya se haya colocado**. Por defecto, continúa funcionando aunque la posición vuelva a beneficio.

**Diferencia con BE:** el BE manual busca cubrir costos; salida en pérdida busca reducir el riesgo incluso cuando todavía no puedes salir sin perder.

Encontré además una limitación vigente: **este botón todavía puede quedar bloqueado si otro gráfico controla la posición**. La corrección de prioridad que hicimos para el BE no se aplicó a salida en pérdida; por eso «preparada» no significa necesariamente «SL modificado».