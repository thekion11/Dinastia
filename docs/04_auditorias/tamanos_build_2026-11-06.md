# Tamaños de build por plataforma y peso de los recursos (6-11-2026) — SOLO INFORME, no se borró nada

Medido en la corrida completa de `compilar.yml` del commit `cdd10830` (rama `sonar/plataformas2`, run 42113966172). Los tamaños de la tabla son los del
ARTEFACTO subido a GitHub (zip comprimido), no del paquete descomprimido.

| Versión | Artefacto (zip) | Notas |
|---|---|---|
| Windows | 321,7 MB | `.exe` + `.pck` + `.dll` de la extensión C++ |
| Windows ligero | 321,3 MB | casi igual que el normal: en el tamaño no se nota diferencia (qué cambia exactamente el preset `WindowsLigero` respecto a `Windows` no se ha revisado aquí) |
| Linux | 311,3 MB | |
| Android (arm64) | 313,5 MB | APK de depuración |
| Android armv7 | 316,8 MB | |
| Web | 292,3 MB | descomprimido: `index.pck` 338,0 MB + `index.wasm` 39,5 MB (medido en el humo de Web) |

Todas las versiones pesan entre 290 y 320 MB comprimidas: el peso lo marca el **paquete de recursos**, no el motor ni el código.

## Dónde está el peso en el proyecto (carpetas, descomprimidas, tras `git lfs pull`)
| Carpeta | MB | Va a los builds públicos |
|---|---|---|
| `assets/` | 394 | sí (menos lo que excluye cada preset) |
| · `assets/characters/` | 220 (de ellos `quaternius/` 142, `kaykit/` 36, `modular/` 18, `outfits/` 14, `vrm/` 9) | sí |
| · `assets/ciudad/` | 60 | sí (Web excluye `complejo_residencial*`, `farola.*`, coches `.fbx`…) |
| · `assets/personas/` | 40 (`persona_realista.glb` 24 MB) | sí |
| · `assets/kenney/` | 34 | sí |
| `recursos/` | 230 (`caras_reales*` ≈ 228) | **NO** (los presets las excluyen: viajan en `caras_reales.pck`, que no se publica) |
| `terceros/` | 65 | NO (`.gdignore`, respaldo) |
| `datos/` | 20 (`caras_reales_mallas.json` 10 MB) | los `caras_reales_*` y `pack_real.json` se excluyen en Web |

Archivos individuales > 8 MB en el proyecto: `persona_realista.glb` (24), `complejo_residencial.glb` (18; excluido de Web), `T_Peasant_Normal.png` (13),
`caras_reales_mallas.json` (10; excluido en Web), `arco_entrada.glb` (9), `T_Peasant_ORM.png` (9).

## Lo que NO se ha medido (y haría falta para recortar con criterio)
- El desglose DENTRO del `.pck` por recurso (qué ocupa cada textura/modelo ya importado y comprimido). Con Godot: `--export-pack` + listar el contenido del pck.
- Si `quaternius/` (142 MB) trae variantes que ningún personaje usa: cruzar con `docs/04_auditorias/recursos_sin_usar.md` (inventario del 27-10).
- La compresión de texturas por plataforma (`vram_texture_compression` está activa para escritorio en Web; móvil/Android no se ha revisado aquí).

## Siguientes pasos posibles (necesitan OK del dueño: tocarían qué lleva cada build)
1. Medir el `.pck` por recurso y cruzarlo con `recursos_sin_usar.md`; listar candidatos a excluir de los presets.
2. Revisar `T_Peasant_*.png` (22 MB entre dos texturas): comprobar resolución y compresión.
3. Valorar un build «ligero» de verdad (sin `persona_realista`, ciudad reducida) para equipos modestos: hoy el «Windows ligero» pesa lo mismo.
