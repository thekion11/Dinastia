# MOTOR DEL PARTIDO: LEAGUE-SOCCER COMO BASE (plan, prototipo y cifras)

Orden expresa del dueño (10-11-2026, `PLAN_GENERAL.md` «ENCARGO DEL DUEÑO (10-11 noche)» punto 6; prevalece sobre las órdenes
23-24): REEMPLAZAR el sistema de juego del partido por el de League-Soccer (C++, Apache 2.0) y montar lo nuestro encima como
variante, sumando las animaciones y extras que ya tenemos. Sesión 4, rama `sesion4-motor-league` (sin PR).

Rutas: **L** = `dinastia-godot/terceros/league_soccer/codigo_y_recursos/src/onthepitch/`, **D** = `dinastia-godot/visor/`.

---

## 1. Qué es League-Soccer por dentro (estudio)

Origen: GameplayFootball (Bastiaan Konings, 2009-2019) → Google Research Football (2019) → League-Soccer (awest813, 2026, con
retoques «PES 5/6»). ~24.500 líneas en `onthepitch/` (más ~10.000 de render, menús y base). El partido es un ciclo de **10 ms
fijos** (`Match::Process`, 100 Hz) en un hilo de juego aparte del de dibujo.

| Pieza | Archivo (L) | Qué hace | Tamaño |
|---|---|---|---|
| Partido | `match.cpp` | Bucle de 10 ms, estados (saque, juego, gol, descanso), posesión, repeticiones, cámara, HUD | 2.631 |
| Balón | `ball.cpp`, `ballphysics.cpp` | Física a 10 ms: gravedad, arrastre cuadrático, bote, roce de césped con «hierba» de 2,5 cm, viento y humedad; **predicción de 3 s** (300 pasos) cada ciclo; palos y red; efecto Magnus | 674 |
| Jugador | `player/player.cpp`, `playerbase.cpp` | Estado, cansancio, **situación táctica** (espacio delante, espacio propio, cercanía al arco) | 850 |
| Cuerpo | `player/humanoid/humanoid*.cpp`, `animcollection.cpp` | **Locomoción guiada por animaciones**: cada orden (moverse, pasar, tirar, entrar) busca en las 296 animaciones la que mejor encaja con la dirección, la velocidad y el balón; el toque ocurre en el cuadro de contacto de la animación; el cuerpo hereda su desplazamiento | 7.600 |
| IA del jugador | `player/controller/elizacontroller.cpp`, `playercontroller.cpp`, `strategies/` | Con balón: puntúa a cada compañero (situación táctica + probabilidad del pase corto/largo/alto) y decide pase, pánico, tiro o regate (campo de fuerzas). Sin balón: estrategias por puesto (defensa, medio, ataque, portero), marcaje, presión | 2.900 |
| IA del equipo | `teamAIcontroller.cpp`, `aitactics.hpp` | Posición de formación adaptada (bloque que se estira con la posesión, foco en el balón con retardo, línea de la trampa del fuera de juego), roles dinámicos (húngaro), marcaje al hombre, presión de equipo y de zona, carreras al espacio, balón parado | 1.480 |
| Imagen mental | `AIsupport/mentalimage.cpp` | Lo que «ve» la IA: posiciones con retardo | 140 |
| Árbitro | `referee.cpp`, `officials.cpp`, `gameplaytuning.hpp` | Faltas, ventaja (vuelve a la falta si la víctima pierde el balón tras 0,6 s; jugada a los 3,5 s), tarjetas pendientes, fuera de juego, reanudaciones | 750 |
| Reloj y reglas | `matchclock.hpp`, `matchduration.hpp` | Mitades, añadido, fases | 250 |

Dependencias que lo atan: el partido nombra el HUD, el menú, la cámara, el sonido y el planificador de tareas; el humanoide
depende del grafo de escena propio, de su cargador de `.anim` y de la geometría del esqueleto (`player.object`). Solo
`ballphysics`, `aitactics`, `gameplaytuning`, `velocitystate`, `humanspeed` y `matchclock` se compilan sin SDL/OpenGL (su
«headless» oficial **no juega un partido**: `tests/integration/match_simulation_test.cpp` solo prueba el reloj y las fórmulas).

### Ejes (traducción obligatoria)
League: X = largo (±52,5), Y = ancho (±34), Z = arriba; `side` = signo del arco PROPIO (±1). Nosotros: Z = largo, X = ancho,
Y = arriba; `dir_ataque(local)` = +1 el local. Por tanto **lado = −dir_ataque**, `ls(v) = Vector2(v.z, v.x)`, `mundo(v) = Vector3(v.y, 0, v.x)`.

---

## 2. Cómo se trae: decisión

| Opción | A favor | En contra | Veredicto |
|---|---|---|---|
| A. Compilar League como GDExtension «headless» sin su render | Fiel al 100 % | Hay que desenredar `match.cpp` y el humanoide del HUD, el menú, el grafo de escena y su cargador de animaciones (~15.000 líneas tocadas); **no existe en Android ni Web** sin otra copia; dos esqueletos y dos sistemas de animación; regla del proyecto: cada función nativa debe ser copia exacta de su GDScript → habría que portarlo igual | NO como primer paso |
| B. Portar a GDScript, módulo a módulo, detrás de una bandera | Funciona en todas las plataformas; se mide contra el motor de hoy pieza a pieza; nuestras reglas, saques, árbitro, cámaras y animaciones siguen valiendo | Más lento que C++; la locomoción por animaciones es lo más caro de portar | **SÍ (base)** |
| C. Mixto: B + pasar a la extensión C++ solo lo caliente (probabilidades de pase, espacio libre, predicción del balón) con su gemelo GDScript | Rendimiento en PC; el GDScript queda de respaldo para Android/Web | Doble mantenimiento (la regla «copia exacta» lo exige y `probar_nativo.tscn` lo comprueba) | **SÍ, en la fase 5**, solo si las cifras lo piden |

Elegido **B → C**. El núcleo portado son funciones PURAS (sin nodos ni azar propio) en el marco de League, para que la
traducción línea a línea se pueda revisar contra el original y, si hace falta, pasar a C++ tal cual.

---

## 3. Cómo se conecta con lo nuestro

```
MotorLeague (D motor_league.gd)  ── hereda de ──>  MotorJugable (reglas, saques, árbitro, porteros, duelos, usuario, señales)
   │  sustituye: _ia_portador (decisión con balón) · _forma (colocación sin balón) · _mover_balon (balón suelto) · paso (estado de equipo)
   ├── LeagueNucleo (D league_nucleo.gd): fórmulas puras portadas (balón, espacio, situación, pase, tiro, pánico, regate, formación, ventaja, fatiga)
   └── LeagueEquipo (D league_equipo.gd): estado por equipo (posesión que se desvanece, historial del balón, trampa del fuera de juego, tácticas vivas)
```

- **Bandera**: `MOTOR_LEAGUE=1` (variable de entorno) o `MotorLeague.activo = true`; `MotorLeague.crear()` devuelve el motor
  que toque. Apagada, el partido es EXACTAMENTE el de siempre (el banco sigue en «FIN. 0 fallos» sin tocar nada).
- **Datos**: no cambia nada en `Partido`, `Club`, `Tactica` ni en `Puente3D`/`PlayerSpawner`: la variante recibe los mismos
  diccionarios de jugador (`attr`, `base_pos`, `slot_code`, `vel`, `node`) y emite las mismas señales (gol, aviso, sustitución…).
- **Pizarra y estrategias rápidas** (`EstrategiaRapida`): sus 4 palancas (0..2) se traducen a las de League (0..1): amplitud →
  `position_*_width_factor`; presión → `*_microfocus_strength` y `*_midfieldfocus` defensivos; mentalidad → ofensividad
  (+0,15 por punto) y foco del medio en ataque; línea → ±4 m del bloque; ritmo → contraataque.
- **Ejecución de cada golpeo**: la decide League, la ejecuta lo nuestro (`_pasar_a`, `_tirar`, `_patear`): error por
  atributos y pie malo (`GestoTecnico`), clima, animaciones de golpeo, contadores y sonido. Igual las fintas (`_intentar_regate`),
  los porteros, los duelos, las faltas, el VAR, las celebraciones, la cámara y el control del usuario.
- **Animaciones**: las 296 de League ya están en `anims_league/league.res` (`visor/league_anim.gd`) y se suman a las nuestras.

---

## 4. Riesgos

| Riesgo | Detalle | Medida |
|---|---|---|
| Rendimiento en móvil | El partido del dueño va a 5 FPS en MEDIA con la GPU al 100 % (`PRUEBA_DUENO_MOVIL_2026-11-03.md`): el cuello es la GPU, no la CPU. Lo caro de League es la CPU: 11 compañeros × 3 tipos de pase × 11 rivales por decisión, la situación táctica de los 11 y la predicción de 3 s del balón | Decisión cada 0,25 s (no cada ciclo); sin predicción de 3 s (solo la media del historial); fase 5 = C++ si hace falta. Medido abajo |
| Android/Web sin nativo | La extensión C++ no está en esas plataformas | El núcleo es GDScript; lo nativo sería un gemelo opcional |
| Determinismo | El de siempre depende del paso del fotograma | La variante integra el balón suelto a paso fijo de 10 ms y su estado de equipo a 10 ms (como League). Comprobado con la misma semilla (abajo) |
| Licencia Apache 2.0 | §4: copia de la licencia, aviso de cambios y atribución | `terceros/league_soccer/LICENCIA_Apache-2.0.txt`, `NOTICE_DINASTIA.md`, cabecera de cada archivo portado, `LICENCIAS.md` y una línea en los créditos del juego (`Creditos.LISTA`; antes faltaba aunque ya usábamos sus animaciones y sonidos) |
| Datos reales | Su base de datos trae jugadores y escudos reales | No se copian (ya fuera del repo); solo su dirección |
| Calibración | Las cifras del motor de hoy (remates, goles, acierto de pase) llevan semanas de ajuste en el banco y las sondas | La variante se mide con `pruebas/comparar_motor_league.tscn` antes de proponerla por defecto |
| Órdenes 23-24 | El partido puro lo llevaban el dueño y la sesión «PES 6» | La orden del 10-11 prevalece; la variante no toca su código (solo hereda) |

---

## 5. Fases (con pruebas)

| Fase | Qué | Prueba | Estado |
|---|---|---|---|
| 1 | Estudio y plan (este documento) | — | HECHO (10-11) |
| 2 | **Prototipo** detrás de la bandera: decisión con balón (Eliza), colocación (TeamAI), balón suelto (ballphysics a 10 ms), estado de equipo (posesión que se desvanece, trampa del fuera de juego, tácticas vivas) | `pruebas/comparar_motor_league.tscn` (partidos completos, varios países, los dos motores, CPU y determinismo); banco `_probar_league_nucleo` (fórmulas contra valores del original) | HECHO (10-11), cifras abajo |
| 3 | IA SIN balón de League: estrategias por puesto (`strategies/offtheball/default_*.cpp`), apoyo por campo de fuerzas, componente defensiva, presión de equipo y de zona (`ApplyTeamPressure`, `ApplyZonePressure`), marcaje al hombre (`CalculateManMarking`), carreras al espacio (`ApplyAttackingRun`), apoyo adelantado, caza del portador | La misma comparación + banco | HECHO (10-11), cifras en §7. Quedan para la 3b: el portero de League (`goalie_default.cpp`; hoy el nuestro), la ventaja del árbitro y las tarjetas pendientes (R1, ya parcial en `MotorVentaja`) |
| 4 | **Locomoción guiada por animaciones** (L humanoid + animcollection): elegir la animación de `league.res` que encaja con la orden y tocar el balón en su cuadro de contacto; velocidades cuantizadas (parado 0, conducción 3,5, trote 5, sprint 8 m/s) y giros con inercia | Capturas con la CÁMARA REAL (`herramientas/captura.sh`), vídeo del partido, `mem_*` | pendiente (lo más grande: ~7.600 líneas de origen) |
| 5 | Rendimiento: medir en `hw_modesto.sh` y en el teléfono del dueño; si la CPU de la IA pesa, pasar a C++ (`nativo/src`) las 3 funciones calientes con su gemelo GDScript | `probar_nativo.tscn` «FIN. 0 fallos», `medir_motor_cpu` | pendiente |
| 6 | Calibrar contra el fútbol real y el motor de hoy (remates 20-26, goles 2,5-2,9, acierto de pase 80-85 %, posesión 50 ± 8) y proponer al dueño el cambio por defecto | `comparar_motor_league` con 16+ partidos | pendiente |
| 7 | Por defecto (con OK del dueño): `MotorLeague.crear()` en el estadio y el partido jugable; el motor de siempre queda como respaldo detrás de la bandera inversa | banco completo con la bandera encendida | pendiente |

---

## 6. Prototipo (fase 2): cifras (10-11-2026)

Archivos: `visor/league_nucleo.gd` (438 l.), `visor/league_reglas.gd`, `visor/league_equipo.gd`, `visor/motor_league.gd`;
fábrica en `ui/estadio_p5.gd` y `ui/partido_jugable.gd` (con `load()`, sin nombrar la clase: regla de memoria del menú).
Pruebas: banco `_probar_league_nucleo` (12 comprobaciones de las fórmulas contra el original + 20 s de partido con dos clubes
de países distintos) y `pruebas/comparar_motor_league.tscn`. Banco completo con la bandera apagada: «FIN. 0 fallos».

### Partidos completos (autopiloto, 2 × 240 s, paso de 1/30 s, misma semilla y mismos onces para los dos motores)
`N_PARTIDOS=6 MITAD=240 godot --headless --path . res://pruebas/comparar_motor_league.tscn` → «FIN. 0 fallos».
Cruces (6 países, 12 clubes): Lautaro FC (CHI) - Núñez Athletic (ARG), Boedo AC (ARG) - Laranjeiras FC (BRA),
Laranjeiras FC (BRA) - Iruña CF (ESP), Olívico CF (ESP) - Trafford Reds (ENG), Selhurst FC (ENG) - Tevere FC (ITA),
Salento FC (ITA) - Rancagua Celeste (CHI).

| Media por partido | Motor de siempre | MotorLeague |
|---|---|---|
| CPU por paso del motor (µs, sin pantalla, con los 22 nodos animados) | 1.498 | 1.920 (+28 %) |
| Pico de un paso (µs) | 15.997 | 29.619 |
| Goles | 4,67 | 1,33 |
| Remates | 39,7 | 7,3 |
| Pases / acierto | 129,7 / 80,7 % | 106,5 / 76,1 % |
| Despejes | 4,8 | 0,5 |
| Posesión del local | 50,5 % | 50,4 % |
| Decisiones de League por partido | — | pase 71 · pánico 0,5 · tiro 4 · conducir 212 |

**Determinismo**: el primer partido de League repetido con la misma semilla da la MISMA huella (marcador, remates, pases y
posición final del balón al milímetro). El balón suelto y el estado de equipo van a paso fijo de 10 ms.

### Partido jugable con la cámara real (carrera, calidad MÍNIMA, `medir_partido_jugable.tscn`)
| | Motor de siempre | MotorLeague |
|---|---|---|
| Llamadas de dibujo / triángulos (xvfb + opengl3, 1 fotograma) | 385 / 166 k (otra toma: 624 / 352 k) | 483 / 231 k (otra toma: 652 / 336 k) |
| Nodos / memoria de vídeo | 2.732 / 184 MB | 2.733 / 184 MB |
| CPU del proceso por fotograma (`CPU=1`) | 10,6 ms | 10,8 ms |
La variante no añade nada que dibujar: las llamadas cambian con dónde están los jugadores y la cámara en ese fotograma (con
el MISMO motor varían de 385 a 624 entre dos tomas). En CPU por fotograma la diferencia (+0,2 ms) está dentro del ruido.

### Hallazgos
1. **Asimetría del original (corregida)**: `clamp(foco + side·2, −pitchHalfW, backXBound·side)` en `GetAdaptedFormationPosition`
   solo limita bien con `side = +1`; en League los equipos cambian de campo en el descanso y se compensa, aquí no (la visita tenía
   ~15 puntos más de posesión, comprobado invirtiendo local y visita con `INVERTIR=1`). Ahora simétrico: 50,4 %.
2. **Remata ~5 veces menos.** En el original la cola de órdenes es pánico → pase → tiro y el muñeco ejecuta la PRIMERA que
   tiene una animación aplicable (`HumanoidBase`, «pick the first that is applicable»). Sin ese filtro (llega con la fase 4,
   locomoción por animaciones) el pase casi siempre gana. Pendiente de decisión del dueño (`PLAN_GENERAL.md`): esperar a la
   fase 4 o calibrar ya.
3. **El sorteo del tiro** es por ciclo de 10 ms en el original; aquí la decisión es cada 0,25 s y se toma el máximo de 25
   sorteos (misma probabilidad).
4. **Coste**: +0,4 ms por paso sin pantalla. Lo caro era el historial del balón (4 medias de hasta 600 muestras por jugador y
   paso): pasado a sumas acumuladas (O(1)); la mezcla de tácticas por puesto se guarda y se rehace una vez por segundo. Lo que
   queda: la situación táctica de los 11 y las probabilidades de 30 pases cada 0,25 s. Candidato a C++ en la fase 5.
5. **Ya teníamos ideas sueltas de League** (F1-F8 de la sesión PES 6: imagen mental, roles húngaros, colocación con retardo…,
   `terceros_ia_motor_2026-11-01.md`). La variante NO las usa en lo que sustituye: allí manda el original, traducido línea a línea.

---

## 7. Fase 3 (IA sin balón): cifras (10-11-2026)

Archivos: `visor/league_sin_balon.gd` (funciones puras: apoyo, componente defensiva, posición de defensa, marcaje, pereza),
`visor/league_reglas.gd` (+ presión de zona, carreras, red de apoyo), `visor/motor_league.gd` (capa 2/2: estado sin balón y
estrategias; la capa 1/2 es `motor_league_p1.gd`). Bandera propia: `LS_FASE3=0` apaga solo la fase 3 (queda la fase 2).
Banco `_probar_league_nucleo` ampliado (8 comprobaciones más). Banco completo: «FIN. 0 fallos».

Cómo funciona (igual que el original): cada jugador sin balón usa la estrategia de su puesto (defensa: DFC/LD/LI; ataque: DC;
medio: el resto) y mezcla su posición de formación estática y la dinámica (roles intercambiados; el reparto lo hace nuestro
`MotorRoles`, que ya era el húngaro de League) según lo lejos que está la acción; con la posesión suma el APOYO por campo de
fuerzas (su base adelantada por carril, la carrera al espacio, repulsión detrás de los 3 rivales cercanos y de los compañeros,
huir de la trayectoria del balón previsto, red alrededor del portador, sin pasar la línea del fuera de juego rival a 240 ms);
sin ella, la COMPONENTE DEFENSIVA hacia el punto de tiro del rival que marca al hombre (los 3 más peligrosos, cada 0,4 s) y la
TRAMPA del fuera de juego; la velocidad sale de la distancia × 2,6 con la PEREZA de su rol, su cansancio y lo que ya corrió.
Encima: presión de ZONA al perder el balón (un segundo presionador 0,7-2,3 s según la palanca), CARRERAS al espacio cada 0,5 s y el
APOYO ADELANTADO cada 1,5 s; la CAZA del portador por los 3 más cercanos que no marcan (posición de defensa en la línea del rival
hacia el arco, solo si hace falta moverse). Se recalcula cada 0,1 s por jugador (el original, cada 10 ms).

**Desvío documentado**: el jugador del equipo que defiende que antes llega al balón SIEMPRE lo disputa dentro del radio de caza
(en el original, solo si no marca a nadie; allí además «interfiere» en cuanto el balón entra en el alcance de una animación de
entrada, `_InterfereCommand`, que llega con la fase 4). Sin este desvío los defensores rodeaban al portador a 3-6 m y nadie entraba
(sonda `pruebas/_sonda/sonda_league_f3.tscn`).

### Partidos completos (los mismos 6 cruces de §6; «FIN. 0 fallos»; determinismo IGUAL)
| Media por partido | Motor de siempre | League fase 2 | League fase 2 + 3 |
|---|---|---|---|
| CPU por paso (µs, sin pantalla) | 1.569 | 1.920 | **1.279 (−18 % frente al de siempre)** |
| Goles | 4,67 | 1,33 | 1,67 |
| Remates | 39,7 | 7,3 | 11,7 |
| Pases / acierto | 129,7 / 80,7 % | 106,5 / 76,1 % | 69,8 / 82,3 % |
| Posesión del local (media) | 50,5 % | 50,4 % | 60,1 % |
| Posesión del local por partido | 51 · 53 · 54 · 36 · 52 · 57 | 50 · 45 · 62 · 48 · 41 · 57 | **81 · 78 · 82 · 16 · 26 · 76** |

### Hallazgos de la fase 3
1. **La CPU baja** por debajo del motor de siempre: la IA sin balón de League sustituye a la nuestra (más cara: jugadas prehechas,
   regiones, anclas, imagen mental por jugador y fotograma) y se recalcula cada 0,1 s.
2. **Un equipo se queda el balón** (~80 % en 5 de 6 partidos; no depende de jugar de local: Olívico-Trafford y Selhurst-Tevere lo
   dominan los visitantes). Con 2 × 120 s el de siempre también daba 73/27 en un partido suelto, pero con 6 partidos completos la
   diferencia es clara. Causa probable: la defensa de League es POSICIONAL (bloque, marcaje, trampa; un solo presionador fuera de la
   presión de zona) y en el original los robos salen sobre todo de su «interferir» por alcance de animación y de los errores del
   primer toque del muñeco (fase 4); con nuestras entradas a 1,25 m el que lleva el balón casi no lo pierde y la posesión que se
   desvanece refuerza al que ya ataca. A revisar en la fase 4 o calibrar en la 6 (decisión del dueño pendiente).
3. Remata más que en la fase 2 (11,7) porque los atacantes se ofrecen y llegan, pero sigue lejos del de siempre (39,7) por la
   prioridad del pase sobre el tiro (§6, hallazgo 2).
