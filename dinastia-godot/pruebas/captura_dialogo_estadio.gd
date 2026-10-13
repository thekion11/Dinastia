extends Node
## Diálogo con alguien del club dentro del estadio (13-10-2026): estilo del
## cuadro, cara y encuadre. Salida: pruebas/capturas/dialogo_estadio.png
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_dialogo_estadio.tscn
var _vista: VistaEstadio
var _ex: ExploradorEstadio
var _n := 0
var _m: Mundo

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	var club: Club = m.ligas[0].clubes[0]
	m.mi_club_id = club.id
	EdificioClub.mundo_ref = weakref(m)
	_m = m
	var ep := EstadioPropio.new()
	PersonajeDT.club_usuario = club.id
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(club, 0.85, null, null, ep.perfil(club))

func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		_vista.recorrer()
		_ex = _vista._explorador
	if _n == 30:
		var pe := get_tree().get_first_node_in_group("personal_club") as PersonalEstadio
		print("personal: ", pe.gente.size() if pe != null else -1)
		if pe != null and not pe.gente.is_empty():
			var g: Dictionary = pe.gente[0]
			var buscado := OS.get_environment("QUIEN") if OS.get_environment("QUIEN") != "" else ""
			for x: Dictionary in pe.gente:
				if (buscado != "" and String(x["clave"]) == buscado) or (buscado == "" and int(x.get("planta", 0)) == _ex.planta):
					g = x
					break
			if int(g.get("planta", 0)) != _ex.planta:
				_ex.ir_a_planta(int(g["planta"]))
			var n: Node3D = g["nodo"]
			var frente := n.global_transform.basis.z.normalized()
			_ex.cuerpo.global_position = n.global_position + frente * 1.4
			_ex.rumbo = atan2(-frente.x, -frente.z)
			_ex.cuerpo.rotation.y = _ex.rumbo
			_ex._colocar_camara(1.0)
			print("hablo con: ", g.get("nombre", "?"), " · ", g.get("puesto", "?"))
			_ex.usar()
	if _n > 30 and _n < 60 and _ex != null:
		_ex._colocar_camara(1.0 / 30.0)
	if _n == 44 and OS.get_environment("QUIEN") != "":
		for b in get_tree().root.find_children("*", "Button", true, false):
			if (b as Button).text.begins_with("❓"):
				(b as Button).pressed.emit()
	if _n == 60:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/dialogo_estadio.png")
		get_tree().quit()
