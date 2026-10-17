# MEGA AUDITORÍA 2 — 14-10-2026

Pedido del usuario: repasar todo, corregir lo que se pueda y anotar los puntos
débiles con honestidad. Este documento dice **qué se hizo, con qué prueba, y qué
NO se logró**. Las cifras salen de herramientas del repositorio (se pueden repetir).

## 1. Cifras del proyecto

| Dato | Valor |
|---|---|
| Scripts GDScript | 589 (≈148.800 líneas) |
| Pruebas / capturas / sondas | 342 archivos en `pruebas/` (14 `prueba_*`, 242 `captura_*`) |
| Banco (`herramientas/banco.sh`) | «FIN. 0 fallos» antes de cada subida |
| Modelos 3D (.glb) | 200 · assets 260 MB |
| Clips de animación del personaje | 335 (+3 caminatas nuevas) |
| Idiomas | 9 (es en pt fr it de ca pl tr) |
| Partido 3D, calidad ALTO (`pruebas/medir_partido.tscn`, llvmpipe) | ≈2,3 M triángulos · ≈700 llamadas · 828 objetos |

## 2. Los 15 puntos del pedido, uno por uno

| # | Pedido | Estado | Evidencia / límite |
|---|---|---|---|
| 1 | Nombre y cara de cada jugador = su enlace real; ninguna cara que no sea el 3D | **Hecho** | `Retrato3D` (retrato = busto del modelo 3D con su camiseta). `Cara.textura()` delega ahí; el 2D antiguo solo se usa en `--headless` (sin pantalla). Auditoría: ningún otro punto de la UI pinta fotos/SVG de cara. Límite: las fotos agachadas siguen algo oscuras (ya anotado en `MOTOR_CARAS.md`). |
| 2 | Público = personas reales, optimizado | **Hecho (parcial)** | `herramientas/hornear_publico.gd` hornea el MISMO modelo humano en 6 poses y 2 niveles (≈420 y ≈150 vértices); bandeja baja: 4 filas cerca + 8 medio. El resto de la grada (lejos, 26 triángulos) sigue siendo maniquí: a 30+ m no se distingue. Coste medido: +8 % de triángulos (2,41 M vs 2,23 M). **Falta**: personas del club/ciudad en las primeras filas (pendiente), y que cada hincha tenga su propia ropa/pelo (hoy: color por instancia + shader por altura). |
| 3 | Camisetas y escudos más reales | **Hecho (2D y 3D)** | 17-10 3D (`equipacion_q.gdshader`): cuello que rodea el cuello con ribete (pico/mao/polo), short y manga con vuelo y dobladillo, sombra falsa sobre la piel, medias con canalé y vuelta, tela satinada sin músculo pintado. Capturas `camisetas_cerca_antes/despues.jpg`, `camisetas_tv_zoom_antes_despues.jpg`. Queda: short pegado en la entrepierna (pide geometría). 2D: `Jersey.svg_de` rehecho (estampado recortado a la silueta, cuello, puños, costuras, sombra de tela, marca y escudo) y `Escudo.svg_de` con aro de borde. Hoja: `pruebas/captura_camisetas_escudos.tscn`. **Falta**: revisar la camiseta procedural del 3D (`equipacion_q.gdshader`) con el mismo criterio; las fotos reales de equipaciones siguen mandando cuando existen. |
| 4 | Cada movimiento con balón ↔ controles, por código | **Hecho en la sesión anterior** | `MotorJugable` + `ControlFC` (pases, tiros, filigranas, combinaciones), `prueba_control_equipo` (verde). No se reabrió hoy. |
| 5 | Mejor física y hitbox | **Parcial (17-10: duelos)** | 17-10: cuerpos con hitbox que se empujan y DUELOS con consecuencias (`MotorJugable._cuerpos`, `_duelo_hombro`, `_duelo_dividido`, `_duelo_agarron`, 6 gestos en `AnimFutbol`); 32 partidos: 2,56 goles (2,81 sin duelos), mejor local 16/0/0, 73 % de pases. Prueba `prueba_duelos`, captura `duelos.jpg`. Antes: La sonda `sonda_fisica_partido` mide 0,12 % de solapes, 0 balones hundidos y 0 balones atravesando cuerpos; pero marca 68 teletransportes del balón y giros > 720°/s en 465 fotogramas (parte son saques de centro y reposiciones). Pendiente real: separar reposiciones de movimiento y suavizar giros. |
| 6 | Más modelos 3D externos, más animaciones, **caminatas distintas** | **Parcial** | «Mi caminata» (formal, normal, animado, cansado, agachado, trote) elegible en ⚙ Ajustes de la ciudad. Modelos externos: **no** se descargó ninguno (la red bloquea polyhaven/quaternius; el usuario puede permitir esos dominios). |
| 7 | Inteligencia de los jugadores | **Parcial** | 17-10: la IA disputa el balón con el cuerpo (duelos de hombro, balón dividido, agarrón) y el DT rival cambia cansados y ajusta la pizarra. Antes: La IA existente (apoyos, marcaje, presión, portero) se revisó y es coherente; no se tocó. Idea medible para después: cobertura de espacios y trampa de fuera de juego de la línea defensiva. |
| 8 | Efectos de cámara, celebraciones, botines visibles, VAR usado | **Hecho** | Cámara: `CameraRig.impacto/golpe_de_zoom` (gol, tarjeta, remate). Botines variados por jugador (`VestidorQ._botin_de`). VAR: 1 de 5 goles con VAR en la liga abre la sala VAR y pausa el motor y desde el 17-10 **1 de cada 3 revisados se ANULA** (fuera de juego o falta previa): acta, goleador, crónica, motor y mapa de tiros vuelven atrás (`Partido.anular_gol_externo`); panel rojo en `SalaVAR`, prueba en `prueba_partido_motor`. Cámara de transmisión inteligente (`CameraRig._transmision`) y estadísticas a pedido (T / Select). Celebraciones: ya existían (carrera al córner, abrazo, repetición). Límite: los botines miden unos píxeles desde la cámara de TV. |
| 9 | Auditoría real de cada parte | **Este documento** | Ver §3. |
| 10 | Conducción mejorada + cámara interior | **Hecho** | `ExploradorCiudad._conducir` (curva de potencia, freno, marcha atrás, freno de mano, volante suave, inclinación); V cambia tercera / capó / interior con volante y cuentakilómetros. Captura: `captura_conduccion.tscn`. Límite: el coche no tiene interior modelado (se dibuja un salpicadero 2D). |
| 11 | Menús incompletos (ciudad, personalizar) | **Hecho** | «Ciudad 3D»: 4 tarjetas (volar, pasear, conducir, entrar al estadio). «Editar»: 6 (mundo, mi personaje, identidad, equipación, estadio, casa). Prueba: `prueba_menu_ciudad_pie`. |
| 12 | Más mini-animaciones y juegos | **Parcial** | +2 minijuegos (Malabares, Reflejos del portero) con récord; prueba `prueba_minijuegos_nuevos`. Mini-animaciones nuevas: solo las caminatas. |
| 13 | Usar la carretera Kenney; mejorar muebles e inmuebles | **Parcial** | Piezas en uso: farolas curvas (avenidas), postes con cable (barrios), carteles colgantes (cruces con semáforo), vallas/luces/vallado de las obras. **No se sustituyeron las calzadas** por las losetas (riesgo con semáforos y tráfico). |
| 14 | Optimizar ≥ 50 % | **Triángulos −58 %; llamadas −9 %** | 17-10: `medir_partido` (ALTO, Forward+, cámara de TV): **1.797.365 → 760.733 triángulos**, 690 → 630 llamadas, 816 → 749 objetos (fotograma bajo lavapipe 954 → 794 ms: no es una cifra de FPS). Causa principal: al rehacer la malla del cuerpo (`VestidorQ._con_reposo`) se perdían los 8 LOD del importador y los ~80 cuerpos se dibujaban siempre con 12.566 triángulos; ahora se copian (`VestidorQ.lods_de`). Cabeza según la distancia: cuero cabelludo de 15 capas → 5 desde 22 m (`PeloCapas.DIST_CUERO`), pestañas hasta 20 m, cejas 3D hasta 30 m (`PeloQ.DIST_CEJAS`); ojos con su LOD. De cerca, igual. Capturas `pruebas/capturas/lod_cabeza_*.jpg`. Herramientas: `NODOS=1` y `OCULTAR=a,b` en `medir_partido`. Las llamadas siguen altas (ojos, cara real y cuero = 1 llamada por pieza y jugador). |
| 15 | Otra mega auditoría + vídeo estilo gameplay al Drive | **Ver §5** | |

## 3. Auditoría por partes (puntos débiles reales)

1. **Rendimiento**: sin GPU real no se puede prometer FPS. El sospechoso principal
   es el coste de pintar la grada y los 22 jugadores con pelo/pestañas/ojos de alta
   densidad (los ojos tienen 768 triángulos por pieza). HECHO 17-10: el gasto real
   eran los cuerpos sin LOD (≈1 M de triángulos) y el cuero por capas (≈180 mil);
   ver #14. Queda: llamadas de dibujo por jugador (≈8 piezas por cabeza+cuerpo).
2. **Física/animación del partido**: reposiciones del balón y giros bruscos (ver #5).
   HECHO 17-10: duelos cuerpo a cuerpo con consecuencias. Faltas: de ~3,8 a ~8,8 por partido
   (17-10; partido comprimido, goles iguales, el mejor sigue ganando 9 de 12).
3. **Público**: la mayoría del estadio sigue siendo muñeco de 26 triángulos; solo
   la bandeja baja usa personas reales. No hay «personas del club» sentadas.
4. **VAR**: HECHO 17-10, ya anula goles. Queda: que la decisión salga de la jugada real
   (posición del atacante en el pase), no del azar.
5. **Ciudad**: calzadas aún propias (no Kenney); sin interior real en los coches;
   metro y galería funcionales pero con poca vida (NPC en andenes).
6. **Contenido legal**: las caras reales (Wikipedia/MediaPipe) están excluidas de
   los builds públicos; el derecho de imagen lo decide el dueño (ya avisado).
7. **Pruebas**: 14 `prueba_*` automáticas vs 242 capturas. Faltan pruebas
   automáticas para ciudad (conducción), minijuegos 3D y menús (solo hay capturas).
8. **Cobertura de idiomas**: 9 idiomas; los menús nuevos y «Mi caminata» YA están traducidos (20 frases × 8 idiomas); faltan las cadenas dibujadas a mano de los minijuegos nuevos.

## 4. Lo que sigue (orden propuesto)

1. ~~LOD de ojos/pestañas + pelo a distancia~~ HECHO 17-10 (−58 % triángulos). Siguiente: bajar llamadas (juntar ojos/cejas en la malla de la cara a distancia).
2. ~~Anulación de goles por VAR y duelos con consecuencias~~ HECHO 17-10. Siguiente: más faltas y fuera de juego real decidiendo el VAR.
3. Traducir las cadenas de los minijuegos nuevos (los menús ya están).
4. Personas del club/ciudad en las primeras filas y NPC en andenes.
5. Probar losetas Kenney en una calle de prueba (sin tocar la red principal).

## 5. Vídeo

Ver el mensaje final de la sesión: el vídeo se entrega por el chat y, si el
tamaño lo permite, al Drive. (Los `.mp4` nunca se suben al repositorio: LFS prohibido.)
