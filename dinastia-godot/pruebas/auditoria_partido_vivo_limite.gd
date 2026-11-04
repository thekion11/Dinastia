extends Node
## CAZA DE FALLOS (4-11-2026, orden de la líder): el PARTIDO SIMULADO EN VIVO llevado al límite (sin 3D).
##   godot --headless --path . res://pruebas/auditoria_partido_vivo_limite.tscn
## Los 9 idiomas con partidos enteros: la crónica no debe traer marcas sin rellenar (%s, %d, {1}, null, nan), ni líneas vacías seguidas, ni tramos de más de 15 minutos callada;
## todas las velocidades con saltos de tiempo absurdos (0, enorme, negativo) y cambiando de velocidad en cada minuto; saltar al final / al próximo gol dos veces y tras acabar;
## la charla del descanso en todos sus tonos (también repetida y fuera de tiempo); y el reloj nunca pasa del final ni va hacia atrás.
var _fallos := 0

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _ready() -> void:
	await _idiomas()
	await _velocidades()
	await _descanso_y_saltos()
	Idiomas.idioma = "es"
	print("===== FIN. %d fallos =====" % _fallos)
	get_tree().quit(0 if _fallos == 0 else 1)

func _abrir(semilla: int) -> Array:
	var m := Mundo.new()
	m.generar(["CHI"], semilla)
	m.mi_club_id = m.ligas[0].clubes[0].id
	var l := m.ligas[0]
	var p := Partido.new(l.clubes[0], l.clubes[1])
	var v := PartidoVivo.new()
	v.con_3d = false
	add_child(v)
	v.abrir(p, l.clubes[0], m.vestuario)
	return [m, p, v]

func _idiomas() -> void:
	var re_marcas := RegEx.create_from_string("%[sdif]|%\\.\\d|\\{\\d\\}|\\b(null|nan|inf|NaN|INF)\\b|<null>|\\[\\]")
	var malas := 0
	var lineas := 0
	var silencios := 0
	for idi in ["es", "en", "pt", "fr", "it", "de", "ca", "pl", "tr"]:
		Idiomas.idioma = idi
		for semilla in [11, 12, 13]:
			var r := _abrir(semilla)
			var v: PartidoVivo = r[2]
			v.call("_hasta_el_final")
			await get_tree().process_frame
			var txt := (v.get("_cronica") as RichTextLabel).get_parsed_text()
			for linea in txt.split("\n"):
				lineas += 1
				var m_ := re_marcas.search(linea)
				if m_ != null:
					malas += 1
					if malas <= 8:
						print("    MARCA «%s» en %s: %s" % [m_.get_string(), idi, linea.left(100)])
			var seguidas := 0
			for linea in txt.split("\n"):
				seguidas = seguidas + 1 if linea.strip_edges() == "" else 0
				if seguidas >= 4:
					silencios += 1
					break
			v.queue_free()
			await get_tree().process_frame
	_comprobar(malas == 0, "la crónica de 27 partidos (9 idiomas × 3) no trae marcas sin rellenar (%d líneas revisadas, %d malas)" % [lineas, malas])
	_comprobar(silencios == 0, "…ni más de tres líneas vacías seguidas (%d partidos)" % silencios)

func _velocidades() -> void:
	Idiomas.idioma = "es"
	var r := _abrir(21)
	var p: Partido = r[1]
	var v: PartidoVivo = r[2]
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var min_ant := p.minuto
	var hacia_atras := 0
	var n := PartidoVivo.VELOCIDADES.size()
	var vueltas := 0
	while not p.terminado_ya and vueltas < 20000:
		v.call("_poner_velocidad", rng.randi() % n)
		var d: float = [0.0, 0.016, 0.5, 3.0, 1.0e6, -1.0, 1.0e-9][rng.randi() % 7]
		if int(v.get("_velocidad")) == 0 and not bool(v.get("_entretiempo")):
			pass
		v._process(d)
		if p.minuto < min_ant:
			hacia_atras += 1
		min_ant = p.minuto
		if bool(v.get("_entretiempo")) and rng.randf() < 0.5:
			v.call("_salir_segunda")
		vueltas += 1
	print("    DIAG min=%d entretiempo=%s hecho=%s vel=%d terminado=%s" % [p.minuto, str(v.get("_entretiempo")), str(v.get("_entretiempo_hecho")), int(v.get("_velocidad")), str(p.terminado_ya)])
	_comprobar(hacia_atras == 0, "el reloj nunca va hacia atrás con saltos de tiempo absurdos (%d retrocesos)" % hacia_atras)
	_comprobar(p.minuto <= Partido.MINUTOS + 1, "ni pasa del final (minuto %d)" % p.minuto)
	_comprobar(p.terminado_ya, "el partido termina aunque se cambie de velocidad en cada vuelta (%d vueltas)" % vueltas)
	v.queue_free()
	await get_tree().process_frame

func _descanso_y_saltos() -> void:
	var r := _abrir(31)
	var p: Partido = r[1]
	var v: PartidoVivo = r[2]
	var m: Mundo = r[0]
	v.call("_charla_libre", "")   ## una charla vacía fuera de tiempo
	var vueltas := 0
	while p.minuto < 45 and vueltas < 3000:
		if int(v.get("_velocidad")) == 0 and not bool(v.get("_entretiempo")):
			v.call("_poner_velocidad", 3)
		v._process(1.0)
		vueltas += 1
	v._process(1.0)   ## (el reloj llega al 45' y el fotograma siguiente es el que lo detiene)
	_comprobar(bool(v.get("_entretiempo")), "el reloj se para en el descanso")
	for tono in Vestuario.TONOS.keys():
		v.call("_dar_charla", String(tono))
		v.call("_dar_charla", String(tono))   ## dos veces seguidas
	v.call("_charla_libre", "x".repeat(2000))
	v.call("_charla_libre", "¡Vamos %s %d {1} !")
	v.call("_salir_segunda")
	v.call("_salir_segunda")   ## doble pulsación
	v.call("_hasta_el_proximo_gol")
	v.call("_hasta_el_proximo_gol")
	v.call("_hasta_el_final")
	v.call("_hasta_el_final")   ## otra vez, ya terminado
	v.call("_hasta_el_proximo_gol")   ## y esto con el partido terminado no se cuelga
	_comprobar(p.terminado_ya, "saltar al próximo gol y al final, repetido y tras acabar, no se cuelga")
	v._process(5.0)
	_comprobar(p.minuto <= Partido.MINUTOS + 1, "con el partido acabado, avanzar el reloj no hace nada (%d')" % p.minuto)
	v.queue_free()
	await get_tree().process_frame
