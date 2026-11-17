extends Node
## PÚBLICO Y CÉSPED (17-11): fotos ANTES/DESPUÉS con la CÁMARA REAL de TV del partido y cifras de dibujo (llamadas, triángulos,
## objetos: media de 24 fotogramas con la cámara de TV «Transmisión»; después una foto con la «TV lejana», que enseña más grada). Un cruce de DOS países (PAIS=ITA,ARG: local del primero, visita del segundo);
## variar los países en cada tanda (regla 34). CALIDAD=minima|alta (por defecto alta); el modo rendimiento va como en el juego
## instalado (encendido: en MÍNIMA, el césped barato).
##   PAIS=ENG,BRA CALIDAD=minima ETIQUETA=antes SALIDA=/ruta herramientas/captura.sh res://pruebas/captura_publico_cesped.tscn
var _n := 0
var _vista: VistaEstadio
var _partido: Partido
var _pais := "ITA_ARG"
var _cal := "alta"
var _ll: Array[float] = []
var _tri: Array[float] = []
var _obj: Array[float] = []

func _ready() -> void:
	_cal = OS.get_environment("CALIDAD").to_lower() if OS.get_environment("CALIDAD") != "" else "alta"
	Calidad.elegida = Calidad.ULTRA_BAJA if _cal.begins_with("min") else Calidad.ALTO
	Calidad.modo_rendimiento = true
	var paises: Array[String] = []
	for q in (OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "ITA,ARG").split(",", false):
		paises.append(String(q))
	_pais = "_".join(paises)
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
	_partido = Partido.new(a, b)
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(a, 0.85, b, _partido)
	var pe := a.perfil_estadio()
	print("PERFIL club=%s rival=%s cesped=%s clima=%s forma=%s calidad=%s" % [a.nombre, b.nombre, pe.get("cesped"), pe.get("clima"), pe.get("forma"), _cal])

func _foto(nombre: String) -> void:
	var dir := OS.get_environment("SALIDA") if OS.get_environment("SALIDA") != "" else "user://"
	var et := OS.get_environment("ETIQUETA") if OS.get_environment("ETIQUETA") != "" else "x"
	var ruta := "%s/%s_%s_%s_%s.jpg" % [dir, nombre, _pais.to_lower(), _cal, et]
	get_viewport().get_texture().get_image().save_jpg(ruta, 0.9)
	print("FOTO ", ruta)

static func _media(v: Array[float]) -> float:
	var s := 0.0
	for x in v:
		s += x
	return s / maxf(v.size(), 1.0)

func _info(tipo: RenderingServer.ViewportRenderInfo) -> float:
	return float(RenderingServer.viewport_get_render_info(get_viewport().get_viewport_rid(), RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE, tipo))

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
	var rig: CameraRig = _vista.get("_rig")
	if _n >= 36 and _n < 60:
		_ll.append(_info(RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME))
		_tri.append(_info(RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME))
		_obj.append(_info(RenderingServer.VIEWPORT_RENDER_INFO_OBJECTS_IN_FRAME))
	if _n == 60:
		_foto("tv")
		print("DIBUJO pais=%s calidad=%s camara=%s llamadas=%.0f triangulos=%.0f objetos=%.0f" % [_pais, _cal,
			rig.current_name() if rig != null else "?", _media(_ll), _media(_tri), _media(_obj)])
		## La otra cámara de TV del juego («TV lejana», la de antes del 16-11): enseña más grada.
		if rig != null and rig.camera_names.find("TV lejana") >= 0:
			rig.switch_to(rig.camera_names.find("TV lejana"))
	if _n == 100:
		_foto("lejana")
		get_tree().quit()
