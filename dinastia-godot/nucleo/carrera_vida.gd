class_name CarreraVida
extends RefCounted
## «TU VIDA» EN «LA RUTA» (13-11-2026): tu sueldo se ahorra semana a semana y
## se gasta fuera del campo en cosas que cambian tu carrera de verdad. Cada
## compra es para siempre y cuesta un número de semanas de tu sueldo de hoy.
## Estado: `ruta["ahorros"]` y `ruta["vida"]` = {id: true}.

## id -> [icono, nombre, qué hace, semanas de sueldo que cuesta]
const COSAS := {
	"gimnasio": ["🏋️", "Gimnasio en casa", "Entrenar te cuesta 4 de energía menos.", 8],
	"community": ["📱", "Alguien que lleve tus redes", "Ganas seguidores cada semana, más cuanta más fama tengas.", 10],
	"fisio": ["💆", "Fisio personal", "Recuperas 6 de energía más cada semana.", 14],
	"coche": ["🏎️", "Un deportivo", "+2.000 seguidores y +2 de fama. Al DT no le hace gracia (−3 de relación).", 16],
	"analista": ["🎥", "Analista de vídeo", "Cada partido te da un 10 % más de experiencia.", 20],
	"casa": ["🏡", "Una casa para tu familia", "Tu ánimo no baja de 60 y ganas +2 de fama.", 30],
	"academia": ["🏟️", "Una escuela de fútbol en tu barrio", "+3 de fama y un punto de talento. Tu nombre queda en la puerta.", 52],
}

static func _vida(c: CarreraJugador) -> Dictionary:
	var r := CarreraRuta.asegurar(c)
	if not r.get("vida") is Dictionary:
		r["vida"] = {}
	return r["vida"]

static func ahorros(c: CarreraJugador) -> int:
	var v: Variant = CarreraRuta.asegurar(c).get("ahorros", 0)
	return int(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] else 0

static func tiene(c: CarreraJugador, id: String) -> bool:
	return _vida(c).has(id)

static func precio(c: CarreraJugador, m: Mundo, id: String) -> int:
	var j := c.jugador(m)
	return int(COSAS[id][3]) * maxi(1, j.sueldo if j != null else 1)

static func puede_comprar(c: CarreraJugador, m: Mundo, id: String) -> bool:
	return COSAS.has(id) and not tiene(c, id) and ahorros(c) >= precio(c, m, id)

static func comprar(c: CarreraJugador, m: Mundo, id: String) -> bool:
	if not puede_comprar(c, m, id):
		return false
	var r := CarreraRuta.asegurar(c)
	r["ahorros"] = ahorros(c) - precio(c, m, id)
	_vida(c)[id] = true
	var j := c.jugador(m)
	match id:
		"coche":
			c.seguidores += 2000
			c.fama = mini(100, c.fama + 2)
			c.relacion_dt = maxi(0, c.relacion_dt - 3)
		"casa":
			c.fama = mini(100, c.fama + 2)
			if j != null and j.moral < 60:
				j.moral = 60
		"academia":
			c.fama = mini(100, c.fama + 3)
			r["puntos"] = int(r["puntos"]) + 1
	## Lo comprado no pasa por el freno semanal de la fama.
	r["fama_ref"] = c.fama
	CarreraRuta._grada(c, String(COSAS[id][0]), "Novedad fuera del campo: %s.", [Idiomas.t(String(COSAS[id][1])).to_lower()])
	return true

## Cada semana: cobras el sueldo y rinde lo que compraste.
static func semana(c: CarreraJugador, m: Mundo) -> void:
	var r := CarreraRuta.asegurar(c)
	var j := c.jugador(m)
	if j == null:
		return
	r["ahorros"] = ahorros(c) + maxi(0, j.sueldo)
	if tiene(c, "fisio"):
		c.energia = mini(CarreraJugador.ENERGIA_MAX, c.energia + 6)
	if tiene(c, "community"):
		c.seguidores += 30 + c.fama * 2
	if tiene(c, "casa") and j.moral < 60:
		j.moral = 60

## Lo que devuelve el gimnasio tras entrenar.
static func tras_entreno(c: CarreraJugador) -> void:
	if tiene(c, "gimnasio"):
		c.energia = mini(CarreraJugador.ENERGIA_MAX, c.energia + 4)

## El multiplicador de experiencia de partido (analista de vídeo).
static func factor_xp(c: CarreraJugador) -> float:
	return 1.1 if tiene(c, "analista") else 1.0
