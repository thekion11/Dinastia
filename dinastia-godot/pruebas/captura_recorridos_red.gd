extends Node
## LOS RECORRIDOS «RED» SOBRE EL MAPA (28-10-2026, orden 17 del dueño): un paradero de la ciudad con su cartel (nombre de la calle y la
## esquina, código y recorridos que paran ahí) a pie y con la cámara real, y el mapa del transporte en la vista de autobuses (N dos veces).
##   herramientas/captura.sh res://pruebas/captura_recorridos_red.tscn   → pruebas/capturas/recorridos_{paradero_N,cartel,mapa}.jpg
##   PARADERO=PA2005 elige otro paradero (por defecto, «Av. Los Pimientos / El Peumo»).
var _n := 0
var _p: Node
var _v: VistaCiudad
var _par: Dictionary = {}

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	var pedido := OS.get_environment("PARADERO")
	for cod: String in RecorridosMapa.datos()["orden"]:
		var q := RecorridosMapa.paradero(cod)
		if cod == pedido or (pedido == "" and String(q["nombre"]) == "Av. Los Pimientos / El Peumo"):
			_par = q
	print("paradero: ", _par.get("codigo", "-"), " · ", _par.get("nombre", "-"), " · ", _par.get("recorridos", []))

func _foto(n: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://pruebas/capturas"))
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/recorridos_%s.png" % n)

## A pie, `adelante` m en el sentido de la calle y `calle` m hacia la calzada desde el paradero, mirando al punto que queda
## `mira` m por delante de él (el poste del cartel está a 3,1 m en el sentido de la marcha).
func _mirar(adelante: float, calle: float, mira := 0.0) -> void:
	var e: ExploradorCiudad = _v.get("_explorador")
	var pos: Vector3 = _par["pos"]
	var dir: Vector2 = _par["dir"]
	var lado: Vector2 = _par["lado"]
	var q := Vector2(pos.x, pos.z) + dir * adelante - lado * calle
	e.cuerpo.position = Vector3(q.x, 0.2, q.y)
	var d := Vector2(pos.x, pos.z) + dir * mira - q
	e.rumbo = atan2(d.x, d.y)
	e.cuerpo.rotation.y = e.rumbo

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.set("_ciclo_activo", false)
		_v.set("_hora", 12.5)
		_v.call("_aplicar_hora")
	if _n == 24:
		_v.explorar("pie")
		_mirar(-6.0, 3.5)
	if _n == 44:
		_foto("paradero_0")
		_mirar(6.5, 3.2, 3.1)
	if _n == 60:
		_foto("paradero_1")
		## De cerca (no es la cámara del juego): el cartel del poste, para leerlo.
		for r: Node in get_tree().get_nodes_in_group("paradero_red"):
			if String(r.get_meta("codigo_red", "")) == String(_par["codigo"]) and r is Node3D:
				var cartel: Vector3 = (r as Node3D).global_transform * Vector3(-3.1, 2.05, 0.9)
				var frente: Vector3 = (r as Node3D).global_transform.basis.z.normalized()
				var cam := Camera3D.new()
				add_child(cam)
				cam.fov = 40.0
				cam.global_position = cartel + frente * 1.45 + Vector3(0, 0.05, 0)
				cam.look_at(cartel, Vector3.UP)
				cam.make_current()
	if _n == 70:
		_foto("cartel")
		var e: ExploradorCiudad = _v.get("_explorador")
		(e.camara as Camera3D).make_current()
		MapaTransporte.alternar(e)
		MapaTransporte.alternar(e)
	if _n == 82:
		_foto("mapa")
		get_tree().quit()
