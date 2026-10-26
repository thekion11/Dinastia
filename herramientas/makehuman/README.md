# Convertidor MakeHuman → modelo de persona del juego (opción B)

Genera, por código, el modelo de persona para DT y personajes: la malla base de MakeHuman,
re-posada al esqueleto Quaternius de 65 huesos del juego, más piel, pelo, cejas, pestañas y ropa.
Todo eso son recursos propios que crea el código. Aquí solo hay **código y texto**: no se suben
ni los .glb ni los datos de MakeHuman.

## Origen de los datos y licencia

| Dato | De dónde sale | Licencia |
|---|---|---|
| Malla base `makehuman/data/3dobjs/base.obj` | https://github.com/makehumancommunity/makehuman, commit `a8bc2d54ff0ac92e78ff71431b1023eda42bf482` (26-06-2024) | CC0 1.0 |
| Rig `makehuman/data/rigs/default.mhskel` y pesos `default_weights.mhw` | mismo repositorio y commit | CC0 1.0 (`"license": "CC0"` dentro del .mhw) |
| Targets (morphs) `makehuman/data/targets/{macrodetails,head,nose,eyebrows,mouth,ears,stomach,chin,cheek}` | mismo repositorio y commit | CC0 1.0 (cabecera de cada `.target`: «explicitly released as CC0 in september 2020») |

Licencia leída en `LICENSE.ASSETS.md` de ese repositorio: *Creative Commons CC0 1.0 Universal*. Permite
el uso comercial y no pide atribución. Aun así, conviene citar «MakeHuman (CC0)» en los créditos.

**Esqueleto de destino:** Quaternius «Universal Base Characters», versión gratuita (CC0 1.0; texto en
`dinastia-godot/assets/characters/quaternius/pelo/License.txt`). El archivo que se lee es
`dinastia-godot/assets/characters/quaternius/Superhero_Male_FullBody.gltf`, exportado con
«Khronos glTF Blender I/O v4.3.47» y fijado en el repo en el commit `bcd27d93a7e39ba0b7688e35965b80b65d548f5a`.
Del .gltf solo se leen los nombres, la jerarquía y el reposo de los huesos. Los clips UAL
(`anims/UAL1_Standard.glb`) usan ese mismo esqueleto, así que funcionan sin retargeting.

## Bajar los datos (clon parcial, unos 120 MB)

```bash
D=/tmp/mh   # fuera del repo
git clone --depth 1 --filter=blob:none --sparse https://github.com/makehumancommunity/makehuman "$D"
cd "$D"
git checkout a8bc2d54ff0ac92e78ff71431b1023eda42bf482   # opcional: fija el commit documentado
git sparse-checkout set makehuman/data/3dobjs makehuman/data/rigs \
  makehuman/data/targets/macrodetails makehuman/data/targets/head makehuman/data/targets/nose \
  makehuman/data/targets/eyebrows makehuman/data/targets/mouth makehuman/data/targets/ears \
  makehuman/data/targets/stomach makehuman/data/targets/chin makehuman/data/targets/cheek
```

Son datos, no código. El convertidor solo lee `.obj`, `.json` y `.target`, y no ejecuta nada del clon.

## Regenerar los modelos

Requisitos: Python 3, numpy y Pillow.

```bash
cd herramientas/makehuman
Q=../../dinastia-godot/assets/characters/quaternius/Superhero_Male_FullBody.gltf
python3 -I mh_generar.py /tmp/mh/makehuman/data "$Q" /tmp/salida/dt_mh5m m   # hombre
python3 -I mh_generar.py /tmp/mh/makehuman/data "$Q" /tmp/salida/dt_mh5f f   # mujer
```

Cada llamada escribe `<base>_cuerpo.glb` (cuerpo, ojos, cejas, pestañas, pelo y morphs) y `<base>_ropa.glb`
(prendas sobre el mismo esqueleto: en Godot, sus MeshInstance3D se re-cuelgan del Skeleton3D del cuerpo).
Peso medido el 26-10: hombre, 4,9 MB de cuerpo y 5,7 MB de ropa; mujer, 7,8 MB de cuerpo y 5,7 MB de ropa. Tarda entre 1 y 2 minutos por modelo. Los .glb van por LFS
(`.gitattributes`), y desde el contenedor las subidas a LFS fallan: o los sube el dueño, o se
regeneran con este script.

## Archivos

| Archivo | Qué hace |
|---|---|
| `mh_generar.py` | Programa principal: arma las piezas y escribe los .glb. |
| `mh_base.py` | Carga MakeHuman, aplica los macro-morphs (sexo, edad, peso, músculo, barriga), re-posa al esqueleto Quaternius (con largos de pierna Quaternius y dedos alineados) y reparte los pesos. |
| `mh_glb.py` | Escritor glTF binario: skin, morphs dispersos y texturas PNG/JPG. |
| `mh_tex.py` | Rasterizado en espacio UV, ruido, UV esférica de la cabeza. |
| `mh_recursos.py` | Tonos (paleta `PIELES` del juego), multiplicador de piel, cejas y pestañas. |
| `mh_piezas.py` | Zonas del cuerpo ocultables, atlas de la cabeza, atlas del cuerpo con uñas, pelo. |
| `mh_loft.py` | Medidas del cuerpo y «loft» de anillos para la ropa, con piel-ado por vecinos. |
| `mh_trajes.py` | Funciones comunes de las prendas y zapatos con forma. |
| `mh_trajes2.py` | Prendas actuales: camisa, corbata, chaqueta y abrigo (abiertos con solapas, sisa de verdad), pantalón por perneras, polo. |
| `mh_casco.py` | Anillos por envolvente convexa, caída desde el pecho, sisas y mangas que nacen de la sisa, perneras sin puente. |
| `mh_pelo_f.py` | Peinados largos y recogidos: media melena con capas y raya, coleta, moño. |

En Godot: el tono de piel va por `albedo_color` de los materiales `Piel*`, y el color de pelo por
`Pelo_*`. En los ojos hay que activar `vertex_color_use_as_albedo`. Al vestir, hay que ocultar
`Cuerpo_Torso`, `Cuerpo_Brazos`, `Cuerpo_Piernas` y `Cuerpo_Pies` según la prenda.
Maquillaje (solo mujer): mostrar `Cuerpo_Cabeza_maquillaje` y ocultar `Cuerpo_Cabeza`.
