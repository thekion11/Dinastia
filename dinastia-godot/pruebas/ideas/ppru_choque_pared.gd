extends "res://pruebas/ideas/ppru_conducir_ciudad.gd"
## CHOCAR CONTRA UN EDIFICIO (ppru, 26-10-2026; plan M-407). En la ciudad real, con W pisado, de
## frente contra la primera fachada a 15-60 m en uno de los cuatro rumbos de la cuadrícula de calles:
## la velocidad cae, no se atraviesa (ningún fotograma con la chapa dentro), sigue sobre el suelo y
## el golpe se registra (`_golpe_coche`: sonido, vibración y sacudida de cámara, M-172).
## Hereda las ayudas de `ppru_conducir_ciudad` (abrir la ciudad, teclas, física a mano).

func _probar_async() -> void:
	_titulo("M-407: CHOQUE CONTRA UN EDIFICIO")
	if not await _abrir_ciudad():
		return
	await _explorar("coche")
	if _e == null:
		return
	_choque_contra_pared(_e.cuerpo.position)
	_linea("  (%.1f s desde que arrancó Godot)" % (Time.get_ticks_msec() / 1000.0))

## De frente contra la fachada más cercana (a 15-60 m) en uno de los cuatro rumbos de las calles.
func _choque_contra_pared(inicio: Vector3) -> void:
	_linea("· choque contra un edificio")
	var ang := -1.0
	var dist := 0.0
	var q := inicio
	## Se busca desde el inicio y, si no, unos metros más allá por la calle más libre.
	var base := _rumbo_mas_libre(inicio)
	for salto in [0.0, 40.0, 80.0, 120.0]:
		q = inicio + Vector3(sin(base), 0, cos(base)) * salto
		q.y = ExploradorCiudad.altura_suelo(q.x, q.z)
		for i in 4:
			var a := PI / 2.0 * i
			if not _e.libre_forma(q, a):
				continue
			var d := _libre_hacia(q, a, 60.0)
			if d >= 15.0 and d < 60.0:
				ang = a
				dist = d
				break
		if ang >= 0.0:
			break
	_comprobar(ang >= 0.0, "hay una pared de frente a 15-60 m para probar el choque")
	if ang < 0.0:
		return
	_linea("  pared a %.1f m hacia %.0f° desde (%.0f, %.0f)" % [dist, rad_to_deg(ang), q.x, q.z])
	_colocar(q, ang)
	var dir := _adelante()
	var t_golpe0: float = _e._t_golpe
	_tecla(KEY_W, true)
	var vmax := 0.0
	var avance_max := 0.0
	var caida := INF
	var dentro := 0
	var v_antes := 0.0
	var i_toca := -1
	for i in 60 * 4:
		_fisica(1)
		var av := (_e.cuerpo.position - q).dot(dir)
		avance_max = maxf(avance_max, av)
		if _e._n_fijos(_e.cuerpo.position, ExploradorCiudad.RADIO_COCHE) > 0:
			dentro += 1
		## El primer fotograma en que pierde velocidad con el pedal pisado: ha tocado la pared.
		if i_toca < 0 and v_antes > 5.0 and _e.vel < v_antes - 0.01:
			i_toca = i
		if i_toca >= 0 and i == i_toca + 30:
			caida = _e.vel
		vmax = maxf(vmax, _e.vel)
		v_antes = _e.vel
	_tecla(KEY_W, false)
	_comprobar(vmax > 12.0, "llega lanzado a la pared (%.0f km/h)" % (vmax * 3.6))
	_comprobar(i_toca >= 0 and caida < vmax * 0.25, "al tocar la pared la velocidad cae: de %.1f a %.1f m/s en 0,5 s" % [vmax, caida])
	_comprobar(avance_max <= dist + 0.3 and dentro == 0, "no atraviesa: avanza %.2f m de %.2f libres, %d fotogramas dentro" % [avance_max, dist, dentro])
	## DEFECTO REAL (ppru, 26-10): de frente y perpendicular a la fachada (las calles son una
	## cuadrícula y el rumbo de salida es 0) `_mover_un_trozo` da por bueno el «deslizamiento»
	## de 0 m (la componente lateral del paso es 0) y nunca llama a `_golpe_coche`.
	_comprobar(_e._t_golpe != t_golpe0, "el choque de frente se registra (sonido, vibración y sacudida de cámara; M-172)")
	_comprobar(_en_el_suelo(_e.cuerpo.position), "tras el choque sigue sobre el suelo")

