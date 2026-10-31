extends "res://nucleo/sonido_p2.gd"
## [Capa 7/7 de `sonido.gd`] ruta_grabado, _crear_banco, _sintetizar_banco, _generar_en_fondo, _ready, banco … (+6)

## SONIDOS GRABADOS (26-10-2026). Si existe `res://audio/ui/<nombre>.ogg`, ese
## archivo manda sobre la receta: el dueño aprobó unos clics de Kenney (CC0, ver
## `audio/ui/LICENCIA_Kenney_CC0.txt`) para la interfaz. El banco es entonces
## ese stream solo, sin variantes: es una grabación y no se desafina. Lo que no
## tenga archivo sigue sintetizándose como siempre.
const CARPETA_GRABADOS := "res://audio/ui/"

## Retoque de volumen de cada grabación, en dB, sobre el volumen de su bus. Son
## clics que se oyen cientos de veces y van por el bus que ya usaba cada llamada
## (INTERFAZ, 0.35). Las grabaciones vienen normalizadas casi a 0 dBFS y la
## síntesis que sustituyen sonaba 9-25 dB más baja: sin este recorte cada clic
## taparía la música. Medido en `pruebas/ideas/sui_grabados.gd`: así quedan a
## +0,5/+2 dB de pico de la receta antigua (un pelo más presentes, nunca más).
const AJUSTE_DB := {"menu_mover": -8.0, "clic_suave": -21.0, "menu_aceptar": -16.0,
	"clic": -23.0, "menu_atras": -18.0, "menu_seccion": -19.0,
	## El silbato real de VCSL (CC0, `audio/ui/LICENCIA_VCSL_CC0.txt`), 26-10-2026.
	"silbato": -6.0, "pitido_final": -6.0, "medio_tiempo": -6.0,
	## El bombo de la barra con redoblante (VCSL, CC0), 26-10-2026. Ajustes tan
	## grandes porque la receta era ruido de 50-90 Hz con un pico muy bajo: se
	## iguala el pico, no se sube la percusión de golpe.
	"tambor": -19.5, "tambor_visitante": -35.0}

func ruta_grabado(nombre: String) -> String:
	return CARPETA_GRABADOS + nombre + ".ogg"

## El banco de un nombre: la grabación si la hay; si no, la síntesis.
func _crear_banco(nombre: String) -> Array:
	var ruta := ruta_grabado(nombre)
	if ResourceLoader.exists(ruta):
		var st := load(ruta) as AudioStream
		if st != null:
			return [st]
	return _sintetizar_banco(nombre)

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
		var b := _crear_banco(nombre)
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
	var nuevo := _crear_banco(nombre)
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
	_aviso_visual(nombre)
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
	p.volume_db = linear_to_db(maxf(0.001, float(volumen[bus]))) + float(AJUSTE_DB.get(nombre, 0.0))
	p.play()

## M-283: el aviso escrito del sonido (aunque el sonido esté apagado). La capa se crea la primera vez que hace falta.
var _avisos: AvisosSonido
func _aviso_visual(nombre: String) -> void:
	if not AvisosSonido.TEXTOS.has(nombre) or not AvisosSonido.activo():
		return
	if _avisos == null:
		_avisos = AvisosSonido.new()
		add_child(_avisos)
	_avisos.avisar(nombre)

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
	var w := variantes[0] as AudioStreamWAV
	if w == null:
		return _ficha_grabado(variantes)
	var pico := 0
	for i in range(0, w.data.size() - 1, 64):
		pico = maxi(pico, absi(w.data.decode_s16(i)))
	return {
		"variantes": variantes.size(),
		"segundos": float(w.data.size() / 2) / float(FRECUENCIA),
		"pico": pico,
		"grabado": false,
	}

## La misma ficha para una grabación: se decodifica entera con `mix_audio` y el
## pico se da en la escala de 16 bits de la síntesis, para que los umbrales del
## banco de pruebas valgan igual para las dos.
func _ficha_grabado(variantes: Array) -> Dictionary:
	var st: AudioStream = variantes[0]
	var pb := st.instantiate_playback()
	pb.start(0.0)
	var pico := 0.0
	var vueltas := 0
	while pb.is_playing() and vueltas < 400:
		for m: Vector2 in pb.mix_audio(1.0, 1024):
			pico = maxf(pico, maxf(absf(m.x), absf(m.y)))
		vueltas += 1
	return {
		"variantes": variantes.size(),
		"segundos": st.get_length(),
		"pico": int(pico * 32767.0),
		"grabado": true,
	}
