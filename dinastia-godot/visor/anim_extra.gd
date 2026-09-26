class_name AnimExtra
extends RefCounted
## EL PORTAFOLIO GRANDE DE MOVIMIENTOS (26-9-2026). Pedido: *"agrega más
## movimientos, regates, expresiones de los jugadores, buscando que tengamos un
## portafolio gigante"*.
##
## Tres fuentes, sin comprar nada:
##   1. Los clips de la Universal Animation Library (CC0, mismo esqueleto) que
##      no se usaban: salto, voltereta, golpes, caída, baile, charla, empujón,
##      agacharse, atarse los botines, recoger el balón, sentarse...
##   2. EL ESPEJO de cada clip de mocap de fútbol: el mismo movimiento con la
##      otra pierna / hacia el otro lado (patada de zurdo, regate hacia la
##      izquierda, estirada del portero al otro palo). Se hace en espacio del
##      MODELO -se evalúa la pose entera, se refleja el cuerpo y se vuelve a
##      rotaciones locales corrigiendo el reposo de cada par izquierda/derecha-,
##      así no depende de cómo estén orientados los ejes de cada hueso.
##   3. Expresiones hechas a mano: aplaudir, protestar, brazos en jarra,
##      cansado, besar el escudo, pedir el balón, saludar, pedir calma...
##
## `CATEGORIAS` agrupa todo por acción, para que el partido (y una futura IA)
## elija variantes en vez de repetir siempre el mismo gesto.

## nombre nuestro -> clip de la UAL
const UAL := {
	"saltar_inicio": "Jump_Start", "saltar": "Jump_Loop", "caer_salto": "Jump_Land",
	"voltereta": "Roll", "golpe_pecho": "Hit_Chest", "balonazo_cara": "Hit_Head",
	"caida_lesion": "Death01", "agachado": "Crouch_Idle_Loop", "agachado_avanza": "Crouch_Fwd_Loop",
	"atarse_botin": "Fixing_Kneeling", "baile": "Dance_Loop", "charla": "Idle_Talking_Loop",
	"empujar": "Push_Loop", "saludo_mano": "Interact", "recoger_balon": "PickUp_Table",
	"caminar_formal": "Walk_Formal_Loop", "sentarse": "Sitting_Enter", "levantarse": "Sitting_Exit",
	"sentado_charla": "Sitting_Talking_Loop", "pedir_con_brazo": "Spell_Simple_Shoot",
	"brazos_al_frente": "Spell_Simple_Enter", "puno_al_aire": "Punch_Jab", "trotar_atras": "Jog_Fwd_Loop",
}
## Los clips de fútbol que se espejan (nombre del original en la librería).
const ESPEJABLES := ["patear", "pase", "penal", "penal_2", "regate_finta", "regate_pausa", "conducir",
	"atajar_izq", "atajar_der", "atajar_bajo", "celebrar", "celebrar_rodillas", "celebrar_carrera",
	"saque_banda", "marcar", "falta_empujon", "mostrar_tarjeta", "mostrar_roja", "dominadas_1",
	"dominadas_2", "dominadas_3", "cabezazo", "falta_barrida", "rabia"]

## Acción -> variantes posibles (las que existan en la librería del jugador).
const CATEGORIAS := {
	"regate": ["regate_finta", "regate_finta_espejo", "regate_pausa", "regate_pausa_espejo", "voltereta"],
	"conducir": ["conducir", "conducir_espejo"],
	"patear": ["patear", "patear_espejo"],
	"pase": ["pase", "pase_espejo"],
	"penal": ["penal", "penal_espejo", "penal_2", "penal_2_espejo"],
	"atajar": ["atajar_izq", "atajar_der", "atajar_bajo", "atajar_izq_espejo", "atajar_der_espejo", "atajar_bajo_espejo"],
	"cabezazo": ["cabezazo", "cabezazo_espejo", "saltar_inicio"],
	"celebrar": ["celebrar", "celebrar_espejo", "celebrar_rodillas", "celebrar_rodillas_espejo", "celebrar_carrera",
		"celebrar_carrera_espejo", "baile", "puno_al_aire", "besar_escudo", "senalar_cielo", "aplaudir"],
	"lamento": ["lamento", "rabia", "rabia_espejo", "manos_cabeza", "cabeza_gacha", "cansado", "mirar_cielo"],
	"protesta": ["protestar", "brazos_jarra", "charla", "pedir_calma"],
	"pedir_balon": ["pedir_balon", "pedir_con_brazo", "senalar_adelante"],
	"defender": ["marcar", "marcar_espejo", "falta_empujon", "falta_empujon_espejo", "empujar", "falta_barrida", "falta_barrida_espejo"],
	"dominadas": ["dominadas_1", "dominadas_2", "dominadas_3", "dominadas_1_espejo", "dominadas_2_espejo", "dominadas_3_espejo"],
	"incidencia": ["golpe_pecho", "balonazo_cara", "caida_lesion", "dolor", "atarse_botin", "recoger_balon", "agachado"],
	"publico": ["saludar_publico", "aplaudir", "saludo_mano"],
	"arbitro": ["mostrar_tarjeta", "mostrar_roja", "senalar_falta", "mostrar_tarjeta_espejo"],
}

## Añade todo a la librería de un jugador. `lib` ya trae los clips de siempre.
static func extender(lib: AnimationLibrary, esq: Skeleton3D, prefijo: String) -> void:
	for k: String in UAL:
		if lib.has_animation(k):
			continue
		## Al importar, Godot le quita el sufijo "_Loop" al nombre (y deja el
		## clip en bucle): se prueba con y sin él.
		var nombre_ual := String(UAL[k])
		var a: Animation = AnimQuaternius.cargar_real(nombre_ual, prefijo)
		if a == null and nombre_ual.ends_with("_Loop"):
			a = AnimQuaternius.cargar_real(nombre_ual.trim_suffix("_Loop"), prefijo)
		if a != null:
			if not nombre_ual.ends_with("Loop"):
				a.loop_mode = Animation.LOOP_NONE
			lib.add_animation(k, a)
	var inst := AnimExtra.new()
	for k: String in EXPRESIONES:
		if not lib.has_animation(k):
			var ex: Animation = inst.call(String(EXPRESIONES[k]), esq, prefijo)
			_completar(ex, esq, prefijo)
			lib.add_animation(k, ex)
	for k: String in ESPEJABLES:
		var nombre := k + "_espejo"
		if lib.has_animation(k) and not lib.has_animation(nombre):
			var e := espejar(lib.get_animation(k), esq, prefijo, k)
			if e != null:
				lib.add_animation(nombre, e)

## Las variantes de una acción que tiene este jugador.
static func variantes(ap: AnimationPlayer, accion: String) -> Array:
	var r: Array = []
	for n: String in CATEGORIAS.get(accion, [accion]):
		if ap.has_animation(n):
			r.append(n)
	return r

## ¿Zurdo? El mismo hash que `Jugador.pie()`, para no tener que pasarle el
## jugador entero al partido 3D.
static func es_zurdo(id: String) -> bool:
	var h := 5381
	for i in id.length():
		h = ((h << 5) + h + id.unicode_at(i)) & 0x7FFFFFFF
	return h % 100 >= 76

## LA VARIANTE QUE TOCA (lo usa `MatchPlayback._ejecutar_accion`):
##   - los golpeos (patear, pase, penal, cabezazo) de un zurdo van espejados;
##   - regates, celebraciones y lamentos se sortean entre su categoría, para
##     no ver siempre el mismo gesto.
const SE_SORTEAN := {"regate_finta": "regate", "regate_pausa": "regate", "celebrar": "celebrar",
	"celebrar_rodillas": "celebrar", "celebrar_carrera": "celebrar", "lamento": "lamento", "rabia": "lamento",
	"protestar": "protesta", "pedir_balon": "pedir_balon"}
## Estos solo cambian de lado (la dirección no importa); la estirada del
## portero NO, porque va hacia donde va el balón.
const A_CUALQUIER_LADO := ["marcar", "falta_empujon", "conducir"]
const DE_PIE := ["patear", "pase", "penal", "penal_2", "cabezazo", "falta_barrida"]

static func variante(ap: AnimationPlayer, nombre: String, id_jugador: String, rng: RandomNumberGenerator) -> String:
	if DE_PIE.has(nombre) and es_zurdo(id_jugador) and ap.has_animation(nombre + "_espejo"):
		return nombre + "_espejo"
	if SE_SORTEAN.has(nombre):
		var opciones := variantes(ap, String(SE_SORTEAN[nombre]))
		if not opciones.is_empty():
			return String(opciones[rng.randi() % opciones.size()])
	if A_CUALQUIER_LADO.has(nombre) and rng.randf() < 0.5 and ap.has_animation(nombre + "_espejo"):
		return nombre + "_espejo"
	return nombre

## Cuántos movimientos distintos hay en total (para la ficha y las pruebas).
static func total(lib: AnimationLibrary) -> int:
	return lib.get_animation_list().size()

## ------------------------------------------------------------------ ESPEJO

static var _cache_espejo: Dictionary = {}

static func _par(nombre: String) -> String:
	if nombre.ends_with("_l"):
		return nombre.substr(0, nombre.length() - 2) + "_r"
	if nombre.ends_with("_r"):
		return nombre.substr(0, nombre.length() - 2) + "_l"
	return nombre

## El mismo movimiento reflejado izquierda <-> derecha.
static func espejar(original: Animation, esq: Skeleton3D, prefijo: String, clave: String = "") -> Animation:
	var cc := "%s|%s" % [clave, prefijo]
	if clave != "" and _cache_espejo.has(cc):
		return _cache_espejo[cc]
	var n := esq.get_bone_count()
	## Qué pistas hay por hueso.
	var pista_rot := {}
	var pista_pos := {}
	for t in original.get_track_count():
		var ruta := str(original.track_get_path(t))
		var hueso := ruta.substr(ruta.rfind(":") + 1)
		var i := esq.find_bone(hueso)
		if i < 0:
			continue
		match original.track_get_type(t):
			Animation.TYPE_ROTATION_3D: pista_rot[i] = t
			Animation.TYPE_POSITION_3D: pista_pos[i] = t
	if pista_rot.is_empty():
		return null
	## El reflejo del cuerpo: la x del modelo cambia de signo.
	var S := Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1))
	var par_de: Array = []
	var padres: Array = []
	var reposo: Array = []
	for i in n:
		var p := esq.find_bone(_par(esq.get_bone_name(i)))
		par_de.append(p if p >= 0 else i)
		padres.append(esq.get_bone_parent(i))
		reposo.append(esq.get_bone_rest(i))
	## Reposo global y la corrección de ejes de cada par.
	var rg: Array = []
	rg.resize(n)
	for i in n:
		var pa: int = padres[i]
		rg[i] = (reposo[i] as Transform3D) if pa < 0 else (rg[pa] as Transform3D) * (reposo[i] as Transform3D)
	var corr: Array = []
	for i in n:
		## Para el hueso i (destino), su fuente es par_de[i].
		var src: int = par_de[i]
		var reflejado: Basis = S * (rg[src] as Transform3D).basis.orthonormalized() * S
		corr.append(reflejado.inverse() * (rg[i] as Transform3D).basis.orthonormalized())
	var out := Animation.new()
	out.length = original.length
	out.loop_mode = original.loop_mode
	## Pistas de salida: todo hueso que tenga pista él o su par.
	var destinos := {}
	for i: int in pista_rot:
		destinos[i] = true
		destinos[par_de[i]] = true
	var pistas_out := {}
	for i: int in destinos:
		var t := out.add_track(Animation.TYPE_ROTATION_3D)
		out.track_set_path(t, NodePath("%s:%s" % [prefijo, esq.get_bone_name(i)]))
		pistas_out[i] = t
	var pos_out := {}
	for i: int in pista_pos:
		var d: int = par_de[i]
		var t2 := out.add_track(Animation.TYPE_POSITION_3D)
		out.track_set_path(t2, NodePath("%s:%s" % [prefijo, esq.get_bone_name(d)]))
		pos_out[d] = t2
	var paso := 1.0 / 30.0
	var tiempo := 0.0
	while tiempo <= original.length + 0.0001:
		## Pose global del original.
		var g: Array = []
		g.resize(n)
		for i in n:
			var loc: Transform3D = reposo[i]
			var q: Quaternion = original.rotation_track_interpolate(pista_rot[i], tiempo) if pista_rot.has(i) else loc.basis.get_rotation_quaternion()
			var o: Vector3 = original.position_track_interpolate(pista_pos[i], tiempo) if pista_pos.has(i) else loc.origin
			var tl := Transform3D(Basis(q), o)
			var pa: int = padres[i]
			g[i] = tl if pa < 0 else (g[pa] as Transform3D) * tl
		## Pose global espejada.
		var ge: Array = []
		ge.resize(n)
		for i in n:
			var src: int = par_de[i]
			var gs: Transform3D = g[src]
			ge[i] = Transform3D(S * gs.basis.orthonormalized() * S * (corr[i] as Basis), S * gs.origin)
		for i: int in pistas_out:
			var pa2: int = padres[i]
			var local: Transform3D = (ge[i] as Transform3D) if pa2 < 0 else (ge[pa2] as Transform3D).affine_inverse() * (ge[i] as Transform3D)
			out.rotation_track_insert_key(pistas_out[i], tiempo, local.basis.orthonormalized().get_rotation_quaternion())
		for i: int in pos_out:
			var pa3: int = padres[i]
			var local2: Transform3D = (ge[i] as Transform3D) if pa3 < 0 else (ge[pa3] as Transform3D).affine_inverse() * (ge[i] as Transform3D)
			out.position_track_insert_key(pos_out[i], tiempo, local2.origin)
		tiempo += paso
	if clave != "":
		_cache_espejo[cc] = out
	return out

## ------------------------------------------------------------ EXPRESIONES

const EXPRESIONES := {
	"aplaudir": "aplaudir", "protestar": "protestar", "brazos_jarra": "brazos_jarra",
	"cansado": "cansado", "besar_escudo": "besar_escudo", "pedir_balon": "pedir_balon",
	"saludar_publico": "saludar_publico", "pedir_calma": "pedir_calma", "manos_cabeza": "manos_cabeza",
	"cabeza_gacha": "cabeza_gacha", "mirar_cielo": "mirar_cielo", "senalar_adelante": "senalar_adelante",
	"senalar_cielo": "senalar_cielo", "silbar_dedos": "silbar_dedos",
}

## Los brazos que una expresión no mueve se quedan COLGANDO, relajados: si no
## tienen pista, conservan la pose del clip anterior (un brazo en alto de la
## carrera, o en cruz si no había nada).
static func _completar(a: Animation, esq: Skeleton3D, pre: String) -> void:
	for lado: String in ["i", "d"]:
		for parte: String in ["brazo_", "antebrazo_"]:
			var i := esq.find_bone(String(AnimQuaternius.HUESOS[parte + lado]))
			if i < 0:
				continue
			var ruta := NodePath("%s:%s" % [pre, esq.get_bone_name(i)])
			if a.find_track(ruta, Animation.TYPE_ROTATION_3D) == -1:
				var v := _brazo(lado, 2, 6) if parte == "brazo_" else _codo(lado, 8)
				_p(a, esq, parte + lado, [[0.0, v], [a.length, v]], pre)

static func _p(a: Animation, esq: Skeleton3D, c: String, k: Array, pre: String) -> void:
	AnimQuaternius._pista(a, esq, c, k, pre)

## EJES MEDIDOS CON LA SONDA (`pruebas/sonda_brazos.gd`, 26-9-2026), con el
## brazo en su "cero" (colgando al costado):
##   - brazo Z: abre hacia el costado (82 = horizontal, 160 = arriba); el
##     derecho con el signo contrario;
##   - brazo Y: adelante/atrás; los DOS van adelante con Y negativo (este eje
##     no está espejado entre lados, como la X de las piernas);
##   - antebrazo: el codo se dobla con Y negativo, en los dos lados;
##     X solo lo gira sobre su eje.
## `_adelante()` y `_codo()` traducen "cuánto adelante" y "cuánto dobla el
## codo" a esos signos, para no equivocarse de lado en cada expresión.
static func _brazo(lado: String, adelante: float, costado: float) -> Vector3:
	var s := 1.0 if lado == "i" else -1.0
	return Vector3(0, -adelante, costado * s)

static func _codo(lado: String, flex: float) -> Vector3:
	return Vector3(0, -flex, 0)

static func _brazos(a: Animation, esq: Skeleton3D, pre: String, lado: String, claves: Array) -> void:
	## claves: [[t, adelante, costado, codo]]
	var kb: Array = []
	var kc: Array = []
	for k: Array in claves:
		kb.append([k[0], _brazo(lado, float(k[1]), float(k[2]))])
		kc.append([k[0], _codo(lado, float(k[3]))])
	_p(a, esq, "brazo_" + lado, kb, pre)
	_p(a, esq, "antebrazo_" + lado, kc, pre)

## Aplaudir: brazos adelante, las manos se juntan y se separan.
static func aplaudir(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(0.5, true)
	for lado: String in ["i", "d"]:
		_brazos(a, esq, pre, lado, [[0.0, 55, 12, 50], [0.25, 55, 2, 62], [0.5, 55, 12, 50]])
	_p(a, esq, "cuello", [[0.0, Vector3(-6, 0, 0)], [0.5, Vector3(-6, 0, 0)]], pre)
	return a

## Protestar: brazos abiertos adelante con los codos flexionados, la cabeza que niega.
static func protestar(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(1.6, false)
	for lado: String in ["i", "d"]:
		_brazos(a, esq, pre, lado, [[0.0, 0, 6, 0], [0.35, 30, 45, 45], [1.2, 28, 42, 45], [1.6, 0, 6, 0]])
	_p(a, esq, "cuello", [[0.0, Vector3.ZERO], [0.4, Vector3(-8, 18, 0)], [0.7, Vector3(-8, -18, 0)], [1.0, Vector3(-8, 16, 0)], [1.6, Vector3.ZERO]], pre)
	_p(a, esq, "espalda2", [[0.0, Vector3.ZERO], [0.35, Vector3(-8, 0, 0)], [1.6, Vector3.ZERO]], pre)
	return a

## Brazos en jarra: manos a la cintura, codos afuera.
static func brazos_jarra(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(2.0, true)
	for lado: String in ["i", "d"]:
		_brazos(a, esq, pre, lado, [[0.0, -10, 40, 100], [2.0, -10, 40, 100]])
	_p(a, esq, "cuello", [[0.0, Vector3(4, 0, 0)], [1.0, Vector3(4, 12, 0)], [2.0, Vector3(4, 0, 0)]], pre)
	return a

## Cansado: se dobla y apoya las manos en las rodillas, respirando.
static func cansado(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(2.0, true)
	var cad := [[0.0, -0.1, -0.06], [1.0, -0.11, -0.06], [2.0, -0.1, -0.06]]
	var kc: Array = []
	for c: Array in cad:
		kc.append([c[0], Vector3(0, c[1], c[2])])
	AnimQuaternius._pista_pos(a, esq, "cadera", kc, pre, true)
	for lado: String in ["i", "d"]:
		AnimQuaternius._pierna_apoyada(a, esq, lado, cad, pre)
		_brazos(a, esq, pre, lado, [[0.0, 45, 10, 10], [2.0, 45, 10, 10]])
	_p(a, esq, "espalda1", [[0.0, Vector3(26, 0, 0)], [1.0, Vector3(30, 0, 0)], [2.0, Vector3(26, 0, 0)]], pre)
	_p(a, esq, "espalda2", [[0.0, Vector3(18, 0, 0)], [1.0, Vector3(21, 0, 0)], [2.0, Vector3(18, 0, 0)]], pre)
	_p(a, esq, "cuello", [[0.0, Vector3(-14, 0, 0)], [2.0, Vector3(-14, 0, 0)]], pre)
	return a

## Besar el escudo: la mano derecha al pecho y la cabeza que baja.
static func besar_escudo(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(2.0, false)
	_brazos(a, esq, pre, "d", [[0.0, 0, 6, 0], [0.5, 35, 10, 130], [1.6, 35, 10, 130], [2.0, 0, 6, 0]])
	_brazos(a, esq, pre, "i", [[0.0, 0, 6, 0], [0.6, 20, 55, 10], [2.0, 0, 6, 0]])
	_p(a, esq, "cuello", [[0.0, Vector3.ZERO], [0.6, Vector3(26, 0, 0)], [1.5, Vector3(26, 0, 0)], [2.0, Vector3.ZERO]], pre)
	return a

## Pedir el balón: brazo derecho arriba.
static func pedir_balon(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(1.2, false)
	_brazos(a, esq, pre, "d", [[0.0, 0, 6, 0], [0.25, 10, 160, 10], [0.9, 10, 155, 10], [1.2, 0, 6, 0]])
	_p(a, esq, "cuello", [[0.0, Vector3.ZERO], [0.3, Vector3(-10, 0, 0)], [1.2, Vector3.ZERO]], pre)
	return a

## Saludar al público: brazo arriba moviendo la mano.
static func saludar_publico(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(1.2, true)
	_brazos(a, esq, pre, "d", [[0.0, 10, 150, 20], [0.3, 10, 150, 45], [0.6, 10, 150, 20], [0.9, 10, 150, 45], [1.2, 10, 150, 20]])
	return a

## Pedir calma: manos abajo al frente, subiendo y bajando.
static func pedir_calma(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(1.0, true)
	for lado: String in ["i", "d"]:
		_brazos(a, esq, pre, lado, [[0.0, 35, 15, 35], [0.5, 25, 15, 25], [1.0, 35, 15, 35]])
	return a

## Manos a la cabeza: la ocasión que no fue.
static func manos_cabeza(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(2.0, false)
	for lado: String in ["i", "d"]:
		_brazos(a, esq, pre, lado, [[0.0, 0, 6, 0], [0.35, 30, 125, 120], [1.6, 30, 122, 120], [2.0, 0, 6, 0]])
	_p(a, esq, "cuello", [[0.0, Vector3.ZERO], [0.4, Vector3(-20, 0, 0)], [1.6, Vector3(-18, 0, 0)], [2.0, Vector3.ZERO]], pre)
	_p(a, esq, "espalda2", [[0.0, Vector3.ZERO], [0.4, Vector3(-10, 0, 0)], [2.0, Vector3.ZERO]], pre)
	return a

## Cabeza gacha, hombros caídos.
static func cabeza_gacha(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(2.0, true)
	_p(a, esq, "cuello", [[0.0, Vector3(34, 0, 0)], [1.0, Vector3(36, 6, 0)], [2.0, Vector3(34, 0, 0)]], pre)
	_p(a, esq, "espalda2", [[0.0, Vector3(12, 0, 0)], [2.0, Vector3(12, 0, 0)]], pre)
	for lado: String in ["i", "d"]:
		_brazos(a, esq, pre, lado, [[0.0, 4, 4, 8], [2.0, 4, 4, 8]])
	return a

## Mirar al cielo con los brazos abiertos.
static func mirar_cielo(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(2.0, false)
	_p(a, esq, "cuello", [[0.0, Vector3.ZERO], [0.5, Vector3(-38, 0, 0)], [1.6, Vector3(-36, 0, 0)], [2.0, Vector3.ZERO]], pre)
	_p(a, esq, "espalda2", [[0.0, Vector3.ZERO], [0.5, Vector3(-12, 0, 0)], [2.0, Vector3.ZERO]], pre)
	for lado: String in ["i", "d"]:
		_brazos(a, esq, pre, lado, [[0.0, 0, 6, 0], [0.5, 0, 60, 10], [1.6, 0, 58, 10], [2.0, 0, 6, 0]])
	return a

## Señalar adelante: "¡por ahí!".
static func senalar_adelante(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(1.4, false)
	_brazos(a, esq, pre, "d", [[0.0, 0, 6, 0], [0.3, 85, 8, 0], [1.1, 85, 8, 0], [1.4, 0, 6, 0]])
	_p(a, esq, "cuello", [[0.0, Vector3.ZERO], [0.3, Vector3(0, -10, 0)], [1.4, Vector3.ZERO]], pre)
	return a

## Señalar al cielo (la dedicatoria).
static func senalar_cielo(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(2.0, false)
	for lado: String in ["i", "d"]:
		_brazos(a, esq, pre, lado, [[0.0, 0, 6, 0], [0.4, 15, 165, 0], [1.6, 15, 162, 0], [2.0, 0, 6, 0]])
	_p(a, esq, "cuello", [[0.0, Vector3.ZERO], [0.4, Vector3(-30, 0, 0)], [1.6, Vector3(-28, 0, 0)], [2.0, Vector3.ZERO]], pre)
	return a

## Silbar con los dedos: la mano a la boca (el capitán llamando a alguien).
static func silbar_dedos(esq: Skeleton3D, pre: String) -> Animation:
	var a := AnimQuaternius._nueva(1.2, false)
	_brazos(a, esq, pre, "d", [[0.0, 0, 6, 0], [0.3, 50, 20, 140], [0.9, 50, 20, 140], [1.2, 0, 6, 0]])
	return a
