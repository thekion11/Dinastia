extends Node
## PERFIL DE CPU POR SCRIPT (15-10-2026). `perfil_arbol` mide lo que se le pide a
## la gráfica; esto mide lo que cuestan los SCRIPTS en cada fotograma: abre el
## partido (con el motor real) o la ciudad a pie, mide el tiempo medio de
## `_process` + `_physics_process`, y luego apaga el procesado de cada script
## (todos sus nodos a la vez) para ver cuánto aporta.
##
##   godot --headless --path . res://pruebas/perfil_cpu.tscn            (partido)
##   ESCENA=ciudad godot --headless --path . res://pruebas/perfil_cpu.tscn
##
## Sin ventana (--headless) no se dibuja nada: el tiempo es casi solo de scripts.
## Las cifras dependen de la máquina; sirven para comparar antes y después.

const FOTOGRAMAS := 90

var _p: Node

func _ready() -> void:
	Calidad.elegida = Calidad.ALTO
	if OS.get_environment("ESCENA") == "ciudad":
		await _abrir_ciudad()
	else:
		await _abrir_partido()
	for i in 60:
		await get_tree().process_frame
	var base := await _medir()
	print("PERFIL CPU base: %.2f ms por fotograma (process %.2f + physics %.2f)" % [base.x + base.y, base.x, base.y])
	var grupos := {}
	for n in _todos(get_tree().root):
		if n == self or not (n.is_processing() or n.is_physics_processing()):
			continue
		var s: Script = n.get_script()
		var clave: String = s.resource_path if s != null and s.resource_path != "" else n.get_class()
		if not grupos.has(clave):
			grupos[clave] = []
		(grupos[clave] as Array).append(n)
	var filas: Array = []
	for clave: String in grupos:
		var nodos: Array = grupos[clave]
		var antes: Array = []
		for n: Node in nodos:
			antes.append([n.is_processing(), n.is_physics_processing()])
			n.set_process(false)
			n.set_physics_process(false)
		var m := await _medir()
		for i in nodos.size():
			var n: Node = nodos[i]
			if is_instance_valid(n):
				n.set_process(bool(antes[i][0]))
				n.set_physics_process(bool(antes[i][1]))
		filas.append([(base.x + base.y) - (m.x + m.y), nodos.size(), clave])
	filas.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	print("PERFIL CPU por script (ms que se ahorran al apagarlo · nodos · script):")
	for f: Array in filas.slice(0, 20):
		print("  %6.2f ms  %4d  %s" % [float(f[0]), int(f[1]), String(f[2])])
	get_tree().quit()

func _abrir_partido() -> void:
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	var par := mundo.proximo_partido()
	var vista := VistaEstadio.new()
	add_child(vista)
	vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))
	for i in 45:
		await get_tree().process_frame

func _abrir_ciudad() -> void:
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
	## En la avenida, con gente y tráfico alrededor (como `captura_paseo`).
	e.cuerpo.position = Vector3(1005.0, e.altura_suelo(1005.0, -500.0), -500.0)
	e.trafico.reciclar_peatones(e.cuerpo.position, Vector3.ZERO, 70.0, 22, 28, true)

## Media de FOTOGRAMAS (tras 10 de espera para que el cambio se asiente), en ms.
func _medir() -> Vector2:
	for i in 10:
		await get_tree().process_frame
	var pr := 0.0
	var fi := 0.0
	for i in FOTOGRAMAS:
		await get_tree().process_frame
		pr += Performance.get_monitor(Performance.TIME_PROCESS)
		fi += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	return Vector2(pr, fi) * 1000.0 / FOTOGRAMAS

func _todos(n: Node) -> Array:
	var r: Array = [n]
	for c in n.get_children():
		r.append_array(_todos(c))
	return r
