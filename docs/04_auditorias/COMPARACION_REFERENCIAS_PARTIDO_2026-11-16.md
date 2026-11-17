# Partido frente a las referencias del Drive (16-11)

Pedido del dueño (16-11): comparar el partido con las referencias del Drive y decir qué falta para llegar a ese nivel.
Referencias usadas (Drive `Dinastia_respaldo_2026-10-24/referencias_del_dueño`, NO van al repo): `FCMobile_mando_sin_balon_2026-11-11.jpg` y `FCMobile_mando_con_balon_2026-11-11.jpg`.
En el Drive no hay capturas del PARTIDO de PES 2020 (solo el menú central de la Liga Master); los vídeos de la carpeta padre (29-780 MB) no se pueden ver desde la nube.
Nuestra captura: `capturas_h1_animacion_2026-11-16/tv_bra_jpn_despues.jpg` (cámara real de TV, ULTRA, sin GPU). (17-11: en el repo solo quedan los pares `*_antes_despues.jpg` reducidos a 1280 px; las capturas sueltas originales siguen en el historial de git, commit d97e0502/9231fd63)

## Diferencias, de la que más se nota a la que menos

| # | Qué | FC Mobile | Dinastía hoy | Qué hacer |
|---|---|---|---|---|
| 1 | Cámara | Cerca y baja: el jugador ocupa ~1/8 del alto de la pantalla | Lejos y alta: el jugador ocupa ~1/15 (se ven «muñequitos») | Acercar la cámara de TV por defecto (altura y apertura) y dejar la lejana como opción; probarlo en el teléfono |
| 2 | Césped | Verde natural algo apagado, franjas de corte anchas, textura con variación | Verde saturado y liso, franjas muy suaves | Bajar saturación, franjas anchas marcadas, textura CC0 (ambientCG `Grass*`) mezclada con variación de tono |
| 3 | Luz y sombras | Luz de día suave, sombras cortas y difusas bajo los pies | Contraste fuerte y una sombra de tribuna enorme con borde duro sobre medio campo | Más luz ambiente, sombra de tribuna más suave o apagada en el césped, tonemap filmic/ACES, cielo HDRI CC0 (Poly Haven) |
| 4 | Lectura del juego | Nombre bajo el controlado y su marca, anillo bajo los pies, triángulo del siguiente | Indicador sencillo, sin nombres | Nombre del controlado y del rival más cercano, anillo con color del equipo |
| 5 | Marcador | Bloque con escudos, siglas y reloj, colores fuertes | Texto plano sobre fondo oscuro | Marcador tipo TV: escudos, siglas de 3 letras, reloj en su caja (fuente OFL del cap. 11) |
| 6 | Radar | Campo dibujado (líneas y áreas) semitransparente, iconos por equipo | Solo puntos de colores sin campo | Dibujar el campo en el radar y usar triángulo/círculo por equipo |
| 7 | Jugadores | Proporciones reales, dorsal y nombre legibles, botas de color | Bien a distancia; de cerca, poco detalle | Dorsal y nombre en la espalda legibles de lejos; animaciones Mixamo (aprobadas) para carrera, control y giro |
| 8 | Mando táctil | Botones redondos con anillo de color y etiqueta, palanca grande a la izquierda | Ya hay mando estilo FC (orden 39) | Comprobar en el teléfono el tamaño y los colores contra la referencia |

## Orden propuesto
1. Cámara más cercana (lo que más cambia la impresión, coste cero).
2. Césped y luz (franjas, saturación, sombra de tribuna, HDRI): un solo bloque con capturas antes/después de 3 clubes.
3. Marcador, nombres sobre el campo y radar (HUD de TV).
4. Animaciones Mixamo y dorsales.
Todo se mira con la cámara real y en MÍNIMA no puede costar más.

## Lo que falta del dueño
- Capturas del PARTIDO de PES 2020 (cámara de TV, de día y de noche) en `referencias_del_dueño`, para comparar también contra PES.
