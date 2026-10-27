# Los «regalitos» de Drive (27-10-2026)

Carpeta de Drive con 11 archivos subidos el 27-10 a las 00:29 (propietario de los archivos en Drive: `dream.brock.11@gmail.com`).
**Ninguno trae licencia ni autor** dentro del propio archivo, y la carpeta no incluye LEEME de origen (el único `.md`,
`LEEME_respaldo.md`, es la nota de respaldo del 24-10, no un regalo). Regla aplicada: **sin licencia clara no se usa**.
No se ha subido ningún binario al repositorio.

## Qué se pudo descargar
El conector de Drive devuelve el contenido en base64 dentro del mensaje y el servidor cierra la conexión cuando el archivo pasa de
unos pocos MB; la descarga directa (`drive.usercontent.google.com`) responde «Google Drive: Sign-in» porque los archivos **no están
compartidos** «con cualquiera que tenga el enlace». Resultado:

| Descargado | No descargado (por tamaño y permisos) |
|---|---|
| `gold+trophy.glb` (157 KB), `gold+trophy.fbx` (117 KB), `LEEME_respaldo.md` (748 B) | los otros 8 (6,8 MB en adelante) |

**Para poder evaluar el resto:** en Drive, «Compartir → Cualquier persona con el enlace → Lector» en la carpeta. Con eso se bajan con
`curl` en un minuto (la red de este entorno llega a `drive.usercontent.google.com`).

## Tabla
Lo marcado como *inferido* sale solo del nombre o del tamaño: no se ha abierto el archivo.

| Archivo | Tamaño | Formato | Licencia | Polígonos / texturas | Destino propuesto | Veredicto |
|---|---:|---|---|---|---|---|
| **gold+trophy.glb** | 157 KB | glTF 2.0 (Blender I/O 4.4.55) | **desconocida** | **2.132 triángulos** (3 copas de ~710), 1 material, textura PNG 128×128 dorada; sin animaciones ni esqueleto; cada copa 0,43 × 0,63 × 0,30 m | Museo del club (`SalasClub.museo` → `copa`) | **Usar si el dueño confirma autoría/licencia** (ver prototipo) |
| **gold+trophy.fbx** | 117 KB | FBX binario | desconocida | La misma malla (2.132 triángulos, 3 copas), **sin textura** (gris 0,91) | — | Descartar: el `.glb` es lo mismo y trae la textura |
| Chair.glb | 64 MB | glTF | desconocida | no medido; **64 MB para una silla** apunta a una malla de escaneo o a texturas enormes (*inferido*) | despacho del DT (`PcOficina` / `CasaDT`) | No evaluable. Con ese peso, solo servirá **si se reduce mucho** (convertir/decimar): hay una silla en `muebles/` |
| grass.blend | 14 MB | Blender | desconocida | no medido | césped del estadio (`StadiumBuilder`) | No evaluable: `.blend` **no se importa sin Blender**. El césped del juego es un shader propio (`cesped.gdshader`, con capas de volumen) |
| stadium_light.blend | 21 MB | Blender | desconocida | no medido | focos del estadio | No evaluable sin Blender; los focos ya existen en `StadiumBuilder` |
| TV+Room+by+Deline.3DS | 23 MB | 3DS (formato antiguo) | desconocida | no medido | casa del DT | No evaluable: Godot no importa `.3DS` sin conversión |
| nv+toufa.obj | 123 MB | OBJ | desconocida | no medido; **123 MB de OBJ** son varios millones de vértices (*inferido*) | por determinar (no se sabe qué es) | No evaluable; casi seguro inutilizable por peso |
| Claw_Machine_Free_glb.zip | 9,5 MB | zip con glb | desconocida (el nombre dice «Free», que no es una licencia) | no medido | centro comercial / sala de minijuegos | No evaluable: el zip puede traer su licencia |
| Realistic+Male+3D+Character+Model.zip | 183 MB | zip | desconocida | no medido; 183 MB indica un modelo de alta resolución (*inferido*) | ¿cuerpo base de los personajes? | Casi seguro **descartar**: el personaje del juego usa el rig de `quaternius`/UAL (65 huesos) y 183 MB no cabe en el presupuesto; habría que reasignar el esqueleto. Hay que ver la licencia |
| 3D_files_textures.zip | 6,8 MB | zip | desconocida | no medido | por determinar | No evaluable |
| LEEME_respaldo.md | 748 B | Markdown | — | — | — | Nota del 24-10 (respaldo del historial): no es un regalo |

## El trofeo, medido
- **Contenido del `.glb`:** tres nodos `gold_trophy1/2/3` (tres copas iguales en fila, a 0,6 m de separación, caja total 1,80 × 0,67 × 0,38 m),
  1 material PBR con la textura dorada (color medio RGB 226·205·125) y rugosidad 0,33, extensión `KHR_materials_sheen` (Godot la ignora).
  Generador: «Khronos glTF Blender I/O v4.4.55»; **no hay campo de autor ni de licencia** en `asset`/`extras`.
- **Godot 4.7.2 lo importa sin errores**, tanto el `.glb` como el `.fbx` (mismos 2.132 triángulos).
- **Presupuesto:** una copa ≈ 710 triángulos; un museo de 6 vitrinas ≈ 4.300. Despreciable frente a los ~0,7 M del partido.
- **Defecto:** el metal sale oscuro porque no hay entorno que reflejar y el `metallic` por defecto es 1: bajarlo a ~0,5 al instanciar.

## Prototipo en el museo (solo local; el modelo no se sube)
Guion `dinastia-godot/pruebas/ideas/f8_captura_museo_trofeo.tscn` (construye solo la sala del museo con `SalasClub.museo`; con
`TROFEO=/ruta/gold_trophy.glb` deja la malla de la copa central en `Engine.meta("proto_trofeo")`). Para la foto «después» se
modificó **localmente** `SalasClub.copa` para que use esa malla (escala 0,75, sobre la peana de siempre); ese cambio **se revirtió y no está
en el repositorio**. Forward+, 1280 × 720.

| Antes (copa procedimental) | Después (trofeo externo) |
|---|---|
| [museo_antes.jpg](capturas_regalos/museo_antes.jpg) | [museo_despues_trofeo.jpg](capturas_regalos/museo_despues_trofeo.jpg) |

Lectura: la copa del regalo tiene **asas y un perfil mucho más reconocibles** que la procedimental (cilindros y toros); con un
`metallic` más bajo se leería bien. Es una mejora clara y barata.

## Para integrarlo de verdad (si el dueño lo aprueba)
1. **Confirmar autoría y licencia** del trofeo (y de lo que se quiera usar del resto).
2. Excepción en `.gitattributes` para `assets/ciudad/…/trofeo.glb` (157 KB, **fuera de LFS**, como pidió la regla de LFS del 26-10).
3. En `SalasClub.copa`: cargar la malla una vez (caché estática), `metallic` ≈ 0,5, una copa por título; si falta el archivo, copa procedimental.
4. Captura antes/después con `f8_captura_museo_trofeo` y banco en verde. Estimación: **2 h**.
