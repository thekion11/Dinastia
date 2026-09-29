extends Node
## "EL CLUB POR DENTRO" DESPUÉS DE SACARLO A `PanelClubDentro` (25-9-2026).
##
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 \
##         res://pruebas/captura_club_dentro_panel.tscn
##
## GENTE → El club por dentro. Pulsa los botones DE VERDAD: mejorar el
## vestuario tiene que cobrar y cambiarlo, y lanzar la app con un nombre tiene
## que dejarla lanzada. Deja una foto. Sale con código 1 si algo falla.

var _p: Node
var _n := 0
var _fallos := 0
var _caja := 0

func _comprobar(c: bool, que: String) -> void:
	print(("  ok    " if c else "  FALLO ") + que)
	if not c:
		_fallos += 1

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _fila_de(raiz: Node, texto: String) -> HBoxContainer:
	for h in raiz.find_children("*", "HBoxContainer", true, false):
		for l in (h as Node).get_children():
			if l is Label and (l as Label).text.strip_edges() == texto:
				return h
	return null

func _process(_d: float) -> void:
	_n += 1
	var mundo: Mundo = _p.get("mundo") if _n > 1 else null
	match _n:
		10:
			_p.call("_ir_a_chip", {"tab": "Gente", "secc": "interno", "label": "El club por dentro"})
		20:
			var raiz: Node = _p.get("_lista_gente")
			var opcion: Array = ClubDentro.VESTUARIO[1]
			var fila := _fila_de(raiz, String(opcion[1]))
			_comprobar(fila != null, "pinta la fila del vestuario «%s»" % opcion[1])
			_caja = mundo.mi_club().saldo
			if fila != null:
				(fila.get_child(fila.get_child_count() - 1) as Button).pressed.emit()
		30:
			var opcion: Array = ClubDentro.VESTUARIO[1]
			_comprobar(mundo.club_dentro.vestuario == String(opcion[0]), "mejorar el vestuario lo cambia de verdad")
			_comprobar(mundo.mi_club().saldo < _caja, "y cobra la obra")
			var raiz: Node = _p.get("_lista_gente")
			var campos := raiz.find_children("*", "LineEdit", true, false)
			_comprobar(not campos.is_empty(), "pinta el campo para lanzar la app")
			if not campos.is_empty():
				var campo: LineEdit = campos[0]
				campo.text = "App de prueba"
				for h in campo.get_parent().get_children():
					if h is Button:
						(h as Button).pressed.emit()
		40:
			_comprobar(not (mundo.club_dentro.app as Dictionary).is_empty(), "lanzar la app la deja lanzada")
			get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/club_dentro_panel.png")
			print("captura_club_dentro_panel: %d fallos" % _fallos)
			get_tree().quit(1 if _fallos > 0 else 0)
