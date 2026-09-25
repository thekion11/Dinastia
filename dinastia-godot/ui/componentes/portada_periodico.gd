class_name PortadaPeriodico
extends Control
## LA PORTADA COMO PERIÓDICO DE VERDAD (26-9-2026, plan maestro C20). El usuario
## mandó una portada de otro juego de gestión como referencia: cabecera grande de
## color, franja de "las últimas noticias", titular enorme en mayúsculas, una
## bajada en banda oscura con la cara del protagonista, y abajo la tabla de la
## liga y una foto. Aquí va la misma idea con cabeceras PROPIAS del juego -seis
## diarios, cada uno con su color y su tipografía- y todo relleno con la
## partida: el titular y la bajada salen de `Prensa.portadas`, la cara del
## entrenador o del jugador que la protagoniza, la tabla de tu liga.
##
## Se abre desde el archivo de portadas (Gente → Prensa) y, si está activado,
## sola después de cada partido que salió en portada. "Guardar imagen" deja el
## PNG en `user://portadas/`, para compartirla.

signal cerrado

## clave, nombre, color de cabecera, color de franja, franja, inclinada
const CABECERAS := [
	["pelotazo", "EL PELOTAZO", Color("d4161c"), Color("b01218"), "LAS ÚLTIMAS DEL FÚTBOL, SIN FILTRO", true],
	["banda", "DIARIO LA BANDA", Color("15233f"), Color("c9a227"), "EL DIARIO DEL HINCHA DESDE 1952", false],
	["tribuna", "TRIBUNA DEPORTIVA", Color("1d6b3e"), Color("0f4a29"), "TODO EL DEPORTE, TODOS LOS DÍAS", false],
	["golazo", "¡GOLAZO!", Color("f2c230"), Color("111111"), "8 PÁGINAS DE PURO FÚTBOL", true],
	["pizarra", "LA PIZARRA", Color("3b4250"), Color("222731"), "ANÁLISIS · TÁCTICA · DATOS", false],
	["crack", "EL CRACK", Color("e2661d"), Color("a8440c"), "LOS PROTAGONISTAS, DE CERCA", true],
]
## El medio de un periodista (`Prensa.PERIODISTAS`) -> su cabecera.
const POR_MEDIO := {"El Pelotazo": "pelotazo", "Diario La Banda": "banda",
	"Radio Tribuna": "tribuna", "Canal Deportes": "golazo", "Podcast Fuera de Juego": "pizarra"}

const ANCHO := 460.0
const ALTO := 690.0
## La hoja se dibuja a 690 px de alto y se encoge para caber con los botones.
const ESCALA := 0.9

var _hoja: Control

static func auto() -> bool:
	var cfg := ConfigFile.new()
	return cfg.load(CajonAjustes.RUTA) != OK or bool(cfg.get_value("interfaz", "portada_auto", true))

static func fijar_auto(si: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value("interfaz", "portada_auto", si)
	cfg.save(CajonAjustes.RUTA)

static func cabecera_de(portada: Dictionary) -> Array:
	var medio := String(portada.get("medio", ""))
	var clave := String(portada.get("cab", POR_MEDIO.get(medio, "")))
	if clave == "":
		var h := absi(String(portada.get("t", "")).hash() + int(portada.get("semana", 0)) * 31)
		return CABECERAS[h % CABECERAS.size()]
	for c: Array in CABECERAS:
		if String(c[0]) == clave:
			return c
	return CABECERAS[0]

static func mostrar(padre: Control, mundo: Mundo, portada: Dictionary) -> PortadaPeriodico:
	var n := PortadaPeriodico.new()
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	padre.add_child(n)
	n._montar(mundo, portada)
	return n

func _montar(mundo: Mundo, p: Dictionary) -> void:
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.8)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(velo)
	var cab := cabecera_de(p)
	var col_cab: Color = cab[2]
	var col_franja: Color = cab[3]
	var inclinada: bool = cab[5]

	## La hoja, con una segunda hoja detrás asomando: un periódico doblado.
	var atras := ColorRect.new()
	atras.color = Color(0.86, 0.87, 0.88)
	atras.size = Vector2(ANCHO, ALTO)
	atras.set_anchors_preset(Control.PRESET_CENTER)
	atras.position = Vector2(-ANCHO / 2.0 + 14.0, -ALTO / 2.0 - 8.0)
	atras.rotation = 0.025
	add_child(atras)
	_hoja = Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.95, 0.95, 0.94)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 14
	_hoja.add_theme_stylebox_override("panel", sb)
	_hoja.set_anchors_preset(Control.PRESET_CENTER)
	_hoja.size = Vector2(ANCHO, ALTO)
	_hoja.position = Vector2(-ANCHO / 2.0, -ALTO / 2.0)
	add_child(_hoja)

	## 1) La cabecera.
	var caja_cab := ColorRect.new()
	caja_cab.color = col_cab
	caja_cab.position = Vector2(12, 12)
	caja_cab.size = Vector2(ANCHO - 24, 104)
	_hoja.add_child(caja_cab)
	## Cabe siempre: 50 px hasta 12 letras, y a partir de ahí se encoge.
	var tam_cab := int(clampf(50.0 * 12.0 / float(maxi(12, String(cab[1]).length())), 30.0, 50.0))
	var nombre := _lbl(String(cab[1]), tam_cab, Color.WHITE if col_cab.get_luminance() < 0.6 else Color(0.08, 0.08, 0.08), inclinada)
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre.position = Vector2(0, 10)
	nombre.size = Vector2(caja_cab.size.x, 70)
	caja_cab.add_child(nombre)
	var fecha := _lbl("%s · Semana %d de %d · Página %d" % [String(cab[1]).capitalize(), int(p.get("semana", 0)),
		int(p.get("anio", 0)), 2 + absi(String(p.get("t", "")).hash()) % 46], 10, Color(1, 1, 1, 0.8), false)
	fecha.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fecha.position = Vector2(0, 82)
	fecha.size = Vector2(caja_cab.size.x - 10, 16)
	caja_cab.add_child(fecha)
	## 2) La franja.
	var franja := ColorRect.new()
	franja.color = col_franja
	franja.position = Vector2(28, 118)
	franja.size = Vector2(ANCHO - 70, 26)
	_hoja.add_child(franja)
	var tf := _lbl(String(cab[4]), 14, Color.WHITE, true)
	tf.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tf.size = franja.size
	franja.add_child(tf)
	## 3) El titular, enorme, en un recuadro.
	var marco := Panel.new()
	var sbm := StyleBoxFlat.new()
	sbm.bg_color = Color(0.97, 0.97, 0.97)
	sbm.border_color = col_cab
	sbm.set_border_width_all(3)
	marco.add_theme_stylebox_override("panel", sbm)
	marco.position = Vector2(14, 150)
	marco.size = Vector2(ANCHO - 28, 190)
	_hoja.add_child(marco)
	var titular := String(p.get("t", "")).replace("\"", "").to_upper()
	var tam := 40 if titular.length() < 40 else (32 if titular.length() < 70 else 24)
	var tt := _lbl(titular, tam, Color(0.06, 0.06, 0.06), false)
	tt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tt.position = Vector2(10, 6)
	tt.size = Vector2(marco.size.x - 20, marco.size.y - 12)
	tt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tt.clip_text = true
	marco.add_child(tt)
	## 4) La bajada en banda oscura, con la cara.
	var banda := ColorRect.new()
	banda.color = Color(0.08, 0.08, 0.09)
	banda.position = Vector2(14, 346)
	banda.size = Vector2(ANCHO - 28, 116)
	_hoja.add_child(banda)
	var sub := String(p.get("sub", ""))
	if sub == "":
		sub = String(p.get("c", ""))
	var ts := _lbl(sub.to_upper(), 19 if sub.length() < 45 else (15 if sub.length() < 80 else 13), Color.WHITE, false)
	ts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ts.position = Vector2(10, 6)
	ts.size = Vector2(banda.size.x - 130, banda.size.y - 12)
	ts.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ts.clip_text = true
	banda.add_child(ts)
	## `expand_mode` ANTES que `size`: si no, el control se queda con el
	## tamaño de la textura (la cara salía enorme, tapando media hoja).
	var cara := TextureRect.new()
	cara.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cara.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cara.texture = _imagen(mundo, String(p.get("img", "dt")))
	cara.position = Vector2(banda.size.x - 116, 4)
	cara.size = Vector2(108, 108)
	banda.add_child(cara)
	## 5) Abajo: la tabla de la liga y la "foto" (el escudo sobre sus colores).
	_tabla(mundo, Vector2(14, 470), Vector2(222, 206))
	var foto := ColorRect.new()
	var mio := mundo.mi_club() if mundo != null else null
	## El color del club aclarado: con una camiseta negra la foto era un
	## agujero negro y el escudo se perdía.
	foto.color = Color(mio.color1).lerp(Color(0.55, 0.58, 0.62), 0.35) if mio != null else col_cab
	foto.position = Vector2(244, 470)
	foto.size = Vector2(ANCHO - 258, 206)
	_hoja.add_child(foto)
	if mio != null:
		var esc := TextureRect.new()
		esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		esc.texture = Escudo.textura(mio, 160)
		esc.position = Vector2(20, 14)
		esc.size = foto.size - Vector2(40, 60)
		foto.add_child(esc)
		var pie := _lbl(Nombres.visible(mio.nombre).to_upper(), 18, Color.WHITE, true)
		pie.add_theme_constant_override("outline_size", 6)
		pie.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pie.position = Vector2(0, foto.size.y - 40)
		pie.size = Vector2(foto.size.x, 30)
		foto.add_child(pie)

	## 6) Los botones, debajo de la hoja.
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	fila.set_anchors_preset(Control.PRESET_CENTER)
	fila.position = Vector2(-ANCHO * ESCALA / 2.0, ALTO * ESCALA / 2.0 - 10.0)
	add_child(fila)
	var guardar := Button.new()
	guardar.text = "📸 Guardar imagen"
	guardar.pressed.connect(func() -> void: guardar.text = "📸 Guardada: " + guardar_png())
	fila.add_child(guardar)
	var auto_cb := CheckBox.new()
	auto_cb.text = "Abrir sola tras cada partido"
	auto_cb.button_pressed = auto()
	auto_cb.toggled.connect(func(si: bool) -> void: fijar_auto(si))
	fila.add_child(auto_cb)
	var b := Button.new()
	b.text = "Cerrar"
	b.pressed.connect(_cerrar)
	fila.add_child(b)
	_hoja.pivot_offset = _hoja.size / 2.0
	atras.pivot_offset = atras.size / 2.0
	atras.scale = Vector2(ESCALA, ESCALA)
	_hoja.position.y -= 18.0
	atras.position.y -= 18.0
	_hoja.scale = Vector2(ESCALA * 0.96, ESCALA * 0.96)
	_hoja.modulate.a = 0.0
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_hoja, "modulate:a", 1.0, 0.25)
	tw.tween_property(_hoja, "scale", Vector2(ESCALA, ESCALA), 0.35)
	Sonido.toca("notificacion" if Sonido.NOMBRES.has("notificacion") else "cambio", Sonido.Bus.INTERFAZ)

func _gui_input(e: InputEvent) -> void:
	if e is InputEventKey and (e as InputEventKey).pressed and (e as InputEventKey).keycode == KEY_ESCAPE:
		_cerrar()

func _cerrar() -> void:
	cerrado.emit()
	queue_free()

## Recorta la hoja de la pantalla y la guarda. Devuelve el nombre del archivo.
func guardar_png() -> String:
	var img := get_viewport().get_texture().get_image()
	var r := Rect2i(_hoja.get_global_rect())
	r = r.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	var recorte := img.get_region(r)
	DirAccess.make_dir_recursive_absolute("user://portadas")
	var nombre := "portada_%d.png" % Time.get_unix_time_from_system()
	recorte.save_png("user://portadas/" + nombre)
	return nombre

func _imagen(mundo: Mundo, que: String) -> Texture2D:
	if mundo == null or mundo.mi_club() == null:
		return null
	var mio := mundo.mi_club()
	if que == "escudo":
		return Escudo.textura(mio, 108)
	if que.begins_with("pid:"):
		for j: Jugador in mio.plantilla:
			if j.id == que.substr(4):
				return Cara.textura(j, mio.color1, mio.color2, 108)
	if mundo.roles != null:
		var look: Dictionary = CaraDT.look_de_nombre(mundo.roles.dt_nombre()) if not mundo.roles.dt_empleado.is_empty() else mundo.roles.look_efectivo()
		return CaraDT.textura(look, 108)
	return Escudo.textura(mio, 108)

func _tabla(mundo: Mundo, pos: Vector2, tam: Vector2) -> void:
	var caja := ColorRect.new()
	caja.color = Color(0.80, 0.81, 0.82)
	caja.position = pos
	caja.size = tam
	_hoja.add_child(caja)
	var enc := ColorRect.new()
	enc.color = Color(0.12, 0.13, 0.15)
	enc.size = Vector2(tam.x, 24)
	caja.add_child(enc)
	var l_enc := _lbl("TABLA DE LA LIGA          PJ   PTS", 11, Color.WHITE, false)
	l_enc.position = Vector2(8, 3)
	enc.add_child(l_enc)
	if mundo == null or mundo.mi_club() == null:
		return
	var liga := mundo.liga_de(mundo.mi_club())
	if liga == null:
		return
	var y := 28.0
	var i := 0
	for f: Dictionary in liga.tabla():
		if i >= 8:
			break
		var c: Club = f["club"]
		var col := Color(0.55, 0.05, 0.05) if c == mundo.mi_club() else Color(0.12, 0.12, 0.12)
		var n := _lbl("%d  %s" % [i + 1, Nombres.visible(c.nombre).to_upper().substr(0, 16)], 12, col, false)
		n.position = Vector2(8, y)
		caja.add_child(n)
		var v := _lbl("%d    %d" % [int(f["pj"]), int(f["pts"])], 12, col, false)
		v.position = Vector2(tam.x - 58, y)
		caja.add_child(v)
		y += 22.0
		i += 1

## Una etiqueta de periódico: negrita gruesa y, si toca, inclinada.
func _lbl(texto: String, tam: int, color: Color, inclinada: bool) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	var fv := FontVariation.new()
	fv.base_font = ThemeDB.fallback_font if get_theme_default_font() == null else get_theme_default_font()
	fv.variation_embolden = 0.55
	if inclinada:
		fv.variation_transform = Transform2D(Vector2(1, 0), Vector2(-0.22, 1), Vector2.ZERO)
	l.add_theme_font_override("font", fv)
	return l
