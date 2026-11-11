# Guía para la próxima prueba en tu teléfono (11-11-2026)

Para qué sirve: con lo que midas aquí decidimos el MOTOR del partido y si el rendimiento ya llega a la meta (60 FPS en el
partido). Son unos 30-40 minutos. No hace falta hacerlo todo de una vez: cada parte vale sola.

**Versión a instalar:** la de `main` actual (0.9.2). En el móvil ya vienen ENCENDIDOS por defecto: «Modo rendimiento»,
«Ahorro en los menús también en Media», tope de 90 FPS y resolución 3D automática.

---

## Parte 1 — FPS (10 min)

1. Ajustes → calidad **Mínima**, y enciende **«Mostrar contador de FPS»**.
2. Mira el contador en cada sitio unos 20-30 segundos y anota el número **típico** y el **más bajo** que veas:
   - **Menú** principal.
   - **Club** (pasillos, vestuario u oficinas).
   - **Partido**: en juego normal, con el balón en el medio del campo (no en repeticiones ni en celebraciones).
   - **Partido**: en un ataque con muchos jugadores cerca del área.
3. Si te sobra tiempo, repite el partido en calidad **Baja** (o **Media**).
4. (Opcional, 6 min) En la configuración inicial está **«Prueba de rendimiento (unos 6 min)»**: recorre menú y estadio
   solo y deja un informe en el portapapeles. Pégalo en el chat tal cual.

> Comparación: el 3-11, en Media, eran 5 FPS en el partido; hacia el 4-11, en Mínima, 60 en el menú y 30 en el partido.

## Parte 2 — Motores a ciegas (20-30 min)

1. Ajustes → **«Motor del partido (prueba a ciegas)»**: elige **A**, **B** o **C**. El juego se reinicia (la partida se conserva).
2. Juega **un partido entero** (o al menos una parte) con esa letra. Al terminar te pregunta
   **«¿Cuánto te divirtió este partido?»** (1 a 5): contesta con sinceridad.
3. Repite con las otras letras. **No pulses «Revelar qué es cada letra»** hasta terminar las tres: así no te influye
   saber cuál es el nuevo.
4. Para cada letra anota en 1-2 frases lo que sientas. Lo que más nos sirve:
   - **Mando**: ¿responde al instante o con retraso? ¿Los giros y frenadas se sienten naturales?
   - **Movimiento**: ¿los jugadores parecen personas o robots? ¿Patinan?
   - **Juego**: ¿hay regates y duelos? ¿Se construyen jugadas de pases? ¿Hay ocasiones?
   - **Ritmo**: ¿demasiados goles, muy pocos o bien?
   - **FPS**: ¿alguna letra va más lenta que otra?
5. Al final pulsa «Revelar qué es cada letra» y mándame la línea de votos que aparece debajo (o una captura).

> Si aparecen C1, C2 y C3 en vez de solo C, son tres versiones del motor combinado: pruébalas igual.

## Parte 3 — Mandar los resultados

Copia esta plantilla, rellénala y pégala en el chat (con capturas si quieres):

```
FPS (Mínima):  menú __ (mín __) · club __ (mín __) · partido __ (mín __) · ataque __ (mín __)
FPS (Baja/Media, opcional): partido __
Informe de la prueba de rendimiento: (pegar)

Motor A: nota __/5 · sensaciones: ...
Motor B: nota __/5 · sensaciones: ...
Motor C: nota __/5 · sensaciones: ...
Revelado: (línea de votos)
Lo que más me molestó: ...
Lo que más me gustó: ...
```

Con esto: (1) decidimos qué motor queda por defecto; (2) sabemos si hay que seguir bajando el coste gráfico del
partido; (3) lo apuntamos como dato real en `PLAN_GENERAL.md` para que ninguna sesión trabaje con cifras viejas.
