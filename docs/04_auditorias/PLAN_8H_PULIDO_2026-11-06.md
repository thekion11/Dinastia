# Plan gigante de pulido y optimización (≈ 8 h por pista, 6-11-2026)
Orden del dueño: SOLO mejorar y pulir lo que ya existe (rendimiento, estabilidad, calidad); NADA de contenido nuevo. No quitar ni apagar nada sin decirlo.
Se trabaja 24/7: las sesiones sin trabajo se archivan. Reglas: banco 0 fallos antes de subir, PR en borrador, medir con llamadas de dibujo/triángulos/memoria (nunca tiempo de fotograma en headless), bloques pequeños, empujar a menudo pero UN solo push por PR al final (cada push reinicia el CI de ~35 min).
Términos: «llamadas de dibujo», «nivel de calidad», «ULTRA BAJA» (hoy MÍNIMO).

## Pista A — RENDIMIENTO (sesión rendimiento)
1. Resolución del 3D en móvil (A1) y sombra solar apagada en el paso bajo con aviso (A2). 0,5 h
2. Los 7 niveles de calidad (ultra baja … ultra alta) con migración `version_calidad`; ULTRA BAJA por defecto en TODOS los sistemas + prueba por plataforma (`OS.has_feature`). 1,5 h
3. Meta: ULTRA BAJA < 130 llamadas de dibujo de media (ciudad + partido; hoy el partido en MÍNIMO = 338). Banco extra con presupuesto. 2 h
4. Medir lo que cuesta cada personaje 3D (esqueleto + mallas) en ciudad, club y eventos: tabla `personajes_coste_2026-11-06.md`. 0,5 h
5. Ciudadanos: nivel de detalle por distancia, tope por nivel de calidad, multimalla (MultiMesh) de lejos. 1 h
6. Instancias repetidas (farolas, árboles, butacas, banderas) a `MultiMesh`; fusionar mallas estáticas por manzana. 1 h
7. Distancia de dibujo (`visibility_range`) y oclusión en la ciudad y el estadio. 0,5 h
8. Sombras: distancia máxima por nivel, sombra «mancha» de lejos. 0,5 h
9. Materiales compartidos y atlas de texturas; menos cambios de estado. 0,5 h
10. Texturas comprimidas para VRAM (S3TC/ETC2/ASTC) y mipmaps: auditar importaciones. 0,5 h
11. Auditoría de `_process`/`_physics_process`: apagar lo que no se ve; ampliar `auditoria_fotograma.py`. 0,5 h
12. Pools de nodos y partículas (balón, efectos, números flotantes); tope de partículas por nivel. 0,5 h
13. Calentar sombreadores/pipelines al cargar: comprobar cobertura (sin tirones al abrir estadio/ciudad). 0,5 h
14. Menú: pantallas de gestión perezosas (−38 MB) y ciudad (−105 MB) según `compilacion_menu_2026-11-03.md`. 1 h
15. Tracy: puntos calientes del partido, la ciudad y el menú; arreglar los 3 primeros. 1 h
16. Audio: tope de voces, flujos comprimidos, carga fuera del hilo principal. 0,5 h
17. Física: menos colisionadores, capas y máscaras, `monitoring` apagado donde no hace falta. 0,5 h
18. UI: evitar redibujos (`queue_redraw`), shaders con `TIME` en menús (ya hecho: revisar los que faltan). 0,5 h
19. Al final: búsqueda web de consejos de rendimiento de Godot (con fuentes) y aplicar solo los seguros.

## Pista B — BANCOS Y ESTABILIDAD (sesión bancos)
1. Cuando #195 esté en `main`: rama `sonar/bancos5`. Corregir la huella del estadio donde el 1,5 % de peatones queda dentro de un obstáculo (rect 8..12, −72..−84) y bajar el TOPE del detector a 0. 1 h
2. Extender el detector a JUGADOR y vehículos aparcados. 0,5 h
3. «Mi personaje no camina de verdad»: prueba que mide avance vs entrada, patinaje de pies, atascos; arreglar lo hallado. 1,5 h
4. Distancia real avatar–objetos (separación mínima junto a paredes y mobiliario). 1 h
5. macOS `err_rafaga_entrada` (899 → 4777 nodos): causa raíz. 1 h
6. Windows: `act_actualizador` (reemplazo de archivo), huella del motor distinta, caché horneada, `aud4_largo_plazo_ui`, `f0s_huellas_sonido` con ruta fija `/tmp/aud`. 1 h
7. Pendientes de calidad: mochilas = 0 (`pers_ropa`), rodillas rectas (`optA_persona`), 5,8 % de frases repetidas, rótulo de estadio en inglés con precio (`uiid_textos`), `trad_textos`, `tut_capas` (1 fallo). 1 h
8. `pre_anim` y `s3_coste_cruce`: pasar de tiempo de CPU a recuentos. 0,5 h
9. Seguir la caza de frágiles por las partes 0-5 (`cazar_fragiles.py`). 1 h
10. Cobertura de funciones: subir `entrenamiento`, `club_dentro`, `cantera_p2`. 0,5 h
11. Guardado: más versiones de partidas viejas (`sav_fosiles`) y migraciones. 0,5 h
12. Textos: 9 idiomas sin marcas sueltas y sin desbordes en móvil. 0,5 h

## Pista C — PLATAFORMAS, CI Y CÓDIGO (sesión plataformas)
1. #197; 7.ª parte del CI; job nocturno con `ESPECIALES_ORDEN=aleatorio`. 1 h
2. Sonar en el CI y `paths-ignore` para PR solo de documentos (requieren OK del dueño: preparar sin activar). 0,5 h
3. Duplicación de código (M-391): los 10 archivos con más líneas duplicadas del informe de Sonar. 2 h
4. Scripts cerca del tope (> 400 líneas): partir antes de que pasen de 450. 1 h
5. Mantener 0 issues en `main` tras cada fusión (informe periódico con `sonar_informe.py`). 0,5 h
6. CI más rápido (35 → 25 min): cachés de importación y LFS, reparto por tiempo. 1 h
7. Tamaños de build por plataforma y recursos sin usar (`recursos_sin_usar.md`): solo informe, no borrar. 1 h
8. Acciones de GitHub a versiones que corren en Node 24 (aviso de obsolescencia). 0,5 h
9. Humo en Linux/Android ARM y memoria en Web. 0,5 h

## Pista D — LÍDER (esta sesión)
1. Revisión horaria: fusionar lo verde, empujar o archivar sesiones, CI rojo por causa raíz.
2. Idea del dueño: personal del club quieto con conversación 2D (3D animado solo en cinemáticas y eventos), ciudadanos simples, multitudes baratas: decidir con la tabla de la pista A.4.
3. Velocidad de carga: crear los visores 3D de los menús (mascota, estudio del personaje) solo al abrir/mostrar; medir.
4. Consejos de la pantalla de carga: revisar traducciones y que avancen en todos los idiomas.
5. Creador de personaje: pasada pendiente (cuerpo femenino, peinados, caras); decide el dueño con capturas (DEJADO PARA DESPUÉS).
6. Registro: este documento y `PLAN_GENERAL.md` al día; lo hecho se BORRA.
