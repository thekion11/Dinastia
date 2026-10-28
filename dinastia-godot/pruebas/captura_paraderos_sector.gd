extends Node
## Un paradero de cada sector, a la altura de una persona, desde sus dos lados (+Z y −Z locales) para ver la orientación respecto a la calle.
##   → /tmp/parad_<sector>_<lado>.png y una línea por paradero con su posición y giro.
var _n := 0
var _vista: VistaCiudad
var _mundo: Mundo
var _lista: Array = []
var _k := 0
var _fase := 0

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4713)
	_mundo.tomar_el_mando(_mundo.ligas[0].clubes[0].id)
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.abrir(_mundo.mi_club(), _mundo.obras, _mundo.ciudad, _mundo.perfil_estadio_de(_mundo.mi_club()))
	_vista.set("_girando", false)

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		_vista.set_process(false)
		var visto := {}
		for n: Node3D in get_tree().get_nodes_in_group("paradero_red"):
			var sec := RecorridosRed.sector_de(n.global_position)
			if not visto.has(sec) and sec <= 500:
				visto[sec] = true
				_lista.append([sec, n])
		_lista.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
		print("paraderos a fotografiar: ", _lista.size())
	if _n < 12 or _k >= _lista.size():
		if _k >= _lista.size() and _n > 12:
			get_tree().quit()
		return
	var sec: int = _lista[_k][0]
	var n: Node3D = _lista[_k][1]
	var cam: Camera3D = _vista.get("_camara")
	var lado := 1.0 if _fase < 4 else -1.0
	if _fase == 0 or _fase == 4:
		cam.global_position = n.global_position + n.global_transform.basis.z.normalized() * 7.0 * lado + Vector3(0, 1.7, 0)
		cam.look_at(n.global_position + Vector3(0, 1.8, 0), Vector3.UP)
		cam.fov = 55.0
		print("sector ", sec, " paradero ", n.get_meta("codigo_red", "?"), " en ", n.global_position, " giro ", rad_to_deg(n.global_rotation.y))
	_fase += 1
	if _fase == 4 or _fase == 8:
		get_viewport().get_texture().get_image().save_png("/tmp/parad_%d_%s.png" % [sec, "mas" if lado > 0 else "menos"])
	if _fase == 8:
		_fase = 0
		_k += 1
