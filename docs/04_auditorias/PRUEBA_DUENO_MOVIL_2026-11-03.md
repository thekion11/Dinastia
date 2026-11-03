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
- P4. Cajas de colisión (hitbox): los personajes atraviesan su propio cuerpo y el suelo. En la FOTO DE EQUIPO los brazos
  atraviesan a los compañeros (prioridad, 3-11); revisar también la salida de los equipos y el sorteo.

## Ciudad y mundo abierto (sesión de ciudad)
- C1. El prólogo aún no carga en su teléfono.
- C2. Nombres flotando sobre los lugares, visibles de lejos: deben ir EN el edificio (cartel) y solo de cerca.

## Interfaz y contenido (líder)
- U4. Clubes y cifras reales: 372 de 402 clubes con plantel y 402 con su estadio real; Egipto, Marruecos,
  Sudáfrica y los clubes chicos de Corea, Australia y Holanda contrastados con búsqueda web (fuentes en
  docs/05_referencia/fuentes_planteles_2026-11-03.md). Queda: con Wikipedia permitida en la red, rehacer la
  verificación con más rigor; segundas divisiones (hoy solo Chile tiene dos) si el dueño las pide.
- U6. Hecho el 3-11: meta de cantera, roles del once en el partido, perillas de la pizarra y menú lateral con
  Plantel, Dinero y Competiciones. Quedan menores: pagar con tarjeta y PIN en tiendas, contador de amarillas antes
  de la sanción, detalle del coste de cada viaje, y revisar si vuelven los cedidos por un evento de prensa.
- U7. Revisar si a `main` le falta algo.

## Preguntas del dueño (respondidas en el chat del 3-11)
Comprar árbitros, cambiar de club, despido, consejero, lenguaje de programación, «mini triángulos».
