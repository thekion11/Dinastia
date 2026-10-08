class_name VistaCiudad
extends Control
## LA CIUDAD DEPORTIVA, EN 3D, DENTRO DEL PROPIO JUEGO (12-9-2026).
##
## `CityBuilder` -el motor que levanta el complejo entero a partir de las
## instalaciones del club- llevaba desde el 2-09-2026 viviendo SOLO en el
## proyecto viejo `visor3d`, nunca portado al proyecto que de verdad compila
## el juego. `nucleo/ciudad.gd` (terrenos, negocios, permisos) sí estaba
## portado y tenía pantalla en Club → Ciudad, pero era texto: el visor 3D en
## sí era inalcanzable para el jugador. Este fichero es el puente que faltaba
## -mismo papel que `estadio.gd` para `StadiumBuilder`-: en vez del puente de
## JSON del proyecto viejo (`ciudad_main.gd` leía un fichero exportado), aquí
## `CityBuilder.build()` recibe el diccionario armado directo desde `Club` e
## `Instalaciones`, sin fichero intermedio.

signal cerrado
## Pedido explícito del usuario (16-9-2026): entrar al editor del estadio
## desde la ciudad 3D, sin volver antes a la pestaña de texto. `principal.gd`
## es quien de verdad abre el editor -esta escena no lo conoce, mismo patrón
## que `cerrado`.
signal editar_estadio_pedido

var club: Club
## B7: quien sabe construir de verdad. Lo pone `Principal` para que construir
## desde el mapa sea EXACTAMENTE lo mismo que desde Club → Infraestructura
## (mismo cobro, mismos permisos, mismo registro). Devuelve "" o el motivo.
var construir: Callable
## B7: ¿se juega en casa esta semana? La ciudad se viste de partido.
var dia_partido := false
## El momento del club (`CiudadAnimo.de`), lo pone quien abre la vista.
var animo: Dictionary = {}
## El ídolo del club (nombre), para la estatua de la Plaza Mayor.
var idolo := ""
var _obras: Instalaciones
var _ciudad_datos: Ciudad
var _perfil: Dictionary = {}
var _objetivo := Vector3(0, 16, 0)
var _objetivo_deseado := Vector3(0, 16, 0)
var _ficha: PanelContainer
var _rotulos_visibles := true
var _raiz3d: Node3D
var _ciudad: CityBuilder
var _camara: Camera3D
## ENCUADRE PARA UN MAPA, NO PARA UN RECINTO. Con 250 m de distancia solo
## cabía el complejo de entrenamiento; el mapa completo -estadio, las cinco
## parcelas y el barrio residencial- ocupa unos 700 m de lado, así que la
## cámara arranca lo bastante lejos y alta como para que se entienda el
## conjunto de un vistazo, y se puede bajar a 120 m para mirar una parcela.
## Y EL ÁNGULO, QUE IMPORTA MÁS QUE LA DISTANCIA: a 170 m de altura la vista
## era casi cenital y todo -el estadio, los edificios, el hotel- se leía como
## manchas planas sobre el suelo. Bajando a 110 m con la misma distancia, cada
## cosa recupera su silueta y se entiende cuál es alta y cuál no, que es justo
## lo que tiene que contar esta pantalla.
var _ang := 0.0
var _dist := 430.0
var _alto := 110.0
var _girando := true

# ---------------------------------------------------------------------------
#  EL CICLO DEL SOL
# ---------------------------------------------------------------------------
#
# Amanece, se hace de día, atardece y anochece, y vuelta a empezar. No es
# adorno: es lo que hace que la ciudad se sienta un sitio y no una foto -las
# sombras giran, el cielo cambia de color y al caer la noche se encienden las
# farolas y las ventanas-. Todo sale de UNA variable, `_hora` (0..24), que
# alimenta el sol, el cielo y la niebla; así no hay forma de que una parte del
# mundo se quede desincronizada de otra.
#
# UNA VUELTA DURA `CICLO_SEG` SEGUNDOS y no un día real: a 24 h de verdad no se
# vería pasar nada, y la gracia está justo en verlo pasar. Dos minutos deja ver
# el amanecer completo sin que maree.
const CICLO_SEG := 120.0
var _hora := 15.5              ## arranca a media tarde, que es cuando mejor luce
var _ciclo_activo := true
var _sol: DirectionalLight3D
var _env: Environment
var _cielo: ShaderMaterial
var _reloj: Label

## `perfil_estadio`: el mismo diccionario que consume el visor de partido
## (`mundo.perfil_estadio_de(club)`). Con él, el estadio que se ve en el mapa
## es EL TUYO, con la forma, las bandejas, el techo y las butacas que hayas
## pagado -no una maqueta genérica-.
func abrir(c: Club, obras: Instalaciones, ciudad: Ciudad, perfil_estadio: Dictionary = {}) -> void:
	club = c
	_obras = obras
	_ciudad_datos = ciudad
	_perfil = perfil_estadio
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_construir(obras, ciudad, perfil_estadio)

## Mismo motivo que en `estadio.gd`: colgada de un `Node` en vez de otro
## `Control` se queda en tamaño 0x0 para siempre.
func _ajustar_a_pantalla() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = get_viewport().get_visible_rect().size

func _construir(obras: Instalaciones, ciudad: Ciudad, perfil_estadio: Dictionary) -> void:
	_ajustar_a_pantalla()
	get_viewport().size_changed.connect(_ajustar_a_pantalla)
	Calidad.aplicar_viewport(get_viewport(), Calidad.elegida)

	_raiz3d = Node3D.new()
	add_child(_raiz3d)
	_sol = Calidad.sol(Calidad.elegida, Calidad.TARDE)
	_raiz3d.add_child(_sol)
	var we := Calidad.entorno(Calidad.elegida, Calidad.TARDE)
	## AJUSTE PARA UN MAPA, NO PARA UN RECINTO. `Calidad` está calibrada para
	## escenas de ~200 m -un estadio, un complejo-, y aquí se ve un kilómetro
	## de lado: con su exposición (1,25 para compensar el sol bajo) y su niebla,
	## el mapa entero salía lavado, de un verde menta descolorido, y las
	## parcelas del fondo se fundían con el cielo. Menos exposición y menos
	## niebla devuelven el color sin tocar cómo se ve el partido, que usa el
	## mismo `Calidad` y no debe cambiar.
	var env := we.environment
	env.tonemap_exposure = 1.02
	## El ánimo del club también tiñe la escena: más viva en la euforia, más
	## gris en la crisis (fase 5).
	env.adjustment_saturation = _saturacion_animo()
	env.adjustment_contrast = 1.10
	if env.fog_enabled:
		env.fog_density = 0.00016
	if env.volumetric_fog_enabled:
		env.volumetric_fog_density = 0.0006
		env.volumetric_fog_length = 600.0
	## EL "SUELO" DEL CIELO, que en un mapa se ve y en un estadio no. `Calidad`
	## lo deja pardo cálido -correcto cuando la cámara está dentro de un recinto
	## y ese trozo de cielo casi no asoma-, pero aquí, con la vista alta sobre
	## un kilómetro de césped, salía una BANDA MARRÓN cortando la imagen justo
	## encima del terreno. Tiñéndolo del verde brumoso del propio césped, el
	## mapa se funde con el horizonte en vez de acabarse de golpe.
	## CIELO PROPIO, CON SHADER (12-9-2026). `ProceduralSkyMaterial` solo sabe
	## degradar cuatro colores: de noche el cielo quedaba vacío -ni una
	## estrella- y de día liso -ni una nube-, justo lo contrario de lo que
	## pide "se siente un poco vacío". `visor/cielo.gdshader` hace el mismo
	## degradado (para no perder el ajuste de arriba) y le suma nubes a la
	## deriva y estrellas que aparecen de verdad con la noche.
	var sky_shader := load("res://visor/cielo.gdshader") as Shader
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = sky_shader
	sky_mat.set_shader_parameter("ground_horizon_color", Color(0.62, 0.70, 0.62))
	sky_mat.set_shader_parameter("ground_bottom_color", Color(0.36, 0.47, 0.36))
	env.sky.sky_material = sky_mat
	_raiz3d.add_child(we)
	_env = env
	_cielo = sky_mat
	_aplicar_hora()

	_ciudad = CityBuilder.new()
	_raiz3d.add_child(_ciudad)
	_ciudad.build(_datos_de(club, obras, ciudad, perfil_estadio))

	_camara = Camera3D.new()
	_camara.fov = 55.0
	_raiz3d.add_child(_camara)
	_mover_camara()

	var barra := HBoxContainer.new()
	barra.add_theme_constant_override("separation", 8)
	barra.offset_left = 18
	barra.offset_top = 14
	add_child(barra)
	_boton(barra, "Detener giro", _alternar_giro)
	_boton(barra, "☀ Detener el día", alternar_ciclo)
	_boton(barra, "🏟️ Editar mi estadio", func() -> void: editar_estadio_pedido.emit())
	_boton(barra, "🏷 Rótulos", func() -> void:
		_rotulos_visibles = not _rotulos_visibles
		_ciudad.mostrar_rotulos(_rotulos_visibles))
	_boton(barra, "📷 Foto", func() -> void:
		## Sin rótulos flotantes en la foto; vuelven al salir.
		_ciudad.mostrar_rotulos(false)
		ModoFoto.abrir(self, club, "la ciudad").tree_exited.connect(func() -> void:
			_ciudad.mostrar_rotulos(_rotulos_visibles)))
	_boton(barra, "🚗 Conducir", func() -> void: explorar("coche"))
	_boton(barra, "🚶 Pasear", func() -> void: explorar("pie"))
	_boton(barra, "🚇 Metro", func() -> void:
		if _ciudad.expansion != null and _ciudad.expansion.metro != null:
			_ciudad.expansion.metro.alternar_rayos_x())
	_boton(barra, "⚽ Día de partido", func() -> void:
		dia_partido = not dia_partido
		_reconstruir())
	_boton(barra, "Volver", func() -> void: cerrado.emit())

	_reloj = Label.new()
	_reloj.add_theme_font_size_override("font_size", 15)
	_reloj.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	_reloj.position = Vector2(18, 52)
	add_child(_reloj)

	var ayuda := Label.new()
	ayuda.text = "arrastra para girar · clic derecho o WASD para moverte · rueda para acercar · clic en un edificio o solar para ver su ficha"
	ayuda.add_theme_font_size_override("font_size", 13)
	ayuda.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	ayuda.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	ayuda.offset_left = 18
	ayuda.offset_bottom = -14
	ayuda.offset_top = -34
	add_child(ayuda)

## El mismo `{club, inst, obras}` que ya exportaba el HTML/el proyecto viejo,
## armado directo desde los objetos vivos -sin fichero intermedio-. Mismas
## claves exactas que lee `CityBuilder`: cambiar una aquí sin mirar el
## constructor dejaría la ciudad a medio construir sin ningún error visible.
func _datos_de(c: Club, obras: Instalaciones, ciudad: Ciudad, perfil_estadio: Dictionary) -> Dictionary:
	var arr_obras: Array = []
	for k: String in obras.obras:
		arr_obras.append({"k": k, "semanas": int(obras.obras[k])})
	return {
		## `rep` y `socios` no son adorno: la ciudad CRECE con ellos -más skyline
		## al fondo, más casas en el barrio, más tráfico-. Es la forma más
		## directa de que ganar títulos se note en el mapa y no solo en una
		## tabla, que es de lo que va esta pantalla para el usuario.
		"club": {
			"nombre": c.nombre, "c1": c.color1, "c2": c.color2,
			"cap": c.estadio_aforo, "rep": c.rep, "socios": c.socios,
			"estadioNom": c.estadio_nombre if c.estadio_nombre != "" else ("Estadio " + c.nombre),
		},
		"inst": obras.niveles.duplicate(),
		"obras": arr_obras,
		## LOS TERRENOS Y LOS NEGOCIOS, que hasta ahora solo existían como texto
		## en Club → Ciudad. Son lo que convierte la escena en un MAPA -cinco
		## parcelas con su sitio propio- en vez de un único recinto con cosas
		## sueltas alrededor.
		"terrenos": ciudad.terrenos.duplicate() if ciudad != null else [],
		"negocios": ciudad.negocios.duplicate() if ciudad != null else {},
		## El nombre del club para los rótulos del túnel y el vestuario.
		"perfil_estadio": perfil_estadio.merged({"club_nombre": Nombres.visible(c.nombre)}) if not perfil_estadio.is_empty() else perfil_estadio,
		"luces": ciudad.luces if ciudad != null else Ciudad.LUCES_POR_DEFECTO,
		"dia_partido": dia_partido,
		"animo": animo,
		"idolo": idolo,
		"vecinos": ciudad.vecinos if ciudad != null else 55,
	}

func _boton(padre: Node, texto: String, accion: Callable) -> void:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(0, 32)
	b.pressed.connect(accion)
	padre.add_child(b)

func _alternar_giro() -> void:
	_girando = not _girando

func _mover_camara() -> void:
	var o := _objetivo
	_camara.position = Vector3(o.x + sin(_ang) * _dist, _alto, o.z + cos(_ang) * _dist + 20.0)
	_camara.look_at(o, Vector3.UP)

## EL MODO A PIE / AL VOLANTE (7-10-2026): ver `ExploradorCiudad`.
var _explorador: ExploradorCiudad = null
var _barra_mapa: Array[Control] = []

func explorar(modo: String) -> void:
	if _explorador != null:
		return
	_explorador = ExploradorCiudad.new()
	_raiz3d.add_child(_explorador)
	var desde := Vector3(0, 0, CityBuilder.RING_Z_SUR) if modo == "coche" else Vector3(0, 0, -440)
	_explorador.iniciar(_ciudad, modo, desde, club.nombre if club != null else "", String(animo.get("estado", "normal")))
	_explorador.salir.connect(_dejar_de_explorar)
	_explorador.interactuar.connect(_interactuar_en_ciudad)
	for h in get_children():
		if h is Control and (h as Control).visible and h != _ficha:
			(h as Control).visible = false
			_barra_mapa.append(h)

func _dejar_de_explorar() -> void:
	if _explorador == null:
		return
	_explorador.queue_free()
	_explorador = null
	_camara.make_current()
	for h in _barra_mapa:
		if is_instance_valid(h):
			h.visible = true
	_barra_mapa.clear()

## La E en un lugar de la ciudad: la ficha de la instalación, el estadio, o
## un minijuego de la ciudad.
func _interactuar_en_ciudad(k: String) -> void:
	if Instalaciones.CATALOGO.has(k):
		abrir_ficha(k)
		return
	if k == "estadio":
		editar_estadio_pedido.emit()
		return
	var juego := MinijuegosCiudad.juego_de(k)
	## Los edificios con interior: se entra (y si además tienen minijuego,
	## dentro hay un botón para jugarlo).
	if InteriorInstalacion.tiene(k):
		var jugar := Callable()
		if juego != "":
			jugar = func() -> void: _abrir_minijuego(juego)
		_pausar_mientras(InteriorInstalacion.abrir(self, k, club, jugar))
		return
	if juego != "":
		_abrir_minijuego(juego)

func _abrir_minijuego(juego: String) -> void:
	_pausar_mientras(MinijuegosCiudad.abrir(self, juego, club))

## Mientras dura un minijuego o una visita por dentro, el paseo se pausa y su
## cartel se oculta.
## Cuenta las ventanas abiertas: pasar del interior a su minijuego no debe
## soltar la pausa por el camino.
var _pausas := 0

func _pausar_mientras(j: Control) -> void:
	if j != null and _explorador != null:
		_pausas += 1
		_explorador.pausar(true)
		j.tree_exited.connect(func() -> void:
			_pausas = maxi(0, _pausas - 1)
			if _explorador != null and _pausas == 0:
				_explorador.pausar(false))

func _process(delta: float) -> void:
	if _explorador != null:
		if _ciclo_activo:
			_hora = fposmod(_hora + delta * (24.0 / CICLO_SEG), 24.0)
			_aplicar_hora()
		return
	if _girando:
		_ang += delta * 0.12
	## CÁMARA LIBRE (B7): WASD mueve el punto que se mira, en el plano del
	## suelo y según hacia dónde mira la cámara.
	var mov := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	if mov != Vector2.ZERO:
		_desplazar(mov * delta * _dist * 0.9)
	_objetivo = _objetivo.lerp(_objetivo_deseado, clampf(delta * 4.0, 0.0, 1.0))
	if _ciclo_activo:
		_hora = fposmod(_hora + delta * (24.0 / CICLO_SEG), 24.0)
		_aplicar_hora()
	_mover_camara()

## Traduce `_hora` a todo lo que depende de ella. Las cuatro franjas -noche,
## amanecer, día, atardecer- se interpolan entre sí, así que no hay saltos:
## el cambio de color va siempre con la altura del sol, que es lo que pasa de
## verdad.
func _aplicar_hora() -> void:
	## Altura del sol: -1 a medianoche, +1 a mediodía. El seno hace justo esta
	## curva si se desplaza para que el cero caiga a las 6 y a las 18.
	var t: float = (_hora - 6.0) / 12.0 * PI
	var altura: float = sin(t)
	var dia: float = clampf(altura * 2.2, 0.0, 1.0)          ## 1 = pleno día
	var noche: float = clampf(-altura * 3.0, 0.0, 1.0)       ## 1 = noche cerrada
	## El rojizo del horizonte solo existe cuando el sol está justo en él.
	var rasante: float = clampf(1.0 - absf(altura) * 3.4, 0.0, 1.0)

	if _sol != null:
		## El sol recorre el cielo de este a oeste inclinándose con la hora.
		##
		## LA TRAMPA DE LA NOCHE, que costó una ronda: si se deja que la luz
		## baje DE VERDAD por debajo del horizonte, de noche apunta hacia
		## arriba desde el subsuelo y no ilumina absolutamente nada -la ciudad
		## entera desaparecía en negro salvo las ventanas encendidas, que es
		## bonito de foto y horrible para mirar un mapa-. La luz nunca baja de
		## 8°: de noche sigue viniendo de arriba, pero muy floja y azulada, que
		## es exactamente lo que hace la luna.
		var altura_luz: float = maxf(altura, 0.14)
		var base := Basis.IDENTITY
		base = base.rotated(Vector3.UP, deg_to_rad(-42.0))
		base = base.rotated(Vector3(cos(deg_to_rad(-42.0)), 0, -sin(deg_to_rad(-42.0))),
			-asin(clampf(altura_luz, -1.0, 1.0)) - PI * 0.5)
		_sol.transform.basis = base
		var sol_dia := Color(1.0, 0.97, 0.90)
		var sol_rasante := Color(1.0, 0.62, 0.34)
		var luna := Color(0.55, 0.66, 1.0)
		var col: Color = sol_dia.lerp(sol_rasante, rasante)
		_sol.light_color = luna.lerp(col, clampf(dia + rasante * 0.8, 0.0, 1.0))
		## 1,15 y no 1,45: a pleno día con 1,45 el césped y los campos salían
		## lavados, casi blancos. El sol de mediodía quema, pero la cámara de
		## este juego no es una cámara real sin diafragma. Y 0,30 de noche, no
		## 0,06: con 0,06 no se veía el suelo.
		_sol.light_energy = lerpf(0.30, 1.15, dia)
		_sol.shadow_enabled = dia > 0.05

	if _cielo != null:
		var top_dia := Color(0.20, 0.42, 0.78)
		## Azul de noche de verdad, no negro: un cielo negro deja la silueta de
		## los edificios sin contra y el mapa se lee peor, no mejor.
		var top_noche := Color(0.045, 0.06, 0.16)
		var hor_dia := Color(0.78, 0.86, 0.94)
		var hor_rasante := Color(0.98, 0.62, 0.34)
		var hor_noche := Color(0.11, 0.14, 0.26)
		_cielo.set_shader_parameter("top_color", top_noche.lerp(top_dia, dia))
		var horizonte := hor_dia.lerp(hor_rasante, rasante)
		_cielo.set_shader_parameter("horizon_color", hor_noche.lerp(horizonte, clampf(dia + rasante, 0.0, 1.0)))
		## El suelo del cielo sigue al césped -ver la nota de arriba- pero se
		## apaga de noche, o el horizonte quedaría verde fosforito a las 3 AM.
		_cielo.set_shader_parameter("ground_horizon_color", Color(0.13, 0.15, 0.17).lerp(Color(0.62, 0.70, 0.62), dia))
		_cielo.set_shader_parameter("ground_bottom_color", Color(0.08, 0.09, 0.11).lerp(Color(0.36, 0.47, 0.36), dia))
		_cielo.set_shader_parameter("energy_multiplier", lerpf(0.42, 1.0, dia))
		## Las estrellas son del cielo nocturno cerrado, no de todo lo que no
		## sea "pleno día": con `1.0-dia` asomaban ya a media tarde.
		_cielo.set_shader_parameter("noche_cantidad", noche)

	if _env != null:
		## De noche hay que abrir el diafragma o no se ve nada; de día cerrarlo
		## o se quema. Es exactamente lo que hace una cámara de verdad.
		_env.tonemap_exposure = lerpf(1.40, 1.02, dia)
		_env.ambient_light_energy = lerpf(0.62, 1.0, dia)
		if _env.fog_enabled:
			_env.fog_light_color = Color(0.10, 0.12, 0.18).lerp(Color(0.78, 0.80, 0.84), dia)

	## Y las luces de la ciudad: farolas y ventanas encendidas cuando cae el sol.
	if _ciudad != null:
		_ciudad.encender_luces(noche)

	if _reloj != null:
		_reloj.text = "%02d:%02d" % [int(_hora), int(fposmod(_hora, 1.0) * 60.0)]

func alternar_ciclo() -> void:
	_ciclo_activo = not _ciclo_activo

## Arrastrar para girar y rueda para acercar, igual que el proyecto viejo -es
## la forma natural de mirar un complejo entero desde fuera, no un plano fijo
## como el estadio-. Al arrastrar se para el giro automático: si siguiera
## girando solo, el ajuste del jugador se pelearía con él cada fotograma.
##
## CLIC EN EL ESTADIO (16-9-2026): el mapa no tiene colisión -son mallas
## puramente visuales, cajas y modelos sin `CollisionShape3D`-, así que en vez
## de un raycast de físicas se compara la posición del clic contra la
## proyección a pantalla del centro del estadio (`Camera3D.unproject_position`,
## el mismo mecanismo que ya se usó para calibrar el gesto del DT en el podio).
## Un "clic" es down+up sin apenas movimiento entre medio -si no, CUALQUIER
## arrastre para girar la cámara terminaría abriendo el editor sin querer.
var _mouse_down_pos := Vector2.ZERO
var _mouse_down_valido := false
const CLIC_TOLERANCIA_PX := 6.0
const ESTADIO_CLIC_RADIO_PX := 90.0

## Mueve el punto mirado: `d.x` a la derecha de la cámara, `d.y` hacia atrás.
func _desplazar(d: Vector2) -> void:
	var derecha := Vector3(cos(_ang), 0, -sin(_ang))
	var atras := Vector3(sin(_ang), 0, cos(_ang))
	_objetivo_deseado += derecha * d.x + atras * d.y
	_objetivo_deseado.x = clampf(_objetivo_deseado.x, -1400.0, 1400.0)
	_objetivo_deseado.z = clampf(_objetivo_deseado.z, -1400.0, 1400.0)
	_girando = false

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion and (ev.button_mask & (MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE)):
		_desplazar(Vector2(-ev.relative.x, -ev.relative.y) * _dist * 0.0022)
		return
	if ev is InputEventMouseMotion and (ev.button_mask & MOUSE_BUTTON_MASK_LEFT):
		_ang -= ev.relative.x * 0.006
		_alto = clampf(_alto - ev.relative.y * 0.9, 35.0, 520.0)
		_girando = false
		if ev.position.distance_to(_mouse_down_pos) > CLIC_TOLERANCIA_PX:
			_mouse_down_valido = false
	elif ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			_mouse_down_pos = ev.position
			_mouse_down_valido = true
		elif _mouse_down_valido and ev.position.distance_to(_mouse_down_pos) <= CLIC_TOLERANCIA_PX:
			_probar_clic_estadio(ev.position)
	elif ev is InputEventMouseButton and ev.pressed:
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			_dist = clampf(_dist - 60.0, 120.0, 2600.0)
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_dist = clampf(_dist + 60.0, 120.0, 2600.0)

## El clic busca el punto tocable más cercano en pantalla (B7): el estadio
## abre el editor, como siempre; un edificio o un solar abre su ficha.
func _probar_clic_estadio(pos_click: Vector2) -> void:
	var p := punto_en(pos_click)
	if p.is_empty():
		return
	if String(p["estado"]) == "estadio":
		editar_estadio_pedido.emit()
		return
	abrir_ficha(String(p["k"]))

const CLIC_RADIO_PX := 60.0

func punto_en(pos_click: Vector2) -> Dictionary:
	if _camara == null or _ciudad == null:
		return {}
	var mejor: Dictionary = {}
	var mejor_d := INF
	for p: Dictionary in _ciudad.puntos_clic:
		var pos3: Vector3 = p["pos"]
		if _camara.is_position_behind(pos3):
			continue
		var d := _camara.unproject_position(pos3).distance_to(pos_click)
		var radio := ESTADIO_CLIC_RADIO_PX if String(p["estado"]) == "estadio" else CLIC_RADIO_PX
		if d <= radio and d < mejor_d:
			mejor_d = d
			mejor = p
	return mejor

## LA FICHA DE UNA INSTALACIÓN, dentro del mapa: qué es, en qué nivel está,
## qué cuesta el siguiente y el botón para hacerlo. La cámara se acerca a ella.
func abrir_ficha(k: String) -> void:
	if _ficha != null:
		_ficha.queue_free()
	if not Instalaciones.CATALOGO.has(k):
		## Los lugares de la ciudad: su interior o su minijuego (7-10-2026).
		_interactuar_en_ciudad(k)
		return
	for p: Dictionary in _ciudad.puntos_clic:
		if String(p["k"]) == k:
			_objetivo_deseado = p["pos"]
			_dist = minf(_dist, 200.0)
			_girando = false
	var cat: Array = Instalaciones.CATALOGO[k]
	_ficha = PanelContainer.new()
	_ficha.add_theme_stylebox_override("panel", Tema.caja(Color(0.05, 0.08, 0.07, 0.94), Tema.RADIO_GRANDE, Tema.ORO))
	_ficha.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_ficha.offset_left = -360
	_ficha.offset_right = -18
	_ficha.offset_top = 14
	add_child(_ficha)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", Tema.ESPACIO)
	_ficha.add_child(v)
	var nivel := _obras.nivel(k)
	v.add_child(Tema.rotulo("Instalación"))
	v.add_child(Tema.etiqueta(Tema.TAM_TITULO, Tema.TEXTO, String(cat[0])))
	var que := Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, String(cat[1]))
	que.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	que.custom_minimum_size = Vector2(300, 0)
	v.add_child(que)
	var estado := "Solar sin construir" if nivel == 0 else "Nivel %d de %d" % [nivel, _obras.maximo(k)]
	if _obras.en_obra(k):
		estado = "🏗 En obra hacia el nivel %d: faltan %d semanas" % [nivel + 1, int(_obras.obras[k])]
	if nivel > 0:
		var txt_t := ("👥 " + Trabajadores.actual.texto_equipo(club, _obras, k).replace("\n", "\n👥 ")) if Trabajadores.actual != null else ("👤 " + Trabajadores.texto_de(club, k))
		var trab := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, txt_t)
		trab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		trab.custom_minimum_size = Vector2(300, 0)
		v.add_child(trab)
	var l_estado := Tema.etiqueta(Tema.TAM_DESTACADO, Tema.ORO, estado)
	l_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l_estado.custom_minimum_size = Vector2(300, 0)
	v.add_child(l_estado)
	var coste := _obras.coste(k, club.rep)
	var aviso := Tema.etiqueta(Tema.TAM_CUERPO, Tema.MAL, "")
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.custom_minimum_size = Vector2(300, 0)
	if coste > 0 and not _obras.en_obra(k):
		var b := Button.new()
		b.text = "%s  ·  %s  ·  %d sem" % ["Construir" if nivel == 0 else "Mejorar al nivel %d" % (nivel + 1),
			Cesiones.dinero(coste), _obras.semanas_de(k)]
		b.custom_minimum_size = Vector2(0, 36)
		b.disabled = coste > club.saldo
		if coste > club.saldo:
			aviso.text = "No alcanza la caja: tienes %s." % Cesiones.dinero(club.saldo)
		b.pressed.connect(func() -> void:
			var problema: String = String(construir.call(k)) if construir.is_valid() else "no disponible"
			if problema != "":
				aviso.text = "No se puede: %s." % problema
				return
			_reconstruir()
			abrir_ficha(k))
		v.add_child(b)
	elif coste < 0:
		v.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.BIEN, "Al máximo."))
	v.add_child(aviso)
	if nivel > 0 and InteriorInstalacion.tiene(k):
		var dentro := Button.new()
		dentro.text = "🚪 Ver por dentro"
		dentro.custom_minimum_size = Vector2(0, 34)
		dentro.pressed.connect(func() -> void: InteriorInstalacion.abrir(self, k, club))
		v.add_child(dentro)
	var cerrar := Button.new()
	cerrar.text = "Cerrar"
	cerrar.flat = true
	cerrar.pressed.connect(func() -> void:
		_ficha.queue_free()
		_ficha = null)
	v.add_child(cerrar)
	Animar.aparecer(_ficha)

## Vuelve a levantar la ciudad con los datos de ahora (tras construir o al
## cambiar el día de partido).
func _saturacion_animo() -> float:
	return {"euforia": 1.3, "bien": 1.22, "mal": 1.0, "crisis": 0.72}.get(String(animo.get("estado", "")), 1.16)

func _reconstruir() -> void:
	if _env != null:
		_env.adjustment_saturation = _saturacion_animo()
	_ciudad.build(_datos_de(club, _obras, _ciudad_datos, _perfil))
	_ciudad.mostrar_rotulos(_rotulos_visibles)
	_aplicar_hora()
