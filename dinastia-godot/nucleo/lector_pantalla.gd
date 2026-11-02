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
	return ". ".join(partes)

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
