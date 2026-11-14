extends Node
## CPU DEL PARTIDO 3D POR CLASE DE SCRIPT (2-11-2026, 120 FPS). Sin pantalla (mide scripts, animación y física, no la gráfica):
##   godot --headless --path . res://pruebas/medir_cpu_partido.tscn      (REPETIR=n: n pasadas y se promedian)
## Con el partido en marcha y la cámara de TV, apaga el proceso de cada clase de script (y de AnimationPlayer, Skeleton3D…) y mira cuánto baja el
## tiempo por fotograma. Lo que baja menos de ~0,5 ms está dentro del ruido de la medición.
var _vista: VistaEstadio
var _n := 0
var _hecho := false

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	var par := mundo.proximo_partido()
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))

func _process(_d: float) -> void:
	if _hecho:
		return
	Engine.max_fps = 0
	var intro: Variant = _vista.get("_intro")
	if intro != null and is_instance_valid(intro) and intro.activa:
		intro.terminar()
		return
	var cer: Variant = _vista.get("_ceremonia")
	if cer != null and is_instance_valid(cer) and cer.activa:
		cer.terminar()
		return
	_n += 1
	if _n == 5:
		(_vista.get("_rig") as CameraRig).switch_to(0)
	if _n == 60:
		_hecho = true
		_medir()

func _medir() -> void:
	var por_clase := {}
	for n in _vista.find_children("*", "Node", true, false):
		if n.get_script() != null and (n.is_processing() or n.is_physics_processing()):
			var k := String(n.get_script().resource_path.get_file())
			if not por_clase.has(k):
				por_clase[k] = []
			por_clase[k].append(n)
	var rep := maxi(1, int(OS.get_environment("REPETIR")) if OS.get_environment("REPETIR") != "" else 3)
	if OS.get_environment("SOLO_BASE") != "":   ## SOLO_BASE=n: n medidas seguidas SIN tocar nada (comprueba si la base deriva)
		for k in int(OS.get_environment("SOLO_BASE")):
			var ms := await _cuadros(150)
			var pa: Variant = _vista.get("partido")
			print("CPUP deriva %d: %.2f ms  (minuto %s, terminado %s)" % [k, ms, str(pa.minuto) if pa != null else "?", str(pa.terminado_ya) if pa != null else "?"])
		get_tree().quit()
		return
	await _cuadros(1600)   ## calentamiento: los ~1350 primeros fotogramas tras abrir el estadio gastan 11-17 ms de CPU en hilos de fondo (carga); estable ~3,6 ms
	var base := 0.0
	for i in rep:
		base += await _cuadros(150)
	base /= rep
	print("CPUP base %.2f ms  (%d clases con proceso, %d nodos)" % [base, por_clase.size(), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
	for k: String in por_clase:
		for n: Node in por_clase[k]:
			n.process_mode = Node.PROCESS_MODE_DISABLED
		var t := 0.0
		for i in rep:
			t += await _cuadros(150)
		t /= rep
		for n: Node in por_clase[k]:
			n.process_mode = Node.PROCESS_MODE_INHERIT
		print("CPUP sin %-30s x%-4d -%.2f ms" % [k, por_clase[k].size(), base - t])
	for clase in ["AnimationPlayer", "AnimationTree", "Skeleton3D", "Label3D", "GPUParticles3D", "CPUParticles3D"]:
		var ns := _vista.find_children("*", clase, true, false)
		for n in ns:
			n.process_mode = Node.PROCESS_MODE_DISABLED
		var t2 := 0.0
		for i in rep:
			t2 += await _cuadros(150)
		t2 /= rep
		for n in ns:
			n.process_mode = Node.PROCESS_MODE_INHERIT
		print("CPUP sin %-30s x%-4d -%.2f ms" % [clase, ns.size(), base - t2])
	print("===== FIN. 0 fallos =====")
	get_tree().quit()

## CPU del proceso (usuario + sistema, todos los hilos) por fotograma, en ms. El tiempo de pared NO sirve sin pantalla: el bucle sin
## render espera hasta un suelo fijo de 6,9 ms por fotograma (medido con una escena vacía) y tapa todo lo que cuesta menos.
static func _cpu_ms() -> float:
	var f := FileAccess.open("/proc/self/stat", FileAccess.READ)   ## los archivos de /proc dicen medir 0 bytes: se lee por líneas
	if f == null:
		return 0.0
	var t := f.get_line()
	var campos := t.substr(t.rfind(")") + 2).split(" ")
	return (float(campos[11]) + float(campos[12])) * 10.0   ## ticks de 10 ms (campos 14 y 15 del archivo)

func _cuadros(c: int) -> float:
	for i in 5:
		await get_tree().process_frame
	var t0 := _cpu_ms()
	for i in c:
		await get_tree().process_frame
	return (_cpu_ms() - t0) / float(c)
