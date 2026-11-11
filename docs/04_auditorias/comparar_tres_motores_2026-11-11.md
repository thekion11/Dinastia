# Comparar los tres motores del partido por DIVERSIÓN (11-11-2026)

Sesión 11, rama `sesion11-comparador`. Criterio del dueño: **jugabilidad y diversión**, no cifras reales (`PLAN_GENERAL.md`, nota «MOTOR DEL PARTIDO»).
Los tres motores: **siempre** (el nuestro, `MotorJugable`), **league** (`MotorLeague`, estado de `main` del 11-11 antes de la fase 4 de la sesión 9) y
**combinado** (`MotorCombinado`: League con piezas cambiables por las nuestras). Con las piezas por defecto el combinado es IDÉNTICO a league
(misma semilla, mismos partidos: lo muestran las tablas); con todas las piezas «siempre» reproduce exactamente al nuestro (probado en el banco).

> **Aviso para el selector a ciegas:** mientras no se cambie ninguna pieza de `datos/motor_c_piezas.json`, **el motor B y el C (los que toquen a league y combinado) son IGUALES**: el reparto A/B/C solo se vuelve informativo cuando C lleva al menos una pieza nuestra (candidata: `decide_con_balon = siempre`).

## Cómo se midió
- `pruebas/comparar_tres_motores.tscn` (parte de `comparar_motor_league`): 6 partidos COMPLETOS por motor en autopiloto (2 × 240 s de reloj
  del motor, 30 Hz), mismos onces y misma semilla para cada motor. Clubes de 3 países (CHI, ESP, BRA), cruces de países distintos y estilos
  distintos (orden 34). Medidor: `pruebas/medidor_diversion.gd` (lee contadores y señales desde fuera; no toca el motor).
- Definiciones: **ocasión clara** = tiro (no penal) desde ≤ 16,5 m del arco y sin rival a menos de 2,5 m; **robo en duelo** = cambio de equipo con
  el nuevo poseedor a ≤ 2,5 m de donde estaba el anterior; **cadena** = pases seguidos del mismo equipo sin perderla ni parar el juego;
  **gol de contra** = ≤ 10 s tras recuperar; **a balón parado** = ≤ 10 s tras falta o córner; **de lejos** = tiro desde ≥ 20 m; **juego seguido** =
  tramo continuo en estado «juego»; **cambio de resultado** = gol que cambia quién gana (empate → ventaja, igualada o remontada).
- Coste de CPU: µs de `motor.paso` por paso, en este contenedor (4 núcleos, 3 procesos a la vez): sirve para comparar entre motores, no son cifras de teléfono.
- «Ablación»: el combinado con UNA sola pieza cambiada por la nuestra (`MOTOR_C_PIEZAS=pieza=siempre`), para ver qué aporta cada pieza.
- Repetir: `N_PARTIDOS=6 MITAD=240 MOTORES=siempre,league,combinado godot --headless --path . res://pruebas/comparar_tres_motores.tscn > registro.txt`
  y `python3 herramientas/informe_tres_motores.py registro.txt …`. **n = 6 partidos por variante: son tendencias, no estadística firme.**

## Lo que dicen las cifras (lectura, no veredicto: el veredicto es del dueño jugando)
1. **League, tal como está, es un partido mucho más quieto**: ~5 tiros y ~1 gol por partido contra ~49 y 6 del nuestro; el juego casi no se para
   (56 s seguidos de media, 93 % del tiempo en juego, 10 saques frente a 59). Menos regates (5 contra 21), menos duelos y pocas ocasiones claras (0,5 contra 3).
2. **Pero League encadena mucho mejor los pases**: cadenas de 2,4 pases de media y 7 de máximo (nuestro 1,5 y 4), y 1,7 cadenas de 5+ pases por partido (nuestro 0,5).
   Nuestro motor es de ida y vuelta (43 cadenas cortas, 31 pérdidas a distancia): más acción, menos construcción.
3. **Variedad de goles**: el nuestro marca de todo (de lejos 2,7, de contra 1, parados 0,8, penales 0,8); League casi solo de jugada, cabeza y algún parado: con tan
   pocos goles la variedad no es medible aún. Ojo: los 2,7 goles de lejos y los penales de nuestro motor son lo que el dueño ya dijo que sobra en «cifras reales».
4. **Cambios de marcador**: nuestro 2,3 cambios de resultado y 0,7 remontadas por partido; League 1,0 y 0,3 (muchos 0-0: 3 de 6).
5. **Palos y paradas**: nuestro 2 palos y 12,7 paradas por partido; League 0,17 y 1,2 (el portero casi no trabaja).
6. **CPU**: nuestro 1 486 µs/paso, league 1 522, combinado 1 614 (diferencias < 10 %: dentro del ruido de 3 procesos en 4 núcleos); el paso más caro de League es 3 veces el nuestro (57 ms contra 20 ms: la predicción del balón y los 11 × 11 pases), un riesgo de tirones en el móvil que habrá que medir allí.

## Ablación del combinado: qué pieza hace qué (League con UNA pieza nuestra)
- **decide_con_balon = siempre**: 42 tiros, 4 goles, 3,3 cadenas de 5+ pases y cadena máxima 12 (la mejor de todas), acierto de pase 86 %, 2,0 cambios de resultado,
  goles de lejos 1,5 y parados 1,5, juego seguido 14 s. **Es la que más cambia**: aporta los tiros y los goles; y, curiosamente, junto con la colocación de League da las cadenas más largas.
  **Candidata a C**: «lo de League para colocarse y moverse + nuestra decisión con balón».
- **coloca_sin_balon = siempre**: 12 tiros, 3,8 goles, MÁS duelos (48) y más robos (20), cadenas cortas (1,5) y 2,3 penales por partido; es la más cara en CPU (2 236 µs/paso).
  La colocación de League evita los duelos y aporta la construcción; la nuestra da más fricción.
- **fisica_balon = siempre**: casi igual que League (6 tiros, 1,3 goles): la física del balón no explica la diferencia de ritmo.
- **locomocion = siempre**: casi igual que League en acción (5 tiros), con cadenas más largas (2,9) y el menor coste (1 255 µs/paso, −18 % frente a League): la fase 4 de League cuesta CPU y no cambia el juego (en esta medida, sin animaciones visibles).

## Por probar (siguientes pasos)
- Combinado que parta de «decide_con_balon = siempre» (ya se puede: `datos/motor_c_piezas.json` o `MOTOR_C_PIEZAS`); sumar piezas de dos en dos (decide + locomoción…).
- Repetir cuando la sesión 9 termine la fase 4 (la comparación justa), con más partidos (`N_PARTIDOS=18`) y con `INVERTIR=1`.
- Coste en el teléfono del dueño (FPS en MÍNIMA) con cada letra: no medible aquí.
- Vídeo lado a lado con la cámara real: **no hecho** (requiere xvfb + `--write-movie` ≈ horas por software, ver orden 21); el script `herramientas/grabar_partido_hd.sh` sirve de base.
- Los votos del dueño (1-5) se guardan en `user://motor_ciego.json` con el motor real; cruzarlos con estas cifras.

Partidos por variante: combinado = 6, league = 6, siempre = 6, combinado[coloca_sin_balon=siempre] = 6, combinado[decide_con_balon=siempre] = 6, combinado[fisica_balon=siempre] = 6, combinado[locomocion=siempre] = 6

## Tablas: Acción y ocasiones (por partido)

| medida | combinado | league | siempre | combinado[coloca_sin_balon=siempre] | combinado[decide_con_balon=siempre] | combinado[fisica_balon=siempre] | combinado[locomocion=siempre] |
|---|---:|---:|---:|---:|---:|---:|---:|
| goles | 1.0 | 1.0 | 6.0 | 3.83 | 4.0 | 1.33 | 1.5 |
| tiros | 4.8 | 4.8 | 48.7 | 12.5 | 41.8 | 6.2 | 5.3 |
| tiros de área | 1.7 | 1.7 | 9.2 | 6.2 | 5.8 | 3.5 | 3.0 |
| ocasiones claras | 0.5 | 0.5 | 3.0 | 2.17 | 3.0 | 2.0 | 1.0 |
| paradas del portero | 1.2 | 1.2 | 12.7 | 2.2 | 9.3 | 1.2 | 0.8 |
| tiros al palo | 0.17 | 0.17 | 2.0 | 0.17 | 1.5 | 0.5 | 0.33 |
| tiros fuera | 2.5 | 2.5 | 28.7 | 6.5 | 27.3 | 3.2 | 2.8 |

## Tablas: Regates y duelos (por partido)

| medida | combinado | league | siempre | combinado[coloca_sin_balon=siempre] | combinado[decide_con_balon=siempre] | combinado[fisica_balon=siempre] | combinado[locomocion=siempre] |
|---|---:|---:|---:|---:|---:|---:|---:|
| regates | 4.7 | 4.7 | 21.0 | 12.0 | 12.7 | 5.7 | 6.5 |
| regates logrados | 2.0 | 2.0 | 8.0 | 6.2 | 6.2 | 2.5 | 3.8 |
| duelos (hombro, dividido, agarrón) | 17.2 | 17.2 | 38.7 | 48.5 | 23.5 | 21.3 | 18.8 |
| robos en duelo (≤ 2,5 m) | 2.7 | 2.7 | 12.0 | 20.3 | 5.0 | 3.2 | 3.3 |
| pérdidas a distancia | 11.5 | 11.5 | 30.8 | 27.8 | 26.7 | 10.7 | 11.3 |

## Tablas: Pases encadenados

| medida | combinado | league | siempre | combinado[coloca_sin_balon=siempre] | combinado[decide_con_balon=siempre] | combinado[fisica_balon=siempre] | combinado[locomocion=siempre] |
|---|---:|---:|---:|---:|---:|---:|---:|
| pases | 65.8 | 65.8 | 122.0 | 107.7 | 112.8 | 66.8 | 64.8 |
| acierto de pase % | 79.3 | 79.3 | 76.6 | 73.4 | 85.6 | 72.9 | 81.7 |
| cadenas | 12.0 | 12.0 | 42.7 | 14.5 | 35.2 | 11.0 | 10.0 |
| pases por cadena (media) | 2.4 | 2.4 | 1.54 | 1.47 | 2.37 | 1.94 | 2.94 |
| cadena más larga (media de máximos) | 7.2 | 7.2 | 4.2 | 3.5 | 12.3 | 4.7 | 7.2 |
| cadenas de 5+ pases | 1.67 | 1.67 | 0.5 | 0.33 | 3.33 | 0.5 | 2.17 |

## Tablas: Goles: variedad (goles por partido de cada tipo)

| medida | combinado | league | siempre | combinado[coloca_sin_balon=siempre] | combinado[decide_con_balon=siempre] | combinado[fisica_balon=siempre] | combinado[locomocion=siempre] |
|---|---:|---:|---:|---:|---:|---:|---:|
| jugada | 0.5 | 0.5 | 0.5 | 0.67 | 0.5 | 0.17 | 0.5 |
| contra | 0.0 | 0.0 | 1.0 | 0.17 | 0.0 | 0.17 | 0.0 |
| parado | 0.17 | 0.17 | 0.83 | 0.67 | 1.5 | 0.33 | 0.17 |
| cabeza | 0.17 | 0.17 | 0.17 | 0.0 | 0.17 | 0.17 | 0.33 |
| lejos | 0.0 | 0.0 | 2.67 | 0.0 | 1.5 | 0.0 | 0.0 |
| penal | 0.17 | 0.17 | 0.83 | 2.33 | 0.33 | 0.5 | 0.5 |

## Tablas: Marcador y ritmo

| medida | combinado | league | siempre | combinado[coloca_sin_balon=siempre] | combinado[decide_con_balon=siempre] | combinado[fisica_balon=siempre] | combinado[locomocion=siempre] |
|---|---:|---:|---:|---:|---:|---:|---:|
| cambios de resultado | 1.0 | 1.0 | 2.33 | 1.67 | 2.0 | 1.0 | 1.0 |
| remontadas | 0.33 | 0.33 | 0.67 | 0.5 | 0.67 | 0.17 | 0.17 |
| juego seguido medio (s) | 56.1 | 56.1 | 8.7 | 12.1 | 14.0 | 42.0 | 50.2 |
| juego seguido máximo (s) | 225.2 | 225.2 | 32.8 | 64.4 | 75.5 | 228.7 | 225.7 |
| % del tiempo en juego | 93.4 | 93.4 | 76.4 | 75.1 | 82.9 | 92.3 | 93.1 |
| paradas del juego (saques) | 9.8 | 9.8 | 58.7 | 45.2 | 36.8 | 13.3 | 11.5 |

## Tablas: Coste de CPU del motor

| medida | combinado | league | siempre | combinado[coloca_sin_balon=siempre] | combinado[decide_con_balon=siempre] | combinado[fisica_balon=siempre] | combinado[locomocion=siempre] |
|---|---:|---:|---:|---:|---:|---:|---:|
| µs por paso (30 Hz) | 1614.0 | 1522.4 | 1486.2 | 2235.9 | 1461.8 | 1605.3 | 1255.4 |
| ms por partido | 25215.0 | 23790.0 | 29709.0 | 47569.0 | 26506.0 | 25499.0 | 19737.0 |
| paso más caro (µs) | 74298.0 | 57022.0 | 20256.0 | 52257.0 | 68334.0 | 60610.0 | 16615.0 |

## Tablas: Partidos jugados

| # | partido | combinado | league | siempre | combinado[coloca_sin_balon=siempre] | combinado[decide_con_balon=siempre] | combinado[fisica_balon=siempre] | combinado[locomocion=siempre] |
|---|---|---|---|---|---|---|---|---|
| 1 | Lautaro FC (CHI, 4-2-3-1 ofensivo) - Pompeia SC (BRA, 4-3-3 vertical) | 0-0 | 0-0 | 3-1 | 2-0 | 3-2 | 1-0 | 0-0 |
| 2 | Azenha FC (BRA, 4-3-3 equilibrado) - Abando AC (ESP, 4-2-3-1 bandas) | 2-1 | 2-1 | 1-4 | 0-2 | 1-0 | 0-1 | 0-0 |
| 3 | Abando AC (ESP, 4-2-3-1 bandas) - Viña Marina (CHI, 4-3-3 vertical) | 1-1 | 1-1 | 4-2 | 4-4 | 1-2 | 0-0 | 1-0 |
| 4 | Chillán Rojo (CHI, 4-4-2 contra) - Leao da Barra (BRA, 4-4-2 directo) | 1-0 | 1-0 | 2-7 | 1-1 | 4-4 | 0-3 | 0-2 |
| 5 | Itapuã FC (BRA, 4-2-3-1 posesion) - Neptuno AC (ESP, 4-4-2 contra) | 0-0 | 0-0 | 3-4 | 1-6 | 1-2 | 0-0 | 0-1 |
| 6 | Vallecas Franja (ESP, 4-2-3-1 presion) - Rancagua Celeste (CHI, 4-3-3 equilibrado) | 0-0 | 0-0 | 1-4 | 2-0 | 2-2 | 2-1 | 3-2 |
