# Arena de pruebas (P5, 3-11-2026)

Un banco aislado para probar UNA pieza del partido sola, verla desde cuatro cámaras a la vez y medirla. Monta solo lo pedido
(cancha + N jugadores + árbitro + balón), sin público, sin ciudad, sin menú.

```
godot --path . --rendering-driver vulkan --resolution 1280x720 res://pruebas/arena/arena.tscn      # a ojo, en PC
ARENA=arbitro CAMARAS=1 DURACION=10 CALIDAD=minima xvfb-run -a godot --path . --rendering-driver opengl3 res://pruebas/arena/arena.tscn   # medir
```

| Variable | Valores | Qué hace |
|---|---|---|
| `ARENA` | `cancha` `jugador` `arbitro` `balon` `porteria` `partido` | qué se monta (por defecto `jugador`) |
| `N` | 1-11 | jugadores por equipo en `partido` |
| `CAMARAS` | 1-4 | cuántas vistas se dibujan; **1** para medir la pieza sin el coste de las otras tres |
| `VELOCIDAD` | 1, 2, 4, 8… | reloj acelerado (`Engine.time_scale`); `T` lo cambia en vivo |
| `DURACION` | segundos | 0 = hasta cerrar (en headless, 8); al acabar imprime las medianas |
| `CALIDAD` | `minima` `media` `alta` `ultra` | nivel gráfico (por defecto el elegido del juego) |
| `MOTOR` | 0 / 1 | el motor jugable lleva a los jugadores (1 en `partido`, `balon`, `porteria`) |
| `ESTADIO` | 0 / 1 | monta además el estadio entero (público, vallas, focos): sirve para medir lo que cuesta |
| `SEMILLA` | n | mundo y motor |
| `ARENA_CSV` | ruta | dónde van las métricas (por defecto `/tmp/arena_<modo>.csv`) |

Teclas: `1`-`4` una cámara a pantalla completa · `0` la cuadrícula · `T` velocidad · `Esc` salir.
Cámaras: TELE, CENITAL, LATERAL y A RAS DE SUELO, las cuatro sobre el mismo mundo 3D (un `SubViewport` por cámara con el mismo `World3D`).

Métricas (una fila por segundo, reloj de pared): FPS medios y mínimos, ms de fotograma, de proceso y de física, llamadas de dibujo, triángulos,
objetos, nodos y MB de vídeo. Sin GPU (llvmpipe) el tiempo solo sirve para comparar versiones: comparar llamadas, triángulos y memoria.
Sin renderizador (`--headless`) las métricas de dibujo salen a 0.

Prueba de humo: `pruebas/ideas/arena_humo.tscn` (cada modo monta lo que dice).
