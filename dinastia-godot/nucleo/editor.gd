class_name Editor
extends RefCounted
## EL EDITOR: renombrar, repintar y reconstruir el mundo entero.
##
## `vEditor()` del HTML. Es la única pantalla del juego que no juega: cambia los
## DATOS. Clubes, escudos, plantillas, atributos, caras y posiciones.
##
## POR QUÉ EXISTE. El mundo se genera solo y los nombres van censurados letra a
## número para no usar los reales. Quien quiera su liga de verdad —con los
## nombres bien escritos y las plantillas que él conoce— tiene que poder
## escribirla, y a mano son cuatrocientos clubes. Por eso hay importador de CSV.
##
## LO QUE NO HACE. No crea clubes ni ligas nuevas: mueve lo que ya existe. Un
## mundo con más equipos de los que la liga admite deja calendarios imposibles,
## y eso no se arregla en una pantalla de edición.

signal cambiado(que: String)

## Cuántas filas de un mismo club hacen falta para REEMPLAZAR su plantilla en
## vez de añadir. Quince: por debajo de eso es un refuerzo, no una plantilla.
const FILAS_PARA_REEMPLAZAR := 15

var _ref: WeakRef

func _init(mundo: Mundo) -> void:
	_ref = weakref(mundo)

func _mundo() -> Mundo:
	return _ref.get_ref() as Mundo if _ref != null else null

# ---------------------------------------------------------------------------
#  CLUBES
# ---------------------------------------------------------------------------

func renombrar_club(c: Club, nuevo: String) -> String:
	var limpio := nuevo.strip_edges()
	if limpio.length() < 2:
		return "el nombre tiene que tener al menos dos letras"
	c.nombre = limpio.substr(0, 40)
	Escudo.limpiar_cache()
	cambiado.emit("club")
	return ""

func mover_reputacion(c: Club, d: int) -> void:
	c.rep = clampi(c.rep + d, 30, 95)
	cambiado.emit("club")

func mover_aforo(c: Club, d: int) -> void:
	c.estadio_aforo = maxi(2000, c.estadio_aforo + d)
	cambiado.emit("club")

## Rehace la plantilla entera de un club. Es destructivo y por eso la pantalla
## lo pide dos veces: los jugadores viejos dejan de existir, con su historia.
func regenerar_plantel(c: Club) -> String:
	var m := _mundo()
	if m == null:
		return "no hay mundo"
	if c.id == m.mi_club_id:
		return "no se regenera el plantel del club que diriges: perderías tu propia plantilla"
	c.plantilla.clear()
	m._poblar(c)
	cambiado.emit("plantel")
	return ""

# ---------------------------------------------------------------------------
#  JUGADORES
# ---------------------------------------------------------------------------

## Los atributos se mueven de tres en tres y la media se recalcula sola: editar
## un atributo y que la media no se entere sería mentir en la misma pantalla.
func mover_atributo(j: Jugador, clave: String, d: int) -> void:
	if not j.atributos.has(clave):
		return
	j.atributos[clave] = clampi(int(j.atributos[clave]) + d, 20, 99)
	j.ovr = j.media_en(j.pos_e)
	j.tasar()
	cambiado.emit("jugador")

func fijar_campo(j: Jugador, campo: String, valor: Variant) -> String:
	match campo:
		"nombre":
			var n := String(valor).strip_edges()
			if n.length() < 2:
				return "el nombre tiene que tener al menos dos letras"
			j.nombre = n.substr(0, 40)
		"ovr":
			j.ovr = clampi(int(valor), 20, 99)
			j.pot = maxi(j.pot, j.ovr)
			j.generar_atributos()
			_cuadrar_media(j)
		"pot":
			j.pot = clampi(int(valor), j.ovr, 99)
		"edad":
			j.edad = clampi(int(valor), 15, 45)
		"dorsal":
			j.dorsal = clampi(int(valor), 1, 99)
		"pais":
			j.pais = String(valor)
		"rasgo":
			j.rasgo = String(valor)
		"pos_e":
			j.pos_e = String(valor)
			j.pos = grupo_de(String(valor))
			## Cambiar de puesto rehace los atributos: un central con los
			## atributos de un extremo es un jugador que no existe.
			j.generar_atributos()
			_cuadrar_media(j)
		_:
			return "«%s» no es un campo editable" % campo
	j.tasar()
	cambiado.emit("jugador")
	return ""

## AJUSTA LOS ATRIBUTOS HASTA QUE LA MEDIA SEA LA QUE SE PIDIO.
##
## `generar_atributos()` reparte alrededor de la media, pero `media_en()` los
## vuelve a pesar segun el puesto y el resultado no cae exactamente donde se
## puso: escribir 91 y ver 89 al tocar el primer atributo es la clase de cosa
## que hace desconfiar de una pantalla entera. Se corrige repartiendo la
## diferencia entre todos los atributos; converge en dos o tres vueltas porque
## la media es un promedio ponderado.
func _cuadrar_media(j: Jugador) -> void:
	var objetivo := j.ovr
	for intento in 6:
		var actual := j.media_en(j.pos_e)
		var dif := objetivo - actual
		if dif == 0:
			break
		var cambio := false
		for k: String in j.atributos:
			var antes := int(j.atributos[k])
			var despues := clampi(antes + signi(dif) * maxi(1, absi(dif)), 20, 99)
			if despues != antes:
				j.atributos[k] = despues
				cambio = true
		if not cambio:
			break
	j.ovr = j.media_en(j.pos_e)

func fijar_look(j: Jugador, clave: String, valor: Variant) -> void:
	j.look[clave] = valor
	Cara.limpiar_cache()
	cambiado.emit("jugador")

## "🎲 Aleatorio" del HTML: un aspecto entero nuevo de una sola vez.
func aleatorizar_look(j: Jugador) -> void:
	j.look = Cara.look_aleatorio()
	Cara.limpiar_cache()
	cambiado.emit("jugador")

## El grupo al que pertenece una demarcación. Sale de la tabla `POSD`, que ya
## venía exportada: escribirlo a mano aquí sería una segunda fuente de verdad.
static func grupo_de(demarcacion: String) -> String:
	var t: Variant = Datos.tabla("POSD")
	if t is Dictionary and (t as Dictionary).has(demarcacion):
		var d: Variant = (t as Dictionary)[demarcacion]
		if d is Dictionary:
			return String((d as Dictionary).get("g", "MED"))
		if d is Array and (d as Array).size() > 0:
			return String((d as Array)[0])
	return "MED"

static func demarcaciones() -> Array:
	var t: Variant = Datos.tabla("POSD")
	if t is Dictionary:
		return (t as Dictionary).keys()
	return ["POR", "DFC", "LAT", "MC", "MCO", "ED", "DC"]

# ---------------------------------------------------------------------------
#  IMPORTAR UNA BASE EN CSV
# ---------------------------------------------------------------------------
#
#     Club;Nombre;POS;Edad;Media[;País;Potencial;Pie;Habilidades]
#
# Es el formato del HTML sin tocar, porque quien tenga una base hecha para el
# HTML tiene que poder pegarla aquí tal cual. El separador es `;` y no `,`
# porque los nombres de club llevan comas.
#
# LA CENSURA LETRA→NÚMERO se aplica al importar si está encendida, igual que en
# el HTML: los nombres que entran son reales y el juego no los usa tal cual.

## El resultado de importar: cuántas filas, cuántos clubes tocados y qué falló.
func importar_csv(texto: String, censurar: bool) -> Dictionary:
	var m := _mundo()
	if m == null:
		return {"error": "no hay mundo"}
	var por_club := {}
	var problemas: Array[String] = []
	var filas := 0
	for linea_bruta: String in texto.split("\n"):
		var linea := linea_bruta.strip_edges()
		if linea == "" or linea.begins_with("#"):
			continue
		var partes := linea.split(";")
		if partes.size() < 5:
			problemas.append("«%s»: faltan columnas" % linea.substr(0, 40))
			continue
		var club := _buscar_club(String(partes[0]).strip_edges())
		if club == null:
			problemas.append("«%s»: no existe ese club" % String(partes[0]).strip_edges())
			continue
		if not por_club.has(club.id):
			por_club[club.id] = []
		(por_club[club.id] as Array).append({
			"nombre": String(partes[1]).strip_edges(),
			"pos": String(partes[2]).strip_edges().to_upper(),
			"edad": int(String(partes[3])),
			"ovr": int(String(partes[4])),
			"pais": String(partes[5]).strip_edges() if partes.size() > 5 else club.pais,
			"pot": int(String(partes[6])) if partes.size() > 6 else 0,
			"pie": String(partes[7]).strip_edges().to_upper() if partes.size() > 7 else "D",
		})
		filas += 1

	var clubes_tocados := 0
	for cid: String in por_club:
		var c: Club = m.clubes[cid]
		var lista: Array = por_club[cid]
		## QUINCE FILAS O MÁS REEMPLAZAN. Por debajo se añaden al plantel, que es
		## lo que se espera si pegas cuatro fichajes y no una plantilla entera.
		if lista.size() >= FILAS_PARA_REEMPLAZAR:
			c.plantilla.clear()
		for f: Dictionary in lista:
			var demarcacion := String(f["pos"])
			var grupo := demarcacion
			if demarcaciones().has(demarcacion):
				grupo = grupo_de(demarcacion)
			else:
				grupo = demarcacion if demarcacion in ["POR", "DEF", "MED", "DEL"] else "MED"
				demarcacion = m.cantera.demarcacion_de(grupo) if m.cantera != null else "MC"
			var j := m.crear_jugador(c, grupo, demarcacion, int(f["edad"]), int(f["ovr"]))
			j.nombre = Nombres.censurar(String(f["nombre"])) if censurar else String(f["nombre"])
			j.pais = String(f["pais"])
			if int(f["pot"]) > 0:
				j.pot = clampi(int(f["pot"]), j.ovr, 99)
			j.real = true
			j.generar_atributos()
			j.tasar()
			c.plantilla.append(j)
		clubes_tocados += 1
		m._repartir_dorsales(c)
	cambiado.emit("plantel")
	return {"filas": filas, "clubes": clubes_tocados, "problemas": problemas}

# ---------------------------------------------------------------------------
#  EXPORTAR LA BASE EN CSV
# ---------------------------------------------------------------------------
#
# `exportarCSV(todo)` del HTML. Mismas columnas que acepta `importar_csv()`,
# para que lo que sale de aquí se pueda volver a pegar tal cual -o pasárselo a
# otra partida-. Trae el pie hábil -`j.pie()`, que ya existía, calculado de un
# hash de su id, no guardado- de regalo, aunque el importador no lo lea de
# vuelta: no hay campo que pisar con él, así que esa columna solo informa.
# SIN habilidades: ese campo vive en `Entrenamiento`, no en `Jugador`, y esta
# función solo recorre plantillas -no tiene ahí el `Entrenamiento` de cada
# club para leerlas-. `importar_csv()` ya acepta menos columnas de las que
# promete el formato completo, así que una base sin habilidades sigue siendo
# válida para volver a importarla.
func exportar_csv(solo_mi_liga: bool) -> String:
	var m := _mundo()
	if m == null:
		return ""
	var clubes: Array = []
	if solo_mi_liga:
		var mio := m.mi_club()
		for l: Liga in m.ligas:
			if mio != null and (l.clubes as Array).has(mio):
				clubes = l.clubes
				break
	else:
		clubes = m.clubes.values()
	var lineas: Array[String] = []
	for c: Club in clubes:
		for j: Jugador in c.plantilla:
			lineas.append("%s;%s;%s;%d;%d;%s;%d;%s" % [
				c.nombre, j.nombre, j.pos_e, j.edad, j.ovr, j.pais, j.pot, j.pie()])
	return "\n".join(lineas)

## Busca un club por nombre, tolerando la censura y las mayúsculas: quien pegue
## "Colo-Colo" tiene que encontrar a "C0lo-C0lo".
func _buscar_club(nombre: String) -> Club:
	var m := _mundo()
	if m == null:
		return null
	var buscado := Nombres.limpiar(nombre).to_lower()
	for c: Club in m.clubes.values():
		if Nombres.limpiar(c.nombre).to_lower() == buscado:
			return c
	for c2: Club in m.clubes.values():
		if Nombres.limpiar(c2.nombre).to_lower().contains(buscado):
			return c2
	return null
