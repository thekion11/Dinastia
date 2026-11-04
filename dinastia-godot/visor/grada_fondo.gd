class_name GradaFondo
extends AudioStreamPlayer
## EL FONDO DE LA GRADA (3-11-2026, orden 22: «el sonido se siente apagado»). El estadio tenía golpes sueltos (tambor,
## cántico, aplauso cada tanto) y un murmullo de 3 s al saque inicial; entre uno y otro, silencio. Esto es la capa
## continua: un bucle de 8 s de multitud (ruido filtrado en tres bandas con ondulación lenta, extremos fundidos para
## que no se note el empalme) que sube cuando el balón se acerca a un arco y se dispara un momento tras un gol.
## Va por el volumen de AMBIENTE de `Sonido`. Se sintetiza una vez y se guarda.

const SEG := 8.0
const BASE_DB := -14.0      ## en calma
const PELIGRO_DB := 7.0     ## cuánto sube con el balón en el área
static var _wav: AudioStreamWAV = null

## Ruido de grada: tres bandas (graves de fondo, voces, silbidos) con ondulación lenta; el final se funde con el
## principio (0,5 s) para que el bucle sea continuo.
static func onda() -> AudioStreamWAV:
	if _wav != null:
		return _wav
	var hz := Sonido.FRECUENCIA
	var n := int(SEG * float(hz))
	var m := PackedFloat32Array()
	m.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261103
	var bandas := [[0.03, 0.55], [0.12, 0.35], [0.45, 0.10]]   ## [coeficiente del filtro, volumen]
	var estado := [0.0, 0.0, 0.0]
	for i in n:
		var t := float(i) / float(hz)
		var v := 0.0
		for b in bandas.size():
			estado[b] += float(bandas[b][0]) * (rng.randf_range(-1.0, 1.0) - float(estado[b]))
			v += float(estado[b]) * float(bandas[b][1])
		var ola := 0.75 + 0.25 * sin(t * TAU / SEG * 2.0) * sin(t * TAU / SEG * 3.0)
		m[i] = v * ola * 0.9
	var fundido := int(0.5 * float(hz))
	for i in fundido:
		var a := float(i) / float(fundido)
		m[i] = m[i] * a + m[n - fundido + i] * (1.0 - a)
	m.resize(n - fundido)
	_wav = Sonido._a_wav(m)
	_wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_wav.loop_begin = 0
	_wav.loop_end = m.size()
	return _wav

## Quién dice cuánto peligro hay (0..1). Lo pone el estadio (la distancia del balón al arco más cercano).
var peligro: Callable
var _subida := 0.0

static func montar(padre: Node, peligro_: Callable) -> GradaFondo:
	var g := GradaFondo.new()
	g.name = "GradaFondo"
	g.stream = onda()
	g.peligro = peligro_
	padre.add_child(g)
	g.volume_db = g._objetivo_db()
	g.play()
	return g

## El enganche del estadio (`estadio_p5`): una sola vez por partido; el peligro sale de lo lejos que está el balón
## del centro a lo largo (z), y cada gol hace estallar la grada.
static func para_estadio(estadio: Node, partido: Partido) -> void:
	if is_instance_valid(estadio.get_node_or_null("GradaFondo")):
		return
	var g := montar(estadio, func() -> float:
		var motor: Variant = estadio.get("_motor")
		if motor == null or not is_instance_valid(motor.balon):
			return 0.3
		return clampf((absf((motor.balon as Node3D).position.z) - 22.0) / 30.0, 0.0, 1.0))
	if partido != null:
		partido.gol.connect(func(_c: Club, _a: Jugador, _m: int, _as: Jugador) -> void:
			if is_instance_valid(g):
				g.gol())

## Tras un gol: la grada estalla y baja en unos segundos.
func gol() -> void:
	_subida = 1.0

func _objetivo_db() -> float:
	var vol := float(Sonido.volumen[Sonido.Bus.AMBIENTE])
	if vol <= 0.001 or not Sonido.encendido:
		return -80.0
	var p := clampf(float(peligro.call()) if peligro.is_valid() else 0.0, 0.0, 1.0)
	return linear_to_db(vol) + BASE_DB + PELIGRO_DB * p + 10.0 * _subida

func _process(delta: float) -> void:
	_subida = maxf(0.0, _subida - delta / 4.0)
	volume_db = lerpf(volume_db, _objetivo_db(), clampf(delta * 3.0, 0.0, 1.0))
