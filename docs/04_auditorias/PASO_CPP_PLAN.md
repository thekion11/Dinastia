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
3. **HECHO** — `MotorJugable._cuerpos` (choques por masa, `cuerpos_motor`, `nativo/src/cuerpos_nativo.cpp`; respaldo `_cuerpos_gd` en `visor/motor_jugable_p11.gd`): 199 → 40 µs por llamada; `medir_motor_cpu`: paso entero 1547 → 1300 µs (−16 %). Igualdad byte a byte (posiciones y velocidades, 40 rondas, con dos jugadores en el mismo punto) en `probar_nativo`. NO cambia la lógica del motor: es la misma función.
4. Pendiente — `Partido.fuerza`/`_media_linea` (55 µs x2 por partido): llama de vuelta a GDScript (`es_ex_de`, `j.pie()`, `impulsos`); necesita pasar esos datos ya resueltos. ~5 % del partido.
5. Pendiente — motor 3D: solo piezas geométricas estables (`_rival_mas_cercano` ~5 µs por llamada y sus 22 llamadas por paso, `_linea_tapada`). La IA (`_ia_equipos`, F1-F8, MotorLeague) es de las sesiones 4 y «PES 6»: NO se toca; portarla ahora chocaría con sus cambios diarios.
6. Descartado por cifras — `_semana_del_plantel` (7 ms de 570 ms, y escribir `forma`/`pide_salir` desde C++ cuesta una llamada por propiedad); generación del mundo (única vez).

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
