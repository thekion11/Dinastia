class_name ReproductorJugadas
extends RefCounted
## Reproduce una jugada del catálogo sobre el visor ya existente.
##
## No es una cámara nueva ni un segundo motor: usa `MatchPlayback._guion_*`
## (la misma puerta que la jugada de gol) y `Balon3D.disparar()` (Magnus).

signal jugada_iniciada(codigo_jugada: String)
signal jugada_completada(resultado: Dictionary)

var en_reproduccion := false
var codigo_actual := ""
var _tiempo_fase: float = 0.0
var _fase_actual: int = 0
var _datos: Dictionary = {}
var _playback: MatchPlayback
var _balon: Balon3D
var _es_local := true
var _impulso_consumido: Array[bool] = []
## Vuelo del balon ya calculado pero todavia sin disparar -ver `_armar_impulso()`-,
## esperando a que la animacion "patear"/"cabezazo" del rematador llegue al
## contacto real, igual que `MatchPlayback._disparo_pendiente`.
var _impulso_pendiente: Dictionary = {}
## Modo ambiente (25-9-2026): la jugada se escenifica entre sucesos del partido
## y se salta la fase de remate -el remate de verdad lo decide la simulación,
## no la jugada-.
var ambiente := false
var _fases: Array = []
## Envío del balón (pase/despeje/remate) esperando el contacto del pie.
var _envio_pendiente: Dictionary = {}

const SLOTS := {
	"ED": ["ED", "SD", "EXT"],
	"EI": ["EI", "SI", "EXT"],
	"LD": ["LD", "LTD", "CAD"],
	"LI": ["LI", "LTI", "CAI"],
	"DC": ["DC", "DLC"],
	"POR": ["POR"],
	"DFC": ["DFC", "DEF"],
	"MC": ["MC", "MCD", "MCO", "MP"],
}

func iniciar(codigo: String, playback: MatchPlayback, balon: Node3D, es_local: bool = true, en_ambiente: bool = false) -> bool:
	_datos = CatalogoJugadas.obtener_definicion(codigo)
	if _datos.is_empty():
		push_error("Jugada no catalogada: " + codigo)
		return false
	if not (balon is Balon3D):
		push_error("ReproductorJugadas necesita un Balon3D")
		return false
	_playback = playback
	_balon = balon as Balon3D
	_es_local = es_local
	ambiente = en_ambiente
	_fase_actual = 0
	_tiempo_fase = 0.0
	codigo_actual = codigo
	en_reproduccion = true
	_fases = []
	for f: Dictionary in (_datos.get("fases", []) as Array):
		## En ambiente no hay remates ni impulsos peligrosos (los de las jugadas
		## antiguas, que acaban en tiro): la jugada se queda en la construcción.
		if ambiente and (bool(f.get("remate", false)) or (f.has("impulso_balon") and bool(f.get("es_peligro", false)))):
			break
		_fases.append(f)
	if _fases.is_empty():
		en_reproduccion = false
		return false
	_impulso_consumido.clear()
	_impulso_pendiente = {}
	_envio_pendiente = {}
	for _i in _fases.size():
		_impulso_consumido.append(false)
	_colocar_balon_inicial()
	_empezar_fase(_fase_dict())
	jugada_iniciada.emit(codigo)
	return true

## Corta la jugada en seco: un suceso real del partido manda sobre ella.
func abortar() -> void:
	if en_reproduccion:
		_impulso_pendiente = {}
		_envio_pendiente = {}
		_finalizar(false)

func avanzar(delta: float) -> void:
	if not en_reproduccion:
		return
	if _fase_actual >= _fases.size():
		_finalizar(true)
		return
	_tiempo_fase += delta
	var fase := _fase_dict()
	if not _impulso_consumido[_fase_actual] and fase.has("impulso_balon"):
		var imp: Vector3 = fase["impulso_balon"]
		var spin: Vector3 = fase.get("spin_balon", Vector3.ZERO)
		if not _es_local:
			imp.z = -imp.z
			imp.x = -imp.x
			spin.y = -spin.y
		_armar_impulso(imp, spin)
		_impulso_consumido[_fase_actual] = true
	if not _impulso_pendiente.is_empty():
		_impulso_pendiente["restante"] -= delta
		if _impulso_pendiente["restante"] <= 0.0:
			_balon.disparar(_impulso_pendiente["imp"], _impulso_pendiente["spin"])
			_impulso_pendiente = {}
	if not _envio_pendiente.is_empty():
		_envio_pendiente["restante"] -= delta
		if _envio_pendiente["restante"] <= 0.0:
			_balon.enviar(_envio_pendiente["destino"], _envio_pendiente["duracion"], _envio_pendiente["altura"], false)
			_envio_pendiente = {}
	if _tiempo_fase >= float(fase.get("duracion", 1.0)):
		_tiempo_fase = 0.0
		_fase_actual += 1
		if _fase_actual < _fases.size():
			_empezar_fase(_fase_dict())

## Lo que pasa al arrancar una fase: todos corren a su sitio, alguien hace su
## gesto y el balón sale -al pie de un compañero, a un punto o a puerta-.
func _empezar_fase(fase: Dictionary) -> void:
	_aplicar_destinos(fase)
	if _playback == null:
		return
	var acciones: Dictionary = fase.get("accion", {})
	for rol: String in acciones:
		var p := _buscar_actor(rol)
		if not p.is_empty():
			_playback._ejecutar_accion(p, String(acciones[rol]), float(fase.get("duracion", 1.0)))
			if String(acciones[rol]) in ["falta_barrida", "falta_empujon"]:
				Sonido.toca("entrada_dura")
	var dur := float(fase.get("duracion", 1.0))
	var altura := float(fase.get("altura", 0.15))
	if fase.has("pase_a"):
		var rol_dest := String(fase["pase_a"])
		var destinos: Dictionary = fase.get("destinos", {})
		var punto := Vector3.ZERO
		if destinos.has(rol_dest):
			punto = _espejo(destinos[rol_dest])
		else:
			var receptor := _buscar_actor(rol_dest)
			if receptor.is_empty() or not is_instance_valid(receptor.get("node")):
				return
			punto = (receptor["node"] as Node3D).position
		_enviar_con_gesto(punto + Vector3(0, Balon3D.RADIO, 0), dur * 0.8, altura, String(fase.get("gesto", "pase")))
	elif fase.has("balon_a"):
		_enviar_con_gesto(_espejo(fase["balon_a"]) + Vector3(0, Balon3D.RADIO, 0), dur * 0.85, altura, "")
	elif bool(fase.get("remate", false)):
		var z_arco := -53.3 if _es_local else 53.3
		var destino := Vector3(randf_range(-2.8, 2.8), randf_range(0.4, 2.0), z_arco)
		_enviar_con_gesto(destino, 0.8, 0.6, "cabezazo" if bool(fase.get("cabeza", false)) else "patear")

## Quien está con el balón hace el gesto (pase, patada, saque de banda) y el
## balón sale en el instante del contacto, no en el primer fotograma.
func _enviar_con_gesto(destino: Vector3, duracion: float, altura: float, gesto: String) -> void:
	var espera := 0.0
	if gesto != "" and is_instance_valid(_balon):
		var quien: Variant = _playback._companero_mas_cercano_al_balon(_es_local, _balon.position)
		if quien != null:
			var n: Node3D = quien.get("node")
			if is_instance_valid(n) and n.position.distance_to(_balon.position) < 4.0:
				_playback._ejecutar_accion(quien, gesto, 0.9)
				n.look_at(Vector3(destino.x, n.position.y, destino.z), Vector3.UP)
				espera = MatchPlayback.CONTACTO_PATADA if gesto != "saque_banda" else 0.9
	_envio_pendiente = {"destino": destino, "duracion": maxf(0.3, duracion), "altura": altura, "restante": espera}
	## El balón largo y el despeje se oyen; el pase corto de cada jugada, no
	## (sería un tic constante).
	if altura >= 3.0:
		Sonido.toca("despeje" if gesto == "" else "pase_largo")

func _espejo(v: Vector3) -> Vector3:
	return v if _es_local else Vector3(-v.x, v.y, -v.z)

## Antes, el balon salia disparado en el mismo instante en que arrancaba la
## fase -el rematador seguia con su animacion de carrera, sin patear nada-.
## Este es el mismo arreglo que ya tiene `MatchPlayback._disparar()` para los
## remates sueltos (goles, tiros libres, corners): la animacion "patear"/
## "cabezazo" arranca YA, pero el balon no sale hasta `CONTACTO_PATADA`
## segundos despues -el tiempo que tarda esa animacion en llegar al golpeo-.
## El catalogo de jugadas no trae un campo "quien patea": se infiere con
## `_companero_mas_cercano_al_balon()`, que en la practica es siempre quien
## acaba de recibir el pase de la fase anterior -o el lateral en cuyo pie
## `_colocar_balon_inicial()` deja el balon, en la fase 0-.
func _armar_impulso(imp: Vector3, spin: Vector3) -> void:
	if _playback != null and is_instance_valid(_balon):
		var rematador: Variant = _playback._companero_mas_cercano_al_balon(_es_local, _balon.position)
		if rematador != null:
			var es_aereo: bool = imp.y >= 4.0
			_playback._ejecutar_accion(rematador, "cabezazo" if es_aereo else "patear", 0.9)
			var n: Node3D = rematador.get("node")
			if is_instance_valid(n) and (absf(imp.x) > 0.01 or absf(imp.z) > 0.01):
				n.look_at(n.position + Vector3(imp.x, 0, imp.z), Vector3.UP)
			_impulso_pendiente = {"imp": imp, "spin": spin, "restante": MatchPlayback.CONTACTO_PATADA}
			return
	_balon.disparar(imp, spin)

func _fase_dict() -> Dictionary:
	if _fase_actual < 0 or _fase_actual >= _fases.size():
		return {}
	return _fases[_fase_actual]

## Dónde empieza el balón. Con `rol`, le llega al pie de ese jugador con un
## pase -nada de teletransportes-; con `balon`, va hacia ese punto (lo tiene el
## rival). Las jugadas antiguas sin inicio siguen empezando en banda derecha.
func _colocar_balon_inicial() -> void:
	if not is_instance_valid(_balon):
		return
	var inicio: Dictionary = _datos.get("inicio", {})
	if inicio.has("rol"):
		var p := _buscar_actor(String(inicio["rol"]))
		if not p.is_empty() and is_instance_valid(p.get("node")):
			var pos: Vector3 = (p["node"] as Node3D).position
			_balon.enviar(Vector3(pos.x, Balon3D.RADIO, pos.z), 0.5, 0.2, false)
			return
	if inicio.has("balon"):
		var b := _espejo(inicio["balon"])
		_balon.enviar(Vector3(b.x, Balon3D.RADIO, b.z), 0.6, 0.3, false)
		return
	if ambiente:
		return
	## Cutback y la mayoría de ataques arrancan en banda derecha, tercio rival.
	var z0 := -22.0 if _es_local else 22.0
	_balon.position = Vector3(16.0 if _es_local else -16.0, Balon3D.RADIO, z0)
	_balon.detener()

func _aplicar_destinos(fase: Dictionary) -> void:
	if _playback == null:
		return
	var destinos: Dictionary = fase.get("destinos", {})
	for clave in destinos.keys():
		var p := _buscar_actor(String(clave))
		if p.is_empty():
			continue
		var dest: Vector3 = destinos[clave]
		if not _es_local:
			dest.x = -dest.x
			dest.z = -dest.z
		var pid = p.get("id")
		_playback._guion_destino[pid] = dest
		_playback._guion_hasta[pid] = _playback.elapsed + float(fase.get("duracion", 1.0)) + 0.35

func _buscar_actor(rol: String) -> Dictionary:
	if _playback == null:
		return {}
	var aceptados: Array = SLOTS.get(rol, [rol])
	for p in _playback.players:
		if bool(p.get("arbitro", false)):
			continue
		if bool(p.get("es_local")) != _es_local:
			continue
		if str(p.get("slot_code", "")) in aceptados:
			return p
	## Si el once no trae ese puesto exacto, el más adelantado del mismo equipo.
	var mejor := {}
	var mejor_z := 9999.0 if _es_local else -9999.0
	for p in _playback.players:
		if bool(p.get("arbitro", false)) or bool(p.get("es_local")) != _es_local:
			continue
		var n: Node3D = p.get("node")
		if not is_instance_valid(n):
			continue
		if _es_local and n.position.z < mejor_z:
			mejor_z = n.position.z
			mejor = p
		elif not _es_local and n.position.z > mejor_z:
			mejor_z = n.position.z
			mejor = p
	return mejor

func _finalizar(exito: bool) -> void:
	en_reproduccion = false
	jugada_completada.emit({"exito": exito, "jugada": codigo_actual})
	codigo_actual = ""
