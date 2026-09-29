extends Node3D
## LOS 12 ESTILOS DE EQUIPACIÓN, DE CERCA (25-9-2026).
##
##   godot --path . --rendering-driver vulkan --resolution 1600x900 \
##         res://pruebas/captura_equipaciones.tscn
##
## Doce jugadores en fila, uno por estilo de la tabla `KITS`, vestidos con
## `VestidorQ.vestir_equipacion()` -la equipación pintada sobre el cuerpo que
## sustituyó a la ropa medieval teñida-. Dos fotos: de frente y de espalda.
## Además comprueba que los doce se vistieron por el camino nuevo (si alguno
## cayera al respaldo de la ropa vieja, lo dice y sale con código 1).

const SALIDAS := ["res://pruebas/capturas/equipaciones_frente.png", "res://pruebas/capturas/equipaciones_espalda.png"]
const COLORES := [
	["#ffffff", "#111111"], ["#1f4fa0", "#f2c230"], ["#ffffff", "#d0202a"], ["#0b7a3b", "#ffffff"],
	["#d0202a", "#ffffff"], ["#111111", "#f2c230"], ["#6a1b9a", "#ffffff"], ["#d0202a", "#ffffff"],
	["#ffffff", "#0b4ea2"], ["#0b4ea2", "#111111"], ["#f2c230", "#0b4ea2"], ["#ffffff", "#d0202a"],
]
const PIELES := ["#f1c7a5", "#c68d68", "#8d5a3b", "#5b3a26"]

var _n := 0
var _cam: Camera3D
var _fallos := 0

func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.13, 0.32, 0.18)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.58, 0.62)
	e.ambient_light_energy = 0.8
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 30, 0)
	sol.light_energy = 1.3
	sol.shadow_enabled = true
	add_child(sol)
	_cam = Camera3D.new()
	_cam.position = Vector3(0, 1.15, 7.2)
	_cam.fov = 60
	add_child(_cam)

	var estilos: Array = Datos.tabla("KITS")
	for i in estilos.size():
		var d := FutbolistaQ.crear(1.80, "male")
		if d.is_empty():
			_fallos += 1
			continue
		var raiz: Node3D = d["nodo"]
		raiz.position = Vector3(-6.05 + i * 1.1, 0, 0)
		add_child(raiz)
		FutbolistaQ.terminar(d, true)
		var par: Array = COLORES[i % COLORES.size()]
		var ok := VestidorQ.vestir_equipacion(d, Color(par[0]), Color(par[1]), String(estilos[i]),
			Color(PIELES[i % PIELES.size()]), Color(0.15, 0.1, 0.07))
		if not ok:
			print("FALLO: el estilo %s no se vistió con la equipación pintada" % estilos[i])
			_fallos += 1
		var ap: AnimationPlayer = d["anim"]
		if ap.has_animation("parado"):
			ap.play("parado")
		var rotulo := Label3D.new()
		rotulo.text = String(estilos[i])
		rotulo.font_size = 36
		rotulo.pixel_size = 0.004
		rotulo.position = Vector3(raiz.position.x, 2.05, 0)
		add_child(rotulo)

func _process(_d: float) -> void:
	_n += 1
	if _n == 30:
		_guardar(0)
		for h in get_children():
			if h is Node3D and not (h is Camera3D) and not (h is Label3D) and not (h is DirectionalLight3D):
				(h as Node3D).rotation.y = PI
	elif _n == 45:
		_guardar(1)
		print("captura_equipaciones: %d fallos" % _fallos)
		get_tree().quit(1 if _fallos > 0 else 0)

func _guardar(i: int) -> void:
	get_viewport().get_texture().get_image().save_png(SALIDAS[i])
