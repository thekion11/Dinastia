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
| 4 | **Locomoción guiada por animaciones** (L humanoid + animcollection): elegir la animación de `league.res` que encaja con la orden y tocar el balón en su cuadro de contacto; velocidades cuantizadas (parado 0, conducción 3,5, trote 5, sprint 8 m/s) y giros con inercia | Capturas con la CÁMARA REAL (`herramientas/captura.sh`), vídeo del partido, `mem_*` | EN CURSO (11-11): 4a-4c HECHAS; 4d catálogo extensible + guía de movimiento (§11) HECHAS; faltan calibrar la fuerza de la guía y capturas con cámara real |
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

### Con la formación y el estilo REAL de cada club (`EstiloClub`, 10-11 tarde)
Hasta aquí la comparación no pasaba las tácticas al motor (los dos motores jugaban con la pizarra neutra). Ahora
`comparar_motor_league` pasa `MotorJugable.tactica_desde(club.tactica)` y empareja en cada cruce estilos DISTINTOS. MotorLeague
traduce además: verticalidad → contraataque (carreras y apoyo adelantado), ritmo → regate ofensivo, amplitud → imán al centro
al conducir (al revés) y anchura del bloque, presión + «tras la pérdida» → presión de zona. La formación ya la respetaba (las
casillas de League salen de la posición base de cada club).

| 6 partidos completos | Motor de siempre | MotorLeague (fases 2 + 3) |
|---|---|---|
| CPU por paso (µs) | 1.581 | 1.256 (−21 %) |
| Goles / remates | 6,0 / 49,3 | 2,83 / 11,8 |
| Pases / acierto | 121 / 74,0 % | 79,7 / 81,2 % |
| Posesión del local | 52,1 % | 20,8 % |

Cruces: Lautaro (CHI, 4-2-3-1 ofensivo) - Núñez (ARG, 4-2-3-1 presión); Boedo (ARG, 4-4-2 garra) - Laranjeiras (BRA, 4-2-3-1
posesión); Laranjeiras - Iruña (ESP, 4-4-2 garra); Olívico (ESP, 4-2-3-1 posesión) - Trafford (ENG, 3-4-3 vertical); Selhurst
(ENG, 3-4-3 vertical) - Tevere (ITA, 4-3-3 equilibrado); Salento (ITA, 4-2-3-1 contra) - Rancagua (CHI, 4-3-3 equilibrado).

**Hallazgo 4 (el estilo pesa demasiado)**: el 20,8 % del local NO es el campo: con local y visita invertidos (`INVERTIR=1`) domina
el MISMO club (Núñez «presión» 79 % de local; Iruña «garra» 76 %). Los estilos de presión alta y «tras la pérdida» alto se quedan
el balón: la presión de zona al máximo más el designado que siempre disputa roban casi todo, y la «posesión» de Laranjeiras
pierde contra la «garra». Que el estilo se note está bien; la magnitud no. Se revisa en la fase 4 (robos por alcance de
animación, sustituyen al desvío del designado) y se calibra en la 6.

## 8. Fase 4a (robos por alcance, conducción y cortes con el catálogo de toques; 10-11 noche)

Archivos: `herramientas/league_toques.py` → `datos/league_toques.json` (133 animaciones con toque de las 296 originales: cuadro y
posición del balón, desplazamiento del cuerpo, dirección del balón que entra y sale, dificultad, «última oportunidad»; 32 KB,
viaja en las exportaciones como los demás `datos/*.json`), `visor/league_toques.gd` (el FILTRO DE ALCANCE), y en
`visor/motor_league.gd`: el balón previsto cada 10 ms durante 700 ms (L Ball::Predict) y tres piezas del muñeco del original:
1. **Robos por alcance** (L `_InterfereCommand` y `_SlidingCommand`): un defensor que puede ganar el duelo (no tiene al rival
   entre él y el balón, L `CouldWinABallDuelLikeliness`) entra si una animación de interferir (≥ 0,2) o de barrida (≥ 0,7, a
   0,7-1,6 m, con poca posesión) toca el balón previsto en su cuadro; el duelo lo resuelve nuestro `_entrada` (atributos, faltas,
   animaciones). Sustituye al desvío del designado de la fase 3, que queda detrás de `LS_DESIG=1`.
2. **El rival fastidia la conducción** (L `GetBallControlVector`, `opponentAnnoyanceFactor`): con un rival a 0,5-1,5 m, a más
   velocidad y con menos serenidad y equilibrio, el toque se alarga hasta 3 m y el balón se escapa del pie.
3. **Cortar el pase**: con un pase en vuelo, el rival que tiene una animación de interferir o de control que alcanza el balón
   previsto va a ese punto; quién se lo queda lo decide lo nuestro (`_disputas`/`_tomar`).

**Simplificado** (anotado en `league_toques.gd`): el radio de toque usa el factor por tipo, el del cuadro y la bonificación por
velocidad del original, pero las bonificaciones por cercanía cuerpo-balón van fijas (+1,6, su valor típico), no se deforma el
área según el balón que entra, y la animación se mira girada HACIA EL BALÓN (el original la elige girada a la dirección
deseada, con giros). Serenidad = nuestro `reg` (no tenemos «calmness»).

| 6 partidos completos con estilos reales | Motor de siempre | League fase 3 | League fase 4a |
|---|---|---|---|
| CPU por paso (µs, misma máquina en la misma tanda) | 1.651 | — | 1.417 (−14 %) |
| Goles / remates | 6,0 / 49,3 | 2,83 / 11,8 | 2,5 / 9,3 |
| Pases / acierto | 121 / 74,0 % | 79,7 / 81,2 % | 74,8 / 78,0 % |
| Cambios de posesión por partido | **76,7** | ~21 | **24,7** |
| Posesión del local por partido | 52 de media | 20,8 de media | 83 · 57 · 44 · 17 · 71 · 74 |
| Por partido: interferir / cortar / fastidio | — | — | ~20 / ~70 / ~120 |

Determinismo IGUAL; banco «FIN. 0 fallos».

**HALLAZGO DE FONDO (lo que falta para proponerlo por defecto)**: con League el balón cambia de dueño 3 veces menos (25 frente a
77). La mayor parte de la diferencia son los REMATES: en el motor de siempre casi cada remate (≈ 49 por partido) termina la
posesión (parada, saque de puerta, córner); con League hay ≈ 9. Así, quien tiene el balón se lo queda, y cualquier ventaja (el club,
quién saca, un robo temprano) se convierte en dominio de 70-85 %: por eso las posesiones extremas cambian de signo según el cruce
(no es un fallo de ejes: comprobado invirtiendo local y visita). Los robos por alcance, la conducción fastidiada y los cortes
suben los cambios solo de ~21 a ~25. El siguiente paso es la **fase 4b: la cola de órdenes del original con el filtro de
animaciones** (pánico → pase → tiro, se ejecuta la primera cuya animación toca el balón) y su consecuencia en los tiros; y, con
la decisión del dueño, calibrar en la fase 6.

## 9. Fase 4b (empezada, 10-11 noche): la cola del original y POR QUÉ NO HAY REMATES

`LeagueNucleo.decidir` devuelve ya la COLA completa del original (pánico, pase y tiro se calculan siempre y en ese orden; antes
volvía en cuanto encontraba un pase), más la marca «en zona de tiro». La acción sigue siendo la primera de la cola. Diagnóstico
en `MotorLeague.cuenta` (lo imprime `comparar_motor_league`): a qué distancia del arco rival decide el portador y cuántos tiros
quedaron detrás de un pase en la cola.

| 2 partidos completos (CHI-ARG, ARG-BRA, estilos reales) | decisiones del portador |
|---|---|
| a más de 55 m del arco rival | 105 · 75 |
| entre 35 y 55 m | 48 · 145 |
| entre 20 y 35 m | **103 · 167** |
| a menos de 20 m | **11 · 17** |
| en la zona de tiro del original (radio 16 m alrededor del punto a 7 m de la línea, ≈ 23 m) | **9 · 7** |
| tiros que quedaron detrás de un pase en la cola | 2 · 0 |

**Conclusión**: la cola con el filtro de animaciones NO traerá los remates (solo 2 por partido quedaban detrás de un pase). El
cuello de botella es que el portador casi nunca llega a la zona de tiro: se queda a 20-35 m, delante del bloque defensivo de
League (la trampa del fuera de juego se sitúa a 30-50 m del arco según la ofensividad) y su conducción por campo de fuerzas lo
aparta de los 5 rivales más cercanos (repulsión 2 a 10 m frente a una atracción del arco de 0,6-1). En el original la
penetración sale del muñeco (regates con animaciones, toques largos, primer toque orientado) y de las carreras. Opciones:
(a) seguir fiel y portar la locomoción por animaciones (lo más grande que queda, ~7.600 líneas de origen); (b) calibrar ya
(zona de tiro algo mayor, más atracción del arco al conducir, línea defensiva algo más alta). Es la decisión pendiente del dueño.

### Pendiente de la 4b
La cola con el filtro (`LeagueToques.alcanza` con pass/highpass/shot, cada paso), el primer toque al recibir (L
`GetDifficultyFactors`) y la locomoción con las animaciones de `league.res`.

## 10. Fase 4c (locomoción fiel; empezada 10-11 noche, tras fusionar `main` f79abf5d)

1. **Pase largo al espacio** (fallo de fidelidad corregido): en el original el pase LARGO va por delante del receptor
   (`AI_GetPass`: +0,2 × la distancia hacia el arco rival) para el que corre al hueco; `_ejecutar` lo mandaba con nuestro
   `_pasar_a(largo)` sin ese adelanto. Ahora usa nuestro «al hueco». Efecto medido: ninguno apreciable (son pocos pases largos).
2. **Primer toque**: el del original (`GetFirstTouchContextPenalty`) YA está en nuestro motor desde el 01-11 (`MotorControl`, U5):
   no hay nada que sumar ahí.
3. **Dónde se atasca el ataque** (sonda `pruebas/_sonda/sonda_league_ataque.tscn`, con balón, cada 0,5 s; dos cruces):

| Distancia al arco rival (media) | League | Motor de siempre |
|---|---|---|
| Portador | 25,3 · 31,8 m | 56,0 · 55,3 m |
| Compañero más adelantado | 20,8 · 23,7 m | 37,1 · 35,9 m |
| Línea rival (penúltimo) | 21,5 · 36,4 m | 36,8 · 33,3 m |

Con League el equipo llega MUCHO más cerca que con el de siempre (portador a 25-32 m frente a 55 m), pero la defensa de League
espera muy hundida (su línea a 21-36 m del arco), el fuera de juego impide a los delanteros pasarla y la zona de tiro del original
empieza a ~20 m. El ataque se queda justo fuera. En el original lo que rompe ese bloque es el muñeco (regates por animación,
toques largos al espacio, giros): portarlo es lo grande que queda (~7.600 líneas de `humanoid*.cpp` + `animcollection.cpp`).

| 6 partidos completos con estilos reales (tras fusionar `main`) | Motor de siempre | MotorLeague |
|---|---|---|
| CPU por paso (µs) | 1.441 | 1.196 (−17 %) |
| Goles / remates | 6,83 / 44,7 | 2,0 / 7,8 |
| Pases / acierto | 125,8 / 77,0 % | 72,8 / 78,0 % |
| Cambios de posesión por partido | 70,5 | 28,8 |
| Posesión del local por partido | 52,6 de media | 12 · 69 · 17 · 12 · 86 · 59 |

Determinismo IGUAL; banco «FIN. 0 fallos».

### Fase 4c, parte 2: el toque de conducción del original (10-11, `main` fusionado)
`MotorLeague._mover_balon`: cada toque deja el balón donde llegará el jugador tras el retardo del original (L
`GetBallControlVector`: desiredDelayTime = (v/8)²·0,6 + 0,25 s) más el frente del pie (0,45 m) y el fastidio del rival (×3 m), en
la dirección de su conducción; la rapidez sale de la distancia con el roce portado (x = ln(1 + k·v0²/c)/2k). A toda velocidad son
toques largos de ~7 m (≈ 1.300-1.700 por partido). Bandera `LS_TOQUE=0` = sin él (solo el fastidio de la 4a).

| 6 partidos con estilos reales | Motor de siempre | League (4c-1) | League (4c-2, toque largo) |
|---|---|---|---|
| CPU por paso (µs) | 1.391 | 1.196 | 1.196 |
| Goles / remates | 6,83 / 44,7 | 2,0 / 7,8 | 2,17 / 8,3 |
| Cambios de posesión | 70,5 | 28,8 | 24,3 |
| Decisiones en la zona de tiro (2 partidos) | — | 9 · 7 | 5 · 4 |

Sin efecto en la llegada a la zona de tiro. Nota: el motor de siempre remata DE MÁS (44,7 por partido en 2 × 240 s; en el fútbol
real ≈ 24) y League DE MENOS (≈ 8). No hay cifras públicas de remates del bot de GameplayFootball / Google Research Football para
comparar (habría que medirlo con su paquete `gfootball`).

### Experimento para la decisión del dueño (no es el original): zona de tiro de 24 m
`LS_ZONA_TIRO=24` (por defecto 16, el del original) agranda el radio de la zona de tiro. 6 partidos: remates 8,3 → **10,3**,
goles 2,17 → 2,33, cambios de posesión 24,3 → 23,5. Calibrar SOLO la zona no basta: desde 24-30 m las probabilidades de tiro son
bajas y el pase sigue delante en la cola. Si el dueño elige calibrar, habría que mover a la vez la zona, la prioridad del tiro y
la profundidad del bloque defensivo.

### Fase 4c, parte 3: locomoción visual del portador (10-11, detrás de `MOTOR_LEAGUE`)
Como en el original, el portador que conduce usa los ciclos de **control de balón** de `league.res` en vez de nuestro «conducir»:
`ls_ballcontrol__walk__000` → clip `conducir_ls` (paso de referencia 5,04 m/s) y `ls_ballcontrol__sprint__000` → `conducir_ls_rapido`
(7,0 m/s). El cambio entre los dos es el umbral trote/sprint del original (`CAMBIO_TROTE_SPRINT`, 6,2 m/s) y la velocidad del clip
se ajusta a la del jugador (velocidad / referencia, entre 0,7 y 1,4) para que los pies no patinen. Código: `LeagueAnim.CICLOS_CONDUCIR`,
`conducir()` y `ciclo_de()` (paso + espejo en bucle) en `visor/league_anim.gd`; `MotorLeague._mover_jugadores` (solo con la fase 3 y
cuando no hay un gesto en curso). Revisado: `pruebas/_sonda/captura_conducir_league.tscn` (los 3 ciclos lado a lado, dos clubes de
ARG y ESP) y `pruebas/_sonda/captura_partido_league.tscn` (cámara real del partido, Forward+, Boedo AC – Madrigal CF): paso
completo, balón pegado al pie, sin poses rotas. Banco «FIN. 0 fallos»; sin cambios en el motor de siempre.

### Fase 4c, parte 4: arranques, frenadas y giros del original (10-11, detrás de `MOTOR_LEAGUE`; `LS_LOCO=0` los apaga)
Las 19 animaciones de locomoción del original (`movement/<velocidad>/*.anim`) y sus espejos. `herramientas/league_movimiento.py`
saca de su pista de raíz lo que calcula `utils/animation.cpp` (velocidad de entrada y salida escalonadas, ángulo de salida, giro
final del cuerpo) a `datos/league_movimiento.json`; `visor/league_movimiento.gd` copia la elección de `HumanoidBase::SelectAnim`
para el movimiento (entrada estricta por clase de velocidad, `GetMovementSimilarity` con `CalculateBiasForFastCornering` y las
11 direcciones preferidas). `visor/league_locomocion.gd` la aplica en el partido a los jugadores sin balón (no al portero) cuando
ARRANCAN, FRENAN o GIRAN más de ~35°: el clip se reproduce entero y los ciclos normales no lo pisan (un gesto de verdad sí).
**Solo cambia lo que se ve**: el giro del cuerpo que trae el clip se compensa en el MODELO (hijo raíz del AnimationPlayer) y
no en el nodo, cuyo giro usan alcances y entradas; posiciones, velocidades y `gesto_hasta` no se tocan. Los clips se añaden a la
biblioteca del jugador en el partido (no van en la biblioteca horneada: la caché de disco no depende de la bandera).
| 2 partidos (2 × 120 s) | `LS_LOCO=0` | `LS_LOCO=1` |
|---|---|---|
| huellas (marcador, tiros, pases) | 0-1 · 1-2 | **iguales** (determinismo IGUAL) |
| transiciones por partido | — | ~160 arranques, ~630 giros, ~450 frenadas |
| CPU por paso (sin gráficos) | ~1.110 µs | ~1.200-1.290 µs (+~9 %) |
Revisado de cerca con `pruebas/_sonda/captura_giro_league.tscn` (cámara de costado que sigue al jugador, Forward+, clubes de BRA e
ITA): un giro de ~180° encadena trote lateral → frenada inclinada → pivote → arranque, como el original, sin poses rotas.
Banco: `_probar_league_movimiento`.

### Fase 4c, parte 5: el cuerpo girado respecto a la marcha («angled») (10-11; `LS_ANGLED=0` las apaga)
Ahora entran las 49 animaciones de `movement/` (también `angled/` y `newangles/`) y las 10 plantillas de `templates/`.
- **Mirada** (L `PlayerController::_MovementCommand`, `defaultLookDirection`): el jugador sin balón gira la vista hacia el balón,
  entera parado y ~78 % a toda carrera (`LeagueMovimiento.mirada`).
- **Cuerpo** respecto a la marcha: 0, ±45 o ±135 grados (`allowedBodyDirAngles`), con los límites del original por velocidad
  (L `CalculateFactualSpatialState`: a toda carrera < 22,5°, al trote rápido < 90°, parado de frente).
- **Elección** (L `SelectAnim`): consulta estricta por velocidad Y cuerpo de entrada, mejor cuadrante de movimiento y dentro el
  que deja el cuerpo mirando más cerca de la mirada (`_KeepBestBodyDirectionAnims`, `CompareBodyDirectionSimilarity`, con el
  «contrabando» de ±18° y el castigo de 0,05 a los cuerpos girados). El cuerpo de salida es el del original
  (`GetOutgoingBodyAngle` = cuerpo final − ángulo de salida).
- **Ciclo estable** con el cuerpo girado: las plantillas (`dribbleD045`, `dribbleD135`, `walkD045` y sus `_left`); el otro pie es
  el espejo de la plantilla girada al otro lado. En el original, el paso estable es la «autogenerada» de una plantilla consigo
  misma en dirección 0, que es la propia plantilla. Si el motor pide otro paso (de espaldas, marcar, cansado) o la velocidad no
  admite el giro, el cuerpo se endereza sin salto.
- **Al acabar un clip**, como nuestra marcha no gira exactamente lo que suponía el clip, el cuerpo pasa al ángulo permitido más
  cercano a como mira de verdad y la compensación del modelo solo cubre el resto (≤ 22,5°), en ~0,25 s. Corrige también un salto
  de la parte 4 (la compensación volvía al ángulo del principio del clip).
| 2 partidos (2 × 120 s) | `LS_ANGLED=0` | `LS_ANGLED=1` |
|---|---|---|
| huellas | 0-1 · 1-2 | **iguales** (el juego no cambia) |
| clips por partido | ~250 arranques, ~950 giros, ~400 frenadas | + ~1.250 cambios de cuerpo |
| coste propio de la locomoción (cronometrado dentro del paso) | ~75-100 µs/paso | ~100-130 µs/paso (~8-10 % del paso) |
Para no pasar del +9 %: los clips se preparan por tandas (8 por paso; de una vez eran un tirón de ~0,2 s), cada jugador se
revisa cada 0,1 s escalonado (el original solo elige al acabar un clip, ~0,24 s), las consultas estrictas están precalculadas,
el cuerpo permitido se calcula con umbrales y el modelo solo se gira si cambia. Lo que queda es coste de GDScript por jugador:
candidato a la extensión C++ (fase 5). La cifra total por paso varía ±150 µs entre ejecuciones en este contenedor: por eso se
cronometra la locomoción aparte.
Revisado con `LADO=1 pruebas/_sonda/captura_giro_league.tscn` (cámara fija de costado, Forward+, BRA e ITA): carrera lateral
mirando al balón, frenada con el cuerpo a 135° y vuelta a encarar el juego, sin poses rotas.

### Fase 4c, parte 6: el pie de apoyo (10-11)
Copia de `CompareFootSimilarity` / `GetOutgoingFoot`. Cada clip empieza moviendo el pie derecho (el espejo, el izquierdo) y deja
para el siguiente el mismo pie si tiene un número par de pasos (`steps`, ahora en `datos/league_movimiento.json`) o el otro si es
impar. En el original, tras quedarse con el mejor cuadrante de movimiento y de cuerpo, las ordenaciones estables posteriores hacen
del pie el criterio que decide entre los que quedan (parado no cuenta): `LeagueMovimiento.elegir(…, pie)` toma, entre los del
mismo cuadrante que miran igual (±0,06π), el que empieza con el pie que toca. El pie que toca (`LeagueLocomocion.pie_que_toca`):
tras un clip, su pie de salida; en un ciclo, el que va en el aire (por `AnimPasos.fases`, la fase medida en que apoya el izquierdo;
en los de League y las plantillas, el derecho en la primera mitad). Efecto: al acelerar o girar ya no se repite siempre el mismo
pie (antes ganaba el primero de cada par espejado); la pierna que estaba en el aire sigue en el aire. Huellas iguales con
`LS_LOCO=0/1` (tras fusionar `main` las huellas de referencia cambiaron: 0-0 y 0-1, por cambios de `main`). Coste propio de la
locomoción: ~110-140 µs/paso.

### Fase 4c, parte 7: las intermedias del original (`GenerateAutoAnims`) (10-11; `LS_AUTO=0` las quita)
`visor/league_auto.gd` copia `GenerateAutoAnims` (L animcollection.cpp). Para cada par de plantillas (de entrada y de salida) y 9
direcciones (0, ±45, ±90, ±135, ±178°) aplica sus reglas de legalidad:
- aceleración máxima de un escalón;
- frenada máxima con el coseno del giro;
- de carrera a trote, ni de espaldas ni girando mucho;
- moviéndose, giros ≤ 90°; con carrera o trote rápido, ≤ 45°;
- no más de media vuelta.
Salen **437 legales + sus espejos = 874**. Sus datos (velocidades, ángulo, cuerpo de entrada y salida, pie) entran en la elección
como los demás clips. La animación se construye solo la primera vez que se elige (como mucho una por paso, ~1-3 ms cada una):
- cada hueso se mezcla con la curva del original (`bias` según cuadro, velocidades y cambio de movimiento, `curve(…, 0,7)`);
- la pelvis gira hacia la nueva dirección (`angle · (bias·0,7 + orig·0,3)`, sobre la vertical del esqueleto);
- la altura se interpola;
- sin la inclinación hacia la curva (≤ 2°).
Para que la elección siga siendo barata con 972 clips, la similitud de movimiento se calcula una vez por cuadrante de salida (solo
depende de él) y no por clip.
Medido (2 partidos de 2 × 120 s): huellas IGUALES con `LS_AUTO=0/1`; las intermedias ganan ~80 % de las elecciones; `elegir`
~55 µs por llamada; construcción ~0,5 s repartida en el primer partido de la sesión (luego quedan en la biblioteca). Coste propio
de la locomoción: ~110-125 µs/paso sin intermedias, ~160-190 con ellas mientras se construyen (en régimen, ~140).
Revisado:
- `pruebas/_sonda/captura_auto_league.tscn` (de cerca, ARG y BRA): de parado a trote girando 90° a la izquierda y su espejo a la
  derecha; de trote a trote con el cuerpo pasando a 135°. El sentido del giro y las poses son correctos.
- La sonda de giros en el partido: un giro de ~180° encadenado con intermedias, natural.
Con esto la LOCOMOCIÓN del original queda portada entera para los jugadores sin balón; el portador usa los ciclos con balón
(parte 3). Pendiente: la inclinación hacia la curva de las intermedias y llevar esta capa a C++ si el coste molesta.

### ¿Gemelo C++ de la locomoción? Medición y propuesta (10-11, pendiente de OK de la líder)
3 partidos seguidos (2 × 120 s, cronometrado dentro del paso; el 3.º ya con casi todas las intermedias construidas):
| por paso (µs) | partido 1 | partido 2 | partido 3 |
|---|---|---|---|
| locomoción entera | 213 | 179 | **152** |
| · evaluar a quién toca (cada 0,1 s) | 133 | 94 | 67 |
| · · de eso, `elegir` (cálculo puro) | 19 | 21 | 18 |
| · · de eso, construir intermedias (cálculo puro, una vez por sesión) | 63 | 39 | 17 |
| · bucle por fotograma (diccionarios del jugador, AnimationPlayer, giro del modelo) | 80 | 85 | 86 |
| paso del motor entero | ~1.610 | ~1.660 | ~1.535 |
Lo que se puede llevar a C++ como función pura con su gemelo exacto (`elegir`, la mezcla de `LeagueAuto.construir`) es ~35 µs/paso
en régimen (~2 % del paso) y ~0,5 s de construcción por sesión. El resto (~120 µs) es acceso a los diccionarios del jugador y
llamadas al motor de Godot, que desde C++ siguen pasando por Variant: ganaría poco y obligaría a duplicar ~600 líneas.
Además la extensión solo existe para Linux y Windows: en Android y Web (donde la prueba del dueño dio 5 FPS con la GPU al 100 % y
la CPU al 0 %) correría igual el GDScript, así que el C++ no ayuda al móvil.
**Propuesta: NO hacer el gemelo C++ ahora.** En su lugar, una mejora en GDScript que sí sirve en todas las plataformas: no revisar
ni animar transiciones de los jugadores fuera de cámara o lejos de ella (solo visual; se puede medir con las mismas huellas). Si
aun así hiciera falta, pasar solo `elegir` y la mezcla de las intermedias (funciones puras, copia exacta y `probar_nativo`).

### Hecho tras la propuesta (10-11, aprobado por la líder): recorte fuera de cámara + gemelo C++ de lo puro
**1. Recorte fuera de cámara** (`LS_FUERA_CAMARA=0` lo apaga; encendido por defecto):
- quien está fuera del encuadre de la cámara activa o a más de 70 m no empieza clips nuevos (los que lleva acaban normal) y, si iba
  con el cuerpo girado, se endereza;
- con el cuerpo girado, la lógica del ciclo va a la cadencia de 0,1 s (en cada fotograma solo la velocidad del clip);
- la recolocación acaba a 0,01 rad;
- cronómetro propio barato: `LeagueLocomocion.us_total` / `pasos`.
Medido con `LS_CAM=1` en `comparar_motor_league` (cámara de televisión que sigue al balón), 3 partidos, µs/paso de la capa:
| | partido 1 | partido 2 | partido 3 | huellas |
|---|---|---|---|---|
| sin recorte | 189 | 147 | 127 | iguales |
| con recorte | 154 | 123 | 120 | iguales |
Transiciones: ~2.800 → ~1.500 por partido (las que no se ven).
**2. Gemelo C++ de lo puro** (`nativo/src/league_nativo.cpp`):
- `league_elegir` = `LeagueMovimiento.elegir_gd`;
- `league_legal` = `LeagueAuto.legal_gd`;
- `league_mezclar` = `LeagueAuto.mezclar_gd`.
Son copia literal; el GDScript se queda de respaldo para Android sin binario, Web y `DINASTIA_SIN_NATIVO=1`.
`pruebas/probar_nativo.tscn` (`ProbarNativoLeague`): iguales en 4.000 elecciones al azar, en toda la tabla de legalidad y en 40
intermedias clave a clave. Velocidad: elegir 11-21 → 4-6 µs; intermedia 173-193 → 105-109 µs.
Binarios recompilados para Linux y Windows. Huellas IGUALES con y sin la extensión. µs/paso de la capa (con recorte): sin
extensión 170 / 124 / 128, con ella 146 / 120 / 123.
**Conclusión:** en régimen la capa queda en ~120 µs/paso (antes ~150). No llega a ≤ 110: lo que queda (~110 µs) es acceso a los
diccionarios de cada jugador (Variant) y llamadas a AnimationPlayer y Node por fotograma, y eso no se gana con C++ (seguiría
pasando por Variant). Bajarlo más pediría cambiar la estructura de datos del motor (jugadores como objetos con campos tipados en
vez de diccionarios), que es una decisión de todo el motor, no de esta capa.

## 11. Fase 4d (sesión 9, 11-11): catálogo etiquetado y locomoción que guía el movimiento

**Catálogo extensible** (`visor/league_catalogo.gd`, `datos/anims_extra/*.json`, formato en `datos/anims_extra/LEEME.md`): cada clip
lleva etiquetas (tipo, velocidad de entrada y salida, ángulo, cuerpo, pie, duración); otras sesiones suman animaciones gratuitas con un
JSON y la elección (`LeagueMovimiento.elegir`) las ve igual que a las del original; con un empate gana el original. Búsqueda general
por etiquetas: `LeagueCatalogo.buscar(filtro, deseo)`. Banco: «MOTOR LEAGUE: CATÁLOGO ETIQUETADO Y EXTENSIBLE». No trae el extractor de
etiquetas desde la pista de raíz de un clip ajeno (hoy se etiquetan a mano).

**Guía del movimiento** (`visor/league_guia.gd`, `LS_GUIA=0` la apaga, `LS_MARCHAS=0` solo las marchas): la velocidad y el rumbo
siguen el clip de arranque, frenada o giro (mezcla suave; más pegada en la CPU, menos en el jugador para que responda), el clip se
corta si lo pedido cambia de golpe (pausa de 0,5 s tras el corte) y a ritmo de crucero la velocidad se asienta en 3,5 / 5 / la propia.
La decisión usa solo estado físico: no depende de cámara ni de clips cargados (con eso sí dependía y rompía el determinismo).
Se aplica tras el paso del motor (no se toca `motor_jugable_p5`). El toque en el cuadro de contacto de los golpeos ya existía (`LeagueAnim.GOLPEOS`).

| 3 cruces (CHI-ARG, ARG-BRA, BRA-ESP), 2 × 120 s | sin guía | con guía |
|---|---|---|
| aceleración media / p95 (m/s²) | 4,73 / 18 | 4,68 / 17 |
| giro medio (rad/s) | 1,06 | 1,05 |
| remates · cambios de posesión | 4,7 · 13,3 | 2,7 · 10,7 |
Determinismo IGUAL; «FIN. 0 fallos». Una primera versión (guía pegada al clip) daba −15 % de sacudidas pero rompía el determinismo y en un
partido hubo 3.085 arranques seguidos (bucle de corte y reinicio): corregido con la decisión física y la pausa. **Lectura honesta**:
con 3 partidos las diferencias de remates y posesión son ruido; el efecto en el movimiento es pequeño. Pendiente: calibrar con 6+
partidos y capturas con la cámara real, y decidir la fuerza (K_CPU, K_USUARIO) por cómo se siente, no por cifras.

### Calibración con 6 cruces y respuesta del humano (11-11, tras el bloque 1)
6 partidos de 2 × 90 s, clubes de CHI, ARG, ESP, BRA, ENG e ITA (cruces y estilos distintos), `comparar_motor_league`:
| | guía apagada | guía encendida |
|---|---|---|
| aceleración media / p95 (m/s²) | 4,72 / 18 | 4,80 / 17-18 |
| giro medio (rad/s) | 1,13 | 0,95 (−15 %) |
| cambios de posesión · acierto de pase | 5,2 · 83,7 % | **9,5 · 71,3 %** (más disputa) |
| remates · goles por partido | 2,8 · 0,5 | 2,7 · 0,17 (ruido: 6 partidos) |
| CPU por paso (µs) | 1.528 | 1.615 (+6 %) |
Determinismo IGUAL con y sin guía. Lectura: la guía no cambia los remates, pero el balón cambia más de dueño y el pase es más
discutido (el giro comprometido de quien conduce da al defensa tiempo de llegar): va en la dirección de más diversión.
**Jugador humano** (`pruebas/_sonda/sonda_league_humano.tscn`, corre a tope y recibe órdenes bruscas; 3 cruces): la guía solo le aplica
la curva de VELOCIDAD del clip (el rumbo lo manda su stick) y el clip se corta si lo pedido se aparta ~30°. Segundos hasta obedecer:
giro 90° 0,49 → 0,47; giro 180° 0,89 → 0,69; parar 0,59 → 0,50. La sonda falla si la guía retrasa más de 0,15 s.
**Animaciones de 100STYLE** (sesión 10, `datos/anims_extra/estilo100.json`, 82 entradas): el catálogo las acepta sin avisos, pero son
ciclos estables (trote ~1,9 m/s y reposos), así que la elección de arranques, frenadas y giros las descarta por diseño (`estable`).
Quedan para variedad de reposo y de trote lento: pendiente un consumidor (elegir el reposo de cada jugador por su id).

### Bloque 3 (11-11): precarga, falta leve, celebraciones de CMU
- **Precarga** (`LeagueLocomocion.precargar`, llamada en `MotorLeague.preparar`): el primer paso de la locomoción gastaba ~185 ms en abrir las
  bibliotecas de animación; ahora van antes del saque (`pruebas/_sonda/sonda_primer_paso.tscn`: 0 pasos > 8 ms en 6.000). Además las
  extras de 100STYLE ya NO se cargan por tandas en cada jugador (~450 ms por tanda): se cargan al elegirlas, y las estables nunca.
- **`LeagueAcciones`** (`LS_ACCIONES=0` la apaga; solo cambia qué clip se ve): falta leve (1 de cada 3 veces el que pierde un choque de hombros
  recibe `Hit_Chest` / `Hit_Head` de la UAL) y celebración del gol (2 de cada 5 veces un baile o alegría de CMU, recortado a 6 s: salsa en
  solitario, alegría, risa, charleston). Con jugadores reales: 44 de 110 celebraciones con CMU.
- **Pendiente**: disputa aérea (`Jump_*`: el motor tendría que levantar al jugador; hoy el cabezazo no despega a nadie); ciclos de carrera de
  CMU como variedad de trote (necesitan escalar la velocidad del clip para no patinar); recortar las transiciones y patadas de CMU (son
  grabaciones de 3-15 s, no recortes). Fotos de la guía con cámara real en `capturas_guia_2026-11-11/` (en foto fija no se aprecia: el
  vídeo queda como NO verificable aquí; lo verá el dueño en su teléfono con el selector a ciegas).

## 12. C4 mejorado (sesión 9, 11-11, orden 39 del dueño; CIERRE)
C4 = `combinado_c4` (League + NUESTRA decisión con balón + NUESTRA colocación con caché de 0,1 s + NUESTRA locomoción).
**Hecho**
1. **Celebraciones de CMU** y **faltas leves** (`LeagueAcciones`, `MotorLeague._anim`): funcionan también en C4 (lo hereda). Al motor de siempre no se toca (queda de respaldo, orden del líder).
2. **Guía de animaciones en C4**: probada y dejada **APAGADA** (`LS_GUIA_C4=1` la enciende; 7 líneas al final de `MotorCombinado._mover_jugadores`).
   Motivo, 6 cruces `MITAD=120`: duelos 28,8 → 22,0, regates 18,3 → 15,8, acierto de pase 68 → 63 %, CPU +18 % (1.182 → 1.392 µs/paso).
3. **Qué baja las cadenas de pases** (ablaciones, `MITAD=120`, 6 cruces): NO es la caché de colocación (sin caché: 0,17 cadenas de 5+ frente a 0,5 y CPU +50 %) ni la locomoción;
   es NUESTRA colocación sin balón. Con la de League y locomoción nuestra: acierto 84 %, cadenas de 5+ 2,3, pero duelos 7,7 y regates 9,7 (el partido quieto).
   Con la nuestra: duelos 29 y regates 18, pero acierto 67 % y cadenas de 5+ 0,5. Es un intercambio entre roce y construcción.
4. **HÍBRIDO de ataque** (`C_ATAQUE_LEAGUE=1`, APAGADO por defecto, en `MotorCombinado`): el equipo con balón se apoya con el campo de fuerzas de League
   (triángulos de pase) y el que defiende sigue con nuestra colocación. Medido con `MOTORES=combinado_c4`, `MITAD=240`, 6 cruces por tanda (la definición de la sesión 11):
   | por partido | C4 | híbrido | C4 (invertido) | híbrido (invertido) |
   |---|---|---|---|---|
   | acierto de pase | 70,7 % | 76,8 % | 74,3 % | 75,6 % |
   | cadenas de 5+ pases · cadena máxima | 1,0 · 5,0 | **3,7 · 6,7** | 0,83 · 5,7 | **2,3 · 7,3** |
   | regates (logrados) | 22,0 (10,5) | 26,3 (13,8) | 23,8 (10,5) | 25,3 (11,0) |
   | duelos · robos | 44,8 · 13,0 | 42,2 · 12,2 | 47,2 · 12,7 | 45,5 · 15,2 |
   | goles · remates | 4,67 · 45,0 | 4,50 · 34,0 | 5,67 · 45,0 | 6,17 · 40,3 |
   | ocasiones claras | 3,7 | **1,3** | 3,2 | **1,5** |
   | CPU (µs/paso) | 1.281 | 1.527 (+19 %) | 1.223 | 1.390 (+14 %) |
   Lectura: más juego construido y más regates con los mismos goles y duelos; a cambio MENOS remates y ocasiones claras y +14-19 % de CPU. El líder lo pidió SIN poner por defecto.
**Falta (siguiente tanda, sin empezar)**
- Recuperar las ocasiones del híbrido: apoyo de League solo hasta el último tercio y nuestra colocación de ataque después (`C_TERCIO`, código escrito, SIN MEDIR, 0 por defecto = la versión medida);
  más DESMARQUES, BALONES LARGOS (cambios de orientación y a la espalda de la defensa), balón parado y sprints sin balón (ideas del dueño en `PLAN_GENERAL.md`): pueden ser justo lo que devuelva las ocasiones.
- Bajar la CPU del híbrido: recalcular el estado de League (balón previsto, marcajes, presión) cada 0,1 s (`C_CADENCIA_ESTADO`, código escrito, SIN MEDIR, 0 por defecto); ver si el apoyo necesita la predicción completa.
- Disputa aérea (`Jump_*`: el motor debe levantar al jugador; hoy el cabezazo no despega a nadie); recortar las transiciones y patadas de CMU (son grabaciones de 3-15 s); ciclos de carrera de CMU como variedad de trote (hay que escalar la velocidad del clip).
- Guía en C4: solo si se rediseña (hoy empeora duelos y regates). Foto fija con cámara real no demuestra la guía: el vídeo queda como NO verificable aquí.

## Mejoras de C4 (líder, 11-11; ideas del dueño)
`visor/mejoras_c4.gd` (`MejorasC4`), solo en C4 (`MotorCombinado.aplicar_variante("combinado_c4")`); el motor de siempre no cambia
(huellas iguales). Banderas: `C4_DESMARQUES`, `C4_SPRINTS`, `C4_LARGOS` (las tres ENCENDIDAS por defecto).
- **Desmarques**: dos carreras al espacio a la vez (`MotorCarreras` con «plazas» por metadatos del motor), también de MCO/MD/MI, descanso de 2 s (antes 4) y la segunda carrera al otro lado del hueco.
- **Sprints sin balón**: quien queda a más de 9 m de su destino (atacando o replegando) corre.
- **Balones largos**: lejos del arco (> 45 m), pase largo al hueco al que hace la carrera (22-55 m, línea limpia, habilitado).
Medido con `comparar_tres_motores` (MOTORES=combinado_c4, MITAD=240, CHI/ESP/BRA, 6 partidos normales + 6 con INVERTIR=1), C4 → C4 mejorado:
cadenas de 5+ 0,92 → 1,50; goles 5,2 → 6,5; duelos 46 → 47,7; ocasiones 3,4 → 3,6; regates 22,9 → 22,5; CPU igual (~950 µs/paso).
Por separado (6 partidos, ruido alto): desmarques suben duelos y regates; balones largos suben goles de jugada (4 → 8) pero bajan ocasiones claras; sprints casi neutros.
Pendiente: balón parado (córners, faltas, saques de banda), cabezazos (0 goles de cabeza en casi todas las tandas), disputa aérea.
- **Balón parado** (`C4_BALON_PARADO`, encendido; `C4_CENTROS` aparte): diagnóstico con los contadores del motor (`diag`, ahora en `TRES_JSON`): C4 hacía 0,3 centros en juego, 1,2 cabezazos y 30 de 45 tiros desde lejos por partido, con 4,5 córners. Hecho: córners por desvío al 20 % (`MotorCorner.desvio` lee el metadato `corner_desvio` del motor; el de siempre sigue con la bandera `CORNER_DESVIO`) → 7,8 córners y goles de córner 1,2 → 1,8; y centro desde la banda con ≥ 2 compañeros en el área (sale poco, 0,3-0,7, porque el portador casi nunca llega a la banda cerca del fondo). Coste: las cadenas de 5+ bajan (más balón parado, menos posesión larga; con 30 % de desvío bajaban más). FALTA: que los extremos encaren por la banda hacia el fondo (para que el centro salga de verdad), remate de cabeza más rico y saques de banda/faltas ensayadas.
- **Encarar por la banda + llegada al área (12-11, PROBADO Y DESCARTADO)**: el de banda conducía pegado a la línea y el 9, el mediapunta y el extremo contrario atacaban primer palo, penal y segundo palo. Medido en ambos sentidos: centros 0,2-0,5 por partido (sin cambio), regates −2, ocasiones sin cambio. Diagnóstico con contadores: el portador llega a la zona de centro solo ~4 veces por partido; antes ya ha TIRADO DE LEJOS (~28-31 tiros lejanos de ~45 por partido). La palanca real es la decisión de tiro lejano de nuestra «decisión con balón» (`motor_jugable_p7.gd`: `ganas_tiro`, `CHISPA_TIRO`, `MotorTiroLimpio.alcance`) en C4. Se revirtió el código.
- **Paciencia ante el tiro lejano + encarar por la banda (12-11, sesión 13; SE QUEDAN, encendidas en C4)**. Causa medida: con la decisión de siempre se tiraba casi en cuanto se decidía a menos de ~45 m (`MotorTiroLimpio.alcance(30) × 1,5` y umbral 0,05, sin azar con `TIRO_REAL`). Gancho `_ganas_tiro_extra` en `motor_jugable_p7.gd` (neutro en el motor de siempre, sin azar: huellas `igualdad_motor` 2244399493 e `igualdad_mundo` 2180788566 iguales); C4 lo cambia por `MejorasC4.ganas_tiro`: desde `C4_PAC_D`=22 m el tiro es un sorteo (0,55 a 22 m, −0,035 por metro, × (0,6 + 0,8·tiro), × 0,6 con espacio, × 0,35 con un compañero mejor colocado). `C4_BANDA`: el portador abierto (|x| > 13, a 8-40 m del fondo, sin rival delante en su carril) conduce pegado a la banda hacia el fondo. Banco: `_probar_paciencia_c4`.
  Medido (MOTORES=combinado_c4, MITAD=240, CHI/ESP/BRA, 6 normales / 6 con INVERTIR=1), base → paciencia + banda: tiros lejanos 31,0/31,5 → 9,0/7,7; tiros 47,7/47,7 → 24,2/24,8; cadenas de 5+ 0,5/1,2 → 1,8/3,5; regates 22,3/22,3 → 24,5/29,5; centros 0,7/0,3 → 2,3/1,2; cabezazos 1,5/1,5 → 1,7/2,0; duelos 44/51 → 46/43; goles 6,0/6,2 → 4,5/5,0 (los que se pierden venían de rebotes de tiros lejanos: córners por desvío, goles de lejos y tras saque de puerta; los de jugada se mantienen ~1,1). CPU sin carga: 853 → 885 µs/paso.
  PROBADO Y DESCARTADO: paciencia sola (goles 4,2/3,7, sin la banda no llegan al área); pase directo al mejor colocado (`C4_PASE_MEJOR`, apagado: goles 4,3/2,8 sin la banda y 3,2/3,7 con ella); paciencia más suave (`C4_PAC_BASE=0.8 C4_PAC_CAIDA=0.04`: tiros lejanos 12-16, goles 4,2/4,2, y 4,5/6,2 con la banda: una tanda sube y la otra no); desvío a córner del 40 % (`C4_DESVIO=0.4`, perilla nueva: +0,3 córners, goles 4,0/4,8, sin mejora).
  FALTA: que el centro acabe en remate de cabeza (goles de cabeza siguen en 0,2-0,5), más llegada al área con el balón (los tiros desde dentro no suben: 6-8 por partido), saques de banda y faltas ensayadas, portero y rechaces.
- **Ir al balón aéreo (12-11, sesión 13; PROBADO Y DESCARTADO, `C4_AEREO` apagado)**. Causa encontrada: el receptor de un pase corre a `_punto_de_recepcion`, que proyecta el balón en el SUELO ~0,6 s por delante; con un centro el rematador llega tarde al radio del cabezazo (0,8 m, balón a 1,5-2,4 m). `MejorasC4.punto_aereo` predice dónde baja el balón a la cabeza (1,9 m) cerca del área. Variantes: en todo balón alto (aer1), solo si cae cerca de un área (`C4_AEREO_AREA`, aer3), solo tras un centro (aer4) y tras un centro o un córner (`C4_AEREO_CENTRO`, aer5); radio del cabezazo 1,1 m (`C4_RADIO_CABEZA`, gancho `_radio_cabezazo`, aer2). Siempre sube el cabezazo (1,7-2,0 → 3,3-4,5) y el gol de cabeza (0,3-0,4 → 0,7-0,8), pero el cabezazo SUSTITUYE al control y tiro con el pie, que convierte más: con 12+12 partidos (aer5 frente a la base) goles 4,0/5,6 → 3,6/4,1 (de pie 3,1 → 2,2). Con el criterio del líder (no bajar de ~4,5 goles) no se queda. Para retomarlo haría falta que el cabezazo convierta más (`MotorCorner.cabeza`, error del cabezazo) o que solo vaya de cabeza el que no puede controlar.
