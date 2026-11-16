# H1 · Animación de los futbolistas: pie y cabeza al balón (16-11-2026)

Hito H1 del informe académico (`INFORME_ACADEMICO_AAA/cap_09_plan.md`, punto 3, tareas de animación): IK de pie al balón y cabeza
que sigue al balón con modificadores de esqueleto de Godot 4.7, deterministas y sin tocar el motor del partido; warping de giros
si es viable; y el canalé de las medias con el mismo arreglo que los «parches claros» de camisetas y shorts.

## Qué se hizo

| Pieza | Archivo | Qué hace |
|---|---|---|
| Pie al balón | `visor/pie_balon_ik.gd` (`PieBalonIK`, `SkeletonModifier3D`) | IK de dos huesos resuelta a mano (`thigh_*` → `calf_*` → `foot_*`, como `BrazosIK`: el `TwoBoneIK3D` del motor no movía este esqueleto tipo Unreal). El tobillo del pie del toque va a 18 cm del centro del balón, del lado del cuerpo; la rodilla se dobla en el plano que ya traía la pierna; la planta conserva la orientación del clip. Pie del toque = el más cercano; si el otro queda 12 cm más cerca, cambia y entra en ~8 fotogramas (sin salto). No estira más de 55 cm. |
| Director (LOD) | `visor/animacion_cercana.gd` (`AnimacionCercana`, un nodo por partido) | Cada fotograma decide quién lleva los retoques. **Cabeza** (la `MiradaBalon` de M-098, `LookAtModifier3D` con topes de 65°/30°): solo jugadores a < 33 m de la cámara (más lejos el cuerpo es la silueta de `ImpostorLejano`) y < 22 m del balón; la influencia sube y baja en ~0,4 s y con 0 el modificador queda apagado. **Pie**: solo uno, el que lleva el balón (o el más cercano si está suelto), con el balón a < 45 cm de altura y a < 1,3 m; peso hasta 0,85 (0,45 durante un golpeo, el clip ya lleva el pie). Los que entran de cambio también miran (antes no llevaban mirada); los que salen o son expulsados se apagan. |
| Montaje | `visor/mirada_balon.gd` | `MiradaBalon.poner(jugadores, balon, motor)` monta además el director (partido jugable y modo estadio, `ui/partido_jugable.gd`, `ui/estadio_p5.gd`). |
| Medias | `visor/equipacion_q.gdshader` | El relieve del canalé (costillas alrededor de la pierna) se sumaba a `nm.x` del atlas: cada isla de UV lo inclinaba a su manera (el mismo fallo de los parches claros). Ahora la pendiente se calcula en x y z de reposo y se lleva al espacio tangente con `v_ejes` y un `v_ejez` nuevo (eje z de reposo, medido igual en el vértice). |

**Calidad.** Encendido de MEDIA hacia arriba. En ULTRA BAJA, BAJA y MEDIA BAJA, y con «Partido ligero», no se monta nada y la
mirada de M-098 queda **APAGADA** (antes iba en los 22 jugadores en todas las calidades): es un cambio que se dice aquí, a favor
del coste. `H1_IK=0` (o `AnimacionCercana.encendida = false`) deja todo como antes (capturas «antes»).

**El motor no cambia.** El director solo LEE `jugadores`, `poseedor`, `balon` y `t`; los modificadores tocan huesos de piernas y
cabeza (el motor solo lee `hand_*` y `pelvis`). Prueba nueva del banco `_probar_h1_animacion` (grupo `partido`): el mismo partido C4
(México-Italia, 900 pasos) con y sin el director actualizándose cada paso da la MISMA huella (posiciones, giro, goles, tiros,
estadísticas); el pie se activa y la IK acerca el tobillo a su objetivo; en ULTRA BAJA, MEDIA BAJA y ULTRA ALTA con «Partido
ligero» (Japón-Nigeria) no hay ni `AnimacionCercana`, ni `PieBalonIK`, ni miradas activas. `pruebas/igualdad_motor.gd` no se tocó.

## Medidas (`pruebas/medir_h1_animacion.tscn`, sin pantalla, estadio México-Italia, 900 fotogramas a 60 Hz)

| Medida | Sin H1 (`H1_IK=0`) | Con H1 |
|---|---|---|
| `AnimacionCercana.actualizar` (ALTA) | — | **~75-80 µs por fotograma** (120-200 µs con otro agente usando los 4 núcleos) |
| Proceso total por fotograma, ALTA (`TIME_PROCESS`) | 57,6 ms | 65,6 ms (ruido: carga 3-4 de otro agente; en otras tandas 69-79 sin y 60-63 con) |
| Proceso total por fotograma, ULTRA BAJA | 17,4 ms | **15,5 ms** (la mirada de M-098 apagada; nada montado) |
| Miradas (`LookAtModifier3D`) activas | 22 siempre | solo las de cuerpo visible (< 33 m de la cámara) y < 22 m del balón |
| `PieBalonIK` activos | — | 0 o 1 |
| Pie al balón: tobillo → objetivo (fotogramas en que actúa) | 0,21-0,34 m (lo que deja el clip) | 0,06-0,19 m |
| Triángulos / llamadas de dibujo | — | sin cambio (solo se mueven huesos; el shader de las medias gana un `varying vec2`) |

El tiempo de proceso total del estadio sin pantalla es el de una máquina compartida (llvmpipe, 4 núcleos, otro agente trabajando):
las diferencias de ±10 ms son ruido; el coste propio es la primera fila más un modificador de pie en GDScript (un jugador) y MENOS
miradas que antes. FPS reales: en la laptop del dueño. Nota: el estadio sin pantalla no es determinista de una tanda a otra (dos
tandas iguales con `H1_IK=0` dieron huellas distintas), así que la igualdad del motor se comprueba en el banco, no aquí.

El balón está a menos de 1,05 m de algún jugador y bajo en ~11-14 % de los fotogramas (C4 pasa mucho): es cuando trabaja el pie.
En un 25-40 % de esos fotogramas el objetivo queda a más de 55 cm del tobillo del clip y no se fuerza la pierna.

## Warping de giros (punto 2): medido, NO hace falta ahora

Con la misma escena se midió el giro del nodo de cada jugador por fotograma (60 Hz, 19.778 muestras): > 10° en el 2 % de los
fotogramas·jugador, > 20° en el 0,15 % y > 45° en el 0,015 %; el cuerpo va de media a 3,3° de la dirección de la marcha a más de
3 m/s. El motor ya gira con `lerp_angle` y `LeagueLocomocion` compensa el giro de los clips en el modelo (cuerpo girado 45°/135°,
transiciones de giro), así que un tope de giro en la vista apenas actuaría y chocaría con esa compensación (escribe
`modelo.rotation.y`). Queda ANOTADO para cuando haya clips de giro con pie de apoyo («plant & turn») o *motion matching*: entonces
el warping es escalar el giro del clip al giro real, no un tope.

## Capturas (`capturas_h1_animacion_2026-11-16/`)

Cámara real del partido (`tv_*`) y un plano de cerca del jugador que lleva el balón (`cerca*`), ANTES (`H1_IK=0`, shader de medias
anterior) y DESPUÉS, con tres cruces de países distintos: Brasil-Japón, Argentina-España y México-Italia
(`herramientas/captura.sh res://pruebas/captura_h1_animacion.tscn`, Forward+), reducidas a 1280x720; `*_antes_despues.jpg` las pone lado a lado. El plano de cerca se toma cuando el balón está a < 75 cm
del jugador; como el estadio no repite exactamente igual de una tanda a otra (ver arriba), alguna pareja no es el mismo instante
(México-Italia `cerca2` deja el balón fuera de cuadro, pero muestra el canalé de las medias).
De cerca se ve el pie del toque pegado al balón en vez de a un palmo; en la cámara de TV el cambio es pequeño (un pie a 30 m).

## Pendiente

- Veredicto del dueño sobre las capturas y en el teléfono (MEDIA).
- Warping de giros: anotado arriba (tras los clips de giro / motion matching del H1).
- La mirada podría pasar a C++ con su gemelo GDScript si el perfil en el teléfono lo pide (hoy son ~75 µs).
