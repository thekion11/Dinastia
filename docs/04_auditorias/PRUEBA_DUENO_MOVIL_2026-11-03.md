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
- R1. Calidad por defecto = MÍNIMA en todas las plataformas (el jugador sube si quiere).
- R2. Cuello de botella de GPU en móvil: resolución del 3D, sombras, público (miles de figuras), vallas, focos, edificios
  lejanos. Medir qué pesa en el partido y bajarlo en MÍNIMA hasta 60 FPS en gama media.
- R3. Lo lejano no se carga (streaming por cercanía); edificios y público lejanos como impostores/MultiMesh.
- R4. Pantallas de carga más largas y más usadas: cargar también lo que vendrá y dejar que el juego se estabilice
  (compilar shaders, precalentar) antes de mostrar.
- R5. Menos subprocesos/hilos innecesarios.
- R6. M-391: código duplicado entre MatchPlayback y MotorJugable.
- R7. «Modo rendimiento» (la prueba del dispositivo): se buggea y deja volver atrás y crear partida mientras corre.

## Partido y físicas (ejecutora)
- P1. El partido «sigue siendo un asco»: jugabilidad, movilidad del jugador horrible.
- P2. En modo jugar: triángulo invertido de color fuerte sobre el jugador controlado.
- P3. Límites físicos de las zonas de los árbitros (no se meten donde no deben).
- P4. Cajas de colisión (hitbox): los personajes atraviesan su propio cuerpo y el suelo.
- P5. **ARENA DE PRUEBAS**: un banco aislado para probar una cosa sola (solo la cancha + un jugador + el árbitro, sin
  público ni menú), mirarla desde varios ángulos a la vez y medirla; reutilizable para cualquier pieza del juego
  (prueba de la pieza sola y de integración).

## Ciudad y mundo abierto (sesión de ciudad)
- C1. El prólogo aún no carga en su teléfono.
- C2. Nombres flotando sobre los lugares, visibles de lejos: deben ir EN el edificio (cartel) y solo de cerca.
- C3. Minimapa solo al subirse a un vehículo.
- C4. Botón «E»: solo en PC y solo muy cerca del objeto.
- C5. Primera persona en móvil: imposible hoy.
- C6. Movilidad del personaje mala (controles táctiles).
- C7. «¿Dónde está lo de salir al mundo abierto?»: que se encuentre fácil.

## Interfaz y contenido (líder)
- U1. Antes de cada partido, una pantalla completa: **Simular / Jugar / Jugar solo las jugadas importantes**.
- U2. Muchas partes de la pantalla inicial deben salir a su propia pantalla completa.
- U3. «¿Empezamos así?» / «Sí, ese soy yo»: debe ser una foto del personaje 3D, no un dibujo que no se le parece.
- U4. Faltan clubes y las cifras reales de jugadores e información del club.
- U5. Sonido apagado: más sonidos y más presencia.
- U6. Partes del juego que existen en el código pero no se encuentran jugando (consejero, cambiar de club, comprar
  árbitros…): auditar y hacerlas visibles.
- U7. Revisar si a `main` le falta algo.

## Preguntas del dueño (respondidas en el chat del 3-11)
Comprar árbitros, cambiar de club, despido, consejero, lenguaje de programación, «mini triángulos».
