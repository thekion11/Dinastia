extends Control
## Las instalaciones por dentro, una foto de cada sala.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_interiores.tscn
const CLAVES_BASE := ["ciudad_ayuntamiento", "ciudad_hospital", "ciudad_comisaria", "ciudad_bomberos", "ciudad_escuela",
	"ciudad_estacion_central", "ciudad_mercado", "ciudad_cine", "ciudad_centro_comercial", "gim", "video", "cocina", "pren", "museo", "piscina",
	"com", "edificio_vivienda", "edificio_bar", "edificio_panaderia", "edificio_peluqueria", "edificio_libreria", "edificio_taller",
	"edificio_oficina", "edificio_tienda|Farmacia", "edificio_mercado"]
## SALAS="clave1,clave2" para fotografiar solo esas; PREFIJO="antes_" para no pisar fotos.
var CLAVES: Array = Array(OS.get_environment("SALAS").split(",")) if OS.get_environment("SALAS") != "" else CLAVES_BASE
var PREFIJO := OS.get_environment("PREFIJO")
var _i := -1
var _t := 0.0
var _int: Control
var _cam_fija: Array = []

func _ready() -> void:
	process_priority = 100   ## después de la sala: la cámara fija manda
	position = Vector2.ZERO
	size = get_viewport().get_visible_rect().size

func _process(d: float) -> void:
	_t += d
	if not _cam_fija.is_empty() and _int != null:
		var cam: Camera3D = _int.get("_cam")
		cam.position = _cam_fija[0]
		cam.look_at(_cam_fija[1], Vector3.UP)
	if _int == null or _t > 2.0:
		if _int != null:
			get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/interior_%s%s.png" % [PREFIJO, String(CLAVES[_i]).get_slice("|", 0)])
			print("FOTO %s · %d triángulos · %d llamadas · %d nodos" % [CLAVES[_i],
				RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
				RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
				_int.find_children("*", "", true, false).size()])
			_int.queue_free()
			_int = null
		_i += 1
		if _i >= CLAVES.size():
			get_tree().quit()
			return
		var club: Club = null
		if CLAVES[_i] == "com":
			club = Club.new()
			club.color1 = "#c8102e"
			club.color2 = "#ffffff"
		_int = InteriorInstalacion.abrir(self, CLAVES[_i], club)
		_t = 0.0
		## CAM="x,y,z,ox,oy,oz": cámara fija (primer plano) en vez de la que gira.
		if OS.get_environment("CAM") != "":
			var v := OS.get_environment("CAM").split_floats(",")
			_int.set("_girando", false)
			_cam_fija = [Vector3(v[0], v[1], v[2]), Vector3(v[3], v[4], v[5])]
