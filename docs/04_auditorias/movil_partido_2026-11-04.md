# Modo «jugar partido» en móvil — controles táctiles (4-11-2026)

Orden del dueño: «mejora la posición y el estándar, basándote en las redes y Google; el tuyo está bastante mal».

## Qué estaba mal (captura a 1280×720 antes del cambio)
- Los seis botones estaban repartidos en una nube que subía hasta el 40 % de la pantalla (Sprint junto al campo, lejos del pulgar) y todos del mismo tamaño.
- La línea de ayuda de teclado («SIN BALÓN: Espacio contener…») seguía visible en el móvil: el partido la crea DESPUÉS de montar los controles, así que la orden de esconderla nunca se aplicaba.
- Tamaños en píxeles fijos del lienzo: en un móvil pequeño o de muchos píxeles el botón podía quedar por debajo de 1 cm; sin área segura (muescas) ni modo zurdo.
- La prueba táctil fallaba a 1920×1080 y 2400×1080 (mandaba posiciones del lienzo como si fueran de la ventana).

## Qué se hizo (`ui/componentes/controles_tactiles.gd`)
- Botones en ARCO alrededor del reposo del pulgar derecho (abajo a la derecha): Pase y Tiro grandes y abajo, Sprint a su izquierda, Al hueco / Centro / Cambiar más arriba y pequeños; nada en el 45 % superior (marcador y estadísticas).
- Colores de aro por botón (Pase azul, Tiro rojo, Centro amarillo, Al hueco verde), etiqueta con contorno legible, relleno suave; el stick flotante y translúcido nace solo en el 45 % izquierdo y por debajo del 20 % superior.
- Tamaño por puntos por pulgada en móvil (botón grande ≈1,5 cm de diámetro; guías: Apple 44 pt, Material 48 dp, NN/g 1 cm) y por altura del lienzo; ≥ 4 px entre botones; margen del 15 % alrededor de cada botón al pulsar (gana el más cercano).
- Área segura (`DisplayServer.get_display_safe_area`) para muescas y esquinas redondeadas.
- Modo zurdo espejado (`ControlesTactiles.zurdo`; falta el interruptor en Ajustes).
- La línea de ayuda de teclado se esconde siempre (se busca en cada fotograma).

## Pruebas
- `pruebas/ideas/tac_controles.gd` (en `especiales.sh`): caben y no se pisan en 1280×720, 1600×720 y 960×480; zona del pulgar; el stick no nace arriba; zurdo.
- `pruebas/captura_tactil_partido.gd`: pasa a 1280×720, 1920×1080 y 2400×1080 (convierte lienzo → ventana).

## Fuentes (orientativas)
Guías de tamaño de objetivo táctil (Apple 44 pt, Material 48 dp, NN/g 1 cm, Smashing Magazine «Finger-friendly design»), regla del pulgar de Josh Clark, patrón de juegos de fútbol de móvil (stick izquierdo flotante, acciones a la derecha, sprint mantenido).

## Unión con main (4-11-2026)
Main ya traía otra versión de los controles (PR #159 de la ejecutora: botón II de pausa, botón Mod y `AjustesTactil` con modo/tamaño/opacidad). Se combinaron: de main se conservan II, Mod, `AjustesTactil` (TAM_MIN, modo siempre/nunca/auto) y la ayuda de teclado escondida; de este trabajo, el arco del pulgar, el tamaño por dpi (× el tamaño de Ajustes, con tope para que el arco no suba del 35 % de arriba), el área segura, el stick flotante y el zurdo, que ahora se elige en Ajustes → Dispositivo (`AjustesTactil.zurdo`, traducido a los 8 idiomas). Pruebas: `tac_controles` (incluye zurdo y Ajustes), captura táctil a 1280×720 y 2400×1080, banco 0 fallos, líneas 0.

## HUD y cámara en el móvil (4-11-2026, segunda pasada; la primera dio el HUD por bueno sin medirlo)
La revisión de la líder (por orden del dueño) lo desmintió: a 2400×1080 y 400 ppp la letra de las estadísticas medía ≈1,6 mm, el jugador era un punto y el balón a veces no se veía. Ahora se MIDE:
- `ui/componentes/hud_tactil.gd`: con los controles táctiles puestos, el marcador, las estadísticas y la ficha del jugador crecen por los puntos por pulgada del aparato (factor 1-2) para que la letra más pequeña mida ≥ 2,5 mm y el marcador ≥ 3,2 mm, y se apartan de las muescas (área segura). Sin controles táctiles (PC) el factor es 1.
- `visor/camara_tactil.gd`: la cámara del partido va a 0,6 de la distancia de siempre y mira casi al jugador (peso del balón 0,12) cuando el balón está cerca de él; cuando el balón se aleja (14-30 m) pasa a seguir al balón (peso 0,9, distancia 0,95): con el balón a la espalda del jugador la cámara «detrás del jugador» de siempre no podía enseñarlo. Se elige en Ajustes → Dispositivo (Automático: cercana con controles táctiles; Siempre; Nunca = la de siempre).
- El stick en reposo sube para no quedar pegado a la ficha del jugador; el botón II baja para no pisar las estadísticas grandes.
- Prueba que MIDE: `pruebas/ideas/tac_hud.gd` (en `especiales.sh`), con un teléfono simulado de 400 ppp y 2400×1080: 10,5 px por mm; letra estadísticas ≥ 2,5 mm (2,5), marcador 4,0 mm, nombre 3,05 mm; ninguna caja del HUD pisa el stick ni los botones y todas caben en el lienzo; cámara a 12,4 m del jugador (la de siempre ≈19,5 m) y el jugador mide el 11,9 % de la altura de la pantalla (≥ 11 %); el balón dentro de cuadro con el jugador cerca y con el balón lejos; Ajustes automático/siempre/nunca.
- Capturas antes/después a 2400×1080 con `DPI_PRUEBA=400` (y `CAMARA_PRUEBA=no` para el «antes») en `pruebas/captura_tactil_partido.gd`.

## Pendiente
- Probar en un móvil real (FPS, tamaño percibido, latencia del dedo).
- Con el balón MUY lejos el jugador que llevas puede quedar fuera de cuadro (la cámara sigue al balón); falta decidir si en modo Carrera conviene un indicador en el borde de la pantalla.
