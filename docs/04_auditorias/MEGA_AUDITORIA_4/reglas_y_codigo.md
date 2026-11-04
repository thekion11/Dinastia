# Mega auditoría 4 — reglas_y_codigo

Sesión «Búsqueda de fallos». Repasos 1 (lectura de reglas) y 2 (ejecución) hechos el 4-11 sobre `main` ya unido.

## Lo que está bien (comprobado)
- Norma de 450 líneas: `python3 herramientas/revisar_lineas.py --todos` → 1897 scripts, 0 pasan.
- `banco.sh` → «FIN. 0 fallos» (3.136+ comprobaciones). `pruebas/probar_nativo.tscn` (C++ = GDScript) → 0 fallos. `pruebas/ideas/mem_menu_estadio.tscn` (memoria del menú) → 0 fallos.
- `*.zip` / `*.mp4`: los 18 que hay en el repo son punteros LFS (ninguno suelto). Ningún archivo del repo nombra un modelo ni lleva contraseñas de keystore.
- `especiales.sh todo`: 166 pruebas OK antes de cortarlo; el único fallo era A4-REGLAS-003.

## Hallazgos
- [A4-REGLAS-001] (repaso 1, gravedad: medio) La regla «sin identificadores de modelo en commits» no se cumple en el HISTORIAL: 264 de los últimos 300 commits llevan `Co-Authored-By: Claude Sonnet 5.5` (162) o `Opus 5.5` (102), también los de esta sesión de búsqueda de fallos. Reproducir: `git log -300 --format=%B | grep -ciE "opus [0-9]|sonnet [0-9]"`. Los archivos están limpios. Reescribir historia es irreversible: estado: **pregunta al dueño** (solo con orden explícita). Para lo NUEVO: los commits de esta sesión ya no llevan el modelo (solo `Claude-Session`); el pie de commit que añade la plataforma lo nombra, habría que cambiarlo en la configuración de las sesiones. Estado: abierto.
- [A4-REGLAS-002] (repaso 2, gravedad: bajo) F-004: tres escenas viejas (`probar_foto_real`, `ver_pieza_ropa`, `recolorear_tunica`) cargaban `assets/characters/quaternius/ropa_temp/…` (carpeta que no existe) y `captura_viento_arboles` leía `pruebas/capturas/viento_arboles_a.png` sin crear la carpeta. Estado: **arreglado** (guardas «OMITIDA» que salen limpias y `make_dir_recursive` antes de guardar; comprobado ejecutando las tres escenas). `probar_foto_real` además lee una ruta de Windows fija (`C:/Users/Alumno/…`): experimento descartable, se deja como estaba.
- [A4-REGLAS-003] (repaso 2, gravedad: bajo) F-008: `banco_inicio` fallaba en `especiales.sh` («sin guardado, _hay_partida() da false») porque `hay_partida()` cuenta CUALQUIER guardado y otra especial deja `prueba_sin_pantalla.dinastia` en `user://partidas`. Estado: **arreglado** (`especiales.sh` corre `banco_inicio` con `XDG_DATA_HOME` propio, como `banco.sh`; comprobado: 0 fallos).
- [A4-REGLAS-004] (repaso 2, gravedad: bajo) F-007 era un FALSO POSITIVO: `idiomas_extra.json` tiene 269 frases menos en en/pt/fr/it/de/ca que en pl/tr, pero las tablas integradas de `Idiomas` (`idiomas_p1.gd`) las cubren; medido con `Idiomas.t`: lo «sin traducir» son palabras iguales en ese idioma («Música», «Todos», «A favor», «Editor»…). Estado: cerrado, sin cambios.
- [A4-REGLAS-005] (repaso 1, gravedad: bajo) La regla dice «`*.zip`, `.avi`, `.mp4` nunca al repo», pero hay 18 en el repo (punteros LFS: `marca/*.mp4`, `recursos/*.zip`, `material/*.zip`). Moverlos está prohibido («no tocar lo ya en LFS»). Estado: **pregunta al dueño** (aclarar la regla: «ninguno NUEVO»).

- [A4-REGLAS-006] (repaso 4, gravedad: bajo) `pruebas/ideas/zz_alt.gd` (en `especiales.sh`) solo imprimía alturas y pendientes del monte, sin ninguna comprobación: siempre daba «0 fallos». Reproducir: romper `CityBuilder.altura_en` y correrla. Estado: **arreglado** (comprueba altura finita y `ny >= 0,6` en los 9 puntos; medido 0,80-0,99; no cambia el juego). Las otras 13 pruebas sin `_comprobar` visible que revisé sí marcan FALLO por otros medios.

## Repaso 3 (al límite) y 4 (coherencia), hecho en parte
- Idiomas: 3 vueltas por los 9 idiomas más códigos inválidos («xx», vacío) con 276 frases (vacías, `%s`, 5.000 caracteres, saltos de línea, emoji): ninguna traducción vacía, sin errores.
- Pruebas vacías: revisadas las 14 que no tienen `_comprobar` visible; solo `zz_alt` no comprobaba nada (A4-REGLAS-006, arreglado).
- Pendiente: CI (`actualizar.yml`, `compilar.yml`: comprobar que las especiales del CI cubren las mismas pruebas que `especiales.sh todo`), señales sin desconectar, documentos desactualizados.
