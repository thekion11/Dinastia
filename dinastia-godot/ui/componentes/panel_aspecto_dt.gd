class_name PanelAspectoDT
extends RefCounted
## EL ASPECTO DEL ENTRENADOR (CENTRAL → Mi Carrera), sacado de `principal.gd` el
## 25-9-2026 con el mismo patrón que `FichaJugadorAcciones`: una clase
## estática que pinta una vez por refresco. Lo que era de `Principal` llega por
## parámetro: la lista donde pintar, el `_texto()` de siempre como `Callable`
## (el que aplica paleta, modo daltónico y escala de letra: una sola fuente de
## verdad) y `_refrescar()` como `al_cambiar`. Los cambios se guardan directo
## en `Roles.look`, igual que antes.
##
## TU ASPECTO. `DT_PELOS`/`DT_TRAJES` llevaban desde el HTML original en
## `tablas.json`, portados a `CaraDT`, sin que ninguna pantalla de Godot los
## usara -552 combinaciones (23 cortes × 3 volúmenes × 4 rayas × 2
## laterales) escritas y ningún sitio donde elegirlas-. Mismo patrón que la
## Identidad del club: vista previa arriba, controles debajo, y cada cambio
## se guarda directo en `Roles.look` -solo el rasgo tocado, el resto sigue
## saliendo de `CaraDT.look_por_defecto()`-.
static func pintar(lista: VBoxContainer, r: Roles, texto: Callable, colores: Dictionary,
		al_cambiar: Callable, abrir_creador: Callable = Callable()) -> void:
	var t: Label = texto.call(11, colores["acento"])
	t.text = "🧑‍💼 TU ASPECTO"
	lista.add_child(t)
	## EL PERSONAJE EN 3D (26-9-2026): el creador a pantalla completa. El
	## retrato 2D de abajo sigue siendo el de las fichas y la prensa.
	if abrir_creador.is_valid():
		var b3 := Button.new()
		b3.text = "🧍 Crear y vestir mi personaje 3D"
		b3.custom_minimum_size = Vector2(0, 40)
		b3.add_theme_font_size_override("font_size", 13)
		b3.pressed.connect(func() -> void: abrir_creador.call())
		lista.add_child(b3)

	var l := r.look_efectivo()
	var previa := HBoxContainer.new()
	previa.add_theme_constant_override("separation", 14)
	previa.alignment = BoxContainer.ALIGNMENT_CENTER
	lista.add_child(previa)
	var img := TextureRect.new()
	img.texture = CaraDT.textura(l, 64)
	img.custom_minimum_size = Vector2(64, 64)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	previa.add_child(img)
	var b_azar := Button.new()
	b_azar.text = "🎲 Aleatorio"
	b_azar.add_theme_font_size_override("font_size", 11)
	b_azar.pressed.connect(func() -> void:
		r.look = CaraDT.look_aleatorio()
		al_cambiar.call())
	previa.add_child(b_azar)

	## El corte de pelo: rejilla de botones, igual que el diseño de camiseta
	## en Identidad.
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	lista.add_child(flow)
	for corte: String in CaraDT.CORTES:
		var b := Button.new()
		b.text = corte
		b.add_theme_font_size_override("font_size", 10)
		b.toggle_mode = true
		b.button_pressed = String(l.get("pelo", "")) == corte
		b.clip_text = true
		b.custom_minimum_size = Vector2(66, 22)
		b.pressed.connect(func() -> void:
			r.look = r.look_efectivo()
			r.look["pelo"] = corte
			al_cambiar.call())
		flow.add_child(b)

	## Volumen, raya y laterales: los tres modificadores que llevan 23 cortes
	## a 552 combinaciones.
	var fila_mod := HBoxContainer.new()
	fila_mod.add_theme_constant_override("separation", 10)
	lista.add_child(fila_mod)
	var vol_box := VBoxContainer.new()
	fila_mod.add_child(vol_box)
	var vol_et: Label = texto.call(10, colores["suave"]); vol_et.text = "Volumen"
	vol_box.add_child(vol_et)
	var vol_fila := HBoxContainer.new()
	vol_box.add_child(vol_fila)
	for i in CaraDT.VOLS.size():
		var bv := Button.new()
		bv.text = String(CaraDT.VOLS[i])
		bv.add_theme_font_size_override("font_size", 10)
		bv.toggle_mode = true
		bv.button_pressed = int(l.get("vol", 1)) == i
		var iv := i
		bv.pressed.connect(func() -> void:
			r.look = r.look_efectivo()
			r.look["vol"] = iv
			al_cambiar.call())
		vol_fila.add_child(bv)
	var raya_box := VBoxContainer.new()
	fila_mod.add_child(raya_box)
	var raya_et: Label = texto.call(10, colores["suave"]); raya_et.text = "Raya"
	raya_box.add_child(raya_et)
	var raya_fila := HBoxContainer.new()
	raya_box.add_child(raya_fila)
	for nombre_raya: Array in [["Ninguna", 0], ["Izquierda", 1], ["Medio", 2], ["Derecha", 3]]:
		var br := Button.new()
		br.text = String(nombre_raya[0])
		br.add_theme_font_size_override("font_size", 10)
		br.toggle_mode = true
		br.button_pressed = int(l.get("raya", 0)) == int(nombre_raya[1])
		var vr := int(nombre_raya[1])
		br.pressed.connect(func() -> void:
			r.look = r.look_efectivo()
			r.look["raya"] = vr
			al_cambiar.call())
		raya_fila.add_child(br)
	var lados_b := Button.new()
	lados_b.text = "Rapar sienes"
	lados_b.add_theme_font_size_override("font_size", 10)
	lados_b.toggle_mode = true
	lados_b.button_pressed = bool(l.get("lados", false))
	lados_b.pressed.connect(func() -> void:
		r.look = r.look_efectivo()
		r.look["lados"] = not bool(l.get("lados", false))
		al_cambiar.call())
	fila_mod.add_child(lados_b)

	## Barba: 0 a 7, mismo catálogo que el HTML -sin nombres, son formas-.
	var barba_et: Label = texto.call(10, colores["suave"]); barba_et.text = "Barba"
	lista.add_child(barba_et)
	var barba_fila := HFlowContainer.new()
	barba_fila.add_theme_constant_override("h_separation", 4)
	lista.add_child(barba_fila)
	for bd in 8:
		var bb := Button.new()
		bb.text = "Sin barba" if bd == 0 else str(bd)
		bb.add_theme_font_size_override("font_size", 10)
		bb.toggle_mode = true
		bb.button_pressed = int(l.get("barba", 0)) == bd
		bb.custom_minimum_size = Vector2(40, 22)
		var vbd := bd
		bb.pressed.connect(func() -> void:
			r.look = r.look_efectivo()
			r.look["barba"] = vbd
			al_cambiar.call())
		barba_fila.add_child(bb)

	## El traje: el mismo catálogo de `DT_TRAJES` que ya vivía en la tabla sin
	## que nadie lo mostrara.
	var traje_et: Label = texto.call(10, colores["suave"]); traje_et.text = "Vestimenta"
	lista.add_child(traje_et)
	var traje_fila := HFlowContainer.new()
	traje_fila.add_theme_constant_override("h_separation", 4)
	lista.add_child(traje_fila)
	for fila_t: Array in CaraDT.TRAJES:
		var bt := Button.new()
		bt.text = String(fila_t[1])
		bt.add_theme_font_size_override("font_size", 10)
		bt.toggle_mode = true
		bt.button_pressed = String(l.get("traje", "")) == String(fila_t[0])
		var id_t := String(fila_t[0])
		bt.pressed.connect(func() -> void:
			r.look = r.look_efectivo()
			r.look["traje"] = id_t
			al_cambiar.call())
		traje_fila.add_child(bt)

	## Los colores libres y las gafas, en una fila compacta.
	var fila_col := HBoxContainer.new()
	fila_col.add_theme_constant_override("separation", 10)
	lista.add_child(fila_col)
	## Para los cuatro heredables ("" = sin elegir) el selector tiene que
	## arrancar mostrando el color EFECTIVO -el que ya se ve en la vista
	## previa-, no negro: mostrar negro para "sin elegir" haría creer que el
	## color es negro. Son los mismos tres efectivos que ya calculó svg_de().
	var pelo_col_ef := "#b9bcb8" if int(l.get("edad", 44)) >= 45 else String(l.get("pelo_c", "#3d2a19"))
	var efectivo := {
		"piel": String(l.get("piel", "#e0ab80")),
		"pelo_c": String(l.get("pelo_c", "#3d2a19")),
		"barba_c": pelo_col_ef,
		"ojos_c": "#2b1d12",
		"ropa_c": "#1e4030",
		"ropa_c2": "#e8ede9",
	}
	for par: Array in [["Piel", "piel"], ["Pelo", "pelo_c"], ["Barba", "barba_c"],
			["Ojos", "ojos_c"], ["Vestimenta 1", "ropa_c"], ["Vestimenta 2", "ropa_c2"]]:
		var clave := String(par[1])
		var col_box := VBoxContainer.new()
		fila_col.add_child(col_box)
		var et: Label = texto.call(9, colores["suave"]); et.text = String(par[0])
		col_box.add_child(et)
		var actual := String(l.get(clave, ""))
		var cp := ColorPickerButton.new()
		cp.color = Color(actual) if actual != "" else Color(String(efectivo[clave]))
		cp.custom_minimum_size = Vector2(58, 22)
		cp.edit_alpha = false
		cp.color_changed.connect(func(nuevo: Color) -> void:
			r.look = r.look_efectivo()
			r.look[clave] = "#" + nuevo.to_html(false)
			al_cambiar.call())
		col_box.add_child(cp)
	var gafas_b := Button.new()
	gafas_b.text = "👓 Gafas"
	gafas_b.add_theme_font_size_override("font_size", 10)
	gafas_b.toggle_mode = true
	gafas_b.button_pressed = bool(l.get("gafas", false))
	gafas_b.pressed.connect(func() -> void:
		r.look = r.look_efectivo()
		r.look["gafas"] = not bool(l.get("gafas", false))
		al_cambiar.call())
	fila_col.add_child(gafas_b)
