extends Node
## (Sin `class_name`: este script ES el autoload `Musica`. Godot rechaza una
## clase global con el nombre de un singleton.)
## LA MÚSICA DEL JUEGO. Seis piezas, y ninguna es un fichero.
##
## POR QUÉ NO SE DESCARGA MÚSICA LIBRE. Se puede —hay bancos de CC0 decentes—,
## pero traía tres problemas que aquí no hacen falta pagar: un MP3 decente son
## 3-5 MB por pieza y el proyecto tiene un techo de 1 GB con 1.102 equipaciones
## y 24 fondos dentro; la licencia hay que arrastrarla y citarla en el paquete;
## y sobre todo, una pista grabada no puede CAMBIAR con la partida. Esto sí:
## la misma pieza sube de intensidad si vas ganando y se apaga si te van a
## echar, porque se compone en el momento.
##
## Es exactamente la misma decisión que ya tomó `Sonido` con los efectos, y por
## las mismas razones. Cero ficheros de audio en todo el juego.
##
## CÓMO ESTÁ HECHA. Cada pieza es una progresión de acordes que se repite, con
## cuatro capas encima: bajo, acordes sostenidos, un arpegio que lleva la
## melodía y una percusión suave. Todo con osciladores y una envolvente por
## nota, más un eco corto al final que le da sitio —sin eco suena a teclado de
## juguete; con 180 ms de retardo al 28% suena a sala—.
##
## NO TOCA `Azar`. Ni una sola decisión de esta música sale del generador
## determinista de la partida: las variaciones vienen de un `RandomNumberGenerator`
## propio con semilla fija por pieza. Un adorno que consumiera `Azar` cambiaría
## la liga entera según cuánto rato hubieras dejado la música puesta.

const FRECUENCIA := 22050

## Los grados de la escala, en semitonos sobre la tónica.
const LA4 := 440.0

## clave -> ficha de la pieza.
##
## `acordes` son grados en semitonos sobre la tónica, uno por compás.
## `raiz` es la tónica en Hz. `bpm` manda el tempo. `capas` dice qué suena.
const PIEZAS := {
	"oficina": {
		"nombre": "Oficina (menús)",
		"desc": "Lo que suena mientras miras números. Lenta, sin melodía marcada y en modo menor suave: tiene que poder estar puesta una hora sin que la notes.",
		"raiz": 130.81, "bpm": 72,
		"acordes": [[0, 3, 7], [-2, 2, 5], [-4, 0, 3], [-5, -1, 2]],
		"capas": {"bajo": 0.16, "pad": 0.10, "arpegio": 0.055, "percusion": 0.0},
		"forma": "seno",
	},
	"vestuario": {
		"nombre": "Vestuario (antes del partido)",
		"desc": "Un pulso que no llega a ser ritmo. No hay melodía: hay espera.",
		"raiz": 110.0, "bpm": 84,
		"acordes": [[0, 3, 7], [0, 3, 7], [-3, 0, 4], [-3, 0, 4]],
		"capas": {"bajo": 0.20, "pad": 0.07, "arpegio": 0.0, "percusion": 0.10},
		"forma": "triangulo",
	},
	"tension": {
		"nombre": "Tensión (los últimos minutos)",
		"desc": "Sube sin resolver nunca. Es la pieza que se pone sola cuando vas empatando el último partido del año.",
		"raiz": 98.0, "bpm": 104,
		"acordes": [[0, 3, 7], [1, 4, 8], [0, 3, 7], [-1, 3, 6]],
		"capas": {"bajo": 0.22, "pad": 0.09, "arpegio": 0.075, "percusion": 0.13},
		"forma": "sierra",
	},
	"gloria": {
		"nombre": "Gloria (celebración)",
		"desc": "Mayor, alta y con la percusión abierta. Dura lo que dura una vuelta olímpica.",
		"raiz": 146.83, "bpm": 118,
		"acordes": [[0, 4, 7], [5, 9, 12], [-3, 2, 5], [0, 4, 7]],
		"capas": {"bajo": 0.20, "pad": 0.10, "arpegio": 0.095, "percusion": 0.14},
		"forma": "sierra",
	},
	"barra": {
		"nombre": "Barra (la grada)",
		"desc": "Bombo, trompeta y poco más. Es la única que suena a gente y no a estudio.",
		"raiz": 123.47, "bpm": 96,
		"acordes": [[0, 4, 7], [0, 4, 7], [5, 9, 12], [-2, 2, 5]],
		"capas": {"bajo": 0.24, "pad": 0.05, "arpegio": 0.085, "percusion": 0.20},
		"forma": "cuadrada",
	},
	"invierno": {
		"nombre": "Invierno (parón de mitad de año)",
		"desc": "La más lenta y la más vacía. Para las semanas en que no se juega.",
		"raiz": 87.31, "bpm": 60,
		"acordes": [[0, 3, 7], [-5, -1, 2], [-2, 2, 5], [-4, 0, 3]],
		"capas": {"bajo": 0.14, "pad": 0.12, "arpegio": 0.045, "percusion": 0.0},
		"forma": "seno",
	},
}

var encendida := false
var volumen := 0.30
## La pieza elegida a mano, o "" para que la elija el juego según lo que pase.
var pieza := ""
var automatica := true

var _voz: AudioStreamPlayer = null
var _cache: Dictionary = {}
var _sonando := ""

## COMPUESTA EN SEGUNDO PLANO (25-9-2026). Cada pieza tarda casi un segundo
## en componerse (medido: 0,8-1,1 s por pieza) y antes se hacía en el hilo
## principal justo cuando se pedía: al entrar al partido o al llegar los
## minutos finales ("tension"), la pantalla se congelaba un segundo. Ahora un
## hilo las compone todas al arrancar, y si se pide una que todavía no está,
## pasa la primera de la cola y empieza a sonar en cuanto está lista.
var _mutex := Mutex.new()
var _hilo: Thread = null
var _parar := false
var _prioridad := ""
var _esperando := ""

func _ready() -> void:
	_voz = AudioStreamPlayer.new()
	## La música va en su propio reproductor, no en la rueda de ocho voces de
	## `Sonido`: es larga y se pisaría con el noveno efecto que sonara.
	add_child(_voz)
	_hilo = Thread.new()
	_hilo.start(_componer_en_fondo, Thread.PRIORITY_LOW)

func _componer_en_fondo() -> void:
	var pendientes: Array = PIEZAS.keys()
	while not pendientes.is_empty() and not _parar:
		_mutex.lock()
		var clave: String = _prioridad if pendientes.has(_prioridad) else String(pendientes[0])
		var ya := _cache.has(clave)
		_mutex.unlock()
		pendientes.erase(clave)
		if ya:
			continue
		var w := _componer(clave)
		_mutex.lock()
		if not _cache.has(clave):
			_cache[clave] = w
		_mutex.unlock()
		call_deferred("_pieza_lista", clave)

func _pieza_lista(clave: String) -> void:
	if _esperando == clave:
		_esperando = ""
		poner(clave)

func _exit_tree() -> void:
	_parar = true
	if _hilo != null and _hilo.is_started():
		_hilo.wait_to_finish()

## Pone una pieza. Si ya está sonando esa, no hace nada —volver a llamar desde
## un repintado no debe cortar la música y empezarla otra vez—.
func poner(clave: String) -> void:
	if not encendida or not PIEZAS.has(clave):
		if not encendida:
			parar()
		return
	if _sonando == clave and _voz.playing:
		_voz.volume_db = linear_to_db(maxf(0.001, volumen))
		return
	## Si todavía no está compuesta y el hilo sigue vivo, se le pasa al frente
	## de la cola y se espera: nada de componer aquí y congelar la pantalla.
	_mutex.lock()
	var lista := _cache.has(clave)
	if not lista:
		_prioridad = clave
	_mutex.unlock()
	if not lista and _hilo != null and _hilo.is_alive():
		_esperando = clave
		return
	_sonando = clave
	_voz.stream = _pista(clave)
	_voz.volume_db = linear_to_db(maxf(0.001, volumen))
	_voz.play()

## Aplica el volumen a lo que ya está sonando, sin cortarlo. Lo llama el
## deslizador de Ajustes: subir el volumen no debe reiniciar la pieza.
func aplicar_volumen() -> void:
	if _voz != null:
		_voz.volume_db = linear_to_db(maxf(0.001, volumen))

func parar() -> void:
	_sonando = ""
	_esperando = ""
	if _voz != null:
		_voz.stop()

## Qué pieza pide el momento. Se llama desde la interfaz con lo que está
## pasando; si el usuario eligió una a mano, manda la suya.
func ambientar(situacion: String) -> void:
	if not encendida:
		parar()
		return
	if not automatica and PIEZAS.has(pieza):
		poner(pieza)
		return
	match situacion:
		"partido": poner("vestuario")
		"final": poner("tension")
		"celebracion": poner("gloria")
		"grada": poner("barra")
		"parón", "paron": poner("invierno")
		_: poner("oficina")

## La pista, generada una vez y guardada. Un minuto de audio a 22 kHz son 2,6 MB
## en memoria; seis piezas son 16 MB, y por eso se generan SOLO cuando se piden
## y no todas al arrancar.
func _pista(clave: String) -> AudioStreamWAV:
	_mutex.lock()
	var hecha: AudioStreamWAV = _cache.get(clave)
	_mutex.unlock()
	if hecha != null:
		return hecha
	var w := _componer(clave)
	_mutex.lock()
	if not _cache.has(clave):
		_cache[clave] = w
	w = _cache[clave]
	_mutex.unlock()
	return w

func _componer(clave: String) -> AudioStreamWAV:
	var p: Dictionary = PIEZAS[clave]
	var bpm := float(p["bpm"])
	var raiz := float(p["raiz"])
	var acordes: Array = p["acordes"]
	var capas: Dictionary = p["capas"]
	var forma := String(p["forma"])
	## Un compás de cuatro tiempos. La pieza entera son los acordes dos veces,
	## que a estos tempos sale entre 32 y 64 segundos.
	var seg_tiempo := 60.0 / bpm
	var seg_compas := seg_tiempo * 4.0
	var vueltas := 2
	var total := seg_compas * float(acordes.size() * vueltas)
	var n := int(total * float(FRECUENCIA))
	var m := PackedFloat32Array()
	m.resize(n)

	## Semilla fija por pieza: las mismas variaciones en cada partida y en cada
	## ordenador. La música no es un sorteo.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(clave)

	var compas := 0
	for vuelta in vueltas:
		for a in acordes:
			var t0 := float(compas) * seg_compas
			var grados: Array = a
			var fund: float = raiz * pow(2.0, float(grados[0]) / 12.0)

			## EL BAJO. La fundamental en el primer tiempo y en el tercero. Es lo
			## que sostiene el compás; sin él, los acordes flotan.
			if float(capas.get("bajo", 0.0)) > 0.0:
				var vb := float(capas["bajo"])
				_nota(m, fund * 0.5, t0, seg_tiempo * 1.8, vb, "seno")
				_nota(m, fund * 0.5, t0 + seg_tiempo * 2.0, seg_tiempo * 1.6, vb * 0.8, "seno")

			## LOS ACORDES SOSTENIDOS. Las tres notas a la vez, durando el compás
			## entero y muy bajas: son el colchón, no la canción.
			if float(capas.get("pad", 0.0)) > 0.0:
				var vp := float(capas["pad"])
				for g in grados:
					_nota(m, raiz * pow(2.0, float(g) / 12.0), t0, seg_compas * 0.95, vp, forma, 0.35)

			## EL ARPEGIO. Las mismas notas del acorde, una detrás de otra, en
			## corcheas. Es lo único que se parece a una melodía, y va una octava
			## arriba para que se despegue del colchón.
			if float(capas.get("arpegio", 0.0)) > 0.0:
				var va := float(capas["arpegio"])
				var orden := [0, 1, 2, 1, 2, 1, 0, 1]
				for i in orden.size():
					## Una de cada seis notas se salta: un arpegio perfectamente
					## regular suena a ejercicio de piano, no a música.
					if rng.randf() < 0.16:
						continue
					var g2: float = float(grados[int(orden[i]) % grados.size()])
					var oct := 2.0 if i % 4 == 3 else 1.0
					_nota(m, raiz * pow(2.0, g2 / 12.0) * 2.0 * oct,
						t0 + float(i) * seg_tiempo * 0.5, seg_tiempo * 0.45, va, forma)

			## LA PERCUSIÓN. Bombo en 1 y 3, caja en 2 y 4, y un charles en cada
			## corchea. Todo con ruido: no hace falta más para que haya pulso.
			if float(capas.get("percusion", 0.0)) > 0.0:
				var vd := float(capas["percusion"])
				for tiempo in 4:
					var tt := t0 + float(tiempo) * seg_tiempo
					if tiempo % 2 == 0:
						_golpe(m, tt, 0.16, 70.0, 45.0, vd)
					else:
						_golpe(m, tt, 0.12, 1400.0, 700.0, vd * 0.5)
					_golpe(m, tt + seg_tiempo * 0.5, 0.05, 5200.0, 3600.0, vd * 0.22)
			compas += 1

	_eco(m, 0.18, 0.28)
	## Un desvanecido de medio segundo al final que engancha con el principio: sin
	## esto, el bucle da un chasquido cada vuelta.
	var fade := int(0.4 * float(FRECUENCIA))
	for i in fade:
		var k := n - fade + i
		if k >= 0 and k < n:
			m[k] *= 1.0 - float(i) / float(fade)
	return _a_wav(m)

## Una nota con ataque y caída. `sostener` dice qué parte de la duración se
## mantiene alta antes de empezar a apagarse: 0 es un pizzicato, 0,35 es un
## acorde sostenido.
func _nota(m: PackedFloat32Array, hz: float, t0: float, dur: float, vol: float,
		forma: String, sostener: float = 0.0) -> void:
	var off := int(t0 * float(FRECUENCIA))
	var n := int(dur * float(FRECUENCIA))
	if n <= 0:
		return
	var paso := hz * TAU / float(FRECUENCIA)
	var ataque := maxf(0.004, dur * 0.06)
	for i in n:
		var k := off + i
		if k < 0 or k >= m.size():
			continue
		var t := float(i) / float(FRECUENCIA)
		var env := minf(t / ataque, 1.0)
		if t > dur * sostener:
			env *= exp(-3.4 * (t - dur * sostener) / maxf(0.001, dur))
		var f := float(i) * paso
		var s := 0.0
		match forma:
			"seno": s = sin(f)
			"cuadrada": s = 1.0 if sin(f) >= 0.0 else -1.0
			"sierra": s = fmod(f / TAU, 1.0) * 2.0 - 1.0
			"triangulo": s = absf(fmod(f / TAU, 1.0) * 4.0 - 2.0) - 1.0
			_: s = sin(f)
		m[k] = clampf(m[k] + s * env * vol, -1.0, 1.0)

## Un golpe de percusión: ruido con un barrido de filtro. Grave y largo es un
## bombo; agudo y corto, un charles.
func _golpe(m: PackedFloat32Array, t0: float, dur: float, f0: float, f1: float, vol: float) -> void:
	var off := int(t0 * float(FRECUENCIA))
	var n := int(dur * float(FRECUENCIA))
	var estado := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = int(f0) * 7919 + int(f1)
	for i in n:
		var k := off + i
		if k < 0 or k >= m.size():
			continue
		var t := float(i) / float(n)
		var corte: float = lerpf(f0, f1, t)
		var a: float = clampf(corte / float(FRECUENCIA) * 6.28, 0.02, 0.95)
		estado += a * (rng.randf_range(-1.0, 1.0) - estado)
		m[k] = clampf(m[k] + estado * exp(-5.0 * t) * vol, -1.0, 1.0)

## Un eco corto. Es lo único que separa "cuatro osciladores" de "música": sin
## sitio, las notas suenan pegadas a la cara.
func _eco(m: PackedFloat32Array, retraso: float, mezcla: float) -> void:
	var d := int(retraso * float(FRECUENCIA))
	if d <= 0:
		return
	for i in range(d, m.size()):
		m[i] = clampf(m[i] + m[i - d] * mezcla, -1.0, 1.0)

func _a_wav(m: PackedFloat32Array) -> AudioStreamWAV:
	var datos := PackedByteArray()
	datos.resize(m.size() * 2)
	for i in m.size():
		datos.encode_s16(i * 2, int(clampf(m[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = FRECUENCIA
	w.stereo = false
	## En bucle: la pieza dura menos de un minuto y tiene que poder estar puesta
	## toda una temporada.
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = m.size()
	w.data = datos
	return w

## Para el banco de pruebas: que una pieza suene a algo y no a silencio.
func ficha(clave: String) -> Dictionary:
	if not PIEZAS.has(clave):
		return {}
	var w := _pista(clave)
	var pico := 0
	for i in range(0, w.data.size() - 1, 128):
		pico = maxi(pico, absi(w.data.decode_s16(i)))
	return {
		"segundos": float(w.data.size() / 2) / float(FRECUENCIA),
		"pico": pico,
		"bucle": w.loop_mode == AudioStreamWAV.LOOP_FORWARD,
	}
