extends Node
## MICROBENCHMARK de `AnclaSuelo` en reposo (13-11, sesión 16, optimización de código): 26 instancias (un partido) con un reproductor cuyo clip
## NO está en la lista de clips que hunden el cuerpo (el caso de casi todo el partido) y se cronometran N fotogramas del árbol real.
##   godot --headless --path . res://pruebas/micro_ancla.tscn      (CPU de GDScript; no es tiempo de fotograma gráfico)
const N_FOT := 3000
const N_JUG := 26

func _crear() -> Array:
	var lista: Array = []
	for i in N_JUG:
		var nodo := Node3D.new()
		add_child(nodo)
		var modelo := Node3D.new()
		nodo.add_child(modelo)
		var esq := Skeleton3D.new()
		modelo.add_child(esq)
		var ap := AnimationPlayer.new()
		nodo.add_child(ap)
		var lib := AnimationLibrary.new()
		var a := Animation.new()
		a.length = 1.0
		a.loop_mode = Animation.LOOP_LINEAR
		lib.add_animation("parado", a)
		var b := Animation.new()
		b.length = 1.0
		lib.add_animation("entrada_tijera", b)
		ap.add_animation_library("", lib)
		ap.play("parado")
		var an := AnclaSuelo.new()
		an._nodo = nodo
		an._modelo = modelo
		an._esq = esq
		an._anim = ap
		an.name = "AnclaSuelo"
		nodo.add_child(an)
		lista.append([an, ap])
	return lista

## Tiempo medio dentro de los `_process` por fotograma (µs): `TIME_PROCESS` mide solo eso, sin la espera del reloj de fotogramas (el suelo de 6,9 ms de headless).
func _tiempo() -> float:
	var suma := 0.0
	for f in N_FOT:
		await get_tree().process_frame
		suma += Performance.get_monitor(Performance.TIME_PROCESS)
	return suma / float(N_FOT) * 1.0e6

func _ready() -> void:
	AnclaSuelo.CLIPS = {"entrada_tijera": true}
	var lista := _crear()
	for i in 10:
		await get_tree().process_frame
	## Coste real de UNA llamada a `_process` en reposo, medida directa (200 000 llamadas): es el trabajo que se repite 26 veces por fotograma.
	var an := lista[0][0] as AnclaSuelo
	var n := 200000
	var t0 := Time.get_ticks_usec()
	for k in n:
		an._process(0.016)
	var us_ancla := float(Time.get_ticks_usec() - t0) / float(n)
	var t1 := Time.get_ticks_usec()
	for k in n:
		pass
	var us_vacio := float(Time.get_ticks_usec() - t1) / float(n)
	print("MICRO_ANCLA llamada en reposo: %.3f us (bucle vacío %.3f) → %d anclas = %.1f us por fotograma (%.2f %% de 8 ms)" % [us_ancla, us_vacio, N_JUG, (us_ancla - us_vacio) * N_JUG, (us_ancla - us_vacio) * N_JUG / 80.0])
	get_tree().quit()
