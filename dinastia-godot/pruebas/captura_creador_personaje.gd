extends Control
## EL CREADOR DE PERSONAJE (26-9-2026): pantalla completa con cada pestaña.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_creador_personaje.tscn
var _n := 0
var _c: CreadorPersonaje

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	m.roles.look["p3d"] = {"ropa": "traje", "gafas": "ver", "barba": true, "complexion": 0.3}
	(func() -> void: _c = CreadorPersonaje.abrir(self, m)).call_deferred()

func _process(_d: float) -> void:
	if _c == null:
		return
	_n += 1
	var tabs := [8, 14, 20, 26, 32]
	var k := tabs.find(_n)
	if k >= 0:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/creador_personaje_%d.png" % k)
		var pest: TabContainer = _c.get("_pestanas")
		if k + 1 < pest.get_tab_count():
			pest.current_tab = k + 1
	if _n == 34:
		get_tree().quit()
