# Rediseño del menú central (pedido del dueño, 3-11-2026)

Idea: el menú central queda LIVIANO y casi todo pasa a **pantallas secundarias** (las del menú lateral izquierdo), cada una
a pantalla completa y que **solo se carga (y compila) al abrirla**. Los accesos más usados tienen atajo en el central; el
jugador elige cuáles (los «favoritos» de Ajustes ya existen). Junto con la separación de familias de scripts
(`compilacion_menu_2026-11-03.md`) el menú queda partido en más de 15 puntos de carga.

## Lo que queda en el central
- Arriba: club, CONFIANZA (sube al encabezado), dinero en una línea, fecha y semana.
- Avanzar (Un día / Calendario) y la tira de días.
- Próximo partido: la tarjeta grande solo 1-2 días antes del partido (el resto del tiempo, propuesta: una línea pequeña).
- Objetivos del mentor: MINIMIZADOS por defecto; se estiran al tocarlos.
- Informe de la semana y atajos (configurables).
- Clima: el calor solo con un ☀️.

## Pantallas secundarias (lateral izquierdo)
| Pantalla | Qué lleva |
|---|---|
| Jugadores («central de jugadores») | plantel, media del once, la estrella, ficha del jugador a pantalla completa |
| Partido (el ⚽ de arriba) | previa, táctica, rival |
| Competiciones | tabla, selector de club (solo aquí), el 🌎 del mundo, todas las competiciones |
| Dinero (el 💰 de arriba) | caja, sueldos, finanzas |
| Estadio | estadio y obras |
| Club | toda la sección «Club» (a los submenús del lateral) |
| Mi carrera | carrera del DT |
| Correo | correo |
| Glosario | glosario |
| Normas | normas |
| Ajustes | + «Otro mundo», Guardar y Cargar |

## Guardado
- Automático (ya existe por ranuras; revisar que guarde cada día y tras cada partido: en el móvil el sistema puede
  cerrar la app sin «salir»).
- Al salir, pregunta si quieres guardar. Guardar/Cargar solo desde Ajustes.

## Orden de trabajo (líder)
1. Esqueleto: pantalla secundaria a pantalla completa genérica que carga su código al abrir + atajos configurables.
2. Mover bloque a bloque (Jugadores, Competiciones, Dinero, Partido… ) con captura antes/después y pruebas.
3. Central nuevo (próximo partido 1-2 días antes, objetivos minimizados, ☀️, confianza arriba).
4. Guardado automático + pregunta al salir; Guardar/Cargar/Otro mundo a Ajustes.
5. Medir la RAM del menú (.pck precompilado) tras cada paso.

## Decisiones del dueño (3-11, respuesta)
- ATAJOS: NO se ven en pantalla. Son teclas internas (p. ej. «P» abre la central de plantilla), reasignables en Ajustes, y
  CUALQUIER menú (del central o secundario) puede tener una. Base: `AtajosCentrales` (ya existe, 1-9/0, N, F3, F5, InputMap y
  `TeclasInterfaz`): se amplía a todas las pantallas y se cambian las teclas por defecto a letras con sentido.
  En el teléfono (sin teclado) se entra por el lateral; con mando, los atajos que ya tenga.
- TABLA DE LA LIGA: se queda en el central tal cual; la versión detallada va a Competiciones.
- PRÓXIMO PARTIDO: línea mínima siempre; la tarjeta grande solo 1-2 días antes.
