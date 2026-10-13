class_name PeatonQ
extends RefCounted
## LOS PEATONES, CON PERSONAS DE VERDAD (26-9-2026). Pedido del usuario: *"hay
## personas 3D del paquete del fútbol (son más que solo el calvo): ponlas como
## peatones, solo ponles ropa o barba y cosas así"*.
##
## Son los cuerpos del paquete Quaternius (hombre y mujer, los mismos de los
## futbolistas) con:
##   - ropa de calle pintada por `equipacion_q.gdshader` en modo `civil` (sin
##     escudo, marca ni dorsal) y `largo` (manga larga y pantalón largo):
##     camiseta lisa, a rayas, a cuadros tipo franela o polerón con capucha de
##     otro color, vaqueros, chinos o pantalón de buzo, y zapatillas;
##   - peinado de los ocho del paquete (`PeloQ`), barba en uno de cada tres
##     hombres, y su color de pelo;
##   - tono de piel y estatura variados;
##   - caminando con el clip "caminar" de la Universal Animation Library.
## Lejos de la cámara se dejan de dibujar (`visibility_range_end`): la ciudad
## puede tener decenas sin notarse en los fotogramas.

const PIELES := ["f1c7a5", "e0b08a", "c68d68", "a86b45", "8a5a3c", "6b4430"]
const PELOS := [Color(0.08, 0.06, 0.05), Color(0.25, 0.16, 0.09), Color(0.45, 0.3, 0.16), Color(0.7, 0.55, 0.3), Color(0.55, 0.55, 0.55), Color(0.85, 0.85, 0.82)]
const CORTES_H := ["corto", "fade", "tupe", "flequillo", "rizado", "largo", "coleta", "rapado"]
const CORTES_M := ["largo", "melena", "coleta", "trenzas", "corto"]
## [diseño, nombre]: lo que se ve por la calle.
## 13-10-2026: ropa de calle de verdad. Sobre todo liso; rayas finas y cuadros
## pequeños de vez en cuando; nada de dibujos de equipación (arlequín, canesú,
## mangas de contraste) ni colores de camiseta de fútbol.
const PRENDAS := ["liso", "liso", "liso", "liso", "liso", "franjas_finas", "cuadros_chicos"]
## Vaqueros (tres lavados), chinos, gris, negro, verde oliva.
const PANTALONES := ["2c3e5c", "3b5577", "1e2a3d", "b8a27a", "4a4a4e", "1b1b1d", "55583f"]
## Colores apagados de calle: blanco roto, gris, negro, azul marino, burdeos,
## verde botella, mostaza apagado, camel, crudo, azul grisáceo, teja.
const ROPA := ["ecebe6", "8f9296", "2b2c30", "26324a", "6e2a33", "2f4a3c", "b5913f", "a67b55", "d9cfbd", "5f7486", "9c5a3c", "46494f", "c9c3b6"]

## Crea el peatón (sin terminar: `terminar()` cuando ya esté en el árbol).
static func crear(rng: RandomNumberGenerator) -> Dictionary:
	var mujer := rng.randf() < 0.45
	var d := FutbolistaQ.crear(rng.randf_range(1.58, 1.72) if mujer else rng.randf_range(1.66, 1.92), "female" if mujer else "male")
	if d.is_empty():
		return d
	d["mujer"] = mujer
	d["semilla"] = rng.randi()
	(d["nodo"] as Node).set_meta("mujer", mujer)
	return d

## Lo arma cuando ya está en el árbol: medidas, ropa, pelo y paso.
static func terminar(d: Dictionary) -> void:
	if d.is_empty():
		return
	var nodo: Node3D = d["nodo"]
	if not nodo.is_inside_tree():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(d["semilla"])
	FutbolistaQ.terminar(d, false)
	## Sin el cuerpo de culturista del modelo (sin coste por fotograma).
	PersonajeDT.adelgazar(d, false)
	var mujer: bool = d["mujer"]
	var c1 := Color(String(ROPA[rng.randi() % ROPA.size()]))
	var c2 := Color(String(ROPA[rng.randi() % ROPA.size()]))
	var pant := Color(String(PANTALONES[rng.randi() % PANTALONES.size()]))
	var piel := Color(String(PIELES[rng.randi() % PIELES.size()]))
	var pelo_col: Color = PELOS[rng.randi() % PELOS.size()]
	var zapatilla: String = ["e8e6e0", "1c1c1e", "3e2723", "4a4d52"][rng.randi() % 4]
	var kit := {
		"dis": String(PRENDAS[rng.randi() % PRENDAS.size()]),
		"cols": [c1.to_html(false), c2.to_html(false), c2.darkened(0.3).to_html(false), "ffffff", "111111"],
		"trim": 1 if rng.randf() < 0.5 else 0,
		"cuello": 1 if rng.randf() < 0.7 else 2,
		"pant": {"dis": "liso", "c1": pant.to_html(false), "c2": pant.to_html(false)},
		"med": {"dis": "lisas", "c1": pant.to_html(false), "c2": pant.to_html(false)},
		"bot": {"mod": "clasico", "c1": zapatilla, "c2": zapatilla, "c3": "eeeeee"},
		"acc": {},
		"civil": true,
	}
	VestidorQ.vestir_equipacion(d, c1, c2, "liso", piel, pelo_col, pant, pant, true, kit, 0)
	var corte: String = CORTES_M[rng.randi() % CORTES_M.size()] if mujer else CORTES_H[rng.randi() % CORTES_H.size()]
	PeloQ.poner(d, corte, pelo_col, not mujer and rng.randf() < 0.35)
	_variedad(d, rng, mujer, pelo_col)
	## Ojos de verdad (iris y párpados), con el material compartido (13-10-2026).
	PersonajeDT._ojos_vivos(d, piel, Color(String(PersonajeDT.OJOS[rng.randi() % PersonajeDT.OJOS.size()])), false)
	var ap: AnimationPlayer = d["anim"]
	if ap.has_animation("caminar"):
		ap.play("caminar")
		ap.seek(rng.randf() * ap.current_animation_length, true)
		ap.speed_scale = rng.randf_range(0.9, 1.1)
	## Lejos de la cámara no se dibuja (ni su sombra).
	for mi in nodo.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).visibility_range_end = 120.0
		(mi as MeshInstance3D).visibility_range_end_margin = 20.0


## COMPLEXIÓN Y ACCESORIOS (etapa 4, 12-10-2026). Todos los peatones eran el
## mismo cuerpo con distinta ropa. Ahora cambian de ANCHURA (de delgado a
## robusto) y llevan, según el azar, mochila, bolso, móvil en la mano, gafas de
## sol o gorra. Piezas de pocos polígonos, colgadas del hueso, que comparten
## materiales (una sola caja de cada color en toda la ciudad). El azar sale de
## `rng` DESPUÉS de todo lo ya sorteado: la ropa de cada peatón no cambia.
static var _mats := {}

static func _m(c: Color, rug := 0.7) -> StandardMaterial3D:
	var k := "%s|%.2f" % [c.to_html(false), rug]
	if not _mats.has(k):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = rug
		_mats[k] = m
	return _mats[k]

static func _pieza(padre: Node3D, malla: Mesh, mat: Material, pos: Vector3, giro := Vector3.ZERO) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = giro
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = 40.0
	padre.add_child(mi)

static func _caja(t: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = t
	return b

static func _en_hueso(esq: Skeleton3D, hueso: String, k: float) -> Node3D:
	if esq.find_bone(hueso) < 0:
		return null
	var ba := BoneAttachment3D.new()
	ba.bone_name = hueso
	esq.add_child(ba)
	var n := Node3D.new()
	n.scale = Vector3.ONE * k
	ba.add_child(n)
	return n

static func _variedad(d: Dictionary, rng: RandomNumberGenerator, mujer: bool, pelo_col: Color) -> void:
	var modelo: Node3D = d["modelo"]
	## Complexión: más o menos ancho (y algo de fondo), sin cambiar la estatura.
	## Más esbeltos que el modelo base de culturista (13-10-2026).
	var ancho := rng.randf_range(0.84, 1.06)
	modelo.scale = Vector3(modelo.scale.x * ancho, modelo.scale.y, modelo.scale.z * lerpf(1.0, ancho, 0.6))
	var esq: Skeleton3D = d["esqueleto"]
	var k := 1.0 / maxf(modelo.scale.y, 0.01)
	var acc := rng.randf()
	var col := Color(String(ROPA[rng.randi() % ROPA.size()])).darkened(0.25)
	if acc < 0.28:
		## Mochila a la espalda (el pecho mira a +Z en el hueso de la columna).
		var h := _en_hueso(esq, "spine_03", k)
		if h != null:
			_pieza(h, _caja(Vector3(0.26, 0.32, 0.13)), _m(col), Vector3(0, 0.02, -0.16))
			_pieza(h, _caja(Vector3(0.22, 0.14, 0.05)), _m(col.darkened(0.2)), Vector3(0, -0.06, -0.25))
	elif acc < 0.42:
		## Bolso colgado de la cadera.
		var h2 := _en_hueso(esq, "hand_r" if rng.randf() < 0.5 else "hand_l", k)
		if h2 != null:
			## Bolsa con asa, colgando BAJO la mano (+Y del hueso = hacia los dedos).
			var bolsa := col if rng.randf() < 0.6 else Color(0.78, 0.66, 0.48)
			_pieza(h2, _caja(Vector3(0.26, 0.22, 0.09)), _m(bolsa, 0.6), Vector3(0, 0.24, 0))
			var asa := TorusMesh.new()
			asa.inner_radius = 0.045
			asa.outer_radius = 0.055
			asa.rings = 10
			asa.ring_segments = 6
			_pieza(h2, asa, _m(bolsa.darkened(0.35), 0.5), Vector3(0, 0.1, 0), Vector3(0, 0, 90))
	elif acc < 0.62:
		## Móvil en la mano: un rectángulo oscuro con la pantalla clara.
		var h3 := _en_hueso(esq, "hand_r", k)
		if h3 != null:
			_pieza(h3, _caja(Vector3(0.07, 0.14, 0.012)), _m(Color(0.05, 0.05, 0.06), 0.3), Vector3(0, 0.05, 0.05))
	var cab_extra := rng.randf()
	var cab := _en_hueso(esq, "Head", k)
	if cab != null:
		if cab_extra < 0.2:
			## Gafas de sol.
			var lente := SphereMesh.new()
			lente.radius = 0.024
			lente.height = 0.02
			lente.radial_segments = 10
			lente.rings = 4
			for sx in [-1.0, 1.0]:
				_pieza(cab, lente, _m(Color(0.04, 0.04, 0.05), 0.15), Vector3(0.034 * sx, 0.1, 0.1))
			_pieza(cab, _caja(Vector3(0.03, 0.005, 0.005)), _m(Color(0.04, 0.04, 0.05), 0.15), Vector3(0, 0.105, 0.108))
		elif cab_extra < 0.34:
			## Gorra: casquete y visera.
			var gm := _m(col.lightened(0.1))
			var copa := SphereMesh.new()
			copa.radius = 0.108
			copa.height = 0.13
			copa.radial_segments = 14
			copa.rings = 6
			copa.is_hemisphere = true
			_pieza(cab, copa, gm, Vector3(0, 0.155, -0.005))
			var visera := CylinderMesh.new()
			visera.top_radius = 0.075
			visera.bottom_radius = 0.075
			visera.height = 0.01
			visera.radial_segments = 12
			_pieza(cab, visera, _m(col.darkened(0.15)), Vector3(0, 0.16, 0.11), Vector3(-8, 0, 0))
