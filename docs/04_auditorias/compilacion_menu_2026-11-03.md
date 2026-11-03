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
