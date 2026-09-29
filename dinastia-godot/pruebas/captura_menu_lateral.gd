extends Node
## EL PANEL LATERAL Y LOS MENÚS A PANTALLA COMPLETA (29-9-2026, mapa de metas 23).
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_menu_lateral.tscn
var _n := 0
var _p: Node
const FOTOS := [[30, "", "menu_lateral_riel"], [60, "*", "menu_lateral_abierto"], [100, "historia", "menu_historia"],
	[140, "gente", "menu_gente"], [180, "operaciones", "menu_operaciones"], [220, "vida", "menu_vida"],
	[260, "ajustes", "menu_ajustes"], [300, "estadio", "menu_estadio"], [340, "ciudad", "menu_ciudad"],
	[380, "carrera", "menu_carrera"], [420, "editar", "menu_editar"]]
func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
func _process(_d: float) -> void:
	_n += 1
	var ml: MenuLateral = _p.get("_menu_lateral")
	for f: Array in FOTOS:
		if _n == int(f[0]) - 22:
			if String(f[1]) == "*":
				ml.desplegar()
			elif String(f[1]) != "":
				ml.abrir_menu(String(f[1]), -1)
		if _n == int(f[0]):
			get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % String(f[2]))
	if _n == 423:
		ml.abrir_menu("historia", 1)
	if _n == 440:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/menu_historia_detalle.png")
	if _n == 441:
		ml.desplegar()
	if _n == 444:
		var esc := InputEventAction.new()
		esc.action = "ui_cancel"
		esc.pressed = true
		Input.parse_input_event(esc)
	if _n == 448:
		print("ESC pliega el cajón: %s; menú sigue abierto: %s" % [not ml.abierto(), is_instance_valid(ml.pantalla_abierta)])
	if _n == 449:
		if is_instance_valid(ml.pantalla_abierta):
			ml.pantalla_abierta.cerrar()
	if _n == 470:
		var tabs: TabContainer = _p.get("_pestanas")
		print("VUELTA: pestanas dentro de principal = %s, pestaña %s" % [_p.is_ancestor_of(tabs), tabs.get_tab_title(tabs.current_tab)])
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/menu_vuelta.png")
		get_tree().quit()
