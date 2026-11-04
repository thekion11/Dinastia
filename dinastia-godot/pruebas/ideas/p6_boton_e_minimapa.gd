extends BaseIdea
## C3 + C4 (3-11, prueba del dueño): el minimapa solo dentro de un vehículo; el botón «E» solo junto a algo que se pueda usar (también en el móvil).

func _probar() -> void:
	_titulo("P6: MINIMAPA SOLO EN VEHICULO · BOTON E CONTEXTUAL")
	var e := ExploradorCiudad.new()
	add_child(e)
	e.cuerpo = CharacterBody3D.new() if e.cuerpo == null else e.cuerpo
	e._boton_e = Button.new()
	e._minimapa = MinimapaCiudad.new()
	add_child(e._boton_e)
	add_child(e._minimapa)
	e.estado = "calle"
	e.modo = "pie"
	e._aviso = Label.new()
	e._actualizar_mano("pie", 0.0, 0.0, 0.0)
	_comprobar(not e._minimapa.visible, "a pie no hay minimapa")
	_comprobar(not e._boton_e.visible, "sin nada cerca no hay botón E (aunque la pantalla sea táctil: %s)" % str(ExploradorCiudad.es_tactil()))
	e._aviso.text = "E: charlar"
	e._actualizar_mano("pie", 0.0, 0.0, 0.0)
	_comprobar(e._boton_e.visible, "junto a algo usable aparece el botón E")
	e.modo = "coche"
	e._actualizar_mano("coche", 0.0, 0.0, 0.0)
	_comprobar(e._minimapa.visible, "en coche sí hay minimapa")
