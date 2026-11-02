class_name BusDT
extends RefCounted
## EL DT SUBE AL BUS «RED» (28-10-2026, pendiente del líder: «el bus cobra al DT»). Junto a un paradero con un autobús parado (a menos de
## `RADIO_BUS` m de la marquesina) aparece «E: subir al bus»: cuesta el pasaje de la tarjeta Red (`VidaCiudad.cobrar_pasaje("bus")`), un fundido y el DT baja
## `PARADAS` paradas más allá en el recorrido de ese autobús (la lista de paraderos de `RecorridosMapa.servicio`). Sin saldo no sube.
const ALCANCE := 3.6
const RADIO_BUS := 12.0
const PARADAS := 3

## El paradero a menos de `ALCANCE` m de `p` (nodo del grupo «paradero_red»), o null.
static func parada_cerca(arbol: SceneTree, p: Vector3) -> Node3D:
	var mejor: Node3D = null
	var d_mejor := ALCANCE
	for n: Node3D in arbol.get_nodes_in_group("paradero_red"):
		var d := Vector2(n.global_position.x - p.x, n.global_position.z - p.z).length()
		if d < d_mejor:
			d_mejor = d
			mejor = n
	return mejor

## El autobús «Red» parado junto a la marquesina `parada`, o null.
static func bus_en(arbol: SceneTree, parada: Node3D) -> Node3D:
	for b: Node3D in arbol.get_nodes_in_group("bus_red"):
		if is_instance_valid(b) and b.visible and Vector2(b.global_position.x - parada.global_position.x, b.global_position.z - parada.global_position.z).length() < RADIO_BUS \
				and b.has_meta("red_recorrido"):
			return b
	return null

## El paradero donde baja quien sube en `cod` al recorrido `num`: `PARADAS` más allá; "" si el recorrido no pasa por `cod`.
static func destino(num: String, cod: String) -> String:
	var lista: Array = RecorridosMapa.servicio(num).get("paraderos", [])
	var i := lista.find(cod)
	if i < 0 or lista.size() < 2:
		return ""
	return String(lista[(i + mini(PARADAS, lista.size() - 1)) % lista.size()])   ## en un recorrido corto, hasta la última

## Lo que ofrece la tecla E en `p`: {tipo: "bus_parada", n, parada, bus, num} o {} si no hay paradero con bus parado.
static func detectar(arbol: SceneTree, p: Vector3) -> Dictionary:
	var pa := parada_cerca(arbol, p)
	if pa == null:
		return {}
	var b := bus_en(arbol, pa)
	if b == null:
		return {}
	var num := String(b.get_meta("red_recorrido"))
	if destino(num, String(pa.get_meta("codigo_red", ""))) == "":
		return {}
	return {"tipo": "bus_parada", "n": "Bus " + num, "parada": pa, "bus": b, "num": num}

## E: el botón peatonal (M-170) o subir al bus. `e` es el `ExploradorCiudad`.
static func usar(e: Object, c: Dictionary) -> void:
	if String(c["tipo"]) == "boton_peatonal":
		e.cb.expansion.semaforos.pedir_con_aviso(e)
		return
	if e.vida != null and not e.vida.cobrar_pasaje("bus"):
		return
	var cod := String((c["parada"] as Node3D).get_meta("codigo_red", ""))
	var dest := destino(String(c["num"]), cod)
	var pa: Dictionary = RecorridosMapa.paradero(dest)
	if pa.is_empty():
		return
	var pos: Vector3 = pa["pos"]
	e._fundido()
	e.cuerpo.position = Vector3(pos.x, e.altura_suelo(pos.x, pos.z), pos.z)
	e._aviso.text = Idiomas.t("Bajas en %s (%s) · %d paradas") % [String(pa["nombre"]), dest, PARADAS]
