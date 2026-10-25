extends "res://ui/entrada/config_club_base.gd"
## [Capa 2/4 de `config_club.gd`] los pasos de la identidad: nombre y colores, escudo y equipación.
##
## Reutiliza lo que ya pinta el club en todo el juego (`Escudo`, `Jersey`,
## `DisenosKit`, `DisenadorKit`) sin tocarlo: aquí solo se eligen valores sobre
## el club de mentira de `ConfigClubDatos`.

## Combinaciones clásicas para empezar rápido: [color1, color2].
const PALETAS := [
	["#1e4030", "#c9a227"], ["#0b3d91", "#f2c230"], ["#b01e23", "#111111"], ["#ffffff", "#1d1d1d"],
	["#5b2a86", "#ffffff"], ["#0e7c3a", "#ffffff"], ["#e06a1b", "#1c2a48"], ["#6cace4", "#ffffff"],
	["#7a1f2b", "#5fb4e3"], ["#f4d03f", "#0f4c81"], ["#111111", "#e8b13a"], ["#c8102e", "#ffffff"],
]

## Miniaturas por dibujar: [TextureRect, Callable que devuelve la textura]. Unas
## pocas por fotograma, como la galería del diseñador: 56 escudos de golpe se notan.
var _cola: Array = []
var _minis_escudo: Array = []   ## [TextureRect, forma, patron]
var _minis_kit: Array = []      ## [TextureRect, estilo]

func _process(delta: float) -> void:
	super._process(delta)
	for _i in 3:
		if _cola.is_empty():
			break
		var par: Array = _cola.pop_front()
		if is_instance_valid(par[0]):
			(par[0] as TextureRect).texture = (par[1] as Callable).call()

## Pide rehacer las miniaturas que dependen de los colores (solo las del paso visible).
func _cambio_colores() -> void:
	_cambio()
	_encolar_miniaturas()

func _encolar_miniaturas() -> void:
	_cola.clear()
	for m: Array in _minis_escudo:
		_cola.append([m[0], _mini_escudo.bind(String(m[1]), String(m[2]))])
	for m: Array in _minis_kit:
		_cola.append([m[0], _mini_kit.bind(String(m[1]))])

func _limpiar_paso() -> void:
	_cola.clear()
	_minis_escudo.clear()
	_minis_kit.clear()
	for h in _contenido.get_children():
		_contenido.remove_child(h)
		h.queue_free()
	_scroll.scroll_vertical = 0

# ------------------------------------------------------------------ IDENTIDAD

func _paso_identidad() -> void:
	var c := datos.club
	_seccion(Idiomas.t("Nombre del club"), Idiomas.t("Así lo leerán la prensa, la hinchada y la tabla."))
	var n := _campo(c.nombre, Idiomas.t("Nombre de tu club"), ConfigClubDatos.NOMBRE_MAX, 20)
	n.name = "CampoNombre"
	if not datos.crea_club:
		## Un club que ya existe conserva su nombre: es su historia (y su palmarés).
		n.editable = false
		n.tooltip_text = Idiomas.t("Un club con historia conserva su nombre.")
		_contenido.add_child(Tema.etiqueta(12, Tema.SUAVE, Idiomas.t("Un club con historia conserva su nombre.")))
	_seccion(Idiomas.t("Nombre del estadio"), Idiomas.t("Si lo dejas vacío, será «Estadio» y el nombre del club."))
	var e := _campo(c.estadio_nombre, "", ConfigClubDatos.ESTADIO_MAX, 15)
	e.name = "CampoEstadio"
	e.placeholder_text = Idiomas.t("Estadio %s") % c.nombre.strip_edges()
	n.text_changed.connect(func(t: String) -> void:
		c.nombre = t
		e.placeholder_text = Idiomas.t("Estadio %s") % t.strip_edges()
		_cambio())
	e.text_changed.connect(func(t: String) -> void:
		c.estadio_nombre = t
		_cambio())
	_seccion(Idiomas.t("Colores del club"), Idiomas.t("Los colores de siempre. Escudo, camiseta e interfaz los heredan mientras no los cambies."))
	_fila_color(Idiomas.t("Color principal"), c.color1, func(h: String) -> void:
		c.color1 = h
		_cambio())
	_fila_color(Idiomas.t("Color secundario"), c.color2, func(h: String) -> void:
		c.color2 = h
		_cambio())
	var f := _flujo()
	for par: Array in PALETAS:
		var b := Button.new()
		b.custom_minimum_size = Vector2(52, 34)
		b.tooltip_text = Idiomas.t("Usar esta combinación")
		_estilo_opcion(b)
		var dos := HBoxContainer.new()
		dos.add_theme_constant_override("separation", 0)
		dos.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 7)
		dos.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for hexa: String in par:
			var m := ColorRect.new()
			m.color = Color(hexa)
			m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			m.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dos.add_child(m)
		b.add_child(dos)
		var p := par
		b.pressed.connect(func() -> void:
			c.color1 = String(p[0])
			c.color2 = String(p[1])
			_cambio()
			_pintar_paso())
		f.add_child(b)
	_seccion(Idiomas.t("Lema"), Idiomas.t("Opcional. Sale en la vista previa y en los detalles del club."))
	var l := _campo(datos.lema, Idiomas.t("Lema del club. Ej: «Nunca caminarás solo»"), 60, 14)
	l.text_changed.connect(func(t: String) -> void:
		datos.lema = t
		_cambio())
	if datos.crea_club and c.nombre.strip_edges() == "" and is_inside_tree():
		n.call_deferred("grab_focus")

func _campo(texto: String, pista: String, maximo: int, tam: int) -> LineEdit:
	var le := LineEdit.new()
	le.text = texto
	le.placeholder_text = pista
	le.max_length = maximo
	le.custom_minimum_size = Vector2(0, 40)
	le.add_theme_font_size_override("font_size", tam)
	le.add_theme_stylebox_override("normal", _caja(Color(0, 0, 0, 0.35), Tema.RADIO, Color(1, 1, 1, 0.14)))
	le.add_theme_stylebox_override("focus", _caja(Color(0, 0, 0, 0.45), Tema.RADIO, Tema.ORO))
	_contenido.add_child(le)
	return le

# --------------------------------------------------------------------- ESCUDO

func _paso_escudo() -> void:
	var c := datos.club
	_seccion(Idiomas.t("Colores del escudo"), Idiomas.t("Cada cosa se pinta por separado: el uniforme no arrastra el color del menú ni el del escudo. Lo que no toques, lo hereda del club."))
	_fila_color(Idiomas.t("Fondo del escudo"), c.color_escudo1(), func(h: String) -> void:
		c.esc_color1 = h
		_cambio_colores())
	_fila_color(Idiomas.t("Borde y patrón"), c.color_escudo2(), func(h: String) -> void:
		c.esc_color2 = h
		_cambio_colores())
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	_contenido.add_child(fila)
	fila.add_child(_opcion("↺ " + Idiomas.t("Volver a los colores del club"), false, func() -> void:
		c.esc_color1 = ""
		c.esc_color2 = ""
		_cambio()
		_pintar_paso()))
	fila.add_child(_opcion("🎲 " + Idiomas.t("Sorpréndeme"), false, func() -> void:
		c.esc_forma = String(Escudo.FORMAS[randi() % Escudo.FORMAS.size()])
		c.esc_patron = String(Escudo.PATRONES[randi() % Escudo.PATRONES.size()])
		_cambio()
		_pintar_paso()))
	_seccion(Idiomas.t("Forma"))
	_rejilla_escudos(Escudo.FORMAS, true)
	_seccion(Idiomas.t("Patrón interior"))
	_rejilla_escudos(Escudo.PATRONES, false)
	_seccion(Idiomas.t("Símbolo (reemplaza las iniciales)"))
	var fs := _flujo()
	var lista_sim: Array = Datos.tabla("ESC_SIM") if Datos.tabla("ESC_SIM") is Array else [""]
	var bs: Array = []
	for s: Variant in lista_sim:
		var sim := String(s)
		var b := _opcion(sim if sim != "" else Escudo.iniciales(c), c.esc_simbolo == sim, func() -> void:
			c.esc_simbolo = sim
			_cambio(), Vector2(46, 40), Idiomas.t("Las iniciales del club") if sim == "" else "")
		b.add_theme_font_size_override("font_size", 18)
		fs.add_child(b)
		bs.append(b)
	_grupo(bs)
	var esp: Array = Escudo.especiales_desbloqueados()
	_seccion(Idiomas.t("Escudo especial (coleccionable)"), Idiomas.t("%d de %d desbloqueados según tu nivel de perfil de gestor. Si eliges uno, reemplaza al escudo de arriba.") % [esp.size(), Escudo.ESPECIALES.size()])
	var fe := _flujo()
	var be: Array = [_opcion(Idiomas.t("Ninguno\n(procedural)"), c.esc_especial == "", func() -> void:
		c.esc_especial = ""
		_cambio(), Vector2(70, 70))]
	be[0].add_theme_font_size_override("font_size", 10)
	fe.add_child(be[0])
	for id: String in esp:
		var idl := id
		var b := _opcion("", c.esc_especial == id, func() -> void:
			c.esc_especial = idl
			_cambio(), Vector2(70, 70), id)
		var ic := _imagen(Vector2.ZERO)
		ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
		ic.texture = Escudo.textura_especial(id)
		b.add_child(ic)
		fe.add_child(b)
		be.append(b)
	_grupo(be)

## Una rejilla de escudos en miniatura: cada botón ES el escudo con esa forma
## (o ese patrón) y los colores actuales, no el nombre de la clave.
func _rejilla_escudos(claves: Array, es_forma: bool) -> void:
	var c := datos.club
	var f := _flujo(null, 5)
	var botones: Array = []
	for k: Variant in claves:
		var clave := String(k)
		var elegido := (c.esc_forma if es_forma else c.esc_patron) == clave
		var b := _opcion("", elegido, func() -> void:
			if es_forma:
				c.esc_forma = clave
			else:
				c.esc_patron = clave
			_cambio_colores(), Vector2(58, 62), clave)
		var ic := _imagen(Vector2.ZERO)
		ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
		b.add_child(ic)
		f.add_child(b)
		botones.append(b)
		## La forma se prueba con el patrón actual, y el patrón con la forma actual.
		_minis_escudo.append([ic, clave if es_forma else "", "" if es_forma else clave])
	_grupo(botones)
	_encolar_miniaturas()

func _mini_escudo(forma: String, patron: String) -> Texture2D:
	var m := Club.new(datos.club.id, datos.club.nombre)
	m.color1 = datos.club.color1
	m.color2 = datos.club.color2
	m.identidad_desde_dic(datos.club.identidad_a_dic())
	m.esc_especial = ""
	if forma != "":
		m.esc_forma = forma
	if patron != "":
		m.esc_patron = patron
	return Escudo.textura(m, 48)

# ----------------------------------------------------------------- EQUIPACIÓN

func _paso_equipacion() -> void:
	var c := datos.club
	_seccion(Idiomas.t("Colores de la camiseta"), Idiomas.t("Lo que no toques, lo hereda del club."))
	_fila_color(Idiomas.t("Color 1 de la camiseta"), c.color_kit1(), func(h: String) -> void:
		_color_kit(0, h))
	_fila_color(Idiomas.t("Color 2 de la camiseta"), c.color_kit2(), func(h: String) -> void:
		_color_kit(1, h))
	_contenido.add_child(_opcion("↺ " + Idiomas.t("Volver a los colores del club"), false, func() -> void:
		_color_kit(0, "")
		_color_kit(1, "")
		_pintar_paso(), Vector2(0, 34)))
	_seccion(Idiomas.t("Diseño"))
	var f := _flujo(null, 5)
	var botones: Array = []
	for k: String in Jersey.KITS:
		var estilo := k
		var b := _opcion("", c.kit_estilo == k, func() -> void:
			c.kit_estilo = estilo
			if c.kit_x.has("dis"):
				c.kit_x["dis"] = estilo
			_cambio(), Vector2(64, 66), Idiomas.t(String(DisenosKit.diseno(k)[1])))
		var ic := _imagen(Vector2.ZERO)
		ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 5)
		b.add_child(ic)
		f.add_child(b)
		botones.append(b)
		_minis_kit.append([ic, k])
	_grupo(botones)
	if not (c.kit_estilo in Jersey.KITS):
		_contenido.add_child(Tema.etiqueta(13, Tema.ORO, Idiomas.t("Diseño elegido en el diseñador: %s") % Idiomas.t(String(DisenosKit.diseno(c.kit_estilo)[1]))))
	_encolar_miniaturas()
	var bd := _opcion(Idiomas.t("🎽  Abrir el diseñador de equipación"), false, _abrir_disenador, Vector2(0, 46))
	bd.add_theme_font_size_override("font_size", 16)
	_contenido.add_child(bd)
	var nota := Tema.etiqueta(12, Tema.SUAVE, Idiomas.t("70 diseños, cinco colores, pantalón, medias, botines, accesorios y números, con el jugador en 3D."))
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_contenido.add_child(nota)
	_seccion(Idiomas.t("Interfaz"), Idiomas.t("El color de los botones y del menú del juego."))
	_fila_color(Idiomas.t("Color de acento (botones y menú)"), c.color_acento(), func(h: String) -> void:
		c.ui_acento = h
		_cambio())
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	_contenido.add_child(fila)
	fila.add_child(_opcion(Idiomas.t("Usar el color del club"), false, func() -> void:
		c.ui_acento = ""
		_cambio()
		_pintar_paso()))
	fila.add_child(_opcion("🎨 " + Idiomas.t("Igualar todo a los colores del club"), false, func() -> void:
		c.igualar_identidad()
		if c.kit_x.has("cols"):
			(c.kit_x["cols"] as Array)[0] = c.color1
			(c.kit_x["cols"] as Array)[1] = c.color2
		_cambio_colores()
		_pintar_paso()))

## Un color de la camiseta ("" = el del club). Si la equipación ya pasó por el
## diseñador (`kit_x` con sus cinco colores), se cambia también ahí: si no, el
## diseñador ganaría y el selector no haría nada.
func _color_kit(i: int, h: String) -> void:
	var c := datos.club
	c.set("kit_color%d" % (i + 1), h)
	if c.kit_x.has("cols"):
		(c.kit_x["cols"] as Array)[i] = h if h != "" else (c.color1 if i == 0 else c.color2)
	_cambio_colores()

func _mini_kit(estilo: String) -> Texture2D:
	var cols := DisenosKit.colores(kit_previa())
	return DisenosKit.textura_camiseta(estilo, cols, 1, 64)

## EL DISEÑADOR COMPLETO, sobre el club de mentira. `DisenadorKit` trabaja con
## `mundo.mi_club()`: se le da un mundo vacío que solo tiene ese club y, al
## cerrar, `Mundo.actual()` vuelve a ser el de antes (crear un mundo lo cambia).
func _abrir_disenador() -> void:
	var antes := Mundo.actual()
	var m := Mundo.new()
	m.clubes[datos.club.id] = datos.club
	m.mi_club_id = datos.club.id
	var dz := DisenadorKit.abrir(self, m)
	dz.cerrado.connect(func() -> void:
		m.clubes.clear()
		if antes != null:
			Mundo._ultimo = weakref(antes)
		for k: String in ["escudo_tex", "marca", "sp"]:
			datos.club.kit_x.erase(k)
		_cambio_colores()
		_pintar_paso())
