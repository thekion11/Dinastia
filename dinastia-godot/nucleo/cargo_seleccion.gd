class_name CargoSeleccion
extends RefCounted
## EL CARGO DE SELECCIONADOR (encargo del dueño del 10-11, punto 2: «el sistema de aceptar una selección y poder jugar los torneos de selecciones»).
## Antes las ofertas de trabajo eran solo de clubes. Ahora, con prestigio, LLAMAN SELECCIONES: cuanto más prestigio, más grande la que llama
## (`_alcanza`). Se acepta o se rechaza; el cargo es DOBLE (sigues con tu club) y se deja con `dimitir`. Mientras lo tengas, el Mundial y el torneo
## continental de esa selección se pueden JUGAR (`torneos_del_anio` los prepara y la interfaz juega tus partidos en directo o simulados); lo que
## quede, y lo que no juegues, lo cierra `Selecciones.cierre_de_temporada` con el mismo torneo (`listo`). Las ofertas usan azar aislado
## (`CopasMundo._aislado`): no cambian nada del resto del juego. Vive dentro de `Selecciones` y se guarda con ella.
const PRESTIGIO_MINIMO := 55
const SEMANAS_ENTRE_OFERTAS := 16
const PROB_SEMANAL := 0.05
const PRESTIGIO_POR_TITULO := 6

var seleccion := ""            ## la que diriges ("" = ninguna)
var desde := 0                 ## año en que la tomaste
var sueldo := 0                ## lo que cobras por semana (va a tu patrimonio)
var oferta: Dictionary = {}    ## {nombre, fuerza, sueldo}
var historial: Array = []      ## [{anio, torneo, puesto}] de tus torneos como seleccionador
var convocados: Array[String] = []   ## tu convocatoria (ids de jugadores del mundo, hasta 26); vacía = los mejores por puesto
var _ultima := -999            ## semana absoluta (año·60 + semana) de la última oferta
var _listos := {}              ## «torneo/año» -> TorneoSelecciones preparados este año (no se guardan: se juegan antes del cierre)

func activo() -> bool:
	return seleccion != ""

## La fuerza más alta de selección que te puede llamar con este prestigio (50 → 70; 80 → 88; 99 → 99).
static func _alcanza(prestigio: int) -> int:
	return 40 + int(round(float(prestigio) * 0.6))

## Todas las selecciones que existen en los torneos (sin repetir).
static func todas() -> Array[String]:
	var out: Array[String] = []
	for clave: String in SeleccionesTorneos.POR_CONFED:
		for n: String in SeleccionesTorneos.POR_CONFED[clave]:
			if not out.has(n):
				out.append(n)
	return out

## La confederación de una selección (la primera lista en la que sale; «lib» si no sale en ninguna).
static func confed_de(nombre: String) -> String:
	var cod := SeleccionEquipo.codigo_de(nombre)
	if cod != "":
		return Continental.confed_de(cod)
	for clave: String in SeleccionesTorneos.POR_CONFED:
		if (SeleccionesTorneos.POR_CONFED[clave] as Array).has(nombre):
			return clave
	return "lib"

## Una semana: quizá llama una selección. Devuelve la oferta nueva, o vacío.
func sortear(m: Mundo, sel: Selecciones) -> Dictionary:
	if m == null or m.roles == null or activo() or not oferta.is_empty():
		return {}
	var ahora := m.anio * 60 + m.semana
	if ahora - _ultima < SEMANAS_ENTRE_OFERTAS or m.roles.prestigio < PRESTIGIO_MINIMO:
		return {}
	var tope := _alcanza(m.roles.prestigio)
	var nueva := {}
	CopasMundo._aislado("cargo_sel%d/%d" % [m.anio, m.semana], func() -> void:
		if not Azar.suerte(PROB_SEMANAL):
			return
		var candidatas: Array[Dictionary] = []
		for n: String in todas():
			var f := sel.fuerza(n)
			if f <= tope and f >= tope - 14:
				candidatas.append({"nombre": n, "fuerza": f})
		if candidatas.is_empty():
			return
		var e: Dictionary = candidatas[Azar.ent(0, candidatas.size() - 1)]
		nueva.merge({"nombre": String(e["nombre"]), "fuerza": int(e["fuerza"]),   ## merge: la lambda no puede reasignar la variable de fuera
			"sueldo": Eco.escalar(3500.0 * (0.6 + float(m.roles.prestigio) / 100.0), float(e["fuerza"]))}))
	if nueva.is_empty():
		return {}
	_ultima = ahora
	oferta = nueva
	return oferta

## Para pruebas y para la interfaz: una oferta concreta (sin azar).
func ofrecer(nombre: String, fuerza: int, sueldo_semana: int = 0) -> void:
	oferta = {"nombre": nombre, "fuerza": fuerza, "sueldo": sueldo_semana}

func responder(m: Mundo, acepta: bool) -> String:
	if oferta.is_empty():
		return "no hay ninguna oferta de selección"
	var n := String(oferta["nombre"])
	var oferta_previa := oferta
	oferta = {}
	if not acepta:
		return "Dices que no a la selección de %s. Tu club respira tranquilo." % n
	seleccion = n
	convocados.clear()
	sueldo = int(oferta_previa.get("sueldo", 0))
	desde = m.anio if m != null else 0
	if m != null and m.prensa != null:
		m.prensa.noticia.emit("🌍 Nuevo seleccionador de %s" % n,
			"Aceptas dirigir a %s sin dejar tu club. Tus torneos de selecciones se juegan al final de la temporada." % n)
	return "Eres el seleccionador de %s (y sigues en tu club)." % n

func dimitir(m: Mundo) -> String:
	if not activo():
		return "no diriges ninguna selección"
	var n := seleccion
	seleccion = ""
	sueldo = 0
	convocados.clear()
	_listos.clear()
	if m != null and m.prensa != null:
		m.prensa.noticia.emit("Dejas la selección de %s" % n, "Presentas la dimisión: vuelves a dedicarte solo a tu club.")
	return "Dejas la selección de %s." % n

# ---------------------------------------------------------------- torneos

## Los torneos de ESTE año en los que juega tu selección (el Mundial, si toca y se clasifica, y su continental, si toca), ya montados.
func torneos_del_anio(m: Mundo, sel: Selecciones, anio: int) -> Array[TorneoSelecciones]:
	var out: Array[TorneoSelecciones] = []
	if not activo() or m == null:
		return out
	var clave := confed_de(seleccion)
	if Calendario.toca_continental_selecciones(clave, anio):
		var nom := String(Selecciones.TORNEO_POR_CONFED.get(clave, "Copa América"))
		var t := listo(nom, anio)
		if t == null:
			t = SeleccionesTorneos.continental(sel, m, clave, nom, anio)
			_listos["%s/%d" % [nom, anio]] = t
		if _con_mi_lista(m, sel, t):
			out.append(t)
	if sel.toca_copa_del_mundo(anio):
		var w := listo("Copa del Mundo", anio)
		if w == null:
			w = SeleccionesTorneos.mundial(sel, m, anio)
			_listos["Copa del Mundo/%d" % anio] = w
		if _con_mi_lista(m, sel, w):
			out.append(w)
	return out

## Pone TU convocatoria en tu selección dentro de `t` (antes de jugar nada). Devuelve si tu selección juega `t`.
func _con_mi_lista(m: Mundo, sel: Selecciones, t: TorneoSelecciones) -> bool:
	var mia := SeleccionesTorneos.equipo_en(t, seleccion)
	if mia == null:
		return false
	if not convocados.is_empty() and t.resultados.is_empty():
		var nueva := SeleccionEquipo.club_de(m, seleccion, sel.fuerza(seleccion), t.anio, convocados)
		mia.plantilla = nueva.plantilla   ## mismo club (mismo id, grupo y tabla): cambia la lista
	return true

## Marca o desmarca a un jugador en tu convocatoria (máx. 26). Devuelve si quedó dentro.
func alternar(id: String) -> bool:
	if convocados.has(id):
		convocados.erase(id)
		return false
	if convocados.size() >= SeleccionEquipo.MAX_CONVOCADOS:
		return false
	convocados.append(id)
	return true

## El torneo `nombre` del año `anio` si ya se preparó (y quizá se jugó a medias), o null.
func listo(nombre: String, anio: int) -> TorneoSelecciones:
	return _listos.get("%s/%d" % [nombre, anio])

## Tu equipo (la selección que diriges) dentro de `t`, o null.
func mi_equipo(t: TorneoSelecciones) -> Club:
	return SeleccionesTorneos.equipo_en(t, seleccion) if activo() else null

## Al cerrarse un torneo de tu selección: lo apunta y, si lo ganaste, suma prestigio.
func anotar(m: Mundo, t: TorneoSelecciones) -> int:
	var mia := mi_equipo(t)
	if mia == null or t.en_curso():
		return -1
	for h: Dictionary in historial:
		if String(h["torneo"]) == t.nombre and int(h["anio"]) == t.anio:
			return int(h["puesto"])
	var puesto := t.puesto_de(mia)
	historial.append({"anio": t.anio, "torneo": t.nombre, "puesto": puesto})
	if puesto == 0 and m != null and m.roles != null:
		m.roles.prestigio = clampi(m.roles.prestigio + PRESTIGIO_POR_TITULO, Roles.PRESTIGIO_MIN, Roles.PRESTIGIO_MAX)
		if m.logros != null:
			m.logros.celebrar_titulo(t.nombre)
	return puesto

## Al cierre de la temporada: termina (simulado) lo que quede de los torneos de tu selección que no cerró `Selecciones` (p. ej. el
## continental de otra confederación que la de tu club) y los apunta. Devuelve [{torneo, puesto, campeon}].
func cerrar_listos(m: Mundo) -> Array:
	var out: Array = []
	for k: String in _listos:
		var t: TorneoSelecciones = _listos[k]
		t.jugar_entero()
		var puesto := anotar(m, t)
		if puesto >= 0:
			out.append({"torneo": t.nombre, "puesto": puesto, "campeon": t.campeon.nombre if t.campeon != null else ""})
	_listos.clear()
	return out

func titulos() -> int:
	return historial.filter(func(h: Dictionary) -> bool: return int(h["puesto"]) == 0).size()

func a_dic() -> Dictionary:
	return {"sel": seleccion, "desde": desde, "oferta": oferta, "sueldo": sueldo, "hist": historial, "ultima": _ultima, "conv": convocados}

func desde_dic(d: Dictionary) -> void:
	seleccion = String(d.get("sel", ""))
	desde = int(d.get("desde", 0))
	sueldo = int(d.get("sueldo", 0))
	oferta = (d.get("oferta", {}) as Dictionary).duplicate()
	historial = (d.get("hist", []) as Array).duplicate(true)
	_ultima = int(d.get("ultima", -999))
	convocados.clear()
	for id in d.get("conv", []):
		convocados.append(String(id))
	_listos.clear()
