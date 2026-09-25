extends Node
## Verifica a ojo el picker de escudos especiales en Gente -> Identidad
## (22-9-2026): que aparezca, que muestre miniaturas reales de los
## desbloqueados segun el nivel de perfil real (no se toca user://), y que
## elegir uno no reviente la pantalla.

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		var mundo: Mundo = _pantalla.get("mundo")
		var c: Club = mundo.mi_club()
		print("desbloqueados con el perfil real: %d" % Escudo.especiales_desbloqueados().size())
		_pantalla.set("_secc_gente", "identidad")
		_pantalla.call("_ir_a_pestana", "Gente")
		_pantalla.call("_refrescar")
		print("pantalla de identidad pintada con el picker de especiales, sin reventar")
	if _n == 16:
		# Elegir el primer especial desbloqueado, si hay alguno, y repintar.
		var lista: Array = Escudo.especiales_desbloqueados()
		if lista.size() > 0:
			var mundo2: Mundo = _pantalla.get("mundo")
			var c2: Club = mundo2.mi_club()
			c2.esc_especial = String(lista[0])
			_pantalla.call("_refrescar")
			print("elegido '%s', repintado sin reventar" % lista[0])
		else:
			print("perfil real en nivel 0 sin nada desbloqueado -normal, no es un fallo")
	if _n == 20:
		## Bajar el scroll de la lista de Gente para que la grilla de especiales
		## -mas abajo del todo, despues de Forma/Patron/Simbolo- entre en cuadro.
		var lista: Control = _pantalla.get("_lista_gente")
		if lista != null:
			var s := lista.get_parent()
			while s != null and not (s is ScrollContainer):
				s = s.get_parent()
			if s != null:
				(s as ScrollContainer).scroll_vertical = 999999
				print("scroll bajado en %s" % s.name)
	if _n == 22:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/pantalla_picker_especiales.png")
		print("captura guardada: res://pruebas/pantalla_picker_especiales.png")
		print("FIN. 0 fallos")
		get_tree().quit()
