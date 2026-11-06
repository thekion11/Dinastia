extends Node
## DETECTOR DE PERSONAJES QUE ATRAVIESAN OBJETOS (6-11, plan §«Personajes que atraviesan objetos»).
## Abre la ciudad a pie, concentra a los peatones alrededor de varios puntos de la ciudad, los deja caminar y en cada
## fotograma comprueba que ninguno quede DENTRO de un obstáculo sólido (`ExploradorCiudad.obstaculos`, las huellas de
## edificios y mobiliario) ni en el río fuera de un puente. Imprime los peores sitios (coordenada y obstáculo) para
## ir corrigiéndolos; el aviso no es un fallo mientras haya casos conocidos: `TOPE` fija cuántas muestras dentro se toleran
## (se baja al corregir). Con `DETECTOR_ESTRICTO=1` el tope es 0.
##   godot --headless --path . res://pruebas/detector_atraviesa.tscn
const PUNTOS: Array[Vector2] = [Vector2(1005, -500), Vector2(0, 0), Vector2(-600, 400), Vector2(500, 700), Vector2(-900, -300)]
const FRAMES := 90
const TOPE_V := 0
const TOPE := 0   ## (6-11) corregida la avenida del estadio: ningún peatón dentro de un obstáculo
var _p: Node
var _fallos := 0

func _ready() -> void:
	Calidad.elegida = Calidad.ALTO
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	for i in 6:
		await get_tree().process_frame
	_p.call("_ver_ciudad_propia")
	var v: VistaCiudad = null
	for h in _p.get_children():
		if h is VistaCiudad:
			v = h
	v.explorar("pie")
	for i in 3:
		await get_tree().process_frame
	var e: ExploradorCiudad = v.get("_explorador")
	var total := 0
	var dentro := 0
	var peores: Dictionary = {}
	var total_v := 0
	var dentro_v := 0
	var peores_v: Dictionary = {}
	var rects_v: Dictionary = {}
	var rects: Dictionary = {}
	for pt in PUNTOS:
		var c := Vector3(pt.x, e.altura_suelo(pt.x, pt.y), pt.y)
		e.cuerpo.position = c
		e.trafico.reciclar_peatones(c, Vector3.ZERO, 70.0, 22, 28, true)
		for f in FRAMES:
			await get_tree().process_frame
			for mv: Dictionary in e.trafico._vehiculos:
				var q: Vector3 = (mv["nodo"] as Node3D).position
				if absf(q.x - c.x) > 150.0 or absf(q.z - c.z) > 150.0:
					continue
				if not bool(mv.get("peaton", false)):   ## coches, buses, motos… (el punto central de un vehículo dentro de una huella es choque seguro)
					total_v += 1
					if not ExploradorCiudad.libre(q, 0.0, e.obstaculos):
						dentro_v += 1
						var clave_v := "%d,%d" % [roundi(q.x / 4.0) * 4, roundi(q.z / 4.0) * 4]
						peores_v[clave_v] = int(peores_v.get(clave_v, 0)) + 1
						if not rects_v.has(clave_v):
							for r2: Rect2 in e.obstaculos:
								if q.x >= r2.position.x and q.x <= r2.end.x and q.z >= r2.position.y and q.z <= r2.end.y:
									rects_v[clave_v] = "%s ruta %d" % [r2, int(mv.get("ruta", -1))]
									break
					continue
				total += 1
				if not ExploradorCiudad.libre(q, 0.0, e.obstaculos):
					dentro += 1
					var clave := "%d,%d" % [roundi(q.x / 4.0) * 4, roundi(q.z / 4.0) * 4]
					peores[clave] = int(peores.get(clave, 0)) + 1
					if not rects.has(clave):
						for r: Rect2 in e.obstaculos:
							if q.x >= r.position.x and q.x <= r.end.x and q.z >= r.position.y and q.z <= r.end.y:
								rects[clave] = r
								break
	print("DETECTOR peatones muestreados: %d · dentro de un obstáculo: %d (%.2f %%)" % [total, dentro, 100.0 * dentro / maxf(1.0, total)])
	var claves := peores.keys()
	claves.sort_custom(func(a: Variant, b: Variant) -> bool: return int(peores[a]) > int(peores[b]))
	for k in claves.slice(0, 10):
		print("  DETECTOR peor sitio (x,z)=%s · %d muestras · obstáculo %s" % [k, peores[k], rects.get(k, "?")])
	print("DETECTOR vehículos muestreados: %d · dentro de un obstáculo: %d (%.2f %%)" % [total_v, dentro_v, 100.0 * dentro_v / maxf(1.0, total_v)])
	var claves_v := peores_v.keys()
	claves_v.sort_custom(func(a: Variant, b: Variant) -> bool: return int(peores_v[a]) > int(peores_v[b]))
	for k in claves_v.slice(0, 10):
		print("  DETECTOR peor sitio de vehículos (x,z)=%s · %d muestras · %s" % [k, peores_v[k], rects_v.get(k, "?")])
	if OS.get_environment("DETECTOR_RUTA") != "":
		var rt = e.trafico._rutas[int(OS.get_environment("DETECTOR_RUTA"))]
		print("  DETECTOR ruta %s: %s" % [OS.get_environment("DETECTOR_RUTA"), rt.puntos])
	var tope := 0 if OS.get_environment("DETECTOR_ESTRICTO") == "1" else TOPE
	_comprobar(total > 100, "hay peatones que muestrear (%d)" % total)
	_comprobar(dentro_v <= TOPE_V, "vehículos dentro de obstáculos %d ≤ %d" % [dentro_v, TOPE_V])
	_comprobar(dentro <= tope, "peatones dentro de obstáculos %d ≤ %d" % [dentro, tope])
	print("===== FIN. %d fallos =====" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)

func _comprobar(ok: bool, texto: String) -> void:
	print("  %s %s" % ["OK   " if ok else "FALLO", texto])
	if not ok:
		_fallos += 1
