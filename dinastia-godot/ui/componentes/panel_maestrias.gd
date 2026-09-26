class_name PanelMaestrias
extends RefCounted
## LAS 15 MAESTRÍAS DE 30 NIVELES, EN TARJETAS (26-9-2026). Debajo del árbol de
## habilidades. Cada tarjeta: icono y nombre en el color de la categoría, el
## nivel sobre 30 con una barra de 30 segmentos (los hitos 10, 20 y 30 marcados
## en dorado), el efecto actual y el botón para subir con lo que cuesta.

static func pintar(lista: VBoxContainer, mundo: Mundo, p: Control) -> void:
	var m := mundo.maestria
	if m == null:
		return
	var cab := HBoxContainer.new()
	lista.add_child(cab)
	var t := Tema.etiqueta(Tema.TAM_DESTACADO + 2, Tema.ORO, "🏅 MAESTRÍAS")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(t)
	var pts := Tema.etiqueta(Tema.TAM_CUERPO, Tema.ORO if m.puntos > 0 else Tema.SUAVE,
		"%d punto%s de maestría · %d / %d niveles" % [m.puntos, "" if m.puntos == 1 else "s",
		m.total_niveles(), Maestria.NIVEL_MAX * Maestria.ORDEN.size()])
	cab.add_child(pts)
	var ayuda := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE,
		"Ganas un punto por semana y otro por victoria. En los niveles 10, 20 y 30 hay un hito: el efecto se refuerza y ganas un punto de habilidad para el árbol.")
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista.add_child(ayuda)
	var flujo := HFlowContainer.new()
	flujo.add_theme_constant_override("h_separation", Tema.ESPACIO)
	flujo.add_theme_constant_override("v_separation", Tema.ESPACIO)
	lista.add_child(flujo)
	for k: String in Maestria.ORDEN:
		flujo.add_child(_tarjeta(k, m, mundo, p))

static func _tarjeta(k: String, m: Maestria, mundo: Mundo, p: Control) -> PanelContainer:
	var d: Array = Maestria.CATEGORIAS[k]
	var col := Color(String(d[2]))
	var n := m.nivel(k)
	var pc := PanelContainer.new()
	var sb := Tema.caja(Tema.TARJETA, Tema.RADIO, Color(col, 0.55 if n > 0 else 0.2))
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	pc.add_theme_stylebox_override("panel", sb)
	pc.custom_minimum_size = Vector2(200, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	pc.add_child(vb)
	var fila := HBoxContainer.new()
	vb.add_child(fila)
	fila.add_child(Tema.etiqueta(24, Tema.TEXTO, String(d[1])))
	var nom := Tema.etiqueta(Tema.TAM_CUERPO, col.lightened(0.15), String(d[0]))
	nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nom.clip_text = true
	fila.add_child(nom)
	fila.add_child(Tema.etiqueta(Tema.TAM_DESTACADO, Tema.ORO if n >= Maestria.NIVEL_MAX else Tema.TEXTO, "%d/%d" % [n, Maestria.NIVEL_MAX]))
	## Barra de 30 segmentos, con los hitos en dorado.
	var barra := HBoxContainer.new()
	barra.add_theme_constant_override("separation", 1)
	vb.add_child(barra)
	for i in Maestria.NIVEL_MAX:
		var seg := ColorRect.new()
		seg.custom_minimum_size = Vector2(5, 8 if not Maestria.HITOS.has(i + 1) else 12)
		seg.size_flags_vertical = Control.SIZE_SHRINK_END
		var hito := Maestria.HITOS.has(i + 1)
		seg.color = (Tema.ORO if hito else col) if i < n else Color(1, 1, 1, 0.08 if not hito else 0.2)
		barra.add_child(seg)
	var ef := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, m.efecto_actual(k) if n > 0 else String(d[3]))
	ef.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(ef)
	var b := Button.new()
	b.add_theme_font_size_override("font_size", 12)
	if n >= Maestria.NIVEL_MAX:
		b.text = "✔ Maestría completa"
		b.disabled = true
	else:
		b.text = "Subir a %d · %d pto%s" % [n + 1, m.coste(k), "" if m.coste(k) == 1 else "s"]
		b.disabled = m.puntos < m.coste(k)
	b.pressed.connect(func() -> void:
		var problema := m.subir(k, mundo.entrenamiento)
		if problema != "":
			Aviso.mostrar(p, "alerta", "⚠️", "No se pudo", problema)
		else:
			Sonido.toca("cambio", Sonido.Bus.INTERFAZ)
		p.call("_refrescar"))
	vb.add_child(b)
	return pc
