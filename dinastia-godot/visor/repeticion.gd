class_name Repeticion
extends Node
## LA REPETICIÓN DEL GOL (25-9-2026, plan maestro B3). Como en una transmisión:
## tras el gol, la jugada otra vez, en cámara lenta y desde otros ángulos.
##
## CÓMO. Mientras se juega, `_process` guarda 20 veces por segundo el estado de
## cada jugador (transform, animación y punto de la animación) y del balón, y
## conserva los últimos `SEGUNDOS_GUARDADOS`. `reproducir()`:
##   1. fotografía el estado EN VIVO de todos (para devolverlo luego tal cual);
##   2. recorre los fotogramas guardados a `VELOCIDAD` (0,5 = la mitad), con
##      dos cámaras propias: primero detrás del arco donde terminó el balón y
##      después a ras de césped siguiéndolo;
##   3. devuelve a cada uno a su estado en vivo y emite `terminada`.
## Quien la usa (`VistaEstadio`) congela el reloj del partido mientras tanto:
## la repetición no juega minutos ni toca `Azar`.

signal terminada

const HZ := 20.0
const SEGUNDOS_GUARDADOS := 12.0
const VELOCIDAD := 0.5

var reproduciendo := false
var _jugadores: Array = []     ## los diccionarios de `_en_campo` (node, anim)
var _balon: Node3D
var _cuadros: Array = []       ## [{t, j: [[Transform3D, anim, pos]], b: Transform3D}]
var _t := 0.0
var _prox := 0.0
var _vivo: Array = []
var _cams: Array[Camera3D] = []
var _cam_previa: Camera3D
var _rep_t := 0.0
var _rep_desde := 0.0
var _rep_hasta := 0.0

func setup(jugadores: Array, balon: Node3D) -> void:
	_jugadores = jugadores
	_balon = balon

func _process(delta: float) -> void:
	if reproduciendo:
		_avanzar_repeticion(delta)
		return
	_t += delta
	if _t < _prox:
		return
	_prox = _t + 1.0 / HZ
	var j: Array = []
	for f: Dictionary in _jugadores:
		var n: Node3D = f.get("node")
		var ap: AnimationPlayer = f.get("anim")
		if not is_instance_valid(n):
			j.append(null)
			continue
		var anim := ""
		var pos := 0.0
		if is_instance_valid(ap) and ap.current_animation != "":
			anim = ap.current_animation
			pos = ap.current_animation_position
		j.append([n.global_transform, anim, pos])
	_cuadros.append({"t": _t, "j": j, "b": _balon.global_transform if is_instance_valid(_balon) else Transform3D.IDENTITY})
	while not _cuadros.is_empty() and _t - float(_cuadros[0]["t"]) > SEGUNDOS_GUARDADOS:
		_cuadros.pop_front()

## Cuántos segundos hay guardados (para las pruebas).
func segundos_guardados() -> float:
	if _cuadros.size() < 2:
		return 0.0
	return float(_cuadros[-1]["t"]) - float(_cuadros[0]["t"])

## Repite los últimos `segundos` (o los que haya). Devuelve false si no hay nada.
func reproducir(segundos: float = 8.0) -> bool:
	if reproduciendo or _cuadros.size() < int(HZ):
		return false
	reproduciendo = true
	## Estado en vivo, para devolverlo tal cual al terminar.
	_vivo.clear()
	for f: Dictionary in _jugadores:
		var n: Node3D = f.get("node")
		var ap: AnimationPlayer = f.get("anim")
		if not is_instance_valid(n):
			_vivo.append(null)
			continue
		var anim: String = ap.current_animation if is_instance_valid(ap) else ""
		var pos: float = ap.current_animation_position if is_instance_valid(ap) and anim != "" else 0.0
		var vel: float = ap.speed_scale if is_instance_valid(ap) else 1.0
		_vivo.append([n.global_transform, anim, pos, vel])
		if is_instance_valid(ap):
			ap.speed_scale = 0.0
	_vivo.append(_balon.global_transform if is_instance_valid(_balon) else Transform3D.IDENTITY)
	_rep_hasta = float(_cuadros[-1]["t"])
	_rep_desde = maxf(float(_cuadros[0]["t"]), _rep_hasta - segundos)
	_rep_t = _rep_desde
	_montar_camaras()
	return true

func _montar_camaras() -> void:
	_cam_previa = get_viewport().get_camera_3d()
	var fin: Transform3D = _cuadros[-1]["b"]
	var lado := signf(fin.origin.z) if absf(fin.origin.z) > 1.0 else 1.0
	## 1) Detrás del arco donde terminó la jugada, alta, mirando al área.
	var c1 := Camera3D.new()
	c1.name = "RepeticionArco"
	c1.fov = 48.0
	add_child(c1)
	c1.global_position = Vector3(fin.origin.x * 0.3, 7.5, lado * 64.0)
	## 2) A ras de césped, desde el costado, siguiendo el balón con zoom.
	var c2 := Camera3D.new()
	c2.name = "RepeticionRas"
	c2.fov = 30.0
	add_child(c2)
	## Dentro del campo y algo alta: en la banda misma camina el juez de
	## línea y tapaba media pantalla.
	c2.global_position = Vector3(-29.0, 2.4, fin.origin.z * 0.7)
	_cams = [c1, c2]
	c1.current = true

func _avanzar_repeticion(delta: float) -> void:
	_rep_t += delta * VELOCIDAD
	var mitad := _rep_desde + (_rep_hasta - _rep_desde) * 0.5
	if _cams.size() == 2 and _rep_t >= mitad and not _cams[1].current:
		_cams[1].current = true
	var cuadro := _cuadro_en(_rep_t)
	if cuadro.is_empty():
		return
	var js: Array = cuadro["j"]
	for i in mini(js.size(), _jugadores.size()):
		var e: Variant = js[i]
		if e == null:
			continue
		var f: Dictionary = _jugadores[i]
		var n: Node3D = f.get("node")
		var ap: AnimationPlayer = f.get("anim")
		if not is_instance_valid(n):
			continue
		n.global_transform = (e as Array)[0]
		if is_instance_valid(ap) and String(e[1]) != "" and ap.has_animation(String(e[1])):
			if ap.current_animation != String(e[1]):
				ap.play(String(e[1]))
			ap.seek(float(e[2]), true)
	if is_instance_valid(_balon):
		_balon.global_transform = cuadro["b"]
		for c: Camera3D in _cams:
			if c.global_position.distance_to(_balon.global_position) > 0.5:
				c.look_at(_balon.global_position, Vector3.UP)
	if _rep_t >= _rep_hasta:
		_terminar()

## El fotograma guardado más cercano a `t` (a 20 Hz no hace falta interpolar
## para una cámara lenta a la mitad: se ven 40 cuadros por segundo de juego).
func _cuadro_en(t: float) -> Dictionary:
	var mejor: Dictionary = {}
	for c: Dictionary in _cuadros:
		if float(c["t"]) <= t:
			mejor = c
		else:
			break
	return mejor

func _terminar() -> void:
	for i in mini(_vivo.size() - 1, _jugadores.size()):
		var e: Variant = _vivo[i]
		if e == null:
			continue
		var f: Dictionary = _jugadores[i]
		var n: Node3D = f.get("node")
		var ap: AnimationPlayer = f.get("anim")
		if not is_instance_valid(n):
			continue
		n.global_transform = (e as Array)[0]
		if is_instance_valid(ap):
			if String(e[1]) != "" and ap.has_animation(String(e[1])):
				ap.play(String(e[1]))
				ap.seek(float(e[2]), true)
			ap.speed_scale = float(e[3])
	if is_instance_valid(_balon):
		_balon.global_transform = _vivo[-1]
	for c: Camera3D in _cams:
		c.queue_free()
	_cams.clear()
	if is_instance_valid(_cam_previa):
		_cam_previa.current = true
	reproduciendo = false
	## Lo grabado durante la jugada ya se repitió: se empieza a grabar de cero.
	_cuadros.clear()
	terminada.emit()
