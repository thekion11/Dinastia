extends Node3D
## Cuánto cuesta cargar a los 22 jugadores (librería de movimientos incluida).
func _ready() -> void:
	var tiempos: Array = []
	for i in 22:
		var t0 := Time.get_ticks_usec()
		var d := FutbolistaQ.crear(1.8, "male")
		var r: Node3D = d["nodo"]
		add_child(r)
		FutbolistaQ.terminar(d, true)
		tiempos.append((Time.get_ticks_usec() - t0) / 1000.0)
	var resto := 0.0
	for i in range(1, 22):
		resto += float(tiempos[i])
	print("primer jugador: %.0f ms · los otros 21: %.0f ms (%.1f ms cada uno)" % [tiempos[0], resto, resto / 21.0])
	get_tree().quit()
