extends BaseIdea
## CONDUCIR POR LA CIUDAD REAL (ppru, 26-10-2026; plan M-407 «sin pruebas de conducción/ciudad», V-06).
## Abre la Principal, va a la ciudad propia y pulsa «🚗 Conducir» (`VistaCiudad.explorar`), como el
## jugador. El tráfico se congela y la física del explorador se llama a mano con 1/60 s: así es
## determinista. Las teclas se pulsan de verdad (`Input.parse_input_event`); la Esc va por el visor.
##   · la cámara de seguimiento va detrás, encima y mirando al coche, y lo alcanza tras girar;
##   · al girar con D el morro va hacia la derecha DE LA CÁMARA;
##   · contra un edificio: la velocidad cae de golpe, no se atraviesa y el golpe se registra;
##   · 8 s de recorrido con volantazos: dentro del mapa, sobre el suelo y nunca dentro de nada.
## Subir y bajar del coche: `ppru_subir_bajar_coche` (hereda de esta). Las piezas de la forma del coche
## y el tráfico están en pmov_*; el manejo puro en `ppru_conducir`. Cada una tarda < 60 s.

const DT := 1.0 / 60.0
var _v: VistaCiudad
var _e: ExploradorCiudad

func _ready() -> void:
	await get_tree().process_frame
	await _probar_async()
	_soltar_todo()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _probar_async() -> void:
	_titulo("M-407: CONDUCIR POR LA CIUDAD REAL")
	if not await _abrir_ciudad():
		return
	await _explorar("coche")
	if _e == null:
		return
	var inicio := _e.cuerpo.position
	_camara_detras()
	_girar_con_la_camara(inicio)
	_choque_contra_pared(inicio)
	_recorrido(inicio)
	_linea("  (%.1f s desde que arrancó Godot)" % (Time.get_ticks_msec() / 1000.0))

## La Principal con la ciudad propia en pantalla (como el botón «Ciudad»).
func _abrir_ciudad() -> bool:
	var p: Node = load("res://escenas/principal.tscn").instantiate()
	add_child(p)
	for i in 6:
		await get_tree().process_frame
	p.call("_ver_ciudad_propia")
	for h in p.get_children():
		if h is VistaCiudad:
			_v = h
	_comprobar(_v != null, "hay vista de la ciudad propia")
	return _v != null

# ------------------------------------------------------------------ ayudas

func _tecla(k: Key, si: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.pressed = si
	Input.parse_input_event(ev)
	Input.flush_buffered_events()

func _soltar_todo() -> void:
	for k in [KEY_W, KEY_S, KEY_A, KEY_D]:
		_tecla(k, false)

func _explorar(modo: String) -> void:
	_v.explorar(modo)
	for i in 3:
		await get_tree().process_frame
	_e = _v.get("_explorador")
	if _e == null:
		_comprobar(false, "explorar(\"%s\") crea el explorador" % modo)
		return
	## Determinista: el tráfico quieto y la física del explorador a mano.
	if _e.trafico != null:
		_e.trafico.process_mode = Node.PROCESS_MODE_DISABLED
	_e.set_physics_process(false)

func _fisica(n: int) -> void:
	for i in n:
		_e._physics_process(DT)

func _adelante() -> Vector3:
	return Vector3(sin(_e.rumbo), 0, cos(_e.rumbo))

func _en_el_suelo(q: Vector3) -> bool:
	return absf(q.y - ExploradorCiudad.altura_suelo(q.x, q.z)) < 0.05

## Metros libres hacia `ang` desde `q` (con la forma del coche), hasta `tope`.
func _libre_hacia(q: Vector3, ang: float, tope: float) -> float:
	var dir := Vector3(sin(ang), 0, cos(ang))
	var d := 0.0
	while d < tope:
		if not _e.libre_forma(q + dir * (d + 0.25), ang):
			return d
		d += 0.25
	return tope

## El rumbo con más calle libre por delante (de 16 posibles).
func _rumbo_mas_libre(q: Vector3) -> float:
	var mejor := 0.0
	var dmax := -1.0
	for i in 16:
		var ang := TAU * i / 16.0
		var d := _libre_hacia(q, ang, 150.0)
		if d > dmax:
			dmax = d
			mejor = ang
	return mejor

func _colocar(q: Vector3, ang: float) -> void:
	_e.cuerpo.position = q
	_e.rumbo = ang
	_e.vel = 0.0
	_e._volante = 0.0
	_e._colocar_camara(1.0)

# ------------------------------------------------------------------ pruebas

## La cámara de persecución: detrás, por encima, mirando al coche; también a toda velocidad.
func _camara_detras() -> void:
	_linea("· la cámara sigue al coche")
	var ang := _rumbo_mas_libre(_e.cuerpo.position)
	_linea("  calle libre hacia %.0f°: %.0f m" % [rad_to_deg(ang), _libre_hacia(_e.cuerpo.position, ang, 150.0)])
	_colocar(_e.cuerpo.position, ang)
	_tecla(KEY_W, true)
	var peor_detras := 1.0
	var peor_mira := 1.0
	var dmin := INF
	var dmax := 0.0
	for i in 180:
		_fisica(1)
		if i < 30:
			continue
		var c := _e.camara.global_position
		var car := _e.cuerpo.global_position
		var rel := car - c
		var hz := Vector3(rel.x, 0, rel.z).normalized()
		peor_detras = minf(peor_detras, hz.dot(_adelante()))
		peor_mira = minf(peor_mira, (-_e.camara.global_transform.basis.z).dot(rel.normalized()))
		dmin = minf(dmin, rel.length())
		dmax = maxf(dmax, rel.length())
		if c.y <= car.y + 1.0:
			peor_detras = -1.0
	_tecla(KEY_W, false)
	_comprobar(_e.vel > 10.0, "acelerando por la calle: %.0f km/h en 3 s" % (_e.vel * 3.6))
	_comprobar(peor_detras > 0.9, "la cámara va detrás y por encima del coche (peor alineación %.2f)" % peor_detras)
	_comprobar(peor_mira > 0.85, "y lo mira (peor coseno %.2f)" % peor_mira)
	_comprobar(dmin > 4.0 and dmax < 16.0, "a una distancia razonable: de %.1f a %.1f m" % [dmin, dmax])

## Girar con D: el morro va hacia la derecha de la cámara; luego la cámara vuelve a quedar detrás.
func _girar_con_la_camara(inicio: Vector3) -> void:
	_linea("· girar")
	var ang := _rumbo_mas_libre(inicio)
	_colocar(inicio, ang)
	_e.vel = 10.0
	_fisica(10)
	var derecha := _e.camara.global_transform.basis.x
	var f0 := _adelante()
	_tecla(KEY_D, true)
	_tecla(KEY_W, true)
	_fisica(30)
	_tecla(KEY_D, false)
	var f1 := _adelante()
	_comprobar(f1.dot(derecha) > 0.1 and f1.dot(f0) < 0.99, "con D el morro gira hacia la derecha de la pantalla (%.2f hacia la derecha)" % f1.dot(derecha))
	_fisica(120)
	_tecla(KEY_W, false)
	var rel := _e.cuerpo.global_position - _e.camara.global_position
	var al := Vector3(rel.x, 0, rel.z).normalized().dot(_adelante())
	_comprobar(al > 0.9, "tras el giro la cámara vuelve a quedar detrás (alineación %.2f)" % al)

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
	var caida := -1.0
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

## 8 s con volantazos por la ciudad real: dentro del mapa, sobre el suelo, nunca dentro de un edificio.
func _recorrido(inicio: Vector3) -> void:
	_linea("· recorrido de 8 s")
	_colocar(inicio, _rumbo_mas_libre(inicio))
	var fuera := 0
	var bajo := 0
	var dentro := 0
	var raros := 0
	var camino := 0.0
	var antes := _e.cuerpo.position
	_tecla(KEY_W, true)
	for i in 60 * 8:
		## Un volantazo a cada lado cada pocos segundos.
		var fase := i % 150
		_tecla(KEY_D, fase >= 60 and fase < 80)
		_tecla(KEY_A, fase >= 110 and fase < 125)
		_fisica(1)
		var p := _e.cuerpo.position
		if not (is_finite(p.x) and is_finite(p.y) and is_finite(p.z) and is_finite(_e.vel)):
			raros += 1
			continue
		if absf(p.x) > ExploradorCiudad.LIMITE or absf(p.z) > ExploradorCiudad.LIMITE:
			fuera += 1
		if not _en_el_suelo(p):
			bajo += 1
		if _e._n_fijos(p, ExploradorCiudad.RADIO_COCHE) > 0:
			dentro += 1
		camino += Vector2(p.x - antes.x, p.z - antes.z).length()
		antes = p
	_soltar_todo()
	var fin := _e.cuerpo.position
	_linea("  de (%.0f, %.0f) a (%.0f, %.0f): %.0f m recorridos" % [inicio.x, inicio.z, fin.x, fin.z, camino])
	_comprobar(raros == 0, "sin posiciones ni velocidades inválidas (%d)" % raros)
	_comprobar(camino > 60.0, "recorre la ciudad: %.0f m en 8 s" % camino)
	_comprobar(fuera == 0, "nunca sale del mapa (límite %.0f m): %d fotogramas fuera" % [ExploradorCiudad.LIMITE, fuera])
	_comprobar(bajo == 0, "siempre a ras del suelo (ni hundido ni flotando): %d fotogramas mal" % bajo)
	_comprobar(dentro == 0, "nunca dentro de un edificio o del río: %d fotogramas" % dentro)
