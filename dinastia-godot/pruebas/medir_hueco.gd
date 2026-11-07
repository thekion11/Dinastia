extends Node
## HUECOS DE LA CARGA DE LA CIUDAD (6-11-2026, orden del dueño: la ciudad se reparte en partes cortas; meta ≤ 200 ms por trozo). Abre la ciudad como el juego
## (`_ver_ciudad_con_carga`: pantalla de carga, ciudad por partes y lo diferido) y apunta el tiempo entre fotogramas hasta que `completa`: el MÁXIMO hueco, los
## que pasan de 200 ms y cuándo ocurre cada uno. Con TIEMPOS=1 salen también los ms por etapa.
##   CALIDAD=minimo taskset -c 0,1 godot --headless --path . res://pruebas/medir_hueco.tscn
var _p: Node
var _n := 0
var _t_prev := 0
var _t0 := 0
var _huecos: Array = []   ## [ms, fotograma, t_ms]
var _vc: VistaCiudad

func _ready() -> void:
	Calidad.elegida = Calidad.MINIMO if OS.get_environment("CALIDAD") == "minimo" else Calidad.MEDIO
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	Engine.max_fps = 0
	var ahora := Time.get_ticks_usec()
	var dt := (ahora - _t_prev) / 1000.0
	_t_prev = ahora
	_n += 1
	if _n == 5:
		_t0 = ahora
		_p.call("_ver_ciudad_con_carga")
	if _n > 5:
		_huecos.append([dt, _n, (ahora - _t0) / 1000.0, _sitio()])
		if _vc == null:
			for h in _p.get_children():
				if h is VistaCiudad:
					_vc = h
		if _vc != null and _vc.get("_ciudad") != null and bool((_vc.get("_ciudad") as Node).get("completa")) and _n > 30:
			_fin()
		elif (ahora - _t0) > 300000000:
			_fin()

## Firma de la escena armada (nodos por clase, instancias de MultiMesh, triángulos de las mallas únicas): debe ser IGUAL antes y después de repartir la carga.
func _firma() -> String:
	var ciudad: Node = _vc.get("_ciudad") if _vc != null else null
	if ciudad == null:
		return "sin ciudad"
	var clases := {}
	var inst := 0
	var caja := Vector3.ZERO
	for n in ciudad.find_children("*", "GeometryInstance3D", true, false):
		if n.get_script() != null or String(n.get_path()).contains("Trafico") or String(n.get_path()).contains("Gente"):
			continue
		clases[n.get_class()] = int(clases.get(n.get_class(), 0)) + 1
		var g := n as GeometryInstance3D
		caja += g.get_aabb().size
		if g is MultiMeshInstance3D and (g as MultiMeshInstance3D).multimesh != null:
			inst += (g as MultiMeshInstance3D).multimesh.instance_count
	var circ: PackedVector3Array = ciudad.get("circulos")
	return "%s inst=%d caja=(%.0f,%.0f,%.0f) circulos=%d" % [str(clases), inst, caja.x, caja.y, caja.z, circ.size()]

var _sitio_ant := ""

## Entre dónde cedió el fotograma anterior y dónde ha cedido este: el tramo de código que tardó.
func _sitio() -> String:
	var ahora := String(_vc.get("_ciudad").get("_cede_en")) if _vc != null and _vc.get("_ciudad") != null else ""
	var r := "de «%s» a «%s»" % [_sitio_ant, ahora]
	_sitio_ant = ahora
	return r

func _fin() -> void:
	print("FIRMA ", _firma())
	var ordenados := _huecos.duplicate()
	ordenados.sort_custom(func(a, b): return float(a[0]) > float(b[0]))
	var largos := 0
	for h: Array in _huecos:
		if float(h[0]) > 200.0:
			largos += 1
	print("HUECO max=%.0f ms  >200ms=%d de %d fotogramas  carga_total=%.0f ms" % [float(ordenados[0][0]), largos, _huecos.size(), float(_huecos[-1][2])])
	for h: Array in ordenados.slice(0, 16):
		print("HUECO_TOP %.0f ms en el fotograma %d (t=%.0f ms) %s" % [float(h[0]), int(h[1]), float(h[2]), String(h[3])])
	get_tree().quit()
