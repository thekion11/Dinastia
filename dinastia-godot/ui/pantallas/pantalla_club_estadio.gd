class_name PantallaClubEstadio
extends RefCounted
## CLUB → ESTADIO: los estilos, el diseño por secciones y las reformas.
##
## Sale de `ui/principal.gd` (mapa de metas 15: el archivo pasaba de
## 15.000 líneas). `p` es la pantalla principal: sus ayudantes (`p._texto`,
## `p._boton`...), el mundo (`p.mundo`) y el repintado (`p._refrescar()`).

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

func _pintar_estilos_estadio(c: Club) -> void:
	var e := p.mundo.estadio
	if e == null:
		return
	p._lista_estadio.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "✨ ESTILOS COMPLETOS"
	p._lista_estadio.add_child(t)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	p._lista_estadio.add_child(flow)
	for p_local: Dictionary in e.presets():
		var clave := String(p_local["clave"])
		var coste := e.coste_preset(c, clave, p.mundo.obras)
		var b := Button.new()
		b.text = "%s  ·  %s" % [Nombres.limpiar(String(p_local["nombre"])), p._dinero(coste)]
		b.tooltip_text = Nombres.limpiar(String(p_local["desc"]))
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = coste > c.saldo
		b.pressed.connect(_aplicar_estilo_estadio.bind(clave))
		flow.add_child(b)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	p._lista_estadio.add_child(fila)
	var sorpresa := Button.new()
	sorpresa.text = "🎲 Sorpréndeme"
	sorpresa.add_theme_font_size_override("font_size", 11)
	sorpresa.pressed.connect(func() -> void:
		p._propuesta_estadio = p.mundo.estadio.aleatorio(p.mundo.mi_club(), p.mundo.obras)
		p._refrescar())
	fila.add_child(sorpresa)
	var fabrica := Button.new()
	fabrica.text = "↺ Volver al estadio de fábrica"
	fabrica.add_theme_font_size_override("font_size", 11)
	fabrica.pressed.connect(_estadio_de_fabrica)
	fila.add_child(fabrica)
	if not p._propuesta_estadio.is_empty():
		var coste_prop := e.presupuesto(c, p._propuesta_estadio, p.mundo.obras)
		var prop := p._texto(11, Principal.COL_ORO)
		prop.text = "Propuesta: %s. Coste %s." % [_resumen_propuesta(p._propuesta_estadio), p._dinero(coste_prop)]
		prop.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_estadio.add_child(prop)
		var fila2 := HBoxContainer.new()
		fila2.add_theme_constant_override("separation", 6)
		p._lista_estadio.add_child(fila2)
		var si := Button.new()
		si.text = "Construirla"
		si.disabled = coste_prop > c.saldo
		si.pressed.connect(_aplicar_propuesta_estadio)
		fila2.add_child(si)
		var no := Button.new()
		no.text = "Descartar"
		no.pressed.connect(func() -> void:
			p._propuesta_estadio = {}
			p._refrescar())
		fila2.add_child(no)

func _aplicar_estilo_estadio(clave: String) -> void:
	var coste := p.mundo.estadio.coste_preset(p.mundo.mi_club(), clave, p.mundo.obras)
	var problema := p.mundo.estadio.aplicar_preset(p.mundo.mi_club(), clave, p.mundo.obras)
	if problema != "":
		p._escribir("[color=#e05555]No se puede: %s.[/color]" % problema)
	else:
		p._escribir("[color=#4caf6d]Estadio rehecho:[/color] estilo «%s». Coste %s." % [
			Nombres.limpiar(String(p.mundo.estadio.preset(clave).get("nombre", clave))), p._dinero(coste)])
	p._refrescar()

func _aplicar_propuesta_estadio() -> void:
	var cambios := p._propuesta_estadio
	var coste := p.mundo.estadio.presupuesto(p.mundo.mi_club(), cambios, p.mundo.obras)
	var problema := p.mundo.estadio.reformar(p.mundo.mi_club(), cambios, p.mundo.obras)
	if problema != "":
		p._escribir("[color=#e05555]No se puede: %s.[/color]" % problema)
	else:
		p._escribir("[color=#4caf6d]Estadio sorpresa construido.[/color] Coste %s." % p._dinero(coste))
		p._propuesta_estadio = {}
	p._refrescar()

## "↺ Volver a fábrica": los valores de `EST_DEF` como una reforma más. Solo
## los campos que el catálogo sabe reformar -más bandejas, pista y vallas- y
## solo los que de verdad cambian: aquí toda obra se paga, también la que
## deshace lo hecho, y no hay por qué cobrar por dejar algo como ya estaba.
func _estadio_de_fabrica() -> void:
	var def: Variant = Datos.tabla("EST_DEF")
	if not (def is Dictionary):
		return
	var cambios := {}
	for k: String in (def as Dictionary):
		var valido: bool = EstadioPropio.CATALOGO_DE.has(k) or ["niveles", "pista", "vallas"].has(k)
		if valido and p.mundo.estadio.ajustes.has(k) and p.mundo.estadio.ajustes[k] != (def as Dictionary)[k]:
			cambios[k] = (def as Dictionary)[k]
	if cambios.is_empty():
		p._escribir("[color=#8ea595]El estadio ya está como vino de fábrica.[/color]")
		return
	var coste := p.mundo.estadio.presupuesto(p.mundo.mi_club(), cambios, p.mundo.obras)
	var problema := p.mundo.estadio.reformar(p.mundo.mi_club(), cambios, p.mundo.obras)
	if problema != "":
		p._escribir("[color=#e05555]No se puede: %s.[/color]" % problema)
	else:
		p._escribir("[color=#4caf6d]Estadio devuelto a fábrica.[/color] Coste %s." % p._dinero(coste))
	p._refrescar()

func _resumen_propuesta(cambios: Dictionary) -> String:
	var partes: Array[String] = []
	for k: String in ["forma", "techo", "focos", "cesped", "niveles"]:
		if cambios.has(k):
			partes.append("%s %s" % [String(Principal.ETIQUETAS_ESTADIO.get(k, k)).to_lower(), str(cambios[k])])
	return ", ".join(partes)

## Un interruptor del diseñador: los campos que son sí o no y no tienen catálogo.
func _fila_interruptor_estadio(p_local: Dictionary, campo: String, titulo: String, nota: String) -> void:
	if not p_local.has(campo):
		return
	var cb := CheckBox.new()
	cb.add_theme_font_size_override("font_size", 11)
	cb.text = titulo
	cb.button_pressed = bool(p_local[campo])
	cb.tooltip_text = nota
	cb.toggled.connect(func(activo: bool) -> void:
		_reformar_valor(campo, activo))
	p._lista_estadio.add_child(cb)
	var n := p._texto(10, Principal.COL_SUAVE)
	n.text = nota
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_estadio.add_child(n)

## Un desplegable del diseñador. Sale aparte porque ahora hay diecisiete y
## repetir veinte líneas por cada uno sería insostenible.
func _fila_diseno_estadio(e: EstadioPropio, p_local: Dictionary, campo: String) -> void:
	var ops: Array = e.opciones(campo)
	if ops.is_empty():
		return
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	p._lista_estadio.add_child(fila)
	var l := p._texto(11, Principal.COL_SUAVE)
	l.text = String(Principal.ETIQUETAS_ESTADIO.get(campo, campo.capitalize()))
	l.custom_minimum_size = Vector2(130, 0)
	l.clip_text = true
	fila.add_child(l)
	var b := OptionButton.new()
	b.add_theme_font_size_override("font_size", 11)
	b.clip_text = true
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in ops.size():
		var o: Dictionary = ops[i]
		b.add_item(String(o["nombre"]))
		b.set_item_metadata(i, String(o["clave"]))
		## Los colores se eligen viéndolos (B6.1): una muestra junto al nombre.
		if String(o["clave"]).begins_with("#"):
			b.set_item_icon(i, _muestra_color(Color(String(o["clave"]))))
		if String(o["clave"]) == String(e.ajustes.get(campo, p_local.get(campo, ""))):
			b.select(i)
	b.item_selected.connect(func(idx: int) -> void:
		_reformar(campo, String(b.get_item_metadata(idx))))
	fila.add_child(b)
	## ESCUCHAR ANTES DE PAGAR -el "▶" de cada sonido en el HTML-. Elegir en el
	## desplegable ya COBRA la reforma, así que probar tiene que ir aparte: un
	## menú con los ocho que solo los toca, sin comprar nada.
	if campo == "sonidoGol":
		var escuchar := MenuButton.new()
		escuchar.text = "▶ Escuchar"
		escuchar.tooltip_text = "Probar cualquier sonido de gol sin pagar la reforma"
		escuchar.add_theme_font_size_override("font_size", 11)
		var pop := escuchar.get_popup()
		for i in ops.size():
			pop.add_item(String((ops[i] as Dictionary)["nombre"]), i)
		pop.id_pressed.connect(_probar_sonido_gol.bind(ops))
		fila.add_child(escuchar)

func _muestra_color(c: Color) -> Texture2D:
	var k := c.to_html(false)
	if not Principal._muestras.has(k):
		var img := Image.create(14, 14, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0.6))
		img.fill_rect(Rect2i(1, 1, 12, 12), c)
		Principal._muestras[k] = ImageTexture.create_from_image(img)
	return Principal._muestras[k]

## Con nombre propio y no como lambda: un `match` o varias líneas dentro de un
## lambda pasado como argumento ya rompió el parser de este archivo una vez.
func _probar_sonido_gol(id: int, ops: Array) -> void:
	if id >= 0 and id < ops.size():
		Sonido.toca("gol_" + String((ops[id] as Dictionary)["clave"]))

func _reformar(campo: String, valor: String) -> void:
	_reformar_valor(campo, valor)

## La reforma de verdad. Acepta Variant porque el diseñador ya no es solo de
## desplegables: `pista` y `vallas` son booleanos y `reformar()` los admite.
func _reformar_valor(campo: String, valor: Variant) -> void:
	var cambios := {campo: valor}
	var coste := p.mundo.estadio.presupuesto(p.mundo.mi_club(), cambios, p.mundo.obras)
	var problema := p.mundo.estadio.reformar(p.mundo.mi_club(), cambios, p.mundo.obras)
	if problema != "":
		p._escribir("[color=#e05555]No se puede reformar: %s.[/color]" % problema)
		p._refrescar()
		return
	var visible: String = String(valor)
	if valor is bool:
		visible = "sí" if bool(valor) else "no"
	p._escribir("[color=#4caf6d]Reforma hecha:[/color] %s → %s. Coste %s." % [
		String(Principal.ETIQUETAS_ESTADIO.get(campo, campo.capitalize())), visible, p._dinero(coste)])
	p._refrescar()
