class_name MarcadorTV
extends Control
## EL MARCADOR DE TELEVISIÓN DEL PARTIDO (17-11, punto 5 de `COMPARACION_REFERENCIAS_PARTIDO_2026-11-16.md`, referencia FC Mobile).
## Antes era una línea de texto («Avellaneda  0 - 0  Turia CF      1'») sobre una caja oscura. Ahora es el bloque compacto de las
## transmisiones: arriba a la izquierda, por cada club una barra con sus dos colores, su escudo (`Escudo.textura`) y sus siglas de tres
## letras (`PantallaEstadio.abreviatura`, las mismas de la pantalla gigante); en medio los goles en una caja clara; y el reloj en su
## propia caja, pegada a la derecha. Debajo de cada mitad, una franja del color fuerte del club.
## Se DIBUJA entero en un solo `_draw` y solo se repinta si cambia el resultado o el reloj. BARATO (medido con `MedirHudAB`): solo
## rectángulos (se agrupan en una llamada), los DOS escudos en UNA textura y un solo tamaño de letra: 3 llamadas de dibujo. Crece con el HUD del móvil (`HudTactil.f`) y respeta la muesca. La fuente es Bebas Neue (OFL, `assets/fuentes`).
## `etiqueta` es un `Label` OCULTO con el texto de siempre: lo leen las pruebas y quien quiera el marcador en texto.

const ALTO := 40.0
const BARRA := 6.0
const ESCUDO := 28.0
const FONDO := Color(0.055, 0.065, 0.085, 0.88)
const CAJA_GOLES := Color(0.1, 0.34, 0.86, 0.97)   ## el resultado sobre fondo de COLOR, como en la tele
const TINTA_GOLES := Color(1, 1, 1)
const LETRA := 26.0   ## un solo tamaño de letra: un solo atlas de la fuente, una sola llamada de dibujo para todo el texto
const CAJA_RELOJ := Color(0.13, 0.15, 0.19, 0.92)
const TINTA_RELOJ := Color(1.0, 0.86, 0.3)

var etiqueta := Label.new()
var local: Club
var visita: Club
var goles_local := 0
var goles_visita := 0
var reloj := "0'"
var escala := 1.0
var _fuente: Font
var _sig := ["", ""]
var _esc: Texture2D   ## los dos escudos juntos (izquierda el local), para dibujarlos en una sola llamada
var _col: Array[Color] = [Color.WHITE, Color.WHITE]
var _col2: Array[Color] = [Color.WHITE, Color.WHITE]

static var _bebas: Font

## Lo monta arriba a la izquierda de `vista` (el estadio) con los dos clubes.
static func poner(vista: Control, l: Club, v: Club) -> MarcadorTV:
	var m := MarcadorTV.new()
	m.name = "MarcadorTV"
	m.local = l
	m.visita = v
	m.escala = HudTactil.f(vista)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.position = Vector2(18.0 + HudTactil.margen(vista).x, 12.0)
	vista.add_child(m)
	return m

## La fuente de los números y las siglas (una vez por partida).
static func fuente() -> Font:
	if _bebas == null:
		_bebas = Fuentes.para(["Bebas Neue"])
	return _bebas if _bebas != null else ThemeDB.fallback_font

## El color FUERTE de un club para el HUD: el principal, salvo que sea casi negro o se pierda contra el césped (entonces el segundo);
## siempre con brillo suficiente para leerse sobre el fondo oscuro. Lo usan también los nombres y el radar.
static func color_vivo(c: Club, segundo := false) -> Color:
	if c == null:
		return Color.WHITE
	var a := Color(c.color2 if segundo else c.color1)
	var b := Color(c.color1 if segundo else c.color2)
	if not segundo and (a.get_luminance() < 0.12 or _de_cesped(a)) and b.get_luminance() >= 0.15 and not _de_cesped(b):
		a = b
	if a.v < 0.55:
		a.v = 0.55 if a.s > 0.25 else 0.35
	return a

## Un verde que se pierde contra el césped.
static func _de_cesped(c: Color) -> bool:
	return c.s > 0.3 and c.h > 0.22 and c.h < 0.45

func _ready() -> void:
	etiqueta.visible = false
	add_child(etiqueta)
	_fuente = fuente()
	for i in 2:
		var c: Club = local if i == 0 else visita
		_sig[i] = PantallaEstadio.abreviatura(c)
		_col[i] = color_vivo(c)
		_col2[i] = Color(c.color2) if c != null else Color.WHITE
	_esc = escudos_juntos(local, visita, int(ceilf(ESCUDO * escala)))
	_medir()

## Los escudos de los dos clubes en UNA textura de 2·lado × lado (izquierda el local).
static func escudos_juntos(l: Club, v: Club, lado: int) -> Texture2D:
	var img := Image.create(lado * 2, lado, false, Image.FORMAT_RGBA8)
	for i in 2:
		var c: Club = l if i == 0 else v
		var t := Escudo.textura(c, lado) if c != null else null
		var e := t.get_image() if t != null else null
		if e == null:
			continue
		if e.is_compressed():
			e.decompress()
		e.convert(Image.FORMAT_RGBA8)
		## Cabe en el cuadrado sin deformarse, centrado.
		var k := minf(float(lado) / e.get_width(), float(lado) / e.get_height())
		var tam := Vector2i(maxi(1, int(e.get_width() * k)), maxi(1, int(e.get_height() * k)))
		e.resize(tam.x, tam.y, Image.INTERPOLATE_LANCZOS)
		img.blit_rect(e, Rect2i(Vector2i.ZERO, tam), Vector2i(i * lado + (lado - tam.x) / 2, (lado - tam.y) / 2))
	return ImageTexture.create_from_image(img)

## Resultado y reloj; solo repinta si algo cambió.
func fijar(gl: int, gv: int, r: String) -> void:
	if gl == goles_local and gv == goles_visita and r == reloj:
		return
	var ancho_antes := _ancho_reloj()
	goles_local = gl
	goles_visita = gv
	reloj = r
	if not is_equal_approx(ancho_antes, _ancho_reloj()):
		_medir()
	queue_redraw()

func _tam(base: float) -> int:
	return int(roundf(base * escala))

func _ancho(txt: String, base: float) -> float:
	return _fuente.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, _tam(base)).x if _fuente != null else txt.length() * base * 0.5 * escala

func _ancho_reloj() -> float:
	return maxf(_ancho(reloj, LETRA), _ancho("00'", LETRA)) + 22.0 * escala

func _ancho_mitad(i: int) -> float:
	return (BARRA + 8.0 + ESCUDO + 7.0 + 10.0) * escala + _ancho(String(_sig[i]), LETRA)

func _ancho_goles() -> float:
	return maxf(_ancho("%d - %d" % [goles_local, goles_visita], LETRA) + 20.0 * escala, 64.0 * escala)

func _medir() -> void:
	var w := _ancho_mitad(0) + _ancho_goles() + _ancho_mitad(1) + 5.0 * escala + _ancho_reloj()
	size = Vector2(w, ALTO * escala)
	custom_minimum_size = size
	pivot_offset = size * 0.5   ## el «salto» del gol (`_animar_marcador_gol`) crece parejo

func _texto(txt: String, centro_x: float, base: float, col: Color) -> void:
	var t := _tam(base)
	var w := _fuente.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, t).x
	var y := size.y * 0.5 + (_fuente.get_ascent(t) - _fuente.get_descent(t)) * 0.5
	draw_string(_fuente, Vector2(centro_x - w * 0.5, y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, t, col)

func _draw() -> void:
	if _fuente == null:
		return
	var e := escala
	var h := size.y
	var wm0 := _ancho_mitad(0)
	var wg := _ancho_goles()
	var wm1 := _ancho_mitad(1)
	var wr := _ancho_reloj()
	var x_reloj := wm0 + wg + wm1 + 5.0 * e
	## 1) Todo lo que no lleva textura, seguido (una llamada): fondos, barras de los dos colores a los lados, la franja del color
	## fuerte bajo cada mitad y la caja de color del resultado.
	draw_rect(Rect2(0, 0, wm0 + wg + wm1, h), FONDO)
	draw_rect(Rect2(x_reloj, 0, wr, h), CAJA_RELOJ)
	for i in 2:
		var x0 := 0.0 if i == 0 else wm0 + wg + wm1 - BARRA * e
		draw_rect(Rect2(x0, 0, BARRA * e, h * 0.5), _col[i])
		draw_rect(Rect2(x0, h * 0.5, BARRA * e, h * 0.5), _col2[i])
		var xf := 0.0 if i == 0 else wm0 + wg
		draw_rect(Rect2(xf, h - 3.0 * e, wm0 if i == 0 else wm1, 3.0 * e), _col[i])
	draw_rect(Rect2(wm0, 0, wg, h), CAJA_GOLES)
	## 2) Los dos escudos (una textura, una llamada).
	var lado := ESCUDO * e
	var y_esc := (h - lado) * 0.5 - 1.0 * e
	if _esc != null:
		var ls := float(_esc.get_height())
		draw_texture_rect_region(_esc, Rect2((BARRA + 8.0) * e, y_esc, lado, lado), Rect2(0, 0, ls, ls))
		draw_texture_rect_region(_esc, Rect2(wm0 + wg + wm1 - (BARRA + 8.0) * e - lado, y_esc, lado, lado), Rect2(ls, 0, ls, ls))
	## 3) Siglas, goles y reloj (una letra, una llamada).
	var w_sig0 := _ancho(String(_sig[0]), LETRA)
	var w_sig1 := _ancho(String(_sig[1]), LETRA)
	_texto(String(_sig[0]), (BARRA + 8.0 + ESCUDO + 7.0) * e + w_sig0 * 0.5, LETRA, Color.WHITE)
	_texto(String(_sig[1]), wm0 + wg + 10.0 * e + w_sig1 * 0.5, LETRA, Color.WHITE)
	_texto("%d - %d" % [goles_local, goles_visita], wm0 + wg * 0.5, LETRA, TINTA_GOLES)
	_texto(reloj, x_reloj + wr * 0.5, LETRA, TINTA_RELOJ)
