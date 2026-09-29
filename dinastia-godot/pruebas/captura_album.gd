extends Node
## EL ÁLBUM DE CROMOS (28-9-2026): se abre un sobre con la partida en marcha.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_album.tscn
var _n := 0
var _p: Node
var _pop: Control
func _ready() -> void:
	Meta.ruta = "user://meta_captura.json"
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		var m: Mundo = _p.get("mundo")
		var d := Meta.leer()
		d["sobres"] = 4
		Meta.guardar(d)
		for _i in 3:
			Meta.abrir_sobre(m)
		m.roles.sumar_trofeo("Primera División")
		_pop = PanelMeta.abrir(_p, m)
	if _n == 14:
		for b in _pop.find_children("*", "Button", true, false):
			if (b as Button).text.begins_with("🎁"):
				(b as Button).pressed.emit()
	if _n == 60:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/album.png")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.ruta))
		get_tree().quit()
