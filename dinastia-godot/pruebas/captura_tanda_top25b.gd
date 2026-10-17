extends Node
## SEGUNDA TANDA DEL TOP 25 (17-10-2026, ESTADO_MEJORAS: M-104, M-160, M-141,
## M-051, M-238 y los operadores de la sala VAR), con la cámara de TV del
## partido real y de cerca:
##   tv · escudo (pecho de cerca) · cambio_cartel · cambio_palmada · cambio_tv
##   var_operadores · sorteo_moneda · sorteo_saludo · resumen · despido_dialogo · despido
## Salida: pruebas/capturas/top25b_<n>_<nombre>[_antes].png (JPG con captura.sh).
##   RESOLUCION=1280x720 herramientas/captura.sh res://pruebas/captura_tanda_top25b.tscn
##   SUFIJO=_antes  (para la tanda «antes»; lo que aún no existe se salta)
var _n := 0
var _vista: VistaEstadio
var _mundo: Mundo
var _fase := 0
var _espera := 0
var _fotos := 0
var _cam: Camera3D
var _ceremonia: Node
var _sale: Dictionary = {}
var _capa: CanvasLayer
var _despido: Node

func _ready() -> void:
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.ALTO)
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", false)
	cfg.set_value(CajonAjustes.SECCION, "intro", false)
	cfg.save(CajonAjustes.RUTA)
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4711)
	_mundo.mi_club_id = _mundo.ligas[0].clubes[0].id
	Partido.ctx_club_id = _mundo.mi_club_id
	var par := _mundo.proximo_partido()
	var partido := Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], partido)

func _motor() -> MotorJugable:
	return _vista.get("_motor")

func _jugador(local: bool, codigo: String) -> Dictionary:
	for p: Dictionary in _motor().jugadores:
		if bool(p["es_local"]) == local and String(p.get("slot_code", "")) == codigo:
			return p
	for p: Dictionary in _motor().jugadores:
		if bool(p["es_local"]) == local and not bool(p["por"]):
			return p
	return {}

func _foto(nombre: String) -> void:
	_fotos += 1
	var ruta := "res://pruebas/capturas/top25b_%d_%s%s.png" % [_fotos, nombre, OS.get_environment("SUFIJO")]
	get_viewport().get_texture().get_image().save_png(ruta)
	print("FOTO ", ruta)

func _cerca(desde: Vector3, hacia: Vector3, fov := 40.0) -> void:
	if _cam == null:
		_cam = Camera3D.new()
		(_vista.get("_raiz3d") as Node3D).add_child(_cam)
	_cam.fov = fov
	_cam.global_position = desde
	_cam.look_at(hacia, Vector3.UP)
	_cam.make_current()

func _tv() -> void:
	var rig: CameraRig = _vista.get("_rig")
	if _cam != null:
		_cam.clear_current()
	var it := rig.camera_names.find("Transmisión")
	rig.switch_to(maxi(it, 0))

## El Jugador del club local que está en el campo con ese id.
func _jug_por_id(id: String) -> Jugador:
	for c: Club in [_vista.get("club"), _vista.get("visitante")]:
		if c == null:
			continue
		for j: Jugador in c.plantilla:
			if j.id == id:
				return j
	return null

func _process(_d: float) -> void:
	_n += 1
	var motor := _motor()
	if motor == null:
		return
	if _espera > 0:
		_espera -= 1
		return
	match _fase:
		0:
			_espera = 40
			_fase = 1
		1:
			_tv()
			_espera = 3
			_fase = 2
		2:
			_foto("tv")
			## El pecho de un jugador de cerca (el escudo), quieto.
			_vista.get("_juego").vel_idx = 0
			var p := _jugador(true, "MC")
			var nd: Node3D = p["node"]
			nd.rotation.y = PI * 0.5
			var ap: AnimationPlayer = p.get("anim")
			if is_instance_valid(ap) and ap.has_animation("parado"):
				ap.play("parado")
			var fwd := Vector3(sin(nd.rotation.y), 0, cos(nd.rotation.y))
			_cerca(nd.global_position + fwd * 1.25 + Vector3(0, 1.45, 0) + fwd.cross(Vector3.UP) * -0.35,
				nd.global_position + Vector3(0, 1.38, 0) + fwd.cross(Vector3.UP) * -0.08, 30.0)
			_espera = 3
			_fase = 3
		3:
			_foto("escudo")
			_tv()
			_vista.get("_juego").vel_idx = 2
			## EL CAMBIO: un medio del local, cerca de la banda del cuarto árbitro.
			_sale = _jugador(true, "MCD")
			var club: Club = _vista.get("club")
			var sale_j := _jug_por_id(String(_sale.get("id", "")))
			var entra_j: Jugador = null
			for j: Jugador in club.plantilla:
				var en_campo := false
				for q: Dictionary in motor.jugadores:
					if String(q.get("id", "")) == j.id:
						en_campo = true
				if not en_campo and not j.es_portero() and j.disponible():
					entra_j = j
					break
			(_sale["node"] as Node3D).position = Vector3(27.0, 0, -3.0)
			if sale_j != null and entra_j != null:
				_vista.call("_al_cambio", sale_j, entra_j, 61)
			_cerca(Vector3(27.5, 2.3, 9.0), Vector3(34.0, 1.3, 1.0), 38.0)
			_espera = 3
			_fase = 4
		4:
			_foto("cambio_cartel")
			_fase = 5
		5:
			## Espera a la palmada (o un rato, si no hay escena de cambio).
			var esc := _vista.find_child("EscenaCambio*", true, false)
			if esc != null and String(esc.get("fase")) != "palmada" and _n < 900:
				return
			if esc == null:
				_espera = 8
			_fase = 6
		6:
			var esc2 := _vista.find_child("EscenaCambio*", true, false)
			if esc2 != null:
				var ent: Node3D = esc2.get("entra_nodo")
				if is_instance_valid(ent):
					var medio := ent.global_position + Vector3(-0.42, 0, -0.12)
					_cerca(medio + Vector3(-1.2, 1.6, 4.3), medio + Vector3(0, 1.3, 0), 34.0)
				esc2.set("congelar", true)
			_espera = 2
			_fase = 7
		7:
			_foto("cambio_palmada")
			var esc3 := _vista.find_child("EscenaCambio*", true, false)
			if esc3 != null:
				esc3.set("congelar", false)
			_tv()
			_espera = 3
			_fase = 8
		8:
			_foto("cambio_tv")
			_vista.call("_a_la_revision_var", 46, "Revisión del gol: posible fuera de juego", true, func() -> void: pass)
			_espera = 30
			_fase = 9
		9:
			## Los operadores, de frente (la cámara de la sala se congela).
			var sala: Node = null
			for s in _vista.find_children("*", "SalaVAR", true, false):
				sala = s
			if sala is SalaVAR:
				sala.set_process(false)
				var c: Camera3D = sala.get("_cam")
				c.position = Vector3(3.3, 1.45, -1.9)
				c.look_at(Vector3(1.6, 1.0, -0.2), Vector3.UP)
				c.fov = 44.0
			_espera = 3
			_fase = 10
		10:
			_foto("var_operadores")
			for s in _vista.find_children("*", "SalaVAR", true, false):
				s.queue_free()
			_vista.set("_sala_var", null)
			## EL SORTEO: la ceremonia a mano, saltando al final.
			var perfil: Dictionary = _vista.get("_perfil")
			var gc := StadiumBuilder.geom_de_forma(String(perfil.get("forma", "oval")))
			var partido: Partido = _vista.get("partido")
			_ceremonia = CeremoniaPartido.iniciar(_vista, _vista.get("_raiz3d"), _vista.get("_en_campo"), partido.local, partido.visita,
				"Estadio", float(gc["dx"]), float(gc["dz"]), StadiumBuilder.tunel_x(perfil))
			_vista.get("_juego").vel_idx = 0
			_vista.set("_ceremonia", _ceremonia)
			_ceremonia.set("_t", CeremoniaPartido.T_FIN - 3.6)
			_espera = 1
			_fase = 11
		11:
			_foto("sorteo_moneda")
			if is_instance_valid(_ceremonia):
				_ceremonia.set("_t", CeremoniaPartido.T_FIN - 1.9)
			_espera = 1
			_fase = 12
		12:
			_foto("sorteo_saludo")
			if is_instance_valid(_ceremonia):
				_ceremonia.call("terminar")
			## EL RESUMEN con las notas (instantáneo, otro partido).
			_capa = CanvasLayer.new()
			_capa.layer = 120
			add_child(_capa)
			var base := Control.new()
			base.set_anchors_preset(Control.PRESET_FULL_RECT)
			_capa.add_child(base)
			var par := _mundo.proximo_partido()
			var p2 := Partido.new(par[0], par[1])
			p2.preparar()
			ResumenPartido.mostrar(base, p2, _mundo.mi_club(), false, false)
			_espera = 4
			_fase = 13
		13:
			_foto("resumen")
			for h in _capa.get_children():
				h.queue_free()
			if ResourceLoader.exists("res://ui/componentes/escena_despido.gd"):
				_capa.queue_free()
				## Sobre la vista (como en `Principal`): el cuadro de diálogo es una
				## capa propia y debe quedar encima.
				_despido = load("res://ui/componentes/escena_despido.gd").mostrar(_vista, _mundo, "derrota ante Rival")
				_espera = 40
				_fase = 16
			else:
				_fase = 15
		14:
			_foto("despido")
			_fase = 15
		16:
			## Primera frase escrita: foto; luego al final (etapa y salida).
			_foto("despido_dialogo")
			_despido.call("_final")
			_espera = 12
			_fase = 14
		15:
			var cfg := ConfigFile.new()
			cfg.load(CajonAjustes.RUTA)
			cfg.set_value(CajonAjustes.SECCION, "ceremonia", true)
			cfg.set_value(CajonAjustes.SECCION, "intro", true)
			cfg.save(CajonAjustes.RUTA)
			get_tree().quit()
	if _n > 3000:
		print("TIEMPO AGOTADO fase %d" % _fase)
		get_tree().quit()
