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

## Pendiente
- Etiquetas según el contexto (con/sin balón) en lugar de «Pase / Presión» (hecho en la lista siguiente).
- HUD del partido (marcador, ficha del jugador) legible a 1080×2400.
- Probar en un móvil real (FPS, tamaño percibido, latencia del dedo).
- Etiquetas según el contexto (con/sin balón) en lugar de «Pase / Presión».
