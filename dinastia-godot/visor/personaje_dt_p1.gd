extends RefCounted
## [Capa 1/2 de `personaje_dt.gd`] aleatorio, de_rival, aspecto, _objetivos, _cuerpo, _pegar … (+7)

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
	## Biblioteca modular (5-10-2026): "cara" = número de cara del tono de piel
	## (-1 = la clásica); "corte_med" = un corte medido ("" = el peinado).
	"cara": -1, "corte_med": "",
	"ropa": "traje", "c_ropa": "1f2a44", "c_ropa2": "f2f2f2", "corbata": true,
	"gafas": "", "gorra": false, "auriculares": false, "bufanda": false, "reloj": true,
	## 13-10-2026: más personalización.
	"ojos": "3d2a1a", "pendiente": false, "cadena": false,
	"manga_corta": false, "tatuaje": 0,
}
const PIELES := ["f6dccb", "f3d2b8", "f1c7a5", "e8bc96", "e0b08a", "d29f78", "c68d68", "b57a55",
	"a86b45", "8a5536", "7a4a2e", "6b4028", "4a2c1c", "3a2216"]
## Color de iris: castaño oscuro, castaño, avellana, verde, gris, azul, negro.
const OJOS := ["3d2a1a", "5a3a22", "7a5a2a", "4a6a3a", "6a7480", "3f6a9a", "181210"]
const COLORES_PELO := ["0e0b09", "2a1c12", "4a3020", "7a5230", "b08050", "d8b878", "9a9a9a", "e8e8e4", "8a2a12"]
const CORTES := ["corto", "fade", "tupe", "flequillo", "ondulado", "rizado", "afro", "largo", "melena",
	"coleta", "samurai", "rastas", "rapado", "calvo"]
## [clave, nombre]
const ROPAS := [["traje", "Traje"], ["chandal", "Chándal del club"], ["polo", "Polo"],
	["camisa", "Camisa"], ["sudadera", "Sudadera"], ["abrigo", "Abrigo largo"],
	["cuero", "Chaqueta de cuero"], ["rayas", "Camisa a rayas"], ["vaqueros", "Jersey y vaqueros"]]
const TATUAJES := [[0, "Sin tatuaje"], [1, "Antebrazo"], [2, "Los dos antebrazos"], [3, "Brazo entero"]]
const GAFAS := [["", "Sin gafas"], ["ver", "De ver"], ["sol", "De sol"], ["redondas", "Redondas"], ["deportivas", "Deportivas"]]

## El personaje del usuario y su club, para la banda de los partidos (lo fija
## `Principal._refrescar()`; la vista del estadio no tiene el mundo delante).
## Si el DT del usuario está sancionado (ve el partido desde la grada).
static var sancionado := false
static var del_usuario: Dictionary = {}
static var club_usuario: String = ""

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

## Un material de ojos por par piel/iris, compartido (peatones incluidos).
## `Expresion` hace su copia propia cuando alguien gesticula.
static var _mats_ojos := {}

const BASE_ESBELTA := {
	"spine_02": Vector3(0.95, 1.0, 0.93), "spine_03": Vector3(0.92, 1.0, 0.9),
	"neck_01": Vector3(0.86, 1.0, 0.86),
	"clavicle_l": Vector3(0.93, 0.9, 0.9), "clavicle_r": Vector3(0.93, 0.9, 0.9),
	"upperarm_l": Vector3(1.0, 0.84, 0.84), "upperarm_r": Vector3(1.0, 0.84, 0.84),
	"lowerarm_l": Vector3(1.0, 0.88, 0.88), "lowerarm_r": Vector3(1.0, 0.88, 0.88),
	"thigh_l": Vector3(0.92, 1.0, 0.92), "thigh_r": Vector3(0.92, 1.0, 0.92),
	"calf_l": Vector3(0.94, 1.0, 0.94), "calf_r": Vector3(0.94, 1.0, 0.94),
}

const ASPECTO_NEUTRO := {"complexion": 0.0, "hombros": 0.0, "barriga": 0.0, "piernas": 0.0, "cabeza": 0.0}

class _Escalas extends Node:
	var esq: Skeleton3D
	var escalas: Dictionary
	func _process(_d: float) -> void:
		if esq == null:
			return
		for i: int in escalas:
			esq.set_bone_pose_scale(i, escalas[i])

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
	a["ojos"] = OJOS[rng.randi() % OJOS.size()]
	a["pendiente"] = rng.randf() < 0.12
	a["cadena"] = rng.randf() < 0.1
	a["manga_corta"] = rng.randf() < 0.3
	a["tatuaje"] = 0 if rng.randf() < 0.85 else 1 + rng.randi() % 3
	a["auriculares"] = false
	return a

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

## El aspecto completo: lo guardado encima de la base.
static func aspecto(guardado: Dictionary) -> Dictionary:
	var a := BASE.duplicate()
	for k: String in guardado:
		a[k] = guardado[k]
	return a

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
	## MENOS MÚSCULO (13-10-2026): el modelo base es de culturista. Una base más
	## esbelta (brazos, pecho, cuello y muslos) y encima la complexión elegida.
	for nombre: String in BASE_ESBELTA:
		o[nombre] = (o.get(nombre, Vector3.ONE) as Vector3) * (BASE_ESBELTA[nombre] as Vector3)
	return o

static func _cuerpo(d: Dictionary, a: Dictionary, con_guardian := true) -> void:
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
	## cada fotograma (un nodo que corre después del AnimationPlayer). Medido el
	## 13-10-2026: caminar y parado NO tocan la escala; los peatones van sin él.
	if not con_guardian:
		return
	var guardian := _Escalas.new()
	guardian.esq = esq
	guardian.escalas = {}
	for i in esq.get_bone_count():
		var s := esq.get_bone_pose_scale(i)
		if not s.is_equal_approx(Vector3.ONE):
			guardian.escalas[i] = s
	guardian.process_priority = 100
	(d["nodo"] as Node3D).add_child(guardian)

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
		"cuero":
			## Cuero oscuro (si eliges un color claro, se oscurece) y vaqueros.
			var cuero := r1 if r1.get_luminance() < 0.35 else r1.darkened(0.55)
			cols = [cuero, cuero, cuero.lightened(0.08), cuero, cuero]
			pant = Color("2f4a6b")
			cuello = 3
			zapato = "3e2723"
		"rayas":
			## Rayas anchas y suaves (13-10-2026): las finas, sobre la forma del
			## pecho, se torcían y daban muaré.
			dis = "franjas"
			cols = [r2, r2.lerp(r1, 0.45), r1, r1, r2]
			pant = Color("2b2f3a") if r1.get_luminance() > 0.3 else Color("c2b280")
			cuello = 2
			zapato = "5a4636"
		"vaqueros":
			cols = [r1, r1, r1.darkened(0.2), r1, r1]
			pant = Color("3b5b82")
			cuello = 1
			zapato = "f2f2f2"
	var kit := {
		"dis": dis,
		"cols": cols.map(func(c: Color) -> String: return c.to_html(false)),
		"trim": 2, "cuello": cuello,
		"pant": {"dis": pant_dis, "c1": pant.to_html(false), "c2": pant_c2.to_html(false)},
		"med": {"dis": "lisas", "c1": pant.darkened(0.2).to_html(false), "c2": pant.to_html(false)},
		"bot": {"mod": "clasico", "c1": zapato, "c2": zapato, "c3": "222222"},
		"acc": {}, "civil": true,
		"manga_corta": bool(a.get("manga_corta", false)) and String(a["ropa"]) in ["polo", "camisa", "rayas", "vaqueros"],
		"tatuaje": int(a.get("tatuaje", 0)),
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
	## La chaqueta de cuero: cremallera metálica en el centro del pecho.
	if ropa == "cuero":
		var torso_c := _pegar(esq, "spine_03")
		var metal := _mat(Color(0.75, 0.75, 0.78), 0.3)
		_caja(torso_c, Vector3(0.012, pecho_y - 0.05, pecho_z + 0.004), Vector3(0.008, 0.34, 0.006), metal)
	## El abrigo: faldón hasta la rodilla.
	if ropa == "abrigo":
		var cadera := _pegar(esq, "pelvis")
		var paño := _mat(r1, 0.85)
		for s in [-1.0, 1.0]:
			var f := _caja(cadera, Vector3(0.1 * s, 0.72, 0.02), Vector3(0.19, 0.46, 0.25), paño)
			f.rotation_degrees.z = 4.0 * s

## Una cara de la biblioteca modular (mezcla de varias, nunca la de un jugador)
## y, si se eligió, un corte medido. Con gorra no va el corte medido.
static func _cara_biblioteca(d: Dictionary, a: Dictionary) -> void:
	var i := int(a.get("cara", -1))
	## (Las mezclas salen de futbolistas hombres: en un cuerpo de mujer
	## quedaban masculinas. Ahí va la cara clásica.)
	if i < 0 or not BibliotecaCaras.hay() or String(a["cuerpo"]) == "female":
		return
	var piel := Color(String(a["piel"]))
	var clave := BibliotecaCaras.cara_de_tono(piel, i)
	if clave == "":
		return
	var corte := "" if bool(a["gorra"]) else String(a.get("corte_med", ""))
	VestidorQ.poner_cara(d, {"look": {}, "foto": "",
		"biblio": {"cara": clave, "pelo": corte, "color_pelo": "#" + String(a["color_pelo"])}}, piel)
static func material_ojos(piel: Color, iris: Color, mujer := false) -> ShaderMaterial:
	var k := piel.to_html(false) + iris.to_html(false) + ("m" if mujer else "")
	if _mats_ojos.has(k):
		return _mats_ojos[k]
	var mo := ShaderMaterial.new()
	mo.shader = load(Expresion.SHADER_OJOS)
	mo.set_shader_parameter("iris", iris)
	mo.set_shader_parameter("piel", piel)
	## Los ojos del cuerpo de mujer están más abajo (medido en su malla: ±0,0345
	## y 1,6559). Con los del hombre, los párpados le tapaban el ojo entero.
	if mujer:
		mo.set_shader_parameter("centro_neg", Vector2(-0.0345, 1.6559))
		mo.set_shader_parameter("centro_pos", Vector2(0.0345, 1.6559))
	_mats_ojos[k] = mo
	return mo

## OJOS DE VERDAD también con la cara clásica (13-10-2026): eran ranuras
## blancas. El shader de ojos (iris, párpados de su piel) y, con él, el
## parpadeo y las expresiones (`Expresion`).
static func _ojos_vivos(d: Dictionary, piel: Color, iris := Color(0.24, 0.16, 0.1), propio := true) -> void:
	for mi: MeshInstance3D in (d["nodo"] as Node).find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var base := mi.mesh.surface_get_material(s)
			var actual := mi.get_surface_override_material(s)
			if base == null or base.resource_name != VestidorQ.MATERIAL_OJOS:
				continue
			if actual is ShaderMaterial and not propio:
				continue
			if actual is ShaderMaterial:
				## Cara de biblioteca: ya tiene el shader (compartido); uno propio con tu iris.
				var copia := (actual as ShaderMaterial).duplicate() as ShaderMaterial
				copia.set_shader_parameter("iris", iris)
				mi.set_surface_override_material(s, copia)
				continue
			VestidorQ._con_reposo_simple(mi)
			var mujer := (d["nodo"] as Node).find_child("Superhero_Female", true, false) != null
			mi.set_surface_override_material(s, material_ojos(piel, iris, mujer))

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
