# Dorsales, nombre en la espalda y animación más natural (17-11)

Punto 7 de `COMPARACION_REFERENCIAS_PARTIDO_2026-11-16.md` («Jugadores: dorsal y nombre legibles de lejos; animaciones para
carrera, control y giro»). Solo cambia lo que se VE: la huella del motor (`pruebas/igualdad_motor.tscn`) sigue en 4068298361.
Capturas: `capturas_dorsales_anim_2026-11-17/` (cámara real de TV y de cerca, Forward+ sin GPU, calidad ALTA; tres cruces de
países distintos: ARG-ESP, BRA-ITA y MEX-ENG). Banco: `_probar_dorsales_anim` (grupo `partido`).

## A) Dorsal y nombre en la espalda

| Antes | Ahora |
|---|---|
| Dígitos de siete segmentos con bordes duros: de lejos parpadeaban y se leían como un reloj digital | Tipografía deportiva hecha con distancias con signo (trazos, arcos y anillos de punta redonda), `visor/dorsal_q.gdshaderinc` |
| Borde del número a saltos de píxel (dientes de sierra y parpadeo al moverse) | Borde suavizado con el tamaño real del píxel sobre la tela (`dFdx`/`dFdy`): de lejos se funde en vez de chisporrotear |
| Sin contraste garantizado (número blanco sobre camiseta blanca o rojo sobre rayas rojas se perdía) | RIBETE solo cuando hace falta: contraste WCAG del número contra cada color de la camiseta (rayas incluidas); < 4,5 → borde del tono opuesto (más grueso si < 2,5). `DisenosKit.ribete_numero` |
| Sin nombre | APELLIDO sobre el número (letras de 5 × 7, A-Z, punto, guion y apóstrofo; tildes, Ñ, Ç… pasan a su letra base; hasta 12 letras, los largos se estrechan); de lejos se funde en un tono medio. `DisenosKit.letras_nombre`, `apellido_espalda` (nombre visible, como el rótulo del partido) |
| Patrocinador de la espalda arriba | Con nombre, el patrocinador de la espalda baja bajo el número (como en la Premier League) |

Coste: **ninguna llamada de dibujo, textura ni material nuevo**. Cada jugador ya tenía su propio material por el dorsal
(`VestidorQ`, clave de caché), y el apellido va en la misma clave. Solo ALU en los píxeles de la espalda. Árbitro: sin nombre.
Llamadas de dibujo medidas en la vista de TV (ALTA, mismo fotograma): iguales (tabla de coste abajo).

## B) Animación más natural

1. **Carrera sin patinar** (`visor/ciclo_carrera.gd`, `CicloCarrera`): antes el cambio trotar↔correr era un umbral seco a 5,2 m/s
   (a 5,1-5,3 m/s el ciclo cambiaba casi cada fotograma, con un fundido que reiniciaba la zancada) y la escala de reproducción se
   cortaba en 0,7-1,4 (el trote no pasa de 4,8 m/s: entre 4,8 y 5,2 m/s los pies se quedaban cortos, y por debajo de 2,4 m/s el
   trote iba más deprisa que el cuerpo). Ahora: histéresis (a correr a 5,2 m/s, a trotar por debajo de 4,5) y margen de escala por
   ciclo (trote 0,55-1,55; carrera 0,6-1,45). Medido en el banco: entre 2 y 10 m/s el pie patina **0,00 m/s** (antes hasta 1,86) y,
   con la velocidad temblando ±0,15 m/s, 4 cambios de ciclo en una subida y bajada completas.
2. **Inercia del cuerpo** (`visor/inercia_cuerpo.gd`, `InerciaCuerpo`, un `SkeletonModifier3D` justo después de la animación):
   - ladeo hacia dentro en las curvas (ángulo ≈ a/g, tope 13°) y cabeceo al arrancar/frenar (tope 9°), girando alrededor del punto
     del césped bajo la pelvis (los pies casi no se mueven);
   - el torso que se adelanta al giro: el pecho se gira hacia la marcha cuando el cuerpo aún mira a otro lado (tope 28°, repartido
     en tres vértebras; no en la guardia, el repliegue ni el portero);
   - CONTROL ORIENTADO: el medio segundo después de hacerse con el balón, el pecho se abre hacia donde sale el balón (0,3 s más
     adelante).
   La gobierna `AnimacionCercana` (H1): solo los jugadores a menos de 33 m de la cámara, peso suave (~0,3 s), de MEDIA hacia arriba y
   sin «Partido ligero». En ULTRA BAJA, BAJA y MEDIA BAJA no se monta (comprobado en el banco). `INERCIA=0` la apaga.

## Coste medido

Vista de TV en el fotograma 90 de `pruebas/captura_dorsales_anim.tscn` (Forward+, ALTA, sin GPU):

| Cruce | Llamadas antes → después | Triángulos antes → después |
|---|---|---|
| ARG-ESP (Boedo AC - Madrigal CF) | 584 → 582 | 1.181.070 → 1.181.530 |
| BRA-ITA (Azenha FC - Tevere FC) | 571 → 571 | 1.269.622 → 1.270.258 |
| MEX-ENG (Occidente FC - Lilywhite FC) | 407 → 408 | 1.154.764 → 1.148.820 |

Las diferencias son de la animación (cada fotograma cambia qué queda dentro de la vista), no del dorsal: ningún material, textura ni
llamada nueva, en ninguna calidad (MÍNIMA y ULTRA BAJA incluidas). En la GPU, el dorsal y el nombre son solo cuentas en los
píxeles de la espalda.

CPU (`pruebas/medir_h1_animacion.tscn`, COL-GER, 900 fotogramas, ALTA, `INERCIA=0` / `1`, dos veces cada una): `AnimacionCercana.actualizar`
pasa de ~96-122 µs a ~173-189 µs por fotograma (**+~70 µs**: la medida de la inercia de los jugadores cercanos). El tiempo de proceso
total de esa prueba no sirve para comparar aquí (24-96 ms con la CPU compartida con otra sesión; varía más entre dos corridas iguales
que entre con y sin). En el móvil (Modo rendimiento y calidades bajas por defecto) la inercia no se monta: coste cero. La huella del
motor no cambia (`igualdad_motor` 4068298361; el banco la compara con y sin inercia en un partido KOR-FRA).

## Capturas (antes | después)

- Espalda de cerca: `espalda2_bra_ita_antes_despues.jpg` (el 23 de siete segmentos se leía «roto»; ahora limpio), `espalda2_arg_esp_antes_despues.jpg`
  (14 amarillo y 9 blanco con ribete oscuro sobre las rayas azulgranas, con el apellido encima), `espalda2_mex_eng_antes_despues.jpg`.
- Cámara de TV: `tv_arg_esp_antes_despues.jpg`, `tv_bra_ita_antes_despues.jpg`, `tv_mex_eng_antes_despues.jpg` (los dorsales se leen
  a la distancia de la TV cercana sin dientes de sierra); `tv2_*` otro momento.
- Carrera y giro de lado: `lado3_*`, `lado4_*`, `espalda1_*` (la postura con la inercia y la zancada con su ciclo).
- Las capturas «antes» se hicieron desde una copia del árbol en d97e0502 (sin estos cambios).
- Nota: con el pelo largo o la cabeza inclinada el apellido (4 cm de alto, entre el número y el cuello) puede quedar tapado.

## Mixamo: la herramienta y los clips que tiene que bajar el dueño

Mixamo pide cuenta de Adobe (no se puede desde la nube). Herramienta lista: `dinastia-godot/herramientas/mixamo_a_res.gd`
(lee los FBX en tiempo de ejecución, sin importarlos; pasa los huesos `mixamorig:*` a los del cuerpo Quaternius; hornea a 30 fps con
`RetargetFutbolQ`; la pelvis conserva la altura y pierde el avance). Los FBX NO van al repo:

```
godot --headless --path . --script res://herramientas/mixamo_a_res.gd -- /carpeta/con/los/fbx
→ res://assets/characters/quaternius/anims_mixamo/mixamo.res  (clave de cada clip = nombre del archivo en minúsculas)
```

Ajustes de descarga en Mixamo (personaje «Y Bot»): **FBX Binary**, **Without Skin**, **30 fps**, **Keyframe Reduction: none**;
**In Place** marcado en los ciclos (si Mixamo lo ofrece). Guardar cada uno con el nombre de archivo de la tabla.

| Archivo | Buscar en Mixamo | Para qué |
|---|---|---|
| `mx_trotar.fbx` | «Jogging» (In Place) | ciclo de trote 3-4 m/s |
| `mx_correr.fbx` | «Running» (In Place) | ciclo de carrera 6-7 m/s |
| `mx_esprint.fbx` | «Fast Run» (In Place) | esprint 8-9 m/s |
| `mx_trotar_atras.fbx` | «Jog Backward» / «Running Backward» (In Place) | repliegue de espaldas |
| `mx_lateral_izq.fbx`, `mx_lateral_der.fbx` | «Left Strafe» / «Right Strafe» (jog) | desplazamiento lateral, marcaje |
| `mx_arrancar.fbx` | «Run Start» / «Standing Run Forward» | primer paso desde parado |
| `mx_frenar.fbx` | «Run To Stop» | frenada desde carrera |
| `mx_giro_180.fbx` | «Running Turn 180» | media vuelta corriendo |
| `mx_cambio_dir_izq.fbx`, `mx_cambio_dir_der.fbx` | «Change Direction» (y su espejo) / «Running Left Turn», «Running Right Turn» | quiebro a 45-90° |
| `mx_giro_parado_izq.fbx`, `mx_giro_parado_der.fbx` | «Left Turn 90», «Right Turn 90» | girar parado hacia el balón |
| `mx_control_pie.fbx` | «Soccer Trap» | control con el interior del pie |
| `mx_control_pecho.fbx` | «Chest Trap» (si no aparece: «Soccer Trap» de pecho) | control de pecho |
| `mx_control_orientado.fbx` | «Soccer Trap» + giro / «Receive Pass And Turn» | control orientado (recibir y girar) |
| `mx_conducir.fbx` | «Soccer Dribble» / «Dribble» (In Place) | conducción |
| `mx_reposo.fbx` | «Soccer Idle» / «Breathing Idle» | parado en juego |

Si un nombre no aparece tal cual en Mixamo, vale el más parecido (la clave sale del nombre del archivo, no del de Mixamo).
Licencia: el dueño la aprobó el 16-11 («Mixamo convertido a `.res` sin los FBX en el repo»); al subir los clips, anotarlos en
`dinastia-godot/LICENCIAS.md` con la plantilla del cap. 11.

## 2.ª pasada (17-11): trote de captura real (CMU) y apellido más grande

### Por qué no Mixamo (todavía)

El dueño quería animaciones de Mixamo y que las bajara Claude. No se puede desde la nube: Mixamo exige iniciar sesión con una
cuenta de Adobe en un navegador (no hay API ni descarga directa), y sus términos permiten usar los clips dentro de un juego pero
NO redistribuir los archivos sueltos (por eso los FBX nunca irían al repo). La herramienta `mixamo_a_res.gd` sigue lista para cuando
el dueño los baje en su equipo (tabla de arriba). Mientras, se usa lo que ya teníamos y es libre del todo: la base de captura de
movimiento de **Carnegie Mellon (CMU)**, libre también para uso comercial citando la fuente (ya en los créditos y en `LICENCIAS.md`;
mismo archivo `anims_cmu/cmu_uso.res`, ningún recurso nuevo).

### A) El trote de cada uno (`visor/trote_cmu.gd`, `TroteCmu`) — HECHO, APAGADO POR DEFECTO (`TROTE_CMU=1`)

El dueño dejó el realismo de los jugadores para después (orden recibida a mitad del bloque): queda listo y probado en el banco, pero
apagado. Encenderlo es cambiar el valor por defecto de `TroteCmu.encendida` (o `TROTE_CMU=1`).

- Los **12 ciclos de carrera reales** de CMU (+ sus espejos = 24) como «trotar» del partido, **repartidos por jugador** con su id
  (siempre el mismo para cada uno; 1 de cada 6 conserva el trote de siempre; los porteros, sus desplazamientos). En un partido del
  banco: 17 jugadores con 10 trotes distintos, y trotan con el suyo.
- **Sin tocar el motor**: la decisión de qué ciclo y a qué escala (que en `main` hace C++, `animar_jugadores`) no cambia: el motor pide
  «trotar» y pone su escala de siempre (velocidad / 3,4 m/s). La variedad entra al montar al jugador: una señal de su AnimationPlayer
  (`current_animation_changed`) cambia «trotar» por su variante en el mismo fotograma. Una primera versión con umbrales propios por
  clip en `CicloCarrera` y `motor_jugable_p3/p5` se deshizo para no chocar con el paso a C++.
- **Sin patinar**: la velocidad del pie de apoyo de cada clip se midió con `AnimPasos.medir` en el cuerpo de 1,80 m (3,11-4,33 m/s) y
  cada clip se **re-cronometra en el propio recurso** a 3,4 m/s (la del trote de siempre): con la misma escala que pone el motor, el
  pie no patina (banco: los 24 a 3,4 m/s ±0,00; el barrido de 2 a 10 m/s de `CicloCarrera` sigue en 0,00).
- **Pies en el césped**: la retarget de CMU dejaba los pies flotando **5-21 cm** (el sujeto de la captura es más alto); la pelvis baja
  lo justo (en el espacio del hueso raíz) y el pie apoya a 0,000 m (banco). La biblioteca guarda las pistas comprimidas: el clip se
  rehace una vez por biblioteca (23 pistas de ~20 claves).
- **Paso en fase**: la fase del pie izquierdo de cada clip va a `AnimPasos.fases`.
- **Coste**: se monta solo donde ya se monta lo cercano (`AnimacionCercana`: de MEDIA hacia arriba y sin «Partido ligero»; en el móvil
  por defecto no existe). Por fotograma, nada (el mismo `play`). Al montar: ~15 clips copiados una vez.
- **Motor intacto**: `igualdad_motor` sigue en **4068298361** y el banco compara la huella de un partido KOR-FRA con y sin.
- Patadas y controles de CMU para tiro y control: **no** se enchufan. Las 6 patadas son grabaciones de 3-7 s desde PARADO (entran a
  0,01-0,84 m/s) con dos golpeos cada una, y CMU no tiene controles de balón; nuestros tiros y pases salen casi siempre en carrera
  (los de League, contacto a 0,17-0,27 s). Encajarían solo en el balón parado (falta, penal): queda en «Pendiente».

### B) Apellido de la espalda más grande (`equipacion_q.gdshader`, `dorsal_q.gdshaderinc`)

| | Antes | Ahora |
|---|---|---|
| Apellido | 4 cm de alto, 1,422-1,462 m, 27 cm de ancho como mucho | **6,5 cm**, **1,375-1,440 m** (2,2 cm más abajo, lejos del pelo y de la cabeza inclinada), 30 cm |
| Ribete del apellido | ninguno (sobre una camiseta del mismo tono se perdía) | el del número cuando el color no contrasta (una celda alrededor de cada letra, `dq_nombre`) |
| Número | 27 cm, base 1,13 m | **25 cm**, base 1,115 m (sigue sobre el patrocinador de la espalda, 1,035-1,10 m) |

Coste: solo ALU en los píxeles de la espalda (4 consultas más a la fuente donde hay ribete); ninguna textura, material ni llamada de
dibujo nueva (tabla de llamadas abajo). Banco: `_dq_espalda_medidas` lee las medidas del shader y comprueba alto, tope y que nada se pise.

### Capturas de la 2.ª pasada

`capturas_cmu_apellido_2026-11-17/` (Forward+ sin GPU, ALTA, cámara real de TV y de cerca; tres cruces nuevos de países distintos:
GER-URU y NED-CHI en ALTA, GER-URU también en MÍNIMA). «Antes»: copia del árbol en 9231fd63. El trote CMU queda apagado: las fotos
muestran el apellido y el dorsal (de espalda y en la TV) y que la carrera de lado no cambia.

Pares (≤ 1280 px, en el repo solo los `*_antes_despues.jpg`; las sueltas, fuera):
- De espalda: `espalda1_ger_uru_antes_despues.jpg` (MEYER 4: el apellido se lee de lejos), `espalda2_ger_uru_…`, `espalda1_ned_chi_…`,
  `espalda2_ned_chi_…` (MIERDING 21), `espalda1_minima_ger_uru_…` (MÍNIMA: el apellido, a menos de un píxel por celda, se funde en
  una franja de tono medio, como antes, sin chisporroteo).
- Cámara de TV: `tv_ger_uru_…`, `tv_ned_chi_…`, `tv_minima_ger_uru_…`. De lado (carrera, sin cambios con el trote apagado): `lado3_ger_uru_…`.
- POR-JPN y FRA-COL: la foto «después» no salió (el proceso de captura murió por memoria en este contenedor sin GPU con 15 GB
  compartidos; POR-JPN dibuja 2,2 M de triángulos) y se cambió por NED-CHI. Tercer cruce: pendiente.

Llamadas de dibujo y triángulos (vista de TV, fotograma 90, mismo motor):

| Cruce | Calidad | Llamadas antes → después | Triángulos antes → después |
|---|---|---|---|
| GER-URU (Wupper FC - Belvedere FC) | ALTA | 677 → 672 | 1.537.610 → 1.536.820 |
| NED-CHI (Kaasstad FC - Levantino SC) | ALTA | 499 → 494 | 1.507.547 → 1.511.757 |
| GER-URU | MÍNIMA | 157 → 152 | 185.778 → 202.883 |

Ningún material, textura ni llamada nueva: las diferencias son del instante (el público y la animación lejana dependen del reloj
real de la captura, y en MÍNIMA la foto «antes» y «después» no cayeron en el mismo momento de juego).

## Pendiente

- Patadas de CMU recortadas (desde `cuadro_toque_balon` de `datos/anims_accion_cmu.json`, ~0,5 s antes y 0,6 s después) solo para el
  balón parado (falta y penal, que arrancan desde parado), con la duración del clip que pide el motor (`LeagueAcciones._neutra`).
- Ciclos de carrera rápida (6-9 m/s): CMU no tiene; con Mixamo («Running», «Fast Run») o la base libre que aparezca.
- Probar `mixamo_a_res.gd` con FBX reales de Mixamo (probado solo con un FBX del pack de Quaternius) y enchufar los clips al
  partido (`CicloCarrera.CICLO` con las velocidades medidas de cada clip con `AnimPasos`).
- Veredicto del dueño en su laptop (FPS reales) y en el teléfono.

Nota (17-11: en el repo solo quedan los pares `*_antes_despues.jpg` reducidos a 1280 px; las capturas sueltas originales siguen en el historial de git, commit d97e0502/9231fd63)
