extends Node
## «MI PERSONAJE NO CAMINA DE VERDAD» (orden del dueño, 6-11). Mide, con el paseo real de la ciudad y teclas simuladas:
##  1) AVANCE: la distancia recorrida en 3 s con W pulsada contra la que pide la entrada (VEL_PIE, descontando la arrancada);
##  2) PATINAJE DE PIES: la velocidad de la animación (speed_scale × velocidad natural del clip) contra la velocidad real del cuerpo;
##  3) ATASCOS: contra una pared el cuerpo se queda, la velocidad cae a ~0 y los pies dejan de caminar (no "corren en el sitio");
##  4) DISTANCIA REAL avatar–objetos: la separación mínima, en un paseo al azar, entre el cuerpo y el borde de las huellas sólidas
##     (no puede ser menor que 0 = dentro, y se informa la mínima para vigilar que no se pegue de más).
##   godot --headless --path . res://pruebas/caminar_de_verdad.tscn
var _p: Node
var _fallos := 0
var _e: ExploradorCiudad

func _ready() -> void:
	Calidad.elegida = Calidad.ALTO
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	for i in 6:
		await get_tree().process_frame
	_p.call("_ver_ciudad_propia")
	var v: VistaCiudad = null
	for h in _p.get_children():
		if h is VistaCiudad:
			v = h
	v.explorar("pie")
	for i in 3:
		await get_tree().process_frame
	_e = v.get("_explorador")
	_e.trafico.reciclar_peatones(_e.cuerpo.position, Vector3.ZERO, 70.0, 0, 0, true)   ## sin gente: se mide solo el avatar
	await _avance_y_patinaje()
	await _atasco()
	await _separacion()
	print("===== FIN. %d fallos =====" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)

func _tecla(k: Key, pulsada: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = k
	ev.keycode = k
	ev.pressed = pulsada
	Input.parse_input_event(ev)
	Input.flush_buffered_events()

## Un punto de calle con `largo` metros libres por delante, mirando a `rumbo`.
func _tramo_libre(rumbo: float, largo: float) -> Vector3:
	for ix in range(-1100, 1100, 37):
		for iz in range(-1100, 1100, 41):
			var ok := true
			var dir := Vector3(sin(rumbo), 0, cos(rumbo))
			var q := Vector3(ix, 0, iz)
			for s in range(0, int(largo) + 1, 1):
				if not _e.libre_total(q + dir * float(s), 1.2):
					ok = false
					break
			if ok:
				return Vector3(ix, _e.altura_suelo(ix, iz), iz)
	return Vector3.INF

func _poner(pos: Vector3, rumbo: float) -> void:
	_e.estado = "calle"
	_e.modo = "pie"
	_e.cuerpo.position = pos
	_e.rumbo = rumbo
	_e.cuerpo.rotation.y = rumbo
	_e.vel = 0.0
	_e.set("_vel_pie", 0.0)

func _avance_y_patinaje() -> void:
	var rumbo := 0.0
	var pos := _tramo_libre(rumbo, 14.0)
	_comprobar(pos != Vector3.INF, "hay un tramo de calle libre de 14 m para medir el avance")
	if pos == Vector3.INF:
		return
	_poner(pos, rumbo)
	for i in 5:
		await get_tree().physics_frame
	var ini := _e.cuerpo.position
	var t0 := Time.get_ticks_msec()
	_tecla(KEY_W, true)
	var fr := 0
	var patina_max := 0.0
	var muestras := 0
	var t_sim := 0.0
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	while t_sim < 3.0:
		await get_tree().physics_frame
		t_sim += dt
		fr += 1
		if t_sim > 1.0 and _e._anim != null:
			var natural := 1.4 if not _e._es_dt else float(ExploradorCiudad.VEL_NATURAL_CLIP.get(String(_e._anim.current_animation), 0.0))
			if natural > 0.0:
				patina_max = maxf(patina_max, absf(_e._anim.speed_scale * natural - absf(_e.vel)))
				muestras += 1
	_tecla(KEY_W, false)
	var recorrido := Vector2(_e.cuerpo.position.x - ini.x, _e.cuerpo.position.z - ini.z).length()
	## Con la arrancada (7 m/s² hasta 1,7 m/s ≈ 0,24 s) se pierden ≈ 0,2 m: en 3 s se esperan ≥ 4,6 m de 5,1 m.
	var pedido := ExploradorCiudad.VEL_PIE * t_sim
	print("  CAMINAR recorrido %.2f m de %.2f m pedidos en %.2f s simulados (%d fotogramas; %d ms reales) · vel final %.2f m/s" % [recorrido, pedido, t_sim, fr, Time.get_ticks_msec() - t0, _e.vel])
	_comprobar(recorrido >= pedido * 0.88, "avanza de verdad: %.2f m ≥ 88 %% de %.2f m" % [recorrido, pedido])
	_comprobar(recorrido <= pedido * 1.02, "no avanza de más (sin teletransportes): %.2f m ≤ %.2f m" % [recorrido, pedido * 1.02])
	if muestras > 0:
		print("  CAMINAR patinaje máximo de pies %.2f m/s (animación contra cuerpo)" % patina_max)
		_comprobar(patina_max <= 0.35, "los pies no patinan: diferencia máxima %.2f m/s ≤ 0.35" % patina_max)
	else:
		print("  CAMINAR (sin clip de caminar reconocido: no se mide el patinaje; animación '%s')" % String(_e._anim.current_animation if _e._anim != null else ""))
		_comprobar(false, "el avatar debería tener un clip de caminar con velocidad natural conocida")

func _atasco() -> void:
	## Camina hacia la primera pared que haya delante.
	var rumbo := 0.0
	var pos := Vector3.INF
	var largo := 0.0
	for ix in range(-1000, 1000, 29):
		for iz in range(-1000, 1000, 31):
			var q := Vector3(ix, 0, iz)
			if not _e.libre_total(q, 1.2):
				continue
			var d := 0.0
			while d < 12.0 and _e.libre_total(q + Vector3(0, 0, d), 1.2):
				d += 0.5
			if d >= 4.0 and d < 12.0:
				pos = Vector3(ix, _e.altura_suelo(ix, iz), iz)
				largo = d
				break
		if pos != Vector3.INF:
			break
	_comprobar(pos != Vector3.INF, "hay una pared a 4–12 m para el atasco")
	if pos == Vector3.INF:
		return
	_poner(pos, rumbo)
	for i in 5:
		await get_tree().physics_frame
	_tecla(KEY_W, true)
	for i in int(Engine.physics_ticks_per_second * (largo / ExploradorCiudad.VEL_PIE + 3.0)):
		await get_tree().physics_frame
	var antes := _e.cuerpo.position
	for i in 30:
		await get_tree().physics_frame
	var movido := Vector2(_e.cuerpo.position.x - antes.x, _e.cuerpo.position.z - antes.z).length()
	var pies := 0.0
	if _e._anim != null:
		pies = _e._anim.speed_scale * (1.4 if not _e._es_dt else float(ExploradorCiudad.VEL_NATURAL_CLIP.get(String(_e._anim.current_animation), 0.0)))
	var limpia := _separacion_a(_e.cuerpo.position)
	_tecla(KEY_W, false)
	print("  ATASCO contra la pared: se movió %.3f m en 0,5 s · vel %.2f m/s · pies %.2f m/s" % [movido, _e.vel, pies])
	_comprobar(movido < 0.1, "contra la pared el cuerpo se queda (%.3f m)" % movido)
	_comprobar(absf(_e.vel) <= 0.2, "contra la pared la velocidad cae a ~0: %.2f m/s ≤ 0.2" % absf(_e.vel))
	print("  SEPARACIÓN de pie contra la pared: %.2f m (radio del cuerpo %.2f m)" % [limpia, ExploradorCiudad.RADIO_PIE])
	_comprobar(limpia >= ExploradorCiudad.RADIO_PIE - 0.05 and limpia <= ExploradorCiudad.RADIO_PIE + 0.6, "al pegarse a una pared queda a %.2f m (entre el radio y el radio + 0,6 m)" % limpia)
	_comprobar(pies <= 0.5, "contra la pared los pies no corren en el sitio: %.2f m/s ≤ 0.5" % pies)

## Distancia del punto a la huella sólida más cercana (0 = dentro).
func _separacion_a(q: Vector3) -> float:
	var mejor := INF
	for r: Rect2 in _e.obstaculos:
		var dx := maxf(maxf(r.position.x - q.x, q.x - r.end.x), 0.0)
		var dz := maxf(maxf(r.position.y - q.z, q.z - r.end.y), 0.0)
		mejor = minf(mejor, sqrt(dx * dx + dz * dz))
	return mejor

func _separacion() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var minima := INF
	var dentro := 0
	var n := 0
	for tramo in 6:
		var pos := Vector3(rng.randf_range(-800, 800), 0, rng.randf_range(-800, 800))
		if not _e.libre_total(pos, 0.6):
			continue
		_poner(Vector3(pos.x, _e.altura_suelo(pos.x, pos.z), pos.z), rng.randf() * TAU)
		_tecla(KEY_W, true)
		for f in 240:
			if f % 60 == 0:
				_e.rumbo += rng.randf_range(-1.2, 1.2)
			await get_tree().physics_frame
			var q: Vector3 = _e.cuerpo.position
			n += 1
			var d := _separacion_a(q)
			minima = minf(minima, d)
			if d == 0.0:
				dentro += 1
		_tecla(KEY_W, false)
	print("  SEPARACIÓN avatar–objetos: mínima %.2f m en %d muestras · dentro de una huella: %d" % [minima, n, dentro])
	_comprobar(n > 500, "hay muestras suficientes (%d)" % n)
	_comprobar(dentro == 0, "el avatar nunca queda dentro de una huella sólida (%d)" % dentro)
	_comprobar(minima >= ExploradorCiudad.RADIO_PIE - 0.05, "separación mínima %.2f m ≥ el radio del cuerpo (%.2f m)" % [minima, ExploradorCiudad.RADIO_PIE - 0.05])

func _comprobar(ok: bool, texto: String) -> void:
	print("  %s %s" % ["OK   " if ok else "FALLO", texto])
	if not ok:
		_fallos += 1
