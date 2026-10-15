extends Node
## ¿Se dibujan las capas de césped en el partido real? Imprime calidad, nodo,
## visibilidad y distancia de la cámara de transmisión al suelo.
var _vista: VistaEstadio
var _n := 0
func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	Partido.ctx_club_id = m.mi_club_id
	var par := m.proximo_partido()
	var partido := Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], partido)
func _process(_d: float) -> void:
	_n += 1
	if _n == 90:
		var c := _vista.find_child("CespedCapas", true, false)
		var cam := get_viewport().get_camera_3d()
		print("CALIDAD ", Calidad.elegida, " ligero ", Calidad.motor_ligero, " capas_por_calidad ", CespedCapas.capas_por_calidad())
		print("NODO ", c, " visible ", c.visible if c else "-", " parent_transform_identidad ", (c.get_parent() as Node3D).global_transform.is_equal_approx(Transform3D.IDENTITY) if c else "-")
		print("CAMARA ", cam.global_position if cam else "-", " fov ", cam.fov if cam else 0)
		get_tree().quit()
