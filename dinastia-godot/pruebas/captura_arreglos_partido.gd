extends Node
## LOS ARREGLOS RÁPIDOS DEL PARTIDO CON MOTOR (17-10-2026, TOP 25 de
## ESTADO_MEJORAS: M-072, M-106, M-139, M-149, M-050, M-118), con la cámara de
## TV del partido real y de cerca:
##   1 tv        plano de transmisión (camiseta del árbitro)
##   2 tarjeta   el árbitro enseña la tarjeta (de cerca)
##   3 anadido   el cuarto árbitro con el cartel (TV) · 4 de cerca
##   5 red       la red ondulándose tras el gol (de cerca)
##   6 festejo   confeti y bengalas en la grada (TV)
##   7 var       la sala VAR con la línea de fuera de juego
## Salida: pruebas/capturas/arreglos_<n>_<nombre>[_antes].png (JPG con captura.sh).
##   RESOLUCION=1280x720 herramientas/captura.sh res://pruebas/captura_arreglos_partido.tscn
##   SUFIJO=_antes  (para la tanda «antes»)
var _n := 0
var _vista: VistaEstadio
var _fase := 0
var _espera := 0
var _fotos := 0
var _cam: Camera3D
var _t0 := 0.0

func _ready() -> void:
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.ALTO)
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", false)
	cfg.set_value(CajonAjustes.SECCION, "intro", false)
	cfg.save(CajonAjustes.RUTA)
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	Partido.ctx_club_id = m.mi_club_id
	var par := m.proximo_partido()
	var partido := Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], partido)

func _motor() -> MotorJugable:
	return _vista.get("_motor")

func _jugador(local: bool, codigo: String) -> Dictionary:
	for p: Dictionary in _motor().jugadores:
		if bool(p["es_local"]) == local and String(p.get("slot_code", "")) == codigo:
			return p
	for p: Dictionary in _motor().jugadores:
		if bool(p["es_local"]) == local and not bool(p["por"]):
			return p
	return {}

func _foto(nombre: String) -> void:
	_fotos += 1
	var ruta := "res://pruebas/capturas/arreglos_%d_%s%s.png" % [_fotos, nombre, OS.get_environment("SUFIJO")]
	get_viewport().get_texture().get_image().save_png(ruta)
	print("FOTO ", ruta)

## Cámara libre de cerca (la de TV vuelve con `_tv()`).
func _cerca(desde: Vector3, hacia: Vector3, fov := 40.0) -> void:
	if _cam == null:
		_cam = Camera3D.new()
		(_vista.get("_raiz3d") as Node3D).add_child(_cam)
	_cam.fov = fov
	_cam.global_position = desde
	_cam.look_at(hacia, Vector3.UP)
	_cam.make_current()

func _tv() -> void:
	var rig: CameraRig = _vista.get("_rig")
	if _cam != null:
		_cam.clear_current()
	var it := rig.camera_names.find("Transmisión")
	rig.switch_to(maxi(it, 0))

func _arbitro() -> Dictionary:
	for a: Dictionary in _motor().arbitros:
		if String(a.get("id", "")) == "arbitro":
			return a
	return {}

func _process(_d: float) -> void:
	_n += 1
	var motor := _motor()
	if motor == null:
		return
	if _espera > 0:
		_espera -= 1
		return
	match _fase:
		0:
			_espera = 40
			_fase = 1
		1:
			_tv()
			_espera = 3
			_fase = 2
		2:
			_foto("tv")
			## Falta con tarjeta segura cerca del árbitro.
			var arb := _arbitro()
			var a := _jugador(true, "DC")
			var d := _jugador(false, "DFC")
			var pa: Vector3 = (arb["node"] as Node3D).position + Vector3(2.5, 0, 3.0)
			(a["node"] as Node3D).position = pa
			(d["node"] as Node3D).position = pa + Vector3(0.8, 0, 0.6)
			motor.estado = "juego"
			_t0 = motor.get("_t_arb") if motor.get("_t_arb") != null else 0.0
			motor.call("_falta", d, a, 1.0)
			_espera = 1
			_fase = 3
		3:
			## Espera a que saque la tarjeta (≈2,4 s de gestos, con el reloj del árbitro).
			var t_arb: float = motor.get("_t_arb") if motor.get("_t_arb") != null else 99.0
			if t_arb - _t0 < 3.3 and _n < 900:
				## (El reloj del árbitro sigue aunque el motor esté en saque.)
				return
			var n: Node3D = _arbitro()["node"]
			var fwd := Vector3(sin(n.rotation.y), 0, cos(n.rotation.y))
			_cerca(n.global_position + fwd * 3.6 + Vector3(0, 1.7, 0) + fwd.cross(Vector3.UP) * 1.2, n.global_position + Vector3(0, 1.5, 0), 38.0)
			_espera = 2
			_fase = 4
		4:
			_foto("tarjeta")
			_tv()
			## Empieza el añadido: el reloj justo pasado el 45'.
			motor.estado = "juego"
			motor.saque = {}
			motor.t = motor.dur_mitad() + 0.2
			_espera = 14
			_fase = 5
		5:
			_foto("anadido_tv")
			_cerca(Vector3(29.0, 2.4, -3.2), Vector3(35.3, 1.8, 0.0), 34.0)
			_espera = 2
			_fase = 6
		6:
			_foto("anadido_cerca")
			_tv()
			## Gol del local: el balón entra por la escuadra del arco +Z.
			motor.t = 30.0
			motor.estado = "juego"
			motor.saque = {}
			motor.poseedor = {}
			var dc := _jugador(true, "DC")
			motor.ultimo_toque = dc
			motor.balon.position = Vector3(1.6, 1.4, 53.3)
			motor.vel_balon = Vector3.ZERO
			motor.call("_gol", true)
			## De lado: el abombado va hacia atrás y de frente apenas se nota.
			_cerca(Vector3(8.5, 1.5, 51.2), Vector3(0.0, 1.1, 54.0), 42.0)
			_fase = 7
		7:
			## Con el render por software cada fotograma dura medio segundo: se
			## congela la onda en su primer cuarto de segundo para la foto.
			## (Por ruta y no por clase: la tanda «antes» no tiene `RedArco`.)
			if ResourceLoader.exists("res://visor/red_arco.gd"):
				load("res://visor/red_arco.gd").golpe(_vista.get("_raiz3d"), motor.balon.global_position)
			for r in _vista.find_children("RedArco*", "", true, false):
				if r is Node and r.is_processing():
					r.set_process(false)
					for m in r.get("panos"):
						(m.material_override as ShaderMaterial).set_shader_parameter("edad", 0.22)
			_espera = 0
			_fase = 8
		8:
			_foto("red")
			_tv()
			_espera = 4
			_fase = 9
		9:
			_foto("festejo_tv")
			## Desde la grada del fondo, mirando al público.
			_cerca(Vector3(0.0, 9.0, 38.0), Vector3(0.0, 8.0, 70.0), 60.0)
			_espera = 1
			_fase = 10
		10:
			_foto("festejo_grada")
			_tv()
			if _vista.has_method("_a_la_revision_var"):
				motor.margen_gol = 0.34
				var lineas := {"linea": 36.0, "atacante": 36.34, "margen": 0.34}
				## (La versión vieja no tiene el parámetro de las líneas.)
				if _vista.get_method_argument_count("_a_la_revision_var") >= 5:
					_vista.call("_a_la_revision_var", 46, "Revisión del gol: posible fuera de juego", true, func() -> void: pass, lineas)
				else:
					_vista.call("_a_la_revision_var", 46, "Revisión del gol: posible fuera de juego", true, func() -> void: pass)
			_espera = 40
			_fase = 11
		11:
			_foto("var")
			var cfg := ConfigFile.new()
			cfg.load(CajonAjustes.RUTA)
			cfg.set_value(CajonAjustes.SECCION, "ceremonia", true)
			cfg.set_value(CajonAjustes.SECCION, "intro", true)
			cfg.save(CajonAjustes.RUTA)
			get_tree().quit()
	if _n > 2500:
		print("TIEMPO AGOTADO fase %d" % _fase)
		get_tree().quit()
