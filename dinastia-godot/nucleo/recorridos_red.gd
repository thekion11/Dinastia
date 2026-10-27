class_name RecorridosRed
extends RefCounted
## LOS RECORRIDOS DE «RED» (27-10-2026, orden del dueño 16). Los paraderos de la ciudad son de «Red» (como Red Movilidad de
## Santiago): cada uno tiene su código «PA####» en el poste (`ParaderoRed`) y el DT lo consulta en la app «Red» del móvil para
## ver qué micros pasan, en cuántos minutos llegan y su patente. Esta es LA TABLA: el cartel y la app la leen, así dicen lo mismo.
## Reglas reales que dio el dueño:
##   · Los recorridos se numeran por SECTOR de la ciudad: sector 100 → 122, 150, 190…; sector 200 → 203, 217, 278…; y así.
##   · Sufijo «c»: el mismo recorrido en sentido contrario (122c vuelve por donde fue el 122).
##   · Sufijo «e»: una alternativa (variante expresa o de desvío). Muy rara.
##   · Además hay recorridos LOCALES tipo «C02», «C09c» (con su «c» también).
##   · Un paradero muestra de 3 a 5 recorridos (el cartel tiene sitio para seis cajitas).
## El código lleva el sector en su primera cifra (PA1xxx = sector 100, PA2xxx = sector 200…): así `recorridos(codigo)` no
## necesita saber dónde está el paradero, y un código escrito a mano en la app da lo mismo que el cartel.
## TODO ES DETERMINISTA: sale de `hash()` del código o del recorrido; no toca `Azar` ni la hora del sistema.
## EL HORARIO (no hay buses «Red» circulando de verdad: los autobuses de `TraficoCiudad` son las líneas 3, 7, 10 y 22 de la
## ciudad, con otra numeración): cada recorrido sale de cabecera cada 6-15 min según la hora del reloj del juego (más seguido
## en punta, más espaciado a última hora y el domingo), con servicio de 05:30 a 23:30 (los locales, de 06:30 a 22:00). La
## pasada por cada paradero va desfasada según el código. La patente es la del bus de la flota del recorrido que hace esa vuelta.

## Las medidas de la ciudad grande que definen las zonas (copiadas de `CiudadExpansion` y `CityBuilder.RIO_X`; la prueba
## `pruebas/ideas/red_app.gd` comprueba que siguen iguales). El núcleo es el club con sus anillos.
const NUC_X0 := -550.0
const NUC_X1 := 440.0
const NUC_Z0 := -440.0
const NUC_Z1 := 660.0
const RIO_X := -470.0
const RIO_MEDIO := 50.0
const PERIFERIA := 1100.0

## Sector → [nombre de la zona, color de sus recorridos (como las unidades de negocio de Red, cada zona su color)].
const SECTORES := {
	100: ["Estadio y club", Color(0.0, 0.47, 0.75)],
	200: ["Centro", Color(0.86, 0.36, 0.08)],
	300: ["Este", Color(0.55, 0.2, 0.6)],
	400: ["Sur", Color(0.0, 0.6, 0.35)],
	500: ["Oeste y puerto", Color(0.8, 0.13, 0.2)],
	600: ["Periferia", Color(0.15, 0.35, 0.65)],
}
const COLOR_LOCAL := Color(0.25, 0.55, 0.15)

## LA TABLA: los recorridos troncales de cada sector y los locales. Los del dueño (122, 150, 190, 203, 217, 278) están.
const TABLA := {
	100: ["101", "104", "109", "112", "122", "150", "168", "190"],
	200: ["203", "205", "210", "217", "226", "232", "278"],
	300: ["301", "303", "307", "314", "325", "341", "385"],
	400: ["401", "405", "412", "421", "426", "438", "480"],
	500: ["502", "506", "511", "516", "519", "540", "592"],
	600: ["604", "610", "614", "630", "648", "672"],
}
const LOCALES := {100: ["C01", "C02"], 200: ["C04", "C05"], 300: ["C07", "C09"], 400: ["C11", "C12"], 500: ["C14"], 600: ["C16", "C18"]}
## Por dónde se cruzan los sectores: un paradero puede tener un recorrido que viene del sector vecino.
const VECINOS := {100: [200, 300, 400, 500], 200: [100, 300, 500], 300: [100, 200, 400], 400: [100, 300, 600], 500: [100, 200, 600], 600: [400, 500]}

## Calles y plazas inventadas con sabor chileno (árboles, aves, cerros, oficios; ningún nombre de persona).
const CALLES := ["Av. Los Quillayes", "Los Aromos", "Av. El Peumo", "Las Araucarias", "Los Copihues", "Av. La Cordillera",
	"Los Litres", "El Boldo", "Las Camelias", "Av. El Salitre", "Los Maitenes", "Las Vizcachas", "Av. Las Golondrinas",
	"El Roble", "Los Canelos", "Los Alerces", "Av. La Chimba", "Las Tinajas", "El Molle", "Los Espinos", "Av. Los Andes",
	"Las Diucas", "Los Zorzales", "El Algarrobo", "Av. La Herradura", "Los Tejares", "Las Lilas", "El Coigüe", "Los Talleres",
	"Av. La Ribera", "Los Pescadores", "Las Bodegas", "El Arrayán", "Los Pimientos", "Av. Cerro Blanco", "Las Achiras"]
const DESTINOS := ["Plaza Los Aromos", "Villa El Peumo", "Estación Ribera", "Terminal La Chimba", "Población El Salitre",
	"Villa Los Copihues", "Plaza Cerro Blanco", "Puerto Viejo", "Mirador Los Andes", "Barrio Las Lilas", "Terminal El Molle",
	"Estadio", "Plaza La Herradura", "Villa Las Diucas", "Hospital del Sur", "Mercado Central"]
## Letras de patente chilena (sin vocales ni las que se confunden).
const LETRAS := "BCDFGHJKLPRSTVWXYZ"
const INICIO_SERVICIO := 330      ## 05:30
const FIN_SERVICIO := 1410        ## 23:30
const INICIO_LOCAL := 390         ## 06:30
const FIN_LOCAL := 1320           ## 22:00
const OCUPACION := ["Con asientos", "De pie", "Lleno"]

## La zona de la ciudad de un punto, como `CiudadExpansion._zona`: oeste del río, centro de torres al norte del club,
## comercio al este, casas al sur y el núcleo del club; más allá de 1.100 m, la periferia.
static func sector_de(pos: Vector3) -> int:
	if maxf(absf(pos.x), absf(pos.z)) > PERIFERIA:
		return 600
	if pos.x < RIO_X - RIO_MEDIO:
		return 500
	if pos.z < NUC_Z0 and absf(pos.x) < 700.0:
		return 200
	if pos.x > NUC_X1:
		return 300
	if pos.z > NUC_Z1:
		return 400
	return 100

static func nombre_sector(sector: int) -> String:
	return String(SECTORES.get(sector, ["?"])[0])

## «PA» + la cifra del sector + tres cifras por `semilla` (la posición del paradero).
static func codigo(semilla: int, sector: int) -> String:
	var s := clampi(sector / 100, 1, 6)
	return "PA%d%03d" % [s, absi(hash([semilla, 11])) % 1000]

## Lo que escribe el jugador («pa1234», «1234», «PA 1234») a la forma del cartel; "" si no es un código.
static func normalizar(texto: String) -> String:
	var t := texto.strip_edges().to_upper().replace(" ", "").replace("-", "")
	if not t.begins_with("PA"):
		t = "PA" + t
	var cifras := t.substr(2)
	if cifras.length() < 3 or cifras.length() > 4 or not cifras.is_valid_int():
		return ""
	return t

## El sector del código: la primera cifra si son cuatro y vale 1-6; si no (códigos viejos «PA433»), uno fijo por hash.
static func sector_del_codigo(cod: String) -> int:
	var cifras := cod.substr(2)
	if cifras.length() == 4 and int(cifras[0]) >= 1 and int(cifras[0]) <= 6:
		return int(cifras[0]) * 100
	return 100 * (1 + absi(hash([cod, "sector"])) % 6)

## Los recorridos que paran en el paradero, ordenados (troncales por número y los locales al final).
static func recorridos(cod: String) -> Array[String]:
	var sector := sector_del_codigo(cod)
	var propios: Array = TABLA[sector]
	var h := absi(hash([cod, "rec"]))
	var n := 3 + h % 3
	var bases: Array[String] = []
	if absi(hash([cod, "local"])) % 3 == 0:
		var locs: Array = LOCALES[sector]
		bases.append(String(locs[absi(hash([cod, "l"])) % locs.size()]))
	if absi(hash([cod, "vecino"])) % 2 == 0:
		var vs: Array = VECINOS[sector]
		var otro: Array = TABLA[int(vs[absi(hash([cod, "v"])) % vs.size()])]
		bases.append(String(otro[absi(hash([cod, "vr"])) % otro.size()]))
	var k := absi(hash([cod, "paso"]))
	var i := 0
	while bases.size() < n and i < propios.size() * 2:
		var r := String(propios[(k + i * 5) % propios.size()])
		if not bases.has(r):
			bases.append(r)
		i += 1
	var out: Array[String] = []
	for b: String in bases:
		out.append(b + sufijo(cod, b))
	out.sort_custom(func(a: String, c: String) -> bool:
		var la := a.begins_with("C")
		var lc := c.begins_with("C")
		return a < c if la == lc else lc)
	return out

## «c» (vuelta) según el lado de la calle en que está el paradero; «e» (alternativa), uno de cada veinticinco.
static func sufijo(cod: String, base: String) -> String:
	if absi(hash([cod, base, "c"])) % 2 == 0:
		return "c"
	if not base.begins_with("C") and absi(hash([cod, base, "e"])) % 25 == 0:
		return "e"
	return ""

static func base_de(recorrido: String) -> String:
	return recorrido.trim_suffix("c").trim_suffix("e")

static func color(recorrido: String) -> Color:
	if recorrido.begins_with("C"):
		return COLOR_LOCAL
	var s := int(recorrido.substr(0, 1)) * 100
	return SECTORES[s][1] if SECTORES.has(s) else Color(0.4, 0.4, 0.45)

## Hacia dónde va: el 122 de A a B; el 122c, de B a A.
static func destino(recorrido: String) -> String:
	var b := base_de(recorrido)
	var h := absi(hash([b, "destino"]))
	var a := h % DESTINOS.size()
	var z := (a + 1 + (h / 7) % (DESTINOS.size() - 1)) % DESTINOS.size()
	return String(DESTINOS[a] if recorrido.ends_with("c") else DESTINOS[z])

## El nombre de la parada: la calle y la esquina («Av. Los Quillayes / Los Aromos»).
static func nombre_parada(cod: String) -> String:
	var h := absi(hash([cod, "calle"]))
	var a := h % CALLES.size()
	var b := (a + 1 + (h / 11) % (CALLES.size() - 1)) % CALLES.size()
	return "%s / %s" % [CALLES[a], CALLES[b]]

## Cada cuánto sale de cabecera (6-15 min): base por recorrido, más seguido en punta de lunes a viernes, más espaciado
## a última hora y el domingo. `dia` 0 = lunes.
static func frecuencia(recorrido: String, minuto_dia: int, dia: int) -> int:
	var f := 8 + absi(hash([base_de(recorrido), "f"])) % 6
	var h := minuto_dia / 60
	if dia < 5 and ((h >= 7 and h < 9) or (h >= 18 and h < 20)):
		f -= 2
	elif h >= 21 or h < 6:
		f += 2
	if dia == 6:
		f += 2
	if recorrido.ends_with("e"):
		f += 3
	return clampi(f, 6, 15)

## Las pasadas del día por el paradero (minuto del día). El índice de cada una es la vuelta del bus, para su patente.
static func pasadas(cod: String, recorrido: String, dia: int) -> PackedInt32Array:
	var local := recorrido.begins_with("C")
	var t := (INICIO_LOCAL if local else INICIO_SERVICIO) + absi(hash([cod, recorrido, "desfase"])) % 12
	var fin := FIN_LOCAL if local else FIN_SERVICIO
	var out := PackedInt32Array()
	while t <= fin:
		out.append(t)
		t += frecuencia(recorrido, t, dia)
	return out

## Los buses de la flota de un recorrido (6-14) y la patente de cada uno: 4 letras y 2 cifras, como «FLXK-52».
static func flota(recorrido: String) -> int:
	return 6 + absi(hash([base_de(recorrido), "flota"])) % 9

static func patente(recorrido: String, bus: int) -> String:
	var id := [base_de(recorrido), bus % flota(recorrido)]
	var h := absi(hash(id + ["patente"]))
	var s := ""
	for i in 4:
		s += LETRAS[h % LETRAS.length()]
		h /= LETRAS.length()
	return "%s-%02d" % [s, 10 + absi(hash(id + ["cifras"])) % 90]

## 0 con asientos, 1 de pie, 2 lleno (más lleno en punta).
static func ocupacion(recorrido: String, vuelta: int, minuto_dia: int, dia: int) -> int:
	var o := absi(hash([recorrido, vuelta, dia, "ocup"])) % 10
	var h := minuto_dia / 60
	var punta := dia < 5 and ((h >= 7 and h < 9) or (h >= 18 and h < 20))
	if punta:
		return 0 if o < 3 else (1 if o < 7 else 2)
	return 0 if o < 6 else (1 if o < 9 else 2)

## LAS PRÓXIMAS LLEGADAS al paradero desde `minuto_semana` (el del `Reloj`: lunes 00:00 = 0): hasta dos por recorrido,
## ordenadas por minutos. Cada una: {recorrido, destino, minutos, hora (minuto del día), patente, ocupacion}.
## Pasada la última vuelta del día no hay nada: de noche tarde no pasan micros.
static func llegadas(cod: String, minuto_semana: int, por_recorrido := 2) -> Array[Dictionary]:
	var dia := clampi(minuto_semana / 1440, 0, 6)
	var md := minuto_semana % 1440
	var out: Array[Dictionary] = []
	for r: String in recorridos(cod):
		var ps := pasadas(cod, r, dia)
		var n := 0
		for i in ps.size():
			if ps[i] < md:
				continue
			out.append({"recorrido": r, "destino": destino(r), "minutos": ps[i] - md, "hora": ps[i],
				"patente": patente(r, i), "ocupacion": ocupacion(r, i, ps[i], dia)})
			n += 1
			if n >= por_recorrido:
				break
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["minutos"]) != int(b["minutos"]):
			return int(a["minutos"]) < int(b["minutos"])
		return String(a["recorrido"]) < String(b["recorrido"]))
	return out

## El paradero más cercano a `pos` entre los montados (`ParaderoRed.montar` los mete en el grupo «paradero_red» con su
## código en la meta «codigo_red»). {codigo, distancia} o {} si no hay ninguno a menos de `radio` metros.
static func paradero_cercano(arbol: SceneTree, pos: Vector3, radio := 40.0) -> Dictionary:
	var mejor := {}
	if arbol == null:
		return mejor
	for n: Node in arbol.get_nodes_in_group("paradero_red"):
		if not (n is Node3D) or not n.is_inside_tree() or not n.has_meta("codigo_red"):
			continue
		var d := (n as Node3D).global_position.distance_to(pos)
		if d <= radio and (mejor.is_empty() or d < float(mejor["distancia"])):
			mejor = {"codigo": String(n.get_meta("codigo_red")), "distancia": d}
	return mejor
