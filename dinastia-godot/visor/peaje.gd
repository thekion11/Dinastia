class_name Peaje
extends RefCounted
## LOS PEAJES DE LA AUTOPISTA (M-197, 3-11-2026): un pórtico con su caseta y su cartel «PEAJE · 2 €» en mitad de cada una de las cuatro rampas que suben al anillo.
## Al subir en coche por una rampa se cobra la tarifa de la cartera del DT (como la expendedora y las multas); bajar por ella es gratis. A pie no cobra.

const TARIFA := 2
const MEDIO_ANCHO := 8.5   ## la rampa mide 16 m

## Cada peaje: {p: centro en la rampa, n: dirección hacia la ciudad (sube a la autopista quien va en -n), a: distancia con signo del último fotograma}.
static var puntos: Array[Dictionary] = []

static func montar(b, enlaces: Array, alto: float, ancho: float, rampa: float) -> void:
	puntos.clear()
	var gris = b._mat_simple(Color(0.62, 0.63, 0.65), 0.6)
	var rojo = b._mat_simple(Color(0.78, 0.12, 0.1), 0.6)
	var cartel = b._mat_simple(Color(0.05, 0.28, 0.5), 0.7)
	for e: Vector3 in enlaces:
		var n := -e.normalized()
		var lat := Vector3(-n.z, 0, n.x)
		var c := e + n * (ancho * 0.5 + rampa * 0.5) + Vector3(0, alto * 0.5 + 0.4, 0)   ## la rampa a mitad de su subida
		for lado: float in [-1.0, 1.0]:
			b._caja_en(c + lat * (MEDIO_ANCHO + 0.6) * lado + Vector3(0, 2.8, 0), Vector3(0.8, 5.6, 0.8), gris)
		b._caja_en(c + Vector3(0, 5.6, 0), Vector3(MEDIO_ANCHO * 2.0 + 2.4, 1.6, 1.0) if absf(n.z) > 0.5 else Vector3(1.0, 1.6, MEDIO_ANCHO * 2.0 + 2.4), cartel)
		b._caja_en(c + Vector3(0, 1.3, 0), Vector3(2.0, 2.6, 5.0) if absf(n.z) > 0.5 else Vector3(5.0, 2.6, 2.0), gris)   ## la caseta, en la mediana de la rampa
		b._caja_en(c + Vector3(0, 2.7, 0), Vector3(2.4, 0.3, 5.4) if absf(n.z) > 0.5 else Vector3(5.4, 0.3, 2.4), rojo)
		var l := Label3D.new()
		l.text = Idiomas.t("PEAJE · %d €") % TARIFA
		l.font_size = 64
		l.pixel_size = 0.012
		l.outline_size = 8
		l.modulate = Color(1, 1, 1)
		l.position = c + n * 0.62 + Vector3(0, 5.6, 0)
		l.rotation.y = atan2(n.x, n.z)   ## de cara a quien llega desde la ciudad
		l.visibility_range_end = 120.0
		b.add_child(l)
		puntos.append({"p": c, "n": n, "a": NAN})

## ¿Cruzó el coche (de `antes` a `ahora`) la línea del peaje hacia la autopista, dentro de la anchura de la rampa?
static func sube(punto: Dictionary, antes: Vector3, ahora: Vector3) -> bool:
	var n: Vector3 = punto["n"]
	var p: Vector3 = punto["p"]
	var lat := Vector3(-n.z, 0, n.x)
	var a0 := (antes - p).dot(n)
	var a1 := (ahora - p).dot(n)
	if a0 <= 0.0 or a1 > 0.0 or a0 > 30.0:
		return false
	return absf((ahora - p).dot(lat)) < MEDIO_ANCHO

static var _antes := Vector3(1e9, 0, 0)

## Cada fotograma en coche: cobra si cruzó un peaje hacia arriba.
static func vigilar(vida, pos: Vector3) -> void:
	var previo := _antes
	_antes = pos
	if previo.x > 1e8:
		return
	for pu in puntos:
		if sube(pu, previo, pos):
			cobrar(vida)
			return

static func cobrar(vida) -> bool:
	var m: Mundo = vida.mundo
	if m == null or m.roles == null:
		return false
	var dia := CarteraDT.clave_dia(m.anio, m.semana, m.reloj.dia)
	var r := m.roles.cartera.cobrar(m.roles, TARIFA, "Peaje de la autopista", dia)
	if String(r["error"]) != "":
		vida._notificar(Idiomas.t("🛣️ Peaje de %d €: ") % TARIFA + CarteraDT.texto_error(String(r["error"]), TARIFA))
	else:
		vida._notificar(Idiomas.t("🛣️ Peaje de %d € (pagado en %s).") % [TARIFA, Idiomas.t(String(r["via"]))])
	Sonido.toca("clic", Sonido.Bus.EFECTOS)
	return true
