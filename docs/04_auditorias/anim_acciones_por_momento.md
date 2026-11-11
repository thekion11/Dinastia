# Qué clip de acción encaja con qué momento del partido (sesión 10, 11-11-2026)

Para la sesión 9 (motor, fase 4). Todos son **CC0** (Quaternius Universal Animation Library 1 y 2), están en la biblioteca de uso
`assets/characters/quaternius/anims_ual/ual_uso.res` (225 KB, viaja en los builds) con el nombre `ual1_…` / `ual2_…`, y la misma tabla en forma de datos en
`datos/anims_accion.json` (se regenera con `herramientas/ual_a_anims_extra.py` + `anims_uso_a_res.gd`). **Ningún clip desplaza la cadera** (se midió: ≤ 0,16 m en todo el
clip): el motor debe mover al jugador. Sin versión espejo (la UAL no la trae; para el lado contrario girar al jugador).

| Momento | Secuencia | Alternativas / después | Duraciones (s) | Nota |
|---|---|---|---|---|
| entrada_deslizante | `ual2_Slide_Start` → `ual2_Slide_Loop` → `ual2_Slide_Exit` |  · luego: `ual2_LayToIdle` | Slide_Start 0.83, Slide_Loop 2.00 ↻, Slide_Exit 0.50, LayToIdle 1.53 | Tackle por abajo: Start (0,83 s) → Loop mientras desliza → Exit (0,5 s) → LayToIdle si queda en el suelo. El motor mueve el cuerpo (los clips no desplazan la cadera) |
| saque_de_banda | `ual2_OverhandThrow` | — | OverhandThrow 1.33 | Lanzamiento con las dos manos por encima de la cabeza; soltar el balón hacia la mitad del clip |
| celebracion_gol | `ual1_Dance_Loop` | — | Dance_Loop 1.00 ↻ | Bucle de 1 s: repetir mientras dura la celebración |
| falta_recibida_leve | `ual1_Hit_Chest` | alt.: `ual1_Hit_Head` | Hit_Chest 0.33, Hit_Head 0.43 | Golpe en el pecho o la cabeza, 0,3-0,4 s, sin caída |
| falta_recibida_fuerte | `ual2_Hit_Knockback` |  · luego: `ual2_LayToIdle` | Hit_Knockback 0.83, LayToIdle 1.53 | Empujón que tira al suelo; después se levanta |
| caida_con_voltereta | `ual1_Roll` |  · luego: `ual2_LayToIdle` | Roll 1.47, LayToIdle 1.53 | Tropiezo/caída con rodada; acaba cerca del suelo |
| lesion_o_k_o | `ual1_Death01` | — | Death01 2.40 | Cae y se queda en el suelo (2,4 s); usar para lesión grave |
| disputa_aerea | `ual1_Jump_Start` → `ual1_Jump_Loop` → `ual1_Jump_Land` | alt.: `ual2_NinjaJump_Start`, `ual2_NinjaJump_Idle_Loop`, `ual2_NinjaJump_Land` | Jump_Start 1.33, Jump_Loop 2.50 ↻, Jump_Land 1.27, NinjaJump_Start 0.97, NinjaJump_Idle_Loop 2.00 ↻, NinjaJump_Land 1.27 | Salto: Start (1,3 s) → Loop (aire) → Land (1,3 s). Elegir Ninja si hay carrera previa |
| disputa_cuerpo_a_cuerpo | `ual1_Push_Loop` | — | Push_Loop 2.67 ↻ | Empuje continuo hombro con hombro (bucle) |
| protesta_reaccion | `ual2_Idle_No_Loop` | alt.: `ual2_Yes`, `ual1_Interact` | Idle_No_Loop 2.50 ↻, Yes 2.50, Interact 2.00 | Negar con la cabeza / asentir / señalar |
| espera_parado | `ual1_Idle_Loop` | alt.: `ual1_Idle_Talking_Loop`, `ual2_Idle_FoldArms_Loop`, `ual1_Crouch_Idle_Loop` | Idle_Loop 2.50 ↻, Idle_Talking_Loop 2.93 ↻, Idle_FoldArms_Loop 2.50 ↻, Crouch_Idle_Loop 2.93 ↻ | Reposos de variedad para jugadores parados (bucle) |

↻ = bucle.

## Lo que NO hay con licencia libre (huecos)

- **Pase, tiro, cabezazo, entrada de pie y portero**: las únicas son las de League-Soccer (`league.res`, Apache 2.0) y las de Rohr (🟡, pendientes de que el dueño confirme su licencia: no meterlas en builds públicos).
- Rohr tendría además saque de banda (`07_Throw_In`), 3 celebraciones (`12`-`14`), paradas de portero (`15`-`17`), defensa y tarjetas (`18`-`21`); ver `datos/animaciones_catalogo_rohr.json`.
- `Punch_Jab` (UAL 1) está en la biblioteca de origen pero NO en la tabla: es un puñetazo, no encaja en un partido de fútbol salvo una pelea.

## Cómo encadenar (guía)

1. Entrada deslizante: el motor arranca `Slide_Start` a la velocidad de carrera, mantiene `Slide_Loop` mientras el jugador se desliza (frenándolo) y cierra con `Slide_Exit`; si la entrada falla, `LayToIdle` (1,5 s) levanta al jugador.
2. Faltas: elegir `Hit_Chest`/`Hit_Head` (0,3-0,4 s, sin caída) para contacto leve; `Hit_Knockback` + `LayToIdle` para falta fuerte; `Death01` solo para lesión.
3. Disputa aérea: `Jump_Start` al llegar el balón, `Jump_Loop` en el aire, `Jump_Land` al caer; el cabezazo no existe como clip libre (se puede superponer el giro de cuello/torso por código).
4. Celebración: `Dance_Loop` de 1 s en bucle; variar con las 3 de Rohr cuando haya licencia.
