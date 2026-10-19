extends Node
## SONDA DE FÍSICA DEL PARTIDO 3D (13-10-2026, «las físicas siguen siendo de lo
## peor»). Juega el partido a ritmo fijo y MIDE, fotograma a fotograma:
##   - jugadores que se atraviesan (centros a menos de 0,45 m);
##   - velocidades y aceleraciones imposibles para una persona;
##   - giros bruscos (más de 720°/s);
##   - el balón que se teletransporta (más de 1,2 m en un fotograma), que se
##     hunde en el césped o que atraviesa a un jugador a la altura del cuerpo;
## y guarda una tira de fotogramas (fisica_tira.png) para mirarla.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --fixed-fps 30 --resolution 960x540 res://pruebas/sonda_fisica_partido.tscn
const DT := 1.0 / 30.0
var FOTOGRAMAS := int(OS.get_environment("FOTOGRAMAS")) if OS.get_environment("FOTOGRAMAS") != "" else 600
var _n := 0
var _vista: VistaEstadio
var _partido: Partido
var _prev := {}
var _vprev := {}
var _rprev := {}
var _bprev := Vector3.INF
var _c := {"solape": 0, "vel": 0, "acel": 0, "giro": 0, "tele": 0, "hundido": 0, "cuerpo": 0, "muestras": 0, "pares": 0}
var _vmax := 0.0
var _amax := 0.0
var _tira: Array[Image] = []
var _acel_tipos := {}   ## DEPURAR_ACEL=1: de dónde salen los tirones

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
	if _n % 30 == 0:
		print("F ", _n, " t=", Time.get_ticks_msec() / 1000)
	var intro: Variant = _vista.get("_intro")
	if intro != null and is_instance_valid(intro) and intro.activa:
		intro.terminar()
		return
	## La ceremonia (filas, himno, sorteo) también se salta: se mide el juego.
	var cer: Variant = _vista.get("_ceremonia")
	if cer != null and is_instance_valid(cer) and cer.activa:
		cer.terminar()
		return
	if _n < 60:
		return
	var gente: Array = []
	for p: Dictionary in _vista.get("_en_campo"):
		var nd: Node3D = p.get("node")
		if nd != null and is_instance_valid(nd) and not bool(p.get("arbitro", false)):
			gente.append(nd)
	_c["muestras"] += 1
	for i in gente.size():
		var a: Node3D = gente[i]
		var pa := a.global_position
		var id := a.get_instance_id()
		if _prev.has(id):
			var v: Vector3 = (pa - _prev[id]) / DT
			v.y = 0.0
			var vel := v.length()
			_vmax = maxf(_vmax, vel)
			if vel > 10.5:
				_c["vel"] += 1
				if OS.get_environment("DEPURAR_VEL") != "" and _c["vel"] <= 40:
					var mo: Variant = _vista.get("_motor")
					print("VEL %.1f m/s %s estado=%s" % [vel, a.name, String(mo.estado) if mo != null else "?"])
			if _vprev.has(id):
				var ac: float = (v - (_vprev[id] as Vector3)).length() / DT
				_amax = maxf(_amax, ac)
				if ac > 25.0 and vel < 10.5:
					_c["tiron"] = int(_c.get("tiron", 0)) + 1
				if ac > 15.0 and vel < 10.5:
					_c["acel"] += 1
					if OS.get_environment("DEPURAR_ACEL") != "":
						var mo: Variant = _vista.get("_motor")
						var pj := {}
						if mo != null:
							for q: Dictionary in mo.jugadores:
								if q.get("node") == a:
									pj = q
						var clave := "%s %s%s%s%s" % [String(mo.estado) if mo != null else "?",
							"emp " if (pj.get("empujon", Vector3.ZERO) as Vector3) != Vector3.ZERO else "",
							"gesto " if float(pj.get("gesto_hasta", 0.0)) > float(mo.t) else "",
							"dueño " if mo != null and mo.poseedor == pj else "",
							"rango%d" % (int(ac / 15.0) * 15)]
						_acel_tipos[clave] = int(_acel_tipos.get(clave, 0)) + 1
			_vprev[id] = v
		if _rprev.has(id):
			var dr: float = absf(wrapf(a.global_rotation.y - float(_rprev[id]), -PI, PI)) / DT
			if dr > deg_to_rad(720.0):
				_c["giro"] += 1
		_rprev[id] = a.global_rotation.y
		_prev[id] = pa
		for j in range(i + 1, gente.size()):
			var b: Node3D = gente[j]
			_c["pares"] += 1
			if Vector2(pa.x - b.global_position.x, pa.z - b.global_position.z).length() < 0.45:
				_c["solape"] += 1
	var bal: Node3D = _vista.get("_balon")
	if bal != null:
		var pb := bal.global_position
		if _bprev != Vector3.INF and pb.distance_to(_bprev) > 1.2:
			## Reposición (saque, gol, tanda: el balón se coloca) o salto en juego.
			var mo: Variant = _vista.get("_motor")
			var est := String(mo.estado) if mo != null and is_instance_valid(mo) else "?"
			if est == "juego":
				_c["tele"] += 1
				if OS.get_environment("DEPURAR_TELE") != "":
					print("TELE %.2f m en juego (dueño: %s)" % [pb.distance_to(_bprev), str(not (mo.poseedor as Dictionary).is_empty())])
			else:
				_c["repos"] = int(_c.get("repos", 0)) + 1
		if pb.y < 0.08:
			_c["hundido"] += 1
		for a: Node3D in gente:
			var d := Vector2(pb.x - a.global_position.x, pb.z - a.global_position.z).length()
			if d < 0.18 and pb.y > 0.5 and pb.y < 1.5:
				_c["cuerpo"] += 1
		_bprev = pb
	if (_n - 60) % 150 == 0 and _tira.size() < 12:
		var img := get_viewport().get_texture().get_image()
		img.resize(480, 270)
		_tira.append(img)
	if _n >= 60 + FOTOGRAMAS:
		_informe()
		get_tree().quit()

func _informe() -> void:
	var s: int = _c["muestras"]
	print("===== FÍSICA DEL PARTIDO (%d fotogramas, minuto %d) =====" % [s, _partido.minuto])
	print("  jugadores solapados (pares-fotograma): %d de %d (%.2f %%)" % [_c["solape"], _c["pares"], 100.0 * _c["solape"] / maxf(1, _c["pares"])])
	print("  velocidad > 10,5 m/s: %d   máx %.1f m/s" % [_c["vel"], _vmax])
	print("  aceleración > 15 m/s²: %d   máx %.0f m/s²   (el motor permite hasta 18: 19-10)" % [_c["acel"], _amax])
	print("  tirones > 25 m/s² (imposibles): %d" % int(_c.get("tiron", 0)))
	print("  giros > 720°/s: %d" % _c["giro"])
	if not _acel_tipos.is_empty():
		var ks := _acel_tipos.keys()
		ks.sort_custom(func(x: String, y: String) -> bool: return int(_acel_tipos[x]) > int(_acel_tipos[y]))
		for k: String in ks.slice(0, 15):
			print("    ACEL %5d  %s" % [int(_acel_tipos[k]), k])
	print("  balón teletransportado EN JUEGO (>1,2 m/fotograma): %d   reposiciones (saques): %d" % [_c["tele"], int(_c.get("repos", 0))])
	print("  balón hundido en el césped: %d" % _c["hundido"])
	print("  balón atravesando un cuerpo: %d" % _c["cuerpo"])
	if not _tira.is_empty():
		var hoja := Image.create(480 * 4, 270 * 3, false, _tira[0].get_format())
		for k in _tira.size():
			hoja.blit_rect(_tira[k], Rect2i(0, 0, 480, 270), Vector2i((k % 4) * 480, (k / 4) * 270))
		hoja.save_png("res://pruebas/capturas/fisica_tira.png")
	print("===== FIN SONDA =====")
