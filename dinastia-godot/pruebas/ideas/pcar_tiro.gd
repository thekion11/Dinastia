extends BaseIdea
## Modo jugador: ya no «todo tiro es gol» (ControlPartido.resolver_tiro).

func _probar() -> void:
	_titulo("PCAR: TIRO DEL MODO JUGADOR")
	var goles_cerca := 0
	var goles_lejos := 0
	var fuera_lejos := 0
	var n := 400
	for i in n:
		var ax := (i + 0.5) / n
		var aa := fmod(i * 0.618034, 1.0)
		if ControlPartido.resolver_tiro(0.6, 10.0, ax, aa)["gol"]:
			goles_cerca += 1
		var lejos: Dictionary = ControlPartido.resolver_tiro(0.6, 32.0, ax, aa)
		if lejos["gol"]:
			goles_lejos += 1
		if not lejos["a_puerta"]:
			fuera_lejos += 1
	_comprobar(goles_cerca < n, "no todo tiro cercano es gol (%d/%d)" % [goles_cerca, n])
	_comprobar(goles_cerca > n * 0.25, "desde 10 m se marca a menudo (%d/%d)" % [goles_cerca, n])
	_comprobar(goles_lejos < goles_cerca, "de lejos se marca menos (%d < %d)" % [goles_lejos, goles_cerca])
	_comprobar(fuera_lejos > n * 0.4, "de lejos muchos tiros se van fuera (%d/%d)" % [fuera_lejos, n])
	var tope: Dictionary = ControlPartido.resolver_tiro(1.0, 12.0, 0.5, 0.99)
	_comprobar(not tope["a_puerta"], "a potencia máxima se va por encima del larguero")
	var centro: Dictionary = ControlPartido.resolver_tiro(0.5, 12.0, 0.5, 0.0)
	_comprobar(centro["a_puerta"] and centro["atajado"], "al centro y con azar bajo, el portero ataja")
	var esquina: Dictionary = ControlPartido.resolver_tiro(0.6, 8.0, 0.88, 0.3)
	_comprobar(esquina["gol"], "a la escuadra desde cerca, gol (x=%.2f)" % esquina["x"])
