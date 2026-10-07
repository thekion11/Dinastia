class_name DocumentalTemporada
extends Control
## EL DOCUMENTAL DE LA TEMPORADA (MEGAPLAN fase 5, originalidad). Al cerrar
## cada año, la temporada se cuenta como una película corta: franjas de cine,
## el escudo o la cara del protagonista con un zoom lento, el título de cada
## capítulo y una narración que se escribe sola. Todo sale de los datos de la
## temporada que se acaba de jugar -no hay frases de relleno sobre partidos
## que no existieron-:
##   1. Portada: el club y el año.            5. La racha.
##   2. El verano: los fichajes.              6. La herida: la peor derrota.
##   3. El goleador.                          7. El veredicto: el puesto final.
##   4. La noche grande: la mayor goleada.    8. Créditos.
## `guion(m)` arma los capítulos (lógica pura, comprobable en el banco) y se
## llama ANTES de `Mundo.nueva_temporada()`, que reinicia tabla y estadísticas.

const SEG_POR_PLANO := 6.5

static var ultimo: Array = []   ## el último documental, para volver a verlo

## Los capítulos: [{titulo, texto, tipo: escudo|jugador|rival, ref}].
static func guion(m: Mundo) -> Array:
	var c := m.mi_club() if m != null else null
	if c == null:
		return []
	var caps: Array = []
	caps.append({"titulo": "%s · Temporada %d" % [c.nombre, m.anio], "texto": "Un año entero en %d minutos de película. Esto fue lo que pasó." % 1, "tipo": "escudo", "ref": c})
	## Fichajes.
	var entran: Array = []
	var salen: Array = []
	if m.mercado != null:
		for f: Dictionary in m.mercado.fichajes_temporada:
			(entran if bool(f["entra"]) else salen).append(f)
	if not entran.is_empty() or not salen.is_empty():
		var t := ""
		if not entran.is_empty():
			entran.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["monto"]) > int(b["monto"]))
			var nombres: Array = []
			for f: Dictionary in entran.slice(0, 3):
				nombres.append("%s (desde %s)" % [f["nombre"], f["otro"]])
			t += "Llegaron %d caras nuevas: %s. " % [entran.size(), ", ".join(nombres)]
		if not salen.is_empty():
			t += "Se fueron %d, entre ellos %s." % [salen.size(), String((salen[0] as Dictionary)["nombre"])]
		caps.append({"titulo": "Capítulo 1 · El verano", "texto": t, "tipo": "escudo", "ref": c})
	else:
		caps.append({"titulo": "Capítulo 1 · El verano", "texto": "Ni una sola incorporación. El plantel que terminó el año pasado fue el que salió a pelear este.", "tipo": "escudo", "ref": c})
	## El goleador y el mejor.
	var gol: Jugador = null
	for j: Jugador in c.plantilla:
		if gol == null or j.goles > gol.goles:
			gol = j
	if gol != null and gol.goles > 0:
		caps.append({"titulo": "Capítulo 2 · El goleador", "texto": "%s marcó %d goles en %d partidos. Cada vez que el equipo necesitó a alguien, miró hacia él." % [gol.nombre, gol.goles, gol.partidos], "tipo": "jugador", "ref": gol})
	## Los partidos: mayor goleada, peor derrota y racha.
	var liga := m.liga_de(c)
	var mejor := {}
	var peor := {}
	var racha := 0
	var racha_max := 0
	var invicto := 0
	var invicto_max := 0
	if liga != null:
		for jornada: Array in liga.historial:
			for r: Dictionary in jornada:
				var mio_local: bool = r["local"] == c
				var mio_visita: bool = r["visita"] == c
				if not (mio_local or mio_visita):
					continue
				var gf := int(r["gl"]) if mio_local else int(r["gv"])
				var gc := int(r["gv"]) if mio_local else int(r["gl"])
				var rival: Club = r["visita"] if mio_local else r["local"]
				var dif := gf - gc
				if mejor.is_empty() or dif > int(mejor["dif"]):
					mejor = {"dif": dif, "gf": gf, "gc": gc, "rival": rival}
				if peor.is_empty() or dif < int(peor["dif"]):
					peor = {"dif": dif, "gf": gf, "gc": gc, "rival": rival}
				racha = racha + 1 if dif > 0 else 0
				racha_max = maxi(racha_max, racha)
				invicto = invicto + 1 if dif >= 0 else 0
				invicto_max = maxi(invicto_max, invicto)
	if not mejor.is_empty() and int(mejor["dif"]) > 0:
		caps.append({"titulo": "Capítulo 3 · La noche grande", "texto": "%d-%d a %s. La noche en la que todo salió bien y la grada no se quería ir a casa." % [mejor["gf"], mejor["gc"], (mejor["rival"] as Club).nombre], "tipo": "rival", "ref": mejor["rival"]})
	if racha_max >= 3 or invicto_max >= 5:
		caps.append({"titulo": "Capítulo 4 · La racha", "texto": "%d victorias seguidas y %d partidos sin perder. Durante unas semanas, parecía imposible ganarles." % [racha_max, invicto_max], "tipo": "escudo", "ref": c})
	if not peor.is_empty() and int(peor["dif"]) < 0:
		caps.append({"titulo": "Capítulo 5 · La herida", "texto": "%d-%d contra %s. Hubo silencio en el vestuario y alguien lo pegó en la pizarra para no olvidarlo." % [peor["gf"], peor["gc"], (peor["rival"] as Club).nombre], "tipo": "rival", "ref": peor["rival"]})
	## El veredicto.
	if liga != null:
		var t2 := liga.tabla()
		var puesto := 0
		var pts := 0
		for k in t2.size():
			if t2[k]["club"] == c:
				puesto = k + 1
				pts = int(t2[k]["pts"])
		var final := ""
		if puesto == 1:
			final = "¡CAMPEONES! %d puntos y la liga en la vitrina. Esta temporada se contará durante años." % pts
		elif puesto > t2.size() - liga.plazas_descenso:
			final = "%dº y descenso. %d puntos no alcanzaron. Toca levantarse." % [puesto, pts]
		else:
			final = "%dº de %d, con %d puntos." % [puesto, t2.size(), pts]
		caps.append({"titulo": "Capítulo final · El veredicto", "texto": final, "tipo": "escudo", "ref": c})
	caps.append({"titulo": "Fin", "texto": "Dirigida por %s.\nProtagonistas: el plantel de %s y su gente." % [m.roles.nombre if m.roles != null else "el míster", c.nombre], "tipo": "escudo", "ref": c})
	(caps[0] as Dictionary)["texto"] = "Un año entero en %d capítulos. Esto fue lo que pasó." % (caps.size() - 2)
	return caps

static func abrir(padre: Control, caps: Array, retrato: Callable = Callable()) -> DocumentalTemporada:
	if caps.is_empty():
		return null
	ultimo = caps
	var d := DocumentalTemporada.new()
	d._caps = caps
	d._retrato = retrato
	d.set_anchors_preset(Control.PRESET_FULL_RECT)
	d.mouse_filter = Control.MOUSE_FILTER_STOP
	## En su propia capa, por encima de los avisos del cierre de temporada
	## (portada del diario, prensa…), que si no lo tapaban.
	var capa := CanvasLayer.new()
	capa.layer = 60
	padre.add_child(capa)
	capa.add_child(d)
	d.tree_exited.connect(capa.queue_free)
	d._montar()
	return d

var _caps: Array = []
var _retrato: Callable
var _i := -1
var _t := 0.0
var _fondo: ColorRect
var _imagen: Control
var _titulo: Label
var _texto: Label
var _puntos: Label
var _escribiendo := 0.0

func _montar() -> void:
	_fondo = ColorRect.new()
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.color = Color(0.02, 0.02, 0.03)
	add_child(_fondo)
	_imagen = CenterContainer.new()
	_imagen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_imagen.offset_bottom = -170
	_imagen.offset_top = 60
	add_child(_imagen)
	## Franjas de cine.
	for arriba: bool in [true, false]:
		var b := ColorRect.new()
		b.color = Color.BLACK
		b.set_anchors_preset(Control.PRESET_TOP_WIDE if arriba else Control.PRESET_BOTTOM_WIDE)
		if arriba:
			b.offset_bottom = 52
		else:
			b.offset_top = -52
		add_child(b)
	_titulo = Label.new()
	_titulo.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_titulo.offset_top = -168
	_titulo.offset_bottom = -128
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.add_theme_font_size_override("font_size", 30)
	_titulo.add_theme_color_override("font_color", Color(1, 0.88, 0.55))
	add_child(_titulo)
	_texto = Label.new()
	_texto.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_texto.offset_top = -124
	_texto.offset_bottom = -58
	_texto.offset_left = 80
	_texto.offset_right = -80
	_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.add_theme_font_size_override("font_size", 19)
	_texto.add_theme_color_override("font_color", Color(0.92, 0.92, 0.9))
	add_child(_texto)
	_puntos = Label.new()
	_puntos.position = Vector2(20, 16)
	_puntos.add_theme_font_size_override("font_size", 14)
	_puntos.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	add_child(_puntos)
	var fila := HBoxContainer.new()
	fila.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	fila.offset_left = -260
	fila.offset_right = -16
	fila.offset_top = 10
	fila.add_theme_constant_override("separation", 8)
	add_child(fila)
	var sig := Button.new()
	sig.text = "Siguiente ▶"
	sig.pressed.connect(_siguiente)
	fila.add_child(sig)
	var salir := Button.new()
	salir.text = "Saltar ✕"
	salir.pressed.connect(queue_free)
	fila.add_child(salir)
	_siguiente()

func _siguiente() -> void:
	_i += 1
	if _i >= _caps.size():
		queue_free()
		return
	_t = SEG_POR_PLANO
	var cap: Dictionary = _caps[_i]
	_titulo.text = String(cap["titulo"])
	_texto.text = String(cap["texto"])
	_texto.visible_ratio = 0.0
	_escribiendo = 0.0
	_puntos.text = "🎬 DOCUMENTAL  ·  %d / %d" % [_i + 1, _caps.size()]
	for h in _imagen.get_children():
		h.queue_free()
	var tex: Texture2D = null
	var ref: Variant = cap.get("ref")
	if String(cap["tipo"]) in ["escudo", "rival"] and ref is Club:
		tex = Escudo.textura(ref as Club, 300)
		var col := Color(String((ref as Club).color1))
		_fondo.color = col.darkened(0.82)
	if String(cap["tipo"]) == "jugador" and ref is Jugador and _retrato.is_valid():
		var r: Control = _retrato.call(ref, 280)
		_imagen.add_child(r)
		_ken_burns(r)
		return
	if tex != null:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(300, 300)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_imagen.add_child(tr)
		_ken_burns(tr)

## El zoom lento de documental sobre la imagen del plano.
func _ken_burns(n: Control) -> void:
	n.pivot_offset = n.custom_minimum_size * 0.5
	n.scale = Vector2.ONE * 0.92
	n.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(n, "modulate:a", 1.0, 0.8)
	tw.parallel().tween_property(n, "scale", Vector2.ONE * 1.08, SEG_POR_PLANO)

func _process(delta: float) -> void:
	_escribiendo += delta
	_texto.visible_ratio = clampf(_escribiendo / 2.5, 0.0, 1.0)
	_t -= delta
	if _t <= 0.0:
		_siguiente()
