extends Node
## LA FINTA DE LA IA, VISTA CON LA CÁMARA DE TRANSMISIÓN (16-10-2026). Partido
## real (VistaEstadio + motor) con la cámara del partido; se adelanta hasta que
## un NPC amaga y ENGAÑA al defensor, y se sacan 9 fotogramas de la jugada
## (cada 0,1 s). Hoja 1: la pantalla entera tal cual. Hoja 2: el mismo
## fotograma recortado y ampliado alrededor del portador.
##   herramientas/captura.sh res://pruebas/captura_finta.tscn
## Salida: pruebas/capturas/finta_transmision.jpg y finta_transmision_zoom.jpg
var _vista: VistaEstadio
var _motor: MotorJugable
var _n := 0
var _fase := "adelantar"
var _p: Dictionary = {}
var _rival: Dictionary = {}
var _fotos: Array[Image] = []
var _zoom: Array[Image] = []
var _cuenta := 0
const DT := 1.0 / 60.0

func _ready() -> void:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", false)
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

func _process(_d: float) -> void:
	_n += 1
	var intro: Variant = _vista.get("_intro")
	if intro != null and is_instance_valid(intro) and intro.activa:
		intro.terminar()
	var cer: Variant = _vista.get("_ceremonia")
	if cer != null and is_instance_valid(cer) and cer.activa:
		cer.terminar()
	if _motor == null:
		_motor = _vista.get("_motor")
		if _motor == null:
			return
		## Los pasos los damos nosotros (para parar justo al empezar la finta).
		_vista.set_process(false)
	if _n < 20:
		return
	match _fase:
		"adelantar":
			## Un cuarto de segundo de partido por fotograma (la cámara sigue).
			for k in 15:
				var ok0 := _motor.regates_ia_ok
				var n0 := _motor.regates_ia
				_vista._paso_motor(DT)
				## Mejor una que engañe; si tarda mucho, la primera que haya.
				if _motor.regates_ia_ok > ok0 or (_motor.regates_ia > n0 and _motor.t > 150.0):
					_elegir()
					_fase = "foto"
					print("FINTA en t %.1f (minuto %d): %s ante %s, engaña %s" % [_motor.t, _motor.minuto(),
						String(_p.get("slot_code", "")), String(_rival.get("slot_code", "")), str(_motor.regates_ia_ok > ok0)])
					break
			if _motor.estado == "fin":
				print("SIN FINTA")
				get_tree().quit(1)
		"foto":
			_cuenta += 1
			## Dos fotogramas sin avanzar para que la cámara se asiente.
			if _cuenta > 2:
				_foto()
				for k in 6:
					_vista._paso_motor(DT)
			if _fotos.size() >= 9:
				_guardar()

func _elegir() -> void:
	for q: Dictionary in _motor.jugadores:
		if float(q.get("regate_hasta", 0.0)) > _motor.t and (_p.is_empty() or float(q["regate_hasta"]) > float(_p["regate_hasta"])):
			_p = q
	var md := 99.0
	for q: Dictionary in _motor.jugadores:
		if bool(q["es_local"]) != bool(_p["es_local"]):
			var d := _motor.pos(q).distance_to(_motor.pos(_p))
			if d < md:
				md = d
				_rival = q

func _foto() -> void:
	var cam := get_viewport().get_camera_3d()
	var img := get_viewport().get_texture().get_image()
	var tam := img.get_size()
	var ap: AnimationPlayer = _p["anim"]
	var apr: AnimationPlayer = _rival["anim"]
	print("  f%d cámara «%s» portador %s (%.1f m/s) | defensor %s enfriar %.2f a %.1f m" % [_fotos.size(),
		cam.name if cam != null else "?", ap.current_animation if is_instance_valid(ap) else "?",
		(_p["vel"] as Vector3).length(), apr.current_animation if is_instance_valid(apr) else "?",
		float(_rival["enfriar"]), _motor.pos(_p).distance_to(_motor.pos(_rival))])
	## Recorte alrededor del portador (en pantalla), 1/4 del ancho.
	var c := Vector2(tam) * 0.5
	if cam != null and not cam.is_position_behind(_motor.pos(_p)):
		c = cam.unproject_position(_motor.pos(_p) + Vector3(0, 0.9, 0))
	var w := tam.x / 4
	var h := tam.y / 4
	var r := Rect2i(clampi(int(c.x) - w / 2, 0, tam.x - w), clampi(int(c.y) - h / 2, 0, tam.y - h), w, h)
	var z := img.get_region(r)
	z.resize(640, 360, Image.INTERPOLATE_LANCZOS)
	_zoom.append(z)
	var f := img.duplicate() as Image
	f.resize(640, 360, Image.INTERPOLATE_LANCZOS)
	_fotos.append(f)

func _guardar() -> void:
	for par in [[_fotos, "finta_transmision"], [_zoom, "finta_transmision_zoom"]]:
		var lista: Array = par[0]
		var hoja := Image.create(640 * 3, 360 * 3, false, (lista[0] as Image).get_format())
		for k in lista.size():
			hoja.blit_rect(lista[k], Rect2i(0, 0, 640, 360), Vector2i((k % 3) * 640, (k / 3) * 360))
		hoja.save_png("res://pruebas/capturas/%s.png" % par[1])
	print("HOJAS guardadas")
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", true)
	cfg.save(CajonAjustes.RUTA)
	get_tree().quit()
