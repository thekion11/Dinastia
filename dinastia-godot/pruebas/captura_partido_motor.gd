extends Node
## EL PARTIDO DEL DT CON EL MOTOR REAL (13-10-2026): se juega de verdad, con
## control de equipo y el panel de táctica y cambios. Salida:
## pruebas/capturas/motor_1..4.png
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_partido_motor.tscn
var _n := 0
var _vista: VistaEstadio
var _partido: Partido
var _fotos := 0

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	Partido.ctx_club_id = m.mi_club_id
	var par := m.proximo_partido()
	_partido = Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], _partido)

func _foto(nombre: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % nombre)
	print("FOTO %s minuto %d marcador %d-%d tiros %d-%d" % [nombre, _partido.minuto, _partido.goles_local, _partido.goles_visita, _partido.remates_local, _partido.remates_visita])

func _process(_d: float) -> void:
	_n += 1
	var intro: Variant = _vista.get("_intro")
	if intro != null and is_instance_valid(intro) and intro.activa:
		intro.terminar()
	var motor: MotorJugable = _vista.get("_motor")
	if motor == null:
		if _n > 40:
			print("SIN MOTOR")
			get_tree().quit()
		return
	## Para no esperar en tiempo real: unos pasos extra por fotograma.
	if _n < 200:
		for i in 6:
			motor.paso(1.0 / 60.0)
	if _n == 60:
		_foto("motor_1")
	if _n == 80:
		_vista.call("_alternar_control_motor")
	if _n == 95:
		_foto("motor_2")
	if _n == 110:
		_vista.call("_abrir_panel_dt")
	if _n == 116:
		_foto("motor_3")
		var p: Node = _vista.get("_panel_dt")
		if p != null:
			p.call("cerrar")
	if _n == 180:
		_foto("motor_4")
		print("ESTADO motor %s minuto %d · pases %s ok %s · tiros %s" % [motor.estado, motor.minuto(), str(motor.pases), str(motor.pases_ok), str(motor.tiros)])
		get_tree().quit()
