extends Node
## TANDA C EN PANTALLA (26-9-2026): la ficha con pie, pierna débil y premios, y
## la lista de instalaciones con su encargado.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_tanda_c.tscn
var _n := 0
var _p: Node

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _bajar_a(contenedor: Control, texto: String) -> void:
	var sc := contenedor.get_parent()
	while sc != null and not (sc is ScrollContainer):
		sc = sc.get_parent()
	for l in contenedor.find_children("*", "Label", true, false):
		if (l as Label).text.contains(texto) and sc != null:
			(sc as ScrollContainer).scroll_vertical = int((l as Label).global_position.y - contenedor.global_position.y) - 10
			return

func _process(_d: float) -> void:
	_n += 1
	var m: Mundo = _p.get("mundo") if _n >= 10 else null
	if _n == 10:
		var j: Jugador = m.mi_club().plantilla[3]
		j.premios = [{"anio": 2026, "premio": "Equipo ideal de la temporada"}, {"anio": 2027, "premio": "Máximo goleador (19 goles)"}]
		_p.call("_ver_ficha", j)
	if _n == 13:
		_bajar_a(_p.get("_ficha"), "PERFIL")
	if _n == 22:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/ficha_premios.png")
		for k in ["ct", "cocina", "piscina", "med", "gim"]:
			m.obras.niveles[k] = 6 if k == "ct" else 2
		_p.call("_ir_a_chip", {"tab": "Club", "secc": "infra", "label": "Infraestructura"})
		_p.call("_refrescar")
	if _n == 30:
		_bajar_a(_p.get("_lista_club"), "Comedor")
	if _n == 38:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/instalaciones_trabajadores.png")
		get_tree().quit()
