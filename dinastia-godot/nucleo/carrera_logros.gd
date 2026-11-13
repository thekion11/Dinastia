class_name CarreraLogros
extends RefCounted
## LOS LOGROS PROPIOS DE «LA RUTA» (13-11-2026, pedido del dueño): hitos de TU
## carrera de jugador, aparte de los logros del juego. Cada uno da experiencia
## una sola vez. Se guardan en `ruta["logros"]` (id -> semana absoluta) y los
## recién ganados esperan en `ruta["logros_nuevos"]` a que la pantalla los anuncie.

## id -> [icono, nombre, cómo se gana, experiencia]
const LOGROS := {
	"debut": ["👟", "El debut", "Juega tu primer partido como profesional.", 30],
	"primer_gol": ["⚽", "El primero", "Marca tu primer gol.", 40],
	"doblete": ["✌", "Doblete", "Marca dos goles en un partido.", 50],
	"triplete": ["🎩", "Triplete", "Marca tres goles en un partido.", 90],
	"un_diez": ["🔟", "Un diez", "Termina un partido con nota 9 o más.", 70],
	"racha": ["🔥", "En racha", "Encadena 5 partidos con nota 7 o más.", 70],
	"socio": ["🎯", "Socio de todos", "Da 10 asistencias en tu carrera.", 60],
	"goleador": ["🥅", "Medio centenar", "Marca 50 goles en tu carrera.", 120],
	"centenario": ["💯", "Centenario", "Juega 100 partidos como profesional.", 120],
	"toque_fino": ["🎼", "Toque fino", "Clava 5 toques perfectos en el entreno.", 50],
	"duelo": ["🥊", "El mejor de los dos", "Gana un duelo de temporada a tu rival.", 60],
	"remontada": ["↩", "Le diste la vuelta", "Gana un duelo que perdías a mitad de temporada.", 80],
	"brazalete": ["©", "El brazalete", "Sé capitán de tu equipo.", 80],
	"rama": ["🌳", "Rama completa", "Aprende los tres talentos de una rama.", 80],
	"los_tuyos": ["🏡", "Los tuyos primero", "Compra una casa para tu familia.", 50],
	"internacional": ["🌎", "Internacional", "Juega un partido con tu selección.", 80],
	"cien_mil": ["📱", "Cien mil", "Llega a 100.000 seguidores.", 80],
	"idolo": ["⭐", "Ídolo de la grada", "Llega a 80 de fama.", 100],
}

static func _cuenta(c: CarreraJugador) -> Dictionary:
	var r := CarreraRuta.asegurar(c)
	if not r.get("cuenta") is Dictionary:
		r["cuenta"] = {}
	return r["cuenta"]

static func ganados(c: CarreraJugador) -> Dictionary:
	var r := CarreraRuta.asegurar(c)
	if not r.get("logros") is Dictionary:
		r["logros"] = {}
	return r["logros"]

static func tiene(c: CarreraJugador, id: String) -> bool:
	return ganados(c).has(id)

## Suma uno a un contador de carrera (goles, asistencias, toques perfectos, remontadas).
static func sumar(c: CarreraJugador, que: String, cuanto := 1) -> void:
	var k := _cuenta(c)
	k[que] = int(k.get(que, 0)) + cuanto

## Tras cada partido tuyo: apunta lo del partido y revisa.
static func tras_partido(c: CarreraJugador, m: Mundo, d: Dictionary) -> Array:
	if int(d.get("minutos", 90)) <= 0:
		return []
	var goles := int(d.get("goles", 0))
	sumar(c, "goles", goles)
	sumar(c, "asist", int(d.get("asist", 0)))
	var k := _cuenta(c)
	k["mejor_goles"] = maxi(int(k.get("mejor_goles", 0)), goles)
	k["mejor_nota"] = maxf(float(k.get("mejor_nota", 0.0)), float(d.get("nota", 6.0)))
	return revisar(c, m)

## Mira todo lo que se puede haber cumplido. Devuelve los ids recién ganados.
static func revisar(c: CarreraJugador, _m: Mundo) -> Array:
	var r := CarreraRuta.asegurar(c)
	var k := _cuenta(c)
	## El toque perfecto de la semana cuenta una vez.
	if float(r["toque"]) >= 0.85 and int(r["toque_semana"]) != int(k.get("toque_visto", -1)):
		k["toque_visto"] = int(r["toque_semana"])
		sumar(c, "perfectos")
	var cumple := {
		"debut": c.pj_carrera >= 1, "centenario": c.pj_carrera >= 100,
		"primer_gol": int(k.get("goles", 0)) >= 1, "goleador": int(k.get("goles", 0)) >= 50,
		"doblete": int(k.get("mejor_goles", 0)) >= 2, "triplete": int(k.get("mejor_goles", 0)) >= 3,
		"un_diez": float(k.get("mejor_nota", 0.0)) >= 9.0, "racha": int(r["mejor_racha"]) >= 5,
		"socio": int(k.get("asist", 0)) >= 10, "toque_fino": int(k.get("perfectos", 0)) >= 5,
		"duelo": int(r["duelos_ganados"]) >= 1, "remontada": int(k.get("remontadas", 0)) >= 1,
		"brazalete": c.capitan, "rama": _rama_completa(c), "los_tuyos": CarreraVida.tiene(c, "casa"),
		"internacional": c.caps >= 1, "cien_mil": c.seguidores >= 100000, "idolo": c.fama >= 80,
	}
	var nuevos: Array = []
	for id: String in LOGROS:
		if bool(cumple.get(id, false)) and not tiene(c, id):
			ganados(c)[id] = int(r.get("ultimo", {}).get("semana", 0))
			CarreraRuta.sumar_xp(c, int(LOGROS[id][3]))
			nuevos.append(id)
	if not nuevos.is_empty():
		if not r.get("logros_nuevos") is Array:
			r["logros_nuevos"] = []
		(r["logros_nuevos"] as Array).append_array(nuevos)
	return nuevos

static func _rama_completa(c: CarreraJugador) -> bool:
	var por_rama := {}
	for id: String in CarreraRuta.TALENTOS:
		var rama := String(CarreraRuta.TALENTOS[id][0])
		por_rama[rama] = bool(por_rama.get(rama, true)) and CarreraRuta.tiene(c, id)
	return por_rama.values().has(true)

## Los que la pantalla aún no anunció; al pedirlos se dan por anunciados.
static func tomar_nuevos(c: CarreraJugador) -> Array:
	var r := CarreraRuta.asegurar(c)
	var lista: Array = r.get("logros_nuevos", []) if r.get("logros_nuevos") is Array else []
	r["logros_nuevos"] = []
	return lista
