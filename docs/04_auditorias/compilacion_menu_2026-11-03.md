# Compilar el menú: 423 MB de GDScript (análisis, 3-11-2026)
Solo análisis, ningún cambio de código del juego. Herramientas en `herramientas/compilacion_menu/`.

## Qué pasa
Godot compila un script en cuanto otro lo nombra (tipo, `Clase.método()`, `extends`, `preload`). Desde `ui/principal.gd` y las autocargas se alcanzan **830 de los 886 scripts** (8,2 MB de fuente): al abrir el menú se compila casi todo el juego.
Medido con el `.pck` precompilado (`godot --export-pack` con `script_export_mode=2` + `--main-pack`, igual que el export real): `load(principal.tscn)` **455 MB**, primer fotograma del menú **687-696 MB** (editor: 509 / 751).
Calibración: ~0,068 MB de RAM por KB de fuente compilado (la ciudad: 1 551 KB de fuente → 105 MB).

## Dónde está el peso (árbol de dominadores desde `Principal`)
`Principal` (17 capas, solo 65 KB) domina el 97 % del grafo: lo arrastra TODO directamente. No hay un puente único caro (cortar uno ahorra ~15-20 MB: los 5 mayores son `VistaEstadio` 300 KB, `StadiumBuilder` 265, `CiudadExpansion` 258, `ExploradorCiudad` 252, `MotorJugable` 239),
pero se agrupan en familias que el menú no necesita hasta que el jugador sale a ellas:
| Familia | Scripts | Fuente | Qué contiene |
|---|---|---|---|
| Ciudad 3D | 156 | 1 551 KB | `CityBuilder`, `CiudadExpansion`, `ExploradorCiudad`, `InteriorInstalacion`, `VidaCiudad`, `MetroCiudad`, `CasaEscena3D`, `Teleferico`… |
| Estadio y partido 3D | 114 | 1 541 KB | `VistaEstadio`, `StadiumBuilder`, `MotorJugable`, `MatchPlayback`, `ExploradorEstadio`… (sin `nucleo/`: el simulador lo usa el menú) |
| Pantallas de gestión | 71 | 753 KB | `PantallaPlantel`, `Legado`, `Finanzas`, `ClubVida`, `Ajustes`, `Ficha`, `Cantera`, `Gente`… |
| Núcleo y resto | ~490 | ~4 MB | `Mundo`, `Roles`, `Club`, `Partido` (simulación), `Prensa`, `Telefono`, `Tutorial`… (el menú lo usa o lo enseña de entrada) |

## Experimentos (copia local, sin subir; `exper.py`)
Se sustituyen las referencias a la familia, desde fuera de ella, por `load("res://…")` (código solo válido para medir; el control quita además `:=` en todo el proyecto) y se mide con el `.pck` precompilado:
| Corte | Carga de la escena | Primer fotograma | Ahorro | Archivos / líneas a tocar | Riesgo |
|---|---|---|---|---|---|
| Control (nada cortado) | 455 MB | 687 MB | — | — | — |
| **Pantallas de gestión** | 408 | 649 | **−38 MB** | 19 / 51 | bajo: son `PantallaX.abrir(…)` desde Principal |
| **Ciudad 3D** | 350 | 582 | **−105 MB** | 69 / 259 | medio: muchas llamadas estáticas, tipos en firmas y `const` |
| Ciudad + pantallas | 302 | 546 | **−141 MB** | 80 / 302 | medio |
| Estadio y partido 3D | 390 | 682 | no concluyente (−5) | 73 / 418 | alto |
- **Estadio y partido**: al cargar la escena baja 65 MB, pero al instanciar `Principal` vuelve a cargarse todo (los 114 scripts quedan en caché): queda una referencia estática que no se ha cortado (una `const`/`preload`, una escena o `PartidoVivo`). Estimación por la calibración: ~100 MB si se encuentra y se corta.
- Los cortes de `const`/`enum` no se tocaron en el experimento (siguen cargando lo que nombran): los ahorros medidos son una COTA INFERIOR.
- Los 5 puentes mayores por separado (estimación, 0,068 MB/KB): `VistaEstadio` ~20 MB, `StadiumBuilder` ~18, `CiudadExpansion` ~17, `ExploradorCiudad` ~17, `MotorJugable` ~16. Cortar uno solo no compensa; compensa cortar la familia entera.

## Recomendación (para decidir mañana)
1. **Pantallas de gestión** primero: −38 MB, 19 archivos, riesgo bajo. Un cargador perezoso (`Cargar.pantalla("plantel")` que hace `load()` al abrir) y quitar los tipos de las firmas de `Principal`.
2. **Ciudad 3D**: −105 MB, ~70 archivos. Mismo cargador y un punto de entrada único `Ciudad.abrir(…)` en vez de nombrar sus clases desde la interfaz. Hay que cambiar los `const` y las llamadas estáticas que apuntan a la ciudad desde fuera de ella.
3. **Estadio y partido**: antes hay que localizar el cargador estático que lo vuelve a traer al instanciar `Principal` (script `mem7` del análisis: `ResourceLoader.has_cached` sobre la familia tras instanciar). Ahorro esperado ~100 MB.
4. Con los tres: ~245 MB menos de los 687 (−35 %), de ~690 a ~440 MB en el menú. No toca el simulador ni la lógica; sí muchos archivos de la interfaz.
5. Pruebas necesarias: el banco entero y `especiales.sh`, más una pasada abriendo cada pantalla y la ciudad/estadio (los fallos serían «identificador no encontrado» al abrirlas, no al arrancar).

## Estadio y partido 3D: HECHO (3-11, sesión ejecutora)
**Paso 1 — qué la volvía a cargar al instanciar `Principal`.** No era una `const` ni una escena ni `PartidoVivo`: eran DOS variables de clase de `Principal` (`ui/principal_p1.gd`), `var _ui_club_estadio := PantallaClubEstadio.new(self)` y `var _jornada := JornadaPartido.new(self)`. Las dos clases cuelgan del árbol de dominadores de la familia (la pantalla del estadio y el flujo del partido arrastran `VistaEstadio`, `StadiumBuilder`, `MotorJugable`…), y construirlas al crear `Principal` cargaba ~85 scripts. Se encontró con `ResourceLoader.has_cached` sobre los 114 scripts de la familia (`mem4.gd`: 29 en caché tras `load(principal.tscn)`, 114 tras `instantiate`) y los `Loading resource:` de `--verbose` entre las dos marcas (`pantalla_club_estadio` y `jornada_partido`).
**Paso 2 — cortes** (herramienta `herramientas/compilacion_menu/cortar.py <familia> [--aplicar]`, la transformación del experimento pero sobre el código real; imprime lo que hay que hacer a mano):
- `_ui_club_estadio` y `_jornada` se crean al USARLAS (propiedad con `get`, mismos nombres de acceso).
- Las 60 referencias estáticas a la familia desde fuera (396 líneas → 155 tras el paso siguiente) pasan a `load("res://…")` (se cargan al usarlas): `StadiumBuilder.geom_de_forma/build/niveles_de…`, `VistaEstadio.new/poner_banca_de…`, `MotorJugable.LARGO/new…`, `PersonalEstadio`, `Anim*`…; los tipos de firma se quitan (`motor: MotorJugable` → sin tipo) y los `:=` que ya no pueden inferir pasan a `=`.
- Lo que más aparecía (235 referencias) eran las piezas de obra de `TunelVestuario` que usa también el edificio del club: `_caja`, `_mat`, `_mat_unico`, `_rotulo` salen a `PiezasObra` (sin dependencias) y las medidas (`VEST_MEDIO`, `PUERTA_X`, `ALTO`…) y `zona_en` a `TunelMedidas`. `TunelVestuario` conserva los mismos nombres llamando a los nuevos.
- `is VistaEstadio or is VistaCiudad` (vistas_menu) → por `Script.get_global_name()`; `colision_club.gd`: `pe` sin tipo.
**Medido** con el `.pck` precompilado (`godot --export-pack Windows` con `script_export_mode=2` + `--main-pack`; `mem3.gd`/`mem4.gd`):
| | Carga de la escena | Tras instanciar | Primer fotograma | Familia en caché (de 114) |
|---|---|---|---|---|
| Antes (rama del líder) | 456 MB | 456 MB | **658 MB** | 114 / 114 |
| Después | 371 MB | 372 MB | **571 MB** | 1 / 114 (`personal_estadio`) → 3 en el primer fotograma (la pestaña del estadio crea su pantalla) |
(−85 MB al cargar la escena y **−87 MB (−13 %) en el primer fotograma**; la estimación era ~100.) El juego no cambia: `igualdad_motor` e `igualdad_mundo` intactas; banco 5×0 fallos; `comprobar_scripts` 1780 scripts sin errores (12 de `pruebas/` necesitaron `:=` → `=` por el motor sin tipo). Prueba nueva `pruebas/ideas/mem_menu_estadio.tscn` (en `especiales.sh`): en su propio proceso, tras abrir el menú ninguno de los scripts gordos del estadio/partido está en memoria.
**Para quien corte las otras familias:** el mismo `cortar.py ciudad` / `pantallas`; ojo con los inicializadores de clase de `Principal` (`var _x := Clase.new(self)`): son los que cargan todo al instanciar aunque la escena ya no lo cargue. Las piezas compartidas (cajas, materiales, medidas) conviene sacarlas a una clase sin dependencias antes de cortar.

## Grupos chicos: HECHO (3-11, sesión ejecutora)
Tras cortar estadio/partido, ciudad y pantallas (menú 657 → 444 MB en el 1.er fotograma, 456 → 240 al cargar la escena), `fam.py` define ahora la familia **`chicos`** (94 scripts, 885 KB): personajes 3D (`CreadorPersonaje`, `VestidorQ`, `PersonajeDT`, `PeloCapas`, `FutbolistaQ`, `CaraMalla`, `PersonaRealista`, `PersonajeVida`, `PlayerSpawner`), edificio del club y museo (`EdificioClub`, `RecorridoClub`, `SalasClub`, `GaleriaClub`, `MuseoAmpliado`), prensa 3D (`RuedaPrensaEscena3D`, `rueda_prensa.gd`, `PortadaPeriodico`), kits y escudos (`DisenosKit`, `DisenadorKit`, `EscudoEmblemas`), extras del partido (`Repeticion`, `CineGol`, `ControlFC`, `PanelControles`, `PartidoJugable`) y `SalaMinijuegos`. `cortar.py chicos --aplicar` (ahora solo toca los scripts que el menú compila: `res not in base`) cambió 27 archivos / 71 líneas (la mayor parte de las aristas ya las habían cortado las otras familias). Medido con el mismo `.pck` precompilado:
| | Carga de la escena | Primer fotograma | Grupo chico en caché |
|---|---|---|---|
| Antes (rama del líder) | 240 MB | 443 MB | 94 / 94 |
| Después | **193 MB** | **398 MB** (−45 MB, −10 %) | 0 / 94 al cargar · 20 / 94 en el primer fotograma |
Lo que quedaba amarrado y no se veía en `cortar.py` (no son llamadas, son `const`, estáticos y llamadas a métodos con efectos):
- `const _PrincipalRuedaPrensa := preload(…)` en `principal_p2.gd` (cortar.py no toca `const`): arrastraba la rueda de prensa 3D entera. Ahora `load()` en `principal_p17.gd` y las llamadas por `call`/`get`/`set`.
- `EdificioClub.fijar_ctx(mundo, club)` en cada refresco del menú (`avance_semana.gd`): compilaba el edificio, la galería, el museo y el recorrido. Ahora el menú solo anota el mundo y el club en `PendienteClub` (hoja, referencias débiles) y `EdificioClub.ctx` / `mundo_ref` (ahora propiedades estáticas con `get`) lo aplican la primera vez que alguien las lee.
- `PersonajeDT.del_usuario` / `club_usuario` (estáticos que fija el menú): pasan a `UsuarioEn3D` (hoja) y `PersonajeDT` los reexpone con el mismo nombre (propiedades estáticas con `get`/`set`).
- `is PortadaPeriodico` (principal.gd) → por `Script.get_global_name()`.
**Lo que queda a propósito en el primer fotograma** (lo pinta el menú central): el retrato 3D del DT (`PersonajeDT`, `VestidorQ`, `PeloCapas`, `CaraMalla`, `FutbolistaQ`: ~11 MB), las camisetas de los clubes (`DisenosKit`) y los escudos (`EscudoEmblemas`). Verificado con `ResourceLoader.has_cached` sobre los 94 scripts, tras `load`, tras `instantiate` y en el primer fotograma (`mem4.gd`).
La prueba `pruebas/ideas/mem_menu_estadio.tscn` comprueba también este grupo (partido jugable, edificio, galería, recorrido, museo, rueda de prensa, creador de personaje, minijuegos, panel de controles, diseñador de kits, repetición, cine del gol): ninguno en memoria tras abrir el menú.

