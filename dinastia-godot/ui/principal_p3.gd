extends "res://ui/principal_p2.gd"
## [Capa 3/19 de `principal.gd`] _acento_de, _aplicar_fondo, fecha_del_dia, fecha_de_hoy, fecha_larga, _limpiar … (+15)

# ===========================================================================
#  EL ASPECTO A TU MEDIDA
# ===========================================================================
#
# Nueve paletas, cinco formas de tarjeta, cuatro densidades y el brillo del
# panel. Ninguna toca una sola regla del juego: todo esto es cómo se ve.
#
# POR QUÉ TANTAS OPCIONES. Es una petición directa del usuario -«me gusta
# demasiado lo de poder configurar, de tener muchísimas opciones»- y es
# coherente con lo que ya hace el juego en otros sitios: catorce fondos, ocho
# formas de escudo por diez patrones, doce estampados de camiseta. Un juego de
# gestión se mira dos horas seguidas; que se vea como uno quiere no es un
# capricho, es la diferencia entre aguantarlo y disfrutarlo.
#
# LAS PALETAS NO PISAN EL COLOR DEL CLUB. El acento sigue saliendo de tu
# identidad (`_acento_de()`); lo que cambia aquí es el FONDO, el panel y el
# borde, que es el lienzo sobre el que se pinta ese acento.

## clave -> [nombre, fondo, panel, borde, texto, texto suave]
const PALETAS := {
	"bosque":   ["Bosque (por defecto)", "0c1510", "141c16", "ffffff12", "e9eeea", "8ea595"],
	"pizarra":  ["Pizarra", "10141a", "181d25", "ffffff14", "e8ecf2", "8e97a5"],
	"carbon":   ["Carbón", "0e0e10", "17171a", "ffffff10", "ececec", "9a9a9e"],
	"vino":     ["Vino", "17090d", "231218", "ffffff14", "f2e8ea", "a88e93"],
	"marino":   ["Marino", "081420", "0f2030", "ffffff14", "e6eef5", "8ba0b0"],
	"tierra":   ["Tierra", "16110b", "221a12", "ffffff12", "f0e9df", "a8917a"],
	"papel":    ["Papel (claro)", "e8e5dd", "f5f3ec", "00000018", "1e2420", "5a6259"],
	"cuaderno": ["Cuaderno de gestión", "e3e0d4", "f2efe3", "00000022", "23281f", "60664f"],
	"neon":     ["Neón", "0a0612", "150d22", "ffffff18", "efe8ff", "9c8fb8"],
	## LAS SEIS DE GEMINI (`ModuloEsteticaUI` del documento "Visual gemini" en
	## Drive, 11-9-2026): a diferencia de las nueve de arriba -que solo cambian
	## de tinte y dejan el borde en blanco/negro translúcido, neutro- estas
	## traen un borde de un color saturado propio, que es justo lo que se ve
	## en las capturas que mandó el usuario. Se integran como seis paletas MÁS,
	## no como un sistema aparte: la nota de arriba ("las paletas no pisan el
	## color del club") sigue valiendo -el acento del club sigue viniendo de
	## `COL_ACENTO`/`_con_contraste()`, esto solo tiñe fondo/panel/borde-.
	"esports":    ["eSports", "0d1620", "121b27", "10b981cc", "e8f5ee", "7fae95"],
	"ejecutivo":  ["Ejecutivo", "141a26", "1b2333", "f59e0bcc", "f5ecd9", "b3a37f"],
	"cibernetico":["Cibernético", "0d0818", "150f24", "00e5ffcc", "eafcff", "8fb8c2"],
	"transmision":["Transmisión", "0c1220", "121a2c", "ef4444cc", "fbecec", "c28f8f"],
	"pizarra_gr": ["Pizarra gris", "0e131c", "141a24", "374151", "e6e9ee", "8b93a0"],
	"minimo":     ["Mínimo", "0a0c10", "0f1216", "1f2937", "e3e6e8", "7a828c"],
}

## Cuánto se redondean las tarjetas. Es el detalle que más cambia el «carácter»
## de una interfaz sin tocar un solo color.
const FORMAS_TARJETA := {
	"redonda":  ["Redondeada", 8, 1],
	"suave":    ["Muy suave", 14, 1],
	"recta":    ["Recta", 0, 1],
	"marcada":  ["Borde marcado", 6, 2],
	"sinborde": ["Sin borde", 8, 0],
}

var _paleta: String = "bosque"
## "Velocidad de partido por defecto" de `vAjustes()`: índice de
## `PartidoVivo.VELOCIDADES` con el que arranca cada partido dirigido en vivo.
## 2 = "Normal", el mismo valor con el que ya arrancaba siempre -así que no
## guardar esto todavía no cambiaba nada, solo faltaba poder elegirlo-.
var _velocidad_partido: int = 2
var _forma_tarjeta: String = "redonda"
var _brillo_tarjetas: bool = true
## El adorno del borde de cada tarjeta. Ver `MarcaPanel`.
var _marca_tarjeta: String = "esquinas"

## SACAR Y METER LA PARTIDA. El HTML pegaba el guardado en un `<textarea>` porque
## el navegador no le dejaba tocar el disco. Aquí sí se puede, así que se hacen
## las dos cosas: se escribe un archivo suelto en una carpeta que se puede abrir
## y se copia el mismo contenido al portapapeles, que es lo que hace falta para
## mandárselo a alguien por chat.
const FICHERO_EXPORTADO := "user://dinastia-exportada.txt"

## LAS SECCIONES DE AJUSTES. La pantalla llegó a medir 1.700 px de alto: para
## llegar al tamaño de letra había que bajar por delante del mezclador, de los
## veinticuatro fondos, de los diez climas y de las nueve paletas.
##
## No se quita ni una opción —son justo lo que hace falta que haya— pero se
## reparten en seis grupos y solo se pinta el que estás mirando. De paso se
## pinta seis veces menos en cada refresco.
const SECCIONES_AJUSTES := [
	["audio", "🔊 Sonido y música"],
	["aspecto", "🎨 Aspecto"],
	["pantalla", "🖥 Pantalla"],
	["juego", "🎮 Juego"],
	["acceso", "♿ Accesibilidad"],
	["partida", "💾 Partida"],
]

var _secc_ajustes: String = "audio"

## `vCorreo()` del HTML: bandeja filtrable sobre `G.noticias`. Aquí lee
## `_bandeja`, que `_anotar()` llena en paralelo a cada `_escribir()` de
## `_conectar_noticias()` -ver el comentario de esa función-. Tocar una fila
## la marca leída, igual que el HTML.
## `vSocial()`: el termómetro de redes y el gabinete de comunicación.
##
## `funa` y `animo` ya se movían solos desde el porte y no había dónde verlos
## juntos ni nada que hacer al respecto. Lo que se añade no es un número más:
## son las tres respuestas del gabinete, que son una decisión de las buenas —no
## hay opción correcta, y contestar puede apagar el fuego o doblarlo.
## `vGente()`: las diez personas del club. No mueve ninguna estadística del
## partido y ese es el punto: es lo que hace que el club sea un SITIO y no una
## hoja de cálculo con escudo.
##
## Tres charlas por semana y no diez: si se pudiera hablar con todos, dejaría de
## ser una elección y sería una ronda de clics. Y los efectos son pequeños a
## propósito —por debajo de 60 de confianza no dan nada—, porque el día que
## hablar con el utilero suba dos puntos de media esto se convierte en otra
## pestaña que hay que exprimir cada lunes.
## `vClubIn()`: el club por dentro. Tres espacios que se compran y dos cosas
## digitales. Cada uno pega en un sitio distinto —moral, funa, patrocinio— y esa
## es la razón de que exista la pantalla: cuando no llega para los tres, hay que
## decidir qué clase de club quieres ser.
## `vIdentidad()`: los colores del club. Es el cambio más pequeño del juego y el
## que más se ve: `Club.color1` tiñe el escudo, la equipación del visor 3D y el
## COLOR DE ACENTO de toda la interfaz (`_acento_de()`), así que tocarlo aquí
## repinta el juego entero.
##
## Hasta ahora los colores existían y no se guardaban: cambiarlos duraba hasta
## cerrar. Ya van en la partida.
## `vIdentidad()`: LAS CUATRO CAPAS. Club, uniforme, escudo e interfaz, cada una
## por su lado.
##
## Antes esto eran dos selectores de color y ya. El HTML separa cuatro capas a
## propósito: el uniforme no arrastra el color del menú ni el del escudo, y lo
## que no tocas lo hereda del club. Esa herencia es lo que hace que un equipo
## recién tomado ya se vea suyo sin elegir nada, y lo que hace que el botón de
## "volver a los colores del club" signifique algo.
# ---------------------------------------------------------------------------
#  LAS PREFERENCIAS SE QUEDAN
# ---------------------------------------------------------------------------
#
# Doce ajustes de interfaz -paleta, forma de tarjeta, brillo, fondo, tamano de
# letra, zoom, modo TV, modo experto, daltonismo, FPS- vivian solo en memoria:
# los elegias, y al cerrar el juego volvia todo a como estaba. Con una sola
# opcion eso se aguanta; con doce es una pelea cada vez que abres.
#
# NO VAN EN LA PARTIDA, van en un archivo aparte. Son tuyos, no de tu club: si
# te gusta la paleta de cuaderno te gusta en todas tus carreras, y una partida
# que viaja a otro ordenador no tiene por que llevarse el tamano de letra de
# nadie.
const PREFS := "user://preferencias.cfg"

## La firma de lo guardado la ultima vez. Esta pantalla se repinta en CADA
## refresco del juego -no solo al tocar un ajuste-, asi que sin esto se escribiria
## el archivo en cada clic sin que hubiera cambiado nada.
var _firma_prefs: String = ""

## LA PESTAÑA "GENTE", PARTIDA EN SUBMENÚS (10-9-2026). Antes cuatro funciones
## sin relación -personas de carne y hueso, identidad visual, explotación
## comercial, y "el club por dentro" (vestuario/prensa/palco)- se apilaban las
## cuatro seguidas bajo un nombre que solo describe a la primera: nadie que
## busque "cambiar el patrocinador de la camiseta" mira en una pestaña
## llamada "Gente". Mismo mecanismo de chips que ya usa Ajustes
## (`SECCIONES_AJUSTES`), clonado en vez de inventar uno nuevo.
const SECCIONES_GENTE := [
	["personas", "👥 Personas"],
	["identidad", "🎨 Identidad y camiseta"],
	["comercial", "💰 Comercial"],
	["interno", "🚪 El club por dentro"],
]
var _secc_gente: String = "personas"

## Tres pantallas del HTML compartían un solo chip y una sola lista: `vSocial`
## (feed + funa + gabinete de comunicación), `vPrensa` (periodistas, medios
## propios, vocero, derechos de TV, portadas, año contado) y `vDebate` (mesa
## de televisión, ranking de entrenadores, el influencer que mueve seguidores).
## Se pinta TODO seguido, como siempre, y esto esconde lo que no toca -mismo
## truco que `_filtrar_records()`, apoyado en que cada sección empieza con un
## Label de título conocido-. El bloque de arriba de todo -seguidores, funa,
## ánimo, prestigio DT- no lleva título propio y por eso se ve siempre: es la
## cabecera de la pantalla, no una sección.
const SECC_REDES := {
	"redes": ["GABINETE DE COMUNICACIÓN", "LO QUE SE DICE"],
	"prensa": ["🎙️ LA PRENSA", "📡 MEDIOS PROPIOS", "🎤 QUIÉN DA LA CARA",
		"📺 DERECHOS DE TELEVISIÓN", "🗞️ ARCHIVO DE PORTADAS", "📖 EL AÑO CONTADO"],
	"debate": ["📺 MESA DE DEBATE", "🏅 RANKING DE ENTRENADORES", "📱 LO QUE DICEN LOS QUE MUEVEN MASAS"],
}
var _secc_redes: String = "redes"

func _acento_de(c: Club) -> Color:
	if c == null:
		return Color("3fa06a")
	## El acento va POR SEPARADO del color del club si se ha elegido uno: es la
	## cuarta capa de la identidad -club, uniforme, escudo e interfaz-.
	var col := Color(c.color_acento())
	if col.get_luminance() < 0.10:
		return Color("e0e0e0")
	## Y si el color del club es muy apagado, se le sube la saturacion: un acento
	## que no se distingue del texto normal no es un acento.
	if col.s < 0.25:
		col.s = 0.45
	return col.lightened(0.15) if col.get_luminance() < 0.35 else col

func _aplicar_fondo() -> void:
	if _clima != null:
		_clima.modo = _clima_elegido
		_clima.interactivo = _clima_interactivo
		_clima.ajustar_area(size if size.x > 0.0 else Vector2(1280, 720))
		_clima.aplicar()
	if _fondo_escena == null:
		return
	## EL FONDO ROTATIVO. El usuario pidió poder elegir entre uno fijo o que
	## "vaya cambiando". La rotación NO usa `Azar` -eso movería la simulación
	## entera, la trampa que ya costó una depuración con el feed de redes-:
	## sale de la semana de juego, que da un fondo distinto cada domingo,
	## siempre el mismo para la misma partida.
	if _fondo_elegido == ROTAR_FONDO:
		var nombres: Array = Fondo.NOMBRES
		if nombres.is_empty():
			_fondo_escena.texture = null
			return
		var i := (mundo.semana if mundo != null else 0) % nombres.size()
		_fondo_escena.texture = Fondo.textura(String(nombres[i]))
		return
	_fondo_escena.texture = Fondo.textura(_fondo_elegido) if _fondo_elegido != "" else null

## La fecha de cualquier día (0 = lunes) de la semana en curso.
func fecha_del_dia(dia: int) -> Dictionary:
	return Calendario.fecha(mundo.anio if mundo != null else 2026, mundo.semana if mundo != null else 1, dia)

## La fecha de hoy, derivada: inicio de temporada + semanas corridas + días.
func fecha_de_hoy() -> Dictionary:
	return fecha_del_dia(_dia_semana)

func fecha_larga() -> String:
	var f := fecha_de_hoy()
	var dow := int(f.get("weekday", 1))
	## `weekday` de Godot es 0=domingo; aquí la semana empieza en lunes.
	var idx := (dow + 6) % 7
	## Entera y sin abreviar: "lunes 26 de enero de 2026".
	return "%s %d de %s de %d" % [String(DIAS_LARGOS[idx]).to_lower(), int(f["day"]),
		MESES_LARGOS[int(f["month"]) - 1], int(f["year"])]

func _limpiar(n: Node) -> void:
	for h in n.get_children():
		n.remove_child(h)
		h.queue_free()


# ---------------------------------------------------------------------------
#  EL TEMA DE LA PALETA
# ---------------------------------------------------------------------------
#
# `_panel()` pinta las tarjetas que crea el juego, pero NO pinta lo que dibuja
# Godot por su cuenta: el fondo de las pestañas, los botones, los desplegables,
# las barras. Eso sale del tema oscuro que trae el motor de fábrica, y con una
# paleta clara quedaba la mitad de arriba en crema y la mitad de abajo en gris
# oscuro, con el texto ya traducido a oscuro y por tanto ilegible.
#
# Se arregla en el sitio donde se arregla de verdad: un `Theme` colgado de la
# raíz. Baja por todos los hijos de golpe, así que las nueve paletas valen para
# la interfaz entera sin tocar ni una pantalla.

## Mezcla dos colores. Los tonos de los botones -reposo, encima, pulsado- no se
## escriben a mano nueve veces: se derivan del panel y del texto de cada paleta,
## que es lo que hace que añadir una paleta cueste una línea.
func _mezcla(a: Color, b: Color, t: float) -> Color:
	return Color(lerpf(a.r, b.r, t), lerpf(a.g, b.g, t), lerpf(a.b, b.b, t), a.a)
func _pal_texto() -> Color: return _ui_ajustes._color_pal(4, COL_TEXTO)
func _pal_suave() -> Color: return _ui_ajustes._color_pal(5, COL_SUAVE)
## El panel conserva el 0,94 de opacidad de siempre: es lo que deja ver el
## fondo de pantalla por debajo sin que la tabla pierda contraste.
func _pal_panel() -> Color:
	var c := _ui_ajustes._color_pal(2, COL_PANEL)
	c.a = 0.94
	return c

func _con_contraste(c: Color) -> Color:
	var lf := _pal_panel().get_luminance()
	if absf(lf - c.get_luminance()) >= SALTO_LUMA:
		return c
	var destino := Color.BLACK if lf > 0.5 else Color.WHITE
	var r := c
	## Ocho pasos y se para. Si un color no llega ni al octavo -un gris exacto del
	## mismo tono que el panel- se devuelve el ultimo, que ya es lo mas separado
	## que se puede sin dejar de ser el mismo color.
	for i in 8:
		r = r.lerp(destino, 0.18)
		if absf(lf - r.get_luminance()) >= SALTO_LUMA:
			return r
	return r

## Las dos mil llamadas a `_texto()` del juego piden COL_TEXTO o COL_SUAVE, que
## son claros porque el fondo por defecto es oscuro. Con una paleta CLARA -papel,
## cuaderno- ese texto quedaria blanco sobre blanco, invisible. Se traduce aqui,
## en el unico sitio por el que pasan todas las etiquetas, en vez de tocar dos mil
## llamadas: los colores con significado propio -el oro de un titulo, el rojo de
## una deuda- pasan de largo sin tocarse, que para eso son ellos los que informan.
func _color_de_paleta(c: Color) -> Color:
	if _paleta == "bosque":
		return c
	if c == COL_TEXTO:
		return _pal_texto()
	if c == COL_SUAVE:
		return _pal_suave()
	return _con_contraste(c)

func _pildora(texto: String, tam: int = 12, alto: int = 32) -> Button:
	var b := Button.new()
	b.text = texto
	b.toggle_mode = true
	if _estilo_menu == "compacto":
		tam = maxi(10, tam - 1)
		alto = maxi(22, alto - 4)
	b.add_theme_font_size_override("font_size", tam)
	b.custom_minimum_size = Vector2(float(texto.length()) * (float(tam) * 0.62) + 30.0, alto)
	## "barra" = esquinas rectas y una línea de acento debajo del activo, que
	## es como se veían las pestañas antes de que todo fuera cápsulas.
	var radio := 3 if _estilo_menu == "barra" else int(alto / 2)
	var reposo := StyleBoxFlat.new()
	reposo.bg_color = _mezcla(_color_de_paleta(COL_PANEL), _color_de_paleta(COL_TEXTO), 0.07)
	reposo.border_color = _color_de_paleta(COL_BORDE)
	reposo.set_border_width_all(1)
	reposo.set_corner_radius_all(radio)
	reposo.content_margin_left = 14
	reposo.content_margin_right = 14
	var encima := reposo.duplicate() as StyleBoxFlat
	encima.bg_color = _mezcla(_color_de_paleta(COL_PANEL), _color_de_paleta(COL_TEXTO), 0.18)
	var activa := StyleBoxFlat.new()
	activa.bg_color = _color_de_paleta(COL_TEXTO)
	activa.set_corner_radius_all(radio)
	activa.content_margin_left = 14
	activa.content_margin_right = 14
	b.add_theme_stylebox_override("normal", reposo)
	b.add_theme_stylebox_override("hover", encima)
	b.add_theme_stylebox_override("focus", encima)
	b.add_theme_stylebox_override("pressed", activa)
	b.add_theme_color_override("font_color", _color_de_paleta(COL_TEXTO))
	b.add_theme_color_override("font_hover_color", _color_de_paleta(COL_TEXTO))
	## La píldora activa lleva letra OSCURA sobre fondo claro: es el mismo
	## truco del HTML y lo que hace que no haga falta ningún subrayado.
	b.add_theme_color_override("font_pressed_color", _color_de_paleta(COL_FONDO))
	b.add_theme_color_override("font_hover_pressed_color", _color_de_paleta(COL_FONDO))
	return b

## Lo mismo para el registro, que pinta con BBCode y no pasa por `_texto()`.
func _bbcode_accesible(t: String) -> String:
	if not _daltonico:
		return t
	return t.replace("#4caf6d", "#56b4e9").replace("#e05555", "#d55e00").replace("#c9a227", "#e69f00")

func _traducir_bbcode(bb: String) -> String:
	if Idiomas.idioma == "es":
		return bb
	if _re_tramos_bb == null:
		_re_tramos_bb = RegEx.create_from_string("\\]([^\\[]+)")
	var salida := bb
	for m: RegExMatch in _re_tramos_bb.search_all(bb):
		var tramo := m.get_string(1)
		var limpio := tramo.strip_edges()
		if limpio == "":
			continue
		var tr_ := Idiomas.t(limpio)
		if tr_ != limpio:
			salida = salida.replace(tramo, tramo.replace(limpio, tr_))
	return salida

func _escribir(bbcode: String) -> void:
	_registro.append_text(_bbcode_accesible(_traducir_bbcode(bbcode)) + "\n")

func _liga_de(c: Club) -> Liga:
	for l in mundo.ligas:
		if l.clubes.has(c):
			return l
	return mundo.ligas[0]

func _dinero(n: int) -> String:
	return Eco.dinero(n)
func _indicador_guardado() -> void:
	if not is_inside_tree():
		return
	if not is_instance_valid(_ind_guardado):
		_ind_guardado = Label.new()
		_ind_guardado.name = "IndicadorGuardado"
		_ind_guardado.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ind_guardado.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		_ind_guardado.offset_left = -240.0
		_ind_guardado.offset_right = -20.0
		_ind_guardado.offset_top = 62.0
		_ind_guardado.offset_bottom = 84.0
		_ind_guardado.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_ind_guardado.add_theme_font_size_override("font_size", 13)
		_ind_guardado.add_theme_color_override("font_color", Color(0.75, 0.9, 0.75))
		_ind_guardado.z_index = 50
		add_child(_ind_guardado)
	_ind_guardado.text = "💾 " + Idiomas.t("Partida guardada")
	_ind_guardado.modulate.a = 1.0
	var tw := _ind_guardado.create_tween()
	tw.tween_interval(1.4)
	tw.tween_property(_ind_guardado, "modulate:a", 0.0, 0.8)

## El interruptor de Ajustes → Guardado. Silencioso a propósito -uno por
## semana durante toda una carrera sería puro ruido en el registro-, en la
## misma ranura que ya usa el botón "Guardar" de arriba.
func _autoguardar_si_toca() -> void:
	if _autoguardado and Partida.guardar(mundo, RANURA):
		_indicador_guardado()

## Lo que el edificio del club pinta del mundo: niveles, salas elegidas,
## plantilla con dorsales, títulos y presidente.
func _contexto_edificio(c: Club) -> Dictionary:
	var pl: Array = []
	var orden := c.plantilla.duplicate()
	orden.sort_custom(func(a: Jugador, b: Jugador) -> bool: return (a.dorsal if a.dorsal > 0 else 99) < (b.dorsal if b.dorsal > 0 else 99))
	var n := 1
	for j: Jugador in orden:
		pl.append([j.dorsal if j.dorsal > 0 else n, Nombres.visible(j.nombre)])
		n += 1
	var dentro := {}
	if mundo.club_dentro != null:
		dentro = {"vestuario": mundo.club_dentro.vestuario, "sala_prensa": mundo.club_dentro.sala_prensa, "palco": mundo.club_dentro.palco}
	var titulos := mundo.roles.trofeos.size() if mundo.roles != null else 0
	var pres := ""
	if mundo.junta != null:
		pres = String(mundo.junta.presidente.get("nombre", ""))
	return {"inst": mundo.obras.niveles.duplicate() if mundo.obras != null else {}, "dentro": dentro,
		"plantilla": pl, "titulos": titulos, "presidente": pres,
		"gente": mundo.gente.fichas.duplicate(true) if mundo.gente != null else {},
		## Por referencia: lo que decores en el 3D se guarda en la partida.
		"interiores": mundo.interiores}
