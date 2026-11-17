class_name EscaparatePartidos
extends RefCounted
## LA FILA DE PARTIDOS DEL ESCAPARATE Y LA TARJETA DE SEGUIDORES (17-11-2026; Liga Master del PES 2020): el ÚLTIMO resultado y los TRES PRÓXIMOS, cada uno con la
## competición arriba, los dos escudos grandes, la HORA grande en el centro (o el marcador) y el estadio y la fecha debajo; «Siguiente» en naranja sobre el primero que viene.
## Y los seguidores (escudo, #CLUB y la cifra enorme) con los colaboradores oficiales (marcas ficticias del juego).

const HORAS := ["12:00", "13:00", "16:00", "18:55", "20:45"]
const NARANJA := Color("f08a3c")

static func _escudo(c: Club, px: int) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Escudo.textura(c, px)
	t.custom_minimum_size = Vector2(px, px)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return t

static func _fecha(m: Mundo, k: int, dia: int) -> String:
	var f := Calendario.fecha(m.anio, m.semana + k, dia)
	return "%d/%d/%d" % [int(f["day"]), int(f["month"]), int(f["year"])]

## La competición como rótulo de color (liga azul, copa dorada, continental violeta).
static func _insignia(tipo: String, texto: String) -> Control:
	var l := EstiloAvanzar.etiqueta(texto.to_upper(), 12, Color.WHITE, true)
	var col: Color = {"liga": Color("2d4a8a"), "copa": Color("b8860b"), "conti": Color("6b3fa0")}.get(tipo, Color("2d4a8a"))
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 8; sb.content_margin_right = 8; sb.content_margin_top = 1; sb.content_margin_bottom = 1
	l.add_theme_stylebox_override("normal", sb)
	l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return l

static func _columna(local: Club, visita: Club, centro: String, comp_tipo: String, comp: String, estadio: String, fecha: String, siguiente: bool, mio: Club) -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 3)
	var tag := EstiloAvanzar.etiqueta(Idiomas.t("Siguiente") if siguiente else " ", 13, NARANJA, true)
	col.add_child(tag)
	col.add_child(_insignia(comp_tipo, comp))
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 12)
	fila.add_child(_escudo(local, 44))
	var c := EstiloAvanzar.etiqueta(centro, 34, NARANJA if siguiente else Color.WHITE, true)
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fila.add_child(c)
	fila.add_child(_escudo(visita, 44))
	col.add_child(fila)
	var e := EstiloAvanzar.etiqueta(estadio, 12, Color(1, 1, 1, 0.85))
	e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	e.clip_text = true
	col.add_child(e)
	var f := EstiloAvanzar.etiqueta(fecha, 12, Color(1, 1, 1, 0.6))
	f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(f)
	return col

static func _nombre_comp(e: Dictionary, liga: Liga) -> String:
	match String(e["tipo"]):
		"liga": return liga.nombre if liga != null else Idiomas.t("Liga")
		"copa": return Idiomas.t("Copa")
		_: return Idiomas.t("Continental")

static func proximos(p: Principal, c: Club, liga: Liga, acento: Color) -> Control:
	var tc := TableroInicio.tarjeta(Idiomas.t("Calendario"), acento, func() -> void: CalendarioSemanas.mostrar(p, p.mundo, p._dia_semana))
	var b: Button = tc[0]
	var v: VBoxContainer = tc[1]
	var fila := HBoxContainer.new()
	fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fila.add_theme_constant_override("separation", 6)
	v.add_child(fila)
	var cols: Array = []
	## el último partido jugado de la liga
	var ultimo: Dictionary = {}
	if liga != null:
		for i in range(liga.historial.size() - 1, -1, -1):
			for r: Dictionary in liga.historial[i]:
				if r["local"] == c or r["visita"] == c:
					ultimo = r.duplicate()
					ultimo["jornada"] = i + 1
					break
			if not ultimo.is_empty():
				break
	var lista: Array = []
	for e: Dictionary in EventosFecha.proximos(p.mundo, p._dia_semana, 12):
		if EventosFecha.es_partido(e) and e.get("rival") is Club:
			lista.append(e)
	var cuantos := 3 if not ultimo.is_empty() else 4   ## sin partido jugado aún, los cuatro próximos (nunca un hueco vacío)
	if not ultimo.is_empty():
		var l: Club = ultimo["local"]
		cols.append(_columna(l, ultimo["visita"], "%d - %d" % [int(ultimo["gl"]), int(ultimo["gv"])], "liga", liga.nombre if liga != null else "", l.estadio_nombre if l.estadio_nombre != "" else l.nombre, Idiomas.t("Jornada %d") % int(ultimo["jornada"]), false, c))
	for i in mini(cuantos, lista.size()):
		var e: Dictionary = lista[i]
		var rival: Club = e["rival"]
		var casa := bool(e.get("local", true))
		var l2: Club = c if casa else rival
		var hora: String = HORAS[absi(hash("%s|%s|%d" % [c.id, rival.id, int(e.get("semana", 0))])) % HORAS.size()]
		cols.append(_columna(l2, rival if casa else c, hora, String(e["tipo"]), _nombre_comp(e, liga), l2.estadio_nombre if l2.estadio_nombre != "" else Idiomas.t("Estadio de %s") % l2.nombre,
			_fecha(p.mundo, int(e.get("k", 0)), int(e["dia"])), i == 0, c))
	for i in cols.size():
		if i > 0:
			var sep := VSeparator.new()
			sep.modulate = Color(1, 1, 1, 0.25)
			fila.add_child(sep)
		fila.add_child(cols[i])
	TableroInicio.cerrar(b)
	return b

static func _marca_de(c: Club, i: int) -> Array:
	var marcas := Auspicio.marcas()
	if marcas.is_empty():
		return ["", "#2d4a8a"]
	var m: Array = marcas[absi(hash("%s|%d" % [c.id, i])) % marcas.size()]
	return [Nombres.limpiar(String(m[0])), String(m[1]) if m.size() > 1 else "#2d4a8a"]

static func hinchada(p: Principal, c: Club, acento: Color) -> Control:
	var tc := TableroInicio.tarjeta(Idiomas.t("Hinchada y socios"), acento, func() -> void: TableroInicio.abrir(p, "Hinchada y socios"))
	var b: Button = tc[0]
	var v: VBoxContainer = tc[1]
	v.add_theme_constant_override("separation", 0)
	v.add_child(EstiloAvanzar.etiqueta(Idiomas.t("Seguidores"), 13, Color(1, 1, 1, 0.7)))
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 8)
	cab.add_child(_escudo(c, 28))
	cab.add_child(EstiloAvanzar.etiqueta("#" + c.nombre.replace(" ", "").to_upper().left(16), 15, Color(1, 1, 1, 0.85)))
	v.add_child(cab)
	var n := EstiloAvanzar.etiqueta(p._miles(c.socios), 26, Color.WHITE, true)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(n)
	v.add_child(EstiloAvanzar.etiqueta(Idiomas.t("Colaboradores oficiales"), 12, Color(1, 1, 1, 0.7)))
	var logos := HBoxContainer.new()
	logos.add_theme_constant_override("separation", 6)
	logos.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(logos)
	var contrato: Dictionary = p.mundo.auspicio.contrato if p.mundo.auspicio != null else {}
	for i in 3:
		var par: Array = [Nombres.limpiar(String(contrato["marca"])), String(contrato.get("color", "#2d4a8a"))] if i == 0 and not contrato.is_empty() else _marca_de(c, i)
		var pc := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(par[1])
		sb.set_corner_radius_all(4)
		pc.add_theme_stylebox_override("panel", sb)
		pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var l := EstiloAvanzar.etiqueta(String(par[0]), 14, Color.WHITE if Color(par[1]).get_luminance() < 0.5 else Color("101820"), true)
		l.custom_minimum_size.y = 22
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pc.add_child(l)
		logos.add_child(pc)
	TableroInicio.cerrar(b)
	return b
