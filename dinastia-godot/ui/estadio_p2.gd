extends "res://ui/estadio_p1.gd"
## [Capa 2/6 de `estadio.gd`] recorrer, _mostrar_banner_gol, _guardar_pref, _crear_cursor, texto_controles, _mostrar_ayuda_control … (+21)

## Baja al vestuario con el protagonista y deja recorrer el estadio a pie.
func recorrer() -> void:
	if _explorador != null:
		return
	if _cajon != null and _cajon.has_method("cerrar"):
		_cajon.call("cerrar")
	_ocultos = []
	for c in get_children():
		if c is CanvasItem and (c as CanvasItem).visible:
			(c as CanvasItem).visible = false
			_ocultos.append(c)
	if _rig != null:
		_rig.set_process(false)
		_rig.set_process_unhandled_input(false)
	_explorador = ExploradorEstadio.new()
	_raiz3d.add_child(_explorador)
	_explorador.iniciar(_perfil, StadiumBuilder.niveles_de(_perfil, int(_perfil.get("aforo", 20000))), club)
	_explorador.salir.connect(_dejar_de_recorrer)

func _mostrar_banner_gol(texto: String, a_favor: bool) -> void:
	if _banner == null or _banner_caja == null:
		return
	_banner.text = texto
	var e: StyleBoxFlat = _banner_caja.get_theme_stylebox("panel")
	e.bg_color = Color(0.10, 0.62, 0.34, 0.92) if a_favor else Color(0.45, 0.14, 0.14, 0.92)
	if is_instance_valid(_tween_banner):
		_tween_banner.kill()
	_banner_caja.modulate = Color(1, 1, 1, 0)
	_banner_caja.scale = Vector2(0.82, 0.82)
	_tween_banner = create_tween()
	_tween_banner.tween_property(_banner_caja, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_QUAD)
	_tween_banner.parallel().tween_property(_banner_caja, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween_banner.tween_interval(2.4)
	_tween_banner.tween_property(_banner_caja, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_QUAD)

func _guardar_pref(k: String, v: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, k, v)
	cfg.save(CajonAjustes.RUTA)

## El jugador que manejas: el indicador de FC (`IndicadorFC`, en pantalla) y
## un aro muy discreto en el suelo para ubicarlo en las cámaras lejanas.
func _crear_cursor() -> void:
	_cursor = Node3D.new()
	_raiz3d.add_child(_cursor)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.6, 1.0, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var aro := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.55
	tm.outer_radius = 0.62
	tm.rings = 32
	aro.mesh = tm
	aro.scale = Vector3(1, 0.05, 1)
	aro.position = Vector3(0, 0.03, 0)
	aro.material_override = mat
	aro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cursor.add_child(aro)
	_indicador = IndicadorFC.new()
	_indicador.z_index = 5
	add_child(_indicador)
	_cursor.visible = false

## La guía con las teclas REALES (las que el jugador haya configurado).
static func texto_controles() -> String:
	Mando.registrar()
	var partes: Array[String] = []
	var mover := "%s%s%s%s" % [Mando.corto_de("jugar_arriba").get_slice("/", 0),
		Mando.corto_de("jugar_izquierda").get_slice("/", 0), Mando.corto_de("jugar_abajo").get_slice("/", 0),
		Mando.corto_de("jugar_derecha").get_slice("/", 0)]
	partes.append(Idiomas.t("%s mover") % mover)
	for par: Array in [["jugar_sprint", "sprint"], ["jugar_pase", "pase"], ["jugar_tiro", "tiro (mantén)"],
			["jugar_centro", "centro"], ["jugar_filtrado", "al hueco"], ["jugar_mod", "rosca/tenso"],
			["jugar_regate", "proteger"], ["jugar_cambiar", "cambiar"], ["jugar_pausa", "táctica y cambios"]]:
		partes.append("%s %s" % [Mando.corto_de(String(par[0])), Idiomas.t(String(par[1]))])
	return " · ".join(partes)

## La guía de controles: aparece al empezar a controlar y se va sola (y está
## en el cajón ⚙ siempre que haga falta).
func _mostrar_ayuda_control() -> void:
	if _ayuda_control == null:
		_ayuda_control = Tema.etiqueta(13, Color(1, 1, 1, 0.92), "")
		_ayuda_control.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
		_ayuda_control.add_theme_constant_override("shadow_offset_y", 2)
		_ayuda_control.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_ayuda_control.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		_ayuda_control.offset_top = -64
		_ayuda_control.offset_bottom = -40
		_ayuda_control.offset_left = -560
		_ayuda_control.offset_right = 560
		add_child(_ayuda_control)
	_ayuda_control.text = texto_controles()
	_ayuda_control.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(7.0)
	tw.tween_property(_ayuda_control, "modulate:a", 0.0, 0.8)

## CONTROLAR A MI EQUIPO (como en FC): manejas al que tiene el balón o al más
## cercano, con la cámara de televisión; Q / LB cambia de jugador.
func _alternar_control_motor() -> void:
	if _mi_lado < 0:
		_mostrar_banner_gol(Idiomas.t("Este partido no es de tu club: solo puedes mirarlo."), false)
		return
	var activo := _motor.control_equipo < 0
	_guardar_pref("control_equipo", activo)
	_motor.control_equipo = _mi_lado if activo else -1
	_motor.autopiloto = not activo
	_motor.fijar_dificultad(_motor.dificultad_cpu)
	_motor.camara = get_viewport().get_camera_3d() if activo else null
	if not activo:
		_motor.usuario = {}
	if _btn_modo != null:
		_btn_modo.text = Idiomas.t("🎮 Controlar a mi equipo: ") + ("SÍ" if activo else "NO")
	if _cursor == null:
		_crear_cursor()
	_cursor.visible = activo
	if activo:
		_mostrar_ayuda_control()

func _alternar_modo_control() -> void:
	if _motor != null:
		_alternar_control_motor()
		return
	if _control == null:
		return
	_control.alternar_modo()
	if _control.activo:
		_btn_modo.text = Idiomas.t("🎮 Modo: Jugador (FC)")
		if _control.jugador_activo.has("node") and is_instance_valid(_control.jugador_activo["node"]):
			_rig.objetivo_seguimiento = _control.jugador_activo["node"]
	else:
		_btn_modo.text = Idiomas.t("🎮 Modo: Manager")
		_rig.objetivo_seguimiento = null

## ESTADÍSTICAS A PEDIDO: su botón (`jugar_estadisticas`) o desde la pausa. El
## partido espera mientras se miran.
func abrir_estadisticas() -> void:
	if _panel_stats != null or partido == null:
		return
	if _cajon != null and _cajon.abierto:
		_cajon.cerrar()
	_panel_stats = PanelEstadisticas.abrir(self, partido, _motor, _stats)
	_panel_stats.cerrado.connect(func() -> void: _panel_stats = null)

## `con_barrido`: entra con el barrido de marca (a pedido); tras la realización del gol ya
## lo pone `CineGol`, que corta a la repetición con la pantalla tapada.
func _lanzar_repeticion(segundos: float, con_barrido := false) -> void:
	_repe.ui_barrido = self
	if _repe.club_barrido == null:
		_repe.club_barrido = club
	if _rig != null:
		_rig.quitar_inserto()
	if _repe.reproducir(segundos, con_barrido):
		if _rotulo_repe == null:
			_rotulo_repe = PanelContainer.new()
			var st := Tema.caja(Color(0.55, 0.08, 0.08, 0.9), Tema.RADIO_CHICO, Color(1, 1, 1, 0.2))
			_rotulo_repe.add_theme_stylebox_override("panel", st)
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 14)
			fila.add_child(Tema.etiqueta(16, Color.WHITE, Idiomas.t("⟲  REPETICIÓN")))
			## Cómo saltarla (la misma tecla que la pide, o un clic).
			fila.add_child(Tema.etiqueta(12, Color(1, 1, 1, 0.7), "%s · %s" % [Mando.corto_de("jugar_repeticion"), Idiomas.t("Saltar")]))
			_rotulo_repe.add_child(fila)
			add_child(_rotulo_repe)
			_rotulo_repe.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
			_rotulo_repe.offset_top = 70
			_rotulo_repe.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_rotulo_repe.visible = true
		Animar.aparecer(_rotulo_repe)

## REPETICIÓN A PEDIDO (20-10-2026, M-132): los últimos 10 s, con su botón
## (`jugar_repeticion`) o desde la pausa. No en plena ceremonia ni con un panel
## abierto; el partido espera mientras se ve.
func repetir_jugada() -> void:
	if _repe == null or partido == null or partido.terminado_ya or _repe.reproduciendo or _repe.congelar:
		return
	if (_intro != null and _intro.activa) or (is_instance_valid(_ceremonia) and _ceremonia.activa):
		return
	_repe.club_barrido = club
	_lanzar_repeticion(10.0, true)

## La pizarra de los dos clubes, con las instrucciones efímeras y lo que haya
## cambiado el DT rival en vivo.
func _actualizar_tacticas() -> void:
	if _motor == null:
		return
	for i in 2:
		var c: Club = partido.local if i == 0 else partido.visita
		var mio := c.id == Partido.ctx_club_id
		var t := MotorJugable.tactica_desde(c.tactica, mio and partido.instr_riesgo, mio and partido.instr_tiempo)
		t.merge(_ajuste_rival[i], true)
		_motor.tacticas[i] = t

func _abrir_panel_dt() -> void:
	if _motor == null or _panel_dt != null or partido == null or partido.terminado_ya:
		return
	if _mi_lado < 0:
		_mostrar_banner_gol(Idiomas.t("Este partido no es de tu club: solo puedes mirarlo."), false)
		return
	var mio: Club = partido.local if _mi_lado == 0 else partido.visita
	_panel_dt = PanelDTPartido.abrir(self, partido, mio, _motor, abrir_estadisticas, repetir_jugada)
	_panel_dt.cerrado.connect(func() -> void:
		_panel_dt = null
		_actualizar_tacticas())

## La pantalla de controles: el partido se para mientras está abierta.
func abrir_controles() -> void:
	if _panel_controles != null:
		return
	if _cajon != null and _cajon.abierto:
		_cajon.cerrar()
	_panel_controles = PanelControles.abrir(self)
	_panel_controles.cerrado.connect(func() -> void:
		_panel_controles = null
		if _ayuda_control != null and _motor != null and _motor.control_equipo >= 0:
			_mostrar_ayuda_control())

func _fijar_ritmo(r: String) -> void:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ritmo_partido", r)
	cfg.save(CajonAjustes.RUTA)
	if _motor != null:
		## Se respeta el minuto en curso: solo cambia lo que dura cada minuto.
		var frac := _motor.t / maxf(_motor.duracion_mitad, 1.0)
		_motor.duracion_mitad = 45.0 * float(SEG_POR_MINUTO.get(r, 5.5))
		_motor.t = frac * _motor.duracion_mitad
	_mostrar_banner_gol({"rapido": "⏩ Partido corto", "normal": "⏯ Ritmo normal", "largo": "🐢 Partido largo"}.get(r, r), true)

## DIFICULTAD DE LA CPU (20-10-2026): se guarda en los ajustes y vale para el
## próximo partido; en el actual, al momento.
static func dificultad_cpu_guardada() -> String:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	var d := String(cfg.get_value(CajonAjustes.SECCION, "dificultad_cpu", "profesional"))
	return d if MotorJugable.DIFICULTADES.has(d) else "profesional"

func _texto_dificultad() -> String:
	return Idiomas.t("🤖 Dificultad de la CPU: ") + Idiomas.t(String(MotorJugable.DIFICULTADES[dificultad_cpu_guardada()]["nombre"]))

func _fijar_dificultad_cpu(nivel: String) -> void:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "dificultad_cpu", nivel)
	cfg.save(CajonAjustes.RUTA)
	if _motor != null:
		_motor.fijar_dificultad(nivel)
	if _btn_dificultad != null:
		_btn_dificultad.text = _texto_dificultad()
	_mostrar_banner_gol(Idiomas.t("CPU: ") + Idiomas.t(String(MotorJugable.DIFICULTADES[nivel]["nombre"])), true)

## Pasa al siguiente nivel (vuelve al primero tras «Leyenda»).
func _ciclar_dificultad_cpu() -> void:
	var orden: Array = MotorJugable.ORDEN_DIFICULTAD
	var i := orden.find(dificultad_cpu_guardada())
	_fijar_dificultad_cpu(String(orden[(i + 1) % orden.size()]))

## Cicla Pausa → Lento → Normal → Rápido → x4 → Pausa. `mas_rapido()` no
## envuelve -se queda en el último escalón-, así que al llegar a x4 hay que
## saltar a Pausa a mano; en cualquier otro escalón basta con acelerar un paso.
func _ciclar_velocidad() -> void:
	if _juego == null:
		return
	if _juego.vel_idx >= MatchPlayback.VELOCIDADES.size() - 1:
		_juego.pausar_o_seguir()
	else:
		_juego.mas_rapido()
	_btn_velocidad.text = "⏱ " + _juego.etiqueta_velocidad()

func _cambio_ia(c: Club, es_local: bool) -> void:
	var peor: Dictionary = {}
	for p: Dictionary in _motor.jugadores:
		if bool(p["es_local"]) != es_local or bool(p["por"]):
			continue
		if peor.is_empty() or _motor.forma_fisica(p) < _motor.forma_fisica(peor):
			peor = p
	if peor.is_empty() or _motor.forma_fisica(peor) > 0.85:
		return
	var once := partido.once_local if es_local else partido.once_visita
	var sale: Jugador = null
	for j: Jugador in once:
		if j.id == String(peor["id"]):
			sale = j
	if sale == null:
		return
	var grupo := Datos.grupo(sale.pos_e)
	var mejor: Jugador = null
	for j: Jugador in VistaEstadio.disponibles_fuera_del_once(c, once):
		if j.es_portero():
			continue
		if mejor == null or (Datos.grupo(j.pos_e) == grupo and Datos.grupo(mejor.pos_e) != grupo) \
				or (Datos.grupo(j.pos_e) == Datos.grupo(mejor.pos_e) and j.ovr > mejor.ovr):
			mejor = j
	if mejor != null:
		partido.cambiar(sale, mejor)

## EL DT DE LA IA, EN VIVO: al 60', 70' y 80' cambia al más cansado si tiene
## con qué; perdiendo desde el 70' va a por el partido, y ganando por uno
## desde el 80' lo cierra. Los dos si el partido no es tuyo.
func _dt_rival(minuto: int) -> void:
	for i in 2:
		if i == _mi_lado:
			continue
		var c: Club = partido.local if i == 0 else partido.visita
		var mios := partido.goles_local if i == 0 else partido.goles_visita
		var suyos := partido.goles_visita if i == 0 else partido.goles_local
		if minuto == 70 and mios < suyos:
			_ajuste_rival[i] = {"mentalidad": 3, "presion": 2, "linea": 2}
		elif minuto == 80 and mios == suyos + 1:
			_ajuste_rival[i] = {"mentalidad": 0, "linea": 0}
		## En la prórroga, otro al 95' y al 106' (hay un cambio más).
		if minuto in [60, 70, 80, 95, 106]:
			_cambio_ia(c, i == 0)

## El reloj del acta sigue al del césped. Devuelve true si la vista se cierra
## (descanso: el camarín).
func _sincronizar_partido() -> bool:
	## En el añadido el acta se queda en el 44'/89' hasta que de verdad se
	## pita: así un gol en el descuento sigue contando y el descanso no se
	## adelanta.
	## En la prórroga igual: 104' y 119' hasta que se pita; durante la tanda
	## el acta espera en el 119' (el pitido final llega con los penales ya
	## guardados, para que `penales()` dé los del césped).
	var objetivo := partido.minutos_fin if _motor.estado == "fin" else _motor.minuto()
	if _motor.estado != "fin":
		if _motor.estado == "tanda":
			objetivo = mini(objetivo, partido.minutos_fin - 1)
		elif _motor.mitad == 1 and _motor.estado != "descanso":
			objetivo = mini(objetivo, 44)
		elif _motor.mitad == 2:
			objetivo = mini(objetivo, 89)
		elif _motor.mitad == 3:
			objetivo = mini(objetivo, 104)
		elif _motor.mitad == 4:
			objetivo = mini(objetivo, 119)
		if _motor.estado == "descanso" or (_motor.mitad == 2 and partido.minuto < 45):
			objetivo = maxi(objetivo, 45)
	while partido.minuto < objetivo and not partido.terminado_ya:
		partido.simular_minuto()
		partido.fijar_estadisticas(float(_motor.posesion_local()), _motor.corners, _motor.faltas, _motor.fueras_de_juego)
		_dt_rival(partido.minuto)
		if parar_en_descanso and not _descanso_hecho and partido.minuto >= 45:
			_descanso_hecho = true
			cerrado.emit()
			return true
	return false

## «Simular hasta el final» con el motor: lo que falta se juega a toda
## velocidad y sin pantalla (tu equipo en piloto automático).
func _simular_resto_motor() -> void:
	_motor.autopiloto = true
	_motor.control_equipo = -1
	_motor.fijar_dificultad(_motor.dificultad_cpu)
	_descanso_hecho = true
	var pasos := 0
	while _motor.estado != "fin" and pasos < 60 * 3600:
		_motor.paso(1.0 / 20.0)
		if _stats != null:
			_stats.muestrear(_motor, 1.0 / 20.0)
		pasos += 1
		if pasos % 20 == 0:
			_t_tactica = 0.0
			parar_en_descanso = false
			_sincronizar_partido()
	parar_en_descanso = false
	_sincronizar_partido()
	while not partido.terminado_ya:
		partido.simular_minuto()
	cerrado.emit()

func _mostrar_nombres(si: bool) -> void:
	PlayerSpawner.mostrar_nombres = si
	_fov_rotulos = -1.0
	for f: Dictionary in _en_campo:
		var n: Node3D = f.get("node")
		if is_instance_valid(n) and n.has_node(PlayerSpawner.ROTULO):
			(n.get_node(PlayerSpawner.ROTULO) as Node3D).visible = si

## 47000 -> "47.000", como se escribe en español.
func _miles(n: int) -> String:
	var t := str(n)
	var out := ""
	while t.length() > 3:
		out = "." + t.substr(t.length() - 3) + out
		t = t.substr(0, t.length() - 3)
	return t + out

func _actualizar_pie(perfil: Dictionary, aforo: int, ocupacion: float) -> void:
	## El aforo es el OFICIAL del club (el mismo que en la presentación y en
	## los menús), no el recuento de butacas del modelo 3D, que no coincidía.
	var techo := String(perfil["techo"])
	_pie_base = "%s%s  ·  %s de %d niveles  ·  %s  ·  %s butacas, %d%% de ocupación" % [
		club.nombre, ("  ·  «%s»" % String(perfil["apodo"])) if String(perfil.get("apodo", "")) != "" else "",
		String(perfil["forma"]).capitalize(), int(perfil["niveles"]),
		"sin techo" if techo == "sin" else "techo " + techo,
		_miles(club.estadio_aforo if club.estadio_aforo > 0 else aforo), int(ocupacion * 100.0)]
	if visitante != null:
		_pie_base += "  ·  %d en el campo" % _en_campo.size()
	_pie.text = _pie_base
