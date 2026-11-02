extends BaseIdea
## LOS MINIJUEGOS 3D SE PUEDEN JUGAR (01-11-2026, fase 8 «minijuegos», M-408: los minijuegos 3D no tenían prueba). Abre los
## penales y el tiro libre de la ciudad sobre un mundo de verdad, juega los cinco tiros de cada uno con sus animaciones
## (el tween de cada tiro dura ~2,5 s) y comprueba el marcador, los dos cuerpos (pateador y portero) y que se cierran.

func _esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _probar() -> void:
	_titulo("MINIJUEGOS 3D")
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	var lienzo := Control.new()
	lienzo.size = Vector2(1280, 720)
	add_child(lienzo)
	## Penales: el jugador elige zona, el portero adivina a veces.
	var pen := MinijuegoPenales.mostrar(lienzo, m)
	await _esperar(0.5)
	_comprobar(not pen._portero.is_empty() and not pen._pateador.is_empty(), "penales: pateador y portero con cuerpo")
	_comprobar(not pen.find_children("*", "SubViewport", true, false).is_empty(), "penales: escena 3D propia")
	for i in MinijuegoPenales.TIROS:
		pen._patear(i % MinijuegoPenales.ZONAS.size())
		var espera := 0.0
		while pen._ocupado and espera < 6.0:
			await _esperar(0.2)
			espera += 0.2
	_comprobar(pen._tiros == MinijuegoPenales.TIROS and pen._goles <= MinijuegoPenales.TIROS, "penales: cinco tiros jugados (%d goles)" % pen._goles)
	var cerrado := [false]
	pen.cerrado.connect(func() -> void: cerrado[0] = true)
	pen._cerrar()
	await _esperar(0.3)
	_comprobar(cerrado[0], "penales: se cierra")
	## Tiro libre: zona + barra de potencia.
	var tl := MinijuegoTiroLibre.mostrar(lienzo, m)
	await _esperar(0.5)
	_comprobar(not tl._portero.is_empty() and not tl._pateador.is_empty(), "tiro libre: pateador y portero con cuerpo")
	for i in MinijuegoTiroLibre.TIROS:
		tl._elegir(i % 4)
		tl._potencia = 0.62
		tl._patear()
		var espera := 0.0
		while tl._ocupado and espera < 6.0:
			await _esperar(0.2)
			espera += 0.2
	_comprobar(tl._tiros == MinijuegoTiroLibre.TIROS, "tiro libre: cinco tiros jugados (%d goles)" % tl._goles)
	_comprobar(MinijuegoTiroLibre.resultado_potencia(0.62) != MinijuegoTiroLibre.resultado_potencia(1.0), "tiro libre: la potencia cambia el golpeo")
	lienzo.queue_free()
