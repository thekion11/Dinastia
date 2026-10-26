class_name AjustesAcceso
extends RefCounted
## LO QUE LE FALTABA A AJUSTES → ACCESIBILIDAD (uiaj, 25-10-2026). La sección
## tenía tres interruptores sin ver qué hacían: el tamaño del texto se elegía a
## ciegas y la paleta para daltonismo no enseñaba los colores que cambia. Aquí
## van las vistas previas (se repintan con cada cambio, porque `_refrescar()`
## vuelve a pintar la sección), la vibración del mando con su botón de probar,
## las animaciones reducidas y lo que hay que saber sobre subtítulos.
## `p` es la pantalla principal, como en `PantallaAjustes`.

## La muestra del tamaño del texto: una frase de verdad pintada con `_texto()`,
## que es por donde pasa la escala, y para qué sirve cada uno de los dos zooms.
static func muestra_texto(p: Principal) -> void:
	var caja := _caja_muestra(p)
	var v := VBoxContainer.new()
	caja.add_child(v)
	var m := p._texto(12, Principal.COL_TEXTO)
	m.text = Idiomas.t("Así se leen las tablas, las fichas y las noticias con este tamaño.")
	m.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(m)
	var m2 := p._texto(10, Principal.COL_SUAVE)
	m2.text = Idiomas.t("Y así las notas pequeñas como esta.")
	m2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(m2)
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = Idiomas.t("Agranda las letras de las pantallas de gestión. Para agrandar TODO (botones y menús incluidos) usa Pantalla → Tamaño de la interfaz.")
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_ajustes.add_child(ex)

## Los tres colores que cambia la paleta para daltonismo, tal y como se ven
## ahora: así se comprueba el cambio sin ir a buscar una tabla con resultados.
static func muestra_colores(p: Principal) -> void:
	var caja := _caja_muestra(p)
	var fila := HFlowContainer.new()
	fila.add_theme_constant_override("h_separation", 16)
	caja.add_child(fila)
	for par: Array in [[Principal.COL_VERDE, "Victoria · sube"], [Principal.COL_ROJO, "Derrota · baja"], [Principal.COL_ORO, "Destacado"]]:
		var col: Color = p._color_accesible(par[0] as Color)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		fila.add_child(h)
		var chip := ColorRect.new()
		chip.color = col
		chip.custom_minimum_size = Vector2(22, 14)
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(chip)
		var l := p._texto(12, par[0] as Color)
		l.text = Idiomas.t(String(par[1]))
		h.add_child(l)

## La vibración del mando: la misma ayuda que en Controles (`Mando.ayudas`),
## aquí también porque hay quien la necesita apagada o suave por las manos.
static func vibracion(p: Principal) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	p._lista_ajustes.add_child(fila)
	var et := p._texto(12, Principal.COL_TEXTO)
	et.text = Idiomas.t("Vibración del mando")
	et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(et)
	var nombres: Dictionary = (PanelControles.NOMBRES_AYUDA["vibracion"] as Array)[1]
	for modo: String in Mando.AYUDAS["vibracion"]:
		var clave := modo
		var b := Button.new()
		b.text = Idiomas.t(String(nombres.get(clave, clave)))
		b.add_theme_font_size_override("font_size", 11)
		b.toggle_mode = true
		b.button_pressed = Mando.ayuda("vibracion") == clave
		b.pressed.connect(func() -> void:
			Mando.fijar_ayuda("vibracion", clave)
			Mando.vibrar(0.8, 0.35)
			p._refrescar())
		fila.add_child(b)
	var probar := Button.new()
	probar.text = Idiomas.t("Probar")
	probar.add_theme_font_size_override("font_size", 11)
	probar.disabled = not Mando.hay_mando() or Mando.ayuda("vibracion") == "no"
	probar.tooltip_text = Idiomas.t("Conecta un mando para notarla.") if not Mando.hay_mando() else ""
	probar.pressed.connect(func() -> void: Mando.vibrar(0.8, 0.35))
	fila.add_child(probar)

## Animaciones reducidas: vive en Juego → La interfaz a tu medida, y se repite
## aquí porque es lo primero que busca quien se marea con el movimiento.
static func animaciones(p: Principal) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila)
	var et := p._texto(12, Principal.COL_TEXTO)
	et.text = Idiomas.t("Animaciones reducidas")
	et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et.tooltip_text = Idiomas.t("Sin entradas escalonadas, cifras que cuentan ni latidos: todo aparece al instante.")
	fila.add_child(et)
	var b := Button.new()
	b.text = "SÍ" if Animar.reducidas() else "NO"
	b.pressed.connect(func() -> void:
		Animar.fijar_reducidas(not Animar.reducidas())
		p._refrescar())
	fila.add_child(b)

## Subtítulos: no hay interruptor porque no hay voces, y eso se dice en vez de
## dejar que el jugador lo busque.
static func nota_subtitulos(p: Principal) -> void:
	var l := p._texto(10, Principal.COL_SUAVE)
	l.text = Idiomas.t("Subtítulos: el juego no tiene voces. La narración del partido, la prensa y el vestuario ya salen siempre escritos.")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_ajustes.add_child(l)

static func _caja_muestra(p: Principal) -> PanelContainer:
	var caja := PanelContainer.new()
	var e := StyleBoxFlat.new()
	e.bg_color = Color(0, 0, 0, 0.22)
	e.set_corner_radius_all(6)
	e.content_margin_left = 10
	e.content_margin_right = 10
	e.content_margin_top = 6
	e.content_margin_bottom = 6
	caja.add_theme_stylebox_override("panel", e)
	p._lista_ajustes.add_child(caja)
	return caja
