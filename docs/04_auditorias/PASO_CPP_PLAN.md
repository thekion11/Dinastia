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
2. **YA ESTABA** — once automático (`once_asignar_libres`): 313 → ~113 µs por once. Retocado: nombres de propiedad como `StringName` fijos (misma salida).
3. Pendiente — `Partido.fuerza`/`_media_linea` (55 µs x2 por partido): llama de vuelta a GDScript (`es_ex_de`, `j.pie()`, `impulsos`); necesita pasar esos datos ya resueltos. ~5 % del partido.
4. Pendiente — motor 3D: solo piezas geométricas estables (`_cuerpos`, `_rival_mas_cercano`, `_linea_tapada`). La IA (`_ia_equipos`, F1-F8, MotorLeague) es de las sesiones 4 y «PES 6»: NO se toca; portarla ahora chocaría con sus cambios diarios.
5. Descartado por cifras — `_semana_del_plantel` (7 ms de 570 ms, y escribir `forma`/`pide_salir` desde C++ cuesta una llamada por propiedad); generación del mundo (única vez).

## 3. Resultados (antes/después, misma semilla)
`zz_medir_simular` (200 partidos de un mundo entero; `DINASTIA_SIN_NATIVO=1` = todo GDScript), **huella idéntica 3660479828** en las dos:
| | Sin extensión | Con extensión |
|---|---|---|
| once x2 | 1565 µs | 525 µs |
| 90 minutos | 1662 µs | 1289 µs (−22 % por el paso 1) |
| partido simulado | 2681 µs | 1899 µs (−29 %) |

Prueba de igualdad (`probar_nativo`): goleador y asistente, con y sin roles, miles de sorteos, misma semilla de `Azar` → mismos elegidos y misma tirada siguiente.

## 4. Lecciones
- Cruzar a C++ cuesta: cada `Object::get("propiedad")` es una llamada dinámica (~1-2 µs). Gana lo que hace MUCHO cálculo por cruce; las funciones que leen muchas propiedades de objetos `Jugador` ganan poco (el sorteo: 14 → 8,5 µs, no 10x).
- Para ganar más en el partido simulado hace falta que los datos estén en arrays planos (p. ej. `PackedFloat64Array` por once), no en objetos: es un cambio de modelo, no de lenguaje.

## 5. Pendientes
- Windows: los `.dll` NO están recompilados (no hay mingw en este contenedor): el método `elegir_ponderado` falta allí y el GDScript usa su respaldo (misma salida). Lo recompila el CI (`compilar.yml`) o `herramientas/compilar_nativo.sh windows` donde haya mingw.
- Fallo que ya traía la rama base (no es de este trabajo): el banco da 1 fallo, «la piel de Brasil sale más oscura que la de Inglaterra (3.8 frente a 3.7)»; sale igual con `DINASTIA_SIN_NATIVO=1`.
