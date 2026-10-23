extends SubViewport
## (Parte 1 de 2 de `pantalla_estadio.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `pantalla_estadio.gd`, conserva la clase.)

## LA PANTALLA GIGANTE DEL ESTADIO, con contenido de verdad y en rotación.
##
## Pedido del usuario cinco veces seguidas entre el 22 y el 23-9-2026: "puede
## estar una visualización de los puntos de la competencia... máximos
## goleadores... o el resultado que van". La primera pasada (22-9) dejó un
## `SubViewport` con un `Label` "0 - 0" y el nombre de los clubes CORTADO a
## media palabra -está documentado en `LEEME.md` como "empezado, no cerrado"-.
## Esto es la segunda pasada, ya con el video de referencia del usuario
## (`marca/referencia/ejemplo-partido.mp4`, Soccer Manager 2026) delante:
##
##   - El marcador de ese juego es una barra oscura con ESCUDO + ABREVIATURA de
##     tres letras + los dos números dentro de un bloque ÁMBAR. Nunca el nombre
##     completo del club: por eso ahí no se corta nada y aquí sí se cortaba.
##     La abreviatura no puede desbordar -son tres letras-, así que el bug de
##     contención desaparece por diseño, no por parchear un `autowrap_mode`.
##   - Una pantalla de estadio de verdad NO enseña siempre lo mismo: va rotando
##     entre marcador, estadísticas, goleadores del partido, tabla y pichichis,
##     y corta a un "¡GOL!" a toda pantalla cuando pasa algo. Eso es lo que la
##     hace sentirse VIVA, que es lo que el usuario pedía con "interactivo".
##
## SEPARADA DE `ui/estadio.gd` A PROPÓSITO: `estadio.gd` ya pasa de 800 líneas y
## esto es una pantalla completa con seis diseños dentro. Además así se puede
## montar sola en una prueba de captura, sin levantar el estadio 3D entero
## (`pruebas/captura_paneles_pantalla.gd` hace justo eso).
##
## Todo lo que pinta sale de datos REALES: `Partido` para marcador, reloj y
## estadísticas; `al_gol()` para la lista de goleadores del partido; y
## `datos` -que se lo pasa quien abre el visor, porque `VistaEstadio` no conoce
## el `Mundo`- para la tabla y los máximos goleadores de la liga.

## 15×8 m es la malla que crea `StadiumBuilder._pantallas()`. 960×512 es
## exactamente esa proporción (1,875), así que el contenido no sale estirado.
const ANCHO := 960
const ALTO := 512

## Cuánto aguanta cada panel antes de pasar al siguiente. El marcador dura más
## que el resto: es lo que la gente mira, los demás son el relleno entre medias.
const SEG_MARCADOR := 11.0
const SEG_PANEL := 7.0
## El corte a "¡GOL!" tapa la rotación entera mientras dura.
const SEG_GOL := 6.5

const COL_FONDO := Color(0.027, 0.047, 0.086)
const COL_PANEL := Color(0.07, 0.10, 0.16)
const COL_TINTA := Color(0.92, 0.94, 0.97)
const COL_SUAVE := Color(0.56, 0.62, 0.72)
const COL_AMBAR := Color(0.95, 0.72, 0.16)
const COL_VERDE := Color(0.24, 0.78, 0.45)
const COL_ROJO := Color(0.85, 0.24, 0.24)

## Los seis diseños. `BIENVENIDA` es el único que se usa SIN partido -el visor
## del propio estadio desde Club → Estadio-, y `GOL` no entra en la rotación:
## lo fuerza `al_gol()` y se va solo.
## `CRUCES` (26-9-2026): los cruces de la ronda en una copa o en la fase de
## eliminación continental, donde no hay tabla que enseñar.
enum Pagina {MARCADOR, ESTADISTICAS, GOLES, TABLA, PICHICHI, BIENVENIDA, GOL, CRUCES}

var partido: Partido
## El club dueño del recinto (el local en un partido normal). Manda en los
## colores de la pantalla: es SU estadio, no el de la competición.
var casa: Club
var rival: Club
## Lo que `VistaEstadio` no puede calcular solo porque no conoce el `Mundo`:
##   {"liga": String, "jornada": int, "tabla": Array, "goleadores": Array}
##   tabla:       [{"nombre","pts","pj","dif","id"}...] ya ordenada
##   goleadores:  [{"nombre","club","goles"}...] ya ordenada
## Vacío es válido y esperado: esos dos paneles simplemente no entran en la
## rotación, no se pinta una tabla en blanco.
var datos: Dictionary = {}
var nombre_recinto := ""

var _paneles: Dictionary = {}       ## Panel -> Control
var _orden: Array[int] = []
var _idx := 0
var _t := 0.0
var _gol_restante := 0.0
var _goles: Array[Dictionary] = []  ## {"min","autor","abrev","casa"}

## Los nodos que cambian solos, guardados para reescribirles el texto en vez de
## reconstruir la pantalla entera cada minuto.
var _lbl_marcador: Label
var _lbl_reloj: Label
var _lbl_pos_casa: Label
var _lbl_pos_rival: Label
var _barra_pos: ColorRect
var _lbl_stats: Dictionary = {}     ## clave -> Label
var _caja_goles: VBoxContainer
var _lbl_gol_autor: Label
var _lbl_gol_min: Label
var _lbl_gol_marcador: Label
var _fondo_gol: ColorRect
## Qué panel se ve ahora mismo. Lo lee la prueba de captura para recorrer los
## seis sin depender de esperar la rotación real en tiempo de reloj.
var pagina_visible: int = Pagina.MARCADOR

# --- rotación y reloj -------------------------------------------------------

const SEG_REDIBUJO := 0.25
var _t_redibujo := 0.0

func _color_casa() -> Color:
	if casa == null:
		return Color(0.16, 0.34, 0.58)
	var c := Color(casa.color_acento()) if casa.color_acento() != "" else Color(casa.color1)
	## Un club de negro deja la franja invisible contra el fondo oscuro de la
	## pantalla. En vez de aclarar el negro a un gris sucio -que es lo que
	## hacía la primera versión, y en la captura de Colo-Colo se veía justo
	## así-, se prueba primero con SU SEGUNDO COLOR, que en un club de negro
	## suele ser el claro de verdad (Colo-Colo: negro y blanco). Solo si ese
	## también sale oscuro se recurre a aclarar.
	if c.get_luminance() < 0.18:
		var alt := Color(casa.color2) if casa.color2 != "" else c
		c = alt if alt.get_luminance() >= 0.30 else c.lightened(0.45)
	return c

func _etiqueta(texto: String, tam: int, color: Color,
		alineacion: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = alineacion
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	## SIEMPRE recortado. Es la lección del 22-9: un nombre largo ensanchaba el
	## `Label`, el `Label` ensanchaba su contenedor y el texto se salía del
	## lienzo entero. Con esto se corta por el borde de su propio hueco.
	l.clip_text = true
	return l

# --- paneles ----------------------------------------------------------------

func _base(titulo: String) -> Control:
	var c := Control.new()
	c.position = Vector2.ZERO
	c.size = Vector2(ANCHO, ALTO)
	if titulo != "":
		var t := _etiqueta(titulo, 26, COL_AMBAR)
		t.position = Vector2(48, 28)
		t.size = Vector2(ANCHO - 96, 34)
		c.add_child(t)
	return c

func _escudo_de(c: Club, pos: Vector2, lado: int) -> Control:
	var tr := TextureRect.new()
	tr.position = pos
	tr.size = Vector2(lado, lado)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if c != null:
		tr.texture = Escudo.textura(c, lado)
	return tr

# --- utilidades -------------------------------------------------------------

## Las tres letras del video ("FTR", "JUV"). Se salta las palabras cortas y las
## iniciales con punto -"D. Limache" tiene que dar "LIM", no "D. "-, que es
## justo el caso que reventaba la versión anterior de esta pantalla.
static func abreviatura(c: Club) -> String:
	if c == null:
		return "—"
	for parte in c.nombre.split(" ", false):
		var limpia := String(parte).replace(".", "").replace("-", "")
		if limpia.length() >= 3:
			return limpia.substr(0, 3).to_upper()
	var todo := c.nombre.replace(" ", "").replace(".", "").replace("-", "")
	return todo.substr(0, mini(3, todo.length())).to_upper()

## La barra de posesión: el bloque de color del dueño de casa creciendo sobre
## una pista clara. Se reutiliza en el marcador y en las estadísticas.
func _barra_posesion(padre: Control, y: float) -> void:
	var etiqueta := _etiqueta("POSESIÓN", 20, COL_SUAVE, HORIZONTAL_ALIGNMENT_CENTER)
	etiqueta.position = Vector2(120, y - 30)
	etiqueta.size = Vector2(720, 26)
	padre.add_child(etiqueta)
	var pista := ColorRect.new()
	pista.color = Color(1, 1, 1, 0.16)
	pista.position = Vector2(120, y)
	pista.size = Vector2(720, 26)
	padre.add_child(pista)
	_barra_pos = ColorRect.new()
	_barra_pos.color = _color_casa()
	_barra_pos.position = Vector2(120, y)
	_barra_pos.size = Vector2(360, 26)
	padre.add_child(_barra_pos)
	_lbl_pos_casa = _etiqueta("50%", 24, COL_TINTA, HORIZONTAL_ALIGNMENT_LEFT)
	_lbl_pos_casa.position = Vector2(48, y - 2)
	_lbl_pos_casa.size = Vector2(66, 30)
	padre.add_child(_lbl_pos_casa)
	_lbl_pos_rival = _etiqueta("50%", 24, COL_SUAVE, HORIZONTAL_ALIGNMENT_RIGHT)
	_lbl_pos_rival.position = Vector2(ANCHO - 114, y - 2)
	_lbl_pos_rival.size = Vector2(66, 30)
	padre.add_child(_lbl_pos_rival)

func _pie(padre: Control) -> void:
	var linea := ColorRect.new()
	linea.color = Color(1, 1, 1, 0.10)
	linea.position = Vector2(48, ALTO - 58)
	linea.size = Vector2(ANCHO - 96, 2)
	padre.add_child(linea)
	var partes: Array[String] = []
	if nombre_recinto != "":
		partes.append(nombre_recinto.to_upper())
	elif casa != null:
		partes.append(casa.nombre.to_upper())
	var liga := String(datos.get("liga", ""))
	if liga != "":
		partes.append(liga.to_upper())
	var jor := int(datos.get("jornada", 0))
	if jor > 0:
		partes.append("FECHA %d" % jor)
	var t := _etiqueta("  ·  ".join(partes), 20, COL_SUAVE)
	t.position = Vector2(48, ALTO - 48)
	t.size = Vector2(ANCHO - 96, 30)
	padre.add_child(t)

## El panel principal, calcado del video de referencia: escudo, tres letras,
## los números en un bloque ámbar, tres letras, escudo. Y debajo el reloj y la
## posesión, que es lo que de verdad se mira desde la grada.
func _panel_marcador() -> Control:
	if partido == null:
		return null
	var c := _base("")
	var local := partido.local
	var visita := partido.visita
	c.add_child(_escudo_de(local, Vector2(56, 86), 150))
	c.add_child(_escudo_de(visita, Vector2(ANCHO - 206, 86), 150))

	var ab_l := _etiqueta(abreviatura(local), 56, COL_TINTA, HORIZONTAL_ALIGNMENT_RIGHT)
	ab_l.position = Vector2(220, 130)
	ab_l.size = Vector2(120, 66)
	c.add_child(ab_l)
	var ab_v := _etiqueta(abreviatura(visita), 56, COL_TINTA, HORIZONTAL_ALIGNMENT_LEFT)
	ab_v.position = Vector2(ANCHO - 340, 130)
	ab_v.size = Vector2(120, 66)
	c.add_child(ab_v)

	var caja := ColorRect.new()
	caja.color = COL_AMBAR
	caja.position = Vector2(356, 96)
	caja.size = Vector2(248, 134)
	c.add_child(caja)
	_lbl_marcador = _etiqueta("0 - 0", 96, Color(0.05, 0.06, 0.09), HORIZONTAL_ALIGNMENT_CENTER)
	_lbl_marcador.position = caja.position
	_lbl_marcador.size = caja.size
	c.add_child(_lbl_marcador)

	## El reloj, en su propia chapa oscura -como el "00:01" de la esquina del
	## video-, con el punto rojo de "en vivo" al lado.
	var chapa := ColorRect.new()
	chapa.color = COL_PANEL
	chapa.position = Vector2(370, 252)
	chapa.size = Vector2(220, 62)
	c.add_child(chapa)
	var punto := ColorRect.new()
	punto.color = COL_ROJO
	punto.position = Vector2(398, 274)
	punto.size = Vector2(18, 18)
	c.add_child(punto)
	_lbl_reloj = _etiqueta("0'", 44, COL_TINTA, HORIZONTAL_ALIGNMENT_CENTER)
	_lbl_reloj.position = Vector2(420, 252)
	_lbl_reloj.size = Vector2(150, 62)
	c.add_child(_lbl_reloj)

	_barra_posesion(c, 340)
	_pie(c)
	return c

func _panel_estadisticas() -> Control:
	if partido == null:
		return null
	var c := _base("ESTADÍSTICAS DEL PARTIDO")
	var ab_casa := abreviatura(casa) if casa != null else abreviatura(partido.local)
	var ab_riv := abreviatura(rival) if rival != null else abreviatura(partido.visita)
	var cab_a := _etiqueta(ab_casa, 34, _color_casa(), HORIZONTAL_ALIGNMENT_LEFT)
	cab_a.position = Vector2(48, 78)
	cab_a.size = Vector2(160, 44)
	c.add_child(cab_a)
	var cab_b := _etiqueta(ab_riv, 34, COL_SUAVE, HORIZONTAL_ALIGNMENT_RIGHT)
	cab_b.position = Vector2(ANCHO - 208, 78)
	cab_b.size = Vector2(160, 44)
	c.add_child(cab_b)

	_barra_posesion(c, 168)
	var filas := [["remates", "REMATES"], ["arco", "AL ARCO"],
		["corners", "CÓRNERS"], ["faltas", "FALTAS"]]
	var y := 232.0
	for f: Array in filas:
		var clave := String(f[0])
		var a := _etiqueta("0", 32, COL_TINTA, HORIZONTAL_ALIGNMENT_LEFT)
		a.position = Vector2(48, y)
		a.size = Vector2(100, 42)
		c.add_child(a)
		_lbl_stats[clave + "_a"] = a
		var mid := _etiqueta(String(f[1]), 24, COL_SUAVE, HORIZONTAL_ALIGNMENT_CENTER)
		mid.position = Vector2(160, y)
		mid.size = Vector2(ANCHO - 320, 42)
		c.add_child(mid)
		var b := _etiqueta("0", 32, COL_TINTA, HORIZONTAL_ALIGNMENT_RIGHT)
		b.position = Vector2(ANCHO - 148, y)
		b.size = Vector2(100, 42)
		c.add_child(b)
		_lbl_stats[clave + "_b"] = b
		y += 50.0
	_pie(c)
	return c

func _panel_goles() -> Control:
	if partido == null:
		return null
	var c := _base("GOLES DEL PARTIDO")
	_caja_goles = VBoxContainer.new()
	_caja_goles.position = Vector2(48, 86)
	_caja_goles.size = Vector2(ANCHO - 96, ALTO - 160)
	_caja_goles.add_theme_constant_override("separation", 10)
	c.add_child(_caja_goles)
	_pie(c)
	return c

func _fila_tabla(pos: String, club: String, pj: String, pts: String,
		color: Color, tam: int) -> Control:
	var cont := Control.new()
	cont.clip_contents = true
	var a := _etiqueta(pos, tam, COL_SUAVE, HORIZONTAL_ALIGNMENT_RIGHT)
	a.position = Vector2(0, 0)
	a.size = Vector2(52, 44)
	cont.add_child(a)
	var b := _etiqueta(club, tam, color)
	b.position = Vector2(76, 0)
	b.size = Vector2(ANCHO - 96 - 76 - 200, 44)
	cont.add_child(b)
	var d := _etiqueta(pj, tam, COL_SUAVE, HORIZONTAL_ALIGNMENT_RIGHT)
	d.position = Vector2(ANCHO - 96 - 190, 0)
	d.size = Vector2(80, 44)
	cont.add_child(d)
	var e := _etiqueta(pts, tam, color, HORIZONTAL_ALIGNMENT_RIGHT)
	e.position = Vector2(ANCHO - 96 - 90, 0)
	e.size = Vector2(90, 44)
	cont.add_child(e)
	return cont

func _panel_tabla() -> Control:
	var filas: Array = datos.get("tabla", [])
	if filas.is_empty():
		return null
	var titulo := String(datos.get("titulo_tabla", "TABLA DE POSICIONES"))
	var liga := String(datos.get("liga", ""))
	if liga != "":
		titulo += "  ·  " + liga.to_upper()
	var c := _base(titulo)
	var enc := _fila_tabla("#", "CLUB", "PJ", "PTS", COL_SUAVE, 22)
	enc.position = Vector2(48, 80)
	enc.size = Vector2(ANCHO - 96, 32)
	c.add_child(enc)
	var y := 120.0
	for i in mini(6, filas.size()):
		var f: Dictionary = filas[i]
		var id := String(f.get("id", ""))
		## Los dos clubes que están jugando, resaltados: es lo primero que
		## busca el hincha cuando la pantalla enseña la tabla.
		var mio := (casa != null and id == casa.id)
		var suyo := (rival != null and id == rival.id)
		var color := _color_casa() if mio else (COL_AMBAR if suyo else COL_TINTA)
		var fila := _fila_tabla(str(i + 1), String(f.get("nombre", "—")),
			str(int(f.get("pj", 0))), str(int(f.get("pts", 0))), color, 28)
		fila.position = Vector2(48, y)
		fila.size = Vector2(ANCHO - 96, 44)
		c.add_child(fila)
		y += 50.0
	_pie(c)
	return c

func _panel_pichichi() -> Control:
	var filas: Array = datos.get("goleadores", [])
	if filas.is_empty():
		return null
	var c := _base("MÁXIMOS GOLEADORES")
	var enc := _fila_tabla("#", "JUGADOR", "", "GOL", COL_SUAVE, 22)
	enc.position = Vector2(48, 80)
	enc.size = Vector2(ANCHO - 96, 32)
	c.add_child(enc)
	var y := 120.0
	for i in mini(6, filas.size()):
		var f: Dictionary = filas[i]
		var nombre := String(f.get("nombre", "—"))
		var club := String(f.get("club", ""))
		var mio := casa != null and club == casa.nombre
		var texto := nombre if club == "" else "%s   ·   %s" % [nombre, club]
		var fila := _fila_tabla(str(i + 1), texto, "",
			str(int(f.get("goles", 0))), _color_casa() if mio else COL_TINTA, 28)
		fila.position = Vector2(48, y)
		fila.size = Vector2(ANCHO - 96, 44)
		c.add_child(fila)
		y += 50.0
	_pie(c)
	return c

static func _miles(n: int) -> String:
	var s := str(maxi(n, 0))
	var salida := ""
	var cuenta := 0
	for i in range(s.length() - 1, -1, -1):
		salida = s[i] + salida
		cuenta += 1
		if cuenta % 3 == 0 and i > 0:
			salida = "." + salida
	return salida

## Sin partido -Club → Estadio, el recinto vacío-: escudo grande, nombre del
## club y el aforo. Antes aquí no había NADA en rotación, solo el degradado
## estático que pinta `StadiumBuilder._pantalla_textura()`.
func _panel_bienvenida() -> Control:
	if partido != null:
		return null
	var c := _base("")
	if casa != null:
		c.add_child(_escudo_de(casa, Vector2(ANCHO / 2.0 - 90, 64), 180))
		var n := _etiqueta(casa.nombre.to_upper(), 52, COL_TINTA, HORIZONTAL_ALIGNMENT_CENTER)
		n.position = Vector2(48, 270)
		n.size = Vector2(ANCHO - 96, 64)
		c.add_child(n)
		var sub := _etiqueta("BIENVENIDOS  ·  %s BUTACAS" % _miles(casa.estadio_aforo),
			26, COL_AMBAR, HORIZONTAL_ALIGNMENT_CENTER)
		sub.position = Vector2(48, 344)
		sub.size = Vector2(ANCHO - 96, 40)
		c.add_child(sub)
	_pie(c)
	return c
