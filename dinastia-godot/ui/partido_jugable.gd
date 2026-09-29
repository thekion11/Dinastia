class_name PartidoJugable
extends Control
## EL PARTIDO QUE JUEGAS TÚ (29-9-2026, Carrera de Jugador). La pantalla del
## `MotorJugable`: tu estadio, los 22 con sus equipaciones, la cámara detrás de
## tu futbolista y una interfaz con la estética propia del modo jugador (negro,
## lima eléctrico y fucsia; nada del verde de despacho del modo entrenador).
##
## Controles (teclado / mando): mover WASD o stick · sprint Shift / RT ·
## pase Espacio / A · tiro K / B (mantener para cargar) · centro L / X ·
## pase largo I / Y · al hueco U / RB · regate E / LT · pedir el balón R / L3 ·
## sin balón: presionar (A), entrada (B), barrida (X) · pausa Esc / Start.

signal terminado(resultado: Dictionary)

const LIMA := Color("c6ff3a")
const FUCSIA := Color("ff2e88")
const NEGRO := Color(0.03, 0.035, 0.045, 0.88)

var mundo: Mundo
var carrera: CarreraJugador
var local: Club
var visita: Club
var motor: MotorJugable
var _raiz: Node3D
var _cam: Camera3D
var _vp: SubViewport
var _marcador: Label
var _reloj: Label
var _mis_stats: Label
var _aguante: ProgressBar
var _barra: ProgressBar
var _banner: Label
var _ayuda: Label
var _flecha: MeshInstance3D
var _mira: Label
var _pausa: Control
var _resumen: Control
var _es_local_usuario := true
var _minutos_usuario := 0.0

static func abrir(padre: Node, m: Mundo, c: CarreraJugador, l: Club, v: Club, duracion_mitad := 240.0) -> PartidoJugable:
	var n := PartidoJugable.new()
	n.mundo = m
	n.carrera = c
	n.local = l
	n.visita = v
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	padre.add_child(n)
	n._montar(duracion_mitad)
	return n

func _montar(duracion_mitad: float) -> void:
	var fondo := ColorRect.new()
	fondo.color = Color.BLACK
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var cont := SubViewportContainer.new()
	cont.stretch = true
	cont.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cont)
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.msaa_3d = Viewport.MSAA_4X
	cont.add_child(_vp)
	_raiz = Node3D.new()
	_vp.add_child(_raiz)
	## El estadio del local, el que se juega.
	var perfil := mundo.perfil_estadio_de(local).duplicate() if mundo != null else local.perfil_estadio()
	Ambience.apply(_raiz, perfil, null, Calidad.elegida)
	StadiumBuilder.build_pitch(_raiz, perfil, local)
	StadiumBuilder.build(_raiz, perfil, int(perfil.get("aforo", 20000)), 0.8, local._hash_id(), local)
	## Los 22.
	var yo := carrera.jugador(mundo) if carrera != null else null
	_es_local_usuario = yo != null and yo.club_id == local.id
	var once_l := carrera.once_para_partido(mundo) if _es_local_usuario else local.once()
	var once_v := carrera.once_para_partido(mundo) if (yo != null and yo.club_id == visita.id) else visita.once()
	var sp := PlayerSpawner.new()
	var l := Puente3D.once(once_l)
	var v := Puente3D.once(once_v)
	var lista: Array = []
	lista.append_array(sp.spawn_team(_raiz, l["xi"], l["jugadores"], Puente3D.formacion(local.tactica.formacion), true, Puente3D.kit(local), Puente3D.kit_portero(local)))
	lista.append_array(sp.spawn_team(_raiz, v["xi"], v["jugadores"], Puente3D.formacion(visita.tactica.formacion), false, Puente3D.kit_visita(local, visita), Puente3D.kit_portero(visita)))
	var cb := Comercial.color_balon(mundo.comercial.balon, local) if mundo != null and mundo.comercial != null else []
	var balon := StadiumBuilder.spawn_ball(_raiz, Vector3(0, 0.11, 0), cb)
	motor = MotorJugable.new()
	add_child(motor)
	motor.duracion_mitad = duracion_mitad
	motor.preparar(lista, balon, yo.id if yo != null else "", hash(local.id + visita.id))
	if carrera != null:
		motor.lanza_usuario = {"corner": bool(carrera.lanzador.get("corners", true)),
			"falta": bool(carrera.lanzador.get("faltas", false)), "penal": bool(carrera.lanzador.get("penales", false)), "banda": false}
	motor.aviso.connect(_mostrar_banner)
	motor.gol.connect(_al_gol)
	motor.terminado.connect(_al_terminar)
	## La cámara, detrás de tu jugador.
	_cam = Camera3D.new()
	_cam.fov = 58.0
	_cam.far = 700.0
	_raiz.add_child(_cam)
	_cam.current = true
	_flecha = _crear_flecha()
	_raiz.add_child(_flecha)
	_montar_hud()
	Sonido.toca("silbato" if Sonido.NOMBRES.has("silbato") else "clic", Sonido.Bus.INTERFAZ)

func _crear_flecha() -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(0.35, 0.05, 1.0)
	m.mesh = caja
	var mat := StandardMaterial3D.new()
	mat.albedo_color = LIMA
	mat.emission_enabled = true
	mat.emission = LIMA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override = mat
	m.visible = false
	return m

func _panel(color_borde: Color) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = NEGRO
	st.border_color = color_borde
	st.border_width_left = 4
	st.border_width_bottom = 2
	st.skew = Vector2(0.18, 0)
	st.content_margin_left = 16; st.content_margin_right = 16
	st.content_margin_top = 6; st.content_margin_bottom = 6
	return st

func _etiqueta(tam: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l

func _montar_hud() -> void:
	## Marcador arriba a la izquierda.
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", _panel(LIMA))
	caja.position = Vector2(24, 18)
	add_child(caja)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	caja.add_child(h)
	_marcador = _etiqueta(24, Color.WHITE)
	h.add_child(_marcador)
	_reloj = _etiqueta(22, LIMA)
	h.add_child(_reloj)
	## Tus números, arriba a la derecha.
	var caja2 := PanelContainer.new()
	caja2.add_theme_stylebox_override("panel", _panel(FUCSIA))
	caja2.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	caja2.offset_left = -330
	caja2.offset_right = -24
	caja2.offset_top = 18
	add_child(caja2)
	_mis_stats = _etiqueta(15, Color.WHITE)
	caja2.add_child(_mis_stats)
	## Tu jugador y su aguante, abajo a la izquierda.
	var caja3 := PanelContainer.new()
	caja3.add_theme_stylebox_override("panel", _panel(LIMA))
	caja3.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	caja3.offset_left = 24
	caja3.offset_top = -92
	caja3.offset_bottom = -20
	caja3.offset_right = 360
	add_child(caja3)
	var v := VBoxContainer.new()
	caja3.add_child(v)
	var yo := carrera.jugador(mundo) if carrera != null else null
	var nom := _etiqueta(18, LIMA)
	nom.text = ("%d  %s" % [yo.dorsal, yo.nombre.to_upper()]) if yo != null else "—"
	v.add_child(nom)
	_aguante = ProgressBar.new()
	_aguante.show_percentage = false
	_aguante.custom_minimum_size = Vector2(300, 10)
	_aguante.max_value = 1.0
	var fondo_b := StyleBoxFlat.new()
	fondo_b.bg_color = Color(1, 1, 1, 0.12)
	var lleno := StyleBoxFlat.new()
	lleno.bg_color = LIMA
	_aguante.add_theme_stylebox_override("background", fondo_b)
	_aguante.add_theme_stylebox_override("fill", lleno)
	v.add_child(_aguante)
	## La barra de potencia, abajo al centro (solo al cargar o apuntar).
	_barra = ProgressBar.new()
	_barra.show_percentage = false
	_barra.max_value = 1.0
	_barra.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_barra.offset_left = -220
	_barra.offset_right = 220
	_barra.offset_top = -70
	_barra.offset_bottom = -50
	var lleno2 := StyleBoxFlat.new()
	lleno2.bg_color = FUCSIA
	_barra.add_theme_stylebox_override("background", fondo_b)
	_barra.add_theme_stylebox_override("fill", lleno2)
	_barra.visible = false
	add_child(_barra)
	## El gran rótulo de sucesos (¡GOL!, falta, córner...).
	_banner = _etiqueta(46, LIMA)
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.offset_top = 110
	_banner.offset_left = -500
	_banner.offset_right = 500
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.modulate.a = 0.0
	add_child(_banner)
	## Ayuda de controles.
	_ayuda = _etiqueta(12, Color(1, 1, 1, 0.75))
	_ayuda.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_ayuda.offset_left = -760
	_ayuda.offset_right = -24
	_ayuda.offset_top = -44
	_ayuda.offset_bottom = -20
	_ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_ayuda)
	## La mira del penal.
	_mira = _etiqueta(40, FUCSIA)
	_mira.text = "◎"
	_mira.visible = false
	add_child(_mira)

func _process(delta: float) -> void:
	if motor == null:
		return
	_actualizar_camara(delta)
	var yo := motor.usuario
	_marcador.text = "%s  %d - %d  %s" % [_abrev(local.nombre), motor.goles[0], motor.goles[1], _abrev(visita.nombre)]
	_reloj.text = "%d'" % motor.minuto()
	var s := motor.stats
	_mis_stats.text = "⚽ %d   🅰 %d   🎯 %d/%d   ✔ %d/%d pases   ⭐ %.1f" % [s["goles"], s["asist"], s["a_puerta"], s["tiros"], s["pases_ok"], s["pases"], motor.nota_usuario()]
	if not yo.is_empty():
		_aguante.value = float(yo["aguante"])
		if motor.estado == "juego":
			_minutos_usuario += delta / motor.duracion_mitad * 45.0
	var con_balon := not yo.is_empty() and motor.poseedor == yo
	if motor.apuntando:
		_barra.visible = true
		_barra.value = float(motor.apunte["fuerza"])
		_ayuda.text = "APUNTAR: ◀ ▶ dirección · ▲ ▼ altura · mantén TIRO para cargar y suelta · PASE: a ras"
	elif motor.cargando:
		_barra.visible = true
		_barra.value = motor.carga
	else:
		_barra.visible = false
		_ayuda.text = ("CON BALÓN: Espacio/A pase · K/B tiro (mantén) · L/X centro · I/Y largo · U/RB al hueco · E/LT regate · Shift/RT sprint" if con_balon
			else "SIN BALÓN: Espacio/A presionar · K/B entrada · L/X barrida · R/L3 pedir el balón · Shift/RT sprint · Esc pausa")
	_actualizar_apunte()
	if Input.is_action_just_pressed("jugar_pausa") and motor.estado != "fin":
		_alternar_pausa()

func _abrev(nombre: String) -> String:
	var n := Nombres.visible(nombre)
	return n.substr(0, 3).to_upper() if n.length() > 3 else n.to_upper()

## La cámara va detrás de tu jugador, mirando hacia el arco rival; en los
## lanzamientos, detrás del balón.
func _actualizar_camara(delta: float) -> void:
	var foco: Vector3
	var d := MotorJugable.dir_ataque(_es_local_usuario)
	if motor.apuntando or motor.estado == "saque" and not motor.usuario.is_empty() and motor.saque.get("lanzador") == motor.usuario:
		foco = motor.balon.position
	elif not motor.usuario.is_empty():
		foco = motor.pos(motor.usuario).lerp(motor.balon.position, 0.35)
	else:
		foco = motor.balon.position
	var detras := Vector3(0, 10.5, -14.0 * d)
	var mira := foco + Vector3(0, 0.5, 9.0 * d)
	if motor.estado == "saque" and String(motor.saque.get("tipo", "")) == "penal":
		detras = Vector3(0, 3.2, -7.0 * d)
	elif motor.apuntando:
		## Córner y falta: detrás del balón, mirando adonde apuntas.
		var dir := motor.direccion_apunte()
		detras = -dir * 9.0 + Vector3(0, 6.5, 0)
		mira = foco + dir * 18.0
	var deseada := foco + detras
	_cam.position = _cam.position.lerp(deseada, clampf(delta * 3.5, 0.0, 1.0)) if _cam.position.length() > 0.1 else deseada
	_cam.look_at(mira, Vector3.UP)

func _actualizar_apunte() -> void:
	_flecha.visible = false
	_mira.visible = false
	if not motor.apuntando:
		return
	var tipo := String(motor.saque.get("tipo", ""))
	var lugar: Vector3 = motor.saque["lugar"]
	if tipo == "penal":
		var arco_z := MotorJugable.LARGO * MotorJugable.dir_ataque(_es_local_usuario)
		var x := -float(motor.apunte["x"]) * MotorJugable.dir_ataque(_es_local_usuario) * (MotorJugable.PALO - 0.35)
		var y := 0.35 + float(motor.apunte["y"]) * 1.8
		var p3 := Vector3(x, y, arco_z)
		if not _cam.is_position_behind(p3):
			_mira.visible = true
			_mira.position = _cam.unproject_position(p3) - Vector2(16, 28)
		return
	var dir := motor.direccion_apunte()
	var largo := 3.0 + float(motor.apunte["fuerza"]) * 10.0
	_flecha.visible = true
	_flecha.scale = Vector3(1, 1, largo)
	_flecha.position = lugar + dir * (largo * 0.5 + 0.6) + Vector3(0, 0.05 + float(motor.apunte["loft"]) * 0.5, 0)
	_flecha.rotation.y = atan2(dir.x, dir.z)

func _mostrar_banner(texto: String) -> void:
	_banner.text = Idiomas.t(texto)
	_banner.modulate.a = 1.0
	_banner.scale = Vector2(1.25, 1.25)
	_banner.pivot_offset = Vector2(500, 30)
	var tw := create_tween()
	tw.tween_property(_banner, "scale", Vector2.ONE, 0.25)
	tw.tween_interval(1.4)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.5)

func _al_gol(de_local: bool, autor: String, _asist: String) -> void:
	var yo_id := String(motor.usuario.get("id", ""))
	if autor != "" and autor == yo_id:
		_mostrar_banner("¡¡GOOOL TUYO!!")
	else:
		_mostrar_banner("¡GOL de %s!" % (Nombres.visible(local.nombre) if de_local else Nombres.visible(visita.nombre)))
	Sonido.toca("gol" if de_local == _es_local_usuario else "gol_rival", Sonido.Bus.INTERFAZ)

# ---------------------------------------------------------------- pausa y final

func _alternar_pausa() -> void:
	if _pausa != null:
		_pausa.queue_free()
		_pausa = null
		motor.set_physics_process(true)
		return
	motor.set_physics_process(false)
	_pausa = _caja_centro("PAUSA", [
		["▶  Seguir jugando", _alternar_pausa],
		["⏩  Simular lo que queda", _simular_resto],
	])

func _caja_centro(titulo: String, botones: Array) -> Control:
	var capa := ColorRect.new()
	capa.color = Color(0, 0, 0, 0.6)
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(capa)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(centro)
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", _panel(FUCSIA))
	centro.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	caja.add_child(v)
	var t := _etiqueta(30, LIMA)
	t.text = titulo
	v.add_child(t)
	t.text = Idiomas.t(titulo)
	for b: Array in botones:
		var bt := Button.new()
		bt.text = Idiomas.t(String(b[0]))
		bt.custom_minimum_size = Vector2(360, 44)
		bt.add_theme_font_size_override("font_size", 17)
		bt.pressed.connect(b[1])
		v.add_child(bt)
	return capa

## Lo que falta se juega solo (tu jugador en piloto automático), a toda
## velocidad y sin pantalla.
func _simular_resto() -> void:
	if _pausa != null:
		_pausa.queue_free()
		_pausa = null
	motor.autopiloto = true
	var pasos := 0
	while motor.estado != "fin" and pasos < 60 * 1200:
		motor.paso(1.0 / 20.0)
		pasos += 1
	motor.set_physics_process(false)

func _al_terminar() -> void:
	motor.set_physics_process(false)
	var s := motor.stats
	var yo := carrera.jugador(mundo) if carrera != null else null
	_resumen = _caja_centro("FINAL  %s %d - %d %s" % [Nombres.visible(local.nombre), motor.goles[0], motor.goles[1], Nombres.visible(visita.nombre)], [
		["Continuar", _cerrar]])
	var caja: VBoxContainer = _resumen.find_children("*", "VBoxContainer", true, false)[0]
	var linea := _etiqueta(17, Color.WHITE)
	linea.text = "%s\nGoles %d · Asistencias %d · Tiros %d (%d a puerta) · Pases %d/%d · Entradas %d/%d\nNota: %.1f   ·   Posesión %d%%" % [
		yo.nombre if yo != null else "", s["goles"], s["asist"], s["tiros"], s["a_puerta"], s["pases_ok"], s["pases"],
		s["entradas_ok"], s["entradas"], motor.nota_usuario(), motor.posesion_local() if _es_local_usuario else 100 - motor.posesion_local()]
	caja.add_child(linea)
	caja.move_child(linea, 1)

func resultado() -> Dictionary:
	var s := motor.stats
	return {"goles_local": motor.goles[0], "goles_visita": motor.goles[1], "goles": s["goles"], "asist": s["asist"],
		"nota": motor.nota_usuario(), "minutos": 90 if not motor.usuario.is_empty() else 0, "titular": true}

func _cerrar() -> void:
	terminado.emit(resultado())
	queue_free()
