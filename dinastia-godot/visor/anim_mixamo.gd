class_name AnimMixamo
extends RefCounted

## Fabrica de animaciones para el esqueleto Mixamo del futbolista.
##
## POR QUE ESTO EXISTE
## El modelo que trajo el usuario (`futbolista_cr7.glb`) viene con un esqueleto
## Mixamo de 33 huesos perfecto, pero **sin animaciones**: la unica accion que
## trae es de 2 fotogramas, o sea una pose fija. Y bajar animaciones de Mixamo
## exige iniciar sesion con una cuenta de Adobe, cosa que el asistente no puede
## hacer. Asi que los ciclos se generan aqui, por codigo, rotando los huesos por
## su nombre. Es lo mismo que hace cualquier motor al reproducir una animacion,
## solo que las claves se escriben a mano en vez de venir de un fichero.
##
## COMO SE USA
##   var lib := AnimMixamo.construir(skeleton)
##   animation_player.add_animation_library("", lib)
##   animation_player.play("correr")
##
## Las claves NO son rotaciones absolutas: son **desvios sobre la pose de
## reposo** del propio esqueleto. Por eso hace falta el Skeleton3D — la misma
## clave "muslo 30 grados adelante" da un resultado distinto segun como este
## plantado el hueso en reposo, y darlo por hecho es lo que hace que un
## personaje acabe corriendo con las rodillas del reves.

const HUESOS := {
	"cadera": "mixamorig_Hips",
	"espalda": "mixamorig_Spine",
	"espalda1": "mixamorig_Spine1",
	"espalda2": "mixamorig_Spine2",
	"cuello": "mixamorig_Neck",
	"cabeza": "mixamorig_Head",
	"hombro_i": "mixamorig_LeftShoulder",
	"brazo_i": "mixamorig_LeftArm",
	"antebrazo_i": "mixamorig_LeftForeArm",
	"mano_i": "mixamorig_LeftHand",
	"hombro_d": "mixamorig_RightShoulder",
	"brazo_d": "mixamorig_RightArm",
	"antebrazo_d": "mixamorig_RightForeArm",
	"mano_d": "mixamorig_RightHand",
	"muslo_i": "mixamorig_LeftUpLeg",
	"pierna_i": "mixamorig_LeftLeg",
	"pie_i": "mixamorig_LeftFoot",
	"muslo_d": "mixamorig_RightUpLeg",
	"pierna_d": "mixamorig_RightLeg",
	"pie_d": "mixamorig_RightFoot",
}

## Nombre de la animacion -> como de largo dura y si se repite en bucle.
const CICLICAS := ["parado", "correr", "trotar", "caminar", "portero_listo"]

# ---------------------------------------------------------------- utilidades

## Ruta al esqueleto DESDE el nodo raiz del AnimationPlayer. No basta con poner
## "Skeleton3D": en este modelo el esqueleto cuelga de un nodo "Armature", y con
## la ruta corta Godot no resuelve ni una pista — avisa con un
## "couldn't resolve track" por cada hueso y el personaje se queda de piedra sin
## que nada falle de verdad. Lo fija construir() segun donde este el esqueleto.
static var _prefijo := "Skeleton3D"

static func _ruta(esq: Skeleton3D, prefijo: String) -> String:
	if prefijo != "":
		return prefijo
	return _prefijo

## La pose de reposo del modelo es una CRUZ (brazos en horizontal). Como todas
## las claves de este fichero son desvios sobre el reposo, un cero en el brazo
## dejaba al futbolista corriendo con los brazos extendidos como un avion. Se
## añaden estos grados a todas las claves de brazo para que el cero signifique
## "brazos caidos al costado", que es como se leen las animaciones de abajo.
const BRAZO_ABAJO := 72.0

## El reposo de "mixamorig_Spine" viene con x=-13.8 grados (comprobado con
## pruebas/diagnostico_postura.gd imprimiendo los eulers de reposo). Se probo
## DOS VECES compensarlo como si fuera un bug aislado, igual que BRAZO_ABAJO,
## y las dos veces salio mal (ver el historial completo en
## project_dinastia_jugadas.md, seccion "espalda"). La segunda vez incluso se
## midio bien -con pruebas/diagnostico_espalda_sola.gd, aislando SOLO el hueso
## y barriendo angulos- y el numero medido (+18.4) SI dejaba la cabeza
## perfectamente alineada en Z con la cadera... pero la imagen renderizada
## seguia viendose mal, con el pecho arqueado hacia atras y la cabeza tirada
## para atras.
##
## La razon: **"mixamorig_Neck" tiene reposo x=+13.8, el espejo exacto de
## Spine**. No es casualidad — es un par disenado a proposito: la espalda se
## inclina -13.8 y el cuello se inclina +13.8 para compensarla, dejando la
## cabeza nivelada EN EL REPOSO ORIGINAL sin que nadie tuviera que tocar nada.
## "parado" no trae ninguna pista de cuello, asi que el cuello se queda
## siempre en su reposo (+13.8). Si se cambia la espalda sola -a cualquier
## angulo que no sea el que ya trae de fabrica-, se rompe ese balance con el
## cuello y el resultado es peor que el original, aunque una metrica simple
## (cabeza vs cadera en Z) pueda dar "cero" por una curva distinta.
##
## CONCLUSION: el reposo de Spine/Neck NO es un bug, es un par compensado a
## proposito. Si de verdad hay un "hunch" visible en el juego real, la causa
## esta en OTRO lado (una animacion concreta con su propio valor grande de
## "espalda" sin que el cuello lo acompane -correr(), patear(), etc-, o algo
## fuera de este hueso). No tocar este bone por este camino: si hace falta
## ajustar una animacion puntual, es la pista de esa animacion (sus propios
## keyframes "espalda", y quiza tambien anadir una pista "cuello" a juego) la
## que hay que retocar, no un offset global en _ajustar().
static func _idx(esq: Skeleton3D, clave: String) -> int:
	return esq.find_bone(HUESOS.get(clave, clave))

## Corrige una clave de brazo para que el cero sea "brazo al costado".
static func _ajustar(clave: String, g: Vector3) -> Vector3:
	# el signo se comprobo renderizando: con +/- al reves los brazos suben por
	# encima de la cabeza en vez de caer al costado
	if clave == "brazo_i":
		return Vector3(g.x, g.y, g.z - BRAZO_ABAJO)
	if clave == "brazo_d":
		return Vector3(g.x, g.y, g.z + BRAZO_ABAJO)
	return g

## Anade una pista de rotacion para un hueso. `claves` es una lista de
## [segundo, Vector3(grados x, y, z)] y los grados se aplican SOBRE el reposo.
static func _pista(anim: Animation, esq: Skeleton3D, clave: String, claves: Array, prefijo: String = "") -> void:
	var i := _idx(esq, clave)
	if i < 0:
		return
	var reposo := esq.get_bone_rest(i).basis.get_rotation_quaternion()
	var pista := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(pista, NodePath("%s:%s" % [_ruta(esq, prefijo), esq.get_bone_name(i)]))
	anim.track_set_interpolation_type(pista, Animation.INTERPOLATION_CUBIC)
	for k in claves:
		var t: float = k[0]
		var g: Vector3 = _ajustar(clave, k[1])
		var desvio := Quaternion.from_euler(Vector3(deg_to_rad(g.x), deg_to_rad(g.y), deg_to_rad(g.z)))
		anim.rotation_track_insert_key(pista, t, reposo * desvio)

## Pista de desplazamiento para la cadera (el bote al correr, el salto...).
static func _pista_pos(anim: Animation, esq: Skeleton3D, clave: String, claves: Array, prefijo: String = "") -> void:
	var i := _idx(esq, clave)
	if i < 0:
		return
	var reposo := esq.get_bone_rest(i).origin
	var pista := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(pista, NodePath("%s:%s" % [_ruta(esq, prefijo), esq.get_bone_name(i)]))
	anim.track_set_interpolation_type(pista, Animation.INTERPOLATION_CUBIC)
	for k in claves:
		anim.position_track_insert_key(pista, k[0], reposo + (k[1] as Vector3))

static func _nueva(dur: float, bucle: bool) -> Animation:
	var a := Animation.new()
	a.length = dur
	a.loop_mode = Animation.LOOP_LINEAR if bucle else Animation.LOOP_NONE
	return a

# ------------------------------------------------------------------ el catalogo

## `ruta_esqueleto` es la ruta del Skeleton3D vista desde el nodo raiz del
## AnimationPlayer que vaya a reproducir esto. Lo normal es pasarle
## `str(reproductor.get_path_to(esqueleto))` y olvidarse.
## LA "GARRA" (18-9-2026), reportada por el usuario y confirmada con captura
## real: las manos se ven deformadas TODO el partido, no en un momento
## puntual. Causa encontrada, no supuesta: el modelo SI trae un dedo indice
## articulado (`mixamorig_LeftHandIndex1/2/3`), pero ninguna de las ~25
## animaciones de este fichero lo toca -no esta ni en `HUESOS`-, asi que se
## queda congelado en la pose de fabrica del .glb para siempre. Esa pose de
## fabrica ademas viene ASIMETRICA entre las dos manos (medido con
## `get_bone_rest()`: el indice izquierdo entra doblado 53 grados y se
## endereza recto en las dos falanges siguientes -un doblez raro, ni cerrado
## ni abierto-, el derecho trae una rotacion de fabrica totalmente distinta
## por como esta armado el hueso espejado). Sin animacion propia para esto
## -serian docenas de huesos mas en cada una de las 25 funciones de abajo, un
## trabajo aparte-, la correccion mas barata y real es fijar UNA vez una pose
## relajada de mano (dedo ligeramente curvado, no recto ni en garra) al crear
## el jugador, con `set_bone_pose_rotation()` -no es una animacion, es dejar
## el hueso quieto en una postura mejor en vez de la que trajo el archivo-.
## Como nadie mas toca estos huesos, la pose puesta aqui no se pisa con nada.
static func aplicar_pose_relajada(esq: Skeleton3D) -> void:
	## Mismo criterio de curva que una mano relajada de verdad: la base del
	## dedo dobla mas, la punta dobla menos -un rastrillo de 45/30/18 grados-.
	## Se aplica iguales en las dos manos porque el desvio es RELATIVO a la
	## propia pose de reposo de cada una (misma logica que `_pista()`), asi
	## que no hace falta pelear con la asimetria de fabrica entre izquierda y
	## derecha para que las dos terminen viendose igual de relajadas.
	var curva := [["Index1", 45.0], ["Index2", 30.0], ["Index3", 18.0]]
	for lado in ["Left", "Right"]:
		for par in curva:
			var nombre := "mixamorig_%sHand%s" % [lado, par[0]]
			var idx := esq.find_bone(nombre)
			if idx < 0:
				continue
			var reposo := esq.get_bone_rest(idx).basis.get_rotation_quaternion()
			var desvio := Quaternion.from_euler(Vector3(deg_to_rad(float(par[1])), 0, 0))
			esq.set_bone_pose_rotation(idx, reposo * desvio)

static func construir(esq: Skeleton3D, ruta_esqueleto: String = "") -> AnimationLibrary:
	_prefijo = ruta_esqueleto if ruta_esqueleto != "" else str(esq.name)
	var lib := AnimationLibrary.new()
	lib.add_animation("parado", parado(esq))
	lib.add_animation("caminar", caminar(esq))
	lib.add_animation("trotar", correr(esq, 0.72, 0.55))
	lib.add_animation("correr", correr(esq, 0.52, 1.0))
	lib.add_animation("patear", patear(esq))
	lib.add_animation("tiro_libre", tiro_libre(esq))
	lib.add_animation("cabezazo", cabezazo(esq))
	lib.add_animation("portero_listo", portero_listo(esq))
	lib.add_animation("atajar_izq", atajar(esq, 1.0))
	lib.add_animation("atajar_der", atajar(esq, -1.0))
	lib.add_animation("celebrar", celebrar(esq))
	lib.add_animation("celebrar_rodillas", celebrar_rodillas(esq))
	lib.add_animation("levantar_copa", levantar_copa(esq))
	lib.add_animation("rabia", rabia(esq))
	lib.add_animation("lamento", lamento(esq))
	lib.add_animation("reclamar", reclamar(esq))
	lib.add_animation("falta_empujon", falta_empujon(esq))
	lib.add_animation("falta_barrida", falta_barrida(esq))
	lib.add_animation("falta_agarron", falta_agarron(esq))
	lib.add_animation("falta_codazo", falta_codazo(esq))
	lib.add_animation("falta_plancha", falta_plancha(esq))
	lib.add_animation("caer", caer(esq))
	lib.add_animation("mostrar_tarjeta", mostrar_tarjeta(esq))
	lib.add_animation("senalar_falta", senalar_falta(esq))
	lib.add_animation("bandera_fuera_juego", bandera_fuera_juego(esq))
	return lib

# ------------------------------------------------------------------ en pie

static func parado(esq: Skeleton3D) -> Animation:
	# Respirar y repartir el peso. Un personaje totalmente quieto parece roto.
	var a := _nueva(3.2, true)
	_pista_pos(a, esq, "cadera", [[0.0, Vector3.ZERO], [1.6, Vector3(0, 0.012, 0)], [3.2, Vector3.ZERO]])
	_pista(a, esq, "espalda", [[0.0, Vector3(0, 0, 0)], [1.6, Vector3(-1.6, 0, 0)], [3.2, Vector3.ZERO]])
	_pista(a, esq, "cabeza", [[0.0, Vector3(0, -4, 0)], [1.6, Vector3(0, 4, 0)], [3.2, Vector3(0, -4, 0)]])
	_pista(a, esq, "brazo_i", [[0.0, Vector3(0, 0, 5)], [1.6, Vector3(0, 0, 8)], [3.2, Vector3(0, 0, 5)]])
	_pista(a, esq, "brazo_d", [[0.0, Vector3(0, 0, -5)], [1.6, Vector3(0, 0, -8)], [3.2, Vector3(0, 0, -5)]])
	_pista(a, esq, "antebrazo_i", [[0.0, Vector3(0, 0, 12)]])
	_pista(a, esq, "antebrazo_d", [[0.0, Vector3(0, 0, -12)]])
	return a

## Ciclo de zancada. `dur` es lo que tarda un paso completo (los dos pies) y
## `f` la fuerza: 0.55 trota, 1.0 corre a tope. Las piernas van en contrafase y
## los brazos en contrafase de las piernas, que es lo que hace que se lea como
## una carrera y no como un muneco agitandose.
## El ciclo se describe en CUATRO tiempos por pierna, no en dos. Con solo
## "adelante" y "atras" el personaje se balancea como un pendulo y se nota de
## lejos que no es una carrera. Los cuatro son los de un ciclo real:
##   contacto -> apoyo -> impulso -> recogida (la rodilla sube y el talon busca
##   el gluteo). La rodilla NO se dobla igual todo el rato: casi recta al apoyar
##   y muy doblada al recoger, que es lo que da la sensacion de zancada.
static func correr(esq: Skeleton3D, dur: float, f: float) -> Animation:
	var a := _nueva(dur, true)
	var t1 := dur * 0.25
	var t2 := dur * 0.5
	var t3 := dur * 0.75
	var muslo: float = 44.0 * f
	var rodilla: float = 86.0 * f
	var brazo: float = 40.0 * f

	# Dos botes por ciclo (uno por pie), no uno: el cuerpo sube en cada impulso.
	_pista_pos(a, esq, "cadera", [
		[0.0, Vector3(0, -0.025 * f, 0)], [t1, Vector3(0, 0.03 * f, 0)],
		[t2, Vector3(0, -0.025 * f, 0)], [t3, Vector3(0, 0.03 * f, 0)],
		[dur, Vector3(0, -0.025 * f, 0)]])
	# Inclinacion hacia delante: poca, o parece que va a caerse de bruces.
	_pista(a, esq, "espalda", [[0.0, Vector3(-5.0 * f, 0, 0)]])
	# El tronco rota al reves que la cadera: es lo que hace que el braceo "cuadre"
	_pista(a, esq, "espalda1", [
		[0.0, Vector3(0, 6.0 * f, 0)], [t2, Vector3(0, -6.0 * f, 0)], [dur, Vector3(0, 6.0 * f, 0)]])
	_pista(a, esq, "cadera", [
		[0.0, Vector3(0, -4.0 * f, 0)], [t2, Vector3(0, 4.0 * f, 0)], [dur, Vector3(0, -4.0 * f, 0)]])
	# La cabeza se queda mirando al frente aunque el tronco gire.
	_pista(a, esq, "cuello", [
		[0.0, Vector3(3.0 * f, -3.0 * f, 0)], [t2, Vector3(3.0 * f, 3.0 * f, 0)],
		[dur, Vector3(3.0 * f, -3.0 * f, 0)]])

	_pierna(a, esq, "muslo_i", "pierna_i", "pie_i", 0.0, dur, muslo, rodilla)
	_pierna(a, esq, "muslo_d", "pierna_d", "pie_d", t2, dur, muslo, rodilla)

	# Brazos en contrafase de las piernas y cruzando un poco hacia el pecho, que
	# es como se corre de verdad; el codo va muy doblado y casi no cambia.
	_pista(a, esq, "brazo_i", [
		[0.0, Vector3(-brazo, 0, 16)], [t1, Vector3(-brazo * 0.2, 0, 10)],
		[t2, Vector3(brazo, 0, 6)], [t3, Vector3(brazo * 0.2, 0, 10)],
		[dur, Vector3(-brazo, 0, 16)]])
	_pista(a, esq, "brazo_d", [
		[0.0, Vector3(brazo, 0, -6)], [t1, Vector3(brazo * 0.2, 0, -10)],
		[t2, Vector3(-brazo, 0, -16)], [t3, Vector3(-brazo * 0.2, 0, -10)],
		[dur, Vector3(brazo, 0, -6)]])
	_pista(a, esq, "antebrazo_i", [
		[0.0, Vector3(0, 0, 78.0 * f)], [t2, Vector3(0, 0, 62.0 * f)], [dur, Vector3(0, 0, 78.0 * f)]])
	_pista(a, esq, "antebrazo_d", [
		[0.0, Vector3(0, 0, -62.0 * f)], [t2, Vector3(0, 0, -78.0 * f)], [dur, Vector3(0, 0, -62.0 * f)]])
	return a

## Una pierna entera con su desfase. `off` = 0 para la que empieza adelante y
## medio ciclo para la otra. Las claves se envuelven con fmod para que la fase
## caiga donde toque sin tener que escribir dos versiones de lo mismo.
static func _pierna(a: Animation, esq: Skeleton3D, mus: String, rod: String, pie: String,
		off: float, dur: float, muslo: float, rodilla: float) -> void:
	var fases := [
		# [fraccion del ciclo, muslo, rodilla, tobillo]
		[0.00,  muslo,          -rodilla * 0.16,  14.0],   # contacto: pierna estirada delante
		[0.25, -muslo * 0.35,   -rodilla * 0.10,  -4.0],   # apoyo: debajo del cuerpo
		[0.50, -muslo * 0.80,   -rodilla * 0.30, -22.0],   # impulso: empuja atras
		[0.75,  muslo * 0.55,   -rodilla,          8.0],   # recogida: rodilla arriba, talon al gluteo
		[1.00,  muslo,          -rodilla * 0.16,  14.0],
	]
	var km: Array = []
	var kr: Array = []
	var kp: Array = []
	for fase in fases:
		var t: float = fmod(float(fase[0]) * dur + off, dur)
		km.append([t, Vector3(fase[1], 0, 0)])
		kr.append([t, Vector3(fase[2], 0, 0)])
		kp.append([t, Vector3(fase[3], 0, 0)])
	# la clave del final del ciclo tiene que existir tambien en t=dur o el bucle
	# da un tiron al reengancharse
	km.append([dur, km[0][1]])
	kr.append([dur, kr[0][1]])
	kp.append([dur, kp[0][1]])
	_pista(a, esq, mus, km)
	_pista(a, esq, rod, kr)
	_pista(a, esq, pie, kp)

static func caminar(esq: Skeleton3D) -> Animation:
	return correr(esq, 1.05, 0.3)

# --------------------------------------------------------------- con el balon

static func patear(esq: Skeleton3D) -> Animation:
	# Armar la pierna, soltarla y acompanar. El pie de apoyo se queda plantado.
	var a := _nueva(0.85, false)
	_pista(a, esq, "espalda", [[0.0, Vector3(-6, 0, 0)], [0.32, Vector3(-16, 0, 0)],
		[0.46, Vector3(6, 0, 0)], [0.85, Vector3(-4, 0, 0)]])
	_pista(a, esq, "muslo_d", [[0.0, Vector3(-10, 0, 0)], [0.32, Vector3(-52, 0, 0)],
		[0.48, Vector3(58, 0, 0)], [0.85, Vector3(6, 0, 0)]])
	_pista(a, esq, "pierna_d", [[0.0, Vector3(-14, 0, 0)], [0.32, Vector3(-92, 0, 0)],
		[0.48, Vector3(-6, 0, 0)], [0.85, Vector3(-18, 0, 0)]])
	_pista(a, esq, "pie_d", [[0.0, Vector3(0, 0, 0)], [0.32, Vector3(-24, 0, 0)],
		[0.48, Vector3(22, 0, 0)], [0.85, Vector3(0, 0, 0)]])
	_pista(a, esq, "muslo_i", [[0.0, Vector3(6, 0, 0)], [0.48, Vector3(-8, 0, 0)], [0.85, Vector3(0, 0, 0)]])
	_pista(a, esq, "pierna_i", [[0.0, Vector3(-12, 0, 0)], [0.48, Vector3(-26, 0, 0)], [0.85, Vector3(-10, 0, 0)]])
	# los brazos contrapesan el latigazo, si no parece que patea una estatua
	_pista(a, esq, "brazo_i", [[0.0, Vector3(-14, 0, 16)], [0.34, Vector3(-58, 0, 34)],
		[0.5, Vector3(-20, 0, 20)], [0.85, Vector3(-10, 0, 14)]])
	_pista(a, esq, "brazo_d", [[0.0, Vector3(10, 0, -16)], [0.34, Vector3(34, 0, -26)],
		[0.5, Vector3(6, 0, -18)], [0.85, Vector3(8, 0, -14)]])
	_pista(a, esq, "antebrazo_i", [[0.0, Vector3(0, 0, 40)]])
	_pista(a, esq, "antebrazo_d", [[0.0, Vector3(0, 0, -40)]])
	return a

static func tiro_libre(esq: Skeleton3D) -> Animation:
	# Se cuadra, mira la barrera, coge carrerilla corta y pega.
	var a := _nueva(2.4, false)
	_pista(a, esq, "cabeza", [[0.0, Vector3(-6, 0, 0)], [0.7, Vector3(-2, 14, 0)],
		[1.3, Vector3(-8, 0, 0)], [2.4, Vector3(-4, 0, 0)]])
	_pista(a, esq, "espalda", [[0.0, Vector3(-4, 0, 0)], [1.4, Vector3(-12, 0, 0)],
		[1.85, Vector3(-20, 0, 0)], [2.0, Vector3(8, 0, 0)], [2.4, Vector3(-4, 0, 0)]])
	_pista(a, esq, "muslo_d", [[0.0, Vector3(0, 0, 0)], [1.5, Vector3(-18, 0, 0)],
		[1.85, Vector3(-56, 0, 0)], [2.02, Vector3(60, 0, 0)], [2.4, Vector3(4, 0, 0)]])
	_pista(a, esq, "pierna_d", [[0.0, Vector3(-8, 0, 0)], [1.85, Vector3(-95, 0, 0)],
		[2.02, Vector3(-8, 0, 0)], [2.4, Vector3(-16, 0, 0)]])
	_pista(a, esq, "brazo_i", [[0.0, Vector3(0, 0, 14)], [1.85, Vector3(-62, 0, 40)],
		[2.05, Vector3(-24, 0, 22)], [2.4, Vector3(-8, 0, 14)]])
	_pista(a, esq, "brazo_d", [[0.0, Vector3(0, 0, -14)], [1.85, Vector3(30, 0, -30)],
		[2.4, Vector3(6, 0, -14)]])
	_pista(a, esq, "antebrazo_i", [[0.0, Vector3(0, 0, 30)]])
	_pista(a, esq, "antebrazo_d", [[0.0, Vector3(0, 0, -30)]])
	return a

static func cabezazo(esq: Skeleton3D) -> Animation:
	var a := _nueva(1.0, false)
	_pista_pos(a, esq, "cadera", [[0.0, Vector3.ZERO], [0.35, Vector3(0, 0.22, 0)],
		[0.62, Vector3(0, 0.26, 0)], [1.0, Vector3.ZERO]])
	_pista(a, esq, "espalda", [[0.0, Vector3(0, 0, 0)], [0.4, Vector3(22, 0, 0)],
		[0.6, Vector3(-26, 0, 0)], [1.0, Vector3(0, 0, 0)]])
	_pista(a, esq, "cuello", [[0.0, Vector3(0, 0, 0)], [0.4, Vector3(16, 0, 0)],
		[0.58, Vector3(-20, 0, 0)], [1.0, Vector3(0, 0, 0)]])
	_pista(a, esq, "brazo_i", [[0.0, Vector3(0, 0, 14)], [0.4, Vector3(-40, 0, 58)], [1.0, Vector3(0, 0, 14)]])
	_pista(a, esq, "brazo_d", [[0.0, Vector3(0, 0, -14)], [0.4, Vector3(-40, 0, -58)], [1.0, Vector3(0, 0, -14)]])
	_pista(a, esq, "muslo_i", [[0.0, Vector3(0, 0, 0)], [0.45, Vector3(38, 0, 0)], [1.0, Vector3(0, 0, 0)]])
	_pista(a, esq, "pierna_i", [[0.0, Vector3(-6, 0, 0)], [0.45, Vector3(-72, 0, 0)], [1.0, Vector3(-6, 0, 0)]])
	return a

# ------------------------------------------------------------------- portero

static func portero_listo(esq: Skeleton3D) -> Animation:
	# Piernas abiertas, peso adelante, manos a la altura de la cintura.
	var a := _nueva(2.0, true)
	_pista(a, esq, "espalda", [[0.0, Vector3(-16, 0, 0)], [1.0, Vector3(-19, 0, 0)], [2.0, Vector3(-16, 0, 0)]])
	_pista(a, esq, "muslo_i", [[0.0, Vector3(24, 0, 12)], [1.0, Vector3(28, 0, 12)], [2.0, Vector3(24, 0, 12)]])
	_pista(a, esq, "muslo_d", [[0.0, Vector3(24, 0, -12)], [1.0, Vector3(28, 0, -12)], [2.0, Vector3(24, 0, -12)]])
	_pista(a, esq, "pierna_i", [[0.0, Vector3(-38, 0, 0)], [1.0, Vector3(-46, 0, 0)], [2.0, Vector3(-38, 0, 0)]])
	_pista(a, esq, "pierna_d", [[0.0, Vector3(-38, 0, 0)], [1.0, Vector3(-46, 0, 0)], [2.0, Vector3(-38, 0, 0)]])
	_pista(a, esq, "brazo_i", [[0.0, Vector3(-26, 0, 46)], [1.0, Vector3(-30, 0, 50)], [2.0, Vector3(-26, 0, 46)]])
	_pista(a, esq, "brazo_d", [[0.0, Vector3(-26, 0, -46)], [1.0, Vector3(-30, 0, -50)], [2.0, Vector3(-26, 0, -46)]])
	_pista(a, esq, "antebrazo_i", [[0.0, Vector3(0, 0, 72)]])
	_pista(a, esq, "antebrazo_d", [[0.0, Vector3(0, 0, -72)]])
	return a

## Estirada. `lado` = +1 a su izquierda, -1 a su derecha.
static func atajar(esq: Skeleton3D, lado: float) -> Animation:
	var a := _nueva(1.15, false)
	_pista_pos(a, esq, "cadera", [[0.0, Vector3.ZERO], [0.25, Vector3(0, 0.14, 0)],
		[0.6, Vector3(0.5 * lado, -0.25, 0)], [1.15, Vector3(0.75 * lado, -0.42, 0)]])
	_pista(a, esq, "cadera", [[0.0, Vector3(0, 0, 0)], [0.3, Vector3(0, 0, 22 * lado)],
		[1.15, Vector3(0, 0, 74 * lado)]])
	_pista(a, esq, "espalda", [[0.0, Vector3(-14, 0, 0)], [0.5, Vector3(-6, 0, 10 * lado)],
		[1.15, Vector3(2, 0, 16 * lado)]])
	# el brazo del lado del disparo se estira del todo, el otro acompana
	_pista(a, esq, "brazo_i", [[0.0, Vector3(-26, 0, 46)],
		[0.45, Vector3(-40, 0, 92 if lado > 0 else 30)], [1.15, Vector3(-52, 0, 104 if lado > 0 else 24)]])
	_pista(a, esq, "brazo_d", [[0.0, Vector3(-26, 0, -46)],
		[0.45, Vector3(-40, 0, -92 if lado < 0 else -30)], [1.15, Vector3(-52, 0, -104 if lado < 0 else -24)]])
	_pista(a, esq, "antebrazo_i", [[0.0, Vector3(0, 0, 72)], [0.5, Vector3(0, 0, 18)], [1.15, Vector3(0, 0, 6)]])
	_pista(a, esq, "antebrazo_d", [[0.0, Vector3(0, 0, -72)], [0.5, Vector3(0, 0, -18)], [1.15, Vector3(0, 0, -6)]])
	_pista(a, esq, "muslo_i", [[0.0, Vector3(24, 0, 12)], [0.5, Vector3(10, 0, 26)], [1.15, Vector3(-14, 0, 30)]])
	_pista(a, esq, "muslo_d", [[0.0, Vector3(24, 0, -12)], [0.5, Vector3(10, 0, -26)], [1.15, Vector3(-14, 0, -30)]])
	_pista(a, esq, "pierna_i", [[0.0, Vector3(-38, 0, 0)], [1.15, Vector3(-20, 0, 0)]])
	_pista(a, esq, "pierna_d", [[0.0, Vector3(-38, 0, 0)], [1.15, Vector3(-20, 0, 0)]])
	return a

# --------------------------------------------------------------- celebrar

static func celebrar(esq: Skeleton3D) -> Animation:
	# Correr con los brazos abiertos y dar un salto. La clasica.
	var a := _nueva(1.6, true)
	_pista_pos(a, esq, "cadera", [[0.0, Vector3.ZERO], [0.4, Vector3(0, 0.24, 0)],
		[0.8, Vector3.ZERO], [1.2, Vector3(0, 0.1, 0)], [1.6, Vector3.ZERO]])
	_pista(a, esq, "espalda", [[0.0, Vector3(4, 0, 0)], [0.4, Vector3(-12, 0, 0)], [1.6, Vector3(4, 0, 0)]])
	_pista(a, esq, "cabeza", [[0.0, Vector3(-14, 0, 0)], [0.8, Vector3(-18, 8, 0)], [1.6, Vector3(-14, 0, 0)]])
	_pista(a, esq, "brazo_i", [[0.0, Vector3(-20, 0, 96)], [0.4, Vector3(-30, 0, 128)],
		[0.8, Vector3(-20, 0, 96)], [1.6, Vector3(-20, 0, 96)]])
	_pista(a, esq, "brazo_d", [[0.0, Vector3(-20, 0, -96)], [0.4, Vector3(-30, 0, -128)],
		[0.8, Vector3(-20, 0, -96)], [1.6, Vector3(-20, 0, -96)]])
	_pista(a, esq, "antebrazo_i", [[0.0, Vector3(0, 0, 16)]])
	_pista(a, esq, "antebrazo_d", [[0.0, Vector3(0, 0, -16)]])
	_pista(a, esq, "muslo_i", [[0.0, Vector3(18, 0, 0)], [0.4, Vector3(46, 0, 0)], [0.8, Vector3(-18, 0, 0)],
		[1.2, Vector3(30, 0, 0)], [1.6, Vector3(18, 0, 0)]])
	_pista(a, esq, "muslo_d", [[0.0, Vector3(-18, 0, 0)], [0.4, Vector3(30, 0, 0)], [0.8, Vector3(18, 0, 0)],
		[1.2, Vector3(-14, 0, 0)], [1.6, Vector3(-18, 0, 0)]])
	_pista(a, esq, "pierna_i", [[0.0, Vector3(-40, 0, 0)], [0.4, Vector3(-88, 0, 0)], [1.6, Vector3(-40, 0, 0)]])
	_pista(a, esq, "pierna_d", [[0.0, Vector3(-30, 0, 0)], [0.8, Vector3(-70, 0, 0)], [1.6, Vector3(-30, 0, 0)]])
	return a

static func celebrar_rodillas(esq: Skeleton3D) -> Animation:
	var a := _nueva(2.0, false)
	_pista_pos(a, esq, "cadera", [[0.0, Vector3.ZERO], [0.9, Vector3(0, -0.42, 0)], [2.0, Vector3(0, -0.46, 0)]])
	_pista(a, esq, "muslo_i", [[0.0, Vector3(0, 0, 0)], [0.9, Vector3(-72, 0, 8)], [2.0, Vector3(-78, 0, 8)]])
	_pista(a, esq, "muslo_d", [[0.0, Vector3(0, 0, 0)], [0.9, Vector3(-72, 0, -8)], [2.0, Vector3(-78, 0, -8)]])
	_pista(a, esq, "pierna_i", [[0.0, Vector3(-10, 0, 0)], [0.9, Vector3(-108, 0, 0)], [2.0, Vector3(-112, 0, 0)]])
	_pista(a, esq, "pierna_d", [[0.0, Vector3(-10, 0, 0)], [0.9, Vector3(-108, 0, 0)], [2.0, Vector3(-112, 0, 0)]])
	_pista(a, esq, "espalda", [[0.0, Vector3(0, 0, 0)], [1.0, Vector3(-22, 0, 0)], [2.0, Vector3(-18, 0, 0)]])
	_pista(a, esq, "cabeza", [[0.0, Vector3(0, 0, 0)], [1.0, Vector3(-30, 0, 0)], [2.0, Vector3(-26, 0, 0)]])
	_pista(a, esq, "brazo_i", [[0.0, Vector3(0, 0, 20)], [1.0, Vector3(-24, 0, 132)], [2.0, Vector3(-28, 0, 138)]])
	_pista(a, esq, "brazo_d", [[0.0, Vector3(0, 0, -20)], [1.0, Vector3(-24, 0, -132)], [2.0, Vector3(-28, 0, -138)]])
	return a

static func levantar_copa(esq: Skeleton3D) -> Animation:
	# Levanta con las dos manos, la sostiene arriba y la mece.
	var a := _nueva(3.4, false)
	_pista(a, esq, "espalda", [[0.0, Vector3(10, 0, 0)], [1.0, Vector3(-14, 0, 0)], [3.4, Vector3(-10, 0, 0)]])
	_pista(a, esq, "cabeza", [[0.0, Vector3(6, 0, 0)], [1.2, Vector3(-16, 0, 0)], [3.4, Vector3(-12, 0, 0)]])
	_pista(a, esq, "brazo_i", [[0.0, Vector3(-30, 0, 30)], [1.1, Vector3(-16, 0, 148)],
		[2.2, Vector3(-16, 0, 156)], [3.4, Vector3(-16, 0, 148)]])
	_pista(a, esq, "brazo_d", [[0.0, Vector3(-30, 0, -30)], [1.1, Vector3(-16, 0, -148)],
		[2.2, Vector3(-16, 0, -156)], [3.4, Vector3(-16, 0, -148)]])
	_pista(a, esq, "antebrazo_i", [[0.0, Vector3(0, 0, 74)], [1.1, Vector3(0, 0, 26)], [3.4, Vector3(0, 0, 22)]])
	_pista(a, esq, "antebrazo_d", [[0.0, Vector3(0, 0, -74)], [1.1, Vector3(0, 0, -26)], [3.4, Vector3(0, 0, -22)]])
	_pista_pos(a, esq, "cadera", [[0.0, Vector3(0, -0.12, 0)], [1.1, Vector3(0, 0.04, 0)],
		[2.2, Vector3(0, 0.06, 0)], [3.4, Vector3(0, 0.04, 0)]])
	return a

# ------------------------------------------------------------------ enfados

static func rabia(esq: Skeleton3D) -> Animation:
	# Punos apretados abajo, cuerpo tenso, grito.
	var a := _nueva(1.4, false)
	_pista(a, esq, "espalda", [[0.0, Vector3(0, 0, 0)], [0.35, Vector3(-16, 0, 0)],
		[0.8, Vector3(10, 0, 0)], [1.4, Vector3(0, 0, 0)]])
	_pista(a, esq, "cabeza", [[0.0, Vector3(0, 0, 0)], [0.35, Vector3(-22, 0, 0)], [1.4, Vector3(-4, 0, 0)]])
	_pista(a, esq, "brazo_i", [[0.0, Vector3(0, 0, 14)], [0.35, Vector3(-34, 0, 40)],
		[0.8, Vector3(24, 0, 22)], [1.4, Vector3(0, 0, 14)]])
	_pista(a, esq, "brazo_d", [[0.0, Vector3(0, 0, -14)], [0.35, Vector3(-34, 0, -40)],
		[0.8, Vector3(24, 0, -22)], [1.4, Vector3(0, 0, -14)]])
	_pista(a, esq, "antebrazo_i", [[0.0, Vector3(0, 0, 30)], [0.35, Vector3(0, 0, 96)], [1.4, Vector3(0, 0, 30)]])
	_pista(a, esq, "antebrazo_d", [[0.0, Vector3(0, 0, -30)], [0.35, Vector3(0, 0, -96)], [1.4, Vector3(0, 0, -30)]])
	return a

## "La cara de que la cague": manos a la cabeza y mirada al suelo.
static func lamento(esq: Skeleton3D) -> Animation:
	var a := _nueva(2.2, false)
	_pista(a, esq, "espalda", [[0.0, Vector3(0, 0, 0)], [0.8, Vector3(14, 0, 0)], [2.2, Vector3(12, 0, 0)]])
	_pista(a, esq, "cabeza", [[0.0, Vector3(0, 0, 0)], [0.8, Vector3(24, 0, 0)], [2.2, Vector3(22, 0, 0)]])
	_pista(a, esq, "brazo_i", [[0.0, Vector3(0, 0, 14)], [0.7, Vector3(-26, 0, 128)], [2.2, Vector3(-24, 0, 124)]])
	_pista(a, esq, "brazo_d", [[0.0, Vector3(0, 0, -14)], [0.7, Vector3(-26, 0, -128)], [2.2, Vector3(-24, 0, -124)]])
	_pista(a, esq, "antebrazo_i", [[0.0, Vector3(0, 0, 30)], [0.7, Vector3(0, 0, 112)], [2.2, Vector3(0, 0, 116)]])
	_pista(a, esq, "antebrazo_d", [[0.0, Vector3(0, 0, -30)], [0.7, Vector3(0, 0, -112)], [2.2, Vector3(0, 0, -116)]])
	_pista_pos(a, esq, "cadera", [[0.0, Vector3.ZERO], [0.8, Vector3(0, -0.08, 0)], [2.2, Vector3(0, -0.07, 0)]])
	return a

## Protestarle al arbitro con los brazos abiertos.
static func reclamar(esq: Skeleton3D) -> Animation:
	var a := _nueva(1.8, false)
	_pista(a, esq, "espalda", [[0.0, Vector3(0, 0, 0)], [0.5, Vector3(-10, 0, 0)],
		[1.1, Vector3(-4, 0, 0)], [1.8, Vector3(-8, 0, 0)]])
	_pista(a, esq, "cabeza", [[0.0, Vector3(0, 0, 0)], [0.5, Vector3(-14, -10, 0)], [1.8, Vector3(-10, 6, 0)]])
	_pista(a, esq, "brazo_i", [[0.0, Vector3(0, 0, 14)], [0.5, Vector3(-8, 0, 74)],
		[1.1, Vector3(-8, 0, 56)], [1.8, Vector3(-8, 0, 78)]])
	_pista(a, esq, "brazo_d", [[0.0, Vector3(0, 0, -14)], [0.5, Vector3(-8, 0, -74)],
		[1.1, Vector3(-8, 0, -56)], [1.8, Vector3(-8, 0, -78)]])
	_pista(a, esq, "antebrazo_i", [[0.0, Vector3(0, 0, 30)], [0.5, Vector3(0, 0, 66)], [1.8, Vector3(0, 0, 58)]])
	_pista(a, esq, "antebrazo_d", [[0.0, Vector3(0, 0, -30)], [0.5, Vector3(0, 0, -66)], [1.8, Vector3(0, 0, -58)]])
	return a

# -------------------------------------------------------------------- faltas

static func falta_empujon(esq: Skeleton3D) -> Animation:
	var a := _nueva(0.9, false)
	_pista(a, esq, "espalda", [[0.0, Vector3(0, 0, 0)], [0.3, Vector3(-14, -12, 0)],
		[0.5, Vector3(-6, 14, 0)], [0.9, Vector3(0, 0, 0)]])
	_pista(a, esq, "brazo_i", [[0.0, Vector3(0, 0, 14)], [0.28, Vector3(-52, 0, 60)],
		[0.5, Vector3(-64, 0, 86)], [0.9, Vector3(0, 0, 14)]])
	_pista(a, esq, "brazo_d", [[0.0, Vector3(0, 0, -14)], [0.28, Vector3(-52, 0, -60)],
		[0.5, Vector3(-64, 0, -86)], [0.9, Vector3(0, 0, -14)]])
	_pista(a, esq, "antebrazo_i", [[0.0, Vector3(0, 0, 40)], [0.28, Vector3(0, 0, 86)], [0.5, Vector3(0, 0, 12)]])
	_pista(a, esq, "antebrazo_d", [[0.0, Vector3(0, 0, -40)], [0.28, Vector3(0, 0, -86)], [0.5, Vector3(0, 0, -12)]])
	return a

static func falta_barrida(esq: Skeleton3D) -> Animation:
	# Entrada a ras de suelo con la pierna por delante.
	var a := _nueva(1.3, false)
	_pista_pos(a, esq, "cadera", [[0.0, Vector3.ZERO], [0.45, Vector3(0, -0.34, 0)], [1.3, Vector3(0, -0.5, 0)]])
	_pista(a, esq, "cadera", [[0.0, Vector3(0, 0, 0)], [0.45, Vector3(-24, 0, 16)], [1.3, Vector3(-44, 0, 26)]])
	_pista(a, esq, "muslo_d", [[0.0, Vector3(0, 0, 0)], [0.4, Vector3(56, 0, -10)], [1.3, Vector3(72, 0, -12)]])
	_pista(a, esq, "pierna_d", [[0.0, Vector3(-10, 0, 0)], [0.4, Vector3(-14, 0, 0)], [1.3, Vector3(-6, 0, 0)]])
	_pista(a, esq, "muslo_i", [[0.0, Vector3(0, 0, 0)], [0.4, Vector3(-30, 0, 12)], [1.3, Vector3(-46, 0, 14)]])
	_pista(a, esq, "pierna_i", [[0.0, Vector3(-10, 0, 0)], [0.4, Vector3(-96, 0, 0)], [1.3, Vector3(-104, 0, 0)]])
	_pista(a, esq, "brazo_i", [[0.0, Vector3(0, 0, 14)], [0.5, Vector3(-30, 0, 70)], [1.3, Vector3(-36, 0, 82)]])
	_pista(a, esq, "brazo_d", [[0.0, Vector3(0, 0, -14)], [0.5, Vector3(-30, 0, -70)], [1.3, Vector3(-36, 0, -82)]])
	return a

static func falta_agarron(esq: Skeleton3D) -> Animation:
	var a := _nueva(1.5, false)
	_pista(a, esq, "espalda", [[0.0, Vector3(0, 0, 0)], [0.4, Vector3(-8, -16, 0)], [1.5, Vector3(-6, -20, 0)]])
	_pista(a, esq, "brazo_d", [[0.0, Vector3(0, 0, -14)], [0.4, Vector3(-58, 0, -74)], [1.5, Vector3(-62, 0, -70)]])
	_pista(a, esq, "antebrazo_d", [[0.0, Vector3(0, 0, -40)], [0.4, Vector3(0, 0, -104)], [1.5, Vector3(0, 0, -110)]])
	_pista(a, esq, "brazo_i", [[0.0, Vector3(0, 0, 14)], [0.4, Vector3(-30, 0, 40)], [1.5, Vector3(-26, 0, 36)]])
	_pista(a, esq, "muslo_i", [[0.0, Vector3(0, 0, 0)], [0.6, Vector3(16, 0, 0)], [1.5, Vector3(10, 0, 0)]])
	return a

static func falta_codazo(esq: Skeleton3D) -> Animation:
	var a := _nueva(0.8, false)
	_pista(a, esq, "espalda1", [[0.0, Vector3(0, 0, 0)], [0.25, Vector3(0, 22, 0)],
		[0.42, Vector3(0, -26, 0)], [0.8, Vector3(0, 0, 0)]])
	_pista(a, esq, "brazo_d", [[0.0, Vector3(0, 0, -14)], [0.25, Vector3(-20, 0, -40)],
		[0.42, Vector3(-70, 0, -84)], [0.8, Vector3(0, 0, -14)]])
	_pista(a, esq, "antebrazo_d", [[0.0, Vector3(0, 0, -40)], [0.42, Vector3(0, 0, -118)], [0.8, Vector3(0, 0, -40)]])
	_pista(a, esq, "cabeza", [[0.0, Vector3(0, 0, 0)], [0.42, Vector3(-6, -20, 0)], [0.8, Vector3(0, 0, 0)]])
	return a

static func falta_plancha(esq: Skeleton3D) -> Animation:
	# Las dos piernas por delante, en el aire. La mas fea de todas.
	var a := _nueva(1.2, false)
	_pista_pos(a, esq, "cadera", [[0.0, Vector3.ZERO], [0.4, Vector3(0, 0.1, 0)], [1.2, Vector3(0, -0.44, 0)]])
	_pista(a, esq, "cadera", [[0.0, Vector3(0, 0, 0)], [0.4, Vector3(-40, 0, 0)], [1.2, Vector3(-62, 0, 0)]])
	_pista(a, esq, "muslo_d", [[0.0, Vector3(0, 0, 0)], [0.4, Vector3(70, 0, -8)], [1.2, Vector3(84, 0, -10)]])
	_pista(a, esq, "muslo_i", [[0.0, Vector3(0, 0, 0)], [0.4, Vector3(52, 0, 10)], [1.2, Vector3(64, 0, 12)]])
	_pista(a, esq, "pierna_d", [[0.0, Vector3(-10, 0, 0)], [1.2, Vector3(-4, 0, 0)]])
	_pista(a, esq, "pierna_i", [[0.0, Vector3(-10, 0, 0)], [1.2, Vector3(-34, 0, 0)]])
	_pista(a, esq, "brazo_i", [[0.0, Vector3(0, 0, 14)], [1.2, Vector3(-40, 0, 92)]])
	_pista(a, esq, "brazo_d", [[0.0, Vector3(0, 0, -14)], [1.2, Vector3(-40, 0, -92)]])
	return a

## El que RECIBE la falta: se va al suelo.
static func caer(esq: Skeleton3D) -> Animation:
	var a := _nueva(1.4, false)
	_pista_pos(a, esq, "cadera", [[0.0, Vector3.ZERO], [0.35, Vector3(0, -0.1, 0)], [1.4, Vector3(0, -0.62, 0)]])
	_pista(a, esq, "cadera", [[0.0, Vector3(0, 0, 0)], [0.4, Vector3(-20, 0, 18)], [1.4, Vector3(-78, 0, 34)]])
	_pista(a, esq, "espalda", [[0.0, Vector3(0, 0, 0)], [0.5, Vector3(16, 0, 0)], [1.4, Vector3(24, 0, 0)]])
	_pista(a, esq, "muslo_i", [[0.0, Vector3(0, 0, 0)], [1.4, Vector3(-46, 0, 14)]])
	_pista(a, esq, "muslo_d", [[0.0, Vector3(0, 0, 0)], [1.4, Vector3(-30, 0, -10)]])
	_pista(a, esq, "pierna_i", [[0.0, Vector3(-10, 0, 0)], [1.4, Vector3(-94, 0, 0)]])
	_pista(a, esq, "pierna_d", [[0.0, Vector3(-10, 0, 0)], [1.4, Vector3(-72, 0, 0)]])
	_pista(a, esq, "brazo_i", [[0.0, Vector3(0, 0, 14)], [0.7, Vector3(-56, 0, 96)], [1.4, Vector3(-30, 0, 60)]])
	_pista(a, esq, "brazo_d", [[0.0, Vector3(0, 0, -14)], [0.7, Vector3(-56, 0, -96)], [1.4, Vector3(-30, 0, -60)]])
	return a

# ------------------------------------------------------------------- arbitro

## Saca la tarjeta: la mano al bolsillo del pecho y el brazo arriba del todo.
static func mostrar_tarjeta(esq: Skeleton3D) -> Animation:
	var a := _nueva(2.2, false)
	_pista(a, esq, "espalda", [[0.0, Vector3(0, 0, 0)], [0.5, Vector3(6, 0, 0)], [1.2, Vector3(-8, 0, 0)],
		[2.2, Vector3(-6, 0, 0)]])
	_pista(a, esq, "cabeza", [[0.0, Vector3(0, 0, 0)], [1.3, Vector3(-8, 0, 0)], [2.2, Vector3(-6, 0, 0)]])
	# 0.0-0.6 la mano va al bolsillo; 0.9-2.2 el brazo sube recto
	_pista(a, esq, "brazo_d", [[0.0, Vector3(0, 0, -14)], [0.55, Vector3(-42, 0, -62)],
		[1.15, Vector3(-14, 0, -166)], [2.2, Vector3(-14, 0, -170)]])
	_pista(a, esq, "antebrazo_d", [[0.0, Vector3(0, 0, -30)], [0.55, Vector3(0, 0, -108)],
		[1.15, Vector3(0, 0, -8)], [2.2, Vector3(0, 0, -4)]])
	_pista(a, esq, "brazo_i", [[0.0, Vector3(0, 0, 14)], [1.2, Vector3(-6, 0, 26)], [2.2, Vector3(-6, 0, 24)]])
	return a

## Pita y senala el punto de la falta con el brazo extendido.
static func senalar_falta(esq: Skeleton3D) -> Animation:
	var a := _nueva(1.6, false)
	_pista(a, esq, "brazo_d", [[0.0, Vector3(0, 0, -14)], [0.4, Vector3(-30, 0, -96)], [1.6, Vector3(-28, 0, -92)]])
	_pista(a, esq, "antebrazo_d", [[0.0, Vector3(0, 0, -30)], [0.4, Vector3(0, 0, -10)], [1.6, Vector3(0, 0, -6)]])
	# la izquierda sostiene el silbato en la boca
	_pista(a, esq, "brazo_i", [[0.0, Vector3(0, 0, 14)], [0.25, Vector3(-40, 0, 108)], [1.6, Vector3(-38, 0, 104)]])
	_pista(a, esq, "antebrazo_i", [[0.0, Vector3(0, 0, 30)], [0.25, Vector3(0, 0, 118)], [1.6, Vector3(0, 0, 116)]])
	_pista(a, esq, "espalda", [[0.0, Vector3(0, 0, 0)], [0.4, Vector3(-10, 0, 0)], [1.6, Vector3(-8, 0, 0)]])
	return a

## Juez de linea: bandera en alto, quieta, y luego apuntando.
static func bandera_fuera_juego(esq: Skeleton3D) -> Animation:
	var a := _nueva(2.4, false)
	_pista(a, esq, "brazo_d", [[0.0, Vector3(0, 0, -14)], [0.5, Vector3(-10, 0, -172)],
		[1.4, Vector3(-10, 0, -174)], [2.4, Vector3(-24, 0, -96)]])
	_pista(a, esq, "antebrazo_d", [[0.0, Vector3(0, 0, -30)], [0.5, Vector3(0, 0, -6)], [2.4, Vector3(0, 0, -4)]])
	_pista(a, esq, "cabeza", [[0.0, Vector3(0, 0, 0)], [1.4, Vector3(0, -18, 0)], [2.4, Vector3(-6, -22, 0)]])
	_pista(a, esq, "espalda", [[0.0, Vector3(0, 0, 0)], [2.4, Vector3(-6, -10, 0)]])
	return a
