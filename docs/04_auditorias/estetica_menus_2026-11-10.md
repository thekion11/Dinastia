# Estética de los menús principales: coherencia con PES 2020 / eFootball (10-11-2026)

Encargo de la líder (PRIORITARIO 1 del plan: «estética y diseño de los menús, falta pulir»). Sin cambiar la estructura ni romper el móvil.

## Referencia
Konami presentó PES 2020 con una «identidad visual renovada» en los menús de Master League, y la crítica la vio más clara aunque
todavía cargada. Con eFootball 2022 se pasó a un estilo «simple y limpio», lejos del recargado de PES 2021. Fuentes:
[Impulse Gamer](https://www.impulsegamer.com/the-next-evolution-of-pes-is-here-efootball-pes-2020-announced/),
[FourFourTwo](https://www.fourfourtwo.com/features/pes-2020-review-new-features-master-league-online-myclub-licenses),
[GamesRadar](https://gamesradar.com/pes-2020-review),
[RealSport101](https://realsport101.com/pes/efootball-2022-mobiles-new-menu-ui-will-blow-pes-2021s-out-the-water).

No hay documentación oficial de su tipografía ni de su rejilla. Lo que se tomó es lo que se ve en sus menús:
1. **Pocas letras y estables:** un título grande, un nombre destacado, un cuerpo y un rótulo pequeño en mayúsculas para las cabeceras.
2. **La cara y el escudo como protagonistas** en las listas de jugadores y en las fichas.
3. **Rejilla fija:** el contenido siempre en el mismo sitio de la pantalla al pasar de un menú a otro.
4. **Foco claro y único:** el mismo marco de acento en todo lo que se puede pulsar.
5. **Cambios de pantalla rápidos** (~0,2 s), sin esperas.

## Cómo se midió
`pruebas/auditoria_estetica_menus.tscn` (en `especiales.sh`, con pantalla, PC a 1600×900). Recorre inicio, plantel, táctica, mercado,
competiciones y club con **2 clubes** (Lautaro FC, CHI; Diagonal FC, ARG) y comprueba:
- **escala tipográfica:** como mucho 3 tamaños con peso (≥ 3 % de los textos), sin contar los títulos héroe ni las iniciales de los
  escudos;
- **rejilla:** el contenido de los menús empieza en el mismo x y deja el mismo margen derecho;
- **estados:** todo lo que se pulsa tiene foco y pulsado que se ven;
- **caras y escudos:** en las filas del plantel y de competiciones miden al menos 28 px.

## Antes
- **Tipografía:** 8 tamaños de letra en las pantallas de gestión (10, 11, 12, 13, 14, 15, 16, 17), repartidos sin regla. El Inicio
  tenía 4-5 tamaños con peso, y el plantel y la táctica 4; en una misma fila convivían 11, 12 y 13.
- **Caras:** de 22 px en la tabla del plantel y en las listas de táctica.
- **Estados:** los desplegables, casillas y botones de menú tenían el foco y el desactivado de fábrica (otro color y grosor que los
  botones).
- **Transición:** entrar en un menú tardaba 0,25 s de fundido y 0,3 s de deslizado.
- **Rejilla:** ya era coherente (contenido en x = 84 px y 22 px de margen derecho en todos los menús).

## Arreglos
- **`EscalaTipografica`** (nuevo, lo monta la principal): **tres tamaños** en el contenido de los menús.
  - Niveles: rótulo 11 (cabeceras, notas), cuerpo 13 (texto corriente y botones: la base de los botones ya era 13) y destacado 16
    (nombres en tarjetas, subtítulos).
  - Cada tamaño de 10-17 px se lleva al nivel más cercano, en el primer dibujado de cada control.
  - No toca:
    - los títulos héroe (≥ 18) ni lo diminuto (≤ 9, iniciales dentro de un escudo);
    - el partido (su HUD tiene su escala por milímetros);
    - nada si el jugador cambió la escala de texto de Ajustes.
  - En el móvil, la letra mínima legible va después y manda.
- **Caras de 30 px** (`Principal.RETRATO_FILA`) en la tabla del plantel y en las listas de táctica (antes, 22).
- **Foco y desactivado comunes:** los desplegables, casillas y botones de menú usan el mismo marco de acento de 2 px y el mismo
  desactivado que los botones.
- **Entrada a los menús:** 0,18 s de fundido y 0,22 s de deslizado (antes, 0,25 y 0,3). La salida (0,15 s) y el cambio de
  submenú (0,18 s) ya eran cortos.

Resultado: **0 fallos** en las 12 pantallas (6 × 2 clubes). Cada pantalla tiene 2-3 tamaños con peso (11, 13 y, en el Inicio, el 20 del
título) y caras de 30 px en las filas. Los únicos 12 px que quedan son los nombres largos del mercado que `TextoQueCabe` encoge para que
quepan. Siguen en verde el banco, la gestión en el móvil, la navegación con mando, `mem_menu_estadio` (el menú no nombra las clases del
partido: se reconocen por la ruta del script) y las 54 pruebas de interfaz y móvil.

## Prototipo para que elija el dueño: iconos dibujados y cabecera compacta en PC
- **`IconosUI`:** 16 iconos propios del mismo estilo para el riel lateral y la cabecera de los menús.
  - Los 16: menú, estadio, caminar, plantel, partido, dinero, trofeo, historia, gente, carrera, operaciones, vida, editar, reglas,
    ajustes, ciudad.
  - Estilo: trazo de 1,8 sobre rejilla de 24, puntas redondeadas y sin relleno, como los de eFootball.
  - El SVG va en el código y se rasteriza al tamaño justo, con caché.
  - Dibujados para Dinastía: sin licencias de terceros, anotado en `LICENCIAS.md`.
- **Ajustes → Pantalla:**
  - «Iconos dibujados»: apagado por defecto (emoji); al cambiarlo, el riel cambia al momento.
  - «Cabecera compacta de los menús» en PC: apagada por defecto; en el móvil sigue la suya, encendida.
  - Las dos se guardan en las preferencias (`pantalla/iconos_dibujados`, `pantalla/cabecera_compacta_pc`).
- **Prueba:** `auditoria_estetica_menus` con `ICONOS=1 COMPACTA_PC=1` comprueba que se rasterizan los 16 y repite todas las
  comprobaciones con el prototipo encendido.

## Pendiente (propuestas, piden el visto bueno del dueño)
- ¿Iconos dibujados por defecto? Si el dueño los quiere, faltan los del cajón y las tarjetas de portada (hoy siguen con emoji).
- ¿Cabecera compacta también por defecto en PC?
