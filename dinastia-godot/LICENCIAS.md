# LICENCIAS Y DATOS REALES — qué puede viajar en una versión publicada

Auditoría del 25-9-2026, hecha a raíz del análisis externo que marcó lo legal como el bloqueo
principal para vender DINASTÍA. Este archivo es la referencia antes de subir el juego a cualquier
tienda (Steam, itch.io, Google Play...). Se excluye solo de las exportaciones (`*.md`).

## Resumen

| Semáforo | Qué significa |
|---|---|
| 🟢 | Licencia verificada que permite uso comercial. Viaja en todas las versiones. |
| 🟡 | Probablemente permitido, pero **no está verificado** en la fuente original. Confirmar o reemplazar antes de vender. |
| 🔴 | No se puede publicar. Ya está **excluido** de las versiones publicables (`export_presets.cfg`). |

Versiones (ver `herramientas/empaquetar.ps1`):

- **completo** (`preset "Windows"`): PRIVADA. Lleva el pack real, las caras reales, las camisetas
  reales y el modelo viejo. Es para jugar tú. **No se publica.**
- **ligero / web / apk / zip** (`presets "WindowsLigero"`, `"Web"`, `"Android"`): PUBLICABLES.
  Base ficticia, sin nada 🔴.

## 1. Datos (nombres de clubes, ligas, jugadores)

| Qué | Dónde | Estado |
|---|---|---|
| Base ficticia: 384 clubes, 24 ligas, 8 torneos continentales, copas y árbitros inventados | `datos/tablas.json` | 🟢 propio |
| Pack real: clubes, ligas, copas, 2.853 fichas de 2.125 futbolistas reales, equipaciones reales, árbitros reales | `datos/pack_real.json` | 🔴 excluido |
| Huellas de nombres reales (md5, 12 hex) para que el generador no invente "Mohamed Salah" | `datos/tablas.json` → `NOMBRES_VETADOS` | 🟢 no contiene ningún nombre legible |
| Listado de futbolistas reales (entrada de la búsqueda de fotos) | `datos/reales_lista.json` | 🔴 excluido |
| Informe de fotos reales (Wikidata/Commons) | `datos/caras_reales_reporte.json` | 🔴 excluido |
| Índice de retratos y créditos de las fotos | `datos/caras_reales_recortes.json`, `datos/creditos_fotos.txt` | 🔴 excluido de las versiones públicas (van con las fotos) |
| Copia vieja de las tablas con todo lo real | `datos/tablas.json.bak` | 🔴 excluido |

**Cómo funciona.** `Datos` carga la base ficticia y, si encuentra un `pack_real.json` (en
`user://`, junto al ejecutable, o en `res://datos/` solo en desarrollo), deja elegir "Base de datos:
Real (pack)" en el menú. Es el modelo de los managers sin licencia (PES, Football Manager): el juego
sale limpio y cada jugador instala por su cuenta la base que quiera. El formato del pack está
documentado en `nucleo/datos.gd`, y `herramientas/base_ficticia.py` regenera los dos archivos.

**Por qué los nombres inventados son como son.** Evocan la ciudad, el barrio, el río o el color del
club original (Boca Juniors → "Riachuelo AC", Real Madrid → "Castellana CF"), pero no usan el
nombre registrado ni el apodo comercial. Se evitaron también nombres de clubes reales pequeños
("Belén FC", "Brera Calcio"...) que coincidían con la primera propuesta.

## 2. Imágenes de personas y equipaciones

Peinados, barba y cejas de los jugadores 3D: *Universal Base Characters* de Quaternius, CC0
(`assets/characters/quaternius/pelo/License.txt`). 🟢

| Qué | Dónde | Estado |
|---|---|---|
| 1.219 fotos de caras de futbolistas reales, bajadas de Wikimedia Commons solo si su licencia es libre (revisado 25-9-2026 sobre el informe: 636 CC BY-SA 4.0, 151 CC BY-SA 3.0, 123 CC0, 71 CC BY-SA 2.0, 70 CC BY 3.0, 66 CC BY 4.0, 56 CC BY 2.0, 33 dominio público, 13 otras CC). Originales en `recursos/caras_reales/`, retratos recortados por la cara en `recursos/caras_reales_256/` | ver las dos filas de abajo | 🔴 excluidas de las versiones públicas; la versión **completo** lleva solo los retratos de 256 px |
| **Derechos de autor de la foto**: libres con condiciones. CC BY y CC BY-SA exigen nombrar autor y licencia y avisar de que se modificó (se recortó): la ficha del jugador lo pone bajo el retrato (`Cara.credito_foto()`) y la lista completa está en `datos/creditos_fotos.txt`. BY-SA pide además que los retratos recortados se compartan con la misma licencia | `datos/caras_reales_recortes.json`, `datos/creditos_fotos.txt` | 🟢 cumplido en el juego (crédito visible) |
| **Derechos de imagen de la persona**: aparte de la licencia de la foto. Commons avisa de que una foto libre no autoriza a usar la cara de alguien en un producto comercial; los juegos con licencia la consiguen de FIFPro o de cada liga | — | 🔴 por eso siguen fuera de lo que se publica. Con la base ficticia `Cara.foto_real()` no enseña ninguna foto |
| 1.102 fotos de camisetas reales (escudo y patrocinadores de marca) | `../recursos/equipaciones/` (fuera del proyecto) | 🔴 solo se copian junto al `.exe` en la versión **completo**. Con la base ficticia `EQUIP_REAL` está vacía y nunca se usan |
| Modelo `futbolista_cr7.glb` y sus texturas (camiseta real del Al-Nassr, sin licencia conocida) | — | ✅ **borrado del proyecto** (25-9-2026), junto con su código (`Futbolista`, `AnimMixamo`, `Vestidor`). Los partidos y el presentador del sorteo usan el modelo Quaternius |

## 3. Modelos 3D y animaciones

| Qué | Dónde | Origen | Estado |
|---|---|---|---|
| Muñeco y animaciones (YA SIN USO, fuera de los builds; en LFS) | `assets/characters/Model`, `Animations` | Kenney "Animated Characters Protagonists" | 🟢 CC0 (`assets/characters/License.txt`) |
| Cuerpo de jugador | `assets/characters/quaternius/*.gltf` | Quaternius "Universal Base Characters" | 🟢 CC0 |
| Animaciones base | `assets/characters/quaternius/anims/UAL1_Standard.glb` | Quaternius "Universal Animation Library" | 🟢 CC0 (`_extraido_universal_animation_library/.../License.txt`) |
| Ropa del jugador | `assets/characters/quaternius/ropa/` | Quaternius "Modular Character Outfits - Fantasy" | 🟢 CC0 |
| Alfombra y cortinas dobles (interiores) | `assets/quaternius_muebles/` | Quaternius (CC0, regalo del usuario el 15-10-2026) | 🟢 CC0 |
| Edificios, coches y comercio de la ciudad | `assets/ciudad/kenney_*` | Kenney City Kit / Car Kit | 🟢 CC0 |
| Furniture Kit 2.0 (140 muebles; guardado, aún sin usar) | `assets/kenney/muebles/` | Kenney | 🟢 CC0 (`assets/kenney/muebles/License.txt`) |
| Modular Buildings 2.1 (108 piezas; guardado, aún sin usar) | `assets/kenney/edificios_modulares/` | Kenney | 🟢 CC0 (`assets/kenney/edificios_modulares/License.txt`) |
| Building Kit 1.0 (79 piezas; guardado, aún sin usar) | `assets/kenney/kit_edificios/` | Kenney | 🟢 CC0 (`assets/kenney/kit_edificios/License.txt`) |
| City Kit Suburban 2.0 (40 piezas; guardado, aún sin usar) | `assets/kenney/suburbano/` | Kenney | 🟢 CC0 (`assets/kenney/suburbano/License.txt`) |
| City Kit Industrial 2.0 (37 piezas; guardado, aún sin usar) | `assets/kenney/industrial/` | Kenney | 🟢 CC0 (`assets/kenney/industrial/License.txt`) |
| Train Kit 1.1 (103 piezas; guardado, aún sin usar) | `assets/kenney/tren/` | Kenney | 🟢 CC0 (`assets/kenney/tren/License.txt`) |
| Coaster Kit 1.0 (183 piezas; guardado, aún sin usar) | `assets/kenney/montana_rusa/` | Kenney | 🟢 CC0 (`assets/kenney/montana_rusa/License.txt`) |
| Mini Market 1.0 (20 piezas; guardado, aún sin usar) | `assets/kenney/mini_mercado/` | Kenney | 🟢 CC0 (`assets/kenney/mini_mercado/License.txt`) |
| Food Kit 2.0 (200 piezas; guardado, aún sin usar) | `assets/kenney/comida/` | Kenney | 🟢 CC0 (`assets/kenney/comida/License.txt`) |
| Mini Arcade 1.2 (20 piezas; guardado, aún sin usar) | `assets/kenney/mini_arcade/` | Kenney | 🟢 CC0 (`assets/kenney/mini_arcade/License.txt`) |
| City Builder Bits (bloques de la Casa Grande) | `assets/ciudad/kaykit/` | Kay Lousberg (KayKit) | 🟢 CC0 (`assets/ciudad/kaykit/LICENSE.txt`) |
| Clips de medio cuerpo del público y de los personajes | `assets/characters/quaternius/anims_m2m/` | Mesh2Motion (Scott Petrovic) | 🟢 CC0 (`anims_m2m/LICENCIA.md`) |
| City Kit Roads (95 piezas; guardado, aún sin usar) | `assets/ciudad/kenney_roads/` | Kenney | 🟢 CC0 (`assets/ciudad/kenney_roads/LICENCIA_Kenney_CC0.txt`) |
| 21 animaciones de fútbol (mocap) | `assets/characters/quaternius/anims_futbol/` | "Free mocap pack 05: Soccer", Anderson Rohr (Gumroad) | 🟡 `LEEME.md` dice "uso comercial libre", pero el zip no trae licencia. **Guardar una captura de la página de Gumroad con los términos.** |
| Coches `coche1.fbx`, `coche2.fbx` | `assets/ciudad/` | Probablemente `recursos/modelos3d/gt-racing-2-montreal.zip` (Sketchfab). El nombre apunta a un modelo sacado de un juego comercial | 🔴 ya no se usan (el aparcamiento es solo Kenney) y están excluidos |
| `estadio.obj`, `farola.obj`, `vagabond.obj` (el velero) | `assets/ciudad/` | sin anotar | 🟡 confirmar |
| `complejo_residencial.glb` | `assets/ciudad/` | `recursos/modelos3d/3.zip` (Sketchfab, sin licencia en el zip). Varias texturas llevan nombre de foto de redes sociales | 🟡 confirmar en Sketchfab o reemplazar |
| `oficina_dt.glb` | `assets/ciudad/` | `interior-15-minimalist-panoramic-viem.zip` (Sketchfab) | 🟡 confirmar. Hoy no se usa (ver `city_builder.gd`) |
| `arco_entrada.glb` | `assets/ciudad/` | `recursos/modelos3d/entrada-jugadores/` (Sketchfab) | 🟡 confirmar |
| `persona_realista.glb` (escaneo de una persona: presentador del sorteo y mentores) | `assets/personas/` | `recursos/modelos3d/navy-jacket-portrait.zip` ("Navy Jacket Portrait", formato de descarga de Sketchfab, sin licencia dentro del zip). Es el modelo que el usuario dejó para el presentador | 🟡 confirmar la licencia en Sketchfab. Además es una persona real escaneada: comprobar que la licencia permite su uso en un juego comercial |
| `asientos_lod.glb` | `assets/ciudad/` | `normal_stadium_seats_v1...zip` | 🟡 confirmar |
| `podio_prensa.glb` | `assets/props/generado_ia/` | Generado con Meshy | 🟡 en plan de pago es tuyo; en plan gratis Meshy lo publica bajo CC BY 4.0 y **hay que acreditar**. Confirmar con qué plan se generó |
| Malla de cara deformable (468 vértices, 898 triángulos) y detector de puntos de la cara, usados para sacar la cara 3D de cada foto real | `datos/cara_malla_topologia.json` (la topología); el detector solo lo usa `herramientas/caras_reales_malla.py` | MediaPipe (Google): `canonical_face_model.obj` y `face_landmarker.task` | 🟢 Apache 2.0: uso comercial permitido; conservar el aviso «Copyright The MediaPipe Authors, Apache License 2.0» |
| Caras 3D de jugadores reales, sus puntos y rasgos (sacados de las fotos) | `datos/caras_reales_mallas.json`, `caras_reales_puntos.json`, `caras_reales_rasgos.json` | Generados aquí desde las fotos de Commons | 🔴 excluido (es la imagen de personas reales) |

## 4. Escudos, texturas, sonido y tipografía

| Qué | Dónde | Estado |
|---|---|---|
| Escudos de club | generados por código (`ui/escudo.gd`) | 🟢 propio |
| 40 insignias especiales desbloqueables | `assets/escudos_especiales/` | 🟡 generadas en Canva a partir de referencias de estilo (no calcadas, ver `LEEME.md` 22-9). Los términos de Canva no permiten usar su contenido como **marca** propia; como insignias dentro del juego deberían ser válidas, pero conviene confirmarlo. Si se quitan de la exportación, `Escudo.textura_especial()` cae solo al escudo procedural |
| Referencias de Pinterest | `../Escudos especiales/` (fuera del proyecto) | 🔴 nunca entraron al juego. No usar |
| Texturas de la Tierra (globo) | `recursos/tierra/` | 🟡 muy probablemente NASA Blue Marble / Black Marble (dominio público). Anotar la fuente |
| Fronteras del globo (`fronteras4k.png`) | `recursos/tierra/` | ✅ Natural Earth, `ne_50m_admin_0_boundary_lines_land` (dominio público, naturalearthdata.com), rasterizadas por nosotros |
| 205 efectos de sonido y 6 piezas de música | sintetizados por código (`nucleo/sonido.gd`, `nucleo/musica.gd`) | 🟢 propio |
| Tipografía: Inter, Barlow Condensed, Bebas Neue, Cinzel, Gelasio, Noto Sans Symbols/Symbols 2, Noto Emoji, Noto Sans JP, Noto Sans Math, Noto Sans Mono | `assets/fuentes/` | 🟢 SIL Open Font License 1.1 (`assets/fuentes/OFL_*.txt`, viajan en el build) |
| Sonidos de interfaz (clics, avisos) | `audio/ui/` | 🟢 CC0: Kenney y VCSL (`audio/ui/LICENCIA_*.txt`); subida autorizada por el dueño el 26-10 |
| Banderas | `assets/banderas/` | 🟢 flag-icons, MIT (`LICENSE_flag-icons_MIT.txt`: hay que conservar el aviso, viaja en el build) |
| Complementos Antialiased Line2D y Debug Menu | `addons/` | 🟢 MIT (`addons/LICENCIAS_TERCEROS.txt`) |
| Caras de jugadores y DT | dibujadas por código (`ui/cara.gd`, `ui/cara_dt.gd`) | 🟢 propio |
| 16 iconos dibujados del menú (riel y cabeceras, prototipo del 10-11) | trazos SVG en el código (`ui/componentes/iconos_ui.gd`) | 🟢 propio: dibujados para Dinastía, sin copiar ningún juego de iconos de terceros |

## 5. Otros nombres propios

| Qué | Estado |
|---|---|
| Marcas de patrocinio (`MARCAS`), bancos, medios, periodistas, agentes | 🟢 inventadas desde el HTML |
| Proveedores de equipación | 🟢 desde esta tanda: "Ad1star", "P0mba" y "N1mbra" quedaban a una letra de Adidas, Puma y Nike. Ahora son "Astra Sport", "Salto" y "Nimbo" |
| "Fecha FIFA", "Compensación FIFA" en textos | 🟢 cambiados a "fecha internacional" / "federación internacional" |
| Rótulos del sorteo ("CHAMPIONS LEAGUE", "COPA LIBERTADORES") escritos en el código | 🟢 ahora salen de la tabla `CONFED` |

## Pendiente antes de vender

1. Confirmar licencia o reemplazar los modelos 🟡 de Sketchfab (`complejo_residencial`, `arco_entrada`,
   `asientos_lod`) y los `.obj` sin origen anotado (`estadio`, `farola`, `vagabond`).
2. Guardar la prueba de licencia del mocap (Gumroad) y del podio (Meshy).
3. La base «ficticia» (`datos/tablas.json` → `REALES`, 256 clubes) son las plantillas reales con el nombre
   retocado letra a letra («Fernando de Paul» → «Fernando de Peol») y la misma edad, media, posición y
   nacionalidad. Viaja en los builds públicos. ¿Basta para el derecho de imagen? Lo decide el dueño (M-421).

## Ultimate Modular Men / Women — `assets/characters/modular/`
Quaternius, CC0-1.0 (vía `trebeljahr/quaternius-showcase/LICENSES.md`). 13 civiles realistas sin animaciones (de 21; sin texturas), esqueleto de 49-51 huesos; `visor/idle_procedural.gd` les da el reposo. Fuera de LFS (OK del dueño, 2-11-2026).

## Avatar regalo del dueño — `assets/characters/avatar_regalo/` (11-11-2026)
FBX de cuerpo entero con texturas incrustadas (esqueleto Mixamo, 73 huesos, 1,82 m). 🔴 LICENCIA SIN CONFIRMAR y sin saber si la cara es de una persona real: EXCLUIDO de los 6 presets de exportación (no va en builds públicos). Solo en el editor.

## Quitados el 11-11-2026 por no ser realistas (orden del dueño)
Outfits «Fantasy» (Campesino, Explorador), KayKit Adventurers/Skeletons, avatares VRM de Numinia, pieles Kenney «skater/criminal/cyborg» y 8 civiles modulares (Adventurer, Farmer, King, Spacesuit, Medieval, SciFi, Witch). Los que estaban en LFS (Kenney `Model`, `Animations`) siguen en el repositorio, sin usarse y fuera de los builds.

## Terceros sumados el 31-10 y el 01-11-2026 (orden del dueño: «agarrar todo» de League-Soccer y soccer5v5)

| Qué | Dónde | Fuente | Estado |
|---|---|---|---|
| 17 animaciones de la Universal Animation Library 2 (Quaternius) | `assets/characters/quaternius/anims_ual2/` | quaternius.itch.io (copia en github.com/NafisRayan/Animate-Rigged-Humanoid-No-Blender) | 🟢 CC0 (`LICENCIA_CC0.txt`) |
| 2.522 ciclos de locomoción convertidos (1.261 + espejos): marcha, carrera, lateral, atrás y reposo en los 100 estilos (11-11-2026) | `assets/characters/quaternius/anims_100style/100style*.res`, catálogos `datos/animaciones_catalogo_100style.json` | «100STYLE», Ian Mason, Sebastian Starke, Taku Komura (zenodo.org/records/8127870) | 🟢 CC BY 4.0 (la ficha de Zenodo dice `cc-by-4.0`): **atribución obligatoria**, ya en `nucleo/creditos.gd`; se pide citar el artículo «Real-Time Style Modelling of Human Locomotion via Feature-Wise Transformations and Local Motion Phases» (2022). Herramientas: `herramientas/estilo100_*` |
| 33 clips de la Universal Animation Library 1 y 2 (sprint, trote, saltos, caídas, entrada deslizante, celebración; 11-11-2026) | `assets/characters/quaternius/anims_ual/ual_extra.res`, catálogo `datos/animaciones_catalogo_ual.json` | quaternius.itch.io (versión Standard gratuita) | 🟢 CC0 1.0 (`License.txt` de la descarga) |
| 293 animaciones de fútbol convertidas (+ espejos) | `assets/characters/quaternius/anims_league/league.res` | github.com/awest813/League-Soccer (heredero de GameplayFootball / Google Research Football) | 🟢 Apache 2.0 (`terceros/league_soccer/LICENCIA_Apache-2.0.txt`); citar en los créditos |
| Golpeo de balón y palo (`pase_corto`, `tiro_potente`, `poste`, `travesano`) | `audio/ui/*.ogg` | League-Soccer, `data/media/sounds/ballsound.wav` y `goalpost.wav` | 🟡 el repositorio es Apache 2.0, pero el WAV no indica su origen (viene de GameplayFootball): confirmar o sustituir antes de vender |
| Minijuego retro 5 contra 5: código, dibujos y efectos | `minijuegos/retro5v5/` | github.com/Habeeb-Rahman-CA/soccer5v5-game-godot | 🟢 MIT, © 2026 Habeeb Rahman (`minijuegos/retro5v5/LICENCIA_MIT.txt`); citar en los créditos. Clubes con nombre modificado y jugadores inventados (el original traía reales) |
| Música del minijuego (4 temas) | `minijuegos/retro5v5/assets/music/` | soccer5v5 | 🟡 el repositorio es MIT, pero su autor no dice de dónde salen los temas: confirmar o sustituir antes de vender |
| Fuente «Daydream» de soccer5v5 | solo en `terceros/soccer5v5/` | soccer5v5 | 🔴 SOLO USO PERSONAL: no se usa ni se publica |
| Fuente «Pixeled» de soccer5v5 | solo en `terceros/soccer5v5/` | soccer5v5 | 🔴 sin licencia: no se usa |
| Rótulo «World Cup» de soccer5v5 | solo en `terceros/soccer5v5/` | soccer5v5 | 🔴 marca registrada de la FIFA: no se usa |
| Máquina recreativa | `assets/kenney/mini_arcade/arcade-machine.glb` | Kenney Mini Arcade | 🟢 CC0 (ya listado arriba; ahora en uso) |
| Núcleo del motor del partido portado a GDScript (decisión con balón, colocación del equipo, física del balón; 10-11-2026) | `visor/league_nucleo.gd`, `visor/league_reglas.gd`, `visor/league_equipo.gd`, `visor/league_sin_balon.gd`, `visor/motor_league.gd`, `visor/motor_league_p1.gd` | League-Soccer `src/onthepitch/` (Copyright 2019 Google LLC & Bastiaan Konings) | 🟢 Apache 2.0: obra derivada con aviso de cambios en cada archivo; atribución en `terceros/league_soccer/NOTICE_DINASTIA.md` y en los créditos del juego |
| Respaldo completo de los dos repositorios | `terceros/` | — | No viaja en ningún build (Godot no lo importa: `.gdignore`). Sus datos REALES no se copiaron: solo su dirección (`terceros/league_soccer/DIRECCION_DATOS_REALES.md`). No usar sus marcas («LEAGUE SOCCER», «LS SPORTS»), sus carteles de publicidad con marcas reales ni sus fondos sin origen indicado |



## Texturas PBR (10-11-2026, sesión 7)
Texturas `assets/cc0/*` (suelos, paredes y azulejo del vestuario): **Poly Haven**, licencia **CC0** (https://polyhaven.com/license), bajadas a 1K con `herramientas/bajar_cc0.py` (rubber_tiles, hinoki_planks, patterned_terracotta_tiling, dark_wooden_planks, beige_wall_001, brick_wall_005, clay_plaster, floor_tiles_06, herringbone_parquet, beige_wall_002, laminate_floor_02, brushed_concrete_03, granite_tile, patterned_clay_plaster, clay_floor_001, patterned_clay_wall). 🟢

Modelos `assets/cc0_modelos/*` (muebles de oficina: modern_arm_chair_01, modern_wooden_cabinet, modern_coffee_table_01; texturas reducidas a 512 px): **Poly Haven**, licencia **CC0**, glTF 1K bajados con `herramientas/bajar_cc0_modelos.py`; fuera de LFS con excepción en `.gitattributes` (autorizado por el dueño, 10-11). 🟢
