class_name PartidoVivo
extends Control
## El partido, en directo y con el entrenador dentro.
##
## Es la pantalla donde el juego deja de ser una hoja de cálculo. No simula nada:
## le pide un minuto al `Partido` cada tantos milisegundos y pinta lo que las
## señales le van contando. El mismo `Partido` que corre aquí es el que corre en
## el banco de pruebas headless a 8.000 partidos por segundo; lo único que cambia
## es que aquí hay alguien mirando.
##
## Lo que puede hacer el entrenador mientras corre el reloj -mover las perillas y
## meter cambios- se aplica al momento, porque `Partido.cambiar()` invalida la
## fuerza cacheada de los onces. Si no se notara en el marcador, sería un menú
## decorativo, que es el error que este proyecto ya ha pagado varias veces.

signal cerrado

## La misma paleta que css/estilo.css (`:root`), no una propia de Godot.
const COL_FONDO := Color("0c1510")
const COL_PANEL := Color("141c16")
const COL_BORDE := Color("ffffff12")
const COL_TEXTO := Color("e9eeea")
const COL_SUAVE := Color("8ea595")
const COL_ACENTO := Color("3fa06a")
const COL_VERDE := Color("4caf6d")
const COL_ROJO := Color("e05555")
const COL_ORO := Color("c9a227")

## Milisegundos por minuto de juego en cada velocidad. La pausa es la primera
## porque es la que más se usa: es cuando se piensa el cambio.
const VELOCIDADES := [
	{"txt": "Pausa", "ms": 0.0},
	{"txt": "Lento", "ms": 600.0},
	{"txt": "Normal", "ms": 250.0},
	{"txt": "Rápido", "ms": 80.0},
]

var partido: Partido
var mi_club: Club
## El perfil de TU estadio -el que diseñaste en `EstadioPropio`-, calculado por
## quien te abrió esta pantalla (`mundo.perfil_estadio_de()`). Sin esto,
## `_ver_estadio()` caería en el genérico por hash y una reforma pagada nunca
## se vería en el partido en vivo.
var perfil_estadio: Dictionary = {}
## `[claro, oscuro]` de la piel de balón elegida -ver `abrir()`-.
var colores_balon: Array = []
## Lo que va a la PANTALLA GIGANTE del estadio cuando se abre el visor 3D
## (23-9-2026): tabla de la liga, máximos goleadores, nombre del torneo y del
## recinto. Se rellena desde `principal.gd`, que es quien tiene el `Mundo`
## delante; ni esta pantalla ni `VistaEstadio` lo conocen. Vacío es válido:
## la pantalla se queda con los paneles que salen del propio `Partido`.
var datos_pantalla: Dictionary = {}
## Si es un cruce a eliminación directa -Copa nacional, hoy la única que se
## dirige en vivo-, un empate en los 90' no se queda así: hay que jugar los
## penales aquí mismo, o el jugador vería "EMPATE" y se enteraría de quién
## pasó de ronda recién la semana siguiente, leyéndolo en un aviso.
var es_eliminatoria := false

var _velocidad := 2
var _acumulado := 0.0
var _marcador: Label
var _reloj: Label
var _estadisticas: Label
var _cronica: RichTextLabel
var _banquillo: VBoxContainer
var _campo: VBoxContainer
var _botones_vel: Array[Button] = []
var _saliendo: Jugador = null
var _pie: Label
var _btn_volver: Button
## La barra de quien manda ahora mismo. Ver `_construir()`.
var _momentum: ProgressBar
## El panel de estadísticas en vivo, cuarta columna. Ver `_construir()`.
var _panel_stats: VBoxContainer

## El entretiempo. `_entretiempo` es "el camarín está abierto ahora mismo";
## `_entretiempo_hecho` es "ya se paró una vez", para que no vuelva a pararse
## cada minuto a partir del 45.
var _entretiempo := false
var _entretiempo_hecho := false
var _charla_dada := false
var _texto_charla: LineEdit
## Arengas que quedan. Tres por partido: si fueran ilimitadas se arengaría a los
## once en el minuto uno y dejaría de ser una decisión sobre A QUIÉN levantar.
var _arengas: int = 3
## El camarín, que hace falta para la charla. Se recibe en `abrir()` en vez de
## buscarlo: esta pantalla no conoce a `Mundo` y no tiene por qué conocerlo.
var vestuario: Vestuario
## `Roles`, para saber si mandas tú o tu DT empleado -`mando()` del HTML-.
## Igual que `vestuario`, se recibe en vez de buscarlo.
var roles: Roles
## Una vez por partido, igual que `M.palcoUsado` del HTML.
var _palco_usado := false

## `velocidad_inicial`: "Velocidad de partido por defecto" de `vAjustes()`, que
## hasta esta tanda no existía en Godot -cada partido arrancaba siempre en
## el mismo índice fijo (2, "Normal"), sin que el jugador pudiera dejar
## puesta su preferencia-. Sigue el mismo índice que `VELOCIDADES`.
func abrir(p: Partido, club: Club, vest: Vestuario = null, eliminatoria: bool = false, rol: Roles = null, velocidad_inicial: int = -1, perfil_est: Dictionary = {}, colores_bal: Array = []) -> void:
	partido = p
	mi_club = club
	vestuario = vest
	es_eliminatoria = eliminatoria
	roles = rol
	perfil_estadio = perfil_est
	colores_balon = colores_bal
	if velocidad_inicial >= 0 and velocidad_inicial < VELOCIDADES.size():
		_velocidad = velocidad_inicial
	partido.preparar()
	partido.gol.connect(_al_gol)
	partido.remate.connect(_al_remate)
	partido.tarjeta.connect(_a_la_tarjeta)
	partido.decision_arbitral.connect(_a_la_decision_arbitral)
	partido.lesion.connect(_a_la_lesion)
	partido.cambio_hecho.connect(_al_cambio)
	partido.terminado.connect(_al_final)
	_construir()
	_refrescar()
	Sonido.toca("silbato")
	Sonido.toca("murmullo", Sonido.Bus.AMBIENTE)
	_escribir("[color=#8ea595]Empieza el partido en %s.[/color]" % partido.local.nombre)
	## EL VISOR 3D, DE ENTRADA (13-9-2026). Pedido explícito hace semanas
	## ("el visor 3D pasa a ser el ESTÁNDAR de la vista de partido, no un
	## extra opcional") y repetido ahora ("no podemos ver realmente en vivo
	## el partido, el visor debe ser de forma nativa"): `_ver_estadio()`
	## siempre hizo todo lo necesario -abre con el partido de VERDAD dentro,
	## no una maqueta, y el reloj de esta pantalla se para para que mande el
	## de la vista 3D-, pero había que ENCONTRAR el botón "Ver en 3D" para
	## llegar a él. Ahora se abre solo al empezar cualquier partido dirigido:
	## lo primero que se ve ya es el estadio, no un panel de texto con un
	## botón escondido. Cerrar el 3D (✕/"Volver") te devuelve aquí para
	## seguir con cambios, arengas y demás, exactamente como ya funcionaba.
	_ver_estadio()

func _process(delta: float) -> void:
	if partido == null or partido.terminado_ya:
		return
	var ms: float = VELOCIDADES[_velocidad]["ms"]
	if ms <= 0.0:
		return
	_acumulado += delta * 1000.0
	while _acumulado >= ms and not partido.terminado_ya:
		## EL ENTRETIEMPO. El reloj se para solo al llegar al 45 y no sigue
		## hasta que salgas del camarín: si no parara, la charla sería un botón
		## que hay que pulsar a tiempo, y eso no es una decisión, es un reflejo.
		if partido.minuto >= 45 and not _entretiempo_hecho:
			_entretiempo_hecho = true
			_entretiempo = true
			_acumulado = 0.0
			Sonido.toca("silbato")
			_escribir("[color=#c9a227][b]🔵 ENTRETIEMPO.[/b][/color] Camarín abierto: charla, cambios e instrucciones.")
			_refrescar()
			return
		if _entretiempo:
			return
		## LA INVASION DE CAMPO. Minuto 70, perdiendo en casa y con la grada
		## harta: el partido se para veinte minutos con la policia desalojando, y
		## el camarin se vuelve a abrir. Es la unica interrupcion del juego que no
		## la provoca el jugador ni el reglamento: la provoca haberlo hecho mal.
		if not partido.invasion_ya and mi_club != null:
			var animo_hoy := 60
			if vestuario != null and vestuario._mundo() != null and vestuario._mundo().prensa != null:
				animo_hoy = vestuario._mundo().prensa.animo
			var soy_local := partido.local == mi_club
			var mis_goles: int = partido.goles_local if soy_local else partido.goles_visita
			var sus_goles: int = partido.goles_visita if soy_local else partido.goles_local
			if partido.chequear_invasion(animo_hoy, soy_local, mis_goles < sus_goles):
				_entretiempo = true
				_acumulado = 0.0
				Sonido.toca("silbato")
				_escribir("[color=#e05555][b]🚨 INVASION DE CAMPO.[/b][/color] La barra salta al cesped y lanza bengalas. El partido se para: la policia desaloja y los dos equipos se meten al tunel. Vuelve a abrirse el camarin, con otro clima.")
				_refrescar()
				return
		_acumulado -= ms
		partido.simular_minuto()
	_refrescar()

# --- construcción -----------------------------------------------------------

func _construir() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = COL_FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.offset_left = 18; raiz.offset_top = 14
	raiz.offset_right = -18; raiz.offset_bottom = -14
	raiz.add_theme_constant_override("separation", 10)
	add_child(raiz)

	_marcador = _texto(34, COL_TEXTO)
	_marcador.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	raiz.add_child(_marcador)
	_reloj = _texto(15, COL_ORO)
	_reloj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	raiz.add_child(_reloj)
	_estadisticas = _texto(12, COL_SUAVE)
	_estadisticas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	raiz.add_child(_estadisticas)

	## LA BARRA DE MOMENTUM. Es la única cosa de la pantalla que se lee sin leer:
	## de un vistazo dice quién está encima ahora mismo, y cambia de color mucho
	## antes de que cambie el marcador. Mide `Partido.momentum_local()` -el log
	## de los últimos 12 remates y goles, `M.mom` del HTML-, no la posesión: la
	## posesión es una media lenta y ya se ve aparte, en las estadísticas.
	_momentum = ProgressBar.new()
	_momentum.min_value = 0.0
	_momentum.max_value = 100.0
	_momentum.show_percentage = false
	_momentum.custom_minimum_size = Vector2(0, 10)
	raiz.add_child(_momentum)

	## Velocidad del reloj.
	var barra := HBoxContainer.new()
	barra.alignment = BoxContainer.ALIGNMENT_CENTER
	barra.add_theme_constant_override("separation", 6)
	raiz.add_child(barra)
	for i in VELOCIDADES.size():
		var b := Button.new()
		b.text = String(VELOCIDADES[i]["txt"])
		b.toggle_mode = true
		b.button_pressed = (i == _velocidad)
		b.custom_minimum_size = Vector2(86, 30)
		b.pressed.connect(func() -> void: _poner_velocidad(i))
		barra.add_child(b)
		_botones_vel.append(b)
	## El estadio en 3D del club que hace de local. Se abre encima del partido y
	## el reloj se para solo mientras se mira.
	var ver3d := Button.new()
	ver3d.text = "Ver en 3D"
	ver3d.custom_minimum_size = Vector2(110, 30)
	ver3d.pressed.connect(_ver_estadio)
	barra.add_child(ver3d)
	## `saltarAlGol()` del HTML: avanza sin pausas hasta el próximo gol -de
	## cualquiera de los dos-, o hasta el final si no llega ninguno. Antes solo
	## existía el salto directo a "Al final".
	var saltar_gol := Button.new()
	saltar_gol.text = "Al próximo gol"
	saltar_gol.custom_minimum_size = Vector2(100, 30)
	saltar_gol.pressed.connect(_hasta_el_proximo_gol)
	barra.add_child(saltar_gol)
	var saltar := Button.new()
	saltar.text = "Al final"
	saltar.custom_minimum_size = Vector2(86, 30)
	saltar.pressed.connect(_hasta_el_final)
	barra.add_child(saltar)
	## LA PUERTA DE SALIDA. Vivía después de un `return` dentro de `_informe()`
	## -código muerto que nunca se ejecutaba, ni un error lo delataba- así que
	## al terminar un partido en vivo NO había ninguna forma de volver al club:
	## la pantalla se quedaba ahí para siempre. Se crea una vez, oculta, y
	## `_al_final()` la muestra.
	_btn_volver = Button.new()
	_btn_volver.text = "Volver al club"
	_btn_volver.custom_minimum_size = Vector2(110, 30)
	_btn_volver.visible = false
	_btn_volver.pressed.connect(func() -> void: cerrado.emit())
	barra.add_child(_btn_volver)

	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 12)
	raiz.add_child(cols)

	_campo = _columna(cols, "EN EL CAMPO", 1.4)
	## OJO: la crónica NO va dentro de un ScrollContainer.
	##
	## Un RichTextLabel tiene altura mínima cero, así que metido en un scroll se
	## queda con cero de alto y el panel sale VACÍO aunque el texto esté escrito.
	## Costó una captura entera darse cuenta, porque no hay error ni aviso: solo
	## un recuadro en blanco. El RichTextLabel ya sabe hacer scroll él solo, que
	## para eso tiene `scroll_following`.
	var medio := _columna(cols, "CRÓNICA", 2.0, false)
	_cronica = RichTextLabel.new()
	_cronica.bbcode_enabled = true
	_cronica.scroll_following = true
	_cronica.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cronica.add_theme_font_size_override("normal_font_size", 13)
	medio.add_child(_cronica)
	_banquillo = _columna(cols, "BANQUILLO Y PIZARRA", 1.4)
	## LAS ESTADÍSTICAS EN VIVO. `Partido` calcula xG, córners, faltas y fueras
	## cada minuto, y hasta ahora solo se veían al FINAL, en la crónica. Verlas
	## mientras corre el reloj es lo que permite darse cuenta de que estás
	## generando y no entrando -o al revés- a tiempo de hacer algo.
	_panel_stats = _columna(cols, "ESTADÍSTICAS", 1.1)

	_pie = _texto(12, COL_SUAVE)
	_pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	raiz.add_child(_pie)

func _columna(padre: HBoxContainer, titulo: String, ratio: float, con_scroll: bool = true) -> VBoxContainer:
	var caja := PanelContainer.new()
	var e := StyleBoxFlat.new()
	e.bg_color = COL_PANEL
	e.border_color = COL_BORDE
	e.set_border_width_all(1)
	e.set_corner_radius_all(8)
	caja.add_theme_stylebox_override("panel", e)
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.size_flags_stretch_ratio = ratio
	padre.add_child(caja)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 12; v.offset_top = 10; v.offset_right = -12; v.offset_bottom = -10
	caja.add_child(v)
	var t := _texto(11, COL_SUAVE)
	t.text = titulo
	v.add_child(t)
	if not con_scroll:
		return v
	var s := ScrollContainer.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(s)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 2)
	s.add_child(lista)
	return lista

func _texto(tam: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l

func _limpiar(n: Node) -> void:
	for h in n.get_children():
		n.remove_child(h)
		h.queue_free()

# --- reloj ------------------------------------------------------------------

func _poner_velocidad(i: int) -> void:
	_velocidad = i
	for k in _botones_vel.size():
		_botones_vel[k].button_pressed = (k == i)

func _hasta_el_final() -> void:
	while not partido.terminado_ya:
		partido.simular_minuto()
	_refrescar()

func _hasta_el_proximo_gol() -> void:
	var goles_antes := partido.goles_local + partido.goles_visita
	while not partido.terminado_ya and partido.goles_local + partido.goles_visita == goles_antes:
		partido.simular_minuto()
	_refrescar()

## `instrViva('banda')` del HTML: gritar desde la banda baja la ansiedad del
## once un par de puntos, con una de cuatro frases al azar. Protestar de más
## tiene consecuencia real: con el árbitro ya caliente
## (`Federacion.enojo_arbitral>=2`) hay 16% de que te expulsen del área
## técnica.
##
## Simplificación real frente al HTML: el original abre además un CASO DE
## TRIBUNAL que te deja sancionado varios PARTIDOS futuros (`expulsarDT()`/
## `G.dtSusp`, todo un sistema de "disciplina del banquillo" que Godot no
## tiene portado) -aquí la consecuencia se queda en ESTE partido: expulsado,
## no puedes volver a gritar desde la banda hasta el próximo.
const _FRASES_BANDA := [
	"🗣️ Gritas desde la banda: el equipo aprieta los dientes.",
	"👏 Aplaudes de pie: la hinchada te sigue.",
	"😤 Pateas una botella: los tuyos se despiertan.",
	"🧘 Te sientas tranquilo: bajas la ansiedad del equipo.",
]
var _expulsado_banda := false

func _gritar_desde_la_banda() -> void:
	if _expulsado_banda or partido.terminado_ya or vestuario == null:
		return
	var fed := vestuario._mundo().federacion if vestuario._mundo() != null else null
	if fed != null and fed.enojo_arbitral >= 2 and Azar.suerte(0.16):
		_expulsado_banda = true
		_escribir("[color=#e05555][b]🟥 ¡Te expulsan a ti![/b][/color] Protestar de forma airada al cuarto árbitro. Te vas a la tribuna: no puedes volver a gritar desde la banda este partido.")
		_refrescar()
		return
	_escribir("[color=#8ea595]%s[/color]" % Azar.uno(_FRASES_BANDA))
	for j in _mi_once():
		var m := vestuario.mente(j)
		m["ansiedad"] = clampi(int(m["ansiedad"]) - Azar.ent(1, 4), 0, 100)
	_refrescar()

# --- señales del partido ----------------------------------------------------

func _al_gol(club: Club, autor: Jugador, minuto: int, _asistente: Jugador = null) -> void:
	var mio := club == mi_club
	## El sonido va aqui y no en `Partido`: el simulador no sabe si hay alguien
	## mirando, y en el banco de pruebas se juegan miles de partidos sin pantalla.
	## EL SONIDO DE GOL QUE ELEGISTE EN TU ESTADIO -`sfxGol(estilo)` del HTML-.
	## Se podía elegir entre ocho y pagar la reforma, pero aquí sonaba siempre
	## el mismo. Solo en los goles TUYOS: el del rival lleva su propio
	## silencio incómodo. Si el estilo guardado no existe como banco -una
	## partida vieja, un valor raro-, cae al "gol" de siempre en vez de sonar
	## a nada.
	if mio:
		var estilo := "bombo"
		var mu := vestuario._mundo() if vestuario != null else null
		if mu != null and mu.estadio != null:
			estilo = String(mu.estadio.ajustes.get("sonidoGol", "bombo"))
		Sonido.toca("gol_" + estilo if Sonido.catalogo().has("gol_" + estilo) else "gol")
	else:
		Sonido.toca("gol_rival")
	_escribir("[color=%s][b]%d'  ¡GOL de %s![/b][/color]  %s" % [
		"#4caf6d" if mio else "#e05555", minuto, club.nombre,
		autor.nombre if autor else ""])

## Las tres frases y los dos sonidos de "casi gol" del HTML (juego.js:2141,
## 2145, 2149): estaban en `sfx()` desde siempre pero nadie los llamaba en
## Godot porque `Partido` solo contaba el remate y no decia como habia
## terminado. El sonido, igual que en `_al_gol`, solo suena si el remate es
## mio -asi lo hacia el HTML tambien-: los remates fallados del rival no
## interrumpen el murmullo de fondo.
const _FRASES_ATAJADA := [
	"🧤 Atajada del arquero tras remate de ",
	"🧤 Manotazo salvador ante el remate de ",
	"🧤 Vuela y saca al córner el disparo de ",
]
const _FRASES_FALLO := [
	"❌ Ocasión clara fallada",
	"😱 La manda a las nubes",
	"🙈 Se le va por poco",
	"🥅 Solo frente al arquero y la tira afuera",
]

func _al_remate(club: Club, autor: Jugador, tipo: String, minuto: int) -> void:
	var mio := club == mi_club
	var nombre := autor.nombre if autor else ""
	match tipo:
		"atajada":
			if mio:
				Sonido.toca("atajada")
			_escribir("[color=#8ea595]%d'  %s%s[/color]" % [minuto, Azar.uno(_FRASES_ATAJADA), nombre])
		"poste":
			if mio:
				Sonido.toca("ocasion")
			_escribir("[color=#8ea595]%d'  🪵 ¡Al palo! Increíble ocasión de %s[/color]" % [minuto, nombre])
		_:
			var frase: String = Azar.uno(_FRASES_FALLO)
			if nombre != "":
				frase += " — " + nombre
			_escribir("[color=#8ea595]%d'  %s[/color]" % [minuto, frase])

func _a_la_tarjeta(j: Jugador, roja: bool, minuto: int) -> void:
	Sonido.toca("roja" if roja else "amarilla")
	if roja:
		_escribir("[color=#e05555]%d'  ROJA a %s.[/color] Se va a la calle." % [minuto, j.nombre])
	elif j.club_id == mi_club.id:
		## Solo se cuentan las amarillas de los tuyos: las del rival son ruido
		## que tapa lo que sí importa.
		_escribir("[color=#c9a227]%d'  Amarilla a %s.[/color]" % [minuto, j.nombre])

## Lo que decide el árbitro por su cuenta -`_arb`/`decision_arbitral` de
## `Partido`-. Se narra siempre, pase lo que pase con la tarjeta o el gol de
## penal que la misma jugada pueda traer detrás: es la frase que explica el
## PORQUÉ, y esa nadie más la cuenta.
func _a_la_decision_arbitral(texto: String, minuto: int) -> void:
	_escribir("[color=#c9a227]%d'  %s[/color]" % [minuto, texto])

func _a_la_lesion(j: Jugador, semanas: int, minuto: int) -> void:
	var mio := j.club_id == mi_club.id
	## Sonido nuevo, sin equivalente en el HTML: hasta hoy una lesión sonaba
	## exactamente igual que nada -Godot no tenia mas efectos que los que ya
	## traia sfx()-. Solo suena cuando es tuyo: la lesión del rival es una
	## buena noticia y no merece el mismo golpe seco.
	if mio:
		Sonido.toca("lesion")
	_escribir("[color=%s]%d'  %s cae lesionado: %d semana%s fuera.[/color]%s" % [
		"#e05555" if mio else "#8ea595", minuto, j.nombre, semanas,
		"" if semanas == 1 else "s",
		"  [color=#c9a227]Te toca mover el banquillo.[/color]" if mio else ""])
	if mio:
		_poner_velocidad(0)   ## se para el reloj: hay una decisión que tomar

func _al_cambio(sale: Jugador, entra: Jugador, minuto: int) -> void:
	## Otro sonido nuevo: `cambio_hecho` solo lo dispara ESTE lado (el rival
	## cambia sin pasar por aqui), asi que suena siempre, sin comprobar "mio".
	Sonido.toca("cambio")
	_escribir("[color=#3fa06a]%d'  Cambio: entra %s por %s.[/color]" % [minuto, entra.nombre, sale.nombre])

func _al_final(gl: int, gv: int) -> void:
	Sonido.toca("pitido_final")
	var mio_local := partido.local == mi_club
	var mios := gl if mio_local else gv
	var suyos := gv if mio_local else gl
	var texto := "VICTORIA" if mios > suyos else ("DERROTA" if mios < suyos else "EMPATE")
	var color := "#4caf6d" if mios > suyos else ("#e05555" if mios < suyos else "#8ea595")
	_escribir("")
	_escribir("[color=%s][b]FINAL. %s.[/b][/color]  %s %d-%d %s" % [
		color, texto, partido.local.nombre, gl, gv, partido.visita.nombre])
	_escribir_goles()
	## LOS PENALES. En una eliminatoria un empate no se queda así -`Copa.
	## jugar_ronda()` los va a pedir de todos modos al avanzar la semana, para
	## saber quién sigue vivo-, así que se juegan aquí mismo y se cuentan: sin
	## esto el jugador veía "EMPATE" y se enteraba de quién pasaba de ronda la
	## semana siguiente, leyéndolo en un aviso. `Partido.penales()` queda
	## memoizado, así que cuando `Copa` los vuelva a pedir sobre este mismo
	## objeto recibe el MISMO resultado, no uno tirado de nuevo.
	if es_eliminatoria and gl == gv:
		var pen := partido.penales()
		var gano_local := int(pen[0]) > int(pen[1])
		var pase_mio := gano_local == mio_local
		_escribir("")
		_escribir("[color=#c9a227][b]🥅 PENALES.[/b][/color]  %s %d-%d %s" % [
			partido.local.nombre, int(pen[0]), int(pen[1]), partido.visita.nombre])
		_escribir("[color=%s][b]%s[/b][/color]" % [
			"#4caf6d" if pase_mio else "#e05555",
			"Pasas de ronda en la tanda de penales." if pase_mio else "Quedas eliminado en la tanda de penales."])
	_escribir_estadisticas(mio_local)
	_escribir("")
	_escribir("[color=#c9a227][b]📋 Informe del ayudante.[/b][/color] %s" % _informe(mio_local, mios, suyos))
	_escribir_notas()
	_btn_volver.visible = true
	_refrescar()

## LA LISTA DE GOLES de `vPost()`. `Partido.cronica` guarda cada gol con minuto y
## autor desde siempre; lo que faltaba era volver a leerla al terminar, para que
## el resultado no sea solo un marcador sino quién lo hizo y cuándo.
func _escribir_goles() -> void:
	var hubo := false
	for e: Dictionary in partido.cronica:
		if String(e.get("tipo", "")) != "gol":
			continue
		if not hubo:
			_escribir("")
			_escribir("[color=#8ea595]GOLES[/color]")
			hubo = true
		var de_los_mios := String(e.get("club", "")) == mi_club.id
		_escribir("[color=%s]  %d'  %s[/color]" % [
			"#4caf6d" if de_los_mios else "#e05555",
			int(e.get("min", 0)), String(e.get("autor", "?"))])

## LAS NOTAS DEL ONCE y la FIGURA DEL PARTIDO. El motor puntúa a cada jugador y
## la nota se guarda en `Jugador.notas` —la usa la satisfacción del vestuario y
## la media de temporada— pero al acabar un partido no se veía por ningún lado:
## había que ir jugador por jugador a su ficha para saber quién había jugado
## bien. Es de las cosas que más se miran al pitido final.
func _escribir_notas() -> void:
	var once := _mi_once()
	if once.is_empty():
		return
	var mejor: Jugador = null
	var peor: Jugador = null
	for j in once:
		if j.notas.is_empty():
			continue
		var n := float(j.notas[j.notas.size() - 1])
		if mejor == null or n > float(mejor.notas[mejor.notas.size() - 1]):
			mejor = j
		if peor == null or n < float(peor.notas[peor.notas.size() - 1]):
			peor = j
	if mejor != null:
		_escribir("")
		_escribir("[color=#c9a227][b]🏅 Figura del partido:[/b][/color] %s (%.1f)" % [
			mejor.nombre, float(mejor.notas[mejor.notas.size() - 1])])
	## El aviso del peor solo si de verdad fue mal: por debajo de 5,6, que es el
	## umbral del HTML. Señalar al menos bueno de un partido bueno es ruido.
	if peor != null and float(peor.notas[peor.notas.size() - 1]) < 5.6:
		_escribir("[color=#8ea595]⚠️ %s terminó con %.1f: conviene revisar su puesto o darle descanso.[/color]" % [
			peor.nombre, float(peor.notas[peor.notas.size() - 1])])
	_escribir("")
	_escribir("[color=#8ea595]NOTAS DEL EQUIPO[/color]")
	for j in once:
		if j.notas.is_empty():
			continue
		var n2 := float(j.notas[j.notas.size() - 1])
		var col := "#4caf6d" if n2 >= 7.5 else ("#e05555" if n2 < 5.5 else "#e9eeea")
		_escribir("[color=#8ea595]  %s[/color] %s   [color=%s][b]%.1f[/b][/color]" % [j.pos_e, j.nombre, col, n2])

## El cuadro de "ESTADÍSTICAS DEL PARTIDO" de `vPost()`, en texto: siete filas
## con el tuyo primero, ganes o pierdas, seas local o visitante -leer tu propia
## columna a la izquierda es lo que hace que un vistazo baste.
func _escribir_estadisticas(mio_local: bool) -> void:
	var p := partido
	var pos_l := int(round(p.posesion_local))
	var filas := [
		["Posesión", "%d%%" % pos_l, "%d%%" % (100 - pos_l)],
		["Remates", str(p.remates_local), str(p.remates_visita)],
		["Al arco", str(p.tiros_puerta_local), str(p.tiros_puerta_visita)],
		["xG (goles esperados)", "%.2f" % p.xg_local, "%.2f" % p.xg_visita],
		["Córners", str(p.corners_local), str(p.corners_visita)],
		["Faltas", str(p.faltas_local), str(p.faltas_visita)],
		["Fuera de juego", str(p.fueras_local), str(p.fueras_visita)],
	]
	_escribir("")
	_escribir("[color=#8ea595]ESTADÍSTICAS DEL PARTIDO[/color]")
	for f: Array in filas:
		var mio: String = f[1] if mio_local else f[2]
		var suyo: String = f[2] if mio_local else f[1]
		_escribir("[color=#8ea595]%s[/color]   [b]%s[/b] - %s" % [String(f[0]), mio, suyo])

## `infPostPartido()` del HTML, frase por frase: el ayudante te cuenta lo que
## las cifras dicen y el marcador no. Es lo que convierte el xG en algo que se
## entiende sin saber qué es el xG.
func _informe(mio_local: bool, mios: int, suyos: int) -> String:
	var p := partido
	var pos := int(round(p.posesion_local)) if mio_local else 100 - int(round(p.posesion_local))
	var xg_mio: float = p.xg_local if mio_local else p.xg_visita
	var xg_suyo: float = p.xg_visita if mio_local else p.xg_local
	var faltas_mias: int = p.faltas_local if mio_local else p.faltas_visita
	var cambios_mios: int = p.cambios_local if mio_local else p.cambios_visita
	var dif := mios - suyos
	var frases: Array[String] = []
	frases.append("Nos llevamos los tres puntos." if dif > 0 else ("Reparto de puntos." if dif == 0 else "Se nos escapó."))
	if pos >= 60:
		frases.append("Tuvimos la pelota casi todo el partido (%d%%): el plan de circulación funcionó." % pos)
	elif pos <= 42:
		frases.append("Les cedimos la pelota (%d%%) y jugamos al contragolpe." % pos)
	else:
		frases.append("Partido parejo en el control del balón (%d%%)." % pos)
	if float(mios) > xg_mio + 1.0:
		frases.append("Los delanteros estuvieron finísimos: convertimos más de lo que la estadística decía (xG %.2f)." % xg_mio)
	elif xg_mio > float(mios) + 1.0:
		frases.append("Generamos mucho más de lo que anotamos (xG %.2f): falta puntería." % xg_mio)
	if xg_suyo > float(suyos) + 1.0:
		frases.append("El arquero nos salvó: el rival mereció más.")
	elif float(suyos) > xg_suyo + 1.0:
		frases.append("Nos hicieron goles baratos, con poco.")
	if faltas_mias > 16:
		frases.append("Cometimos demasiadas faltas: con otro árbitro terminamos con diez.")
	if absi(dif) >= 3:
		frases.append("Goleada que va a levantar el ánimo de todo el club." if dif > 0 else "Goleada en contra: hay que hablar en el camarín.")
	if cambios_mios == 0:
		frases.append("No usaste cambios: el once terminó fundido.")
	return " ".join(frases)

func _escribir(bbcode: String) -> void:
	_cronica.append_text(bbcode + "\n")

# --- pintado ----------------------------------------------------------------

func _refrescar() -> void:
	_marcador.text = "%s   %d - %d   %s" % [
		partido.local.nombre, partido.goles_local, partido.goles_visita, partido.visita.nombre]
	_reloj.text = "%d'" % partido.minuto if not partido.terminado_ya else "FINAL"
	## La línea de arriba, en vivo: lo que se mira de reojo mientras corre el
	## reloj. El desglose completo -xG, córners, faltas, fueras- va al final, en
	## la crónica, que es donde el HTML lo pone (`vPost`).
	_estadisticas.text = "Posesión  %d%% - %d%%      Remates  %d - %d      Al arco  %d - %d      Cambios  %d - %d de %d" % [
		int(round(partido.posesion_local)), 100 - int(round(partido.posesion_local)),
		partido.remates_local, partido.remates_visita,
		partido.tiros_puerta_local, partido.tiros_puerta_visita,
		partido.cambios_local, partido.cambios_visita, Partido.MAX_CAMBIOS]
	## `M.mom` del HTML: quién está encima AHORA MISMO según el ritmo reciente
	## de ocasiones, no la posesión acumulada -eso ya se ve aparte, en el texto
	## de estadísticas de más arriba-. La barra siempre mide LO TUYO, seas local
	## o visitante: si midiera al local el jugador tendría que acordarse de en
	## qué lado juega para interpretarla, y entonces ya no se lee de un vistazo.
	var mom := float(partido.momentum_local())
	var mia := mom if partido.local == mi_club else 100.0 - mom
	_momentum.value = mia
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = COL_VERDE if mia >= 55.0 else (COL_ROJO if mia <= 45.0 else COL_ORO)
	relleno.set_corner_radius_all(3)
	_momentum.add_theme_stylebox_override("fill", relleno)
	_pintar_campo()
	_pintar_banquillo()
	_pintar_estadisticas_vivo()

func _mi_once() -> Array[Jugador]:
	return partido.once_local if partido.local == mi_club else partido.once_visita

func _mis_cambios() -> int:
	return partido.cambios_local if partido.local == mi_club else partido.cambios_visita

## `mando()` del HTML: si tu rol es despacho/dueño/cantera/ayudante, el once
## no lo pones tú -lo pone tu DT empleado-. `Roles.manda()` ya es ese mismo
## booleano, portado hace tiempo, solo que ninguna pantalla lo consultaba
## todavía: el ayudante o el dueño podían tocar la pizarra y los cambios en
## vivo exactamente igual que un DT.
func _en_palco() -> bool:
	return roles != null and roles.manda()

func _pintar_campo() -> void:
	_limpiar(_campo)
	if _en_palco():
		var av := _texto(11, COL_SUAVE)
		av.text = "🥂 Dirige %s desde el banquillo. Los cambios y la charla son cosa suya." % roles.dt_nombre()
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_campo.add_child(av)
		for j in _mi_once():
			var l := _texto(12, COL_ORO if partido.con_impulso(j) else COL_TEXTO)
			l.text = "%s%s  %s  %d" % ["🔥 " if partido.con_impulso(j) else "", j.pos_e, j.nombre, j.ovr]
			_campo.add_child(l)
		return
	var ayuda := _texto(11, COL_SUAVE)
	ayuda.text = "Pulsa a quién sacas." if _saliendo == null else "Ahora, quién entra."
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_campo.add_child(ayuda)
	## LAS ARENGAS. Gritarle a uno desde la banda: le sube la moral y rinde un
	## 12% más durante dieciocho minutos. Tres por partido, porque si fueran
	## ilimitadas se arengaría a los once en el minuto uno y dejaría de ser una
	## decisión sobre A QUIÉN levantar.
	var ta := _texto(11, COL_ORO)
	ta.text = "📣 ARENGAS  ·  te quedan %d" % _arengas
	_campo.add_child(ta)
	for j in _mi_once():
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 4)
		_campo.add_child(fila)
		var encendido := partido.con_impulso(j)
		var b := Button.new()
		b.text = "%s%s  %s  %d" % ["🔥 " if encendido else "", j.pos_e, j.nombre, j.ovr]
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_color_override("font_color",
			COL_ORO if encendido else (COL_ACENTO if j == _saliendo else COL_TEXTO))
		b.disabled = partido.terminado_ya
		b.pressed.connect(func() -> void:
			_saliendo = null if _saliendo == j else j
			_refrescar())
		fila.add_child(b)
		var ba := Button.new()
		ba.text = "📣"
		ba.tooltip_text = "Arengarle: le sube la moral y rinde un 12% más durante 18 minutos."
		ba.add_theme_font_size_override("font_size", 11)
		ba.custom_minimum_size = Vector2(34, 0)
		ba.disabled = partido.terminado_ya or _arengas <= 0 or encendido
		ba.pressed.connect(func() -> void: _arengar(j))
		fila.add_child(ba)

## EL CAMARÍN DEL ENTRETIEMPO. Va arriba del todo del panel derecho y solo
## existe mientras el reloj está parado en el 45: es lo único que hay que
## resolver en ese momento, y si estuviera siempre visible dejaría de ser un
## momento.
##
## Los seis tonos NO son seis grados de lo mismo: cada uno tiene su margen, y
## los de más recorrido son los que más pueden hundirte. "Sacudir" va de -9 a
## +14, así que es la jugada del que va perdiendo y no tiene nada que perder.
func _pintar_camarin() -> void:
	var v := vestuario
	if v == null:
		return
	var t := _texto(13, COL_ORO)
	t.text = "🔵 CAMARÍN — ENTRETIEMPO"
	_banquillo.add_child(t)
	## Desde el palco no se habla en el camarín -es cosa de tu DT empleado-,
	## pero el partido tiene que poder seguir: la única puerta es salir a la
	## segunda parte.
	if _en_palco():
		var ap := _texto(11, COL_SUAVE)
		ap.text = "%s da la charla. No es cosa tuya." % roles.dt_nombre()
		ap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_banquillo.add_child(ap)
		var salir_p := Button.new()
		salir_p.text = "▶️  Salir a la segunda parte"
		salir_p.custom_minimum_size = Vector2(0, 30)
		salir_p.pressed.connect(_salir_segunda)
		_banquillo.add_child(salir_p)
		_banquillo.add_child(HSeparator.new())
		return
	if _charla_dada:
		var ya := _texto(11, COL_SUAVE)
		ya.text = "Ya has hablado. Puedes hacer cambios y mover la pizarra antes de salir."
		ya.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_banquillo.add_child(ya)
	else:
		var ay := _texto(11, COL_SUAVE)
		ay.text = "A un líder o a una muralla les va la exigencia; a un frágil o a un cerebro, el elogio."
		ay.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_banquillo.add_child(ay)
		var rej := GridContainer.new()
		rej.columns = 3
		_banquillo.add_child(rej)
		for clave: String in Vestuario.TONOS:
			var fila: Array = Vestuario.TONOS[clave]
			var b := Button.new()
			b.text = "%s %s" % [String(fila[1]), String(fila[0])]
			b.add_theme_font_size_override("font_size", 11)
			b.tooltip_text = "Efecto en la moral: de %d a %d. Ansiedad: %+d." % [int(fila[2]), int(fila[3]), int(fila[4])]
			var k := clave
			b.pressed.connect(func() -> void: _dar_charla(k))
			rej.add_child(b)
		## La charla escrita: el tono se deduce de lo que escribes. Es lo más
		## barato del sistema y lo que más mete en el papel — decir "así no,
		## señores" y ver que el equipo lo acusa vale más que elegir de una lista.
		_texto_charla = LineEdit.new()
		_texto_charla.placeholder_text = "…o díselo con tus palabras y pulsa Enter"
		_texto_charla.add_theme_font_size_override("font_size", 12)
		_texto_charla.text_submitted.connect(_charla_libre)
		_banquillo.add_child(_texto_charla)
	var salir := Button.new()
	salir.text = "▶️  Salir a la segunda parte"
	salir.custom_minimum_size = Vector2(0, 30)
	salir.pressed.connect(_salir_segunda)
	_banquillo.add_child(salir)
	_banquillo.add_child(HSeparator.new())

func _dar_charla(tono: String) -> void:
	var v := vestuario
	if v == null or _charla_dada:
		return
	var r: Dictionary = v.charla(_mi_once(), tono)
	_charla_dada = true
	_escribir("[color=#c9a227]%s Charla (%s):[/color] %s. (%d ↑ / %d ↓)" % [
		String(r["icono"]), String(r["nombre"]).to_lower(), String(r["reaccion"]),
		int(r["suben"]), int(r["bajan"])])
	Sonido.toca("clic", Sonido.Bus.INTERFAZ)
	_refrescar()

func _charla_libre(texto: String) -> void:
	var v := vestuario
	if v == null or _charla_dada:
		return
	var limpio := texto.strip_edges()
	if limpio == "":
		return
	_escribir("[color=#e9eeea]🗣️ «%s»[/color]" % limpio.substr(0, 110))
	_dar_charla(v.tono_de_texto(limpio))

func _salir_segunda() -> void:
	if not _charla_dada:
		_escribir("[color=#8ea595]🤐 Te quedaste callado en el camarín. El equipo sale como entró.[/color]")
	_entretiempo = false
	_escribir("[color=#8ea595]▶️ Comienza la segunda parte.[/color]")
	_refrescar()

func _pintar_banquillo() -> void:
	_limpiar(_banquillo)
	if _entretiempo:
		_pintar_camarin()
	if _en_palco():
		_pintar_palco()
		return
	## La pizarra: las perillas se pueden mover con el partido en marcha, y se
	## nota en el minuto siguiente porque `Partido` vuelve a medir los onces.
	_perilla("Mentalidad", ["Defensiva", "Equilibrada", "Ofensiva"], mi_club.tactica.mentalidad,
		func(v: int) -> void: mi_club.tactica.mentalidad = v)
	_perilla("Presión", ["Baja", "Media", "Alta"], mi_club.tactica.presion,
		func(v: int) -> void: mi_club.tactica.presion = v)
	_perilla("Ritmo", ["Lento", "Medio", "Alto"], mi_club.tactica.ritmo,
		func(v: int) -> void: mi_club.tactica.ritmo = v)
	_perilla("Línea", ["Baja", "Media", "Adelantada"], mi_club.tactica.linea,
		func(v: int) -> void: mi_club.tactica.linea = v)

	## INSTRUCCIONES EN VIVO -`instrViva('riesgo'/'tiempo'/'banda')` del HTML-:
	## a diferencia de la pizarra de arriba (persistente), esto se resetea solo
	## con el partido. Estaba escrito en `Partido` pero sin ningún botón que lo
	## tocara.
	_banquillo.add_child(HSeparator.new())
	var ti := _texto(11, COL_SUAVE)
	ti.text = "INSTRUCCIONES EN VIVO"
	_banquillo.add_child(ti)
	var fi := HFlowContainer.new()
	_banquillo.add_child(fi)
	var br := Button.new()
	br.text = "%s Todo al ataque" % ("✅" if partido.instr_riesgo else "⬜")
	br.disabled = partido.terminado_ya
	br.pressed.connect(func() -> void:
		partido.instr_riesgo = not partido.instr_riesgo
		_escribir("[color=#8ea595]%d'  📋 %s.[/color]" % [partido.minuto,
			"Todos arriba: se juega a todo o nada." if partido.instr_riesgo else "Vuelve el orden: se deja de arriesgar."])
		_refrescar())
	fi.add_child(br)
	var bt := Button.new()
	bt.text = "%s Perder tiempo" % ("✅" if partido.instr_tiempo else "⬜")
	bt.disabled = partido.terminado_ya
	bt.pressed.connect(func() -> void:
		partido.instr_tiempo = not partido.instr_tiempo
		_escribir("[color=#8ea595]%d'  📋 %s.[/color]" % [partido.minuto,
			"Ordenas perder tiempo y cerrar el partido." if partido.instr_tiempo else "Se acabó el manejo de tiempos: a jugar."])
		_refrescar())
	fi.add_child(bt)
	var bb := Button.new()
	bb.text = "🗣️ Gritar desde la banda"
	bb.disabled = partido.terminado_ya or _expulsado_banda
	bb.pressed.connect(_gritar_desde_la_banda)
	fi.add_child(bb)

	var sep := HSeparator.new()
	_banquillo.add_child(sep)
	var t := _texto(11, COL_SUAVE)
	t.text = "SUPLENTES  (%d de %d cambios usados)" % [_mis_cambios(), Partido.MAX_CAMBIOS]
	_banquillo.add_child(t)

	var en_campo := _mi_once()
	for j in mi_club.plantilla:
		if en_campo.has(j):
			continue
		var b := Button.new()
		b.text = "%s  %s  %d%s" % [j.pos_e, j.nombre, j.ovr, "" if j.disponible() else "  (fuera)"]
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_color_override("font_color", COL_TEXTO if j.disponible() else COL_ROJO)
		## Solo se puede meter a alguien cuando ya se ha elegido a quién sacar:
		## así no hay forma de terminar con doce en el campo por un clic de más.
		b.disabled = partido.terminado_ya or _saliendo == null or not j.disponible()
		b.pressed.connect(func() -> void: _hacer_cambio(j))
		_banquillo.add_child(b)

## `🥂 PALCO PRESIDENCIAL` del HTML: no diriges, así que no hay perillas, ni
## cambios, ni arengas, ni instrucciones en vivo -eso es cosa de tu DT
## empleado-. Solo puedes mirar la sintonía y, una vez por partido, bajar al
## borde del campo a presionar.
func _pintar_palco() -> void:
	var t := _texto(11, COL_SUAVE)
	t.text = "🥂 PALCO PRESIDENCIAL"
	_banquillo.add_child(t)
	var cargo := roles.nombre_del_cargo() if roles != null else "directivo"
	var p := _texto(11, COL_SUAVE)
	p.text = "Dirige %s. Los cambios, la charla y las instrucciones son cosa suya: tú solo puedes mirar… o hacerte notar." % (roles.dt_nombre() if roles != null else "tu DT")
	p.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banquillo.add_child(p)
	if roles != null and not roles.dt_empleado.is_empty():
		var sin := int(roles.dt_empleado.get("sintonia", 60))
		_dato_banquillo("Sintonía con %s" % roles.dt_nombre(), "%d/100" % sin,
			COL_VERDE if sin >= 50 else COL_ROJO)
	var bp := Button.new()
	bp.text = "😠 Bajar al borde del campo"
	bp.disabled = partido.terminado_ya or _palco_usado
	bp.pressed.connect(_presionar_desde_el_palco)
	_banquillo.add_child(bp)
	_banquillo.add_child(HSeparator.new())
	var t2 := _texto(11, COL_SUAVE)
	t2.text = "%s  (cargo: %s)" % ["EL ONCE", cargo]
	_banquillo.add_child(t2)
	for j in _mi_once():
		var l := _texto(12, COL_TEXTO)
		l.text = "%s  %s  %d" % [j.pos_e, j.nombre, j.ovr]
		_banquillo.add_child(l)

## Una fila "etiqueta … valor" para el panel del banquillo, mismo patrón que
## `_dato()` de `principal.gd` pero sin depender de esa pantalla.
func _dato_banquillo(etiqueta: String, valor: String, color: Color) -> void:
	var h := HBoxContainer.new()
	var a := _texto(11, COL_SUAVE)
	a.text = etiqueta
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	a.clip_text = true
	h.add_child(a)
	var b := _texto(11, color)
	b.text = valor
	h.add_child(b)
	_banquillo.add_child(h)

## `presionarDesdePalco()` del HTML: una vez por partido, desde el palco no se
## dirige pero se puede bajar al borde del campo. 55% de que salga bien -sube
## la moral del once 3 puntos-, 45% de que se lea como desconfianza -baja 2-.
## Cueste lo que cueste, la sintonía con el DT cae 9 puntos: la injerencia
## siempre tiene un precio. El HTML de paso sube el ritmo a "a mil"
## (`M.instr.ritmo=2`) cuando sale bien -no portado a propósito: Godot no
## tiene una capa efímera de ritmo, solo la perilla PERSISTENTE de
## `Club.tactica`, y tocarla desde el palco contradiría la premisa de que
## desde ahí no se toca la pizarra-.
func _presionar_desde_el_palco() -> void:
	if _palco_usado or partido.terminado_ya or roles == null:
		return
	_palco_usado = true
	var cargo := roles.nombre_del_cargo()
	if Azar.suerte(0.55):
		_escribir("[color=#8ea595]👔 El %s baja al borde del campo. El equipo se sacude y sube una marcha.[/color]" % cargo)
		for j in _mi_once():
			j.moral = clampi(j.moral + 3, 10, 99)
	else:
		_escribir("[color=#e0a832]👔 Bajas al borde del campo y las cámaras lo enfocan todo. El vestuario lo lee como desconfianza.[/color]")
		for j in _mi_once():
			j.moral = clampi(j.moral - 2, 10, 99)
	if not roles.dt_empleado.is_empty():
		var s := clampi(int(roles.dt_empleado.get("sintonia", 60)) - 9, 0, 100)
		roles.dt_empleado["sintonia"] = s
		if s < 18:
			_escribir("[color=#e05555]Ruptura en el cuerpo técnico:[/color] %s no aguanta más la injerencia desde arriba." % roles.dt_nombre())
	Sonido.toca("clic", Sonido.Bus.INTERFAZ)
	_refrescar()

func _perilla(etiqueta: String, opciones: Array, actual: int, al_cambiar: Callable) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	_banquillo.add_child(h)
	var l := _texto(11, COL_SUAVE)
	l.text = etiqueta
	l.custom_minimum_size = Vector2(74, 0)
	h.add_child(l)
	for i in opciones.size():
		var b := Button.new()
		b.text = String(opciones[i])
		b.toggle_mode = true
		b.button_pressed = (i == actual)
		b.add_theme_font_size_override("font_size", 11)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			al_cambiar.call(i)
			partido.invalidar_fuerza()
			_escribir("[color=#8ea595]%d'  %s: %s.[/color]" % [partido.minuto, etiqueta, opciones[i]])
			_refrescar())
		h.add_child(b)

func _hacer_cambio(entra: Jugador) -> void:
	if _saliendo == null:
		return
	var problema := partido.cambiar(_saliendo, entra)
	if problema != "":
		_escribir("[color=#e05555]No se puede: %s.[/color]" % problema)
	_saliendo = null
	_refrescar()

## Abre el estadio del local en 3D, encima del partido.
##
## El reloj se para mientras tanto: si siguiera corriendo, el jugador volvería
## del estadio y se habría perdido veinte minutos de su propio partido.
func _ver_estadio() -> void:
	var antes := _velocidad
	_poner_velocidad(0)
	## BUG REAL, ENCONTRADO CON UNA CAPTURA (13-9-2026): un comentario de
	## `principal.gd` decía que esta pantalla "ya deja hueco de sobra" para el
	## 3D y por eso no hacía falta esconder nada. Era una suposición nunca
	## comprobada con una imagen: `_pintar_campo()` + `_pintar_camarin()` +
	## `_pintar_banquillo()` + `_pintar_estadisticas_vivo()` cubren la
	## pantalla ENTERA, borde a borde. `VistaEstadio` se construía perfecto
	## -con el partido de verdad dentro- y quedaba invisible detrás: Godot
	## pinta los `Control` SIEMPRE encima del 3D, sin importar el orden de los
	## nodos. El botón "Ver en 3D" durante un partido dirigido probablemente
	## nunca mostró nada. Mismo arreglo que ya usa
	## `principal.gd::_ver_estadio_propio()`: esconder los hijos visibles
	## propios y devolverlos tal cual al volver.
	##
	## Y NO BASTA CON ESCONDER LOS PROPIOS: `PartidoVivo` vive colgado de
	## `principal.gd` (`_dirigir()` hace `add_child(vivo)` sobre sí mismo), y
	## esa pantalla de abajo -tabla, cabecera, pestañas- es OTRO Control
	## opaco en el mismo viewport. Escondiendo solo los hijos de aquí, la
	## primera prueba con captura real seguía mostrando el panel del club por
	## debajo: dos capas del mismo problema, no una. Hay que esconder también
	## los hijos visibles del padre mientras el 3D está abierto.
	var ocultados: Array = []
	for h in get_children():
		if h is Control and (h as Control).visible:
			(h as Control).visible = false
			ocultados.append(h)
	var padre := get_parent()
	if padre != null:
		for h in padre.get_children():
			if h != self and h is Control and (h as Control).visible:
				(h as Control).visible = false
				ocultados.append(h)
	var vista := VistaEstadio.new()
	## ANTES de `abrir()`: `VistaEstadio._construir()` monta la pantalla gigante
	## dentro de esa llamada, así que asignarlo después llegaría tarde y la
	## pantalla se quedaría sin tabla ni goleadores.
	vista.datos_pantalla = datos_pantalla
	add_child(vista)
	## La ocupación que se ve en las gradas es la de verdad: la que sale de la
	## curva de la taquilla con el precio de entrada que has puesto tú. Un
	## estadio medio vacío tiene que verse medio vacío.
	var f := Finanzas.new(partido.local)
	var gente := float(f.asistencia()) / float(maxi(partido.local.estadio_aforo, 1))
	## Y con el partido de verdad dentro: los 22 juegan, el marcador corre y lo que
	## pase ahi es lo que va a la tabla. El reloj de esta pantalla queda parado
	## mientras tanto — manda el de la vista 3D, para que no haya dos relojes.
	vista.abrir(partido.local, clampf(gente, 0.05, 1.0), partido.visita, partido, perfil_estadio, colores_balon)
	vista.cerrado.connect(func() -> void:
		vista.queue_free()
		for h in ocultados:
			if is_instance_valid(h):
				(h as Control).visible = true
		_poner_velocidad(antes))

func _arengar(j: Jugador) -> void:
	if _arengas <= 0:
		return
	var problema := partido.arengar(j)
	if problema != "":
		_escribir("[color=#8ea595]%s.[/color]" % problema)
		return
	_arengas -= 1
	Sonido.toca("ovacion", Sonido.Bus.AMBIENTE)
	_escribir("[color=#c9a227]📣 Le gritas a %s desde la banda. Se enciende.[/color]" % j.nombre)
	_refrescar()

## Las estadísticas mientras corre el reloj. Cada fila es TU número contra el
## suyo, con una barra que reparte los dos: leer "6-3" cuesta más que ver una
## barra que se llena, y aquí hay que enterarse de un vistazo sin dejar de
## mirar el partido.
func _pintar_estadisticas_vivo() -> void:
	_limpiar(_panel_stats)
	var p := partido
	var mio_local := p.local == mi_club
	var pos_l := int(round(p.posesion_local))
	var filas := [
		["Posesión", pos_l, 100 - pos_l],
		["Remates", p.remates_local, p.remates_visita],
		["Al arco", p.tiros_puerta_local, p.tiros_puerta_visita],
		["Córners", p.corners_local, p.corners_visita],
		["Faltas", p.faltas_local, p.faltas_visita],
		["Fuera de juego", p.fueras_local, p.fueras_visita],
	]
	for f: Array in filas:
		var mio: int = int(f[1]) if mio_local else int(f[2])
		var suyo: int = int(f[2]) if mio_local else int(f[1])
		var cab := HBoxContainer.new()
		_panel_stats.add_child(cab)
		var a := _texto(12, COL_ACENTO)
		a.text = str(mio)
		a.custom_minimum_size = Vector2(30, 0)
		cab.add_child(a)
		var n := _texto(11, COL_SUAVE)
		n.text = String(f[0])
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.clip_text = true
		cab.add_child(n)
		var b := _texto(12, COL_TEXTO)
		b.text = str(suyo)
		b.custom_minimum_size = Vector2(30, 0)
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cab.add_child(b)
		var barra := ProgressBar.new()
		barra.min_value = 0.0
		barra.max_value = 100.0
		## Con los dos a cero la barra va al 50: repartir 0 entre 0 no significa
		## que domine nadie, significa que todavía no ha pasado nada.
		barra.value = 50.0 if mio + suyo == 0 else float(mio) * 100.0 / float(mio + suyo)
		barra.show_percentage = false
		barra.custom_minimum_size = Vector2(0, 6)
		var relleno := StyleBoxFlat.new()
		relleno.bg_color = COL_ACENTO
		relleno.set_corner_radius_all(2)
		barra.add_theme_stylebox_override("fill", relleno)
		_panel_stats.add_child(barra)
	## El xG aparte, con dos decimales: es el único que no es un contador.
	var xg_mio: float = p.xg_local if mio_local else p.xg_visita
	var xg_suyo: float = p.xg_visita if mio_local else p.xg_local
	var xg := _texto(12, COL_ORO)
	xg.text = "xG   %.2f  ·  %.2f" % [xg_mio, xg_suyo]
	xg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel_stats.add_child(xg)
	## Y la lectura, que es lo que convierte el xG en algo que se entiende sin
	## saber qué es el xG.
	var goles_mios: int = p.goles_local if mio_local else p.goles_visita
	if xg_mio >= 1.0 or goles_mios > 0:
		var l := _texto(10, COL_SUAVE)
		if float(goles_mios) < xg_mio - 0.9:
			l.text = "Generas más de lo que metes: es cuestión de que entre una."
		elif float(goles_mios) > xg_mio + 0.9:
			l.text = "Vas por delante de lo que has generado. Ojo con confiarse."
		else:
			l.text = "El marcador se parece a lo que has hecho."
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_panel_stats.add_child(l)
