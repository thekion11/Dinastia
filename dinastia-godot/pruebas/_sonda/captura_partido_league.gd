extends Node
## Partido con MOTOR_LEAGUE=1 y la CÁMARA REAL (fase 4c, 10-11): fotos cuando el portador conduce, para revisar los ciclos
## «conducir_ls» / «conducir_ls_rapido». Dos clubes de países distintos (orden 34). Salida: CAPTURA_DIR/league_partido_N.jpg
##   MOTOR_LEAGUE=1 herramientas/captura.sh res://pruebas/_sonda/captura_partido_league.tscn
var _n := 0
var _vista: VistaEstadio
var _fotos := 0
var _ultima := -999

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	var m := Mundo.new()
	m.generar(["ARG", "ESP"], 4712)
	var a: Club = m.ligas[0].clubes[3]
	var b: Club = m.ligas[m.ligas.size() - 1].clubes[5]
	m.mi_club_id = a.id
	Partido.ctx_club_id = a.id
	var partido := Partido.new(a, b)
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(a, 0.85, b, partido)

func _process(_d: float) -> void:
	_n += 1
	var intro: Variant = _vista.get("_intro")
	if intro != null and is_instance_valid(intro) and intro.activa:
		intro.terminar()
	var cer: Variant = _vista.get("_ceremonia")
	if cer != null and is_instance_valid(cer) and cer.activa:
		cer.terminar()
	var motor: MotorJugable = _vista.get("_motor")
	if motor == null:
		if _n > 40:
			print("SIN MOTOR")
			get_tree().quit()
		return
	if _n == 41:
		print("MOTOR ", motor.get_script().resource_path)
	if _n < 120:
		for i in 4:
			motor.paso(1.0 / 60.0)
		return
	var pos: Dictionary = motor.poseedor
	var anim := String(pos.get("anim_actual", "")) if not pos.is_empty() else ""
	if anim.begins_with("conducir_ls") and _n - _ultima > 90:
		_ultima = _n
		_fotos += 1
		var ruta := OS.get_environment("CAPTURA_DIR").path_join("league_partido_%d.jpg" % _fotos)
		get_viewport().get_texture().get_image().save_jpg(ruta, 0.9)
		print("FOTO %s anim=%s vel=%.1f" % [ruta, anim, (pos["vel"] as Vector3).length()])
	if _fotos >= 3 or _n > 1500:
		print("FIN fotos=%d" % _fotos)
		get_tree().quit()
