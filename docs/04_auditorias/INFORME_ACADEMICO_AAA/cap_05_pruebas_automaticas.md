# Capítulo 5. Pruebas automáticas reales: el banco, las especiales y la norma de tamaño

Informe académico AAA de Dinastía · Ejecución y redacción: 16-11-2026, en un contenedor en la nube sin GPU.
Convenciones del informe: [M] medido en esta ejecución · [D] documento del proyecto · [E] estimación. Cada fallo lleva archivo:línea, causa, propuesta y veredicto (CONFIRMADO / PLAUSIBLE / NO REPRODUCIDO). Este capítulo **no corrige código**.

---

## Resumen

Se ejecutó la batería automática completa del proyecto tal como la define `CLAUDE.md`: importación del proyecto con Godot 4.7.2, el **banco** (`herramientas/banco.sh`, 5.457 comprobaciones en ~367 secciones), las **pruebas especiales** (`herramientas/especiales.sh`, 397 pruebas, incluidas las «con pantalla» bajo un servidor X virtual) y la **norma de 450 líneas** (`herramientas/revisar_lineas.py`).

- El banco terminó en **«FIN. 0 fallos»** en 176 s [M]. No obstante, su registro contiene errores del motor que el banco no convierte en fallo; se analizan cuatro de ellos como **fallos latentes**.
- Las especiales dieron **384 OK y 13 FALLO** [M]. Tras repetir cada fallo de forma aislada, **8 son reproducibles y atribuibles al código o a las pruebas del proyecto** y **5 se deben al entorno** (cambios concurrentes en la copia de trabajo, presión de memoria, renderizado por software).
- De los 8 reproducibles, **2 son fallos de comportamiento del juego** (una opción táctica que no cambia nada en el partido 3D y un estado «menú abierto» que no se apaga al cerrar un menú), **1 es una infracción de una regla del proyecto** (dos scripts superan 450 líneas), **1 es un conflicto de contrato** entre una orden del dueño y una prueba (la gala 3D ignora la calidad elegida) y **4 son pruebas desfasadas** tras dos decisiones intencionadas del 15-11 (ULTRA al 60 % del 3D y «Modo rendimiento» encendido por defecto en PC).
- Se añaden un **fallo latente de rendimiento** (`InteriorOculto`, que puede reescanear el túnel cada fotograma) y avisos de importación de recursos (mallas sin UV, `.mtl` con mayúsculas distintas y texturas inexistentes).

La conclusión metodológica principal es que **el banco verde no basta**: los cambios del 15-11 y 16-11 entraron con el banco en verde pero dejaron rojas seis especiales, y la norma de líneas, que `CLAUDE.md` atribuye también a `pruebas/comprobar_scripts.gd`, solo la vigila hoy `especiales.sh`.

---

## 5.1 Introducción

### 5.1.1 Problema

Los capítulos 6 y 7 auditan el código por lectura. Esa técnica encuentra defectos de lógica, pero no dice si el proyecto, tal como está en la rama, **pasa sus propias pruebas**. El proyecto declara en `CLAUDE.md` un criterio de entrega explícito: antes de subir, `banco.sh` debe terminar en «FIN. 0 fallos», y lo que el banco no ve lo cubre `especiales.sh`. Este capítulo comprueba ese criterio con una ejecución real y documenta cada desviación.

### 5.1.2 Preguntas

1. ¿Terminan el banco y las especiales sin fallos con Godot 4.7.2 en un entorno limpio?
2. De los fallos observados, ¿cuáles son del juego y cuáles del entorno de ejecución?
3. ¿Qué errores aparecen en los registros aunque las pruebas den «ok» (fallos latentes)?
4. ¿Qué dice todo ello del proceso de integración del proyecto?

---

## 5.2 Método

### 5.2.1 Entorno

| Elemento | Valor |
|---|---|
| Sistema | Linux x86_64 (núcleo 6.18), contenedor en la nube |
| CPU / memoria | Intel Xeon a 2,30 GHz, **4 núcleos**; **15 GB** de RAM compartidos con otros procesos de la sesión |
| GPU | **ninguna**. Las pruebas «con pantalla» corren con `xvfb-run` y el controlador `opengl3`, que aquí es renderizado por software (llvmpipe) |
| Motor | **Godot 4.7.2 estable oficial** (`4.7.2.stable.official.ed1daf0bf`), binario `Godot_v4.7.2-stable_linux.x86_64` de `godotengine/godot-builds` (GitHub releases), enlazado como `godot` en el PATH |
| Python | 3.13 (para `revisar_lineas.py`) |
| Repositorio | clon superficial (*shallow*) de la rama de trabajo; el banco se lanzó sobre `ae23b25b`; durante las especiales otra sesión hizo commits en la misma copia (hasta `5ed9696a`), ver §5.5 |
| LFS | `git lfs pull --include="dinastia-godot/**"`: terminó sin error; los **79** objetos LFS de `dinastia-godot/` quedaron descargados (todos marcados `*`) |

### 5.2.2 Procedimiento y tiempos

| Paso | Comando | Tiempo de pared [M] | Resultado |
|---|---|---|---|
| 1 | `git lfs pull --include="dinastia-godot/**"` | < 1 min | 79/79 objetos presentes |
| 2 | descarga y descompresión de Godot 4.7.2 | < 1 min | binario operativo |
| 3 | `godot --headless --import --path .` | **192 s** | código 0; 5.008 pasos de reimportación; 206 líneas de error de recursos (§5.3.4) |
| 4 | `herramientas/banco.sh` (4 partes en paralelo, una por núcleo) | **176 s** | **«===== FIN. 0 fallos =====»**, 5.457 comprobaciones |
| 5 | `herramientas/especiales.sh` en 3 partes (`ESPECIALES_PARTE=i/3`, cada una con su `XDG_DATA_HOME`) | **4.905 s** (≈82 min); suma de los tiempos de prueba: 13.958 s | 384 OK, 13 FALLO |
| 6 | `python3 herramientas/revisar_lineas.py` | < 5 s | 2 scripts por encima de 450 líneas |
| 7 | repetición aislada de cada FALLO (uno a uno, sin otras pruebas en paralelo) | ≈25 min | ver §5.3.2 |

Notas de procedimiento:

- Un primer intento de las especiales en un solo proceso se cortó a los 590 s (solo había hecho 15 pruebas: el comentario de cabecera «≈2 min» de `especiales.sh` está desfasado; con pantallas por software la serie entera tarda más de 2 h en un solo proceso [E]). Se relanzó en tres partes con el mecanismo de reparto del propio script.
- `especiales.sh` (sin `todo`) ya incluye las pruebas «con pantalla», porque en este contenedor sí hay `xvfb-run`; en el CI se saltan (comentario del 12-11 en el script).
- Las secciones más lentas del banco fueron `_probar_ligas_activas_todos` (54,4 s), `_probar_ligas_activas` (35,0 s), `_probar_logros` (21,7 s), `_probar_motor_libre` (18,3 s) y `_probar_cantera` (17,4 s) [M].
- Las especiales más lentas: la gala 3D (600 s, cortada), `a4_limite_mundo 2/3` (475 s), `uipl_textos` y las de recorrido de pantallas (280-330 s) [M].

### 5.2.3 Criterio de clasificación

Un FALLO se clasificó como **del entorno** solo si (a) pasa al repetirse de forma aislada en la misma copia, y (b) hay una causa externa identificada (cambio concurrente de archivos, proceso matado por memoria, límite de tiempo con renderizado por software). Si se repite de forma determinista, se clasificó como **del proyecto**, y dentro de este se distinguió entre fallo del juego, infracción de regla, conflicto de contrato y prueba desfasada leyendo el código y el historial de git.

---

## 5.3 Resultados

### 5.3.1 Resumen cuantitativo

| Batería | Pruebas | OK | FALLO | Del proyecto | Del entorno |
|---|---|---|---|---|---|
| Banco (`banco.sh`) | 5.457 comprobaciones (~367 secciones) | 5.457 | 0 | 0 (+4 latentes en el registro) | — |
| Especiales (`especiales.sh`) | 397 | 384 | 13 | 8 | 5 |
| Norma de líneas (`revisar_lineas.py`) | 2.401 scripts | 2.399 | 2 | 2 (contados dentro de las especiales como 1 fallo) | — |
| Extensión C++ = GDScript (`probar_nativo.tscn`, dentro de especiales) | 1 | 1 | 0 | — | — |

### 5.3.2 Tabla de los 13 FALLOS de las especiales

| # | Prueba | Mensaje | ¿Se repite aislada? | Clase | Ver |
|---|---|---|---|---|---|
| 1 | norma de 450 líneas | `486 visor/motor_jugable_p5.gd`, `454 visor/calidad.gd` | sí | **regla del proyecto** | F-03 |
| 2 | `r2: s5_tactica_roles` | «la contrapresión cambia cómo juega el rival en el 3D (precisión 80 % → 80 %)» | sí, 3 de 3 | **fallo del juego** | F-01 |
| 3 | vida de la app fuera del partido | «"atrás" en una pantalla de menú vuelve a su portada y luego la cierra (4 "atrás")» y «…sin preguntar de salir mientras la pantalla seguía abierta» | sí | **fallo del juego** | F-02 |
| 4 | `p6_calidad_minima` | «asignaciones de sombra/glow/SSAO/MSAA sin mirar la calidad (4)» | sí | **conflicto de contrato** | F-04 |
| 5 | `p6_resolucion3d` | «alta y ultra, 100 %» y «ALTA y ULTRA no se tocan» | sí | prueba desfasada | F-05 |
| 6 | 7 niveles de calidad | «escala 3D del nivel 3 (0.60) no baja…» y «sin sombra solar en ULTRA BAJA y BAJA; con ella desde MEDIA BAJA» | sí | prueba desfasada | F-05 |
| 7 | `f0m_visor_estadio` | «el sol a pleno y sombras en 2 cascadas (Medio alivia el partido)» | sí | prueba desfasada | F-05 |
| 8 | `a4_limite_mundo (2/3 calidad y horas)` | en paralelo: «calidad -3 … (1 luces con sombra)»; aislada: «calidad 0 … (0 luces con sombra)» | sí (con otro mensaje) | prueba desfasada + intermitencia | F-05, E-05 |
| 9 | La Ruta: la entrega en 3D de cada premio | corte a los 600 s | sí (sigue sin acabar en 600 s) | entorno (renderizado por software); ver también F-04 | E-03 |
| 10 | A4 cruzado: partido simulado con equipos absurdos | `Parse Error: Cannot infer the type of "am" variable` | **no** (aislada: «FIN. 0 fallos») | entorno (copia modificada durante la ejecución) | E-01 |
| 11 | guardado: autoguardado en segundo plano | el mismo `Parse Error` | **no** (aislada: «FIN. 0 fallos») | entorno (ídem) | E-01 |
| 12 | `a4_limite_mundo (1/3 calidad: fugas al reabrir)` | sin «FIN» a los 160 s | **no** (aislada: «FIN. 0 fallos», 122 s) | entorno (presión de memoria) | E-02 |
| 13 | `a4_metro_museo 2/2` | sin «FIN» a los 239 s | **no** (aislada: «FIN. 0 fallos») | entorno (ídem) | E-02 |

### 5.3.3 Errores en el registro del banco (banco en verde)

| Mensaje del motor | Veces | Origen (pila de GDScript) | Clase |
|---|---|---|---|
| `Attempted to push_back an object of type 'Node' into a TypedArray, which does not inherit from 'Node3D'` | 4 | `visor/interior_oculto.gd:63` (`_juntar_vestuario`) | **latente del juego** (L-01) |
| `Node origin and target are in the same position, look_at() failed` | 1 | `visor/banderas_grada.gd:48`, llamado desde `ui/calentamiento_efectos.gd:36` | latente del juego (L-02) |
| `Error calling deferred method: 'GDScript::enfocar': Cannot convert argument 1 from Object to Object` | 3 | `FocoMando.enfocar.call_deferred(n)` con el nodo ya liberado | latente, al cerrar (L-03) |
| `String formatting error: unsupported format character` | 2 | `pruebas/banco/estadio_p2.gd:358`, `pruebas/banco/partido_p3.gd:267` | latente de las pruebas (L-04) |
| `Condition "err != 1" is true` en `decompress` + «la huella no cuadra» | 33 + 30 | `nucleo/partida_archivo.gd:49` desde `_probar_guardado_seguro` | **esperado**: la prueba estropea partidas a propósito |
| `Nodes with non-equal opposite anchors…` | 33 | `pruebas/banco/partido.gd:302-413` (`_probar_mando_tactil_fc`) | artefacto de la prueba (fija `size` a un control anclado a pantalla completa) |
| fugas al salir (`ObjectDB instances leaked`, RID de `CanvasItem`, `PagedAllocator`) | 3-52 por parte | cierre del proceso de prueba | ruido de cierre; no se analiza aquí (lo cubre `a4_limite_mundo 1/3`) |

### 5.3.4 Errores de la importación de recursos

| Mensaje | Veces | Recurso | Clase |
|---|---|---|---|
| `Condition "!first && !(format & Mesh::ARRAY_FORMAT_TEX_UV)"` y `UVs are required to generate tangents` | 192 + 1 | `assets/ciudad/farola.obj` (superficies sin coordenadas UV) | recurso defectuoso (R-01) |
| `Couldn't open MTL file 'res://assets/ciudad/Vagabond.mtl'` | 1 | `vagabond.obj` cita `Vagabond.mtl`; en disco es `vagabond.mtl` | recurso: mayúsculas (R-02) |
| `Couldn't open MTL file 'res://assets/ciudad/Streetlight_LowRes.mtl'` | 1 | `farola.obj` cita un `.mtl` que no está en el repositorio | recurso (R-02) |
| `Can't open file … T_Eye_Brown.png`, `T_Hair_N_BaseColor.png`, `T_Eye_Normal_png.png`, `T_Hair_N_Normal*.png`, `ropa/T_Regular_Male_{Normal,Roughness}.png` | 11 | `assets/characters/quaternius/Superhero_{Male,Female}_FullBody.gltf` | recurso: texturas referenciadas que no existen (R-03) |

---

## 5.4 Análisis de cada fallo

### F-01 · La «contrapresión» no cambia nada en el partido 3D si la presión es media o alta — CONFIRMADO, gravedad ALTA

- **Prueba**: `pruebas/ideas/s5_tactica_roles.gd:164` (bloque `_motor_3d`, líneas 145-164). Con las semillas 3, 5 y 7, la táctica «tras la pérdida = ALTO» (`Tactica.Nivel.ALTO`, línea 174) da exactamente los mismos tiros (18), pases (68) y precisión del rival (80 %) que la táctica base, en tres de tres repeticiones. La verticalidad, en cambio, sí cambia el juego (21 tiros, 78 %).
- **Causa**: la contrapresión solo existe como un gatillo de `_gatillo_presion` (`visor/motor_jugable_p8_p1.gd:123`: ventana de 0,3 / 0,6 / 1,5 s tras recuperar el balón según `tras_perdida`). Ese gatillo solo se consulta en `_ia_defensa` (`motor_jugable_p8_p1.gd:190-194`) y **solo altera la decisión cuando la presión del equipo es baja**: `if pres == 0 and not gatillo and … : return <temporizar>`. Con presión media o alta (la base de la prueba y el caso más común), el primer presionador corre siempre, haya gatillo o no; la ventana más larga de la contrapresión no añade presionadores ni intensidad. La opción del menú táctico es, en la práctica, inerte salvo combinada con «presión baja».
- **Relación con el capítulo 6**: el cap. 6 (§ presión por zona y ventana de recuperación) señala que el gatillo puede quedar «siempre activo»; este capítulo muestra la otra cara: aunque se active, casi nunca decide nada.
- **Propuesta**: dar a la contrapresión un efecto propio con presión media/alta, por ejemplo, durante la ventana de `tras_perdida`, que el **segundo** presionador de `MotorPresion.papeles` también corra al portador (en vez de cubrir) y que la línea defensiva no retroceda. Tras el cambio, `s5_tactica_roles` debe pasar con las tres semillas y el banco del partido seguir en verde. Como cambia cómo se juega, se anota en el hallazgo (orden 31).

### F-02 · El menú lateral sigue «ocupado» después de cerrarse (caché de `MenuGuardado`) — CONFIRMADO, gravedad MEDIA-ALTA

- **Prueba**: `pruebas/auditoria_vida_global_limite.gd:89-104`. Abre un menú lateral y pulsa «atrás» hasta que `ml.pantalla_abierta` deje de ser válida; tras 4 pulsaciones sigue siendo válida, y entretanto apareció el diálogo «¿Guardar antes de salir?».
- **Causa**: desde el 15-11 (commits `3d315d20` y `13e8870a`, «menú guardado al cerrar»), `PantallaMenu.cerrar()` (`ui/componentes/pantalla_menu.gd:409-424`) ya no libera la pantalla: al terminar la animación llama a `MenuGuardado.guardar`, que la saca del árbol y la conserva en caché (`ui/componentes/menu_guardado.gd:43-63`). Pero `MenuLateral.pantalla_abierta` (`ui/componentes/menu_lateral.gd:44`) **nunca se pone a `null` al cerrar** (solo se limpia al abrir otro menú, línea 350-351), y `MenuLateral.ocupado()` (línea 395-396) sigue devolviendo `is_instance_valid(pantalla_abierta)`, que es verdadero para un nodo guardado fuera del árbol.
- **Efecto en el juego** (además de la prueba): `ui/principal/atajos_menu.gd:31-40` decide con `ocupado()` si L1/R1/L2/R2 navegan el menú lateral o el central. Después de cerrar cualquier menú lateral, los atajos siguen yendo a la pantalla guardada e invisible (`pm.submenu_vecino`) o abren el menú lateral vecino (`menu_vecino`) en vez de mover el menú central; `construir_menu.gd:325` muestra además las ayudas del mando del panel lateral. En el móvil, la secuencia de «atrás» funciona para el usuario (portada → cerrar → pregunta de salir), pero el estado interno miente.
- **Propuesta**: en `MenuLateral`, conectar `cerrada` a `pantalla_abierta = null` (o que `ocupado()` exija `pantalla_abierta.is_inside_tree() and not pantalla_abierta.cerrando()`); revisar los demás lectores de `pantalla_abierta` (`menu_lateral.gd:81, 387`, `principal_p7.gd:70`). La prueba de `auditoria_vida_global_limite.gd:97-104` debe pasar a comprobar `is_inside_tree()` en lugar de `is_queued_for_deletion()`, porque la caché hace que una pantalla cerrada ya no se libere.

### F-03 · Dos scripts superan la norma de 450 líneas — CONFIRMADO, regla del proyecto

- `dinastia-godot/visor/motor_jugable_p5.gd`: **486** líneas (en `origin/main`: 449). Creció en `59f7963e` (15-11, C++ `mover_jugadores_fisica` con su gemelo GDScript).
- `dinastia-godot/visor/calidad.gd`: **454** líneas (en `origin/main`: 450). Creció en `82b91cbe` y `57812789` (15-16-11, escala de ULTRA y sombras).
- **Causa de proceso**: `CLAUDE.md` dice que la norma la vigilan `herramientas/revisar_lineas.py` y `pruebas/comprobar_scripts.gd`; en la versión actual, `comprobar_scripts.gd` solo comprueba que todo compile (no cuenta líneas) y la norma solo la aplica `especiales.sh` (líneas 53-58). Como el criterio de subida es el banco, ambos cambios entraron con el banco en verde. Además, `revisar_lineas.py --nuevos` aborta con `CalledProcessError` en un clon superficial (no hay base común con `origin/main`), así que en contenedores como este la comprobación «solo lo nuevo» no puede usarse.
- **Propuesta**: partir ambos con `herramientas/partir_gd.py` (la última capa conserva ruta y `class_name`); recompilar la extensión si se toca la parte gemela de C++ (`probar_nativo.tscn`); llevar la cuenta de líneas a `comprobar_scripts.gd` (que ya corre en paralelo con el banco) para que el criterio de subida la incluya; y que `revisar_lineas.py --nuevos` caiga a `--todos` cuando no haya base común.

### F-04 · La gala 3D de La Ruta fuerza calidad máxima: choca con la regla de MÍNIMA — CONFIRMADO como conflicto; decisión del dueño

- **Prueba**: `pruebas/ideas/p6_calidad_minima.tscn` busca en el código asignaciones de sombra, glow, SSAO o MSAA que no miren `Calidad`. Encuentra cuatro, todas en `visor/gala_premio3d.gd`: **:65** `_vp.msaa_3d = Viewport.MSAA_8X`, **:80** `env.glow_enabled = true`, **:83** `env.ssao_enabled = true`, **:94** `luz.shadow_enabled = true`.
- **Causa**: es deliberado. El comentario de `gala_premio3d.gd:57-61` cita la orden del dueño del 14-11 («la calidad al máximo aunque los gráficos estén en mínimo; 4K») y `_calidad_maxima()` sube además `scaling_3d_scale = 2.0` (línea 64) y el atlas de sombras a 4096. La prueba de MÍNIMA, anterior, no lo sabe.
- **Riesgo real**: en el teléfono del dueño (5 FPS en MEDIA, `PRUEBA_DUENO_MOVIL_2026-11-03.md` [D]) una escena al doble de resolución con MSAA 8x y SSAO puede tardar varios segundos por fotograma o agotar la memoria de la GPU. En este contenedor (renderizado por software) cada gala tarda ≈2 min y la prueba de las 20 galas no termina en 600 s (E-03).
- **Propuesta**: dos opciones para el dueño, a registrar en `PLAN_GENERAL.md` (preguntas): (a) mantener la orden y añadir `gala_premio3d.gd` a una lista explícita de excepciones de `p6_calidad_minima`; o (b) limitar la «calidad máxima» a ALTA/ULTRA y, en el móvil o por debajo de MEDIA, usar escala 1,0 y MSAA 2x. En ambos casos conviene que la prueba de la gala tenga un modo rápido (una sola gala, o escala 1,0 con `GALA_PRUEBA=1`) para que sea ejecutable sin GPU.

### F-05 · Cuatro pruebas desfasadas tras dos decisiones del 15-11 — CONFIRMADO, gravedad BAJA (pero dejan las especiales en rojo)

Las dos decisiones que las rompen son intencionadas y están documentadas en el propio código:

1. **ULTRA al 60 % del 3D** en Forward+: `visor/calidad.gd:62` (`base = escala_ultra`) y `:326` (`static var escala_ultra := 0.6`).
2. **«Modo rendimiento» encendido por defecto en todas las plataformas**: `visor/calidad.gd:98` (`modo_rendimiento: bool = true`, «PC: 15-11, orden del dueño»). Con él, `ModoRendimiento.sin_sol(nivel)` quita la sombra del sol de MEDIA hacia abajo, de modo que `Calidad.sombra_solar(MEDIA_BAJA)` y `sombra_solar(MEDIO)` son falsos.

| Prueba | Línea | Supone | Propuesta |
|---|---|---|---|
| `pruebas/ideas/p6_resolucion3d.gd` | 12, 34 | ULTRA = 100 % | esperar `Calidad.escala_ultra` en ULTRA (Forward+) y 1,0 en ALTA |
| `pruebas/ideas/ren_calidad_7_niveles.gd` | 19 | la escala 3D nunca baja al subir de nivel | excluir ULTRA de la monotonía o comprobarla contra `escala_ultra` |
| ídem | 24 | sombra solar desde MEDIA BAJA | fijar `Calidad.modo_rendimiento = false` al inicio de la comprobación (y restaurarlo), o comprobar ambos estados |
| `pruebas/ideas/f0m_visor_estadio.gd` | 35-36 | sol con sombra en MEDIA | ídem: fijar el modo rendimiento explícitamente |
| `pruebas/ideas/a4_limite_mundo.gd` | 59 | sombra en todo nivel > MÍNIMO | ídem: el umbral depende de `modo_rendimiento` |

Mientras no se actualicen, «especiales» seguirá en rojo y ocultará regresiones nuevas en esas mismas pruebas.

### L-01 · `InteriorOculto` puede reescanear el túnel en cada fotograma — CONFIRMADO, gravedad MEDIA (rendimiento)

- `visor/interior_oculto.gd:11` declara `var _vestuario: Array[Node3D]`; `:27-28` (`_process`) llama a `_juntar_vestuario()` mientras el arreglo esté vacío; y `:62-63`, cuando no encuentra piezas de vestuario, intenta marcar «ya se buscó» con `_vestuario.append(self)`. Pero `InteriorOculto` **extiende `Node`** (línea 2), no `Node3D`: el arreglo tipado rechaza el `append` (el error del registro) y queda vacío.
- **Efecto**: en un estadio cuyo túnel no tenga piezas sueltas de vestuario, cada fotograma del partido recorre todos los hijos del túnel, calcula AABB y además escribe un error en el registro (en móvil, la escritura de errores por fotograma es cara). El banco lo ve 4 veces porque llama a `_process` a mano.
- **Propuesta**: usar un `bool` aparte (`_vest_buscado := true`) en vez del centinela, y quitar la comparación `n != self` de la línea 45. No cambia lo que se ve.

### L-02 · `look_at()` con dirección nula en el calentamiento de efectos — CONFIRMADO, gravedad BAJA

- `ui/calentamiento_efectos.gd:36` llama a `BanderasGrada.lanzar(raiz, c1, c2, [Vector3(0, -BAJO, 0)], 0.3)`. En `visor/banderas_grada.gd:45-48`, `hacia = Vector3(-s.x, 0, -s.z).normalized()` es cero para un sitio en el eje, y `mi.look_at(mi.position - hacia, …)` falla.
- **Efecto**: un error por proceso al empezar el primer partido; la bandera queda sin orientar (está 60 m bajo el campo y no se ve), así que solo es ruido.
- **Propuesta**: en `lanzar`, si `hacia.length_squared() < 1e-6`, usar `Vector3.FORWARD`; o pasar en el calentamiento un sitio desplazado del eje.

### L-03 · `FocoMando.enfocar` diferido sobre un nodo ya liberado — PLAUSIBLE, gravedad BAJA

- `FocoMando.enfocar(raiz: Control, …)` (`ui/componentes/foco_mando.gd:31`) se encola con `call_deferred` en `ui/componentes/pantalla_menu.gd:50`, `ui/principal_p14.gd:38` y `ui/entrada/ligas_activas_pantalla.gd:124`. Si el nodo se libera antes de que corra la cola, Godot no puede convertir el argumento («Cannot convert argument 1 from Object to Object»); la guarda `raiz == null` de la línea 32 no llega a ejecutarse. En el registro aparece 3 veces, al cerrar el proceso.
- **Propuesta**: declarar el parámetro como `Object`/sin tipo y comprobar `is_instance_valid(raiz)` al principio, o encolar con `enfocar.bind(n).call_deferred()` desde un llamable que compruebe la validez.

### L-04 · Dos mensajes de prueba con `%` sin escapar — CONFIRMADO, gravedad BAJA (solo pruebas)

- `pruebas/banco/estadio_p2.gd:358` («… → 64 % del alcance …» dentro de una cadena con `%`) y `pruebas/banco/partido_p3.gd:267` («… baja un 10 % (%.2f)»). El operador `%` de GDScript interpreta «% d» y «% (» como especificadores, lanza «unsupported format character» y el mensaje sale **sin las cifras** (en el registro aparece literalmente «(%.0f, %.0f, %.0f, %.0f)»). La condición se evalúa bien; lo que se pierde es el diagnóstico si un día falla.
- **Propuesta**: escribir `%%` en ambos textos (como ya hace `s5_tactica_roles.gd:160`).

### R-01 a R-03 · Recursos con errores de importación — CONFIRMADO, gravedad BAJA

- **R-01** `assets/ciudad/farola.obj`: superficies sin UV (193 errores por importación). Si la farola se usa con normal maps no tendrá tangentes. Propuesta: reexportar con UV o desactivar «generate tangents» en su `.import`.
- **R-02** `assets/ciudad/vagabond.obj` cita `Vagabond.mtl` (en disco `vagabond.mtl`): funciona en Windows, falla en Linux y Android (sistemas que distinguen mayúsculas); `farola.obj` cita `Streetlight_LowRes.mtl`, que no existe. Propuesta: corregir la línea `mtllib` de ambos `.obj` (el material ya lo asigna el juego por código, o se pierde en esas plataformas).
- **R-03** `assets/characters/quaternius/Superhero_{Male,Female}_FullBody.gltf` referencian 11 texturas que no están en el repositorio. Propuesta: comprobar si se usan; si sí, añadir las texturas (CC0 de Quaternius) fuera de LFS si son pequeñas (orden 7) o quitar las referencias.

---

## 5.5 Fallos atribuidos al entorno (no son del juego)

| Id | Pruebas | Evidencia | Por qué es del entorno |
|---|---|---|---|
| **E-01** | «A4 cruzado» y «autoguardado en segundo plano» | `Parse Error: Cannot infer the type of "am"` en `visor/motor_jugable.gd:163` (`var am := acta.amarillas_hoy(…)`) | Otra sesión hizo commits **en la misma copia de trabajo** durante la ejecución (`965eb8f7` a las 05:22, que añade `sembrar_amarillas` y `Partido.amarillas_hoy`; `fbc5dc91`/`bb2e78df` a las 05:38-05:39). El analizador vio un estado intermedio de archivos o una caché de clases anterior al método nuevo. Repetidas después: ambas «FIN. 0 fallos». |
| **E-02** | `a4_limite_mundo 1/3` y `a4_metro_museo 2/2` | sin «FIN» a los 160 s y 239 s; el sistema notificó que el núcleo mató un proceso por falta de memoria | Tres partes de especiales con pantalla por software más otra prueba manual compartiendo 15 GB. Repetidas en solitario: «FIN. 0 fallos» (122 s y ~120 s). |
| **E-03** | La Ruta: entrega en 3D de cada premio | corte a los 600 s; repetida con 1.500 s de límite, había montado 6 de 20 galas sin ningún FALLO cuando se detuvo a mano (~13 min) | Renderizado por software de la gala a doble resolución con MSAA 8x (F-04). En una GPU real no es representativo. El contenido verificado hasta el corte fue correcto («hay un guion por premio (faltan: [])», cada gala monta 10 jugadores y el galardón se toma con las dos manos). |
| **E-04** | `revisar_lineas.py --nuevos` | `CalledProcessError` en `git diff origin/main...HEAD` | El clon es superficial y no tiene base común; es robustez de la herramienta, no del juego (propuesta en F-03). |
| **E-05** | `a4_limite_mundo 2/3`, nivel −3 | en paralelo: 1 luz con sombra en MÍNIMA; aislada: 0 | NO REPRODUCIDO. El código del ciclo del sol respeta `Calidad.sombra_solar` (`ui/ciudad_vista_p1_p1.gd:185`). Probable carrera de fotogramas bajo carga. Se deja anotado; la ciudad 3D está apagada en el juego instalado (orden 33). |

Además, todas las pruebas «con pantalla» son más lentas aquí que en una GPU; sus límites de 600 s están pensados para máquinas con aceleración. Ninguna medida de esta ejecución sirve para hablar de FPS (orden 19: el tiempo de fotograma sin pantalla tiene un suelo de 6,9 ms y llvmpipe no representa una GPU).

---

## 5.6 Amenazas a la validez

1. **Copia de trabajo en movimiento.** El banco corrió sobre `ae23b25b`; las especiales, durante unos 80 minutos en los que entraron al menos seis commits de otra sesión en la misma rama y copia. Un resultado «OK» de una especial temprana no garantiza que la misma prueba pase en `HEAD`, y dos FALLO (E-01) se deben a ese movimiento. Lo correcto para una medición reproducible es una copia aislada (`git worktree`) fijada a un commit.
2. **Paralelismo.** Las especiales están diseñadas para correr una tras otra o repartidas entre máquinas; aquí se repartieron en tres procesos en la misma máquina, con `XDG_DATA_HOME` separado por parte y por prueba. Eso evita choques de guardado pero no de CPU ni de memoria (E-02).
3. **Sin GPU.** Las pruebas con pantalla validan lógica y estructura de escena, no apariencia ni rendimiento. Las capturas no se revisaron (el método visual del proyecto exige Forward+ y la cámara real: `herramientas/captura.sh`).
4. **Determinismo.** Solo F-01 se repitió tres veces; el resto de fallos reproducibles se repitió una vez. Las pruebas del partido usan semillas fijas, lo que da determinismo pero no cobertura estadística.
5. **Cobertura.** No se ejecutó `especiales.sh todo` (recorrido de todas las pantallas y balance a largo plazo, +9 min según el script, bastante más sin GPU), ni la prueba de Android/Web, ni la exportación. El banco tampoco ejerce la versión C++ de cada función salvo en `probar_nativo.tscn` (que pasó: «extensión C++ = GDScript», 112 s).
6. **Oráculo.** Una prueba en verde solo dice que se cumple lo que la prueba comprueba. F-05 muestra el caso contrario: pruebas en rojo cuyo «oráculo» quedó viejo frente a una decisión del dueño. La clasificación «prueba desfasada» se basa en los comentarios del código que citan la decisión; no se consultó al dueño.

---

## 5.7 Conclusiones

1. **El criterio de subida del proyecto se cumple solo a medias.** El banco termina en «FIN. 0 fallos» en menos de 3 minutos, pero las especiales tienen 8 fallos reproducibles del proyecto. Las decisiones de rendimiento del 15-16-11 (ULTRA al 60 %, modo rendimiento por defecto) entraron con el banco en verde y dejaron cuatro especiales en rojo, y la norma de 450 líneas se rompió en dos archivos por la misma vía.
2. **Dos fallos afectan a lo que el jugador ve o hace**: la contrapresión no tiene efecto en el partido 3D con presión media o alta (F-01) y el menú lateral queda «ocupado» al cerrarse, lo que desvía los atajos L1/R1/L2/R2 del menú central (F-02). Ambos son pequeños de arreglar y tienen ya su prueba.
3. **El registro del banco esconde fallos latentes**: el más relevante es `InteriorOculto` (L-01), un posible trabajo y un error por fotograma en el partido que el banco no marca porque no busca «ERROR:» en el registro, solo «SCRIPT ERROR».
4. **La gala 3D necesita una decisión del dueño** (F-04): su calidad forzada es coherente con su orden del 14-11 pero contradice la regla de MÍNIMA y su prueba no es ejecutable sin GPU.
5. **Recomendaciones de proceso** (no son arreglos de código del juego):
   - que `banco.sh` falle también ante `ERROR:` con pila de GDScript que apunte a `res://` fuera de las pruebas que provocan errores a propósito (lista blanca: `partida_archivo.gd` en `_probar_guardado_seguro`);
   - que la cuenta de líneas forme parte del criterio de subida (dentro de `comprobar_scripts.gd`);
   - que un cambio en `visor/calidad.gd` o `ModoRendimiento` obligue a correr el bloque de calidad de las especiales (`p6_*`, `ren_calidad_7_niveles`, `f0m_visor_estadio`, `a4_limite_mundo`);
   - actualizar el comentario «≈2 min» de `especiales.sh`: con pantalla y sin GPU la serie completa supera las 2 h en un proceso [E] y tarda ≈82 min en tres.

### Lista de fallos por gravedad

| Orden | Id | Archivo:línea | Clase |
|---|---|---|---|
| 1 | F-01 | `dinastia-godot/visor/motor_jugable_p8_p1.gd:192-194` (gatillo en `:123`) | juego, táctica inerte |
| 2 | F-02 | `dinastia-godot/ui/componentes/menu_lateral.gd:395-396` (y `:44`, `pantalla_menu.gd:409-424`, `atajos_menu.gd:31`) | juego, estado de menú |
| 3 | F-04 | `dinastia-godot/visor/gala_premio3d.gd:64-65, 80, 83, 94` | conflicto con la regla de MÍNIMA; riesgo en móvil |
| 4 | L-01 | `dinastia-godot/visor/interior_oculto.gd:63` (y `:27-28`) | juego, rendimiento y registro |
| 5 | F-03 | `dinastia-godot/visor/motor_jugable_p5.gd` (486), `dinastia-godot/visor/calidad.gd` (454) | regla del proyecto |
| 6 | F-05 | `p6_resolucion3d.gd:12,34`; `ren_calidad_7_niveles.gd:19,24`; `f0m_visor_estadio.gd:35`; `a4_limite_mundo.gd:59` | pruebas desfasadas |
| 7 | L-02 | `dinastia-godot/visor/banderas_grada.gd:48` | ruido |
| 8 | L-03 | `dinastia-godot/ui/componentes/foco_mando.gd:31` | ruido al cerrar |
| 9 | L-04 | `pruebas/banco/estadio_p2.gd:358`, `pruebas/banco/partido_p3.gd:267` | mensajes de prueba |
| 10 | R-01..R-03 | `assets/ciudad/farola.obj`, `vagabond.obj`, `quaternius/Superhero_*_FullBody.gltf` | recursos |
