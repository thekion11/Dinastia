class_name PersonajeDT
extends RefCounted
## EL PERSONAJE DEL JUGADOR, EN 3D Y MODIFICABLE (26-9-2026). Pedido del
## usuario: *"ve por el modelo de nuestro personaje, el modificable"* (E19 del
## plan, B8 "creador estilo Los Sims", que estaba a medias: solo había un
## retrato 2D).
##
## Es el mismo cuerpo con esqueleto de los futbolistas (Quaternius, hombre o
## mujer) con:
##   - CUERPO por escalas de huesos: estatura, complexión, hombros, barriga,
##     largo de piernas y tamaño de cabeza. Cada hueso compensa la escala de su
##     padre para que "más barriga" no agrande también la cabeza y los brazos.
##   - PIEL, PELO (los cortes del pack), color de pelo y BARBA.
##   - ROPA: traje con camisa y corbata, chándal del club, polo, camisa,
##     sudadera o abrigo, cada uno con sus dos colores.
##   - ACCESORIOS: gafas (de ver o de sol), gorra, auriculares, bufanda del club
##     y reloj.
## El aspecto es un `Dictionary` plano que se guarda en `Roles.look["p3d"]`: el
## mismo sale en el creador, en la banda de cada partido y donde haga falta.

const BASE := {
	"cuerpo": "male", "altura": 1.78,
	"complexion": 0.0, "hombros": 0.0, "barriga": 0.0, "piernas": 0.0, "cabeza": 0.0,
	"piel": "c68d68", "pelo": "tupe", "color_pelo": "2a1c12", "barba": false,
	"ropa": "traje", "c_ropa": "1f2a44", "c_ropa2": "f2f2f2", "corbata": true,
	"gafas": "", "gorra": false, "auriculares": false, "bufanda": false, "reloj": true,
}
const PIELES := ["f3d2b8", "f1c7a5", "e0b08a", "c68d68", "a86b45", "8a5536", "6b4028", "4a2c1c"]
const COLORES_PELO := ["0e0b09", "2a1c12", "4a3020", "7a5230", "b08050", "d8b878", "9a9a9a", "e8e8e4", "8a2a12"]
const CORTES := ["corto", "fade", "tupe", "flequillo", "ondulado", "rizado", "afro", "largo", "melena",
	"coleta", "samurai", "rastas", "rapado", "calvo"]
## [clave, nombre]
const ROPAS := [["traje", "Traje"], ["chandal", "Chándal del club"], ["polo", "Polo"],
	["camisa", "Camisa"], ["sudadera", "Sudadera"], ["abrigo", "Abrigo largo"]]
const GAFAS := [["", "Sin gafas"], ["ver", "De ver"], ["sol", "De sol"]]

## El personaje del usuario y su club, para la banda de los partidos (lo fija
## `Principal._refrescar()`; la vista del estadio no tiene el mundo delante).
static var del_usuario: Dictionary = {}
static var club_usuario: String = ""

## El DT rival: siempre el mismo para el mismo club (sale de su id), de traje
## o chándal.
static func de_rival(club_id: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(club_id + "|dt")
	var a := aleatorio(rng)
	if not String(a["ropa"]) in ["traje", "chandal", "abrigo"]:
		a["ropa"] = "traje"
	a["gorra"] = false
	a["auriculares"] = false
	return a

## En la banda: mira a la cancha y alterna gestos de entrenador.
static func poner_en_banda(padre: Node3D, asp: Dictionary, c1: Color, c2: Color, pos: Vector3, giro: float) -> Dictionary:
	var d := crear(padre, asp, c1, c2)
	if d.is_empty():
		return d
	var n: Node3D = d["nodo"]
	n.position = pos
	n.rotation.y = giro
	var g := _GestosBanda.new()
	g.ap = d["anim"]
	g.rng.seed = hash(str(pos))
	n.add_child(g)
	return d

## EL PERSONAL DEL ESTADIO (26-9-2026, pendiente "camarógrafos y guardias con
## uniforme"): una persona entera con el uniforme de su oficio.
##   "prensa"    polo naranja de prensa con auriculares, junto a su cámara;
##   "seguridad" polo amarillo flúor de alta visibilidad y gorra, de espaldas
##               al campo mirando a la grada, como en cualquier estadio.
static func personal_estadio(padre: Node3D, rol: String, pos: Vector3, giro: float, semilla: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var asp := {"cuerpo": "female" if rng.randf() < 0.3 else "male", "altura": rng.randf_range(1.66, 1.90),
		"complexion": rng.randf_range(-0.2, 0.5), "barriga": rng.randf_range(0.0, 0.4),
		"piel": PIELES[rng.randi() % PIELES.size()], "pelo": CORTES[rng.randi() % 7],
		"color_pelo": COLORES_PELO[rng.randi() % 6], "barba": rng.randf() < 0.3,
		"corbata": false, "reloj": false, "gafas": ""}
	if rol == "seguridad":
		asp.merge({"ropa": "polo", "c_ropa": "d7f000", "c_ropa2": "1a1a1a", "gorra": true}, true)
	else:
		asp.merge({"ropa": "polo", "c_ropa": "e07b16", "c_ropa2": "23262b", "auriculares": true, "gorra": rng.randf() < 0.4}, true)
	var d := crear(padre, asp)
	if d.is_empty():
		return d
	var n: Node3D = d["nodo"]
	n.position = pos
	n.rotation.y = giro
	var ap: AnimationPlayer = d["anim"]
	var g := "brazos_jarra" if rol == "seguridad" and rng.randf() < 0.5 and ap.has_animation("brazos_jarra") else "parado"
	if ap.has_animation(g):
		ap.play(g)
		ap.seek(rng.randf() * ap.current_animation_length, true)
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return d

class _GestosBanda extends Node:
	const GESTOS := ["brazos_jarra", "aplaudir", "pedir_calma", "protestar", "manos_cabeza", "senalar", "llamar_hinchada"]
	var ap: AnimationPlayer
	var rng := RandomNumberGenerator.new()
	var hasta := 2.0
	func _process(delta: float) -> void:
		hasta -= minf(delta, 0.1)
		if hasta > 0.0 or ap == null:
			return
		## Casi siempre quieto mirando; de vez en cuando, un gesto.
		if rng.randf() < 0.55 or not ap.has_animation("parado"):
			var hay: Array[String] = []
			for g: String in GESTOS:
				if ap.has_animation(g):
					hay.append(g)
			if not hay.is_empty():
				ap.play(hay[rng.randi() % hay.size()], 0.3)
				hasta = maxf(ap.current_animation_length, 1.5)
				return
		ap.play("parado", 0.3)
		hasta = rng.randf_range(3.0, 7.0)

## El aspecto completo: lo guardado encima de la base.
static func aspecto(guardado: Dictionary) -> Dictionary:
	var a := BASE.duplicate()
	for k: String in guardado:
		a[k] = guardado[k]
	return a

## Uno al azar (para "Aleatorio" y para el DT rival).
static func aleatorio(rng: RandomNumberGenerator) -> Dictionary:
	var a := BASE.duplicate()
	var mujer := rng.randf() < 0.25
	a["cuerpo"] = "female" if mujer else "male"
	a["altura"] = snappedf(rng.randf_range(1.60, 1.74) if mujer else rng.randf_range(1.68, 1.95), 0.01)
	for k: String in ["complexion", "hombros", "barriga", "piernas", "cabeza"]:
		a[k] = snappedf(clampf(rng.randfn(0.0, 0.4), -1.0, 1.0), 0.05)
	a["piel"] = PIELES[rng.randi() % PIELES.size()]
	a["color_pelo"] = COLORES_PELO[rng.randi() % COLORES_PELO.size()]
	a["pelo"] = CORTES[rng.randi() % CORTES.size()]
	a["barba"] = not mujer and rng.randf() < 0.4
	var r: Array = ROPAS[rng.randi() % ROPAS.size()]
	a["ropa"] = r[0]
	a["c_ropa"] = ["1f2a44", "111111", "3a3a3a", "5a4636", "2e3f2a", "6a1b2a", "20354d"][rng.randi() % 7]
	a["c_ropa2"] = ["f2f2f2", "cfe0f5", "e8e0d0", "ffffff", "d9d9d9"][rng.randi() % 5]
	a["corbata"] = rng.randf() < 0.6
	a["gafas"] = String(GAFAS[rng.randi() % GAFAS.size()][0]) if rng.randf() < 0.4 else ""
	a["gorra"] = rng.randf() < 0.1
	a["bufanda"] = rng.randf() < 0.2
	a["reloj"] = rng.randf() < 0.6
	a["auriculares"] = false
	return a

## Crea el personaje dentro de `padre` (que ya debe estar en el árbol) y lo
## devuelve (el `Dictionary` de `FutbolistaQ` con "nodo", "anim", ...).
## `c1`/`c2`: colores del club, para el chándal y la bufanda.
static func crear(padre: Node3D, asp_guardado: Dictionary, c1: Color = Color("1f5fa8"), c2: Color = Color.WHITE) -> Dictionary:
	var a := aspecto(asp_guardado)
	var d := FutbolistaQ.crear(float(a["altura"]), String(a["cuerpo"]))
	if d.is_empty():
		return d
	padre.add_child(d["nodo"])
	FutbolistaQ.terminar(d, false)
	_cuerpo(d, a)
	_vestir(d, a, c1, c2)
	var corte := String(a["pelo"])
	## Con gorra, el pelo queda debajo: solo asoma lo corto. Antes se
	## libraban el rizado, el ondulado o el tupé, que con su volumen asomaban
	## por encima de la copa y dejaban la visera flotando (28-9-2026).
	if bool(a["gorra"]) and not corte in ["corto", "fade", "rapado", "calvo"]:
		corte = "corto"
	PeloQ.poner(d, corte, Color(String(a["color_pelo"])), bool(a["barba"]) and String(a["cuerpo"]) == "male")
	_accesorios(d, a, c1, c2)
	var ap: AnimationPlayer = d["anim"]
	if ap.has_animation("parado"):
		ap.play("parado")
	return d

# -----------------------------------------------------------------------------
#  EL CUERPO: ESCALAS DE HUESOS
# -----------------------------------------------------------------------------

## La escala que cada hueso debería tener EN EL MUNDO (ejes del modelo: x de
## lado, y arriba, z hacia delante). Lo que no aparece, 1.
static func _objetivos(a: Dictionary) -> Dictionary:
	var c: float = a["complexion"]
	var h: float = a["hombros"]
	var b: float = a["barriga"]
	var p: float = a["piernas"]
	var k: float = a["cabeza"]
	var o := {}
	o["pelvis"] = Vector3(1.0 + 0.10 * c + 0.06 * b, 1.0, 1.0 + 0.10 * c + 0.05 * b)
	o["spine_01"] = Vector3(1.0 + 0.14 * c + 0.12 * b, 1.0, 1.0 + 0.12 * c + 0.38 * b)
	o["spine_02"] = Vector3(1.0 + 0.16 * c + 0.06 * b, 1.0, 1.0 + 0.14 * c + 0.16 * b)
	o["spine_03"] = Vector3(1.0 + 0.16 * c + 0.10 * h, 1.0, 1.0 + 0.14 * c)
	o["neck_01"] = Vector3(1.0 + 0.16 * c, 1.0, 1.0 + 0.16 * c)
	o["Head"] = Vector3.ONE * (1.0 + 0.12 * k)
	for s: String in ["_l", "_r"]:
		o["clavicle" + s] = Vector3(1.0 + 0.32 * h, 1.0 + 0.08 * c, 1.0 + 0.08 * c)
		o["upperarm" + s] = Vector3(1.0, 1.0 + 0.22 * c, 1.0 + 0.22 * c)
		o["lowerarm" + s] = Vector3(1.0, 1.0 + 0.18 * c, 1.0 + 0.18 * c)
		o["thigh" + s] = Vector3(1.0 + 0.18 * c + 0.04 * b, 1.0 + 0.08 * p, 1.0 + 0.18 * c)
		o["calf" + s] = Vector3(1.0 + 0.14 * c, 1.0 + 0.08 * p, 1.0 + 0.14 * c)
	return o

static func _cuerpo(d: Dictionary, a: Dictionary) -> void:
	var esq: Skeleton3D = d["esqueleto"]
	var obj := _objetivos(a)
	## La escala acumulada en el mundo de cada hueso, para compensar la del
	## padre en el hijo (los huesos van casi alineados a los ejes en la pose de
	## reposo, en T: basta con ver a qué eje del mundo apunta cada eje local).
	var mundo := {}
	for i in esq.get_bone_count():
		var nombre := esq.get_bone_name(i)
		var padre := esq.get_bone_parent(i)
		var del_padre: Vector3 = mundo.get(padre, Vector3.ONE)
		var quiero: Vector3 = obj.get(nombre, Vector3.ONE)
		mundo[i] = quiero
		var razon := quiero / del_padre
		var base := esq.get_bone_global_rest(i).basis
		var local := Vector3.ONE
		for eje in 3:
			var v := base[eje].abs()
			var mayor := 0 if v.x >= v.y and v.x >= v.z else (1 if v.y >= v.z else 2)
			local[eje] = razon[mayor]
		if not local.is_equal_approx(Vector3.ONE):
			esq.set_bone_pose_scale(i, local)
	## Con piernas más largas, los pies quedarían bajo el suelo.
	var modelo: Node3D = d["modelo"]
	modelo.position.y = 0.9 * 0.08 * float(a["piernas"]) * modelo.scale.y
	## Las animaciones pueden reponer la pose: se vuelve a aplicar al final de
	## cada fotograma (un nodo que corre después del AnimationPlayer).
	var guardian := _Escalas.new()
	guardian.esq = esq
	guardian.escalas = {}
	for i in esq.get_bone_count():
		var s := esq.get_bone_pose_scale(i)
		if not s.is_equal_approx(Vector3.ONE):
			guardian.escalas[i] = s
	guardian.process_priority = 100
	(d["nodo"] as Node3D).add_child(guardian)

class _Escalas extends Node:
	var esq: Skeleton3D
	var escalas: Dictionary
	func _process(_d: float) -> void:
		if esq == null:
			return
		for i: int in escalas:
			esq.set_bone_pose_scale(i, escalas[i])

# -----------------------------------------------------------------------------
#  LA ROPA
# -----------------------------------------------------------------------------

static func _vestir(d: Dictionary, a: Dictionary, c1: Color, c2: Color) -> void:
	var piel := Color(String(a["piel"]))
	var pelo := Color(String(a["color_pelo"]))
	var r1 := Color(String(a["c_ropa"]))
	var r2 := Color(String(a["c_ropa2"]))
	var zapato := "111111"
	var dis := "liso"
	var cols := [r1, r1, r2, r2, r1]
	var pant := r1
	var cuello := 1
	var pant_dis := "liso"
	var pant_c2 := r1
	match String(a["ropa"]):
		"traje":
			## Chaqueta y pantalón del mismo paño; la camisa va en la pechera.
			cuello = 0
		"chandal":
			dis = "mangas_contraste"
			cols = [c1, c2, c2, c1, c2]
			pant = c1.darkened(0.25)
			pant_dis = "lateral"
			pant_c2 = c2
			zapato = "f2f2f2"
			cuello = 3
		"polo":
			cols = [r1, r1, r2, r2, r1]
			pant = Color("c2b280") if r1.get_luminance() < 0.5 else Color("2b2f3a")
			cuello = 2
			zapato = "5a4636"
		"camisa":
			dis = "cuadros_chicos"
			cols = [r2, r2.darkened(0.35), r1, r1, r2]
			pant = r1
			cuello = 2
			zapato = "5a4636"
		"sudadera":
			dis = "canesu"
			cols = [r1, r2, r2, r1, r2]
			pant = Color("2b2f3a")
			zapato = "f2f2f2"
			cuello = 1
		"abrigo":
			cuello = 3
	var kit := {
		"dis": dis,
		"cols": cols.map(func(c: Color) -> String: return c.to_html(false)),
		"trim": 2, "cuello": cuello,
		"pant": {"dis": pant_dis, "c1": pant.to_html(false), "c2": pant_c2.to_html(false)},
		"med": {"dis": "lisas", "c1": pant.darkened(0.2).to_html(false), "c2": pant.to_html(false)},
		"bot": {"mod": "clasico", "c1": zapato, "c2": zapato, "c3": "222222"},
		"acc": {}, "civil": true,
	}
	var antes := VestidorQ.ropa_aparte
	VestidorQ.ropa_aparte = false
	VestidorQ.vestir_equipacion(d, cols[0], cols[1], "liso", piel, pelo, pant, pant, true, kit, 0)
	VestidorQ.ropa_aparte = antes

	var esq: Skeleton3D = d["esqueleto"]
	var ropa := String(a["ropa"])
	var mujer := String(a["cuerpo"]) == "female"
	var pecho_y := 1.36 if not mujer else 1.31
	var pecho_z := 0.125 if not mujer else 0.13
	## Traje: la camisa la pinta el shader (cuello en V con el color de
	## ribete); aquí solo va la corbata, fina y pegada al pecho.
	if (ropa == "traje" or ropa == "abrigo") and bool(a["corbata"]):
		var torso := _pegar(esq, "spine_03")
		var corb := _mat(c1 if ropa == "traje" else r1.darkened(0.4), 0.45)
		_caja(torso, Vector3(0, pecho_y + 0.1, pecho_z - 0.008), Vector3(0.028, 0.026, 0.016), corb)
		var larga := _caja(torso, Vector3(0, pecho_y - 0.02, pecho_z + 0.012), Vector3(0.036, 0.2, 0.006), corb)
		larga.rotation_degrees.x = -14.0
	## El abrigo: faldón hasta la rodilla.
	if ropa == "abrigo":
		var cadera := _pegar(esq, "pelvis")
		var paño := _mat(r1, 0.85)
		for s in [-1.0, 1.0]:
			var f := _caja(cadera, Vector3(0.1 * s, 0.72, 0.02), Vector3(0.19, 0.46, 0.25), paño)
			f.rotation_degrees.z = 4.0 * s

# -----------------------------------------------------------------------------
#  ACCESORIOS
# -----------------------------------------------------------------------------

static func _accesorios(d: Dictionary, a: Dictionary, c1: Color, c2: Color) -> void:
	var esq: Skeleton3D = d["esqueleto"]
	var mujer := String(a["cuerpo"]) == "female"
	## El centro de la cabeza (en el modelo) y los ojos.
	var cab_y := 1.69 if not mujer else 1.635
	var ojo_y := cab_y - 0.005
	var ojo_z := 0.095 if not mujer else 0.09
	var cabeza := _pegar(esq, "Head")
	var gafas := String(a["gafas"])
	if gafas != "":
		var marco := _mat(Color(0.06, 0.06, 0.07), 0.3)
		for s in [-1.0, 1.0]:
			var aro := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = 0.018
			tm.outer_radius = 0.023
			tm.rings = 16
			aro.mesh = tm
			aro.material_override = marco
			aro.position = Vector3(0.034 * s, ojo_y, ojo_z)
			aro.rotation_degrees.x = 90.0
			cabeza.add_child(aro)
			var lente := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.019
			cm.bottom_radius = 0.019
			cm.height = 0.002
			lente.mesh = cm
			lente.material_override = _mat(Color(0.05, 0.05, 0.07, 0.9), 0.1, 0.9) if gafas == "sol" else _mat(Color(0.8, 0.9, 1.0, 0.18), 0.05, 0.18)
			lente.position = aro.position
			lente.rotation_degrees.x = 90.0
			cabeza.add_child(lente)
			## Patillas hacia las orejas.
			var pat := _caja(cabeza, Vector3(0.068 * s, ojo_y + 0.004, ojo_z - 0.05), Vector3(0.004, 0.004, 0.1), marco)
			pat.rotation_degrees.y = 6.0 * s
		_caja(cabeza, Vector3(0, ojo_y + 0.004, ojo_z + 0.002), Vector3(0.02, 0.004, 0.004), marco)
	if bool(a["gorra"]):
		var tela := _mat(c1, 0.8)
		## La copa: más ancha que el pelo corto (no asoma por arriba) y con el
		## borde a la altura de la frente, no de los ojos.
		## `cab_y` es la altura de los OJOS: el borde de la copa va 4-5 cm más
		## arriba (sobre la frente) y la visera sale de ahí.
		var copa := _esfera(cabeza, Vector3(0, cab_y + 0.1, -0.012), 0.108, tela)
		copa.scale = Vector3(1.0, 0.62, 1.1)
		var visera := _caja(cabeza, Vector3(0, cab_y + 0.052, 0.118), Vector3(0.165, 0.01, 0.085), _mat(c1.darkened(0.2), 0.7))
		visera.rotation_degrees.x = 10.0
		_esfera(cabeza, Vector3(0, cab_y + 0.166, -0.012), 0.011, _mat(c2, 0.7))
	if bool(a["auriculares"]):
		var neg := _mat(Color(0.1, 0.1, 0.11), 0.4)
		var arco := MeshInstance3D.new()
		var tm2 := TorusMesh.new()
		tm2.inner_radius = 0.105
		tm2.outer_radius = 0.118
		arco.mesh = tm2
		arco.material_override = neg
		arco.position = Vector3(0, cab_y + 0.0, -0.01)
		arco.rotation_degrees.z = 90.0
		arco.scale = Vector3(1.0, 1.0, 0.9)
		cabeza.add_child(arco)
		for s in [-1.0, 1.0]:
			var copa2 := MeshInstance3D.new()
			var cm2 := CylinderMesh.new()
			cm2.top_radius = 0.04
			cm2.bottom_radius = 0.04
			cm2.height = 0.03
			copa2.mesh = cm2
			copa2.material_override = neg
			copa2.position = Vector3(0.1 * s, cab_y - 0.025, -0.01)
			copa2.rotation_degrees.z = 90.0
			cabeza.add_child(copa2)
	if bool(a["bufanda"]):
		var cuello := _pegar(esq, "neck_01")
		var lana1 := _mat(c1, 0.95)
		var lana2 := _mat(c2, 0.95)
		var cy := 1.5 if not mujer else 1.455
		for i in 3:
			var anillo := MeshInstance3D.new()
			var tm3 := TorusMesh.new()
			tm3.inner_radius = 0.05
			tm3.outer_radius = 0.085
			anillo.mesh = tm3
			anillo.material_override = lana1 if i % 2 == 0 else lana2
			anillo.position = Vector3(0, cy + 0.012 * i, -0.02)
			cuello.add_child(anillo)
		## Las dos puntas colgando por delante.
		for s in [-1.0, 1.0]:
			var punta := _caja(cuello, Vector3(0.045 * s, cy - 0.15, 0.1), Vector3(0.06, 0.26, 0.018), lana1 if s < 0.0 else lana2)
			punta.rotation_degrees.z = 5.0 * s
	if bool(a["reloj"]):
		var brazo := _pegar(esq, "lowerarm_l")
		var x := 0.66 if not mujer else 0.595
		var yb := 1.455 if not mujer else 1.418
		var correa := MeshInstance3D.new()
		var tm4 := TorusMesh.new()
		tm4.inner_radius = 0.026
		tm4.outer_radius = 0.034
		correa.mesh = tm4
		correa.material_override = _mat(Color(0.12, 0.1, 0.09), 0.5)
		correa.position = Vector3(x, yb, -0.07)
		correa.rotation_degrees.z = 90.0
		brazo.add_child(correa)
		var esfera := MeshInstance3D.new()
		var cm3 := CylinderMesh.new()
		cm3.top_radius = 0.018
		cm3.bottom_radius = 0.018
		cm3.height = 0.008
		esfera.mesh = cm3
		var metal := _mat(Color(0.85, 0.8, 0.6), 0.25)
		metal.metallic = 0.9
		esfera.material_override = metal
		esfera.position = Vector3(x, yb + 0.032, -0.07)
		brazo.add_child(esfera)

# -----------------------------------------------------------------------------
#  PIEZAS
# -----------------------------------------------------------------------------

## Un nodo que sigue al hueso y dentro del cual las medidas son las del MODELO
## en reposo (en T, en metros): se coloca todo como si el personaje estuviera
## quieto con los brazos abiertos, y después sigue a su hueso.
static func _pegar(esq: Skeleton3D, hueso: String) -> Node3D:
	var i := esq.find_bone(hueso)
	var ba := BoneAttachment3D.new()
	ba.bone_name = hueso
	esq.add_child(ba)
	var n := Node3D.new()
	n.transform = esq.get_bone_global_rest(i).affine_inverse() if i >= 0 else Transform3D.IDENTITY
	ba.add_child(n)
	return n

static func _mat(c: Color, rug: float, alfa: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c, alfa)
	m.roughness = rug
	if alfa < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

static func _caja(padre: Node3D, pos: Vector3, tam: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	mi.mesh = b
	mi.material_override = m
	mi.position = pos
	padre.add_child(mi)
	return mi

static func _esfera(padre: Node3D, pos: Vector3, r: float, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	mi.mesh = s
	mi.material_override = m
	mi.position = pos
	padre.add_child(mi)
	return mi
