extends Control
## LA SALA VAR POR DENTRO (26-9-2026). Pedido: *"ver el VAR por dentro"*.
##
## Cuando el árbitro pide revisar, la transmisión se va a la sala de vídeo:
## una sala oscura con una pared de monitores, dos puestos con sus operadores
## (auriculares, polo oscuro) y el rótulo VAR. Los monitores NO son dibujos:
## cada uno es una cámara de verdad sobre el MISMO mundo 3D del partido (detrás
## del arco, lateral a ras de campo, cenital y la de la jugada), así que se ve
## lo que está pasando en el campo desde cuatro ángulos.
## Dura unos segundos, muestra la decisión y se cierra sola. El partido se
## pausa mientras tanto (lo reanuda quien la abrió, con `terminada`).

signal terminada

const DURACION := 6.5
## Altura del asiento del operador (la silla y la cadera se alinean con ella).
const _OP_ASIENTO := 0.48

var _vp: SubViewport
var _cam: Camera3D
var _t := 0.0
var _ult_seg := -1   ## (28-10) último segundo escrito en el reloj

var _rotulo: Label
var _reloj: Label
var _decision: PanelContainer
var _motivo := ""
## Si la revisión acaba anulando lo decidido en el campo (el gol).
var anula := false
var _minuto := 0
var _mundo_partido: World3D
var _foco := Vector3.ZERO
var _monitores: Array = []
## LA LÍNEA DEL FUERA DE JUEGO EN EL MONITOR (17-10-2026, M-118): con
## {"linea": z del penúltimo defensor, "atacante": z del goleador, "margen": m}
## (lo que mide el motor en el pase, `MotorJugable.lineas_gol`), la cámara 2 se
## pone en alto de lado mirando a esa zona y se dibujan encima las dos líneas
## de lado a lado del campo, como en la tele: roja la del defensor, azul la del
## atacante, y el margen en metros.
var lineas: Dictionary = {}

## `opc`: {"anular": bool (false), "lineas": Dictionary ({})}; agrupados para no pasar 7 argumentos.

func _caja(raiz: Node3D, pos: Vector3, tam: Vector3, col: Color, emision: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.7
	if emision > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = emision
	mi.material_override = m
	mi.position = pos
	raiz.add_child(mi)
	return mi

func _monitor(raiz: Node3D, pos: Vector3, tam: Vector2, tex: Texture2D, i: int) -> void:
	_caja(raiz, pos + Vector3(0, 0, -0.03), Vector3(tam.x + 0.08, tam.y + 0.08, 0.05), Color(0.02, 0.02, 0.03), 0.0)
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = tam
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if tex != null:
		m.albedo_texture = tex
	else:
		m.albedo_color = Color(0.1, 0.3, 0.2)
	mi.material_override = m
	mi.position = pos
	raiz.add_child(mi)
	var et := Label3D.new()
	et.text = [Idiomas.t("CÁMARA 1 · JUGADA"), Idiomas.t("CÁMARA 2 · LÍNEA"), Idiomas.t("CÁMARA 3 · CENITAL"), Idiomas.t("CÁMARA 4 · CONTRA")][i]
	et.font_size = 28
	et.pixel_size = 0.0035
	et.modulate = Color(0.85, 0.92, 1.0)
	et.position = pos + Vector3(-tam.x * 0.5 + 0.35, tam.y * 0.5 - 0.07, 0.01)
	raiz.add_child(et)

## Las dos líneas, proyectadas con la cámara del monitor y dibujadas sobre su
## pantalla (finas cintas que brillan), recortadas al borde del monitor.
func _dibujar_lineas(raiz: Node3D, cam: Camera3D, px: Vector2, centro: Vector3, tam: Vector2) -> void:
	var pares := [[float(lineas["linea"]), Color(1.0, 0.18, 0.2)], [float(lineas["atacante"]), Color(0.25, 0.6, 1.0)]]
	for par: Array in pares:
		var z: float = par[0]
		var a3 := Vector3(-34.0, 0.03, z)
		var b3 := Vector3(34.0, 0.03, z)
		if cam.is_position_behind(a3) or cam.is_position_behind(b3):
			continue
		var a := _a_monitor(cam.unproject_position(a3), px, tam)
		var b := _a_monitor(cam.unproject_position(b3), px, tam)
		var rec := _recortar(a, b, tam * 0.5)
		if rec.is_empty():
			continue
		_cinta(raiz, centro, rec[0], rec[1], par[1])
	## El margen medido, abajo del monitor.
	var m := float(lineas.get("margen", 0.0))
	var et := Label3D.new()
	var cm := absf(m) * 100.0
	et.text = (Idiomas.t("ADELANTADO %d cm") if m > 0.0 else Idiomas.t("HABILITADO %d cm")) % int(round(cm))
	et.font_size = 34
	et.pixel_size = 0.0035
	et.outline_size = 6
	et.modulate = Color(1.0, 0.35, 0.35) if m > 0.0 else Color(0.5, 0.85, 1.0)
	## Arriba a la derecha (abajo lo tapa la cabeza del operador).
	et.position = centro + Vector3(tam.x * 0.5 - 0.42, tam.y * 0.5 - 0.08, 0.012)
	raiz.add_child(et)

## Píxel de la cámara del monitor -> punto (x, y) sobre la pantalla del monitor.
func _a_monitor(p: Vector2, px: Vector2, tam: Vector2) -> Vector2:
	return Vector2((p.x / px.x - 0.5) * tam.x, (0.5 - p.y / px.y) * tam.y)

## Liang-Barsky: el tramo a-b dentro del rectángulo ±medio.
func _recortar(a: Vector2, b: Vector2, medio: Vector2) -> Array:
	var t0 := 0.0
	var t1 := 1.0
	var d := b - a
	var p := [-d.x, d.x, -d.y, d.y]
	var q := [a.x + medio.x, medio.x - a.x, a.y + medio.y, medio.y - a.y]
	for k in 4:
		if absf(float(p[k])) < 0.000001:
			if float(q[k]) < 0.0:
				return []
			continue
		var r := float(q[k]) / float(p[k])
		if float(p[k]) < 0.0:
			t0 = maxf(t0, r)
		else:
			t1 = minf(t1, r)
		if t0 > t1:
			return []
	return [a + d * t0, a + d * t1]

func _cinta(raiz: Node3D, centro: Vector3, a: Vector2, b: Vector2, col: Color) -> void:
	var largo := a.distance_to(b)
	if largo < 0.01:
		return
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(largo, 0.012, 0.002)
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	mi.material_override = m
	var medio := (a + b) * 0.5
	mi.position = centro + Vector3(medio.x, medio.y, 0.008)
	mi.rotation.z = atan2(b.y - a.y, b.x - a.x)
	raiz.add_child(mi)

## UN OPERADOR DEL VAR (17-10-2026): antes era el futbolista del partido con
## la equipación pintada de oscuro (calvo, de culturista y con ropa de juego).
## Ahora se arma como la gente de la ciudad (`PeatonQ`): complexión normal
## (`adelgazar`), polo de árbitro con el cuello celeste del VAR y pantalón de
## vestir (ropa de calle del `VestidorQ`), pelo (`PeloQ`), cara de la
## biblioteca modular y ojos de verdad; sentado en una silla de oficina.
func _operador(raiz: Node3D, pos: Vector3, lado: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7741 + (1 if lado > 0.0 else 0)
	var d := FutbolistaQ.crear(rng.randf_range(1.72, 1.84), "male")
	if d.is_empty():
		return
	var nodo: Node3D = d["nodo"]
	nodo.position = pos
	nodo.rotation_degrees.y = 180.0
	raiz.add_child(nodo)
	FutbolistaQ.terminar(d, false)
	PersonajeDT.adelgazar(d, false)
	_op_vestir(d, rng, lado)
	_op_sentar(nodo, pos)
	_op_silla(raiz, pos)
	var cab := _op_cabeza(raiz, nodo, pos)
	_op_auriculares(cab)

## Ropa, pelo, cara y ojos del operador (polo oscuro, auriculares de la mesa).
func _op_vestir(d: Dictionary, rng: RandomNumberGenerator, lado: float) -> void:
	var piel := Color("b98a66") if lado < 0 else Color("7a5238")
	var pelo_col: Color = CargaCiudad.de("PeatonQ").PELOS[rng.randi() % 3]
	var polo := Color("1b1f27")
	var ribete := Color("3fa9f5")
	var pant := Color("22252c")
	var kit := {
		"dis": "liso",
		"cols": [polo.to_html(false), polo.to_html(false), ribete.to_html(false), "ffffff", "111111"],
		"trim": 1, "cuello": 2, "manga_corta": true,
		"pant": {"dis": "liso", "c1": pant.to_html(false), "c2": pant.to_html(false)},
		"med": {"dis": "lisas", "c1": "15161a", "c2": "15161a"},
		"bot": {"mod": "clasico", "c1": "111214", "c2": "111214", "c3": "222222"},
		"acc": {}, "civil": true,
	}
	VestidorQ.vestir_equipacion(d, polo, ribete, "liso", piel, pelo_col, pant, pant, true, kit, 0)
	PeloQ.poner(d, ["corto", "fade", "flequillo"][rng.randi() % 3] if lado < 0 else "rapado", pelo_col, rng.randf() < 0.5)
	if BibliotecaCaras.hay():
		var bib := BibliotecaCaras.para("var_%d" % rng.seed, piel, pelo_col)
		if not bib.is_empty():
			bib["pelo"] = ""
			VestidorQ.poner_cara(d, {"look": {}, "foto": "", "biblio": bib}, piel)
	PersonajeDT._ojos_vivos(d, piel, Color(String(PersonajeDT.OJOS[rng.randi() % PersonajeDT.OJOS.size()])), false)
	var ap: AnimationPlayer = d["anim"]
	if ap.has_animation("sentado"):
		ap.play("sentado")

## Sentado de verdad: la cadera sobre el asiento.
func _op_sentar(nodo: Node3D, pos: Vector3) -> void:
	## Sentado de verdad: la cadera sobre el asiento (como en los bancos del
	## metro, `CargaCiudad.de("MetroCiudad").altura_cadera`), no flotando a la altura de pie.
	var cadera = CargaCiudad.de("MetroCiudad").altura_cadera(nodo)
	if cadera > 0.0:
		nodo.position.y = pos.y + _OP_ASIENTO + 0.08 - cadera * 0.99

## La silla de oficina: asiento, respaldo, pie y base.
func _op_silla(raiz: Node3D, pos: Vector3) -> void:
	## La silla de oficina: asiento, respaldo (detrás: el operador mira a −Z),
	## pie y base.
	var gris := Color(0.12, 0.12, 0.14)
	_caja(raiz, pos + Vector3(0, _OP_ASIENTO - 0.03, 0.02), Vector3(0.5, 0.07, 0.48), gris, 0.0)
	_caja(raiz, pos + Vector3(0, _OP_ASIENTO + 0.36, 0.27), Vector3(0.46, 0.62, 0.06), gris, 0.0)
	_caja(raiz, pos + Vector3(0, _OP_ASIENTO * 0.5 - 0.02, 0.02), Vector3(0.06, _OP_ASIENTO - 0.06, 0.06), Color(0.3, 0.3, 0.32), 0.0)
	_caja(raiz, pos + Vector3(0, 0.03, 0.02), Vector3(0.56, 0.04, 0.56), Color(0.2, 0.2, 0.22), 0.0)

## El nodo de la cabeza del operador (sobre el hueso Head); devuelve el nodo de los auriculares.
func _op_cabeza(raiz: Node3D, nodo: Node3D, pos: Vector3) -> Node3D:
	## Auriculares: una diadema y dos cascos, en su cabeza (hueso Head de la
	## pose de reposo: la postura sentada no mueve la cadera, ver arriba).
	var alto_cabeza := 1.62
	var esqs := nodo.find_children("*", "Skeleton3D", true, false)
	if not esqs.is_empty():
		var sk: Skeleton3D = esqs[0]
		var hb := sk.find_bone("Head")
		if hb >= 0:
			alto_cabeza = (sk.global_transform * sk.get_bone_global_rest(hb)).origin.y - nodo.global_position.y + 0.1
	var cab := Node3D.new()
	cab.position = Vector3(pos.x, nodo.position.y + alto_cabeza, pos.z + 0.02)
	raiz.add_child(cab)
	return cab

## Auriculares: dos cascos y una diadema, en la cabeza.
func _op_auriculares(cab: Node3D) -> void:
	for s: float in [-1.0, 1.0]:
		var casco := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.045
		cm.bottom_radius = 0.045
		cm.height = 0.03
		casco.mesh = cm
		casco.rotation_degrees.z = 90.0
		casco.position = Vector3(0.085 * s, 0.0, 0.0)
		var mm := StandardMaterial3D.new()
		mm.albedo_color = Color(0.08, 0.08, 0.09)
		casco.material_override = mm
		cab.add_child(casco)
	var diadema := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.085
	tm.outer_radius = 0.1
	diadema.mesh = tm
	diadema.rotation_degrees.z = 90.0
	diadema.rotation_degrees.y = 90.0
	diadema.position = Vector3(0, 0.02, 0)
	cab.add_child(diadema)
