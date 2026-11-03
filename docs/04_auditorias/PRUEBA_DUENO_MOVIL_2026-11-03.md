# Prueba del dueño en su teléfono (3-11-2026, versión del 2-11 a las 17:00)

15 capturas del dueño (partido, sorteo, foto de equipo, salida de los equipos, ciudad del prólogo, panel de rendimiento del
teléfono, creación de personaje). Su veredicto: **«visualmente es bueno, jugabilidad muy mala»**. El plan del lunes queda en
pausa salvo el código duplicado (M-391) y el rendimiento. Lo que sigue manda sobre el plan hasta cerrarlo.
Nota: la versión probada es anterior a lo de la noche del 2-11 (calidad Mínima, carga diferida, memoria del partido,
penales, física del balón): varias cifras ya mejoraron, pero hay que volver a medir en su teléfono.

## Cifras en su teléfono
- Calidad MEDIA: media de **5 FPS**, nunca más de 10 (3-10 FPS en partido, 3-6 en las salidas y la foto). Menú: 28 FPS.
- **GPU al 100 %, CPU al 0 %**: el cuello de botella es la gráfica (no el GDScript). 2,8 h de partida, 36 % de batería.
- Objetivo del dueño: **60 FPS**; la calidad por defecto debe ser **la más baja**.

## Rendimiento (ejecutora)
- R2. Cuello de botella de GPU en móvil: MÍNIMA ya es la calidad por defecto y el estadio va más ligero (3-11); falta MEDIR
  en su teléfono si llega a 60 FPS y, si no, seguir bajando (píxel 50 %, recorte en CPU, impostores).
- R3. Lo lejano no se carga (streaming por cercanía); edificios y público lejanos como impostores/MultiMesh.
- R5. Menos subprocesos/hilos innecesarios.
- R6. M-391: código duplicado entre MatchPlayback y MotorJugable.
- R7. «Modo rendimiento» (la prueba del dispositivo): se buggea y deja volver atrás y crear partida mientras corre.

## Partido y físicas (ejecutora)
- P1. El partido «sigue siendo un asco»: jugabilidad, movilidad del jugador horrible.
- P2. En modo jugar: triángulo invertido de color fuerte sobre el jugador controlado.
- P3. Límites físicos de las zonas de los árbitros (no se meten donde no deben).
- P4. Cajas de colisión (hitbox): los personajes atraviesan su propio cuerpo y el suelo.

## Ciudad y mundo abierto (sesión de ciudad)
- C1. El prólogo aún no carga en su teléfono.
- C2. Nombres flotando sobre los lugares, visibles de lejos: deben ir EN el edificio (cartel) y solo de cerca.

## Interfaz y contenido (líder)
- U4. Faltan clubes y las cifras reales de jugadores e información del club (en curso: planteles de las 8 ligas sin
  plantel y la arquitectura de los 226 estadios que faltaban).
- U6. Partes del juego que existen en el código pero no se encuentran jugando: ya visibles «Mi carrera» (ofertas,
  dimitir, confianza de la directiva) y «Directorio y consejeros» en el menú; seguir auditando el resto.
- U7. Revisar si a `main` le falta algo.

## Preguntas del dueño (respondidas en el chat del 3-11)
Comprar árbitros, cambiar de club, despido, consejero, lenguaje de programación, «mini triángulos».
