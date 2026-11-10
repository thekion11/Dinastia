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

## El club a pie (`pruebas/medir_club.tscn`, nuevo; 10-11)
Abre el estadio propio, entra en el recorrido a pie (`ExploradorEstadio`) y mide en 15 puntos: la salida, el centro de 3 salas por planta (plantas -2, -1, 1 y 2), el vestuario, el túnel y el campo. ULTRA BAJA, Compatibilidad, 1280x720.
**Hallazgo:** el club a pie pedía ~860-960 llamadas y 0,86-1,26 M de triángulos desde CUALQUIER sala (el partido: 200-260 y 234-378 k), porque no hay oclusión: la cámara dibujaba también las gradas, la hinchada, las torres de focos y el entorno que quedan DETRÁS de las paredes. Ocultar plantas del edificio no ahorraba nada (el coste no era el edificio); ocultar el estadio de fuera sí.
**Cambio hecho:** `OcultarEstadioDentro` (`visor/ocultar_estadio_dentro.gd`, llamado desde `ExploradorEstadio._rotulos`): en las plantas distintas de la 0 se ocultan los hijos de primer nivel del estadio que no son luces, cámara, el edificio (`TunelVestuario`), la calle (`Exterior`) ni la fachada; se devuelve tal cual al volver a la planta 0 o cerrar el recorrido (lo que ya estaba oculto sigue oculto). Prueba en el banco (`_probar_ocultar_estadio_dentro`). Capturas con la cámara real del recorrido (sala de prensa, oficina del DT): idénticas antes y después. Lo único que deja de verse es el entorno lejano por la ventana trasera (se ve la calle y la fachada).
| Club | Antes (media de 15 puntos) | Después (media de 15 puntos) | Cambio |
|---|---|---|---|
| CHI | 957 llamadas · 1,20 M tri · 269 ms | 455 · 358 k · 142 ms | −52 % llamadas · −70 % tri · −47 % fotograma |
| ESP | 870 · 858 k · 232 ms | 405 · 277 k · 133 ms | −53 % · −68 % · −43 % |
| ENG | 963 · 1,26 M · 282 ms | 454 · 361 k · 134 ms | −53 % · −71 % · −52 % |
Solo en las plantas ≠ 0 (CHI): ~850 → 335-405 llamadas, 1,1 M → 125-150 k triángulos, ~285 → ~105-120 ms (−60 %). Las puntos de la planta 0 (salida, vestuario, túnel, campo) no cambian: 350-960 llamadas.
**Pendiente (club):** (1) la planta 0 es lo que queda caro: el «Vestuario» (886 llamadas) es una sala cerrada como las demás y se podría tratar igual (hace falta que el dueño/sesión 7 confirme que no se ve el estadio por el túnel con la puerta abierta); (2) `TunelVestuario` (176 piezas) y `Exterior` (152) siguen siendo ~330 llamadas dentro de una sala: agruparlas por sala (oclusión por sala) es un cambio de la escena del club (sesión 7); (3) el club solo se midió en ULTRA BAJA: BAJA/MEDIA añaden MSAA (ya cubierto por el cambio de `Calidad`) y las sombras.

## El menú (`pruebas/zz_medir_menu_gpu.tscn`, ahora con `PAIS`, `CLUB` y nivel por argumento)
Pantalla central del menú con la partida de un club, Compatibilidad, 1280x720, pantalla quieta durante 3 s:
| Club | Nivel | Llamadas | Primitivas | Vídeo | Fotogramas dibujados en 3 s |
|---|---|---|---|---|---|
| CHI | ULTRA BAJA | 410 | 17,2 k | 36 MB | **1** (bajo consumo) |
| CHI | BAJA / MEDIA | 389 | 17,0 k | 36 / 54 MB | **51** |
| ESP | ULTRA BAJA | 407 | 16,9 k | 37 MB | **1** |
| ESP | BAJA / MEDIA | 408 | 17,0 k | 37 / 55 MB | **48 / 50** |
| ENG | ULTRA BAJA | 419 | 16,9 k | 38 MB | **1** |
| ENG | BAJA / MEDIA | 420 | 17,0 k | 38 / 57 MB | **48 / 46** |
**Hallazgo:** solo ULTRA BAJA activaba el modo de bajo consumo del menú (`AhorroMenu.toca()`): en BAJA, MEDIA BAJA y MEDIA el menú se repintaba entero (~400 llamadas) 46-51 veces cada 3 s con la pantalla quieta, en vez de 1.
**Cambio hecho:** `AhorroMenu.toca()` vale ahora hasta MEDIA BAJA (bajo consumo, motas y fondos con shader de `TIME` quietos, mientras no haya 3D a la vista). Después: BAJA y MEDIA BAJA, los 3 clubes: **1 fotograma en 3 s** (−98 %). Coste visual, dicho: en BAJA y MEDIA BAJA los fondos animados del menú y las motas van quietos. MEDIA y superiores no se tocan (decisión de diseño original); en móvil MEDIA se repinta igual: el dueño decide si MEDIA en móvil también (es lo que midió con 28 FPS en el menú).

## El partido en directo ya sin MSAA: lo siguiente que pesa (MEDIA, CHI, 1280x720; fotograma relativo, base 395-411 ms, 433 llamadas, 762 k triángulos)
| Experimento | Llamadas | Fotograma | Efecto |
|---|---|---|---|
| sin sombra solar (2 cortes) | 360 (−73) | 345 ms | **−13 a −17 %** |
| sin jugadores ni pelo | 375 | 366 ms | −11 % |
| sin gente fuera del campo (suplentes, cuerpo técnico, camarógrafos…) | 386 | 386 ms | −6 % |
| sin butacas | 417 | 396 ms | −4 % (−185 k tri) |
| sin focos / sin fundidos / sin coches | 432 / 402 / 432 | 396 / 393 / 401 ms | −3 a −4 % cada uno |
| sin hinchas (MultiMesh) | 429 | 407 ms | −1 % |
| piezas finas (ojos, cejas, pestañas, pelo) sin sombra proyectada | 431 | 410 ms | **nada** (ya no se descarta por menor) |
Lectura: tras quitar el MSAA el coste está repartido; lo único que destaca es la sombra solar (13-17 %), y es un efecto visible: se queda como propuesta para el dueño («MEDIA sin sombra en móvil» sería BAJA, que ya no la tiene; el escalón existe). Nada de lo medido se puede apagar sin que se note (hinchas, butacas, focos y coches son 1-4 % cada uno). Sin MSAA, la sombra y los personajes (22 + árbitros: ~150 llamadas) son el grueso; reducir personajes lejanos (impostores, menos huesos) es trabajo de la sesión de personajes. BAJA (sin sombra) ya está en 250-315 llamadas.
Recordatorio: llamadas, triángulos y vídeo son comparables entre máquinas; el fotograma de llvmpipe solo vale a igual resolución en esta máquina (una repetición de «sin efectos de entorno» dio 678 ms con un parón aislado de 31 s: se descartó).

## El arranque hasta el menú (2 núcleos, 4 GB, llvmpipe 1280x720; `.pck` exportado con scripts precompilados como el juego real)
Herramientas nuevas: `pruebas/medir_arranque.tscn` (portada) y `pruebas/medir_arranque_menu.tscn` (menú real «Continuar»: `principal.tscn` con un club). Con el `.pck`: `godot --export-pack "Windows" x.pck` (quitando `pruebas/*` del filtro de exclusión solo para medir) y `godot --main-pack x.pck res://pruebas/medir_arranque.tscn`.
| Qué | Desde fuentes (editor) | Con `.pck` precompilado |
|---|---|---|
| Motor + autoloads | 0,55-0,66 s | 0,53-0,56 s |
| Montar la portada (`inicio.tscn`) | 2,9-5,2 s | **1,75-1,90 s** |
| 1.er fotograma de la portada | 3,8-6,1 s | **2,5-2,8 s** |
| 30.º fotograma de la portada | 6,0-7,5 s | 4,6-4,7 s |
| Menú real: motor+autoloads (compila `Principal`) | — | ~2,0 s |
| Menú real: instanciar y montar `Principal` | — | 2,6-3,4 s |
| Menú real: generar mundo + tomar el mando + refrescar | — | 0,06-0,13 s |
| Menú real: 1.er fotograma | — | **6,9-8,8 s** |
Memoria: portada 219 MB estática (248 desde fuentes), vídeo 54 MB; menú real 372-374 MB.
**Dónde se va:** de `Inicio._ready` solo ~340 ms (`_construir` 307 ms); el resto es cargar y COMPILAR scripts (el análisis de `compilacion_menu_2026-11-03.md`: `Principal` arrastra 830 de 886 scripts) y, en el menú real, instanciar las 17 capas de `Principal`. Generar el mundo y refrescar es despreciable (0,1 s). Quedan 2-4 s entre «refrescar» y el 1.er fotograma que NO se pueden atribuir aquí (compilación de shaders de llvmpipe, hilos de `Precarga`/`RuidosFondo`/`CompilarFondo`): en un teléfono la compilación de shaders de la GPU es otra y solo se mide allí (la «Prueba de rendimiento» de Ajustes no mide el arranque: pendiente añadirlo).
**Propuesta (sin tocar nada aún):** (1) seguir con los cortes de familias del análisis del 3-11 (pantallas de gestión −38 MB y arranque más corto; ciudad 3D −105 MB: ahora que está apagada se corta con poco riesgo); (2) una pantalla de carga con barra mientras se instancia `Principal` (hoy el jugador ve la portada quieta 2-3 s); (3) medir el arranque en el teléfono del dueño (cronómetro en el log del primer fotograma: `Time.get_ticks_msec()` al `Inicio._ready` y al primer `frame_post_draw`).

## Lo que NO se hizo (y por qué) / siguiente
- **La meta de ULTRA BAJA (< 130 llamadas) NO se cumple**: 198-260. No se ha recortado nada más porque lo que quita llamadas es visual y hay que decidirlo: ojos y cejas de los jugadores lejanos (81 llamadas), pelo (136), hinchas (157 llamadas / 135 k triángulos) y butacas lejanas (230 k triángulos, −12 % de fotograma). Propuesta para el dueño: en ULTRA BAJA, sin ojos/cejas/pestañas a más de 12 m de la cámara; hinchas y butacas lejanas como una sola malla por grada con menos detalle. Se aplica cuando lo apruebe el dueño (regla: no quitar nada sin decirlo).
- Luces omni, post-proceso y gente fuera del campo no pesan en este banco: no se tocan.
- Falta medir en el teléfono del dueño (Compatibilidad real, GPU móvil): llvmpipe no es una GPU de móvil; sobre todo MSAA en GPUs de teselas (resolución en memoria de tesela) podría pesar menos que aquí. La «Prueba de rendimiento» de Ajustes mide cada escala con y sin MSAA en el propio teléfono: con su informe se confirma o se revierte para MEDIA.
- Texto de Ajustes: la frase de ULTRA BAJA dice «sin sombras ni suavizado»; BAJA y MEDIA BAJA (y MEDIA en móvil) ahora tampoco suavizan: ajustar la frase de cada nivel (`Idiomas.t` + `sumar_traducciones.py`) cuando el selector de 7 niveles se termine (paso 3 de `calidad_7_niveles_2026-11-06.md`, sesión que lo lleva).
