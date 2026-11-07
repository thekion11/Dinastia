class_name ExpansionTardia
extends RefCounted
## EL MOBILIARIO URBANO DE LA CIUDAD, la parte que se puede construir DESPUÉS de mostrarla (2-11-2026, meta de carga de 5 s): marquesinas, guirnaldas, farolas,
## mobiliario, placas de calle, orillas, obras y losetas Kenney. Lo llama `CargaCiudad.de("CiudadExpansion").construir` de seguida o, con `CargaCiudad.de("CityBuilder").diferir`, `CargaCiudad.de("CityBuilder")._resto`.

## Con `CargaCiudad.de("CityBuilder").diferir`, solo las `PRIMEROS` manzanas más cercanas al estadio se dibujan antes de mostrar la ciudad; el resto se guarda en `ex.bloques_diferidos` (de cerca a lejos).
const PRIMEROS := 26

static func primeros_bloques(ex) -> Array:
	if not CargaCiudad.de("CityBuilder").diferir or ex.bloques.size() <= PRIMEROS:
		return ex.bloques
	var orden: Array = ex.bloques.duplicate()
	var centro = Vector2(CargaCiudad.de("CityBuilder").ESTADIO_EN.x, CargaCiudad.de("CityBuilder").ESTADIO_EN.z)
	orden.sort_custom(func(a: Dictionary, c: Dictionary) -> bool: return (a["rect"] as Rect2).get_center().distance_to(centro) < (c["rect"] as Rect2).get_center().distance_to(centro))
	ex.bloques_diferidos = orden.slice(PRIMEROS)
	return orden.slice(0, PRIMEROS)

## El azar de cada pieza sale de SU clave y no de lo que se haya dibujado antes (`_rng` compartido): así la ciudad es la misma se construya de seguida o por partes, y en cualquier orden.
static func sembrar(ex, clave: Variant) -> void:
	ex._rng.seed = 13072026 + hash(clave)

## Una manzana, con su propio azar.
static func bloque(ex, bl: Dictionary) -> void:
	sembrar(ex, ["bloque", bl["celda"]])
	ex._dibujar_bloque(bl)

## Lo que se agrupa tras dibujar todas las manzanas: edificios lejanos, casas y modulares.
static func casas(ex) -> void:
	sembrar(ex, "edificios_lejanos")
	ex._edificios_lejanos()
	await ex.b._marca("exp.edificios_lejanos")   ## (6-11) cada paso cede por separado (la carga en partes cortas)
	sembrar(ex, "casas")
	ex._casas_multimesh()
	await ex.b._marca("exp.casas_mm")
	sembrar(ex, "modular")
	ex._modular_multimesh()

## Las manzanas que faltan, una a una (cada una cede el fotograma si toca).
static func bloques_restantes(ex) -> void:
	for bl: Dictionary in ex.bloques_diferidos:
		bloque(ex, bl)
		await ex.b._marca("exp.bloque")
	ex.bloques_diferidos = []
	await casas(ex)
	await ex.b._marca("exp.casas")

static func mobiliario(ex) -> void:
	sembrar(ex, "marquesinas")
	ex._marquesinas_bus()
	await ex.b._marca("exp.mob.marquesinas_bus")
	sembrar(ex, "guirnaldas")
	ex._guirnaldas()
	await ex.b._marca("exp.mob.guirnaldas")
	sembrar(ex, "farolas")
	ex._farolas()
	await ex.b._marca("exp.mob.farolas")
	sembrar(ex, "mobiliario")
	ex._mobiliario_urbano()
	await ex.b._marca("exp.mob.mobiliario_urbano")
	sembrar(ex, "placas")
	ex._placas_de_calle()
	await ex.b._marca("exp.mob.placas_de_calle")
	sembrar(ex, "orillas")
	ex._orillas_nucleo()
	await ex.b._marca("exp.mob.orillas_nucleo")
	sembrar(ex, "obras")
	ex._obras_en_calle()
	await ex.b._marca("exp.mob.obras_en_calle")
	sembrar(ex, "kenney")
	ex._kenney_calles()
	await ex.b._marca("exp.mob.kenney_calles")
	ex.tardio_pendiente = false
	await ex.b._marca("exp.mobiliario")

## Lo más lejano de la ciudad (no está en el prólogo): la autopista, el parque eólico, el depósito de agua y el teleférico.
static func afueras(ex) -> void:
	sembrar(ex, "autopista")
	ex.cuenta["autopista"] = CargaCiudad.de("Autopista").montar(ex.b)
	await ex.b._marca("exp.autopista")   ## (6-11) cada paso cede por separado
	sembrar(ex, "eolico")
	ex._parque_eolico()
	sembrar(ex, "deposito")
	ex._deposito_agua()
	await ex.b._marca("exp.eolico_deposito")
	ex.tele_nodo = CargaCiudad.de("Teleferico").montar(ex.b)
	ex.teleferico = ex.tele_nodo.datos()

## (3-11, el prólogo no cargaba en el móvil) Los modelos de coches y karts se leen del disco en HILOS aparte antes de montarlos:
## `load` en el hilo principal congelaba la pantalla ~0,8 s en un servidor (decenas de segundos en un teléfono). Espera
## fotograma a fotograma; si algo falla, `load` lo vuelve a pedir de forma normal después.
static func precargar_vehiculos(b) -> void:
	var rutas: Array[String] = []
	rutas.append_array([CargaCiudad.de("CityBuilder").RUTA_COCHE_REAL_1, CargaCiudad.de("CityBuilder").RUTA_COCHE_REAL_2])
	rutas.append_array(CargaCiudad.de("CityBuilder").RUTAS_COCHES_KENNEY)
	rutas.append_array(CargaCiudad.de("CityBuilder").RUTAS_SERVICIO)
	for lista: Array in [CargaCiudad.de("CityBuilder").KARTS, CargaCiudad.de("CityBuilder").RUEDAS, CargaCiudad.de("CityBuilder").PIEZAS]:
		for n: String in lista:
			rutas.append("res://assets/ciudad/kenney_cars_extra/%s.glb" % n)
	var pedidas: Array[String] = []
	for r in rutas:
		if ResourceLoader.exists(r) and ResourceLoader.load_threaded_request(r) == OK:
			pedidas.append(r)
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 20000:
		var pendiente := false
		for r in pedidas:
			if ResourceLoader.load_threaded_get_status(r) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				pendiente = true
				break
		if not pendiente:
			break
		await b.get_tree().process_frame
