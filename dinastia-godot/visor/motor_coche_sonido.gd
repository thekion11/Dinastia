class_name MotorCocheSonido
extends AudioStreamPlayer
## EL MOTOR DEL COCHE SUENA (21-10-2026, M-173). Conducir era mudo. Como el resto
## del sonido del juego, no es un fichero: se sintetiza en el momento (un
## `AudioStreamGenerator`) y así puede seguir de verdad a lo que hace el coche:
##   · las REVOLUCIONES salen de la velocidad y la marcha (5 marchas: al llegar
##     arriba se cambia y la nota cae, como en un coche de verdad);
##   · pisar el acelerador sube el volumen y el «gruñido» (más armónicos);
##   · al ralentí, un murmullo grave con su vaivén.
## Tres armónicos de la frecuencia de encendido + un poco de ruido filtrado.
## `poner(vel, acelera)` se llama cada fotograma desde `ExploradorCiudad`.

const MEZCLA := 22050.0
## km/h a los que cada marcha llega al corte (la 5.ª no tiene techo).
const MARCHAS := [0.0, 22.0, 42.0, 66.0, 92.0, 140.0]
const RPM_RALENTI := 850.0
const RPM_CORTE := 5600.0

var rpm := RPM_RALENTI
var marcha := 1
var _carga := 0.0
var _fase := 0.0
var _ruido := 0.0
var _vol := 0.0
var _gen: AudioStreamGeneratorPlayback
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	var g := AudioStreamGenerator.new()
	g.mix_rate = MEZCLA
	g.buffer_length = 0.12
	stream = g
	_rng.seed = 7
	if Sonido.encendido:
		play()
		_gen = get_stream_playback()

## Las revoluciones para una velocidad (m/s) y la marcha que toca.
static func rpm_de(vel_ms: float) -> Vector2:
	var kmh := absf(vel_ms) * 3.6
	var m := 1
	while m < MARCHAS.size() - 1 and kmh > float(MARCHAS[m]):
		m += 1
	var desde := float(MARCHAS[m - 1])
	var hasta := float(MARCHAS[m]) if m < MARCHAS.size() - 1 else 180.0
	var k := clampf((kmh - desde) / maxf(hasta - desde, 1.0), 0.0, 1.0)
	## En cada marcha se sube de ~2.000 al corte; parado, ralentí.
	var r := RPM_RALENTI if kmh < 3.0 else lerpf(1900.0, RPM_CORTE, k)
	return Vector2(r, m)

func poner(vel_ms: float, acelera: float) -> void:
	var rm := rpm_de(vel_ms)
	marcha = int(rm.y)
	## Las revoluciones no saltan: persiguen su valor (al cambiar de marcha caen
	## rápido, al acelerar suben algo más despacio).
	var rapidez := 9.0 if rm.x < rpm else 4.0
	rpm = lerpf(rpm, rm.x, clampf(get_process_delta_time() * rapidez, 0.0, 1.0))
	_carga = lerpf(_carga, clampf(acelera, 0.0, 1.0), clampf(get_process_delta_time() * 6.0, 0.0, 1.0))
	_vol = 0.18 + 0.22 * _carga + 0.12 * (rpm - RPM_RALENTI) / (RPM_CORTE - RPM_RALENTI)
	volume_db = linear_to_db(maxf(0.001, float(Sonido.volumen[Sonido.Bus.EFECTOS]) * 0.9))
	_rellenar()

func _rellenar() -> void:
	if _gen == null:
		return
	var n := _gen.get_frames_available()
	## Frecuencia de encendido de un 4 cilindros: rpm / 60 × 2.
	var f := rpm / 30.0
	var paso := f / MEZCLA
	for i in n:
		_fase = fmod(_fase + paso, 1.0)
		var a := TAU * _fase
		## Fundamental + armónicos; con carga, más del 3.º (el gruñido).
		var s := sin(a) * 0.55 + sin(a * 2.0) * 0.28 + sin(a * 3.0) * (0.08 + 0.22 * _carga)
		## El vaivén del ralentí y el escape: ruido filtrado (paso bajo simple).
		_ruido = lerpf(_ruido, _rng.randf_range(-1.0, 1.0), 0.08)
		s += _ruido * (0.18 + 0.15 * _carga)
		s *= _vol * (0.9 + 0.1 * sin(a * 0.25))
		_gen.push_frame(Vector2(s, s))
