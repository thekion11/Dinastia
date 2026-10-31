class_name RecorridosRed
extends RefCounted
## LOS RECORRIDOS DE «RED» (27-10-2026, orden del dueño 16; ATADOS AL MAPA el 28-10, orden 17). Los paraderos de la ciudad son de
## «Red» (como Red Movilidad de Santiago): cada uno tiene su código «PA####» en el poste (`ParaderoRed`) y el DT lo consulta en la
## app «Red» del móvil para ver qué micros pasan, en cuántos minutos llegan y su patente. ESTA ES LA FACHADA ÚNICA: el cartel 3D,
## la app, el mapa del transporte y los buses de la calle (`BusesRed`) leen de aquí, así dicen lo mismo.
## LOS DATOS salen del mapa (`RecorridosMapa`): cada recorrido sigue calles reales, su número es el del sector donde nace (1xx el
## club, 2xx el centro…), su vuelta lleva «c», el 301e es la alternativa y C02/C09 los locales; los paraderos son sus paradas, con
## el nombre de la calle y la esquina (`CallesCiudad`) y el código «PA» + sector + 3 cifras, numerado en orden por sector.
## EL HORARIO (cuando la ciudad no está montada o el DT no está en la calle): cada recorrido sale de su cabecera cada 6-15 min según
## la hora del reloj del juego (más seguido en punta, más espaciado a última hora y el domingo), con servicio de 05:30 a 23:30 (los
## locales, de 06:30 a 22:00), y llega a cada paradero tras la DISTANCIA REAL del recorrido hasta él a `VEL_COMERCIAL`. En la
## calle, la app usa la posición y la velocidad reales de los buses (`BusesRed.llegadas`).
## TODO ES DETERMINISTA: no toca `Azar` ni la hora del sistema.

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

## Letras de patente chilena (sin vocales ni las que se confunden).
const LETRAS := "BCDFGHJKLPRSTVWXYZ"
const INICIO_SERVICIO := 330      ## 05:30
const FIN_SERVICIO := 1410        ## 23:30
const INICIO_LOCAL := 390         ## 06:30
const FIN_LOCAL := 1320           ## 22:00
const OCUPACION := ["Con asientos", "De pie", "Lleno"]
const VEL_COMERCIAL := 330.0     ## m por minuto de reloj (~20 km/h con paradas y semáforos)

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

## Un paradero REAL del mapa para `semilla` dentro del `sector` (los montajes sueltos de pruebas y capturas): siempre el mismo.
static func codigo(semilla: int, sector: int) -> String:
	var s := clampi(sector / 100, 1, 6) * 100
	var lista: Array[String] = []
	for cod: String in RecorridosMapa.datos()["orden"]:
		if int(RecorridosMapa.paradero(cod)["sector"]) == s:
			lista.append(cod)
	if lista.is_empty():
		return String(RecorridosMapa.datos()["orden"][0])
	return lista[posmod(semilla, lista.size())]

## ¿Existe ese paradero en el mapa?
static func existe(cod: String) -> bool:
	return not RecorridosMapa.paradero(cod).is_empty()

## El paradero del mapa en (o muy cerca de) una posición: "" si no hay ninguno a menos de `radio` metros.
static func paradero_en(pos: Vector3, radio := 3.0) -> String:
	return RecorridosMapa.cercano(pos, radio)

## Lo que escribe el jugador («pa1234», «1234», «PA 1234») a la forma del cartel; "" si no es un código.
static func normalizar(texto: String) -> String:
	var t := texto.strip_edges().to_upper().replace(" ", "").replace("-", "")
	if not t.begins_with("PA"):
		t = "PA" + t
	var cifras := t.substr(2)
	if cifras.length() < 3 or cifras.length() > 4 or not cifras.is_valid_int():
		return ""
	return t

## El sector del código: su primera cifra (PA2xxx = centro). Los del mapa siempre tienen cuatro.
static func sector_del_codigo(cod: String) -> int:
	var cifras := cod.substr(2)
	if cifras.length() == 4 and int(cifras[0]) >= 1 and int(cifras[0]) <= 6:
		return int(cifras[0]) * 100
	return 0

## Los recorridos que paran en el paradero (los que de verdad pasan por él, en su sentido), troncales por número y los locales
## al final. Vacío si el código no existe.
static func recorridos(cod: String) -> Array[String]:
	var p := RecorridosMapa.paradero(cod)
	var out: Array[String] = []
	if not p.is_empty():
		out.assign(p["recorridos"])
	return out

static func base_de(recorrido: String) -> String:
	return recorrido.trim_suffix("c").trim_suffix("e")

static func color(recorrido: String) -> Color:
	if recorrido.begins_with("C"):
		return COLOR_LOCAL
	var s := int(recorrido.substr(0, 1)) * 100
	return SECTORES[s][1] if SECTORES.has(s) else Color(0.4, 0.4, 0.45)

## Hacia dónde va (el barrio o hito de su cabecera final): el 122 al Puerto; el 122c, al Estadio.
static func destino(recorrido: String) -> String:
	return String(RecorridosMapa.servicio(recorrido).get("destino", ""))

## El nombre de la parada: la calle y la próxima esquina («Av. Los Pimientos / El Peumo»).
static func nombre_parada(cod: String) -> String:
	return String(RecorridosMapa.paradero(cod).get("nombre", ""))

## Metros desde la cabecera del recorrido hasta el paradero, por sus calles (−1 si no para ahí).
static func distancia(cod: String, recorrido: String) -> float:
	var s := RecorridosMapa.servicio(recorrido)
	var i := (s.get("paraderos", []) as Array).find(cod)
	return float(s["dist"][i]) if i >= 0 else -1.0

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

## Las pasadas del día por el paradero (minuto del día): las salidas de cabecera (desfasadas por recorrido) más el tiempo de
## viaje por la distancia real hasta el paradero. El índice de cada una es la vuelta del bus, para su patente.
static func pasadas(cod: String, recorrido: String, dia: int) -> PackedInt32Array:
	var local := recorrido.begins_with("C")
	var t := (INICIO_LOCAL if local else INICIO_SERVICIO) + absi(hash([recorrido, "desfase"])) % 12
	var fin := FIN_LOCAL if local else FIN_SERVICIO
	var viaje := roundi(maxf(distancia(cod, recorrido), 0.0) / VEL_COMERCIAL)
	var out := PackedInt32Array()
	while t <= fin:
		out.append(t + viaje)
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
