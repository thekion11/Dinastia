extends Node
## LA GUÍA DEL MOVIMIENTO, A LA VISTA (11-11-2026, fase 4d; pedido del líder): partido con `MOTOR_LEAGUE=1` y la CÁMARA REAL del
## partido (Forward+). Hace fotos de una frenada, un giro, un arranque (con la guía en curso: `ls_guia`), de una carrera a toda
## velocidad y de la conducción del portador. Dos clubes de países distintos que se eligen con `PAR=0|1|2` (orden 34: nunca uno solo).
##   LS_GUIA=0|1 PAR=0 MOTOR_LEAGUE=1 CAPTURA_DIR=... herramientas/captura.sh res://pruebas/_sonda/captura_guia_league.tscn
## Salida: CAPTURA_DIR/guia<LS_GUIA>_par<PAR>_<evento>.jpg
const PARES := [["ARG", "ESP", 3, 5], ["BRA", "ITA", 2, 4], ["CHI", "ENG", 4, 1]]
var _n := 0
var _vista: VistaEstadio
var _hechas := {}
var _ult := -999
var _par := 0

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	_par = int(OS.get_environment("PAR")) % PARES.size()
	var d: Array = PARES[_par]
	var m := Mundo.new()
	m.generar([d[0], d[1]], 4712 + _par)
	var a: Club = m.ligas[0].clubes[int(d[2])]
	var b: Club = m.ligas[m.ligas.size() - 1].clubes[int(d[3])]
	m.mi_club_id = a.id
	Partido.ctx_club_id = a.id
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(a, 0.85, b, Partido.new(a, b))

func _process(_dt: float) -> void:
	_n += 1
	var intro: Variant = _vista.get("_intro")
	if intro != null and is_instance_valid(intro) and intro.activa:
		intro.terminar()
	var cer: Variant = _vista.get("_ceremonia")
	if cer != null and is_instance_valid(cer) and cer.activa:
		cer.terminar()
	var motor: MotorJugable = _vista.get("_motor")
	if motor == null:
		if _n > 60:
			print("SIN MOTOR")
			get_tree().quit()
		return
	if _n < 120:
		for i in 4:
			motor.paso(1.0 / 60.0)
		return
	if _n - _ult > 45:
		var ev := _evento(motor)
		if ev != "" and not _hechas.has(ev):
			_ult = _n
			_hechas[ev] = true
			var ruta := OS.get_environment("CAPTURA_DIR").path_join("guia%s_par%d_%s.jpg" % [OS.get_environment("LS_GUIA"), _par, ev])
			get_viewport().get_texture().get_image().save_jpg(ruta, 0.9)
			print("FOTO ", ruta)
	if _hechas.size() >= 5 or _n > 2400:
		print("FIN fotos=", _hechas.keys())
		get_tree().quit()

## Qué se ve ahora, si merece foto: algo en pantalla y dentro del encuadre de la cámara.
func _evento(motor: MotorJugable) -> String:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return ""
	for p: Dictionary in motor.jugadores:
		var nodo: Node3D = p.get("node")
		if not is_instance_valid(nodo) or not cam.is_position_in_frustum(nodo.global_position + Vector3(0, 1, 0)):
			continue
		if nodo.global_position.distance_to(cam.global_position) > 45.0:
			continue
		var sp := (p["vel"] as Vector3).length()
		var clip := String(p.get("anim_actual", ""))
		if clip.begins_with("ls_movement__") and not is_same(p, motor.poseedor):   ## el clip del original que se ve (vale con o sin guía)
			return "arranque" if clip.contains("accel") else ("frenada" if clip.contains("decel") else "giro")
		if is_same(p, motor.poseedor) and sp > 6.0:
			return "conduccion"
		if sp > 7.2 and not is_same(p, motor.poseedor):
			return "carrera"
	return ""
