extends BaseIdea
## LA CONDUCCIÓN DEL COCHE, CON EL TECLADO (ppru, 26-10-2026; plan M-407 «sin pruebas de
## conducción/ciudad», V-06). Las de pmov miran la FORMA del coche contra paredes, postes y
## tráfico; esta mira el MANEJO: se pulsan teclas de verdad (`Input.parse_input_event`, que es lo
## que lee `ExploradorCiudad._entrada`) y se llama a `_conducir` como en cada fotograma de física.
##   · W: la velocidad sube sin parar hasta el tope `VEL_COCHE` y no lo pasa.
##   · Sin pedal: frena solo, poco a poco. S: frena mucho más fuerte, y parado da marcha atrás (tope -8).
##   · A/D: el rumbo cambia hacia el lado del volante, parado no gira, marcha atrás invierte el giro
##     y a tope gira menos que a media velocidad. Espacio (freno de mano): para antes que soltar.
## Sin ciudad ni pantalla (headless): el recorrido por la ciudad real está en `ppru_conducir_ciudad`.

const DT := 1.0 / 60.0
var _e: ExploradorCiudad

func _probar() -> void:
	_titulo("M-407: CONDUCCIÓN — acelerar, frenar, marcha atrás y girar")
	_e = _nuevo()
	_e.modo = "coche"
	add_child(_e)
	_e.set_physics_process(false)
	_comprobar(_e._entrada() == Vector2.ZERO, "sin teclas, la entrada es cero")
	_acelerar()
	_frenar()
	_marcha_atras()
	_girar()
	_freno_de_mano()
	_soltar_todo()
	_e.queue_free()

## El explorador que se prueba (una prueba de mutación puede dar uno roto a propósito).
func _nuevo() -> ExploradorCiudad:
	return ExploradorCiudad.new()

func _tecla(k: Key, si: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.pressed = si
	Input.parse_input_event(ev)
	Input.flush_buffered_events()

func _soltar_todo() -> void:
	for k in [KEY_W, KEY_S, KEY_A, KEY_D, KEY_SPACE]:
		_tecla(k, false)

## `n` fotogramas de 1/60 s con lo que esté pulsado; devuelve las velocidades.
func _fotogramas(n: int) -> PackedFloat32Array:
	var v := PackedFloat32Array()
	for i in n:
		_e._conducir(_e._entrada(), DT)
		v.append(_e.vel)
	return v

func _acelerar() -> void:
	_e.vel = 0.0
	_tecla(KEY_W, true)
	_comprobar(_e._entrada() == Vector2(0, 1), "W se lee como acelerar (entrada %s)" % _e._entrada())
	var v := _fotogramas(60 * 12)
	var sube := true
	var t20 := -1.0
	var maximo := 0.0
	for i in v.size():
		maximo = maxf(maximo, v[i])
		if i > 0 and v[i] < v[i - 1] - 0.0001:
			sube = false
		if t20 < 0.0 and v[i] >= 20.0:
			t20 = (i + 1) * DT
	_comprobar(v[0] > 0.0 and sube, "con W la velocidad sube sin bajar nunca (1.er fotograma %.3f m/s)" % v[0])
	_comprobar(t20 > 1.5 and t20 < 8.0, "de 0 a 72 km/h en %.1f s (entre 1,5 y 8: ni instantáneo ni eterno)" % t20)
	_comprobar(maximo <= ExploradorCiudad.VEL_COCHE + 0.0001 and v[v.size() - 1] >= ExploradorCiudad.VEL_COCHE * 0.99,
		"tiene tope: máx. %.2f m/s, al final %.2f (tope %.0f)" % [maximo, v[v.size() - 1], ExploradorCiudad.VEL_COCHE])
	_tecla(KEY_W, false)

func _frenar() -> void:
	## Soltando el pedal frena solo, poco a poco.
	_e.vel = ExploradorCiudad.VEL_COCHE
	var suelto := _fotogramas(60)
	var tras_1s := suelto[suelto.size() - 1]
	_comprobar(tras_1s < ExploradorCiudad.VEL_COCHE * 0.95 and tras_1s > ExploradorCiudad.VEL_COCHE * 0.6,
		"sin pedal pierde velocidad poco a poco: %.1f → %.1f m/s en 1 s" % [ExploradorCiudad.VEL_COCHE, tras_1s])
	## Con S, mucho más fuerte, y se para (no pasa de golpe a marcha atrás).
	_e.vel = ExploradorCiudad.VEL_COCHE
	_tecla(KEY_S, true)
	var v := _fotogramas(60 * 3)
	var t_para := -1.0
	for i in v.size():
		if v[i] <= 0.5:
			t_para = (i + 1) * DT
			break
	_comprobar(v[29] < tras_1s - 5.0, "con S frena mucho más que soltando (a los 0,5 s: %.1f m/s)" % v[29])
	_comprobar(t_para > 0.3 and t_para < 2.5, "con S se para en %.2f s desde 94 km/h" % t_para)
	_tecla(KEY_S, false)

func _marcha_atras() -> void:
	_e.vel = 0.0
	_tecla(KEY_S, true)
	var v := _fotogramas(60 * 6)
	var minimo := 0.0
	for x in v:
		minimo = minf(minimo, x)
	_comprobar(v[30] < -1.0, "parado, S da marcha atrás (a los 0,5 s: %.1f m/s)" % v[30])
	_comprobar(minimo >= -8.0001 and v[v.size() - 1] <= -7.9, "la marcha atrás tiene tope de 8 m/s (mín. %.2f)" % minimo)
	_tecla(KEY_S, false)
	## Y con W se vuelve a ir hacia delante.
	_tecla(KEY_W, true)
	var w := _fotogramas(60 * 3)
	_comprobar(w[w.size() - 1] > 5.0, "de marcha atrás, W lo devuelve hacia delante (%.1f m/s)" % w[w.size() - 1])
	_tecla(KEY_W, false)

## Cuánto cambia el rumbo en `seg` segundos con la tecla `k` y la velocidad fija `v`.
func _giro(k: Key, v: float, seg: float) -> float:
	_e.rumbo = 0.0
	_e._volante = 0.0
	_tecla(k, true)
	for i in int(seg * 60.0):
		_e.vel = v
		_e._conducir(_e._entrada(), DT)
	_tecla(k, false)
	return _e.rumbo

func _girar() -> void:
	## El lado: mirando a +Z desde detrás, la derecha es -X (lo que ve la cámara de seguimiento:
	## su eje x es (-cos r, 0, sin r)). Con D el morro va hacia la derecha.
	var d := _giro(KEY_D, 10.0, 0.5)
	var dch := Vector3(sin(d), 0, cos(d)).dot(Vector3(-1, 0, 0))
	_comprobar(d < -0.1 and dch > 0.1, "D gira a la derecha (rumbo %.2f rad, morro hacia -X %.2f)" % [d, dch])
	var a := _giro(KEY_A, 10.0, 0.5)
	_comprobar(a > 0.1 and absf(a + d) < 0.01, "A gira a la izquierda lo mismo (rumbo %.2f vs %.2f)" % [a, d])
	var parado := _giro(KEY_D, 0.0, 1.0)
	_comprobar(is_zero_approx(parado), "parado no gira aunque se pise el volante (rumbo %.3f)" % parado)
	var atras := _giro(KEY_D, -5.0, 0.5)
	_comprobar(atras > 0.05, "marcha atrás con D el morro va al otro lado, como un coche (rumbo %.2f)" % atras)
	var a_tope := absf(_giro(KEY_D, ExploradorCiudad.VEL_COCHE, 0.5))
	var a_media := absf(_giro(KEY_D, 10.0, 0.5))
	_comprobar(a_tope < a_media, "a tope gira menos que a media velocidad (%.2f < %.2f rad en 0,5 s)" % [a_tope, a_media])
	## El volante no salta: tarda unos fotogramas en llegar a tope (`_volante` suavizado).
	_e._volante = 0.0
	_tecla(KEY_D, true)
	_e.vel = 10.0
	_e._conducir(_e._entrada(), DT)
	var v1 := _e._volante
	_tecla(KEY_D, false)
	_comprobar(v1 > 0.0 and v1 < 0.5, "el volante gira suave, no de golpe (%.2f tras un fotograma)" % v1)

func _freno_de_mano() -> void:
	_e.vel = 20.0
	var suelto := _fotogramas(60)[59]
	_e.vel = 20.0
	_tecla(KEY_SPACE, true)
	var mano := _fotogramas(60)[59]
	_tecla(KEY_SPACE, false)
	_comprobar(mano < suelto - 10.0, "el freno de mano (Espacio) para mucho antes que soltar (%.1f vs %.1f m/s en 1 s)" % [mano, suelto])
