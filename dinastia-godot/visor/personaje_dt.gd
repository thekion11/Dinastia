class_name PersonajeDT
extends "res://visor/personaje_dt_p1.gd"
## [Capa 2/2 de `personaje_dt.gd`] _accesorios, crear, poner_en_banda, personal_estadio, adelgazar, aspecto_futbolista … (+1)

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
	if gafas == "deportivas":
		## Lente envolvente espejada en dos mitades que siguen la curva de la cara.
		var espejo := _mat(Color(0.05, 0.07, 0.1, 0.94), 0.05, 0.94)
		espejo.metallic = 0.6
		for s2 in [-1.0, 1.0]:
			var mitad := _caja(cabeza, Vector3(0.03 * s2, ojo_y + 0.002, ojo_z + 0.002), Vector3(0.062, 0.027, 0.005), espejo)
			mitad.rotation_degrees.y = -14.0 * s2
			mitad.rotation_degrees.z = 4.0 * s2
			_caja(cabeza, Vector3(0.066 * s2, ojo_y + 0.006, ojo_z - 0.05), Vector3(0.005, 0.006, 0.1), _mat(Color(0.08, 0.08, 0.09), 0.3))
		_caja(cabeza, Vector3(0, ojo_y + 0.016, ojo_z + 0.006), Vector3(0.12, 0.005, 0.006), _mat(Color(0.08, 0.08, 0.09), 0.3))
	elif gafas != "":
		var marco := _mat(Color(0.06, 0.06, 0.07), 0.3)
		for s in [-1.0, 1.0]:
			var aro := MeshInstance3D.new()
			var tm := TorusMesh.new()
			var rg := 1.18 if gafas == "redondas" else 1.0
			tm.inner_radius = 0.018 * rg
			tm.outer_radius = 0.0215 * rg if gafas == "redondas" else 0.023
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
	if bool(a.get("pendiente", false)):
		var oro := _mat(Color(0.95, 0.8, 0.4), 0.2)
		oro.metallic = 0.35
		oro.emission_enabled = true
		oro.emission = Color(0.35, 0.27, 0.1)
		for s3 in [-1.0, 1.0]:
			_esfera(cabeza, Vector3(0.078 * s3, ojo_y - 0.045, -0.005), 0.0055, oro)
	if bool(a.get("cadena", false)):
		var cuello_c := _pegar(esq, "neck_01")
		var plata := _mat(Color(0.85, 0.85, 0.88), 0.25)
		plata.metallic = 0.35
		var cad := MeshInstance3D.new()
		var tmc := TorusMesh.new()
		tmc.inner_radius = 0.074
		tmc.outer_radius = 0.079
		tmc.rings = 24
		cad.mesh = tmc
		cad.material_override = plata
		cad.position = Vector3(0, (1.455 if not mujer else 1.415), 0.045)
		cad.rotation_degrees.x = 38.0
		cad.scale = Vector3(1.0, 1.0, 0.85)
		cuello_c.add_child(cad)
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
	_cara_biblioteca(d, a)
	_ojos_vivos(d, Color(String(a["piel"])), Color(String(a.get("ojos", "3d2a1a"))))
	_accesorios(d, a, c1, c2)
	var ap: AnimationPlayer = d["anim"]
	if ap.has_animation("parado"):
		ap.play("parado")
	return d

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

## Solo la base esbelta, para futbolistas y demás gente con el mismo modelo
## (13-10-2026). Usa el mismo guardián que el personaje del jugador.
static func adelgazar(d: Dictionary, con_guardian := true) -> void:
	if not d.has("esqueleto") or not d.has("modelo"):
		return
	_cuerpo(d, ASPECTO_NEUTRO, con_guardian)

## CADA FUTBOLISTA CON SU CUERPO (21-10-2026, M-081): antes compartían todos el
## mismo. La complexión y los hombros salen de su FÍSICO (los fuertes, más
## anchos; los livianos, más finos) con un poco de variación fija por jugador.
## Rangos cortos a propósito: es un futbolista, no un culturista.
static func aspecto_futbolista(jug: Dictionary, jid: String) -> Dictionary:
	var fis := float((jug.get("atributos", {}) as Dictionary).get("fis", 70))
	var ruido := float(absi(hash(jid + "cuerpo")) % 1000) / 1000.0 - 0.5
	var ruido2 := float(absi(hash(jid + "hombros")) % 1000) / 1000.0 - 0.5
	return {"complexion": clampf((fis - 68.0) / 38.0 + ruido * 0.3, -0.45, 0.6),
		"hombros": clampf((fis - 68.0) / 50.0 + ruido2 * 0.2, -0.3, 0.45),
		"barriga": 0.0, "piernas": 0.0, "cabeza": 0.0}

static func cuerpo_futbolista(d: Dictionary, jug: Dictionary, jid: String) -> void:
	if not d.has("esqueleto") or not d.has("modelo"):
		return
	_cuerpo(d, aspecto_futbolista(jug, jid), true)
