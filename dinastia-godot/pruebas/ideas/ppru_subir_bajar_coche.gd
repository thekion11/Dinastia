extends "res://pruebas/ideas/ppru_conducir_ciudad.gd"
## SUBIR Y BAJAR DEL COCHE (ppru, 26-10-2026; plan M-407). En la ciudad real, como el jugador:
## «🚗 Conducir» → Esc (al mapa) → «🚶 Pasear» → Esc. Cada vez: el modo, el estado, la cámara
## activa, el rótulo, lo que sabe el tráfico de ti y que apareces sobre el suelo y en un sitio libre.
## Hereda las ayudas de `ppru_conducir_ciudad` (abrir la ciudad, teclas, física a mano).

func _probar_async() -> void:
	_titulo("M-407: SUBIR Y BAJAR DEL COCHE")
	if not await _abrir_ciudad():
		return
	await _subir_y_bajar()
	_linea("  (%.1f s desde que arrancó Godot)" % (Time.get_ticks_msec() / 1000.0))

## Conducir → Esc → Pasear → Esc → Conducir: cada vez el modo, el cuerpo, la cámara y el sitio.
func _subir_y_bajar() -> void:
	_linea("· subir y bajar del coche")
	await _explorar("coche")
	if _e == null:
		return
	var coche := _e
	var q := coche.cuerpo.position
	_comprobar(coche.modo == "coche" and coche.estado == "calle", "Conducir: modo coche, en la calle")
	_comprobar(get_viewport().get_camera_3d() == coche.camara, "la cámara activa es la del coche")
	_comprobar(_en_el_suelo(q) and coche.libre_forma(q, coche.rumbo), "el coche aparece sobre el suelo y libre (%.0f, %.1f, %.0f)" % [q.x, q.y, q.z])
	_comprobar(Vector2(q.x, q.z).distance_to(Vector2(0, CityBuilder.RING_Z_SUR)) < 40.0, "en coche se sale en la ronda sur (a %.0f m)" % Vector2(q.x, q.z).distance_to(Vector2(0, CityBuilder.RING_Z_SUR)))
	_comprobar(coche.trafico != null and coche.trafico.jugador == coche.cuerpo and coche.trafico.jugador_huella.y > 2.0, "el tráfico sabe que eres un coche (huella %s)" % (coche.trafico.jugador_huella if coche.trafico != null else Vector2.ZERO))
	_fisica(1)
	_comprobar(coche._hud.text.contains(Idiomas.t("🚗 Conduciendo")), "el rótulo dice «Conduciendo»")
	await _esc()
	_comprobar(_v.get("_explorador") == null and not is_instance_valid(coche), "Esc: se baja del coche y vuelve al mapa")
	_comprobar(get_viewport().get_camera_3d() != null and get_viewport().get_camera_3d() == _v.get("_camara"), "con la cámara del mapa")
	await _explorar("pie")
	if _e == null:
		return
	var pie := _e
	var qp := pie.cuerpo.position
	_comprobar(pie.modo == "pie" and pie.estado == "calle", "Pasear: modo a pie")
	_comprobar(_en_el_suelo(qp) and pie.libre_forma(qp, pie.rumbo), "a pie aparece sobre el suelo y libre (%.0f, %.1f, %.0f)" % [qp.x, qp.y, qp.z])
	_comprobar(pie.trafico != null and pie.trafico.jugador == pie.cuerpo and pie.trafico.jugador_huella.y < 1.0, "el tráfico sabe que vas a pie")
	_fisica(1)
	_comprobar(pie._hud.text.contains(Idiomas.t("🚶 A pie")), "el rótulo dice «A pie»")
	## A pie, W anda (a paso de peatón), no conduce.
	_tecla(KEY_W, true)
	_fisica(120)
	_tecla(KEY_W, false)
	_comprobar(pie.vel > 1.0 and pie.vel <= ExploradorCiudad.VEL_PIE + 0.001, "a pie, W anda a %.2f m/s (tope %.1f)" % [pie.vel, ExploradorCiudad.VEL_PIE])
	await _esc()
	_comprobar(_v.get("_explorador") == null, "Esc a pie: también vuelve al mapa")

func _esc() -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_ESCAPE
	ev.physical_keycode = KEY_ESCAPE
	ev.pressed = true
	get_viewport().push_input(ev)
	var suelta := ev.duplicate() as InputEventKey
	suelta.pressed = false
	get_viewport().push_input(suelta)
	for i in 3:
		await get_tree().process_frame

