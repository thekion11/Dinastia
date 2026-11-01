# IA y motor: League-Soccer frente a Dinastía

Rutas: L = `terceros/league_soccer/codigo_y_recursos/src/onthepitch/`, D = `dinastia-godot/visor/`.
Aviso de ejes: League usa X como largo y `side` (±1) como signo del arco propio; nosotros usamos Z y `dir_ataque()`. Cualquier fórmula portada necesita esa traducción.

## 1. REEMPLAZAR (lo de League es claramente mejor)

**R1. La ventaja del árbitro.** Prioridad ALTA, esfuerzo PEQUEÑO.
- Nuestro lado: D `motor_jugable_p4.gd::_falta`. Hoy la ventaja se da al azar (35 %), solo cuando la entrada falla en campo rival, y se olvida al momento. Ni se vuelve a la falta ni queda la tarjeta pendiente.
- Lo de League: L `gameplaytuning.hpp::EvaluateAdvantage` y `referee.cpp::CheckFoul`. Si la víctima pierde la posesión después de 0,6 s, el árbitro vuelve a la falta. Pasados 3,5 s, la jugada se da por jugada. En el área no hay ventaja. Con `PreservePendingCaution` e `IssuePendingCautions` la amarilla se muestra en la siguiente parada.
- Mejora: es la regla real (ley 5), y el «ventaja → falta atrás» es una jugada que se nota.
- Riesgo: hay que guardar `_falta_pendiente`, revisarla en `paso()` y no romper los gestos del árbitro. Los recuentos de `tarjetas_motor` cambian, así que las pruebas del banco de faltas pueden necesitar ajuste.

**R2. Elegir pase por cuánto mejora la jugada.** Prioridad MEDIA-ALTA, esfuerzo MEDIO.
- Nuestro lado: D `motor_jugable_p6.gd::_mejor_pase`. Suma lineal de avance, libertad y riesgo de línea con umbral 2,2 m, más ruido. No tiene en cuenta hacia dónde mira el pasador ni dónde estará el receptor dentro de 0,5 s.
- Lo de League: L `AIfunctions.cpp::AI_CalculatePassingOdds`, con un pasillo que se ensancha con la distancia (`0,45 + d·0,22`), posiciones previstas del receptor (+0,5 s) y de los rivales (+0,3 s), y castigo por orientación del cuerpo (`AI_GetPassRatings`, `bodyDirPenalty`). Además `elizacontroller.cpp::GetOnTheBallCommands` solo pasa si el compañero mejora la valoración táctica (`tacticalImprovementThreshold`), o con el pase de apoyo bajo presión (`aitactics.hpp::ShouldConsiderSupportPass`, `GetSupportPassBonus`, `longPossessionFactor`).
- Mejora: menos pases interceptados por rivales que llegan corriendo, y circulación con sentido.
- Riesgo: cambian las cifras calibradas (pases por minuto, % de acierto, `CHISPA_*`). Habría que recalibrar con las sondas. Propuesta: dejarlo como alternativa con bandera, al estilo de `TIRO_PULIDO`.

**R3. Segundo presionador estable.** Prioridad MEDIA, esfuerzo PEQUEÑO.
- Nuestro lado: D `motor_jugable_p8.gd::_ia_defensa`. El primero y el segundo salen de ordenar por distancia en cada fotograma, así que en las distancias parejas los papeles parpadean.
- Lo de League: L `teamAIcontroller.cpp::ApplyTeamPressure` y `aitactics.hpp::ShouldKeepPressurePlayer`. El presionador se mantiene salvo que otro sea más de 1,5 m mejor, y la nota es distancia + castigo por rol (`GetSecondaryPressureRolePenalty`, para que vaya un medio y no un central).
- Riesgo: bajo. Hay que guardar un id por equipo (`p["id"]`, nunca el dict).

## 2. UNIR (sumar sin sustituir)

**U1. Presión por zona.** Prioridad MEDIA, esfuerzo PEQUEÑO.
- Sumar L `aitactics.hpp::ShouldStartZonePressure` (umbral de territorio `0,55 − 0,9·presión`, distancia `5 + 8·presión`) y `GetZonePressureDuration_ms` como un gatillo más en D `_gatillo_presion`.
- El valor `_tac("presion")` (0/1/2) se pasa a 0/0,5/1.

**U2. Tácticas según el marcador y el reloj.** Prioridad MEDIA, esfuerzo PEQUEÑO.
- Sumar L `teamAIcontroller.cpp::UpdateTactics`: `goalFactor = 0,5 + (en contra − a favor)·0,17`, ponderado con `timeFactor` y mezclado con la posesión de los últimos 60 s.
- Nuestro motor jugable no tiene nada parecido. Solo `nucleo/partido.gd::_aplicar_plan`, en el minuto 60 de la simulación. Se puede alimentar con eso el `men` de D `_forma`.

**U3. Línea de fuera de juego prevista.** Prioridad MEDIA, esfuerzo PEQUEÑO.
- Sumar L `AI_GetOffsideLine(…, futureSim_ms=240)`, que proyecta a los rivales unos 240 ms hacia delante, a D `motor_jugable_p7.gd::_ultima_linea`, solo para los desmarques (`_ia_ataque_sin_balon`, `_companero_al_hueco`).
- El fuera de juego que pita el árbitro (`_foto_offside`) se queda igual: ya es correcto, incluidas las excepciones de banda, córner y puerta, iguales a las de L `setpiecerules.hpp`.

**U4. Trampa del fuera de juego suave.** Prioridad BAJA-MEDIA, esfuerzo PEQUEÑO.
- L `TeamAIController::ApplyOffsideTrap` comprime una franja de ±2 m alrededor de la línea en vez de un corte seco.
- Se aplica sobre `obj.z` en D `_ia_defensa`.

**U5. Penalización del primer toque.** Prioridad MEDIA, esfuerzo PEQUEÑO.
- L `gameplaytuning.hpp::GetFirstTouchContextPenalty`: presión a menos de 1,6 m, balón rápido que llega por el lado ciego y serenidad. Tope 0,25.
- Va como error extra en el control de D `motor_jugable_p5.gd::_tomar`. Ya tenemos `serenidad()` (p10).

**U6. Coste del esfuerzo.** Prioridad BAJA, esfuerzo PEQUEÑO.
- L `GetFatigueWorkloadFactor`: esprintar cuesta más (`0,9 + carga²·0,36`), y más todavía con balón.
- Hoy D `_aplicar_cansancio` y `forma_fisica` solo dependen del tiempo, según lo que vi. Esto lo haría depender de cómo corre cada uno.

**U7. Física del balón: solo detalles.** Prioridad BAJA, esfuerzo PEQUEÑO.
- L `ballphysics.cpp::ApplyBallMotionForces` aporta tres cosas:
  - el viento escalado por lo que el balón está en el aire;
  - `linearBounce`, un freno fijo en cada bote;
  - `wetness`, que reduce el roce a la mitad.
- Se pueden sumar en D `motor_jugable_p4.gd::_mover_balon` y `_roce_clima`.
- NO cambiar nuestro modelo de roce (lineal + constante) por su arrastre cuadrático: `distancia_rodando` y `velocidad_para` (p6) son analíticas para nuestro modelo y calibran todos los pases.

**U8. Parámetros tácticos por equipo.** Prioridad MEDIA, esfuerzo MEDIO.
- Los valores de L `TeamAIController()` (líneas 32-75):
  - `depth` 0,45 y `width` 0,95;
  - `position_{offense,defense}_{depth,width}_factor` 0,92/0,80/0,90/0,74;
  - `midfieldfocus`, `sidefocus_strength` y `microfocus_strength`, con multiplicadores de ±0,10 por ajuste del usuario.
- Además `mixup()` ajusta por rol: laterales hacia delante, centrales más abiertos y extremos o delanteros arriba según `counter_attack`.
- Hoy nuestra pizarra son enteros 0-2 (`linea`, `mentalidad`, `amplitud`, `presion`, `trampa`, `verticalidad`, `ritmo`, `tras_perdida`). Se pueden traducir a estos números continuos y guardarlos por club. `dribble_offensiveness` entra en `GetDribbleForwardDrive` (`0,55 + 0,28·x + 0,12·mentalidad del rol`) para la decisión de conducir de D `_ia_portador`.

## 3. GUARDAR PARA EL FUTURO (pasada FINAL del motor)

**F1. Colocación sin balón completa.** Esfuerzo GRANDE.
- L `TeamAIController::GetAdaptedFormationPosition` y `AI_GetAdaptedFormationPosition`:
  - `possessionBias`, que mezcla la posesión reciente y la posición del balón;
  - posición media del balón con retardo de 2-4 s según la urgencia;
  - microfoco hacia el portador y foco en el medio campo;
  - límites de profundidad y anchura del bloque.
- Es mucho más rico que D `_forma`, que solo mezcla 55 % de la base y 45 % del balón.
- Cómo usarlo: como nueva `_forma`, con los parámetros de U8 y un banco de sondas que compare la compacidad y la distancia entre líneas.

**F2. Roles dinámicos con el algoritmo húngaro.** Esfuerzo MEDIO-GRANDE.
- L `CalculateDynamicRoles`: cada jugador ocupa el hueco de la formación más cercano, de modo que los puestos se permutan.
- Cómo usarlo: con 10 jugadores de campo la matriz es de 10×10. Basta un húngaro en GDScript cada 0,5 s, o candidato a la extensión C++ (con su copia GDScript, según la norma).

**F3. Desmarques de apoyo por campo de fuerzas.** Esfuerzo GRANDE.
- L `ElizaController::GetSupportPosition_ForceField` (repulsión de rivales y compañeros según el rol, atracción al portador, `GetSupportWebScale`, «forward support player»), junto con `default_off.cpp`, `default_mid.cpp` y `default_def.cpp` (`AddDefensiveComponent`, `GetLazyVelocity`, la pereza).
- Sustituiría los desplazamientos fijos de D `_ia_ataque_sin_balon` (±9 m y +5 m) y la `_zona_de_llegada` codificada a mano.

**F4. Marcaje individual de los 3 rivales más peligrosos.** Esfuerzo MEDIO.
- L `CalculateMarkingQuality` y `CalculateManMarking`.
- Hoy D `_ia_defensa` marca al rival más cercano a la zona.

**F5. Carreras al espacio con temporizador.** Esfuerzo MEDIO.
- L `SelectAttackingRunPlayer`, `ApplyAttackingRun` y `GetAttackingRunThreshold/Duration` (2,8-5 s según `counter_attack`).
- Se combina con las jugadas prehechas (`_guiar_jugada`).

**F6. Tiro por probabilidad de línea limpia.** Esfuerzo MEDIO.
- L `GetOnTheBallCommands`: tres puntos del arco, `odds^0,5 + azar` mayor que 0,55.
- Alternativa a `ganas_tiro` en D `_ia_portador`, a evaluar junto a `TIRO_PULIDO`.

**F7. Portero.** Esfuerzo MEDIO.
- L `goalie_default.cpp::CalculateIfBallIsBoundForGoal` con `IsGoalMouthThreat` (anticipación).
- Comparar con D `_reaccion_portero` y `salida_portero.gd`. No los comparé línea a línea.

**F8. Imagen mental.** Esfuerzo MEDIO.
- L `mentalimage.cpp`: una foto con retardo de lo que «ve» cada jugador.
- Sirve para la dificultad de la CPU en 8 niveles: más retardo y menos lectura en Practicante, menos en Ultimate.

## 4. NO SIRVE

- **`humanspeed.hpp`:** son deslizadores de velocidad del jugador humano (1,8-9,5 m/s), un perfil de mando. Tenemos el nuestro (`PRESETS` realista/arcade en p11). Como mucho sirve de referencia.
- **`referee.cpp::Process` y `BallTouched` en general:** están atados a su sistema de animaciones y funciones (`TouchAnim`, `GetTouchFrame`) para medir la gravedad de la barrida. Nuestro `puntos_falta` por factores es más explicable y está calibrado.
- **`_AddPanicPass` y el umbral de pánico del portero (`possessionAmount < 3`):** son tosquedades. Nuestro despeje en `_ia_portador` ya cubre ese caso.
- **`match.cpp`, `team.cpp` y `officials.cpp`:** el bucle de partido, la cámara, el reloj, la repetición y el movimiento de los asistentes están unidos a su motor (blunted). Lo nuestro (`_mover_arbitros`, `_gestos_del_arbitro`) ya cumple. No vi nada que valga la pena portar, aunque `officials.cpp` solo lo hojeé.
- **La simulación de resultados (`nucleo/partido*.gd`):** League no tiene un simulador estadístico, así que no hay nada que comparar ni que reemplazar ahí.
- **Arrastre cuadrático del balón:** rompería la calibración analítica de los pases (ver U7).

## Orden sugerido

Ahora, en bloques pequeños: R1, R3, U1, U3, U5, U2. Cada uno lleva su sección en el banco.

Antes de la pasada final: R2 (con bandera) y U8.

En la pasada final: F1-F8. Encajan como tres capas nuevas: colocación, apoyo y marcaje.
