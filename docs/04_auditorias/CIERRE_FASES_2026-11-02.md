# Cierre de las fases 1-9 de la orden del dueño (01-11 → 02-11-2026)

Orden 20 de `CLAUDE.md`: fallos → clubes → IA → jugabilidad → optimización → detectar fallos → sonidos de sistema →
minijuegos → entrenamiento. Orden 21: seguirlas todas sin parar, avisar solo al final y grabar dos vídeos para la nota
del dueño (1-100, con argumentos). Rama `claude/coordination-active-sessions-eyjhfl`. Banco «FIN. 0 fallos» en cada
subida; especiales en orden.

## 1. Fallos (los 8 que League-Soccer ya resolvió)
- 1-5 y 7 no existían aquí. ARREGLADOS: la posesión del motor libre que podía sumar 101; el equipo con menos de siete
  jugadores que seguía jugando (ahora se suspende, 3-0; solo en el 3D); los jugadores libres que no cumplían años; los
  goles del descuento del 3D, que ahora se leen «90+3'». Prueba `ideas/fallos_terceros`.

## 2. Clubes
- De los 8 clubes de League-Soccer, 6 ya estaban recreados (orden 15). Su base de jugadores es de ~2014 (solo 23 de 144
  siguen activos): no sirve.
- PAÍSES BAJOS deja de ser una liga inventada: la Eredivisie 25-26 (18 clubes) sale del pack real
  (`herramientas/liga_paises_bajos.py`), con nombres ficticios (se conservan los 12 de antes), escudo, uniforme,
  historia, 7 clásicos y plantillas reales de Ajax, PSV, Feyenoord y AZ (en la base pública, con guiño). Prueba
  `ideas/c1_paises_bajos`; el build público sigue sin nombres reales.

## 3. IA (cada punto con su sección en el banco y medido en 32 partidos)
- R1 ventaja de verdad: se vuelve a la falta si el equipo que la sufrió pierde el balón en 3,5 s (`MotorVentaja`).
- R3 presionadores estables y de segundo sale un medio (`MotorPresion`).
- U1 presión por zona; U3 línea de fuera de juego prevista para los desmarques; U5 el primer toque puede irse largo;
  U2 la táctica de la CPU según el marcador y el reloj; U8 estilo táctico propio de cada club.
- R2 (elegir el pase con receptor y rivales previstos) detrás de la bandera `PMOT_PASE=1`, APAGADA: encendida pasa más
  seguro (pases buenos 1873 → 1953, fueras de juego 24 → 11) y tira menos (330 → 275). DECISIÓN DEL DUEÑO.
- FALLO DE FONDO arreglado al medir U3: el portero paraba hasta 1,6 s antes de que llegara el tiro y el balón volaba
  16 m a sus manos a 167 m/s (`MotorParada`: la parada se hace cuando el balón llega).
- Cifras finales frente a antes: goles 53 → 74 en 32 partidos (≈2,3 por partido), tiros 285 → 330. VIGILAR al calibrar.

## 4. Jugabilidad
- M-131: perfiles de ayuda Arcade / Semi / Manual en el panel de controles.
- La pizarra se nota en los dos motores (8 perillas, `ideas/j4_pizarra`); salida corta, marca al hombre y tiro lejano NO
  llegaban al partido 3D: ahora sí.
- El partido simulado (`ideas/j4_partido_vivo`, `j4_partido_reacciones`): momentum, xG, palos, ocasiones; el perfil del
  árbitro no se notaba (0,1 tarjetas por partido) y ahora sí (tarjetero ×1,4; el casero carga al visitante); el clima
  no tocaba la asistencia (ahora sí; el techo retráctil salva la lluvia); la IA nunca cambiaba de plan en el 60' (ahora
  se vuelca perdiendo y el débil se cierra ganando); aviso si tu once elegido tiene un lesionado o un sancionado.

## 5. Optimización
- Medida la semana (`pruebas/zz_medir_semana.tscn`): 68 ms con 1 país, 187 ms con 6, 665 ms con las 22 ligas (87 % en
  jugar ~200 partidos simulados). Salida rápida en las reglas de cupo del once (×3). Los FPS y las llamadas de dibujo en
  hardware real son del dueño.

## 6. Detectar fallos
- Barrido de las 211 pruebas de `pruebas/ideas` que no estaban en especiales: 160 pasan. Arreglados: la pelvis de los
  clips en bucle que se disparaba (la guardia lateral del portero bajaba a −821 m durante 0,03 s: `SueloAnim` lineal),
  un sonido inexistente en malabares, el mensaje del patrocinio sin traducir y 5 pruebas viejas. Lo que queda abierto
  está en `PLAN_GENERAL.md` (fila M-470).

## 7. Sonidos de sistema
- `ideas/s7_sonidos_sistema`: los 64 sonidos que pide el juego existen; buses separados; gol propio distinto del rival;
  modo silencioso total. La patada suena más fuerte cuanto más potente (M-320).

## 8. Minijuegos
- `ideas/m4_minijuegos_3d`: penales y tiro libre 3D se juegan enteros (5 tiros, cuerpos con animación) y se cierran
  (M-408). La «Práctica libre» ya existía (M-152, fila vieja borrada).

## 9. Entrenamiento
- `ideas/j9_entrenamiento`: el mismo club 12 semanas con decisiones distintas; la intensidad, el foco y el plan de días
  cambian el progreso, el físico y las lesiones.

## Pendiente (del dueño o de la pasada final, orden 13)
- Encender o no `PMOT_PASE`; calibrar los goles por partido; FPS en hardware real.
- Pasada final del motor: F1-F8 de la IA, pisadas y más sonidos, entrenamiento visible en 3D (M-233, M-016), bar con
  minijuego (M-189).
