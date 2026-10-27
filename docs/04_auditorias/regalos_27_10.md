# Los «regalitos» de Drive (27-10-2026)

Carpeta de Drive con 11 archivos subidos el 27-10 (propietario en Drive: `dream.brock.11@gmail.com`).
**Licencia: libre y gratuita, confirmada por el dueño el 27-10.** Ningún archivo trae licencia ni autor dentro (los zips no
llevan LEEME; el glb del trofeo no tiene campo de autor), así que la confirmación del dueño es la única referencia de licencia.
`LEEME_respaldo.md` no es un regalo (nota de respaldo del 24-10). Los 11 archivos se bajaron con `curl` (carpeta compartida) y se
midieron con Godot 4.7.2; **no se ha subido ningún zip ni binario >1 MB al repositorio**.

## Tabla (todo medido)
| Archivo | Tamaño | Contenido medido | Destino | Veredicto |
|---|---:|---|---|---|
| **gold+trophy.glb** | 157 KB | 3 copas iguales (2.132 triángulos, ~710 por copa), 1 material, textura 128×128, copa 0,43 × 0,63 × 0,30 m | Museo del club | **INTEGRADA** (una copa, `assets/ciudad/trofeo.glb`, 52 KB, ver abajo) |
| gold+trophy.fbx | 117 KB | la misma malla sin textura | — | Descartado: duplicado del glb |
| Chair.glb | 64 MB | 117.744 triángulos, 3 materiales, texturas **4096²**, 0,63 × 0,98 × 0,59 m | despacho del DT | Útil pero hay que decimar en Blender (dueño): 117 k triángulos y 4 k de textura no caben (hay una silla en `muebles/`) |
| Claw_Machine_Free_glb.zip | 9,5 MB | 19 glb: máquina `Toy_Claw_01` (11.825 triángulos, 21 mallas, 7 materiales, texturas 2048², 1,35 × 2,98 × 1,2 m), 14 peluches (≈1–2 k triángulos, 1024², ~550 KB cada uno) y 4 `ColorSet` (84 triángulos, 2048²) | centro comercial / sala de juegos | **INTEGRADA (c)**: `Toy_Claw_01` re-exportada con Godot (texturas 256 px, **893 KB**, `assets/ciudad/maquina_peluches.glb`), 7 máquinas ante la fachada del centro comercial (`CiudadArcade`). Los peluches y `ColorSet` no se usan |
| grass.blend | 14 MB | Blender ≥3.0 (zstd) | césped del estadio | Solo anotado: no se importa sin Blender; el césped del juego es shader propio |
| stadium_light.blend | 21 MB | Blender ≥3.0 (zstd) | focos del estadio | Solo anotado: sin Blender; los focos ya existen en `StadiumBuilder` |
| TV+Room+by+Deline.3DS | 23 MB | 3DS válido, formato antiguo | casa del DT | Solo anotado: Godot no importa `.3DS`; habría que convertirlo en Blender (dueño) |
| nv+toufa.obj | 123 MB | **739.891 vértices / 757.651 triángulos**, 105 superficies, sin materiales (falta `nv toufa.mtl`), caja 745 × 451 × 40 | por determinar | No usar: pesa y no se sabe qué es (¿maqueta o plano a escala de ciudad?) |
| 3D_files_textures.zip | 6,8 MB | `books_and_mugs.obj` (49.844 triángulos, sin `.mtl`, caja 17,8 × 10,3 × 26,6) + 8 JPG de textura (**2.jpg y 3.jpg están en CMYK**: Godot no los carga) + `.max` | libros/tazas del despacho | Útil pero hay que decimar en Blender (dueño); 50 k triángulos para unas tazas es excesivo |
| Realistic+Male+3D+Character+Model.zip | 183 MB | Exportación de Reallusion: FBX de 28 MB (**485.122 triángulos**, 101 huesos, 2 animaciones), FBX con rig de 44 MB, `.iAvatar` 104 MB, `.blend` 34 MB, difusa 9,4 MB y normal 7,6 MB (4 k) | cuerpo de jugador | **No usar** (solo anotado): 485 k triángulos frente a un presupuesto de ~0,7 M para todo el partido, y el esqueleto de 101 huesos no es el del juego (65, UAL) |
| LEEME_respaldo.md | 748 B | nota del 24-10 | — | No es un regalo |

## El trofeo, integrado
- `dinastia-godot/assets/ciudad/trofeo.glb` (52 KB, **fuera de LFS** con excepción en `.gitattributes`, como los sonidos de UI): una sola
  copa, extraída del nodo `gold_trophy1` y reexportada con `GLTFDocument` (más `trofeo_*.png`, 1,5 KB, la textura que Godot extrae).
- `SalasClub.copa` la carga **una vez** (caché estática), con `metallic` 0,5 (el metal pleno sale negro sin entorno que reflejar), a
  escala 0,75 sobre la peana de siempre; una copa por título. **Si falta el archivo, vuelve a la copa procedimental.**
- Presupuesto: ~710 triángulos por copa, 6 vitrinas ≈ 4.300; despreciable.
- Antes (copa procedimental) y después (trofeo), cámara del paseo, Forward+, vía `pruebas/ideas/f8_captura_museo_trofeo.tscn`:

| Antes | Después |
|---|---|
| [museo_antes.jpg](capturas_regalos/museo_antes.jpg) | [museo_despues_trofeo.jpg](capturas_regalos/museo_despues_trofeo.jpg) |

## La máquina de peluches, integrada
Re-exportada con `GLTFDocument` (texturas a 256 px: con 512 pesaba 1,5 MB; con 256, 893 KB < 1 MB). `CiudadArcade.montar` la instancia entera
(21 mallas), 7 unidades de 2,8 m, a 2,2 m de la fachada de vidrio. Se ve mejor de cerca; desde la calle son pequeñas frente a una fachada de
16 m (la fachada del centro comercial sigue siendo un P1 de la auditoría de la ciudad). Capturas: [pie](capturas_regalos/centro_comercial_maquinas_pie.jpg) · [aérea](capturas_regalos/centro_comercial_maquinas_aerea.jpg).
Herramienta: `f6c_captura_ciudad` admite ahora `LADO=sur` y `DIST=<m>` para la toma a pie.

## Pendiente del dueño (Blender)
Decimar `Chair.glb` (a <10 k triángulos y texturas ≤1024), `books_and_mugs.obj`, y convertir `grass.blend`, `stadium_light.blend` y
`TV_Room.3DS` a glb si se quieren usar. El zip del personaje masculino y `nv_toufa.obj` no se usarán.
