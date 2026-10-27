class_name PantallaAjustes
extends "res://ui/pantallas/pantalla_ajustes_p1.gd"
## [Capa 2/2 de `pantalla_ajustes.gd`] fuente_de, _pintar_tipografia, _pintar_ranuras, _pintar_fondos_ajustes, _pintar_ajustes

## AJUSTES DEL JUGADOR (fase 0, paso 2): esta clase es la DUEÑA de las
## tipografías, el límite de fotogramas, las ranuras manuales y la sección
## abierta. Antes vivían repartidos por cuatro capas de `Principal`; ahí solo
## quedan puentes (`_tipografia`, `_fps_elegido`, `_secc_ajustes`, `_fuente_de`).

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

var seccion: String = "audio"

## LA TIPOGRAFIA. Siete, y la primera es la de siempre.
##
## Cada entrada es una lista de nombres que resuelve `Fuentes.para()`
## (`ui/fuentes.gd`): si el primero es una fuente PROPIA del juego
## (`assets/fuentes/`, OFL) se usa el archivo y el resto queda de repuesto del
## sistema; si no, se piden al sistema por nombre como antes («Segoe UI» de
## Windows, «Helvetica Neue» de macOS, el genérico al final).
##
## LOS EMOJI (26-10-2026): antes se colgaban «Segoe UI Emoji» y compañía, que
## no existen en Android ni en Web. Ahora toda tipografía, «Del juego» incluida,
## lleva la cadena de `Fuentes.repuesto()`: emojis en color del sistema si los
## hay y, si no, Noto Emoji + Noto Sans Symbols 2 propias.
const TIPOGRAFIAS := {
	"juego":     ["Del juego (por defecto)", []],
	"sistema":   ["Del sistema", ["Segoe UI", "Helvetica Neue", "Cantarell", "sans-serif"]],
	"diario":    ["De diario (serif)", ["Georgia", "Times New Roman", "Liberation Serif", "serif"]],
	"estrecha":  ["Estrecha (cabe más)", ["Barlow Condensed", "Arial Narrow", "Roboto Condensed", "DejaVu Sans Condensed", "sans-serif"]],
	"redonda":   ["Redonda y grande", ["Verdana", "Tahoma", "DejaVu Sans", "sans-serif"]],
	"informe":   ["De informe (mono)", ["Consolas", "Menlo", "DejaVu Sans Mono", "monospace"]],
	"titular":   ["De titular", ["Bebas Neue", "Impact", "Haettenschweiler", "DejaVu Sans Bold", "sans-serif"]],
}

## Los nombres de repuesto para los simbolos: los emojis en color del sistema.
## Se conserva por compatibilidad; la cadena completa (con las propias) es
## `Fuentes.repuesto()`.
const REPUESTO_SIMBOLOS := Fuentes.EMOJI_SISTEMA

var tipografia: String = "juego"
static var _fuentes: Dictionary = {}

## EL LÍMITE DE FOTOGRAMAS. En un portátil, dejar el juego a 300 fps calienta la
## máquina para dibujar la misma tabla trescientas veces por segundo. Treinta
## basta para una interfaz; sesenta para el estadio en 3D.
const FPS_OPCIONES := [30, 60, 120, 0]
var fps_elegido: int = 60

## LAS TRES RANURAS MANUALES de `vAjustes()`. `Partida` guarda por NOMBRE desde
## el porte —`guardar(m, nombre)`, `listar()`, `borrar()`— y el juego solo usaba
## una ranura fija: toda esa capacidad estaba escrita y era inalcanzable.
##
## Tres y no más porque tres es lo que se usa de verdad: la partida en curso,
## una copia antes de una decisión gorda, y una vieja por si acaso.
const RANURAS := ["ranura1", "ranura2", "ranura3"]

func fuente_de(clave: String) -> Font:
	if not TIPOGRAFIAS.has(clave):
		return null
	if _fuentes.has(clave):
		return _fuentes[clave]
	## «Del juego» es la de fábrica con la cadena de respaldo (`ui/fuentes.gd`).
	if clave == "juego":
		_fuentes[clave] = Fuentes.del_juego()
		return _fuentes[clave]
	var f := Fuentes.para((TIPOGRAFIAS[clave] as Array)[1])
	## Sin esto, un texto pequeno con una serif se ve sucio: la rejilla de pixeles
	## y los remates finos pelean, y a 10 px gana la rejilla.
	f.set("antialiasing", TextServer.FONT_ANTIALIASING_GRAY)
	f.set("subpixel_positioning", TextServer.SUBPIXEL_POSITIONING_AUTO)
	_fuentes[clave] = f
	return f

func _pintar_tipografia() -> void:
	var lt := p._texto(10, Principal.COL_SUAVE)
	lt.text = Idiomas.t("Tipografia")
	p._lista_ajustes.add_child(lt)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	p._lista_ajustes.add_child(flow)
	for k: String in TIPOGRAFIAS:
		var clave := k
		var b := Button.new()
		b.text = String((TIPOGRAFIAS[k] as Array)[0])
		b.add_theme_font_size_override("font_size", 10)
		b.toggle_mode = true
		b.button_pressed = tipografia == clave
		b.clip_text = true
		b.custom_minimum_size = Vector2(132, 24)
		## Cada boton se escribe CON su fuente: se elige mirando, igual que las
		## paletas. Un nombre de fuente no dice nada; verla, si.
		var f := fuente_de(clave)
		if f != null:
			b.add_theme_font_override("font", f)
		b.pressed.connect(func() -> void:
			tipografia = clave
			p._aplicar_aspecto()
			p._refrescar())
		flow.add_child(b)

func _pintar_ranuras() -> void:
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("RANURAS DE GUARDADO")
	p._lista_ajustes.add_child(t)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = Idiomas.t("Aparte del autoguardado. Sirven para dejar una copia antes de una decisión de la que no se vuelve.")
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_ajustes.add_child(ex)
	## Se lista una vez y se busca en memoria: `Partida.listar()` abre y lee la
	## cabecera de cada fichero, y llamarlo tres veces sería leer el disco tres
	## veces para pintar tres filas.
	var guardadas := {}
	for f: Dictionary in Partida.listar():
		guardadas[String(f.get("fichero", ""))] = f
	for i in RANURAS.size():
		var nombre := String(RANURAS[i])
		var hay: Dictionary = guardadas.get(nombre, {})
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_ajustes.add_child(fila)
		var et := p._texto(12, Principal.COL_TEXTO if not hay.is_empty() else Principal.COL_SUAVE)
		et.text = Idiomas.t("Ranura %d") % (i + 1)
		et.custom_minimum_size = Vector2(70, 0)
		fila.add_child(et)
		var desc := p._texto(11, Principal.COL_SUAVE)
		desc.text = Idiomas.t("%s · %d, semana %d") % [String(hay.get("club", "")), int(hay.get("anio", 0)), int(hay.get("semana", 0))] if not hay.is_empty() else Idiomas.t("vacía")
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc.clip_text = true
		fila.add_child(desc)
		var bg := Button.new()
		bg.text = Idiomas.t("Guardar")
		bg.add_theme_font_size_override("font_size", 11)
		bg.pressed.connect(func() -> void: p._partida.guardar_en(nombre))
		fila.add_child(bg)
		var bc := Button.new()
		bc.text = Idiomas.t("Cargar")
		bc.add_theme_font_size_override("font_size", 11)
		bc.disabled = hay.is_empty()
		bc.pressed.connect(func() -> void: p._partida.cargar_de(nombre))
		fila.add_child(bc)
	p._lista_ajustes.add_child(HSeparator.new())

## El selector de los veinticuatro fondos. Estaba suelto dentro de
## `_pintar_ajustes()`; sale a su función para que la sección de aspecto se lea.
func _pintar_fondos_ajustes() -> void:
	var tf := p._texto(11, Principal.COL_SUAVE)
	tf.text = Idiomas.t("FONDO DE PANTALLA")
	p._lista_ajustes.add_child(tf)
	var ef := p._texto(10, Principal.COL_SUAVE)
	ef.text = Idiomas.t("Va detrás de la interfaz. Los paneles siguen siendo opacos: un fondo que deja la tabla ilegible es un fondo malo.")
	ef.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_ajustes.add_child(ef)
	var op := OptionButton.new()
	op.add_theme_font_size_override("font_size", 11)
	op.clip_text = true
	## Sin esto el desplegable pide el ancho de su entrada más larga -386 px- y
	## empuja la raíz fuera de la ventana. Trampa ya pagada en este proyecto.
	op.fit_to_longest_item = false
	## EL ESTILO DEL MENÚ, arriba del fondo: es lo que más cambia la cara del
	## juego de un vistazo.
	var te := p._texto(11, Principal.COL_SUAVE)
	te.text = Idiomas.t("ESTILO DEL MENÚ")
	p._lista_ajustes.add_child(te)
	var fila_estilo := HFlowContainer.new()
	fila_estilo.add_theme_constant_override("h_separation", 4)
	p._lista_ajustes.add_child(fila_estilo)
	for e: Array in EstilosMenu.ESTILOS_MENU:
		var clave := String(e[0])
		var be := Button.new()
		be.text = String(e[1])
		be.add_theme_font_size_override("font_size", 11)
		be.toggle_mode = true
		be.button_pressed = p._estilo_menu == clave
		be.custom_minimum_size = Vector2(160, 26)
		be.pressed.connect(func() -> void:
			p._estilo_menu = clave
			p._reconstruir_grupos()
			p._guardar_preferencias()
			_pintar_ajustes())
		fila_estilo.add_child(be)
	## La rotación del menú central (mapa de metas 24).
	var rot := CheckButton.new()
	rot.text = Idiomas.t("Cambiar el diseño del menú central cada 10 minutos de juego")
	rot.button_pressed = p._rotar_diseno
	rot.toggled.connect(func(v: bool) -> void:
		p._rotar_diseno = v
		p._guardar_preferencias())
	p._lista_ajustes.add_child(rot)
	## «El bloqueo» (dueño, 27-10): apagado = todo abierto; encendido, algunos modos se ganan jugando.
	var blo := CheckButton.new()
	blo.text = Idiomas.t("Desbloquear modos jugando (si no, todo abierto)")
	blo.button_pressed = DesbloqueoModos.activo()
	blo.toggled.connect(func(v: bool) -> void: DesbloqueoModos.fijar_activo(v))
	p._lista_ajustes.add_child(blo)
	p._lista_ajustes.add_child(HSeparator.new())

	op.add_item("Sin fondo (verde plano)", 0)
	## La segunda entrada es la rotación: fijo o "que vaya cambiando", que es
	## como lo pidió el usuario. Va arriba del todo, antes de los 24 fondos,
	## porque es una decisión distinta -no es "cuál", es "uno o todos"-.
	op.add_item("🔀 Ir cambiando cada semana", 1)
	var elegido := 0
	if p._fondo_elegido == Principal.ROTAR_FONDO:
		elegido = 1
	for i in Fondo.NOMBRES.size():
		var k := String(Fondo.NOMBRES[i])
		op.add_item(String(Fondo.TITULOS.get(k, k)), i + 2)
		if k == p._fondo_elegido:
			elegido = i + 2
	op.selected = elegido
	op.item_selected.connect(func(idx: int) -> void:
		if idx == 0:
			p._fondo_elegido = ""
		elif idx == 1:
			p._fondo_elegido = Principal.ROTAR_FONDO
		else:
			p._fondo_elegido = String(Fondo.NOMBRES[idx - 2])
		p._aplicar_fondo())
	p._lista_ajustes.add_child(op)

func _pintar_ajustes() -> void:
	p._limpiar(p._lista_ajustes)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 4)
	chips.add_theme_constant_override("v_separation", 4)
	p._lista_ajustes.add_child(chips)
	for s: Array in SECCIONES_AJUSTES:
		var clave := String(s[0])
		var b := Button.new()
		b.text = String(s[1])
		b.add_theme_font_size_override("font_size", 11)
		b.toggle_mode = true
		b.button_pressed = seccion == clave
		b.clip_text = true
		b.custom_minimum_size = Vector2(126, 26)
		b.pressed.connect(func() -> void:
			seccion = clave
			_pintar_ajustes())
		chips.add_child(b)
	p._lista_ajustes.add_child(HSeparator.new())

	match seccion:
		"audio":
			var t1 := p._texto(11, Principal.COL_SUAVE)
			t1.text = Idiomas.t("SONIDO")
			p._lista_ajustes.add_child(t1)
			var fila1 := HBoxContainer.new()
			p._lista_ajustes.add_child(fila1)
			var et1 := p._texto(13, Principal.COL_TEXTO)
			et1.text = Idiomas.t("Sonidos del partido")
			et1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila1.add_child(et1)
			var b1 := Button.new()
			b1.text = "SÍ" if Sonido.encendido else "NO"
			b1.pressed.connect(func() -> void:
				Sonido.encendido = not Sonido.encendido
				p._refrescar())
			fila1.add_child(b1)
			p._ui_opciones._pintar_mezclador()
			p._ui_opciones._pintar_musica()
		"aspecto":
			## El tutorial se repite desde aquí: la última tarjeta del propio
			## recorrido lo promete ("AJUSTES → Interfaz").
			var tut := Button.new()
			tut.text = Idiomas.t("📖 Repetir el tutorial")
			tut.custom_minimum_size = Vector2(0, 32)
			tut.pressed.connect(func() -> void: p.abrir_tutorial())
			p._lista_ajustes.add_child(tut)
			p._lista_ajustes.add_child(HSeparator.new())
			_pintar_fondos_ajustes()
			_pintar_clima()
			p._lista_ajustes.add_child(HSeparator.new())
			_pintar_aspecto()
		"pantalla":
			_pintar_fotogramas()
			p._ui_opciones._pintar_dispositivo()
			p._ui_opciones._pintar_atajos()
		"juego":
			p._ui_opciones._pintar_idioma()
			p._ui_opciones._pintar_moneda()
			p._ui_opciones._pintar_velocidad_partido()
			p._ui_opciones._pintar_qol()
			AjustesVida.pintar(p)
		"acceso":
			_pintar_accesibilidad()
		"partida":
			_pintar_ranuras()
			_pintar_traspaso_partida()
			AjustesRegistro.pintar(p)
			var t2 := p._texto(11, Principal.COL_SUAVE)
			t2.text = Idiomas.t("GUARDADO")
			p._lista_ajustes.add_child(t2)
			var fila2 := HBoxContainer.new()
			p._lista_ajustes.add_child(fila2)
			var et2 := p._texto(13, Principal.COL_TEXTO)
			et2.text = Idiomas.t("Autoguardado")
			et2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila2.add_child(et2)
			var b2 := Button.new()
			b2.text = "SÍ" if p._autoguardado else "NO"
			b2.pressed.connect(func() -> void:
				p._autoguardado = not p._autoguardado
				p._refrescar())
			fila2.add_child(b2)
			var ex2 := p._texto(11, Principal.COL_SUAVE)
			ex2.text = Idiomas.t("Guarda solo al avanzar cada semana o cerrar temporada, en la misma ranura de \"Guardar\".")
			ex2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_ajustes.add_child(ex2)
			p._lista_ajustes.add_child(HSeparator.new())
			var t3 := p._texto(11, Principal.COL_SUAVE)
			t3.text = Idiomas.t("ACERCA DE")
			p._lista_ajustes.add_child(t3)
			var ac := p._texto(11, Principal.COL_SUAVE)
			ac.text = Idiomas.t("DINASTÍA Fútbol Manager · motor Godot. Los nombres de clubes y futbolistas generados usan sustitución letra→número; los datos reales que sí tienen nombre e imagen vienen de fuentes con licencia libre. La música y todos los efectos están sintetizados por el propio juego: no hay ni un fichero de audio.")
			ac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_ajustes.add_child(ac)
			## M-309: créditos y licencias de lo que no es propio.
			p._lista_ajustes.add_child(HSeparator.new())
			var t4 := p._texto(11, Principal.COL_SUAVE)
			t4.text = Idiomas.t("CRÉDITOS Y LICENCIAS")
			p._lista_ajustes.add_child(t4)
			for linea: String in Creditos.lineas():
				var cr := p._texto(10, Principal.COL_TEXTO)
				cr.text = "· " + linea
				cr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				p._lista_ajustes.add_child(cr)
			var fotos := p._texto(10, Principal.COL_SUAVE)
			fotos.text = Idiomas.t("Las fotos de futbolistas reales (solo en la versión privada) llevan su autor y su licencia bajo el retrato, en la ficha del jugador.")
			fotos.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_ajustes.add_child(fotos)

	## Esta pantalla se repinta sola al tocar una pestaña de sección, sin pasar
	## por `_refrescar()`, asi que se traduce aqui tambien.
	p._traducir_pantalla(p._lista_ajustes)
	## Cada cambio de esta pantalla vuelve a pintarla; guardar aqui recoge los
	## ajustes sin tener que colgar un guardado de cada boton.
	p._guardar_preferencias()
