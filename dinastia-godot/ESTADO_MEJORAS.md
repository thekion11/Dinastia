# ESTADO DE LAS MEJORAS · 17-10-2026

Repaso de los 470 puntos de `INFORME_MEJORAS.md` (14-10-2026) **contra el código actual** de la rama, más la lista del dueño `instruciones profundas/300-ideas-juego-futbol-manager-1.md` (350 ideas numeradas). Se buscó cada punto en `nucleo/`, `visor/`, `ui/`, `pruebas/` y `herramientas/` con búsquedas de texto y lectura de las funciones; el título del informe no basta para darlo por hecho. Fuentes de apoyo: `git log` desde el 14-10, `MEGA_AUDITORIA_2.md`, `COMPARACION_JUEGOS_2.md` y la memoria (`CLAUDE.md`).

**Leyenda.** HECHO = está en el código (se cita dónde) · PARCIAL = existe una parte (se dice qué falta) · PENDIENTE = no se encontró nada · 🔒 DUEÑO = builds, licencias, keystore, FPS en hardware real, música o voces · SIN VERIFICAR = no se pudo confirmar en esta pasada.

**Límites de esta pasada.** Es una verificación por lectura y búsqueda, sin abrir el juego. Un PENDIENTE significa «no se encontró»; el proyecto ya tuvo falsos negativos (ver LEEME, 13-9), así que antes de construir algo marcado así conviene un segundo grep. Dos puntos que el informe daba por faltantes ya existían antes del 14-10: `_probar_negociacion` (M-212) y `_probar_logros` (M-255).

## 0. Pasada del 20-10-2026 (pedido: «pulir lo de los más de 300 puntos»)

Estado contado sobre las filas de este documento tras la pasada: **HECHO 94 · PARCIAL 113 · PENDIENTE 245** (el 17-10: 49 · 119 · 284). La tabla de la sección 1 es la del 17-10 y se deja como referencia.

Cerrados en esta pasada (cada uno con prueba o captura): público (M-034 piel por país, M-036 onda y ola, M-045 protesta, M-047 colores del club, M-049 siguen el balón), partido (M-119 lectura del lanzador en la tanda, parcial; M-127 gestión del tiempo; M-137 xA; M-139 añadido por entradas duras; M-162 CSV), gestión (M-224 camisetas del ídolo, M-227 mantenimiento, M-228 imprevistos de obra, M-237 capitán votado, M-246 alineación indebida), interfaz (M-288 fondos ligeros, M-301 autoguardado visible, M-309 créditos), textos y datos (M-240 política/religión, M-331 tocayos, M-335 glifos), código y pruebas (M-358 FPS, M-381 prints, M-389 reimportar, M-395 requirements, M-412 guardados estropeados). Ya hechos antes y marcados ahora: M-104, M-114, M-115, M-123, M-132, M-151.

### Pasada del 21-10 (segunda, secciones A-F)

Estado tras ella: **HECHO 102 · PARCIAL 111 · PENDIENTE 239**. Cerrados: M-021 sector visitante, M-059 reparto de marcas, M-062 escudos únicos, M-073 brazalete de capitán (no se ponía nunca y con la base real no había capitanes), M-098 la cabeza sigue al balón, M-105 protesta al ver tarjeta, M-107 jueces de línea con el penúltimo defensor, M-175 faros y luces de freno; parciales: M-085 canas, M-102 banquillo ante la roja, M-183 menos gente de madrugada.

### Pasada del 21-10 (tercera: hallazgos del vídeo de gameplay, informe técnico y piezas modulares)

Estado tras ella: **HECHO 104 · PARCIAL 114 · PENDIENTE 234** (contado fila a fila); con la 4.ª (fabricantes M-057, motor del coche M-173, práctica libre M-130, ropa del público M-033, cuerpos M-081 y la pantalla gigante M-011, que ya estaba): **HECHO 110 · PARCIAL 115 · PENDIENTE 227** (con la presión por gatillos, M-124). Hallazgos del vídeo: pocas ocasiones (M-138: ritmos y `prisa`), controles táctiles en PC (M-433), el mentor tapaba la rueda de prensa (`MentorVoz` espera, grupo `no_tapar_mentor`), haces de farola en triángulo (M-014), malabares rehechos con racha ×2/×3/×4, manos del público del color de la ropa (`hinchada.gdshader`). Informe técnico: oclusión de la ciudad (M-344), panel de objetivos por señal (M-386), texturas revisadas (M-346). Pedido del dueño «reusar todos los objetos, separar y unir de forma modular»: `visor/modulos.gd` (reserva para reciclar, unir/separar conjuntos, guardarlos como datos, teñir por material) y el edificio del club amueblado con él (M-186), con 7 objetos de decoración nuevos.

## 1. Resumen en cifras

| Sección | Puntos | HECHO | PARCIAL | PENDIENTE | 🔒 DUEÑO | SIN VERIF. |
|---|---:|---:|---:|---:|---:|---:|
| A. Estadios y entorno | 32 | 1 | 12 | 19 | 0 | 0 |
| B. Público y ambiente | 18 | 0 | 6 | 12 | 0 | 0 |
| C. Camisetas, escudos y marcas | 28 | 2 | 5 | 21 | 0 | 0 |
| D. Jugadores, caras, cuerpos y animaciones | 34 | 1 | 13 | 19 | 0 | 1 |
| E. Partido: física, IA, controles, cámara, presentación | 54 | 7 | 18 | 28 | 0 | 1 |
| F. Ciudad, vehículos, metro, interiores | 40 | 5 | 8 | 26 | 0 | 1 |
| G. Gestión del club | 56 | 8 | 20 | 26 | 0 | 2 |
| H. Carrera de Jugador | 14 | 2 | 2 | 9 | 0 | 1 |
| I. Interfaz, menús, accesibilidad | 36 | 6 | 14 | 15 | 0 | 1 |
| J. Audio y música | 12 | 0 | 3 | 7 | 2 | 0 |
| K. Idiomas y textos | 12 | 4 | 2 | 6 | 0 | 0 |
| L. Rendimiento y optimización | 22 | 2 | 6 | 12 | 2 | 0 |
| M. Datos y contenido | 20 | 5 | 1 | 13 | 0 | 1 |
| N. Código y arquitectura | 24 | 1 | 2 | 19 | 0 | 2 |
| O. Pruebas y herramientas | 16 | 2 | 3 | 11 | 0 | 0 |
| P. Repositorio, build y legal | 14 | 1 | 2 | 7 | 4 | 0 |
| Q. Móvil, táctil y mando | 10 | 0 | 1 | 9 | 0 | 0 |
| R. Pasada 3 | 28 | 2 | 1 | 25 | 0 | 0 |
| **Total** | **470** | **49** | **119** | **284** | **8** | **10** |

Hecho 10 % · parcial 25 % · pendiente 60 % · del dueño 2 % · sin verificar 2 %. El 14-10 había 15 marcados ✅; lo que se sumó después vino sobre todo de la MEGA AUDITORÍA 2 (fachadas, duelos, faltas, VAR, transmisión, estadísticas, LOD, equipación 3D, metro, puentes, idiomas). La mayoría de los PENDIENTES son puntos «I» (inferidos) que nadie ha tocado: público, marcas/escudos, audio, accesibilidad, móvil y pruebas.

## 2. Los 470 puntos, sección por sección

### A. Estadios y entorno (M-001 … M-032) · HECHO 1 · PARCIAL 12 · PENDIENTE 19

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-001 | P0 | Exterior de estadio = caja gris con cuatro torres | HECHO | `visor/fachada_estadio.gd` (16-10): 6 estilos, rampas, puertas con rótulo, escudo en fachada, cubierta vista |
| M-002 | P1 | Solo 6 formas de estadio para 384 clubes | PENDIENTE | ninguna de las formas nuevas (`anfiteatro`, `doble_anillo`…) existe en `stadium_builder.gd` |
| M-003 | P1 | Las formas no varían de forma continua | PENDIENTE | `RETRANQUEO_BANDEJA` sigue siendo constante; sin parámetros por club |
| M-004 | P1 | El «estadio real» sólo copia forma/niveles/techo/pista/focos/fachada | PENDIENTE | `ESTADIOS` de `herramientas/estadios_reales.py` sin color de pista/vallas, año ni pantalla |
| M-005 | P1 | Colores propios de butacas en 47 de 176 estadios reales | PENDIENTE | `ASIENTOS` sigue con 47 de 176 estadios |
| M-006 | P2 | Entorno vacío alrededor del estadio (sólo ciudad propia lo tiene) | HECHO | 21-10: `visor/entorno_estadio.gd` en el partido y la Carrera: hierba hasta el horizonte, plaza con mástiles y banderas del club, avenida con farolas y árboles, dos aparcamientos con coches y 64 edificios de fondo (Kenney); además, las formas sin grada de esquina («rect», «principal») cierran las esquinas con un edificio de servicios con fachada; captura `captura_exterior` |
| M-007 | P2 | Sin variación de entorno por país (palmeras, nieve, montaña de fondo) | PENDIENTE | sin fondo lejano por país/clima en el estadio |
| M-008 | P2 | Tribunas «falsas» por falta de profundidad en el graderío | HECHO | vomitorios (`StadiumBuilder._vomitorios`); 21-10: pasillos con peldaños y barandilla cada 8 grupos de butacas (`_montar_pasillos`), escaleras de acceso desde el césped (`_escaleras_de_acceso`), cinta LED en el peto de la bandeja alta (`cinta_led.gdshader`); se sube caminando a la butaca (`RecorridoClub.camino_a_butaca`); capturas `captura_diagnostico_grada`, `captura_sentarse` |
| M-009 | P2 | Sin voladizo/cubierta visible en estadios sin techo | PARCIAL | techo «visera» y cerchas vistas desde fuera (`FachadaEstadio`); sin visera parcial con estructura por sector |
| M-010 | P2 | Sin carteles de pared (patrocinadores, fechas, escudo) fuera del campo | PENDIENTE | sin carteles en muros exteriores (la fachada tiene rótulos de puerta, no publicidad) |
| M-011 | P1 | Marcador/pantalla gigante estática | HECHO | revisado 21-10: era un falso pendiente: `VistaEstadio._montar_pantalla` pone en las pantallas el lienzo vivo de `ui/pantalla_estadio.gd` (marcador con escudos y abreviaturas, estadísticas, goleadores, tabla, pichichis en rotación y «¡GOL!» a pantalla completa); `_pantalla_textura` solo es el fondo hasta que se monta |
| M-012 | P2 | Vallas LED con la misma rotación de marcas inventadas (30) | PENDIENTE | `VallasLed` sin catálogo ampliado; `Auspicio` tiene 38 marcas |
| M-013 | P2 | Banderas de esquina/córner genéricas | PARCIAL | banderines con tela y color del asiento del estadio (`_corners`); sin banderola del país ni viento |
| M-014 | P1 | Sin diferencia día/noche en el aspecto de la iluminación… | PARCIAL | 21-10: el haz de cada farola de la ciudad es un cono volumétrico falso con degradado y sin contorno (`visor/cono_farola.gdshader`); sin haces de los focos del estadio |
| M-015 | P2 | El césped usa 12 dibujos, asignación por hash | PENDIENTE | el dibujo de césped sigue por hash (`Club._CESPED`); no hay campo en estadios reales |
| M-016 | P2 | Sin campo de entrenamiento/calentamiento visible fuera del estadio | PENDIENTE | sin campo anexo con calentamiento |
| M-017 | P1 | Túnel de vestuario sólo en +Z | PENDIENTE | túnel fijo en la tribuna +Z (`tunel_x`) |
| M-018 | P2 | Banquillos de un solo diseño por preset | PENDIENTE | `EST_BANQUILLOS` sin ampliar |
| M-019 | P2 | Sin zona de prensa/cabinas de TV visibles en el graderío | PARCIAL | cabina de prensa en `estadio_extras.gd`; sin vidrio ni NPC de prensa dentro |
| M-020 | P2 | Sin palcos reales (`palcos` existe como instalación) | PARCIAL | palcos como pieza de `estadio_extras.gd` y `ClubDentro.PALCO`; sin interior con personas |
| M-021 | P2 | Sin zona de aficionados visitantes diferenciada | HECHO | 21-10: en partido, un cuarto de la bandeja baja del fondo −Z con los colores del rival y una franja de butacas vacías que lo separa (`est.visita1/2`, `sector_visita`); captura `captura_sector_visita` |
| M-022 | P2 | Sin sonido espacial por sector (cantos locales vs visitantes) | PENDIENTE | no existe ningún `AudioStreamPlayer3D` en el juego |
| M-023 | P3 | Sin clima visible en el estadio más allá de lluvia/niebla (nieve,… | PARCIAL | nieve, lluvia y niebla (`Precipitacion`, `Clima`); sin calima/polvo ni charcos que reflejan |
| M-024 | P2 | Sombras de la grada sobre el campo no cambian con la hora real del… | PARCIAL | `Ambience` usa la hora elegida para el estadio, no la hora/estación real del partido |
| M-025 | P2 | Poca variedad de torres de luz (4 esquinas) | PARCIAL | focos «corona/mixto/halo» además de torres; no 6/8 torres por forma |
| M-026 | P3 | Estadios sin nombre dibujado en fachada | PARCIAL | rótulos en las puertas de la fachada; sin nombre grande del estadio por tipografía de club |
| M-027 | P2 | Sin variación de terreno exterior (cerro, mar, río) según `rasgo` | PENDIENTE | el texto `rasgo` no elige fondo ni niebla |
| M-028 | P2 | El estadio propio y el rival usan caminos de construcción… | PARCIAL | `pruebas/captura_mismo_estadio.gd` (manual); no está en el banco |
| M-029 | P2 | Ampliaciones del estadio propio sin animación de obra detallada | PARCIAL | andamios, grúa torre y vallado (`estadio_extras.gd`, `EstadioPropio.obra`); sin polvo ni operarios |
| M-030 | P3 | Sin estadio nacional/selección con identidad propia | PENDIENTE | sin sedes de selección con arquitectura propia |
| M-031 | P2 | Sin mapa de estadios (galería) para ver todos los del juego | PENDIENTE | sin pantalla «Estadios del mundo» |
| M-032 | P2 | Sin ficha de estadio con datos reales (capacidad oficial, año,… | PARCIAL | aforo OFICIAL en la ficha (`ui/estadio.gd:544`); faltan año y superficie |

### B. Público y ambiente (M-033 … M-050) · HECHO 0 · PARCIAL 6 · PENDIENTE 12

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-033 | P1 | Los hinchas comparten malla por pose; sólo cambia color de camiseta | HECHO | 21-10: además del color por instancia, bufandas a franjas y gorras: camiseta del club a rayas (1 de 5), chaqueta abierta con cremallera (1 de 7) y sudadera con capucha (1 de 8), pelo de 5 tonos y calvos (`hinchada.gdshader`); captura `captura_diagnostico_grada` |
| M-034 | P1 | Pelo/piel por azar sin población real | HECHO | 20-10: `OlaGrada.PIEL_SESGO` por país del club de casa (24 países) → `piel_sesgo` en `hinchada.gdshader` (DT y Carrera); aproximación, no dato por persona |
| M-035 | P1 | Sin bufandas/banderas/camisetas del club en la mano | PARCIAL | banda de bufandas y tifo en grada (`StadiumBuilder` «bufandas»/«tifo»); sin mallas en la mano |
| M-036 | P2 | Animación del público: balanceo uniforme + saltos | HECHO | 20-10: onda de saltos desde el fondo del gol local y la ola (`visor/ola_grada.gd`, uniformes en `hinchada.gdshader`); captura `captura_ola` |
| M-037 | P2 | Sin sector «barra brava»/torcida con comportamiento diferente (de… | PENDIENTE | sin sector ultra con bengalas/humo |
| M-038 | P2 | Hinchas sentados con piernas invisibles (se cortan en la cadera) | PENDIENTE | público horneado cortado en la cadera |
| M-039 | P2 | Tres niveles de detalle; el salto «cerca→medio→lejos» puede verse | PARCIAL | detalle por distancia por tramos de grada (16-10, 2,24→1,72 M tris); sin mezcla por dithering |
| M-040 | P2 | Sin personas del club/ciudad reconocibles en primeras filas (pedido) | PENDIENTE | pendiente según MEGA_AUDITORIA_2 §2 |
| M-041 | P2 | Sin niños, familias ni asistentes en sillas de ruedas | PENDIENTE | sin niños/familias/sillas de ruedas en grada |
| M-042 | P2 | Ocupación = reputación, no asistencia del partido | PARCIAL | ocupación = asistencia de `Finanzas` (depende del precio); no por sector |
| M-043 | P2 | Sin diferencia de público por competición (final vs liga) | PENDIENTE | sin decoración especial en finales |
| M-044 | P2 | Gol local: ceremonia de público única | PARCIAL | 20-10: además del confeti/bengalas, onda de saltos desde ese fondo, la ola con el partido decidido y la protesta; falta variar por sector |
| M-045 | P2 | Sin reacción del público a decisiones (silbidos al árbitro, VAR) | HECHO | 20-10: «protesta» (todos de pie agitando los brazos 3 s) con tarjeta a uno de casa y gol local anulado por el VAR, además del abucheo de `Sonido` |
| M-046 | P3 | Sin multitudes en accesos, tienda y museo del estadio | PENDIENTE | sin flujo de NPC antes/después del partido |
| M-047 | P2 | Colores de hincha con 14 tonos (hoy) | HECHO | 20-10: ~6 de cada 10 con los colores del CLUB (`est.hincha1/2` desde `StadiumBuilder.build`; antes eran los de las butacas), resto ropa de calle |
| M-048 | P2 | Fotógrafos/camarógrafos pocos y repetidos | PARCIAL | `visor/camarografos_siguen.gd` (giran con el balón, uno camina); siguen siendo pocos |
| M-049 | P2 | Sin aficionados que se levantan/siguen el balón con la cabeza | HECHO | 20-10: cabeza y hombros giran hacia el balón (`balon_pos`/`mira_balon` en `hinchada.gdshader`, `OlaGrada.mirar` cada 4 fotogramas en DT y Carrera); se levantan con la ola/onda/protesta |
| M-050 | P3 | Sin streamers de papel, confeti ni bengalas | HECHO | 17-10: `FestejoGrada` (confeti con los colores del club + bengalas con humo sobre el público real) en goles del local y en la salida; apagado con motor ligero, MEDIO solo confeti |

### C. Camisetas, escudos y marcas (M-051 … M-078) · HECHO 2 · PARCIAL 5 · PENDIENTE 21

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-051 | P1 | El escudo en la camiseta mide ~8 cm y es plano | HECHO | 17-10: 10,4 cm de ancho (+18 % de lado, ≈ +40 % de superficie), algo más arriba, y bordado de ~0,7 mm con normal falsa por derivadas (`h_escudo` en `equipacion_q.gdshader`), solo de cerca |
| M-052 | P1 | Camiseta pintada sin tejido | HECHO | tela satinada y micro relieve del tejido (`equipacion_q.gdshader`, 17-10) |
| M-053 | P1 | Cuello y puños sólo por color | HECHO | cuello pico/redondo/polo/mao con ribete y puños (`equipacion_q.gdshader`, 17-10; por shader, no geometría) |
| M-054 | P1 | Ropa con volumen sólo en retratos (K-02) | PENDIENTE | `VestidorQ.ropa_aparte` sigue apagado en partido por coste |
| M-055 | P1 | Sin arrugas dinámicas según animación | PARCIAL | pliegues de tela estáticos (`pliegues()` en el shader); no dependen de la animación |
| M-056 | P2 | Sin sudor/barro/lluvia en la camiseta | PENDIENTE | sin uniform de barro/mojado |
| M-057 | P1 | Marca de ropa genérica (tick) | HECHO | 21-10: cada fabricante ficticio (Korrida, Astra Sport, Nimbo, Salto, Volkspor y la marca propia) tiene su logo en el pecho de la camiseta 3D (`equipacion_q.gdshader` `marca_forma`); tu club lleva el proveedor firmado y los demás uno fijo por club (`DisenosKit.marca_de`); captura `captura_marcas`, banco en `_probar_marcas_y_escudos` |
| M-058 | P1 | 30 marcas de patrocinio (K-03) | PARCIAL | 38 marcas en `Auspicio` (antes 30); meta 70 |
| M-059 | P1 | Reparto de marcas sesgado (arreglado el hash hoy, ✅) | HECHO | 21-10: `_probar_marcas_y_escudos` en un mundo de 352 clubes: ninguna marca pasa del doble de la media (la que más, ×27 con media 20) |
| M-060 | P2 | Patrocinio fijo por club entre temporadas, sin contratos de IA que… | PENDIENTE | sin renovación/cambio de patrocinador de clubes IA |
| M-061 | P2 | Sin patrocinador en la parte trasera del pantalón ni en las medias | PENDIENTE | sin zonas `short_trasero`/`medias` |
| M-062 | P1 | Escudos: 188 combinaciones únicas para 384 clubes (C-03) | HECHO | 21-10: comprobado en el banco: forma + dibujo + colores + iniciales/símbolo no se repiten en 352 clubes (la cuenta de 188 era sin colores) |
| M-063 | P1 | Escudos reales sólo 26 (7 %) | PENDIENTE | `ESCUDOS` sigue con 26 clubes |
| M-064 | P2 | Falta ornamento reconocible (león, águila, estrella, castillo,… | PENDIENTE | sin biblioteca de símbolos (solo el almenado) |
| M-065 | P2 | Texto/iniciales ilegibles <24 px | PENDIENTE | sin prueba de legibilidad a 24 px |
| M-066 | P2 | Escudo sin variante monocroma (para periódico, marcador) | PENDIENTE | sin `Escudo.mono` |
| M-067 | P2 | Sin escudo animado en el marcador al gol | PENDIENTE | sin pulso del escudo en el marcador |
| M-068 | P1 | Diseño de camiseta por hash en el 63 % de clubes (ya hay tabla… | PENDIENTE | `CAMISETAS` con 63 clubes |
| M-069 | P2 | 12 diseños con reparto casi uniforme (C-06) | PENDIENTE | sin pesos en el reparto de diseños |
| M-070 | P2 | Sin segunda/tercera camiseta con diseño propio | PENDIENTE | sin tercera equipación |
| M-071 | P2 | Portero: color por contraste, sin diseño | PENDIENTE | portero solo por contraste; guantes como color de accesorio |
| M-072 | P2 | Árbitros siempre iguales | HECHO | 17-10: `Puente3D.kit_arbitro` (8 camisetas; la que más contrasta con los dos equipos y los porteros, estable por partido) |
| M-073 | P2 | Sin brazalete de capitán visible a distancia | HECHO | 21-10: el brazalete NO se ponía nunca (el shader lo tenía, nadie lo activaba) y con la base real ningún club tenía capitán. Ahora cada club tiene capitán al generarse, la cinta la hereda el veterano del once si el capitán no juega (`Puente3D.once`), y el brazalete (amarillo, o blanco con camiseta amarilla, más ancho) va en una copia del material (`PlayerSpawner.poner_brazalete`) |
| M-074 | P2 | Medias/pantalón: diseño correcto pero sin franjas del fabricante | PENDIENTE | sin franjas del fabricante en medias/pantalón |
| M-075 | P2 | Dorsal sin fuente propia por club | PENDIENTE | dorsal en siete segmentos, una sola fuente |
| M-076 | P3 | Sin parches de competición (campeón, copa) | PENDIENTE | sin parches de competición |
| M-077 | P2 | Retrato con camiseta de volumen pero sin patrocinio en pecho visible | PENDIENTE | encuadre del retrato sin cambiar |
| M-078 | P2 | Foto real de equipación sólo con pack real (C-08) | PARCIAL | 2D y 3D con cuello/costuras desde el 14/17-10; diferencia con foto real sigue |

### D. Jugadores, caras, cuerpos y animaciones (M-079 … M-112) · HECHO 1 · PARCIAL 13 · PENDIENTE 19 · SIN VERIFICAR 1

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-079 | P1 | Retrato real 13 % (base real) | PENDIENTE | 13 % con retrato real; descarga bloqueada por la red |
| M-080 | P2 | Fotos agachadas aún oscuras/deformadas | PENDIENTE | fotos agachadas sin re-detección (límite anotado en MOTOR_CARAS.md) |
| M-081 | P1 | Todos con el mismo cuerpo base | HECHO | 21-10: cada futbolista con su complexión y hombros según su FÍSICO más una variación fija por jugador (`PersonajeDT.aspecto_futbolista` / `cuerpo_futbolista`, en `PlayerSpawner._crear_jugador`); estatura ya era la de su ficha; captura `captura_marcas` (del 89 al 33 de físico) |
| M-082 | P2 | Altura sólo por escala global | PENDIENTE | sin proporciones variables |
| M-083 | P2 | Sin tatuajes/cicatrices por jugador salvo civiles | PARCIAL | tatuaje solo en ropa civil (`equipacion_q.gdshader` `tatuaje`); no en jugadores |
| M-084 | P2 | Biblioteca de caras = 72 mezclas | PENDIENTE | biblioteca de 72 caras |
| M-085 | P2 | Envejecimiento visual de jugadores (canas, arrugas) no ligado a `edad` | PARCIAL | 21-10: canas desde los 32 en los inventados (`Cara.look_de`, a uno de cada cuatro casi nada); los reales llevan el color de su foto; arrugas pendientes |
| M-086 | P2 | Expresiones faciales limitadas a `Expresion` básica | PENDIENTE | `Expresion` sin emociones nuevas |
| M-087 | P2 | Sin parpadeo/respiración idle variados | PARCIAL | parpadeo en el DT/`Expresion`; sin respiración idle en jugadores |
| M-088 | P1 | Pelo con 30 cortes pero poca variación de color/aspecto por país | PENDIENTE | sin tabla de pelo por país |
| M-089 | P2 | Barbas/cejas por capas apagadas (manchas) | PENDIENTE | barba/cejas por capas siguen apagadas |
| M-090 | P2 | Guantes de portero sólo color | PENDIENTE | sin geometría de guante |
| M-091 | P1 | Botines: variedad añadida, pero sin modelos distintos por forma | PARCIAL | `VestidorQ._botin_de` varía modelo/color por dorsal; no hay mallas de bota alta/calcetín |
| M-092 | P2 | Cordones/tacos sin geometría | PENDIENTE | sin relieve de cordones/tacos |
| M-093 | P2 | Sin canilleras/vendas/cintas visibles | PENDIENTE | sin canilleras/vendas en partido |
| M-094 | P1 | Animación de caminata del DT: 6 estilos (✅) | PARCIAL | «Mi caminata» con 6 estilos para el DT; peatones y jugadores no |
| M-095 | P1 | 335 clips; muchos sin uso en partido | PENDIENTE | sin auditoría automática de clips usados |
| M-096 | P2 | Transiciones entre clips con mezcla fija 0,25 s | PENDIENTE | mezcla fija entre clips |
| M-097 | P2 | Retarget con pies que patinan | PARCIAL | IK de piernas solo en la ciudad (`AnimQuaternius._ik_pierna`); sin foot locking en partido |
| M-098 | P2 | Sin IK de mirada (cabeza sigue balón) | HECHO | 21-10: `visor/mirada_balon.gd`: un `LookAtModifier3D` en el hueso Head de cada jugador apuntando al balón (topes 65°/30°, suavizado 0,5 s), en el modo DT y en la Carrera; comprobado con `captura_mirada` (balón a un lado y al otro) |
| M-099 | P2 | Cuerpos sin colisión entre brazos/piernas (solapes sólo en XZ) | PARCIAL | cuerpos que se empujan y duelos en el motor (`MotorJugable._cuerpos`, 17-10), en 2D; sin cápsulas 3D |
| M-100 | P2 | Sin respiración/cansancio visible (manos a rodillas) | HECHO | `MotorJugable` pone el clip «cansado» (manos a rodillas) con forma < 0,6 (l.3440) |
| M-101 | P2 | Celebraciones por rasgo (ya) pero sólo 2/3 propias | PARCIAL | carrera al córner y abrazo (`_ia_celebracion`); sin 10 por rasgo ni coreografías |
| M-102 | P2 | Sin reacciones de banquillo coordinadas | PARCIAL | celebra el gol (`_banca_celebra`); 21-10: protesta la roja de uno de los suyos (`_banca_protesta`); falta la lesión |
| M-103 | P2 | Lesiones sin animación específica | PARCIAL | clip de dolor (`AnimQuaternius`); sin camilla ni médicos en campo |
| M-104 | P2 | Cambios de jugador sin animación (entra/sale) | HECHO | 17-10, con motor: cartel LED del cuarto árbitro con los dos dorsales (`CuartoArbitro.levantar_cambio`), el que entra espera en la banda, el que sale camina hasta él, palmada (`chocar_mano`) y se va (`visor/escena_cambio.gd`). 20-10: también en la Carrera de Jugador (`PartidoJugable._escena_cambio`) |
| M-105 | P2 | Sin tarjetas con ceremonia de árbitro detallada | HECHO | 21-10: con cada tarjeta el amonestado protesta mirando al árbitro (`discutir_arbitro`, `MotorJugable._protestar`) mientras este habla y enseña la cartulina |
| M-106 | P1 | Árbitro con sólo gestos básicos | HECHO | 17-10: en el motor real pita, señala la falta, ventaja de verdad, habla y enseña la tarjeta (cartulina en la mano), penal, córner, saque de puerta, añadido y final (`MotorJugable._gesto_arbitro`) |
| M-107 | P2 | Asistentes de línea sin carrera real | HECHO | 21-10: cada juez de línea se coloca a la altura del penúltimo defensor o del balón si está más adelante (`MotorJugable.linea_fuera_de_juego`) |
| M-108 | P2 | Mascotas con animación limitada | SIN VERIFICAR | `MascotaQ` tiene animaciones propias; no se comprobó si son 6 ni si hay rutas |
| M-109 | P2 | Niños de ceremonia con una misma malla | PARCIAL | niños con cuerpos de peatones variados (`CeremoniaPartido`); sin comprobar variedad de malla |
| M-110 | P2 | Sin voces/murmullos de jugadores | PENDIENTE | sin voces de jugadores |
| M-111 | P3 | Sin modo foto con poses y expresión (existe `ModoFoto`) | PENDIENTE | `ModoFoto` sin poses ni editor de expresión |
| M-112 | P2 | Sin avatar del usuario en el estadio como jugador (carrera) con su… | PENDIENTE | la Carrera de Jugador no usa el cuerpo del creador |

### E. Partido: física, IA, controles, cámara, presentación (M-113 … M-166) · HECHO 7 · PARCIAL 18 · PENDIENTE 28 · SIN VERIFICAR 1

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-113 | P1 | Sesgo de local (M-01): con N=100 no existe (antes 0,63–0,67,… | HECHO | ✅ 15-10 (sesgo de local corregido) |
| M-114 | P1 | Teletransportes del balón en sonda (M-02) | HECHO | 19-10: conducción que recoge el balón (toque ≤ 0,25 m), atajada sin salto a las manos; sonda: balón saltando en juego 3 → 1 (PENDIENTES 2.1) |
| M-115 | P1 | Giros >720°/s (465) | HECHO | 19-10: `_mirar` con `GIRO_RAPIDO` al patear y en filigranas, tope de aceleración `A_MAX`; sonda: giros > 720°/s 3 → 0; `_probar_fisica_motor` en el banco |
| M-116 | P1 | Sin duelos con contacto (M-03) | HECHO | duelos de hombro, balón dividido y agarrón (`MotorJugable._duelo_*`, 17-10) |
| M-117 | P1 | Faltas sin lógica de contacto real (sólo azar) | HECHO | faltas por entrada al tobillo/llegar tarde (`_falta`); ~8,8 por partido (17-10) |
| M-118 | P1 | Fuera de juego sólo por posición en el instante (✅ base) | HECHO | el VAR decide con la posición real (`margen_gol`) y desde el 17-10 dibuja las dos líneas y el margen en cm en el monitor de la sala (`lineas_gol`) |
| M-119 | P1 | Penales: el portero «decide una vez» pero sin lectura del lanzador | PARCIAL | 20-10: en la TANDA el portero de la IA se tira más al lado natural del pie del lanzador (46/36/18) y, según sus reflejos (4-16 %), lee la carrera (`_lado_portero_tanda`); falta en los penales del partido |
| M-120 | P2 | Córners con 3 variantes | PARCIAL | receptor/2.º/3.er lanzador en córners (14-10); sin jugadas ensayadas de `CatalogoJugadas` |
| M-121 | P2 | Tiros libres: barrera simple | PARCIAL | barrera de 4 a 9,15 m fija |
| M-122 | P2 | Sin saque de banda largo/estratégico | PARCIAL | saque de banda largo del usuario (X); sin atributo |
| M-123 | P1 | IA: no hay trampa de fuera de juego, cobertura ni basculación (M-04) | HECHO | 19-10: `_linea_defensiva` común (recula/sube) y trampa (`tactica.trampa`); con trampa el rival cae en fuera de juego 0,42 → 0,75 por partido |
| M-124 | P1 | Pressing por zonas sin gatillos | HECHO | 21-10: gatillos de presión (`MotorJugable._gatillo_presion`): recién recibido, pegado a la banda, de espaldas o salida de balón cerca de su área; con ellos sale a morder hasta el equipo que espera y con presión media van dos; sonda táctica: ofensivo 5/2/1, defensivo 2/0/6, simetría 2,7 goles |
| M-125 | P2 | Sin tácticas de medio campo (doble pivote, falso 9) | PENDIENTE | sin roles con comportamiento propio |
| M-126 | P2 | Cambios de IA por cansancio (60/70/80') fijos | PARCIAL | DT rival cambia en 60/70/80' y ajusta la pizarra según marcador (`_dt_rival`); minutos fijos |
| M-127 | P2 | Sin gestión de tiempo (perder tiempo, acelerar) | HECHO | 20-10: desde el 75' la CPU que gana tarda ×2,2 en cada saque (sin saques rápidos) y la que pierde saca ×0,6 (`_ritmo_de_saque`); el equipo del usuario no |
| M-128 | P2 | Portero con salidas sólo en mano a mano | PARCIAL | colocación y achique del portero (14-10); sin salidas aéreas |
| M-129 | P2 | Sin lanzamientos de larga distancia ni centros desde banda con… | PARCIAL | los atributos pesan en el motor (`_atributos`); sin parámetro de precisión por tipo de envío |
| M-130 | P2 | Controles FC mapeados (65+ combinaciones) sin tutorial interactivo | HECHO | 21-10: «Práctica libre» en la sala de minijuegos (Mi Vida): tu equipo contra un rival que no presiona, sin reloj, el balón del rival vuelve a tus pies y tomas el mando al entrar (`MotorJugable.empezar_practica`, `VistaEstadio.abrir_practica`); prueba `prueba_practica.tscn` |
| M-131 | P2 | Ayudas de asistencia (pase/tiro) con 3 niveles | PARCIAL | ayudas por pieza (asistido/manual, auto/semi/manual) en `Mando`; sin perfiles Arcade/Semi/Manual |
| M-132 | P2 | Sin repetición manual del usuario | HECHO | 20-10: G / Share (`jugar_repeticion`) y botón «⟲ Repetición» en la pausa (`VistaEstadio.repetir_jugada`, últimos 10 s) |
| M-133 | P1 | Cámara TV sin zoom automático al área | HECHO | `CameraRig._transmision` cierra en área, ocasión y córner (16-10) |
| M-134 | P2 | Sin cámaras de repetición cinematográficas (grúa, dron) | PARCIAL | cámaras «Dron orbital» y otras en el rig; la repetición no alterna planos |
| M-135 | P2 | Sin cámara de gol del cuarto árbitro/línea | PENDIENTE | sin cámara de línea de gol |
| M-136 | P2 | HUD del partido con FC-style indicadores; sin heatmap/estadísticas… | HECHO | `PanelEstadisticas` (T/Select) con mapa de tiros y de calor (16-10); falta mapa de pases |
| M-137 | P2 | Sin xG ni xA | HECHO | xG por remate (`EstadisticasVivo.xg_de`); 20-10: xA (el pase previo se lleva el xG del remate: `xa`, `xa_por_jugador`) y fila «Asistencias esperadas (xA)» en los 9 idiomas |
| M-138 | P1 | Ritmo del partido ≈ 54 s/s vs 11 s/s (M-07) | HECHO | 21-10: ritmos del DT a 4 / 5,5 / 7,5 s por minuto (el «normal» ≈ 10 min, como FC) y `MotorJugable.prisa()` compensa las mitades cortas: 247 s → 2,6 goles y 15 tiros (antes, a ritmo normal, 1,3 goles y el vídeo acabó 0-0) |
| M-139 | P2 | Tiempo añadido con base real pero sin descuentos por lesión visibles | HECHO | 17-10: cartel 3D del cuarto árbitro (`CuartoArbitro`; 20-10 a tamaño real); 20-10: cada entrada dura (nivel de amarilla o más) suma medio minuto de atención (`MotorJugable._falta`), además de goles, cambios y expulsiones |
| M-140 | P2 | Descanso: charla de medio tiempo con opciones; sin vestuario 3D… | PENDIENTE | el descanso vuelve al camarín 2D (`prueba_descanso_3d`); sin cinemática de vestuario |
| M-141 | P2 | Resumen de partido sin mapa de calor ni valoraciones por jugador… | HECHO | 17-10: `Partido.valoraciones()` (determinista, sin `Azar`) en `ResumenPartido` (mejor del partido en franja dorada + dos columnas) y al final de `PartidoVivo`. OJO (hallazgo): en un partido mirado `_cerrar_notas()` no se llama nunca (solo `simular()`), así que `Jugador.notas`/forma no reciben ese partido; no se tocó (cambiaría el azar de la partida) |
| M-142 | P2 | Rueda de prensa posterior no enlazada con incidentes del partido | SIN VERIFICAR | no se encontró tema de árbitro/VAR en `Prensa.resolver` |
| M-143 | P2 | Sin clima dinámico durante el partido (tormenta repentina) | PENDIENTE | sin cambio de clima en vivo |
| M-144 | P2 | Campo se desgasta (barro) sin visualización | PARCIAL | desgaste fijo en áreas y punto de penal (`cesped.gdshader`); no evoluciona |
| M-145 | P2 | Sin marcas de césped (pisadas, deslizamientos) | PENDIENTE | sin marcas de pisadas |
| M-146 | P2 | Balón con skins pero sin desgaste/mojado | PENDIENTE | balón sin desgaste/mojado |
| M-147 | P1 | Hitbox del balón vs cuerpo: 0 casos atravesando (sonda); pero… | PARCIAL | balón con altura y cabezazo en el motor; colisión por distancia, sin cápsulas |
| M-148 | P2 | Sin rebotes contra postes/larguero realistas con física propia | PARCIAL | poste y larguero detectados en el motor; rebote sin comprobar |
| M-149 | P2 | Red del arco rígida | HECHO | 17-10: `red_arco.gdshader` (onda de vértice desde el punto de entrada, sin física); de frente se ve bien, desde la TV es sutil |
| M-150 | P2 | Sin balones adicionales (calentamiento, reserva) | PENDIENTE | sin balones decorativos |
| M-151 | P2 | Muro de pruebas: `sonda_fisica` no distingue reposiciones | HECHO | 19/20-10: la sonda separa tele/reposiciones y salta la ceremonia; `_probar_fisica_motor` en el banco (velocidad, giros, tirones, teletransportes) |
| M-152 | P2 | Sin modo de entrenamiento libre (probar controles) | PENDIENTE | sin entrenamiento libre |
| M-153 | P2 | Sin modo multijugador local | PENDIENTE | sin multijugador local |
| M-154 | P3 | Sin online | PENDIENTE | fuera de alcance, sin documentar |
| M-155 | P2 | Penal de usuario con barra, sin variantes por pierna | PARCIAL | el zurdo usa clips en espejo; penal del usuario sin variante por pierna |
| M-156 | P2 | Sin decisión de capitán (protesta) | PENDIENTE | sin protesta del capitán |
| M-157 | P2 | Sin cantos/anuncios del estadio (megafonía con alineaciones) | PENDIENTE | sin megafonía |
| M-158 | P2 | Presentación: 180 s en FC; aquí variable | HECHO | ajustes «Presentación antes del partido» y «Ceremonia completa» (`ui/estadio.gd` l.364-366) |
| M-159 | P2 | Sin himno por país con partitura procedural | PARCIAL | un motivo genérico «himno» sintetizado; no por país |
| M-160 | P2 | Sin saludo protocolar/pre-partido (capitanes, sorteo de campo) | HECHO | 17-10: fase final de `CeremoniaPartido` (4,2 s): árbitro y capitanes en el centro, moneda que gira, «X elige campo» y apretón de manos (`dar_mano`); se salta con la ceremonia |
| M-161 | P2 | Sin mini-partidos de selección con identidad | PENDIENTE | sin identidad de selección en el 3D |
| M-162 | P2 | Estadísticas del motor (tiros, pases) sin exportar | HECHO | 20-10: al terminar el partido con motor, `EstadisticasVivo.a_csv` guarda la tabla y cada remate (x, z, xG, resultado, pase) en `user://estadisticas/*.csv` |
| M-163 | P2 | Sin modo «Director técnico automático» configurable (IA del usuario) | PARCIAL | `MotorJugable.autopiloto`; sin perfil configurable |
| M-164 | P2 | Sin modo espectador con cámara libre | PENDIENTE | sin cámara libre en la UI |
| M-165 | P2 | Sin reglas especiales (prórroga, penales, gol de oro por competición) | HECHO | 17-10: prórroga 2×15' y tanda jugable en el césped (`MotorJugable`, `MarcadorTanda`, `Partido.penales_externos`, prueba_prorroga_penales) |
| M-166 | P3 | Sin partidos de fútbol sala/playa/mujeres (género existe) | PENDIENTE | fuera de alcance, sin documentar |

### F. Ciudad, vehículos, metro, interiores (M-167 … M-206) · HECHO 5 · PARCIAL 8 · PENDIENTE 26 · SIN VERIFICAR 1

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-167 | P1 | Calzadas = cajas de asfalto con marcas propias; Kenney sólo… | PENDIENTE | calzadas propias; losetas Kenney no usadas |
| M-168 | P2 | Sin rotondas | PENDIENTE | sin rotondas |
| M-169 | P2 | Puente sin pilares Kenney | HECHO | apoyos de los puentes (`CiudadExpansion._apoyos_puente`, 16-10) |
| M-170 | P2 | Sin semáforos peatonales con botón | PENDIENTE | sin botón peatonal |
| M-171 | P1 | Tráfico sin comportamiento complejo (adelantar, ceder en cruce) | PARCIAL | cola y frenado en rojo (`TraficoCiudad`); sin adelantar |
| M-172 | P1 | Colisiones del coche del usuario con NPC/vehículos sólo círculos | PENDIENTE | choque solo desliza; sin daño ni multa |
| M-173 | P2 | Sin sonido de motor/marchas/derrape | PARCIAL | 21-10: el motor del coche suena, sintetizado en vivo con revoluciones y 5 marchas (`visor/motor_coche_sonido.gd`); sin radio |
| M-174 | P2 | Interior de coche sin modelo (salpicadero 2D) | PARCIAL | salpicadero y volante 2D (`VolanteUI`) |
| M-175 | P2 | Sin faros ni luces de freno encendidos por hora | HECHO | 21-10: faros blancos y traseras rojas que se encienden con la noche y se avivan al frenar en rojo (`TraficoCiudad.faros`, una malla por coche, hasta 220 m) |
| M-176 | P2 | Sin tipos de vehículo (moto, bus conducible, camión) | PENDIENTE | solo coche conducible |
| M-177 | P2 | Sin gasolinera/aparcamiento/lavado | PENDIENTE | sin gasolinera/lavado |
| M-178 | P2 | Sin minimapa | HECHO | 17-10: GPS dentro del móvil en la mano (`MapaMovil`), M lo saca andando |
| M-179 | P2 | GPS/ruta al club | HECHO | 17-10: ruta dorada al estadio por las calles (`MapaMovil.ruta_al_estadio`) |
| M-180 | P2 | Metro: sin vendedores/música/anuncios | PARCIAL | anuncios en el vagón (`MetroCiudad.ANUNCIOS`); sin vendedores ni música |
| M-181 | P2 | Sin pasajeros que suben/bajan reales en tren | HECHO | gente que sube y baja por sub-pasos y puertas (`metro_ciudad.gd`, 16-10) |
| M-182 | P2 | Sin tarjeta de transporte ni coste | PENDIENTE | máquinas de billetes decorativas; sin coste |
| M-183 | P2 | Peatones: 34 máx; sin rutinas por hora | PARCIAL | 21-10: de madrugada queda en la calle un tercio de la gente (los ocultos tampoco se mueven: `TraficoCiudad.faros`); faltan rutinas por persona |
| M-184 | P2 | Sin NPC con nombre y memoria (te reconocen) | PENDIENTE | sin vecinos con memoria |
| M-185 | P2 | Diálogos por oficio (hecho) pero sin ramas ni consecuencias | PENDIENTE | diálogos sin consecuencias |
| M-186 | P2 | Interiores: 15 salas; edificios entrables «la mayoría» sin… | PARCIAL | gimnasio, piscina, estación central, recreativos con muebles Kenney (15/16-10); 21-10: edificio del club con muebles de verdad del catálogo común `Modulos` (oficina del DT, despacho, sala de vídeo, prensa, comedor, enfermería); sin 3 variantes por arquetipo |
| M-187 | P2 | Casas sin habitantes ni rutinas | PARCIAL | vivienda con «la familia que vive allí» (`InteriorInstalacion` l.1057); sin horarios |
| M-188 | P2 | Sin tiendas con compra real (ropa, balones) | PENDIENTE | sin compra en tiendas |
| M-189 | P2 | Sin bares/restaurantes con minijuego | PENDIENTE | sin bar con minijuego |
| M-190 | P2 | Sin clima dinámico en la ciudad (lluvia con charcos, reflejos) | PARCIAL | charcos de luz de farola (`CiudadExpansion`); sin charcos de lluvia en la ciudad |
| M-191 | P2 | Sin ciclo día/noche más allá del slider | PARCIAL | ciclo día/noche automático (`_ciclo_activo`); sin reloj real |
| M-192 | P2 | Aceras/pavimentos: 3 texturas | SIN VERIFICAR | no se midió la variedad de aceras por barrio |
| M-193 | P2 | Sin vegetación variada (setos, flores) más allá de árboles | PARCIAL | setos de jardines y casas (`CiudadExpansion._setos_t`); sin flores |
| M-194 | P2 | Cielo sin nubes dinámicas | HECHO | nubes con ruido en `visor/cielo.gdshader` |
| M-195 | P2 | Agua del río/mar plana | HECHO | olas y espuma en `visor/agua.gdshader` |
| M-196 | P2 | Botes sin sonido/estela | PENDIENTE | sin estela de botes |
| M-197 | P2 | Autopista sin peajes ni estaciones | PENDIENTE | sin peajes |
| M-198 | P2 | Aeropuerto/estación de tren inexistentes (no hay viajes) | PENDIENTE | sin viajes/aeropuerto |
| M-199 | P2 | Sin señales de tráfico reales (límites, ceda) | PENDIENTE | sin límites de velocidad con multa |
| M-200 | P2 | Sin policía/multas | PENDIENTE | sin policía |
| M-201 | P2 | Sin accidentes/eventos aleatorios | PENDIENTE | sin eventos de calle |
| M-202 | P2 | Galería subterránea sólo en la ciudad | HECHO | decisión documentada (galería solo en la ciudad) |
| M-203 | P2 | Sin colisión/oclusión de sonido en interiores | PENDIENTE | sin filtro de sonido en interiores |
| M-204 | P2 | LOD de edificios lejanos con ventanas (cristal) pero sin siluetas… | PENDIENTE | sin impostores de edificios |
| M-205 | P2 | `ciudad_expansion.gd` 2.321 líneas y `city_builder.gd` 4.687 | PENDIENTE | `ciudad_expansion.gd` creció a 3.569 líneas |
| M-206 | P2 | Sin editor de ciudad más allá de terrenos/negocios | PENDIENTE | sin editor de ciudad |

### G. Gestión del club (M-207 … M-262) · HECHO 8 · PARCIAL 20 · PENDIENTE 26 · SIN VERIFICAR 2

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-207 | P1 | Plantillas de 25 en todos los clubes (C-05) | PENDIENTE | plantillas de 25 |
| M-208 | P1 | Caja del club propio crece de forma casi monótona (prueba larga:… | PARCIAL | 20-10: el mantenimiento de instalaciones (M-227) es un coste que crece con el club; faltan crisis |
| M-209 | P2 | La prueba larga sólo comprueba que no hay errores, no el equilibrio | PARCIAL | `prueba_larga` comprueba medias en rango; sin métricas de equilibrio |
| M-210 | P1 | Mercado: precios por reputación sin burbujas ni crisis | PARCIAL | eras con precios (`Eras`, `_probar_eras_y_precios`); sin burbujas |
| M-211 | P2 | Cláusulas de rescisión: sin «cláusulazo» automático de IA | PARCIAL | el mercado reconoce pagos de cláusula (`Mercado` l.345); sin «clausulazo» de IA deliberado |
| M-212 | P2 | Negociación 346 líneas sin pruebas directas (módulo `Negociacion`… | HECHO | `_probar_negociacion` en el banco (la auditoría no lo vio) |
| M-213 | P2 | Sin agentes con personalidad reflejada en comisiones (hay 4 perfiles) | PARCIAL | perfiles de agente (`MesaAgente.PERFIL`); sin historial |
| M-214 | P2 | Cesiones con opción de compra obligatoria sin seguimiento de… | PENDIENTE | cesiones sin bonus por partidos |
| M-215 | P2 | Mercado de invierno y verano sin ventanas diferenciadas (¿existe?) | HECHO | dos ventanas (`Mundo.VENTANA_VERANO/INVIERNO`) y aviso de cierre |
| M-216 | P2 | Fichajes de IA entre clubes poco visibles | SIN VERIFICAR | no se comprobó la noticia semanal de traspasos de IA |
| M-217 | P2 | Sin fichajes libres por fin de contrato anticipados (precontrato) | PENDIENTE | sin precontratos |
| M-218 | P2 | Sin límite de fair play financiero explícito (hay aviso) | PARCIAL | tope salarial con administrador (`Insolvencia`); sin ratio salarial general |
| M-219 | P1 | `Banco` e `Insolvencia` existen pero con pocos eventos de gravedad | PARCIAL | administrador, tope salarial, venta de lo que sobra, refundación (`Insolvencia`); sin descenso administrativo |
| M-220 | P2 | Sin intereses variables según reputación y mercado | PARCIAL | préstamos con tasas por tipo (`Banco`); no dinámicas |
| M-221 | P2 | Impuestos y derechos de TV simplificados | SIN VERIFICAR | derechos de TV con multiplicador; no se comprobó el reparto por país |
| M-222 | P2 | Venta de entradas: precio único | PARCIAL | precio único por partido; sin sectores ni precio por rival |
| M-223 | P2 | Abonos/socios: modelo simple | PARCIAL | socios por temporada (`Reputacion`) y campaña de abonos (`Hinchada`); sin lista de espera |
| M-224 | P2 | Tienda/merchandising ligado a ventas de camisetas por ídolo | HECHO | 20-10: `Instalaciones.factor_idolo` (la estrella del plantel: con 90 de media, +60 %) multiplica la «Tienda y museo» |
| M-225 | P2 | `Comercial` zonas de patrocinio manual para el usuario; IA sin… | PENDIENTE | sin noticias de contratos comerciales de IA |
| M-226 | P2 | Naming del estadio sin historia (renombrar cada contrato) | HECHO | naming con `nombre_viejo` (`Comercial.naming`) |
| M-227 | P2 | Instalaciones: 19 obras; sin mantenimiento ni desgaste | HECHO | 20-10: `Instalaciones.mantenimiento_del_mes` (0,3 % al mes del valor de cada nivel, escalado con el club) cobrado en el cierre de mes con su movimiento «Mantenimiento de instalaciones» |
| M-228 | P2 | Obras sin imprevistos (retrasos, sobrecostes, permisos) | HECHO | 20-10: `Instalaciones._imprevisto`: ~1 de cada 4 obras tiene uno (retraso de una semana o +8 % de coste), sin azar guardado (repetible al recargar), con noticia «🚧 Imprevisto en la obra» en los 9 idiomas |
| M-229 | P2 | Academia: sin variedad de métodos pedagógicos | PENDIENTE | sin planes pedagógicos |
| M-230 | P2 | Cantera 1.422 líneas con representantes; pocos hitos narrativos | PARCIAL | `EventosCantera`: torneo, dejarlo, padres, convocatoria; sin lesión/mudanza |
| M-231 | P2 | Ojeadores con sesgo regional (ya) sin informes visuales (campo vs… | PARCIAL | ojeadores con personalidad que infla/recorta informes (`Ojeadores`); sin informe visual |
| M-232 | P2 | Staff de 6 puestos sin personalidad ni relaciones entre sí | PENDIENTE | staff sin química |
| M-233 | P2 | Entrenamiento 1.117 líneas; sesiones sin visualización 3D | PENDIENTE | sin escenas de entrenamiento |
| M-234 | P2 | Maestrías con efecto en partido poco visible | PENDIENTE | maestrías sin registro en el resumen |
| M-235 | P1 | Lesiones: duración y recaídas ok; sin prevención visible (carga… | PARCIAL | carga y riesgo en `Medico` (l.244-254); indicador por jugador sin confirmar |
| M-236 | P2 | Vestuario 1.436 líneas con grupos; sin conflictos con… | PENDIENTE | sin discusiones visibles en partido |
| M-237 | P2 | Capitanías: elección sin votación | HECHO | 20-10: `Vestuario.votar_capitan` (veteranía, calidad, moral y voto en bloque de la camarilla); si el club se queda sin cinta, el vestuario vota esa semana y sale la noticia «🗳️ El vestuario elige capitán» |
| M-238 | P1 | Directiva: objetivos con confianza; despido sin cinemática | HECHO | 17-10: `EscenaDespido` (presidente en 3D con traje vía `PersonajeDT.crear`, diálogo en `CuadroDialogo`, resumen de la etapa y «Ver ofertas de otros clubes»); en `Principal` al emitirse `Directiva.despedido` |
| M-239 | P2 | Junta/accionistas: sin asambleas jugables | PARCIAL | asamblea en insolvencia/federación; no jugable |
| M-240 | P2 | `Politica` ficticia (decisión legal): mantener sin real | HECHO | 20-10: `_probar_palabras_prohibidas` revisa 263 archivos (código + narración + traducciones) contra políticos/partidos reales y religiones; el calendario (fechas como el Ramadán) es la única excepción |
| M-241 | P1 | Prensa 2.541 líneas (la mayor del núcleo): `resolver` 476 líneas | PENDIENTE | `Prensa.resolver` sigue en una función |
| M-242 | P2 | Titulares dinámicos: 129 sólo en EN/PT (I-01) | HECHO | titulares traducidos en los 9 idiomas (paridad 15-10) |
| M-243 | P2 | Redes sociales: seguidores y comentarios; sin bots/trolls/tendencias | PARCIAL | tendencias y hashtags (`Redes.tendencia`); sin trolls |
| M-244 | P2 | Sin entrevistas en TV con escena 3D variada (existe rueda de… | PENDIENTE | un solo set de rueda de prensa |
| M-245 | P2 | Federación 999 líneas con reglas; votaciones sin presentación | PARCIAL | votaciones con señales (`Federacion`); pantalla de sesión sin comprobar |
| M-246 | P2 | `LeyesPais` (cupos) ok; sin visualización de «alineación indebida»… | HECHO | 20-10: aviso rojo en la pizarra (`PantallaPlantel._pintar_tactica`) con la infracción y qué pasará (el ayudante corrige / la federación multa); prueba `prueba_alineacion_indebida.tscn` |
| M-247 | P2 | Competiciones continentales (620 líneas) sin sorteo animado por fases | HECHO | cinemática del bombo para la fase de grupos (`Continental.sorteo_grupos` → `ui/sorteo.gd`) |
| M-248 | P2 | Mundial de clubes/selecciones (1.012 líneas) con pocos modos | PARCIAL | convocatorias con efecto en el físico (`Selecciones`); sin concentraciones |
| M-249 | P2 | Hinchada con segmentos; sin rivalidades por barrio | PARCIAL | clásico con incidentes (`Prensa`); sin rivalidades por barrio |
| M-250 | P2 | Ciudad y club: terrenos/negocios; economía simplificada | PENDIENTE | negocios sin depender de la ocupación |
| M-251 | P2 | Gente del club (10 personas) sin crecimiento de relaciones | PENDIENTE | gente del club sin afinidad |
| M-252 | P2 | Trabajadores/instalaciones con eventos; sin huelgas/negociación | PARCIAL | huelga de hinchas y por sueldos impagos (`Prensa`); sin negociación laboral |
| M-253 | P2 | Licencia de entrenador: exámenes; sin cursos con coste y tiempo | PENDIENTE | licencia sin cursos |
| M-254 | P2 | Vida del DT (bienestar, casa, familia): sin impacto en rendimiento… | PARCIAL | estrés en `VidaDT`; efecto en rendimiento sin comprobar |
| M-255 | P2 | Retos/logros: 1.132 líneas (`Logros`) **sin referencias en banco** | HECHO | `_probar_logros` en el banco (la auditoría no lo vio) |
| M-256 | P2 | Álbum/museo sin colecciones jugables | HECHO | cromos con rarezas (`Meta.RAREZAS`, `PanelMeta`) |
| M-257 | P2 | Historia del club generada; sin línea de tiempo interactiva | PENDIENTE | sin línea de tiempo |
| M-258 | P2 | Documental de temporada: guion fijo | PENDIENTE | documental con guion fijo |
| M-259 | P2 | Clima en partidos con efecto menor | PARCIAL | el clima reduce las llegadas (`Partido.clima`); sin efecto en balón ni desgaste |
| M-260 | P2 | Dificultad: 3 niveles simples | PENDIENTE | sin dificultad adaptativa |
| M-261 | P2 | Sin modo historia/campaña guiada | PENDIENTE | sin modo historia |
| M-262 | P2 | Sin editor de escenarios compartible | HECHO | exportar/importar CSV en `Editor` |

### H. Carrera de Jugador (M-263 … M-276) · HECHO 2 · PARCIAL 2 · PENDIENTE 9 · SIN VERIFICAR 1

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-263 | P1 | Eventos únicos (13) y control real; pocos días de «vida» entre… | PENDIENTE | sin agenda semanal |
| M-264 | P1 | Misma ceremonia y gol que en el modo DT: pendiente | HECHO | misma ceremonia y gol (`PartidoJugable.con_ceremonia`, `CineGol`, 16-10) |
| M-265 | P2 | Avatar propio sin personalización de cuerpo | PENDIENTE | sin personalización del cuerpo |
| M-266 | P2 | Sin entrenador como NPC con diálogos sobre el jugador | PARCIAL | `relacion_dt` decide minutos; sin entrenador con diálogos |
| M-267 | P2 | Transferencias vistas desde el jugador: ofertas sin negociación… | PENDIENTE | la Carrera no usa `MesaAgente` |
| M-268 | P2 | Selección nacional: convocatorias sin escena | PARCIAL | convocatoria como evento; sin cinemática |
| M-269 | P2 | Lesiones del jugador: sin recuperación jugable (fisio) | PENDIENTE | sin rehabilitación jugable |
| M-270 | P2 | Retiro con paso a DT ok; sin homenaje | PENDIENTE | sin homenaje de retiro |
| M-271 | P2 | Sin contratos de imagen propios | PENDIENTE | sin contratos de imagen |
| M-272 | P2 | Fuera de juego, cambios, selección ✅; sin protestas/tarjetas del… | PENDIENTE | sin expediente disciplinario |
| M-273 | P2 | Rivales NPC por `Fama`; sin rivalidades nominales | PENDIENTE | sin rival de posición |
| M-274 | P2 | Sin vida privada coherente con regla (no romances de reales) | HECHO | regla mantenida (solo ficticios) |
| M-275 | P2 | `carrera_jugador.gd` usa país «XXX» para el rival (línea 620) | HECHO | 17-10: país real por nombre (`CODIGO_SELECCION`) y 13 banderas nuevas en `Banderas` |
| M-276 | P2 | Pruebas: modo cubierto en `prueba_modos`; faltan casos extremos… | SIN VERIFICAR | no se comprobaron los casos extremos en `prueba_modos` |

### I. Interfaz, menús, accesibilidad (M-277 … M-312) · HECHO 6 · PARCIAL 14 · PENDIENTE 15 · SIN VERIFICAR 1

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-277 | P1 | 274 textos en español directamente en `ui/` (I-02), concentrados… | PARCIAL | ✅ 15-10: 1.132 textos envueltos; quedan ~15 (M-447) |
| M-278 | P1 | `ui/principal.gd` 6.655 líneas (y 3 funciones >330) | PENDIENTE | `principal.gd` con 6.777 líneas |
| M-279 | P1 | 27 módulos de `visor/` y 8 de `nucleo/` sin referencia directa en… | PENDIENTE | los módulos siguen sin prueba directa |
| M-280 | P1 | 105 módulos de UI/visor sin referencia en banco/pruebas | PENDIENTE | sin prueba visual automática |
| M-281 | P2 | Sin modo daltónico | HECHO | paleta para daltonismo (`Tema`, ajustes) |
| M-282 | P2 | Sin escala de interfaz/ fuente ajustable global | HECHO | escala de texto 0,7-1,6 (`Principal._escala_texto`) |
| M-283 | P2 | Sin subtítulos/indicadores visuales de sonido | PENDIENTE | sin avisos visuales de sonido |
| M-284 | P2 | Sin modo lectura de pantalla (TTS) | PENDIENTE | sin TTS |
| M-285 | P2 | Navegación por mando en menús (panel de controles sí) | PARCIAL | navegación con mando en el panel de controles; no en todos los menús |
| M-286 | P2 | Sin atajos de teclado documentados globalmente | HECHO | tabla de atajos (`pantalla_opciones.gd` `_pintar_atajos`) |
| M-287 | P2 | Rendimiento de menús: refresco ya 14× más rápido; sin pruebas de… | PENDIENTE | sin medida de apertura de pantallas |
| M-288 | P2 | Fondos animados únicos (9) con coste en GPU baja | HECHO | 20-10: con el motor ligero los fondos de menú son de color fijo (sin shader con TIME, que obliga a redibujar cada fotograma) y las partículas de fondo bajan a un tercio |
| M-289 | P2 | Menú lateral con 9 menús; Ciudad/Editar completados; Ajustes sólo… | PENDIENTE | Ajustes sigue con 3 tarjetas (`MenuLateral`) |
| M-290 | P2 | Tarjetas con dato vivo sólo en algunas (`Menu.dato`) | PARCIAL | `MenuLateral.dato` existe; no todas las tarjetas |
| M-291 | P2 | Sin buscador global (jugadores, clubes, pantallas) | HECHO | buscador global en la cabecera (`principal.gd` l.587) |
| M-292 | P2 | Sin favoritos/marcadores de jugadores o clubes | PARCIAL | favoritos de pestañas; sin seguimiento de jugadores/clubes |
| M-293 | P2 | Tablas con filtros limitados (plantel) | PARCIAL | filtros en plantel/libres |
| M-294 | P2 | Comparador de jugadores existe; sin comparativa de club/estadio | PARCIAL | comparador de jugadores; sin club/estadio |
| M-295 | P2 | Sin gráficos históricos (valor, forma) en ficha | SIN VERIFICAR | «crecimiento por temporada» en la ficha; sin gráficos verificados |
| M-296 | P2 | Notificaciones (`Aviso`) sin centro de notificaciones | PARCIAL | bandeja de correo; sin filtros |
| M-297 | P2 | Tutorial: ciudad y controles; falta tutorial de gestión (primer mes) | PENDIENTE | sin tutorial de gestión |
| M-298 | P2 | Pantalla de carga con consejos (`consejos_carga.py`) | HECHO | consejos en `pantalla_carga.gd`, traducidos |
| M-299 | P2 | Sin confirmaciones consistentes para acciones destructivas… | PARCIAL | `CuadroDialogo` en despacho/principal; no uniforme en vender/despedir |
| M-300 | P2 | Sin deshacer en acciones de pizarra | PENDIENTE | sin deshacer en pizarra |
| M-301 | P2 | Sin guardado automático visible | HECHO | 20-10: «💾 Partida guardada» arriba a la derecha tras cada autoguardado (`Principal._indicador_guardado`), en los 9 idiomas; captura `captura_guardado` |
| M-302 | P2 | Sin tema claro/alto contraste | PENDIENTE | sin tema claro/alto contraste |
| M-303 | P2 | Cursor/hover sin feedback sonoro consistente en todos los… | PARCIAL | `BotonFx` en todos los botones; pestañas/listas sin sonido |
| M-304 | P2 | Animaciones de transición entre pantallas desiguales | PARCIAL | `Animar` en 16 archivos; sin sistema común de transición |
| M-305 | P2 | Tooltips escasos | PARCIAL | 103 tooltips |
| M-306 | P2 | Sin glosario (términos de fútbol/gestión) | HECHO | pestaña Glosario |
| M-307 | P2 | Resoluciones: pensado 1280×720–1600×900; sin pruebas en 4:3, 21:9… | PENDIENTE | sin capturas por aspecto |
| M-308 | P2 | DPI alto: texto del `Label3D` en 3D no escala | PENDIENTE | `pixel_size` fijo |
| M-309 | P2 | Sin pantalla de créditos/licencias dentro del juego | HECHO | 20-10: Ajustes → Partida → «CRÉDITOS Y LICENCIAS» (`nucleo/creditos.gd`: Godot MIT, Quaternius y Kenney CC0, mocap, MediaPipe Apache 2.0, NASA, audio propio); captura `captura_creditos` |
| M-310 | P2 | Sin pantalla «Novedades» tras actualizar | PENDIENTE | sin «Novedades» |
| M-311 | P2 | Sin perfil de jugador (estadísticas globales) | PARCIAL | `PanelMeta` (álbum/museo global); sin perfil de estadísticas |
| M-312 | P2 | Sin modo «streamer» (ocultar datos sensibles/real) | PARCIAL | ajuste «Caras reales: FOTO / RECREACIÓN» (`Cara.usar_fotos`); sin modo streamer |

### J. Audio y música (M-313 … M-324) · HECHO 0 · PARCIAL 3 · PENDIENTE 7 · DUEÑO 2

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-313 | P2 | `Sonido._sintetizar` 1.000 líneas: efectos sintetizados sin editor | PENDIENTE | `_sintetizar` sigue monolítica |
| M-314 | P2 | Sin mezcla dinámica (ducking de música en diálogo/gol) | PENDIENTE | sin ducking |
| M-315 | P2 | Música (`Musica` 384 líneas, procedural): sin variaciones por mood… | PARCIAL | `Musica` con capas por estado |
| M-316 | P2 | Cantos de hinchada genéricos | PARCIAL | cánticos sintetizados; sin sincronía con el juego |
| M-317 | P2 | Sin comentarista | 🔒 DUEÑO | narración por voz = audios (decisión del dueño; COMPARACION_JUEGOS_2) |
| M-318 | P2 | Sin sonidos de pisadas por superficie en partido | PENDIENTE | sin pisadas |
| M-319 | P2 | Sin eco/reverb en túnel/vestuario/estadio | PARCIAL | sonido «eco_estadio»; sin reverb por zona |
| M-320 | P2 | Sonido del balón (patada) sin variación por tipo/potencia | PENDIENTE | sin variantes de patada por potencia |
| M-321 | P2 | Volúmenes por bus sin perfil «noche»/audífonos | PENDIENTE | sin presets de volumen |
| M-322 | P2 | Sin audio espacial en la ciudad (fuentes 3D) | PENDIENTE | sin audio espacial (0 `AudioStreamPlayer3D`) |
| M-323 | P3 | Sin música licenciada (decisión del dueño) | 🔒 DUEÑO | música licenciada: decisión del dueño |
| M-324 | P2 | Sin prueba que detecte clipping/silencios | PENDIENTE | sin prueba de clipping |

### K. Idiomas y textos (M-325 … M-336) · HECHO 4 · PARCIAL 2 · PENDIENTE 6

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-325 | P1 | Frases distintas por idioma (I-01): en/pt 1.531, fr/it/de/ca… | HECHO | ✅ 15-10 |
| M-326 | P1 | «297 frases faltan en fr/it/de/ca»: en realidad faltaban **36… | HECHO | ✅ 15-10 |
| M-327 | P2 | «168 frases faltan en en/pt»: no faltaba ninguna (estaban en… | HECHO | ✅ 15-10 |
| M-328 | P2 | Patrones numéricos (`patrones` 58) con plurales simples | PENDIENTE | sin reglas de plural por idioma |
| M-329 | P2 | Sin género gramatical (entrenadora/jugadora) en todos los idiomas | PARCIAL | `Genero` solo en español |
| M-330 | P2 | Formatos de fecha/número por idioma | PENDIENTE | sin `Idiomas.fecha/numero` |
| M-331 | P2 | Nombres de personas por país (bolsas) sin pruebas de duplicados… | HECHO | 20-10: `_probar_nombres_repetidos` lo destapó (10,1 % de tocayos, «Lucas Barbosa» ×5: bolsas de 14×14). Bolsas ampliadas (`datos/bolsas_nombres.json`, 16 países + general) y re-sorteo si el nombre ya existe (`Mundo._nombre_al_azar`): 1,1 % |
| M-332 | P2 | Narración traducida (`narracion.json`) sin revisión nativa | PENDIENTE | sin revisión nativa |
| M-333 | P2 | Texto en imágenes (carteles del 3D) sin traducir | PARCIAL | textos de `visor/` envueltos en `Idiomas.t` (15-10); carteles dibujados sin comprobar |
| M-334 | P2 | Sin RTL (árabe, hebreo) aunque hay KSA/EGY/MAR | PENDIENTE | sin RTL |
| M-335 | P2 | Fuentes: cobertura de glifos para pl/tr/ar | HECHO | 20-10: `_probar_glifos_idiomas` comprueba que la letra del juego tiene los 375 caracteres de las traducciones (pl, tr, ca…); el árabe no está entre los idiomas |
| M-336 | P2 | `CLAUDE.md` afirma «1.402 frases c/u» (I-04) | HECHO | CLAUDE.md ya dice 2.574 frases + 373 patrones |

### L. Rendimiento y optimización (M-337 … M-358) · HECHO 2 · PARCIAL 6 · PENDIENTE 12 · DUEÑO 2

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-337 | P0 | No hay perfil en hardware real (R-01) | 🔒 DUEÑO | perfil en hardware real |
| M-338 | P1 | Partido ALTO ≈ 2,3 M tris/700 llamadas | PARCIAL | partido ALTO 0,76 M tris / 630 llamadas (17-10); sin presupuesto por categoría escrito |
| M-339 | P1 | Césped en capas ≈ 230 k tris/57 llamadas | PENDIENTE | capas del césped hasta 46 m sin LOD extra |
| M-340 | P1 | 22 jugadores con pelo por capas, cejas, pestañas (ver… | HECHO | cuero 15→5 capas desde 22 m, pestañas 20 m, cejas 30 m (`PeloCapas.DIST_CUERO`, `PeloQ.DIST_CEJAS`, 17-10) |
| M-341 | P1 | Sombras: 4 cortes en ALTO; sin ahorro medible al bajar (probado),… | 🔒 DUEÑO | coste de sombras en GPU real |
| M-342 | P1 | Público real +8 % de triángulos (S-03) | HECHO | LOD del público por tramos (16-10) |
| M-343 | P2 | Draw calls 700 | PARCIAL | sombras en 8 mallas por sector (741→691) y 630 llamadas; sin atlas |
| M-344 | P2 | Overdraw en grada por butacas y personas | PARCIAL | 21-10: oclusión en la CIUDAD (`OclusoresCiudad`, 1.120 paredes): −16 % de llamadas a pie de calle (12.128 → 10.192 en 4 calles, `medir_oclusion`); en la grada del estadio sigue sin `OccluderInstance3D` |
| M-345 | P2 | Culling por trozos para MultiMesh grandes | PENDIENTE | sin culling por trozos de MultiMesh |
| M-346 | P2 | Texturas con compresión (s3tc en PC); sin variantes móviles… | PARCIAL | 21-10: revisado: las texturas grandes de 3D ya están en VRAM (s3tc) y limitadas (ropa 4K → 1024); las 3.103 sin comprimir son caras reales, iconos 2D y paletas de Kenney, que se dejan sin pérdida a propósito; sin etc2/astc para móvil |
| M-347 | P2 | VRAM 539 MB en partido | PARCIAL | texturas del globo comprimidas (72→13 MB); VRAM del partido sin remedir |
| M-348 | P2 | Carga: `Precarga` existe; primera construcción de estadio larga | PENDIENTE | sin caché en disco de mallas generadas |
| M-349 | P2 | Generación de `Mundo` (384 clubes) y `Reales.aplicar`: medir… | PENDIENTE | sin `WorkerThreadPool` |
| M-350 | P2 | `avanzar_semana` 532 líneas: tiempo por semana desconocido | PENDIENTE | sin perfil por semana |
| M-351 | P2 | Hilos: ¿se usan para IA/ciudad? | PENDIENTE | sin hilos para tráfico/peatones (solo LOD del tráfico) |
| M-352 | P2 | GC/alloc en `_process` (Dictionary por jugador) | PENDIENTE | sin Packed arrays en el motor |
| M-353 | P2 | Valorar C#/GDExtension sólo si el motor domina CPU | PENDIENTE | sin medición previa |
| M-354 | P2 | `RendimientoAdaptativo` existe; documentar umbrales y probarlos | PARCIAL | `pruebas/probar_rendimiento_adaptativo.gd`; no está en el banco |
| M-355 | P2 | Sin modo batería/60→30 FPS en móvil | PARCIAL | límite de FPS 30/60/120 (`Principal.FPS_OPCIONES`); sin modo batería |
| M-356 | P2 | Memoria de la ciudad ×4 (2.640 m) | PENDIENTE | sin streaming por celdas |
| M-357 | P2 | Capturas pesadas en repo (`pruebas/capturas`) | PARCIAL | `.gitignore` de promo/lotes y JPG por defecto; resto en repo |
| M-358 | P2 | Sin telemetría local de FPS por pantalla | HECHO | 20-10: «Mostrar contador de FPS» en Ajustes → Pantalla (`ContadorFps`, en la raíz: sigue en estadio, ciudad y Carrera; color por umbral); prueba `prueba_contador_fps`. De paso: «sin límite» de FPS ya no vuelve a 30 al recargar |

### M. Datos y contenido (M-359 … M-378) · HECHO 5 · PARCIAL 1 · PENDIENTE 13 · SIN VERIFICAR 1

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-359 | P1 | Estadio real en 46 % de clubes (C-01) | PENDIENTE | 46 % |
| M-360 | P1 | 4 clubes sin estadio en base real (✅ E-03) | HECHO | ✅ |
| M-361 | P2 | `tablas.json` en una línea (D-04) | SIN VERIFICAR | no se revisó `tablas.json` |
| M-362 | P2 | `ESTADIO_CLUB` por nombre (frágil con leetspeak) | PENDIENTE | `ESTADIO_CLUB` por nombre |
| M-363 | P2 | Mapa ficticio→real (`CLUBES` en `base_ficticia.py`) sin prueba de… | PENDIENTE | sin prueba de cobertura |
| M-364 | P2 | Países: 23 con 16 clubes (Chile 32) | PENDIENTE | sin ligas nuevas |
| M-365 | P2 | Copas nacionales sólo `Copa` genérica | HECHO | copas por país (`Copa.COPAS_POR_PAIS`) |
| M-366 | P2 | Árbitros con datos mínimos | HECHO | árbitros con historial y perfil psicológico (`Federacion`/`Previa`, LEEME) |
| M-367 | P2 | Calendario con feriados (`Calendario` 350 líneas); sin zonas horarias | PENDIENTE | sin zonas horarias |
| M-368 | P2 | Jugadores históricos/leyendas sin mecánica de «cromo» | PENDIENTE | leyendas sin cromo |
| M-369 | P2 | Nombres de estadios ficticios sin apodos amplios (`GuinosEstadio`) | PENDIENTE | `GuinosEstadio` sin ampliar |
| M-370 | P2 | Historia de clubes (`historia_clubes.py`) por club; verificación… | PENDIENTE | sin prueba de coherencia |
| M-371 | P2 | Himnos y cánticos sin letra | PENDIENTE | himnos sin letra |
| M-372 | P2 | Retratos de DT/presidente generados; sin variedad étnica medida | PENDIENTE | sin estadística por país |
| M-373 | P2 | Bandera de cada país como pieza; verificar que son las correctas y… | PENDIENTE | sin prueba visual de banderas |
| M-374 | P2 | Divisas: ¿hay multi-moneda? | HECHO | divisas seleccionables (cerrado 25-9, `_probar_moneda`) |
| M-375 | P2 | Sin calendario de selecciones fechas FIFA | HECHO | fechas FIFA con convocatoria (`CarreraJugador.convocatoria`, `Selecciones`) |
| M-376 | P2 | Premios individuales sin votación explicada | PENDIENTE | sin votación explicada |
| M-377 | P2 | Sin clima por país/estación realista | PARCIAL | `Clima.del_partido` por país/estación; sin tabla completa verificada |
| M-378 | P2 | Sin datos de ciudades (población, altura) para estadios | PENDIENTE | sin datos de ciudades |

### N. Código y arquitectura (M-379 … M-402) · HECHO 1 · PARCIAL 2 · PENDIENTE 19 · SIN VERIFICAR 2

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-379 | P2 | 64 funciones > 120 líneas (Q-01): `Sonido._sintetizar` 1.000,… | PENDIENTE | funciones largas sin partir |
| M-380 | P2 | `pruebas/banco.gd` 8.029 líneas | PENDIENTE | `banco.gd` con 8.454 líneas |
| M-381 | P2 | 16 `print()` en código de juego | HECHO | 20-10: los que quedaban sin condición (`KitTextureFactory`) solo con `--verbose`; el resto ya iba detrás de interruptores de depuración |
| M-382 | P2 | Sin análisis estático | PENDIENTE | sin gdlint |
| M-383 | P2 | Tipado: muchos `Dictionary` sin forma (jugadores del motor) | PENDIENTE | sin `JugadorMotor` tipado |
| M-384 | P2 | `Mundo` 2.921 líneas, `Roles` 2.065, `Prensa` 2.541: acoplamiento alto | PENDIENTE | sin extraer servicios |
| M-385 | P2 | Autoloads con globals (`Datos`, `Sonido`…) | PENDIENTE | sin documentar autoloads |
| M-386 | P2 | Señales sin desconexión en liberación (posibles fugas) | PARCIAL | `auditoria_tecnica.gd` mide huérfanos en la pantalla principal; 21-10: el panel de objetivos pasa a señal (`vista_cambiada`) y respaldo cada 3 s, sin fallar con las pestañas prestadas a un menú |
| M-387 | P2 | Mensajes de error silenciosos (`return` sin aviso) | PENDIENTE | sin registro de errores |
| M-388 | P2 | Constantes mágicas (balance) dispersas | PENDIENTE | sin archivo de balance |
| M-389 | P2 | `class_name` nuevos exigen `--import` (aprendido hoy) | HECHO | 20-10: `banco.sh` y `mini_banco.sh` reimportan solos si hay un .gd más nuevo que la caché de clases |
| M-390 | P2 | Un error de sintaxis deja el banco colgado | HECHO | `banco.sh` corta en errores de sintaxis, cuelgues y SCRIPT ERROR (14-10) |
| M-391 | P2 | Duplicación entre `MatchPlayback` y `MotorJugable` | PENDIENTE | duplicación sin retirar |
| M-392 | P2 | `MotorLibre` prototipo (546 líneas) sin uso claro | PENDIENTE | `MotorLibre` sigue (545 líneas); 20-10: con la base ficticia da 12,5 goles de media entre iguales (su prueba fija ahora la base real para no depender del orden) |
| M-393 | P2 | Código de pruebas mezclado con herramientas (`herramientas/*.ps1`) | PENDIENTE | sin separar |
| M-394 | P2 | Herramientas `.exe`/`.cs` binarias en repo | PENDIENTE | `herramientas/*.exe` siguen en el repo |
| M-395 | P2 | Scripts Python sin entorno declarado | HECHO | 20-10: `herramientas/requirements.txt` (Pillow, numpy, opencv, mediapipe, imageio-ffmpeg; `bpy` va con Blender) |
| M-396 | P2 | Convenciones: mezcla de español/inglés en nombres | PENDIENTE | sin guía de estilo |
| M-397 | P2 | Comentarios muy extensos (valioso pero ruidoso) | PENDIENTE | sin ADRs |
| M-398 | P2 | Sin documentación de arquitectura actualizada (`LEEME.md`) | PENDIENTE | LEEME sin diagrama |
| M-399 | P2 | Versión de guardado (`VERSION`) con migración mínima | SIN VERIFICAR | no se revisaron migraciones |
| M-400 | P2 | Sin límites de memoria en historiales (noticias, prensa) | SIN VERIFICAR | no se revisaron topes de historiales |
| M-401 | P2 | Dependencia de nombres de nodo (`find_child`) frágil | PENDIENTE | sin cambio |
| M-402 | P2 | Duplicación de carga de JSON (`Datos` 212 tablas) | PENDIENTE | sin carga perezosa |

### O. Pruebas y herramientas (M-403 … M-418) · HECHO 2 · PARCIAL 3 · PENDIENTE 11

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-403 | P1 | 8 módulos de `nucleo/` sin referencia en pruebas:… | PARCIAL | Logros y Negociación cubiertos de forma indirecta (`_probar_logros`, `_probar_negociacion`); los otros 6 no |
| M-404 | P1 | 27 módulos de `visor/` sin referencia: `Ambience`, `Autopista`,… | PENDIENTE | solo `CameraRig` aparece en el banco |
| M-405 | P1 | Pruebas visuales manuales (242 capturas) | PENDIENTE | sin comparación de imágenes |
| M-406 | P2 | `Retrato3D` no se ejercita en headless | PENDIENTE | sin prueba con xvfb |
| M-407 | P2 | Sin pruebas de conducción/ciudad (V-06) | PENDIENTE | sin prueba de conducción |
| M-408 | P2 | Sin pruebas de minijuegos 3D | PARCIAL | `prueba_minijuegos_nuevos` (2D); minijuegos 3D sin prueba |
| M-409 | P2 | Sin pruebas de menús/UI de integración (abrir cada pantalla sin error) | PARCIAL | `_probar_carga_de_ui` en el banco; sin recorrido por pestañas |
| M-410 | P2 | Sin pruebas de rendimiento con umbrales | PENDIENTE | sin umbrales de rendimiento |
| M-411 | P2 | Sin pruebas de idioma (V. I-01) | HECHO | `_probar_paridad_idiomas` |
| M-412 | P2 | Sin fuzzing de guardados | HECHO | 20-10: `_probar_guardado_seguro` estropea un guardado de 40 maneras (bytes, cortes, cabecera, ceros) sin copia: cargar nunca revienta |
| M-413 | P2 | `auditoria_clubes`/`auditoria_datos` no están en el banco | PENDIENTE | auditorías fuera del banco |
| M-414 | P2 | Resultados de sondas (calidad/táctica/simetría) sin umbrales | PENDIENTE | sondas sin umbrales |
| M-415 | P2 | Tiempo del banco largo y frágil al correr en paralelo | HECHO | banco en paralelo, 4 procesos equilibrados (15-10) |
| M-416 | P2 | Sin CI en GitHub Actions | PENDIENTE | sin GitHub Actions |
| M-417 | P2 | `herramientas/banco.sh` sólo bash | PENDIENTE | sin unificar |
| M-418 | P2 | Sin informes de cobertura | PENDIENTE | sin cobertura |

### P. Repositorio, build y legal (M-419 … M-432) · HECHO 1 · PARCIAL 2 · PENDIENTE 7 · DUEÑO 4

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-419 | P1 | `.git` 5,5 GB con punteros LFS antiguos (D-03) | 🔒 DUEÑO | historial/LFS: decisión del dueño |
| M-420 | P1 | Builds públicos sin datos reales (caras, fotos): comprobar con… | PENDIENTE | sin prueba del .pck |
| M-421 | P1 | Derechos de imagen de jugadores reales (decisión del dueño) | 🔒 DUEÑO | derechos de imagen |
| M-422 | P2 | 8 presets de exportación; sin pruebas de compilación | PENDIENTE | sin CI de exportación |
| M-423 | P2 | Android: keystore del dueño (regla) | 🔒 DUEÑO | keystore |
| M-424 | P2 | Licencias de terceros (Kenney CC0, Quaternius, Anderson Rohr):… | PARCIAL | `LICENCIAS.md` con los kits Kenney (15-10); sin auditoría automática |
| M-425 | P2 | Créditos de fotos (`creditos_fotos.txt`) sólo para el pack real | PENDIENTE | créditos de fotos sin pantalla |
| M-426 | P2 | Archivos grandes sueltos (`.glb` >5 MB) | PENDIENTE | sin compresión de GLB grandes |
| M-427 | P2 | `pruebas/capturas` crece sin control | PARCIAL | carpetas promo/lotes ignoradas; capturas siguen en el repo |
| M-428 | P2 | `.zip` de terceros dentro de `recursos/` (punteros LFS) | 🔒 DUEÑO | archivos de terceros con LFS: decisión del dueño |
| M-429 | P2 | Versionado del juego sin número visible | PENDIENTE | sin versión visible |
| M-430 | P2 | Sin canal de reporte de errores | PENDIENTE | sin reporte de errores |
| M-431 | P2 | Privacidad: sin datos personales (OK) | HECHO | mantener (sin datos personales) |
| M-432 | P2 | Sin política de contenido (religión/política ficticia) | PENDIENTE | sin lista en CI |

### Q. Móvil, táctil y mando (M-433 … M-442) · HECHO 0 · PARCIAL 1 · PENDIENTE 9

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-433 | P1 | Controles táctiles sólo en la ciudad (cruceta/E) | PARCIAL | 21-10: en PC ya no salen la cruceta ni «Salir» al pasear (estadio y ciudad) y la E solo aparece si hay algo con lo que interactuar (`ExploradorCiudad.es_tactil`); el partido sigue sin controles táctiles |
| M-434 | P2 | Sin vibración (rumble) en mando | HECHO | 17-10: `Mando.vibrar` en gol, remate y tarjeta (DT y Carrera), ayuda «Vibración del mando» normal/suave/no |
| M-435 | P2 | Sin gatillos analógicos para potencia de pase | PENDIENTE | sin gatillos analógicos |
| M-436 | P2 | Sin giroscopio para cámara en primera persona (móvil) | PENDIENTE | sin giroscopio |
| M-437 | P2 | Sin detección de dispositivo para cambiar iconos en tiempo real… | PARCIAL | `dispositivo_detectado` en panel de controles y `ControlFC`; guía del partido sin comprobar |
| M-438 | P2 | UI de móvil: botones pequeños | PENDIENTE | sin tamaño mínimo |
| M-439 | P2 | Orientación vertical no soportada | PENDIENTE | sin vertical |
| M-440 | P2 | Sin modo una mano | PENDIENTE | sin modo una mano |
| M-441 | P2 | Sin soporte de teclado en pantalla para nombres | PENDIENTE | sin teclado en pantalla |
| M-442 | P2 | Mando: botones reasignables guardados pero sin perfiles múltiples | PENDIENTE | sin perfiles de mando |

### R. Pasada 3 (M-443 … M-470) · HECHO 2 · PARCIAL 1 · PENDIENTE 25

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-443 | P1 | La IA del motor no amaga (0 en un partido de prueba). Hecho: amago… | HECHO | ✅ 15-10 (en el 3D la tasa sigue más baja) |
| M-444 | P2 | Fuga de texturas GL al cerrar `prueba_carrera_flujo` | PENDIENTE | fuga de texturas sin arreglar (INFORME_INTERNO H-12) |
| M-445 | P2 | Pruebas que no caben en 5 min con render por software (`intro`,… | PENDIENTE | sin modo rápido del arnés (H-13) |
| M-446 | P1 | 69 claves nuevas sin traducir (✅ arregladas); el patrón se… | HECHO | ✅ 15-10 |
| M-447 | P1 | Las cadenas en español escritas directo en `ui/` (I-02): antes 573… | PARCIAL | ✅ 15-10 salvo 15 textos |
| M-448 | P2 | `auditoria_clubes` tarda ~8 min y `auditoria_datos` ~1 min | PENDIENTE | sin muestra |
| M-449 | P2 | Los informes (`AUDITORIA_CLUBES.csv`) se regeneran a mano | PENDIENTE | sin CI nocturno |
| M-450 | P2 | `pruebas/prueba_*` no tienen un índice de «qué cubre cada una» | PENDIENTE | sin índice de pruebas |
| M-451 | P2 | Duplicación del arnés (`_ok`, `_fallos`) en decenas de pruebas | PENDIENTE | sin `PruebaBase` |
| M-452 | P2 | Salida de pruebas sin código de retorno uniforme (algunas… | PENDIENTE | varias pruebas acaban con `quit()` sin código |
| M-453 | P2 | Pruebas ligadas al azar sin semilla fija en algunos casos (la IA… | PENDIENTE | sin semillas fijas generalizadas |
| M-454 | P2 | Capturas que cambian el estado de la máquina (ajustes de… | PENDIENTE | sin restaurar |
| M-455 | P2 | Pruebas que escriben en `user://ajustes.cfg` real (E-10) | PENDIENTE | sin ruta inyectable |
| M-456 | P2 | `auditoria_tecnica` solo carga las escenas de `escenas/` y `ui/` (4) | PENDIENTE | sin cambio |
| M-457 | P2 | Los nodos huérfanos se miden solo en la pantalla principal | PENDIENTE | sin cambio |
| M-458 | P2 | Sin comprobación de que cada `Label` traducible esté dentro de un… | PENDIENTE | sin cambio |
| M-459 | P2 | Cinco idiomas de los nueve nacieron con frases que luego se… | PENDIENTE | sin flujo único |
| M-460 | P2 | Las traducciones nuevas (552) están hechas a mano sin revisión nativa | PENDIENTE | sin marcar |
| M-461 | P2 | Las cadenas con `%s`/`%d` dependen del orden de argumentos; en… | PENDIENTE | sin placeholders con nombre |
| M-462 | P2 | Etiquetas de botón con emoji/caracteres (💾 ↺ ● ✔ ▸ ◯) pueden no… | PENDIENTE | sin prueba de glifos |
| M-463 | P2 | `Idiomas.t` devuelve la clave si falta (silencioso) | PENDIENTE | sin registro de clave faltante |
| M-464 | P2 | No existe un informe de «frases por pantalla»: no se sabe qué… | PENDIENTE | sin informe por pantalla |
| M-465 | P3 | Sin pruebas de rendimiento de la carga de idiomas (`idiomas.gd`… | PENDIENTE | sin carga perezosa |
| M-466 | P2 | `datos/idiomas_extra.json` se reescribe entero con cada ampliación… | PENDIENTE | un solo archivo |
| M-467 | P2 | Falta un chequeo de longitud de texto (alemán/finés largo) en botones | PENDIENTE | sin chequeo de longitud |
| M-468 | P2 | Plurales y géneros en las 69 frases nuevas (p. ej. «%d botones»)… | PENDIENTE | sin plurales |
| M-469 | P3 | Falta documentación del flujo de pruebas para colaboradores | PENDIENTE | sin sección en LEEME |
| M-470 | P2 | El banco no ejecuta `auditoria_tecnica`, `auditoria_datos` ni las… | PENDIENTE | banco sin auditorías |

## 3. Las 350 ideas del dueño (verificación rápida por bloques)

Método: una búsqueda de palabras clave por idea en `nucleo/`, `ui/` y `visor/` (con y sin tilde) y lectura cuando había dudas. Es más gruesa que la de los 470 puntos: HECHO quiere decir que el sistema existe, no que esté pulido.

| Bloque | Ideas | HECHO | PARCIAL | PENDIENTE | Sin verif. |
|---|---:|---:|---:|---:|---:|
| 1. Infraestructura y Estadio | 1–15 | 13 | 1 | 0 | 1 |
| 2. Ciudad Deportiva / Instalaciones | 16–30 | 15 | 0 | 0 | 0 |
| 3. Personalización visual | 31–45 | 7 | 4 | 4 | 0 |
| 4. Personaje (DT / Presidente / Dueño) | 46–55 | 7 | 3 | 0 | 0 |
| 5. Plantilla y Jugadores | 56–70 | 12 | 3 | 0 | 0 |
| 6. Cantera y Formación Juvenil | 71–80 | 7 | 3 | 0 | 0 |
| 7. Fichajes y Negociación | 81–90 | 8 | 2 | 0 | 0 |
| 8. Cuerpo Técnico y Staff | 91–105 | 14 | 1 | 0 | 0 |
| 9. Economía y Finanzas | 106–120 | 12 | 1 | 2 | 0 |
| 10. Auspicios y Marketing | 121–135 | 6 | 4 | 5 | 0 |
| 11. Fans y Comunidad | 136–145 | 7 | 1 | 2 | 0 |
| 12. Redes Sociales | 146–155 | 5 | 5 | 0 | 0 |
| 13. Medios y Prensa | 156–165 | 7 | 1 | 2 | 0 |
| 14. Competencias y Torneos | 166–175 | 10 | 0 | 0 | 0 |
| 15. Premios y Reconocimientos | 176–185 | 3 | 4 | 3 | 0 |
| 16. Eventos Narrativos y Decisiones | 186–200 | 12 | 3 | 0 | 0 |
| 17. Rivalidades y Clásicos | 201–210 | 2 | 5 | 3 | 0 |
| 18. Legado e Historia del Club | 211–220 | 7 | 1 | 2 | 0 |
| 19. Roles de Juego (DT / Presidente / Dueño) | 221–230 | 8 | 2 | 0 | 0 |
| 20. Extras y Sistemas Meta | 231–250 | 11 | 4 | 5 | 0 |
| 21. Detalles de Ambientación | 251–260 | 4 | 5 | 1 | 0 |
| 22. Sistemas de Jugadores (detalle extra) | 261–270 | 5 | 4 | 1 | 0 |
| 23. Eventos de Crisis y Oportunidad | 271–280 | 4 | 3 | 3 | 0 |
| 24. Progresión y Metas | 281–290 | 5 | 4 | 1 | 0 |
| 25. Toques Finales de Personalización | 291–300 | 3 | 6 | 1 | 0 |
| 26. Simulación de Partido (minuto a minuto, sin animación completa) | 301–315 | 15 | 0 | 0 | 0 |
| 27. Récords, Historia y Memoria del Club | 316–325 | 5 | 3 | 2 | 0 |
| 28. Sala de Trofeos y Celebraciones | 326–335 | 4 | 3 | 3 | 0 |
| 29. Más Ideas Adicionales | 336–350 | 6 | 6 | 3 | 0 |
| **Total** | **350** | **224** | **82** | **43** | **1** |

**Ideas PENDIENTES** (no se encontró nada en el código):

- **Personalización visual**: 39. Colecciones especiales (edición aniversario, homenaje); 40. Personalización del logo del club en redes sociales; 42. Personalización del himno/cántico del club; 45. Diseño de banderines y merchandising.
- **Economía y Finanzas**: 118. Fondo de emergencia del club; 120. Bonos e incentivos fiscales por inversión en cantera.
- **Auspicios y Marketing**: 125. Sponsor de entrenamiento; 130. Colaboraciones con marcas para ediciones limitadas; 131. Sponsors regionales vs. internacionales; 133. Sponsors "sorpresa" que ofrecen tratos únicos; 135. Ferias/eventos de marca para aumentar reputación.
- **Fans y Comunidad**: 144. Fan zone fuera del estadio en días de partido; 145. Programa de fidelización de hinchas.
- **Medios y Prensa**: 162. Ranking de prensa sobre mejores DTs/presidentes; 164. Reportajes especiales sobre la cantera.
- **Premios y Reconocimientos**: 177. Mejor arquero del año; 179. Mejor presidente/dueño del año; 183. Premio al club más popular.
- **Rivalidades y Clásicos**: 204. Eventos especiales previos al clásico; 206. Fichajes polémicos entre rivales; 208. Comparación de logros con el rival histórico.
- **Legado e Historia del Club**: 211. Línea de tiempo histórica del club; 219. Leyendas como mentores de la cantera.
- **Extras y Sistemas Meta**: 231. Modo historia con objetivos guiados; 234. Guardado de partida en la nube; 238. Comparación con otros jugadores (si hay online); 240. Modo "carrera rápida" para partidas cortas; 250. Modo multijugador asíncrono (comparar ligas entre amigos).
- **Detalles de Ambientación**: 257. Impacto económico del club en la ciudad ficticia.
- **Sistemas de Jugadores (detalle extra)**: 269. Patrocinios personales de jugadores (compite con el club).
- **Eventos de Crisis y Oportunidad**: 272. Boom económico repentino de un sponsor; 275. Oferta de fusión con otro club (dilema); 279. Presión por bajar precios de entradas.
- **Progresión y Metas**: 283. Ranking histórico de mejores gestiones (leaderboard interno).
- **Toques Finales de Personalización**: 294. Personalización del bus del equipo.
- **Récords, Historia y Memoria del Club**: 318. Línea de tiempo navegable de temporadas anteriores; 324. Historial de presidentes/DTs anteriores y su legado.
- **Sala de Trofeos y Celebraciones**: 332. Exhibición temporal de un trofeo destacado en el estadio; 333. Ceremonia de entrega de camiseta homenaje en aniversarios; 334. Muro de campeones con fotos de planteles ganadores.
- **Más Ideas Adicionales**: 345. Resumen de prensa internacional si el club gana notoriedad; 348. Eventos climáticos que afectan la asistencia y el ánimo del público; 349. Modo "reconstrucción": heredar un club en crisis y sanearlo.

**Ideas PARCIALES**: 15, 34, 41, 43, 44, 50, 51, 52, 66, 67, 68, 71, 73, 80, 85, 90, 101, 114, 127, 128, 129, 132, 142, 147, 149, 152, 153, 154, 165, 176, 182, 184, 185, 191, 195, 199, 202, 205, 207, 209, 210, 215, 226, 229, 233, 237, 244, 246, 253, 256, 258, 259, 260, 263, 266, 268, 270, 273, 277, 278, 287, 288, 289, 290, 292, 293, 295, 296, 297, 299, 319, 320, 325, 327, 331, 335, 336, 337, 339, 340, 346, 350. Sin verificar: 2 (niveles de estadio «inhumanos»: hay topes de nivel, no se comprobó si el estadio los tiene).

## 4. TOP 25 PENDIENTES por impacto ÷ coste

Sin lo del dueño. **Impacto** = cuánto lo nota el jugador (3 alto, 2 medio, 1 bajo); **coste** estimado (1 poco: horas · 2 medio: un día o dos · 3 mucho). Orden por impacto ÷ coste y, a igualdad, por impacto. Incluye PENDIENTES y PARCIALES cuya parte que falta es la visible.

| # | Id | Qué | Impacto | Coste | Por qué / cómo |
|---:|---|---|---:|---:|---|
| 1 | M-072 | Árbitros con color por liga y contraste con los dos equipos (hoy siempre de negro) | 3 | 1 | se ve en cada plano del partido; tabla de 3 colores + regla de contraste en `PlayerSpawner.spawn_arbitros` |
| 2 | M-106 | Gestos del árbitro en el motor real (falta, ventaja, tarjeta, córner) | 3 | 1 | los clips `arbitro_*` ya existen y se usan en `MatchPlayback`; falta llamarlos desde `MotorJugable` |
| 3 | M-139 | Cartel del cuarto árbitro con el tiempo añadido | 2 | 1 | el añadido real ya se calcula (45'+1:23); falta el cartel 3D/2D |
| 4 | M-050 | Confeti, bengalas y humo de color en goles y salida | 2 | 1 | `GPUParticles3D` ya se usa en `Precipitacion`; engancharlo a la señal `gol` |
| 5 | M-149 | Red del arco que se ondula al gol | 2 | 1 | shader de vértice en la malla de la red, con impulso en el punto de entrada |
| 6 | M-118 | Línea de fuera de juego visible en la sala VAR | 2 | 1 | `margen_gol` ya da la posición; dibujar dos líneas en `SalaVAR` |
| 7 | ~~M-051~~ HECHO 17-10 | Escudo de la camiseta más grande (9-10 cm) y con relieve | 2 | 1 | cambiar el rectángulo de `escudo_tex` y añadir normal en `equipacion_q.gdshader` |
| 8 | ~~M-141~~ HECHO 17-10 | Valoraciones por jugador en el resumen del partido | 2 | 1 | el motor ya cuenta pases, entradas y remates por jugador |
| 9 | M-434 | Vibración del mando en gol, choque y entrada | 2 | 1 | `Input.start_joy_vibration` en las señales del motor |
| 10 | ~~M-104~~ HECHO 17-10 | Cambio de jugador con cartel y palmada | 2 | 1 | los cambios ya existen en el motor (`sale_id`); solo falta la escena |
| 11 | ~~M-160~~ HECHO 17-10 | Sorteo de campo con moneda y saludo de capitanes en la ceremonia | 2 | 1 | encaja en `CeremoniaPartido` |
| 12 | M-057 | Fabricantes de ropa inventados con logo propio por club | 2 | 1 | hoy una sola «ala» genérica en el shader |
| 13 | ~~M-238~~ HECHO 17-10 | Escena de despido del DT | 2 | 1 | la señal `Directiva.despedido` ya existe |
| 14 | ~~M-165~~ HECHO 17-10 | Prórroga y tanda de penales jugables en el 3D | 3 | 2 | lo que más se nota en copas (COMPARACION_JUEGOS_2 §6) |
| 15 | M-123 | Línea defensiva común: subir/bajar y trampa del fuera de juego | 3 | 2 | último 40 % del punto 7 de la MEGA AUD. 2 |
| 16 | M-114 | Separar reposiciones y suavizar giros bruscos del balón y los cuerpos (con M-115) | 3 | 2 | la sonda ya mide los dos problemas |
| 17 | M-263 | Semana con agenda en la Carrera de Jugador (entreno, descanso, vida social) | 3 | 2 | hoy hay eventos sueltos entre partidos |
| 18 | M-040 | Personas del club y de la ciudad en las primeras filas | 2 | 2 | pendiente reconocido en MEGA AUD. 2 (punto 2 al 80 %) |
| 19 | M-033 | Variedad de ropa y peinado en los hinchas (torso y pelo por instancia) | 2 | 2 | hoy color por instancia + shader |
| 20 | M-036 | Público que reacciona al gol en onda desde el sector y hace la ola | 2 | 2 | con M-044; todo en `hinchada.gdshader` por uniformes |
| 21 | M-132 | Repetición manual de los últimos 10 s | 2 | 2 | `Repeticion` ya graba |
| 22 | M-173 | Sonido del motor del coche con RPM (y radio con sonidos propios) | 2 | 2 | conducción mejorada sin sonido; sin música con licencia |
| 23 | M-178 | Minimapa y GPS hacia el club en la ciudad (con M-179) | 2 | 2 | `camino_entre` ya calcula rutas |
| 24 | M-130 | Modo práctica / entrenamiento libre para aprender los controles FC (con M-152) | 2 | 2 | 65+ combinaciones sin lugar donde probarlas |
| 25 | M-275 | Quitar el país «XXX» del rival en la Carrera de Jugador | 1 | 1 | una línea (`carrera_jugador.gd:620`) y comprobar banderas |

**2.ª tanda (17-10)**: M-104, M-160, M-141, M-051 y M-238 hechos, más los operadores de la sala VAR (polo, pelo, complexión normal y silla, como la gente de la ciudad). Coste del partido (`medir_partido`, ALTO, lavapipe): 632 llamadas y 761.687 triángulos, frente a 632 y 761.462 con el shader anterior (+0,03 %). Capturas `pruebas/capturas/top25b_*` (con `_antes`), banco `_probar_tanda_top25b`.

Fuera del TOP por ser del dueño: perfil de FPS en hardware real (M-337, M-341), narración por voz (M-317), música (M-323), historial/LFS, derechos de imagen y keystore (M-419, M-421, M-423, M-428).

