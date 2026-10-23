extends Control
## (Parte 1 de 2 de `ciudad_vista.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `ciudad_vista.gd`, conserva la clase.)

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

## EL MODO A PIE / AL VOLANTE (7-10-2026): ver `ExploradorCiudad`.
var _explorador: ExploradorCiudad = null
var _barra_mapa: Array[Control] = []

## Mientras dura un minijuego o una visita por dentro, el paseo se pausa y su
## cartel se oculta.
## Cuenta las ventanas abiertas: pasar del interior a su minijuego no debe
## soltar la pausa por el camino.
var _pausas := 0

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

const CLIC_RADIO_PX := 60.0

## Mismo motivo que en `estadio.gd`: colgada de un `Node` en vez de otro
## `Control` se queda en tamaño 0x0 para siempre.
func _ajustar_a_pantalla() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = get_viewport().get_visible_rect().size

## Vuelve a levantar la ciudad con los datos de ahora (tras construir o al
## cambiar el día de partido).
func _saturacion_animo() -> float:
	## Sin pasarse (13-10-2026): con 1,3 la euforia quemaba los colores.
	return {"euforia": 1.14, "bien": 1.09, "mal": 0.96, "crisis": 0.8}.get(String(animo.get("estado", "")), 1.05)

## Traduce `_hora` a todo lo que depende de ella. Las cuatro franjas -noche,
## amanecer, día, atardecer- se interpolan entre sí, así que no hay saltos:
## el cambio de color va siempre con la altura del sol, que es lo que pasa de
## verdad.
func _aplicar_hora() -> void:
	## La gente del club del estadio trabaja de 8 a 21 h.
	PersonalEstadio.hora = _hora
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
		## Luna fría pero no azul eléctrico (13-10-2026: teñía aceras y calles).
		var luna := Color(0.66, 0.72, 0.9)
		var col: Color = sol_dia.lerp(sol_rasante, rasante)
		_sol.light_color = luna.lerp(col, clampf(dia + rasante * 0.8, 0.0, 1.0))
		## 1,15 y no 1,45: a pleno día con 1,45 el césped y los campos salían
		## lavados, casi blancos. El sol de mediodía quema, pero la cámara de
		## este juego no es una cámara real sin diafragma. Y 0,30 de noche, no
		## 0,06: con 0,06 no se veía el suelo.
		_sol.light_energy = lerpf(0.24, 1.15, dia)
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
		## En el renderizador de compatibilidad (móvil, web) el cielo con shader
		## propio no da luz ambiente: lo que queda a la sombra -la espalda de la
		## grada, la copa de los árboles- salía NEGRO a mediodía. Ahí la luz
		## ambiente va como color, el del cielo de esa hora.
		## De noche, el reflejo cálido de las farolas sobre la ciudad (como el
		## sodio de una ciudad real), no un azul puro que lo tiñe todo.
		_env.ambient_light_color = Color(0.24, 0.21, 0.22).lerp(Color(0.62, 0.68, 0.74), dia)
		if Calidad.es_compatibilidad():
			_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		else:
			## Forward+ (15-10-2026): todo el ambiente salía del cielo, que es
			## azul, y lo que quedaba a la sombra (aceras, calzada, fachadas)
			## se teñía de azul. Un 30 % cielo y el resto, el color neutro de arriba.
			_env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
			_env.ambient_light_sky_contribution = 0.3
		if _env.fog_enabled:
			_env.fog_light_color = Color(0.16, 0.13, 0.14).lerp(Color(0.78, 0.80, 0.84), dia)

	## Y las luces de la ciudad: farolas y ventanas encendidas cuando cae el sol.
	if _ciudad != null:
		_ciudad.encender_luces(noche)

	if _reloj != null:
		_reloj.text = "%02d:%02d" % [int(_hora), int(fposmod(_hora, 1.0) * 60.0)]

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
		## El club en sí: el estadio de la ciudad se levanta con su semilla y su
		## escudo, igual que en el partido y en el visor (el MISMO estadio).
		"club_obj": c,
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

func _mover_camara() -> void:
	var o := _objetivo
	_camara.position = Vector3(o.x + sin(_ang) * _dist, _alto, o.z + cos(_ang) * _dist + 20.0)
	_camara.look_at(o, Vector3.UP)

func _boton(padre: Node, texto: String, accion: Callable) -> void:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(0, 32)
	b.pressed.connect(accion)
	padre.add_child(b)

func _alternar_giro() -> void:
	_girando = not _girando

func alternar_ciclo() -> void:
	_ciclo_activo = not _ciclo_activo

func _dejar_de_explorar() -> void:
	if _explorador == null:
		return
	_explorador.queue_free()
	_explorador = null
	_camara.make_current()
	_ciudad.mostrar_rotulos(_rotulos_visibles)
	for h in _barra_mapa:
		if is_instance_valid(h):
			h.visible = true
	_barra_mapa.clear()

func _reconstruir() -> void:
	if _env != null:
		_env.adjustment_saturation = _saturacion_animo()
	_ciudad.build(_datos_de(club, _obras, _ciudad_datos, _perfil))
	_ciudad.mostrar_rotulos(_rotulos_visibles and _explorador == null)
	_aplicar_hora()

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

func _pausar_mientras(j: Control) -> void:
	if j != null and _explorador != null:
		_pausas += 1
		_explorador.pausar(true)
		j.tree_exited.connect(func() -> void:
			_pausas = maxi(0, _pausas - 1)
			if _explorador != null and _pausas == 0:
				_explorador.pausar(false))

func _abrir_minijuego(juego: String) -> void:
	_pausar_mientras(MinijuegosCiudad.abrir(self, juego, club))

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

func explorar(modo: String) -> void:
	if _explorador != null:
		return
	_explorador = ExploradorCiudad.new()
	_raiz3d.add_child(_explorador)
	var desde := Vector3(0, 0, CityBuilder.RING_Z_SUR) if modo == "coche" else Vector3(0, 0, -440)
	_explorador.iniciar(_ciudad, modo, desde, club.nombre if club != null else "", String(animo.get("estado", "normal")))
	_explorador.salir.connect(_dejar_de_explorar)
	_explorador.interactuar.connect(_interactuar_en_ciudad)
	## A pie o en coche, fuera los rótulos del MAPA (nombres flotantes de parques,
	## solares...): a ras de calle se veían repetidos sobre los carteles de verdad.
	_ciudad.mostrar_rotulos(false)
	for h in get_children():
		if h is Control and (h as Control).visible and h != _ficha:
			(h as Control).visible = false
			_barra_mapa.append(h)
