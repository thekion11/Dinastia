# Coste del MUNDO ENTERO frente a un mundo parcial — 10-11-2026, sesión 5

Encargo del dueño (para la pantalla «Ligas activas», sesión 6). Herramienta: `dinastia-godot/pruebas/zz_coste_mundo.tscn` (un proceso por configuración: la RAM sale limpia). Datos de `main` (rama `sesion5-cpp` fusionada con `main` el 10-11: **71 países, 1.375 clubes, 34.375 jugadores**), semilla 4711, extensión C++ activa (Linux x86_64).
- **Configuraciones**: `1` = Chile (32 clubes); `5` = CHI + los 4 países con más clubes (ARG, USA, EGY, BRA); `15` = CHI + los 14 con más clubes (ARG, USA, EGY, BRA, COL, ESP, ENG, ITA, JPN, NGA, IRQ, PER, GER, FRA); `TODOS` = `Mundo.generar([])`. Se eligen por NÚMERO DE CLUBES, no por «ligas grandes»: si se quieren las cinco ligas top de Europa + las de Sudamérica, el coste sale parecido al de «15».
- **PC** = este contenedor, 4 núcleos, `godot --headless`. **MODESTO** = `herramientas/hw_modesto.sh` (2 núcleos, cgroup de 4 GB, como un equipo de 4 GB DDR3 / Pentium).
- «semana» = media de 5 `avanzar_semana()` (con tu club en el mundo); «resto de temporada» = `jugar_temporada()` hasta el final tras esas 5 semanas; «cierre» = `nueva_temporada()` (ascensos, premios, envejecer, selecciones).

## Tabla (tiempos en ms; RAM en MB)
| | 1 país | 5 países | 15 países | **MUNDO ENTERO** |
|---|---|---|---|---|
| clubes / jugadores | 32 / 800 | 169 / 4.225 | 487 / 12.175 | **1.375 / 34.375** |
| **Generar** PC | 42 | 210 | 684 | **2.072** |
| Generar MODESTO | 49 | 234 | 1.094 | 1.875 |
| **Una semana** PC | 57 | 234 | 571 | **1.408** |
| Una semana MODESTO | 52 | 223 | 822 | 1.390 |
| **Resto de una temporada** PC | 1.147 | 5.770 | 15.090 | **33.912** |
| Resto de temporada MODESTO | 1.044 | 5.269 | 14.443 | 34.070 |
| **Cierre de temporada** PC | 407 | 615 | 1.091 | **3.596** |
| Cierre MODESTO | 624 | 590 | 1.226 | 3.464 |
| **Guardar** PC | 64 | 289 | 855 | **2.423** |
| **Cargar** PC | 68 | 320 | 750 | **2.073** |
| Guardar / cargar MODESTO | 150 / 136 | 291 / 296 | 850 / 790 | 2.413 / 2.190 |
| **Archivo guardado** (comprimido) | 0,08 MB | 0,33 MB | 0,90 MB | **2,42 MB** |
| JSON sin comprimir | 0,6 MB | 2,5 MB | 6,9 MB | 19,1 MB |
| **RAM: RSS tras generar** PC (inicio ≈ 332) | 342 | 373 | 445 | **648** |
| RSS tras una temporada PC | 362 | 412 | 511 | **779** |
| RAM estática del motor tras generar PC | 236 | 259 | 311 | 456 |
| **Pico de RSS al CARGAR** PC (conviven el mundo viejo y el nuevo + el JSON) | 392 | 547 | 888 | **1.833** |
| **Pico de RAM MODESTO** (`VmHWM`) | 698 | 793 | 1.017 | **1.962** |

## Lectura
1. **Casi todo es lineal en el número de clubes**: generar ≈ 1,5 ms/club; una semana ≈ 1,0-1,2 ms/club; el resto de la temporada ≈ 25 ms/club (≈ 34 s el mundo entero); el archivo ≈ 1,8 KB/club; la RAM ≈ +0,23 MB/club (+316 MB sobre los 332 MB de base del motor). Quitar países ahorra en proporción.
2. **El mundo entero cuesta ~25 veces un país y ~3 veces «15 países»**; la RAM no se multiplica tanto porque 332 MB son del motor y los autoloads.
3. **El pico de RAM está en CARGAR**, no en jugar: ~1,8-2,0 GB con el mundo entero porque la partida vieja, la nueva y el JSON de 19 MB están vivos a la vez. En un equipo de 4 GB cabe, pero en un móvil de 3-4 GB (Android mata la app por encima de ~1,5-2 GB) es el riesgo real. Con 15 países el pico baja a ~0,9-1,0 GB; con 5, a ~0,55-0,8 GB.
4. **Tiempos que nota el jugador**: avanzar una semana ≈ 1,4 s con todo el mundo (0,23 s con 5 países); guardar/cargar ≈ 2,1-2,4 s con todo (0,3 s con 5). El autoguardado ya va en segundo plano (`GuardadoSegundoPlano`), la carga no.
5. **Equipo modesto** (2 núcleos): casi igual que el PC en estas cifras: es CPU de un solo hilo (la simulación no se paraleliza).

## Estimación para el móvil (NO medido; hace falta el teléfono)
- La extensión C++ NO existe en Android (falta el `.so`, ver `PASO_CPP_PLAN.md` §2.2): la simulación de partidos va con el gemelo GDScript, ~2× más lenta en la parte de partidos (semana del mundo 786 → 395 ms medido con C++).
- Un móvil de gama media rinde por hilo entre 0,4× y 0,7× de un núcleo de servidor. Con ambos factores, una **semana con el mundo entero sería ≈ 4-7 s**, una temporada entera ≈ 2-3 min, **generar ≈ 6-10 s**, guardar/cargar ≈ 5-8 s y el pico de RAM al cargar ≈ 2 GB (riesgo de cierre). Con 5 países: semana ≈ 0,8-1,2 s, generar ≈ 1 s, pico ≈ 0,6-0,8 GB (cómodo).

## Propuesta para «Ligas activas»
- Valor por defecto en móvil: **~5 países** (el club del jugador y su entorno); en PC, 15; «mundo entero» como opción explícita con aviso de coste («más lento al avanzar y al guardar; usa ~2 GB al cargar»).
- Los países no activos NO se simulan (la tabla de arriba es el ahorro: −65 % de tiempo y −50 % de RAM con 15 de 71 países).
- Antes de ofrecer «mundo entero» en móvil: bajar el pico de RAM al cargar (liberar el mundo viejo ANTES de parsear el nuevo, y parsear sin duplicar el JSON), que es una mejora independiente y barata.

## Pico de RAM al CARGAR: causa y arreglo (10-11, sesión 5; orden del líder)
Herramientas: `pruebas/zz_carga_ram.tscn` (pico de `Partida.cargar` con el mundo anterior vivo o soltado, y comprobación de que el mundo cargado es el mismo que el guardado), `zz_fuga_mundo.tscn` (¿se libera un mundo al soltarlo?).
**Dónde se iba la RAM** (mundo entero, memoria estática): JSON descomprimido +17 MB, como `String` +65 MB, parseado a `Dictionary` +233 MB, mundo construido +184 MB; y **el mundo de antes no se liberaba nunca**, por dos causas:
1. `LeyesPais.clubes_mundo` (variable estática) guardaba los clubes, y con ellos todos los jugadores, del último mundo generado o cargado; `Partida.cargar` la sobrescribía al FINAL, así que el mundo viejo seguía vivo durante toda la carga.
2. En `tomar_el_mando` dos lambdas (`medico.gasto.connect(func …)` / `vestuario.gasto.connect(func …)`) capturaban el propio `Mundo`: ciclo Mundo → médico → señal → lambda → Mundo. Una lambda de GDScript guarda su `self` vivo, así que un `Mundo` con partida tomada NO se liberaba aunque nadie lo referenciara: cada partida cargada o nueva dejaba ~225 MB (mundo entero) sin liberar para siempre (cargar 5 veces seguidas acumulaba >1 GB).
**Arreglo:** (a) `Mundo._gasto_al_libro` (método) en vez de las lambdas: el mundo soltado SÍ se libera; (b) `Partida.cargar(nombre, soltar_antes)`: tras leer el guardado y comprobar que es bueno (huella, versión, claves: `_instantanea_buena`) y ANTES de construir el mundo nuevo, vacía `LeyesPais.clubes_mundo` y llama a `soltar_antes` (la interfaz pasa `p.mundo = null`); si el guardado no sirve no se llama y el mundo actual queda intacto; (c) los bytes del JSON se sueltan en cuanto existe el texto.
**Medido** (mundo generado + 3 semanas + guardado; carga de la misma partida):
| | Sin soltar (antes) | Con soltar (ahora) |
|---|---|---|
| MUNDO ENTERO, pico estática | 954 MB | **831 MB** |
| MUNDO ENTERO, VmHWM (pico del proceso) | 1.364 MB | **1.168 MB** |
| MUNDO ENTERO, estática TRAS cargar | 708 MB | **483 MB** (−225 MB: el viejo ya no queda) |
| 5 países, pico estática / tras cargar | 336 / 302 MB | 319 / 270 MB |
Mismo mundo: el guardado del mundo cargado es idéntico al original (sin la hora del guardado) en las dos configuraciones. Banco FIN. 0 fallos. **Queda** un pico de ~830 MB estática (~1,17 GB de proceso) con el mundo entero: diccionario del JSON + texto + mundo viejo, hasta que se suelta el viejo; bajarlo más exigiría soltar el mundo actual ANTES de parsear (si el guardado no se pudiera leer, el jugador perdería su partida actual), por eso no se hace.
