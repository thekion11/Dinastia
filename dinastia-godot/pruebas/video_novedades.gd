extends Node
## VÍDEO DE NOVEDADES (14-10-2026): lo hecho en la MEGA AUDITORÍA 2, jugando de
## verdad (partido con público de personas reales y efectos de cámara, conducción
## con cámara interior, menús completos y minijuegos nuevos). Se graba POR TRAMOS:
##   NOV_TRAMO=partido godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##       --fixed-fps 20 --write-movie pruebas/capturas/nov/partido.avi res://pruebas/video_novedades.tscn
## y `herramientas/montar_novedades.py` los junta con rótulos en un MP4.

const TRAMOS := {"partido": 170, "conduccion": 180, "menus": 100, "minijuegos": 120}
var _tramo := "partido"
var _f := 0
var _vista: VistaEstadio
var _p: Node
var _e: ExploradorCiudad
var _gol := false
var _bot: MinijuegoMalabares
var _etiqueta: Label

func _ready() -> void:
	_tramo = OS.get_environment("NOV_TRAMO")
	if not TRAMOS.has(_tramo):
		_tramo = "partido"
	var capa := CanvasLayer.new()
	capa.layer = 100
	add_child(capa)
	_etiqueta = Label.new()
	_etiqueta.position = Vector2(24, 650)
	_etiqueta.add_theme_font_size_override("font_size", 30)
	_etiqueta.add_theme_color_override("font_outline_color", Color.BLACK)
	_etiqueta.add_theme_constant_override("outline_size", 8)
	capa.add_child(_etiqueta)
	match _tramo:
		"partido":
			Calidad.elegida = Calidad.ALTO
			_ajustes(false)
			var m := Mundo.new()
			m.generar(["CHI"], 4711)
			m.mi_club_id = m.ligas[0].clubes[0].id
			Partido.ctx_club_id = m.mi_club_id
			var par := m.proximo_partido()
			_vista = VistaEstadio.new()
			add_child(_vista)
			_vista.abrir(par[0], 0.95, par[1], Partido.new(par[0], par[1]))
		"conduccion", "menus", "minijuegos":
			_p = load("res://escenas/principal.tscn").instantiate()
			add_child(_p)

func _ajustes(ceremonia: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", ceremonia)
	cfg.set_value(CajonAjustes.SECCION, "intro", ceremonia)
	cfg.save(CajonAjustes.RUTA)

func _process(_d: float) -> void:
	_f += 1
	match _tramo:
		"partido": _partido()
		"conduccion": _conduccion()
		"menus": _menus()
		"minijuegos": _minijuegos()
	if _f >= int(TRAMOS[_tramo]):
		if _tramo == "partido":
			_ajustes(true)
		get_tree().quit()

func _partido() -> void:
	var motor: MotorJugable = _vista.get("_motor")
	if motor == null:
		return
	_etiqueta.text = "Público de personas reales · cámara de transmisión"
	if _f < 90:
		for k in 3:
			motor.paso(1.0 / 60.0)
	if _f == 90 and not _gol:
		_gol = true
		for p: Dictionary in motor.jugadores:
			if bool(p["es_local"]) and String(p.get("slot_code", "")) == "DC":
				(p["node"] as Node3D).position = Vector3(4.0, 0, 40.0)
				motor.ultimo_toque = p
		motor.call("_gol", true)
	if _f >= 90:
		_etiqueta.text = "GOL · sacudida y golpe de zoom de cámara"

func _conduccion() -> void:
	if _f == 6:
		_p.call("_ver_ciudad_propia")
		var v: VistaCiudad
		for h in _p.get_children():
			if h is VistaCiudad:
				v = h
		v.set("_ciclo_activo", false)
		v.set("_hora", 11.0)
		v.call("_aplicar_hora")
		v.explorar("coche")
		_e = v.get("_explorador")
		_e.cuerpo.position = Vector3(1005.0, 0, -500.0)
		_e.cuerpo.position.y = _e.altura_suelo(1005.0, -500.0)
		_e.set("rumbo", PI)
	if _e == null or _f < 10:
		return
	var fase := (_f - 10) / 55
	_e.cam_coche = clampi(fase, 0, 2)
	_etiqueta.text = ["Conducción: tercera persona", "Cámara de capó", "Cámara interior"][_e.cam_coche]
	_e.set("vel", minf(float(_e.get("vel")) + 1.2, 16.0))
	_e.set("_volante", sin(float(_f) * 0.12) * 0.5)

func _menus() -> void:
	var ml: MenuLateral = _p.get("_menu_lateral")
	if _f == 6:
		ml.abrir_menu("ciudad", -1)
	if _f == 52:
		ml.abrir_menu("editar", -1)
	_etiqueta.text = "Menú Ciudad 3D" if _f < 52 else "Menú Editar"

func _minijuegos() -> void:
	if _f == 6:
		SalaMinijuegos.abrir(_p, _p.get("mundo"))
		_etiqueta.text = "Sala de minijuegos"
	if _f == 40:
		for h in _p.get_children():
			if h is SalaMinijuegos:
				h.queue_free()
		_bot = MinijuegoMalabares.mostrar(_p, null)
		_etiqueta.text = "Malabares (jugado por un bot)"
	if _bot != null and is_instance_valid(_bot):
		if _bot._fin:
			_bot._reiniciar()
		if _bot._y > 0.8:
			_bot._pie = _bot._x
			_bot._tocar()
