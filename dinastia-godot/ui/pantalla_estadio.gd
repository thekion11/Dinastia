class_name PantallaEstadio
extends SubViewport
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

## `p` puede ser null: entonces la pantalla se queda en modo "bienvenida" +
## tabla + goleadores, que es lo que enseña un estadio el día que no se juega.
func montar(club_casa: Club, club_rival: Club, p: Partido, d: Dictionary,
		recinto: String = "") -> void:
	casa = club_casa
	rival = club_rival
	partido = p
	datos = d
	nombre_recinto = recinto
	size = Vector2i(ANCHO, ALTO)
	## A RITMO DE MARCADOR, NO DE FOTOGRAMA (25-9-2026). Con `UPDATE_ALWAYS`
	## la pantalla entera se volvía a dibujar 60 veces por segundo para
	## enseñar un minuto que cambia cada segundo y un panel que rota cada
	## siete. Ahora se dibuja al cambiar de panel y cuatro veces por segundo
	## (`_process()`), que es de sobra para el reloj.
	render_target_update_mode = SubViewport.UPDATE_ONCE
	transparent_bg = false
	## Aquí dentro solo hay `Control`s. Sin esto el viewport arrastra toda la
	## maquinaria 3D en cada repintado -y se repinta en cada frame- para no
	## dibujar nada.
	disable_3d = true
	_construir()

func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = COL_FONDO
	fondo.position = Vector2.ZERO
	fondo.size = Vector2(ANCHO, ALTO)
	add_child(fondo)

	## La franja de arriba lleva el color del club de casa: es lo único de la
	## pantalla que cambia de estadio a estadio, y basta para que no se vean
	## todas iguales. NO se usa como fondo -ese fue el bug del 22-9: un club de
	## camiseta negra daba una pantalla negra con el texto perdido encima-.
	var acento := ColorRect.new()
	acento.color = _color_casa()
	acento.position = Vector2.ZERO
	acento.size = Vector2(ANCHO, 12)
	add_child(acento)

	_paneles[Pagina.MARCADOR] = _panel_marcador()
	_paneles[Pagina.ESTADISTICAS] = _panel_estadisticas()
	_paneles[Pagina.GOLES] = _panel_goles()
	_paneles[Pagina.TABLA] = _panel_tabla()
	_paneles[Pagina.PICHICHI] = _panel_pichichi()
	_paneles[Pagina.BIENVENIDA] = _panel_bienvenida()
	_paneles[Pagina.GOL] = _panel_gol()
	_paneles[Pagina.CRUCES] = _panel_cruces()
	for k: int in _paneles:
		var c: Control = _paneles[k]
		if c == null:
			continue
		## Cada panel recorta lo suyo. Es el candado contra el bug de la
		## primera pasada: un `Label` con texto más ancho que su hueco empuja
		## al contenedor y se sale del lienzo; con `clip_contents` lo peor que
		## puede pasar es que se corte por el borde del panel, nunca que
		## desborde la pantalla.
		c.clip_contents = true
		c.visible = false
		add_child(c)

	_rehacer_orden()
	mostrar(_orden[0] if not _orden.is_empty() else Pagina.MARCADOR)
	refrescar()

## Qué paneles entran en la rotación. Se recalcula cuando cae el primer gol
## (antes de eso, el panel de goleadores del partido estaría vacío).
func _rehacer_orden() -> void:
	_orden.clear()
	if partido != null:
		_orden.append(Pagina.MARCADOR)
		_orden.append(Pagina.ESTADISTICAS)
		if not _goles.is_empty():
			_orden.append(Pagina.GOLES)
	else:
		_orden.append(Pagina.BIENVENIDA)
	if not (datos.get("tabla", []) as Array).is_empty():
		_orden.append(Pagina.TABLA)
	if not (datos.get("cruces", []) as Array).is_empty():
		_orden.append(Pagina.CRUCES)
	if not (datos.get("goleadores", []) as Array).is_empty():
		_orden.append(Pagina.PICHICHI)

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

# --- rotación y reloj -------------------------------------------------------

const SEG_REDIBUJO := 0.25
var _t_redibujo := 0.0

func _process(delta: float) -> void:
	_t_redibujo += delta
	if _t_redibujo >= SEG_REDIBUJO:
		_t_redibujo = 0.0
		render_target_update_mode = SubViewport.UPDATE_ONCE
	## BUG REAL, ENCONTRADO CON LA PRUEBA DE CAPTURA (23-9-2026): este
	## `refrescar()` estaba DESPUÉS del `return` del corte de gol, así que
	## durante los 6,5 s del "¡GOOOL!" el marcador de debajo no se enteraba del
	## gol -y al volver a la rotación seguía diciendo el resultado anterior
	## hasta el siguiente frame-. La prueba lo cazó pidiendo "1 - 0" y leyendo
	## "0 - 0". Va lo primero y sin condiciones: es barato (solo reescribe
	## texto) y así no hay ningún camino que se lo salte.
	refrescar()
	if _gol_restante > 0.0:
		_gol_restante -= delta
		if _gol_restante <= 0.0:
			_rehacer_orden()
			_idx = 0
			_t = 0.0
			mostrar(_orden[0] if not _orden.is_empty() else Pagina.MARCADOR)
		return
	if _orden.size() > 1:
		_t += delta
		var tope := SEG_MARCADOR if _orden[_idx] == Pagina.MARCADOR else SEG_PANEL
		if _t >= tope:
			_t = 0.0
			_idx = (_idx + 1) % _orden.size()
			mostrar(_orden[_idx])

## Público a propósito: la prueba de captura fuerza cada panel en vez de
## esperar siete segundos de reloj real por cada uno.
func mostrar(p: int) -> void:
	for k: int in _paneles:
		var c: Control = _paneles[k]
		if c != null:
			c.visible = (k == p)
	pagina_visible = p
	render_target_update_mode = SubViewport.UPDATE_ONCE

## Repinta solo lo que cambia con el partido. Barato a propósito: se llama en
## cada frame y no crea ni destruye nada, solo reescribe texto.
func refrescar() -> void:
	if partido == null:
		return
	if _lbl_marcador != null:
		_lbl_marcador.text = "%d - %d" % [partido.goles_local, partido.goles_visita]
	if _lbl_reloj != null:
		_lbl_reloj.text = "%d'" % partido.minuto
	var pos_l := clampf(partido.posesion_local, 0.0, 100.0)
	## `posesion_local` es siempre la del LOCAL. Si el dueño del recinto juega
	## de visita -un estadio neutral, una final-, hay que darle la vuelta o la
	## pantalla anunciaría la posesión del rival con el escudo de casa.
	var pos_casa := pos_l if _casa_es_local() else 100.0 - pos_l
	if _lbl_pos_casa != null:
		_lbl_pos_casa.text = "%d%%" % int(round(pos_casa))
	if _lbl_pos_rival != null:
		_lbl_pos_rival.text = "%d%%" % int(round(100.0 - pos_casa))
	if _barra_pos != null:
		_barra_pos.size.x = maxf(4.0, 720.0 * pos_casa / 100.0)
	_refrescar_stats()

func _casa_es_local() -> bool:
	return partido == null or casa == null or partido.local == casa

func _refrescar_stats() -> void:
	if _lbl_stats.is_empty() or partido == null:
		return
	var soy_local := _casa_es_local()
	_par_stat("remates", partido.remates_local, partido.remates_visita, soy_local)
	_par_stat("arco", partido.tiros_puerta_local, partido.tiros_puerta_visita, soy_local)
	_par_stat("corners", partido.corners_local, partido.corners_visita, soy_local)
	_par_stat("faltas", partido.faltas_local, partido.faltas_visita, soy_local)

func _par_stat(clave: String, val_local: int, val_visita: int, soy_local: bool) -> void:
	var a: Label = _lbl_stats.get(clave + "_a")
	var b: Label = _lbl_stats.get(clave + "_b")
	if a != null:
		a.text = str(val_local if soy_local else val_visita)
	if b != null:
		b.text = str(val_visita if soy_local else val_local)

# --- el corte a "¡GOL!" -----------------------------------------------------

## Lo llama `VistaEstadio._al_gol()`. El marcador que se pinta ya viene subido
## -esta pantalla nunca cuenta goles por su cuenta, solo enseña los de
## `Partido`-, así que se lee después de que el simulador haya hecho lo suyo.
func al_gol(club_gol: Club, autor: Jugador, minuto: int) -> void:
	var de_casa := club_gol == casa
	_goles.append({
		"min": minuto,
		"autor": autor.nombre if autor != null else "—",
		"abrev": abreviatura(club_gol),
		"casa": de_casa,
	})
	_repintar_goles()
	if _lbl_gol_autor != null:
		_lbl_gol_autor.text = (autor.nombre if autor != null else "GOL").to_upper()
	if _lbl_gol_min != null:
		_lbl_gol_min.text = "MINUTO %d  ·  %s" % [minuto, abreviatura(club_gol)]
	if _lbl_gol_marcador != null and partido != null:
		_lbl_gol_marcador.text = "%d - %d" % [partido.goles_local, partido.goles_visita]
	if _fondo_gol != null:
		## Verde si anota la casa, rojo si la sufre. Es el mismo criterio que ya
		## usa el cartel 2D de `estadio.gd`, para que la pantalla y el HUD no se
		## contradigan en el mismo instante.
		_fondo_gol.color = Color(0.08, 0.42, 0.24) if de_casa else Color(0.40, 0.10, 0.12)
	_gol_restante = SEG_GOL
	mostrar(Pagina.GOL)
	## Y el marcador de debajo, ya: quien mire la pantalla justo cuando se
	## apaga el "¡GOOOL!" tiene que ver el resultado nuevo, no el de antes.
	refrescar()

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

## Los últimos seis, de más nuevo a más viejo: en un 5-4 no caben los nueve y
## lo que importa es lo que acaba de pasar.
func _repintar_goles() -> void:
	if _caja_goles == null:
		return
	for h in _caja_goles.get_children():
		h.queue_free()
	var desde: int = maxi(0, _goles.size() - 6)
	for i in range(_goles.size() - 1, desde - 1, -1):
		var g: Dictionary = _goles[i]
		var fila := HBoxContainer.new()
		fila.custom_minimum_size = Vector2(0, 52)
		fila.add_theme_constant_override("separation", 18)
		var min_l := _etiqueta("%d'" % int(g["min"]), 32, COL_AMBAR, HORIZONTAL_ALIGNMENT_RIGHT)
		min_l.custom_minimum_size = Vector2(80, 48)
		fila.add_child(min_l)
		var nom := _etiqueta(String(g["autor"]).to_upper(), 32,
			COL_TINTA if bool(g["casa"]) else COL_SUAVE)
		nom.custom_minimum_size = Vector2(540, 48)
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(nom)
		var eq := _etiqueta(String(g["abrev"]), 30,
			_color_casa() if bool(g["casa"]) else COL_SUAVE, HORIZONTAL_ALIGNMENT_RIGHT)
		eq.custom_minimum_size = Vector2(110, 48)
		fila.add_child(eq)
		_caja_goles.add_child(fila)

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

## LOS CRUCES DE LA RONDA (26-9-2026): en una copa no hay tabla, y enseñar la
## de la liga en un partido de copa era mentirle al estadio. Hasta seis cruces;
## el de los dos que están jugando, resaltado.
func _panel_cruces() -> Control:
	var filas: Array = datos.get("cruces", [])
	if filas.is_empty():
		return null
	var c := _base("CRUCES  ·  " + String(datos.get("liga", "")).to_upper())
	var y := 96.0
	for i in mini(6, filas.size()):
		var par: Array = filas[i]
		var txt := "%s   vs   %s" % [String(par[0]), String(par[1])]
		var es_este := casa != null and (String(par[0]) == casa.nombre or String(par[1]) == casa.nombre)
		var fila := _fila_tabla("", txt, "", "", _color_casa() if es_este else COL_TINTA, 28)
		fila.position = Vector2(48, y)
		fila.size = Vector2(ANCHO - 96, 44)
		c.add_child(fila)
		y += 52.0
	_pie(c)
	return c

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

func _panel_gol() -> Control:
	if partido == null:
		return null
	var c := _base("")
	_fondo_gol = ColorRect.new()
	_fondo_gol.color = Color(0.08, 0.42, 0.24)
	_fondo_gol.position = Vector2(0, 12)
	_fondo_gol.size = Vector2(ANCHO, ALTO - 12)
	c.add_child(_fondo_gol)
	var g := _etiqueta("¡GOOOL!", 116, Color(1, 1, 1), HORIZONTAL_ALIGNMENT_CENTER)
	g.position = Vector2(0, 60)
	g.size = Vector2(ANCHO, 140)
	c.add_child(g)
	_lbl_gol_autor = _etiqueta("", 52, COL_AMBAR, HORIZONTAL_ALIGNMENT_CENTER)
	_lbl_gol_autor.position = Vector2(48, 212)
	_lbl_gol_autor.size = Vector2(ANCHO - 96, 66)
	c.add_child(_lbl_gol_autor)
	_lbl_gol_min = _etiqueta("", 28, Color(1, 1, 1, 0.82), HORIZONTAL_ALIGNMENT_CENTER)
	_lbl_gol_min.position = Vector2(48, 288)
	_lbl_gol_min.size = Vector2(ANCHO - 96, 40)
	c.add_child(_lbl_gol_min)
	_lbl_gol_marcador = _etiqueta("0 - 0", 72, Color(1, 1, 1), HORIZONTAL_ALIGNMENT_CENTER)
	_lbl_gol_marcador.position = Vector2(48, 344)
	_lbl_gol_marcador.size = Vector2(ANCHO - 96, 96)
	c.add_child(_lbl_gol_marcador)
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
