extends Control
## (Parte 1 de 2 de `partido_jugable.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `partido_jugable.gd`, conserva la clase.)

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
var _camarografos: CamarografosSiguen
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

## Si empiezas en el banco, el minuto en que entras (-1 = titular).
var entra_al := -1

## El equipo del usuario cuando no es su club (la selección).
var equipo_usuario: Club = null

## LA MISMA CEREMONIA Y EL MISMO GOL QUE EL PARTIDO DEL DT (16-10-2026,
## pendiente de la Carrera de Jugador). Se reutilizan los componentes del modo
## entrenador, con los colores de este modo: `CeremoniaPartido` antes del saque
## inicial (se salta con «Saltar», cualquier tecla o botón), y en cada gol
## `CineGol` (goleador -que ya corre al córner y lo abrazan en el motor-,
## banquillo, grada, barridos y `CartaGoleador`) y la `Repeticion`, que acaba
## en el gol. Las capturas sin ceremonia la apagan con `con_ceremonia = false`.
static var con_ceremonia := true
var _en_campo: Array = []
var _ceremonia: CeremoniaPartido
var _btn_saltar: Button
var _cine: CineGol
var _repe: Repeticion
var _rotulo_repe: PanelContainer
var _hud: Array[Control] = []
## Tu ficha y la ayuda de abajo: fuera en la realización del gol (ahí sale la
## carta del goleador) y en la repetición.
var _hud_abajo: Array[Control] = []
var _simulando := false
var _rotulos_fuera := false
## La tecla que salta la ceremonia no abre además la pausa.
var _cuadro_fin_ceremonia := -1
var _tiros_de := {}
var _goles_de := {}
var _perfil := {}

## EL CAMBIO CON CARTEL Y PALMADA (20-10-2026), el mismo del partido del DT
## (`EscenaCambio`): el cuarto árbitro levanta los dorsales, el que sale camina
## a la banda y choca la mano con el que entra. Si el que entra eres tú, no se
## te retiene esperando la palmada: entras jugando.
var _sp: PlayerSpawner
var _kit_arb: Dictionary = {}

var _banner_pendiente := ""
var _t_rotulos := 0.0

# ---------------------------------------------------------------- pausa y final

var _controles: PanelControles

static func abrir(padre: Node, m: Mundo, c: CarreraJugador, l: Club, v: Club, duracion_mitad := 240.0,
		entra_al_minuto := -1, equipo: Club = null) -> PartidoJugable:
	var n := PartidoJugable.new()
	n.entra_al = entra_al_minuto
	n.equipo_usuario = equipo
	n.mundo = m
	n.carrera = c
	n.local = l
	n.visita = v
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	padre.add_child(n)
	n._montar(duracion_mitad)
	return n

func _montar_pantalla(perfil: Dictionary) -> void:
	var pantallas := _raiz.find_children("PantallaMarcador*", "MeshInstance3D", true, false)
	if pantallas.is_empty():
		return
	var pe := PantallaEstadio.new()
	add_child(pe)
	pe.montar(local, visita, null, {}, String(perfil.get("nombre", local.estadio_nombre)))
	var tex := pe.get_texture()
	for m: MeshInstance3D in pantallas:
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.emission_enabled = true
		mat.emission_texture = tex
		mat.emission_energy_multiplier = 1.1
		m.material_override = mat

## La pantalla gigante del estadio, como en `VistaEstadio._montar_pantalla`
## (sin `Partido`: rota bienvenida, tabla y goleadores).
## El once de `c` con `yo` dentro (por el peor de su línea si no estaba).
func _once_con(c: Club, yo: Jugador) -> Array[Jugador]:
	var once := c.once()
	if once.has(yo):
		return once
	var peor := -1
	for i in once.size():
		if once[i].pos == yo.pos and (peor < 0 or once[i].ovr < once[peor].ovr):
			peor = i
	if peor < 0:
		for i in once.size():
			if not once[i].es_portero() and (peor < 0 or once[i].ovr < once[peor].ovr):
				peor = i
	if peor >= 0:
		once[peor] = yo
	return once

## CAMBIOS (MEGAPLAN fase 3). En la banda espera un jugador más: tú, si
## empiezas en el banco, o el mejor suplente de tu puesto, por si el DT te saca.
func _preparar_cambio(sp: PlayerSpawner, yo: Jugador) -> void:
	if yo == null or carrera == null:
		return
	## Si ya estás en el once, eres titular: no hay entrada desde el banco.
	if entra_al >= 0 and not motor.usuario.is_empty():
		entra_al = -1
	var mi_club := equipo_usuario if equipo_usuario != null else (local if _es_local_usuario else visita)
	var kit := Puente3D.kit(local) if _es_local_usuario else Puente3D.kit_visita(local, visita)
	var quien: Jugador = yo
	if entra_al < 0:
		## Titular: el suplente de tu línea con más media.
		quien = null
		var once := _once_con(mi_club, yo) if equipo_usuario != null else mi_club.once()
		for j: Jugador in mi_club.plantilla:
			if j == yo or once.has(j) or not j.disponible() or j.es_portero():
				continue
			if quien == null or (j.pos == yo.pos) and (quien.pos != yo.pos or j.ovr > quien.ovr):
				quien = j
		if quien == null:
			return
	var una := Puente3D.once([quien] as Array[Jugador])
	var hechos := sp.spawn_team(_raiz, una["xi"], una["jugadores"], {"s": [[quien.pos_e, 50, 50]]}, _es_local_usuario, kit)
	if hechos.is_empty():
		return
	motor.exigencia_dt = carrera.exigencia_dt()
	motor.poner_extra(hechos[0], entra_al >= 0, entra_al)
	if entra_al >= 0:
		## Hasta que entras, el partido corre solo y deprisa.
		var pasos := 0
		while motor.usuario.is_empty() and motor.estado != "fin" and pasos < 20 * 1200:
			motor.paso(1.0 / 20.0)
			pasos += 1
		if not motor.usuario.is_empty():
			_banner_pendiente = "🔁 ¡ENTRAS AL CAMPO!  %d'" % motor.minuto()

func _mostrar_banner(texto: String) -> void:
	_banner.text = Idiomas.t(texto)
	_banner.modulate.a = 1.0
	_banner.scale = Vector2(1.25, 1.25)
	_banner.pivot_offset = Vector2(500, 30)
	var tw := create_tween()
	tw.tween_property(_banner, "scale", Vector2.ONE, 0.25)
	tw.tween_interval(1.4)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.5)

func _escena_cambio() -> void:
	var c: Dictionary = motor.ultimo_cambio
	var sale: Dictionary = c.get("sale", {})
	var entra: Dictionary = c.get("entra", {})
	var ns: Node3D = sale.get("node")
	if not is_instance_valid(ns) or entra.is_empty():
		return
	ns.position = c.get("pos", ns.position)
	ns.visible = true
	var e := EscenaCambio.iniciar(_raiz, _sp, motor, ns, sale.get("anim"), entra,
		int((sale.get("jugador", {}) as Dictionary).get("dorsal", 0)),
		int((entra.get("jugador", {}) as Dictionary).get("dorsal", 0)), _kit_arb)
	if e == null:
		ns.visible = false
		return
	e.borrar_al_salir = false
	if entra == motor.usuario:
		e._soltar()
		e.fase = "se_va"

func _ver_rotulos(si: bool) -> void:
	_rotulos_fuera = not si
	if motor == null:
		return
	var filas: Array = motor.jugadores.duplicate()
	if not motor.extra.is_empty():
		filas.append(motor.extra)   ## el que espera en la banda para entrar
	for f: Dictionary in filas:
		var n: Node3D = f.get("node")
		if is_instance_valid(n) and n.has_node(PlayerSpawner.ROTULO):
			(n.get_node(PlayerSpawner.ROTULO) as Node3D).visible = si and PlayerSpawner.mostrar_nombres

func _ver_hud_abajo(si: bool) -> void:
	for c: Control in _hud_abajo:
		if is_instance_valid(c):
			c.visible = si

## Las preferencias del partido son las del modo entrenador (⚙ del estadio):
## «Ceremonia» y «Repetición de los goles» valen para los dos modos.
func _pref(k: String, por_defecto: bool) -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(CajonAjustes.RUTA) != OK:
		return por_defecto
	return bool(cfg.get_value(CajonAjustes.SECCION, k, por_defecto))

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

func _fin_cine() -> void:
	_cine = null
	if is_instance_valid(_cam):
		_cam.current = true
	if motor == null or motor.estado == "fin" or not _pref("repeticiones", true) or not _repe.reproducir(6.0):
		_repe.congelar = false
		_ver_rotulos(true)
		_ver_hud_abajo(true)
		return
	## Mientras se repite, el partido espera.
	motor.set_physics_process(false)
	if _rotulo_repe == null:
		_rotulo_repe = PanelContainer.new()
		_rotulo_repe.add_theme_stylebox_override("panel", _panel(LIMA))
		var l := _etiqueta(18, FUCSIA)
		l.text = Idiomas.t("⟲  REPETICIÓN")
		_rotulo_repe.add_child(l)
		add_child(_rotulo_repe)
		_rotulo_repe.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		_rotulo_repe.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_rotulo_repe.offset_top = 70
	_rotulo_repe.visible = true
	Animar.aparecer(_rotulo_repe)

## LA REALIZACIÓN DEL GOL, la del modo entrenador (`CineGol`): el motor alarga
## la celebración (`duracion_gol`) y al final se repite la jugada.
func _cine_gol(de_local: bool, autor_id: String) -> void:
	if _raiz == null or motor == null:
		return
	if is_instance_valid(_cine):
		_cine.cortar()
	var nodo: Node3D = null
	var jd: Dictionary = {}
	for p: Dictionary in motor.jugadores:
		if String(p.get("id", "")) == autor_id and is_instance_valid(p.get("node")):
			nodo = p["node"]
			jd = p.get("jugador", {})
			break
	## La repetición debe acabar en el gol, no en la celebración.
	_repe.congelar = true
	var club_gol := local if de_local else visita
	var carta := func() -> Dictionary:
		if jd.is_empty():
			return {}
		return {"dorsal": int(jd.get("dorsal", 0)), "nombre": String(jd.get("nombre", "")),
			"tiros": int(_tiros_de.get(autor_id, 1)), "goles": int(_goles_de.get(autor_id, 1))}
	var gc := StadiumBuilder.geom_de_forma(String(_perfil.get("forma", "oval")))
	_cine = CineGol.iniciar(self, _raiz, club_gol, de_local, nodo, carta, float(gc["dx"]))
	_ver_rotulos(false)
	_ver_hud_abajo(false)
	_flecha.visible = false
	_cine.terminado.connect(_fin_cine)

func _al_gol(de_local: bool, autor: String, _asist: String) -> void:
	Mando.vibrar(1.0, 0.6)
	var yo_id := String(motor.usuario.get("id", ""))
	if autor != "" and autor == yo_id:
		_mostrar_banner("¡¡GOOOL TUYO!!")
	else:
		_mostrar_banner("¡GOL de %s!" % (Nombres.visible(local.nombre) if de_local else Nombres.visible(visita.nombre)))
	Sonido.toca("gol" if de_local == _es_local_usuario else "gol_rival", Sonido.Bus.INTERFAZ)
	## La red se abomba donde entró el balón (M-149).
	if motor.balon != null:
		RedArco.golpe(_raiz, motor.balon.global_position)
		## La grada local salta en onda desde ese fondo (M-036, como en el DT).
		if de_local and not _simulando:
			OlaGrada.lanzar(_raiz, "onda", Vector3(0, 0, signf(motor.balon.position.z) * 62.0))
	if autor != "":
		_tiros_de[autor] = int(_tiros_de.get(autor, 0)) + 1
		_goles_de[autor] = int(_goles_de.get(autor, 0)) + 1
	if not _simulando:
		_cine_gol(de_local, autor)

func _fin_repeticion() -> void:
	_repe.congelar = false
	if _rotulo_repe != null:
		_rotulo_repe.visible = false
	if is_instance_valid(_cam):
		_cam.current = true
	_ver_rotulos(true)
	_ver_hud_abajo(true)
	if motor != null and motor.estado != "fin" and _pausa == null and not _simulando:
		motor.set_physics_process(true)

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

func resultado() -> Dictionary:
	var s := motor.stats
	return {"goles_local": motor.goles[0], "goles_visita": motor.goles[1], "goles": s["goles"], "asist": s["asist"],
		"nota": motor.nota_usuario(), "minutos": int(round(motor.minutos_usuario)), "titular": entra_al < 0,
		"sustituido": motor.usuario_sustituido}

func _cerrar() -> void:
	terminado.emit(resultado())
	queue_free()

func _al_terminar() -> void:
	motor.set_physics_process(false)
	if is_instance_valid(_cine):
		_cine.cortar()
		_cine = null
		if is_instance_valid(_cam):
			_cam.current = true
	_ver_rotulos(true)
	_ver_hud_abajo(true)
	var s := motor.stats
	var yo := carrera.jugador(mundo) if carrera != null else null
	_resumen = _caja_centro("FINAL  %s %d - %d %s" % [Nombres.visible(local.nombre), motor.goles[0], motor.goles[1], Nombres.visible(visita.nombre)], [
		["Continuar", _cerrar]])
	var caja: VBoxContainer = _resumen.find_children("*", "VBoxContainer", true, false)[0]
	var linea := _etiqueta(17, Color.WHITE)
	linea.text = Idiomas.t("%s\nGoles %d · Asistencias %d · Tiros %d (%d a puerta) · Pases %d/%d · Entradas %d/%d\nNota: %.1f   ·   Posesión %d%%") % [
		yo.nombre if yo != null else "", s["goles"], s["asist"], s["tiros"], s["a_puerta"], s["pases_ok"], s["pases"],
		s["entradas_ok"], s["entradas"], motor.nota_usuario(), motor.posesion_local() if _es_local_usuario else 100 - motor.posesion_local()]
	caja.add_child(linea)
	caja.move_child(linea, 1)

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
