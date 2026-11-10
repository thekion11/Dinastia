extends Node
## CUÁNTO TARDA EL ARRANQUE HASTA EL MENÚ (10-11-2026, rendimiento en móvil/equipo modesto): ms desde que arranca el motor (`Time.get_ticks_msec()`: motor + autoloads + escena principal) hasta
## que la portada (`inicio.tscn`, lo primero que ve el jugador) está montada y hasta que se han dibujado sus 1.º y 30.º fotogramas, y la memoria (estática y pico del proceso).
##   herramientas/hw_modesto.sh res://pruebas/medir_arranque.tscn   (HW_NUCLEOS=0,1 → equipo modesto de 2 núcleos; NIVEL por argumento: `-- baja`)
var _t_ready := 0
var _t_montada := 0
var _n := 0
var _t_f1 := 0

func _ready() -> void:
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.NIVEL_DEFECTO)
	_t_ready = Time.get_ticks_msec()
	var inicio: Node = load("res://escenas/inicio.tscn").instantiate()
	add_child(inicio)
	_t_montada = Time.get_ticks_msec()
	RenderingServer.frame_post_draw.connect(_dibujado)

func _dibujado() -> void:
	_n += 1
	if _n == 1:
		_t_f1 = Time.get_ticks_msec()
	if _n == 30:
		var pico := 0
		var f := FileAccess.open("/proc/self/status", FileAccess.READ)
		if f != null:
			for l in f.get_as_text().split("\n"):
				if l.begins_with("VmHWM"):
					pico = int(l.split(" ", false)[1]) / 1024
		print("ARRANQUE motor+autoloads=%d ms · montar la portada=%d ms · 1.er fotograma a los %d ms · 30.º fotograma a los %d ms · memoria estática %d MB · pico del proceso %d MB · vídeo %d MB" % [
			_t_ready, _t_montada - _t_ready, _t_f1, Time.get_ticks_msec(), OS.get_static_memory_usage() / 1048576, pico,
			Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576])
		get_tree().quit()
