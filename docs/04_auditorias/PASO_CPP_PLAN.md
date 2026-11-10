# Paso a C++ — plan y cifras (sesión 5, 10-11-2026)

Orden del dueño (10-11 noche): pasar a la extensión nativa (`nativo/src` → `bin_nativo/`) lo caliente, función a función, cada una copia EXACTA de su GDScript (que se queda de respaldo para Android/Web). Prueba de igualdad en `pruebas/probar_nativo.tscn` («FIN. 0 fallos») y banco.
Medido en este contenedor (4 núcleos, Linux, sin pantalla). Herramientas de medición nuevas (no son del banco): `pruebas/zz_perfil_semana`, `zz_perfil_minuto`, `zz_perfil_motor`, `zz_perfil_once`; ya existían `zz_medir_simular`, `zz_medir_semana`, `medir_motor_cpu`.

## 1. Dónde se va la CPU (antes de portar)
| Zona | Coste | Notas |
|---|---|---|
| Semana del mundo entero (466 clubes) | ~570 ms | 90 % = `_semana_jugar_ligas` (`Partido.simular`); `_semana_modulos_del_club` 37 ms; `_semana_caja_y_plantillas` 21 ms (de ello `_semana_del_plantel` 7 ms) |
| Partido simulado | ~2,3-2,7 ms | 90 minutos ~1,6 ms; once automático x2 ~0,5-1,5 ms; el resto <0,2 ms |
| Función por llamada (GDScript) | `fuerza` 55 µs, `_elegir_goleador` ~14 µs, `_elegir_asistente` ~14 µs, `_atacar` 38 µs, `simular_minuto` 30 µs | `_chequeo_arbitral` 1,5 µs, `_incidencias` 2,7 µs |
| Motor 3D (`MotorJugable.paso`) | ~1,4 ms por paso (sin gráfica) | `_ia_equipos` ~0,46 ms (`_ia_defensa`, `_ia_ataque_sin_balon`), `_mover_jugadores`, `_duelos` ~0,11 ms, `_cuerpos` ~0,13 ms, `_rival_mas_cercano` x22 ~0,09 ms |
| Generación del mundo entero | 610 ms (una vez) | no es caliente |

## 2. Lista ordenada
1. **HECHO** — sorteo ponderado del goleador y del asistente (`elegir_ponderado`, `nativo/src/partido_nativo.cpp`; envoltorio `nucleo/partido_ponderado.gd`, que conserva `goleador_gd`/`asistente_gd`).
2. **YA ESTABA + RETOCADO** — once automático (`once_asignar_libres`): GDScript 335 → C++ 82 µs por once. Retocado el 10-11: nombres de propiedad como `StringName` fijos y, en `OnceAuto`, el orden de las ranuras y su empaquetado se calculan una vez por formación (`orden_de`, `_entrada`): `Club.once()` 166 → ~110 µs, `once x2` por partido 515 → 394 µs. Misma salida (misma huella).
2b. **HECHO (orden del líder, 10-11)** — `simular_90`: los 90 minutos del partido simulado de la IA en C++ (`nativo/src/partido_90.cpp`; GDScript `nucleo/partido_rapido.gd`, llamado desde `Liga.jugar_jornada`). Misma secuencia de llamadas a `Azar` (se usa el MISMO generador); los sucesos raros (gol, tarjeta, penal, lesión, cambio, plan del minuto 60) vuelven al GDScript original, cuyo código vive una sola vez en `PartidoRapido.hit_*` y lo usan las dos rutas. NO simula (nadie lo lee en un cruce que se tira): crónica de remates, `RastroPartido`, `momentum` de remates. Solo se usa si el cruce no es del jugador, no hay motor/grada/instrucciones/prórroga, no hay roles en las tácticas y nadie más escucha los remates (`_puede`); si no, `simular_minuto()` de siempre. Sin extensión: el mismo bucle de siempre.
   - Igualdad: `pruebas/nativo_partido.gd` (desde `probar_nativo`): 4 mundos (CHI+ESP, ENG+ARG+BRA, GER+ITA+FRA, mundo entero), 2094 cruces, 6 jornadas por liga: marcadores, 19 estadísticas del partido, TODO el estado de los jugadores (`inst_to_dict`) y el estado del generador de azar, iguales. Comprobado que la prueba detecta un cambio mínimo (p_lesión 0,0024 → 0,0030 falla en el cruce 63).
   - Cifras (200 partidos de un mundo entero): 90 minutos 1697 → 616 µs (−64 %); partido completo 2465 → 1268 µs (−49 %). Semana del mundo (521 clubes): **786 → 438 ms (−44 %)**; `_semana_jugar_ligas` 704 → 349 ms. Banco: FIN. 0 fallos.
   - Lo que queda en el partido: `preparar` ~590 µs (once x2 ~390), 90 minutos ~616 µs (sobre todo ~900 tiradas de `randf` por la API, ~0,3 µs cada una, y las vueltas a GDScript por gol/tarjeta), cierre ~64 µs.
2c. **HECHO** — `preparar()` del cruce de la IA: (a) `medias_linea` (las 4 `_media_linea` de `fuerza` en una llamada nativa; `nucleo/partido_medias.gd`, gemelo `_media_linea`): 43 → 15 µs por once, igual byte a byte con arengas, exes y laterales de los dos pies (`NativoPartido.probar_medias`); (b) `sin_rastro`: el cruce que se tira no calcula `RastroPartido.al_preparar` (60 µs). Cruce completo (prueba de igualdad, 2094 cruces) 1834 → 956 µs. Semana del mundo (521 clubes): **792 → 395 ms (−50 %)**; `_semana_jugar_ligas` 707 → 310 ms. Banco: FIN. 0 fallos.
2d. **HECHO** — tiradas de azar en C++: `AzarNativo` (partido_90.cpp) reproduce el PCG32 de `RandomNumberGenerator` sobre su `state` (se vuelca/relee en cada vuelta a GDScript). Autocomprobación `pcg_coincide()` (5 semillas x 4000 tiradas + estado final) la primera vez; si el motor de otra versión no coincidiera, `simular_90` usa las llamadas del motor (mismo resultado, más lento). 90 minutos ~600 → ~500 µs (medición ruidosa). Semana del mundo: 365-400 ms (−50 % frente a 792).
2e. **MEDIDO, NO SE PORTA MÁS (10-11)** — `preparar()` (herramienta `pruebas/zz_perfil_preparar.tscn`, cruces de la IA de un mundo entero, µs por cruce): preparar entero 442; once x2 215 (el resto: `Clima.del_partido` 14, `Previa.arbitro_de` 5, notas/titulares 12; ~190 son ~60 asignaciones de campos y `invalidar_fuerza`). Un `once()` son ~110-165 µs: `OnceAuto.asignar` 72 (de ello 65 es el nativo: leer ~30 jugadores y ~275 `media_en`), `LeyesPais.ajustar_once` 22, `disponibles` 10. Seguir bajando exigiría un volcado de atributos por jugador que se invalide con cada cambio (lesión, forma, moral, traspaso): invasivo y con riesgo de romper la igualdad exacta, para ~80 µs de ~950 por cruce (≈ −25 ms de 395 ms la semana). No compensa; el suelo ya es el cruce GDScript↔C++ por propiedad.
3. **HECHO** — `MotorJugable._cuerpos` (choques por masa, `cuerpos_motor`, `nativo/src/cuerpos_nativo.cpp`; respaldo `_cuerpos_gd` en `visor/motor_jugable_p11.gd`): 199 → 40 µs por llamada; `medir_motor_cpu`: paso entero 1547 → 1300 µs (−16 %). Igualdad byte a byte (posiciones y velocidades, 40 rondas, con dos jugadores en el mismo punto) en `probar_nativo`. NO cambia la lógica del motor: es la misma función.
4. Pendiente — `Partido.fuerza`/`_media_linea` (55 µs x2 por partido): llama de vuelta a GDScript (`es_ex_de`, `j.pie()`, `impulsos`); necesita pasar esos datos ya resueltos. ~5 % del partido.
5. Pendiente — motor 3D: solo piezas geométricas estables (`_rival_mas_cercano` ~5 µs por llamada y sus 22 llamadas por paso, `_linea_tapada`). La IA (`_ia_equipos`, F1-F8, MotorLeague) es de las sesiones 4 y «PES 6»: NO se toca; portarla ahora chocaría con sus cambios diarios.
6. Descartado por cifras — `_semana_del_plantel` (7 ms de 570 ms, y escribir `forma`/`pide_salir` desde C++ cuesta una llamada por propiedad); generación del mundo (única vez).

## 2.1 Motor 3D en directo y generación del mundo (10-11, medido y descartado por ahora)
Paso del motor jugable (`zz_perfil_motor`, µs por paso, sin gráfica): `_ia_equipos` ~640 (IA: sesiones 4 y «PES 6», NO se toca), `_mover_jugadores` ~215, `_duelos` ~140, `_presion` x22 ~117, `_rival_mas_cercano` x22 ~86, `_disputas` ~31, `_cuerpos` ~28 (ya en C++), el resto <25 cada uno. Lo no-IA que queda (`_mover_jugadores` + `_duelos` ≈ 355 µs de ~1300) son bloques largos de diccionarios (`p["vel"]`, `p.get("freno", 1.0)`...) y nodos, que cambian a diario por las sesiones de jugabilidad: un gemelo C++ se quedaría obsoleto (regla de la extensión: tocar una de las dos obliga a recompilar y repasar la igualdad) y el cruce GDScript↔C++ por cada propiedad se come la ganancia. Estimación honesta: −0,15 ms por fotograma (2 % del presupuesto de 8,3 ms a 120 FPS) a cambio de mucho coste de mantenimiento. En el móvil el límite es la GPU (CPU al 0 % en la prueba del dueño): no ayuda. `perfil_cpu` (por script, en el partido 3D) sale dominado por ruido en este contenedor (valores negativos): el cuello del directo es el dibujo, no los scripts.
Generación del mundo al empezar partida: 610 ms para 466 clubes (una sola vez), ya troceada por fotogramas (`generar_por_trozos`): no es caliente.
Si el dueño quiere más CPU en el directo, lo rentable no es C++ sino cachear en el motor (p. ej. posiciones de los 22 en un array plano por paso que lean `_presion`, `_rival_mas_cercano` e `_ia_defensa`), que es un cambio de datos de la IA (sesión 4).

## 2.2 Android y Linux ARM (10-11, orden del líder tras la auditoría móvil)
`bin_nativo/dinastia.gdextension` declaraba `android.{debug,release}.arm64` y `linux.{debug,release}.arm64` sin que existieran los `.so`: un error claro (aviso o fallo al exportar/arrancar). Se QUITARON esas cuatro líneas; quedan Linux x86_64 y Windows x86_64. **PENDIENTE del dueño/CI: compilar el `.so` de Android arm64** (`herramientas/compilar_nativo.sh` con el NDK; hay que volver a añadir las dos líneas `android.*.arm64` al `.gdextension`). Hasta entonces, en Android el juego usa los gemelos GDScript (misma salida, más lento: la semana del mundo ~786 ms en vez de ~395).

## 3. Resultados (antes/después, misma semilla)
`zz_medir_simular` (200 partidos de un mundo entero; `DINASTIA_SIN_NATIVO=1` = todo GDScript), **huella idéntica 3660479828** en las dos:
| | Sin extensión | Con extensión |
|---|---|---|
| once x2 | 1565 µs | 525 µs |
| 90 minutos | 1662 µs | 1289 µs (−22 % por el paso 1) |
| partido simulado | 2681 µs | 1899 µs (−29 %) |

Prueba de igualdad (`probar_nativo`): goleador y asistente, con y sin roles, miles de sorteos, misma semilla de `Azar` → mismos elegidos y misma tirada siguiente.

### Semana entera (`zz_perfil_semana`, mundo entero, 521 clubes, tras fusionar la rama del líder)
| | Sin extensión (`DINASTIA_SIN_NATIVO=1`) | Con extensión |
|---|---|---|
| semana | 728 ms | 611 ms (−16 %) |
| `_semana_jugar_ligas` | 651 ms | 528 ms |
Huella de `zz_medir_simular` igual en las dos (3383400550). Banco: FIN. 0 fallos.

## 4. Lecciones
- Cruzar a C++ cuesta: cada `Object::get("propiedad")` es una llamada dinámica (~1-2 µs). Gana lo que hace MUCHO cálculo por cruce; las funciones que leen muchas propiedades de objetos `Jugador` ganan poco (el sorteo: 14 → 8,5 µs, no 10x).
- Portar el cuerpo de `simular_minuto` (prelude de probabilidades y contadores) NO compensa: son ~60 sentencias (~6 µs/min), pero C++ tendría que recibir ~20 valores (propiedades de `Partido`, variables estáticas `ctx_*` que `Object::get` no ve) y devolver otros tantos; el cruce se come casi todo (ganancia estimada ~2,5 µs/min ≈ 12 % del partido, con riesgo de desfase del azar). Además `_atacar` emite señales con oyentes GDScript (`_aporte_*`, crónica).
- Un partido de la IA enteramente en C++ (`simular_rapido`) sí ganaría de verdad (estimo 5-10x), pero obliga a copiar también crónica, notas, aportes, tarjetas y lesiones, que viven en GDScript y en `Jugador`: es un proyecto de varios días, no un retoque. Decisión del líder/dueño.
- Para ganar más en el partido simulado hace falta que los datos estén en arrays planos (p. ej. `PackedFloat64Array` por once), no en objetos: es un cambio de modelo, no de lenguaje.

## 5. Pendientes
- Windows: los `.dll` NO están recompilados (no hay mingw en este contenedor): el método `elegir_ponderado` falta allí y el GDScript usa su respaldo (misma salida). Lo recompila el CI (`compilar.yml`) o `herramientas/compilar_nativo.sh windows` donde haya mingw.
- Fallo que ya traía la rama base (no es de este trabajo): el banco da 1 fallo, «la piel de Brasil sale más oscura que la de Inglaterra (3.8 frente a 3.7)»; sale igual con `DINASTIA_SIN_NATIVO=1`.

## 2f. Semana del mundo entero (10-11, orden 35, sesión 5)
Perfil (2206 clubes, `PAISES=TODOS SEMANAS=12 zz_perfil_semana`, mismo equipo): **1532 ms/semana** → `_semana_jugar_ligas` 1109, `_semana_modulos_del_club` 305, `_semana_caja_y_plantillas` 114. Por sentencias, lo que quedaba en GDScript:
- `MercadoDT.semana` → `presion()` por club reordenaba la liga y su tabla CADA vez (O(n²·log n)): 297 ms. **Arreglado sin C++** (`MercadoDT.presiones_de(liga)`, una vez por liga, mismas cuentas; prueba en `s6_mercado_dt`): modulos_del_club 305 → 16 ms. Semana **1532 → ~1280 ms**, huella 2180788566 igual con y sin nativo.
- `Partido._cerrar_notas` (64 ms/semana): **a C++** (`cerrar_notas`, `nativo/src/cerrar_notas.cpp`; la gemela `_cerrar_notas_gd` se queda de respaldo; misma tirada `randf` por jugador sobre `Azar._rng`). Comparada en `probar_nativo` (300 cruces: notas, forma, partidos y estado del azar iguales): 47 → 37 µs por cruce; en la semana, dentro del ruido (~10 ms): el coste es leer y escribir propiedades de objetos GDScript, no la aritmética.
- Ya estaban en C++: `simular_90`, `once_asignar_libres` (aun así 273 ms/semana, por las lecturas de `Jugador` y `media_en`), `elegir_ponderado`, `medias_linea`.
- Lo que queda de `_semana_jugar_ligas` (~1130 ms): `Club.once()` ~440 ms (273 en la extensión, `disponibles()` 69), `_cerrar_notas` + notas iniciales ~130, `simular_90` y envoltorios. Siguiente paso real (no hecho; cambia la estructura, no es copia exacta): guardar el once automático del club mientras plantilla, lesiones y sanciones no cambien, o pasar a la extensión los atributos de los jugadores en arrays planos.
- Windows .dll y Android .so NO recompilados aquí (CI/dueño); sin ellos `has_method("cerrar_notas")` es falso y corre la gemela GDScript.
