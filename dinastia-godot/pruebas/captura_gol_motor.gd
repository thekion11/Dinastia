extends Node
## LA REALIZACIÓN DEL GOL con el motor real: goleador, banquillo, grada,
## barrido y repetición. Salida: pruebas/capturas/gol_motor_1..5.png
var _n := 0
var _vista: VistaEstadio
var _fotos := 0
var _marcado := false

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", false)
	cfg.set_value(CajonAjustes.SECCION, "intro", false)
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
	var motor: MotorJugable = _vista.get("_motor")
	if motor == null:
		return
	if _n < 90:
		for k in 3:
			motor.paso(1.0 / 60.0)
	if _n == 90 and not _marcado:
		_marcado = true
		## Un gol del local: lo marca su delantero centro, cerca del área.
		for p: Dictionary in motor.jugadores:
			if bool(p["es_local"]) and String(p.get("slot_code", "")) == "DC":
				(p["node"] as Node3D).position = Vector3(4.0, 0, 40.0)
				motor.ultimo_toque = p
		motor.call("_gol", true)
	var t: float = float(_vista.get("_cine_t"))
	var momentos := [1.6, 3.2, 4.4, 6.2]
	if _marcado and _fotos < momentos.size() and t >= momentos[_fotos]:
		_fotos += 1
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/gol_motor_%d.png" % _fotos)
		print("FOTO gol_motor_%d cine %.1f" % [_fotos, t])
	var repe: Variant = _vista.get("_repe")
	if _fotos == 4 and repe != null and repe.reproduciendo:
		_fotos = 5
		_espera = 25
	if _fotos == 5:
		_espera -= 1
		if _espera == 0:
			get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/gol_motor_5.png")
			print("FOTO gol_motor_5 (repetición)")
			var cfg := ConfigFile.new()
			cfg.load(CajonAjustes.RUTA)
			cfg.set_value(CajonAjustes.SECCION, "ceremonia", true)
			cfg.set_value(CajonAjustes.SECCION, "intro", true)
			cfg.save(CajonAjustes.RUTA)
			get_tree().quit()
	if _n > 900:
		print("TIEMPO AGOTADO fotos %d cine %.1f" % [_fotos, t])
		get_tree().quit()

var _espera := 0
