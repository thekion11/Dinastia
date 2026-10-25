extends BaseIdea
## PANTALLA DE IDIOMA (fase 1, etapa 1; 25-10-2026). Comprueba `PantallaIdioma`
## (`ui/entrada/idioma.gd`) de punta a punta, como la usaría el jugador:
##  - los nueve idiomas de `Idiomas.NOMBRES`, cada uno con su tarjeta y su bandera;
##  - que la pantalla entera habla el idioma enfocado (título, saludo, botones);
##  - teclado, mando y ratón mueven el foco, y cada gesto suena;
##  - elegir abre la confirmación SIN aplicar nada; cancelar (Esc, B, «Elegir
##    otro») vuelve sin emitir; confirmar aplica el idioma y emite
##    `terminado({"idioma": código})`, para CADA uno de los nueve;
##  - `volver` con Esc, y sin él cuando el estado dice `puede_volver = false`.
## Usa `await` (la confirmación tarda unas décimas en fundirse): por eso no
## hereda el `_ready` de `BaseIdea` tal cual, sino que espera a `_probar()`.

var _datos: Dictionary = {}
var _emitidos := 0
var _volveres := 0

func _ready() -> void:
	await get_tree().process_frame
	await _probar()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _probar() -> void:
	_titulo("PANTALLA DE IDIOMA (fase 1, etapa 1)")
	var original := Idiomas.idioma
	Idiomas.idioma = "es"
	await _estructura()
	await _navegacion()
	await _cancelar()
	await _volver()
	await _cada_idioma()
	Idiomas.idioma = original

# --- ayudas ----------------------------------------------------------------------

func _nueva(estado: Dictionary) -> PantallaIdioma:
	var p := PantallaIdioma.new()
	p.configurar(estado)
	p.terminado.connect(func(d: Dictionary) -> void:
		_datos = d
		_emitidos += 1)
	p.volver.connect(func() -> void: _volveres += 1)
	add_child(p)
	await _cuadros(3)
	return p

func _cuadros(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _accion(nombre: String) -> void:
	var ev := InputEventAction.new()
	ev.action = nombre
	ev.pressed = true
	get_viewport().push_input(ev)
	var suelta := InputEventAction.new()
	suelta.action = nombre
	suelta.pressed = false
	get_viewport().push_input(suelta)

func _tecla(codigo: Key) -> void:
	for apretada: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = codigo
		ev.physical_keycode = codigo
		ev.pressed = apretada
		get_viewport().push_input(ev)

func _mando(boton: JoyButton) -> void:
	for apretado: bool in [true, false]:
		var ev := InputEventJoypadButton.new()
		ev.button_index = boton
		ev.pressed = apretado
		get_viewport().push_input(ev)

func _enfocada() -> String:
	var f := get_viewport().gui_get_focus_owner()
	return String(f.name).trim_prefix("Tarjeta_") if f != null else ""

func _esperar_emision(antes: int) -> void:
	for i in 240:
		if _emitidos > antes:
			return
		await get_tree().process_frame

# --- partes ------------------------------------------------------------------------

func _estructura() -> void:
	var p := await _nueva({"idioma": "es"})
	var cods := p.codigos()
	_comprobar(cods.size() == 9 and cods == Idiomas.NOMBRES.keys(), "los nueve idiomas, en el orden de Idiomas.NOMBRES: %s" % [cods])
	var sin_tarjeta: Array = []
	var sin_bandera: Array = []
	var sin_nombre: Array = []
	for c: String in cods:
		var t := p.tarjeta(c)
		if t == null:
			sin_tarjeta.append(c)
			continue
		if t.find_children("*", "BanderaIdioma", true, false).is_empty() or not BanderaIdioma.COLORES.has(c):
			sin_bandera.append(c)
		var nombre := String((Idiomas.NOMBRES[c] as Array)[0])
		var hay := false
		for l: Node in t.find_children("*", "Label", true, false):
			hay = hay or (l as Label).text == nombre
		if not hay:
			sin_nombre.append(c)
	_comprobar(sin_tarjeta.is_empty(), "cada idioma tiene su tarjeta (faltan: %s)" % [sin_tarjeta])
	_comprobar(sin_bandera.is_empty(), "cada tarjeta lleva su bandera dibujada (faltan: %s)" % [sin_bandera])
	_comprobar(sin_nombre.is_empty(), "cada tarjeta dice el nombre nativo («Deutsch», «Türkçe»…) (faltan: %s)" % [sin_nombre])
	var pantalla := get_viewport().get_visible_rect().size
	_comprobar(p.size.is_equal_approx(pantalla), "la pantalla ocupa todo el viewport: %s de %s" % [p.size, pantalla])
	var fondo: Control = p.get_child(0)
	_comprobar(fondo is ColorRect and fondo.size.is_equal_approx(pantalla), "el fondo animado cubre toda la pantalla: %s" % [fondo.size])
	_comprobar(p.has_signal("terminado") and p.has_signal("volver") and p.has_method("configurar"), "cumple el contrato del orquestador (terminado, volver, configurar)")
	_comprobar(p.codigo_enfocado() == "es" and _enfocada() == "es", "sale enfocado el idioma del estado (es): %s / %s" % [p.codigo_enfocado(), _enfocada()])
	_comprobar(p.titulo_visible() == "Elige tu idioma", "en castellano el título dice «Elige tu idioma»: %s" % p.titulo_visible())
	## Que la pantalla entera cambia de idioma: los textos de cada uno, distintos.
	var distintos := {}
	var sin_traducir: Array = []
	for c: String in cods:
		var tx := p.textos_de(c)
		distintos[String(tx.get("saludo", ""))] = true
		if c != "es":
			for k: String in ["titulo", "saludo", "pregunta", "nota", "si", "otro"]:
				if String(tx.get(k, "")) == String(p.textos_de("es").get(k, "")):
					sin_traducir.append("%s:%s" % [c, k])
	_comprobar(distintos.size() == 9, "nueve saludos distintos, uno por idioma (%d)" % distintos.size())
	_comprobar(sin_traducir.is_empty(), "título, saludo y confirmación traducidos en los 8 idiomas (sin traducir: %s)" % [sin_traducir])
	_comprobar(Idiomas.idioma == "es", "calcular los textos de los nueve no cambia el idioma del juego")
	p.enfocar("tr")
	_comprobar(p.titulo_visible() == "Dilini seç" and p.saludo_visible() == String(p.textos_de("tr")["saludo"]), "al enfocar el turco, la vista previa habla turco: %s · %s" % [p.titulo_visible(), p.saludo_visible()])
	_comprobar(Idiomas.idioma == "es", "enfocar no aplica el idioma (solo lo enseña)")
	p.queue_free()
	await _cuadros(2)

func _navegacion() -> void:
	var p := await _nueva({"idioma": "es"})
	PantallaIdioma.ultimo_sonido = ""
	await get_tree().create_timer(0.08).timeout
	_accion("ui_right")
	await _cuadros(2)
	_comprobar(_enfocada() == "en" and p.codigo_enfocado() == "en", "teclado/acción ui_right: de es a en (%s)" % _enfocada())
	_comprobar(PantallaIdioma.ultimo_sonido == "clic_suave", "pasar a otra tarjeta suena (clic_suave): «%s»" % PantallaIdioma.ultimo_sonido)
	_comprobar(p.titulo_visible() == "Choose your language", "el título pasa al inglés: %s" % p.titulo_visible())
	_tecla(KEY_DOWN)
	await _cuadros(2)
	_comprobar(_enfocada() == "it", "flecha abajo: de en a it (%s)" % _enfocada())
	_mando(JOY_BUTTON_DPAD_RIGHT)
	await _cuadros(2)
	_comprobar(_enfocada() == "de", "cruceta del mando a la derecha: de it a de (%s)" % _enfocada())
	_mando(JOY_BUTTON_DPAD_DOWN)
	await _cuadros(2)
	_comprobar(_enfocada() == "tr" and p.titulo_visible() == "Dilini seç", "cruceta abajo: de de a tr, y el título en turco (%s · %s)" % [_enfocada(), p.titulo_visible()])
	## Ratón: pasar por encima enfoca.
	p.tarjeta("pt").mouse_entered.emit()
	await _cuadros(2)
	_comprobar(_enfocada() == "pt" and p.codigo_enfocado() == "pt", "pasar el ratón por una tarjeta la enfoca (%s)" % _enfocada())
	## Stick izquierdo hacia abajo (y soltarlo). Por `Input` y no por `push_input`:
	## el viewport solo navega con los ejes del mando cuando llegan por el camino
	## real de la entrada (comprobado aparte; con los botones da igual).
	for valor: float in [1.0, 0.0]:
		var em := InputEventJoypadMotion.new()
		em.axis = JOY_AXIS_LEFT_Y
		em.axis_value = valor
		Input.parse_input_event(em)
		await _cuadros(2)
	_comprobar(_enfocada() == "de", "stick izquierdo abajo: de pt a de (%s)" % _enfocada())
	p.queue_free()
	await _cuadros(2)

func _cancelar() -> void:
	var p := await _nueva({"idioma": "es"})
	var antes := _emitidos
	p.tarjeta("fr").pressed.emit()
	await _cuadros(3)
	_comprobar(p.confirmacion() != null, "elegir una tarjeta abre la confirmación")
	_comprobar(PantallaIdioma.ultimo_sonido == "abrir", "elegir suena (abrir): «%s»" % PantallaIdioma.ultimo_sonido)
	_comprobar(Idiomas.idioma == "es" and _emitidos == antes, "abrir la confirmación no aplica ni emite nada")
	var c := p.confirmacion()
	if c != null:
		_comprobar(c.size.is_equal_approx(p.size), "la confirmación cubre la pantalla entera (el velo oscurece todo): %s" % [c.size])
		var panel := c.boton_si.get_parent().get_parent().get_parent() as Control
		var centro_panel := panel.get_global_rect().get_center()
		_comprobar(centro_panel.distance_to(p.get_global_rect().get_center()) < 4.0, "y el cuadro sale centrado: %s" % [centro_panel])
		_comprobar(c.boton_si.has_focus(), "el foco va al «Sí, continuar» (Intro o A confirma)")
		_comprobar(c.boton_si.text == "Oui, continuer" and c.boton_otro.text == "En choisir une autre", "la confirmación habla el idioma elegido: %s / %s" % [c.boton_si.text, c.boton_otro.text])
		var textos := []
		for l: Node in c.find_children("*", "Label", true, false):
			textos.append((l as Label).text)
		_comprobar(textos.has("¿Quieres jugar en este idioma?"), "y repite la pregunta en el idioma que había (castellano)")
		_comprobar(p.tarjeta("it").focus_mode == Control.FOCUS_NONE, "con el cuadro abierto, las tarjetas de detrás no toman el foco")
	_accion("ui_cancel")
	await _cuadros(3)
	_comprobar(p.confirmacion() == null and _emitidos == antes and _volveres == 0, "Esc / B cierra la confirmación sin elegir ni volver")
	_comprobar(PantallaIdioma.ultimo_sonido == "menu_atras", "cancelar suena (menu_atras)")
	await get_tree().create_timer(0.2).timeout
	_comprobar(_enfocada() == "fr" and Idiomas.idioma == "es", "el foco vuelve a la tarjeta del francés y el idioma sigue igual (%s)" % _enfocada())
	## «Elegir otro» hace lo mismo.
	p.tarjeta("pl").pressed.emit()
	await _cuadros(3)
	if p.confirmacion() != null:
		p.confirmacion().boton_otro.pressed.emit()
	await _cuadros(3)
	_comprobar(p.confirmacion() == null and _emitidos == antes and Idiomas.idioma == "es", "«Elegir otro» cierra sin aplicar")
	p.queue_free()
	await _cuadros(2)

func _volver() -> void:
	var p := await _nueva({"idioma": "es"})
	_accion("ui_cancel")
	await _cuadros(2)
	_comprobar(_volveres == 1, "Esc en la rejilla emite volver (%d)" % _volveres)
	_mando(JOY_BUTTON_B)
	await _cuadros(2)
	_comprobar(_volveres == 2, "la B del mando también (%d)" % _volveres)
	p.queue_free()
	await _cuadros(2)
	var q := await _nueva({"idioma": "es", "puede_volver": false})
	_accion("ui_cancel")
	await _cuadros(2)
	var boton_visible := false
	for b: Node in q.find_children("*", "Button", true, false):
		boton_visible = boton_visible or ((b as Button).visible and not String(b.name).begins_with("Tarjeta_"))
	_comprobar(_volveres == 2 and not boton_visible, "con puede_volver = false no hay botón ni Esc para volver")
	q.queue_free()
	await _cuadros(2)

## Cada uno de los nueve, elegido y confirmado de verdad. El alemán se confirma con
## Intro (ui_accept) y el polaco con la A del mando; el resto, pulsando «Sí».
func _cada_idioma() -> void:
	var previo := "es"
	for c: String in Idiomas.NOMBRES:
		Idiomas.idioma = previo
		var p := await _nueva({"idioma": previo})
		p.enfocar(c)
		p.tarjeta(c).pressed.emit()
		await _cuadros(3)
		var conf := p.confirmacion()
		if conf == null:
			_comprobar(false, "%s: se abre la confirmación" % c)
			p.queue_free()
			continue
		var antes := _emitidos
		_datos = {}
		if c == "de":
			_accion("ui_accept")
		elif c == "pl":
			_mando(JOY_BUTTON_A)
		else:
			conf.boton_si.pressed.emit()
		await _esperar_emision(antes)
		_comprobar(_emitidos == antes + 1 and _datos == {"idioma": c}, "%s: confirmar emite terminado({\"idioma\": \"%s\"}) → %s" % [c, c, _datos])
		_comprobar(Idiomas.idioma == c, "%s: y el idioma queda aplicado (Idiomas.idioma = %s)" % [c, Idiomas.idioma])
		_comprobar(PantallaIdioma.ultimo_sonido == "menu_aceptar", "%s: confirmar suena (menu_aceptar)" % c)
		await _cuadros(2)
		_comprobar(p.confirmacion() == null, "%s: el cuadro de confirmación se va" % c)
		p.queue_free()
		await _cuadros(2)
		previo = c
	## Con el idioma ya aplicado, el juego traduce: comprobación cruzada con la tabla.
	Idiomas.idioma = "it"
	_comprobar(Idiomas.t("Elige tu idioma") == "Scegli la tua lingua", "con el italiano aplicado, Idiomas.t traduce los textos nuevos")
	Idiomas.idioma = "es"
