class_name PrologoAnimado
extends EventoPantallaCompleta
## EL PRÓLOGO DE CINE (9-11 primer corte; 10-11 rehecho: «puedes hacerlo muchísimo mejor», el dueño, que eligió la animación del motor frente al vídeo).
## SIN vídeo: seis escenas dibujadas por el motor y montadas como cine (`PrologoCine`): cada una en CAPAS (fondo `PrologoArte`, primer plano y lo
## vivo de `PrologoEscenas`) que una CÁMARA mueve con paralaje; LUCES aditivas (los focos se encienden uno a uno, la luz del campo en el túnel);
## figuras que caminan y gesticulan; FUNDIDOS cruzados entre escenas; títulos que entran con el espaciado cerrándose; bandas panorámicas, viñeta y
## grano. Abre con el ESCUDO de tu club revelado por un haz de luz y cierra con el escudo y «DINASTÍA». Lo fijo se pinta una vez (barato).
## Controles: tocar un tramo de la barra de arriba salta a esa escena; Esc, Enter, Espacio, cualquier botón del mando o mover el stick lo salta entero.
## Emite `terminado` al acabar o saltarse (el que lo lanza marca el prólogo como visto).
const FUNDIDO := 0.8
const APERTURA := 2.6   ## segundos del escudo sobre negro al empezar
const CIERRE := 3.4     ## segundos del cartel final
const PLANOS := [
	{"escena": "estadio", "dur": 8.4, "cam": [Vector2(0.0, 0.03), Vector2(0.0, -0.02), 1.0, 1.07], "titulo": "Hoy empieza tu dinastía", "texto": "Un club, una ciudad y todo por construir.", "mas": "La grada ya canta tu nombre. Ahora hay que darle motivos.", "sonido": "ovacion"},
	{"escena": "vestuario", "dur": 6.6, "cam": [Vector2(-0.04, 0.0), Vector2(0.04, 0.0), 1.04, 1.08], "titulo": "El vestuario", "texto": "Donde se ganan los partidos antes de jugarlos.", "mas": "Cada camiseta es un jugador que confía en ti. Cuida el ánimo y la charla.", "sonido": "menu_seccion"},
	{"escena": "tunel", "dur": 6.8, "cam": [Vector2(0.0, 0.02), Vector2(0.0, 0.0), 1.0, 1.16], "titulo": "El túnel", "texto": "Por aquí sale el equipo cada partido. Ya se oye la grada.", "mas": "Al final del pasillo está el césped. Y el marcador.", "sonido": "murmullo"},
	{"escena": "banquillo", "dur": 6.6, "cam": [Vector2(0.04, 0.01), Vector2(-0.03, 0.0), 1.06, 1.06], "titulo": "El banquillo", "texto": "Desde aquí dirigirás: cambios, órdenes y la charla del descanso.", "mas": "Noventa minutos que deciden una semana entera.", "sonido": "silbato"},
	{"escena": "despacho", "dur": 6.8, "cam": [Vector2(0.0, -0.02), Vector2(0.02, 0.03), 1.02, 1.1], "titulo": "El despacho del presidente", "texto": "Aquí se firma y aquí se despide. La directiva te mira.", "mas": "Te fijará un objetivo. Cúmplelo y tendrás tiempo; fállalo y no.", "sonido": "menu_seccion"},
	{"escena": "oficina", "dur": 9.6, "cam": [Vector2(0.0, 0.03), Vector2(0.0, 0.0), 1.0, 1.12], "titulo": "Tu oficina", "texto": "Desde tu PC lo gestionas todo. Es hora de empezar.", "mas": "Fichajes, plantilla, estadio y finanzas: todo pasa por aquí.", "sonido": "menu_aceptar"},
]

var _club: Club
var _i := -1
var _t := 0.0
var _vivo := 0.0
var _escena: Control            ## el plano en pantalla (capas + luces + vivo)
var _capas: Dictionary = {}     ## del plano actual: fondo, luces, vivo, frente
var _post: Control              ## acabado de cine, apertura y cierre (encima de los planos)
var _titulo: Label
var _texto: Label
var _fuente_titulo: FontVariation
var _segmentos: Array[Button] = []
var _acabado := false
var _escudo: Texture2D

static func mostrar(pr: Principal) -> PrologoAnimado:
	var v := PrologoAnimado.new()
	v._club = pr.mundo.mi_club()
	v._montar_base(pr)
	v._armar(pr)
	return v

func _c1() -> Color:
	return Color(_club.color1) if _club != null else Tema.ACENTO

func _c2() -> Color:
	return Color(_club.color2) if _club != null else Tema.ORO

func _armar(_pr: Principal) -> void:
	for h in _raiz.get_children():   ## el fondo, los filetes y el contenido genéricos de los eventos: el prólogo pone los suyos
		_raiz.remove_child(h)
		h.queue_free()
	var negro := ColorRect.new()
	negro.color = Color.BLACK
	negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(negro)
	if _club != null:
		_escudo = Escudo.textura(_club, 256)
	_post = Control.new()
	_post.set_anchors_preset(Control.PRESET_FULL_RECT)
	_post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_post.draw.connect(_dibujar_post)
	_post.z_index = 2
	_raiz.add_child(_post)
	## La barra de fases de arriba (sobre la banda negra): un tramo por escena; tocarlo salta a esa escena.
	var barra := HBoxContainer.new()
	barra.set_anchors_preset(Control.PRESET_TOP_WIDE)
	barra.offset_left = 40
	barra.offset_right = -40
	barra.offset_top = 14
	barra.offset_bottom = 22
	barra.add_theme_constant_override("separation", 8)
	barra.z_index = 3
	_raiz.add_child(barra)
	for k in PLANOS.size():
		var b := Button.new()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 8)
		b.focus_mode = Control.FOCUS_NONE
		var idx := k
		b.pressed.connect(func() -> void: _ir(idx))
		barra.add_child(b)
		_segmentos.append(b)
	var saltar := boton(Idiomas.t("Saltar ▶▶"))
	saltar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	saltar.offset_left = -190
	saltar.offset_top = -100
	saltar.offset_right = -40
	saltar.offset_bottom = -44
	saltar.z_index = 3
	saltar.modulate.a = 0.75
	saltar.pressed.connect(_terminar)
	_raiz.add_child(saltar)
	var pie := VBoxContainer.new()
	pie.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	pie.offset_left = 90
	pie.offset_right = -260
	pie.offset_top = -170
	pie.offset_bottom = -40
	pie.add_theme_constant_override("separation", 4)
	pie.z_index = 3
	_raiz.add_child(pie)
	_titulo = etiqueta("", 36, Color(1, 0.93, 0.7), false, false)
	_fuente_titulo = FontVariation.new()
	_fuente_titulo.base_font = _titulo.get_theme_font("font")
	_titulo.add_theme_font_override("font", _fuente_titulo)
	_titulo.add_theme_constant_override("outline_size", 8)
	pie.add_child(_titulo)
	_texto = etiqueta("", 17, Tema.TEXTO, false)
	pie.add_child(_texto)
	if DisplayServer.get_name() != "headless":
		Musica.poner("gloria")   ## la música del prólogo; al volver al menú, `AvanceSemana` la vuelve a ambientar
	_ir(0)

## Salta a la escena `k`: la anterior se funde mientras entra la nueva; el título entra con el espaciado cerrándose.
func _ir(k: int) -> void:
	_i = clampi(k, 0, PLANOS.size() - 1)
	_t = 0.0
	var p: Dictionary = PLANOS[_i]
	if _escena != null:
		var viejo := _escena
		var tw := create_tween()
		tw.tween_property(viejo, "modulate:a", 0.0, FUNDIDO)
		tw.tween_callback(viejo.queue_free)
	_montar_escena(String(p["escena"]))
	_escena.modulate.a = 0.0
	create_tween().tween_property(_escena, "modulate:a", 1.0, FUNDIDO * 0.75)
	_titulo.text = Idiomas.t(String(p["titulo"]))
	_texto.text = Idiomas.t(String(p["texto"])) + "\n" + Idiomas.t(String(p["mas"]))
	_texto.visible_ratio = 0.0
	var retraso := APERTURA if _i == 0 else 0.5
	_titulo.modulate.a = 0.0
	_fuente_titulo.spacing_glyph = 14
	var tt := create_tween().set_parallel(true)
	tt.tween_property(_titulo, "modulate:a", 1.0, 0.9).set_delay(retraso)
	tt.tween_property(_fuente_titulo, "spacing_glyph", 1, 1.4).set_delay(retraso).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for n in _segmentos.size():
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(Tema.ORO, 0.95) if n <= _i else Color(1, 1, 1, 0.18)
		sb.set_corner_radius_all(3)
		for estado in ["normal", "hover", "pressed", "focus"]:
			_segmentos[n].add_theme_stylebox_override(estado, sb)
	if Engine.get_main_loop() is SceneTree and DisplayServer.get_name() != "headless":
		Sonido.toca(String(p["sonido"]))

## Monta las capas de una escena: fondo y primer plano fijos (pintados una vez), luces aditivas y lo vivo.
func _montar_escena(clave: String) -> void:
	_escena = Control.new()
	_escena.set_anchors_preset(Control.PRESET_FULL_RECT)
	_escena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_escena)
	_raiz.move_child(_escena, 1)   ## sobre el negro y detrás del acabado, la barra y los textos
	var tam := get_viewport().get_visible_rect().size
	var c1 := _c1()
	var c2 := _c2()
	var club := _club
	_capas = {}
	_capas["fondo"] = PrologoCine.capa(_escena, tam, func(ci: CanvasItem, w: float, h: float) -> void:
		var oscuro := Color(0.03, 0.06, 0.04)
		PrologoCine.degradado(ci, Rect2(0, 0, w, h), c1.lerp(oscuro, 0.9), c1.lerp(Tema.ORO, 0.16).lerp(oscuro, 0.72))
		PrologoArte.dibujar(ci, clave, w, h, c1, c2, 0.0, club), false)
	for nombre: String in ["luces", "vivo"]:
		var cap := Control.new()
		cap.size = tam * (1.0 + 2.0 * PrologoCine.MARGEN)
		cap.position = -tam * PrologoCine.MARGEN
		cap.pivot_offset = cap.size * 0.5
		cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if nombre == "luces":
			cap.material = PrologoCine.material_luz()
			cap.draw.connect(func() -> void: PrologoEscenas.luces(cap, clave, cap.size.x, cap.size.y, _t, c1))
		else:
			cap.draw.connect(func() -> void: PrologoEscenas.vivo(cap, clave, cap.size.x, cap.size.y, _t, c1, c2))
		_escena.add_child(cap)
		_capas[nombre] = cap
	_capas["frente"] = PrologoCine.capa(_escena, tam, func(ci: CanvasItem, w: float, h: float) -> void:
		PrologoEscenas.frente(ci, clave, w, h, c1, c2))
	_capas["base"] = -tam * PrologoCine.MARGEN
	_capas["tam"] = tam

## La cámara: paneo y acercamiento del plano; el primer plano se mueve 1,6 veces más (paralaje).
func _mover_camara() -> void:
	if _capas.is_empty():
		return
	var p: Dictionary = PLANOS[_i]
	var cam: Array = p["cam"]
	var u := clampf(_t / float(p["dur"]), 0.0, 1.0)
	u = u * u * (3.0 - 2.0 * u)   ## suave al empezar y al acabar
	var tam: Vector2 = _capas["tam"]
	var pan := (cam[0] as Vector2).lerp(cam[1], u) * tam
	var zoom := lerpf(float(cam[2]), float(cam[3]), u)
	var base: Vector2 = _capas["base"]
	for nombre: String in ["fondo", "luces", "vivo"]:
		var n := _capas[nombre] as Control
		n.position = base + pan
		n.scale = Vector2(zoom, zoom)
	var f := _capas["frente"] as Control
	f.position = base + pan * 1.6
	f.scale = Vector2.ONE * (1.0 + (zoom - 1.0) * 1.8)
	(_capas["luces"] as Control).queue_redraw()
	(_capas["vivo"] as Control).queue_redraw()

func _process(delta: float) -> void:
	if _acabado or _i < 0:
		return
	_vivo += delta
	_t += delta
	var retraso := APERTURA if _i == 0 else 0.6
	_texto.visible_ratio = clampf((_t - retraso) / 3.0, 0.0, 1.0)
	if _i == PLANOS.size() - 1:   ## en el cartel final los textos se retiran
		var fuera := clampf((_t - (float(PLANOS[_i]["dur"]) - CIERRE)) / 0.6, 0.0, 1.0)
		_titulo.modulate.a = minf(_titulo.modulate.a, 1.0 - fuera)
		_texto.modulate.a = 1.0 - fuera
	else:
		_texto.modulate.a = 1.0
	_mover_camara()
	_post.queue_redraw()
	if _t >= float(PLANOS[_i]["dur"]):
		if _i >= PLANOS.size() - 1:
			_terminar()
		else:
			_ir(_i + 1)

## Saltarlo entero: Esc / Enter / Espacio, un botón del mando o mover el stick (con un margen al empezar, para no saltarlo por el pulso del stick).
func _input(ev: InputEvent) -> void:
	if _acabado or _vivo < 0.8:
		return
	if (ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]) \
			or (ev is InputEventJoypadButton and ev.pressed) \
			or (ev is InputEventJoypadMotion and absf((ev as InputEventJoypadMotion).axis_value) > 0.7):
		get_viewport().set_input_as_handled()
		_terminar()

func _terminar() -> void:
	if _acabado:
		return
	_acabado = true
	terminado.emit()

# ---------------------------------------------------------------- acabado, apertura y cierre

func _dibujar_post() -> void:
	var w := _post.size.x
	var h := _post.size.y
	PrologoCine.acabado(_post, w, h, _vivo, clampf(_vivo / 1.2, 0.0, 1.0))
	if _i == 0 and _t < APERTURA:   ## APERTURA: el escudo sobre negro, revelado por un haz de luz
		var negro := clampf((APERTURA - _t) / 0.9, 0.0, 1.0)
		_post.draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, negro))
		_cartel(w, h, clampf(_t / 0.8, 0.0, 1.0) * negro, _t, "%s · %d" % [Idiomas.t("TEMPORADA"), Mundo.actual().anio if Mundo.actual() != null else 2026])
	var dur := float(PLANOS[_i]["dur"])
	if _i == PLANOS.size() - 1 and _t > dur - CIERRE:   ## CIERRE: fundido a negro con el escudo y «DINASTÍA»
		var u := clampf((_t - (dur - CIERRE)) / 0.9, 0.0, 1.0)
		_post.draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.92 * u))
		_cartel(w, h, u, _t - (dur - CIERRE), "DINASTÍA")

## El cartel del escudo: escudo en el centro (crece un poco), un haz de luz que lo cruza, el nombre del club y una línea debajo.
func _cartel(w: float, h: float, alfa: float, t: float, linea: String) -> void:
	if alfa <= 0.01:
		return
	var lado := h * 0.26 * (0.94 + 0.06 * clampf(t / 2.0, 0.0, 1.0))
	var centro := Vector2(w * 0.5, h * 0.42)
	PrologoCine.brillo(_post, centro, lado * 1.4, Color(_c1().lerp(Color.WHITE, 0.5), 0.35 * alfa))
	if _escudo != null:
		_post.draw_texture_rect(_escudo, Rect2(centro - Vector2(lado, lado) * 0.5, Vector2(lado, lado)), false, Color(1, 1, 1, alfa))
	var barrido := lerpf(-0.6, 1.6, clampf(t / 1.4, 0.0, 1.0))   ## el haz diagonal que cruza el escudo
	var bx := centro.x - lado * 0.5 + lado * barrido
	_post.draw_polygon(PackedVector2Array([Vector2(bx - lado * 0.08, centro.y - lado * 0.6), Vector2(bx + lado * 0.04, centro.y - lado * 0.6),
		Vector2(bx - lado * 0.2, centro.y + lado * 0.6), Vector2(bx - lado * 0.32, centro.y + lado * 0.6)]), PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.45 * alfa), Color(1, 1, 1, 0.45 * alfa), Color(1, 1, 1, 0.0)]))
	var f := ThemeDB.fallback_font
	var nombre := (_club.nombre if _club != null else "").to_upper()
	_post.draw_string(f, Vector2(0, centro.y + lado * 0.78), nombre, HORIZONTAL_ALIGNMENT_CENTER, w, int(h * 0.05), Color(1, 1, 1, alfa))
	_post.draw_line(Vector2(w * 0.42, centro.y + lado * 0.86), Vector2(w * 0.58, centro.y + lado * 0.86), Color(Tema.ORO, alfa), 2.0)
	_post.draw_string(f, Vector2(0, centro.y + lado * 1.02), linea, HORIZONTAL_ALIGNMENT_CENTER, w, int(h * 0.032), Color(Tema.ORO, alfa))
