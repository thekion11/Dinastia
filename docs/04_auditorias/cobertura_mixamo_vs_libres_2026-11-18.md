# ¿Hace falta Mixamo? Tabla de `DORSALES_ANIM_2026-11-17.md` frente a los clips libres que ya están en el repo (18-11-2026)

Conteo real de las bibliotecas de uso (sacado cargando los `.res`, no de memoria):
`league.res` **586** clips (Apache 2.0): `ls_movement` 98 · `ls_ballcontrol` 90 · `ls_trap` 80 · `ls_pass` 74 · `ls_deflect` 56 · `ls_trip` 38 · `ls_shot` 34 · `ls_highpass` 30 · `ls_templates` 20 · `ls_interfere` 14 · `ls_sliding` 12 · `ls_celebration` 6 (con espejos).
`cmu_uso.res` **155** (libre, citando CMU) · `ual_uso.res` **27** (CC0) · extras de locomoción: 100STYLE 143 ciclos (ID 79, FR 41, SR 15, BR 6; CC BY 4.0), 12 ciclos CMU y 2 de la UAL (`datos/anims_extra/`) · Rohr 21 (licencia pendiente del dueño).
El motor lee `datos/league_movimiento.json` (49 clips con entrada/salida/ángulo: arranques 8, frenadas 9, giros 15, cambios de ritmo 26) y los JSON de `datos/anims_extra/`: sumar un clip es poner una entrada de datos, no tocar código.

| Hueco de Mixamo | ¿Ya hay clip libre? | Con qué | Veredicto |
|---|---|---|---|
| Trotar | Sí | `ual1_Jog_Fwd_Loop`, ciclos CMU 3,2-4,3 m/s, 100STYLE FR | cubierto |
| Correr | Sí | `ls_templates__sprintD000`, ciclos CMU, 100STYLE FR | cubierto |
| Esprint 8-9 m/s | Casi | `ual1_Sprint_Loop` (7,35 m/s medidos), League sprint | cubierto salvo el pico de 8-9 |
| Trotar atrás | Sí | 100STYLE BR (6) | cubierto |
| Lateral izq./der. | Sí | 100STYLE SR (15) + espejo | cubierto |
| Arrancar | Sí | League arranques (8: 0-135°) | cubierto |
| Frenar | Sí | League frenadas (9) + `ls_ballcontrol__sprint__*_decel` | cubierto |
| Giro 180 corriendo | Sí | League giros 135° y `dribble__180_decel` | cubierto (135° y 180°) |
| Quiebro 45-90° izq./der. | Sí | League giros 45° (9) y 90° (3) con espejo | cubierto |
| Giro parado 90° | Sí | `ls_movement__idle__090_accel`, `ls_ballcontrol__idle__090/135/180` | cubierto |
| Control con el pie | Sí | `ls_trap` (80) | cubierto |
| Control de pecho | Por comprobar | `ls_trap` / `ual1_Hit_Chest` no es control | dudoso: revisar los nombres de `ls_trap` |
| Control orientado | Sí | `ls_ballcontrol__idle__*` y `ls_trap__*_135` | cubierto |
| Conducir | Sí | `ls_templates__dribble*` y Rohr dribbles | cubierto |
| Reposo | Sí | `ual1_Idle_Loop`, `ls_templates__idleD000`, 100STYLE ID (79) | cubierto |

**Conclusión: 13 de los 15 huecos están cubiertos con lo libre y ya incluido; Mixamo aportaría poco.** Bajarlo exige cuenta de Adobe y no se pueden publicar los archivos sueltos. No se recomienda.

## Lo que SÍ falta (y Mixamo tampoco lo resuelve bien)
1. **Portero** (estirada, atajada, despeje): League no trae categoría de portero; CMU 33/34 solo lanzar y atrapar; Rohr trae 3 paradas (`15_` a `17_Goalkeeper_Save`) pero su licencia no está confirmada. Es el mayor hueco real.
2. **Cabezazo**: League tiene `ls_deflect` (56) que podría servir; CMU, saltos (`16_03`, `13_10`). Por comprobar pose a pose.
3. Pico de esprint 8-9 m/s y control de pecho: menores.

## Recomendación
No bajar Mixamo. Prioridad: (a) que el dueño confirme la licencia de Rohr (desbloquea las 3 paradas); (b) revisar `ls_deflect` y `ls_trap` para cabezazo y control de pecho. No se tocó ningún código de animación: no hizo falta.
