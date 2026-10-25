extends Node
## SONDA DE PIES Y TRANSICIONES DEL PARTIDO 3D (pani, 25-10-2026). Juega el
## partido de verdad (motor + vista, como `pruebas/sonda_fisica_partido.gd`) y
## mide, fotograma a fotograma y POR CLIP, lo que se ve de la animación:
##   - PATINAJE: el pie de apoyo (la bola del pie a menos de 4 cm del césped en
##     dos fotogramas seguidos) no debería moverse; se mide cuánto resbala (m/s).
##   - SALTOS DE POSE: un hueso grande (pelvis, columna, muslos, brazos) que
##     gira más de 25° de un fotograma al siguiente (a 30 fps, 750°/s) es un
##     corte, no un movimiento; se cuentan y se apunta entre qué clips pasó.
##   - PARPADEO: cambios de clip de locomoción en menos de 0,3 s (trotar →
##     correr → trotar), que hacen temblar las piernas.
##   - PIES HUNDIDOS: la bola del pie más de 4 cm bajo el césped.
##   godot --headless --path . --fixed-fps 30 res://pruebas/ideas/pani_sonda_pies.tscn
##   (FOTOGRAMAS=n, por defecto 600; DETALLE=1 imprime los saltos.)
const DT := 1.0 / 30.0
const HUESOS := ["pelvis", "spine_02", "thigh_l", "thigh_r", "calf_l", "calf_r", "upperarm_l", "upperarm_r", "Head"]
const LOCO := ["parado", "caminar", "trotar", "correr", "conducir", "conducir_espejo", "trotar_atras", "marcar",
	"marcar_espejo", "portero_listo", "portero_lateral_der", "portero_lateral_izq", "cansado"]
var FOTOGRAMAS := int(OS.get_environment("FOTOGRAMAS")) if OS.get_environment("FOTOGRAMAS") != "" else 600
var _n := 0
var _vista: Node
var _partido: Partido
var _prev := {}   ## id de nodo -> {pies, rot, anim, t_cambio}
var _por_clip := {}   ## anim -> [muestras de apoyo, suma del patinaje, suma de la velocidad del cuerpo]
var _saltos := {}
var _parpadeos := 0
var _cambios := 0
var _hundidos := 0
var _muestras := 0
var _t := 0.0

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	var par := m.proximo_partido()
	_partido = Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.9, par[1], _partido)

func _process(_d: float) -> void:
	_n += 1
	var intro: Variant = _vista.get("_intro")
	if intro != null and is_instance_valid(intro) and intro.activa:
		intro.terminar()
		return
	var cer: Variant = _vista.get("_ceremonia")
	if cer != null and is_instance_valid(cer) and cer.activa:
		cer.terminar()
		return
	if _n < 60:
		return
	_t += DT
	var mo: Variant = _vista.get("_motor")
	if mo == null:
		return
	for p: Dictionary in mo.jugadores:
		_medir(p)
	if _n >= 60 + FOTOGRAMAS:
		_informe()
		get_tree().quit()

func _medir(p: Dictionary) -> void:
	var nd: Node3D = p.get("node")
	if nd == null or not is_instance_valid(nd):
		return
	var esq := FutbolistaQ.esqueleto_de(nd)
	if esq == null:
		return
	var ap: AnimationPlayer = p.get("anim")
	var anim := String(ap.current_animation) if is_instance_valid(ap) else ""
	var g := esq.global_transform
	var pies: Array[Vector3] = []
	for b: String in ["ball_l", "ball_r"]:
		pies.append(g * esq.get_bone_global_pose(esq.find_bone(b)).origin)
	var rot := {}
	for b: String in HUESOS:
		var i := esq.find_bone(b)
		if i >= 0:
			rot[b] = esq.get_bone_global_pose(i).basis.get_rotation_quaternion()
	var id := nd.get_instance_id()
	_muestras += 1
	for q: Vector3 in pies:
		if q.y < -0.04:
			_hundidos += 1
	if _prev.has(id):
		var pr: Dictionary = _prev[id]
		var antes: Array = pr["pies"]
		var cuerpo := Vector2(nd.global_position.x - float(pr["x"]), nd.global_position.z - float(pr["z"])).length() / DT
		for k in 2:
			var a0: Vector3 = antes[k]
			var a1: Vector3 = pies[k]
			if a0.y < 0.04 and a1.y < 0.04 and cuerpo < 11.0:
				var desliz := Vector2(a1.x - a0.x, a1.z - a0.z).length() / DT
				var c: Array = _por_clip.get(anim, [0, 0.0, 0.0])
				c[0] += 1
				c[1] += desliz
				c[2] += cuerpo
				_por_clip[anim] = c
		var mismo_clip := String(pr["anim"]) == anim
		for b: String in rot:
			if (pr["rot"] as Dictionary).has(b):
				var ang := rad_to_deg((rot[b] as Quaternion).angle_to(pr["rot"][b]))
				if ang > 25.0:
					var clave := "%s %s→%s" % [b, pr["anim"], anim] if not mismo_clip else "%s dentro de %s" % [b, anim]
					_saltos[clave] = int(_saltos.get(clave, 0)) + 1
		if not mismo_clip:
			_cambios += 1
			if LOCO.has(anim) and LOCO.has(String(pr["anim"])) and _t - float(pr["t_cambio"]) < 0.3:
				_parpadeos += 1
	var t_cambio: float = _t
	if _prev.has(id) and String(_prev[id]["anim"]) == anim:
		t_cambio = float(_prev[id]["t_cambio"])
	_prev[id] = {"pies": pies, "rot": rot, "anim": anim, "t_cambio": t_cambio, "x": nd.global_position.x, "z": nd.global_position.z}

func _informe() -> void:
	print("===== PIES Y TRANSICIONES (%d muestras jugador-fotograma) =====" % _muestras)
	var total_ap := 0
	var total_des := 0.0
	var ks := _por_clip.keys()
	ks.sort_custom(func(x: String, y: String) -> bool: return int(_por_clip[x][0]) > int(_por_clip[y][0]))
	for k: String in ks:
		var c: Array = _por_clip[k]
		total_ap += int(c[0])
		total_des += float(c[1])
		print("  CLIP %-22s apoyos %6d  patina %.2f m/s  cuerpo a %.2f m/s" % [k, c[0], float(c[1]) / maxf(1, c[0]), float(c[2]) / maxf(1, c[0])])
	print("  PATINAJE MEDIO DEL PIE DE APOYO: %.3f m/s (%d apoyos)" % [total_des / maxf(1, total_ap), total_ap])
	var ns := 0
	for k: String in _saltos:
		ns += int(_saltos[k])
	print("  SALTOS DE POSE (>25° en un fotograma): %d" % ns)
	var ss := _saltos.keys()
	ss.sort_custom(func(x: String, y: String) -> bool: return int(_saltos[x]) > int(_saltos[y]))
	for k: String in ss.slice(0, 25):
		print("    SALTO %5d  %s" % [int(_saltos[k]), k])
	print("  CAMBIOS DE CLIP: %d   PARPADEOS DE LOCOMOCIÓN (<0,3 s): %d" % [_cambios, _parpadeos])
	print("  PIES HUNDIDOS (>4 cm): %d" % _hundidos)
	print("===== FIN SONDA PIES =====")
