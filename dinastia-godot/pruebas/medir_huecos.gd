extends Node
## HUECOS ENTRE FOTOGRAMAS DE UNA CARGA (7-11, meta «< 200 ms por carga»): abre la escena `ESCENA` (por defecto la de inicio del juego), y mide el tiempo de montarla (síncrono)
## y cada fotograma posterior; imprime los huecos de más de 100 ms con su instante. Por software los absolutos no valen: se compara antes/después.
##   ESCENA=res://escenas/inicio.tscn HW_RAM_MB=16000 bash herramientas/hw_modesto.sh res://pruebas/medir_huecos.tscn -- minimo
var _n := 0
var _t_prev := 0
var _t_ini := 0
var _huecos: Array = []
var _max := 0.0

func _ready() -> void:
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.ULTRA_BAJA)
	var ruta := OS.get_environment("ESCENA") if OS.get_environment("ESCENA") != "" else "res://escenas/inicio.tscn"
	_t_ini = Time.get_ticks_usec()
	var ps := load(ruta) as PackedScene
	var t1 := Time.get_ticks_usec()
	var e := ps.instantiate()
	var t2 := Time.get_ticks_usec()
	add_child(e)
	var t3 := Time.get_ticks_usec()
	print("HUECOS montar: load %.0f ms · instanciar %.0f ms · añadir (_ready) %.0f ms" % [(t1 - _t_ini) / 1000.0, (t2 - t1) / 1000.0, (t3 - t2) / 1000.0])
	_t_prev = Time.get_ticks_usec()

func _process(_d: float) -> void:
	Engine.max_fps = 0
	var ahora := Time.get_ticks_usec()
	var dt := (ahora - _t_prev) / 1000.0
	_t_prev = ahora
	_n += 1
	_max = maxf(_max, dt)
	if dt > 100.0:
		_huecos.append("%.0f ms en el fotograma %d (a los %.1f s)" % [dt, _n, (ahora - _t_ini) / 1000000.0])
	if _n >= 900:
		print("HUECOS mayor hueco %.0f ms; huecos > 100 ms: %d" % [_max, _huecos.size()])
		for h in _huecos.slice(0, 14):
			print("HUECOS   ", h)
		get_tree().quit()
