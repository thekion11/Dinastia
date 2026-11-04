class_name LectorPantalla
## M-284 (2-11-2026): LECTURA DE PANTALLA. Con el interruptor de Ajustes → Accesibilidad encendido, el juego LEE EN VOZ ALTA
## (voz del sistema, `DisplayServer.tts_*`) el control que toma el foco: el rótulo del botón, la etiqueta, el texto o la
## pista del campo, y su ayuda si la tiene. Sin voces instaladas (o sin pantalla) no hace nada y no se queja. Se engancha una
## vez al árbol desde `Idiomas._ready` (`vigilar`), como `TextoQueCabe`. `decir()` sirve para avisos sueltos.

const RUTA := "user://ajustes.cfg"
static var _activo := -1
static var _voz := ""
static var _ultimo := ""

static func activo() -> bool:
	if _activo < 0:
		var cfg := ConfigFile.new()
		_activo = 1 if cfg.load(RUTA) == OK and bool(cfg.get_value("acceso", "lector", false)) else 0
	return _activo == 1

static func fijar(si: bool) -> void:
	_activo = 1 if si else 0
	var cfg := ConfigFile.new()
	cfg.load(RUTA)
	cfg.set_value("acceso", "lector", si)
	cfg.save(RUTA)
	if not si:
		parar()

## Se llama una vez, al arrancar.
static func vigilar(arbol: SceneTree) -> void:
	if arbol != null and arbol.root != null and not arbol.root.gui_focus_changed.is_connected(_al_enfocar):
		arbol.root.gui_focus_changed.connect(_al_enfocar)

static func _al_enfocar(c: Control) -> void:
	if activo():
		decir(texto_de(c))

## Lo que se lee de un control: su texto (o la pista si está vacío) y su ayuda; "" si no hay nada que leer.
static func texto_de(c: Control) -> String:
	if c == null:
		return ""
	var partes: Array[String] = []
	var t := ""
	if c is LineEdit:
		t = (c as LineEdit).text if (c as LineEdit).text != "" else (c as LineEdit).placeholder_text
	elif c is TextEdit:
		t = (c as TextEdit).text
	elif c is OptionButton and (c as OptionButton).selected >= 0:
		t = (c as OptionButton).get_item_text((c as OptionButton).selected)
	elif c.get("text") != null:
		t = String(c.get("text"))
	t = _limpiar(t)
	if t != "":
		partes.append(t)
	if c is CheckButton or c is CheckBox:
		partes.append(Idiomas.t("activado") if (c as BaseButton).button_pressed else Idiomas.t("desactivado"))
	if c.tooltip_text.strip_edges() != "":
		partes.append(_limpiar(c.tooltip_text))
	## Sin rótulo ni ayuda (selector de color, casilla suelta): lo nombra la etiqueta que va justo antes en su fila («Color 1», «Color del bus del equipo»).
	if partes.is_empty() or (partes.size() == 1 and c is ColorPickerButton):
		var vecina := _etiqueta_previa(c)
		if vecina != "":
			partes.push_front(vecina)
	## Un botón transparente encima de una tarjeta (el tablero del Inicio) lee lo que dice la tarjeta; una miniatura sin ayuda, «Opción 3 de 12».
	if partes.is_empty() and c is Button:
		var tarjeta := _texto_de_la_tarjeta(c)
		if tarjeta != "":
			partes.append(tarjeta)
		elif ((c as Button).icon != null or (c as Button).text.strip_edges() != "") and c.get_parent() != null:   ## miniatura o solo un emoji (la voz no lo lee)
			partes.append(Idiomas.t("Opción %d de %d") % [c.get_index() + 1, c.get_parent().get_child_count()])
			if (c as Button).toggle_mode and (c as Button).button_pressed:
				partes.append(Idiomas.t("elegida"))
	return ". ".join(partes)

## Los textos de las etiquetas del contenedor hermano (una tarjeta con un botón encima), hasta 4.
static func _texto_de_la_tarjeta(c: Control) -> String:
	var padre := c.get_parent()
	if padre == null:
		return ""
	var trozos: Array[String] = []
	var fuentes: Array = [c]   ## sus propias etiquetas (un botón-tarjeta con hijos) y las del contenedor hermano
	for h in padre.get_children():
		if h != c and h is Container:
			fuentes.append(h)
	for h in fuentes:
		for l in (h as Node).find_children("*", "Label", true, false):
			var t := _limpiar((l as Label).text)
			if t != "" and trozos.size() < 4:
				trozos.append(t)
		if not trozos.is_empty():
			break   ## lo suyo primero; los hermanos solo si no lleva nada dentro
	return ". ".join(trozos)

static func _etiqueta_previa(c: Control) -> String:
	var padre := c.get_parent()
	if padre == null:
		return ""
	var i := c.get_index() - 1
	while i >= 0:
		var h := padre.get_child(i)
		if h is Label and (h as Label).text.strip_edges() != "":
			return _limpiar((h as Label).text)
		i -= 1
	return ""

## Fuera iconos y marcas de formato: la voz no lee «⚽» ni «[b]».
static func _limpiar(t: String) -> String:
	var r := RegEx.create_from_string("\\[/?[a-z_=#0-9 ]+\\]")
	var s := r.sub(t, "", true).strip_edges()
	var salida := ""
	for i in s.length():
		var u := s.unicode_at(i)
		if u < 0x2190 or (u >= 0x3000 and u < 0xE000):   ## se quedan letras, números, signos y los alfabetos; fuera flechas y emoji
			salida += s[i]
	return salida.strip_edges().replace("  ", " ")

static func decir(texto: String) -> void:
	if texto == "" or texto == _ultimo or not _hay_voz():
		return
	_ultimo = texto
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(texto, _voz, 50, 1.0, 1.1)

## LOS AVISOS EMERGENTES (2-11-2026, M-284): logros, noticias y notificaciones del móvil se leen en cola, sin
## cortar lo que se esté leyendo. `ultimo_anuncio` queda aunque no haya voz (para las pruebas).
static var ultimo_anuncio := ""
static func anunciar(texto: String) -> void:
	if not activo() or texto.strip_edges() == "":
		return
	ultimo_anuncio = texto
	if _hay_voz():
		DisplayServer.tts_speak(texto, _voz, 50, 1.0, 1.1)

static func parar() -> void:
	_ultimo = ""
	if _hay_voz():
		DisplayServer.tts_stop()

## La voz del idioma del juego, o la primera que haya. "" = no hay síntesis de voz en este equipo.
static func _hay_voz() -> bool:
	if _voz != "":
		return true
	if DisplayServer.get_name() == "headless" or not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return false
	var voces := DisplayServer.tts_get_voices_for_language(Idiomas.idioma)
	if voces.is_empty():
		var todas := DisplayServer.tts_get_voices()
		if todas.is_empty():
			return false
		_voz = String((todas[0] as Dictionary).get("id", ""))
	else:
		_voz = String(voces[0])
	return _voz != ""
