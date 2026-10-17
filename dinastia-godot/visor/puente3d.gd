class_name Puente3D
extends RefCounted
## Traduce los objetos del juego a lo que espera el sistema 3D.
##
## `PlayerSpawner`, `Vestidor` y compañía vienen del visor que era un programa
## aparte, y allí los datos llegaban en un JSON que exportaba el HTML: un
## diccionario por jugador, con `dorsal`, `look`, `alt`... Aquí los datos son
## objetos `Jugador` y `Club` de verdad.
##
## En vez de reescribir 700 líneas de código 3D que ya funcionan y ya están
## depuradas -el atlas de texturas, el re-teñido de equipaciones, el escalado del
## esqueleto Mixamo, las cinco trampas que costó cada cosa-, se traduce en la
## frontera. Es un adaptador, y es la pieza más barata de mantener del proyecto:
## si mañana cambia el modelo de jugador, se toca aquí y solo aquí.

## Alturas por demarcación, en metros. El lateral es el más bajo de la defensa y
## el central el más alto: es lo que hace que un once no parezca una fila de
## clones. Sale del mismo criterio que ya usaba el visor.
const ALTURA := {
	"POR": 1.90, "DFC": 1.87, "LD": 1.75, "LI": 1.75, "CAD": 1.76, "CAI": 1.76,
	"MCD": 1.82, "MC": 1.78, "MCO": 1.74, "MD": 1.75, "MI": 1.75,
	"ED": 1.76, "EI": 1.76, "SD": 1.79, "DC": 1.86,
}

## Tonos de piel y de pelo. Se eligen por el id del jugador, no al azar: el mismo
## futbolista tiene siempre la misma cara, partido tras partido.
const PIELES := ["#f0c39b", "#e0ab80", "#d7a377", "#b97f4f", "#8a5a34", "#6b4529"]
const PELOS := ["#231a14", "#3d2a19", "#6b4a2a", "#c8a05a", "#1a1a1a", "#4a3a2a"]

## Un jugador, en el diccionario que espera el equipador.
static func jugador(j: Jugador) -> Dictionary:
	var h := _hash(j.id)
	return {
		"id": j.id,
		"nombre": j.nombre,
		"dorsal": j.dorsal,
		"pos": j.pos,
		"posE": j.pos_e,
		"alt": ALTURA.get(j.pos_e, 1.80),
		## EL MISMO ASPECTO QUE SU RETRATO (25-9-2026). Antes el 3D sorteaba su
		## propio pelo, piel y barba a partir del id, así que el jugador del
		## campo no se parecía al de la ficha. Ahora sale de `Cara.look_de()`,
		## que además respeta lo que el editor haya cambiado a mano.
		"look": Cara.look_de(j),
		## La cara de verdad sobre el modelo (29-9-2026): el retrato real
		## calzado, si lo tiene (solo con la base real).
		"foto": String(Cara.datos_3d(j).get("foto", "")),
		## Para la barra de energía sobre el nombre (26-9-2026).
		"fisico": j.fisico,
		"forma": j.forma,
		## Para celebrar el gol según su carácter (29-9-2026).
		"rasgo": j.rasgo,
		## PARA EL MOTOR REAL (13-10-2026): sin esto `MotorJugable` jugaba con
		## los 22 a 60 de media -no le llegaba ni la media ni un atributo- y la
		## calidad de la plantilla no influía en lo que pasaba en el césped.
		"ovr": j.ovr,
		"atributos": j.atributos.duplicate(),
		"moral": j.moral,
	}

## El once entero: los ids en orden y el diccionario que los describe. El
## equipador quiere las dos cosas por separado, porque el orden de los ids es el
## que casa con las ranuras de la formación.
static func once(jugadores: Array[Jugador]) -> Dictionary:
	var ids: Array = []
	var mapa := {}
	for j in jugadores:
		ids.append(j.id)
		mapa[j.id] = jugador(j)
	return {"xi": ids, "jugadores": mapa}

## La equipación de un club: sus dos colores de camiseta.
## HASTA HOY esto mandaba SIEMPRE `estilo:"liso"` e `img:""` -literal, sin leer
## nada del club-, así que en el 3D ningún equipo mostraba su equipación real
## ni su estampado (franjas, banda...), solo un color liso plano. `Jersey` (la
## ficha 2D, "Club → Equipación") ya resuelve las dos cosas -la equipación real
## archivada en `EQUIP_REAL` si el club tiene una, y si no el estampado
## determinista por id- desde hace tiempo; aquí solo faltaba llamarla.
## EL CHOQUE DE CAMISETAS (29-9-2026). Nadie miraba si las dos camisetas se
## parecían: con dos clubes amarillo y negro no se distinguía a nadie. Si la
## camiseta de la visita choca con la del local, se cambia: primero sus
## colores al revés, y si tampoco alcanza, blanca (o casi negra si el local va
## de claro). El diseño del club se deja (la "x" del diseñador lleva sus
## colores), así que la alternativa va lisa.
static func distancia_color(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()

static func chocan(k1: Dictionary, k2: Dictionary) -> bool:
	return distancia_color(Color(String(k1.get("c1", "#ffffff"))), Color(String(k2.get("c1", "#ffffff")))) < 0.45

static func kit_visita(local: Club, visita: Club) -> Dictionary:
	var kl := kit(local)
	var kv := kit(visita)
	if not chocan(kl, kv):
		return kv
	var invertido := {"c1": kv["c2"], "c2": kv["c1"], "estilo": String(kv.get("estilo", "liso")), "img": "", "x": {}}
	if not chocan(kl, invertido):
		return invertido
	var claro := Color(String(kl.get("c1", "#ffffff"))).get_luminance() > 0.55
	return {"c1": "#1b1f26" if claro else "#f2f2f2", "c2": String(kv["c1"]), "estilo": "liso", "img": "", "x": {}}

static func kit(c: Club) -> Dictionary:
	var estilo := Jersey.kit_de(c, c.kit_estilo)
	var img := Jersey.fichero_real(c)
	## "x": la equipación completa del diseñador (26-9-2026).
	return {"c1": c.color_kit1(), "c2": c.color_kit2(), "estilo": estilo, "img": img, "x": DisenosKit.kit_de_club(c)}

## La del portero. Tiene que CONTRASTAR con la de sus compañeros, o desde la
## cámara alta no se distingue al arquero de un defensa. Se elige el color que
## más se aleja de los dos del club.
static func kit_portero(c: Club) -> Dictionary:
	var base := Color(c.color1)
	var candidatos: Array[String] = ["#2fa06a", "#e8b820", "#c0392b", "#7d3c98", "#2c3e50"]
	var mejor: String = candidatos[0]
	var mejor_d := -1.0
	for hex: String in candidatos:
		var d: float = _distancia(Color(hex), base) + _distancia(Color(hex), Color(c.color2))
		if d > mejor_d:
			mejor_d = d
			mejor = hex
	return {"c1": mejor, "c2": "#101010", "estilo": "liso"}

## EL ÁRBITRO SE VISTE PARA QUE SE LE VEA (17-10-2026, M-072). Antes iba
## siempre de negro: contra un equipo de negro o azul marino no se distinguía
## desde la cámara alta. Como en las ligas de verdad, el trío tiene varias
## camisetas y se pone la que más contrasta con las de LOS DOS equipos (la peor
## de las dos distancias manda) y, de segundo, con los porteros. Entre las que
## quedan casi empatadas decide la semilla del partido, así que el mismo partido
## siempre sale igual y no todos los partidos con blancos y rojos son iguales.
## Devuelve {c1: camiseta, c2: ribete, pantalon, nombre}.
const PALETA_ARBITRO := [
	{"nombre": "negro", "c1": "#111216", "c2": "#e2c62a", "pantalon": "#0e0e12"},
	{"nombre": "amarillo", "c1": "#f2dc1e", "c2": "#141414", "pantalon": "#121214"},
	{"nombre": "rojo", "c1": "#c8202a", "c2": "#141414", "pantalon": "#121214"},
	{"nombre": "celeste", "c1": "#6fc3ea", "c2": "#10233a", "pantalon": "#10141c"},
	{"nombre": "lima", "c1": "#a6e22e", "c2": "#141414", "pantalon": "#121214"},
	{"nombre": "rosa", "c1": "#f06bb0", "c2": "#141414", "pantalon": "#121214"},
	{"nombre": "naranja", "c1": "#f28a1a", "c2": "#141414", "pantalon": "#121214"},
	{"nombre": "gris", "c1": "#7d838c", "c2": "#141414", "pantalon": "#121214"},
]

## Distancia «de ojo» entre dos colores: la media ponderada de rojo (redmean)
## más la diferencia de luz, que es lo que separa dos camisetas de lejos.
static func contraste_camiseta(a: Color, b: Color) -> float:
	var rm := (a.r + b.r) * 0.5
	var dr := a.r - b.r
	var dg := a.g - b.g
	var db := a.b - b.b
	var rgb := sqrt((2.0 + rm) * dr * dr + 4.0 * dg * dg + (3.0 - rm) * db * db) / 3.0
	return rgb + absf(a.get_luminance() - b.get_luminance()) * 0.8

static func kit_arbitro(kit_local: Dictionary, kit_visita: Dictionary, semilla: int, porteros: Array = []) -> Dictionary:
	var cl := Color(String(kit_local.get("c1", "#ffffff")))
	var cv := Color(String(kit_visita.get("c1", "#ffffff")))
	var notas: Array[float] = []
	var mejor := 0.0
	for k: Dictionary in PALETA_ARBITRO:
		var c := Color(String(k["c1"]))
		var nota := minf(contraste_camiseta(c, cl), contraste_camiseta(c, cv))
		for kp in porteros:
			if kp is Dictionary and (kp as Dictionary).has("c1"):
				nota = minf(nota, 0.35 + contraste_camiseta(c, Color(String(kp["c1"]))))
		## El negro es el de siempre: un poco de preferencia si contrasta igual.
		if String(k["nombre"]) == "negro":
			nota += 0.04
		notas.append(nota)
		mejor = maxf(mejor, nota)
	var validas: Array[int] = []
	for i in notas.size():
		if notas[i] >= mejor * 0.88:
			validas.append(i)
	var r := RandomNumberGenerator.new()
	r.seed = semilla
	var elegido: Dictionary = PALETA_ARBITRO[validas[r.randi() % validas.size()]]
	return elegido.duplicate()

static func _distancia(a: Color, b: Color) -> float:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)

## La formación, con sus ranuras. Sale de la tabla FORMS que exportó el HTML, así
## que las posiciones sobre el campo son exactamente las que ya estaban dibujadas
## en el pizarrón 2D.
static func formacion(nombre: String) -> Dictionary:
	var forms: Dictionary = Datos.tabla("FORMS")
	if forms == null:
		return {"s": []}
	return forms.get(nombre, forms.get("4-3-3", {"s": []}))

## djb2, el mismo que usa el resto del proyecto, para que un jugador tenga
## siempre el mismo aspecto.
static func _hash(s: String) -> int:
	var h := 5381
	for i in s.length():
		h = ((h << 5) + h + s.unicode_at(i)) & 0x7FFFFFFF
	return h
