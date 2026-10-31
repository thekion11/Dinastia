class_name BusesRed
extends Node
## LOS BUSES «RED» DE LA CALLE (28-10-2026, orden 17 del dueño). Cada recorrido del mapa (`RecorridosMapa`) es UNA ruta cerrada de
## `TraficoCiudad`: la ida por el carril derecho hasta la cabecera, media vuelta y la vuelta («c») por el otro carril (el 301e vuelve
## como 301c). En ella circulan sus buses (1 por cada 5 km de vuelta completa, de 1 a 3), con el número, el destino del sentido en que
## van (el letrero cambia en la cabecera) y su PATENTE de la flota (`RecorridosRed.patente`), y paran en cada paradero de su recorrido.
## La app «Red» del móvil calcula los minutos con la posición y la velocidad reales de estos buses (`llegadas`).
## Los paraderos (`montar_paraderos`) se montan desde la misma fuente, mirando a la calle, en la acera de su sentido.

const VEL := 9.0
const PUERTA_ADELANTE := 4.6   ## m del centro del bus a su puerta delantera (`AutobusModelo`)
const ESPERA := 7.0
const ARRANQUE_Y_FRENADA := 4.0   ## segundos que se pierden en cada parada además de la espera (frena y vuelve a arrancar)
const CARRIL_AV := 6.0
const CARRIL_CALLE := 3.5
const CARRIL_NUCLEO := 4.0

var trafico: TraficoCiudad
var buses: Array = []   ## {nodo, ida, vuelta, s_vuelta, largo, paradas: {código: s}, rotulo: Label3D, sentido}
var _t := 0.0

## Los paraderos del mapa (menos los cuatro del anillo, que monta `CityBuilder._paradas_bus`) y su sitio de espera para los pasajeros.
static func montar_paraderos(ex: CiudadExpansion) -> int:
	var n := 0
	for cod: String in RecorridosMapa.datos()["orden"]:
		var p := RecorridosMapa.paradero(cod)
		if bool(p["club"]):
			continue
		var raiz := Node3D.new()
		raiz.position = p["pos"]
		raiz.rotation.y = float(p["giro"])
		ex.b.add_child(raiz)
		ParaderoRed.montar(raiz, 3.8, 0, String(p["nombre"]), int(p["sector"]), cod)
		ex.b.esperas_bus.append((p["pos"] as Vector3) + raiz.basis * Vector3(0, 0.24, 0.3))
		n += 1
	return n

## El carril de un recorrido: cada tramo desplazado a su derecha (avenida, calle o calle del club).
static func carril(ejes: PackedVector2Array, alto: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	var n := ejes.size()
	for k in n:
		var off := Vector2.ZERO
		for t in [k - 1, k]:
			if t < 0 or t >= n - 1:
				continue
			var d := (ejes[t + 1] - ejes[t]).normalized()
			var c := _ancho_carril(ejes[t], ejes[t + 1])
			## Un giro de 90°: se suman los dos desplazamientos; recto, uno solo.
			if off != Vector2.ZERO and absf(off.normalized().dot(Vector2(-d.y, d.x))) > 0.99:
				continue
			off += Vector2(-d.y, d.x) * c
		out.append(Vector3(ejes[k].x + off.x, alto, ejes[k].y + off.y))
	return out

static func _ancho_carril(a: Vector2, c: Vector2) -> float:
	var ac := RecorridosMapa._acera(a, c)
	return CARRIL_NUCLEO if ac == RecorridosMapa.ACERA_NUCLEO else (CARRIL_AV if ac == RecorridosMapa.ACERA_AV else CARRIL_CALLE)

## Monta los buses de todos los recorridos en `t`. Devuelve cuántos.
static func montar(ex: CiudadExpansion, t: TraficoCiudad) -> int:
	var g := BusesRed.new()
	g.name = "BusesRed"
	g.trafico = t
	g.add_to_group("buses_red")
	t.add_child(g)
	for num: String in RecorridosMapa.servicios():
		if num.ends_with("c"):
			continue
		var ida := RecorridosMapa.servicio(num)
		var vuelta := RecorridosMapa.servicio(RecorridosMapa.vuelta_de(num))
		var pi := carril(ida["ejes"], 0.3)
		var pv := carril(vuelta["ejes"], 0.3)
		var pts := pi.duplicate()
		pts.append_array(pv)
		var id := t.agregar_ruta(ex.b._redondear(ex._subir_puentes(pts), 12.0))
		ex._controles_de(t, id)
		var paradas := {}
		var lista: Array = []
		for cod: String in ida["paraderos"]:
			paradas[cod] = t.s_mas_cercano(id, RecorridosMapa.paradero(cod)["pos"])
		var s_vuelta := t.s_mas_cercano(id, pv[0])
		for cod: String in vuelta["paraderos"]:
			if not paradas.has(cod):
				paradas[cod] = t.s_mas_cercano(id, RecorridosMapa.paradero(cod)["pos"])
		var largo := t.largo_de(id)
		## El bus para con su PUERTA DELANTERA frente al paradero: el centro del bus queda PUERTA_ADELANTE m antes del punto del paradero.
		for cod: String in paradas:
			paradas[cod] = fposmod(float(paradas[cod]) - PUERTA_ADELANTE, largo)
		lista.assign(paradas.values())
		var cuantos := clampi(roundi(largo / 5000.0), 1, 3)
		var col := RecorridosRed.color(num)
		for k in cuantos:
			var pat := RecorridosRed.patente(num, k + (4 if num.ends_with("e") else 0))   ## el «e» usa otros buses de la flota de su base
			var nb: Node3D = CityBuilder.autobus(col, "%s · %s" % [num, String(ida["destino"]).to_upper()], num)
			nb.name = "Bus_%s_%d" % [num, k]
			nb.add_to_group("bus_red")
			nb.set_meta("red_recorrido", num)
			nb.set_meta("red_patente", pat)
			var lp := Label3D.new()   ## la patente, sobre la placa trasera
			lp.text = pat
			lp.font_size = 36
			lp.pixel_size = 0.004
			lp.outline_size = 6
			lp.position = Vector3(0, 0.62, -6.07)
			lp.rotation.y = PI
			lp.double_sided = false
			lp.visibility_range_end = 40.0
			nb.add_child(lp)
			t.agregar_vehiculo(nb, id, largo * float(k) / float(cuantos), VEL, 0.0, 0.0)
			t.agregar_paradas_al_ultimo(lista, ESPERA)
			t.marcar_cola_al_ultimo()
			var rotulo: Label3D = null
			for l: Node in nb.find_children("*", "Label3D", false, false):
				if (l as Label3D).text.contains(" · "):
					rotulo = l
			g.buses.append({"nodo": nb, "ida": num, "vuelta": String(vuelta["numero"]), "s_vuelta": s_vuelta, "largo": largo,
				"paradas": paradas, "rotulo": rotulo, "sentido": 0, "destinos": [String(ida["destino"]), String(vuelta["destino"])]})
	return g.buses.size()

## Cada segundo: el letrero de delante dice el sentido en que va el bus (en la cabecera pasa de «122 · PUERTO» a «122c · ESTADIO»).
func _process(delta: float) -> void:
	_t -= delta
	if _t > 0.0 or trafico == null:
		return
	_t = 1.0
	var vs := _vehiculos()
	for b: Dictionary in buses:
		var v: Dictionary = vs.get(b["nodo"], {})
		if v.is_empty() or b["rotulo"] == null:
			continue
		var sentido := 0 if float(v["s"]) < float(b["s_vuelta"]) else 1
		if sentido != int(b["sentido"]):
			b["sentido"] = sentido
			(b["rotulo"] as Label3D).text = "%s · %s" % [b["ida"] if sentido == 0 else b["vuelta"], String(b["destinos"][sentido]).to_upper()]

func _vehiculos() -> Dictionary:
	var out := {}
	for v: Dictionary in trafico._vehiculos:
		out[v["nodo"]] = v
	return out

## LAS PRÓXIMAS LLEGADAS EN VIVO al paradero `cod`: para cada bus que para ahí, la distancia que le falta por su ruta, a su velocidad,
## más lo que se detiene en las paradas de en medio. Mismo formato que `RecorridosRed.llegadas` (+ «en_vivo», «segundos»). Vacío
## si no hay buses montados (la app usa entonces el horario).
static func llegadas(arbol: SceneTree, cod: String, por_recorrido := 2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if arbol == null:
		return out
	var por: Dictionary = {}
	for g: Node in arbol.get_nodes_in_group("buses_red"):
		var gb := g as BusesRed
		if gb == null or gb.trafico == null or not is_instance_valid(gb.trafico):
			continue
		var vs := gb._vehiculos()
		for b: Dictionary in gb.buses:
			var v: Dictionary = vs.get(b["nodo"], {})
			if v.is_empty() or not (b["paradas"] as Dictionary).has(cod):
				continue
			var largo := float(b["largo"])
			var s_bus := float(v["s"])
			var s_par := float(b["paradas"][cod])
			var falta := fposmod(s_par - s_bus, largo)
			var seg := falta / maxf(float(v["vel"]), 0.5)
			for s2: float in (b["paradas"] as Dictionary).values():
				var d := fposmod(s2 - s_bus, largo)
				if d > 0.5 and d < falta - 0.5:
					seg += ESPERA + ARRANQUE_Y_FRENADA
			if falta < 1.0 and float(v.get("espera", 0.0)) > 0.0:
				seg = 0.0
			var num := String(b["ida"]) if s_par < float(b["s_vuelta"]) else String(b["vuelta"])
			var l := {"recorrido": num, "destino": RecorridosRed.destino(num), "minutos": int(seg / 60.0), "segundos": seg, "hora": -1,
				"patente": String((b["nodo"] as Node).get_meta("red_patente", "")), "ocupacion": clampi(((b["nodo"] as Node).get_meta("pasajeros", []) as Array).size() / 4, 0, 2),
				"en_vivo": true}
			if not por.has(num):
				por[num] = []
			(por[num] as Array).append(l)
	for num: String in por:
		var lista: Array = por[num]
		lista.sort_custom(func(a: Dictionary, c: Dictionary) -> bool: return float(a["segundos"]) < float(c["segundos"]))
		for i in mini(por_recorrido, lista.size()):
			out.append(lista[i])
	out.sort_custom(func(a: Dictionary, c: Dictionary) -> bool:
		if int(a["minutos"]) != int(c["minutos"]):
			return int(a["minutos"]) < int(c["minutos"])
		return String(a["recorrido"]) < String(c["recorrido"]))
	return out
