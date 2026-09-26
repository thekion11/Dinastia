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

	var perfil := perfil_forzado if not perfil_forzado.is_empty() else club.perfil_estadio()
	_perfil = perfil
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
	volver.text = "Volver"
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
	if partido != null:
		_cajon.seccion("Partido")
		_btn_modo = _cajon.boton("🎮 Modo: Manager", _alternar_modo_control)
		_btn_velocidad = _cajon.boton("⏱", _ciclar_velocidad)
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
	_cajon.interruptor("ℹ Ficha del estadio abajo", _pref("pie", true), func(si: bool) -> void:
		_pie.visible = si
		_guardar_pref("pie", si))
	_cajon.interruptor("🎬 Presentación antes del partido", _pref("intro", true), func(si: bool) -> void:
		_guardar_pref("intro", si))
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
	_pie.visible = _pref("pie", true)
	add_child(_pie)
	_actualizar_pie(perfil, aforo, ocupacion)

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
				(rot.get_node(PlayerSpawner.BARRA) as Label3D).pixel_size = tam

## La energía bajo cada nombre, una vez por minuto simulado.
var _minuto_barras := -1

func _actualizar_barras() -> void:
	if not PlayerSpawner.mostrar_nombres:
		return
	for f: Dictionary in _en_campo:
		var n: Node3D = f.get("node")
		if is_instance_valid(n) and n.has_node(PlayerSpawner.ROTULO + "/" + PlayerSpawner.BARRA):
			PlayerSpawner.actualizar_barra(n.get_node(PlayerSpawner.ROTULO + "/" + PlayerSpawner.BARRA) as Label3D, _minuto_barras)

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
			_btn_camara.text = "📷 Cámara: " + _rig.current_name()
		if _pie != null:
			_pie.text = _pie_base + "  ·  cámara: " + _rig.current_name()

func _actualizar_pie(perfil: Dictionary, aforo: int, ocupacion: float) -> void:
	_pie_base = "%s  ·  %s de %d niveles  ·  techo %s  ·  %d butacas, %d%% de ocupación" % [
		club.nombre, String(perfil["forma"]).capitalize(), int(perfil["niveles"]),
		String(perfil["techo"]), aforo, int(ocupacion * 100.0)]
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
		Puente3D.kit(visitante), Puente3D.kit_portero(visitante)))
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
	var disponibles := _disponibles_fuera_del_once(c, once_c)
	var kit := Puente3D.kit(c)
	var kit_por := Puente3D.kit_portero(c)
	_en_banca.append_array(_spawner.spawn_banca(_raiz3d, disponibles, es_local, kit, kit_por))
	_poner_dt(c, es_local, mini(disponibles.size(), 7))
	if disponibles.size() > 7:
		_en_banca.append_array(_spawner.spawn_sentados(_raiz3d,
			disponibles.slice(7, 12), es_local, kit, kit_por))

## EL ENTRENADOR EN LA BANDA (26-9-2026): tu personaje del creador en el
## área técnica de tu club, y un DT rival (siempre el mismo por club) en la
## otra. Delante de su fila de suplentes, del lado del centro del campo.
## CAMARÓGRAFOS Y GUARDIAS DE VERDAD (26-9-2026). El constructor deja a cada
## operador como un maniquí de cajas con su cámara; aquí se oculta el maniquí
## y se pone una persona entera detrás de la cámara. Y seis guardias de
## seguridad detrás de las vallas, de espaldas al juego, mirando a la grada.
func _poner_personal() -> void:
	if _raiz3d == null:
		return
	var i := 0
	for cam in _raiz3d.find_children("Camarografo*", "Node3D", true, false):
		var base := cam as Node3D
		var d := PersonajeDT.personal_estadio(_raiz3d, "prensa", base.position - base.basis.z * 0.12, base.rotation.y, 700 + i)
		if not d.is_empty():
			for mi in base.find_children("*", "MeshInstance3D", false, false):
				if mi.has_meta("cuerpo"):
					(mi as Node3D).visible = false
		i += 1
	var puestos := [
		[Vector3(-38.8, 0, -36.0), -PI * 0.5], [Vector3(-38.8, 0, -12.0), -PI * 0.5],
		[Vector3(-38.8, 0, 12.0), -PI * 0.5], [Vector3(-38.8, 0, 36.0), -PI * 0.5],
		[Vector3(0.0, 0, 57.0), 0.0], [Vector3(0.0, 0, -57.0), PI],
	]
	for k in puestos.size():
		## El giro es hacia FUERA del campo: la persona mira a +Z sin girar.
		PersonajeDT.personal_estadio(_raiz3d, "seguridad", puestos[k][0], puestos[k][1], 900 + k)

func _poner_dt(c: Club, es_local: bool, cuantos: int) -> void:
	var asp: Dictionary = PersonajeDT.del_usuario if c.id == PersonajeDT.club_usuario else PersonajeDT.de_rival(c.id)
	var lado := -1.0 if es_local else 1.0
	var z := lado * 14.0 - lado * (float(maxi(cuantos, 1)) * 0.8 + 1.8)
	PersonajeDT.poner_en_banda(_raiz3d, asp, Color(c.color1), Color(c.color2), Vector3(34.6, 0, z), -PI * 0.5)

## Mejores disponibles (sin lesión/sanción, no en el once) por media, para que
## la banca se vea como un banco de verdad y no como un sorteo cualquiera.
func _disponibles_fuera_del_once(c: Club, once_c: Array[Jugador]) -> Array:
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
	Sonido.toca("salida_tunel", Sonido.Bus.AMBIENTE)
	## La presentación: vuelo de cámara con el rótulo del partido (B3).
	if _pref("intro", true):
		var gi := StadiumBuilder.geom_de_forma(String(_perfil.get("forma", "oval")))
		var nombre_est := club.estadio_nombre if club.estadio_nombre != "" else "Estadio de %s" % club.nombre
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

	# Control interactivo de jugador (Modo FC 26)
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
	_escalar_rotulos()
	if _juego == null or partido == null:
		return
	## Durante la repetición y la presentación el partido está CONGELADO: ni
	## reloj ni minutos.
	if _repe != null and _repe.reproduciendo:
		return
	if _intro != null and _intro.activa:
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
var _rotulo_repe: PanelContainer

func _repetir_gol() -> void:
	if _repe == null or not _pref("repeticiones", true) or partido == null or partido.terminado_ya:
		return
	if _repe.reproducir(9.0):
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
	get_tree().create_timer(SEG_ANTES_REPETICION).timeout.connect(_repetir_gol)
	_juego.suceso({
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
	_mostrar_banner_gol("⚽ GOL DE %s" % (autor.nombre.to_upper() if autor else "?"), a_favor)
	_animar_marcador_gol()
	## La pantalla gigante corta a "¡GOOOL!" a pantalla completa y vuelve sola
	## a su rotación a los 6,5 s -igual que la de un estadio de verdad-.
	if _pantalla != null:
		_pantalla.al_gol(c, autor, minuto)
	_seguir_jugada_gol(autor)
	## EL BANQUILLO REACCIONA (22-9-2026). `a_favor` aquí es "el dueño de este
	## estadio anotó", no necesariamente el club local en la cancha -mismo
	## matiz que ya advierte el comentario del sonido, un poco más arriba-,
	## así que el lado que festeja es el de `c`, no el de `a_favor` a secas.
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
	_juego.suceso({
		"min": minuto, "t": "warn",
		"equipo": "local" if j.club_id == club.id else "visita",
		"tx": ("ROJA a " if roja else "Amarilla a ") + j.nombre,
		"roja": roja,
		"jugadorId": j.id,
	})

## Un cambio en el campo: sale uno y entra otro DE VERDAD, no solo en la lista.
## Al que sale se le quita el modelo y al que entra se le crea en la ranura que
## deja libre, para que el once que se ve sea el once que juega.
func _al_cambio(sale: Jugador, entra: Jugador, minuto: int) -> void:
	Sonido.toca("cambio")
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
	_juego.suceso({
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
		_fov_rotulos = -1.0
		_juego.players = _en_campo
		_juego.players_by_id[entra.id] = nf
		_juego.players_by_id.erase(sale.id)
		return

func _alternar_modo_control() -> void:
	if _control == null:
		return
	_control.alternar_modo()
	if _control.activo:
		_btn_modo.text = "🎮 Modo: Jugador (FC)"
		if _control.jugador_activo.has("node") and is_instance_valid(_control.jugador_activo["node"]):
			_rig.objetivo_seguimiento = _control.jugador_activo["node"]
	else:
		_btn_modo.text = "🎮 Modo: Manager"
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
	_juego.suceso({
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
	_juego.suceso({
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
	_juego.suceso({
		"min": minuto,
		"t": "arbitro",
		"tx": texto,
	})

