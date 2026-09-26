class_name HistoriaClub
extends RefCounted
## LA HISTORIA DE CADA CLUB (26-9-2026, plan maestro C4). Pedido: *"historia
## real de los clubes"*: fundación, estadio, apodo, rival, títulos y alguna
## anécdota.
##
## MISMA REGLA LEGAL QUE LOS NOMBRES:
##   - con la base ficticia (la que se publica), la historia se GENERA, coherente
##     con el club: los grandes son más antiguos y tienen más títulos, el apodo
##     sale de sus colores y el rival es el grande más parecido de su país;
##   - con el pack real instalado (`HISTORIA_REAL`, solo en `pack_real.json`, que
##     no va en las versiones publicadas), los datos que haya -fundación, apodo,
##     estadio, rival- son los reales y pisan a los generados.
## Los títulos históricos del pack NO se ponen: cambian cada año y un número
## viejo es peor que uno inventado a la vista.
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
		"real": false,
	}
	## Lo real, si el pack está instalado.
	var real := dato_real(c.nombre)
	if not real.is_empty():
		for k: String in ["fundado", "apodo", "estadio", "rival", "origen"]:
			if real.has(k):
				r[k] = real[k]
		r["real"] = true
	return r

## Sin nombre de estadio guardado, uno que suene a ese club: "Estadio
## Lautaro", "Estadio Precordillera"... (sin las siglas FC, U., SC...).
static func nombre_estadio(c: Club) -> String:
	for w: String in Nombres.limpiar(c.nombre).split(" ", false):
		if w.length() >= 4 and not w.ends_with(".") and w.to_upper() != w:
			return "Estadio " + w
	return "Estadio Municipal"

static func dato_real(nombre: String) -> Dictionary:
	if not Datos.tiene("HISTORIA_REAL"):
		return {}
	var t: Variant = Datos.tabla("HISTORIA_REAL")
	if not (t is Dictionary):
		return {}
	var clave := Mundo._norm_nombre(nombre)
	for k: String in (t as Dictionary):
		if Mundo._norm_nombre(k) == clave:
			return (t as Dictionary)[k]
	return {}

## El texto de una línea para las fichas.
static func resumen(hi: Dictionary) -> String:
	if hi.is_empty():
		return ""
	var partes: Array[String] = ["Fundado en %d" % int(hi["fundado"]), "«%s»" % String(hi["apodo"]), String(hi["estadio"])]
	if String(hi["rival"]) != "":
		partes.append("rival: %s" % Nombres.visible(String(hi["rival"])))
	if not bool(hi.get("real", false)):
		partes.append("%d ligas y %d copas" % [int(hi["titulos"]), int(hi["copas"])])
	return " · ".join(partes)
