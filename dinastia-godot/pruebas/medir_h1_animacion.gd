extends Node
## H1 · ANIMACIÓN (16-11): el COSTE del pie y la cabeza al balón (`AnimacionCercana`) en un partido corto, sin pantalla, con el
## estadio y la cámara real del partido. Mide el tiempo de proceso por fotograma (`Performance.TIME_PROCESS`, incluye los
## modificadores de esqueleto) y el del propio `AnimacionCercana.actualizar`, y cuenta los giros del cuerpo por fotograma
## (para ver si hace falta «warping» de giros en la vista). Dos clubes de países distintos (PAIS=ARG,ESP).
##   H1_IK=0|1 CALIDAD=2 PAIS=MEX,ITA godot --headless --path . res://pruebas/medir_h1_animacion.tscn
const FOTOGRAMAS := 900
var _n := 0
var _vista: VistaEstadio
var _t_proc := 0.0
var _medidos := 0
var _yaw: Dictionary = {}
var _giros := [0, 0, 0, 0]   ## fotogramas·jugador con |Δgiro| > 5°, 10°, 20° y 45°
var _muestras := 0
var _desvio := 0.0           ## media de |giro del cuerpo − dirección de la marcha| con velocidad > 3 m/s (grados)
var _con_vel := 0
var _pie_n := 0
var _d_cam := 0.0
var _cerca_balon := 0   ## fotogramas con alguien a menos de 1,05 m (horizontal) del balón y el balón bajo
var _pie_fuera := 0
var _pie_antes := 0.0
var _pie_despues := 0.0

func _ready() -> void:
	Calidad.elegida = int(OS.get_environment("CALIDAD")) if OS.get_environment("CALIDAD") != "" else Calidad.ALTA
	if OS.get_environment("H1_IK") == "0":
		AnimacionCercana.encendida = false
	var paises: Array[String] = []
	for q in (OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "MEX,ITA").split(",", false):
		paises.append(String(q))
	var m := Mundo.new()
	m.generar(paises, 4711)
	var a: Club = null
	var b: Club = null
	for liga: Liga in m.ligas:
		if int(liga.div) == 1:
			if liga.pais == paises[0] and a == null:
				a = liga.clubes[1]
			elif liga.pais == paises[paises.size() - 1] and b == null:
				b = liga.clubes[3]
	m.mi_club_id = a.id
	Partido.ctx_club_id = m.mi_club_id
	var partido := Partido.new(a, b)
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(a, 0.85, b, partido)

func _process(_d: float) -> void:
	_n += 1
	var intro: Variant = _vista.get("_intro")
	if intro != null and is_instance_valid(intro) and intro.activa:
		intro.terminar()
	var motor: MotorJugable = _vista.get("_motor")
	if motor == null:
		if _n > 60:
			print("SIN MOTOR")
			get_tree().quit()
		return
	var cer: Variant = _vista.get("_ceremonia")
	if cer != null and is_instance_valid(cer) and cer.activa:
		cer.terminar()
	motor.paso(1.0 / 60.0)
	if _n > 120:
		_t_proc += Performance.get_monitor(Performance.TIME_PROCESS)
		_medidos += 1
		_medir_balon_camara(motor)
		_medir_jugadores(motor)
	if _n >= 120 + FOTOGRAMAS:
		_informe_h1(motor)
		get_tree().quit()


## Balón: cuántas veces está pegado a alguien y a cuánto va la cámara.
func _medir_balon_camara(motor: MotorJugable) -> void:
	var bp := motor.balon.global_position
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		_d_cam += cam.global_position.distance_to(bp)
	for p: Dictionary in motor.jugadores:
		var gq := (p["node"] as Node3D).global_position
		if bp.y < 0.45 and Vector2(gq.x - bp.x, gq.z - bp.z).length() < 1.05:
			_cerca_balon += 1
			break


## Giros de cada jugador, pie con IK y desvío cuerpo-marcha.
func _medir_jugadores(motor: MotorJugable) -> void:
	for p: Dictionary in motor.jugadores:
		var nodo: Node3D = p["node"]
		var k := nodo.get_instance_id()
		if _yaw.has(k):
			var dg := absf(rad_to_deg(angle_difference(float(_yaw[k]), nodo.rotation.y)))
			for i in 4:
				if dg > [5.0, 10.0, 20.0, 45.0][i]:
					_giros[i] += 1
			_muestras += 1
		_yaw[k] = nodo.rotation.y
		_medir_pie(nodo)
		var v: Vector3 = p.get("vel", Vector3.ZERO)
		if Vector2(v.x, v.z).length() > 3.0:
			_desvio += absf(rad_to_deg(angle_difference(nodo.rotation.y, atan2(v.x, v.z))))
			_con_vel += 1


## El pie con IK activo: cuánto se corrige el tobillo respecto al clip (o si queda fuera de alcance).
func _medir_pie(nodo: Node3D) -> void:
	var esq := FutbolistaQ.esqueleto_de(nodo)
	var pie: PieBalonIK = esq.get_node_or_null("PieBalonIK") if esq != null else null
	if pie != null and pie.active and pie.peso > 0.3:
		if pie.medida.y < 0.0:
			_pie_fuera += 1
		else:
			_pie_n += 1
			_pie_antes += pie.medida.x
			_pie_despues += pie.medida.y


## El informe final: rendimiento, giros, balón, pie y la huella de posiciones (para comparar versiones).
func _informe_h1(motor: MotorJugable) -> void:
	var ac: AnimacionCercana = motor.get_node_or_null("AnimacionCercana")
	print("H1 ik=%s calidad=%d proceso_ms=%.3f ac_us=%.1f fotogramas=%d" % [
		OS.get_environment("H1_IK"), Calidad.elegida, _t_proc / maxf(_medidos, 1) * 1000.0,
		float(ac.us_total) / maxf(ac.llamadas, 1) if ac != null else 0.0, _medidos])
	print("GIROS por fotograma·jugador (%d): >5° %.2f %%, >10° %.2f %%, >20° %.3f %%, >45° %.3f %%; desvío cuerpo-marcha a >3 m/s: %.1f°" % [
		_muestras, 100.0 * _giros[0] / maxf(_muestras, 1), 100.0 * _giros[1] / maxf(_muestras, 1), 100.0 * _giros[2] / maxf(_muestras, 1),
		100.0 * _giros[3] / maxf(_muestras, 1), _desvio / maxf(_con_vel, 1)])
	print("BALON pegado a alguien en %d de %d fotogramas; cámara a %.1f m del balón de media" % [_cerca_balon, _medidos, _d_cam / maxf(_medidos, 1)])
	print("PIE activo %d fotogramas (+%d fuera de alcance): tobillo-objetivo %.3f m del clip → %.3f m con el IK" % [
		_pie_n, _pie_fuera, _pie_antes / maxf(_pie_n, 1), _pie_despues / maxf(_pie_n, 1)])
	var h := PackedStringArray()
	for p: Dictionary in motor.jugadores:
		var q := (p["node"] as Node3D).position
		h.append("%.3f,%.3f,%.3f" % [q.x, q.z, (p["node"] as Node3D).rotation.y])
	print("HUELLA ", hash("|".join(h)), " balon ", motor.balon.position, " estado ", motor.estado)

