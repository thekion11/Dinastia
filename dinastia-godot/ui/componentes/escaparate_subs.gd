class_name EscaparateSubs
extends RefCounted
## «DIRECCIÓN DEL EQUIPO» E «INFORMACIÓN DEL CLUB» EN EL LENGUAJE DEL ESCAPARATE (17-11-2026): el mismo mosaico con IMAGEN (una sala del club por tarjeta, teñida con el
## color del club), icono grande y el dato vivo en grande; nueve tarjetas (una grande, cuatro medianas, cuatro bajas) que se REPARTEN el alto: sin desplazamiento y sin el
## informe de la semana debajo. Cada tarjeta es `TableroInicio.tarjeta` (foco de mando, campana roja de `CampanasMenu`) y abre su submenú como siempre.

## La ilustración de cada tarjeta (`EscaparateArte`: dibujada en los colores del club, reconocible a primera vista).
const ARTE := {"*plantel": "plantel", "Pizarra y dibujo": "pizarra", "Entrenamiento": "entrenamiento", "Mercado de fichajes": "mercado", "Academia": "academia",
	"Enfermería": "enfermeria", "Contratos": "contratos", "Personal del club": "personal", "Camarín": "camarin",
	"*cuentas": "cuentas", "Patrocinadores": "patrocinadores", "Hinchada y socios": "hinchada", "Diseño del estadio": "estadio", "Historia del club": "historia",
	"Ligas y clubes": "ligas", "Correo": "correo", "*informe": "informe", "Récords": "records", "*sistema": "sistema"}
const AMBAR := Color("ffc857")

static func _sub_de(rot: String) -> Dictionary:
	var sitio := TableroInicio.buscar(rot)
	if not sitio.is_empty():
		return (MenusLaterales.menu_por_id(String(sitio[0]))["subs"] as Array)[int(sitio[1])]
	return {"label": "Sistema", "icono": "⚙️", "desc": "Guardar, cargar, pantalla, sonido y controles."}

## La tarjeta «Informe de la semana»: el aviso más urgente como titular y el contador de avisos; abre la pantalla completa del informe.
static func _informe(p: Principal, acento: Color) -> Control:
	var res := InformeSemana.resumen(p)
	var tc := TableroInicio.tarjeta(Idiomas.t("Informe de la semana"), acento, func() -> void: EscaparatePantalla.de(p).abrir_informe(p), Color(0.05, 0.07, 0.09, 1.0))
	var v: VBoxContainer = tc[1]
	var fila := HBoxContainer.new()
	fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fila.add_theme_constant_override("separation", 12)
	v.add_child(fila)
	var cont := EstiloAvanzar.etiqueta("%d" % int(res["graves"]), 44, Tema.mal() if int(res["graves"]) > 0 else Tema.bien(), true)
	cont.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	fila.add_child(cont)
	var t := EstiloAvanzar.etiqueta(String(res["titular"]), 18, Color.WHITE)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.max_lines_visible = 3
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.size_flags_vertical = Control.SIZE_SHRINK_END
	t.add_theme_constant_override("outline_size", 4)
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	fila.add_child(t)
	TableroInicio.cerrar(tc[0])
	return tc[0]

## ¿Este dato es un AVISO? Por las cifras (sirve en cualquier idioma): puestos del personal sin cubrir («0 de 13»), contratos que acaban («6 acaban este año») y lesionados («3 en la camilla»).
static func _alerta(rot: String, dato: String) -> bool:
	var n := RegEx.create_from_string("\\d+").search_all(dato)
	if rot == "Personal del club":
		return n.size() >= 2 and int(n[0].get_string()) < int(n[1].get_string())
	if rot == "Contratos" or rot == "Enfermería":
		return not n.is_empty() and int(n[0].get_string()) > 0
	return false

## Las cifras en grande: la cifra BLANCA (legible con cualquier club) y su rótulo; sin el color del club en el texto.
static func _cifras(datos: Array) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	for d: Array in datos:
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", -4)
		h.add_child(col)
		var n := EstiloAvanzar.etiqueta(String(d[1]), 30, Color.WHITE, true)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.clip_text = true
		col.add_child(n)
		var r := TableroInicio.etiqueta(String(d[0]).to_upper(), 11, Color(1, 1, 1, 0.75))
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		r.clip_text = true
		col.add_child(r)
	return h

static func _panel_oscuro(h: Control) -> PanelContainer:
	var pc := PanelContainer.new()
	var e := StyleBoxFlat.new()
	e.bg_color = Color(0, 0, 0, 0.62)
	e.set_corner_radius_all(6)
	e.content_margin_left = 10; e.content_margin_right = 10; e.content_margin_top = 6; e.content_margin_bottom = 6
	pc.add_theme_stylebox_override("panel", e)
	pc.add_child(h)
	return pc

## «Mi plantel»: el once tipo dibujado en el campo con su formación y sus dorsales, las cifras en blanco y la forma de los últimos 5 partidos.
static func _plantel(p: Principal, c: Club, acento: Color) -> Control:
	var tc := TableroInicio.tarjeta(Idiomas.t("Mi plantel"), acento, func() -> void: TableroInicio.abrir(p, "Mi plantel"), Color(0.05, 0.07, 0.09, 1.0))
	var v: VBoxContainer = tc[1]
	var lesionados := 0
	var moral := 0
	for j: Jugador in c.plantilla:
		lesionados += 1 if j.lesion > 0 else 0
		moral += j.moral
	moral = moral / maxi(c.plantilla.size(), 1)
	v.add_child(_panel_oscuro(_cifras([[Idiomas.t("Media"), "%d" % roundi(c.media()), 0], [Idiomas.t("Jugadores"), "%d" % c.plantilla.size(), 0],
		[Idiomas.t("Lesionados"), "%d" % lesionados, 0], [Idiomas.t("Moral"), "%d" % moral, 0]])))
	_al_fondo(v)
	var forma := _forma(p, c)
	if forma != null:
		v.add_child(forma)
	TableroInicio.cerrar(tc[0])
	return tc[0]

static func _al_fondo(v: VBoxContainer) -> void:
	var hueco := Control.new()
	hueco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(hueco)

## Los últimos 5 partidos de liga del club como fichas G / E / P (la más reciente a la derecha), o null si aún no hay.
static func _forma(p: Principal, c: Club) -> Control:
	var liga := p._liga_de(c)
	var res: Array[String] = []
	if liga != null:
		for i in range(liga.historial.size() - 1, -1, -1):
			if res.size() >= 5:
				break
			for r: Dictionary in liga.historial[i]:
				if r["local"] != c and r["visita"] != c:
					continue
				var mios := int(r["gl"]) if r["local"] == c else int(r["gv"])
				var suyos := int(r["gv"]) if r["local"] == c else int(r["gl"])
				res.append("G" if mios > suyos else ("P" if mios < suyos else "E"))
	res.reverse()
	if res.is_empty():
		return null
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 5)
	h.add_child(EstiloAvanzar.etiqueta(Idiomas.t("Forma"), 14, Color.WHITE))
	for r: String in res:
		var pc := PanelContainer.new()
		var e := StyleBoxFlat.new()
		e.bg_color = Tema.bien() if r == "G" else (Tema.mal() if r == "P" else Color("6b7a70"))
		e.set_corner_radius_all(4)
		e.content_margin_left = 8; e.content_margin_right = 8
		pc.add_theme_stylebox_override("panel", e)
		pc.add_child(EstiloAvanzar.etiqueta(r, 15, Color.WHITE, true))
		h.add_child(pc)
	return _panel_oscuro(h)

## Cuentas del club: la caja en grande (blanca; roja si está en números rojos) y sus cifras.
static func _cuentas(p: Principal, c: Club, acento: Color) -> Control:
	var tc := TableroInicio.tarjeta(Idiomas.t("Cuentas del club"), acento, func() -> void: TableroInicio.abrir(p, "Cuentas del club"), Color(0.05, 0.07, 0.09, 1.0))
	var v: VBoxContainer = tc[1]
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", -2)
	caja.add_child(TableroInicio.etiqueta(Idiomas.t("Caja").to_upper(), 12, Color(1, 1, 1, 0.75)))
	caja.add_child(EstiloAvanzar.etiqueta(p._dinero(c.saldo), 40, Color.WHITE if c.saldo >= 0 else Tema.mal(), true))
	v.add_child(_panel_oscuro(caja))
	_al_fondo(v)
	v.add_child(_panel_oscuro(_cifras([[Idiomas.t("Sueldos/sem"), p._dinero(c.masa_salarial()), 0], [Idiomas.t("Socios"), p._miles(c.socios), 0], [Idiomas.t("Butacas"), p._miles(c.estadio_aforo), 0]])))
	TableroInicio.cerrar(tc[0])
	return tc[0]

## Una tarjeta del mosaico: ilustración del club de fondo, velo oscuro abajo, icono y dato en BLANCO (el color del club, solo de acento en el icono); los avisos llevan punto rojo y texto ámbar.
static func _tarjeta(p: Principal, c: Club, rot: String, acento: Color) -> Control:
	var b: Control
	if rot == "*informe":
		b = _informe(p, acento)
	elif rot == "*plantel":
		b = _plantel(p, c, acento)
	elif rot == "*cuentas":
		b = _cuentas(p, c, acento)
	else:
		var sub := _sub_de(rot)
		var tc := TableroInicio.tarjeta(Idiomas.t(String(sub.get("label", rot))), acento, func() -> void: TableroInicio.abrir(p, rot), Color(0.05, 0.07, 0.09, 1.0))
		b = tc[0]
		(b as Button).tooltip_text = Idiomas.t(String(sub.get("desc", "")))
		var v: VBoxContainer = tc[1]
		var fila := HBoxContainer.new()
		fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
		fila.add_theme_constant_override("separation", 10)
		v.add_child(fila)
		var ic := IconosUI.control(String(sub.get("icono", "•")), 40)
		ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		ic.modulate = acento.lightened(0.25)
		fila.add_child(ic)
		var dato := MenuLateral.dato(p, sub)
		var alerta := _alerta(rot, dato)
		var d := EstiloAvanzar.etiqueta(("●  " if alerta else "") + dato, 24, AMBAR if alerta else Color.WHITE, true)
		d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		d.size_flags_vertical = Control.SIZE_SHRINK_END
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		d.clip_text = true
		d.add_theme_constant_override("outline_size", 5)
		d.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		fila.add_child(d)
		TableroInicio.cerrar(b)
	EscaparateArte.poner(b, String(ARTE.get(rot, "sistema")), c)
	EscaparateTarjetas._velo(b, 1, 0.45)
	b.custom_minimum_size = Vector2(120, 70)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return b

## Reparte las nueve tarjetas: arriba la grande (2) y dos columnas de dos (1,5 del alto); abajo cuatro (1). Todo por proporciones: nada se sale ni se desliza.
static func pintar(p: Principal, cuerpo: VBoxContainer, c: Club, lista: Array, acento: Color) -> void:
	var t: Array[Control] = []
	var rots := lista.duplicate()
	if rots.has("*cuentas"):   ## (17-11) «Información del club» lleva además el informe de la semana, junto a Correo
		rots.insert(rots.find("Correo") + 1, "*informe")
	for rot: String in rots:
		t.append(_tarjeta(p, c, rot, acento))
	var arriba := HBoxContainer.new()
	arriba.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arriba.size_flags_stretch_ratio = 1.5
	arriba.add_theme_constant_override("separation", TableroInicio.SEP)
	cuerpo.add_child(arriba)
	t[0].size_flags_stretch_ratio = 2.0
	arriba.add_child(t[0])
	for k in 2:
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", TableroInicio.SEP)
		arriba.add_child(col)
		col.add_child(t[1 + 2 * k])
		col.add_child(t[2 + 2 * k])
	var abajo := HBoxContainer.new()
	abajo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	abajo.size_flags_stretch_ratio = 1.0
	abajo.add_theme_constant_override("separation", TableroInicio.SEP)
	cuerpo.add_child(abajo)
	for i in range(5, t.size()):
		abajo.add_child(t[i])
