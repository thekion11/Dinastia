extends Node
## Giros del original en el PARTIDO (fase 4c, 10-11): MOTOR_LEAGUE=1; cuando un jugador empieza un giro fuerte del original
## (90°/135°/180°), una cámara de costado lo sigue y se juntan 5 instantes del clip en una tira. Dos clubes de países distintos
## (orden 34). Salida: CAPTURA_DIR/league_giro_N.jpg
##   MOTOR_LEAGUE=1 herramientas/captura.sh res://pruebas/_sonda/captura_giro_league.tscn
const CUADROS := [0, 5, 10, 15, 22]
var _n := 0
var _vista: VistaEstadio
var _cam: Camera3D
var _sigue: Dictionary = {}
var _desde := 0
var _tira: Image
var _tiras := 0

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	var m := Mundo.new()
	m.generar(["BRA", "ITA"], 9031)
	var a: Club = m.ligas[0].clubes[2]
	var b: Club = m.ligas[m.ligas.size() - 1].clubes[6]
	m.mi_club_id = a.id
	Partido.ctx_club_id = a.id
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(a, 0.85, b, Partido.new(a, b))

func _process(_d: float) -> void:
	_n += 1
	var intro: Variant = _vista.get("_intro")
	if intro != null and is_instance_valid(intro) and intro.activa:
		intro.terminar()
	var cer: Variant = _vista.get("_ceremonia")
	if cer != null and is_instance_valid(cer) and cer.activa:
		cer.terminar()
	var motor = _vista.get("_motor")
	if motor == null or _n < 150:
		return
	if _sigue.is_empty():
		for p: Dictionary in motor.jugadores:
			var an := String(p.get("anim_actual", ""))
			if float(p.get("ls_trans_hasta", 0.0)) > motor.t and (an.contains("_090") or an.contains("_135") or an.contains("_180")):
				_sigue = p
				_desde = _n
				_tira = Image.create(1280, 720, false, Image.FORMAT_RGB8)
				print("GIRO ", an, " jugador ", p.get("id"))
				break
		if _sigue.is_empty():
			return
	var n: Node3D = _sigue["node"]
	if _cam == null:
		_cam = Camera3D.new()
		_cam.fov = 30
		n.get_parent().add_child(_cam)
	var yaw := float(_sigue.get("ls_yaw0", n.rotation.y))
	var lado := Vector3(cos(yaw), 0, -sin(yaw))
	_cam.position = n.position + lado * 7.0 + Vector3(0, 1.4, 0)
	_cam.look_at(n.position + Vector3(0, 0.9, 0))
	_cam.make_current()
	var k := _n - _desde
	var i := CUADROS.find(k)
	if i >= 0:
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.convert(Image.FORMAT_RGB8)
		var w := img.get_width() / 5
		_tira.blit_rect(img, Rect2i(img.get_width() / 2 - w / 2, 0, w, img.get_height()), Vector2i(i * (1280 / 5), 0))
		print("  cuadro ", k, " anim ", _sigue.get("anim_actual"), " yaw nodo ", snappedf(n.rotation.y, 0.01), " off ", snappedf(float(_sigue.get("ls_off", 0.0)), 0.01))
	if k > CUADROS[-1]:
		_tiras += 1
		_tira.save_jpg(OS.get_environment("CAPTURA_DIR").path_join("league_giro_%d.jpg" % _tiras), 0.9)
		_sigue = {}
		_n = 150 - 90 * _tiras   ## espera un poco antes del siguiente
		if _tiras >= 3:
			print("FIN")
			get_tree().quit()
	if _n > 4000:
		get_tree().quit()
