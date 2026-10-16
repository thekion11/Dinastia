class_name EstadisticasVivo
extends RefCounted
## LAS ESTADÍSTICAS DEL PARTIDO EN VIVO (16-10-2026, pendiente de la línea del
## motor real: «estadísticas a pedido»). Lo que el acta ya cuenta (posesión,
## remates, córners, faltas) sale del `Partido`; lo que solo se ve en el césped
## lo apunta esto mirando el motor SIN tocarlo: dónde se tiró cada remate y cómo
## acabó (mapa de tiros y xG por remate), las tarjetas de cada equipo y por qué
## zonas movió el balón cada uno (mapa de calor).
##
## Coordenadas del motor: el local ataca hacia +Z, el campo mide 105 x 68
## (x en [-34, 34], z en [-52,5, 52,5]).

const LARGO := 52.5
const ANCHO := 34.0
## La rejilla del mapa de calor: columnas a lo largo, filas a lo ancho.
const COLS := 12
const FILAS := 8
const CADA := 0.25   ## segundos de juego entre muestras

## Cada remate: {"local": bool, "pos": Vector2(x, z), "min": int, "xg": float, "res": "gol|atajada|poste|fallo|"}
var tiros: Array = []
var amarillas := [0, 0]
var rojas := [0, 0]
## [equipo][fila * COLS + col] = muestras con el balón en esa zona.
var calor: Array = [PackedInt32Array(), PackedInt32Array()]
var _t_muestra := 0.0
var _tiro_t := -1.0

func _init() -> void:
	for i in 2:
		var a := PackedInt32Array()
		a.resize(COLS * FILAS)
		calor[i] = a

## xG sencillo por distancia y ángulo a la portería (curva logística ajustada a
## valores de referencia en juego: a 6 m centrado ≈ 0,5, a 11 m ≈ 0,23, frontal
## del área ≈ 0,1, a 25 m ≈ 0,04, a 30 m ≈ 0,02; el penal va aparte, 0,76).
static func xg_de(pos: Vector2, ataca_local: bool) -> float:
	var arco := Vector2(0.0, LARGO if ataca_local else -LARGO)
	var d := pos.distance_to(arco)
	## Ángulo con el que se ve la portería (7,32 m de boca).
	var a1 := Vector2(-3.66, arco.y) - pos
	var a2 := Vector2(3.66, arco.y) - pos
	var ang := absf(a1.angle_to(a2))
	var z := -1.1 - 0.105 * d + 1.6 * ang
	return clampf(1.0 / (1.0 + exp(-z)), 0.01, 0.8)

## Una muestra por fotograma del partido (solo cuenta con el juego vivo).
func muestrear(motor: MotorJugable, delta: float) -> void:
	if motor == null or motor.balon == null:
		return
	## Un remate nuevo: el motor deja `_tiro_vivo` con el instante del golpeo.
	var tv: Dictionary = motor.get("_tiro_vivo") if motor.get("_tiro_vivo") is Dictionary else {}
	if not tv.is_empty() and float(tv.get("t", -1.0)) != _tiro_t:
		_tiro_t = float(tv.get("t", -1.0))
		var p: Dictionary = tv.get("p", {})
		var n: Node3D = p.get("node")
		var donde: Vector3 = n.position if is_instance_valid(n) else motor.balon.position
		var loc := bool(p.get("es_local", true))
		anotar_tiro(loc, Vector2(donde.x, donde.z), motor.minuto())
		## El penal tiene su propio xG (≈0,76), no el de un tiro a 11 m en juego.
		if String(motor.saque.get("tipo", "")) == "penal" and absf(LARGO - absf(donde.z) - 11.0) < 2.0 and absf(donde.x) < 2.0:
			(tiros[-1] as Dictionary)["xg"] = 0.76
	if motor.estado != "juego":
		return
	_t_muestra -= delta
	if _t_muestra > 0.0:
		return
	_t_muestra = CADA
	var dueno: Dictionary = motor.poseedor if not motor.poseedor.is_empty() else motor.ultimo_toque
	if dueno.is_empty():
		return
	var b := motor.balon.position
	anotar_calor(0 if bool(dueno.get("es_local", true)) else 1, Vector2(b.x, b.z))

func anotar_tiro(local: bool, pos: Vector2, minuto: int) -> void:
	tiros.append({"local": local, "pos": pos, "min": minuto, "xg": xg_de(pos, local), "res": ""})

func anotar_calor(eq: int, pos: Vector2) -> void:
	var c := clampi(int((pos.y + LARGO) / (2.0 * LARGO) * COLS), 0, COLS - 1)
	var f := clampi(int((pos.x + ANCHO) / (2.0 * ANCHO) * FILAS), 0, FILAS - 1)
	var a: PackedInt32Array = calor[eq]
	a[f * COLS + c] += 1
	calor[eq] = a

## Cómo acabó el último remate de ese equipo que aún no tenía resultado.
## `pos_tirador`: dónde estaba quien remató, por si el remate empezó y acabó en
## el mismo paso del motor (un tiro bloqueado a bocajarro) y no se llegó a ver.
func cerrar_tiro(local: bool, res: String, pos_balon: Vector3 = Vector3.ZERO, pos_tirador: Vector3 = Vector3.INF) -> void:
	for i in range(tiros.size() - 1, -1, -1):
		var t: Dictionary = tiros[i]
		if bool(t["local"]) == local and String(t["res"]) == "":
			t["res"] = res
			return
	## Un gol sin remate apuntado (rebote, en propia): se apunta donde está el balón.
	if res == "gol":
		anotar_tiro(local, Vector2(pos_balon.x, pos_balon.z), -1)
		(tiros[-1] as Dictionary)["res"] = "gol"
	elif pos_tirador != Vector3.INF:
		anotar_tiro(local, Vector2(pos_tirador.x, pos_tirador.z), -1)
		(tiros[-1] as Dictionary)["res"] = res

func tarjeta(local: bool, roja: bool) -> void:
	var i := 0 if local else 1
	if roja:
		rojas[i] += 1
	else:
		amarillas[i] += 1

func xg(local: bool) -> float:
	var s := 0.0
	for t: Dictionary in tiros:
		if bool(t["local"]) == local:
			s += float(t["xg"])
	return s

func n_tiros(local: bool) -> int:
	var n := 0
	for t: Dictionary in tiros:
		if bool(t["local"]) == local:
			n += 1
	return n

## La tabla completa, [local, visita] en cada fila. Junta el acta del `Partido`
## (lo que va a la ficha) con lo que se midió en el césped.
func resumen(p: Partido, motor: MotorJugable) -> Array:
	var filas: Array = []
	if p != null:
		filas.append(["Posesión", "%d%%" % int(round(p.posesion_local)), "%d%%" % int(round(100.0 - p.posesion_local)),
			p.posesion_local, 100.0 - p.posesion_local])
		filas.append(["Tiros", str(p.remates_local), str(p.remates_visita), float(p.remates_local), float(p.remates_visita)])
		filas.append(["Tiros a puerta", str(p.tiros_puerta_local), str(p.tiros_puerta_visita),
			float(p.tiros_puerta_local), float(p.tiros_puerta_visita)])
	var xl := xg(true)
	var xv := xg(false)
	if tiros.is_empty() and p != null:
		xl = p.xg_local
		xv = p.xg_visita
	filas.append(["Goles esperados (xG)", "%.2f" % xl, "%.2f" % xv, xl, xv])
	if motor != null:
		var pl := int(motor.pases[0])
		var pv := int(motor.pases[1])
		filas.append(["Pases", str(pl), str(pv), float(pl), float(pv)])
		var al := 100.0 * float(motor.pases_ok[0]) / float(pl) if pl > 0 else 0.0
		var av := 100.0 * float(motor.pases_ok[1]) / float(pv) if pv > 0 else 0.0
		filas.append(["Precisión de pase", "%d%%" % int(round(al)), "%d%%" % int(round(av)), al, av])
	if p != null:
		filas.append(["Córners", str(p.corners_local), str(p.corners_visita), float(p.corners_local), float(p.corners_visita)])
		filas.append(["Faltas", str(p.faltas_local), str(p.faltas_visita), float(p.faltas_local), float(p.faltas_visita)])
	if motor != null:
		filas.append(["Fueras de juego", str(motor.fueras_de_juego[0]), str(motor.fueras_de_juego[1]),
			float(motor.fueras_de_juego[0]), float(motor.fueras_de_juego[1])])
	filas.append(["Tarjetas amarillas", str(amarillas[0]), str(amarillas[1]), float(amarillas[0]), float(amarillas[1])])
	filas.append(["Tarjetas rojas", str(rojas[0]), str(rojas[1]), float(rojas[0]), float(rojas[1])])
	return filas

## Las 3-4 filas del rótulo de la tele, según el momento.
func para_rotulo(p: Partido, motor: MotorJugable, claves: Array) -> Array:
	var sal: Array = []
	for f: Array in resumen(p, motor):
		if String(f[0]) in claves:
			sal.append(f)
	return sal
