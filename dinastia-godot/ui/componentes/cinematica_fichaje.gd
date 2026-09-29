class_name CinematicaFichaje
extends Control
## LA PRESENTACIÓN EN EL ESTADIO, COMO CINEMÁTICA (29-9-2026, mapa de metas 13,
## plan B3). Elegir "presentarlo en el estadio" ya no es solo una línea en el
## registro: se ve TU estadio -el mismo que se juega, con su forma, sus colores y
## la grada llena según cuánto ilusiona el fichaje-, y el jugador en el círculo
## central con tu camiseta y su dorsal. Tres planos:
##   1. vuelo sobre el estadio (0-4 s),
##   2. la cámara baja y se acerca al jugador (4-8 s), que da toques al balón si
##      es una estrella,
##   3. plano medio con el rótulo: nombre, dorsal y de dónde llega (8-11 s).
## Con confeti de los colores del club y los flashes de la prensa. Se salta con
## un botón o con Esc.

signal terminada

const DURACION := 11.0
const PLANO_2 := 4.0
const PLANO_3 := 8.0

var _t := 0.0
var _cam: Camera3D
var _raiz: Node3D
var _rotulo: Control
var _velo: ColorRect
var _flashes: Array[OmniLight3D] = []
var _cerrando := false
var _rotulo_visto := false
var _ap: AnimationPlayer
var estrella := false

static func mostrar(padre: Control, mundo: Mundo, j: Jugador, de: Club, es_estrella: bool) -> CinematicaFichaje:
	var n := CinematicaFichaje.new()
	n.estrella = es_estrella
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	padre.add_child(n)
	n._montar(mundo, j, de)
	return n

func _montar(mundo: Mundo, j: Jugador, de: Club) -> void:
	var mio := mundo.mi_club()
	var fondo := ColorRect.new()
	fondo.color = Color.BLACK
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var cont := SubViewportContainer.new()
	cont.stretch = true
	cont.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cont)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	cont.add_child(vp)
	_raiz = Node3D.new()
	vp.add_child(_raiz)
	## El MISMO estadio que se juega: el que diseñaste en Club → Estadio, con
	## sus butacas, reformas y obras (no el genérico que sale del id del club).
	var perfil := mundo.perfil_estadio_de(mio).duplicate()
	## Las presentaciones son de día, con el sol de frente a la cámara.
	perfil["clima"] = "dia"
	Ambience.apply(_raiz, perfil, null, Calidad.elegida)
	StadiumBuilder.build_pitch(_raiz, perfil, mio)
	var aforo := int(perfil.get("aforo", 20000))
	## La grada responde a quién presentas: llena para una estrella, a medias
	## para uno de rotación (lo mismo que dice la noticia de `aplicar()`).
	StadiumBuilder.build(_raiz, perfil, aforo, 0.92 if estrella else 0.4, mio._hash_id(), mio)
	_poner_jugador(j, mio)
	_poner_confeti(Color(mio.color_kit1()), Color(mio.color_kit2()))
	_poner_flashes()
	## Luz de relleno de frente, como la de los focos de la tele: sin ella la
	## cara queda en sombra en el plano medio.
	var relleno := SpotLight3D.new()
	relleno.position = Vector3(6, 4, 0.5)
	relleno.spot_range = 14.0
	relleno.spot_angle = 22.0
	relleno.light_energy = 2.2
	_raiz.add_child(relleno)
	relleno.look_at(Vector3(0, 1.3, 0), Vector3.UP)
	_cam = Camera3D.new()
	_cam.fov = 55.0
	_cam.far = 900.0
	_raiz.add_child(_cam)
	_cam.current = true
	_colocar_camara(0.0)
	_montar_rotulos(mio, j, de)
	_velo = ColorRect.new()
	_velo.color = Color.BLACK
	_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_velo)
	create_tween().tween_property(_velo, "color:a", 0.0, 0.6)
	Sonido.toca("ovacion" if estrella else "aplauso", Sonido.Bus.INTERFAZ)

func _poner_jugador(j: Jugador, mio: Club) -> void:
	var jd := Puente3D.jugador(j)
	var d := FutbolistaQ.crear(PlayerSpawner.altura_de(jd, j.id, j.pos_e), "male")
	if d.is_empty():
		return
	var nodo: Node3D = d["nodo"]
	_raiz.add_child(nodo)
	FutbolistaQ.terminar(d, true)
	var look := PlayerSpawner._look_de(jd)
	var kit := Puente3D.kit(mio)
	var kx: Dictionary = {} if j.pos_e == "POR" else kit.get("x", {})
	if not VestidorQ.vestir_equipacion(d, Color(String(kit["c1"])), Color(String(kit["c2"])), String(kit["estilo"]),
			look[0], look[1], Color(0, 0, 0, 0), Color(0, 0, 0, 0), false, kx, maxi(j.dorsal, 1)):
		VestidorQ.vestir(d, Color(String(kit["c1"])))
	var lk: Dictionary = jd.get("look", {}) if jd.get("look") is Dictionary else {}
	PeloQ.poner(d, String(lk.get("pelo", "corto")), look[1], int(look[2]) in [1, 4, 6])
	## De frente a la cámara del plano final (que mira desde +X).
	nodo.rotation.y = PI * 0.5
	var ap: AnimationPlayer = d["anim"]
	_ap = ap
	## Siempre en movimiento: la estrella da toques al balón; el de rotación
	## saluda y aplaude a la grada. En el plano final, todos saludan.
	var clip := "dominadas_%d" % (1 + absi(j.id.hash()) % 3)
	if estrella and Dominadas.montar(nodo, ap, clip) != null:
		ap.play(clip)
	else:
		_tocar(["saludo_mano", "aplaudir", "parado"])

func _poner_confeti(c1: Color, c2: Color) -> void:
	for col: Color in [c1, c2, Color(0.95, 0.85, 0.3)]:
		var p := CPUParticles3D.new()
		p.amount = 260 if estrella else 90
		p.lifetime = 6.0
		p.position = Vector3(0, 16, 0)
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = Vector3(14, 1, 14)
		p.direction = Vector3.DOWN
		p.spread = 25.0
		p.gravity = Vector3(0, -1.6, 0)
		p.initial_velocity_min = 0.5
		p.initial_velocity_max = 1.5
		p.angular_velocity_min = -360.0
		p.angular_velocity_max = 360.0
		var q := QuadMesh.new()
		q.size = Vector2(0.06, 0.1)
		var m := StandardMaterial3D.new()
		m.albedo_color = col
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		q.material = m
		p.mesh = q
		p.preprocess = 3.0
		_raiz.add_child(p)

## Los flashes de los fotógrafos: luces cortas alrededor del jugador.
func _poner_flashes() -> void:
	for i in 6:
		var l := OmniLight3D.new()
		var a := -0.8 + float(i) * 0.32
		l.position = Vector3(cos(a) * 5.0, 1.4, sin(a) * 5.0)
		l.omni_range = 6.0
		l.light_energy = 0.0
		l.light_color = Color(1, 0.98, 0.92)
		_raiz.add_child(l)
		_flashes.append(l)

func _montar_rotulos(mio: Club, j: Jugador, de: Club) -> void:
	var cab := Tema.etiqueta(Tema.TAM_DESTACADO + 4, Tema.ORO, "🏟️ PRESENTACIÓN · %s" % Nombres.visible(mio.nombre).to_upper())
	cab.position = Vector2(28, 20)
	add_child(cab)
	var saltar := Button.new()
	saltar.text = "⏭ Saltar"
	saltar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	saltar.offset_left = -130
	saltar.offset_top = 16
	saltar.offset_right = -20
	saltar.pressed.connect(cerrar)
	add_child(saltar)
	## El rótulo de abajo, el de la tele: aparece en el tercer plano.
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.offset_left = 40
	panel.offset_top = -170
	panel.offset_bottom = -40
	panel.add_theme_stylebox_override("panel", Tema.caja(Color(Color(mio.color_kit1()).darkened(0.55), 0.92), Tema.RADIO, Tema.ORO))
	var v := VBoxContainer.new()
	panel.add_child(v)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	v.add_child(fila)
	fila.add_child(Tema.etiqueta(Tema.TAM_TITULO + 18, Tema.ORO, str(maxi(j.dorsal, 1))))
	fila.add_child(Tema.etiqueta(Tema.TAM_TITULO + 8, Color.WHITE, j.nombre.to_upper()))
	v.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Color(0.9, 0.92, 0.95), "%s · %d años · media %d  ·  %s" % [
		j.pos_e, j.edad, j.ovr, ("llega desde %s" % Nombres.visible(de.nombre)) if de != null else "llega libre"]))
	panel.modulate.a = 0.0
	add_child(panel)
	_rotulo = panel

## La cámara según el tiempo: una función pura del reloj, así se puede
## comprobar cada plano sin esperar.
func _colocar_camara(t: float) -> void:
	var mira := Vector3(0, 1.2, 0)
	var pos: Vector3
	if t < PLANO_2:
		var k := t / PLANO_2
		var a := lerpf(-1.2, 0.2, k)
		var r := lerpf(95.0, 60.0, k)
		pos = Vector3(cos(a) * r, lerpf(48.0, 26.0, k), sin(a) * r)
		mira = Vector3(0, 0, 0)
	elif t < PLANO_3:
		var k := smoothstep(0.0, 1.0, (t - PLANO_2) / (PLANO_3 - PLANO_2))
		var a := lerpf(0.55, 0.15, k)
		var r := lerpf(14.0, 4.2, k)
		pos = Vector3(cos(a) * r, lerpf(4.5, 1.5, k), sin(a) * r)
		mira = Vector3(0, lerpf(0.6, 1.1, k), 0)
	else:
		var k := clampf((t - PLANO_3) / (DURACION - PLANO_3), 0.0, 1.0)
		var a := lerpf(0.12, -0.05, k)
		pos = Vector3(cos(a) * lerpf(3.2, 2.8, k), 1.55, sin(a) * lerpf(3.2, 2.8, k))
		mira = Vector3(0, 1.35, 0)
	_cam.position = pos
	_cam.look_at(mira, Vector3.UP)

## La primera animación de la lista que tenga el jugador, con fundido.
func _tocar(nombres: Array) -> String:
	if not is_instance_valid(_ap):
		return ""
	for n: String in nombres:
		if _ap.has_animation(n):
			_ap.play(n, 0.35)
			return n
	return ""

func plano(t: float) -> int:
	return 1 if t < PLANO_2 else (2 if t < PLANO_3 else 3)

func _process(delta: float) -> void:
	if _cerrando:
		return
	_t += delta
	_colocar_camara(_t)
	if _t >= PLANO_3 and not _rotulo_visto:
		_rotulo_visto = true
		_tocar(["saludar_publico", "celebrar", "aplaudir"])
		create_tween().tween_property(_rotulo, "modulate:a", 1.0, 0.4)
		Sonido.toca("flashes", Sonido.Bus.INTERFAZ)
	## Flashes en los dos últimos planos, a golpes cortos.
	for i in _flashes.size():
		var fase := fmod(_t * (1.3 + 0.37 * float(i)) + float(i) * 0.41, 1.0)
		_flashes[i].light_energy = 7.0 if _t > PLANO_2 and fase < 0.05 else 0.0
	if _t >= DURACION:
		cerrar()

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		cerrar()
		get_viewport().set_input_as_handled()

func cerrar() -> void:
	if _cerrando:
		return
	_cerrando = true
	terminada.emit()
	if not is_inside_tree():
		queue_free()
		return
	var tw := create_tween()
	tw.tween_property(_velo, "color:a", 1.0, 0.35)
	tw.tween_callback(queue_free)
