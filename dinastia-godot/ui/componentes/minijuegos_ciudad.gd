class_name MinijuegosCiudad
extends Control
## LOS MINIJUEGOS DE LA CIUDAD (7-10-2026, pedido: «puedes crear minijuegos
## dentro de la ciudad»). Se abren al llegar a un lugar (E en el modo a pie o
## al volante, o clic en el mapa):
##   · Plaza Mayor → AUTÓGRAFOS: los hinchas asoman entre la gente; tócalos
##     antes de que se vayan (30 s). Más reputación del club, más hinchas.
##   · Puerto → PESCA: el corcho flota; cuando grita «¡PICA!», tienes un
##     instante para tirar. Seis lanzadas.
##   · Karting → CONTRARRELOJ: tres vueltas al óvalo con tu kart (flechas o
##     WASD); salirte del asfalto te frena.
##   · Universidad / Cine → la TRIVIA del club.  · Parques → PENALES con los
##     chicos del barrio.
## Todo con un generador propio: jugar no cambia la partida.

const LUGARES := {
	"ciudad_plaza_mayor": "autografos", "ciudad_puerto": "pesca", "karting": "karting",
	"ciudad_universidad": "trivia", "ciudad_cine": "trivia", "ciudad_parque": "penales",
	"ciudad_parque_lago": "penales", "ciudad_instituto": "trivia",
}

static var records := {"autografos": 0, "pesca": 0, "karting": 0.0}

static func juego_de(k: String) -> String:
	return String(LUGARES.get(k, ""))

static func abrir(padre: Control, juego: String, club: Club) -> Control:
	var mundo: Mundo = null
	var p := padre
	while p != null and mundo == null:
		if p.get("mundo") is Mundo:
			mundo = p.get("mundo")
		p = p.get_parent() as Control
	match juego:
		"trivia":
			if mundo != null:
				return TriviaClub.mostrar(padre, mundo)
			return null
		"penales":
			if mundo != null:
				return MinijuegoPenales.mostrar(padre, mundo)
			return null
	var n := MinijuegosCiudad.new()
	n.juego = juego
	n.rep = club.rep if club != null else 60
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	padre.add_child(n)
	n._montar()
	return n


## EN 3D (7-10-2026, pedido: «los mini juegos también deben ser 3D con
## animaciones»): cada juego monta su escena con `Mini3D` -la plaza con su
## fuente y los hinchas que se acercan caminando, el muelle con la caña, el
## corcho y el pez que salta, el circuito con su kart y los rivales- y la
## interfaz (título, aviso, botones) queda encima.

var juego := ""
var rep := 60
var _rng := RandomNumberGenerator.new()
var _titulo: Label
var _aviso: Label
var _t := 0.0
var _puntos := 0
var _activo := false
var _v := {}
var _cam: Camera3D
var _raiz: Node3D

func _montar() -> void:
	_rng.seed = Time.get_ticks_usec()
	_v = Mini3D.vista(self, Calidad.DIA)
	_cam = _v["cam"]
	_raiz = _v["raiz"]
	var banda := ColorRect.new()
	banda.color = Color(0, 0, 0, 0.45)
	banda.set_anchors_preset(Control.PRESET_TOP_WIDE)
	banda.offset_bottom = 58
	banda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banda)
	_titulo = _lbl("", 22, Color.WHITE)
	_titulo.position = Vector2(24, 16)
	add_child(_titulo)
	_aviso = _lbl("", 20, Color(1, 0.92, 0.6))
	_aviso.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_aviso.offset_top = -70
	_aviso.offset_left = -460
	_aviso.offset_right = 460
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.add_theme_constant_override("outline_size", 6)
	_aviso.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	add_child(_aviso)
	var salir := Button.new()
	salir.text = "Salir"
	salir.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	salir.offset_left = -110
	salir.offset_right = -20
	salir.offset_top = 12
	salir.offset_bottom = 48
	salir.pressed.connect(queue_free)
	add_child(salir)
	match juego:
		"autografos":
			_autografos_empezar()
		"pesca":
			_pesca_empezar()
		"karting":
			_kart_empezar()

func _lbl(t: String, tam: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _process(delta: float) -> void:
	match juego:
		"autografos":
			_autografos(delta)
		"pesca":
			_pesca(delta)
		"karting":
			_kart(delta)

func _gui_input(ev: InputEvent) -> void:
	var pos := Vector2(-1, -1)
	if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		pos = (ev as InputEventMouseButton).position
	elif ev is InputEventScreenTouch and (ev as InputEventScreenTouch).pressed:
		pos = (ev as InputEventScreenTouch).position
	if pos.x < 0.0:
		return
	match juego:
		"autografos":
			_firmar_en(pos)
		"pesca":
			_tirar()
	accept_event()

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and (ev as InputEventKey).pressed and not (ev as InputEventKey).echo:
		var k := (ev as InputEventKey).keycode
		if k == KEY_SPACE or k == KEY_E:
			if juego == "pesca":
				_tirar()
			elif juego == "autografos":
				_firmar_mas_cercano()
			get_viewport().set_input_as_handled()
		elif k == KEY_ESCAPE:
			queue_free()
			get_viewport().set_input_as_handled()

## Edificios de fondo: bloques con ventanas, para que ningún juego flote en la nada.
func _fondo_ciudad(centro: Vector3, radio: float, desde: float, hasta: float, n: int) -> void:
	var cols := [Color(0.86, 0.8, 0.7), Color(0.75, 0.62, 0.5), Color(0.92, 0.9, 0.86), Color(0.6, 0.66, 0.72), Color(0.8, 0.72, 0.6)]
	var vidrio := Mini3D.mat(Color(0.25, 0.32, 0.4), 0.2)
	for i in n:
		var a := lerpf(desde, hasta, (float(i) + 0.5) / float(n))
		var alto := _rng.randf_range(9.0, 24.0)
		var ancho := _rng.randf_range(7.0, 11.0)
		var p := centro + Vector3(sin(a), 0, cos(a)) * radio
		var b := Mini3D.caja(_raiz, p + Vector3(0, alto * 0.5, 0), Vector3(ancho, alto, 7.0), Mini3D.mat(cols[i % cols.size()], 0.85))
		b.rotation.y = a
		## Ventanas en la cara que mira al centro.
		for f in int(alto / 3.2):
			for c in int(ancho / 2.4):
				var v := Mini3D.caja(b, Vector3(-ancho * 0.5 + 1.4 + float(c) * 2.4, -alto * 0.5 + 2.2 + float(f) * 3.2, -3.52), Vector3(1.2, 1.5, 0.05), vidrio)
				v.rotation.y = 0.0

# ------------------------------------------------------------- AUTÓGRAFOS
## La Plaza Mayor: tú en medio, junto a la fuente; los hinchas llegan
## caminando desde la gente, levantan la mano y te piden la firma. Tócalos (o
## E) antes de que se cansen: firmas, el hincha lo celebra y se va feliz. Si
## tardas, se va con las manos en la cabeza.

var _yo := {}
var _hinchas: Array = []   ## {d, estado, t, angulo, objetivo, firma(Label3D)}
var _prox_hincha := 0.0

func _autografos_empezar() -> void:
	_t = 30.0
	_activo = true
	_aviso.text = "¡Toca a los hinchas que levantan la mano antes de que se vayan! (clic, toque o E)"
	## La plaza: adoquín, el círculo central, la fuente, bancos y farolas.
	Mini3D.caja(_raiz, Vector3(0, -0.1, 0), Vector3(140, 0.2, 140), Mini3D.mat(Color(0.5, 0.45, 0.4), 0.9))
	## Adoquines en damero suave y el círculo central de piedra más oscura.
	var lose := Mini3D.mat(Color(0.56, 0.5, 0.44), 0.9)
	for i in range(-8, 9):
		for j in range(-8, 9):
			if (i + j) % 2 == 0 and Vector2(i, j).length() > 4.6:
				Mini3D.caja(_raiz, Vector3(float(i) * 2.0, 0.005, float(j) * 2.0), Vector3(2.0, 0.01, 2.0), lose)
	Mini3D.cilindro(_raiz, Vector3(0, 0.01, 0), 9.0, 0.04, Mini3D.mat(Color(0.4, 0.36, 0.33), 0.85))
	Mini3D.cilindro(_raiz, Vector3(0, 0.02, 0), 8.4, 0.04, Mini3D.mat(Color(0.62, 0.58, 0.52), 0.85))
	var piedra := Mini3D.mat(Color(0.82, 0.8, 0.76), 0.7)
	var agua := Mini3D.mat(Color(0.3, 0.55, 0.75, 0.85), 0.05)
	Mini3D.cilindro(_raiz, Vector3(0, 0.4, -7.5), 3.4, 0.8, piedra)
	Mini3D.cilindro(_raiz, Vector3(0, 0.78, -7.5), 3.1, 0.1, agua)
	Mini3D.cilindro(_raiz, Vector3(0, 1.6, -7.5), 0.35, 2.4, piedra)
	Mini3D.cilindro(_raiz, Vector3(0, 2.9, -7.5), 1.3, 0.25, piedra, 0.9)
	var chorro := Mini3D.cilindro(_raiz, Vector3(0, 3.6, -7.5), 0.12, 1.2, Mini3D.mat(Color(0.7, 0.85, 1.0, 0.6), 0.05, 0.3), 0.04)
	chorro.name = "Chorro"
	var madera := Mini3D.mat(Color(0.5, 0.33, 0.2), 0.8)
	var hierro := Mini3D.mat(Color(0.12, 0.12, 0.13), 0.4)
	for k in 6:
		var a := TAU * float(k) / 6.0 + 0.5
		var p := Vector3(sin(a), 0, cos(a)) * 12.5
		var banco := Mini3D.caja(_raiz, p + Vector3(0, 0.45, 0), Vector3(2.2, 0.12, 0.6), madera)
		banco.rotation.y = a
		Mini3D.caja(banco, Vector3(0, 0.35, -0.28), Vector3(2.2, 0.5, 0.08), madera)
		var f := p * 1.25
		Mini3D.cilindro(_raiz, f + Vector3(0, 2.2, 0), 0.08, 4.4, hierro)
		Mini3D.esfera(_raiz, f + Vector3(0, 4.5, 0), 0.32, Mini3D.mat(Color(1.0, 0.92, 0.7), 0.3, 1.2))
	_fondo_ciudad(Vector3.ZERO, 46.0, -PI * 0.95, PI * 0.95, 14)
	## Tú, con ropa de calle, mirando a la cámara.
	_yo = Mini3D.persona(_raiz, _rng, Vector3(0, 0, 0))
	if not _yo.is_empty():
		Mini3D.anim(_yo, "saludo_mano")
	## Gente de relleno al fondo, paseando o mirando.
	for k in 6:
		var a := _rng.randf_range(-2.4, 2.4)
		var d := Mini3D.persona(_raiz, _rng, Vector3(sin(a), 0, -cos(a)) * _rng.randf_range(17.0, 24.0))
		if not d.is_empty():
			(d["nodo"] as Node3D).rotation.y = _rng.randf() * TAU
			Mini3D.anim(d, ["aplaudir", "parado", "cruzar_brazos", "saludar_publico"][k % 4], "")
	## El grupo de hinchas que se acercan (se reciclan).
	for k in 7:
		var d := Mini3D.persona(_raiz, _rng, Vector3(0, -50, 0))
		if d.is_empty():
			continue
		var firma := Label3D.new()
		firma.text = "✍️"
		firma.font_size = 96
		firma.pixel_size = 0.009
		firma.outline_size = 18
		firma.outline_modulate = Color(0.1, 0.1, 0.1, 0.85)
		firma.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		firma.no_depth_test = true
		firma.position = Vector3(0, 2.25, 0)
		firma.visible = false
		(d["nodo"] as Node3D).add_child(firma)
		_hinchas.append({"d": d, "estado": "fuera", "t": 0.0, "firma": firma, "objetivo": Vector3.ZERO, "salida": Vector3.ZERO})
	_cam.position = Vector3(0, 3.4, 8.6)
	_cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)

func _caminar_hacia(n: Node3D, destino: Vector3, vel: float, delta: float) -> bool:
	var d := destino - n.position
	d.y = 0.0
	if d.length() < 0.15:
		return true
	n.rotation.y = lerp_angle(n.rotation.y, atan2(d.x, d.z), clampf(delta * 8.0, 0.0, 1.0))
	n.position += d.normalized() * minf(vel * delta, d.length())
	return false

func _autografos(delta: float) -> void:
	var ch := _raiz.get_node_or_null("Chorro") as Node3D
	if ch != null:
		ch.scale.y = 1.0 + sin(Time.get_ticks_msec() * 0.008) * 0.12
	for h: Dictionary in _hinchas:
		var n: Node3D = h["d"]["nodo"]
		match String(h["estado"]):
			"llega":
				if _caminar_hacia(n, h["objetivo"], 3.4, delta):
					h["estado"] = "espera"
					## Paciencia: menos cuanto más avanzado el reloj.
					h["t"] = _rng.randf_range(1.6, 2.6) * lerpf(0.8, 1.0, _t / 30.0)
					var mira := -n.position
					n.rotation.y = atan2(mira.x, mira.z)
					Mini3D.anim(h["d"], "saludar_publico", "")
					(h["firma"] as Label3D).visible = true
			"espera":
				h["t"] = float(h["t"]) - delta
				var f: Label3D = h["firma"]
				f.position.y = 2.25 + absf(sin(Time.get_ticks_msec() * 0.01)) * 0.18
				f.modulate = Color.WHITE if float(h["t"]) > 0.6 else Color(1, 0.5, 0.4)
				if float(h["t"]) <= 0.0:
					h["estado"] = "triste"
					h["t"] = 1.0
					f.visible = false
					Mini3D.anim(h["d"], "manos_cabeza", "")
			"firmado", "triste":
				h["t"] = float(h["t"]) - delta
				if float(h["t"]) <= 0.0:
					h["estado"] = "se_va"
					Mini3D.anim(h["d"], "caminar", "")
			"se_va":
				if _caminar_hacia(n, h["salida"], 2.2, delta):
					h["estado"] = "fuera"
					n.position.y = -50.0
	if not _activo:
		return
	_t -= delta
	_titulo.text = "✍️ Autógrafos en la Plaza Mayor  ·  %d s  ·  firmados: %d  ·  récord: %d" % [int(ceil(_t)), _puntos, records["autografos"]]
	if _t <= 0.0:
		_activo = false
		records["autografos"] = maxi(int(records["autografos"]), _puntos)
		_aviso.text = "¡Firmaste %d autógrafos! %s" % [_puntos, "La plaza entera coreó tu nombre." if _puntos >= 14 else "La gente se fue contenta."]
		Mini3D.anim(_yo, "celebrar" if _puntos >= 14 else "aplaudir", "parado")
		for h: Dictionary in _hinchas:
			if String(h["estado"]) in ["llega", "espera"]:
				h["estado"] = "triste"
				h["t"] = 0.2
				(h["firma"] as Label3D).visible = false
		return
	_prox_hincha -= delta
	if _prox_hincha <= 0.0:
		## Con más reputación, llegan más seguido.
		_prox_hincha = _rng.randf_range(0.7, 1.4) * lerpf(1.3, 0.7, float(rep) / 100.0)
		for h: Dictionary in _hinchas:
			if String(h["estado"]) != "fuera":
				continue
			## Llegan por los lados, desde la gente que pasea.
			var lado := -1.0 if _rng.randf() < 0.5 else 1.0
			var a := lado * _rng.randf_range(1.2, 2.3)
			var n: Node3D = h["d"]["nodo"]
			n.position = Vector3(sin(a) * 10.0, 0, cos(a) * 8.0)
			h["salida"] = Vector3(sin(a + lado * _rng.randf_range(0.0, 0.4)) * 18.0, 0, cos(a) * 14.0)
			## Un hueco libre alrededor tuyo (no se pisan entre ellos).
			var ang := a
			for intento in 6:
				var libre := true
				for o: Dictionary in _hinchas:
					if o != h and String(o["estado"]) in ["llega", "espera"] and (o["objetivo"] as Vector3).distance_to(Vector3(sin(ang), 0, cos(ang)) * 2.6) < 1.3:
						libre = false
				if libre:
					break
				ang = _rng.randf_range(-1.3, 1.3)
			h["objetivo"] = Vector3(sin(ang), 0, cos(ang)) * 2.6
			h["estado"] = "llega"
			Mini3D.anim(h["d"], "caminar", "")
			break

func _firmar(h: Dictionary) -> void:
	_puntos += 1
	h["estado"] = "firmado"
	h["t"] = 1.3
	(h["firma"] as Label3D).visible = false
	Mini3D.anim(h["d"], ["celebrar", "puno_al_aire", "aplaudir", "baile"][_rng.randi() % 4], "")
	## Te giras hacia él y firmas.
	var n: Node3D = h["d"]["nodo"]
	if not _yo.is_empty():
		var yo: Node3D = _yo["nodo"]
		var tw := create_tween()
		tw.tween_property(yo, "rotation:y", atan2(n.position.x, n.position.z), 0.15)
		Mini3D.anim(_yo, "saludo_mano", "parado")
	Sonido.toca("cambio", Sonido.Bus.INTERFAZ)

func _firmar_en(pos: Vector2) -> void:
	if not _activo:
		return
	var mejor := {}
	var dist := 70.0
	for h: Dictionary in _hinchas:
		if String(h["estado"]) != "espera":
			continue
		var n: Node3D = h["d"]["nodo"]
		for alto: float in [1.0, 1.6, 2.2]:
			var q := _cam.unproject_position(n.position + Vector3(0, alto, 0))
			if q.distance_to(pos) < dist:
				dist = q.distance_to(pos)
				mejor = h
	if not mejor.is_empty():
		_firmar(mejor)

func _firmar_mas_cercano() -> void:
	if not _activo:
		return
	var mejor := {}
	var menos := INF
	for h: Dictionary in _hinchas:
		if String(h["estado"]) == "espera" and float(h["t"]) < menos:
			menos = float(h["t"])
			mejor = h
	if not mejor.is_empty():
		_firmar(mejor)

# ------------------------------------------------------------- PESCA
## El muelle del puerto fluvial: lanzas la caña (el corcho vuela y cae al
## agua), esperas viendo cómo flota, y cuando se hunde y salpica -«¡PICA!»-
## tienes un instante para tirar. El pez sale del agua dando la vuelta y cae
## en el muelle. Seis lanzadas.

var _lanzadas := 0
var _estado_pesca := "espera"   ## lanzando / espera / pica / fin
var _capturas: Array = []
var _cana: Node3D
var _punta: Node3D
var _corcho: Node3D
var _sedal: MeshInstance3D
var _sedal_mesh: ImmediateMesh
var _corcho_base := Vector3(0.6, 0.05, -10.0)
var _agua_mat: ShaderMaterial
var _bote: Node3D
const PECES := [["🐟 una mojarra", 1, Color(0.7, 0.72, 0.6)], ["🐠 un pez payaso (¿en un río?)", 2, Color(1.0, 0.5, 0.1)],
	["🐡 un pez globo", 2, Color(0.9, 0.8, 0.4)], ["🦈 ¡un tiburón de río!", 5, Color(0.45, 0.5, 0.58)],
	["🥾 una bota vieja", 0, Color(0.3, 0.2, 0.12)], ["🐟 una trucha", 3, Color(0.55, 0.6, 0.45)]]

const SHADER_AGUA := """
shader_type spatial;
render_mode cull_disabled;
uniform vec4 color_hondo : source_color = vec4(0.03, 0.12, 0.16, 1.0);
uniform vec4 color_claro : source_color = vec4(0.1, 0.26, 0.3, 1.0);
void vertex() {
	float t = TIME;
	VERTEX.y += sin(VERTEX.x * 0.35 + t * 1.3) * 0.08 + cos(VERTEX.z * 0.5 + t * 1.1) * 0.06;
}
void fragment() {
	float t = TIME;
	vec2 p = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
	float r = sin(p.x * 1.7 + t * 1.8) * cos(p.y * 1.3 - t * 1.4);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = mix(color_hondo.rgb, color_claro.rgb, 0.5 + 0.25 * r) + vec3(fres * 0.12);
	ROUGHNESS = 0.18;
	METALLIC = 0.1;
	SPECULAR = 0.7;
}
"""

func _pesca_empezar() -> void:
	## El río: un plano con oleaje propio.
	var agua := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(260, 260)
	pm.subdivide_width = 80
	pm.subdivide_depth = 80
	agua.mesh = pm
	var sh := Shader.new()
	sh.code = SHADER_AGUA
	_agua_mat = ShaderMaterial.new()
	_agua_mat.shader = sh
	agua.material_override = _agua_mat
	agua.position = Vector3(0, -0.1, -60)
	_raiz.add_child(agua)
	## El muelle de tablones sobre pilotes, con la orilla detrás.
	var madera := Mini3D.mat(Color(0.48, 0.34, 0.22), 0.85)
	var madera2 := Mini3D.mat(Color(0.4, 0.28, 0.18), 0.9)
	for k in 14:
		Mini3D.caja(_raiz, Vector3(0, 0.62, 6.0 - float(k) * 0.62), Vector3(3.2, 0.1, 0.56), madera if k % 2 == 0 else madera2)
	for z: float in [5.8, 2.5, -0.8, -2.0]:
		for x: float in [-1.5, 1.5]:
			Mini3D.cilindro(_raiz, Vector3(x, -0.4, z), 0.14, 2.2, madera2)
	Mini3D.caja(_raiz, Vector3(0, 0.0, 12.0), Vector3(80, 1.2, 12), Mini3D.mat(Color(0.35, 0.5, 0.25), 0.9))
	Mini3D.caja(_raiz, Vector3(0, 0.3, 7.5), Vector3(80, 0.6, 3), Mini3D.mat(Color(0.55, 0.52, 0.46), 0.9))
	## Bolardos, un balde y una caja de cebos.
	Mini3D.cilindro(_raiz, Vector3(-1.3, 0.85, -1.6), 0.12, 0.4, Mini3D.mat(Color(0.15, 0.15, 0.16), 0.4))
	Mini3D.cilindro(_raiz, Vector3(1.1, 0.85, 1.2), 0.22, 0.42, Mini3D.mat(Color(0.25, 0.45, 0.75), 0.5), 0.26)
	Mini3D.caja(_raiz, Vector3(-1.0, 0.8, 2.0), Vector3(0.6, 0.3, 0.4), Mini3D.mat(Color(0.75, 0.2, 0.15), 0.5))
	## La otra orilla: árboles y la ciudad.
	var hoja := Mini3D.mat(Color(0.2, 0.42, 0.2), 0.9)
	var tronco := Mini3D.mat(Color(0.35, 0.24, 0.15), 0.9)
	Mini3D.caja(_raiz, Vector3(0, 0.2, -95), Vector3(260, 2.0, 14), Mini3D.mat(Color(0.32, 0.46, 0.24), 0.9))
	for k in 26:
		var x := -120.0 + float(k) * 9.5 + _rng.randf_range(-2, 2)
		Mini3D.cilindro(_raiz, Vector3(x, 2.2, -92), 0.3, 2.4, tronco)
		Mini3D.cilindro(_raiz, Vector3(x, 5.0, -92), 2.2, 4.5, hoja, 0.0)
	_fondo_ciudad(Vector3(0, 0, -40), 72.0, PI * 0.82, PI * 1.18, 12)
	## Un bote amarrado que se mece.
	_bote = Node3D.new()
	_bote.position = Vector3(-6.5, 0.1, -3.0)
	_raiz.add_child(_bote)
	Mini3D.caja(_bote, Vector3(0, 0.25, 0), Vector3(1.6, 0.5, 4.2), Mini3D.mat(Color(0.85, 0.85, 0.82), 0.6))
	Mini3D.caja(_bote, Vector3(0, 0.52, 0), Vector3(1.7, 0.06, 4.3), Mini3D.mat(Color(0.1, 0.35, 0.6), 0.6))
	Mini3D.caja(_bote, Vector3(0, 0.45, 0.4), Vector3(1.4, 0.08, 0.4), madera)
	## Tú, en la punta del muelle, mirando al río.
	_yo = Mini3D.persona(_raiz, _rng, Vector3(0, 0.67, -1.6))
	if not _yo.is_empty():
		(_yo["nodo"] as Node3D).rotation.y = PI
		Mini3D.anim(_yo, "brazos_al_frente", "")
	## La caña: gira desde la mano (pivote) y lleva la punta al final.
	_cana = Node3D.new()
	_cana.position = Vector3(0.12, 1.62, -2.15)
	_raiz.add_child(_cana)
	var vara := Mini3D.cilindro(_cana, Vector3(0, 0, -1.4), 0.025, 2.8, Mini3D.mat(Color(0.15, 0.12, 0.1), 0.4), 0.008)
	vara.rotation.x = PI * 0.5
	Mini3D.cilindro(_cana, Vector3(0.05, -0.02, -0.15), 0.05, 0.08, Mini3D.mat(Color(0.7, 0.7, 0.72), 0.3)).rotation.z = PI * 0.5
	_punta = Node3D.new()
	_punta.position = Vector3(0, 0, -2.8)
	_cana.add_child(_punta)
	_cana.rotation.x = 0.55
	## El corcho rojo y blanco.
	_corcho = Node3D.new()
	_raiz.add_child(_corcho)
	Mini3D.esfera(_corcho, Vector3(0, 0.06, 0), 0.11, Mini3D.mat(Color(0.9, 0.12, 0.1), 0.4))
	Mini3D.esfera(_corcho, Vector3(0, 0.14, 0), 0.08, Mini3D.mat(Color.WHITE, 0.4))
	Mini3D.cilindro(_corcho, Vector3(0, 0.26, 0), 0.012, 0.16, Mini3D.mat(Color(0.95, 0.85, 0.2), 0.4))
	_corcho.visible = false
	## El sedal: una línea que va de la punta al corcho.
	_sedal_mesh = ImmediateMesh.new()
	_sedal = MeshInstance3D.new()
	_sedal.mesh = _sedal_mesh
	var ms := StandardMaterial3D.new()
	ms.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ms.albedo_color = Color(0.95, 0.95, 0.95, 0.85)
	ms.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_sedal.material_override = ms
	_raiz.add_child(_sedal)
	_cam.position = Vector3(3.6, 3.1, 3.4)
	_cam.look_at(Vector3(-0.4, 0.4, -7.5), Vector3.UP)
	var tirar := Button.new()
	tirar.text = "¡TIRAR! (espacio)"
	tirar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	tirar.offset_top = -120
	tirar.offset_bottom = -80
	tirar.offset_left = -110
	tirar.offset_right = 110
	tirar.pressed.connect(_tirar)
	add_child(tirar)
	_nueva_lanzada()

func _nueva_lanzada() -> void:
	if _lanzadas >= 6:
		_estado_pesca = "fin"
		records["pesca"] = maxi(int(records["pesca"]), _puntos)
		_aviso.text = "Fin de la pesca: %d puntos. %s" % [_puntos, ", ".join(_capturas) if not _capturas.is_empty() else "Hoy no picó nada."]
		_corcho.visible = false
		Mini3D.anim(_yo, "celebrar" if _puntos >= 10 else "parado", "parado")
		return
	_estado_pesca = "lanzando"
	_aviso.text = "Lanzada %d de 6…" % (_lanzadas + 1)
	_corcho_base = Vector3(_rng.randf_range(-1.6, 2.4), 0.0, _rng.randf_range(-11.5, -8.5))
	## La caña va atrás y sale disparada; el corcho vuela en arco al agua.
	var tw := create_tween()
	tw.tween_property(_cana, "rotation:x", 1.25, 0.35).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_cana, "rotation:x", -0.25, 0.22).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(func() -> void:
		_corcho.visible = true
		_corcho.position = _punta.global_position)
	tw.tween_method(func(f: float) -> void:
		var a := _punta.global_position
		var p := a.lerp(_corcho_base, f)
		p.y = lerpf(a.y, _corcho_base.y, f) + sin(f * PI) * 2.5
		_corcho.position = p, 0.0, 1.0, 0.75)
	tw.tween_property(_cana, "rotation:x", 0.15, 0.4)
	tw.tween_callback(func() -> void:
		_salpicar(_corcho_base, 0.6)
		_estado_pesca = "espera"
		_t = _rng.randf_range(1.5, 4.5)
		_aviso.text = "Lanzada %d de 6. Espera a que pique…" % (_lanzadas + 1))

## Salpicadura: un anillo que se abre en el agua y gotas que saltan.
func _salpicar(p: Vector3, fuerza: float) -> void:
	var anillo := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.18
	tm.outer_radius = 0.24
	anillo.mesh = tm
	anillo.material_override = Mini3D.mat(Color(0.9, 0.95, 1.0, 0.7), 0.1)
	anillo.position = p + Vector3(0, 0.03, 0)
	_raiz.add_child(anillo)
	var tw := anillo.create_tween().set_parallel(true)
	tw.tween_property(anillo, "scale", Vector3(5, 1, 5) * fuerza + Vector3.ONE, 0.9)
	tw.tween_property(anillo.material_override, "albedo_color:a", 0.0, 0.9)
	tw.chain().tween_callback(anillo.queue_free)
	for k in int(6 * fuerza) + 3:
		var g := Mini3D.esfera(_raiz, p, 0.04, Mini3D.mat(Color(0.85, 0.92, 1.0, 0.8), 0.1))
		var dest := p + Vector3(_rng.randf_range(-0.5, 0.5), 0, _rng.randf_range(-0.5, 0.5)) * fuerza
		var alto := _rng.randf_range(0.3, 0.8) * fuerza
		var tg := g.create_tween()
		tg.tween_method(func(f: float) -> void:
			g.position = p.lerp(dest, f) + Vector3(0, sin(f * PI) * alto, 0), 0.0, 1.0, 0.5)
		tg.tween_callback(g.queue_free)

func _pesca(delta: float) -> void:
	_titulo.text = "🎣 Pesca en el puerto fluvial  ·  puntos: %d  ·  récord: %d" % [_puntos, records["pesca"]]
	var ms := Time.get_ticks_msec()
	if _bote != null:
		_bote.rotation.z = sin(ms * 0.0011) * 0.05
		_bote.position.y = 0.05 + sin(ms * 0.0013) * 0.05
	if _estado_pesca == "espera" or _estado_pesca == "pica":
		var hundir := 0.0
		var temblor := Vector3.ZERO
		if _estado_pesca == "pica":
			hundir = -0.16 + sin(ms * 0.03) * 0.05
			temblor = Vector3(sin(ms * 0.05) * 0.05, 0, cos(ms * 0.043) * 0.05)
			_cana.rotation.x = 0.0 + sin(ms * 0.04) * 0.05
		_corcho.position = _corcho_base + Vector3(0, sin(ms * 0.004) * 0.04 + hundir, 0) + temblor
	_dibujar_sedal()
	if _estado_pesca in ["fin", "lanzando", "sacando"]:
		return
	_t -= delta
	if _estado_pesca == "espera" and _t <= 0.0:
		_estado_pesca = "pica"
		_t = 0.75
		_aviso.text = "¡¡PICA!!"
		_salpicar(_corcho_base, 0.8)
	elif _estado_pesca == "pica" and _t <= 0.0:
		_lanzadas += 1
		_aviso.text = "Se escapó… demasiado lento."
		Mini3D.anim(_yo, "manos_cabeza", "brazos_al_frente")
		_recoger(1.4)

func _dibujar_sedal() -> void:
	_sedal_mesh.clear_surfaces()
	if not _corcho.visible:
		return
	_sedal_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var a := _punta.global_position
	var b := _corcho.position + Vector3(0, 0.3, 0)
	for k in 13:
		var f := float(k) / 12.0
		var p := a.lerp(b, f)
		p.y -= sin(f * PI) * (0.35 if _estado_pesca != "pica" else 0.05)
		_sedal_mesh.surface_add_vertex(p)
	_sedal_mesh.surface_end()

## Recoge el sedal y prepara la siguiente lanzada.
func _recoger(espera: float) -> void:
	_estado_pesca = "sacando"
	var tw := create_tween()
	tw.tween_interval(espera * 0.5)
	tw.tween_method(func(f: float) -> void:
		_corcho.position = _corcho_base.lerp(_punta.global_position, f), 0.0, 1.0, 0.5)
	tw.tween_callback(func() -> void: _corcho.visible = false)
	tw.tween_interval(espera * 0.5)
	tw.tween_callback(_nueva_lanzada)

func _tirar() -> void:
	if _estado_pesca == "pica":
		var pez: Array = PECES[_rng.randi() % PECES.size()]
		_puntos += int(pez[1])
		_capturas.append(String(pez[0]).split(" ", true, 1)[0])
		_aviso.text = "¡Sacaste %s! (+%d)" % [pez[0], pez[1]]
		_lanzadas += 1
		_estado_pesca = "sacando"
		_cana.rotation.x = 0.9
		create_tween().tween_property(_cana, "rotation:x", 0.15, 0.8)
		_pez_salta(pez)
		Mini3D.anim(_yo, "puno_al_aire" if int(pez[1]) > 0 else "manos_cabeza", "brazos_al_frente")
		_recoger(1.8)
	elif _estado_pesca == "espera":
		_aviso.text = "Tiraste antes de tiempo: se espantó el pez."
		_lanzadas += 1
		Mini3D.anim(_yo, "cabeza_gacha", "brazos_al_frente")
		_recoger(1.2)

## El pez sale del agua dando vueltas y cae en el muelle.
func _pez_salta(pez: Array) -> void:
	var p := Node3D.new()
	_raiz.add_child(p)
	var col: Color = pez[2]
	if String(pez[0]).contains("bota"):
		Mini3D.caja(p, Vector3(0, 0.2, 0), Vector3(0.4, 0.64, 0.24), Mini3D.mat(col, 0.8))
		Mini3D.caja(p, Vector3(0, -0.06, 0.2), Vector3(0.4, 0.2, 0.6), Mini3D.mat(col, 0.8))
	else:
		var tam := 3.2 if String(pez[0]).contains("tiburón") else 2.0
		var cuerpo := Mini3D.esfera(p, Vector3.ZERO, 0.16 * tam, Mini3D.mat(col, 0.3))
		cuerpo.scale = Vector3(0.55, 0.8, 2.0)
		var cola := Mini3D.caja(p, Vector3(0, 0, 0.36 * tam), Vector3(0.03, 0.22, 0.14) * tam, Mini3D.mat(col.darkened(0.2), 0.4))
		cola.rotation.x = 0.4
		Mini3D.esfera(p, Vector3(0.06, 0.04, -0.22) * tam, 0.025, Mini3D.mat(Color.BLACK, 0.2))
	var desde := _corcho_base
	var hasta := Vector3(0.6, 0.8, -1.2)
	_salpicar(desde, 1.0)
	var tw := p.create_tween()
	tw.tween_method(func(f: float) -> void:
		p.position = desde.lerp(hasta, f) + Vector3(0, sin(f * PI) * 3.0, 0)
		p.rotation = Vector3(f * TAU * 1.5, f * 2.0, 0), 0.0, 1.0, 1.1)
	tw.tween_interval(1.0)
	tw.tween_property(p, "scale", Vector3.ONE * 0.01, 0.3)
	tw.tween_callback(p.queue_free)

# ------------------------------------------------------------- KARTING
## El circuito del karting en 3D: un óvalo de dos rectas y dos curvas con
## pianos rojos y blancos, barreras de neumáticos, la grada y la meta a
## cuadros. Tu kart (flechas o WASD) contra tres rivales que siguen la
## trazada; cámara detrás. Tres vueltas; salirte del asfalto te frena.

const KART_VEL := 24.0
const RECTA := 34.0
const RADIO := 22.0
const ANCHO_PISTA := 11.0
var _kart_n: Node3D
var _kp := Vector3(0, 0, RADIO)
var _kr := PI * 0.5
var _kv := 0.0
var _vueltas := 0
var _crono := 0.0
var _empezado := false
var _fin_kart := false
var _paso_arriba := false
var _cuenta := 3.5
var _rivales: Array = []   ## {n, s, v, lado}
var _semaforo: Label
var _mi_total := 0.0

## Punto de la línea central a una distancia `s` (sentido de la carrera:
## recta de abajo hacia +x, curva derecha, recta de arriba hacia -x, curva izquierda).
func _centro_pista(s: float) -> Dictionary:
	var total := 4.0 * RECTA + TAU * RADIO
	s = fposmod(s, total)
	var semi := PI * RADIO
	if s < 2.0 * RECTA:
		return {"p": Vector3(-RECTA + s, 0, RADIO), "dir": Vector3(1, 0, 0)}
	s -= 2.0 * RECTA
	if s < semi:
		var a := s / RADIO
		return {"p": Vector3(RECTA + sin(a) * RADIO, 0, cos(a) * RADIO), "dir": Vector3(cos(a), 0, -sin(a))}
	s -= semi
	if s < 2.0 * RECTA:
		return {"p": Vector3(RECTA - s, 0, -RADIO), "dir": Vector3(-1, 0, 0)}
	s -= 2.0 * RECTA
	var b := s / RADIO
	return {"p": Vector3(-RECTA - sin(b) * RADIO, 0, -cos(b) * RADIO), "dir": Vector3(-cos(b), 0, sin(b))}

func _largo_pista() -> float:
	return 4.0 * RECTA + TAU * RADIO

## Distancia a la línea central (para saber si vas por el asfalto).
func _fuera_de_eje(p: Vector3) -> float:
	if absf(p.x) <= RECTA:
		return absf(absf(p.z) - RADIO)
	return absf(Vector2(p.x - signf(p.x) * RECTA, p.z).length() - RADIO)

func _kart_empezar() -> void:
	_raiz.add_child(_suelo_verde())
	## El asfalto, en una tira de triángulos a lo largo del eje.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 160
	var total := _largo_pista()
	var bordes: Array = []
	for k in n + 1:
		var c := _centro_pista(total * float(k) / float(n))
		var lat := Vector3(-(c["dir"] as Vector3).z, 0, (c["dir"] as Vector3).x)
		bordes.append([(c["p"] as Vector3) - lat * ANCHO_PISTA * 0.5, (c["p"] as Vector3) + lat * ANCHO_PISTA * 0.5, lat, c["p"]])
	for k in n:
		var a: Array = bordes[k]
		var b: Array = bordes[k + 1]
		for v: Vector3 in [a[0], b[0], a[1], a[1], b[0], b[1]]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v + Vector3(0, 0.03, 0))
	var asfalto := MeshInstance3D.new()
	asfalto.mesh = st.commit()
	asfalto.material_override = Mini3D.mat(Color(0.2, 0.2, 0.22), 0.85)
	_raiz.add_child(asfalto)
	## Pianos rojos y blancos en los dos bordes y barreras de neumáticos fuera.
	var rojo := Mini3D.mat(Color(0.85, 0.12, 0.1), 0.6)
	var blanco := Mini3D.mat(Color(0.95, 0.95, 0.95), 0.6)
	var goma := Mini3D.mat(Color(0.08, 0.08, 0.09), 0.9)
	var mm_r: Array[Transform3D] = []
	var mm_b: Array[Transform3D] = []
	var mm_g: Array[Transform3D] = []
	for k in n:
		var a: Array = bordes[k]
		var b: Array = bordes[k + 1]
		for lado in 2:
			var p: Vector3 = ((a[lado] as Vector3) + (b[lado] as Vector3)) * 0.5
			var d: Vector3 = (b[lado] as Vector3) - (a[lado] as Vector3)
			var base := Basis.looking_at(d.normalized(), Vector3.UP) * Basis.from_scale(Vector3(0.9, 0.08, d.length()))
			var lat: Vector3 = a[2]
			var hacia := -1.0 if lado == 0 else 1.0
			var t := Transform3D(base, p + lat * hacia * 0.45 + Vector3(0, 0.05, 0))
			if k % 2 == 0:
				mm_r.append(t)
			else:
				mm_b.append(t)
		if k % 2 == 0:
			var lat2: Vector3 = a[2]
			var fuera: Vector3 = (a[1] as Vector3) + lat2 * 3.2
			for piso in 2:
				mm_g.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.9, 0.35, 0.9)), fuera + Vector3(0, 0.18 + float(piso) * 0.36, 0)))
			var dentro: Vector3 = (a[0] as Vector3) - lat2 * 2.6
			mm_g.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.9, 0.35, 0.9)), dentro + Vector3(0, 0.18, 0)))
	_multimalla(mm_r, BoxMesh.new(), rojo)
	_multimalla(mm_b, BoxMesh.new(), blanco)
	var rueda := CylinderMesh.new()
	rueda.top_radius = 0.5
	rueda.bottom_radius = 0.5
	rueda.height = 1.0
	_multimalla(mm_g, rueda, goma)
	## La meta a cuadros, el pórtico y la grada con público.
	for i in 11:
		for j in 2:
			Mini3D.caja(_raiz, Vector3(0.25 + float(j) * 0.5, 0.04, RADIO - ANCHO_PISTA * 0.5 + 0.5 + float(i)), Vector3(0.5, 0.02, 1.0),
				blanco if (i + j) % 2 == 0 else Mini3D.mat(Color(0.05, 0.05, 0.05), 0.6))
	var portico := Mini3D.mat(Color(0.9, 0.75, 0.1), 0.5)
	for z: float in [RADIO - ANCHO_PISTA * 0.5 - 1.0, RADIO + ANCHO_PISTA * 0.5 + 1.0]:
		Mini3D.caja(_raiz, Vector3(0.5, 2.6, z), Vector3(0.4, 5.2, 0.4), portico)
	Mini3D.caja(_raiz, Vector3(0.5, 5.4, RADIO), Vector3(0.6, 0.9, ANCHO_PISTA + 2.6), portico)
	var cartel := Label3D.new()
	cartel.text = "🏁 META"
	cartel.font_size = 96
	cartel.pixel_size = 0.012
	cartel.position = Vector3(-0.1, 5.4, RADIO)
	cartel.rotation.y = -PI * 0.5
	_raiz.add_child(cartel)
	var grada := Node3D.new()
	grada.position = Vector3(0, 0, RADIO + ANCHO_PISTA * 0.5 + 9.0)
	_raiz.add_child(grada)
	for f in 4:
		Mini3D.caja(grada, Vector3(0, 0.4 + float(f) * 0.8, float(f) * 1.2), Vector3(40, 0.8, 1.2), Mini3D.mat(Color(0.55, 0.57, 0.6), 0.8))
	Mini3D.caja(grada, Vector3(0, 5.6, 2.5), Vector3(42, 0.2, 6.5), Mini3D.mat(Color(0.15, 0.35, 0.6), 0.6))
	for k in 10:
		var d := Mini3D.persona(grada, _rng, Vector3(-15.0 + float(k) * 3.3, 0.8 + float(k % 3) * 0.8, float(k % 3) * 1.2))
		if not d.is_empty():
			(d["nodo"] as Node3D).rotation.y = PI
			Mini3D.anim(d, ["aplaudir", "saludar_publico", "puno_al_aire"][k % 3], "")
	_fondo_ciudad(Vector3.ZERO, 95.0, -PI, PI, 22)
	## Los karts: el tuyo y tres rivales en la parrilla.
	_kart_n = _nuevo_kart(0)
	_kp = Vector3(-6.0, 0, RADIO + 2.0)
	for i in 3:
		var r := _nuevo_kart(i + 1)
		## En la recta de abajo, s = x + RECTA: tú en x = -6, ellos al lado y detrás.
		_rivales.append({"n": r, "s": RECTA - 4.0 - float(i) * 4.5, "v": 0.0, "tope": _rng.randf_range(19.0, 22.5), "lado": [-2.5, 2.5, -2.5][i]})
	_mi_total = _progreso(_kp)
	_semaforo = _lbl("", 80, Color(1, 0.3, 0.2))
	_semaforo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_semaforo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_semaforo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_semaforo.add_theme_constant_override("outline_size", 12)
	_semaforo.add_theme_color_override("font_outline_color", Color.BLACK)
	add_child(_semaforo)
	_aviso.text = "Flechas o WASD. Tres vueltas. ¡Que no se te vaya del asfalto!"
	_colocar_kart(1.0)

func _suelo_verde() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	mi.mesh = pm
	mi.material_override = Mini3D.mat(Color(0.3, 0.5, 0.25), 0.95)
	return mi

func _multimalla(ts: Array[Transform3D], malla: Mesh, m: Material) -> void:
	if ts.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = malla
	mm.instance_count = ts.size()
	for i in ts.size():
		mm.set_instance_transform(i, ts[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = m
	_raiz.add_child(mi)

func _nuevo_kart(i: int) -> Node3D:
	var n := Node3D.new()
	_raiz.add_child(n)
	var k := Mini3D.kit("res://assets/ciudad/kenney_cars_extra/%s.glb" % CityBuilder.KARTS[i % CityBuilder.KARTS.size()])
	if k != null:
		k.scale = Vector3.ONE * 2.2
		n.add_child(k)
	else:
		Mini3D.caja(n, Vector3(0, 0.35, 0), Vector3(1.2, 0.4, 2.0), Mini3D.mat(Color.from_hsv(float(i) * 0.25, 0.8, 0.9), 0.4))
	return n

func _colocar_kart(delta: float) -> void:
	_kart_n.position = _kp
	_kart_n.rotation.y = _kr
	var adelante := Vector3(sin(_kr), 0, cos(_kr))
	var deseo := _kp - adelante * 9.5 + Vector3(0, 4.2, 0)
	_cam.position = _cam.position.lerp(deseo, clampf(delta * 6.0, 0.0, 1.0)) if delta < 1.0 else deseo
	_cam.look_at(_kp + adelante * 3.0 + Vector3(0, 0.8, 0), Vector3.UP)

func _kart(delta: float) -> void:
	## Cuenta atrás: 3, 2, 1, ¡YA!
	if _cuenta > -1.0:
		_cuenta -= delta
		_semaforo.text = str(int(ceil(_cuenta))) if _cuenta > 0.5 else ("¡YA!" if _cuenta > -1.0 else "")
		_semaforo.add_theme_color_override("font_color", Color(1, 0.3, 0.2) if _cuenta > 0.5 else Color(0.3, 1, 0.4))
	if _cuenta <= -1.0 and _semaforo.text != "":
		_semaforo.text = ""
	var arranca := _cuenta <= 0.5
	## Rivales: siguen la trazada con algo de vaivén.
	var total := _largo_pista()
	var delante := 0
	for r: Dictionary in _rivales:
		if arranca and not _fin_kart:
			r["v"] = move_toward(float(r["v"]), float(r["tope"]), 9.0 * delta)
			r["s"] = float(r["s"]) + float(r["v"]) * delta
		var c := _centro_pista(float(r["s"]))
		var dir: Vector3 = c["dir"]
		var lat := Vector3(-dir.z, 0, dir.x)
		var rn: Node3D = r["n"]
		rn.position = (c["p"] as Vector3) + lat * (float(r["lado"]) + sin(float(r["s"]) * 0.05) * 1.2)
		rn.rotation.y = atan2(dir.x, dir.z)
		if float(r["s"]) > _mi_total:
			delante += 1
	if _fin_kart:
		_colocar_kart(delta)
		return
	var x := float(Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A))
	var y := float(Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W)) - float(Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S))
	if not arranca:
		y = 0.0
		x = 0.0
	if y != 0.0:
		_empezado = true
	var en_pista := _fuera_de_eje(_kp) < ANCHO_PISTA * 0.5
	var tope := KART_VEL if en_pista else KART_VEL * 0.35
	_kv = clampf(_kv + y * 16.0 * delta, -6.0, maxf(tope, _kv))
	if y == 0.0:
		_kv = move_toward(_kv, 0.0, 6.0 * delta)
	if _kv > tope:
		_kv = move_toward(_kv, tope, 22.0 * delta)
	## Girar a la izquierda con la flecha izquierda (rumbo +x = derecha en pantalla).
	_kr -= x * 1.9 * delta * clampf(absf(_kv) / 8.0, 0.0, 1.0) * signf(_kv if _kv != 0.0 else 1.0)
	var antes := _kp
	_kp += Vector3(sin(_kr), 0, cos(_kr)) * _kv * delta
	## Las barreras de neumáticos: no se atraviesan.
	if _fuera_de_eje(_kp) > ANCHO_PISTA * 0.5 + 2.4:
		_kp = antes
		_kv *= -0.3
	## Inclinación en las curvas y algo de vibración fuera del asfalto.
	_kart_n.rotation.z = lerpf(_kart_n.rotation.z, x * 0.06 * clampf(_kv / KART_VEL, 0.0, 1.0), delta * 6.0)
	_colocar_kart(delta)
	if not en_pista and absf(_kv) > 3.0:
		_kart_n.position.y = _rng.randf_range(0.0, 0.05)
	var dp := _progreso(_kp) - _progreso(antes)
	if dp > total * 0.5:
		dp -= total
	elif dp < -total * 0.5:
		dp += total
	_mi_total += dp
	if _empezado:
		_crono += delta
	## Vuelta: pasar por la recta de arriba y luego cruzar la meta (x = 0 abajo).
	if _kp.z < -RADIO * 0.5:
		_paso_arriba = true
	if _paso_arriba and _kp.z > 0.0 and antes.x < 0.5 and _kp.x >= 0.5:
		_vueltas += 1
		_paso_arriba = false
	_titulo.text = "🏎️ Karting · vuelta %d de 3 · %.1f s · posición %d.º de 4 · récord: %s" % [mini(_vueltas + 1, 3), _crono, delante + 1,
		("%.1f s" % records["karting"]) if float(records["karting"]) > 0.0 else "—"]
	if _vueltas >= 3:
		_fin_kart = true
		var mejor := float(records["karting"])
		var puesto := "¡Ganaste la carrera!" if delante == 0 else "Llegaste %d.º." % (delante + 1)
		if mejor <= 0.0 or _crono < mejor:
			records["karting"] = _crono
			_aviso.text = "%s ¡Nuevo récord del circuito: %.1f s!" % [puesto, _crono]
		else:
			_aviso.text = "%s Tiempo: %.1f s (récord %.1f s)." % [puesto, _crono, mejor]

## Lo recorrido en la vuelta (para la posición).
func _progreso(p: Vector3) -> float:
	var semi := PI * RADIO
	if absf(p.x) <= RECTA:
		return (p.x + RECTA) if p.z > 0.0 else (2.0 * RECTA + semi + (RECTA - p.x))
	if p.x > 0.0:
		return 2.0 * RECTA + atan2(p.x - RECTA, p.z) * RADIO if p.z > 0.0 else 2.0 * RECTA + (PI - atan2(p.x - RECTA, -p.z)) * RADIO
	var a := atan2(-(p.x + RECTA), -p.z)
	return 4.0 * RECTA + semi + (a if a >= 0.0 else a + TAU) * RADIO
