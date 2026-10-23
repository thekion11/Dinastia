extends RefCounted
## (Parte 1 de 3 de `anim_quaternius.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `anim_quaternius.gd`, conserva la clase.)

## Fabrica de animaciones para el esqueleto Quaternius (`FutbolistaQ`), el
## segundo modelo de jugador. Mismo principio que `AnimMixamo` -las claves son
## DESVIOS sobre la pose de reposo del propio hueso, no rotaciones absolutas-
## pero un esqueleto distinto de verdad (estilo Unreal Engine, no
## `mixamorig_*`) necesita sus propios ejes: se midieron por separado,
## renderizando una sonda hueso por hueso (`pruebas/sonda_ejes_q.gd`), no
## copiados del otro archivo. Ejes confirmados asi, para las dos piernas y
## los dos brazos SIN invertir signo entre izquierda y derecha (la mirada del
## rig es simetrica en X, solo Y/Z cambian de signo entre lados):
##   muslo/rodilla/tobillo -> eje X, positivo = adelante / se dobla / puntera arriba
##   brazo (adelante-atras) -> eje X, positivo = adelante
##   brazo (sube-baja)      -> eje Z, positivo = sube
##
## POR AHORA: solo "parado" y "correr" -las dos que mas se ven en un partido-.
## El resto del catalogo de AnimMixamo (patear, celebrar, faltas...) es
## trabajo aparte, no de esta ronda.

const HUESOS := {
	"cadera": "pelvis",
	"espalda1": "spine_01",
	"espalda2": "spine_02",
	"espalda3": "spine_03",
	"cuello": "neck_01",
	"cabeza": "Head",
	"brazo_i": "upperarm_l",
	"antebrazo_i": "lowerarm_l",
	"mano_i": "hand_l",
	"brazo_d": "upperarm_r",
	"antebrazo_d": "lowerarm_r",
	"mano_d": "hand_r",
	"muslo_i": "thigh_l",
	"pierna_i": "calf_l",
	"pie_i": "foot_l",
	"muslo_d": "thigh_r",
	"pierna_d": "calf_r",
	"pie_d": "foot_r",
}

## LOS BRAZOS EN REPOSO ESTAN EN T -igual que en el otro modelo-: el desvio
## en Z que hace falta para que caigan a los costados, medido con la sonda
## (`sonda_brazo_z40.png`: +40 SUBE el brazo izquierdo desde el reposo
## horizontal, asi que para bajarlo hace falta el signo contrario y bastante
## mas angulo). CONFIRMADO CON CAPTURA REAL (18-9-2026, primer intento de
## "parado"): el mismo signo en el brazo derecho lo mandaba PARA ARRIBA en
## vez de para abajo -el eje Z SI esta espejado entre los dos brazos, a
## diferencia del eje X de piernas/brazo-adelante-atras, que no lo esta-. Por
## eso brazo_d usa el signo contrario, no el mismo.
const BRAZO_ABAJO_Z := -82.0

## MOVIMIENTO CAPTURADO DE VERDAD, NO A MANO (18-9-2026). El usuario probo una
## captura de `celebrar` y con toda razon la vio "de muniaco" -rigida, sin el
## peso ni el timing de un movimiento humano real, porque yo estaba
## adivinando angulos-. Encontramos la "Universal Animation Library" de
## Quaternius (CC0, gratis, mismo esqueleto de 65 huesos que este modelo, sin
## necesitar retargeting) y la version SIN root motion se copio a
## `res://assets/characters/quaternius/anims/UAL1_Standard.glb`. Esta funcion
## saca un clip de ahi y le reapunta cada pista a NUESTRO esqueleto -las
## pistas del glb original apuntan a "Armature/Skeleton3D:hueso" relativas a
## SU PROPIO AnimationPlayer, hay que cambiar el path pero conservar el
## nombre del hueso, que es identico en los dos modelos-.
const RUTA_UAL := "res://assets/characters/quaternius/anims/UAL1_Standard.glb"
static var _packed_ual: PackedScene
static var _lib_ual: AnimationLibrary

## MOCAP DE FUTBOL DE VERDAD (19-9-2026). El usuario consiguio -gratis, uso
## comercial libre, sin atribucion- el pack "Free mocap pack 05: Soccer" de
## Anderson Rohr (Gumroad): 21 clips reales (patadas, penales, festejos,
## atajadas, tarjetas), exportados en 3 esqueletos. Se uso la version "UE5"
## (Manny) porque su nomenclatura de huesos es casi identica a la nuestra
## -confirmado con `pruebas/diagnostico_mocap_ue5.gd`, no supuesto-: mismos
## `pelvis`/`spine_01..03`/`clavicle_l`/`upperarm_l`/`thigh_l`/`calf_l`/
## `foot_l`/`ball_l`... La UNICA diferencia real es que ellos usan "head" en
## minuscula y este esqueleto "Head" con mayuscula -de ahi `MAPA_HUESO_FUTBOL`-.
## Su esqueleto trae ademas huesos que el nuestro no tiene (spine_04/05,
## neck_02, huesos de torsion "_twist_", metacarpianos): esas pistas se
## descartan en vez de dejarlas apuntando a un hueso que no existe -Godot no
## truena por una NodePath de hueso invalida, pero es basura muerta en el
## recurso, mejor no guardarla-.
const CARPETA_FUTBOL := "res://assets/characters/quaternius/anims_futbol/"
const MAPA_HUESO_FUTBOL := {"head": "Head"}
static var _cache_futbol := {}

## RETARGET GLOBAL (20/21-9-2026). `cargar_futbol()` (arriba) retargetea pista
## por pista, en espacio LOCAL de cada hueso -mismo espacio que usa `_pista()`
## para las animaciones a mano-. Verificado con captura real superpuesta al
## esqueleto de origen (`pruebas/diagnostico_retarget_global.gd`, imagen
## `retarget_global_power_kick_lado.png` contra `mocap_origen_power_kick_
## lado.png`): el metodo local produce una postura "plausible" -de pie, sin
## romperse- pero que NO reproduce el gesto real -el origen se inclina
## adelante en la patada de potencia, el retarget local salia inclinado
## ATRAS-. El metodo GLOBAL (`RetargetFutbolQ`, en `visor/retarget_futbol_q.gd`)
## SI calza con el origen: mide la pose de cada hueso en espacio global
## RELATIVO A LA RAIZ ANIMADA (no relativo a su propio reposo local), y por
## eso no lo engaña la correccion de importacion de -90° que trae el hueso
## `root` del FBX -se cancela sola al dividir por la pose animada de la
## propia raiz en vez de intentar adivinar su reposo "correcto"-.
##
## `RetargetFutbolQ.aplicar()` es en TIEMPO REAL -necesita el AnimationPlayer
## de origen ya posicionado en el fotograma que se quiere y escribe la pose
## directo en un Skeleton3D vivo-, no sirve para guardar en una
## `AnimationLibrary` tal cual. Esta funcion lo "hornea": arma una escena
## descartable (el fbx de origen + un `FutbolistaQ` molde, los dos
## temporalmente colgados de la raiz del arbol para que el posado funcione),
## recorre el clip a 30 muestras por segundo aplicando el retarget en cada
## paso, y graba la pose LOCAL resultante de cada hueso del molde como
## claves de un `Animation` nuevo -con rutas SIN prefijo (":hueso") para que
## `cargar_futbol_global()` pueda reapuntarlas a cualquier instancia despues,
## mismo patron de cache-una-vez-y-reapuntar que ya usan `cargar_real()` y
## `cargar_futbol()`-.
const PASO_HORNEADO := 1.0 / 30.0
static var _cache_futbol_global := {}

## TOPE ANATÓMICO DE LA RODILLA (25-9-2026). Una rodilla humana deja de
## doblar hacia los 155-160°: el gemelo choca con el muslo. El actor del mocap
## llega ahí al arrodillarse, pero nuestro modelo tiene otras proporciones y
## el retarget lo empujaba a 176° (`celebrar_rodillas`, medido por
## `pruebas/auditoria_biomecanica.gd`), una pierna plegada como una navaja. Se
## limita el giro TOTAL de la pierna respecto a su reposo (limitar solo la
## componente de bisagra no bastaba: el retarget le suma giro fuera del eje y
## seguía midiendo 169°), conservando su dirección. El pie queda un par de
## centímetros más lejos del glúteo; nada más cambia.
const RODILLA_MAX := 150.0

## PIERNAS CON ANATOMÍA DE VERDAD (25-9-2026). La auditoría biomecánica
## (`pruebas/auditoria_biomecanica.gd`) encontró que TODAS las poses de piernas
## hechas a mano -sentado, lamento, rabia, dolor, barrida, cabezazo- tenían los
## signos al revés: el muslo iba hacia ATRÁS y la rodilla doblaba hacia
## DELANTE, el espejo exacto de una pierna humana. Desde la cámara de TV casi no
## se notaba (en el banquillo, los muslos quedaban escondidos bajo el banco),
## pero ninguna rodilla del mundo dobla así. Medido con sonda en este esqueleto
## (+45° aislados en cada hueso):
##   muslo  +X -> el muslo va hacia atrás   => flexión de cadera = -X
##   pierna +X -> el talón va al glúteo     => flexión de rodilla = +X
##   pie    +X -> la punta baja             => flexión plantar   = +X
## La rodilla de reposo ya trae 6,4° doblados.
## Estos dos helpers hablan en ANATOMÍA (grados de flexión, + = doblar como un
## humano) y traducen a los ejes del hueso; así ya no hay signos que recordar.
const RODILLA_REPOSO := 6.4

## Mapa animacion-nuestra -> clip real de la Universal Animation Library,
## para las que SI tienen equivalente real.
const CLIP_REAL := {
	"parado": "Idle",
	## 13-10-2026: el paso «formal» (brazos cerca del cuerpo, erguido) en vez
	## del paso de superhéroe.
	"caminar": "Walk_Formal",
	"trotar": "Jog_Fwd",
	"correr": "Sprint",
}

## Pasos extra para elegir «mi caminata» (ver `ExploradorCiudad.ESTILOS_CAMINATA`).
const CLIP_CAMINATA := {
	"caminar_normal": "Walk",
	"caminar_agachado": "Crouch_Fwd",
	"caminar_trote": "Jog_Fwd",
}

## Mapa animacion-nuestra -> clip del mocap de futbol real (Anderson Rohr,
## ver `cargar_futbol()`). `cabezazo` se queda a mano: el pack gratis no trae
## cabezazo, solo pateo/penal/festejo/atajada/tarjeta/regate/entrada.
const CLIP_FUTBOL := {
	"patear": "09_Power_Kick_ue5",
	"celebrar": "13_Goal_Celebration_02_ue5",
}

## Animaciones NUEVAS que no existian antes -sin version a mano de respaldo,
## si el archivo no carga simplemente no se agregan a la libreria-.
const CLIP_FUTBOL_NUEVO := {
	"mostrar_tarjeta": "20_Yellow_Card_ue5",
	"atajar": "15_Goalkeeper_Save_01_ue5",
	"penal": "10_Penalty_Kick_01_ue5",
}

## LOS MOVIMIENTOS QUE FALTABAN (25-9-2026). `match_playback.gd` pedía
## animaciones que no existían -`atajar_der`/`atajar_izq`, `portero_listo`,
## `celebrar_rodillas`, `lamento`, `rabia`, `falta_barrida`, `falta_empujon`,
## `senalar_falta`- y `_animar()` las descartaba en silencio: el portero no se
## tiraba nunca, nadie se lamentaba de un gol, las faltas no tenían gesto. Y de
## los 21 clips del mocap de fútbol solo se usaban cinco.
##
## Ojo con los clips largos: la atajada real está al 70-80% de un clip de 4 a 9
## segundos (antes hay segundos de guardia), y el partido la reproducía 1,15 s
## desde el principio, así que el portero NUNCA se veía tirarse. Cada clip se
## RECORTA a su momento: [archivo, desde, hasta (fracción), bucle, sin
## desplazamiento]. "Sin desplazamiento" quita el avance horizontal de la
## pelvis que trae el mocap (quien lo mueve por el campo es el partido, no la
## animación); las estiradas del portero lo conservan, porque tirarse ES
## desplazarse. Ventanas medidas con `pruebas/diagnostico_clips_restantes.gd`.
static var _cache_recortes := {}

const CLIP_RECORTES := {
	"atajar_izq": ["15_Goalkeeper_Save_01_ue5", 0.62, 0.92, false, false],
	"atajar_der": ["16_Goalkeeper_Save_02_ue5", 0.66, 1.0, false, false],
	"atajar_bajo": ["17_Goalkeeper_Save_03_ue5", 0.68, 0.92, false, false],
	"portero_listo": ["17_Goalkeeper_Save_03_ue5", 0.2, 0.5, true, true],
	"celebrar_rodillas": ["12_Goal_Celebration_01_ue5", 0.0, 1.0, false, true],
	"celebrar_carrera": ["14_Goal_Celebration_03_ue5", 0.0, 1.0, false, true],
	"saque_banda": ["07_Throw_In_ue5", 0.42, 0.9, false, true],
	"pase": ["08_Side_Foot_Kick_ue5", 0.2, 0.55, false, true],
	"marcar": ["18_Defending_01_ue5", 0.1, 0.7, true, true],
	"falta_empujon": ["19_Defending_02_ue5", 0.3, 0.6, false, true],
	"mostrar_roja": ["21_Yellow_And_Red_Card_ue5", 0.3, 0.75, false, true],
	"penal_2": ["11_Penalty_Kick_02_ue5", 0.0, 0.45, false, true],
	## LOS REGATES Y LAS DOMINADAS (25-9-2026). Seis clips del mismo pack de
	## mocap de fútbol llevaban meses importados y sin usar. Van sin
	## desplazamiento propio (el actor recorre metros; aquí el que mueve al
	## jugador es el partido):
	##  - `regate_finta`: el amague con salida lateral (Dribble_01).
	##  - `regate_pausa`: pisar y proteger el balón, parado (Dribble_02).
	##  - `conducir`: llevar el balón pegado al pie avanzando, en bucle
	##    (Dribble_03, desde que arranca a avanzar).
	##  - `dominadas_1..3`: el calentamiento con el balón en el aire.
	"regate_finta": ["01_Dribble_01_ue5", 0.04, 0.42, false, true],
	"regate_pausa": ["02_Dribble_02_ue5", 0.12, 0.42, false, true],
	"conducir": ["03_Dribble_03_ue5", 0.38, 0.98, true, true],
	"dominadas_1": ["04_Juggling_01_ue5", 0.02, 0.98, true, true],
	"dominadas_2": ["05_Juggling_02_ue5", 0.02, 0.98, true, true],
	"dominadas_3": ["06_Juggling_03_ue5", 0.02, 0.98, true, true],
}

## Las acciones de futbol de este rig se mantuvieron opt-in mientras se
## terminaba su retarget. Las capturas de 20-9-2026 probaron que tanto la
## version a mano como el primer rebase del FBX UE5 (`cargar_futbol()`, en
## espacio LOCAL) deforman la silueta; no se debian colar en un partido solo
## porque el recurso existiera. Corregido el 21-9-2026 con el retarget
## GLOBAL (`cargar_futbol_global()`, ver el comentario largo mas arriba):
## verificado con captura real contra el esqueleto de origen para las 5
## acciones -patear, celebrar, atajar, mostrar_tarjeta, penal-, las 5 calzan.
## La bandera `acciones_experimentales` se mantiene -sigue siendo una decision
## aparte activarlas en partidos de verdad via `PlayerSpawner`, esto solo dice
## que el contenido ya no esta roto-. La locomocion real de Quaternius (Idle/
## Walk/Jog/Sprint) nunca dependio de esta bandera, se agrega siempre.
## BIBLIOTECAS COMPARTIDAS (etapa 3, 8-10-2026). Medido con TIEMPOS=1: la
## ciudad armaba 105 bibliotecas IDÉNTICAS -una por peatón, hincha o empleado-
## a ~27 ms cada una: 2,9 s de la construcción. Lo que sale de aquí solo
## depende de la ruta al esqueleto, de las acciones de fútbol y de la pose de
## reposo del modelo, así que se arma una vez por combinación y se comparte
## (nadie la modifica después; si alguien lo hiciera, cambiaría a todos).
static var _bibliotecas := {}

## SENTADO (22-9-2026, pedido directo del usuario tras ver el banquillo de
## pie: "que los que no caben estén sentados"). Pose estatica -con la misma
## respiracion sutil que ya usa `parado()`, para que no se lea como una
## estatua entre gente que sí se mueve-, solo eje X en muslo/rodilla/pie -el
## mismo eje ya calibrado con la sonda para correr/patear, sin ejes nuevos
## sin medir-. El truco real no esta en el angulo de las piernas -90 grados
## en la cadera, otros 90 en la rodilla, la geometria de sentarse en
## cualquier silla- sino en que rotar el muslo NO mueve la cadera en el
## espacio: `FutbolistaQ` sigue de pie a la altura de pelvis=1.03m (medido,
## `pruebas/diagnostico_altura_cadera_q.gd`) aunque las piernas ya esten
## dobladas -"flotando sentado en el aire" en vez de apoyado en un banco-.
## Por eso esto SOLO es la mitad de la solucion: quien llame a esto tiene que
## bajar la raiz del modelo (`ALTO_ASIENTO_OFFSET`) para que la cadera caiga a
## la altura real de un asiento, ver `visor/player_spawner.gd::spawn_
## sentados()`.
const ALTO_ASIENTO_OFFSET := -0.47

static func _buscar_ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _buscar_ap(c)
		if r:
			return r
	return null

## Se guarda solo la LIBRERIA (un Resource, con su propio refcount, no un
## Node), no el AnimationPlayer ni el resto de la escena -esa se instancia
## una vez, se le saca la libreria, y se libera al toque con `free()`. La
## primera version dejaba el Node huerfano vivo para siempre (nunca se
## agregaba al arbol, asi que nunca se liberaba solo): funcionaba, pero
## Godot lo marcaba como fuga de mallas/shaders/RIDs al cerrar el proceso.
static func _lib_real() -> AnimationLibrary:
	if _lib_ual != null:
		return _lib_ual
	if _packed_ual == null:
		_packed_ual = load(RUTA_UAL)
	if _packed_ual == null:
		return null
	var nodo: Node3D = _packed_ual.instantiate()
	var ap := _buscar_ap(nodo)
	if ap != null and ap.has_animation_library(""):
		_lib_ual = ap.get_animation_library("")
	nodo.free()
	return _lib_ual

## Copia el clip real `nombre_real` (p.ej. "Idle", "Walk", "Jog_Fwd",
## "Sprint") reapuntando cada pista a `prefijo` (el mismo que usa `_pista()`
## para este esqueleto). Devuelve null si el clip no existe -para que quien
## llama pueda quedarse con la version a mano como respaldo en vez de romper.
static func cargar_real(nombre_real: String, prefijo: String) -> Animation:
	var lib := _lib_real()
	if lib == null:
		return null
	if not lib.has_animation(nombre_real):
		return null
	var original: Animation = lib.get_animation(nombre_real)
	var copia: Animation = original.duplicate(true)
	## Los clips de locomocion (parado/caminar/trotar/correr) se reproducen en
	## bucle en este proyecto; el glb no siempre trae ese modo marcado.
	copia.loop_mode = Animation.LOOP_LINEAR
	for i in copia.get_track_count():
		var ruta := str(copia.track_get_path(i))
		var hueso := ruta.substr(ruta.rfind(":") + 1)
		copia.track_set_path(i, NodePath("%s:%s" % [prefijo, hueso]))
	return copia

static func _buscar_esqueleto(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var r := _buscar_esqueleto(c)
		if r:
			return r
	return null

## `_cache_futbol[archivo]` guarda un Dictionary con "anim" (el Animation tal
## cual vino del fbx) y "reposo" (hueso -> {"rot": Quaternion, "pos": Vector3}
## de SU PROPIO esqueleto, no el nuestro). Hace falta guardar el reposo de
## origen porque el retargeting real necesita los DOS reposos, no solo el
## nuestro -ver el porque en el comentario de `cargar_futbol()`.
static func _cargar_clip_futbol(archivo: String) -> Dictionary:
	if _cache_futbol.has(archivo):
		return _cache_futbol[archivo]
	var salida := {"anim": null, "reposo": {}}
	var packed: PackedScene = load(CARPETA_FUTBOL + archivo + ".fbx")
	if packed != null:
		var nodo: Node3D = packed.instantiate()
		var ap := _buscar_ap(nodo)
		var esq_origen := _buscar_esqueleto(nodo)
		if ap != null and ap.has_animation_library("") and esq_origen != null:
			var lib := ap.get_animation_library("")
			if lib.has_animation("clip"):
				salida["anim"] = lib.get_animation("clip")
				var reposo := {}
				for i in esq_origen.get_bone_count():
					var nombre := esq_origen.get_bone_name(i)
					var t := esq_origen.get_bone_rest(i)
					reposo[nombre] = {"rot": t.basis.get_rotation_quaternion(), "pos": t.origin}
				salida["reposo"] = reposo
		nodo.free()
	_cache_futbol[archivo] = salida
	return salida
