# Partido: lo que se ve y se siente (sesión 14, 12-11-2026)

Encargo del dueño: «quiero que el juego mejore muchísimo». Esta sesión lleva el CUERPO, las animaciones, la cámara, las
reacciones y el aspecto del partido (la sesión 13 lleva las decisiones de la IA: `motor_jugable_p7.gd` y `mejoras_c4.gd` no se tocan).
Capturas en `capturas_partido_visual_2026-11-12/` (Forward+, JPG). Escena nueva de primeros planos:
`pruebas/captura_futbolistas_cerca.tscn` (mismo camino de creación que el partido, 6 jugadores de 3 países:
`PAISES=ENG,ARG,JPN SUFIJO=x herramientas/captura.sh …`; `OCULTAR=a,b` esconde mallas por nombre y `LISTAR=1` las enumera).

## Bloque 1: realismo de los futbolistas de cerca

Lo que se vio de cerca con el código de `main` (hoja `cara_cuello_y_pelo_ENG_ARG_JPN.jpg` y `botas_y_cuerpo_ENG_ARG_JPN.jpg`):
1. **Botas con DEDOS**: el cuerpo Quaternius es un pie desnudo y el botín solo se pintaba encima: se veían los cinco dedos en negro.
2. **Costura cara-cuello**: el borde de la cara de la biblioteca solo se pegaba a la cabeza en z; en sienes, mejillas y junto a las
   orejas (donde la piel mira de lado) no encontraba la piel y quedaba a 4-16 mm en el aire (medido: 95-103 de 108 vértices del
   borde a más de 4 mm). De perfil: escalones en la mejilla; de espaldas: un arco fino junto a cada oreja.
3. **Pelo**: la nuca nacía a la altura del mentón (y = 1,575 m) y bajaba hasta el cuello de la camiseta («mullet» de espaldas);
   el corte 3D salía al azar entre los 44 de la biblioteca, sin relación con el corte del retrato 2D.

Hecho:
- `visor/botas_q.gd` (`BotasQ`, nuevo): la horma de la bota, una vez por malla en `VestidorQ._con_reposo` (la copia compartida):
  empeine llevado a la superelipse de cada corte (solo hacia fuera) y puntera ANALÍTICA desde z = 3,5 cm (todas las posiciones
  sobre una superficie lisa que se estrecha y baja hacia el dedo gordo, con su normal exacta). En el shader, la bota ya no deja ver
  el relieve de los dedos del mapa de normales. `BOTAS_DESNUDAS=1` mide el antes.
- `CaraMalla._pegar_borde` en 3D: cada vértice del borde va al plano tangente de la piel más cercana (+1,5 mm), del cráneo y la cara
  (no de la oreja). El borde que no tiene piel cerca (mentón más ancho que la cabeza) se funde del todo; además, el borde que mira de
  canto o de espaldas a la cámara se desvanece. `CARA_BORDE_Z=1` vuelve al método de antes. Vale también para peatones y personal.
- Pelo por capas: la nuca nace a la altura del lóbulo (1,612 m; la melena rizada sigue igual).
- `BibliotecaCaras.para(…, corte)`: el corte 3D sale de la familia del corte del retrato (`FAMILIA_CORTE`: un «rapado» no sale con
  melena, un «corto» no lleva nuca larga). Futbolistas y peatones.
- Banco: «FUTBOLISTAS DE CERCA: HORMA DE LA BOTA, BORDE DE LA CARA, CORTE DEL RETRATO» (`_probar_futbolista_visual`, grupo estadio).

Rendimiento (MÍNIMA, `hw_modesto.sh res://pruebas/medir_partido.tscn -- minimo`, `HW_DRIVER=opengl3 HW_RES=1280x720`, 2 núcleos,
cámara de TV; NO es tiempo de fotograma de `--headless`):

| club | llamadas antes → después | triángulos | vram | pico de RAM del proceso |
|---|---|---|---|---|
| ENG 2 | 151 → 151 / 153 | 176 k → 174-180 k | 183 → 182 MB | 1 950 → 2 495 / 1 831 MB (ruido entre corridas: ±300 MB) |
| ARG 4 | 197 → 200 | 299 k → 300 k | 140 → 140 MB | 1 903 → 2 012 MB |

Lectura: lo cambiado es geometría de una malla compartida (los mismos vértices) y unas cuantas operaciones de shader: 0 mallas, 0
materiales y 0 llamadas nuevas; las diferencias de llamadas y triángulos son del momento del partido en que se mide.

Pendiente de este bloque: proporciones del cuerpo «superhéroe» (hombros anchos y brazos largos: se ve de cerca), la cara de la
biblioteca algo plana y clara frente al cuello en luz de estadio, el «rapado» que de perfil parece calvo arriba.

## Bloque 2: animaciones de acción (capa `LeagueAcciones`, en C4 y en League; el motor de siempre no se toca)

Hallazgo: los clips de cabezazo SÍ saltan (la cadera sube 0,3-0,4 m hacia los 0,3 s), pero el motor los arranca en el CONTACTO:
la cabeza llegaba arriba 0,3 s después de que el balón se fuera. Hoja `disputa_aerea_contacto_antes_despues.jpg` (de cerca y a la
distancia de la cámara de TV, en el instante del contacto).

Hecho (`visor/league_acciones.gd`, enganchado en `MotorLeague._anim` y al final de `MotorLeague._mover_jugadores`):
- **Disputa aérea**: cuando un balón alto baja hacia 2,05 m y llegará en ~0,3 s, el jugador de cada equipo más cercano al punto de
  caída (1,4 m, sin porteros) arranca ya su clip de cabezazo: los dos saltan y el que remata lo hace con la cabeza arriba. Cuando el
  motor pide el cabezazo de verdad, sigue el salto que ya va. `LS_AEREO=0` lo apaga.
- **Reacción al fallo**: tras un remate fuera o al palo (señal `remate`), el que tiró se lleva las manos a la cabeza, se lamenta o se
  encoge de hombros (CMU 111_25, solo si la biblioteca de CMU ya está cargada: sin tirones), si no está corriendo; si arranca, se corta.
  `LS_REACCION=0` la apaga.
- **Entrada de pie**: la estocada de siempre, la lateral y la anticipación, por jugador.
- **Celebraciones**: además de bailes y alegrías (2 de cada 5), 1 de cada 5 una acrobacia de CMU: rueda lateral (90_04), voltereta
  (90_01) o mortal (85_01). **Lamento** del que encaja: 1 de cada 3, llanto (79_72) o tristeza (79_71) de CMU.
  Hoja `celebraciones_reacciones_entradas_nuevas.jpg`.
- Mecanismo común de «clip propio» (salto, reacción): un ciclo del motor no lo pisa, la locomoción de League tampoco
  (`LeagueLocomocion._paso` lo salta) y al acabar vuelve el ciclo que el motor tenía.

**Que no cambie el partido** (regla: esta sesión no toca las decisiones). Primer intento: con la variedad de entradas el partido de
C4 CAMBIABA (3-5 → 2-4): el motor lee cuánto dura el gesto (`gesto_hasta`: quién puede moverse, entrar o levantarse), y otro clip de
otra duración cambiaba la simulación. Arreglado por causa: las variantes nuevas dejan anotado el clip que pidió el motor y
`LeagueAcciones.igualar` escribe la duración de ese; el salto no escribe nada que lea la IA (en el cabezazo, lo mismo que habría escrito
el motor). Comprobado con `comparar_tres_motores` (C4, 2 × 240 s): 6 cruces (ENG/ARG/JPN y ESP/BRA/GER) con marcador y todas las
cifras IDÉNTICOS a `main`. Por partido: 12-20 saltos a disputar, 1-6 cabezazos con el saltador ya en el aire, 7-16 reacciones a un fallo.
Las variantes que ya existían (celebración de CMU y golpe en el duelo, 11-11) siguen como estaban.

Rendimiento: 0 mallas, 0 materiales, 0 llamadas de dibujo; por paso, un recorrido de los 22 jugadores (sin búsqueda de bolas si el
balón no baja hacia 2 m). Los clips de CMU solo se cargan donde ya se cargaban (la primera celebración).
Banco: «ACCIONES DEL PARTIDO: DISPUTA AÉREA A TIEMPO Y VARIANTES NEUTRAS» (`_probar_acciones_visuales`); la prueba de las
celebraciones de CMU (`varios_p11`) pasa a 3 de cada 5. Escena para ver clips congelados: `pruebas/captura_acciones.tscn`
(`CLIPS=… TIEMPOS=… DESFASE=… BALON=… LEJOS=1 GIRO=`).

Pendiente de este bloque: reacción del infractor a una falta sin tarjeta (hoy solo protesta el amonestado), saltos de disputa en los
córners con más de dos jugadores, y verlo en vídeo con la cámara real (la foto fija no muestra el tiempo).
