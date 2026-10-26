extends Node
## M-358: el contador de FPS se enciende, sobrevive a cambiar de pantalla (cuelga
## de la raíz), se guarda en las preferencias y «sin límite» (0) no se pierde.
##   godot --headless --path . res://pruebas/prueba_contador_fps.tscn
var _n := 0
var _p: Node
var _fallos := 0
func _ok(c: bool, t: String) -> void:
	print(("  ok    " if c else "  FALLO ") + t)
	_fallos += 0 if c else 1
func _tecla(k: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = k
	return e
func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		ContadorFps.poner(get_tree(), true)
		_p.set("_fps_elegido", 0)
		_p.call("_guardar_preferencias")
	if _n == 14:
		var c := get_tree().root.get_node_or_null("ContadorFps")
		_ok(c != null, "el contador cuelga de la raíz")
		_ok(c != null and String(c.call("texto")).contains("FPS"), "y enseña los FPS")
		_ok(c != null and c.get_node_or_null("DebugMenu") != null, "con el Debug Menu (MIT) dentro")
		_ok(InputMap.has_action("cycle_debug_menu") and not InputMap.action_has_event("cycle_debug_menu", _tecla(KEY_F3)), "su tecla no pisa F3 (táctica rápida)")
		var cf := ConfigFile.new()
		cf.load(Principal.PREFS)
		_ok(bool(cf.get_value("pantalla", "contador_fps", false)), "la preferencia queda guardada")
		_p.queue_free()
		_p = load("res://escenas/principal.tscn").instantiate()
		add_child(_p)
	if _n == 22:
		_ok(int(_p.get("_fps_elegido")) == 0, "«sin límite» sigue siendo sin límite al recargar (%d)" % int(_p.get("_fps_elegido")))
		_ok(get_tree().root.get_node_or_null("ContadorFps") != null, "el contador sigue tras rehacer la pantalla")
		ContadorFps.poner(get_tree(), false)
		_p.set("_fps_elegido", 60)
		_p.call("_guardar_preferencias")
		print("===== FIN CONTADOR FPS. %d fallos =====" % _fallos)
		get_tree().quit()
