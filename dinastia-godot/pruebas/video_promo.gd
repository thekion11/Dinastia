extends Node
## EL VÍDEO PROMOCIONAL (29-9-2026). Pedido del usuario: «jugando de verdad, un
## vídeo realmente detallado y largo, mostrando cada detalle y función».
##
## Se graba POR TRAMOS -uno por ejecución, cada una corta- con el escritor de
## películas de Godot, que dibuja a paso fijo: sale fluido aunque la máquina
## vaya a 3 fps. Después `herramientas/montar_promo.py` los junta en un MP4.
##
##   PROMO_TRAMO=hub godot --path . --rendering-driver opengl3 \
##       --resolution 1280x720 --fixed-fps 25 \
##       --write-movie pruebas/capturas/promo/hub.avi res://pruebas/video_promo.tscn
##
## Nada de lo que se ve está trucado: son las pantallas, escenas y el motor del
## juego, movidos por este guion como los movería un jugador.

const FPS := 25.0
## tramo -> [segundos, título, subtítulo]
const TRAMOS := {
	"portada": [9.0, "DINASTÍA", "Manager de fútbol · 7 modos de juego"],
	"hub": [16.0, "Tu club, semana a semana", "Tablero, calendario, objetivos de la directiva siempre a la vista"],
	"menus": [22.0, "Nueve menús a pantalla completa", "Historia · Gente · Mi carrera · Operaciones · Mi vida · Editar · Ajustes · Ciudad · Estadio"],
	"plantel": [22.0, "Plantel, táctica y entrenamiento", "Pizarra táctica, 15 maestrías, fichas con cara propia"],
	"fichaje": [11.3, "Cada fichaje, una presentación", "Tu estadio, tu camiseta con su dorsal, la hinchada"],
	"partido": [26.0, "El partido en 3D", "Estadios con la forma del real · grada llena · cámaras de TV"],
	"prensa": [11.0, "Rueda de prensa", "Lo que dices cambia tu relación con los medios"],
	"sorteo": [10.0, "Sorteos en directo", "Copas de 8 confederaciones"],
	"casa": [15.0, "Tu vida fuera del campo", "Tu casa en 3D: un café, el paisaje, el atardecer"],
	"telefono": [11.0, "Tu móvil", "Tribuna, mensajes, banco, calendario"],
	"ciudad": [13.0, "La ciudad que rodea tu estadio", "Terrenos, negocios y un día entero en 13 segundos"],
	"carrera": [9.0, "NUEVO · Carrera de Jugador", "Empiezas con 17 años en un club de segunda"],
	"jugable": [26.0, "Y el partido lo juegas tú", "Mando o teclado · pases, tiros, córners y penales"],
	"idiomas": [14.0, "9 idiomas", "Español · English · Português · Français · Italiano · Deutsch · Català · Polski · Türkçe"],
	"cierre": [7.0, "DINASTÍA", "Construye un club. Escribe su historia."],
}

## Los tramos 3D pesados se graban en partes, cada una en su propia ejecución
## corta: en el servidor sin gráfica un fotograma 3D cuesta más de 2 s.
## `PROMO_PARTE=k` graba desde el corte k-1 hasta el corte k.
const CORTES := {"fichaje": [6.5], "partido": [4.5, 9.0, 13.5, 18.0, 22.5], "prensa": [5.5],
	"sorteo": [5.0], "casa": [5.0, 10.0], "ciudad": [4.5, 9.0], "jugable": [4.5, 9.0, 13.5, 18.0, 22.5]}
var _parte := ""
var _desde := 0.0
var _hasta := 0.0
var _tramo := ""
var _f := 0
var _dur := 10.0
var _p: Node               ## pantalla principal, si el tramo la usa
var _m: Mundo
var _x: Dictionary = {}    ## estado propio de cada tramo
var _rotulo: Control
var _titulo: Label
var _sub: Label
var _marca: Label

func _ready() -> void:
	_tramo = OS.get_environment("PROMO_TRAMO")
	if not TRAMOS.has(_tramo):
		_tramo = "portada"
	_dur = float(TRAMOS[_tramo][0])
	_hasta = _dur
	_parte = OS.get_environment("PROMO_PARTE")
	if CORTES.has(_tramo) and _parte != "":
		var cortes: Array = CORTES[_tramo]
		var k := int(_parte)
		_desde = 0.0 if k == 0 else float(cortes[k - 1])
		_hasta = _dur if k >= cortes.size() else float(cortes[k])
	Idiomas.idioma = "es"
	## Grabación rápida: en render por software, el antialias y las sombras
	## caras son casi todo el coste de un fotograma 3D.
	Calidad.elegida = Calidad.MEDIO
	call("_montar_" + _tramo)
	_montar_rotulo()

func _t() -> float:
	return _desde + float(_f) / FPS

func _sin_aa(n: Node) -> void:
	if n is Viewport:
		(n as Viewport).msaa_3d = Viewport.MSAA_DISABLED
		(n as Viewport).screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		(n as Viewport).use_taa = false
	for h in n.get_children():
		_sin_aa(h)

func _process(_d: float) -> void:
	_f += 1
	if _f % 10 == 1:
		_sin_aa(get_tree().root)
	var t := _t()
	var fn := "_paso_" + _tramo
	if has_method(fn):
		call(fn, t)
	_animar_rotulo(t)
	if t >= _hasta:
		get_tree().quit()

# ------------------------------------------------------------------ rótulos

func _montar_rotulo() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 120
	add_child(capa)
	_rotulo = Control.new()
	_rotulo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(_rotulo)
	var banda := ColorRect.new()
	banda.color = Color(0.02, 0.03, 0.05, 0.78)
	banda.anchor_top = 1.0; banda.anchor_bottom = 1.0; banda.anchor_right = 1.0
	banda.offset_top = -118; banda.offset_bottom = -28
	banda.offset_left = 0; banda.offset_right = 0
	banda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rotulo.add_child(banda)
	var filo := ColorRect.new()
	filo.color = Color("#c9f24b")
	filo.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	filo.offset_right = 8
	banda.add_child(filo)
	_titulo = Label.new()
	_titulo.text = String(TRAMOS[_tramo][1])
	_titulo.add_theme_font_size_override("font_size", 34)
	_titulo.add_theme_color_override("font_color", Color.WHITE)
	_titulo.position = Vector2(34, 8)
	banda.add_child(_titulo)
	_sub = Label.new()
	_sub.text = String(TRAMOS[_tramo][2])
	_sub.add_theme_font_size_override("font_size", 18)
	_sub.add_theme_color_override("font_color", Color("#c9f24b"))
	_sub.position = Vector2(36, 54)
	banda.add_child(_sub)
	_marca = Label.new()
	_marca.text = "DINASTÍA"
	_marca.add_theme_font_size_override("font_size", 18)
	_marca.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	_marca.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_marca.add_theme_constant_override("outline_size", 6)
	_marca.anchor_left = 1.0; _marca.anchor_right = 1.0
	_marca.anchor_top = 1.0; _marca.anchor_bottom = 1.0
	_marca.offset_left = -130; _marca.offset_top = -26
	capa.add_child(_marca)

## La banda entra deslizando, se queda 4 s y se va; la marca queda siempre.
func _animar_rotulo(t: float) -> void:
	var entra := clampf(t / 0.45, 0.0, 1.0)
	var sale := clampf((t - 4.6) / 0.5, 0.0, 1.0)
	if _tramo == "portada" or _tramo == "cierre":
		sale = 0.0
	var k := entra * (1.0 - sale)
	_rotulo.modulate.a = k
	_rotulo.position.x = (1.0 - ease(entra, 0.3)) * -420.0 + sale * -420.0

# ------------------------------------------------------------------ ayudas

func _principal() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _mundo_p() -> Mundo:
	if _m == null and _p != null:
		_m = _p.get("mundo")
	return _m

func _una_vez(clave: String, t: float, desde: float) -> bool:
	if t >= desde and not _x.has(clave):
		_x[clave] = true
		return true
	return false

func _ml() -> MenuLateral:
	return _p.get("_menu_lateral")

# ------------------------------------------------------------------ tramos

func _montar_portada() -> void:
	var ini: Node = load("res://escenas/inicio.tscn").instantiate()
	add_child(ini)
	_x["ini"] = ini

## Baja despacio por la portada: los modos de juego están debajo.
func _paso_portada(t: float) -> void:
	var sc: ScrollContainer = null
	for n in (_x["ini"] as Node).find_children("*", "ScrollContainer", true, false):
		sc = n
		break
	if sc == null:
		return
	var barra := sc.get_v_scroll_bar()
	var k := clampf((t - 2.0) / (_dur - 3.0), 0.0, 1.0)
	sc.scroll_vertical = int(ease(k, -1.8) * barra.max_value * 0.75)

func _montar_hub() -> void:
	_principal()

## Sin avanzar semanas: tras el partido se abre sola la rueda de prensa, que
## tiene su propio tramo.
func _paso_hub(t: float) -> void:
	if _una_vez("ficha", t, 5.5):
		var c := _mundo_p().mi_club()
		_p.call("_ver_ficha", c.plantilla[3])
	if _una_vez("cajon", t, 9.5):
		_ml().desplegar()
	if _una_vez("plegar", t, 14.0):
		_ml().plegar()

func _montar_menus() -> void:
	_principal()

const ORDEN_MENUS := ["historia", "gente", "carrera", "operaciones", "vida", "editar", "ajustes", "ciudad", "estadio"]
func _paso_menus(t: float) -> void:
	var i := int((t - 0.6) / 2.0)
	if t > 0.6 and i < ORDEN_MENUS.size() and _una_vez("m%d" % i, t, 0.6):
		_ml().abrir_menu(String(ORDEN_MENUS[i]), -1)
	if _una_vez("detalle", t, 19.0):
		_ml().abrir_menu("historia", 0)

func _montar_plantel() -> void:
	_principal()

func _paso_plantel(t: float) -> void:
	## El panel de objetivos (movible) tapa la ficha en 1280x720: aquí se aparta.
	var po: Variant = _p.get("_panel_obj")
	if po != null and is_instance_valid(po):
		(po as Control).visible = false
	if _una_vez("a", t, 0.3):
		_p.call("_ir_a_pestana", "Mi plantel")
		_p.call("_refrescar")
	if _una_vez("ficha", t, 3.5):
		var c := _mundo_p().mi_club()
		var mejor: Jugador = c.plantilla[0]
		for j: Jugador in c.plantilla:
			if j.ovr > mejor.ovr:
				mejor = j
		_p.call("_ver_ficha", mejor)
	if _una_vez("tactica", t, 7.0):
		_p.call("_ir_a_pestana", "Táctica")
		_p.call("_refrescar")
	if _una_vez("entrenar", t, 12.0):
		_p.call("_ir_a_pestana", "Entrenar")
		_p.call("_refrescar")
	if _una_vez("mercado", t, 16.0):
		_p.call("_ir_a_pestana", "Mercado")
		_p.call("_refrescar")
	if _una_vez("finanzas", t, 19.0):
		_p.call("_ir_a_pestana", "Finanzas")
		_p.call("_refrescar")

func _montar_fichaje() -> void:
	_principal()

func _paso_fichaje(t: float) -> void:
	if _una_vez("cin", t, 0.3):
		var m := _mundo_p()
		var mio := m.mi_club()
		var j: Jugador = mio.plantilla[0]
		for x: Jugador in mio.plantilla:
			if x.pos_e != "POR" and x.ovr > j.ovr:
				j = x
		var de: Club = m.ligas[0].clubes[1] if m.ligas[0].clubes[1] != mio else m.ligas[0].clubes[2]
		var cin := CinematicaFichaje.mostrar(_p, m, j, de, true)
		cin._t = _desde

func _montar_partido() -> void:
	_m = Mundo.new()
	_m.generar(["CHI"], 4711)
	_m.mi_club_id = _m.ligas[0].clubes[0].id
	var par := _m.proximo_partido()
	var partido := Partido.new(par[0], par[1])
	var v := VistaEstadio.new()
	add_child(v)
	v.abrir(par[0], 0.9, par[1], partido)
	_x["vista"] = v
	_x["partido"] = partido

func _paso_partido(t: float) -> void:
	var v: VistaEstadio = _x["vista"]
	var partido: Partido = _x["partido"]
	var rig: CameraRig = v.get("_rig")
	if _una_vez("gol", t, 6.0) and partido.once_local.size() >= 2:
		partido.goles_local += 1
		partido.gol.emit(partido.local, partido.once_local[9], 23, partido.once_local[7])
	if rig != null:
		if _una_vez("cam1", t, 12.5):
			var i := rig.camera_names.find("A ras de campo")
			if i != -1:
				rig.switch_to(i)
		if _una_vez("cam2", t, 17.0):
			rig.switch_to(0)
		if _una_vez("cam3", t, 21.5) and rig.cameras.size() > 3:
			rig.switch_to(3)

func _montar_prensa() -> void:
	_principal()

func _paso_prensa(t: float) -> void:
	if _una_vez("rueda", t, 0.3):
		var m := _mundo_p()
		m.prensa.abrir_rueda(true, false)
		_p.call("_abrir_rueda_pantalla_completa", m.prensa.entrevista)

func _montar_sorteo() -> void:
	var e := SorteoEscena3D.new()
	add_child(e)
	e.montar(Color("f5c518"), Color("0d2818"))
	_x["esc"] = e

func _paso_sorteo(t: float) -> void:
	var e: SorteoEscena3D = _x["esc"]
	if _una_vez("p1", t, 3.5):
		e.cortar_plano(1)
	if _una_vez("p2", t, 7.0):
		e.cortar_plano(2)

func _montar_casa() -> void:
	_principal()

func _paso_casa(t: float) -> void:
	if _una_vez("abrir", t, 0.3):
		var m := _mundo_p()
		m.vida.vivienda = "mansion"
		var pop: Control = CasaEscena3D.abrir(_p, m, _p.get("_bandeja"))
		_x["casa"] = pop.find_children("*", "CasaEscena3D", true, false)[0]
	if _x.has("casa"):
		var c: CasaEscena3D = _x["casa"]
		if _una_vez("cafe", t, 4.0):
			c.tomar_cafe()
		if _una_vez("hora", t, 10.0):
			c.alternar_hora()

func _montar_telefono() -> void:
	_principal()

func _paso_telefono(t: float) -> void:
	if _una_vez("abrir", t, 0.3):
		var m := _mundo_p()
		_p.call("_anotar", "✅ Victoria de visita", "El equipo gana 2-1 y se sube al tercer puesto.")
		m.redes.publicar(m, "hinchada", ["#Hinchada", m.redes.tendencia])
		m.redes.dar_acceso_club(m)
		m.redes._publican_jugadores(m)
		m.movil.fondo = "atardecer"
		m.movil.funda = "club"
		var pop: Control = Telefono.abrir(_p, m)
		_x["tel"] = pop.find_children("*", "Telefono", true, false)[0]
	if not _x.has("tel"):
		return
	var tel: Telefono = _x["tel"]
	if _una_vez("tribuna", t, 2.5):
		tel.abrir_app("tribuna")
	if _una_vez("mensajes", t, 5.5):
		tel.set("_chat", "Community manager")
		tel.abrir_app("mensajes")
	if _una_vez("banco", t, 8.0):
		tel.abrir_app("calendario")

func _montar_ciudad() -> void:
	_m = Mundo.new()
	_m.generar(["CHI"], 4713)
	_m.tomar_el_mando(_m.ligas[0].clubes[0].id)
	for k in _m.obras.niveles.keys():
		_m.obras.niveles[k] = 3
	_m.ciudad.terrenos = ["norte", "centro", "periferia", "ribera", "sur"]
	for n in ["hotel", "parking", "comercial", "clinica"]:
		_m.ciudad.negocios[n] = true
	var v := VistaCiudad.new()
	add_child(v)
	v.abrir(_m.mi_club(), _m.obras, _m.ciudad, _m.perfil_estadio_de(_m.mi_club()))
	v.set("_hora", 5.0)
	_x["v"] = v

func _paso_ciudad(t: float) -> void:
	var v: VistaCiudad = _x["v"]
	var k := t / _dur
	v.set("_hora", fposmod(5.0 + k * 24.0, 24.0))
	v.set("_ang", 0.2 + k * TAU * 0.8)
	v.set("_dist", lerpf(560.0, 420.0, k))
	v.set("_alto", lerpf(175.0, 125.0, k))

func _montar_carrera() -> void:
	CarreraJugadorUI.mundo = null
	var ui: CarreraJugadorUI = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(ui)
	_x["ui"] = ui

func _paso_carrera(t: float) -> void:
	if _una_vez("crear", t, 3.5):
		(_x["ui"] as CarreraJugadorUI)._crear()

func _montar_jugable() -> void:
	CarreraJugadorUI.mundo = null
	var ui: CarreraJugadorUI = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(ui)
	ui._crear()
	var club := ui.carrera.club(CarreraJugadorUI.mundo)
	var par := ui._partido_de_la_semana(club)
	var pj := PartidoJugable.abrir(ui, CarreraJugadorUI.mundo, ui.carrera, par[0], par[1], 90.0)
	pj.motor.autopiloto = true
	_x["pj"] = pj

func _paso_jugable(t: float) -> void:
	var pj: PartidoJugable = _x["pj"]
	var m := pj.motor
	if _una_vez("corner", t, 11.0):
		m.autopiloto = false
		var d := MotorJugable.dir_ataque(bool(m.usuario["es_local"]))
		m._empezar_saque("corner", bool(m.usuario["es_local"]), Vector3(33.7, 0.11, 52.2 * d))
	if t > 11.5 and t < 14.5 and m.apuntando:
		m.apunte["fuerza"] = clampf((t - 11.5) / 2.5, 0.2, 0.75)
	if _una_vez("lanza", t, 14.5):
		m._lanzar_usuario(0.62)
		m.autopiloto = true
	if _una_vez("penal", t, 19.5):
		m.autopiloto = false
		m.lanza_usuario["penal"] = true
		var d2 := MotorJugable.dir_ataque(bool(m.usuario["es_local"]))
		m._empezar_saque("penal", bool(m.usuario["es_local"]), Vector3(0, 0.11, (52.5 - 11.0) * d2))
	if _una_vez("tira", t, 23.5):
		m._lanzar_usuario(0.75)
		m.autopiloto = true

func _montar_idiomas() -> void:
	_principal()

const ORDEN_IDIOMAS := ["en", "pt", "fr", "it", "de", "ca", "pl", "tr", "es"]
func _paso_idiomas(t: float) -> void:
	var i := int((t - 1.0) / 1.35)
	if t > 1.0 and i < ORDEN_IDIOMAS.size() and _una_vez("i%d" % i, t, 1.0):
		Idiomas.idioma = String(ORDEN_IDIOMAS[i])
		_p.call("_refrescar")
	if t >= _dur - 0.1 and Idiomas.idioma != "es":
		Idiomas.idioma = "es"

func _montar_cierre() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 110
	add_child(capa)
	var fondo := ColorRect.new()
	fondo.color = Color("#07120c")
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(fondo)
	var caja := VBoxContainer.new()
	caja.set_anchors_preset(Control.PRESET_CENTER)
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.grow_horizontal = Control.GROW_DIRECTION_BOTH
	caja.grow_vertical = Control.GROW_DIRECTION_BOTH
	capa.add_child(caja)
	for fila: Array in [["DINASTÍA", 92, Color.WHITE], ["Construye un club. Escribe su historia.", 28, Color("#c9f24b")],
			["", 18, Color.WHITE], ["24 ligas · 384 clubes · 7 modos de juego · 9 idiomas", 22, Color(1, 1, 1, 0.8)],
			["Dueño · Director técnico · Presidente · Crear tu club · Retos · Fondo de inversión · Carrera de jugador", 17, Color(1, 1, 1, 0.6)]]:
		var l := Label.new()
		l.text = String(fila[0])
		l.add_theme_font_size_override("font_size", int(fila[1]))
		l.add_theme_color_override("font_color", fila[2])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caja.add_child(l)
	_x["caja"] = caja

func _paso_cierre(t: float) -> void:
	(_x["caja"] as Control).modulate.a = clampf(t / 1.2, 0.0, 1.0)
	_rotulo.visible = false
