class_name HistoriaClub
extends RefCounted
## LA HISTORIA DE CADA CLUB (26-9-2026, plan maestro C4). Pedido: *"historia
## real de los clubes"*: fundación, estadio, apodo, rival, títulos y alguna
## anécdota.
##
## CON GUIÑO (pedido del usuario, 26-9): cada club del juego refleja a uno
## real, y su historia tiene que dejarlo reconocer. `HISTORIA_CLUBES` (escrita
## por `herramientas/historia_clubes.py`) trae para los 384 clubes su año de
## fundación, su apodo, el apodo de su estadio y una línea de historia; en la
## base ficticia va con los nombres inventados y en el pack real con los
## reales. `CLASICOS` da nombre a los partidos grandes: Superclásico, Clásico
## Universitario, Gran Derbi...
## Lo que no esté en la tabla (años de clubes chicos, por ejemplo) se GENERA,
## coherente con el club: los grandes son más antiguos y tienen más títulos, el
## apodo sale de sus colores y el rival es el club más parecido de su país.
## Los títulos solo se inventan con la base ficticia: con el pack real un
## número inventado confundiría.
## Todo por hash: el mismo club tiene siempre la misma historia, sin `Azar`.

const APODO_COLOR := {
	"blanco": ["los Albos", "los Merengues", "los Blancos"],
	"azul": ["los Azules", "la Azul", "los Azulgranas"],
	"rojo": ["los Rojos", "los Diablos Rojos", "el Rojo"],
	"verde": ["los Verdes", "los Albiverdes", "los Esmeraldas"],
	"amarillo": ["los Canarios", "los Aurinegros", "los Amarillos"],
	"celeste": ["los Celestes", "los Cielo", "la Celeste"],
	"negro": ["los Negros", "los Albinegros", "los Cuervos"],
	"granate": ["los Granates", "los Guindas", "el Granate"],
	"naranja": ["los Naranjas", "los Mineros", "la Naranja Mecánica"],
	"violeta": ["los Violetas", "los Lilas", "el Violeta"],
}
const APODO_EXTRA := ["la Academia", "el Ciclón", "los Guerreros", "el Expreso", "los Leones",
	"los Halcones", "el Tanque", "los Piratas", "la Máquina", "los Toros"]
const ORIGEN := [
	"Lo fundaron trabajadores del ferrocarril en un galpón de la estación.",
	"Nació de un grupo de estudiantes que jugaba en el patio del liceo.",
	"Lo fundaron inmigrantes que llegaron al puerto y querían su propio club.",
	"Surgió en un campamento minero, con camisetas cosidas a mano.",
	"Se fundó en la trastienda de un almacén de barrio, entre amigos.",
	"Nació como sección de fútbol de un club de remo.",
	"Lo fundaron obreros de una fábrica textil para el tiempo libre.",
	"Surgió de la fusión de dos clubes de barrio que no podían solos.",
]
const EPOCA := ["los años 50", "los años 60", "los años 70", "los años 80", "los años 90", "la década de 2000", "la década de 2010"]

static func _h(t: String) -> int:
	return absi(t.hash())

## El color más parecido de la paleta de apodos.
static func color_de(hexa: String) -> String:
	var c := Color(hexa) if hexa.begins_with("#") else Color.WHITE
	if c.s < 0.18:
		return "blanco" if c.v > 0.6 else "negro"
	var h := c.h * 360.0
	if h < 15.0 or h >= 345.0:
		return "granate" if c.v < 0.55 else "rojo"
	if h < 40.0:
		return "naranja"
	if h < 70.0:
		return "amarillo"
	if h < 170.0:
		return "verde"
	if h < 205.0:
		return "celeste"
	if h < 255.0:
		return "azul" if c.v < 0.8 or c.s > 0.5 else "celeste"
	if h < 320.0:
		return "violeta"
	return "rojo"

## La historia de un club. `rivales` son los clubes de su país (para elegir el
## rival histórico).
static func de(c: Club, rivales: Array) -> Dictionary:
	if c == null:
		return {}
	var h := _h("hist|" + c.id + "|" + c.nombre)
	var rep := float(c.rep)
	## Los grandes son más antiguos: un club de reputación 90 nació hacia 1900.
	var fundado := clampi(int(2010.0 - (rep - 40.0) * 2.2) - h % 25, 1885, 2005)
	var col := color_de(c.color1)
	var apodos: Array = APODO_COLOR.get(col, APODO_EXTRA)
	var apodo: String = apodos[(h / 3) % apodos.size()] if (h / 7) % 4 != 0 else APODO_EXTRA[(h / 11) % APODO_EXTRA.size()]
	## El rival: el club del país con la reputación más parecida (los grandes
	## se miran entre ellos), desempatando por hash.
	var rival := ""
	var mejor := 999.0
	for o: Variant in rivales:
		var oc := o as Club
		if oc == null or oc.id == c.id:
			continue
		var d := absf(float(oc.rep) - rep) + float(_h(c.id + oc.id) % 7) * 0.3
		if d < mejor:
			mejor = d
			rival = oc.nombre
	var titulos := maxi(0, int(pow(maxf(rep - 68.0, 0.0), 1.45) / 3.2) + (h / 13) % 3 - 1)
	var copas := maxi(0, int(float(titulos) * 0.6) + (h / 17) % 2)
	var r := {
		"fundado": fundado,
		"apodo": apodo,
		"estadio": c.estadio_nombre if c.estadio_nombre != "" else nombre_estadio(c),
		"rival": rival,
		"titulos": titulos,
		"copas": copas,
		"origen": ORIGEN[(h / 19) % ORIGEN.size()],
		"epoca": ("Su época dorada fue en %s." % EPOCA[(h / 23) % EPOCA.size()]) if titulos > 2 else "Todavía espera su gran época.",
		"guino": "",
		"clasicos": clasicos_de(c.nombre),
		"con_guino": false,
	}
	## EL GUIÑO (pedido del usuario, 26-9): cada club del juego refleja a uno
	## real, y su historia tiene que hacerlo reconocible -"al estadio del Colo
	## se le llama la Ruca"-. `HISTORIA_CLUBES` trae fundación, apodo, apodo
	## del estadio y una línea de historia; lo que falte queda generado.
	var g := dato(c.nombre)
	if not g.is_empty():
		for k: String in ["fundado", "apodo", "estadio", "guino"]:
			if g.has(k):
				r[k] = g[k]
		r["con_guino"] = true
	## El rival histórico es el del clásico con nombre, si lo hay.
	if not (r["clasicos"] as Array).is_empty():
		r["rival"] = String((r["clasicos"] as Array)[0]["rival"])
	return r

## Sin nombre de estadio guardado, uno que suene a ese club: "Estadio
## Lautaro", "Estadio Precordillera"... (sin las siglas FC, U., SC...).
static func nombre_estadio(c: Club) -> String:
	for w: String in Nombres.limpiar(c.nombre).split(" ", false):
		if w.length() >= 4 and not w.ends_with(".") and w.to_upper() != w:
			return "Estadio " + w
	return "Estadio Municipal"

## La fila de `HISTORIA_CLUBES` de un club (por nombre normalizado: vale
## igual con la base ficticia que con el pack real, cada uno trae la suya).
static var _indice: Dictionary = {}
static var _indice_de: Variant = null

static func dato(nombre: String) -> Dictionary:
	if not Datos.tiene("HISTORIA_CLUBES"):
		return {}
	var t: Variant = Datos.tabla("HISTORIA_CLUBES")
	if not (t is Dictionary):
		return {}
	## Índice por nombre normalizado; se rehace si cambia la tabla (base/pack).
	if not is_same(_indice_de, t):
		_indice = {}
		for k: String in (t as Dictionary):
			_indice[Mundo._norm_nombre(k)] = (t as Dictionary)[k]
		_indice_de = t
	return _indice.get(Mundo._norm_nombre(nombre), {})

## Índice de clásicos: nombre normalizado -> [{rival, nombre}]. Se rehace si
## cambia la tabla (base/pack). `es_clasico()` corre muchas veces por semana:
## normalizar 132 nombres en cada llamada era demasiado.
static var _clasicos: Dictionary = {}
static var _clasicos_de_tabla: Variant = null

static func _indice_clasicos() -> Dictionary:
	if not Datos.tiene("CLASICOS"):
		return {}
	var t: Variant = Datos.tabla("CLASICOS")
	if is_same(_clasicos_de_tabla, t):
		return _clasicos
	_clasicos = {}
	for f: Variant in t:
		var a := Mundo._norm_nombre(String(f[0]))
		var b := Mundo._norm_nombre(String(f[1]))
		if not _clasicos.has(a):
			_clasicos[a] = []
		if not _clasicos.has(b):
			_clasicos[b] = []
		(_clasicos[a] as Array).append({"rival": String(f[1]), "rival_n": b, "nombre": String(f[2])})
		(_clasicos[b] as Array).append({"rival": String(f[0]), "rival_n": a, "nombre": String(f[2])})
	_clasicos_de_tabla = t
	return _clasicos

## Los clásicos con nombre de un club: [{rival, nombre}].
static func clasicos_de(nombre: String) -> Array:
	return _indice_clasicos().get(Mundo._norm_nombre(nombre), [])

## El nombre del partido entre dos clubes ("Superclásico"), o "".
static func nombre_clasico(a: String, b: String) -> String:
	var lista: Array = _indice_clasicos().get(Mundo._norm_nombre(a), [])
	if lista.is_empty():
		return ""
	var nb := Mundo._norm_nombre(b)
	for x: Dictionary in lista:
		if String(x["rival_n"]) == nb:
			return String(x["nombre"])
	return ""

## El texto de una línea para las fichas.
static func resumen(hi: Dictionary) -> String:
	if hi.is_empty():
		return ""
	var partes: Array[String] = ["Fundado en %d" % int(hi["fundado"]), "«%s»" % String(hi["apodo"]),
		"juega en %s" % String(hi["estadio"])]
	if not Datos.base_real:
		partes.append("%d ligas y %d copas" % [int(hi["titulos"]), int(hi["copas"])])
	return " · ".join(partes)

## Los clásicos en una línea: "Superclásico contra U. Andina · Clásico
## Universitario contra..." o, sin clásico con nombre, el rival de siempre.
static func texto_clasicos(hi: Dictionary) -> String:
	var cl: Array = hi.get("clasicos", [])
	if cl.is_empty():
		return ("Rival de siempre: %s." % Nombres.visible(String(hi["rival"]))) if String(hi.get("rival", "")) != "" else ""
	var partes: Array[String] = []
	for x: Dictionary in cl:
		partes.append("%s contra %s" % [String(x["nombre"]), Nombres.visible(String(x["rival"]))])
	return "⚔️ " + " · ".join(partes)

## La línea de historia: el guiño si lo hay; si no, el origen generado.
static func texto_historia(hi: Dictionary) -> String:
	var g := String(hi.get("guino", ""))
	return g if g != "" else String(hi.get("origen", ""))
