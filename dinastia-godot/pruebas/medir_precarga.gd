extends Node
## ¿CUÁNTO AHORRA LA PRECARGA? (etapa 3). Abre la portada (que lanza la
## precarga), espera a que termine y cronometra abrir la ciudad. Con
## SIN_PRECARGA=1 la precarga no arranca: la diferencia es lo ganado.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://pruebas/medir_precarga.tscn
var _n := 0
var _t0 := 0

func _ready() -> void:
	if OS.get_environment("SIN_PRECARGA") != "":
		Precarga._hecha = true
	add_child(load("res://escenas/inicio.tscn").instantiate())
	_t0 = Time.get_ticks_msec()

func _process(_d: float) -> void:
	_n += 1
	if _n < 5 or get_tree().root.has_node("Precarga"):
		return
	set_process(false)
	print("MEDIDA precarga terminada en %d ms" % (Time.get_ticks_msec() - _t0))
	var p: Node = load("res://escenas/principal.tscn").instantiate()
	add_child(p)
	var t := Time.get_ticks_msec()
	p.call("_ver_ciudad_propia")
	print("MEDIDA abrir la ciudad: %d ms" % (Time.get_ticks_msec() - t))
	get_tree().quit()
