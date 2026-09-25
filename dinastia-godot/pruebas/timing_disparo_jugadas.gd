extends Node
## Verificacion del fix de sincronizacion balon/animacion en las JUGADAS
## PREHECHAS (`ReproductorJugadas._armar_impulso()`, 22-9-2026). Antes del
## fix, `Balon3D.disparar()` se llamaba en el mismo instante en que arrancaba
## la fase -el balon salia disparado mientras el rematador seguia con su
## animacion de carrera, sin patear nada, y sin el retraso `CONTACTO_PATADA`
## que `MatchPlayback._disparar()` ya aplicaba para los remates sueltos (ver
## `diagnostico_timing_disparo.gd`, el mismo bug, la otra puerta de disparo).
## Mismo metodo de verificacion: medir el timing y la animacion arrancada
## directamente, no una captura de pantalla.

func _ready() -> void:
	var fallos: Array = []

	var balon := Balon3D.new()
	add_child(balon)

	var mp := MatchPlayback.new()
	mp.setup([], [], 90, 50.0, balon)

	# Rematador falso: un AnimationPlayer con "patear"/"cabezazo" de mentira,
	# para comprobar que arranca sin necesitar el modelo 3D real.
	var nodo_jugador := Node3D.new()
	add_child(nodo_jugador)
	var ap := AnimationPlayer.new()
	nodo_jugador.add_child(ap)
	var lib := AnimationLibrary.new()
	lib.add_animation("patear", Animation.new())
	lib.add_animation("cabezazo", Animation.new())
	ap.add_animation_library("", lib)
	var jugador := {
		"id": "test_id", "es_local": true, "node": nodo_jugador, "anim": ap,
		"base_pos": Vector3.ZERO, "slot_code": "LD", "arbitro": false,
	}
	mp.players = [jugador]
	mp.players_by_id["test_id"] = jugador

	var rj := ReproductorJugadas.new()
	# ATQ-01 ("Cutback por banda"): su fase 0 trae impulso_balon y dura 1.4s
	# -de sobra para las comprobaciones de abajo sin que la fase avance sola-.
	if not rj.iniciar("ATQ-01", mp, balon, true):
		fallos.append("no pudo iniciar la jugada ATQ-01")
	# `iniciar()` solo coloca el balon y los destinos; el impulso de la fase 0
	# se arma recien en el primer `avanzar()` (asi lo dispara `puente3d.gd` en
	# el juego real, tick a tick), por eso hace falta un primer avance de 0s.
	rj.avanzar(0.0)

	# Justo tras ese primer avanzar(): el vuelo debe estar CALCULADO pero NO
	# lanzado, y
	# el unico jugador de la lista (LD, el mas cercano al balon) debe estar
	# ejecutando la patada.
	if rj._impulso_pendiente.is_empty():
		fallos.append("el impulso debia quedar pendiente, no salio inmediato")
	elif absf(rj._impulso_pendiente.get("restante", -1.0) - MatchPlayback.CONTACTO_PATADA) > 0.001:
		fallos.append("restante inicial no es CONTACTO_PATADA")
	if ap.current_animation != "patear" and ap.current_animation != "cabezazo":
		fallos.append("el rematador no arranco la animacion de patada (current_animation='%s')" % ap.current_animation)

	# Avanzar menos que CONTACTO_PATADA (0.35s): debe seguir pendiente.
	rj.avanzar(0.1)
	rj.avanzar(0.1)
	rj.avanzar(0.1)
	if rj._impulso_pendiente.is_empty():
		fallos.append("el balon salio ANTES de tiempo (antes de CONTACTO_PATADA)")

	# Avanzar el resto: ahora si debe haber salido.
	rj.avanzar(0.1)
	rj.avanzar(0.05)
	if not rj._impulso_pendiente.is_empty():
		fallos.append("el balon nunca salio, sigue pendiente pasado CONTACTO_PATADA")

	print("fallos: ", fallos.size())
	for f in fallos:
		print("FALLO: ", f)
	print("FIN. %d fallos" % fallos.size())
	get_tree().quit(0 if fallos.is_empty() else 1)
