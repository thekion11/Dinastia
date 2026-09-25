extends Node
## Verificacion del fix de sincronizacion balon/animacion en `_disparar()`
## (match_playback.gd). Antes del fix, `Balon3D.enviar()` se llamaba en el
## mismo instante en que arrancaba la animacion "patear"/"cabezazo" (fotograma
## 0, el jugador recien empezando el gesto) en vez de cuando el pie conecta a
## mitad del swing. Este test mide directamente el timing, no la pose: es la
## forma correcta de verificar un bug de sincronizacion temporal (un screenshot
## no lo puede probar, un numero de posicion en el tiempo si).

func _ready() -> void:
	var fallos: Array = []

	var balon := Balon3D.new()
	add_child(balon)
	balon.position = Vector3(0.0, 0.11, 0.0)

	var mp := MatchPlayback.new()
	mp.setup([], [], 90, 50.0, balon)
	var nodo_jugador := Node3D.new()
	add_child(nodo_jugador)
	var jugador := {
		"id": "test_id", "es_local": true, "node": nodo_jugador, "anim": null,
		"base_pos": Vector3.ZERO, "slot_code": "DC", "arbitro": false,
	}
	mp.players = [jugador]
	mp.players_by_id["test_id"] = jugador

	var ev := {
		"min": 10, "tx": "remate", "t": "disparo", "tipo": "atajada",
		"equipo": "local", "jugadorId": "test_id",
	}
	mp._disparar(ev)

	# Justo tras `_disparar()`: el vuelo debe estar CALCULADO pero NO lanzado.
	if mp._disparo_pendiente.is_empty():
		fallos.append("el disparo debia quedar pendiente, no salio inmediato")
	elif absf(mp._disparo_pendiente.get("restante", -1.0) - MatchPlayback.CONTACTO_PATADA) > 0.001:
		fallos.append("restante inicial no es CONTACTO_PATADA")

	# Avanzar 0.3s (menos que CONTACTO_PATADA=0.35): debe seguir pendiente.
	mp.tick(0.1)
	mp.tick(0.1)
	mp.tick(0.1)
	if mp._disparo_pendiente.is_empty():
		fallos.append("el balon salio ANTES de tiempo (antes de CONTACTO_PATADA)")

	# Avanzar el resto: ahora si debe haber salido.
	mp.tick(0.1)
	mp.tick(0.05)
	if not mp._disparo_pendiente.is_empty():
		fallos.append("el balon nunca salio, sigue pendiente pasado CONTACTO_PATADA")

	print("fallos: ", fallos.size())
	for f in fallos:
		print("FALLO: ", f)
	print("FIN. %d fallos" % fallos.size())
	get_tree().quit(0 if fallos.is_empty() else 1)
