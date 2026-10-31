# Auditoría del coche y de los peatones (31-10-2026)

Pieza F de §2.2h del plan: «primero una AUDITORÍA del coche actual y de los peatones; luego tres mejoras pequeñas elegidas por el dueño».
Leída en el código de la rama `claude/segunda-sesion-guion-2`. Las rutas son de `dinastia-godot/`.

## Lo que hay

| Tema | Hoy | Dónde |
|---|---|---|
| Física | `_physics_process` con trozos de ≤ 0,3 m. Velocidad máxima 26 m/s (~94 km/h), marcha atrás −8 m/s. Aceleración de 7,7 m/s² parado a ~2,9 m/s² arriba. Frenada ~0,95 g. Pedal suavizado. Giro que se cierra con la velocidad (×0,55 a tope). Carrocería que cabecea | `visor/explorador_ciudad_p5.gd` (`_conducir`) |
| Freno de mano | Espacio / B: frena 9 m/s² y el giro ×1,6. **Sin derrape real** (no hay deslizamiento lateral) | p5 `_conducir` |
| Marchas | Solo en el sonido (5 marchas sintetizadas). La 5.ª empieza a 92 km/h con tope a 94: casi nunca suena | `visor/motor_coche_sonido.gd` |
| Colisiones | Coche = 3 círculos. Edificios en rejilla, coches del tráfico rectángulos y peatones círculos (a < 30 m). De frente rebota (−25 %). En diagonal se desliza (−8 %) | `explorador_ciudad_p1/p2/p4.gd` |
| Golpes | > 2,5 m/s: sonido, sacudida y vibración. A > 25 km/h contra coche o peatón: multa (contador) + claxon. 3 multas = calabozo | p4, `vida_ciudad*.gd` |
| Atropellos | **No hay**: el peatón es un obstáculo sólido, sin reacción ni daño | — |
| Aparcar | **No hay**: el modo (coche / a pie) se elige al empezar el paseo; no te bajas del coche | `menu_lateral.gd`, p4 |
| Gasolina | Depósito de 45 l; premium +15 %; aviso en el móvil por debajo del 15 %. **Sin indicador ni luz de reserva** en el salpicadero (solo km/h) | `nucleo/vida_dt.gd`, `cabina_coche.gd` |
| Daños, radio, luces, claxon | **No hay** daños visibles, radio, intermitentes ni tecla de claxon. Los faros son estéticos | — |
| Cámaras | V: tercera persona / capó / interior con velocímetro | p3, p5 |
| Peatones | Hasta 34 alrededor (18 en calidad media), reciclados cada 1,2 s. Se adelantan, charlan y miran el móvil. Ante el coche esperan; ante ti a pie te rodean. **No se asustan.** Suben y bajan del bus. Ninguno toma coches | `trafico_ciudad*.gd`, `pasajeros_bus.gd` |
| Rendimiento | ~310 coches y vecinos en total, ~3,4 ms por fotograma. LOD a 150 y 260 m | `trafico_ciudad.gd` |

## Arreglado hoy (fallo claro, sin decisión de diseño)

- Sin gasolina el coche avanzaba a trompicones: `VidaCiudad` lo paraba en `_process` y `_conducir` lo volvía a acelerar en cada paso de física.
- Ahora el pedal no empuja con el depósito vacío (`ExploradorCiudad.sin_gasolina`; prueba en `f3v_vida`).

## Rarezas que piden una decisión del dueño

1. **Consumo de 2,5 l/km** (`VidaDT.L_POR_KM`): da solo 18 km por depósito; un coche real gasta 0,06-0,08 l/km. Puede ser a propósito, porque la ciudad está a escala reducida y así la gasolina se nota. ¿Se deja así o se baja (p. ej. a 0,5 l/km: un depósito ≈ 90 km)?
2. **Multas temerarias sin coste**: solo cuentan para el calabozo. La del semáforo sí cobra. Además, tras el calabozo de la semana, las multas siguientes se ponen a 0 sin castigo, así que conducir a lo loco sale gratis hasta el lunes. ¿Cobrar cada multa (p. ej. 60 €) de la cartera?
3. **Choques de lado y contra algo fijo** no multan aunque haya un peatón o un coche (se prioriza la pared).
4. **Avería del coche**: el taller toca 1 semana de cada 8 por sorteo, no por el uso ni por los choques.
5. **Tráfico en `_process`** (delta variable) y el jugador en `_physics_process`: pueden verse pequeños tirones o solapes al ir pegado a otro coche.
6. El HUD dice «V: vista» solo a pie, aunque V cambia la cámara también en coche.

## Mejoras candidatas (el dueño elige tres)

| # | Mejora | Tamaño |
|---|---|---|
| A | Indicador de gasolina y **luz de reserva** en el salpicadero y en el HUD | pequeño |
| B | **Derrape** con freno de mano (deslizamiento lateral que se recupera) | medio |
| C | **Daños visibles** (abolladuras/arañazos por golpes) y el taller según los choques | medio |
| D | **Aparcar**: bajarse del coche (F) donde estés y volver a él | medio |
| E | **Radio** con 3 emisoras (música libre ya en el proyecto) y tecla de claxon | pequeño-medio |
| F | **Atropello con reacción**: el peatón salta a un lado o cae y se levanta; multa y titular | medio |
| G | Peatones que **se asustan** (corren) si vas rápido cerca de la acera | pequeño |
