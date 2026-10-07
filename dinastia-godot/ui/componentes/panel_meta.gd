class_name PanelMeta
extends RefCounted
## EL ÁLBUM Y EL MUSEO GLOBAL, a pantalla completa (28-9-2026, `Meta`). Se
## abre desde el inicio (sin partida: solo se ven, no se abren sobres) y desde
## la carrera (con partida: los sobres salen de los jugadores de tu mundo).

static func abrir(p: Control, m: Mundo = null) -> Control:
	var pop := Control.new()
	pop.set_anchors_preset(Control.PRESET_FULL_RECT)
	pop.mouse_filter = Control.MOUSE_FILTER_STOP
	p.add_child(pop)
	var fondo := ColorRect.new()
	fondo.color = Color(0.03, 0.035, 0.045, 0.97)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	pop.add_child(fondo)
	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.offset_left = 40; raiz.offset_right = -40; raiz.offset_top = 24; raiz.offset_bottom = -24
	raiz.add_theme_constant_override("separation", 10)
	pop.add_child(raiz)
	var cab := HBoxContainer.new()
	raiz.add_child(cab)
	var tit := Tema.etiqueta(Tema.TAM_DESTACADO + 6, Tema.ORO, "📒 Álbum y museo")
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(tit)
	var cerrar := Button.new()
	cerrar.text = "✕ Cerrar"
	cerrar.pressed.connect(pop.queue_free)
	cab.add_child(cerrar)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	raiz.add_child(tabs)
	var album := VBoxContainer.new()
	album.name = "Álbum de cromos"
	tabs.add_child(album)
	var museo := ScrollContainer.new()
	museo.name = "Museo de tus carreras"
	tabs.add_child(museo)
	_pintar_album(album, m)
	_pintar_museo(museo)
	return pop

static func _pintar_album(album: VBoxContainer, m: Mundo) -> void:
	## Fuera del árbol YA (no solo `queue_free`): al abrir un sobre se busca la
	## fila de recién salidos por su índice justo después de repintar.
	for h in album.get_children():
		album.remove_child(h)
		h.queue_free()
	var d := Meta.leer()
	var cromos: Dictionary = d["cromos"]
	var cuenta := {}
	for cr: Dictionary in cromos.values():
		cuenta[String(cr["rareza"])] = int(cuenta.get(String(cr["rareza"]), 0)) + 1
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	album.add_child(fila)
	fila.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, "%d cromos distintos" % cromos.size()))
	for r: Array in Meta.RAREZAS:
		fila.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Color(String(r[3])), "%s: %d" % [String(r[1]), int(cuenta.get(String(r[0]), 0))]))
	var abrir := Button.new()
	abrir.text = "🎁 Abrir sobre (%d)" % int(d["sobres"])
	abrir.disabled = m == null or int(d["sobres"]) <= 0
	if m == null:
		abrir.tooltip_text = "Los sobres se abren con una partida en marcha: los cromos salen de tu mundo."
	fila.add_child(abrir)
	var recien := HFlowContainer.new()
	recien.add_theme_constant_override("h_separation", 10)
	recien.add_theme_constant_override("v_separation", 10)
	album.add_child(recien)
	abrir.pressed.connect(func() -> void:
		var salen := Meta.abrir_sobre(m)
		_pintar_album(album, m)
		var r2: HFlowContainer = album.get_child(1) if album.get_child_count() > 1 else null
		if r2 == null:
			return
		for i in salen.size():
			var cr: Dictionary = salen[i]
			var carta := _cromo(cr, true)
			carta.modulate.a = 0.0
			r2.add_child(carta)
			var tw := carta.create_tween()
			tw.tween_interval(0.25 * i)
			tw.tween_property(carta, "modulate:a", 1.0, 0.3))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	album.add_child(sc)
	var rej := HFlowContainer.new()
	rej.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rej.add_theme_constant_override("h_separation", 8)
	rej.add_theme_constant_override("v_separation", 8)
	sc.add_child(rej)
	var lista := cromos.values()
	var orden := {"leyenda": 0, "oro": 1, "plata": 2, "bronce": 3}
	lista.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if orden.get(a["rareza"], 9) != orden.get(b["rareza"], 9):
			return int(orden.get(a["rareza"], 9)) < int(orden.get(b["rareza"], 9))
		return int(a["ovr"]) > int(b["ovr"]))
	for cr: Dictionary in lista.slice(0, 240):
		rej.add_child(_cromo(cr, false))
	if lista.is_empty():
		album.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, "Todavía no tienes cromos. Cada temporada cerrada y cada título te dan un sobre."))

static func _cromo(cr: Dictionary, grande: bool) -> PanelContainer:
	var col := Meta.color_rareza(String(cr["rareza"]))
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(150 if grande else 120, 0)
	pc.add_theme_stylebox_override("panel", Tema.caja(col.darkened(0.7), 10, col))
	var v := VBoxContainer.new()
	pc.add_child(v)
	v.add_child(Tema.etiqueta(Tema.TAM_DESTACADO + (4 if grande else 0), col, "%d  %s" % [int(cr["ovr"]), String(cr["pos"])]))
	var n := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, String(cr["nombre"]))
	n.clip_text = true
	v.add_child(n)
	var c := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, String(cr["club"]))
	c.clip_text = true
	v.add_child(c)
	var extra := ""
	if bool(cr.get("nuevo", false)):
		extra = "✨ ¡NUEVO!"
	elif int(cr.get("veces", 1)) > 1:
		extra = "×%d" % int(cr["veces"])
	if extra != "":
		v.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.ORO, extra))
	return pc

static func _pintar_museo(museo: ScrollContainer) -> void:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	museo.add_child(v)
	var d := Meta.leer()
	var lista: Array = d["museo"]
	if lista.is_empty():
		v.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, "Aquí quedan los títulos de todas tus carreras. Todavía no ganaste ninguno."))
	for t: Dictionary in lista:
		var l := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, "🏆 %d  ·  %s  ·  %s  ·  DT: %s" % [int(t.get("anio", 0)), String(t.get("titulo", "")), String(t.get("club", "")), String(t.get("dt", ""))])
		v.add_child(l)
	var leg: Dictionary = d["legado"]
	if not leg.is_empty():
		v.add_child(HSeparator.new())
		v.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "🌍 MUNDO GUARDADO PARA HEREDAR: temporada %d, %s con %s. Al empezar una partida nueva puedes heredarlo." % [int(leg.get("anio", 0)), String(leg.get("dt", "")), String(leg.get("club", ""))]))
