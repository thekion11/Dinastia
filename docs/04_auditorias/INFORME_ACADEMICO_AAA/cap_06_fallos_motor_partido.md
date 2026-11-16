# Capítulo 6. Fallos del motor del partido jugable: auditoría estática de corrección

Informe académico AAA de Dinastía · Redacción: 16-11-2026 · Rama auditada: la de trabajo de esta sesión, al día con `main` (último cambio del motor: 15-11, paso a C++ del movimiento de los 22).
Convenciones del informe (ver `00_INDICE.md`): [M] medido o calculado · [D] documento del proyecto · [E] estimación · [F] fuente externa. Este capítulo **no corrige código**: describe, localiza y propone. Los arreglos se harán después, con `herramientas/banco.sh` en «FIN. 0 fallos».

---

## Resumen

Este capítulo audita, sin ejecutar el juego, la corrección del motor del partido jugable de Dinastía en su configuración por defecto, el **motor C4** (orden 39 del dueño): la cadena de doce capas de `MotorJugable`, la capa de League-Soccer (`MotorLeague`), el combinado (`MotorCombinado`) con sus piezas y las `MejorasC4`, los módulos de IA que cuelgan del bucle (`MotorMente`, `MotorPresion`, `MotorCarreras`, `MotorColocacion`…), las gemelas C++ de la extensión nativa (`mover_nativo.cpp`, `cuerpos_nativo.cpp`, `estado_nativo.cpp`) y los dos lugares donde el motor se integra en una pantalla (`VistaEstadio` y `PartidoJugable`). Se revisaron unas 12.700 líneas en 54 archivos, 8.900 de ellas en lectura completa.

Se registran **26 hallazgos**: **5 de gravedad alta**, **8 media** y **13 baja**; 21 quedan **CONFIRMADOS** por lectura del código y de sus llamadores (en un caso, además, con un cálculo numérico reproducible) y 5 como **PLAUSIBLES**. No se encontró ningún fallo que cuelgue el juego en el camino normal; los fallos graves son de tres familias:

1. **La entrada del jugador dentro de un paso fijo** (M6-01). En el estadio, el motor da 0, 1 o varios pasos de 1/60 s por fotograma desde `_process`, y cada paso lee `Input.is_action_just_pressed`. A más de 60 fps se **pierde** cerca de la mitad de las pulsaciones; a 30 fps o menos se **duplican**: el cambio de jugador se anula a sí mismo, un toque simple cuenta como doble toque y la «presión de equipo» de la cruceta se queda puesta para siempre.
2. **El reloj `t` que vuelve a cero en cada mitad** frente a decenas de plazos absolutos (`…_hasta = t + x`) que no se reinician (M6-02, M6-03, M6-08, M6-09). El caso más visible: si alguien golpeó el balón en el último tercio de segundo de la primera parte, su cuerpo queda **girado hacia ese golpeo durante casi todo el segundo tiempo**, y con él la dirección en que conduce; la CPU en Practicante y Cadete ve a los rivales **donde estaban al final del primer tiempo**.
3. **El reglamento**: el **fuera de juego no se pita nunca en un remate o pase de primera** (cabezazo incluido), porque solo se juzga cuando alguien *controla* el balón (M6-04); y en el modo entrenador, al rehacer el estadio tras el descanso, **las amarillas del primer tiempo se olvidan** y una segunda amarilla no expulsa (M6-05).

A estos se suma un hallazgo de calibración propio de C4 (M6-06): C4 mueve el balón suelto con la física de League-Soccer, pero calcula la fuerza de los pases con el modelo de rozamiento del motor de siempre; el cálculo muestra que un **pase manual de 12 m rueda unos 8 m**, y uno de la IA de 30 m se queda a unos 23 m. Las gemelas C++ revisadas son copias fieles de su GDScript; el único incumplimiento de las reglas fijas del proyecto es un archivo de 486 líneas (M6-12).

---

## 6.1 Introducción

### 6.1.1 Problema

Desde el 11-11 el partido jugable usa por defecto el motor **C4**: el núcleo portado de League-Soccer (Apache 2.0) con cuatro piezas que se pueden cambiar por las nuestras, de las que C4 cambia tres (decisión con balón, colocación sin balón y locomoción) y deja la cuarta (física del balón suelto) en la de League [D: `visor/motor_combinado.gd`, `datos/motor_c_piezas.json`]. Sobre esa base se montaron, entre el 12 y el 15-11, una veintena de mejoras con bandera (`MejorasC4*`), el paso a C++ de varias partes calientes y los ganchos que las conectan. El motor tiene una batería de pruebas amplia (banco, especiales, sondas de calibración, `probar_nativo.tscn`), pero esas pruebas miden sobre todo **cifras agregadas** (goles, tiros, pases buenos por partido) e **igualdad de bytes** entre gemelas; casi ninguna recorre las fronteras del partido —el descanso, la prórroga, el cambio de ritmo, el estadio rehecho, la frecuencia de fotogramas real del dispositivo— donde suelen esconderse los fallos de estado.

### 6.1.2 Objetivo y preguntas

El objetivo es localizar **fallos reales de corrección** —no de estilo ni de diseño— con la precisión suficiente para que se puedan arreglar sin volver a investigarlos. Las preguntas guía fueron:

- P1. ¿Hay errores de lógica, divisiones por cero, accesos nulos o fuera de rango en el camino del partido?
- P2. ¿Qué estado no se reinicia al cambiar de mitad, de partido o de motor?
- P3. ¿Se aplican de verdad las banderas y ajustes que el jugador o el dueño eligen (clima, ritmo, dificultad, piezas de C4)?
- P4. ¿Coinciden las gemelas C++ con su GDScript?
- P5. ¿Está bien implementado el reglamento (fuera de juego, ventaja, tarjetas, saques, penales, tanda)?
- P6. ¿Es determinista la simulación con la misma semilla?
- P7. ¿Se cumplen las reglas fijas del proyecto (CLAUDE.md)?

### 6.1.3 Alcance

Dentro: todo lo que corre en un paso del motor jugable con C4, y las dos pantallas que lo conducen. Fuera: la jugabilidad y las cifras de calibración (decisión del dueño: orden 23 y 38-39), lo visual que no altera el estado, el simulado de la IA (`PartidoRapido`/`simular_90`) salvo una revisión de sus divisiones y de su contrato con la gemela, y los motores alternativos del selector A/B/C, que solo se citan cuando comparten el fallo.

---

## 6.2 Método

### 6.2.1 Material revisado

| Bloque | Archivos | Líneas | Lectura |
|---|---|---:|---|
| `MotorJugable` (12 capas + 2 subcapas) | `visor/motor_jugable.gd`, `_p1` … `_p11`, `_p7_p1`, `_p8_p1` | 5.102 | completa |
| Combinado C4 | `visor/motor_combinado.gd`, `motor_fabrica.gd` | 358 | completa |
| Mejoras de C4 | `visor/mejoras_c4.gd`, `_p1`, `_adelanto`, `_pared`, `_avance`, `_cabeza`, `_hueco`, `_regate` | 1.086 | completa en `mejoras_c4`, `_p1` (hasta la línea 220), `_adelanto`; dirigida en el resto |
| Capa League | `visor/motor_league.gd`, `motor_league_p1.gd`, `league_nucleo.gd`, `league_equipo.gd`, `league_acciones.gd` | 1.753 | dirigida (balón, decisión, estado, línea, acciones) |
| Módulos de IA y reglas | `motor_ventaja`, `motor_siete`, `motor_cambio_portero`, `motor_parada`, `motor_mente`, `motor_colocacion`, `motor_adaptacion`, `motor_carreras`, `motor_presion`, `motor_roles`, `penal_portero`, `salida_portero`, `gesto_tecnico` | 873 | completa salvo `motor_roles`, `salida_portero`, `gesto_tecnico` (dirigida) |
| Extensión C++ | `nativo/src/mover_nativo.cpp`, `cuerpos_nativo.cpp`, `estado_nativo.cpp`, `partido_90.cpp` | 920 | completa en las tres primeras (`estado_nativo` hasta la línea 140); dirigida en `partido_90` |
| Integración | `ui/estadio.gd`, `estadio_p2.gd`, `estadio_p5.gd`, `partido_jugable.gd`, `_p1`, `_tanda`, `ui/partido_vivo_p1.gd` | ~2.300 | dirigida (bucle del motor, descanso, ritmo, señales) |
| Núcleo | `nucleo/partido_rapido.gd`, `balance.gd`, `partido.gd` (tarjetas y estadísticas externas) | ~400 | dirigida |

Total: unas **12.700 líneas** en 54 archivos, de las que unas **8.900** se leyeron completas [M]. Se usaron además las pruebas `pruebas/probar_nativo.gd` (para saber qué cubre la igualdad de gemelas) y la herramienta `herramientas/revisar_lineas.py`.

### 6.2.2 Procedimiento

1. **Mapa del motor.** Se reconstruyó la cadena de herencia (`extends`) y el orden exacto de llamadas dentro de `paso()` (§6.3).
2. **Lectura por capas**, de la 1 a la 12, anotando para cada función: qué estado escribe, con qué reloj (`t`, `_t_estado`, `_t_arb`, `delta`) y quién la llama.
3. **Búsquedas transversales** con patrones concretos: azar sin semilla (`randf(` fuera de `_rng`), estado estático mutable (`static var … := {}`), plazos absolutos (`= t +`), lecturas de entrada (`is_action_just_pressed`), diccionarios de jugador usados como clave, comparaciones de flotantes con `==`, accesos a `p["anim"]` sin comprobar.
4. **Comparación de gemelas** operación por operación (C++ frente a GDScript), y lectura de lo que la prueba de igualdad cubre y no cubre.
5. **Verificación de cada sospecha** leyendo el código alrededor y **todos** sus llamadores; si un escenario no pudo trazarse hasta el final, el hallazgo queda como PLAUSIBLE.
6. **Cálculo numérico** donde hacía falta una cifra (M6-06): un guion de Python que integra las dos leyes de frenado con los mismos pasos y constantes que el código (se cita el resultado; el guion no va al repositorio).

### 6.2.3 Criterios

- **Fallo**: el código hace algo distinto de lo que su propio comentario, su llamador, el reglamento del fútbol o una regla del proyecto dicen que debe hacer, en un escenario alcanzable desde el juego.
- **Gravedad.** *Alta*: afecta a cada partido o a una mecánica central (control, reglamento, IA de un equipo) de forma visible y sin que el jugador pueda evitarlo. *Media*: afecta a una configuración concreta (un modo, un motor del selector, un clima), a estadísticas oficiales o a una regla del proyecto. *Baja*: caso raro, efecto cosmético o diferencia pequeña con el reglamento.
- **Veredicto.** *CONFIRMADO*: la cadena causa → efecto se sigue entera en el código. *PLAUSIBLE*: la causa existe pero falta probar que el escenario se da en el juego (por ejemplo, que un dato llegue nulo).
- Se descartó lo que solo es estilo, lo que las cifras de calibración ya absorben a propósito, y lo dudoso que no pudo trazarse.

### 6.2.4 Límites

No se ejecutó Godot. Las estimaciones de frecuencia llevan [E]. La lectura de la capa League y del simulado fue dirigida: puede haber fallos ahí que este capítulo no ve. La semántica de `Input.is_action_just_pressed` que sostiene M6-01 es la documentada por el motor (devuelve verdadero en el fotograma de proceso o en el tic de física en que empezó la pulsación); conviene confirmarla con una prueba de un minuto antes de arreglar.

---

## 6.3 Arquitectura del motor

### 6.3.1 La cadena de clases

```
Node
 └─ motor_jugable_p1.gd   capa 1: estado, constantes, atributos, dificultad, ganchos (_radio_cabezazo, _guia_pase…)
     └─ _p2   montaje (preparar), saques, cambios, nota, tácticas, expulsión, reloj de mitad
         └─ _p3   control de equipo, cansancio, añadido, árbitro, tanda (orden), fin de mitad, gol, postes y líneas, colocación del portero
             └─ _p4   balón (conducción y vuelo), duelos dividido y hombro, faltas y tarjetas, ventaja
                 └─ _p5   agarrón, movimiento de los 22 (GDScript / C++), animación, fuera de juego, _tomar, gesto del golpeo
                     └─ _p6   _patear, cabezazo, entrada, disputas, recepción, jugadas, mejor pase, _pasar_a
                         └─ _p7_p1 → _p7   parada, reacción del portero, IA del portero, fintas, regate, _tirar · decisión del portador
                             └─ _p8_p1 → _p8   forma, llegada, ataque sin balón, línea defensiva, defensa, IA de equipos, tácticas rápidas, barrida
                                 └─ _p9   control del usuario (balón, tiro, pases, sin balón)
                                     └─ _p10   tanda (turnos), saques del usuario e IA, balón parado
                                         └─ _p11   colocar saque, tanda (fases), celebración, cuerpos, presets
                                             └─ motor_jugable.gd  (class_name MotorJugable)  paso(), _physics_process
                                                 └─ motor_league_p1.gd → motor_league.gd (MotorLeague)
                                                     └─ motor_combinado.gd (MotorCombinado)  ← C4
```

La fábrica `MotorFabrica.crear()` elige según `MotorEleccion` (por defecto `combinado_c4`) y, para C4, llama a `aplicar_variante("combinado_c4")`, que pone las piezas `coloca_sin_balon` y `locomocion` en «siempre» (las nuestras), activa `_mejoras_c4` y escribe en metadatos del motor lo que leen los módulos (`carreras_n`, `corner_desvio`…) [D: `visor/motor_fabrica.gd`, `visor/motor_combinado.gd:43-51`]. La pieza `decide_con_balon` viene en «siempre» desde `datos/motor_c_piezas.json`, y `fisica_balon` se queda en «league».

El combinado elige «lo nuestro» **sin tocar los archivos de League**: vacía `equipos` o apaga la bandera estática `MotorLeague.fase3` durante la llamada a `super`, y las restaura al salir (`motor_combinado.gd:68-85, 169-176, 242-258, 271-298`). Es un patrón de «interruptor temporal» que funciona porque todo corre en un hilo, pero deja una ventana en la que el estado global no es el real (M6-24).

### 6.3.2 El paso

`MotorJugable.paso(delta)` (`visor/motor_jugable.gd:7-97`) es el corazón. En orden:

1. Si `delta > 0,1 s`, se parte en pasos de ≤ 1/30 s y se llama a sí mismo (con despacho dinámico: en C4 entra otra vez por `MotorLeague.paso`, que actualiza el estado de League en cada subpaso).
2. Cámara lenta (`lento`), relojes `_t_estado` y del árbitro.
3. Según `estado`: **juego** (reloj `t`, cambio forzado, fin de mitad, posesión, saque de mano, balón, duelos, ventaja, colocación, «imagen mental», adaptación, traza; si el estado cambió en medio, solo se mueven los cuerpos; si no: disputas, control de equipo, IA de equipos, práctica, control del usuario, indicador de pase, cansancio, cierre del remate a los 3,5 s), **saque** (cambio, cursor del usuario, `_colocar_saque`), **tanda** (`_paso_tanda`), **gol/descanso** (balón, celebración y, al acabar la espera, siguiente mitad o saque de centro).
4. Movimiento de los 22 (`_mover_jugadores`, que llama a `mover_jugadores_fisica` en C++ o a `_mover_fisica_gd`), choques de cuerpos (`cuerpos_motor` o `_cuerpos_gd`) y giro visual del balón.

### 6.3.3 Los relojes

El motor tiene tres relojes y el detalle importa para los hallazgos M6-02, M6-03, M6-08 y M6-09:

- **`t`**: segundos de motor de la **mitad en curso**. Solo avanza en «juego» y «tanda», y **vuelve a 0** al empezar la segunda parte y cada mitad de la prórroga (`motor_jugable.gd:88-89`).
- **`_t_estado`**: segundos desde el último cambio de estado (vuelve a 0 en cada saque, gol, descanso…).
- **`_t_arb`**: reloj propio del árbitro, que no se para en los saques.

El código usa `t` de dos maneras: como **duración** (`t >= dur_mitad() + añadido`, `minuto()`) y como **marca absoluta** para plazos (`p["mirar_hasta"] = t + 0,35`, `_decision_en = t + …`, `e["hasta"] = m.t + 4`). La búsqueda de `= t +` / `= m.t +` en el motor, League y C4 encuentra **31 claves de plazo distintas** [M]. Solo `gesto_hasta` se reinicia en `_saque_de_centro` (`motor_jugable_p2.gd:140-146`). Esta es la causa común de cuatro hallazgos.

### 6.3.4 Balón y física

- **Con poseedor**, el balón va pegado al pie (parado, al paso, portero, protegiendo) o se conduce «a toques»: el jugador lo empuja en la dirección de **su rotación** (`fwd = (sin ry, 0, cos ry)`), lo alcanza y lo vuelve a tocar (`motor_jugable_p4.gd:9-70`).
- **Suelto**, en el motor de siempre: gravedad, efecto Magnus, arrastre cuadrático 0,008 en el aire y, a ras de suelo, frenado lineal `dv/dt = −(0,18·v + 0,7)·roce_clima` (`_p4.gd:71-104`, `nucleo/balance.gd:13-28`).
- **Suelto, en C4**: la física de League (`LeagueNucleo.fuerzas_balon`, a pasos fijos de 10 ms, en C++ `balon_avanzar`): arrastre 0,017·v² siempre y, en el césped, `0,06·v² + 1,55` (`visor/league_nucleo.gd:59-88`, `motor_league_p1.gd:252-290`).
- Postes, larguero, gol y líneas se juzgan en `_palos_y_lineas` al cruzar el plano de la línea en el paso (`_p3.gd:366-401`).

Los **golpeos** se calculan siempre con el modelo de siempre: `_patear` saca la parábola con `G` y compensa el arrastre con `ARRASTRE_CUAD = 0,008` (`_p6.gd:9-67, 445-446`); los pases rasos piden la velocidad que hace rodar el balón «`sobra` metros más allá» con la integral del frenado lineal (`_p6.gd:387-402`). La coexistencia de los dos modelos en C4 es el hallazgo M6-06.

### 6.3.5 IA

- **Portador**: en C4, `MotorCombinado._ia_portador` prueba primero las mejoras (vuelta de la pared, pase atrás, centro, pared, balón largo) y si no, la decisión de siempre (`_p7.gd:5-108`): despeje bajo presión en su tercio, tiro con «ganas» y paciencia, centro, finta de último recurso, pase al hueco, mejor pase o seguir conduciendo.
- **Sin balón**: forma del equipo con balón «lento» (`MotorColocacion`), roles dinámicos (`MotorRoles`), apoyos, llegada al área, carreras al espacio con temporizador (`MotorCarreras`), y en defensa presionadores estables (`MotorPresion`), marcaje de los peligrosos, línea común y región propia. En C4 cada destino se guarda 0,1 s por jugador (`_cache_col`, `motor_combinado.gd:238-258`).
- **Imagen mental**: la CPU en los niveles bajos ve a los rivales con retardo (historial de 1,2 s, `MotorMente`) y en los altos, adelantados.
- **Portero**: parada decidida al ver venir el tiro y ejecutada al llegar el balón (`MotorParada`), salida a centros (`SalidaPortero`), penales por adivinanza (`PenalPortero`).

### 6.3.6 Reglas

Saques de centro, banda, esquina, puerta, faltas (puntos por factores con umbrales de falta, amarilla y roja), ventaja con vuelta a la falta (`MotorVentaja`), fuera de juego por «foto» en el momento del pase (`_foto_offside`) juzgado en la recepción (`_pitar_offside` desde `_tomar`), añadido, prórroga y tanda (cinco y muerte súbita, `tanda_decidida`), partido suspendido con menos de siete (`MotorSiete`).

### 6.3.7 Extensión C++

Cada función nativa del motor tiene una gemela GDScript que se queda como respaldo (Android/Web) y `pruebas/probar_nativo*.gd` compara bytes. En el camino de C4 se llaman, entre otras, `mover_jugadores_fisica`, `cuerpos_motor`, `league_estado_base`, `balon_avanzar`, `league_cortar_candidatos`, `league_linea_penultimo` y `league_mas_cercano*` [M: búsqueda de `nat.` en `visor/`].

### 6.3.8 Integración

- **`VistaEstadio`** (modo entrenador y «Entrar al estadio»): crea el motor, le apaga `_physics_process` y lo avanza desde **`_process`** con un acumulador de pasos fijos de 1/60 s y tope de 16 pasos por fotograma (`ui/estadio.gd:213-232, 274-295`; `estadio_p1.gd:120`). En el partido del DT con charla de descanso, el estadio **se cierra al 45 y se abre otro** para el segundo tiempo, con un motor nuevo (`ui/partido_vivo_p1.gd:323-334`, `estadio.gd:305-311`).
- **`PartidoJugable`** (Carrera de Jugador y La Ruta): deja el `_physics_process` del motor encendido (un `paso` por tic de física) y usa **el mismo motor** las dos mitades, la prórroga y la tanda (`ui/partido_jugable_p1.gd:345-346`).

Esta diferencia explica por qué unos hallazgos afectan a un modo y no al otro (M6-01 solo al estadio; M6-02/03/08 sobre todo a la Carrera y a la prórroga; M6-05/11 solo al estadio del DT).

---

## 6.4 Tabla de hallazgos

| Id | Grav. | Archivo:línea | Descripción | Escenario de fallo concreto | Arreglo propuesto | Veredicto |
|---|---|---|---|---|---|---|
| M6-01 | Alta | `ui/estadio.gd:224-227` (bucle desde `_process`, :274-294); lectores en `motor_jugable_p3.gd:28`, `_p8_p1.gd:321-352`, `_p9.gd:367, 393`, `_p10.gd:159, 202, 214-236, 293-300` | `is_action_just_pressed` leído en cada paso fijo de un bucle que corre 0, 1 o N veces por fotograma | A 120 fps, ~1 de cada 2 pulsaciones de Pase/Cambio se pierde; a 30 fps, «Cambiar» salta A→B→A y no cambia; un toque de RB o Y cuenta como doble; «presión de equipo» deja `_tac_base` en 2 y no se acaba | Leer la entrada una vez por fotograma en la vista y pasarla al motor como «flancos pendientes» consumidos en el primer paso (o mover el motor a `_physics_process`) | CONFIRMADO |
| M6-02 | Alta | `visor/motor_mente.gd:24, 32, 57-62`; reinicio en `motor_jugable.gd:89` | El historial de posiciones no tolera que `t` vuelva a 0 | Carrera en Practicante o Cadete: todo el segundo tiempo la CPU marca a los rivales donde estaban al final del primero; el historial crece sin tope (~2.400 fotos por mitad) | Vaciar el historial al cambiar de mitad o usar un reloj monótono (`tiempo_jugado()`) | CONFIRMADO |
| M6-03 | Alta | `_p4.gd:194-196, 297-311`; `_p5.gd:116, 186`; `nativo/src/mover_nativo.cpp:53, 119`; `_p6.gd:174`; `_p2.gd:140-146` | Plazos absolutos por jugador (`mirar_hasta`, `levanta_hasta`, `levantar_en`, `freno_duelo_hasta`, `contacto_hasta`, `regate_hasta`, `duelo_hasta`, `barrida_hasta`) sobreviven al reinicio de `t` | Pase o tiro en los últimos 0,35 s del primer tiempo: ese jugador queda girado hacia aquel golpeo y conduce en esa dirección casi todo el segundo; derribado en los últimos 3,4 s: no se mueve ni toca el balón en todo el segundo tiempo | Restar el `t` final a todos los plazos al cambiar de mitad, o pasar los plazos a un reloj monótono | CONFIRMADO |
| M6-04 | Alta | `_p6.gd:53, 80-105, 216-223`; `_p9.gd:402-414`; `_p5.gd:294-324, 349, 388-420` | El fuera de juego solo se juzga en `_tomar`; un remate o pase de primera hace una foto nueva sin juzgar la anterior | Centro o falta lateral con un delantero adelantado: cabecea a gol y el gol vale; lo mismo con el remate de primera del usuario | En `_patear`, antes de `_foto_offside(p)`, llamar a `_pitar_offside(p)` si `p` no es el último que pateó, y abortar el golpeo si se pita | CONFIRMADO |
| M6-05 | Alta | `ui/estadio_p5.gd:4-20`; `ui/partido_vivo_p1.gd:323-334`; `_p4.gd:263, 279-284`; `nucleo/partido.gd:191-211` | Al rehacer el estadio tras el descanso del DT, el motor nuevo no sabe quién tenía amarilla | Amarilla en el 30', otra en el 70': el motor la trata como primera, el acta suma dos amarillas y nadie es expulsado | Sembrar `p["amarillas"]` desde `partido._amarillas_hoy` al montar el motor; y que `tarjeta_externa` convierta la segunda en roja | CONFIRMADO |
| M6-06 | Media | `_p6.gd:253-261, 387-402, 434, 445-446`; `_p9.gd:79-92`; `motor_league_p1.gd:252-290`; `league_nucleo.gd:59-88` | C4 frena el balón con la ley de League pero calcula pases y recepciones con la de siempre | Pase manual de 12 m: el balón para a ~8 m; pase raso de la IA de 30 m: ~23 m; el receptor corre a un punto pasado de largo | Dar a `velocidad_para`, `compensa_arrastre` y `_punto_de_recepcion` la ley del motor que mueve el balón (gancho en la capa 1 sobrescrito en `MotorLeague`) | CONFIRMADO [M] |
| M6-07 | Media | `motor_league_p1.gd:9, 252-290`; `league_nucleo.gd:86-88`; `gesto_tecnico.gd:93-95` | El clima no frena ni acelera el balón suelto en C4 | Partido con lluvia o nieve: el balón suelto rueda igual que con sol (solo el conducido lo nota) | Construir `cfg_balon` con la humedad del clima (`config_balon(humedad)`) o multiplicar `roce`/`roce_lineal` por `_roce_clima` | CONFIRMADO |
| M6-08 | Media | `motor_presion.gd:68-77`; `motor_carreras.gd:56-59, 81`; `mejoras_c4_p1.gd:136`; `_p8_p1.gd:327-344`; `_p9.gd:342`; `motor_jugable.gd:64` | Plazos absolutos de equipo y del usuario tras el reinicio de `t` | Segundo tiempo: un equipo presiona por zona sin parar; un delantero «hace la carrera» toda la mitad o nadie la hace; la «presión de equipo» de 45 s dura toda la mitad | Igual que M6-03 (reloj monótono o rebase de plazos en el cambio de mitad) | CONFIRMADO |
| M6-09 | Media | `motor_league_p1.gd:215-217` | En el motor «league» del selector, `_decision_league` es absoluto | Con «league» en la Carrera: en el segundo tiempo el portador de la IA no pasa ni tira (solo conduce) hasta que `t` supera el final del primero | Rebasar `_decision_league` (y `_posee_desde`) en el cambio de mitad | CONFIRMADO |
| M6-10 | Media | `_p6.gd:227-228`; `_p4.gd:15-20, 110`; `_p5.gd:371-372` | El portero con el balón es intocable y lo lleva pegado en cualquier parte del campo | Carrera como portero: sales del área conduciendo y ningún rival entra ni carga; el gesto es de blocaje con las manos fuera del área | Aplicar la inmunidad y el balón pegado solo con `en_manos` y dentro de su área; fuera del área, conducción normal | CONFIRMADO |
| M6-11 | Media | `ui/estadio_p2.gd:386-388`; `nucleo/partido.gd:249-259`; `ui/estadio_p5.gd:4-20` | Las estadísticas del motor nuevo del segundo tiempo pisan las del acta | Partido del DT con charla: el acta final enseña córners, faltas, fueras de juego y posesión solo del segundo tiempo | Sumar las del primer tiempo al montar el segundo motor (sembrar contadores) o acumular en `Partido` | CONFIRMADO |
| M6-12 | Media | `visor/motor_jugable_p5.gd` (486 líneas) | Incumple la regla fija «ningún script > 450 líneas» | `python3 herramientas/revisar_lineas.py --todos` lo lista; nació el 15-11 con el paso a C++ del movimiento | Partir con `herramientas/partir_gd.py` (o mover `_mover_fisica_gd` a un módulo estático) | CONFIRMADO [M] |
| M6-13 | Media | `_p2.gd:224-252, 278-299`; `motor_jugable.gd:30-33` | El «cambio forzado» no para el juego (`forzar` no hace nada) y `_cambiar` no limpia referencias al que sale | Minuto 63, balón en juego: el que sale desaparece y el que entra aparece en la banda sin pitido; si iba un pase hacia él, `pase_a` apunta a un jugador fuera del campo y el control del equipo puede saltar a él | Parar el juego (saque de banda o de falta neutral) o esperar al primer balón parado; limpiar `pase_a`, `_receptor_marcado`, `ultimo_toque` | CONFIRMADO (parte del salto de control: PLAUSIBLE) |
| M6-14 | Baja | `_p9.gd:95-113` (`_ctx_golpeo` en la 109) | El contexto «centro» se fija después de patear | El centro del usuario sale con gesto de pase y el siguiente golpeo de cualquiera (cabezazo, despeje) sale con gesto de centro | Mover `_ctx_golpeo = "centro"` antes de las llamadas a `_patear` | CONFIRMADO |
| M6-15 | Baja | `_p10.gd:269-272` | La falta lanzada por el usuario a < 32 m suma tiro sin abrir remate | Falta lateral centrada al área: cuenta como tiro aunque fuera un pase; si va a puerta, ni el mapa de tiros ni el acta reciben su desenlace | Abrir `_tiro_vivo` y contar el tiro solo si el destino está entre los palos | CONFIRMADO |
| M6-16 | Baja | `ui/estadio_p2.gd:225-234`; `_p3.gd:83-91` | Al cambiar el ritmo a mitad de partido no se reescala el añadido | De «rápido» a «largo» en el 40': el cuarto árbitro enseña la mitad de minutos de añadido | Reescalar `anadido` por el mismo factor que `t` | CONFIRMADO |
| M6-17 | Baja | `_p11.gd:96-107, 159`; `_p3.gd:255-267` | Tanda: no se iguala el número de lanzadores; sin portero en el equipo que defiende nadie para | Tanda tras una roja: a partir del décimo penal el equipo con 10 repite lanzador antes que el otro; con el portero expulsado sin sustituto, todos los penales entran | Recortar la lista del equipo con más jugadores; designar portero al jugador de campo que toque | CONFIRMADO |
| M6-18 | Baja | `_p10.gd:394-400` | En un penal los demás se colocan a 7,5 m del punto | Penal: los jugadores esperan a 18,5 m de la línea, dentro del arco de 9,15 m | Usar `max(AREA_Z + 1, PUNTO_PENAL + 9,15)` o empujar fuera del arco | CONFIRMADO |
| M6-19 | Baja | `_p3.gd:371, 387, 399` | Gol y fuera se miden con el centro del balón, no con la pelota entera | Balón que cruza la línea 6 cm: es gol (el reglamento exige que la pelota entera cruce) | Comparar con `LARGO + R` y `ANCHO + R` | CONFIRMADO |
| M6-20 | Baja | `_p6.gd:57` | El lanzador de un saque puede volver a tocar el balón antes que nadie a los 0,35 s | Penal al palo que vuelve al lanzador: remata a gol (el reglamento lo sanciona con libre indirecto) | Marcar «ejecutor del saque» hasta el siguiente toque ajeno y pitar libre indirecto | CONFIRMADO |
| M6-21 | Baja | `_p5.gd:482-483`; `_p6.gd:62-64` | El azar del motor se consume o no según qué animaciones estén cargadas | Mismo partido y semilla en una sonda sin modelos y en el juego: distinta secuencia de `_rng` desde el primer golpeo | Sacar el sorteo del gesto a un generador propio de la vista (no al `_rng` del motor) | CONFIRMADO |
| M6-22 | Baja | `motor_jugable.gd:116-129`; `_p6.gd:9-47, 216-223` | Durante el saque de mano el balón está «suelto» en la mano del portero | Un rival a menos de 0,8 m del portero cabecea el balón de su mano | Tratar `_en_mano` como posesión (excluirlo de disputas y cabezazos) | PLAUSIBLE |
| M6-23 | Baja | `_p5.gd:374, 376`; `visor/futbolista_q.gd:100-118` | `(p["anim"] as AnimationPlayer).has_animation` sin comprobar nulo | Un futbolista con modelo sin clips (`anim` nulo) controla un balón alto: error de ejecución en `_tomar` a mitad de la recepción | `is_instance_valid(ap)` antes, como en el resto del motor | PLAUSIBLE |
| M6-24 | Baja | `motor_combinado.gd:282-298` | Durante `_mover_balon` el combinado deja `equipos = []` y `MotorLeague.fase3 = false` mientras se emiten señales | Un gol o un saque dentro de ese paso emite `gol`, `aviso`, `cambio_estado`; si un oyente consulta el motor, ve una configuración de piezas que no es la real | Emitir las señales en diferido o no vaciar `equipos` (pasar la elección por parámetro) | PLAUSIBLE |
| M6-25 | Baja | `_p9.gd:95-113`; `_p7.gd:70-79`; `mejoras_c4_p1.gd:171-193` | Los centros no cuentan en `pases[]` pero el del usuario sí en `stats["pases"]` | La precisión de pase del equipo y la del jugador no salen del mismo conjunto de envíos | Contar los centros en los dos sitios (o en ninguno) | CONFIRMADO |
| M6-26 | Baja | `_p6.gd:216-223` | Un jugador en el suelo puede cabecear | Derribado en el área: el balón alto pasa a 0,8 m y «cabecea» tumbado | Excluir `levanta_hasta > t` como en el control | CONFIRMADO |

Recuento: **Alta 5, Media 8, Baja 13**; **CONFIRMADOS 21**, **PLAUSIBLES 5** (M6-13 cuenta como confirmado en su parte principal).

---

## 6.5 Hallazgos en detalle

### M6-01 · La entrada del jugador dentro del paso fijo del estadio (Alta, CONFIRMADO)

**Dónde.** `ui/estadio.gd:213-232` (`_paso_motor`), llamado desde `_process` (`:274-294`):

```gdscript
var mult := _juego.velocidad() if _juego != null else 1.0
_acum_motor = minf(_acum_motor + delta * mult, DT_MOTOR * 16.0)
while _acum_motor >= DT_MOTOR:
	_motor.paso(DT_MOTOR)
	_acum_motor -= DT_MOTOR
```

Dentro de `paso`, el control del usuario y del equipo lee **flancos** de botón: `Input.is_action_just_pressed("jugar_cambiar")` (`motor_jugable_p3.gd:28`), las cuatro tácticas de la cruceta (`_p8_p1.gd:332-350`), el doble toque de RB (`_p9.gd:366-368`) y de Y (`:392-395`), Pase/Centro/Filtrado/Tiro en `_control_pases` y `_control_sin_balon`, el cambio de receptor en saques (`_p10.gd:158-159`, `:293-294`) y el segundo/tercer lanzador (`:296-301`).

**Por qué falla.** Fuera de la física, `is_action_just_pressed` devuelve verdadero durante **todo el fotograma de proceso** en que empezó la pulsación. El bucle de arriba ejecuta `floor(acumulado / (1/60))` pasos por fotograma:

- **Más de 60 fps** (el objetivo del dueño es 120 fps, orden 19): la mitad de los fotogramas no ejecuta ningún paso. Una pulsación que cae en uno de ellos **no la ve nunca el motor**. A 120 fps se pierde ~1 de cada 2 pulsaciones de Pase, Filtrado, Centro, Cambiar o tácticas [E: proporción de fotogramas sin paso].
- **60 fps exactos**: un paso por fotograma; funciona (es la cadencia con que se probó).
- **30 fps o menos** (el móvil medido por el dueño: 5 fps, orden 22): dos o más pasos por fotograma, y la pulsación se ve en **todos**. Efectos concretos, trazados en el código:
  - *Cambiar de jugador* (`_control_de_equipo`): en el primer paso, `_mio_mas_cercano(mio, usuario=A)` da B y se cambia a B; en el segundo, `_mio_mas_cercano(mio, usuario=B)` excluye a B y devuelve **A**, el más cercano. Con un número par de pasos (30 fps → 2; 5 fps → 12) el botón **no hace nada**.
  - *Doble toque*: `_presion_doble = t - _rb_ultimo < 0,3` es verdadero en el segundo paso (han pasado 1/60 s); un toque simple de RB manda **dos** presionadores. Igual con Y: un toque manda al portero al palo largo (`_palo_largo_hasta`).
  - *Tácticas rápidas*: «arriba» sube la mentalidad dos puntos; «derecha» abre y cierra los laterales (sin efecto); «izquierda» ejecuta dos veces `_tac_base[eq] = tc.duplicate()` (`_p8_p1.gd:341`): la segunda copia ya tiene `presion = 2`, de modo que al acabar los 45 s se «restaura» la presión… a 2. **La presión de equipo no se acaba nunca.**
  - *Saques*: Cambiar avanza el receptor dos posiciones; RB en un córner llama al segundo lanzador y, en el paso siguiente, `_otro_lanzador(1)` excluye al nuevo y elige al primero (el mejor pateador) otra vez: se vuelve al de antes.

`PartidoJugable` no tiene el problema porque usa `_physics_process` del motor (un paso por tic, y Godot evalúa el flanco por tic de física). Tampoco lo tiene el tiro, que se carga con `is_action_pressed` y se suelta por cambio de estado (`cargando`).

**Arreglo.** En la vista, leer los flancos una vez por fotograma de proceso y guardarlos en un conjunto «pendiente» del motor; el primer paso los consume y los borra. Alternativa más simple: avanzar el motor desde `_physics_process` (con el ritmo de partido como multiplicador y el acumulador solo para el modo acelerado). En cualquiera de los dos casos, una prueba: inyectar una pulsación de `jugar_cambiar` y simular fotogramas de 1/30 y 1/120 s, comprobando que el usuario cambia exactamente una vez.

### M6-02 · La imagen mental de la CPU se congela en el segundo tiempo (Alta, CONFIRMADO)

**Dónde.** `visor/motor_mente.gd`:

```gdscript
if m.t - float(e["ult"]) < CADA and m.t >= float(e["ult"]):   # :24
	return
...
while h.size() > 1 and m.t - float(h[0]["t"]) > MEMORIA:      # :32
	h.pop_front()
...
var mejor: Dictionary = h[0]                                   # :57
for s: Dictionary in h:
	if float(s["t"]) <= obj_t:
		mejor = s
	else:
		break
```

**Por qué falla.** Al empezar el segundo tiempo `t` vuelve a 0 (`motor_jugable.gd:89`). El historial conserva las fotos del final del primero, con `t` ≈ 240-260. La limpieza de la línea 32 compara `0 − 250 > 1,2`, que es falso: **no borra nada** hasta que `t` supere el último instante del primer tiempo, es decir, durante casi toda la mitad; mientras, se añade una foto de los 22 cada 0,1 s (unas 2.400 por mitad de 240 s) [E]. La búsqueda de las líneas 57-62 empieza en la foto más vieja, que tiene un `t` mayor que el buscado, y sale en la primera iteración: devuelve **la foto del final del primer tiempo**.

**Escenario.** Carrera de Jugador (mismo motor las dos mitades) con la dificultad en Practicante (retardo 0,5 s) o Cadete (0,2 s) [D: `nucleo/balance.gd:59-60`]. En el segundo tiempo, el marcaje de la CPU (`_ia_defensa`, `_p8_p1.gd:214-246`) y la presión (`_presion`, `_p6.gd:372-374`) usan posiciones de rivales que ya no existen. El fallo también aparece en cada mitad de la prórroga. Las dificultades Debutante y superiores no pasan por el historial (retardo 0 o negativo).

**Arreglo.** Vaciar el historial (`remove_meta("_mente")`) en `_saque_de_centro` cuando cambia la mitad; o indexar las fotos con un reloj monótono (`tiempo_jugado()` ya existe, `_p2.gd:177-180`).

### M6-03 · Plazos por jugador que cruzan la mitad (Alta, CONFIRMADO)

**Dónde.** Los plazos se escriben con `t` absoluto: `_mirar` (`_p4.gd:194-196`: `p["mirar_hasta"] = t + dur`), `_caer` (`:297-311`: `levanta_hasta`, `levantar_en`), `_empujar` (`freno_duelo_hasta`), los duelos (`contacto_hasta`), las fintas (`regate_hasta`, `duelo_hasta`), la barrida (`barrida_hasta`). `_saque_de_centro` solo reinicia `gesto_hasta` (`_p2.gd:140-146`).

**Por qué falla.** En el segundo tiempo `t` empieza en 0 y cualquier plazo puesto en los últimos segundos del primero queda **en el futuro durante casi toda la mitad**:

- `mirar_hasta` (golpeo en los últimos 0,35 s): el movimiento lo lee primero y gira el cuerpo hacia el rumbo guardado **en cada paso** (`_p5.gd:186-188`; gemela C++ `mover_nativo.cpp:119-120`, idéntica). Como la conducción empuja el balón en la dirección del cuerpo (`_p4.gd:12, 46-51`), ese jugador, si recibe, **conduce hacia el sitio equivocado** y pierde el balón en la rama de «se le fue» (`:33-39, 64-66`). Además no se inclina en las curvas y su animación de carrera no corresponde a su rumbo.
- `levanta_hasta` / `levantar_en` (derribo en los últimos 3,4 s): el objetivo de movimiento se sustituye por su posición actual (`_p5.gd:116`), no puede tocar el balón (`_p6.gd:174`), no puede sacar (`_p2.gd:90`) y queda congelado en la pose de la caída (`_p5.gd:237-239`). **Un jugador inmóvil todo el segundo tiempo.**
- `freno_duelo_hasta`: corre al 35-95 % de su velocidad toda la mitad. `contacto_hasta`: no entra en ningún duelo. `regate_hasta`: no puede intentar fintas (`_p7_p1.gd:199`) y quien le entra tiene la defensa como si estuviera regateando (`_p6.gd:115-116`).

**Escenario y frecuencia.** Mismo motor en las dos mitades (Carrera, La Ruta; prórroga en todos los modos). El silbato del descanso llega cuando `t ≥ duración + añadido`, sin esperar a que el balón esté parado; con un golpeo cada 1-2 s, la probabilidad de que alguien haya golpeado en los últimos 0,35 s es del orden de una de cada cuatro a seis mitades [E]. El derribo es menos frecuente (necesita una falta o una carga en los últimos 3,4 s).

**Arreglo.** Una función `_rebasar_plazos(desfase)` llamada al empezar cada mitad que reste el `t` final a todas las claves `*_hasta`/`*_en` de los jugadores (y de los módulos de M6-08); o, mejor a medio plazo, que todos los plazos usen un reloj monótono del partido. La prueba: jugar hasta el silbato con un golpeo forzado en el último paso y comprobar que en el segundo 1 del segundo tiempo `mirar_hasta ≤ t`.

### M6-04 · El fuera de juego no existe en los remates y pases de primera (Alta, CONFIRMADO)

**Dónde.** La «foto» se toma al patear (`_patear` → `_foto_offside(p)`, `_p6.gd:53`; `_p5.gd:388-420`), y el fuera de juego **solo** se juzga cuando alguien controla el balón: `_tomar` → `_pitar_offside` (`_p5.gd:349`). Los cabezazos se ejecutan sin control (`_disputas` → `_cabezazo` → `_patear`, `_p6.gd:216-223, 80-105`), igual que el remate de primera del usuario (`_p9.gd:402-412` → `_tirar` → `_patear`) y el despeje de primera.

**Por qué falla.** `_foto_offside` empieza con `_offside = {}` y escribe la foto del nuevo golpeo. La foto anterior —la que decía que el rematador estaba adelantado cuando se le centró— se borra sin consultarla.

**Escenario.** Falta lateral ensayada de C4 (`MejorasC4.falta_ensayada`) o centro desde la banda (`MotorCorner.centrar`, `MejorasC4.centro`): un delantero 1 m por delante del penúltimo defensor en el momento del centro cabecea a gol. El árbitro no pita, el juez de línea tampoco y el VAR solo mira el margen guardado en la **recepción** (`_margen_recepcion`, que tampoco se escribe en un cabezazo), así que el gol vale y la sala VAR, si lo revisa por azar, no tiene líneas que dibujar. Lo mismo ocurre con el usuario que remata de primera un pase al hueco desde fuera de juego.

**Arreglo.** En `_patear`, antes de hacer la foto nueva, si `p` es del equipo de la foto vigente y está en su lista, pitar (`_pitar_offside(p)`) y no ejecutar el golpeo. Así quedan cubiertos el cabezazo, la volea, el despeje de primera y cualquier golpeo futuro sin control. El margen para el VAR debería escribirse en el mismo punto.

### M6-05 · Las amarillas del primer tiempo se olvidan en el estadio del DT (Alta, CONFIRMADO)

**Dónde.** El partido del entrenador con charla de descanso cierra el estadio al 45 y abre **otro** para el segundo tiempo (`ui/partido_vivo_p1.gd:323-334`: `vista.parar_en_descanso = not _entretiempo_hecho` y `vista.queue_free()` al cerrar). El estadio nuevo monta un motor nuevo con diccionarios de jugador nuevos (`ui/estadio_p5.gd:4-20`). El motor guarda las amarillas del partido **solo** en el diccionario del jugador (`_p4.gd:263, 279-284`) y nada las siembra desde el acta: la búsqueda de `_amarillas_hoy` fuera de `nucleo/partido*.gd` no encuentra ningún uso [M].

**Por qué falla.** Una amarilla en el segundo tiempo a quien ya tenía una se emite como `tarjeta(id, roja=false)`. `Partido.tarjeta_externa` (`nucleo/partido.gd:191-211`) suma `_amarillas_hoy[id] = 2` pero **no** convierte la segunda en roja ni expulsa: solo lo hace si el motor le dice `roja = true`.

**Escenario.** Modo entrenador, partido en el estadio, amarilla a un central en el 30' y otra en el 70': sigue en el campo, el acta registra dos amarillas y ninguna roja, y no hay sanción por expulsión.

**Arreglo.** Doble: al montar el motor, `p["amarillas"] = partido._amarillas_hoy.get(id, 0)` para cada jugador (vía un accesor público del `Partido`); y, como defensa en profundidad, que `tarjeta_externa` trate la segunda amarilla del mismo partido como roja (el simulado ya lo hace en `_amonestar`).

### M6-06 · C4 mezcla dos leyes de rozamiento (Media, CONFIRMADO [M])

**Dónde.** C4 deja la pieza `fisica_balon` en «league»: el balón suelto se mueve con `LeagueNucleo.fuerzas_balon` (arrastre 0,017·v² siempre; en el césped, 0,06·v² + 1,55; `league_nucleo.gd:59-88`). Pero los golpeos se calculan en la capa 6 con el modelo del motor de siempre:

- `velocidad_para(dist, sobra)` busca la velocidad que hace rodar el balón `dist + sobra` metros con `dv/dt = −(0,18·v + 0,7)` (`_p6.gd:387-402`);
- `compensa_arrastre` corrige el vuelo con 0,008·v² (`:445-446`);
- `_punto_de_recepcion` predice dónde para el balón con la misma ley lineal (`:253-261`).

**Cálculo.** Integrando las dos leyes con los pasos del código (1/60 s y 10 ms) para las velocidades que piden los pases [M: guion de comprobación]:

| Pase pedido | Velocidad pedida | Rodaría (ley de siempre) | Rueda en C4 (ley League) |
|---|---:|---:|---:|
| IA raso, 20 m (`× VEL_K 1,2`) | 19,3 m/s | 68 m | **19 m** |
| IA raso, 30 m | 25,8 m/s | 99 m | **23 m** |
| IA raso, 35 m | 29,0 m/s | 115 m | **24 m** |
| Usuario, pase manual 12 m (`_pase_manual`) | 7,0 m/s | 17 m | **8 m** |
| Usuario, pase manual 16 m (RB) | 7,9 m/s | 20 m | **9 m** |

El pase de la IA se diseñó para llegar «con fuerza» y morir lejos detrás del receptor; en C4 los pases cortos llegan justos y los de 25-36 m (que todavía van rasos: `_p6.gd:421-434`) se quedan cortos. El pase manual —que no busca compañero y apunta a un punto— **no llega a su destino en ningún caso**. El receptor, además, corre a un punto calculado con la ley lineal, pasado de largo, y el balón se para detrás de él.

**Matiz.** Las sondas de C4 midieron pases buenos por partido con esta mezcla, así que parte del efecto en la IA está absorbido en la calibración. El pase manual del usuario y los pases largos rasos no lo están.

**Arreglo.** Un gancho `_ley_rodadura()` en la capa 1 (la de siempre) sobrescrito en `MotorLeague` cuando `equipos` no está vacío, del que beban `velocidad_para`, `distancia_rodando`, `compensa_arrastre` y `_punto_de_recepcion`. Con la ley de League la distancia tiene forma cerrada: `x = ln(1 + k·v₀²/c) / (2k)` con `k = 0,077` y `c = 1,55` (el propio `motor_league.gd:392-401` ya la usa para el toque de conducción). Recalibrar después `VEL_K`.

### M6-07 · El clima no llega al balón suelto de C4 (Media, CONFIRMADO)

`GestoTecnico.fijar_clima` pone `_roce_clima` en el motor (`gesto_tecnico.gd:93-95`: lluvia 0,78, nieve 1,35). Solo lo leen las dos ramas del balón **de siempre** (`_p4.gd:59, 83`). En C4 el balón suelto lo mueve League con `cfg_balon = LeagueNucleo.config_balon()` construido una vez con `humedad = 0` (`motor_league_p1.gd:9`); `config_balon` admite humedad (`league_nucleo.gd:86-88`) pero nadie se la pasa. Resultado: con lluvia o nieve, el balón suelto rueda igual que con sol (el pedido del dueño del 27-10 era que el clima «cambie lo que rueda el balón»). Arreglo: en `fijar_clima`, si el motor tiene `cfg_balon`, rehacerlo con la humedad equivalente o escalar `roce` y `roce_lineal` por `_roce_clima`.

### M6-08 · Plazos de equipo que cruzan la mitad (Media, CONFIRMADO)

La misma causa que M6-03 en el estado de equipo y del usuario:

- **Presión por zona** (`motor_presion.gd:68-77`): `zona_hasta` vale `t + 2-4 s`. Si estaba activa al silbato, en el segundo tiempo `m.t < hasta` es verdadero toda la mitad y `_gatillo_presion` dispara siempre para ese equipo: el segundo presionador sale con presión media y la contrapresión se activa con «tras la pérdida» alto (`_p8_p1.gd:121-135, 179-212`).
- **Carreras al espacio** (`motor_carreras.gd:56-59, 81`; `mejoras_c4_p1.gd:136`): si una plaza estaba ocupada, su delantero «corre» todo el segundo tiempo (siempre a la línea, siempre esprintando); si estaba en descanso, la plaza no vuelve a abrirse. C4 tiene dos plazas por equipo y el ciclo carrera/descanso es continuo mientras se ataca, así que lo normal es que al menos una esté en uno de los dos estados [E].
- **Presión de equipo de la cruceta** (`_p8_p1.gd:327-344`): dura toda la mitad en vez de 45 s.
- **Cambio con el stick derecho** (`_p9.gd:342`): si se usó en los últimos 0,45 s, queda bloqueado la mitad.
- **Remate abierto** (`motor_jugable.gd:64`): un tiro en vuelo al silbato no se cierra a los 3,5 s; se cierra como «fallo» en el primer toque del segundo tiempo, con minuto y desenlace equivocados en el acta.
- **Ventana de recuperación** (`_eq_tomo_en`): hasta el primer cambio de posesión, el gatillo de contrapresión da verdadero para el equipo que no recupere.

Arreglo: el mismo rebase de plazos de M6-03, extendido a los metadatos de los módulos (`zona_hasta`, `_carrera_*`, `_mente`) y a las variables de la capa 1.

### M6-09 · El motor «league» del selector deja de decidir en el segundo tiempo (Media, CONFIRMADO)

En `MotorLeague._ia_portador` (`motor_league_p1.gd:215-217`) la decisión espera a `t ≥ _decision_league`, que se escribe como `t + REACCION`. Tras el reinicio de `t`, el portador de la IA no vuelve a pasar ni a tirar hasta que `t` supera el instante de la última decisión del primer tiempo: el segundo tiempo entero de la Carrera con el motor «league» elegido en el selector A/B/C (o con `MOTOR_LEAGUE=1`) se juega sin decisiones de la IA, solo conducción, fintas y robos. C4 no lo sufre porque su decisión con balón es la nuestra (vacía `equipos` y el gancho cae a `super`). Gravedad media porque «league» no es el motor por defecto, pero lo usa cualquiera que vote a ciegas y le toque esa letra.

### M6-10 · El portero intocable fuera de su área (Media, CONFIRMADO)

`_disputas` sale nada más empezar si el poseedor es portero (`_p6.gd:227-228`: «al portero con el balón en las manos no se le entra»), los duelos lo excluyen (`_libre_para_duelo`, `_p4.gd:110`) y el balón va pegado a su pie a cualquier velocidad (`_p4.gd:15`). Ninguna de las tres condiciones mira si está en su área o si tiene el balón en las manos (`en_manos` existe y se usa solo para el saque de mano). Con la IA el caso es raro (el portero solo sale a por balones sueltos dentro del área), pero en la **Carrera como portero** el usuario puede salir conduciendo y la IA rival no puede ni entrarle ni cargarle; si recoge un balón fuera del área, el gesto es de blocaje con las manos (`_p5.gd:371-372`) y no hay mano pitada. Arreglo: inmunidad y balón pegado solo con `en_manos` y `_en_su_area`; fuera, tratarlo como un jugador de campo (incluido el gesto de control con el pie).

### M6-11 · Las estadísticas del segundo motor pisan las del acta (Media, CONFIRMADO)

En el mismo flujo de M6-05, el motor del segundo tiempo nace con `corners = faltas = fueras_de_juego = [0, 0]` y `posesion = [0, 0]`, y `_sincronizar_partido` llama en cada minuto a `partido.fijar_estadisticas(posesion_local(), corners, faltas, fueras_de_juego)` (`ui/estadio_p2.gd:386-388`), que **asigna** (no suma) los valores (`nucleo/partido.gd:249-259`). El acta final enseña solo el segundo tiempo. También se pierden el cansancio acumulado (`aguante` vuelve a 1) y el `entro_en` de los suplentes. Arreglo: sembrar los contadores del motor nuevo con los del `Partido` (o hacer que `Partido` acumule por mitad).

### M6-12 · Un script de 486 líneas (Media, CONFIRMADO [M])

`python3 herramientas/revisar_lineas.py --todos` lista `dinastia-godot/visor/motor_jugable_p5.gd` con **486 líneas** (también `visor/calidad.gd`, 454, fuera del motor). El exceso nació el 15-11 con el paso a C++ del movimiento (`_mover_fisica` + `_mover_fisica_gd`, `:93-219`). Incumple la regla fija del proyecto (CLAUDE.md: «ningún script > 450 líneas»). `pruebas/comprobar_scripts.gd` no lo detecta porque solo comprueba que compilen. Arreglo: sacar `_mover_fisica_gd` a un módulo estático (`MovimientoMotor`) o partir con `herramientas/partir_gd.py`; y añadir la comprobación de longitud al banco para que no vuelva a pasar.

### M6-13 · El cambio «forzado» no para el juego (Media, CONFIRMADO / PLAUSIBLE)

El comentario de `_revisar_cambio` dice que, sin balón parado, «el árbitro para el juego para el cambio» (`_p2.gd:274-277`), pero `forzar` solo hace `minu = maxi(minu, 0)` (`:282-283`), que no cambia nada (el minuto ya es ≥ 0). Desde el paso (`motor_jugable.gd:30-33`) se llama en pleno juego tres minutos después del previsto, y `_cambiar` intercambia los jugadores con el balón en juego: el que sale desaparece y el que entra aparece en la línea de banda, a la altura del medio campo. `_cambiar` limpia `poseedor` pero no `pase_a`, `_receptor_marcado` ni `ultimo_toque` (`:224-252`), a diferencia de `reemplazar` (`:390-392`); si el cambio coincide con un pase al que sale, nadie va a por él y, con el equipo en las manos del usuario, `_control_de_equipo` puede poner el control en `pase_a`, un jugador oculto fuera del campo (`_p3.gd:46-48`) — esta última parte es PLAUSIBLE (necesita la coincidencia). Arreglo: pitar una interrupción (o esperar al primer balón parado como dice el diseño) y limpiar las referencias.

### M6-14 a M6-26 · Hallazgos de gravedad baja

- **M6-14** (`_p9.gd:95-113`). `_centro_usuario` patea y **después** escribe `_ctx_golpeo = "centro"`. Como `_patear` lo vacía al final, el centro del usuario elige el gesto como un pase genérico, y el contexto «centro» queda pendiente para el **siguiente** golpeo de cualquier jugador: el remate de cabeza del propio centro o el despeje del defensor salen con gesto de centro (`_golpeo_anim`, `_p5.gd:451-452`). La IA lo hace en el orden correcto (`_p7.gd:73`, `mejoras_c4_p1.gd:189`).
- **M6-15** (`_p10.gd:269-272`). La falta del usuario a menos de 32 m suma un tiro al equipo y al jugador aunque se lance al área para un compañero, y no abre `_tiro_vivo`: si va a puerta, ni la señal `remate` ni el mapa de tiros saben cómo acabó, y la nota del jugador cuenta un tiro que no lo fue.
- **M6-16** (`ui/estadio_p2.gd:225-234`). `_fijar_ritmo` conserva el minuto reescalando `t`, pero `anadido` (segundos de motor calculados con el ritmo anterior en `sortear_anadido`, `_p3.gd:83-91`) queda igual: pasar de «rápido» a «largo» a mitad de mitad reduce los minutos de añadido a casi la mitad, y al revés los alarga.
- **M6-17** (`_p11.gd:96-107, 159-166`; `_p3.gd:255-267`). La tanda usa a todos los jugadores que quedan en el campo de cada equipo; el reglamento obliga a igualar el número de lanzadores y a que nadie repita hasta que todos hayan tirado. Con una roja, desde el décimo penal un equipo repite antes que el otro. Si el equipo que defiende no tiene portero (expulsado sin suplente), `gk` queda vacío y `_vuelo_tanda` no intenta parar nada: todos los penales entre los palos son gol.
- **M6-18** (`_p10.gd:394-400`). En un penal, `_fuera_del_area` deja a los demás a `AREA_Z + 2 = 18,5 m` de la línea de gol, es decir, a 7,5 m del punto: dentro del arco de 9,15 m que marca el reglamento.
- **M6-19** (`_p3.gd:371, 387, 399`). Gol y saques se deciden cuando el **centro** del balón cruza la línea (`|z| ≥ LARGO`, `|x| > ANCHO`); el reglamento exige que la pelota entera cruce, 11 cm más (`R = 0,11`). Afecta a los balones sobre la línea y a los despejes in extremis.
- **M6-20** (`_p6.gd:57`). Tras patear, el lanzador solo queda 0,35 s sin poder tocar el balón. En un saque (penal, falta, córner, banda, puerta), si el balón vuelve a él sin que lo toque otro (penal al palo, falta contra la barrera que rebota hacia él), puede jugarlo: el reglamento castiga el doble toque con libre indirecto.
- **M6-21** (`_p5.gd:482-483`; `_p6.gd:62-64`). `_golpeo_anim` solo consume `_rng` si hay clips disponibles para el golpeo, y `_patear` solo llama a `_golpeo_anim` si el jugador tiene `AnimationPlayer`. La secuencia aleatoria del partido depende, por tanto, de qué animaciones estén cargadas: una sonda sin modelos y el juego con modelos no juegan el mismo partido con la misma semilla, y la carga perezosa de clips (`AnimExtra.asegurar`, `LeagueCatalogo`) puede cambiarla según el momento en que se carguen. No rompe la reproducibilidad de un mismo dispositivo, pero invalida comparar huellas entre configuraciones.
- **M6-22** (`motor_jugable.gd:116-129`; `_p6.gd:9-47`). Durante los 0,45 s del saque de mano, `poseedor` está vacío y el balón se coloca en la mano del portero: las disputas y los cabezazos (`_p6.gd:169-223`) lo consideran un balón suelto. Un rival a menos de 0,8 m con el balón entre 1,5 y 2,4 m de altura lo «cabecea». PLAUSIBLE porque depende de la altura de la mano en el clip.
- **M6-23** (`_p5.gd:374, 376`). `_tomar` llama a `has_animation` sobre `p["anim"]` sin comprobarlo, mientras el resto del motor siempre hace `is_instance_valid(ap)`. `FutbolistaQ` devuelve `anim = null` para modelos sin clips (`visor/futbolista_q.gd:100-118`). Si un futbolista así llega al partido, la primera recepción alta lanza un error a mitad de `_tomar` (con `ultimo_toque` ya cambiado y `poseedor` sin poner). PLAUSIBLE: no se pudo confirmar que el reparto de modelos del partido entregue uno sin clips.
- **M6-24** (`motor_combinado.gd:282-298`). El combinado vacía `equipos` y apaga `MotorLeague.fase3` alrededor de `super._mover_balon`; dentro, `_palos_y_lineas` puede marcar gol o empezar un saque y emitir señales que la vista atiende al instante. Cualquier oyente que pregunte al motor (o a otro motor, porque `fase3` es estática) ve piezas que no son las reales. Hoy los oyentes revisados no consultan esas piezas, de ahí PLAUSIBLE.
- **M6-25** (`_p9.gd:95-113`; `_p7.gd:70-79`; `mejoras_c4_p1.gd:171-193`). Los centros de la IA y del usuario no suman en `pases[]` ni ponen `_pase_eq` (lo que la transmisión enseña como precisión de pase del equipo), pero el del usuario sí suma en `stats["pases"]`. La precisión del equipo y la del jugador se calculan sobre conjuntos distintos.
- **M6-26** (`_p6.gd:216-223`). El bucle de cabezazos excluye a los porteros y a los que están «enfriándose», pero no a los que están en el suelo (`levanta_hasta > t`), a diferencia del control (`:174`). Un jugador derribado en el área puede rematar de cabeza tumbado.

---

## 6.6 Verificaciones con resultado negativo

Tan importante como lo que falla es lo que se comprobó y está bien; evita que se gaste tiempo en volver a mirarlo.

1. **Gemelas C++.** `mover_jugadores_fisica` reproduce `_mover_fisica_gd` operación por operación: el mismo orden de giro, freno y tope de aceleración; los `Vector3` en 32 bits y los escalares en doble; la condición de poseedor por `id` en vez de igualdad de diccionarios (equivalente mientras los `id` sean únicos); el coste del aguante calculado fuera por equipo y pasado como arreglo (equivalente a llamar a `_tac` por jugador). `cuerpos_motor` reproduce `CuerposFisica.solape` y el reparto por masas. `league_estado_base` reproduce `_ms_al_balon`, `_mas_cercano_a_todos_gd` y `LeagueEquipo.linea_penultimo` (incluido el truncado a 32 bits del `PackedFloat32Array`). La prueba `probar_nativo.gd:256-311` compara posiciones, rotaciones, velocidades, empujones y aguante durante 120 pasos con 44 jugadores; no cubre `levanta_hasta`, `freno_duelo_hasta` ni `atras`, pero el código de esas ramas también es idéntico. Las diferencias de robustez (el C++ salta un nodo liberado donde el GDScript fallaría) no son diferencias de resultado.
2. **Azar con semilla.** Todo el azar del motor sale de `_rng`, sembrado en `preparar` (`_p2.gd:154`); no hay ninguna llamada a `randf()`/`randi()` globales en el motor, League, C4 ni los módulos [M]. Los «caracteres» de los jugadores usan `hash` de cadenas, determinista. La semilla del estadio es `hash(local.id + visita.id) + minuto`, repetible. (La excepción es M6-21.)
3. **Diccionarios de jugador como clave.** No se encontró ningún diccionario indexado por un diccionario de jugador; los mapas usan `String(p["id"])` como manda CLAUDE.md. Sí hay `Array.has(p)` y comparaciones `p == q` de diccionarios, que en Godot 4 comparan contenido: son correctas (cada jugador lleva su nodo, único) aunque cuestan más que comparar el `id`.
4. **Divisiones.** Todas las divisiones del camino caliente revisadas tienen guarda: `maxf(delta, 0.001)`, `maxf(vh, 1.0)`, `maxf(tv, 0.2)`, `vel_balon.z` con umbral antes de dividir en la parada y en la reacción del portero, `bis.z` con umbral en la colocación, `tot > 0` en la posesión, `maxf(def_rival, 0.001)` y `maxf(…, 0.0001)` en `partido_90.cpp`.
5. **Reglas que están bien.** La línea del fuera de juego cuenta al portero y toma el penúltimo (`_p5.gd:396-403`, `_p3.gd:187-195`); no hay fuera de juego en banda, córner ni saque de puerta (`_p5.gd:391-392`); el rechace de un rival rompe la foto y el de un compañero no (`_p6.gd:213-215`); la falta se saca donde se cometió y el fuera de juego donde estaba el adelantado; el penal sale del punto correcto en los dos arcos; el saque de banda es del equipo contrario al último que tocó; córner si el último toque fue del que defiende, saque de puerta si no (`_p3.gd:390-397`); la segunda amarilla expulsa dentro de un mismo motor; con menos de siete el partido se suspende 0-3 o con el marcador si ya era peor (`motor_siete.gd`); la ventaja vuelve a la falta si el equipo pierde el balón en 3,5 s y se olvida si el juego se para (`motor_ventaja.gd`); `tanda_decidida` corta bien en las cinco primeras rondas y en la muerte súbita (`_p11.gd:189-202`).
6. **Expulsiones dentro de bucles.** `_expulsar` borra de `jugadores` mientras `_duelos` recorre la lista, pero solo después de un `_falta` que deja el estado en «saque», y `_duelos` sale en cuanto el estado cambia (`_p5.gd:85-88`); las demás expulsiones ocurren fuera de bucles sobre `jugadores`.
7. **Partido terminado a mitad de una falta.** `_empezar_saque` no hace nada si el estado ya es «fin» (`_p2.gd:115`), así que la suspensión por menos de siete en plena falta no abre un saque fantasma.
8. **Caché de colocación de C4.** `_cache_col` sobrevive al reinicio de `t`, pero su condición `c.t − t ≤ cadencia + 0,001` descarta las entradas viejas (`motor_combinado.gd:248`): no participa de M6-08.
9. **Línea defensiva.** El caché por `t` con `==` (`_p8_p1.gd:138`) es una clave de memoización, no una comparación de magnitudes; el reinicio de la línea a `INF` en cada saque evita que el suavizado use valores viejos.

---

## 6.7 Discusión

### 6.7.1 Una causa, cuatro fallos: el reloj que vuelve a cero

M6-02, M6-03, M6-08 y M6-09 comparten una decisión de diseño razonable en su origen —`t` como «segundos de la mitad», que hace triviales el minuto y el final de cada parte— con una práctica posterior que la contradice: usar `t` como marca absoluta de plazos. Cada módulo nuevo (fintas, caídas, carreras, imagen mental, presión por zona, guía de League) añadió sus plazos sin que nada en la arquitectura avisara del problema, porque **las pruebas y las sondas miden partidos que casi nunca cruzan el descanso con el mismo objeto**: las sondas de calibración simulan por mitades o comparan cifras agregadas, y el estadio del DT rehace el motor en el descanso. Es un caso típico de invariante implícito («`t` crece monótonamente») que se viola en una frontera poco ejercitada.

Hay dos arreglos posibles. El *mínimo* es una función de rebase en `_saque_de_centro` cuando cambia la mitad, que reste el `t` final a las 31 claves y a los metadatos de los módulos; es local pero frágil, porque cada plazo nuevo tendrá que acordarse de registrarse. El *estructural* es separar los dos usos: un reloj monótono (`t_partido`, que ya existe en forma de `tiempo_jugado()`) para todos los plazos, y `t` solo para el minuto. Este capítulo recomienda el estructural, con una prueba de frontera en el banco: jugar un partido entero con el mismo motor y comprobar, en el primer segundo de cada mitad, que ningún `*_hasta` está más de 10 s en el futuro.

### 6.7.2 La entrada como estado, no como evento

M6-01 nace de otra frontera: la que separa el bucle de render del bucle de simulación. La práctica estándar en juegos de paso fijo es **leer la entrada una vez por fotograma y entregarla a la simulación como datos** (eventos con marca de fotograma, o estado del mando muestreado), nunca consultar el sistema de entrada desde dentro del paso. El fallo no se ve a 60 fps, que es donde se probó en escritorio, y se vuelve grave justo en los dos extremos que el proyecto persigue: el móvil a baja frecuencia (orden 22: 5 fps medidos) y el PC a 120 fps (orden 19). Merece prioridad porque degrada el control en el modo principal («Entrar al estadio») y porque su arreglo es pequeño y no toca la calibración.

### 6.7.3 Dos físicas en un mismo balón

M6-06 y M6-07 son la consecuencia de la estrategia de C4 de combinar piezas: cada pieza se validó por sus cifras agregadas, pero las piezas comparten **un supuesto físico** (cuánto rueda un balón) que vive en sitios distintos. La pieza «física del balón suelto» de League se enchufó sin enchufar con ella las funciones que **predicen** el movimiento del balón (velocidad de pase, compensación de arrastre, punto de recepción) ni las que lo **modulan** (clima). La lección general para el resto del combinado es que una pieza intercambiable debe llevar consigo su modelo, o exponerlo por un gancho, para que los consumidores no lo dupliquen.

Conviene subrayar que la calibración empírica de las sondas pudo haber compensado parte del efecto en la IA (los pases cortos de la IA llegan, aunque sin la «fuerza» prevista). Por eso se clasifica como media y no como alta. El pase manual del usuario, en cambio, no tiene compensación: apuntar a un punto a 12 m y que el balón se pare a 8 es exactamente la clase de fallo que el dueño describió en su prueba («jugabilidad muy mala», orden 22).

### 6.7.4 El reglamento: lo que se juzga en la recepción

El fuera de juego del motor está bien pensado —foto en el pase, juicio en la recepción, margen para el VAR— pero asume que todo balón se *recibe*. El fútbol no funciona así: el remate de primera y el cabezazo son, precisamente, las acciones en las que el fuera de juego decide goles. M6-04 es el fallo de reglamento con más impacto en el marcador de todo el capítulo y su arreglo es de pocas líneas, en un único punto (`_patear`). M6-05 es menos frecuente pero más visible para un jugador atento (un central que debería estar expulsado sigue jugando), y además deja el acta inconsistente con la sanción posterior.

Los hallazgos bajos de reglamento (M6-17 a M6-20) son omisiones conocidas en simuladores comerciales de primera generación; se registran para que la decisión de implementarlos o no sea explícita.

### 6.7.5 Las gemelas, bien; la regla de tamaño, no

La regla del proyecto sobre la extensión C++ («cada función es copia exacta de su versión GDScript») se cumple en lo revisado, y la prueba de igualdad es exigente (bytes). Su punto débil es el contrario: una gemela idéntica **reproduce también los fallos** —M6-03 está en `mover_nativo.cpp:119` exactamente igual que en `_p5.gd:186`—, así que el arreglo de M6-03 tendrá que tocar las dos y recompilar (`herramientas/compilar_nativo.sh`), como manda CLAUDE.md.

La regla de las 450 líneas se incumplió en el mismo cambio que pasó el movimiento a C++ (M6-12). Que el banco no lo detecte indica un hueco de proceso: la herramienta existe (`revisar_lineas.py --nuevos` devuelve código 1) pero no está en el camino obligatorio antes de subir.

### 6.7.6 Priorización propuesta

| Orden | Hallazgos | Motivo |
|---|---|---|
| 1 | M6-01 | Control del usuario en el modo principal; arreglo local; sin efecto en la calibración |
| 2 | M6-04, M6-05 | Reglamento con efecto en el marcador y en las sanciones; arreglos pequeños |
| 3 | M6-03, M6-02, M6-08, M6-09 | Una sola refactorización (reloj monótono) con una prueba de frontera; toca C++ |
| 4 | M6-06, M6-07 | Recalibrar C4 tras unificar la ley de rodadura; necesita sondas |
| 5 | M6-10, M6-11, M6-12, M6-13 | Modo portero, acta, regla del proyecto, cambios |
| 6 | Bajos | Por lotes, con el banco |

Ninguno de los arreglos de los puntos 1, 2 y 5 cambia la huella del motor en las sondas actuales (que no cruzan el descanso con el mismo motor ni usan entrada humana), salvo M6-04, que reducirá algo los goles de cabeza de C4 y debe medirse.

---

## 6.8 Conclusiones

1. El motor C4 es **robusto frente a fallos de ejecución** en el camino normal: las divisiones están guardadas, el azar está sembrado, las gemelas C++ son fieles y la mayoría del reglamento implementado es correcto. No se encontró ningún cuelgue ni acceso fuera de rango confirmado.
2. Sus fallos graves están en **las fronteras que las pruebas no recorren**: el cambio de mitad con el mismo motor (reloj que vuelve a cero frente a plazos absolutos), la frecuencia real de fotogramas del dispositivo (entrada leída dentro del paso fijo) y el estadio rehecho en el descanso (estado del partido que no se traspasa).
3. El reglamento tiene **un agujero de alto impacto**: el fuera de juego no se pita en remates ni pases de primera. Se arregla en un único punto.
4. La combinación de piezas de C4 dejó **dos modelos físicos** en el mismo balón; el pase manual del usuario es la víctima más clara (12 m pedidos, ~8 m reales).
5. Se registran 26 hallazgos (5 altos, 8 medios, 13 bajos; 21 confirmados y 5 plausibles), con archivo y línea, escenario y arreglo. Ninguno se ha corregido en este capítulo.
6. Recomendaciones de proceso: (a) una **prueba de frontera de mitad** en el banco (mismo motor, plazos y módulos sanos al empezar cada parte); (b) una **prueba de entrada a 30 y 120 fps** simulados para el estadio; (c) **`revisar_lineas.py --nuevos` en el banco** o antes de cada subida; (d) que toda pieza intercambiable de C4 exponga su modelo físico por un gancho.

---

## Referencias internas

- [D] `CLAUDE.md` (reglas fijas; órdenes 19, 22, 23, 38, 39, 57).
- [D] `visor/motor_jugable*.gd`, `visor/motor_league*.gd`, `visor/motor_combinado.gd`, `visor/mejoras_c4*.gd`, `visor/motor_*.gd` (módulos), `visor/league_*.gd`.
- [D] `nativo/src/mover_nativo.cpp`, `cuerpos_nativo.cpp`, `estado_nativo.cpp`, `partido_90.cpp`; `pruebas/probar_nativo.gd`.
- [D] `ui/estadio.gd`, `ui/estadio_p2.gd`, `ui/estadio_p5.gd`, `ui/partido_vivo_p1.gd`, `ui/partido_jugable*.gd`.
- [D] `nucleo/partido.gd`, `nucleo/partido_rapido.gd`, `nucleo/balance.gd`, `datos/motor_c_piezas.json`.
- [D] `docs/04_auditorias/MOTOR_LEAGUE_SOCCER_PLAN.md` (piezas y mejoras de C4), `PRUEBA_DUENO_MOVIL_2026-11-03.md` (5 fps en el móvil).
- [M] `python3 herramientas/revisar_lineas.py --todos` (16-11-2026): 2 archivos por encima de 450 líneas.
- [M] Cálculo de rodadura de M6-06: integración numérica de `dv/dt = −(0,18·v + 0,7)` a 1/60 s y de `dv/dt = −(0,017 + 0,06)·v² − 1,55` a 10 ms, con las velocidades que devuelven `velocidad_para` y los topes de `_pasar_a` y `_pase_manual`.
