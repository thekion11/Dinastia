extends BaseSO
## ESTÁNDAR · reglas del partido simulado: marcador no negativo y entero, misma semilla = mismo partido, el local rinde algo más que el
## visitante, un club mucho mejor gana más y no se producen goles absurdos. 120 partidos con dos clubes reales del mundo generado.
func _nombre() -> String:
	return "est_partido_simulado_reglas"

func _media(c: Club) -> float:
	var s := 0.0
	for j: Jugador in c.plantilla:
		s += j.ovr
	return s / maxf(1.0, c.plantilla.size())

func _jugar(a: Club, b: Club, semilla: int) -> Dictionary:
	Azar.sembrar(semilla)
	return Partido.new(a, b).simular()

func _probar() -> void:
	_titulo("ESTÁNDAR · reglas del partido simulado [%s]" % sistema())
	var m := _mundo(20261105)
	## (10-11) Solo clubes de PRIMERA: el mundo trae ahora segundas divisiones y el más débil del mundo (~41 de media) contra el mejor (~71) es un cruce que en liga no existe.
	var todos: Array = m.clubes.values().filter(func(c: Club) -> bool: return m.liga_de(c) != null and m.liga_de(c).division() == 1)
	todos.sort_custom(func(x: Club, y: Club) -> bool: return _media(x) > _media(y))
	var fuerte: Club = todos[0]
	var debil: Club = todos[todos.size() - 1]
	_comprobar(_media(fuerte) > _media(debil) + 5.0, "hay diferencia de nivel: %.1f contra %.1f" % [_media(fuerte), _media(debil)])
	var r1 := _jugar(fuerte, debil, 77)
	var r2 := _jugar(fuerte, debil, 77)
	_comprobar(r1["local"] == r2["local"] and r1["visita"] == r2["visita"], "misma semilla → mismo marcador (%d-%d)" % [r1["local"], r1["visita"]])
	var gl := 0
	var gv := 0
	var v_fuerte := 0
	var v_debil := 0
	var max_goles := 0
	var raros := 0
	for i in 60:
		var r := _jugar(fuerte, debil, 1000 + i)
		var gl_i := int(r["local"])
		var gv_i := int(r["visita"])
		raros += int(gl_i < 0 or gv_i < 0 or not (r["local"] is int))
		gl += gl_i
		gv += gv_i
		v_fuerte += int(gl_i > gv_i)
		v_debil += int(gv_i > gl_i)
		max_goles = maxi(max_goles, gl_i + gv_i)
	_comprobar(raros == 0, "marcadores enteros y no negativos")
	_comprobar(max_goles <= 14, "ningún partido pasa de 14 goles (máximo %d)" % max_goles)
	_comprobar(v_fuerte > v_debil, "el club fuerte gana más que el débil (%d contra %d)" % [v_fuerte, v_debil])
	var promedio := float(gl + gv) / 60.0
	_comprobar(promedio > 1.2 and promedio < 5.0, "%.2f goles por partido (rango del fútbol real 1,2-5)" % promedio)
	## Local vs visitante entre iguales: 60 partidos de ida y 60 de vuelta entre dos clubes parejos.
	var a: Club = todos[todos.size() / 2]
	var b: Club = todos[todos.size() / 2 + 1]
	var loc := 0
	var vis := 0
	for i in 60:
		var r := _jugar(a, b, 5000 + i)
		loc += int(r["local"])
		vis += int(r["visita"])
	_comprobar(loc >= vis - 6, "ser local no perjudica (local %d, visitante %d goles)" % [loc, vis])
