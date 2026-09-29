extends Node
## EL EDITOR DE ASPECTO DEL DT DESPUÉS DE SACARLO A `PanelAspectoDT` (25-9-2026).
##
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 \
##         res://pruebas/captura_aspecto_dt_panel.tscn
##
## Vive en CENTRAL → Mi Carrera. Pulsa los botones DE VERDAD (`pressed.emit()`), no solo mira que pinten:
## "Aleatorio" y un corte de pelo tienen que cambiar `Roles.look` y repintar.
## Deja una foto. Sale con código 1 si algo falla.

var _p: Node
var _n := 0
var _fallos := 0
var _look_antes: Dictionary = {}

func _comprobar(c: bool, que: String) -> void:
	print(("  ok    " if c else "  FALLO ") + que)
	if not c:
		_fallos += 1

func _boton(raiz: Node, texto: String) -> Button:
	for h in raiz.find_children("*", "Button", true, false):
		if (h as Button).text == texto and (h as Button).is_visible_in_tree():
			return h
	return null

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	match _n:
		10:
			_p.call("_ir_a_chip", {"tab": "Club", "secc": "carrera", "label": "Mi Carrera"})
		20:
			var lista: Node = _p.get("_lista_club")
			var azar := _boton(lista, "🎲 Aleatorio")
			_comprobar(azar != null, "el panel pinta el botón Aleatorio")
			_look_antes = (_p.get("mundo").roles.look as Dictionary).duplicate()
			if azar != null:
				azar.pressed.emit()
		30:
			var r: Roles = _p.get("mundo").roles
			_comprobar(r.look != _look_antes, "Aleatorio cambia el aspecto")
			var lista: Node = _p.get("_lista_club")
			var corte := _boton(lista, String(CaraDT.CORTES[3]))
			_comprobar(corte != null, "y pinta la rejilla de cortes")
			if corte != null:
				corte.pressed.emit()
		40:
			var r: Roles = _p.get("mundo").roles
			_comprobar(String(r.look.get("pelo", "")) == String(CaraDT.CORTES[3]), "elegir un corte lo guarda en Roles.look")
			var lista: Node = _p.get("_lista_club")
			var b := _boton(lista, String(CaraDT.CORTES[3]))
			_comprobar(b != null and b.button_pressed, "y tras repintar ese corte queda marcado")
			get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/aspecto_dt_panel.png")
			print("captura_aspecto_dt_panel: %d fallos" % _fallos)
			get_tree().quit(1 if _fallos > 0 else 0)
