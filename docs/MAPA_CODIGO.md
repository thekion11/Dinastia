# MAPA DEL CÓDIGO

Generado por `dinastia-godot/herramientas/mapa_codigo.py` (no se edita a mano; el banco falla si difiere).

Qué es cada columna: **Usos** = archivos que nombran la clase; **Líneas** = tamaño (tope 450); **Capas** = cadena de herencia de `partir_gd.py` (la última conserva la ruta y el `class_name`).

Total: 2508 archivos (.gd, .cpp, .h), 359702 líneas, 991 clases con nombre.

## Extensión C++

22 archivos, 4614 líneas. Carpetas: `nativo/src`.

Cada función es copia exacta de su gemela GDScript (regla de la extensión). Archivos por tamaño:

- `nativo/src/partido_90.cpp` (429 líneas)
- `nativo/src/sin_balon_nativo.cpp` (427 líneas)
- `nativo/src/dinastia_nativo.cpp` (378 líneas)
- `nativo/src/league_portador_nativo.cpp` (378 líneas)
- `nativo/src/cerrar_notas.cpp` (354 líneas)
- `nativo/src/estado_nativo.cpp` (319 líneas)
- `nativo/src/league_equipo_nativo.cpp` (319 líneas)
- `nativo/src/pasos_nativo.cpp` (318 líneas)
- `nativo/src/guia_nativo.cpp` (259 líneas)
- `nativo/src/league_nativo.cpp` (182 líneas)
- `nativo/src/terreno_hierba.cpp` (178 líneas)
- `nativo/src/mover_nativo.cpp` (156 líneas)
- `nativo/src/dinastia_nativo.h` (149 líneas)
- `nativo/src/balon_nativo.cpp` (130 líneas)

## La Ruta (modo jugador)

38 archivos, 5506 líneas. Carpetas: `nucleo`, `ui/carrera`.

| Clase | Archivo | Líneas | Usos | Capas |
|---|---|---|---|---|
| `CarreraJugador` | `nucleo/carrera_jugador.gd` | 439 | 53 | carrera_jugador_p1.gd |
| `CarreraRuta` | `nucleo/carrera_ruta.gd` | 450 | 33 |  |
| `CarreraPremios` | `nucleo/carrera_premios.gd` | 250 | 14 |  |
| `CarreraPortero` | `nucleo/carrera_jugador_portero.gd` | 63 | 10 |  |
| `CarreraEstilo` | `nucleo/carrera_estilo.gd` | 126 | 9 |  |
| `CarreraEventosRuta` | `nucleo/carrera_eventos_ruta.gd` | 124 | 9 |  |
| `RutaSub` | `ui/carrera/ruta_sub.gd` | 136 | 9 |  |
| `CarreraHabilidad` | `nucleo/carrera_habilidad.gd` | 203 | 8 |  |
| `CarreraVida` | `nucleo/carrera_vida.gd` | 84 | 8 |  |
| `RutaEstilo` | `ui/carrera/ruta_estilo.gd` | 364 | 8 |  |
| `CarreraComienzo` | `nucleo/carrera_comienzo.gd` | 54 | 7 |  |
| `CarreraAgenda` | `nucleo/carrera_jugador_agenda.gd` | 76 | 7 |  |
| `CarreraLogros` | `nucleo/carrera_logros.gd` | 114 | 7 |  |
| `CarreraPatrocinio` | `nucleo/carrera_patrocinio.gd` | 72 | 7 |  |

Cerca del tope (≥ 400 líneas): `carrera_ruta.gd` (450), `carrera_jugador_p1.gd` (449), `carrera_jugador.gd` (439).

## Partido: motor C4 y respaldo

89 archivos, 15794 líneas. Carpetas: `nucleo`, `visor`.

| Clase | Archivo | Líneas | Usos | Capas |
|---|---|---|---|---|
| `Partido` | `nucleo/partido.gd` | 449 | 345 | partido_p2.gd ← partido_p1.gd |
| `MotorJugable` | `visor/motor_jugable.gd` | 201 | 181 | motor_jugable_p11.gd ← motor_jugable_p10.gd ← motor_jugable_p9.gd ← motor_jugable_p8.gd ← motor_jugable_p8_p1.gd ← motor_jugable_p7.gd ← motor_jugable_p7_p1.gd ← motor_jugable_p6.gd ← motor_jugable_p6_p1.gd ← motor_jugable_p5.gd ← motor_jugable_p5_p1.gd |
| `MotorLeague` | `visor/motor_league.gd` | 450 | 25 | motor_league_p1.gd |
| `MotorCombinado` | `visor/motor_combinado.gd` | 443 | 15 |  |
| `MotorTraza` | `visor/motor_traza.gd` | 260 | 14 |  |
| `LeagueNucleo` | `visor/league_nucleo.gd` | 450 | 13 |  |
| `MotorFabrica` | `visor/motor_fabrica.gd` | 21 | 13 |  |
| `LeagueAcciones` | `visor/league_acciones.gd` | 320 | 10 |  |
| `MejorasC4` | `visor/mejoras_c4.gd` | 33 | 10 | mejoras_c4_p1.gd |
| `LeagueLocomocion` | `visor/league_locomocion.gd` | 394 | 9 |  |
| `MotorReglas` | `visor/motor_reglas.gd` | 127 | 9 |  |
| `LeagueAnim` | `visor/league_anim.gd` | 127 | 8 |  |
| `LeagueMovimiento` | `visor/league_movimiento.gd` | 267 | 8 |  |
| `MotorColocacion` | `visor/motor_colocacion.gd` | 87 | 8 |  |

Cerca del tope (≥ 400 líneas): `partido_p1.gd` (450), `league_nucleo.gd` (450), `motor_jugable_p4.gd` (450), `motor_league.gd` (450), `partido.gd` (449), `motor_jugable_p2.gd` (449), `motor_jugable_p6_p1.gd` (448), `motor_jugable_p1.gd` (446), `motor_jugable_p8_p1.gd` (444), `motor_combinado.gd` (443).

## Club e instalaciones

21 archivos, 6262 líneas. Carpetas: `nucleo`, `visor`.

| Clase | Archivo | Líneas | Usos | Capas |
|---|---|---|---|---|
| `Club` | `nucleo/club.gd` | 416 | 817 |  |
| `StadiumBuilder` | `visor/stadium_builder.gd` | 13 | 135 | stadium_builder_p10.gd ← stadium_builder_p10_p1.gd ← estadio_partes_tribuna.gd ← stadium_builder_p9.gd ← stadium_builder_p8.gd ← stadium_builder_p7.gd ← stadium_builder_p6.gd ← stadium_builder_p5.gd ← stadium_builder_p4.gd ← stadium_builder_p3.gd ← stadium_builder_p2.gd |
| `EstadioExtras` | `visor/estadio_extras.gd` | 310 | 9 |  |
| `ClubDentro` | `nucleo/club_dentro.gd` | 285 | 8 |  |
| `CasaDT` | `visor/casa_dt.gd` | 322 | 7 |  |
| `EstadioObra` | `visor/estadio_partes_obra.gd` | 69 | 5 |  |
| `DetalleGrada` | `visor/estadio_partes_tribuna_detalle.gd` | 299 | 5 |  |
| `CasaPlano` | `visor/casa_plano.gd` | 210 | 4 |  |
| `CasaConstruccion` | `visor/casa_construccion.gd` | 133 | 2 |  |

Cerca del tope (≥ 400 líneas): `stadium_builder_p4.gd` (450), `stadium_builder_p6.gd` (449), `stadium_builder_p8.gd` (438), `stadium_builder_p7.gd` (434), `stadium_builder_p3.gd` (431), `stadium_builder_p2.gd` (424), `club.gd` (416), `stadium_builder_p5.gd` (413), `stadium_builder_p1.gd` (410).

## Menús e interfaz

469 archivos, 93363 líneas. Carpetas: `ui`, `ui/avanzar`, `ui/competiciones`, `ui/componentes`, `ui/entrada`, `ui/menu` ….

| Clase | Archivo | Líneas | Usos | Capas |
|---|---|---|---|---|
| `Principal` | `ui/principal.gd` | 55 | 260 | principal_p17.gd ← principal_p16.gd ← principal_p15.gd ← principal_p14.gd ← principal_p13.gd ← principal_p12.gd ← principal_p10.gd ← principal_p9.gd ← principal_p8.gd ← principal_p7.gd ← principal_p6.gd |
| `VistaEstadio` | `ui/estadio.gd` | 446 | 186 | estadio_p5.gd ← estadio_p5_p1.gd ← estadio_p4.gd ← estadio_p3.gd ← estadio_p2.gd ← estadio_p1.gd |
| `Tema` | `ui/tema.gd` | 153 | 159 |  |
| `VistaCiudad` | `ui/ciudad_vista.gd` | 218 | 102 | ciudad_vista_p1.gd ← ciudad_vista_p1_p1.gd |
| `Escudo` | `ui/escudo.gd` | 71 | 101 | escudo_p1.gd |
| `Cara` | `ui/cara.gd` | 378 | 75 | cara_p1.gd |
| `EscalaMovil` | `ui/componentes/escala_movil.gd` | 148 | 75 |  |
| `Animar` | `ui/componentes/animar.gd` | 95 | 70 |  |
| `PedidoPartida` | `ui/principal/pedido_partida.gd` | 71 | 68 |  |
| `AjustesCiudad` | `ui/componentes/ajustes_ciudad.gd` | 172 | 57 |  |
| `Tutorial` | `ui/componentes/tutorial.gd` | 221 | 48 | tutorial_p2.gd ← tutorial_p1.gd |
| `CajonAjustes` | `ui/componentes/cajon_ajustes.gd` | 258 | 47 |  |
| `MenuLateral` | `ui/componentes/menu_lateral.gd` | 423 | 39 |  |
| `Inicio` | `ui/inicio.gd` | 112 | 39 | inicio_p2.gd ← inicio_p1.gd |

Cerca del tope (≥ 400 líneas): `interior_instalacion_p6.gd` (450), `plantilla_pes.gd` (450), `pantalla_cantera_p2.gd` (450), `pantalla_opciones_p1.gd` (450), `telefono_p1.gd` (449), `pantalla_despacho.gd` (449), `panel_plantel.gd` (448), `estadio_p1.gd` (448), `partido_vivo_p2.gd` (448), `mando_giratorio_p1.gd` (447).

## Minijuegos

48 archivos, 1497 líneas. Carpetas: `minijuegos/retro5v5`, `minijuegos/retro5v5/resources`, `minijuegos/retro5v5/scenes`, `minijuegos/retro5v5/scenes/ball`, `minijuegos/retro5v5/scenes/ball/ball_states`, `minijuegos/retro5v5/scenes/characters` ….

| Clase | Archivo | Líneas | Usos | Capas |
|---|---|---|---|---|
| `Player` | `minijuegos/retro5v5/scenes/characters/player.gd` | 192 | 31 |  |
| `Ball` | `minijuegos/retro5v5/scenes/ball/ball.gd` | 89 | 19 |  |
| `PlayerState` | `minijuegos/retro5v5/scenes/characters/character_states/player_state.gd` | 43 | 17 |  |
| `GameState` | `minijuegos/retro5v5/scenes/game_manager/game_states/game_state.gd` | 14 | 8 |  |
| `PlayerStateData` | `minijuegos/retro5v5/scenes/characters/character_states/player_state_data.gd` | 30 | 6 |  |
| `BallState` | `minijuegos/retro5v5/scenes/ball/ball_states/ball_state.gd` | 54 | 5 |  |
| `AIBehavior` | `minijuegos/retro5v5/scenes/characters/ai/ai_behavior.gd` | 51 | 5 |  |
| `Retro5v5` | `minijuegos/retro5v5/retro5v5.gd` | 59 | 4 |  |
| `PlayerResource` | `minijuegos/retro5v5/resources/player_resource.gd` | 15 | 3 |  |
| `GameStateData` | `minijuegos/retro5v5/scenes/game_manager/game_states/game_state_data.gd` | 10 | 3 |  |
| `GameStateKickoff` | `minijuegos/retro5v5/scenes/game_manager/game_states/game_state_kickoff.gd` | 21 | 3 |  |
| `Goal` | `minijuegos/retro5v5/scenes/goal/goal.gd` | 36 | 3 |  |
| `BallStateData` | `minijuegos/retro5v5/scenes/ball/ball_states/ball_state_data.gd` | 10 | 2 |  |
| `BallStateFactory` | `minijuegos/retro5v5/scenes/ball/ball_state_factory.gd` | 14 | 1 |  |

## Pruebas y banco

1226 archivos, 117765 líneas. Carpetas: `pruebas`, `pruebas/_sonda`, `pruebas/arena`, `pruebas/banco`, `pruebas/bancos`, `pruebas/ideas` ….

Entradas: `pruebas/banco.gd` (secciones en `pruebas/banco/*.gd`), escenas `*.tscn` lanzadas por `herramientas/banco.sh` y `especiales.sh`.

## Núcleo: mundo, gestión y datos

248 archivos, 51599 líneas. Carpetas: `nucleo`.

| Clase | Archivo | Líneas | Usos | Capas |
|---|---|---|---|---|
| `Mundo` | `nucleo/mundo.gd` | 158 | 906 | mundo_p7.gd ← mundo_p7_p1.gd ← mundo_p6.gd ← mundo_p5.gd ← mundo_p5_p2.gd ← mundo_p5_p1.gd ← mundo_p4.gd ← mundo_p3.gd ← mundo_p3_p1.gd ← mundo_p2.gd ← mundo_p1.gd |
| `Jugador` | `nucleo/jugador.gd` | 450 | 470 |  |
| `Liga` | `nucleo/liga.gd` | 235 | 193 |  |
| `Nombres` | `nucleo/nombres.gd` | 169 | 168 |  |
| `Partida` | `nucleo/partida.gd` | 450 | 117 | partida_p1.gd |
| `Copa` | `nucleo/copa.gd` | 348 | 93 |  |
| `Mercado` | `nucleo/mercado.gd` | 64 | 91 | mercado_p1.gd |
| `Finanzas` | `nucleo/finanzas.gd` | 384 | 89 |  |
| `Roles` | `nucleo/roles.gd` | 357 | 77 | roles_p4.gd ← roles_p3.gd ← roles_p2.gd ← roles_p1.gd |
| `Prensa` | `nucleo/prensa.gd` | 445 | 74 | prensa_p6.gd ← prensa_p5.gd ← prensa_p4.gd ← prensa_p4_p1.gd ← prensa_p3.gd ← prensa_p2.gd ← prensa_p1.gd |
| `Calendario` | `nucleo/calendario.gd` | 78 | 70 | calendario_p1.gd |
| `CargaCiudad` | `nucleo/carga_ciudad.gd` | 14 | 67 |  |
| `Cantera` | `nucleo/cantera.gd` | 209 | 65 | cantera_p3.gd ← cantera_p2.gd ← cantera_p1.gd |
| `Banco` | `nucleo/banco.gd` | 241 | 62 |  |

Cerca del tope (≥ 400 líneas): `idiomas.gd` (450), `jugador.gd` (450), `mercado_p1.gd` (450), `partida.gd` (450), `roles_p4.gd` (450), `mundo_p1.gd` (449), `partida_p1.gd` (449), `musica.gd` (446), `selecciones_p2.gd` (446), `prensa.gd` (445).

## Visor: 3D, cámaras y efectos

327 archivos, 61068 líneas. Carpetas: `visor`.

| Clase | Archivo | Líneas | Usos | Capas |
|---|---|---|---|---|
| `Calidad` | `visor/calidad.gd` | 22 | 267 | calidad_p1.gd |
| `CityBuilder` | `visor/city_builder.gd` | 185 | 165 | city_builder_p11.gd ← city_builder_p10.gd ← city_builder_p9.gd ← city_builder_p8.gd ← city_builder_p7.gd ← city_builder_p6.gd ← city_builder_p5.gd ← city_builder_p4.gd ← city_builder_p3.gd ← city_builder_p2.gd ← city_builder_p1.gd |
| `FutbolistaQ` | `visor/futbolista_q.gd` | 203 | 128 |  |
| `ExploradorCiudad` | `visor/explorador_ciudad.gd` | 12 | 115 | explorador_ciudad_p5.gd ← explorador_ciudad_p5_p1.gd ← explorador_ciudad_p4.gd ← explorador_ciudad_p3.gd ← explorador_ciudad_p2.gd ← explorador_ciudad_p1.gd |
| `PlayerSpawner` | `visor/player_spawner.gd` | 230 | 95 | player_spawner_p1.gd |
| `Puente3D` | `visor/puente3d.gd` | 223 | 91 |  |
| `PersonajeDT` | `visor/personaje_dt.gd` | 344 | 77 | personaje_dt_p1.gd ← personaje_dt_p1_p1.gd |
| `Mini3D` | `visor/mini3d.gd` | 257 | 62 |  |
| `CiudadExpansion` | `visor/ciudad_expansion.gd` | 421 | 59 | ciudad_expansion_p8.gd ← ciudad_expansion_p7.gd ← ciudad_expansion_p6.gd ← ciudad_expansion_p5.gd ← ciudad_expansion_p4.gd ← ciudad_expansion_p3.gd ← ciudad_expansion_p2.gd ← ciudad_expansion_p1.gd |
| `CameraRig` | `visor/camera_rig.gd` | 245 | 57 | camera_rig_p1.gd |
| `VidaCiudad` | `visor/vida_ciudad.gd` | 432 | 51 | vida_ciudad_p1.gd |
| `Texturas` | `visor/texturas.gd` | 36 | 48 | texturas_p1.gd |
| `TraficoCiudad` | `visor/trafico_ciudad.gd` | 450 | 44 | trafico_ciudad_p1.gd |
| `EdificioClub` | `visor/edificio_club.gd` | 300 | 43 | edificio_club_p1.gd |

Cerca del tope (≥ 400 líneas): `anim_quaternius.gd` (450), `city_builder_p1.gd` (450), `city_builder_p9.gd` (450), `edificio_club_p1.gd` (450), `explorador_ciudad_p1.gd` (450), `explorador_ciudad_p3.gd` (450), `explorador_ciudad_p5_p1.gd` (450), `personaje_dt_p1_p1.gd` (450), `texturas_p1.gd` (450), `trafico_ciudad.gd` (450).
