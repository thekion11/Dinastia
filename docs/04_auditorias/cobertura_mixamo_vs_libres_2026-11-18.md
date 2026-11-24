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
| Control de pecho | Sí | `ls_trap__*highballs__*_chest*` (11: parado, andando, esprintando, con salto, desde arriba) | cubierto |
| Control orientado | Sí | `ls_ballcontrol__idle__*` y `ls_trap__*_135` | cubierto |
| Conducir | Sí | `ls_templates__dribble*` y Rohr dribbles | cubierto |
| Reposo | Sí | `ual1_Idle_Loop`, `ls_templates__idleD000`, 100STYLE ID (79) | cubierto |

**Conclusión: 14 de los 15 huecos están cubiertos con lo libre y ya incluido (el esprint de 8-9 m/s queda a medias); Mixamo aportaría poco.** Bajarlo exige cuenta de Adobe y no se pueden publicar los archivos sueltos. No se recomienda.

## Revisión de `ls_trap` y `ls_deflect` (18-11, misma tarde)
- **`ls_trap` (40 clips sin espejo)**: control de pecho (11: `highballs__*_chest`, con salto y desde arriba), de rodilla y de empeine, controles a ras con balón de entrada a 0°, 90° y 135°, y «último recurso» (`lastditch`, estirados). Cubre control de pie, de pecho y orientado.
- **`ls_deflect` (28 sin espejo) NO es cabezazo: es PORTERO.** `holdball` = atrapada (a ras, rodilla, tronco, alta) y `deflect` = despeje/palmeo (`ground`, `midheight`, `high`, de cerca y de lejos, con estirada lateral a 90°). Cubre atajadas y estiradas. (Mi primera versión de este informe decía que League no traía portero: era un error.)
- **Cabezazo**: `ls_interfere__idle__000_header_jump` y `ls_interfere__sprint__000_header_jump` (balón a 1,8 m, 93 y 66 cuadros), más `ls_deflect`/UAL de salto para la disputa. Son pocos (2 con espejo) pero existen; CMU `16_03`, `13_10` dan saltos.
- `datos/league_toques.json` trae para cada clip el cuadro del toque y la posición del balón y del cuerpo: sirve para sincronizar balón y animación.

## Lo que falta de verdad
1. Variedad de **cabezazos** (solo 2 clips): cabezazo en plancha, de remate picado, de despeje defensivo.
2. **Pico de esprint 8-9 m/s** (el mejor son 7,35 m/s).
3. **Rohr (licencia pendiente)** ya no es necesario para el portero: League lo cubre; sirve como extra.

## Recomendación
No bajar Mixamo. Si se quiere más variedad, lo único que justifica un clip nuevo son los cabezazos; se suma con una entrada de datos en `datos/anims_extra/`. No se tocó ningún código de animación.
