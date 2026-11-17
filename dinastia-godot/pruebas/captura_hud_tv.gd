extends Node
## HUD DE TV (17-11): fotos ANTES/DESPUÉS del marcador, los nombres sobre el campo y el radar del partido, con la CÁMARA REAL de
## TV (estadio, motor por defecto, ALTA). Un cruce de DOS países (PAIS=ENG,ARG: local del primero, visita del segundo); variar los
## países en cada tanda (regla 34). `tv` y `tv2` = mirando el partido (el foco es quien lleva el balón); `ctrl` = con el equipo en
## tus manos (el controlado con su indicador y el rival más cercano), sin tocar las preferencias guardadas.
##   PAIS=GER,BRA ETIQUETA=despues SALIDA=/ruta herramientas/captura.sh res://pruebas/captura_hud_tv.tscn
var _n := 0
var _vista: VistaEstadio
var _pais := "ENG_ARG"

func _ready() -> void:
	## CALIDAD=minima: MÍNIMA (ULTRA BAJA); sin ella, ALTA.
	Calidad.elegida = Calidad.ULTRA_BAJA if OS.get_environment("CALIDAD") == "minima" else Calidad.nivel_de_argumentos(Calidad.ALTA)
	var paises: Array[String] = []
	for q in (OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "ENG,ARG").split(",", false):
		paises.append(String(q))
	_pais = "_".join(paises)
	var m := Mundo.new()
	m.generar(paises, 4711)
	var a: Club = null
	var b: Club = null
	for liga: Liga in m.ligas:
		if int(liga.div) == 1:
			if liga.pais == paises[0] and a == null:
				a = liga.clubes[3]
			elif liga.pais == paises[paises.size() - 1] and b == null:
				b = liga.clubes[1]
	m.mi_club_id = a.id
	Partido.ctx_club_id = m.mi_club_id
	var p := Partido.new(a, b)
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(a, 0.85, b, p)
	print("CRUCE %s (%s) - %s (%s)" % [a.nombre, a.color1, b.nombre, b.color1])

func _foto(nombre: String) -> void:
	var dir := OS.get_environment("SALIDA") if OS.get_environment("SALIDA") != "" else "user://"
	var ruta := "%s/%s%s_%s_%s.jpg" % [dir, nombre, "_min" if OS.get_environment("CALIDAD") == "minima" else "", _pais.to_lower(), OS.get_environment("ETIQUETA") if OS.get_environment("ETIQUETA") != "" else "x"]
	get_viewport().get_texture().get_image().save_jpg(ruta, 0.9)
	print("FOTO ", ruta)

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
	if _n < 30:
		for i in 12:
			motor.paso(1.0 / 60.0)
	else:
		motor.paso(1.0 / 60.0)
	## Cada foto, en el primer fotograma LIMPIO desde su turno: sin repetición (se salta), ni celebración, ni balón parado
	## (con un gol temprano las fotos salían en la repetición, con el HUD escondido a propósito).
	if _n >= _turno and _limpio(motor):
		_hacer(motor)
	if _hechas >= 3 or _n > 1400:
		get_tree().quit()

var _turno := 70
var _hechas := 0

func _limpio(motor: MotorJugable) -> bool:
	var repe: Variant = _vista.get("_repe")
	if repe != null and is_instance_valid(repe) and repe.reproduciendo:
		repe.saltar()
		return false
	var cine: Variant = _vista.get("_cine")
	return motor.estado == "juego" and not (cine != null and is_instance_valid(cine))

func _hacer(motor: MotorJugable) -> void:
	_foto(["tv", "tv2", "ctrl"][_hechas])
	_hechas += 1
	_turno = _n + (100 if _hechas == 1 else 60)
	if _hechas == 2:
		## Tu equipo en tus manos, como `_alternar_control_motor` pero sin guardar la preferencia (el archivo de ajustes es de todos).
		var lado: int = _vista.get("_mi_lado")
		motor.control_equipo = maxi(lado, 0)
		motor.autopiloto = false
		motor.camara = get_viewport().get_camera_3d()
		if _vista.get("_cursor") == null:
			_vista.call("_crear_cursor")
		(_vista.get("_cursor") as Node3D).visible = true
