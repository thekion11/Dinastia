# Animaciones gratuitas para el partido (sesión 10, 11-11-2026)

Encargo del dueño: más animaciones gratuitas, con licencia que permita **usarlas y distribuirlas dentro de un juego comercial**
(CC0, CC-BY con atribución, MIT o Apache). Descartado: no comercial (CC-BY-NC) y lo que prohíba redistribuir el archivo.

Hoy en el repo (antes de esta sesión): 296 de League-Soccer (`anims_league/league.res`, Apache 2.0), 45 de la Universal Animation
Library 1 Standard (`anims/UAL1_Standard.glb`, CC0), 17 elegidas de la UAL 2 (`anims_ual2/`, CC0), 21 de mocap de fútbol de Gumroad
(`anims_futbol/`, 🟡 sin licencia escrita en el zip) y clips de Mesh2Motion (CC0).

## Resumen del veredicto

| Fuente | Licencia | Cantidad | ¿Sirve? | ¿Se baja desde el contenedor? |
|---|---|---|---|---|
| 100STYLE (Zenodo 8127870) | CC BY 4.0 | 100 estilos × ~10 movimientos, BVH a 60 fps (**los 100 estilos ya están convertidos**) | **SÍ** (locomoción: marcha, carrera, lado, atrás, giros, reposo), con atribución | sí (1,4 GB; se extrae solo lo usado) |
| Quaternius UAL 2 Standard | CC0 | 43 (17 ya en el repo) | parcial (barrida/tackle, derribo, levantarse, lanzamiento con las manos) | sí (itch.io, gratis) |
| Quaternius UAL 1 Standard | CC0 | 43 (ya en el repo) | ya incluida | ya |
| Quaternius UAL 1 / 2 «Pro» y «Source» | CC0 pero **de pago** ($9,99 / $14,99) | 120+ / 130+ | no se compran sin OK del dueño | — |
| Base CMU (mocap.cs.cmu.edu) | «libre para uso comercial; se pide citar la fuente» | 2.500+ BVH (sujetos 10, 11… traen fútbol) | sí en teoría | **no**: el host de CMU no responde desde el contenedor y los espejos de GitHub no se pueden añadir a la sesión (denegado) |
| Mixamo | uso en juegos permitido, **pero no se puede redistribuir el archivo suelto** y exige cuenta | ~2.500 | **descartado** (redistribución en el repo + login) | no |
| Bandai Namco Research Motion Dataset | CC BY-NC-ND | 36.000 | **descartado** (no comercial) | — |
| AMASS / LAFAN1 | no comercial | — | **descartado** | — |
| OpenGameArt (CC0 genéricos) | CC0 | pocos, sin fútbol | sin valor añadido | sí |
| GameplayFootball / Google Research Football | GPL-3 / Apache 2.0 | GRF no trae animaciones propias; GameplayFootball es el origen de las de League-Soccer | ya cubierto por League-Soccer | ya |


## Fuentes, con enlace y licencia citada

1. **100STYLE** — Ian Mason, Sebastian Starke, Taku Komura. https://zenodo.org/records/8127870 · página del autor https://ianxmason.github.io/100style
   Licencia (campo `license` de la API de Zenodo): `cc-by-4.0`. La página del autor pide citar el artículo a los usuarios académicos y
   «dar crédito de forma adecuada» a los creativos y comerciales. **Cantidad**: 100 estilos × 8-10 movimientos, >4 millones de cuadros en BVH
   sin editar a 60 fps (Xsens, 28 huesos, T-pose, Y arriba, +Z adelante: los MISMOS ejes que nuestro esqueleto). **Tipos**: marcha/carrera
   adelante, atrás y lateral, reposo y transiciones. NO trae pases, tiros, cabezazos, portero ni celebraciones. Descarga desde el contenedor:
   sí (1,47 GB, `100STYLE.zip`; se extrae solo lo usado, nada del zip entra al repo).
2. **Quaternius, Universal Animation Library 1 y 2** — https://quaternius.com/packs/universalanimationlibrary.html y
   https://quaternius.com/packs/universalanimationlibrary2.html. Licencia citada: «Free to use in personal, educational and commercial
   projects. (CC0 License)». La versión gratuita («Standard») trae 43 + 43 clips (descargada hoy de itch.io; ya estaban en el repo las
   dos selecciones). Sin fútbol; lo útil ya está (`Slide_*` como entrada deslizante, `OverhandThrow` como saque de banda, `Hit_Knockback`, `LayToIdle`).
   Las versiones «Pro» (120+/130+) y «Source» son de pago ($9,99 / $14,99): no se compran sin OK del dueño.
3. **Base de captura de movimiento de la CMU** — http://mocap.cs.cmu.edu (la conversión a BVH de Bruce Hahne, cgspeed). Texto citado por las
   fuentes secundarias: «free for use in research and commercial projects», se pide citar «The data used in this project was obtained from
   mocap.cs.cmu.edu». Trae sujetos con patadas y fútbol. **No se pudo traer**: el host de CMU no responde desde el contenedor (sin ruta en la
   red) y las copias están en GitHub, que la sesión no pudo añadir (`add_repo` denegado). Queda como la mejor candidata para pases, tiros y
   cabezazos si el dueño abre la ruta o sube él los BVH; el conversor `herramientas/estilo100_*` sirve casi igual (otro esqueleto y 120 fps).
4. **Mixamo (Adobe)** — términos de uso: se pueden usar en juegos comerciales, pero NO redistribuir los archivos sueltos/en paquetes, y exige
   cuenta para descargar. **Descartado** (el repo es público y distribuiría los archivos).
5. **Bandai Namco Research Motion Dataset** — CC BY-NC-ND (no comercial). **Descartado**. Igual AMASS y LAFAN1 (no comercial).
6. **«Free mocap pack 05: Soccer», Anderson Rohr** (el enlace de 80.lv que mandó el dueño; Gumroad) — 21 clips, ~3 minutos: regates,
   malabares, saque de banda, patadas, penales, celebraciones, paradas de portero, defensa y tarjetas; esqueletos Rokoko, iClone y UE5 Manny.
   **Ya está integrado** (`anims_futbol/`). El artículo lo presenta para «juegos, cinemáticas y VFX» pero NO cita texto de licencia; sigue 🟡
   hasta guardar la captura de la página de Gumroad (pendiente del dueño, ya anotado en `LICENCIAS.md`).
7. **GameplayFootball / League-Soccer / Google Research Football** — ya cubiertas: las 296 de League-Soccer (Apache 2.0) son las de
   GameplayFootball; Google Research Football no trae animaciones propias.
8. **OpenGameArt / Godot Asset Library**: sin animaciones de fútbol con licencia clara (lo que hay son los mismos Quaternius CC0).
9. Datasets de investigación de fútbol (Soccer-X, GINGA): sin publicación ni licencia comprobables.

**Conclusión honesta**: «más de mil» animaciones de fútbol con licencia libre y descargables NO existen hoy; lo que se consiguió es locomoción
(la parte más repetida del partido) y el catálogo con contacto para lo que ya había. Para pases, tiros, cabezazos, entradas y portero la única
vía libre real es la CMU (pendiente de ruta de red) o grabar/animar propias.

## Lo que entra en el repo (rama `sesion10-animaciones`)

| Qué | Dónde | Cantidad |
|---|---|---|
| Ciclos de locomoción retargeteados a nuestro esqueleto (AnimationLibrary, bucle, 30 fps, con espejo «…_espejo») | `dinastia-godot/terceros/estilo100/biblioteca/100style.res` (16 estilos «de fútbol») y `100style_g2…g5.res` (los otros 84), 34 MB en total, fuera de LFS y **fuera de los builds** (`terceros/` no se importa ni se exporta) | **1.261 ciclos + 1.261 espejos = 2.522 animaciones** (100 estilos) |
| Catálogos con etiquetas (uno por biblioteca) | `dinastia-godot/terceros/estilo100/catalogos/animaciones_catalogo_100style*.json` | 2.522 fichas (2.136 con revisión `ok`) |
| Formato `anims_extra` de la sesión 9 | `dinastia-godot/datos/anims_extra/estilo100.json` + biblioteca de USO `assets/characters/quaternius/anims_100style/100style_uso.res` (1,5 MB, viaja en los builds) | 143 ciclos + 143 espejos |
| Catálogo de los 21 clips de Rohr con cuadro de golpeo | `dinastia-godot/datos/animaciones_catalogo_rohr.json` | 21 fichas |
| Herramientas (reproducibles) | `herramientas/estilo100_ciclos.py` (BVH → ciclos), `estilo100_a_res.gd` (retarget), `estilo100_revisar.gd` (patinaje y brazos), `catalogo_rohr.gd` | |
| Escena de capturas pose a pose | `pruebas/captura_anims_100style.tscn` | |
| Capturas JPG | `docs/04_auditorias/capturas_animaciones_2026-11-11/` | 14 clips × (cerca + cámara real) |

Los estilos 17-100 se convirtieron en 4 grupos (`ESTILO100_NOMBRE=100style_g2…g5`, variable que usan `estilo100_a_res.gd` y `estilo100_revisar.gd`); 17 ciclos con mal cierre se descartaron. Estilos sueltos como `Kick`, `Lunge`, `Skip`, `Sweep`, `Swat`, `TwoFootJump`, `LeftHop` están ahí (algunos útiles para fintas); otros son humorísticos (`Chicken`, `Dinosaur`…) y se filtran por nombre.

Regenerar: bajar `100STYLE.zip` de Zenodo, descomprimirlo fuera del repo y
`python3 -I herramientas/estilo100_ciclos.py <100STYLE> ciclos.json` → `ESTILO100_JSON=ciclos.json godot --headless --path . --script res://herramientas/estilo100_a_res.gd`
→ `godot --headless --path . --script res://herramientas/estilo100_revisar.gd` (este último reescribe el catálogo con la velocidad medida y el aviso).

## Etiquetas del catálogo de 100STYLE (para que el motor elija por búsqueda)

`nombre` (`e100_<Estilo>_<FW|FR|BW|BR|SW|SR|ID>_<n>`, en la biblioteca `100style.res`), `estilo`, `tipo` (`marcha`, `carrera`, `marcha_atras`,
`carrera_atras`, `marcha_lateral`, `carrera_lateral`, `reposo`), `cuadros`, `fps` (30), `duracion_s`, `bucle` (siempre sí),
`velocidad_ms` (la que NO patina: velocidad de avance que cancela el pie en apoyo; reproducir el clip a esa velocidad), `velocidad_cadera_ms`
(la medida en el origen), `angulo_mov_grados` (marcha respecto al cuerpo: 0 adelante, ±180 atrás, +90 a la izquierda, −90 a la derecha;
el espejo cambia el signo), `apoyos_pie_derecho` / `apoyos_pie_izquierdo` (cuadros con el pie en el suelo), `pie_en_aire_al_inicio` (D/I),
`cuadro_toque_balon` (**null**: locomoción sin balón), `mueve_con_el_balon` (false), `revision` (`ok` o `aviso: …`),
`patinaje_ms`, `min_dist_mano_torso_m`, `min_dist_codo_torso_m`.

Límites que hay que saber: (1) el actor se movía dentro de un estudio: la carrera «rápida» es un trote de 1,3-1,9 m/s; para 5-8 m/s hay
que reproducirla acelerada (el catálogo da la velocidad base) o usar las de League-Soccer; (2) **386 de 2.522 fichas con aviso** de patinaje o de brazo en el cuerpo (sobre todo estilos raros y las carreras hacia atrás): filtrar `revision == "ok"`; (3) la medida de patinaje es una
heurística (apoyo = pie a <3 cm de su mínimo), no un solucionador de pies.

Catálogo de Rohr (`animaciones_catalogo_rohr.json`): por clip `tipo`, `duracion_s`, y para regates, malabares, pase, tiro y penal:
`cuadro_toque_balon` / `tiempo_toque_s` / `pie_que_golpea` (el pico de velocidad del pie, medido sobre el esqueleto de origen UE5 a 30 fps, a partir
del cuadro 4), `velocidad_pie_ms`, `altura_pie_m` y `golpeos` (todos los picos > 45 % del máximo). **Es una heurística**: el pico de velocidad
del pie coincide con el golpeo, pero sin balón en la escena puede dar el pie de apoyo o un giro; validar a ojo antes de fiarse (p. ej. Power_Kick:
golpeo en el cuadro 78 con el izquierdo; Side_Foot_Kick y los penales traen carrera previa y varios picos). Los clips son largos (3-23 s).

## Para la sesión 9 (`LeagueCatalogo`, `datos/anims_extra/`)

`datos/anims_extra/estilo100.json` (generado por `herramientas/estilo100_a_anims_extra.py`): 143 ciclos + 143 espejos con las etiquetas de su
LEEME. Un ciclo entra y sale a la misma velocidad (`ang` 0); `cuerpo` = −ángulo de marcha (atrás ±π, lateral ∓π/2). Solo pasan los de
`revision: ok` y los que llegan a la clase 3,5 m/s (≥ 1,8 m/s reales) más los reposos. Las marchas lentas
(< 1,8 m/s) serían «parado» en la clase del motor, así que NO entran (siguen en `animaciones_catalogo_100style.json`). `v_entra`/`v_sale` llevan la
velocidad real. Los clips de Rohr no son locomoción: no encajan en ese formato (su catálogo es `animaciones_catalogo_rohr.json`).

## UAL 1 + UAL 2 de Quaternius: lo útil para el partido (bloque 4)

Licencia verificada: `License.txt` de la descarga de itch.io («CC0 1.0 Universal, Public Domain Dedication») y la página de Quaternius («Free to use in
personal, educational and commercial projects. (CC0 License)»). La versión gratuita son 43 + 43 clips (las «Pro» y «Source» son de pago).
`herramientas/ual_a_res.gd` saca 33 clips a `terceros/ual/ual_extra.res` (1,2 MB, fuera de LFS y de los builds) y su catálogo
`terceros/ual/animaciones_catalogo_ual.json`: marcha (Walk, Walk_Formal, Walk_Carry, Crouch_Fwd), **trote Jog_Fwd (6,4 m/s medidos)** y **SPRINT (7,35 m/s,
ciclo de 0,67 s)**, reposos y reacciones, **saltos** (Jump y NinjaJump: despegue, aire, aterrizaje), **caídas y golpes** (Roll, Hit_Chest, Hit_Head,
Hit_Knockback, Death01, LayToIdle), **entrada deslizante** (Slide_Start/Loop/Exit), **celebración** (Dance_Loop), **saque de banda** (OverhandThrow),
disputa (Punch_Jab, Push_Loop) y ClimbUp. La velocidad de los ciclos es la medida sobre el esqueleto (pie en apoyo). En `anims_extra/quaternius_ual.json` entran
SOLO el trote y el sprint (los únicos que son locomoción rápida; sin espejo); los demás son acciones, no transiciones de marcha, y meterlos
con entra = sale = 0 el motor podría elegirlos como «parado». Revisión visual: sprint, trote, deslizamiento, salto, voltereta, baile, lanzamiento y caída
(`ual*_*.jpg` en la carpeta de capturas): sin brazos atravesando el cuerpo ni pies flotando. Nota: el «1,47 GB» no era la UAL (pesa 18 MB) sino el zip de 100STYLE.

## Peso en los builds (orden del líder, 11-11)

Solo viaja lo que el motor referencia. Las bibliotecas completas (34 MB de 100STYLE + 1,2 MB de UAL) viven en `terceros/` (con `.gdignore`: ni se
importan ni se exportan; no hace falta tocar los `exclude_filter` de los presets). Los JSON de `anims_extra/` apuntan a dos bibliotecas de USO que
`herramientas/anims_uso_a_res.gd` arma copiando solo los clips referenciados y comprimiendo sus pistas (`Animation.compress()`): `100style_uso.res`
(143 ciclos + 143 espejos, **1,5 MB**; sin comprimir eran 5,6) y `ual_uso.res` (trote y sprint, 10 KB). Con la compresión las poses no cambian
(capturas comparadas). **Medido con `--export-pack "Windows"`: 386,4 MB con las 5 bibliotecas dentro → 348,6 MB ahora (−37,8 MB)**; el pack contiene
`100style_uso.res` y `ual_uso.res` y no contiene nada de `terceros/`. Para sumar un clip al motor: añadirlo a `anims_extra` con
`estilo100_a_anims_extra.py` / `ual_a_anims_extra.py` y volver a correr `anims_uso_a_res.gd`.

## Revisión visual (pose a pose, 14 clips)

`docs/04_auditorias/capturas_animaciones_2026-11-11/<clip>_cerca.jpg` (8 fases del ciclo, Forward+) y `<clip>_camara_real.jpg` (cámara de la
transmisión: FOV 33°, 17 m de altura, 46 m; recorte). Revisados a ojo: marcha, carrera, atrás, lateral, reposo, HighKnees, Angry, Heavyset,
BigSteps, Crouched, March, Elated. **Sin brazos atravesando el torso** (distancia mínima mano-columna 0,21-0,36 m; codo 0,23-0,32 m; el
umbral de aviso es 0,12 / 0,11 m) y **sin pies cruzados ni flotando** en las capturas. Defecto encontrado y corregido durante la revisión:
el BVH conserva el rumbo absoluto del actor (los ciclos salían girados 46°, −136°…); `normalizar_rumbo` lo deja mirando a +Z.
Pendiente: verlas dentro del partido real con el motor de la sesión 9 (sus velocidades de marcha reales pueden pedir otro `velocidad_ms`).
