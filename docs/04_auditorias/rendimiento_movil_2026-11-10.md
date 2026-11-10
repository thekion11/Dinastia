# Rendimiento en móvil (GPU): mediciones y primer recorte — 10-11-2026

Encargo del líder (brecha n.º 2 frente al PES 2020): en el teléfono del dueño la GPU iba al 100 % y la CPU al 0 % (5 FPS en MEDIA, meta 60; `PRUEBA_DUENO_MOVIL_2026-11-03.md`).

## Método
`herramientas/hw_modesto.sh res://pruebas/medir_partido.tscn -- <nivel>` con `HW_DRIVER=opengl3` (Compatibilidad, el renderizador del móvil), 1280x720, 2 núcleos, cámara real de TV, partido corriendo. Tres clubes de tres países (regla del dueño de no medir con un solo equipo): **CHI** (club 0), **ESP** (club 5), **ENG** (club 8). Nuevos interruptores de la herramienta: `PAIS`, `CLUB`, `SIN_MSAA`, `SIN_OMNI`, `SIN_ENTORNO_FX` (además de `OCULTAR_GRUPOS`, `PARTES`, `DETALLE`, `SIN_GENTE_FUERA`, que ya existían).
**Cómo leer las cifras:** llamadas de dibujo, triángulos y memoria de vídeo no dependen de la máquina. El «fotograma» es el de llvmpipe (rasterizador por software): no vale como FPS absoluto, pero con la MISMA resolución y la MISMA máquina es un indicador razonable del trabajo de relleno/sombreado (la parte que limita a una GPU de móvil); el ruido de una repetición es de ~5 % (ULTRA BAJA, con poco trabajo por fotograma, llega a ~15 %).

## Línea base (antes)
| Club | Nivel | Llamadas | Triángulos | Vídeo | Fotograma relativo |
|---|---|---|---|---|---|
| CHI | ULTRA BAJA | 260 | 378 k | 135 MB | 190 ms |
| CHI | BAJA | 314 | 615 k | 176 MB | 776 ms |
| CHI | MEDIA | 429 | 763 k | 203 MB | 1409 ms |
| ESP | ULTRA BAJA | 244 | 254 k | 176 MB | 146 ms |
| ESP | BAJA | 305 | 416 k | 212 MB | 579 ms |
| ESP | MEDIA | 489 | 540 k | 238 MB | 1087 ms |
| ENG | ULTRA BAJA | 198 | 234 k | 150 MB | 193 ms |
| ENG | BAJA | 249 | 367 k | 187 MB | 594 ms |
| ENG | MEDIA | 349 | 535 k | 214 MB | 1186 ms |

## Qué pesa más (BAJA, CHI; fotograma relativo, base 776-789 ms)
| Experimento | Fotograma | Efecto |
|---|---|---|
| **sin MSAA x2** | **313 ms** | **−60 %** |
| sin luces omni (26 de túneles y edificio del club) | 817 ms | nada |
| sin glow/niebla/ajuste de color/SSAO | 839 ms | nada |
| sin gente fuera del campo | 802 ms | nada |
| sin hinchas (MultiMesh) | 773 ms | −2 % (−135 k triángulos) |
| sin butacas | 683 ms | −12 % (−230 k triángulos) |
| sin jugadores ni pelo | 709 ms | −9 % (−35 llamadas) |
Confirmado también en MEDIA (CHI 1446 → 472 ms, −67 %; ESP 1087 → 400 ms, −63 %) y BAJA en ESP (579 → 247 ms, −57 %) y ENG (594 → 247 ms, −58 %).
Desglose por grupos en ULTRA BAJA (CHI, llamadas que quitaría cada grupo): hinchas 157, jugadores 155, pelo 136, resto de MultiMesh 100, MultiMesh sin nombre 92, ojos y cejas 81 (por solo 5,5 k triángulos), focos 55, fundidos 64. Los grupos se solapan.

## Cambio hecho (rama `sesion5-cpp`, commit «Calidad: BAJA y MEDIA BAJA sin MSAA…»)
`Calidad.msaa_activo(nivel)` (`visor/calidad.gd`): **ULTRA BAJA, BAJA y MEDIA BAJA sin MSAA** (en ULTRA BAJA ya lo estaba, decisión del dueño A4-PARTIDO-R01); **MEDIA sin MSAA solo en Compatibilidad** (móvil y web); MEDIA en escritorio, MEDIA ALTA y superiores conservan el x2. Las vistas 3D secundarias (`msaa_ui`) siguen la misma regla. Coste visual, dicho: bordes más dentados (líneas finas del campo y siluetas lejanas) en esos niveles. Pruebas del banco en `pruebas/banco/ideas_p2.gd` (BAJA y MEDIA BAJA sin MSAA; ALTA con x2; MEDIA según renderizador). Banco: FIN. 0 fallos.

## Después (mismo método)
| Club | Nivel | Llamadas | Triángulos | Vídeo | Fotograma relativo | Cambio |
|---|---|---|---|---|---|---|
| CHI | ULTRA BAJA | 258 | 377 k | 135 MB | 187 ms | = |
| CHI | BAJA | 315 | 615 k | 169 MB | 273 ms | **−65 %** |
| CHI | MEDIA | 430 | 762 k | 189 MB | 432 ms | **−69 %** |
| ESP | ULTRA BAJA | 245 | 254 k | 176 MB | 142 ms | = |
| ESP | BAJA | 305 | 416 k | 205 MB | 241 ms | **−58 %** |
| ESP | MEDIA | 489 | 540 k | 224 MB | 384 ms | **−65 %** |
| ENG | ULTRA BAJA | 203 | 239 k | 150 MB | 173 ms | = (ruido) |
| ENG | BAJA | 250 | 367 k | 180 MB | 241 ms | **−59 %** |
| ENG | MEDIA | 349 | 534 k | 200 MB | 396 ms | **−67 %** |
Memoria de vídeo: −7 a −14 MB en BAJA/MEDIA (el búfer multimuestra). Los escalones siguen siendo monótonos en llamadas, triángulos y fotograma (ULTRA BAJA < BAJA < MEDIA en los tres clubes).

## Lo que NO se hizo (y por qué) / siguiente
- **La meta de ULTRA BAJA (< 130 llamadas) NO se cumple**: 198-260. No se ha recortado nada más porque lo que quita llamadas es visual y hay que decidirlo: ojos y cejas de los jugadores lejanos (81 llamadas), pelo (136), hinchas (157 llamadas / 135 k triángulos) y butacas lejanas (230 k triángulos, −12 % de fotograma). Propuesta para el dueño: en ULTRA BAJA, sin ojos/cejas/pestañas a más de 12 m de la cámara; hinchas y butacas lejanas como una sola malla por grada con menos detalle. Se aplica cuando lo apruebe el dueño (regla: no quitar nada sin decirlo).
- Luces omni, post-proceso y gente fuera del campo no pesan en este banco: no se tocan.
- Falta medir en el teléfono del dueño (Compatibilidad real, GPU móvil): llvmpipe no es una GPU de móvil; sobre todo MSAA en GPUs de teselas (resolución en memoria de tesela) podría pesar menos que aquí. La «Prueba de rendimiento» de Ajustes mide cada escala con y sin MSAA en el propio teléfono: con su informe se confirma o se revierte para MEDIA.
- Texto de Ajustes: la frase de ULTRA BAJA dice «sin sombras ni suavizado»; BAJA y MEDIA BAJA (y MEDIA en móvil) ahora tampoco suavizan: ajustar la frase de cada nivel (`Idiomas.t` + `sumar_traducciones.py`) cuando el selector de 7 niveles se termine (paso 3 de `calidad_7_niveles_2026-11-06.md`, sesión que lo lleva).
