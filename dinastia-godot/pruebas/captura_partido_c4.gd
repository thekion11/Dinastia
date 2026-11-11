extends Node
## EL PARTIDO CON EL MOTOR POR DEFECTO (C4, 11-11-2026, orden 39): abre el estadio con la cámara real de un cruce de DOS países (PAIS=ARG,ESP: local del primero, visita del segundo),
## avanza el motor y guarda 2 fotos JPG en `SALIDA` (por defecto el scratchpad del entorno). Imprime el motor usado.
##   PAIS=ARG,ESP SALIDA=/ruta herramientas/captura.sh res://pruebas/captura_partido_c4.tscn
var _n := 0
var _vista: VistaEstadio
var _partido: Partido
var _pais := "ARG"

func _ready() -> void:
	Calidad.elegida = Calidad.ALTA
	var paises: Array[String] = []
	for q in (OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "ARG,ESP").split(",", false):
		paises.append(String(q))
	_pais = paises[0]
	var m := Mundo.new()
	m.generar(paises, 4711)
	var a: Club = null
	var b: Club = null
	for liga: Liga in m.ligas:
		if int(liga.div) == 1:
			if liga.pais == paises[0] and a == null:
				a = liga.clubes[2]
			elif liga.pais == paises[paises.size() - 1] and b == null:
				b = liga.clubes[4]
	m.mi_club_id = a.id
	Partido.ctx_club_id = m.mi_club_id
	_partido = Partido.new(a, b)
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(a, 0.85, b, _partido)

func _foto(nombre: String) -> void:
	var dir := OS.get_environment("SALIDA") if OS.get_environment("SALIDA") != "" else "user://"
	var ruta := "%s/%s.jpg" % [dir, nombre]
	get_viewport().get_texture().get_image().save_jpg(ruta, 0.9)
	print("FOTO ", ruta, " minuto ", _partido.minuto, " marcador ", _partido.goles_local, "-", _partido.goles_visita)

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
	if _n < 40:
		for i in 20:
			motor.paso(1.0 / 60.0)
	if _n == 30 or _n == 42:
		_foto("partido_c4_%s_%d" % [_pais, _n])
	if _n == 44:
		print("MOTOR ", motor.get_meta("motor_id", "?"), " clase ", motor.get_class(), " ", motor.get_script().resource_path, " estado ", motor.estado, " pases ", motor.pases, " tiros ", motor.tiros)
		get_tree().quit()
