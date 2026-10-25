class_name VistaEstadio
extends "res://ui/estadio_p5.gd"
## [Capa 6/6 de `estadio.gd`] _actualizar_barras, disponibles_fuera_del_once, poner_dt, poner_banca_de, poner_personal, _tocar_ambiente … (+11)

func _actualizar_barras() -> void:
	if not PlayerSpawner.mostrar_nombres:
		return
	for f: Dictionary in _en_campo:
		var n: Node3D = f.get("node")
		if is_instance_valid(n) and n.has_node(PlayerSpawner.ROTULO + "/" + PlayerSpawner.BARRA):
			var bar := n.get_node(PlayerSpawner.ROTULO + "/" + PlayerSpawner.BARRA) as Node3D
			## Con el motor real, la energía de verdad del que corre.
			var real := _energia_motor(f)
			if real >= 0.0:
				PlayerSpawner.poner_energia(bar, real * 100.0)
			else:
				PlayerSpawner.actualizar_barra(bar, _minuto_barras)

## Mejores disponibles (sin lesión/sanción, no en el once) por media, para que
## la banca se vea como un banco de verdad y no como un sorteo cualquiera.
static func disponibles_fuera_del_once(c: Club, once_c: Array) -> Array:
	var fuera: Array = []
	for j in c.plantilla:
		if once_c.has(j):
			continue
		if j.lesion > 0 or j.suspension > 0:
			continue
		fuera.append(j)
	fuera.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	return fuera

static func poner_dt(_raiz3d: Node3D, c: Club, es_local: bool, cuantos: int, perfil: Dictionary = {}) -> void:
	var asp: Dictionary = PersonajeDT.del_usuario if c.id == PersonajeDT.club_usuario else PersonajeDT.de_rival(c.id)
	var lado := -1.0 if es_local else 1.0
	var z := lado * 14.0 - lado * (float(maxi(cuantos, 1)) * 0.8 + 1.8)
	## SANCIONADO: no está en la banda, está sentado en la grada.
	if c.id == PersonajeDT.club_usuario and PersonajeDT.sancionado:
		butaca_sancion = RecorridoClub.butaca(perfil if not perfil.is_empty() else perfil_actual, 1.0, z, 4)
		var d := PersonajeDT.crear(_raiz3d, asp, Color(c.color1), Color(c.color2))
		if not d.is_empty():
			var n: Node3D = d["nodo"]
			n.position = butaca_sancion["pos"]
			n.rotation.y = float(butaca_sancion["rumbo"])
			_a_la_butaca(n)
			var ap: AnimationPlayer = d.get("anim") as AnimationPlayer
			if ap != null and ap.has_animation("sentado"):
				ap.play("sentado")
			## Su butaca y las de al lado, libres de hinchas.
			RecorridoClub.despejar_hinchas(_raiz3d, _raiz3d.global_position + (butaca_sancion["pos"] as Vector3) + Vector3(0, 0.5, 0), 1.6)
		return
	PersonajeDT.poner_en_banda(_raiz3d, asp, Color(c.color1), Color(c.color2), Vector3(34.6, 0, z), -PI * 0.5)

## Estática para que la reutilice el partido jugable de la Carrera de Jugador:
## la misma banda, el mismo DT, sin copiar código.
static func poner_banca_de(raiz: Node3D, sp: PlayerSpawner, c: Club, once_c: Array, es_local: bool) -> Array:
	var disponibles := disponibles_fuera_del_once(c, once_c)
	var kit := Puente3D.kit(c)
	var kit_por := Puente3D.kit_portero(c)
	var out: Array = sp.spawn_banca(raiz, disponibles, es_local, kit, kit_por)
	poner_dt(raiz, c, es_local, mini(disponibles.size(), 7))
	if disponibles.size() > 7:
		out.append_array(sp.spawn_sentados(raiz, disponibles.slice(7, 12), es_local, kit, kit_por))
	return out

## Devuelve quién mueve a los camarógrafos: hay que darle el balón.
static func poner_personal(raiz: Node3D) -> CamarografosSiguen:
	if raiz == null:
		return null
	var _raiz3d := raiz
	var i := 0
	var sig := CamarografosSiguen.new()
	sig.name = "CamarografosSiguen"
	raiz.add_child(sig)
	for cam in _raiz3d.find_children("Camarografo*", "Node3D", true, false):
		var base := cam as Node3D
		var d := PersonajeDT.personal_estadio(_raiz3d, "prensa", base.position - base.basis.z * 0.12, base.rotation.y, 700 + i)
		if not d.is_empty():
			for mi in base.find_children("*", "MeshInstance3D", false, false):
				if mi.has_meta("cuerpo"):
					(mi as Node3D).visible = false
			## El operador va DENTRO del puesto: gira y camina con su cámara.
			(d["nodo"] as Node3D).reparent(base, true)
			sig.agregar(base, d)
		i += 1
	var puestos := [
		[Vector3(-38.8, 0, -36.0), -PI * 0.5], [Vector3(-38.8, 0, -12.0), -PI * 0.5],
		[Vector3(-38.8, 0, 12.0), -PI * 0.5], [Vector3(-38.8, 0, 36.0), -PI * 0.5],
		[Vector3(0.0, 0, 57.0), 0.0], [Vector3(0.0, 0, -57.0), PI],
	]
	for k in puestos.size():
		## El giro es hacia FUERA del campo: la persona mira a +Z sin girar.
		PersonajeDT.personal_estadio(_raiz3d, "seguridad", puestos[k][0], puestos[k][1], 900 + k)
	return sig

func _tocar_ambiente() -> void:
	var r := _rng_ambiente.randf()
	if r < 0.35:
		Sonido.toca(AMBIENTE_PERCUSION[_rng_ambiente.randi_range(0, AMBIENTE_PERCUSION.size() - 1)], Sonido.Bus.AMBIENTE)
	elif r < 0.8 or partido.goles_local >= partido.goles_visita:
		Sonido.toca(AMBIENTE_REACCION[_rng_ambiente.randi_range(0, AMBIENTE_REACCION.size() - 1)], Sonido.Bus.AMBIENTE)
	else:
		Sonido.toca("abucheo", Sonido.Bus.AMBIENTE)

## Se llama desde `_process` (antes del paso del motor).
func _cine_paso(delta: float) -> void:
	if is_instance_valid(_cine):
		_cine.paso(delta)

## LAS PISTAS DE LA TRANSMISIÓN: el realizador (la cámara) sabe qué pasa en el
## césped leyendo el motor -sin tocarlo-: quién ataca, si hay un tiro en el
## aire, qué saque se va a lanzar.
func _pistas_camara() -> void:
	if _rig == null or _motor == null:
		return
	_rig.pista_estado = _motor.estado
	var dueno: Dictionary = _motor.poseedor if not _motor.poseedor.is_empty() else _motor.ultimo_toque
	if _motor.estado == "saque" and not _motor.saque.is_empty() and _motor.saque.has("local"):
		_rig.pista_ataca = MotorJugable.dir_ataque(bool(_motor.saque["local"]))
	elif not dueno.is_empty():
		_rig.pista_ataca = MotorJugable.dir_ataque(bool(dueno.get("es_local", true)))
	_rig.pista_saque = String(_motor.saque.get("tipo", "")) if _motor.estado == "saque" else ""
	var tv: Variant = _motor.get("_tiro_vivo")
	if tv is Dictionary and not (tv as Dictionary).is_empty():
		_rig.pista_ocasion = maxf(_rig.pista_ocasion, 1.4)
	_vigilar_inserto()

## Los rótulos de estadísticas de la tele en los momentos muertos.
func _rotulo_automatico() -> void:
	if _stats == null or not _pref("rotulos", true) or is_instance_valid(_cine):
		return
	var cual := RotuloEstadisticas.cuando(_motor.minuto(), _motor.estado, _motor.mitad, _rotulos_hechos)
	if cual == "":
		return
	_rotulos_hechos[cual] = true
	RotuloEstadisticas.mostrar(self, cual, partido, _motor, _stats)

func _mover_cursor() -> void:
	if _cursor == null:
		return
	if _indicador != null:
		_indicador.visible = _cursor.visible
	if not _cursor.visible:
		return
	var u: Dictionary = _motor.usuario
	if u.is_empty() or not is_instance_valid(u.get("node")):
		if _indicador != null:
			_indicador.visible = false
		return
	var n := u["node"] as Node3D
	_cursor.global_position = n.global_position
	var cam := get_viewport().get_camera_3d()
	if _indicador != null and cam != null:
		var cabeza := n.global_position + Vector3(0, 2.05, 0)
		if cam.is_position_behind(cabeza):
			_indicador.visible = false
			return
		var jd: Dictionary = u.get("jugador", {})
		var nom := Nombres.visible(String(jd.get("nombre", "")))
		_indicador.colocar(cam.unproject_position(cabeza), nom.get_slice(" ", nom.get_slice_count(" ") - 1).to_upper(),
			int(jd.get("dorsal", 0)), _motor.forma_fisica(u))

func _hud_juego() -> void:
	if _motor == null or _motor.control_equipo < 0:
		if _barra_pot != null:
			_barra_pot.visible = false
		if _flecha_apunte != null:
			_flecha_apunte.visible = false
		return
	if _barra_pot == null:
		_barra_pot = ProgressBar.new()
		_barra_pot.show_percentage = false
		_barra_pot.max_value = 1.0
		_barra_pot.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		_barra_pot.offset_left = -200
		_barra_pot.offset_right = 200
		_barra_pot.offset_top = -96
		_barra_pot.offset_bottom = -80
		var fondo := StyleBoxFlat.new()
		fondo.bg_color = Color(0, 0, 0, 0.55)
		fondo.set_corner_radius_all(6)
		var lleno := StyleBoxFlat.new()
		lleno.bg_color = Color("ffd23f")
		lleno.set_corner_radius_all(6)
		_barra_pot.add_theme_stylebox_override("background", fondo)
		_barra_pot.add_theme_stylebox_override("fill", lleno)
		add_child(_barra_pot)
	_barra_pot.visible = _motor.cargando or _motor.apuntando
	if _motor.apuntando:
		_barra_pot.value = float(_motor.apunte.get("fuerza", 0.0))
	else:
		_barra_pot.value = _motor.carga
	## Rojo si te pasas de fuerza (el tiro se va alto).
	var lleno_st := _barra_pot.get_theme_stylebox("fill") as StyleBoxFlat
	if lleno_st != null:
		lleno_st.bg_color = Color("ff5a4a") if _barra_pot.value > 0.85 else Color("ffd23f")
	if _flecha_apunte == null:
		_flecha_apunte = MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.35, 0.04, 1.0)
		_flecha_apunte.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("ffd23f")
		mat.emission_enabled = true
		mat.emission = Color("ffd23f")
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_flecha_apunte.material_override = mat
		_raiz3d.add_child(_flecha_apunte)
	var tipo := String(_motor.saque.get("tipo", ""))
	_flecha_apunte.visible = _motor.apuntando and tipo != "penal"
	if _flecha_apunte.visible:
		var lugar: Vector3 = _motor.saque["lugar"]
		var dir := _motor.direccion_apunte()
		var largo := 3.0 + float(_motor.apunte.get("fuerza", 0.0)) * 10.0
		_flecha_apunte.scale = Vector3(1, 1, largo)
		_flecha_apunte.position = lugar + dir * (largo * 0.5 + 0.6) + Vector3(0, 0.05 + float(_motor.apunte.get("loft", 0.0)) * 0.5, 0)
		_flecha_apunte.rotation.y = atan2(dir.x, dir.z)

func _paso_motor(delta: float) -> void:
	if _panel_dt != null or _panel_controles != null or _sala_var != null or _panel_stats != null:
		return
	var mult := _juego.velocidad() if _juego != null else 1.0
	_acum_motor = minf(_acum_motor + delta * mult, DT_MOTOR * 16.0)
	while _acum_motor >= DT_MOTOR:
		_motor.paso(DT_MOTOR)
		_acum_motor -= DT_MOTOR
		## Cada paso: así no se pierde un remate que empieza y acaba en el mismo fotograma.
		if _stats != null:
			_stats.muestrear(_motor, DT_MOTOR)
	_pistas_camara()
	_rotulo_automatico()
	_t_tactica -= delta
	if _t_tactica <= 0.0:
		_t_tactica = 1.0
		_actualizar_tacticas()
	if _sincronizar_partido():
		return
	_refrescar_marcador()
	_mover_cursor()
	_hud_juego()
	if _motor.estado == "fin" and not _final_motor:
		_final_motor = true
		## Las estadísticas del césped, a un CSV (M-162).
		if _stats != null:
			_stats.a_csv(partido, _motor)
		var mio_gana := (partido.goles_local > partido.goles_visita and _mi_lado == 0) or (partido.goles_visita > partido.goles_local and _mi_lado == 1)
		var pen := ""
		if not _motor.tanda.is_empty():
			var gl := _motor.goles_tanda(0)
			var gv := _motor.goles_tanda(1)
			pen = "  (%s %d-%d)" % [Idiomas.t("pen."), gl, gv]
			mio_gana = (gl > gv and _mi_lado == 0) or (gv > gl and _mi_lado == 1)
		_mostrar_banner_gol("🏁 %s  %s %d - %d %s%s" % [Idiomas.t("FINAL"), Nombres.visible(partido.local.nombre),
			partido.goles_local, partido.goles_visita, Nombres.visible(partido.visita.nombre), pen], mio_gana)
		get_tree().create_timer(5.0).timeout.connect(func() -> void:
			if is_instance_valid(self):
				cerrado.emit())
	if _juego != null and _juego.velocidad() > 0.0:
		_prox_ambiente -= delta
		if _prox_ambiente <= 0.0:
			_tocar_ambiente()
			_prox_ambiente = _rng_ambiente.randf_range(10.0, 18.0)
	if _radar != null:
		var pos_ctrl := Vector3.ZERO
		if not _motor.usuario.is_empty() and is_instance_valid(_motor.usuario.get("node")):
			pos_ctrl = (_motor.usuario["node"] as Node3D).global_position
		_radar.actualizar_datos(_en_campo, _balon.global_position if is_instance_valid(_balon) else Vector3.ZERO, pos_ctrl)

func _process(delta: float) -> void:
	StadiumBuilder.ocultar_techo_ante(get_viewport().get_camera_3d())
	## La grada sigue el balón con la cabeza (M-049), cada pocos fotogramas.
	if Engine.get_process_frames() % 4 == 0 and is_instance_valid(_balon):
		OlaGrada.mirar(_raiz3d, _balon.global_position)
	_escalar_rotulos()
	_despejar_rotulos(delta)
	_hud_realizacion(delta)
	if _juego == null or partido == null:
		return
	## Durante la repetición y la presentación el partido está CONGELADO: ni
	## reloj ni minutos.
	if _repe != null and _repe.reproduciendo:
		return
	if _intro != null and _intro.activa:
		return
	if is_instance_valid(_ceremonia) and _ceremonia.activa:
		return
	if _motor != null:
		_cine_paso(delta)
		_paso_motor(delta)
		return
	if _destacado_hasta_ms > 0 and Time.get_ticks_msec() >= _destacado_hasta_ms:
		_destacado_hasta_ms = -1
		if _juego.vel_idx == VEL_DESTACADOS_JUGADA:
			_juego.vel_idx = VEL_DESTACADOS_RAPIDO
			if _btn_velocidad != null:
				_btn_velocidad.text = "⏱ " + _juego.etiqueta_velocidad()
	_juego.tick(delta)
	## El reloj de la reproducción manda: cuando cruza un minuto, se le pide otro
	## minuto al partido. Nunca al revés, y nunca los dos a la vez.
	while partido.minuto < _juego.current_minute() and not partido.terminado_ya:
		partido.simular_minuto()
		## EL DESCANSO TAMBIÉN EN 3D: al 45 se vuelve al camarín (charla,
		## cambios, pizarra) y "Salir a la segunda parte" reabre el estadio.
		if parar_en_descanso and not _descanso_hecho and partido.minuto >= 45:
			_descanso_hecho = true
			cerrado.emit()
			return
	if partido.minuto != _minuto_barras:
		_minuto_barras = partido.minuto
		_actualizar_barras()
	_refrescar_marcador()

	if _juego.elapsed >= _prox_ambiente:
		_tocar_ambiente()
		_prox_ambiente = _juego.elapsed + _rng_ambiente.randf_range(10.0, 18.0)

	# Actualizar radar táctico
	if _radar != null:
		var pos_ctrl := Vector3.ZERO
		if _control != null and not _control.jugador_activo.is_empty() and is_instance_valid(_control.jugador_activo.get("node")):
			pos_ctrl = _control.jugador_activo["node"].global_position
		_radar.actualizar_datos(_en_campo, _balon.global_position if is_instance_valid(_balon) else Vector3.ZERO, pos_ctrl)

func _unhandled_input(e: InputEvent) -> void:
	## SALTAR LA REPETICIÓN: su misma tecla, Esc o un clic (el partido está congelado).
	if _repe != null and _repe.reproduciendo and _sala_var == null and (e.is_action_pressed("jugar_repeticion")
			or e.is_action_pressed("ui_cancel") or (e is InputEventMouseButton and (e as InputEventMouseButton).pressed
			and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT)):
		get_viewport().set_input_as_handled()
		_repe.saltar()
		return
	if partido != null and _panel_controles == null and _panel_stats == null and e.is_action_pressed("jugar_estadisticas"):
		get_viewport().set_input_as_handled()
		abrir_estadisticas()
		return
	if partido != null and _panel_dt == null and _panel_controles == null and _panel_stats == null and e.is_action_pressed("jugar_repeticion"):
		get_viewport().set_input_as_handled()
		repetir_jugada()
		return
	if _motor != null and _panel_dt == null and _panel_controles == null and _panel_stats == null and e.is_action_pressed("jugar_pausa"):
		if _cajon != null and _cajon.abierto:
			return
		get_viewport().set_input_as_handled()
		_abrir_panel_dt()

## Al salir del 3D el partido puede seguir en la pantalla 2D: ahí vuelve a
## jugarlo el `Partido` por su cuenta (si no, no habría goles).
func _exit_tree() -> void:
	if partido != null and _motor != null:
		partido.motor_externo = false
		PlayerSpawner.mostrar_nombres = _nombres_globales

## La práctica: tomas el mando de tu equipo al momento y un aviso explica qué es.
func _empezar_practica() -> void:
	if _motor == null:
		return
	if _motor.control_equipo < 0:
		_alternar_control_motor()
	_mostrar_banner_gol(Idiomas.t("🎯 Práctica libre: prueba los controles. El rival no presiona y el reloj no corre. Esc para salir."), true)

## Abre la práctica libre con tu club contra un sparring de su liga.
static func abrir_practica(padre: Node, m: Mundo) -> VistaEstadio:
	var c := m.mi_club()
	if c == null:
		return null
	var liga: Liga = null
	for l: Liga in m.ligas:
		if l.clubes.has(c):
			liga = l
	var rival: Club = null
	for x: Club in (liga.clubes if liga != null else []):
		if x != c:
			rival = x
			break
	if rival == null:
		return null
	Partido.ctx_club_id = c.id
	var v := VistaEstadio.new()
	v.practica = true
	padre.add_child(v)
	v.abrir(c, 0.15, rival, Partido.new(c, rival), m.perfil_estadio_de(c))
	return v
