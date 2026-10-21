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

## Cada remate: {"local": bool, "pos": Vector2(x, z), "min": int, "xg": float, "res": "gol|atajada|poste|fallo|", "asist": id del pase previo (si lo hubo)}
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
		## xA (M-137): el compañero que le dio el último pase se lleva el xG del
		## remate como «asistencia esperada».
		var pase: Dictionary = motor.penultimo_toque
		if not pase.is_empty() and pase != p and bool(pase.get("es_local", not loc)) == loc:
			(tiros[-1] as Dictionary)["asist"] = String(pase.get("id", ""))
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

## El VAR anula: el último gol de ese equipo pasa a "anulado" en el mapa.
func anular_gol(local: bool) -> void:
	for i in range(tiros.size() - 1, -1, -1):
		var t: Dictionary = tiros[i]
		if bool(t["local"]) == local and String(t["res"]) == "gol":
			t["res"] = "anulado"
			return

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

## Asistencias esperadas: el xG de los remates que salieron de un pase.
func xa(local: bool) -> float:
	var s := 0.0
	for t: Dictionary in tiros:
		if bool(t["local"]) == local and String(t.get("asist", "")) != "":
			s += float(t["xg"])
	return s

## xA de cada jugador (id → xA), para la ficha del partido.
func xa_por_jugador() -> Dictionary:
	var d := {}
	for t: Dictionary in tiros:
		var a := String(t.get("asist", ""))
		if a != "":
			d[a] = float(d.get(a, 0.0)) + float(t["xg"])
	return d

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
	## Lo que el motor mide al momento (posesión, córners, faltas) se lee de
	## él: el acta solo lo copia una vez por minuto.
	var pos_l := float(motor.posesion_local()) if motor != null else (p.posesion_local if p != null else 50.0)
	if p != null or motor != null:
		filas.append(["Posesión", "%d%%" % int(round(pos_l)), "%d%%" % int(round(100.0 - pos_l)), pos_l, 100.0 - pos_l])
	if p != null:
		filas.append(["Tiros", str(p.remates_local), str(p.remates_visita), float(p.remates_local), float(p.remates_visita)])
		filas.append(["Tiros a puerta", str(p.tiros_puerta_local), str(p.tiros_puerta_visita),
			float(p.tiros_puerta_local), float(p.tiros_puerta_visita)])
	var xl := xg(true)
	var xv := xg(false)
	if tiros.is_empty() and p != null:
		xl = p.xg_local
		xv = p.xg_visita
	filas.append(["Goles esperados (xG)", "%.2f" % xl, "%.2f" % xv, xl, xv])
	if not tiros.is_empty():
		var al_ := xa(true)
		var av_ := xa(false)
		filas.append(["Asistencias esperadas (xA)", "%.2f" % al_, "%.2f" % av_, al_, av_])
	if motor != null:
		var pl := int(motor.pases[0])
		var pv := int(motor.pases[1])
		filas.append(["Pases", str(pl), str(pv), float(pl), float(pv)])
		var al := 100.0 * float(motor.pases_ok[0]) / float(pl) if pl > 0 else 0.0
		var av := 100.0 * float(motor.pases_ok[1]) / float(pv) if pv > 0 else 0.0
		filas.append(["Precisión de pase", "%d%%" % int(round(al)), "%d%%" % int(round(av)), al, av])
	var co: Array = motor.corners if motor != null else ([p.corners_local, p.corners_visita] if p != null else [])
	var fa: Array = motor.faltas if motor != null else ([p.faltas_local, p.faltas_visita] if p != null else [])
	if not co.is_empty():
		filas.append(["Córners", str(co[0]), str(co[1]), float(co[0]), float(co[1])])
		filas.append(["Faltas", str(fa[0]), str(fa[1]), float(fa[0]), float(fa[1])])
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

## EXPORTAR A CSV (M-162, 20-10-2026): al terminar un partido con motor, la
## tabla y cada remate quedan en `user://estadisticas/` para mirarlos fuera
## del juego (hoja de cálculo). Devuelve la ruta (o "" si no se pudo).
func a_csv(p: Partido, motor: MotorJugable) -> String:
	var l := PackedStringArray()
	var loc := p.local.nombre if p != null and p.local != null else "Local"
	var vis := p.visita.nombre if p != null and p.visita != null else "Visita"
	l.append("dato;%s;%s" % [loc.replace(";", ","), vis.replace(";", ",")])
	for f: Array in resumen(p, motor):
		l.append("%s;%s;%s" % [f[0], f[1], f[2]])
	l.append("")
	l.append("remate;equipo;minuto;x;z;xg;resultado;pase_de")
	for i in tiros.size():
		var t: Dictionary = tiros[i]
		var pos: Vector2 = t["pos"]
		l.append("%d;%s;%d;%.1f;%.1f;%.3f;%s;%s" % [i + 1, "local" if bool(t["local"]) else "visita", int(t["min"]),
			pos.x, pos.y, float(t["xg"]), String(t["res"]), String(t.get("asist", ""))])
	DirAccess.make_dir_recursive_absolute("user://estadisticas")
	var nombre := "user://estadisticas/%s_%s_%s.csv" % [Time.get_datetime_string_from_system().replace(":", "-"),
		loc.to_snake_case().left(20), vis.to_snake_case().left(20)]
	var f := FileAccess.open(nombre, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string("\n".join(l) + "\n")
	f.close()
	return nombre
