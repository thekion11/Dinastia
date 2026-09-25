extends Node
## Prueba de que `_dirigir()` ahora encuentra el partido continental -antes
## de esta tanda, jamas existia esa puerta: solo miraba copa y liga-.
## Avanza semanas una por una -no en bloque, para poder frenar apenas haya
## un cruce continental en vez de arriesgarse al colgado del sorteo de copa
## que ya salió una vez esta sesión con `_avanzar_semana()` en bloque-.

var _n := 0
var _pantalla: Node
var _probado := false

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n < 12 or _probado:
		return
	var mundo: Mundo = _pantalla.get("mundo")
	## ¿Esta semana hay continental para mi club, y no hay copa -que tiene
	## prioridad-? Si no, avanza una semana más y vuelve a mirar.
	var par_conti: Array = mundo.partido_continental()
	var par_copa: Array = mundo.partido_de_copa()
	if not par_conti.is_empty() and par_copa.is_empty():
		_probado = true
		var t := mundo.mi_continental()
		print("semana=%d torneo=%s ronda=%s grupos=%s" % [
			mundo.semana, t.clave, t.nombre_de_ronda(), t.en_fase_de_grupos()])
		print("emparejamiento_continental=%s vs %s" % [par_conti[0].nombre, par_conti[1].nombre])
		_pantalla.call("_dirigir")
		var vivo: PartidoVivo = null
		for h in _pantalla.get_children():
			if h is PartidoVivo:
				vivo = h
				break
		print("se abrio PartidoVivo = %s" % (vivo != null))
		if vivo != null:
			var p: Partido = vivo.partido
			print("partido: %s vs %s (eliminatoria=%s)" % [p.local.nombre, p.visita.nombre, vivo.es_eliminatoria])
			vivo.call("_hasta_el_final")
			var gl_antes := p.goles_local
			var gv_antes := p.goles_visita
			print("resultado en vivo: %d-%d" % [gl_antes, gv_antes])
			vivo.queue_free()
			mundo.avanzar_semana(p)
			print("resultado anotado por el torneo: %d-%d" % [p.goles_local, p.goles_visita])
			print("COINCIDE (no se volvio a simular) = %s" % (p.goles_local == gl_antes and p.goles_visita == gv_antes))
		get_tree().quit()
		return
	mundo.avanzar_semana()
	if mundo.semana > 34:
		print("no se encontro una semana continental libre de copa en toda la temporada")
		get_tree().quit()
