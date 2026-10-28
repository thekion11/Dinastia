extends Node
## Semáforo peatonal con botón (M-170): el poste con su hombrecito en rojo, en verde y el botón. → /tmp/semped_<n>.png
var _n := 0
var _vista: VistaCiudad
var _sem: Semaforos

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 4713)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.abrir(m.mi_club(), m.obras, m.ciudad, m.perfil_estadio_de(m.mi_club()))
	_vista.set("_girando", false)

func _process(_d: float) -> void:
	_n += 1
	var cb := _vista.get("_ciudad") as CityBuilder
	if _n == 10:
		_vista.set_process(false)
		_sem = cb.expansion.semaforos
		_sem.process_mode = Node.PROCESS_MODE_DISABLED
		print("botones: ", _sem.botones.size())
	if _sem == null or _n < 12:
		return
	var b: Vector3 = _sem.botones[2]
	var cam: Camera3D = _vista.get("_camara")
	var i := (_n - 12) / 6
	if i >= 3:
		get_tree().quit()
		return
	if (_n - 12) % 6 == 0:
		_sem.t = [1.0, Semaforos.VERDE - 1.0, Semaforos.VERDE + 5.0][i]
		_sem._aplicar()
		var hacia := Vector3(b.x, 0, b.z).normalized()
		cam.global_position = b + Vector3(-5.0, 0.6, 7.5)
		cam.look_at(b + Vector3(0, 1.2, 0), Vector3.UP)
		cam.fov = 55.0
	if (_n - 12) % 6 == 4:
		get_viewport().get_texture().get_image().save_png("/tmp/semped_%d.png" % i)
