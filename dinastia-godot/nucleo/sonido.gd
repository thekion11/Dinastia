extends "res://nucleo/sonido_p2.gd"
## (Parte 3 de 3 de `sonido.gd`.)

func _sintetizar_banco(nombre: String) -> Array[AudioStreamWAV]:
	var b: Array[AudioStreamWAV] = []
	for v in VARIANTES:
		b.append(_sintetizar(nombre, float(v) / float(VARIANTES)))
	return b

## EN SEGUNDO PLANO (25-9-2026). Antes `_ready()` sintetizaba los 820 sonidos
## (205 × 4 variantes) en el hilo principal: medido, 12 segundos de pantalla
## congelada al abrir el juego. Ahora un hilo los va haciendo mientras se juega,
## y si alguien pide uno que todavía no está, `banco()` hace solo ese, al
## momento -unos milisegundos-. La síntesis no toca `Azar` (cada receta usa su
## propio generador), así que el hilo no altera ninguna partida.
func _generar_en_fondo() -> void:
	for nombre: String in NOMBRES:
		if _parar:
			return
		_mutex.lock()
		var ya := _bancos.has(nombre)
		_mutex.unlock()
		if ya:
			continue
		var b := _sintetizar_banco(nombre)
		_mutex.lock()
		if not _bancos.has(nombre):
			_bancos[nombre] = b
		_mutex.unlock()

func _ready() -> void:
	for i in VOCES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_voces.append(p)
	_hilo = Thread.new()
	_hilo.start(_generar_en_fondo, Thread.PRIORITY_LOW)

## Las variantes de un sonido, generándolas si todavía no estaban.
func banco(nombre: String) -> Array:
	_mutex.lock()
	var b: Variant = _bancos.get(nombre)
	_mutex.unlock()
	if b != null:
		return b
	if not NOMBRES.has(nombre):
		return []
	var nuevo := _sintetizar_banco(nombre)
	_mutex.lock()
	if not _bancos.has(nombre):
		_bancos[nombre] = nuevo
	var r: Array = _bancos[nombre]
	_mutex.unlock()
	return r


## Genera TODO de golpe, en el hilo que llama. Solo para pruebas y
## herramientas: el juego usa el hilo de fondo de `_ready()`.
func _generar_todo() -> void:
	for nombre: String in NOMBRES:
		banco(nombre)

func _exit_tree() -> void:
	_parar = true
	if _hilo != null and _hilo.is_started():
		_hilo.wait_to_finish()

## Reproduce un efecto. Si no existe, no hace nada y no se queja: un sonido que
## falta no puede tumbar un partido.
func toca(nombre: String, bus: Bus = Bus.EFECTOS) -> void:
	if not encendido:
		return
	var variantes: Array = banco(nombre)
	if variantes.is_empty():
		return
	var p := _voces[_siguiente % VOCES]
	_siguiente += 1
	## LA VARIANTE NO SE SORTEA CON `Azar`. `Azar` es el generador DETERMINISTA
	## de la partida: si elegir cual de las cuatro variantes suena consumiera un
	## numero de ahi, subir el volumen o jugar con los sonidos apagados daria
	## resultados distintos en la liga. Es exactamente la trampa que ya se pago
	## una vez en este proyecto con un feed cosmetico, y solo la caza el banco.
	## Aqui basta con ir rotando: el oido no distingue una rueda de un sorteo.
	p.stream = variantes[_siguiente % variantes.size()]
	p.volume_db = linear_to_db(maxf(0.001, float(volumen[bus])))
	p.play()

## Los nombres de los efectos que hay cargados, y una ficha de cada uno.
##
## Existen para que el banco de pruebas pueda comprobar que la sintesis produce
## ondas de verdad. Un banco que "carga" pero suena a nada es peor que uno que
## falla: no hay error, y el juego se queda mudo sin que nadie sepa por que.
func catalogo() -> Array:
	var l := NOMBRES.duplicate()
	l.sort()
	return l

func ficha(nombre: String) -> Dictionary:
	var variantes: Array = banco(nombre)
	if variantes.is_empty():
		return {}
	var w: AudioStreamWAV = variantes[0]
	var pico := 0
	for i in range(0, w.data.size() - 1, 64):
		pico = maxi(pico, absi(w.data.decode_s16(i)))
	return {
		"variantes": variantes.size(),
		"segundos": float(w.data.size() / 2) / float(FRECUENCIA),
		"pico": pico,
	}
