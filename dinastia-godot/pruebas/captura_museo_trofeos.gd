extends Node
## MUSEO DEL CLUB CON LA COPA DE CADA COMPETICIÓN (orden 15 e, 27-10-2026). Construye solo la sala del
## museo (`SalasClub.museo`) y la fotografía con la cámara del paseo.
##   RECETAS=0  las copas de siempre (el «antes»)   SALIDA=nombre  (se guarda en /tmp/<nombre>.png)
## Sin pantalla no hace nada.
var _n := 0
var _raiz: Node3D
var _cam: Camera3D

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("sin pantalla no se captura nada")
		print("===== FIN. 0 fallos =====")
		get_tree().quit()
		return
	var ent := Environment.new()
	ent.background_mode = Environment.BG_COLOR
	ent.background_color = Color(0.16, 0.17, 0.2)
	ent.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ent.ambient_light_color = Color(0.85, 0.85, 0.9)
	ent.ambient_light_energy = 0.55
	var we := WorldEnvironment.new()
	we.environment = ent
	add_child(we)
	_raiz = Node3D.new()
	add_child(_raiz)
	var caja := Rect2(0.0, 0.0, 3.6, 6.0)
	Datos.usar_base_real(true)
	var hitos := [{"anio": 1999, "titulo": "Liga"}, {"anio": 2001, "titulo": "Copa Libertadores"}, {"anio": 2005, "titulo": "Copa Argentina"},
		{"anio": 2008, "titulo": "Mundial de Clubes"}, {"anio": 2010, "titulo": "Champi0ns Le4gue"}, {"anio": 2012, "titulo": "Copa Sudamericana"}]
	if OS.get_environment("RECETAS") == "0":
		hitos = []
	SalasClub.museo(_raiz, caja, 0.0, Color("#c01020"), Color("#f2f2f2"), 6, 4, hitos, "ARG")
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(8.0, 10.0)
	suelo.mesh = pm
	suelo.position = Vector3(1.8, -0.01, 3.0)
	_raiz.add_child(suelo)
	_cam = Camera3D.new()
	_cam.fov = 62.0
	_raiz.add_child(_cam)
	_cam.position = Vector3(1.8, 1.45, 5.9)
	_cam.look_at(Vector3(1.8, 1.25, 1.2), Vector3.UP)

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		var nombre := OS.get_environment("SALIDA") if OS.get_environment("SALIDA") != "" else "museo_trofeos"
		get_viewport().get_texture().get_image().save_png("/tmp/%s.png" % nombre)
		print("FOTO ", nombre)
		get_tree().quit()
