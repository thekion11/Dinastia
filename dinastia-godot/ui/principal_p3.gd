extends "res://ui/principal_p2.gd"
## [Capa 3/17 de `principal.gd`] _acento_de, _aplicar_fondo, fecha_del_dia, fecha_de_hoy, fecha_larga, _limpiar … (+13)

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

const PALETAS := TablasMenu.PALETAS

const FORMAS_TARJETA := TablasMenu.FORMAS_TARJETA

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

## La sección de Ajustes abierta vive en `PantallaAjustes.seccion` (fase 0,
## paso 2); el puente conserva `p._secc_ajustes` para los chips y las pruebas.
var _secc_ajustes: String:
	get: return _ui_ajustes.seccion
	set(v): _ui_ajustes.seccion = v

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

const SECCIONES_GENTE := TablasMenu.SECCIONES_GENTE
var _secc_gente: String = "personas"

const SECC_REDES := TablasMenu.SECC_REDES
var _secc_redes: String = "redes"

## Puentes (fase 6, paso 7): viven en `PiezasUI`.
func _limpiar(n: Node) -> void: _piezas._limpiar(n)
func _traducir_bbcode(bb: String) -> String: return _piezas._traducir_bbcode(bb)
func _acento_de(c: Club) -> Color: return _piezas._acento_de(c)


## Puentes (fase 6, paso 7): viven en `ui/principal/tema_menu.gd`.
func _aplicar_fondo() -> void: _tema_menu._aplicar_fondo()
func _con_contraste(c: Color) -> Color: return _tema_menu._con_contraste(c)
func _color_de_paleta(c: Color) -> Color: return _tema_menu._color_de_paleta(c)


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
	c.a = 1.0 if _paleta == "contraste" else 0.94
	return c



## Puente: la píldora la viste `EstilosMenu.pildora()` con el estilo activo.
func _pildora(texto: String, tam: int = 12, alto: int = 32) -> Button:
	return _estilos.pildora(texto, tam, alto)

## Lo mismo para el registro, que pinta con BBCode y no pasa por `_texto()`.
func _bbcode_accesible(t: String) -> String:
	if not _daltonico:
		return t
	return t.replace("#4caf6d", "#56b4e9").replace("#e05555", "#d55e00").replace("#c9a227", "#e69f00")


func _escribir(bbcode: String) -> void:
	_registro.append_text(_bbcode_accesible(_traducir_bbcode(CompeticionInfo.visibles_en(bbcode))) + "\n")

func _liga_de(c: Club) -> Liga:
	for l in mundo.ligas:
		if l.clubes.has(c):
			return l
	return mundo.ligas[0]

func _dinero(n: int) -> String:
	return Eco.dinero(n)
