# Terceros (League-Soccer y soccer5v5): qué reemplazar, unir, guardar o descartar

Rutas relativas a `dinastia-godot/terceros/league_soccer/codigo_y_recursos/` (LS) y a `dinastia-godot/` (nuestro).

## Resumen

La gestión de LS es mucho más delgada que la nuestra. Sus piezas principales:
- `src/league/leaguecode.cpp`: liga de ida y vuelta con `GenerateRoundRobinFixtures` y `StepLeagueTime`.
- `src/menu/career/career_sim.cpp`: simulación con `PoissonGoals` y `ClubRating`.
- `career_finance.cpp`, `src/data/transfermarket.cpp` (48 líneas) y `career_sponsors.cpp`, con patrocinadores fijos en `GenerateSponsorOffers`.

Nuestra gestión ocupa 384 archivos en `nucleo/`. **No hay nada que REEMPLAZAR en gestión, guardado ni menús.** Lo que sí sirve de LS:
- los iconos de botones y teclas;
- los textos en 5 idiomas, como glosario;
- la idea de bandeja de entrada, química y moral;
- su método de pruebas.

## 1. REEMPLAZAR

**Nada claro.** Comparación punto por punto:

| Área | LS | Nuestro | Veredicto |
|---|---|---|---|
| Liga y calendario | `GenerateRoundRobinFixtures`, `GenerateSeasonCalendars` | `nucleo/calendario.gd`, `liga.gd`, `copa.gd`, `continental*.gd`, `federacion*.gd` | Nuestro es más completo |
| Simulación | `career_sim.cpp`: Poisson con valoración del club | `nucleo/partido*.gd` y motor real | Nuestro |
| Mercado | `TransferMarket::SubmitBid/ProcessAIBids` | `mercado*.gd`, `negociacion.gd`, `mesa_agente.gd`, `cesiones*.gd`, `precontratos.gd` | Nuestro |
| Finanzas y dueño | `ownerpages.cpp` (entradas, estadio, patrocinios) | `finanzas.gd`, `economia.gd`, `estadio_propio*.gd`, `auspicio.gd`, `crisis_caja.gd`, `insolvencia.gd` | Nuestro |
| Guardado | SQLite en `career_persistence.cpp` (`Save/Load`, lectura de formatos viejos) | `partida_archivo.gd`: escribe a un `.tmp`, guarda 3 copias rotativas (`.bak`, `.bak2`, `.bak3`), comprueba con una huella y tiene versión | El nuestro es más robusto |
| Ajustes gráficos | `visualoptions.cpp`: sol al azar, uniforme | `pantalla_opciones.gd`: calidades y bajada automática a menos de 40 FPS | Nuestro |
| Shaders | `data/media/shaders/*.frag` (GLSL 150, otro motor) | Godot Forward+ | No se pueden portar |

## 2. UNIR

| # | Qué | Dónde (LS → nuestro) | Esfuerzo | Prioridad |
|---|---|---|---|---|
| U1 | **Iconos de mando y teclado** (53 PNG de 128 px: Xbox, PS, Switch y teclas). Los genera `tools/generate_controller_and_keyboard_icons.py` (Python puro; el script dice «Public Domain»). Mejor que copiar los PNG: llevar el script a `herramientas/` y regenerarlos a nuestro estilo. | `data/media/menu/buttons/` → `ui/componentes/teclas_interfaz.gd`, `panel_controles*.gd`, `dibujo_mando.gd` (hoy se dibujan a mano), indicaciones en pantalla y tutorial | Pequeño | Alta |
| U2 | **Glosario de 5 idiomas**: 973 claves en `data/locale/{es,en,de,fr,pt}.ini`. Sirve para revisar los términos de fútbol y de interfaz que ya tenemos en de, fr y pt (fuera de juego, saque de banda, «Super Cancel»…). No se suman idiomas. Lo que se use entra con `sumar_traducciones.py`. | → `datos/idiomas_extra.json` | Pequeño | Media |
| U3 | **Bandeja de entrada**: mensajes con remitente y asunto, borrar y contador. Comparar con nuestras categorías de aviso y el teléfono; sumar lo que falte (por ejemplo, borrar en lote o contador de no leídos). | `src/menu/league/league_inbox.cpp`, tabla `inbox_messages` en `leaguecode.cpp` → `ui/componentes/telefono*.gd`, `categoria_aviso.gd` | Pequeño | Media |
| U4 | **Química del equipo y moral tras fichajes**: `MoraleManager::ComputeTeamChemistry`, `UpdateAfterTransfer`, `GetPerformanceMultiplier`. Hay que ver si `vestuario*.gd` ya cubre esto. | `src/data/moraledata.cpp` → `nucleo/vestuario*.gd` | Pequeño | Media |
| U5 | **Plan de entrenamiento continuo** (Equilibrado, Desarrollo o Recuperación), que se aplica en cada partido. Tabla en `docs/career-progression.md`. Comparar con lo nuestro; puede ser una opción más. | `career_training.cpp` → `nucleo/entrenamiento*.gd` | Pequeño | Baja |
| U6 | **Pruebas**: | | | |
| | • Prueba de partida dañada: `load_damaged_save` en `docs/gap-list.md` §403 y `menu_smoke_league_damaged_save.config`. | → `pruebas/banco/guardado*.gd` | Pequeño | Alta |
| | • Prueba de rutas de menú que falla si una etiqueta se sale de la pantalla: `tests/run_menu_layout_audit.py`, más de 40 rutas. | → herramienta GDScript para el banco | Medio | Media |
| | • Auditoría de 12 temporadas con 4 niveles de club y semilla fija: `tests/career/career_longrun_audit_test.cpp`. | → `pruebas/prueba_larga.gd` | Pequeño | Media |
| U7 | **Lista de fallos típicos ya resueltos** en un manager, para buscarlos en el nuestro: | `docs/gap-list.md` | Pequeño | Alta |
| | • un fichaje libre sin años de contrato; | | | |
| | • un contrato que vence y no devuelve el sueldo al presupuesto; | | | |
| | • canteranos que no envejecen; | | | |
| | • el mercado que ofrece jugadores propios; | | | |
| | • guardar antes de tener el club; | | | |
| | • posesión que suma 101 %; | | | |
| | • minuto «45+2'»; | | | |
| | • 3-0 si un equipo queda con 6. | | | |

## 3. GUARDAR PARA EL FUTURO

- **Modos del dueño** (Dueño/GM, Entrenador, delegado, «legado») y patrocinios con años y condiciones. Están en `ownerpages.cpp` y `career_board.cpp`. Sirven de lista de control cuando se pula la directiva (`nucleo/junta.gd`, `directiva.gd`). Esfuerzo medio, prioridad baja.
- **Editor de balón parado** (`src/menu/ingame/setpieceeditor.cpp`, `src/data/setpiececonfig.cpp`). Va con la TÁCTICA de la pasada final del motor (orden 13). Esfuerzo grande, prioridad media en esa pasada.
- **Draft y academia**: `draftdata.cpp` y `youthacademy.cpp`. Un draft de juveniles podría ser una opción de liga. Esfuerzo medio, prioridad baja.
- **Radar del partido** (`data/media/menu/radar/radar.png`, 1100×720, y los puntos `p1`, `p2` y `ball`). Ya tenemos `RadarPartido` (`ui/estadio_p3.gd`), así que solo sirve de referencia de estilo. Esfuerzo pequeño, prioridad baja.
- **Texturas de césped y estadio**: `textures/pitch/pitch_0X` con mapas normal y especular, `seamlessgrass08.png`, `stadium/goalnetting.png`, `crowd01.png` y `concrete/`. Sirven para la pasada visual del pasto y las redes, comparándolas con el `grass.blend` del Drive. Origen sin confirmar: vienen de GameplayFootball y Google Research Football. Esfuerzo pequeño, prioridad baja.
- **Fuente Alegreya Sans y Alegreya Sans SC** (`data/media/fonts/alegreya/`, OFL 1.1, uso comercial libre). Útil para el periódico, los trofeos o el museo si se quiere un toque clásico. Esfuerzo pequeño, prioridad baja.
- **Sonidos** (`data/media/sounds/`, 8 WAV: gentío, poste, silbatos, clic). Solo como respaldo: nuestro audio es sintetizado. Si se usa alguno, va en `audio/ui/<nombre>.ogg`. El origen exacto no figura en el repositorio. Esfuerzo pequeño, prioridad baja.
- **soccer5v5, arquitectura**. Tiene una fábrica de estados (`scenes/characters/player_state_factory.gd`, 15 estados), estados del balón (`ball_states/`: llevado, libre, disparo), estados del partido (`game_manager/game_states/`: saque, en juego, gol, prórroga, fin) e IA de campo y de portero (`characters/ai/`). Ya está en `minijuegos/retro5v5/`. Para nuestro motor 3D (`visor/motor_jugable*.gd`) vale como **modelo de refactor**: un estado por clase, que además encaja con la norma de 450 líneas. Conviene hacerlo en la pasada final del motor, no ahora. También es buena base para otros minijuegos 2D (penales o futbolito con la misma máquina de estados). Esfuerzo grande en el motor y medio en minijuegos. Prioridad media, en la pasada final.

## 4. NO SIRVE

- Los shaders GLSL de `data/media/shaders/`, el motor C++ entero (`src/managers`, `src/utils/gui2`, `text2d`, `textrenderlock.hpp`) y `database.cpp`/`sqltext.hpp`: todo esto es de otro motor.
- La dificultad de 5 pasos (`src/utils/difficulty.hpp`): la nuestra tiene 8 (orden 14).
- Los guiones `modernize_*.py`, `Dockerfile`, `shell.nix`, `build.*` y los `menu_smoke_*.config`: sirven solo como idea (ver U6).
- Las imágenes `controller/controller_*.png`, porque la silueta del mando de Xbox es reconocible. Para dibujar el mando es mejor nuestro `dibujo_mando.gd`.

## Avisos de licencia y marcas (no publicar sin revisar)

- **Marcas de LS**: `menu/main/title01.png` (logo «LEAGUE SOCCER»), `menu/tvlogo.png` («LS SPORTS LIVE HD»), `menu/league.png` y `menu/credits/`. No van en Dinastía.
- **Publicidad con nombres reales**: `textures/adboards/ad_groningen01.png` usa el lema y el logo reales de la ciudad de Groningen. `ad_polygon*`, `ad_indietopia01`, `ad_stark0X`, `ad_tenshu01`, `ad_brokenbread01`, `ad_blauwprint01`, `ad_bleep01`, `ad_3xblast01`, `ad_omeganorth01` y `ad_altfunc01` parecen patrocinadores o estudios reales del proyecto original. **No usar.**
- **Imágenes generadas con IA**: los carteles «meme» (`adboards/memes/*`) y el balón (`docs/artwork/meme-kit/manifest.json` lo dice). Además, el tono «meme» no encaja con nuestro estilo. **No usar.** Los fondos `backgrounds/stadium01.png` y `megabackground01.jpg` tienen aspecto de foto de archivo o de imagen generada. Su origen no consta, así que no conviene usarlos.
- **Iconos de mando**: los glifos con los nombres «Xbox», «PS» y «Switch» sirven para indicar botones, que es lo habitual. Lo que no se debe hacer es meter logos de consola.
- **soccer5v5**:
  - `assets/fonts/Daydream.ttf` es **SOLO USO PERSONAL**. Ya está excluida, así que hay que mantenerla fuera.
  - `Pixeled.ttf` no trae licencia: no usarla.
  - Las 4 músicas `.mp3` **ya se cargan** en `minijuegos/retro5v5/assets/music/`, pero no tengo pruebas de que sean MIT: el README original no cita su origen. Hay que confirmarlo antes de publicar o sustituirlas por música propia (`nucleo/musica.gd`).
  - El rótulo «World Cup» ya figura como pendiente en `terceros/soccer5v5/LEEME_DINASTIA.md`.
- **Atribución**: Apache 2.0 pide conservar el aviso de licencia, y MIT el copyright de Habeeb Rahman. **`LICENCIAS.md` no nombra hoy ni a League-Soccer ni a soccer5v5**, y ya usamos las animaciones de LS y el minijuego retro5v5: hay que sumar a los dos (esfuerzo pequeño, prioridad alta).

## Orden sugerido

1. U1 (iconos, regenerados).
2. U7 (cazar esos mismos fallos en el nuestro).
3. U6 (partida dañada).
4. Revisar la licencia de las músicas de retro5v5.
5. U2 y U3.
6. El resto, en la pasada final del motor.
