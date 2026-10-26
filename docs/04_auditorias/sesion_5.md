# Sesión 5: ocasiones jugables y el porqué del resultado (26-10-2026)

Rama: `ccr-76d707c5-dwse9h-s5`. Encargo: las filas 14 y 4 de `docs/04_auditorias/investigacion_s4/03_propuesta.md`, aprobadas por el dueño.
Commits: `f3d774c5` (ocasiones jugables) y el commit final de esta sesión (el porqué, el informe y el plan).

## Resultado del cierre

| Comprobación | Resultado |
|---|---|
| `herramientas/banco.sh` | **FIN. 0 fallos** (2.601 comprobaciones, 135 s) |
| `herramientas/especiales.sh todo` | **todo en orden** (10/10, con la norma de 450 líneas) |
| `herramientas/ideas.sh s5_ocasiones` | **0 fallos** (169 s) |
| `herramientas/ideas.sh s5_causas` | **0 fallos** (11 s) |
| Capturas en Forward+ con la cámara real | 6, en `docs/04_auditorias/capturas_sesion_5/` |

## 1. Ocasiones jugables en el partido del DT (fila 14)

**Qué ve el jugador.** En el partido en 3D (modos «3D completo» y «3D destacados», con el motor real), en 3 a 6 llegadas claras de su equipo el partido se para. La cámara baja a pie de campo, detrás del que lleva el balón, y aparecen tres botones: **pase** (a quién), **conducción** o **tiro**. Cada botón muestra su probabilidad y una ⭐ marca lo que recomienda el cuerpo técnico. Se elige con clic, con las teclas 1/2/3 o con el mando (A pase, X conducción, B tiro). Hay 7 s para decidir; si no se elige, el jugador hace lo recomendado. Tras un pase o una conducción puede tocar decidir otra vez (como mucho 3 decisiones). Cada ocasión dura como mucho 15 s reales. Al terminar sale un aviso («⚽ ¡GOOOL!», «🧤 ¡La saca el portero!», «🥅 ¡Al palo!», «😩 Se va fuera», «❌ Te la quitaron») y vuelve la cámara de la tele.

**Dónde se enciende.** Hay un interruptor en el panel previo al partido (`InformeRival`, «⚡ Ocasiones jugables: SÍ/NO»), no en la pantalla de ajustes. Está encendido por defecto y la elección se guarda.

**Por qué el resultado es coherente con la simulación:**
- No se añade ninguna ocasión. Solo se toma la decisión en llegadas que ya existen en el partido simulado.
- La decisión la ejecuta el mismo motor del césped (`MotorJugable`), con sus propios `_tirar()` y `_pasar_a()`. El error, el portero y los defensas son los de siempre.
- El tiro usa la misma puntería al azar que la IA. Un primer tiro «perfecto» (al palo contrario y raso) convertía entre el 30 y el 60 % incluso desde 25 m: habría sido un gol de regalo, así que se descartó.
- Mientras se elige, el motor no da ni un paso: los defensas no se mueven y nadie sale ganando con la pausa.
- Los goles van al acta, a la tabla y a las estadísticas como cualquier otro gol.

**Los porcentajes, medidos contra el motor que juega.** La lectura de la jugada usa `MotorLibre`: se le copian las posiciones del césped, se le da el mando del que lleva el balón (`tomar_control`) y su IA de utilidad (`_opciones`, con `AccionesJuego`) dice a quién pasar y cuánto vale cada opción. Las cifras de `MotorLibre` no se parecían a lo que pasa en el 3D, así que se calibraron con sondas (ya borradas):

| Medición | Resultado |
|---|---|
| Tiro limpio, solo ante el portero: 2.700 tiros de 9 a 30 m, centrados y escorados, con el mejor y el peor tirador | ~80 % a 9 m con el mejor tirador, ~30 % a 17 m, ~15 % a 25 m. El xG de `MotorLibre` decía 4 % a 20 m |
| Tiro con un rival tapando la línea | 0-2 % |
| Tiro con un rival al lado, sin tapar | casi igual que sin presión |
| Partidos enteros eligiendo siempre lo mismo: 20 semillas, 66 tiros y 105 pases | el tiro convierte ~0,55 de la curva limpia; el pase llega ~0,66 de lo que dice `MotorLibre` |
| Validación con 12 semillas nuevas, ya ajustado | pase: botón 43 %, césped 49 %. Tiro: botón 13 %, césped 10 % |

La curva del tiro está en `OcasionesDT.prob_tiro_3d()`. La recomendación compara todas las opciones en la misma moneda (probabilidad de acabar en gol): pasar o conducir vale lo que valdría el tiro siguiente. Con la cifra de `MotorLibre`, el cuerpo técnico no habría recomendado tirar nunca.

**Cuántas salen.** El cupo de cada partido es de 3 a 6, fijo por partido (semilla por los clubes, sin tocar `Azar`). Se reduce en proporción si el partido se abre a mitad. Tras el descanso en el camarín el cupo sigue, no vuelve a cero. Un equipo flojo pisa el área con espacio en solo 9 a 12 minutos de cada 90, así que hay tres niveles de exigencia: normal, «apurado» y «mínimo de tres». En la prueba del partido entero salen 4 de 6, todas cerradas y la más larga de 13,8 s.

**Archivos**
- `nucleo/ocasiones_dt.gd` (nuevo): cupo, criterio de llegada clara, lectura con `MotorLibre` y curva del tiro 3D.
- `ui/ocasion_jugable.gd` y `ui/ocasion_jugable_p1.gd` (nuevos): la pausa, los botones, la cuenta atrás, la cámara a pie de campo (`CameraRig.insertar_plano`) y el aviso.
- `ui/estadio.gd`, `ui/estadio_p1.gd` y `ui/estadio_p5.gd`: se monta en tu partido con el motor real (nunca en la práctica ni sin pantalla). Se mira tras **cada** paso del motor, para cazar la jugada antes de que la IA la resuelva.
- `ui/componentes/informe_rival.gd`: el interruptor.
- `pruebas/ideas/s5_ocasiones.gd` y `pruebas/captura_s5_ocasion.gd` (nuevos).

**Prueba (`s5_ocasiones`):**
- El cupo, el criterio y los niveles de exigencia.
- La lectura (tiro, pase y conducción con su probabilidad).
- Cada elección ejecutada por el motor real, sin que corra el reloj mientras se elige.
- La elección automática al acabarse el tiempo y el tope de 15 s.
- Un partido entero en piloto automático y el cupo tras reabrir el estadio.
- La coherencia botón/césped en 4 partidos deterministas por elección: pase 41 % frente a 39 %, tiro 15 % frente a 20 %.

**Límites (decididos, no olvidados):**
- Solo en los modos 3D con el motor real. En «En vivo (texto)», «Resumen» e «Instantáneo» no hay cámara ni motor del césped que ejecute la jugada.
- Con «motor real» apagado (`ControlPartido`, jugadas con guion), tampoco.
- Si el jugador controla a su equipo con el mando, no salen: ya está jugando.

## 2. El porqué del resultado (fila 4, la parte del partido)

**Qué ve el jugador.** Tras cada partido aparece «🔎 POR QUÉ» con las **tres causas que más pesaron**: icono, nombre y una frase con cifras. El nombre va en verde si te ayudó, en rojo si te hundió y en gris si fue para los dos. Sale en el resumen (`ResumenPartido`, modos «Resumen» e «Instantáneo») y en el final del partido en vivo, también tras el 3D (`PartidoVivo`).

**De dónde salen.** Nada se inventa. `RastroPartido` (nuevo) escucha las señales del `Partido`: no usa `Azar` y no toca el marcador (probado). Guarda cuatro cosas:
- Cómo llegaban los dos onces: forma, físico, media y pizarra.
- El momentum minuto a minuto.
- Lo que el árbitro decidió por su cuenta y contra quién.
- Las rojas y las lesiones.

Con eso, `CausasPartido` (nuevo) arma las candidatas:

| Causa | Cuándo sale |
|---|---|
| Momentum | El cuarto de hora con más llegadas netas de un lado y los goles que cayeron en él |
| Forma, plantilla | Diferencia de forma media o de media del once al empezar |
| Clima | La lluvia traba el partido para los dos; el visitante no está hecho al clima |
| Táctica del rival | Su pizarra abrió o cerró el partido, con el cambio real de llegadas de cada uno, y su plan del 60' (le salió o lo pagó) |
| Cansancio | Diferencia de físico; sin cambios y goles encajados después del 75' |
| Árbitro | Las rojas y las tarjetas o penales que decidió por su cuenta |
| Eficacia | Goles frente a xG, de los dos |
| Lesión | Un jugador tuyo lesionado durante el partido |
| Localía, posesión | Relleno, solo si no hay nada más fuerte |

Si ganaste van primero las causas a tu favor; si perdiste, las de en contra; en el empate, las que más pesaron. Sale una por tipo.

**Dos decisiones de honestidad:**
- La pizarra no «gana la partida» en neto, porque las perillas de `Tactica` restan atrás lo que suman delante. Por eso la causa táctica cuenta lo que sí cambia: el volumen de llegadas (por ejemplo, «partido abierto, +115 % de llegadas suyas y +108 % de las nuestras»).
- Si el partido lo jugó el motor del 3D, no se usan el clima, el xG ni la localía: ese motor no los modela y sería contar una causa que no existió.

**Archivos**
- `nucleo/rastro_partido.gd` y `nucleo/causas_partido.gd` (nuevos).
- `nucleo/partido_p2.gd`: 4 líneas (crea el rastro y lo prepara).
- `ui/componentes/resumen_partido.gd` y `ui/partido_vivo.gd`: lo pintan.
- `pruebas/ideas/s5_causas.gd` y `pruebas/captura_s5_porque.gd` (nuevos).

**Prueba (`s5_causas`):**
- Cada causa con un partido preparado: forma, roja, árbitro, momentum, clima, el motor 3D sin clima ni localía, el cerrojo del rival que le salió o no, la pizarra distinta y la lesión.
- El rastro no gasta azar y el mismo partido da lo mismo.
- 60 partidos reales: siempre 3 causas distintas, la primera explica el resultado en 45 de 45 partidos decididos, y salen 8 a 10 tipos de causa.
- Las dos pantallas.

## Capturas (`docs/04_auditorias/capturas_sesion_5/`)

- `s5_ocasion_eligiendo.jpg`: la pausa a pie de campo con los tres botones, la ⭐ y la cuenta atrás.
- `s5_ocasion_tiro.jpg`: el tiro elegido, en marcha.
- `s5_ocasion_resultado.jpg`: el aviso «Se va fuera», de vuelta al plano de TV.
- `s5_panel_previo_interruptor.jpg`: el interruptor en el informe del rival.
- `s5_porque_resumen.jpg` y `s5_porque_partido_vivo.jpg`: el porqué en las dos pantallas.

## Textos

**54 frases nuevas**, todas con `Idiomas.t` y traducidas a los 8 idiomas con `herramientas/sumar_traducciones.py`. Se comprobó por programa que en cada traducción los marcadores de formato van en el mismo orden que en castellano: había 2 frases en turco al revés y se corrigieron.

## Lo que queda y avisos para otras zonas

- **Fila 4, parte de finanzas** («cada ingreso y gasto con su origen y no el año partido en 12»): no estaba en este encargo y sigue pendiente en el plan.
- **Para quien lleve `visor/motor_jugable*`:**
  - Un tiro limpio ante el portero convierte mucho desde cerca: ~80 % a 9 m con el mejor tirador y 63 % de media entre el mejor y el peor.
  - Un rival tapando la línea lo deja casi siempre en 0 %.
  - En partido real, la precisión de pase es ~72 %.
  - Si se recalibra, hay que repetir la sonda del tiro y tocar `OcasionesDT.prob_tiro_3d()` y los dos `AJUSTE_*`. La prueba `s5_ocasiones` avisará si el botón deja de cuadrar con el césped.
- **Para quien lleve `MotorLibre`:** su xG del tiro y su pase no se parecen a los del motor 3D. Si algún día se enchufa al visor, conviene calibrarlo como aquí.
- **Uso de funciones internas:** `OcasionJugable` llama a funciones internas de `MotorJugable` (`_tirar`, `_pasar_a`, `_presion`, `_arco_rival`, `_decision_en`, `_rng`, `_tiro_vivo`). Están comentadas, pero si se renombran hay que tocarla. La prueba lo cazaría.
- **Zona de `nucleo/partido_p2.gd`:** no estaba en la lista de zonas prohibidas, pero es del núcleo. El cambio son 4 líneas que solo enganchan el rastro.

## 3. Rueda de prensa según el contexto (petición del supervisor, aprobada por el dueño)

**Qué cambia para el jugador.** Detrás de la pregunta de siempre (la que depende del resultado) pueden llegar hasta tres más, cada una de un periodista distinto, todas en la misma sala:

| Pregunta | De dónde sale |
|---|---|
| El porqué del partido | La causa que más pesó (`Partido.ultimas_causas`, de `CausasPartido`): el tramo en que el rival les encerró, la eficacia, el árbitro, la lesión, la pizarra del rival, un once mejor sobre el papel… |
| La racha | 3 o más victorias o derrotas seguidas en la liga |
| El último fichaje | Solo la primera vez que llega uno; se guarda cuántos se preguntaron |
| El próximo rival | Si es el clásico o uno de los tres primeros |

**La duración varía.** Hay una pregunta extra de base, una más si hay mucho en juego (goleada, clásico o directiva con la confianza baja) y otra si la racha es de 4 o más. Uno de cada tres días tranquilos no hay ninguna. En total, la rueda tiene de 1 a 4 preguntas.

**Delegar en el ayudante.** La primera pregunta trae una opción más: «🙋 Que responda mi ayudante». Se acaba la rueda entera y tiene un coste:
- −2 de relación con cada periodista;
- −1 de confianza de la directiva;
- −2 de reputación «Mediático»;
- la portada de mañana: «El DT no dio la cara: habló su ayudante».

Con portavoz no aparece, porque ya habla otro por ti.

**Cómo encaja.**
- Va en `nucleo/prensa_contexto.gd` (nuevo) y en dos sobrescrituras en `nucleo/prensa.gd` (`abrir_rueda` y `responder`).
- La pantalla no se ha tocado (`ui/principal/rueda_prensa*` es de otra sesión): ya pinta todas las opciones y ya encadena preguntas cuando `responder()` devuelve `"sigue": true`, como hacía con la repregunta.
- La portada sale de la respuesta más llamativa de la rueda, no de la última.
- No se gasta azar: los sorteos van por hash de la fecha.
- La cola de preguntas y los fichajes preguntados se guardan con la partida (`nucleo/partida_p1.gd`).
- `nucleo/partido.gd` guarda las causas del último partido de tu club.
- 61 frases nuevas, traducidas a los 8 idiomas.

**Prueba (`pruebas/ideas/s5_rueda.gd`, 0 fallos):**
- Cada tipo de pregunta, con sus datos.
- El porqué de otra semana no se pregunta y el fichaje no se repite.
- Una rueda real de 3 preguntas, que se responden encadenadas.
- La delegación con sus cuatro costes.
- Que con portavoz no se puede delegar, que no se gasta azar y que todo se guarda con la partida.

Mini banco de «textos» y «partido», banco entero: 0 fallos.

**Para la sesión de la interfaz de la rueda:** se puede usar `entrevista["numero"]` y `entrevista["total"]` para mostrar «2/3» en el plató.
