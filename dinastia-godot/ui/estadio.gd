class_name VistaEstadio
extends Control
## El estadio en 3D, dentro del propio juego.
##
## Hasta ahora el visor 3D era un programa aparte: el HTML exportaba un JSON, se
## abría otro proyecto de Godot y allí se veía el recinto. Aquí no hay puente ni
## fichero intermedio — el perfil lo produce el propio `Club` y la escena se
## construye en el momento.
##
## Esto es lo que Compatibility no podía dar. Corre en **Forward+**, que es lo
## único que trae oclusión ambiental, reflejos y niebla volumétrica; en
## Compatibility el estadio se ve plano y sin sombras suaves por mucho que se
## pidan. El proyecto entero está en Forward+ por esto, y la interfaz 2D se
## comporta exactamente igual (comprobado: Vulkan 1.3.237 sobre Intel UHD).

signal cerrado
## Lo pide el partido en vivo dirigido: al 45 se cierra para abrir el camarín.
var parar_en_descanso := false
var _descanso_hecho := false

var _mini_pantalla: TextureRect
var club: Club
var visitante: Club
var _raiz3d: Node3D
var _rig: CameraRig
var _pie: Label
var _pie_base := ""
var _spawner: PlayerSpawner
var _en_campo: Array = []
## Los suplentes de pie junto al banquillo (22-9-2026, "efecto banquillo").
## Aparte de `_en_campo`: `MatchPlayback.tick()` solo mueve lo que hay en esa
## lista -la banca se queda quieta donde se paró, que es lo real- y no debe
## contarse como "en el campo" en ningún sitio que lea `_en_campo.size()`.
var _en_banca: Array = []
## La pantalla gigante del estadio (23-9-2026). El `SubViewport` se mantiene
## vivo mientras dure la vista -si se libera, su textura queda en negro- y se
## repinta solo: ver `ui/pantalla_estadio.gd`, que es quien decide qué enseña
## (marcador, estadísticas, goleadores, tabla) y cuándo rota.
var _pantalla: PantallaEstadio
## Lo que esta vista NO puede calcular sola porque no conoce el `Mundo`: la
## tabla de la liga, los máximos goleadores, el nombre del torneo y el del
## recinto. Se rellena desde fuera ANTES de `abrir()` -`principal.gd` y
## `partido_vivo.gd` sí tienen el mundo delante-. Vacío es válido: la pantalla
## simplemente se queda con los paneles que salen del propio `Partido`.
var datos_pantalla: Dictionary = {}
var partido: Partido
var _juego: MatchPlayback
var _btn_velocidad: Button
var _marcador: Label
var _balon: Node3D
var _control: ControlPartido
var _radar: RadarPartido
var _btn_modo: Button
## 3D DESTACADOS (25-9-2026, plan maestro B2): el partido corre a x4 y frena a
## velocidad normal en cada ocasión -remate o gol- durante `SEG_DESTACADO`
## segundos reales, para ver la jugada. La simulación es la misma: solo cambia
## a qué velocidad se mira.
var modo_destacados := false
const VEL_DESTACADOS_RAPIDO := 4
const VEL_DESTACADOS_JUGADA := 2
const SEG_DESTACADO := 6.0
var _destacado_hasta_ms := -1
var _btn_camara: Button
var _cajon: CajonAjustes
var _vineta: ColorRect
var _perfil: Dictionary = {}
var _banner: Label
var _banner_caja: PanelContainer
var _tween_banner: Tween
var _tween_marcador: Tween
var _caja_marcador: PanelContainer

## VARIEDAD DE GRADA (21-9-2026): hasta ahora este visor solo ponia "murmullo"
## una vez al abrir y lo dejaba en bucle todo el partido -sonido de fondo fijo,
## exactamente lo que el usuario ya habia descrito como "se siente generico".
## El catalogo de `Sonido` trae cantico/tambor/trompeta/aplauso/abucheo desde
## hace tiempo, sintetizados y probados, pero nunca sonaban en un partido real.
## RNG propio, no `Azar`: es puramente cosmetico (ver feedback-verification-
## discipline en memoria) y no debe correr el generador determinista del
## resultado del partido.
var _rng_ambiente := RandomNumberGenerator.new()
var _prox_ambiente := 0.0

## EL PARTIDO, JUGADO DE VERDAD (13-10-2026). Con el motor real encendido
## (`_pref("motor_real")`, por defecto sí) ya no hay jugadas con guion: los 22
## los mueve `MotorJugable`, el resultado sale del césped y el `Partido` solo
## lleva el reloj y el acta (`motor_externo`). La pizarra y los cambios que
## hace el DT -desde el panel de pausa o desde la pantalla 2D- cambian lo que
## pasa. Y con «Controlar a mi equipo» manejas a tus jugadores como en FC.
var _motor: MotorJugable
var _mi_lado := -1
var _acum_motor := 0.0
var _t_tactica := 0.0
var _cursor: Node3D
var _indicador: IndicadorFC
var _tiros_de := {}
var _goles_de := {}
var _ayuda_control: Label
var _panel_dt: PanelDTPartido
var _panel_controles: PanelControles
## Estadísticas a pedido y rótulos de la tele (16-10-2026).
var _stats: EstadisticasVivo
var _panel_stats: PanelEstadisticas
var _rotulos_hechos := {}
## Lo que el DT rival cambia en vivo (sin tocar la táctica guardada de su club).
var _ajuste_rival := [{}, {}]
var _final_motor := false
var _anadido_avisado := {}
var _nombres_globales := true
const DT_MOTOR := 1.0 / 60.0
## Segundos reales por minuto de partido con el motor real.
const SEG_POR_MINUTO := {"rapido": 2.7, "normal": 4.0, "largo": 6.0}

## Tres modos, según lo que se le pase:
##
##   abrir(club)                      el recinto vacío, para mirarlo
##   abrir(club, occ, rival)          los 22 colocados, sin jugar
##   abrir(club, occ, rival, partido) el partido, jugándose de verdad
##
## En el tercero manda el reloj de `MatchPlayback`: cada vez que cruza un minuto,
## le pide otro minuto al `Partido`. UN solo reloj y UNA sola verdad. Si el reloj
## corriera aquí y en la pantalla 2D a la vez, el marcador que se ve y el que va a
## la tabla se separarían, que es el fallo que ya costó una depuración con el
## partido dirigido.
## `perfil_forzado`: el perfil YA calculado -normalmente `mundo.perfil_estadio_de(c)`-,
## para cuando `c` es tu propio club y por tanto su recinto es el que hayas
## diseñado en `EstadioPropio`, no el que sale del hash de su id. Sin este
## parámetro `_construir()` cae siempre en `c.perfil_estadio()` -el genérico-,
## que es lo que hacía antes de que existiera este parámetro: el visor 3D
## nunca mostraba una reforma pagada, ni en el partido en vivo ni en el botón
## de vista previa, aunque el diseñador ya la tuviera guardada.
## `colores_balon`: `[claro, oscuro]` de la piel elegida en Club → Detalles del
## club (`Comercial.color_balon()`). Vacío se queda con la piel clásica.
func abrir(c: Club, ocupacion: float = 0.8, rival: Club = null, p: Partido = null,
		perfil_forzado: Dictionary = {}, colores_balon: Array = []) -> void:
	club = c
	visitante = rival
	partido = p
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_construir(ocupacion, perfil_forzado, colores_balon)
	if partido != null:
		_arrancar_partido()

## Se da tamaño a sí misma, en vez de fiarlo a las anclas.
##
## Un Control solo hereda el rectángulo de su padre si el padre es otro Control.
## Colgada de un `Node` normal -como en las pruebas de captura- se queda en 0×0
## para siempre, y entonces cualquier ancla en fracciones apunta al mismo sitio:
## el marcador "centrado" al 0,5 acababa pegado al borde izquierdo, encima de los
## botones de cámara. Los botones sí salían bien porque van con offsets absolutos
## desde la esquina, que con tamaño cero siguen valiendo.
func _ajustar_a_pantalla() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = get_viewport().get_visible_rect().size

func _construir(ocupacion: float, perfil_forzado: Dictionary = {}, colores_balon: Array = []) -> void:
	_ajustar_a_pantalla()
	get_viewport().size_changed.connect(_ajustar_a_pantalla)

	## El 3D va DIRECTO al viewport principal, no dentro de un SubViewport.
	##
	## El primer intento lo metía en un SubViewport para poder renderizar por
	## encima de la resolución de la ventana y sacar 4K de verdad. No funcionó: un
	## SubViewport dentro de un SubViewportContainer no tiene tamaño hasta que el
	## contenedor se coloca, y con 0×0 el motor intenta crear los búferes con
	## cinco niveles de mipmap sobre una textura de un píxel. Salían decenas de
	## errores de Vulkan ("Too many mipmaps requested…", "Image is not a valid
	## texture") que parecen un fallo de la tarjeta y no lo son, y la pantalla se
	## quedaba negra. Darle un tamaño a mano tampoco bastó.
	##
	## Así que se hace como en el visor que ya funcionaba: los nodos 3D cuelgan
	## del árbol y los pinta el viewport raíz, que dibuja el 3D primero y los
	## Control encima. Por eso aquí NO hay un ColorRect de fondo: taparía el
	## estadio entero. El 4K por SubViewport se puede recuperar más adelante, pero
	## es un lujo y esto es lo que tiene que verse.
	_raiz3d = Node3D.new()
	add_child(_raiz3d)
	## Fuera de la ciudad no se sabe la hora: la gente del club está siempre.
	PersonalEstadio.hora = -1.0

	var perfil := perfil_forzado if not perfil_forzado.is_empty() else club.perfil_estadio()
	_perfil = perfil
	perfil_actual = perfil
	butaca_sancion = {}
	var aforo := int(perfil.get("aforo", 20000))

	## EL ORDEN ES EL DEL VISOR QUE YA FUNCIONABA, y las cuatro llamadas hacen
	## falta. La primera vez faltaban `aplicar_viewport` y `build_pitch`, y el
	## resultado fue un estadio con gradas, techo, focos y marcador… sobre un
	## agujero negro donde tenía que estar el campo. No hubo ni un error: `build`
	## levanta el recinto, pero el césped, las líneas y las porterías los pone
	## `build_pitch`, que es una función aparte.
	Calidad.aplicar_viewport(get_viewport(), Calidad.elegida)
	Ambience.apply(_raiz3d, perfil, null, Calidad.elegida)
	## El clima también se VE, no solo se oye (plan maestro B11).
	var gp := StadiumBuilder.geom_de_forma(String(perfil["forma"]))
	## B6.5: con el techo retráctil cerrado no llueve dentro.
	if String(perfil.get("techo", "")) != "retractil":
		Precipitacion.montar(_raiz3d, String(perfil.get("clima", "noche")), float(gp["dx"]), float(gp["dz"]), Calidad.elegida)
	## Si la máquina no llega a 40 FPS, se bajan efectos por escalones durante
	## el partido (ver `RendimientoAdaptativo`). En un renderizador por software
	## -los servidores de pruebas- no tiene sentido: ahí nunca se llegaría y las
	## capturas saldrían con la calidad rebajada.
	var adaptador := RenderingServer.get_video_adapter_name().to_lower()
	if Calidad.adaptativa and not adaptador.contains("llvmpipe") and not adaptador.contains("swiftshader"):
		var ra := RendimientoAdaptativo.new()
		ra.raiz3d = _raiz3d
		add_child(ra)
		ra.escalon_aplicado.connect(func(_e: int, que: String) -> void:
			if _pie != null:
				_pie_base += "  ·  calidad ajustada: %s" % que
				_pie.text = _pie_base)
	StadiumBuilder.build_pitch(_raiz3d, perfil, club)
	## La semilla sale del id del club: el mismo recinto siempre.
	StadiumBuilder.build(_raiz3d, perfil, aforo, ocupacion, club._hash_id(), club)
	## LA PANTALLA GIGANTE (22-9-2026, rehecha el 23-9). Ahora se monta SIEMPRE,
	## haya partido o no: sin partido enseña bienvenida + tabla + goleadores,
	## que es lo que hace la pantalla de un estadio de verdad un día entre
	## semana. Antes, sin partido, se quedaba en el degradado estático.
	_montar_pantalla()
	## EL BALÓN DE INVIERNO (29-9-2026): con nieve se juega con el naranja,
	## que se ve sobre el blanco, como en las ligas de verdad.
	if String(perfil.get("clima", "")) == "nieve":
		colores_balon = [Color("#ff7a1a"), Color("#1a1a1a"), "moderno"]
	_balon = StadiumBuilder.spawn_ball(_raiz3d, Vector3(0, 0.11, 0), colores_balon)
	## Si viene un partido sin empezar hay que prepararlo ANTES de sacar a nadie:
	## `preparar()` es quien arma los dos onces y quien mide su fuerza. Sin eso,
	## `once_local` está vacío y la fuerza cacheada es un diccionario vacío, así
	## que `simular_minuto()` revienta con "Invalid access to property 'ata'" en
	## cada uno de los noventa minutos.
	##
	## Y solo si NO ha empezado: llamarlo con el partido en marcha lo devolvería
	## al minuto cero y borraría el marcador.
	if partido != null and partido.once_local.is_empty():
		partido.preparar()
	if visitante != null:
		_sacar_los_22()

	## Las cámaras se calculan CONTRA el estadio recién construido, no se ponen
	## en posiciones fijas: un recinto de 8.000 butacas y uno de 90.000 necesitan
	## encuadres distintos, y con posiciones fijas la cámara acaba dentro de una
	## tribuna. Eso ya pasó en el visor aparte — pantalla en verde sólido y ni un
	## error en consola.
	var g := StadiumBuilder.geom_de_forma(String(perfil["forma"]))
	var alto := StadiumBuilder.altura_de(perfil, aforo)
	_rig = CameraRig.new()
	_raiz3d.add_child(_rig)
	_rig.build_for(g["dx"], g["dz"], alto)
	_rig.balon_ref = _balon
	## SANCIONADO (estadio 2.0): el partido, desde tu butaca de la grada.
	if partido != null and PersonajeDT.sancionado and not butaca_sancion.is_empty():
		var ojo: Vector3 = (butaca_sancion["pos"] as Vector3) + Vector3(0, 1.2, 0)
		_rig._add("Desde la grada (sancionado)", ojo + Vector3(0.6, 0.3, 0), Vector3(0, 0, ojo.z * 0.3), 62)
		_rig.switch_to(_rig.cameras.size() - 1)

	## Viñeta de transmisión (22-9-2026, comparando contra el look de cámara de
	## Open-Soccer): un oscurecido 2D encima del 3D, no un efecto de Environment
	## -Godot 4 no trae viñeta nativa ahí-. Va ANTES del radar/barra/pie en el
	## árbol para quedar DEBAJO de ellos (los Control últimos en añadirse se
	## dibujan encima): la viñeta oscurece justo las esquinas donde vive el HUD,
	## y si se dibujara arriba le restaría legibilidad al marcador y los botones.
	_vineta = ColorRect.new()
	_vineta.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vineta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vineta.material = ShaderMaterial.new()
	_vineta.material.shader = load("res://visor/vineta.gdshader")
	_vineta.visible = _pref("vineta", true)
	add_child(_vineta)

	# Radar táctico 2D en esquina inferior derecha
	_radar = RadarPartido.new()
	_radar.anchor_left = 1.0; _radar.anchor_right = 1.0; _radar.anchor_top = 1.0; _radar.anchor_bottom = 1.0
	_radar.offset_left = -226; _radar.offset_right = -16; _radar.offset_top = -178; _radar.offset_bottom = -42
	_radar.visible = _pref("radar", true)
	add_child(_radar)

	## LA PANTALLA GIGANTE, EN LA ESQUINA (26-9-2026). La del estadio rota
	## marcador, tabla y goleadores, pero desde la cámara de transmisión es una
	## mota al fondo del estadio: nadie la leía. Aquí se ve la MISMA textura,
	## en vivo, arriba a la derecha. Se apaga desde el cajón.
	_mini_pantalla = TextureRect.new()
	_mini_pantalla.anchor_left = 1.0; _mini_pantalla.anchor_right = 1.0
	_mini_pantalla.offset_left = -348; _mini_pantalla.offset_right = -16
	_mini_pantalla.offset_top = 64; _mini_pantalla.offset_bottom = 64 + 177
	_mini_pantalla.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mini_pantalla.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_mini_pantalla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mini_pantalla.visible = false
	add_child(_mini_pantalla)
	## La pantalla se monta antes que el HUD: aquí ya puede existir.
	if _pantalla != null:
		_mini_pantalla.texture = _pantalla.get_texture()
		_mini_pantalla.visible = _pref("pantalla_esquina", true)

	## AJUSTES EN UN CAJÓN (25-9-2026, plan maestro B1). Antes siete botones
	## vivían encima de la transmisión (cámara, zoom ±, modo, velocidad, nombres,
	## volver); el usuario pidió que no estuvieran todos a la vista. Ahora en
	## pantalla quedan el marcador, "Volver" y el ⚙, y el resto entra desde la
	## derecha al pulsarlo (`CajonAjustes`).
	_cajon = CajonAjustes.crear(self, "partido3d")
	var volver := Button.new()
	volver.text = Idiomas.t("Volver")
	volver.focus_mode = Control.FOCUS_NONE
	add_child(volver)
	volver.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	volver.offset_left = -150
	volver.offset_right = -66
	volver.offset_top = 14
	volver.offset_bottom = 54
	volver.pressed.connect(func() -> void: cerrado.emit())

	_cajon.seccion("Transmisión")
	_btn_camara = _cajon.boton("📷 Cámara: " + (_rig.current_name() if _rig != null else "TV"), _rotar_camara)
	_cajon.fila([["🔍 Acercar", func() -> void: if _rig: _rig.ajustar_zoom(-3.0)],
		["🔍 Alejar", func() -> void: if _rig: _rig.ajustar_zoom(3.0)]])
	_cajon.boton("📸 Modo foto", func() -> void: ModoFoto.abrir(self, club, "el estadio"))
	## RECORRER EL ESTADIO A PIE (7-10-2026): del vestuario, por el túnel, a la
	## cancha. Solo sin partido en marcha.
	if partido == null:
		_cajon.boton("🚶 Recorrer el estadio (vestuario y túnel)", recorrer)
	if partido != null:
		_cajon.seccion("Partido")
		_btn_modo = _cajon.boton("🎮 Controlar a mi equipo: NO", _alternar_modo_control)
		_cajon.boton("📋 Táctica y cambios (Esc)", _abrir_panel_dt)
		_cajon.boton("🎮 Controles: teclas, mando y ayudas", abrir_controles)
		_cajon.interruptor("⚽ Motor real: el resultado se juega en el césped", _pref("motor_real", true), func(si: bool) -> void:
			_guardar_pref("motor_real", si))
		_cajon.fila([["⏩ Partido corto", func() -> void: _fijar_ritmo("rapido")],
			["⏯ Normal", func() -> void: _fijar_ritmo("normal")],
			["🐢 Largo (FC)", func() -> void: _fijar_ritmo("largo")]])
		_btn_velocidad = _cajon.boton("⏱", _ciclar_velocidad)
		## SIMULAR EL RESTO (28-9-2026, informe externo: "falta el botón de
		## simular el partido entero"). Existía en la pantalla de texto, que
		## queda oculta mientras se ve el 3D. Juega todos los minutos que
		## faltan -descanso incluido- y vuelve al resumen.
		_cajon.boton("⏭ Simular hasta el final", func() -> void:
			if _motor != null:
				_simular_resto_motor()
				return
			_descanso_hecho = true
			while not partido.terminado_ya:
				partido.simular_minuto()
			cerrado.emit())
	_cajon.seccion("En pantalla")
	_cajon.interruptor("🏷 Nombres de los jugadores", PlayerSpawner.mostrar_nombres, _mostrar_nombres)
	_cajon.interruptor("📺 Pantalla del estadio en la esquina", _pref("pantalla_esquina", true), func(si: bool) -> void:
		_guardar_pref("pantalla_esquina", si)
		_mini_pantalla.visible = si and _mini_pantalla.texture != null)
	_cajon.interruptor("🗺 Radar táctico", _radar.visible, func(si: bool) -> void:
		_radar.visible = si
		_guardar_pref("radar", si))
	_cajon.interruptor("📺 Rótulos de las jugadas", _pref("rotulos", true), func(si: bool) -> void:
		_guardar_pref("rotulos", si)
		if _rotulo_jugada != null and not si:
			_rotulo_jugada.modulate.a = 0.0)
	_cajon.interruptor("🎞 Viñeta de transmisión", _vineta.visible, func(si: bool) -> void:
		_vineta.visible = si
		_guardar_pref("vineta", si))
	_cajon.interruptor("ℹ Ficha del estadio abajo", _pref("pie", false), func(si: bool) -> void:
		_pie.visible = si
		_guardar_pref("pie", si))
	_cajon.interruptor("🎬 Presentación antes del partido", _pref("intro", true), func(si: bool) -> void:
		_guardar_pref("intro", si))
	_cajon.interruptor("🧒 Ceremonia completa (niños, mascota, alineaciones)", _pref("ceremonia", true), func(si: bool) -> void:
		_guardar_pref("ceremonia", si))
	_cajon.interruptor("🔁 Repetición de los goles", _pref("repeticiones", true), func(si: bool) -> void:
		_guardar_pref("repeticiones", si))
	_cajon.interruptor("⚡ Calidad automática", Calidad.adaptativa, func(si: bool) -> void:
		Calidad.adaptativa = si)
	_cajon.seccion("Sonido")
	_cajon.deslizador("Grada y ambiente", float(Sonido.volumen.get(Sonido.Bus.AMBIENTE, 0.5)), func(v: float) -> void:
		Sonido.volumen[Sonido.Bus.AMBIENTE] = v)
	_cajon.deslizador("Efectos (balón, silbato)", float(Sonido.volumen.get(Sonido.Bus.EFECTOS, 0.8)), func(v: float) -> void:
		Sonido.volumen[Sonido.Bus.EFECTOS] = v)
	_cajon.deslizador("Música", Musica.volumen, func(v: float) -> void:
		Musica.volumen = v
		Musica.aplicar_volumen())

	_pie = Label.new()
	_pie.add_theme_font_size_override("font_size", 13)
	_pie.add_theme_color_override("font_color", Color("e9eeea"))
	_pie.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_pie.offset_left = 18
	_pie.offset_bottom = -14
	_pie.offset_top = -34
	_pie.visible = _pref("pie", false)
	add_child(_pie)
	_actualizar_pie(perfil, aforo, ocupacion)

var _explorador: ExploradorEstadio
var _ocultos: Array = []

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

func _dejar_de_recorrer() -> void:
	if _explorador == null:
		return
	_explorador.queue_free()
	_explorador = null
	for c in _ocultos:
		if is_instance_valid(c):
			(c as CanvasItem).visible = true
	_ocultos = []
	if _rig != null:
		_rig.set_process(true)
		_rig.set_process_unhandled_input(true)
		_rig.switch_to(_rig.current_index)

## `fixed_size` compensa la DISTANCIA, no el zoom: con "Tele Dinámica" (campo
## de visión estrecho) los nombres salían tres veces más grandes que con la de
## TV. Se reescalan con la tangente del campo de visión de la cámara activa,
## tomando la de TV (46°) como referencia. Solo cuando cambia el campo de visión.
var _fov_rotulos := -1.0

func _escalar_rotulos() -> void:
	if not PlayerSpawner.mostrar_nombres:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null or is_equal_approx(cam.fov, _fov_rotulos):
		return
	_fov_rotulos = cam.fov
	var tam := PlayerSpawner.TAM_ROTULO * tan(deg_to_rad(cam.fov) * 0.5) / tan(deg_to_rad(46.0) * 0.5)
	for f: Dictionary in _en_campo:
		var n: Node3D = f.get("node")
		if is_instance_valid(n) and n.has_node(PlayerSpawner.ROTULO):
			var rot := n.get_node(PlayerSpawner.ROTULO) as Label3D
			rot.pixel_size = tam
			if rot.has_node(PlayerSpawner.BARRA):
				rot.get_node(PlayerSpawner.BARRA).set("pixel_size", tam)

## RÓTULOS SIN AMONTONAR (MEGAPLAN fase 1): en las jugadas de área los
## nombres se pisaban. Cada décima de segundo se proyectan a la pantalla y, si
## dos se tocan, queda el del jugador más cerca del balón. El que ya se veía
## tiene ventaja (si no, parpadeaban al cruzarse dos jugadores).
var _t_despeje := 0.0

func _despejar_rotulos(delta: float) -> void:
	if not PlayerSpawner.mostrar_nombres:
		return
	_t_despeje -= delta
	if _t_despeje > 0.0:
		return
	_t_despeje = 0.1
	var bpos := _balon.global_position if is_instance_valid(_balon) else Vector3.ZERO
	PlayerSpawner.despejar_rotulos(_en_campo, get_viewport().get_camera_3d(), bpos, get_viewport().get_visible_rect().size.y)

## La energía bajo cada nombre, una vez por minuto simulado.
var _minuto_barras := -1

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

func _energia_motor(f: Dictionary) -> float:
	if _motor == null:
		return -1.0
	var id := String(f.get("id", ""))
	for p: Dictionary in _motor.jugadores:
		if p.get("node") == f.get("node") or (id != "" and String(p.get("id", "")) == id):
			return _motor.forma_fisica(p)
	return -1.0

func _mostrar_nombres(si: bool) -> void:
	PlayerSpawner.mostrar_nombres = si
	_fov_rotulos = -1.0
	for f: Dictionary in _en_campo:
		var n: Node3D = f.get("node")
		if is_instance_valid(n) and n.has_node(PlayerSpawner.ROTULO):
			(n.get_node(PlayerSpawner.ROTULO) as Node3D).visible = si

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

## 47000 -> "47.000", como se escribe en español.
func _miles(n: int) -> String:
	var t := str(n)
	var out := ""
	while t.length() > 3:
		out = "." + t.substr(t.length() - 3) + out
		t = t.substr(0, t.length() - 3)
	return t + out

## Preferencias de lo que se ve sobre la transmisión, en el mismo archivo que
## el resto de ajustes (`user://ajustes.cfg`, sección `hud`).
func _pref(k: String, por_defecto: bool) -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(CajonAjustes.RUTA) != OK:
		return por_defecto
	return bool(cfg.get_value(CajonAjustes.SECCION, k, por_defecto))

func _guardar_pref(k: String, v: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, k, v)
	cfg.save(CajonAjustes.RUTA)

func _rotar_camara() -> void:
	if _rig != null:
		_rig.cycle()
		if _btn_camara != null:
			_btn_camara.text = Idiomas.t("📷 Cámara: ") + _rig.current_name()
		if _pie != null:
			_pie.text = _pie_base + Idiomas.t("  ·  cámara: ") + _rig.current_name()

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

## Saca a los 22 al campo, cada uno en su ranura de la formación y con la
## equipación de su club.
##
## Los datos van por `Puente3D`, que traduce mis objetos `Jugador` y `Club` a los
## diccionarios que espera el equipador. Ese código viene del visor que era un
## programa aparte y ya está depurado -el atlas de texturas, el re-teñido, el
## escalado del esqueleto Mixamo-, así que se adapta en la frontera en vez de
## reescribirlo.
func _sacar_los_22() -> void:
	_spawner = PlayerSpawner.new()
	_en_campo.clear()
	## Si hay partido, salen los onces DEL PARTIDO, no los que devolvería el club
	## ahora mismo. No son lo mismo en cuanto entra el primer cambio: `club.once()`
	## volvería a armar el equipo desde cero y en el campo aparecería el titular
	## que acaba de salir.
	var once_local := partido.once_local if partido != null else club.once()
	var once_visita := partido.once_visita if partido != null else visitante.once()
	var l := Puente3D.once(once_local)
	var v := Puente3D.once(once_visita)
	## El local ataca hacia un lado y el visitante hacia el otro: `spawn_team` lo
	## resuelve con `es_local`, que además le da la vuelta al jugador.
	_en_campo.append_array(_spawner.spawn_team(_raiz3d, l["xi"], l["jugadores"],
		Puente3D.formacion(club.tactica.formacion), true,
		Puente3D.kit(club), Puente3D.kit_portero(club)))
	_en_campo.append_array(_spawner.spawn_team(_raiz3d, v["xi"], v["jugadores"],
		Puente3D.formacion(visitante.tactica.formacion), false,
		Puente3D.kit_visita(club, visitante), Puente3D.kit_portero(visitante)))
	_en_campo.append_array(_spawner.spawn_arbitros(_raiz3d))
	_poner_banca(once_local, once_visita)
	_poner_personal()
	_purgar_nodos_fantasma()

## LA BANDA YA NO ESTÁ VACÍA (22-9-2026). Hasta hoy solo se veían los 22 +
## árbitros: ni un suplente, aunque el club tenga 20+ jugadores citables. La
## "banca visual" es una muestra -los mejores disponibles que no están en el
## once, hasta 7-, no la lista real de quién puede entrar (`Partido.cambiar()`
## acepta cualquier jugador disponible de la plantilla entera, no solo estos
## 7): esto es solo lo que se VE de pie junto al banquillo, no una regla
## nueva de convocatoria.
func _poner_banca(once_local: Array[Jugador], once_visita: Array[Jugador]) -> void:
	_en_banca.clear()
	if club == null or visitante == null:
		return
	_poner_banca_de(club, once_local, true)
	_poner_banca_de(visitante, once_visita, false)

## Los primeros 7 disponibles, de pie; del 8 al 12, sentados en el banco
## simple de al lado (22-9-2026, "que los que no caben estén sentados").
func _poner_banca_de(c: Club, once_c: Array[Jugador], es_local: bool) -> void:
	_en_banca.append_array(VistaEstadio.poner_banca_de(_raiz3d, _spawner, c, once_c, es_local))

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

## EL ENTRENADOR EN LA BANDA (26-9-2026): tu personaje del creador en el
## área técnica de tu club, y un DT rival (siempre el mismo por club) en la
## otra. Delante de su fila de suplentes, del lado del centro del campo.
## CAMARÓGRAFOS Y GUARDIAS DE VERDAD (26-9-2026). El constructor deja a cada
## operador como un maniquí de cajas con su cámara; aquí se oculta el maniquí
## y se pone una persona entera detrás de la cámara. Y seis guardias de
## seguridad detrás de las vallas, de espaldas al juego, mirando a la grada.
func _poner_personal() -> void:
	var sig := VistaEstadio.poner_personal(_raiz3d)
	if sig != null:
		sig.balon = _balon

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

## Dónde se sienta el DT sancionado: la grada de los banquillos, a la altura
## de su banquillo (estadio 2.0, fase 3).
static var butaca_sancion: Dictionary = {}
## El perfil del estadio que se está montando (para la butaca del sancionado).
static var perfil_actual: Dictionary = {}

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
			var ap: AnimationPlayer = d.get("anim") as AnimationPlayer
			if ap != null and ap.has_animation("sentado"):
				ap.play("sentado")
			## Su butaca y las de al lado, libres de hinchas.
			RecorridoClub.despejar_hinchas(_raiz3d, _raiz3d.global_position + (butaca_sancion["pos"] as Vector3) + Vector3(0, 0.5, 0), 1.6)
		return
	PersonajeDT.poner_en_banda(_raiz3d, asp, Color(c.color1), Color(c.color2), Vector3(34.6, 0, z), -PI * 0.5)

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

## LA PANTALLA GIGANTE. Busca las mallas que `StadiumBuilder._pantallas()` dejó
## marcadas como "PantallaMarcador" -puede haber una, dos (tipo "dos") o hasta
## tres ("todo", con el cubo suspendido)- y les reemplaza la textura estática
## por la del `SubViewport` de `PantallaEstadio`. Un solo `SubViewport` para
## todas: las dos/tres muestran lo mismo, como en un estadio real.
##
## REHECHA EL 23-9-2026 con el video de referencia del usuario delante. Antes
## era un `Label` "0 - 0" más el nombre completo de los clubes, que se salía
## del lienzo (bug documentado en `LEEME.md`). Ahora todo el diseño y la
## rotación de paneles viven en `ui/pantalla_estadio.gd`; aquí solo queda
## engancharla al 3D y darle los datos.
func _montar_pantalla() -> void:
	var pantallas := _raiz3d.find_children("PantallaMarcador*", "MeshInstance3D", true, false)
	if pantallas.is_empty() or club == null:
		return
	_pantalla = PantallaEstadio.new()
	add_child(_pantalla)
	var recinto := String(datos_pantalla.get("recinto", ""))
	if recinto == "":
		recinto = club.estadio_nombre
	_pantalla.montar(club, visitante, partido, datos_pantalla, recinto)

	var tex := _pantalla.get_texture()
	if _mini_pantalla != null:
		_mini_pantalla.texture = tex
		_mini_pantalla.visible = _pref("pantalla_esquina", true)
	for p: MeshInstance3D in pantallas:
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.emission_enabled = true
		mat.emission_texture = tex
		## Mismo brillo que ya se ajustó el 22-9 contra el bloom del
		## post-procesado: más alto quema el contenido, más bajo no se lee
		## "encendida" desde la cancha.
		mat.emission_energy_multiplier = 1.1
		p.material_override = mat

## Documento de arquitectura: maniquíes residuales en (0,0,0) se leían como
## "el gigante" en el centro del campo. No se toca a los 22 ni al balón.
func _purgar_nodos_fantasma() -> void:
	if _raiz3d == null:
		return
	var vivos: Dictionary = {}
	for p in _en_campo:
		var n = p.get("node")
		if is_instance_valid(n):
			vivos[n] = true
	for nodo in _raiz3d.get_children():
		if nodo == _balon or nodo == _rig:
			continue
		if vivos.has(nodo):
			continue
		if nodo is CharacterBody3D and nodo.global_position.length() < 0.35:
			push_warning("[LIMPIEZA] Eliminado nodo fantasma residual: %s" % nodo.name)
			nodo.queue_free()
		elif nodo is MeshInstance3D and String(nodo.name).to_lower().contains("dummy"):
			nodo.queue_free()

# --- el partido, jugándose -------------------------------------------------

func _arrancar_partido() -> void:
	_juego = MatchPlayback.new()
	## La posesión estimada sale de la fuerza de los dos onces, que es la que ya
	## decide los goles. Así lo que se ve en el campo -quién ataca más- cuadra
	## con lo que dice el marcador, en vez de ser un adorno aparte.
	var fl: float = partido.fuerza(partido.once_local, partido.local)["ata"]
	var fv: float = partido.fuerza(partido.once_visita, partido.visita)["ata"]
	var pos := 100.0 * fl / maxf(fl + fv, 0.001)
	_juego.setup([], _en_campo, Partido.MINUTOS, pos, _balon, club.tactica, visitante.tactica)
	## EL RELOJ EMPIEZA DONDE VA EL PARTIDO (28-9-2026). Al reabrir el 3D a
	## mitad de partido -tras el descanso, o con "Volver" y "Ver en 3D"- la
	## reproducción arrancaba en el 0' con el partido ya en el 45': durante
	## 45 minutos de reloj no se simulaba nada y parecía colgado ("después de
	## la charla del medio tiempo no deja continuar").
	_juego.elapsed = float(partido.minuto) * _juego.seconds_per_minute
	_descanso_hecho = partido.minuto >= 45
	## La cámara del árbitro sigue su cabeza.
	var arb: Variant = _juego.players_by_id.get("arbitro")
	if arb is Dictionary and _rig != null:
		_rig.arbitro_ref = (arb as Dictionary).get("node")
	## La sala VAR, cuando el árbitro pide revisar.
	_juego.revision_var.connect(_a_la_revision_var)
	## La repetición del gol (plan maestro B3): graba siempre los últimos
	## segundos de los 22 y del balón.
	_repe = Repeticion.new()
	add_child(_repe)
	_repe.setup(_en_campo, _balon)
	_repe.terminada.connect(func() -> void:
		if _rotulo_repe != null:
			_rotulo_repe.visible = false)
	_juego.jugada_ambiente.connect(_al_jugada_ambiente)
	if _btn_velocidad != null:
		_btn_velocidad.text = "⏱ " + _juego.etiqueta_velocidad()
	partido.gol.connect(_al_gol)
	partido.gol.connect(func(_c: Club, _a: Jugador, _m: int, _as: Jugador) -> void: _frenar_destacado())
	partido.remate.connect(func(_c: Club, _a: Jugador, _t: String, _m: int) -> void: _frenar_destacado())
	partido.invasion_de_campo.connect(func(_m: int) -> void:
		_mostrar_banner_gol("🚨 INVASIÓN DE CAMPO", false))
	if modo_destacados:
		_juego.vel_idx = VEL_DESTACADOS_RAPIDO
		if _btn_velocidad != null:
			_btn_velocidad.text = "⏱ " + _juego.etiqueta_velocidad()
	partido.tarjeta.connect(_a_la_tarjeta)
	partido.cambio_hecho.connect(_al_cambio)
	partido.remate.connect(_al_remate)
	## Tiros y goles de cada uno, para la carta del goleador.
	partido.remate.connect(func(_c: Club, a: Jugador, _t: String, _m: int) -> void:
		if a != null:
			_tiros_de[a.id] = int(_tiros_de.get(a.id, 0)) + 1)
	partido.gol.connect(func(_c: Club, a: Jugador, _m: int, _as: Jugador) -> void:
		if a != null:
			_tiros_de[a.id] = int(_tiros_de.get(a.id, 0)) + 1
			_goles_de[a.id] = int(_goles_de.get(a.id, 0)) + 1)
	partido.lesion.connect(_a_la_lesion)
	partido.decision_arbitral.connect(_a_la_decision_arbitral)
	## Saque inicial + murmullo de fondo: lo mismo que ya sonaba en la pantalla
	## 2D de `partido_vivo.gd`, que hasta hoy este visor 3D -el que de verdad se
	## juega- nunca reproducía.
	Sonido.toca("saque_inicial")
	Sonido.toca("murmullo", Sonido.Bus.AMBIENTE)
	## SONIDOS QUE EXISTÍAN Y NUNCA SONABAN (25-9-2026): de los 205 del
	## catálogo, 157 no tenían ningún disparador. Aquí los del partido: la
	## salida del túnel, el ambiente según el clima del estadio, los tiempos
	## del reloj y los goles especiales.
	if partido.minuto == 0:
		Sonido.toca("salida_tunel", Sonido.Bus.AMBIENTE)
	## La presentación: vuelo de cámara con el rótulo del partido (B3).
	if _pref("intro", true) and partido.minuto == 0:
		var gi := StadiumBuilder.geom_de_forma(String(_perfil.get("forma", "oval")))
		var nombre_est := club.estadio_nombre if club.estadio_nombre != "" else "Estadio de %s" % club.nombre
		## LA CEREMONIA (13-10-2026): salida con niños, mascota, lona y
		## alineaciones. Con el ajuste «ceremonia» apagado, el vuelo corto.
		if _pref("ceremonia", true):
			## Se monta al final de `_arrancar_partido`, cuando el motor ya colocó
			## a todos para el saque (si no, los recolocaba encima).
			_ceremonia_pendiente = nombre_est
		else:
			_intro = IntroPartido.iniciar(self, float(gi["dx"]), float(gi["dz"]), 20.0,
				"%s  vs  %s" % [club.nombre, visitante.nombre],
				"%s  ·  %s butacas" % [nombre_est, _miles(club.estadio_aforo)])
	var clima := String(_perfil.get("clima", "noche"))
	var por_clima := {"lluvia": "lluvia_ambiente", "tormenta": "trueno", "niebla": "niebla_ambiente",
		"nieve": "frio_extremo", "noche": "noche_estadio", "dia": "dia_soleado", "tarde": "eco_estadio"}
	if por_clima.has(clima):
		Sonido.toca(String(por_clima[clima]), Sonido.Bus.AMBIENTE)
	partido.minuto_jugado.connect(_al_minuto_sonoro)
	## Semilla fija por partido (mismo criterio que `_rng` en MatchPlayback):
	## repetible si se reabre el mismo partido, pero sin tocar `Azar`.
	_rng_ambiente.seed = hash("ambiente") + partido.local.id.hash() + partido.visita.id.hash()
	_prox_ambiente = _juego.elapsed + _rng_ambiente.randf_range(10.0, 18.0)

	if _pref("motor_real", true):
		_montar_motor()
	else:
		# Control interactivo de jugador (Modo FC 26), con las jugadas con guion
		_control = ControlPartido.new()
		add_child(_control)
		var es_local_user: bool = (partido.local == club)
		_control.setup(_en_campo, _balon, _rig, es_local_user, _juego, _radar)


	var caja := PanelContainer.new()
	var e := StyleBoxFlat.new()
	e.bg_color = Color(0, 0, 0, 0.55)
	e.set_corner_radius_all(8)
	e.content_margin_left = 14; e.content_margin_right = 14
	e.content_margin_top = 6; e.content_margin_bottom = 6
	caja.add_theme_stylebox_override("panel", e)
	## Anclas a mano, sin preset.
	##
	## Con `position` el marcador se iba al borde izquierdo, y con
	## `set_anchors_preset(..., keep_offsets)` tampoco: ese `keep_offsets`
	## RECALCULA los offsets para conservar el rectángulo actual, así que pisa lo
	## que se le ponga justo después. Puestas las cuatro anclas y los cuatro
	## offsets a mano no hay ambigüedad. Desde el 25-9 va arriba a la izquierda
	## (la barra de botones pasó a la derecha), con 380 px de ancho.
	caja.anchor_left = 0.0
	caja.anchor_right = 0.0
	caja.anchor_top = 0.0
	caja.anchor_bottom = 0.0
	caja.offset_left = 18
	caja.offset_right = 398
	caja.offset_top = 12
	caja.offset_bottom = 54
	add_child(caja)
	_caja_marcador = caja
	## El pivote tiene que quedar al centro del panel para que el "salto" del
	## gol (escalar en `_animar_marcador_gol()`) crezca parejo a los dos lados,
	## no que se vaya de bruces hacia una esquina.
	caja.pivot_offset = Vector2(190, 21)
	_marcador = Label.new()
	_marcador.add_theme_font_size_override("font_size", 20)
	_marcador.add_theme_color_override("font_color", Color("e9eeea"))
	_marcador.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(_marcador)
	_refrescar_marcador()

	_crear_banner_gol()
	_crear_rotulo_jugada()
	if _ceremonia_pendiente != "":
		var gc := StadiumBuilder.geom_de_forma(String(_perfil.get("forma", "oval")))
		_ceremonia = CeremoniaPartido.iniciar(self, _raiz3d, _en_campo, partido.local, partido.visita, _ceremonia_pendiente,
			float(gc["dx"]), float(gc["dz"]), StadiumBuilder.tunel_x(_perfil))
		_ceremonia_pendiente = ""
		## La pantalla limpia mientras dura: sin marcador, radar ni nombres.
		var ocultos: Array = []
		for c: Control in [_caja_marcador, _mini_pantalla, _radar]:
			if c != null and c.visible:
				c.visible = false
				ocultos.append(c)
		var nombres_antes := PlayerSpawner.mostrar_nombres
		_mostrar_nombres(false)
		_ceremonia.terminada.connect(func() -> void:
			for c: Control in ocultos:
				if is_instance_valid(c):
					c.visible = true
			_mostrar_nombres(nombres_antes))

## EL RÓTULO DE LA JUGADA (25-9-2026): como en la tele, cuando un equipo
## construye una jugada del catálogo aparece su nombre debajo del marcador
## ("▸ PARED FRONTAL 1-2"), con el color del equipo, y se va solo.
var _rotulo_jugada: PanelContainer
var _lbl_jugada: Label
var _tween_jugada: Tween

func _crear_rotulo_jugada() -> void:
	_rotulo_jugada = PanelContainer.new()
	var e := StyleBoxFlat.new()
	e.bg_color = Color(0, 0, 0, 0.62)
	e.border_width_left = 4
	e.border_color = Color("c9a227")
	e.set_corner_radius_all(4)
	e.content_margin_left = 12; e.content_margin_right = 14
	e.content_margin_top = 4; e.content_margin_bottom = 4
	_rotulo_jugada.add_theme_stylebox_override("panel", e)
	_rotulo_jugada.anchor_left = 0.0
	_rotulo_jugada.anchor_right = 0.0
	_rotulo_jugada.offset_left = 18
	_rotulo_jugada.offset_top = 60
	_rotulo_jugada.modulate.a = 0.0
	_rotulo_jugada.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rotulo_jugada)
	_lbl_jugada = Label.new()
	_lbl_jugada.add_theme_font_size_override("font_size", 14)
	_lbl_jugada.add_theme_color_override("font_color", Color("e9eeea"))
	_rotulo_jugada.add_child(_lbl_jugada)

func _al_jugada_ambiente(nombre: String, es_local: bool) -> void:
	if _rotulo_jugada == null or not _pref("rotulos", true):
		return
	var equipo: Club = club if es_local else visitante
	(_rotulo_jugada.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Color(equipo.color1) if equipo != null else Color("c9a227")
	_lbl_jugada.text = "▸ %s  ·  %s" % [nombre.to_upper(), equipo.nombre if equipo != null else ""]
	if _tween_jugada != null and _tween_jugada.is_valid():
		_tween_jugada.kill()
	_tween_jugada = create_tween()
	_tween_jugada.tween_property(_rotulo_jugada, "modulate:a", 1.0, 0.25)
	_tween_jugada.tween_interval(3.2)
	_tween_jugada.tween_property(_rotulo_jugada, "modulate:a", 0.0, 0.6)

## Sonidos de grada sin evento puntual detras -el "ruido de fondo con vida"
## que faltaba-. Uno por bloque para no repetir siempre el mismo: percusion,
## instrumento suelto y reaccion humana (canto/aplauso/abucheo, este ultimo
## mas probable si el visitante ataca, nunca si el propio equipo va ganando
## comodo -no tiene sentido que la propia hinchada abuchee sin motivo).
const AMBIENTE_PERCUSION := ["tambor", "trompeta", "bengala"]
const AMBIENTE_REACCION := ["cantico", "aplauso"]

func _tocar_ambiente() -> void:
	var r := _rng_ambiente.randf()
	if r < 0.35:
		Sonido.toca(AMBIENTE_PERCUSION[_rng_ambiente.randi_range(0, AMBIENTE_PERCUSION.size() - 1)], Sonido.Bus.AMBIENTE)
	elif r < 0.8 or partido.goles_local >= partido.goles_visita:
		Sonido.toca(AMBIENTE_REACCION[_rng_ambiente.randi_range(0, AMBIENTE_REACCION.size() - 1)], Sonido.Bus.AMBIENTE)
	else:
		Sonido.toca("abucheo", Sonido.Bus.AMBIENTE)

func _frenar_destacado() -> void:
	if not modo_destacados or _juego == null or _juego.vel_idx == 0:
		return
	_juego.vel_idx = VEL_DESTACADOS_JUGADA
	_destacado_hasta_ms = Time.get_ticks_msec() + int(SEG_DESTACADO * 1000.0)
	if _btn_velocidad != null:
		_btn_velocidad.text = "⏱ " + _juego.etiqueta_velocidad()

func _process(delta: float) -> void:
	StadiumBuilder.ocultar_techo_ante(get_viewport().get_camera_3d())
	_escalar_rotulos()
	_despejar_rotulos(delta)
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


func _refrescar_marcador() -> void:
	if _marcador == null:
		return
	if _motor != null:
		## El reloj de la transmisión: 45' +2 en el añadido, y el cartel del
		## cuarto árbitro cuando empieza.
		var seg := _motor.segundos_anadidos()
		var reloj := "%d'" % _motor.minuto()
		if seg >= 0.0:
			reloj = "%d' +%d:%02d" % [45 if _motor.mitad == 1 else 90, int(seg) / 60, int(seg) % 60]
			if not _anadido_avisado.has(_motor.mitad):
				_anadido_avisado[_motor.mitad] = true
				_mostrar_rotulo_suceso("⏱ %s: +%d" % [Idiomas.t("Tiempo añadido"), _motor.minutos_anadidos()])
				Sonido.toca("descuento_anunciado")
		_marcador.text = "%s  %d - %d  %s      %s" % [_corto(partido.local.nombre), partido.goles_local,
			partido.goles_visita, _corto(partido.visita.nombre), reloj]
		return
	_marcador.text = "%s  %d - %d  %s      %d'" % [
		_corto(partido.local.nombre), partido.goles_local,
		partido.goles_visita, _corto(partido.visita.nombre),
		partido.minuto]

## Cartel de gol, abajo al centro -pensado para pantalla horizontal, la misma
## orientación en la que se juega esta vista-. Empieza invisible y fuera de la
## pantalla (offset vertical positivo, `clip_contents` del padre no hace
## falta porque el Control raíz ya mide toda la pantalla): `_mostrar_banner_gol()`
## lo trae, lo sostiene y lo despide, todo con el mismo Tween para que un
## segundo gol a los dos segundos del primero no dispare una animación a medias
## sobre otra.
func _crear_banner_gol() -> void:
	_banner_caja = PanelContainer.new()
	var e := StyleBoxFlat.new()
	e.bg_color = Color(0.10, 0.62, 0.34, 0.92)
	e.set_corner_radius_all(10)
	e.content_margin_left = 26; e.content_margin_right = 26
	e.content_margin_top = 10; e.content_margin_bottom = 10
	e.border_width_top = 3
	e.border_color = Color(0.93, 0.85, 0.35)
	_banner_caja.add_theme_stylebox_override("panel", e)
	_banner_caja.anchor_left = 0.5
	_banner_caja.anchor_right = 0.5
	_banner_caja.anchor_top = 1.0
	_banner_caja.anchor_bottom = 1.0
	_banner_caja.offset_left = -260
	_banner_caja.offset_right = 260
	_banner_caja.offset_top = -108
	_banner_caja.offset_bottom = -60
	_banner_caja.pivot_offset = Vector2(260, 24)
	_banner_caja.modulate = Color(1, 1, 1, 0)
	add_child(_banner_caja)
	_banner = Label.new()
	_banner.add_theme_font_size_override("font_size", 24)
	_banner.add_theme_color_override("font_color", Color.WHITE)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.text = ""
	_banner_caja.add_child(_banner)

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

## El "salto" del marcador: un golpe de escala corto -crece y vuelve, como el
## marcador de un estadio de verdad al subir el número-, no una animación larga
## que tape el juego. Se corta y se reinicia si llega un segundo gol encima.
func _animar_marcador_gol() -> void:
	if _caja_marcador == null:
		return
	if is_instance_valid(_tween_marcador):
		_tween_marcador.kill()
	_caja_marcador.scale = Vector2.ONE
	_tween_marcador = create_tween()
	_tween_marcador.tween_property(_caja_marcador, "scale", Vector2(1.22, 1.22), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween_marcador.tween_property(_caja_marcador, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

## Los nombres largos no caben en un marcador de televisión, y recortar por
## caracteres deja cosas como "Deportes Antofa". Se usa la primera palabra larga.
func _corto(n: String) -> String:
	if n.length() <= 14:
		return n
	for parte in n.split(" "):
		if parte.length() >= 5:
			return parte
	return n.substr(0, 14)

## Cuánto se espera tras el gol antes de repetirlo: el remate, el balón en la
## red y el primer festejo se ven en vivo; después, la repetición.
const SEG_ANTES_REPETICION := 6.0
var _repe: Repeticion
var _intro: IntroPartido
var _ceremonia: CeremoniaPartido
var _ceremonia_pendiente := ""
var _rotulo_repe: PanelContainer

func _repetir_gol() -> void:
	if _repe == null or not _pref("repeticiones", true) or partido == null or partido.terminado_ya:
		return
	if _repe.reproducir(6.0 if _motor != null else 9.0):
		if _rotulo_repe == null:
			_rotulo_repe = PanelContainer.new()
			var st := Tema.caja(Color(0.55, 0.08, 0.08, 0.9), Tema.RADIO_CHICO, Color(1, 1, 1, 0.2))
			_rotulo_repe.add_theme_stylebox_override("panel", st)
			var l := Tema.etiqueta(16, Color.WHITE, "⟲  REPETICIÓN")
			_rotulo_repe.add_child(l)
			add_child(_rotulo_repe)
			_rotulo_repe.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
			_rotulo_repe.offset_top = 70
			_rotulo_repe.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_rotulo_repe.visible = true
		Animar.aparecer(_rotulo_repe)

func _al_gol(c: Club, autor: Jugador, minuto: int, asistente: Jugador = null) -> void:
	var a_favor := c == club
	if _motor != null:
		## Con el motor real: la secuencia de cámaras y, al final, la repetición.
		_cine_gol(c, autor)
	else:
		get_tree().create_timer(SEG_ANTES_REPETICION).timeout.connect(_repetir_gol)
	_suceso({
		"min": minuto, "t": "golMi" if a_favor else "golR",
		"equipo": "local" if a_favor else "visita",
		"tx": "¡GOL de %s! %s" % [c.nombre, autor.nombre if autor else ""],
		"jugadorId": autor.id if autor else "",
		"asistidorId": asistente.id if asistente != null else "",
	})
	## SONIDO (18-9-2026): hasta ahora esta vista 3D -la que de verdad se juega,
	## `partido_vivo.gd` la abre encima del partido en marcha- nunca llamaba a
	## `Sonido`. Todo el catálogo (incluidos los ocho estilos de gol elegibles
	## en el diseño del estadio) existía y sonaba en las pruebas, pero en el
	## partido de verdad esta pantalla se quedaba muda -el 2D de `partido_vivo`
	## sí tenía sus propios `Sonido.toca()`, este visor no-. `a_favor` aquí
	## significa "anotó el club dueño de ESTE estadio" -es la bocina de SU
	## recinto, no una noción de "mi club" que este visor no conoce-.
	## Goles con nombre propio: el doblete, el hat-trick, el tempranero y el
	## agónico tienen su propio grito encima del de siempre.
	if autor != null:
		_goles_autor[autor.id] = int(_goles_autor.get(autor.id, 0)) + 1
		match int(_goles_autor[autor.id]):
			2: Sonido.toca("doblete", Sonido.Bus.AMBIENTE)
			3: Sonido.toca("hat_trick", Sonido.Bus.AMBIENTE)
	if minuto <= 3:
		Sonido.toca("gol_rapido", Sonido.Bus.AMBIENTE)
	elif minuto >= 86:
		Sonido.toca("gol_agonico", Sonido.Bus.AMBIENTE)
	if a_favor:
		Sonido.toca("festejo_hinchada_extra", Sonido.Bus.AMBIENTE)
		var estilo := String(_perfil.get("sonidoGol", "bombo"))
		Sonido.toca("gol_" + estilo if Sonido.catalogo().has("gol_" + estilo) else "gol")
	else:
		Sonido.toca("gol_rival")
	## Con el motor real lo dice la carta del goleador (como en FC); el cartel
	## queda para el gol en propia puerta y el partido sin motor.
	if _motor == null or autor == null:
		_mostrar_banner_gol("⚽ GOL DE %s" % (autor.nombre.to_upper() if autor else "?"), a_favor)
	_animar_marcador_gol()
	## La pantalla gigante corta a "¡GOOOL!" a pantalla completa y vuelve sola
	## a su rotación a los 6,5 s -igual que la de un estadio de verdad-.
	if _pantalla != null:
		_pantalla.al_gol(c, autor, minuto)
	_vallas_evento(["¡GOOOL!", c.nombre.to_upper()], c)
	if _motor == null:
		_seguir_jugada_gol(autor)
	## EL BANQUILLO REACCIONA (22-9-2026). `a_favor` aquí es "el dueño de este
	## estadio anotó", no necesariamente el club local en la cancha -mismo
	## matiz que ya advierte el comentario del sonido, un poco más arriba-,
	## así que el lado que festeja es el de `c`, no el de `a_favor` a secas.
	if _motor == null:
		_banca_celebra(c == club)

## CÁMARA (18-9-2026): "no se ve la jugada planificada" -con razón: la cámara
## seguía al balón, no al jugador, y en el instante del gol el balón ya viaja
## solo hacia la red mientras la jugada real (la carrera del asistidor) pasa
## en otra parte del encuadre. Mientras haya un gol en curso, la cámara sigue
## al GOLEADOR -que es quien tiene la jugada con guion encima- por el tiempo
## que dura la jugada más el festejo, y después SUELTA sola para no quedarse
## pegada a él el resto del partido. No se activa en Modo Jugador: ahí el
## usuario ya eligió a quién sigue la cámara con sus propias manos.
func _seguir_jugada_gol(autor: Jugador) -> void:
	if _rig == null or autor == null or _juego == null:
		return
	if _control != null and _control.activo:
		return
	if not _juego.players_by_id.has(autor.id):
		return
	var nodo_autor: Node3D = _juego.players_by_id[autor.id].get("node")
	if not is_instance_valid(nodo_autor):
		return
	_rig.objetivo_seguimiento = nodo_autor
	## NO BASTABA CON `objetivo_seguimiento`: cada modo de cámara de
	## `CameraRig._process()` decide por su cuenta qué tan de cerca reacciona a
	## ese objetivo -varias de las 9 son planos casi fijos que apenas se
	## inmutan-. Si el gol pasa con una de esas activa, el objetivo cambia pero
	## en pantalla no se nota nada: es la causa real de "no se ve la jugada
	## planificada". "Tele Dinámica" es la única pensada para acompañar de
	## cerca el avance de una jugada -se guarda la cámara de antes y se
	## restaura sola al terminar, para no imponerle al usuario un cambio de
	## plano permanente.
	var idx_antes := _rig.current_index
	var idx_tele := _rig.camera_names.find("Tele Dinámica")
	if idx_tele != -1 and idx_tele != idx_antes:
		_rig.switch_to(idx_tele)
	get_tree().create_timer(5.5).timeout.connect(func() -> void:
		if not is_instance_valid(_rig):
			return
		if _rig.objetivo_seguimiento == nodo_autor:
			_rig.objetivo_seguimiento = null
		if _rig.current_index == idx_tele:
			_rig.switch_to(idx_antes))

## El banquillo del equipo que anotó se levanta a festejar -misma animación
## "celebrar" que ya usa el autor del gol en la cancha (real, no a mano, ver
## `AnimQuaternius`)- y vuelve solo a "parado" a los 3s. No es un bucle: si
## hay otro gol antes de que termine el timer, simplemente se reinicia sobre
## la marcha, no hace falta encolar nada más elaborado para esto.
func _banca_celebra(es_local: bool) -> void:
	for f: Dictionary in _en_banca:
		if bool(f.get("es_local", false)) != es_local:
			continue
		## Los sentados NO se paran a festejar -la pose "celebrar" es de pie,
		## y sin además subir la raíz del modelo (bajada por `ALTO_ASIENTO_
		## OFFSET` para que la cadera caiga a la altura del banco) saldría
		## festejando hundido a medio metro bajo el piso. Arreglar eso es
		## trabajo aparte (parar, reposicionar, festejar, volver a sentar);
		## por ahora los sentados se quedan sentados, que ya es más real que
		## la banda vacía de antes de hoy.
		if bool(f.get("sentado", false)):
			continue
		var ap: AnimationPlayer = f.get("anim")
		var n: Node3D = f.get("node")
		if not is_instance_valid(ap) or not is_instance_valid(n):
			continue
		if ap.has_animation("celebrar"):
			ap.play("celebrar")
		## Vuelve a lo suyo: "parado", o las dominadas si estaba calentando.
		var reposo := String(f.get("reposo_anim", "parado"))
		get_tree().create_timer(3.0).timeout.connect(func() -> void:
			if is_instance_valid(ap) and ap.has_animation(reposo):
				ap.play(reposo))

func _a_la_tarjeta(j: Jugador, roja: bool, minuto: int) -> void:
	Sonido.toca("roja" if roja else "amarilla")
	_suceso({
		"min": minuto, "t": "warn",
		"equipo": "local" if j.club_id == club.id else "visita",
		"tx": ("ROJA a " if roja else "Amarilla a ") + j.nombre,
		"roja": roja,
		"jugadorId": j.id,
	})

## Un cambio en el campo: sale uno y entra otro DE VERDAD, no solo en la lista.
## Al que sale se le quita el modelo y al que entra se le crea en la ranura que
## deja libre, para que el once que se ve sea el once que juega.
## Las vallas LED cortan al mensaje con los colores del club (`VallasLed.evento`).
func _vallas_evento(palabras: Array, c: Club, seg: float = 6.0) -> void:
	var led := _raiz3d.find_child("VallasLed", true, false) as VallasLed if _raiz3d != null else null
	if led == null or c == null:
		return
	led.evento(palabras, Color(c.color1), Color(c.color2), seg)

func _al_cambio(sale: Jugador, entra: Jugador, minuto: int) -> void:
	Sonido.toca("cambio")
	var del_cambio: Club = club if club != null and club.plantilla.has(entra) else visitante
	_vallas_evento(["CAMBIO", "⬆ %s" % entra.nombre.get_slice(" ", entra.nombre.get_slice_count(" ") - 1).to_upper(),
		"⬇ %s" % sale.nombre.get_slice(" ", sale.nombre.get_slice_count(" ") - 1).to_upper()], del_cambio, 4.0)
	## Si `entra` era uno de los 7 de la banca visual, se le quita el modelo
	## de ahí antes de crearle uno en la cancha -si no, quedaría duplicado:
	## uno de pie junto al banquillo y otro jugando, el mismo jugador dos
	## veces a la vista. Si no estaba entre los 7 mostrados (la banca visual
	## es una muestra, no la convocatoria real, ver `_poner_banca()`), no hay
	## nada que quitar y este bucle simplemente no encuentra nada.
	for i in range(_en_banca.size() - 1, -1, -1):
		var fb: Dictionary = _en_banca[i]
		if String(fb.get("id", "")) == entra.id:
			var nb: Node3D = fb.get("node")
			if is_instance_valid(nb):
				nb.queue_free()
			_en_banca.remove_at(i)
			break
	_suceso({
		"min": minuto, "t": "info", "equipo": "local",
		"tx": "Cambio: entra %s por %s" % [entra.nombre, sale.nombre], "jugadorId": entra.id,
	})
	for i in _en_campo.size():
		var f: Dictionary = _en_campo[i]
		if String(f.get("id", "")) != sale.id:
			continue
		var viejo: Node3D = f["node"]
		var pos: Vector3 = viejo.position
		var es_local: bool = f["es_local"]
		viejo.queue_free()
		var equipo := club if es_local else visitante
		var d := Puente3D.jugador(entra)
		var nuevos := _spawner.spawn_team(_raiz3d, [entra.id], {entra.id: d},
			{"s": [[f["slot_code"], 50, 50]]}, es_local,
			Puente3D.kit(equipo), Puente3D.kit_portero(equipo))
		if nuevos.is_empty():
			_en_campo.remove_at(i)
			return
		var nf: Dictionary = nuevos[0]
		nf["node"].position = pos
		nf["base_pos"] = f["base_pos"]
		nf["slot_code"] = f["slot_code"]
		nf["es_local"] = es_local
		_en_campo[i] = nf
		if _motor != null:
			_motor.reemplazar(sale.id, nf)
			_mostrar_banner_gol("🔁 %s  ⬆ %s   ⬇ %s" % [Idiomas.t("CAMBIO"), Nombres.visible(entra.nombre), Nombres.visible(sale.nombre)],
				equipo.id == Partido.ctx_club_id)
		_fov_rotulos = -1.0
		_juego.players = _en_campo
		_juego.players_by_id[entra.id] = nf
		_juego.players_by_id.erase(sale.id)
		return

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


func _al_remate(c: Club, autor: Jugador, tipo: String, minuto: int) -> void:
	if _juego == null:
		return
	## Igual que en `_al_gol()`: la reacción sonora es del ESTADIO (`a_favor` =
	## remató el dueño de este recinto), no de "mi club" -este visor no conoce
	## esa noción, y hasta hoy ninguna de las dos vivía aquí.
	if c == club:
		match tipo:
			"atajada":
				Sonido.toca("atajada")
				Sonido.toca("alarido_atajada", Sonido.Bus.AMBIENTE)
			"poste":
				Sonido.toca("travesano" if minuto % 2 == 0 else "ocasion")
				Sonido.toca("suspiro_grada", Sonido.Bus.AMBIENTE)
			## BUG REAL ENCONTRADO Y CORREGIDO (21-9-2026): un remate desviado no
			## sonaba NADA -la rama por defecto solo hacia `pass`- pese a que
			## `Sonido` ya trae "remate_fuera" sintetizado y sin usar en ningun
			## lado del visor 3D. El partido se quedaba mudo en el caso MAS
			## comun de un remate (fallar es mas frecuente que atajar o dar en
			## el palo).
			"fallo": Sonido.toca("remate_fuera")
			_: pass
	_suceso({
		"min": minuto,
		"t": "disparo",
		"tipo": tipo,
		"equipo": "local" if c == club else "visita",
		"tx": "Remate de %s (%s)" % [autor.nombre if autor else "delantero", tipo],
		"jugadorId": autor.id if autor else "",
	})

var _goles_autor := {}

## Los tiempos del partido, a oído: el descanso, la vuelta, el último minuto,
## el descuento, y la grada que se pone tensa en un final apretado.
func _al_minuto_sonoro(minuto: int) -> void:
	match minuto:
		45: Sonido.toca("medio_tiempo")
		46: Sonido.toca("reanudacion")
		89: Sonido.toca("ultimo_minuto", Sonido.Bus.AMBIENTE)
		90: Sonido.toca("descuento_anunciado")
	if minuto >= 80 and minuto % 4 == 0 and absi(partido.goles_local - partido.goles_visita) <= 1:
		Sonido.toca("tension_publico", Sonido.Bus.AMBIENTE)

func _a_la_lesion(j: Jugador, semanas: int, minuto: int) -> void:
	if _juego == null:
		return
	if j.club_id == club.id:
		Sonido.toca("lesion_grave" if semanas >= 6 else "lesion")
	_suceso({
		"min": minuto,
		"t": "lesion",
		"equipo": "local" if j.club_id == club.id else "visita",
		"tx": "¡Lesión de %s! (%d sem)" % [j.nombre, semanas],
		"jugadorId": j.id,
	})

## LA SALA VAR (26-9-2026): el partido se para, se ve la sala por dentro con
## los monitores mostrando la jugada desde cuatro cámaras, y se sigue.
var _sala_var: SalaVAR = null

func _a_la_revision_var(minuto: int, motivo: String) -> void:
	if _sala_var != null or _raiz3d == null:
		return
	var vel_antes := _juego.vel_idx if _juego != null else 2
	if _juego != null:
		_juego.vel_idx = 0
	var foco := _balon.global_position if is_instance_valid(_balon) else Vector3.ZERO
	_sala_var = SalaVAR.abrir(self, _raiz3d.get_world_3d(), foco, minuto, motivo)
	_sala_var.terminada.connect(func() -> void:
		_sala_var = null
		if _juego != null:
			_juego.vel_idx = maxi(vel_antes, 1))

func _a_la_decision_arbitral(texto: String, minuto: int) -> void:
	if _juego == null:
		return
	_suceso({
		"min": minuto,
		"t": "arbitro",
		"tx": texto,
	})


# --- el partido con el motor real ---------------------------------------------

## Las jugadas con guion de `MatchPlayback` solo cuando NO juega el motor real
## (con el motor, `MatchPlayback` no mueve a nadie).
func _suceso(ev: Dictionary) -> void:
	if _motor != null or _juego == null:
		return
	_juego.suceso(ev)

static func ritmo_partido() -> String:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	return String(cfg.get_value(CajonAjustes.SECCION, "ritmo_partido", "normal"))

func _fijar_ritmo(r: String) -> void:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ritmo_partido", r)
	cfg.save(CajonAjustes.RUTA)
	if _motor != null:
		## Se respeta el minuto en curso: solo cambia lo que dura cada minuto.
		var frac := _motor.t / maxf(_motor.duracion_mitad, 1.0)
		_motor.duracion_mitad = 45.0 * float(SEG_POR_MINUTO.get(r, 4.0))
		_motor.t = frac * _motor.duracion_mitad
	_mostrar_banner_gol({"rapido": "⏩ Partido corto", "normal": "⏯ Ritmo normal", "largo": "🐢 Partido largo"}.get(r, r), true)

func _montar_motor() -> void:
	partido.motor_externo = true
	_motor = MotorJugable.new()
	add_child(_motor)
	_motor.set_physics_process(false)
	_motor.duracion_mitad = 45.0 * float(SEG_POR_MINUTO.get(ritmo_partido(), 4.0))
	_motor.cansancio_real = true
	_motor.duracion_gol = 7.6
	_motor.tarjetas_reales = true
	_motor.autopiloto = true
	_motor.lanza_usuario = {"corner": true, "falta": true, "penal": true, "banda": true}
	_motor.preparar(_en_campo, _balon, "", hash(partido.local.id + partido.visita.id) + partido.minuto)
	_motor.empezar_en(partido.minuto, partido.goles_local, partido.goles_visita)
	_motor.sortear_anadido()
	_mi_lado = 0 if partido.local.id == Partido.ctx_club_id else (1 if partido.visita.id == Partido.ctx_club_id else -1)
	_stats = EstadisticasVivo.new()
	_motor.gol.connect(func(de_local: bool, autor: String, asist: String) -> void:
		_stats.cerrar_tiro(de_local, "gol", _balon.position if is_instance_valid(_balon) else Vector3.ZERO)
		partido.gol_externo(de_local, autor, asist)
		if _rig != null:
			_rig.impacto(0.9, 0.7)
			_rig.golpe_de_zoom(5.0, 1.2)
		## EL VAR SE USA (14-10-2026): con VAR en la liga, uno de cada cinco goles
		## se revisa en la sala (el partido espera y el gol se confirma).
		if Partido.ctx_factor_tarjetas < 1.0 and Azar.suerte(0.2):
			get_tree().create_timer(2.2).timeout.connect(func() -> void:
				if is_instance_valid(self) and _motor != null:
					_a_la_revision_var(partido.minuto, "Revisión del gol: posible fuera de juego")))
	_motor.remate.connect(func(de_local: bool, autor: String, tipo: String) -> void:
		var tirador := _nodo_de(autor)
		_stats.cerrar_tiro(de_local, tipo, Vector3.ZERO, tirador.position if tirador != null else (_balon.position if is_instance_valid(_balon) else Vector3.ZERO))
		partido.remate_externo(de_local, autor, tipo)
		if _rig != null:
			_rig.golpe_de_zoom(2.0, 0.5))
	_motor.tarjeta.connect(func(id: String, roja: bool, de_local: bool) -> void:
		_stats.tarjeta(de_local, roja)
		partido.tarjeta_externa(id, roja)
		if _rig != null:
			_rig.impacto(0.45 if roja else 0.25, 0.4))
	_motor.aviso.connect(_al_aviso_motor)
	_motor.tactica_rapida.connect(func(eq: int, clave: String, valor: int) -> void:
		var c: Club = partido.local if eq == 0 else partido.visita
		if c != null and c.tactica != null:
			c.tactica.set(clave, valor)
			partido.invalidar_fuerza())
	_actualizar_tacticas()
	## La transmisión, como en el vídeo: cámara alta que sigue el balón y la
	## pantalla limpia (sin nombres sobre los 22 ni la pantalla gigante en la
	## esquina; se pueden encender en ⚙).
	if _rig != null:
		var it := _rig.camera_names.find("Transmisión")
		if it >= 0 and not (PersonajeDT.sancionado and _rig.current_name().begins_with("Desde la grada")):
			_rig.switch_to(it)
			if _btn_camara != null:
				_btn_camara.text = Idiomas.t("📷 Cámara: ") + _rig.current_name()
	_nombres_globales = PlayerSpawner.mostrar_nombres
	if not _pref("nombres_motor", false):
		_mostrar_nombres(false)
	## Si jugaste tú el último partido, vuelves a jugar (se recuerda).
	if _pref("control_equipo", false) and _mi_lado >= 0:
		_alternar_control_motor.call_deferred()
	if _mini_pantalla != null and not _pref("pantalla_esquina_motor", false):
		_mini_pantalla.visible = false

## Los avisos del motor que merecen rótulo (los goles ya tienen el suyo).
func _al_aviso_motor(texto: String) -> void:
	for clave in ["Córner", "Penal", "PENAL", "Fuera de juego", "Roja", "PALO", "LARGUERO", "parada", "Atajada"]:
		if texto.contains(clave):
			_mostrar_rotulo_suceso(Idiomas.t(texto))
			return

## Un rótulo corto debajo del marcador (reutiliza el de las jugadas).
func _mostrar_rotulo_suceso(texto: String) -> void:
	if _rotulo_jugada == null or not _pref("rotulos", true):
		return
	(_rotulo_jugada.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Color("c9a227")
	_lbl_jugada.text = "▸ " + texto
	if _tween_jugada != null and _tween_jugada.is_valid():
		_tween_jugada.kill()
	_tween_jugada = create_tween()
	_tween_jugada.tween_property(_rotulo_jugada, "modulate:a", 1.0, 0.2)
	_tween_jugada.tween_interval(2.2)
	_tween_jugada.tween_property(_rotulo_jugada, "modulate:a", 0.0, 0.5)

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
		var mio_gana := (partido.goles_local > partido.goles_visita and _mi_lado == 0) or (partido.goles_visita > partido.goles_local and _mi_lado == 1)
		_mostrar_banner_gol("🏁 %s  %s %d - %d %s" % [Idiomas.t("FINAL"), Nombres.visible(partido.local.nombre),
			partido.goles_local, partido.goles_visita, Nombres.visible(partido.visita.nombre)], mio_gana)
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

## El reloj del acta sigue al del césped. Devuelve true si la vista se cierra
## (descanso: el camarín).
func _sincronizar_partido() -> bool:
	## En el añadido el acta se queda en el 44'/89' hasta que de verdad se
	## pita: así un gol en el descuento sigue contando y el descanso no se
	## adelanta.
	var objetivo := 90 if _motor.estado == "fin" else _motor.minuto()
	if _motor.estado != "fin":
		if _motor.mitad == 1 and _motor.estado != "descanso":
			objetivo = mini(objetivo, 44)
		elif _motor.mitad == 2:
			objetivo = mini(objetivo, 89)
		if _motor.estado == "descanso" or (_motor.mitad == 2 and partido.minuto < 45):
			objetivo = maxi(objetivo, 45)
	while partido.minuto < objetivo and not partido.terminado_ya:
		partido.simular_minuto()
		partido.fijar_estadisticas(float(_motor.posesion_local()), _motor.corners, _motor.faltas)
		_dt_rival(partido.minuto)
		if parar_en_descanso and not _descanso_hecho and partido.minuto >= 45:
			_descanso_hecho = true
			cerrado.emit()
			return true
	return false

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
		if minuto in [60, 70, 80]:
			_cambio_ia(c, i == 0)

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

## «Simular hasta el final» con el motor: lo que falta se juega a toda
## velocidad y sin pantalla (tu equipo en piloto automático).
func _simular_resto_motor() -> void:
	_motor.autopiloto = true
	_motor.control_equipo = -1
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

func _abrir_panel_dt() -> void:
	if _motor == null or _panel_dt != null or partido == null or partido.terminado_ya:
		return
	if _mi_lado < 0:
		_mostrar_banner_gol(Idiomas.t("Este partido no es de tu club: solo puedes mirarlo."), false)
		return
	var mio: Club = partido.local if _mi_lado == 0 else partido.visita
	_panel_dt = PanelDTPartido.abrir(self, partido, mio, _motor, abrir_estadisticas)
	_panel_dt.cerrado.connect(func() -> void:
		_panel_dt = null
		_actualizar_tacticas())

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

## Los rótulos de estadísticas de la tele en los momentos muertos.
func _rotulo_automatico() -> void:
	if _stats == null or not _pref("rotulos", true) or is_instance_valid(_cine):
		return
	var cual := RotuloEstadisticas.cuando(_motor.minuto(), _motor.estado, _motor.mitad, _rotulos_hechos)
	if cual == "":
		return
	_rotulos_hechos[cual] = true
	RotuloEstadisticas.mostrar(self, cual, partido, _motor, _stats)

## ESTADÍSTICAS A PEDIDO: su botón (`jugar_estadisticas`) o desde la pausa. El
## partido espera mientras se miran.
func abrir_estadisticas() -> void:
	if _motor == null or _panel_stats != null or partido == null:
		return
	if _cajon != null and _cajon.abierto:
		_cajon.cerrar()
	_panel_stats = PanelEstadisticas.abrir(self, partido, _motor, _stats)
	_panel_stats.cerrado.connect(func() -> void: _panel_stats = null)

func _unhandled_input(e: InputEvent) -> void:
	if _motor != null and _panel_controles == null and _panel_stats == null and e.is_action_pressed("jugar_estadisticas"):
		get_viewport().set_input_as_handled()
		abrir_estadisticas()
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


# --- la secuencia del gol (motor real) -------------------------------------

## LA REALIZACIÓN DEL GOL (13-10-2026, como en el vídeo de FC 26): el goleador
## corriendo a celebrar de cerca, corte al banquillo que salta, la grada, un
## barrido con el escudo y la repetición. Mientras, el motor alarga la
## celebración (`duracion_gol`) y el reloj no corre.
## La secuencia vive en `CineGol` (compartida con la Carrera de Jugador).
var _cine: CineGol
var _cine_t: float:
	get:
		return _cine.t if is_instance_valid(_cine) else -1.0

func _cine_gol(c: Club, autor: Jugador) -> void:
	if _raiz3d == null:
		return
	if is_instance_valid(_cine):
		_cine.cortar()
	## La repetición debe acabar en el gol, no en la celebración: se deja de
	## grabar hasta que termine.
	if _repe != null:
		_repe.congelar = true
	var autor_id := autor.id if autor != null else ""
	var g := StadiumBuilder.geom_de_forma(String(_perfil.get("forma", "oval")))
	var carta := func() -> Dictionary:
		var j := partido._por_id(autor_id) if partido != null and autor_id != "" else null
		if j == null:
			return {}
		return {"dorsal": j.dorsal, "nombre": j.nombre, "tiros": int(_tiros_de.get(j.id, 1)), "goles": int(_goles_de.get(j.id, 1))}
	_cine = CineGol.iniciar(self, _raiz3d, c, c == club, _nodo_de(autor_id), carta, float(g["dx"]))
	_cine.banquillo.connect(func() -> void: _banca_celebra(c == club))
	_cine.terminado.connect(func() -> void:
		_repetir_gol()
		if _repe != null:
			if _repe.reproduciendo:
				_repe.terminada.connect(func() -> void: _repe.congelar = false, CONNECT_ONE_SHOT)
			else:
				_repe.congelar = false)

func _nodo_de(id: String) -> Node3D:
	for p: Dictionary in _en_campo:
		if String(p.get("id", "")) == id and is_instance_valid(p.get("node")):
			return p["node"]
	return null

## Se llama desde `_process` (antes del paso del motor).
func _cine_paso(delta: float) -> void:
	if is_instance_valid(_cine):
		_cine.paso(delta)


## LA BARRA DE POTENCIA Y LA FLECHA DE APUNTE (jugando tú, como en FC): al
## cargar un tiro o un balón parado, la barra abajo al centro; en córners y
## faltas, una flecha en el césped hacia donde apuntas.
var _barra_pot: ProgressBar
var _flecha_apunte: MeshInstance3D

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
