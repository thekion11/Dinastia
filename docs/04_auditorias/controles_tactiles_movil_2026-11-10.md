# Controles táctiles del partido en el teléfono: auditoría (10-11-2026)

Encargo de la líder (orden 26: el partido en MÓVIL es uno de los puntos más débiles). Sin tocar la IA del partido (F1-F8, del
dueño) ni la calibración del motor.

## Cómo se midió
`pruebas/captura_tactil_movil.tscn`: un teléfono de 400 ppp (6,5" a 2400×1080) en HORIZONTAL y en VERTICAL (1080×2400), tres
partidos de clubes y países distintos (`PARTIDO=0|1|2`: U. Penquista – Patronato SC (CHI), Isidro Casanova – Bolivar Buenos (ARG),
Africa Norte – Miranda Rojillo (ESP)). En cada uno, con balón, en la banda y sin balón:
- **Medidas:**
  - tamaño de cada botón en mm (Pase y Tiro ≥ 10 mm; el resto ≥ 7 mm, guías de Apple, Material y NN-g);
  - todos dentro de la pantalla;
  - ≥ 2 mm de borde a borde entre dos botones que se ven a la vez;
  - ningún botón encima de un texto o panel del HUD (se mide el texto de verdad, no su caja; se ignora lo desvanecido);
  - ≤ 3 % del tercio central tapado (en vertical, por encima de la franja de los pulgares, el 25 % de abajo).
- **Toques simulados:**
  - el stick responde al fotograma siguiente y el jugador se mueve;
  - Sprint corre;
  - Pase y Tiro se pulsan a la vez con otros dedos;
  - al levantar los dedos todo se suelta;
  - sin balón, Cambiar pide el cambio;
  - el II abre la pausa.
- **Fotos** (Forward+): `tactil_<orientación>_<partido>_<contexto>.jpg`.
Queda en `herramientas/especiales.sh` (horizontal ARG y vertical ESP, con opengl3 como el CI).

## Hallazgos (antes)
| | horizontal | vertical |
|---|---|---|
| Pase y Tiro | 15 mm, pero a **0,9 mm** uno de otro | 10,6 mm, a **0,7 mm** |
| Tiro y Centro/Barrida | **1,8 mm** | **1,3 mm** |
| Pase y Sprint / Cambiar y Sprint | 2,1 mm | **1,5 mm** |
| Solapes con el HUD | ninguno | **Sprint tapaba la ficha del jugador** (nombre y aguante) |
| Tercio central tapado | 0-0,5 % | 3,4-3,7 % (inevitable con 1.280 de ancho: es la franja de los pulgares) |
| Botón II de pausa | casi invisible sobre cielo y gradas | casi invisible |
| Toques | todos bien | todos bien |
Además, el modo ZURDO (arco a la izquierda) también habría quedado encima de la ficha del jugador, en horizontal.

## Arreglos (`ui/componentes/controles_tactiles.gd`)
- **Colocación rehecha:** ≥ 26 px del lienzo a escala 1 entre bordes, que es lo que pide el peor caso (vertical, 18,7 px/mm con
  escala 1,5). Ahora hay ≥ 2 mm entre todos los botones que se ven a la vez, en las dos orientaciones. Pase y Tiro siguen siendo
  los grandes y los de abajo.
- **El arco sube sobre la ficha:** si el arco se cruza en horizontal con la ficha del jugador (`_hud_abajo` del partido), sube por
  encima en vez de taparla. Pasa en vertical y con el modo zurdo; en horizontal diestro no cambia nada.
- **El II de pausa se ve:** letra mayor y fondo más opaco.
Resultado: **0 fallos en los 6 casos** (3 partidos × 2 orientaciones), 15 mm en horizontal y 10,6 mm en vertical para Pase y Tiro.
Siguen pasando `tac_controles`, `tac_hud`, `p6_mando_tactil` y `captura_tactil_partido`.

## Pendiente (no tocado: fuera del encargo o decisión de otro)
- En VERTICAL todo es más pequeño (10,6 mm) porque la escala tiene tope 1,5 y el arco tiene que caber en ~68 mm de ancho. El
  proyecto fija el móvil en horizontal (`window/handheld/orientation=0`), así que el vertical solo sale en navegador o tableta.
  ¿Quitamos el vertical del todo o hacemos un diseño propio para él? Es decisión del dueño.
- La ficha del jugador (abajo a la izquierda) ocupa ~43 % del ancho en horizontal y deja la mitad de abajo vacía. Encogerla daría
  más sitio al stick; es HUD, no controles.
- En vertical la cámara del partido queda muy cerca y el triángulo amarillo del jugador es enorme: es cámara, no controles.
