extends Node
## LA LLEGADA AL ÁREA VISTA DESDE LA TELE (20-10-2026). Juega el partido con la
## cámara de transmisión y, cuando un equipo lleva un rato atacando el último
## tercio, saca la foto: se ve si el área se llena como en el fútbol de verdad.
##   herramientas/captura.sh res://pruebas/captura_llegada.tscn
##   (SIN_LLEGADA=1 para la foto de antes)
var _vista: VistaEstadio
var _motor: MotorJugable
var _en_tercio := 0
var _n := 0

func _ready() -> void:
	Calidad.elegida = Calidad.ALTO
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	var par := mundo.proximo_partido()
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))

func _process(_d: float) -> void:
	_n += 1
	var intro: Variant = _vista.get("_intro")
	if intro != null and is_instance_valid(intro) and intro.activa:
		intro.terminar()
		return
	var cer: Variant = _vista.get("_ceremonia")
	if cer != null and is_instance_valid(cer) and cer.activa:
		cer.terminar()
		return
	_motor = _vista.get("_motor")
	if _motor == null or _motor.estado != "juego" or _motor.poseedor.is_empty():
		_en_tercio = 0
	else:
		var due: Dictionary = _motor.poseedor
		var cerca := _motor.pos(due).distance_to(_motor._arco_rival(due)) < 28.0
		_en_tercio = _en_tercio + 1 if cerca else 0
	## Un segundo y medio atacando el último tercio: foto.
	if _en_tercio == 20 or _n > 1200:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/llegada%s.png" % ("_antes" if OS.get_environment("SIN_LLEGADA") != "" else ""))
		print("FOTO en el minuto %d (%s)" % [_motor.minuto() if _motor != null else -1, "tercio" if _en_tercio >= 20 else "tope"])
		get_tree().quit()
