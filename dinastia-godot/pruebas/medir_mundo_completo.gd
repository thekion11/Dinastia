extends Node
## Mide cuanto tarda generar el mundo completo (todos los paises), que es lo
## que hace el HTML siempre y lo que hasta ahora Godot solo hacia en pruebas.
func _ready() -> void:
	var t0 := Time.get_ticks_msec()
	var m := Mundo.new()
	m.generar([], 12345)
	var ms := Time.get_ticks_msec() - t0
	print("mundo completo: %d clubes, %d jugadores, %d ligas, en %d ms" % [
		m.clubes.size(), m.cuantos_jugadores(), m.ligas.size(), ms])
	get_tree().quit()
