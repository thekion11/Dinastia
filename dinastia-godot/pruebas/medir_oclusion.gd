extends Node
## ¿Cuánto ahorra la oclusión de la ciudad? (21-10-2026). A pie en varias
## calles, cuenta llamadas de dibujo y objetos con las paredes de oclusión
## encendidas y apagadas.
##   xvfb-run -a godot --path . --rendering-driver vulkan res://pruebas/medir_oclusion.tscn
var _n := 0
var _p: Node
var _v: VistaCiudad
var _e: ExploradorCiudad
const SITIOS := [Vector3(1005.0, 0, -500.0), Vector3(345.0, 0, -658.0), Vector3(-224.0, 0, -880.0), Vector3(120.0, 0, 1150.0)]
const RUMBOS := [PI, 2.356, 1.571, -1.571]
var _datos := []

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.set("_ciclo_activo", false)
		_v.set("_hora", 11.0)
		_v.call("_aplicar_hora")
		_v.explorar("pie")
		_e = _v.get("_explorador")
		print("PAREDES DE OCLUSION: ", OclusoresCiudad.cuantas(_e.cb))
	if _n < 10 or _e == null:
		return
	## Cada sitio: 12 fotogramas con oclusión y 12 sin ella.
	var k := (_n - 10) / 24
	var f := (_n - 10) % 24
	if k >= SITIOS.size():
		var con := 0
		var sin := 0
		for d: Array in _datos:
			con += int(d[0])
			sin += int(d[1])
		print("TOTAL llamadas con oclusión %d · sin %d · ahorro %.0f %%" % [con, sin, 100.0 * (1.0 - float(con) / maxf(sin, 1.0))])
		get_tree().quit()
		return
	if f == 0:
		_e.cuerpo.position = SITIOS[k]
		_e.cuerpo.position.y = _e.altura_suelo(SITIOS[k].x, SITIOS[k].z)
		_e.set("rumbo", RUMBOS[k])
		_e.cuerpo.rotation.y = RUMBOS[k]
		_e.call("_colocar_camara", 1.0)
		_datos.append([0, 0])
	## Lo enciende el explorador en cada fotograma: se fuerza después de él.
	OclusoresCiudad.activar(_e.cb, f < 12)
	var llamadas := int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	if f == 10:
		_datos[k][0] = llamadas
	if f == 22:
		_datos[k][1] = llamadas
		print("sitio %d: con oclusión %d llamadas · sin %d" % [k, _datos[k][0], _datos[k][1]])
