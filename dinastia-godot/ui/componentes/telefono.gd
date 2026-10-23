class_name Telefono
extends "res://ui/componentes/telefono_p2.gd"
## (Parte 3 de 3 de `telefono.gd`.)

func _banco() -> void:
	_titulo_app("Banco")
	var c := m.mi_club()
	var filas := []
	if c != null:
		filas.append(["🏟️ Caja del club", Cesiones.dinero(c.saldo), Tema.BIEN if c.saldo >= 0 else Color("e5534b")])
		filas.append(["💸 Sueldos del plantel", Cesiones.dinero(c.masa_salarial()) + " / semana", Tema.TEXTO])
		## Cuántas semanas aguanta la caja pagando solo sueldos.
		var sem := int(c.saldo / maxi(1, c.masa_salarial())) if c.saldo > 0 else 0
		filas.append(["⏳ Semanas de sueldos en caja", str(sem) if sem < 999 else "999+", Tema.BIEN if sem > 20 else (Tema.ORO if sem > 6 else Color("e5534b"))])
	if m.roles != null:
		filas.append(["👤 Tu patrimonio", Cesiones.dinero(m.roles.patrimonio), Tema.TEXTO])
	if m.fondo != null:
		filas.append(["💼 Tu fondo de inversión", Cesiones.dinero(m.fondo.valor_total(m)), Tema.ORO])
	for f: Array in filas:
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", _caja_informe(f == filas[0]))
		var v := VBoxContainer.new()
		pc.add_child(v)
		v.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, String(f[0])))
		v.add_child(Tema.etiqueta(Tema.TAM_DESTACADO + 4, f[2], String(f[1])))
		_cuerpo.add_child(pc)

func _calendario() -> void:
	## MEDIO INFORME (13-10-2026): la ficha del próximo partido con los dos
	## escudos y la tabla con columnas, sobria, como el parte del club.
	_titulo_app("Calendario")
	var c := m.mi_club()
	var prox := m.proximo_partido()
	var caja := PanelContainer.new()
	var sb := Tema.caja(TARJETA, 12, TARJETA)
	sb.border_width_left = 3
	sb.border_color = Tema.ORO
	caja.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	caja.add_child(v)
	v.add_child(Tema.etiqueta(Tema.TAM_ROTULO - 2, Tema.ORO, "PRÓXIMO PARTIDO"))
	if prox.size() >= 2:
		var fila := HBoxContainer.new()
		fila.alignment = BoxContainer.ALIGNMENT_CENTER
		fila.add_theme_constant_override("separation", 10)
		for i in 2:
			var cl: Club = prox[i]
			var col := VBoxContainer.new()
			col.custom_minimum_size = Vector2(130, 0)
			var esc := TextureRect.new()
			esc.texture = Escudo.textura(cl, 96)
			esc.custom_minimum_size = Vector2(44, 44)
			esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			col.add_child(esc)
			var nom := Tema.etiqueta(Tema.TAM_ROTULO, Tema.ORO if cl == c else Tema.TEXTO, cl.nombre)
			nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			col.add_child(nom)
			fila.add_child(col)
			if i == 0:
				fila.add_child(Tema.etiqueta(Tema.TAM_DESTACADO, Tema.SUAVE, "vs"))
		v.add_child(fila)
		var donde := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "🏠 En casa" if prox[0] == c else "✈️ De visita")
		donde.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(donde)
	else:
		v.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, "Semana sin partido de liga."))
	_cuerpo.add_child(caja)
	## La tabla alrededor de tu puesto, con columnas alineadas.
	for l in m.ligas:
		if not l.clubes.has(c):
			continue
		var t: Array = l.tabla()
		var yo := 0
		for i in t.size():
			if t[i]["club"] == c:
				yo = i
		_cuerpo.add_child(Tema.etiqueta(Tema.TAM_ROTULO - 2, Tema.ORO, "  TU LIGA"))
		var rej := GridContainer.new()
		rej.columns = 5
		rej.add_theme_constant_override("h_separation", 10)
		for cab: String in ["#", "Club", "PJ", "DG", "Pts"]:
			rej.add_child(Tema.etiqueta(Tema.TAM_ROTULO - 2, Tema.SUAVE, cab))
		for i in range(maxi(0, yo - 3), mini(t.size(), yo + 4)):
			var f: Dictionary = t[i]
			var cl: Club = f["club"]
			var tono := Tema.ORO if cl == c else Tema.TEXTO
			rej.add_child(Tema.etiqueta(Tema.TAM_ROTULO, tono, str(i + 1)))
			var nom := Tema.etiqueta(Tema.TAM_ROTULO, tono, cl.nombre)
			nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			nom.clip_text = true
			rej.add_child(nom)
			rej.add_child(Tema.etiqueta(Tema.TAM_ROTULO, tono, str(int(f.get("pj", 0)))))
			rej.add_child(Tema.etiqueta(Tema.TAM_ROTULO, tono, "%+d" % int(f.get("dif", 0))))
			rej.add_child(Tema.etiqueta(Tema.TAM_ROTULO, tono, str(int(f.get("pts", 0)))))
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", Tema.caja(TARJETA, 12, TARJETA))
		pc.add_child(rej)
		_cuerpo.add_child(pc)
		break

func _fotos() -> void:
	_titulo_app("Fotos")
	var rej := GridContainer.new()
	rej.columns = 3
	rej.add_theme_constant_override("h_separation", 3)
	rej.add_theme_constant_override("v_separation", 3)
	_cuerpo.add_child(rej)
	rej.add_child(_avatar(m.movil.textura_perfil(m), 104, "🧑‍💼"))
	var n := 1
	for p: Dictionary in m.redes.publicaciones:
		if (String(p["cuenta"]) == "dt" or bool(p.get("tuya", false))) and FOTOS.has(String(p["tipo"])):
			var f := _foto(String(p["tipo"]), 104.0)
			f.custom_minimum_size = Vector2(104, 104)
			rej.add_child(f)
			n += 1
	## Las del modo foto (fase 5): ciudad, estadio y casa.
	for ruta: String in ModoFoto.fotos():
		var img := Image.load_from_file(ProjectSettings.globalize_path(ruta))
		if img == null or img.is_empty():
			continue
		var tr := TextureRect.new()
		tr.texture = ImageTexture.create_from_image(img)
		tr.custom_minimum_size = Vector2(104, 104)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		rej.add_child(tr)
		n += 1
	_cuerpo.add_child(_nota("%d foto%s" % [n, "" if n == 1 else "s"]))

func _muestra(col: Color, nombre: String, elegido: bool, al_tocar: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(40, 40)
	b.tooltip_text = nombre
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(20)
	sb.set_border_width_all(3 if elegido else 1)
	sb.border_color = Tema.ORO if elegido else Color(1, 1, 1, 0.3)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.pressed.connect(al_tocar)
	return b

func _pintar_papel() -> void:
	var d: Array = Movil.FONDOS.get(m.movil.fondo, Movil.FONDOS["noche"])
	var g := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.set_color(0, Movil.color(String(d[1]), m.mi_club()))
	gr.set_color(1, Movil.color(String(d[2]), m.mi_club()))
	g.gradient = gr
	g.fill_from = Vector2(0, 0)
	g.fill_to = Vector2(0.3, 1)
	_papel.texture = g
	var col := m.movil.color_funda(m.mi_club())
	_marco.bg_color = col
	_marco.border_color = col.lightened(0.2)

## LA GALERÍA: el selector de archivos del sistema (el nativo en móvil y en
## escritorio). La imagen se recorta al cuadrado y se guarda como tu foto.
func _elegir_de_galeria() -> void:
	var fd := FileDialog.new()
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.use_native_dialog = true
	fd.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Imágenes"])
	fd.title = Idiomas.t("Elige tu foto de perfil")
	get_tree().root.add_child(fd)
	fd.file_selected.connect(func(ruta: String) -> void:
		var error := m.movil.usar_foto_de_galeria(ruta)
		fd.queue_free()
		if is_instance_valid(self):
			abrir_app("ajustes")
			_decir("✔ Foto de perfil actualizada." if error == "" else "⚠️ " + error)
			estetica_cambiada.emit())
	fd.canceled.connect(fd.queue_free)
	fd.popup_centered_ratio(0.7)

# --- ajustes ----------------------------------------------------------------------------

func _ajustes() -> void:
	_titulo_app("Ajustes")
	var mv := m.movil
	_cuerpo.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "FONDO DE PANTALLA"))
	var fondos := HFlowContainer.new()
	_cuerpo.add_child(fondos)
	for k: String in Movil.FONDOS:
		var d: Array = Movil.FONDOS[k]
		var kk := k
		fondos.add_child(_muestra(Movil.color(String(d[1]), m.mi_club()), String(d[0]), mv.fondo == k, func() -> void:
			mv.fondo = kk
			_pintar_papel()
			estetica_cambiada.emit()
			abrir_app("ajustes")))
	_cuerpo.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "FUNDA"))
	var fundas := HFlowContainer.new()
	_cuerpo.add_child(fundas)
	for f: Array in Movil.FUNDAS:
		var clave := String(f[1])
		fundas.add_child(_muestra(Movil.color(clave, m.mi_club()), String(f[0]), mv.funda == clave, func() -> void:
			mv.funda = clave
			_pintar_papel()
			estetica_cambiada.emit()
			abrir_app("ajustes")))
	_cuerpo.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "TAMAÑO DE LETRA"))
	var letras := HBoxContainer.new()
	_cuerpo.add_child(letras)
	for i in Movil.LETRAS.size():
		var b := Button.new()
		b.toggle_mode = true
		b.button_pressed = mv.letra == i
		b.text = String(Movil.LETRAS[i][0])
		var k2 := i
		b.pressed.connect(func() -> void:
			mv.letra = k2
			abrir_app("ajustes"))
		letras.add_child(b)
	_cuerpo.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "FOTO DE PERFIL"))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	_cuerpo.add_child(fila)
	fila.add_child(_avatar(mv.textura_perfil(m), 72, "🧑‍💼"))
	var botones := VBoxContainer.new()
	fila.add_child(botones)
	var retrato := Button.new()
	retrato.text = Idiomas.t("🧑 Usar mi personaje")
	retrato.pressed.connect(func() -> void:
		mv.foto_perfil = "retrato"
		estetica_cambiada.emit()
		abrir_app("ajustes"))
	botones.add_child(retrato)
	var galeria := Button.new()
	galeria.text = Idiomas.t("🖼️ Elegir de mi galería")
	galeria.pressed.connect(_elegir_de_galeria)
	botones.add_child(galeria)

## El tamaño de letra elegido en Ajustes, aplicado a todo lo que se pintó.
func _escalar_letra() -> void:
	var f := m.movil.factor_letra()
	if is_equal_approx(f, 1.0):
		return
	for n in _cuerpo.find_children("*", "Control", true, false):
		if n is Label or n is Button or n is LineEdit:
			var c := n as Control
			c.add_theme_font_size_override("font_size", int(round(c.get_theme_font_size("font_size") * f)))
		elif n is RichTextLabel:
			var r := n as RichTextLabel
			r.add_theme_font_size_override("normal_font_size", int(round(r.get_theme_font_size("normal_font_size") * f)))

## Botones con forma de móvil (13-10-2026): píldoras, no los rectángulos del
## resto del juego. Los planos (atrás, iconos) se quedan como están.
func _botones_movil() -> void:
	for n in _cuerpo.find_children("*", "Button", true, false):
		var b := n as Button
		if b.flat or b.get_child_count() > 0 or b.has_theme_stylebox_override("normal"):
			continue
		CuadroDialogo.respuesta(b)

func abrir_app(app: String) -> void:
	_app = app
	_decir("")
	for h in _cuerpo.get_children():
		h.queue_free()
	## En las apps el fondo de pantalla se oscurece, como detrás de una app.
	_papel.modulate = Color(1, 1, 1, 1.0 if app == "inicio" else 0.18)
	match app:
		"inicio": _inicio()
		"tribuna": _tribuna()
		"mensajes": _mensajes()
		"noticias": _noticias()
		"banco": _banco()
		"calendario": _calendario()
		"fotos": _fotos()
		"ajustes": _ajustes()
	_escalar_letra.call_deferred()
	_botones_movil.call_deferred()
	_scroll.scroll_vertical = 0

# --- el aparato -----------------------------------------------------------------

func _montar() -> void:
	custom_minimum_size = Vector2(ANCHO, 0)
	_marco = Tema.caja(m.movil.color_funda(m.mi_club()), 34, m.movil.color_funda(m.mi_club()).lightened(0.2))
	## Carcasa realista: sombra que lo despega del fondo y canto más claro.
	_marco.shadow_color = Color(0, 0, 0, 0.55)
	_marco.shadow_size = 22
	_marco.shadow_offset = Vector2(0, 8)
	_marco.set_border_width_all(2)
	add_theme_stylebox_override("panel", _marco)
	var borde := MarginContainer.new()
	for k in ["left", "right", "top", "bottom"]:
		borde.add_theme_constant_override("margin_" + k, 10)
	add_child(borde)
	var pantalla := PanelContainer.new()
	var sb := Tema.caja(FONDO_APP, 26, Color(0, 0, 0))
	sb.set_content_margin_all(0)
	pantalla.add_theme_stylebox_override("panel", sb)
	pantalla.clip_contents = true
	borde.add_child(pantalla)
	_papel = TextureRect.new()
	_papel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_papel.stretch_mode = TextureRect.STRETCH_SCALE
	_papel.set_anchors_preset(Control.PRESET_FULL_RECT)
	pantalla.add_child(_papel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	pantalla.add_child(v)
	## La «isla» de la cámara frontal, centrada arriba.
	var isla := Panel.new()
	isla.add_theme_stylebox_override("panel", Tema.caja(Color(0, 0, 0), 11, Color(0, 0, 0)))
	isla.custom_minimum_size = Vector2(92, 24)
	isla.anchor_left = 0.5
	isla.anchor_right = 0.5
	isla.offset_left = -46
	isla.offset_right = 46
	isla.offset_top = 8
	isla.offset_bottom = 32
	isla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	## Dentro de un Control libre: el PanelContainer estiraría la isla a toda la pantalla.
	var capa := Control.new()
	capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(isla)
	pantalla.add_child(capa)
	## Barra de estado.
	var estado := HBoxContainer.new()
	estado.custom_minimum_size = Vector2(0, 40)
	var hora := Tema.etiqueta(Tema.TAM_ROTULO, Tema.TEXTO, "   " + _hora())
	hora.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	estado.add_child(hora)
	estado.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.TEXTO, "▂▄▆ 5G  🔋 82%   "))
	v.add_child(estado)
	_aviso = Tema.etiqueta(Tema.TAM_ROTULO, Tema.ORO, "")
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aviso.visible = false
	v.add_child(_aviso)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_scroll)
	var margen := MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for k in ["left", "right"]:
		margen.add_theme_constant_override("margin_" + k, 8)
	_scroll.add_child(margen)
	_cuerpo = VBoxContainer.new()
	_cuerpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cuerpo.add_theme_constant_override("separation", 8)
	margen.add_child(_cuerpo)
	## La barra de inicio.
	var barra := Button.new()
	barra.flat = true
	barra.text = "━━━━"
	barra.custom_minimum_size = Vector2(0, 30)
	barra.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	barra.pressed.connect(func() -> void: abrir_app("inicio"))
	v.add_child(barra)
	_pintar_papel()
	abrir_app("inicio")

## Abre el móvil a pantalla completa (desde MI VIDA o el despacho).
static func abrir(p: Control, mundo: Mundo) -> Control:
	var pop := Control.new()
	pop.set_anchors_preset(Control.PRESET_FULL_RECT)
	pop.mouse_filter = Control.MOUSE_FILTER_STOP
	p.add_child(pop)
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.75)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	pop.add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	pop.add_child(centro)
	var noticias: Array = p.get("_bandeja") if p.get("_bandeja") != null else []
	var tel := Telefono.crear(mundo, noticias)
	## A la altura de la pantalla VISIBLE (la interfaz va escalada: 780 px
	## "de diseño" se salían por abajo y tapaban la barra de inicio).
	var alto := p.get_viewport_rect().size.y
	tel.custom_minimum_size = Vector2(ANCHO, clampf(alto - 40.0, 420.0, 780.0))
	centro.add_child(tel)
	var cerrar := Button.new()
	cerrar.text = Idiomas.t("✕ Guardar el móvil")
	cerrar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	cerrar.offset_left = -200
	cerrar.offset_right = -30
	cerrar.offset_top = 24
	cerrar.offset_bottom = 60
	cerrar.pressed.connect(func() -> void:
		pop.queue_free()
		if p.has_method("_refrescar"):
			p.call("_refrescar"))
	pop.add_child(cerrar)
	return pop
