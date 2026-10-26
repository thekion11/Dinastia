# 01 — Recursos libres en GitHub que nos sirven (26-10-2026)

Sesión 4 (investigación). **No se descargó nada al repo.** Los clones superficiales se hicieron en `/tmp` y se borraron. Las rutas de código son relativas a `dinastia-godot/`.

## Cómo se verificó

- **Licencias.** Cada licencia se leyó en el **archivo real del repositorio**, por `raw.githubusercontent.com/<repo>/<rama>/<archivo>`, con la rama sacada de `git ls-remote --symref`. Esta sesión volvió a leer en persona las licencias de los recursos de prioridad alta: Mesh2Motion, VAT plugin, KayKit City Builder, Sky3D, MPFB2, CMU, VCSL, Meta-open-sound, Inter, Tabler, Lucide y flag-icons, y comprobó la etiqueta `4.7.2-stable` de godot-ci.
- **Qué licencias valen.** Solo las que permiten uso comercial: CC0, CC-BY, MIT, ISC, Apache-2.0, BSD, OFL y Unicode. Se descartó todo lo NC, ND y sin licencia.
- **Peso.** Es `du -sh` del clon sin `.git`, o la cifra que da el propio repositorio.
- **Calidad.** Nota de 1 a 5, estimada mirando el contenido, el mantenimiento y lo que dice la comunidad.

**Dos condiciones del proyecto que deciden el encaje**

1. **Renderizador.** `project.godot:53-57` usa Forward+ en escritorio y `gl_compatibility` en móvil y Web. Todo lo que use compute shaders (`.glsl` o RenderingDevice) **no funciona en móvil**; va marcado **[solo F+]**.
2. **LFS.** Desde el contenedor, GitHub rechaza las subidas a LFS (orden 7 de `CLAUDE.md`).
   - Solo `audio/ui/*.ogg` tiene excepción en `.gitattributes`.
   - Un `.ogg` o `.glb` en otra carpeta iría a LFS y **hay que preguntar al dueño**.
   - Los `.ttf`, `.svg` y `.png` no van a LFS.

**Hallazgo principal.** Mesh2Motion (CC0) trae animaciones con el **mismo esqueleto de nombres UE5** que ya usamos (`neck_01`, `index_01_l`…, igual que Quaternius UAL y los `anims_futbol/*_ue5.fbx`). Incluye justo lo que nos falta:
- **Grada**: `Cheering_Two_Hands`, `Cheer_One_arm`, `Victory_Fist_Pump`.
- **Banquillo**: `Sitting_*`, `Idle_FoldArms`, `Angry`, `Reject`, `Insult`.
- **Ceremonia**: `Salute`, `Greeting`.

Junto con el plugin VAT de antzGames (MIT, Godot 4.7, funciona en Compatibility) da una **hinchada animada de verdad** que también va en móvil.

---

## A. Modelos 3D: personas, props y ciudad

| Recurso | URL | Licencia (archivo leído) | Peso | Calidad | Encaje en nuestro código | Prioridad |
|---|---|---|---|---|---|---|
| **MPFB2 / MakeHuman**: generador de humanos realistas en Blender | github.com/makehumancommunity/mpfb2 | `LICENSE.md` §C: los assets (malla base, *targets*, texturas, ropa, rigs) son **CC0 1.0**. §D: lo que se exporta no hereda la licencia del programa. El código es GPL, pero se queda en Blender y no viaja en el juego | herramienta | 4: humanos realistas, ropa CC0 | **El mejor reemplazo de `assets/personas/persona_realista.glb`** 🟡 (`visor/persona_realista.gd`; presentador del sorteo y mentores). Es un escaneo de una persona real; un humano sintético quita también el problema del derecho de imagen | **alta** |
| **KayKit City Builder Bits 1.0**: edificios A–H, bancos, calles | github.com/KayKit-Game-Assets/KayKit-City-Builder-Bits-1.0 | `LICENSE.txt`: «Creative Commons Zero, CC0… free to use in personal, educational and commercial projects» | ~10 MB | 4: *low-poly* parecido a Kenney | Reemplazo de los 🟡 `complejo_residencial.glb` (`visor/city_builder.gd`, `city_builder_p1.gd`, `city_builder_p2.gd`), `farola.obj` y `estadio.obj` (`visor/city_builder_p1.gd`) | **alta** |
| **KayKit Furniture Bits 1.0** | github.com/KayKit-Game-Assets/KayKit-Furniture-Bits-1.0 | `LICENSE.txt`: CC0 | ~7 MB | 4 | Casa (`ui/casa_escena3d*.gd`), interiores (`ui/componentes/interior_instalacion*.gd`) y sala de prensa | media |
| **KayKit Prototype Bits / Restaurant Bits** | github.com/KayKit-Game-Assets/KayKit-Prototype-Bits-1.0 · …/KayKit-Restaurant-Bits-1.0 | `LICENSE.txt`: CC0 (los dos) | no medido | 3 | Bar y cantina del club; conos y cajas de entrenamiento | baja |
| **Mesh2Motion: modelos humanos** (`static/models-variation/human/*.glb`) | github.com/scottpetrovic/mesh2motion-app | `LICENSE-CC0.MD`: «All 3d models, blend files, rigs, animations — CC0 1.0 Universal». Ojo: `src/lib/VariationLicenseInfo.ts` admite variantes CC-BY o CC-SA, así que **hay que mirar modelo por modelo** | ~13 MB las animaciones | 3: *low-poly*, rig UE5 | Variedad de peatones (`visor/peaton_q.gd`) y de público (`herramientas/hornear_publico.gd`) | media |
| **godot-vrm**: importa VRM y MToon | github.com/V-Sekai/godot-vrm | `LICENSE`: MIT. Los modelos de muestra tienen otra licencia (`vrm_samples/LICENSE_SAMPLES.txt`): **no usarlos** | 9,4 MB (el *addon*, 624 KB); Godot 4.2+ | 4 | Personajes que el dueño haga en VRoid (los derechos son suyos) para el DT y los mentores (`visor/personaje_dt.gd`) | baja |
| **KayKit Character Pack Adventures** | github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0 | `LICENSE.txt`: CC0 | ~124 MB | 4 en su estilo, pero es fantasía | Como mucho disfraces de hinchas y mascotas (`visor/mascota_q.gd`) | baja |
| Kenney Starter Kit City Builder | github.com/KenneyNL/Starter-Kit-City-Builder | `LICENSE.md`: MIT (código); modelos de Kenney, CC0 | 2,4 MB | 3 | Ejemplo de rejilla para `visor/city_builder*.gd` | baja |
| Godot TPS demo | github.com/godotengine/tps-demo | `LICENSE.md`: assets **CC-BY 3.0** | no medido | 4 | Solo referencia de materiales (es ciencia ficción) | baja |

**No encontrado con licencia en GitHub:** estadios, porterías, banderines, banquillos ni focos. Lo mejor es seguir con el estadio procedural (`visor/stadium_builder*.gd`) y modelar ahí lo que falte. Fuera de GitHub hay porterías y balones *low-poly* en Poly Pizza (mezcla CC0 y CC-BY) y un balón CC0 en itch.io (dleom); no se verificaron.

## B. Animaciones

| Recurso | URL | Licencia | Peso | Calidad | Encaje | Prioridad |
|---|---|---|---|---|---|---|
| **Mesh2Motion: animaciones humanas** (`static/animations/`: `human-base` 87 clips, `human-addon` 75, `human-mocap` 16) | github.com/scottpetrovic/mesh2motion-app | `LICENSE-CC0.MD` (CC0) y el README: «art assets… are all licensed under CC0» | 5,6 + 5,3 + 2,0 MB | 4. **Esqueleto UE5**, compatible con `visor/anim_quaternius*.gd` y `visor/retarget_futbol_q.gd`, cuyo `MAPA_HUESO` hoy solo mapea `head` | **Grada y festejo**: `Cheering_Two_Hands`, `Cheer_One_arm`, `Victory_Fist_Pump` → `visor/festejo_grada.gd`, `herramientas/hornear_publico.gd`. **Banquillo y DT**: `Sitting_Idle`, `Sitting_Talking`, `Idle_FoldArms`, `Angry`, `Reject` → `visor/personaje_dt*.gd`. **Ciudad**: `Walk_Formal`, `Idle_TalkingPhone`, `Jog` → `visor/peaton_q.gd`. **Ceremonia**: `Salute`, `Greeting`, `Head Nod` → `visor/ceremonia_partido*.gd` | **alta** |
| **CMU Mocap en BVH** (2.548 clips, conversión de cgspeed) | github.com/una-dinosauria/cmu-mocap | Sin `LICENSE`. `READMEFIRST.txt` cita a CMU: «This data is free for use in research and commercial projects», con agradecimiento opcional a mocap.cs.cmu.edu (NSF EIA-0196217) | ~1-2 GB (estimado, no medido) | 3: mocap real con ruido; hay que retargetear en Blender | **Reemplazo parcial de `assets/characters/quaternius/anims_futbol/`** 🟡 (licencia de Gumroad sin probar). Patadas: `10_01..10_06`, `11_01`, `74_03..06`, `143_24`, `144_05`. Protestas: `18_10`, `19_10`, `80_48` → `visor/cuarto_arbitro.gd` y tarjetas. 646 clips de andar y 144 de correr. **No trae regates** (los de la serie 06 son de baloncesto) | **alta** |
| Quaternius UAL (espejo glTF) | github.com/J-Ponzo/gltf-universal-animation-library | `LICENSE`: CC0 | 6,2 MB | 4 | **Ya la usamos** (`assets/characters/quaternius/anims`). Sirve como fuente en GitHub para `docs/05_referencia/LICENCIAS.md` | baja |
| Mesh2Motion assets (fuentes `.blend`) | github.com/Mesh2Motion/mesh2motion-assets | `LICENSE`: CC0 | no medido | 3 | Editar o crear animaciones propias | baja |

**Descartados por NC/ND:** Bandai Namco Research Motion dataset (CC BY-NC 4.0) y Ubisoft LaFAN1 (CC BY-NC-ND 4.0). Fuera de GitHub, sin verificar: 100STYLE (Zenodo, CC BY 4.0, estilos de andar), KayKit Character Animations (itch).

## C. Shaders: césped, cielo, nubes, agua y multitud

| Recurso | URL | Licencia | Peso / Godot | Calidad | Encaje | Prioridad |
|---|---|---|---|---|---|---|
| **VAT: Vertex Animation Textures plugin** (MultiMesh animado) | github.com/antzGames/Godot_Vertex_Animation_Textures_Plugin | `LICENSE`: MIT (Antz 2024) | repo 162 MB, *addon* **168 KB**; **Godot 4.7, Compatibility** | 4. Su demo ya usa modelos de Mesh2Motion | **Multitud animada**: sustituir las poses fijas horneadas (`herramientas/hornear_publico.gd`) por clips en los MultiMesh de `visor/stadium_builder_p5.gd` y `p6.gd`, con `visor/hinchada.gdshader`. Funciona en móvil | **alta** |
| **Sky3D**: día y noche, sol, luna, estrellas, nubes, niebla | github.com/TokisanGames/Sky3D | `LICENSE.txt`: MIT (Petkovsek y colaboradores) | 13 MB; Godot 4.5; solo `.gdshader` | 4; lo mantiene el autor de Terrain3D | Completar o reemplazar `visor/cielo.gdshader` y `visor/ambience.gd`, y la hora en `ui/ciudad_vista.gd`. No usa compute, pero **no se probó en Compatibility** | **alta** |
| **Godot Foam Water**: espuma en los bordes | github.com/antzGames/Godot-Foam-Water | `LICENSE`: MIT (Antz 2025) | 23 MB; Godot 4.6 **Compatibility** | 4; ligero | Mejorar `visor/agua.gdshader` (`visor/city_builder_p2.gd`, `guinos_estadio.gd`) | **alta** |
| gd-vat (winston-yallow) | github.com/winston-yallow/gd-vat | `LICENSE`: MIT | 2,3 MB; Godot 4.1 | 3; mínimo y legible | Alternativa al anterior: meter el shader dentro de `hinchada.gdshader` | media |
| SunshineClouds2: nubes volumétricas | github.com/Bonkahe/SunshineClouds2 | `LICENSE`: MIT | *addon* 14 MB; Godot 4.6; 7 `.glsl` **[solo F+]** | 5 | Cielo del estadio en escritorio, con respaldo de `cielo.gdshader` vía `visor/calidad.gd` y `rendimiento_adaptativo.gd` | media |
| Volumetric Cloud Demo v2 (clayjohn) | github.com/clayjohn/godot-volumetric-cloud-demo-v2 | `LICENSE.md`: MIT (código y atmósfera) | 11 MB; Godot 4.4 | 5; de un mantenedor del renderizador de Godot | Referencia para un cielo con nubes en `cielo.gdshader` | media |
| GodotGrass (2Retr0) | github.com/2Retr0/GodotGrass | `LICENSE`: MIT | 50 MB; Godot 4.3; 1 `.glsl` | 5 | Técnica para `visor/cesped_capas.gdshader`, `cesped.gdshader` y `cesped_comun.gdshaderinc` en primeros planos (`visor/cine_gol.gd`, `repeticion.gd`). **Copiar solo el shader**: trae `reisen.glb`, un personaje de Touhou con derechos de terceros | media |
| ProtonScatter: esparcir con MultiMesh | github.com/HungryProton/scatter | `LICENSE.md`: MIT | 14 MB; **Godot 4.7** | 5 | Árboles, arbustos y objetos de la ciudad, que hoy se ponen a mano en `visor/ciudad_expansion_p5.gd`, `city_builder_p8.gd` y `p11.gd` | media |
| Nishita sky + nubes | github.com/MMqd/godot-nishita-sky-with-volumetric-clouds | `LICENSE.md`: MIT | 23 MB; F+ | 4 | Alternativa para el cielo | baja |
| MultiMesh Grass Shader Example | github.com/Malidos/Grass-Shader-Example | sin `LICENSE`; el README dice «CC0» | 848 KB | 3 | Hierba de exteriores en `ui/casa_naturaleza.gd`. Guardar prueba del CC0 antes de usarlo | baja |
| GodotOceanWaves (FFT) | github.com/2Retr0/GodotOceanWaves | `LICENSE`: MIT | 63 MB **[solo F+]** | 5 | Demasiado para nuestro río y puerto | baja |
| TCA Weather System | github.com/kS222138/TCA_Weather_System | `LICENSE`: MIT | 404 KB | 2; repo muy joven | Referencia frente a `visor/precipitacion.gd` y `nucleo/clima.gd` | baja |
| Waterways · Godot_VAT3 | github.com/Arnklit/Waterways · github.com/G4ND44/Godot_VAT3 | MIT · MIT | Godot 3 · necesita Houdini | — | Solo referencia | baja |

**Fuera de GitHub, CC0, sin verificar aquí:** Poly Haven y ambientCG, con HDRI de cielo para `visor/ambience.gd` y texturas de césped y hormigón para `cesped*.gdshader`.

## D. Herramientas y addons de Godot 4

| Recurso | URL | Licencia | Peso / Godot | Calidad | Encaje | Prioridad |
|---|---|---|---|---|---|---|
| **godot-ci**: imagen Docker con Godot y plantillas | github.com/abarichello/godot-ci | `LICENSE`: MIT. Etiquetas **`4.7.2-stable`**, `4.7.1-stable` y `4.7-stable` (comprobado con `git ls-remote --tags`) | — | 5 | **La «imagen Godot 4.7 para el CI» de las órdenes del lunes** (`docs/PLAN_DEL_LUNES.md` §1, `compilar.yml`): correr `herramientas/banco.sh` y exportar. No se comprobó Docker Hub | **alta** |
| setup-godot (GitHub Action) | github.com/chickensoft-games/setup-godot | `LICENSE`: MIT | — | 4 | Alternativa a Docker para el mismo CI | **alta** |
| **Debug Menu**: FPS, tiempo por fotograma, CPU y GPU | github.com/godot-extended-libraries/godot-debug-menu | `LICENSE.md`: MIT (Calinou) | 116 KB | 4 | Más completo que `ui/componentes/contador_fps.gd`; útil para la medida de FPS en hardware real (M-337, del dueño) | **alta** |
| **Antialiased Line2D** | github.com/godot-extended-libraries/godot-antialiased-line2d | `LICENSE.md`: MIT (Calinou) | 104 KB | 4 | Líneas suaves en `ui/radar_partido.gd`, `ui/componentes/radar_atributos.gd`, `pizarra_tactica.gd` y `minimapa_ciudad.gd`, que hoy usan `draw_line`/`draw_polyline` con dientes de sierra | **alta** (barato) |
| Easy Charts | github.com/fenix-hub/godot-engine.easy-charts | `LICENSE`: MIT | *addon* 1,1 MB; Godot 4.6, Compatibility | 4 | `ui/componentes/panel_finanzas_grafico.gd`, que hoy se dibuja a mano, `panel_estadisticas.gd` y `visor/estadisticas_vivo.gd` | media |
| TauPlot | github.com/ze2j/tau-plot | `LICENSE`: BSD-3-Clause | *addon* 4,4 MB; Godot 4.5 | 3; joven | Igual que Easy Charts, y se adapta mejor al tema (`ui/tema.gd`) | media |
| **Dialogue Manager** | github.com/nathanhoad/godot_dialogue_manager | `LICENSE`: MIT | *addon* 1,3 MB; v4.1.0, **Godot 4.7** | 5 | `ui/componentes/cuadro_dialogo.gd`, prensa (`nucleo/prensa*.gd`) y charlas (`nucleo/charlas.gd`). **Choque:** los diálogos se generan con `herramientas/dialogos_ciudad.py`, así que habría que generar archivos `.dialogue` en vez de escribirlos a mano | media |
| Phantom Camera | github.com/ramokz/phantom-camera | `LICENSE`: MIT | 3,1 MB | 5 | Cámaras de TV y transiciones: `visor/camera_rig*.gd`, `cine_gol.gd`, `intro_partido.gd`, `repeticion*.gd`, y el corte al cartel del cuarto árbitro (plan §3). Revisar con la cámara real | media |
| Beehave: árboles de comportamiento | github.com/bitbrain/beehave | `LICENSE`: MIT (rama `godot-4.x`) | *addon* 3,6 MB; Godot 4.7 | 4 | Peatones que esquiven (plan §8: hoy «solo esperan»; `visor/peaton_q.gd`), `visor/personal_estadio.gd`, mascota | media |
| Godot Road Generator | github.com/TheDuckCow/godot-road-generator | `LICENSE`: MIT | Godot 4.4 | 4 | Carriles y rutas para `visor/trafico_ciudad*.gd`, `autopista.gd` y `semaforos.gd` (ceder el paso, plan §8) | media |
| godot-imposter (Godot 4) | github.com/zhangjt93/godot-imposter | `LICENSE`: MIT | *addon* 428 KB; Godot 4.5 F+ | 3; no hornea por lotes | Edificios lejanos (`visor/oclusores_ciudad.gd`, `visibility_range` en `city_builder_p5.gd`) y el anillo de público lejano | media |
| Virtual Joystick | github.com/MarcoFazioRandom/Virtual-Joystick-Godot | `LICENSE`: MIT | 652 KB; Compatibility | 4 | Partido jugable en móvil (`ui/partido_jugable*.gd`, `visor/control_partido.gd`) y paseo por la ciudad (`visor/explorador_ciudad*.gd`) | media |
| godot-gdscript-toolkit (gdlint, gdformat) | github.com/Scony/godot-gdscript-toolkit | `LICENSE`: MIT | pip | 4 | Complemento de `herramientas/revisar_lineas.py` y `pruebas/comprobar_scripts.gd` (`max-file-lines=450`) | media |
| Debug Draw 3D | github.com/DmitriySalnikov/godot_debug_draw_3d | MIT (`addons/debug_draw_3d/LICENSE`) | GDExtension; los binarios están en Releases | 5 | Depurar el balón (`visor/balon_3d.gd`), la IA (`visor/motor_jugable*.gd`) y los oclusores | media |
| Godot State Charts | github.com/derkork/godot-statecharts | `LICENSE`: MIT | *addon* 4,4 MB | 4 | Estados del portero (`visor/motor_cambio_portero.gd`) y transiciones (`visor/anim_transiciones.gd`) | baja |
| LimboAI | github.com/limbonaut/limboai | `LICENSE.md`: MIT | GDExtension | 5 | Como Beehave, pero en C++; ojo con la exportación a móvil | baja |
| Spatial Gardener · Terrain3D · HeightMap (Zylann) | dreadpon/godot_spatial_gardener · TokisanGames/Terrain3D · Zylann/godot_heightmap_plugin | MIT · MIT · MIT | — | 4-5 | Vegetación y terreno (`visor/terreno.gdshader`); seguramente sobran | baja |
| Maaack's Menus Template | github.com/Maaack/Godot-Menus-Template | `LICENSE.txt`: MIT | 9,3 MB; Godot 4.7 | 4 | Referencia de opciones y carga frente a `ui/pantallas/` y `ui/componentes/pantalla_carga.gd` | baja |
| Godot 4 Localization Editor | github.com/VP-GAMES/Godot4LocalizationEditor | `LICENSE`: MIT | 3,4 MB | 3 | **Choque**: nuestro formato es `datos/idiomas_extra.json` con `Idiomas.t`, no CSV ni PO. No compensa | baja |
| gdUnit4 · GUT · SaveMadeEasy · godot-sqlite · Godot Tracy | — | MIT todos | — | — | Ya tenemos banco propio (`nucleo/banco.gd`) y guardado (`nucleo/partida_archivo.gd`). Tracy obliga a recompilar Godot | baja |

**Descartados o sin verificar**
- `wojtekpil/Godot-Octahedral-Impostors`: MIT, pero solo Godot 3.
- `hdrsniped/octahedral-impostor-lod-godot`: Godot 4.7, pero **sin LICENSE**.
- `GDQuest/godot-shaders` y su controlador 3D: código MIT, pero el arte es **CC-BY-NC-SA**; solo se puede tomar el código.
- `NitroxNova/humanizer` (MakeHuman en Godot): **AGPL-3.0**, no se puede llevar en el juego.
- `MeshLodGenerator`: CC BY 4.0, pero Godot ya genera LOD al importar.
- GDQuest Steering AI: es Godot 3. En 4.x está `NavigationAgent3D` con evasión RVO integrada, y **hoy no lo usamos** (grep: 0 usos).
- Dialogic 2: sigue en alfa.

## E. Sonidos

Por dónde entran los sonidos grabados: `nucleo/sonido.gd:20-30` (`_crear_banco`). Si existe `res://audio/ui/<receta>.ogg`, **sustituye a la síntesis** (un solo sonido, sin variantes), y el volumen se ajusta en `AJUSTE_DB`.

Dónde suena el partido:

| Sonido | Dónde |
|---|---|
| silbato y murmullo | `ui/partido_vivo.gd:336-337,370` |
| silbato | `ui/partido_vivo_p2.gd:296` |
| ovación | `ui/partido_vivo_p1.gd:176` |
| gol | `ui/partido_jugable_p1.gd:312` |
| aplauso | `ui/componentes/cinematica_fichaje.gd:97` |

| Recurso | URL | Licencia | Peso | Calidad | Encaje | Prioridad |
|---|---|---|---|---|---|---|
| **VCSL** (Versilian Community Sample Library) | github.com/sgossner/VCSL | `LICENSE`: **CC0 1.0** | El silbato son 361 KB en WAV (~40 KB en OGG); el repo tiene 4.282 WAV | 4: estudio, limpio | **Silbato de árbitro real**: `Aerophones/Edge-blown Aerophones/Ball Whistle/Main_BallWhistle_Long-001.wav` y `_Short-001.wav` (comprobado). Va como `audio/ui/silbato.ogg` para `_receta_silbato`, `_receta_pitido_final` y `_receta_medio_tiempo`, y cabe en la excepción LFS. Bombo, palmas y platillos sirven como capas de `_receta_tambor`, `_receta_gol_bombo` y `_receta_aplauso` | **alta** |
| **Meta-open-sound / Oculus Audio Pack 1**: 289 sonidos, 508 tomas | github.com/facebookincubator/Meta-open-sound | Raíz CC0 (`LICENSE`), pero el pack lleva **CC BY 4.0** (`corpora/oculus-audio-pack/LICENSE`): **hay que acreditar** | ~10 KB por clic en OGG | 5: profesional | Interfaz (29 UIClick, 17 UIAlert): `_receta_error`, `_receta_aviso`, `_receta_notificacion`. Coche: `visor/motor_coche_sonido.gd`. Ciudad y lluvia (`AMBUrbn_CityEuroDaytime`, `RAIN_CityRain`): `_receta_lluvia_ambiente`. 72 pisadas: `_receta_paso`. Voces de esfuerzo: `_receta_lesion` | **alta / media** |
| Kenney: Impact, Interface, UI Audio, Music Jingles, Voiceover | kenney.nl (espejo en github.com/lavenderdotpet/CC0-Public-Domain-Sounds) | CC0. Mejor bajarlo del original, como los clics que ya tenemos | 100-300 KB por pack | 4 | Impactos: `_receta_despeje`, `_receta_poste`, `_receta_tiro_potente`. Jingles: `_receta_trofeo`, `_receta_ascenso`, `_receta_logro` | media |
| Muestras de Sonic Pi (`etc/samples`) | github.com/sonic-pi-net/sonic-pi | `etc/samples/README.md`: CC0 (Freesound y Arovane). **No usar `loop_amen*`**: el *Amen break* tiene problemas de derechos | ~100 FLAC pequeños | 3 | Redobles de hinchada: `_receta_tambor`, `_receta_tambor_visitante` | media-baja |
| godot-sfxr · gdfxr | github.com/tomeyro/godot-sfxr · github.com/timothyqiu/gdfxr | MIT | < 100 KB | 3 | Herramienta para afinar recetas; va con nuestra síntesis | baja |
| sfx-kit · homebrew_vgm · ZzFX | wyzowl/sfx-kit · Beatscribe/homebrew_vgm · KilledByAPixel/ZzFX | CC0 · CC0 · MIT | — | 3 | sfx-kit también es sintetizado por código, así que aporta poco. homebrew_vgm es chiptune | baja |

**No encontrado en GitHub con licencia verificable:** hinchada, cánticos, ambiente de estadio, golpe de balón y red. Fuera de GitHub:
- Freesound, filtrando por CC0.
- Wikimedia Commons, cuando se abra la red (lunes).
- «Free Crowd Cheering Sounds», de Gregor Quendel, en OpenGameArt (CC BY 4.0 según el buscador; no se pudo abrir).

Recomendación: **seguir sintetizando la hinchada, la red y el balón**, y usar el silbato y la percusión de VCSL como capas.

**Descartados:** ESC-50 y UrbanSound8K (no comerciales), BBC Sound Effects (RemArc no comercial), y los packs «warfork» y «MMRetro» del espejo de lavenderdotpet (origen sin comprobar).

## F. Narración y voz

Hoy la narración es solo texto (`datos/narracion*.json`, `nucleo/prensa*.gd`). `DisplayServer.tts_*` no se usa en ningún sitio.

**Ojo con el linaje de cada voz Piper.** La licencia de una voz es la del dataset con que se entrenó (está en su `MODEL_CARD`). Muchas voces se afinan desde `en_US-lessac`, cuyo dataset (Blizzard 2013) **prohíbe el uso comercial**. Hugging Face está bloqueado desde aquí: la tabla viene de auditorías de terceros en GitHub (`444sofiane/Batch-tts-generator/PIPER_VOICE_LICENSES.md`, leída entera) y **hay que confirmarla en el `MODEL_CARD` antes de usar una voz**.

| Recurso | URL | Licencia | Encaje | Prioridad |
|---|---|---|---|---|
| **Piper** (motor) | github.com/rhasspy/piper (archivado; sucesor `OHF-Voice/piper1-gpl`) | Motor MIT (`LICENSE.md`); el sucesor es GPL-3 | **Pregrabar sin conexión** frases cortas por idioma («¡Gol!», «¡Qué atajada!», «Final del partido») en `.ogg` que suenen por `Sonido`. Usar la herramienta GPL fuera del juego no afecta al audio que produce. **No meter la librería dentro del juego** | **alta** (pregrabado) |
| Voces Piper aptas, según la auditoría | rhasspy/piper `VOICES.md` | **es**: `es_MX-claude-high` Apache-2.0, `es_ES-carlfm-x_low` dominio público, `es_ES-sharvard` CC BY 3.0, `es_ES-mls_*` CC BY 4.0. **en**: `en_GB-cori` y `en_US-ljspeech` dominio público, `en_US-arctic` (tipo BSD). **pt**: `pt_BR-faber/cadu/jeff` y `pt_PT-tugão` CC0. **fr**: `siwis` CC BY 4.0. **it**: `riccardo` (M-AILABS, BSD-3), `serena` CC BY 4.0. **de**: `eva_k`/`karlsson`/`ramona` (M-AILABS, BSD-3). **pl**: `darkman`/`gosia`/`mc_speech` CC0. **ca**: `upc_ona`/`pau` **CC BY-SA 3.0** (compartir igual). **tr**: solo `dfki`, **CC BY-NC-SA → no hay voz turca apta** | Evitar las afinadas desde lessac aunque digan CC0 (`es_ES-davefx`, `fr_FR-gilles`, `de_DE-thorsten`, `es_MX-ald`) y `lessac`, `ryan`, `hfc_*`, `amy`, `semaine`, `l2arctic`, `pavoque` y `kerstin` | alta (con revisión legal) |
| Kokoro-82M | github.com/hexgrad/kokoro | Apache-2.0, código y pesos | Calidad 5, pero solo es, fr, it, pt-br y en: **no tiene de, pl, tr ni ca** | media |
| sherpa-onnx | github.com/k2-fsa/sherpa-onnx | Apache-2.0 | Corre Piper o Kokoro desde C. Para voz en vivo (nombres de jugadores) habría que escribir un GDExtension | media |
| MeloTTS | github.com/myshell-ai/MeloTTS | MIT | Solo en, es y fr | media-baja |
| Voz del sistema (`DisplayServer.tts_speak`) | integrado en Godot | del motor | Accesibilidad: «leer la crónica» en `ui/partido_vivo_p1.gd` (`_escribir`). Cubre los 9 idiomas si el sistema tiene voces; coste cero | media |

**Descartados:** Coqui XTTS (pesos CPML, no comerciales), fish-speech (licencia comunitaria con restricciones), F5-TTS (pesos CC BY-NC, citado de memoria) y espeak-ng como voz (GPL-3 y robótica). `PhilNikitin/godot-kokoro` no tiene licencia.

## G. Música

Hoy hay 6 piezas compuestas en vivo por `nucleo/musica.gd`, que deja escrita la decisión de usar «cero ficheros de audio». Lo coherente es usar **muestras de instrumento** (el timbre), no pistas grabadas. La música final es del dueño (🔒).

| Recurso | URL | Licencia | Peso | Encaje | Prioridad |
|---|---|---|---|---|---|
| **Meta Piano / Nylon Guitar / Steel Guitar** (con mapas SFZ) | github.com/facebookincubator/Meta-open-sound | `LICENSE` raíz: **CC0 1.0** (leído) | El piano completo: 352 muestras, ~35 MB. Con una capa de velocidad y una nota de cada tres, ~2-3 MB | Cambiar el oscilador de `_nota` en `nucleo/musica.gd` por una muestra afinada, **sin perder la composición dinámica**. Va fuera de `audio/ui/`, así que **hay que preguntar por LFS** | **alta** |
| VSCO-2-CE: orquesta de cámara | github.com/sgossner/VSCO-2-CE | `LICENSE`: CC0 | cientos de MB; se usaría un subconjunto | Metales y timbales para `_receta_himno`, `_receta_trofeo` y piezas épicas | media |
| TinySoundFont | github.com/schellingb/TinySoundFont | MIT | un `.h` | MIDI + SF2 si algún día se hace un GDExtension | baja |
| SoundSafari/CC0-1.0-Music | github.com/SoundSafari/CC0-1.0-Music | dice CC0, pero **es una recopilación** (incluye Pixabay, que no es CC0) | ~40 GB | Solo FreePD con verificación tema a tema; contradice la decisión de `musica.gd` | baja |
| midi-js-soundfonts | github.com/gleitz/midi-js-soundfonts | código MIT; **la licencia de las muestras no se leyó** | — | pendiente | baja |

## H. Fuentes (tipografías)

**Lo que hay hoy**
- Los 9 idiomas (es, en, pt, fr, it, de, ca, pl, tr) **solo usan alfabeto latino**, pero piden Latin Extended-A: ą ć ę ł ń ś ź ż, ğ İ ı ş, Œ œ y el **ᵉ** francés (`"$1ᵉ sur $2"`). Se comprobó con fontTools sobre `idiomas_extra.json`, `narracion_traducida*.json`, `tablas.json` y `bolsas_nombres.json`.
- `ui/principal_p2.gd:325` (`TIPOGRAFIAS`) y `ui/principal_p4.gd` (`_fuente_de`, con `SystemFont`) piden Impact, Arial Narrow y Georgia, que **no existen en Linux, Android ni Web**.
- Hay **1.106 emojis usados como icono en 182 archivos** (los más repetidos: ✔ 44, ⚙ 27, 🏆 25, ⚽ 22). El respaldo `REPUESTO_SIMBOLOS` (`ui/principal_p2.gd:337`) son fuentes del sistema.
- `project.godot` activa MSDF.

| Fuente | Repo y licencia | Peso | Glifos que faltan | Uso | Prioridad |
|---|---|---|---|---|---|
| **Inter** | github.com/rsms/inter, OFL 1.1 (`LICENSE.txt`, leído) | 877 KB, variable | **0** (tiene hasta ᵉ); cifras tabulares | Fuente base: `ui/tema.gd`, «juego» en `TIPOGRAFIAS` | **alta** |
| **Noto Emoji** (monocromo) + **Noto Sans Symbols 2** | google/fonts, OFL | 2,0 + 1,2 MB | Con Inter cubren **los 345 símbolos y emojis distintos que usa el juego (100 %)** | Sustituyen a `REPUESTO_SIMBOLOS`. Son contornos: van con MSDF y se tiñen con `font_color` | **alta** |
| **Barlow Condensed** | github.com/jpt/barlow, OFL | ~100 KB por estilo | solo ᵉ; cifras tabulares | «estrecha» (hoy Arial Narrow), tablas, plantilla | **alta** |
| **Bebas Neue** | github.com/dharmatype/Bebas-Neue, OFL | 61 KB | solo ᵉ (solo mayúsculas) | «titular» (hoy Impact), marcador (`ui/estadio_p1.gd:57`) | **alta** |
| Jersey 10 / 25, Graduate, Alumni Sans Collegiate One | google/fonts, OFL | 60-165 KB | solo ᵉ | Dorsales y nombres en la camiseta: `ui/disenos_kit.gd`, `ui/estadio_p3.gd` y `p4.gd`, `ui/partido_jugable_p1.gd` | media |
| DSEG7 (LED de 7 segmentos) | github.com/keshikan/DSEG, OFL (`DSEG-LICENSE.txt`) | ~30 KB | solo cifras | Videomarcador. **Los `.ttf` solo están en Releases (bloqueado)** | media |
| Oswald, Anton, Teko, Saira Condensed, Big Shoulders | OFL | 60-320 KB | solo ᵉ; cifras de ancho variable | Titulares y portadas (`ui/componentes/portada_periodico.gd`) | media |
| Noto Color Emoji | github.com/googlefonts/noto-emoji, OFL | COLRv1 5 MB / CBDT 10,7 MB | — | Emojis en color. **Probar en Godot**: CBDT no va con MSDF y COLRv1 está sin confirmar | media |
| Atkinson Hyperlegible Next | OFL | 115 KB | ō, ᵉ | Modo de lectura fácil (accesibilidad) | media-baja |
| Noto Sans, Roboto Condensed, Montserrat, Source Sans 3 | OFL | 0,4-2 MB | 0 (Roboto Condensed: ᵉ) | Alternativas a Inter | media |

**Total recomendado:** Inter + Noto Emoji + Symbols 2 + Barlow Condensed + Bebas Neue ≈ **4,3 MB**, fuera de LFS. **Descartadas:** Squada One (le faltan 36 glifos: el polaco, el turco y las comillas) y Rajdhani (le faltan ª y º).

## I. Iconos

Objetivo: sustituir poco a poco los 1.106 emojis-icono por SVG, que Godot importa con ThorVG. Los iconos de trazo usan `stroke="currentColor"`: conviene pasarlo a `#fff` al importar para teñirlos con `modulate`. Hoy `assets/iconos_botones/` son Kenney Input Prompts 1.5A (CC0, 514 archivos).

| Set | URL | Licencia | Fútbol que trae | Prioridad |
|---|---|---|---|---|
| **Tabler Icons** (5.184 de trazo + 1.054 rellenos) | github.com/tabler/tabler-icons | **MIT** (leído) | `ball-football`, `building-stadium`, `scoreboard`, `shirt-sport`, `soccer-field`, `play-football`, `cards`, `first-aid-kit`, `transfer`, `trophy`, `speakerphone`, `news` (no tiene silbato) | **alta** |
| **Lucide** (1.903) | github.com/lucide-icons/lucide | **ISC** (leído) | `whistle`, `goal`, `shirt`, `trophy`, `megaphone`, `siren`, `flag` (no tiene balón de fútbol) | **alta**, como complemento de Tabler |
| Phosphor (1.512 × 6 grosores) | github.com/phosphor-icons/core | MIT | `soccer-ball`, `t-shirt`, `trophy`, `medal` | media |
| Material Symbols | github.com/google/material-design-icons | Apache-2.0 | `sports_soccer`, `scoreboard`, `stadium` | media |
| game-icons.net (~4.000) | github.com/game-icons/icons | `license.txt`: CC BY 3.0 (o CC0 si se indica). **Hay que acreditar a cada autor** | `soccer-kick`, `goal-keeper`, `whistle`, `laurels-trophy` | media |
| Twemoji · Fluent Emoji | jdecked/twemoji · microsoft/fluentui-emoji | gráficos CC BY 4.0 · MIT | si se prefiere conservar el estilo emoji | media |

**Evitar:**
- Remix Icon: nueva licencia propia de enero de 2026, que no es OSI y prohíbe usar los iconos como identidad.
- Font Awesome Free: CC BY, hay que acreditar.
- OpenMoji: CC BY-SA, compartir igual.

## J. Datos: nombres, ciudades, países y banderas

Lo que hay hoy:
- `datos/bolsas_nombres.json`: 16 bolsas (BRA, JPN, KOR, KSA, EGY, MAR, RSA, AUS, MEX, USA, ENG, GER, ITA, FRA, ESP y `_GENERAL`).
- `tablas.json`: `NOMBRES` (60) y `APELLIDOS` (80).
- `nucleo/regiones.gd`: solo ESP y EUS.
- `visor/banderas.gd`: dibuja 86 banderas a mano.

| Recurso | URL | Licencia de código / **de datos** | Encaje | Prioridad |
|---|---|---|---|---|
| **faker** (Python) | github.com/joke2k/faker | MIT; las listas de nombres van dentro del repo MIT | Herramienta sin conexión para **ampliar `datos/bolsas_nombres.json`** (es_ES/MX/AR/CL/CO, pt_BR/PT, ja_JP, ko_KR, ar_SA, de, it, fr, pl, tr, hr, zu_ZA…). Le faltan EGY, MAR y AUS. Las combinaciones siguen pasando por `NOMBRES_VETADOS` | **alta** |
| @faker-js/faker | github.com/faker-js/faker | MIT | Completa en_AU, af_ZA/en_ZA, sr_RS_latin, hr, yo_NG… | media |
| **unicode-org/cldr-json** | github.com/unicode-org/cldr-json | **Unicode License V3**, permisiva | Nombres de país traducidos a los 9 idiomas (`cldr-localenames-full/main/<l>/territories.json`; comprobado en es, ca, pl y tr). Ahorra escribirlos a mano en `Idiomas.t` (`ui/entrada/personaje_datos.gd:74`) | **alta** |
| **Natural Earth vector** | github.com/nvkelso/natural-earth-vector | **dominio público** (`LICENSE.md`) | Ya usamos sus fronteras (`recursos/tierra/fronteras4k.png`). `ne_10m_populated_places_simple.geojson` (4,9 MB) trae ciudades con el nombre en es, pt, fr, it, de, pl, tr… para el globo y `ui/mapa_pais.gd` | **alta** |
| **datasets/world-cities** | github.com/datasets/world-cities | código MIT; **datos de GeoNames, CC BY 4.0** (README, leído): hay que acreditar | 34.163 ciudades de más de 15.000 habitantes, con su región: `nucleo/regiones.gd` y `nucleo/mundo*.gd` | **alta** |
| **lipis/flag-icons** | github.com/lipis/flag-icons | **MIT** (leído) | 271 SVG, incluidas `gb-eng`, `gb-sct`, `gb-wls`, `es-ct`, `es-pv`. Alternativa a `visor/banderas.gd`. **Decide el dueño**: choca con la línea «sin símbolos oficiales detallados» de ese archivo, y hay que pasar los 86 códigos FIFA a ISO-2 a mano | **alta** (si el dueño quiere) |
| circle-flags | github.com/HatScripts/circle-flags | MIT | Banderas redondas para la nacionalidad en la interfaz | media |
| popular-names-by-country-dataset | github.com/sigpwned/popular-names-by-country-dataset | CC0; los datos vienen de listas de Wikipedia | 106 países de nombres y 75 de apellidos para `_GENERAL` | media (con nota) |
| openfootball (football.json, clubs) | github.com/openfootball | CC0 | **Solo para reforzar el veto** de nombres de club reales en `herramientas/base_ficticia.py`. Nunca en las versiones públicas | media |
| skeeto/fantasyname | github.com/skeeto/fantasyname | Unlicense | Patrón de generador. Para clubes y estadios mejor una cadena de Markov propia sobre topónimos de Natural Earth y GeoNames | baja |

**Descartados**
- `philipperemy/name-dataset`: **datos sacados de la filtración de Facebook (533 M de usuarios)**.
- `davidam/damegender`: GPL-3.
- Con cuidado: `dr5hn/countries-states-cities-database` y `mledoze/countries` (ODbL, compartir igual), `stefangabos/world_countries` (CC BY-SA).
- La columna FIFA de `datasets/country-codes` tiene fuentes de licencia poco clara.

---

## Orden recomendado (lo de prioridad alta)

1. **Hinchada y banquillo animados**: Mesh2Motion (CC0) + plugin VAT (MIT). Funciona en móvil. Archivos: `herramientas/hornear_publico.gd`, `visor/stadium_builder_p5.gd`/`p6.gd`, `visor/hinchada.gdshader`, `visor/personaje_dt*.gd`.
2. **Quitar los 🟡 de `LICENCIAS.md`**:
   - MPFB2 → `persona_realista.glb`.
   - KayKit City Builder → `complejo_residencial.glb`, `farola.obj`, `estadio.obj`.
   - CMU → parte de `anims_futbol/` (tiros y protestas).
3. **Fuentes**: Inter + Noto Emoji + Symbols 2 + Barlow Condensed + Bebas Neue (~4,3 MB, sin LFS). Arregla los emojis y las fuentes que faltan en Linux, Android y Web.
4. **CI**: `barichello/godot-ci:4.7.2-stable` o `setup-godot` (órdenes del lunes).
5. **Sonido**: el silbato de VCSL (CC0) en `audio/ui/silbato.ogg`, que ya está soportado. Los clics y ambientes del Oculus Pack van con crédito (CC BY 4.0).
6. **Iconos**: Tabler + Lucide.
7. **Datos**: CLDR (países traducidos), Natural Earth y GeoNames (ciudades), faker (bolsas de nombres).
8. **Mejoras baratas**: Antialiased Line2D, Debug Menu, Foam Water, Sky3D.
9. **Música**: muestras CC0 de Meta Piano dentro de `musica.gd`. Va fuera de `audio/ui/`: preguntar al dueño por LFS.

**Todo lo CC BY** (Oculus Pack, GeoNames, game-icons, voces Piper CC BY) exige **la pantalla de créditos** pendiente en `docs/05_referencia/LICENCIAS.md` («Pendiente antes de vender», punto 4).

## Lo que no se pudo ver

- **Red**:
  - La API REST de GitHub (`api.github.com`, 403) y `mcp__github__get_file_contents` (limitado a `thekion11/dinastia`). Se usaron `git ls-remote`, `git clone --filter=blob:none` + `ls-tree` y raw.
  - Hugging Face y las páginas de Releases de GitHub (bloqueados): los `MODEL_CARD` de las voces Piper, los pesos de Kokoro y MeloTTS y los `.ttf` de DSEG.
  - Docker Hub (la imagen de godot-ci).
  - OpenGameArt, Poly Haven, ambientCG, Poly Pizza, itch.io y Freesound.
- **Sin probar**: Sky3D en Compatibility; COLRv1 y CBDT en Godot 4.7.
- **Licencias sin leer**: las muestras de `midi-js-soundfonts`, cada tema de SoundSafari y cada modelo de la carpeta de variantes de Mesh2Motion.
- **Búsquedas en GitHub sin resultados útiles**: estadios, porterías, hinchada, cánticos, red, golpe de balón y nombres de censo. La búsqueda de repos es muy literal; se probaron unas 15 consultas.

## Fuentes

Las licencias se leyeron en `raw.githubusercontent.com` de cada repositorio citado, en el archivo que indica cada tabla. Además:

**Animación y 3D**
- https://github.com/scottpetrovic/mesh2motion-app (README, `LICENSE-CC0.MD`, `src/lib/VariationLicenseInfo.ts`)
- https://github.com/una-dinosauria/cmu-mocap (`READMEFIRST.txt`, `cmu-mocap-index-text.txt`)
- https://github.com/makehumancommunity/mpfb2 (`LICENSE.md` §C y §D)
- https://github.com/BandaiNamcoResearchInc/Bandai-Namco-Research-Motiondataset
- https://github.com/ubisoft/ubisoft-laforge-animation-dataset

**Voz**
- https://github.com/444sofiane/Batch-tts-generator/blob/main/PIPER_VOICE_LICENSES.md
- https://raw.githubusercontent.com/rhasspy/piper/master/VOICES.md

**Asset Library de Godot y buscador**
- https://godotengine.org/asset-library/asset/683
- https://godotengine.org/asset-library/asset/5528
- https://quaternius.itch.io/universal-animation-library
- https://opengameart.org/content/free-crowd-cheering-sounds
- https://dleom.itch.io/3d-soccer-ball

**Código propio revisado con grep:**
- `visor/city_builder*.gd`, `visor/stadium_builder_p5.gd`/`p6.gd`, `visor/persona_realista.gd`, `visor/retarget_futbol_q.gd`, `visor/anim_quaternius_p1.gd`, `visor/hinchada.gdshader`
- `herramientas/hornear_publico.gd`, `nucleo/sonido.gd`, `nucleo/musica.gd`
- `ui/principal_p2.gd`, `ui/componentes/*`, `project.godot`, `docs/05_referencia/LICENCIAS.md`
