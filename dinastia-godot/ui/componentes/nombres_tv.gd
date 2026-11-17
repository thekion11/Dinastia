class_name NombresTV
extends Control
## LOS NOMBRES SOBRE EL CAMPO, COMO EN LA TELE (17-11, punto 4 de `COMPARACION_REFERENCIAS_PARTIDO_2026-11-16.md`, referencia FC Mobile).
## Con la «pantalla limpia» de la transmisión (sin los 22 rótulos) no se sabía quién era quién. Ahora, como mucho TRES:
##   · el FOCO: el que manejas (con el equipo en tus manos) o, mirando el partido, el que lleva el balón;
##   · si manejas al que lleva el balón, el RECEPTOR probable del pase (`receptor_probable`: el compañero de campo mejor alineado con
##     hacia donde mira, como el pase asistido del motor, leyendo solo su estado público), con aro fino y una flecha;
##   · y el RIVAL más cercano al foco (a menos de `RADIO_RIVAL` m): su marca;
## cada uno con un ANILLO en el césped (una elipse proyectada) del color fuerte de su club (`MarcadorTV.color_vivo`) y, debajo, una
## pastilla con el APELLIDO. Sobre la cabeza del que manejas, un triángulo pequeño (en el estadio lo pone `IndicadorFC`, con su dorsal
## y su energía). TODO EN 2D, a la resolución de la pantalla: el 3D del móvil se dibuja al ~35 % y lo que vive dentro sale pixelado
## (por eso el aro 3D del controlado del estadio y el triángulo y el aro 3D de `MarcadorJugador` en el partido de La Ruta se apagan).
## Sirve en el estadio (`VistaEstadio`, 3D en la ventana) y en el partido de La Ruta (`PartidoJugable`, 3D en un `SubViewport`: las
## posiciones proyectadas se pasan a la pantalla con `_a_pantalla`).
## BARATO: aros y flechas son primitivas (una llamada para todos), las pastillas rectángulos (otra) y el texto un tamaño de letra
## (otra): 3 llamadas 2D, ninguna 3D; en MÍNIMA / ULTRA BAJA igual que en ALTA. Se esconde en la repetición, la presentación, la
## ceremonia, los goles y el descanso. Si están encendidos los 22 rótulos del estadio (⚙ → nombres) no repite nombres: solo los aros.

const RADIO_RIVAL := 18.0
const RADIO_ARO := 0.75   ## m
const LADOS_ARO := 20

var vista: Control
var escala := 1.0
var _fuente: Font
## Lo que se pinta este fotograma: [{pos: Vector2 (pies), aro: PackedVector2Array, atras: Array[bool], col, nombre, grande}]
var _marcas: Array = []
var _firma := ""
var _aro_apagado := false
## (PartidoJugable) el triángulo sobre la cabeza del que manejas lo pinta este nodo (en el estadio, `IndicadorFC`).
var triangulo := false

static func poner(v: Control) -> NombresTV:
	var n := NombresTV.new()
	n.name = "NombresTV"
	n.vista = v
	n.escala = HudTactil.f(v)
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.z_index = 4   ## debajo del indicador del controlado (5), encima del 3D
	v.add_child(n)
	n.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return n

func _ready() -> void:
	_fuente = MarcadorTV.fuente()

func _club(local: bool) -> Club:
	var p: Variant = vista.get("partido")
	if p is Partido:
		return (p as Partido).local if local else (p as Partido).visita
	var c: Variant = vista.get("local" if local else "visita")
	return c as Club if c is Club else null

## El motor del partido: `_motor` en el estadio, `motor` en el de La Ruta (`MotorJugable` o el combinado C4, que no hereda de él: se
## lee por nombre lo público que tienen los dos: `estado`, `control_equipo`, `usuario`, `poseedor`, `jugadores`).
func _el_motor() -> Object:
	var m: Variant = vista.get("_motor")
	if m == null:
		m = vista.get("motor")
	return m as Object if m is Object and is_instance_valid(m) else null

## La cámara del partido (la del `SubViewport` en La Ruta) y el paso de sus píxeles a los de la pantalla.
func _camara() -> Camera3D:
	var c: Variant = vista.get("_cam")
	if c is Camera3D and is_instance_valid(c) and (c as Camera3D).current:
		return c
	return get_viewport().get_camera_3d()

func _a_pantalla(cam: Camera3D, p: Vector3) -> Vector2:
	var q := cam.unproject_position(p)
	var vp := cam.get_viewport()
	if vp is SubViewport and vp != get_viewport():
		var t := Vector2((vp as SubViewport).size)
		if t.x > 0.0 and t.y > 0.0:
			q *= size / t
	return q

## ¿Toca esconderlo? (repetición, presentación, ceremonia, goles, descanso, tanda).
func _oculto(motor: Object) -> bool:
	if motor == null or not (String(motor.get("estado")) in ["juego", "saque"]):
		return true
	var repe: Variant = vista.get("_repe")
	if repe != null and bool(repe.get("reproduciendo")):
		return true
	var intro: Variant = vista.get("_intro")
	if intro != null and is_instance_valid(intro) and bool(intro.get("activa")):
		return true
	var cine: Variant = vista.get("_cine")
	if cine != null and is_instance_valid(cine):
		return true
	var cer: Variant = vista.get("_ceremonia")
	return cer != null and is_instance_valid(cer) and bool(cer.get("activa"))

## El foco (el que manejas o el que lleva el balón) y su rival más cercano (datos del motor: `control_equipo`, `usuario`,
## `poseedor`, `jugadores`; sin tocarlo).
static func elegir(control_equipo: int, usuario: Dictionary, poseedor: Dictionary, jugadores: Array) -> Array[Dictionary]:
	var foco: Dictionary = {}
	if control_equipo >= 0 and not usuario.is_empty():
		foco = usuario
	elif not poseedor.is_empty():
		foco = poseedor
	var r: Array[Dictionary] = []
	if foco.is_empty() or not is_instance_valid(foco.get("node")):
		return r
	var fpos := (foco["node"] as Node3D).position
	var rival: Dictionary = {}
	var mejor := RADIO_RIVAL * RADIO_RIVAL
	for q: Dictionary in jugadores:
		if bool(q.get("es_local", true)) == bool(foco.get("es_local", true)) or not is_instance_valid(q.get("node")):
			continue
		var d := (q["node"] as Node3D).position.distance_squared_to(fpos)
		if d < mejor:
			mejor = d
			rival = q
	r.append(foco)
	if not rival.is_empty():
		r.append(rival)
	return r

func _process(_d: float) -> void:
	var motor: Variant = _el_motor() if is_instance_valid(vista) else null
	var cam := _camara() if is_instance_valid(vista) else null
	if cam == null or _oculto(motor):
		if not _marcas.is_empty():
			_marcas.clear()
			_firma = ""
			queue_redraw()
		return
	## En La Ruta (`triangulo`) siempre llevas a tu jugador; en el estadio, solo con el equipo en tus manos.
	var manejas: bool = not (motor.usuario as Dictionary).is_empty() and (int(motor.control_equipo) >= 0 or triangulo)
	var lista := elegir(0 if manejas else -1, motor.usuario, motor.poseedor, motor.jugadores)
	if manejas:
		_apagar_cursor_3d()
	var receptor := -1
	if manejas and not lista.is_empty() and lista[0] == motor.poseedor:
		var n0 := lista[0]["node"] as Node3D
		var q := receptor_probable(lista[0], Vector3(sin(n0.rotation.y), 0.0, cos(n0.rotation.y)), motor.jugadores)
		if not q.is_empty() and is_instance_valid(q.get("node")):
			lista.insert(1, q)
			receptor = 1
	var con_rotulos := PlayerSpawner.mostrar_nombres and vista.has_method("_escalar_rotulos")   ## los 22 rótulos solo existen en el estadio
	var marcas: Array = []
	var firma := ""
	for i in lista.size():
		var q: Dictionary = lista[i]
		var n := q["node"] as Node3D
		var pie := n.global_position
		if cam.is_position_behind(pie):
			continue
		var col := MarcadorTV.color_vivo(_club(bool(q.get("es_local", true))))
		var yo := i == 0 and manejas
		var aro := PackedVector2Array()
		var al_cam := cam.global_position - pie
		var atras: Array[bool] = []
		for k in LADOS_ARO + 1:
			var ang := TAU * k / LADOS_ARO
			var off := Vector3(cos(ang), 0.0, sin(ang)) * (RADIO_ARO * (1.15 if yo else 1.0))
			aro.append(_a_pantalla(cam, pie + off + Vector3(0, 0.03, 0)))
			atras.append(off.dot(Vector3(al_cam.x, 0.0, al_cam.z)) < 0.0)
		var jd: Dictionary = q.get("jugador", {})
		var nom := "" if con_rotulos and not yo else _apellido(String(jd.get("nombre", q.get("nombre", ""))))
		var pp := _a_pantalla(cam, pie)
		marcas.append({"aro": aro, "atras": atras, "col": col, "nombre": nom, "pie": pp, "grande": i == 0, "yo": yo,
			"receptor": i == receptor, "cabeza": _a_pantalla(cam, pie + Vector3(0, 2.25, 0))})
		firma += "%d,%d,%s;" % [int(pp.x), int(pp.y), nom]
	if firma != _firma:
		_firma = firma
		_marcas = marcas
		queue_redraw()

## El compañero de campo (no el portero) al que iría el pase hacia `dir`: el mejor alineado y no muy lejos (3-45 m). Copia la nota del
## pase asistido del motor sin la línea tapada; solo para el HUD (el motor decide su pase aparte).
static func receptor_probable(p: Dictionary, dir: Vector3, jugadores: Array) -> Dictionary:
	var mejor: Dictionary = {}
	var nota_mejor := 0.0
	var n := p.get("node") as Node3D
	if n == null or not is_instance_valid(n):
		return mejor
	for q: Dictionary in jugadores:
		if q == p or bool(q.get("es_local", true)) != bool(p.get("es_local", true)) or bool(q.get("por", false)) or not is_instance_valid(q.get("node")):
			continue
		var v := (q["node"] as Node3D).position - n.position
		var dist := v.length()
		if dist < 3.0 or dist > 45.0:
			continue
		var nota := v.normalized().dot(dir.normalized()) * 3.0 - dist * 0.03
		if nota > nota_mejor:
			nota_mejor = nota
			mejor = q
	return mejor

static func _apellido(nombre: String) -> String:
	var v := Nombres.visible(nombre)
	return v.get_slice(" ", v.get_slice_count(" ") - 1).to_upper() if v != "" else ""

## El aro 3D del que manejas en el estadio (`_cursor`) se apaga: ahora es una elipse 2D, nítida en el móvil.
func _apagar_cursor_3d() -> void:
	if _aro_apagado:
		return
	var cur: Variant = vista.get("_cursor")
	if cur == null or not is_instance_valid(cur):
		return
	for h in (cur as Node).get_children():
		if h is MeshInstance3D:
			(h as MeshInstance3D).visible = false
	_aro_apagado = true

## Un tramo de línea como primitiva de 4 puntos: Godot agrupa todas las primitivas seguidas en una sola llamada (`medir_hud_tv.tscn`).
func _tramo(a: Vector2, b: Vector2, ancho: float, col: Color) -> void:
	var n := (b - a).orthogonal().normalized() * ancho * 0.5
	draw_primitive(PackedVector2Array([a - n, b - n, b + n, a + n]), PackedColorArray([col, col, col, col]), PackedVector2Array())

func _draw() -> void:
	if _marcas.is_empty():
		return
	var e := escala
	## 1) Aros y flechas (primitivas: una llamada).
	for m: Dictionary in _marcas:
		var aro: PackedVector2Array = m["aro"]
		var atras: Array = m["atras"]
		var col: Color = m["col"]
		var ancho := (3.0 if bool(m["grande"]) else 2.4) * e * (0.7 if bool(m["receptor"]) else 1.0)
		for k in aro.size() - 1:
			var tras := bool(atras[k]) and bool(atras[k + 1])
			_tramo(aro[k], aro[k + 1], ancho + 2.0, Color(0, 0, 0, 0.25 if tras else 0.5))
			_tramo(aro[k], aro[k + 1], ancho, Color(col, 0.4 if tras else 0.95))
		if bool(m["yo"]) and triangulo:
			## El triángulo pequeño sobre la cabeza del que manejas (antes uno 3D de hasta 2,6 m que tapaba el centro de la pantalla).
			var cy: Vector2 = m["cabeza"]
			var ry := 8.0 * e
			_tramo(cy + Vector2(-ry, -ry * 1.6), cy + Vector2(ry, -ry * 1.6), 3.0 * e, Color(0, 0, 0, 0.6))
			draw_primitive(PackedVector2Array([cy + Vector2(-ry, -ry * 1.6), cy + Vector2(0, -ry * 1.2), cy + Vector2(ry, -ry * 1.6), cy]),
				PackedColorArray([col, col, col, col]), PackedVector2Array())
		if bool(m["receptor"]):
			## La flecha del pase, sobre la cabeza del que lo recibiría.
			var c: Vector2 = m["cabeza"]
			var r := 9.0 * e
			draw_primitive(PackedVector2Array([c + Vector2(-r, -r * 1.1), c + Vector2(0, -r * 0.6), c + Vector2(r, -r * 1.1), c]),
				PackedColorArray([col, col, col, col]), PackedVector2Array())   ## 4 puntos (punta de flecha): va en la misma llamada que los aros
	## 2) Las pastillas (rectángulos: una llamada).
	var textos: Array = []
	var t := int(roundf(18.0 * e))
	for m: Dictionary in _marcas:
		var nom := String(m["nombre"])
		if nom == "" or _fuente == null:
			continue
		var w := _fuente.get_string_size(nom, HORIZONTAL_ALIGNMENT_LEFT, -1, t).x
		var aro: PackedVector2Array = m["aro"]
		var bajo := (m["pie"] as Vector2).y
		for p: Vector2 in aro:
			bajo = maxf(bajo, p.y)
		var caja := Rect2(Vector2((m["pie"] as Vector2).x - w * 0.5 - 7.0 * e, bajo + 4.0 * e), Vector2(w + 14.0 * e, t + 4.0 * e))
		draw_rect(caja, Color(0.03, 0.04, 0.05, 0.66))
		draw_rect(Rect2(caja.position, Vector2(3.0 * e, caja.size.y)), m["col"])
		textos.append([nom, Vector2(caja.position.x + 8.5 * e, caja.position.y + 2.0 * e + _fuente.get_ascent(t))])
	## 3) El texto (un tamaño de letra: una llamada).
	for x: Array in textos:
		draw_string(_fuente, x[1], String(x[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, t, Color(1, 1, 1, 0.97))
