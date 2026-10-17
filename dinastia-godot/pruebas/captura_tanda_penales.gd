extends Node
## LA TANDA DE PENALES EN EL CÉSPED (17-10-2026), con la cámara real del
## partido: una eliminatoria empatada salta al final de la prórroga y se ve la
## tanda (marcador de círculos, plano detrás del lanzador, el portero que se
## tira) y, con la transmisión, los jugadores en el círculo central.
## Salida: pruebas/capturas/tanda_1..4 (JPG con captura.sh).
##   RESOLUCION=1280x720 herramientas/captura.sh res://pruebas/captura_tanda_penales.tscn
var _n := 0
var _vista: VistaEstadio
var _fase := 0
var _espera := 0
var _fotos := 0
var _vistos := 0

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", false)
	cfg.set_value(CajonAjustes.SECCION, "intro", false)
	cfg.save(CajonAjustes.RUTA)
	Partido.ctx_factor_tarjetas = 1.0
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	Partido.ctx_club_id = m.mi_club_id
	var par := m.proximo_partido()
	var partido := Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	_vista.eliminatoria = true
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], partido)

func _foto(nombre: String) -> void:
	_fotos += 1
	var motor: MotorJugable = _vista.get("_motor")
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/tanda_%d.png" % _fotos)
	print("FOTO tanda_%d %s · fase %s · tiros %s" % [_fotos, nombre, String(motor.tanda.get("fase", "")), str(motor.tanda.get("tiros", []))])

func _total(motor: MotorJugable) -> int:
	if motor.tanda.is_empty():
		return 0
	return (motor.tanda["tiros"][0] as Array).size() + (motor.tanda["tiros"][1] as Array).size()

func _process(_d: float) -> void:
	_n += 1
	var motor: MotorJugable = _vista.get("_motor")
	if motor == null:
		return
	if _espera > 0:
		_espera -= 1
		return
	var rig: CameraRig = _vista.get("_rig")
	match _fase:
		0:
			## Al final de la prórroga, empatados: la tanda.
			_vista.partido.prorroga_externa()
			motor.autopiloto = true
			motor.control_equipo = -1
			motor.mitad = 4
			motor.t = motor.dur_mitad() + 1.0
			motor.call("_empezar_tanda")
			_espera = 20
			_fase = 1
		1:
			## Con la transmisión: los de campo en el círculo central.
			## Plano fijo desde el lado del arco: los de campo en el círculo.
			if rig != null:
				rig.set_process(false)
				var cam: Camera3D = rig.cameras[rig.current_index]
				cam.global_position = Vector3(9.0, 6.5, 17.0)
				cam.fov = 48.0
				cam.look_at(Vector3(0, 0.8, 0.5), Vector3.UP)
			_espera = 3
			_fase = 11
		11:
			_foto("circulo")
			if rig != null:
				rig.set_process(true)
			_fase = 2
		2:
			## Tres penales ya tirados y el cuarto, preparado.
			if _total(motor) >= 3 and String(motor.tanda["fase"]) == "preparar" and motor._t_estado > 1.2:
				_foto("preparado")
				_fase = 3
		3:
			if String(motor.tanda["fase"]) == "vuelo" and motor._t_estado > 0.12:
				_foto("disparo")
				_fase = 4
		4:
			if motor.estado == "fin":
				_espera = 30
				_fase = 5
		5:
			_foto("final")
			var cfg := ConfigFile.new()
			cfg.load(CajonAjustes.RUTA)
			cfg.set_value(CajonAjustes.SECCION, "ceremonia", true)
			cfg.set_value(CajonAjustes.SECCION, "intro", true)
			cfg.save(CajonAjustes.RUTA)
			get_tree().quit()
	if _n > 4000:
		print("TIEMPO AGOTADO fase %d" % _fase)
		get_tree().quit()
