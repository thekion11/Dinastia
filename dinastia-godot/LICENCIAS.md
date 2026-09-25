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

| Qué | Dónde | Estado |
|---|---|---|
| 1.547 fotos de caras de futbolistas reales (Wikidata/Commons; muchas son CC-BY-SA con atribución, algunas no libres, y todas tienen derechos de imagen de la persona) | `recursos/caras_reales/` | 🔴 excluido. Además, `Cara.foto_real()` no enseña ninguna foto con la base ficticia |
| 1.102 fotos de camisetas reales (escudo y patrocinadores de marca) | `../recursos/equipaciones/` (fuera del proyecto) | 🔴 solo se copian junto al `.exe` en la versión **completo**. Con la base ficticia `EQUIP_REAL` está vacía y nunca se usan |
| Modelo `futbolista_cr7.glb` y sus texturas (camiseta real del Al-Nassr, sin licencia conocida) | — | ✅ **borrado del proyecto** (25-9-2026), junto con su código (`Futbolista`, `AnimMixamo`, `Vestidor`). Los partidos y el presentador del sorteo usan el modelo Quaternius |

## 3. Modelos 3D y animaciones

| Qué | Dónde | Origen | Estado |
|---|---|---|---|
| Personajes, animaciones y skins | `assets/characters/Model`, `Animations`, `Skins` | Kenney "Animated Characters Protagonists" | 🟢 CC0 (`assets/characters/License.txt`) |
| Cuerpo de jugador | `assets/characters/quaternius/*.gltf` | Quaternius "Universal Base Characters" | 🟢 CC0 |
| Animaciones base | `assets/characters/quaternius/anims/UAL1_Standard.glb` | Quaternius "Universal Animation Library" | 🟢 CC0 (`_extraido_universal_animation_library/.../License.txt`) |
| Ropa del jugador | `assets/characters/quaternius/ropa/` | Quaternius "Modular Character Outfits - Fantasy" | 🟢 CC0 |
| Edificios, coches y comercio de la ciudad | `assets/ciudad/kenney_*` | Kenney City Kit / Car Kit | 🟢 CC0 |
| 21 animaciones de fútbol (mocap) | `assets/characters/quaternius/anims_futbol/` | "Free mocap pack 05: Soccer", Anderson Rohr (Gumroad) | 🟡 `LEEME.md` dice "uso comercial libre", pero el zip no trae licencia. **Guardar una captura de la página de Gumroad con los términos.** |
| Coches `coche1.fbx`, `coche2.fbx` | `assets/ciudad/` | Probablemente `recursos/modelos3d/gt-racing-2-montreal.zip` (Sketchfab). El nombre apunta a un modelo sacado de un juego comercial | 🔴 ya no se usan (el aparcamiento es solo Kenney) y están excluidos |
| `estadio.obj`, `farola.obj`, `vagabond.obj` (el velero) | `assets/ciudad/` | sin anotar | 🟡 confirmar |
| `complejo_residencial.glb` | `assets/ciudad/` | `recursos/modelos3d/3.zip` (Sketchfab, sin licencia en el zip). Varias texturas llevan nombre de foto de redes sociales | 🟡 confirmar en Sketchfab o reemplazar |
| `oficina_dt.glb` | `assets/ciudad/` | `interior-15-minimalist-panoramic-viem.zip` (Sketchfab) | 🟡 confirmar. Hoy no se usa (ver `city_builder.gd`) |
| `arco_entrada.glb` | `assets/ciudad/` | `recursos/modelos3d/entrada-jugadores/` (Sketchfab) | 🟡 confirmar |
| `persona_realista.glb` (escaneo de una persona: presentador del sorteo y mentores) | `assets/personas/` | `recursos/modelos3d/navy-jacket-portrait.zip` ("Navy Jacket Portrait", formato de descarga de Sketchfab, sin licencia dentro del zip). Es el modelo que el usuario dejó para el presentador | 🟡 confirmar la licencia en Sketchfab. Además es una persona real escaneada: comprobar que la licencia permite su uso en un juego comercial |
| `asientos_lod.glb` | `assets/ciudad/` | `normal_stadium_seats_v1...zip` | 🟡 confirmar |
| `podio_prensa.glb` | `assets/props/generado_ia/` | Generado con Meshy | 🟡 en plan de pago es tuyo; en plan gratis Meshy lo publica bajo CC BY 4.0 y **hay que acreditar**. Confirmar con qué plan se generó |

## 4. Escudos, texturas, sonido y tipografía

| Qué | Dónde | Estado |
|---|---|---|
| Escudos de club | generados por código (`ui/escudo.gd`) | 🟢 propio |
| 40 insignias especiales desbloqueables | `assets/escudos_especiales/` | 🟡 generadas en Canva a partir de referencias de estilo (no calcadas, ver `LEEME.md` 22-9). Los términos de Canva no permiten usar su contenido como **marca** propia; como insignias dentro del juego deberían ser válidas, pero conviene confirmarlo. Si se quitan de la exportación, `Escudo.textura_especial()` cae solo al escudo procedural |
| Referencias de Pinterest | `../Escudos especiales/` (fuera del proyecto) | 🔴 nunca entraron al juego. No usar |
| Texturas de la Tierra (globo) | `recursos/tierra/` | 🟡 muy probablemente NASA Blue Marble / Black Marble (dominio público). Anotar la fuente |
| 205 efectos de sonido y 6 piezas de música | sintetizados por código (`nucleo/sonido.gd`, `nucleo/musica.gd`) | 🟢 propio |
| Tipografía | fuente por defecto de Godot / fuentes del sistema | 🟢 |
| Caras de jugadores y DT | dibujadas por código (`ui/cara.gd`, `ui/cara_dt.gd`) | 🟢 propio |

## 5. Otros nombres propios

| Qué | Estado |
|---|---|
| Marcas de patrocinio (`MARCAS`), bancos, medios, periodistas, agentes | 🟢 inventadas desde el HTML |
| Proveedores de equipación | 🟢 desde esta tanda: "Ad1star", "P0mba" y "N1mbra" quedaban a una letra de Adidas, Puma y Nike. Ahora son "Astra Sport", "Salto" y "Nimbo" |
| "Fecha FIFA", "Compensación FIFA" en textos | 🟢 cambiados a "fecha internacional" / "federación internacional" |
| Rótulos del sorteo ("CHAMPIONS LEAGUE", "COPA LIBERTADORES") escritos en el código | 🟢 ahora salen de la tabla `CONFED` |

## Pendiente antes de vender

1. ~~Reemplazar `coche1.fbx`/`coche2.fbx` por coches Kenney~~ hecho el 25-9-2026.
2. Confirmar licencia o reemplazar los modelos 🟡 de Sketchfab (`complejo_residencial`, `arco_entrada`,
   `asientos_lod`) y los `.obj` sin origen anotado (`estadio`, `farola`, `vagabond`).
3. Guardar la prueba de licencia del mocap (Gumroad) y del podio (Meshy).
4. Añadir una pantalla de créditos: Kenney y Quaternius no lo exigen (CC0) pero lo agradecen;
   Meshy gratis y Wikimedia sí lo exigen si algo de eso llegara a publicarse.
