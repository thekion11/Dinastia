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
| 3 | IA SIN balón de League: estrategias por puesto (`strategies/offtheball/default_*.cpp`, `goalie_default.cpp`), presión de equipo y de zona (`ApplyTeamPressure`, `ApplyZonePressure`), marcaje al hombre (`CalculateManMarking`), carreras al espacio (`ApplyAttackingRun`); ventaja del árbitro y tarjetas pendientes (R1, ya parcial en `MotorVentaja`) | La misma comparación + `auditoria_arbitro_limite` | pendiente |
| 4 | **Locomoción guiada por animaciones** (L humanoid + animcollection): elegir la animación de `league.res` que encaja con la orden y tocar el balón en su cuadro de contacto; velocidades cuantizadas (parado 0, conducción 3,5, trote 5, sprint 8 m/s) y giros con inercia | Capturas con la CÁMARA REAL (`herramientas/captura.sh`), vídeo del partido, `mem_*` | pendiente (lo más grande: ~7.600 líneas de origen) |
| 5 | Rendimiento: medir en `hw_modesto.sh` y en el teléfono del dueño; si la CPU de la IA pesa, pasar a C++ (`nativo/src`) las 3 funciones calientes con su gemelo GDScript | `probar_nativo.tscn` «FIN. 0 fallos», `medir_motor_cpu` | pendiente |
| 6 | Calibrar contra el fútbol real y el motor de hoy (remates 20-26, goles 2,5-2,9, acierto de pase 80-85 %, posesión 50 ± 8) y proponer al dueño el cambio por defecto | `comparar_motor_league` con 16+ partidos | pendiente |
| 7 | Por defecto (con OK del dueño): `MotorLeague.crear()` en el estadio y el partido jugable; el motor de siempre queda como respaldo detrás de la bandera inversa | banco completo con la bandera encendida | pendiente |

---

## 6. Prototipo (fase 2): cifras

(se rellena con la salida de `comparar_motor_league.tscn`)
