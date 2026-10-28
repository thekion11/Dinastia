class_name PrecalentarCaras
extends Node
## LOS JUGADORES EN EL MENÚ (M-348, 28-10-2026). Medido: la primera vez que sale un jugador en el estadio cuesta ~45 ms (su cara moldeada, su pelo por capas, su
## equipación) y la segunda 1-5 ms, PERO no es por cara de la biblioteca sino por jugador (calentar las 72 caras no adelanta casi nada: −0,2 s). Así que aquí se
## «crea» cada jugador de los que van a salir (el once del club propio al tomar el mando, y los dos onces del próximo partido) con el mismo camino que usa el estadio
## (`PlayerSpawner._crear_jugador`), en un personaje invisible que se borra: de uno en uno, esperando lo que haga falta para no pasar de `MS_POR_FOTOGRAMA` ms de media por
## fotograma. Se detiene sola si el jugador entra en una pantalla pesada (`detener()`: partido, estadio, ciudad). En móvil solo se precalienta el club propio.

const MS_POR_FOTOGRAMA := 1.0

static var _activa: PrecalentarCaras = null
static var _hechos := {}
static var presupuesto_ms := MS_POR_FOTOGRAMA   ## 0 = sin espera (las mediciones)
static var por_fotograma := 1                    ## jugadores por fotograma cuando no hay espera

var _cola: Array = []
var _espera := 0
var _spawner := PlayerSpawner.new()

## El once del club `c` (al tomar el mando).
static func club(c: Club) -> void:
	_poner_en_cola([c], true)

## Los dos onces del próximo partido.
static func partido(local: Club, visita: Club) -> void:
	_poner_en_cola([local, visita], true)

## Al empezar la semana: los onces del partido que toca (en móvil, solo el del club propio).
static func del_mundo(m: Mundo) -> void:
	if m == null:
		return
	if OS.has_feature("mobile"):
		club(m.mi_club())
		return
	var par := m.proximo_partido()
	if par.size() >= 2:
		partido(par[0], par[1])

static func _items(clubes: Array) -> Array:
	var items: Array = []
	for c: Club in clubes:
		if c == null:
			continue
		var once: Dictionary = Puente3D.once(c.once())
		var k := Puente3D.kit(c)
		for jid: Variant in (once.get("jugadores", {}) as Dictionary):
			var clave := "%s|%s" % [jid, c.id]
			if _hechos.has(clave):
				continue
			items.append({"clave": clave, "jid": String(jid), "jug": (once["jugadores"] as Dictionary)[jid], "kit": k})
		## Y los suplentes que salen en la banca (hasta 12).
		for j: Jugador in VistaEstadio.disponibles_fuera_del_once(c, c.once()).slice(0, 12):
			var clave_b := "%s|%s" % [j.id, c.id]
			if not _hechos.has(clave_b):
				items.append({"clave": clave_b, "jid": j.id, "jug": Puente3D.jugador(j), "kit": k})
	return items

static func _poner_en_cola(clubes: Array, delante: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var arbol := Engine.get_main_loop() as SceneTree
	if arbol == null:
		return
	var items := _items(clubes)
	if items.is_empty():
		return
	if not is_instance_valid(_activa):
		_activa = PrecalentarCaras.new()
		_activa.name = "PrecalentarCaras"
		arbol.root.add_child.call_deferred(_activa)
	_activa._cola = (items + _activa._cola) if delante else (_activa._cola + items)

## El jugador entra a una pantalla pesada: se deja de precalentar (y se suelta lo pendiente).
static func detener() -> void:
	if is_instance_valid(_activa):
		_activa._cola.clear()
		_activa.queue_free()
	_activa = null

func _process(_d: float) -> void:
	if _cola.is_empty():
		queue_free()
		_activa = null
		return
	if _espera > 0:
		_espera -= 1
		return
	if not PrecalentarAnim.terminado():
		return   ## las animaciones primero: crear un personaje las necesita hechas
	var t0 := Time.get_ticks_usec()
	for k in (por_fotograma if presupuesto_ms <= 0.0 else 1):
		if _cola.is_empty():
			break
		_uno(_cola.pop_front())
	var ms := float(Time.get_ticks_usec() - t0) / 1000.0
	_espera = 0 if presupuesto_ms <= 0.0 else int(ceil(ms / presupuesto_ms))

func _uno(it: Dictionary) -> void:
	_hechos[it["clave"]] = true
	var jug: Dictionary = it["jug"]
	var k: Dictionary = it["kit"]
	var look := PlayerSpawner._look_de(jug)
	var raiz := Node3D.new()
	raiz.visible = false
	add_child(raiz)
	_spawner._kit_x = k.get("x", {})
	_spawner._crear_jugador(raiz, String(it["jid"]), "MC", "", Color(k.get("c1", "#2b6b45")), Color(k.get("c2", "#ffffff")),
		String(k.get("estilo", "liso")), int(jug.get("dorsal", 0)), look[0], look[1], look[2], Color(0, 0, 0, 0), jug)
	raiz.queue_free()
