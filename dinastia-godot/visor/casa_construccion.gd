class_name CasaConstruccion
extends RefCounted
## LEVANTA LA CASA DEL PERSONAJE EN 3D a partir del plano (`CasaPlano`), sin la ciudad (10-11, «solo club»): suelos por
## habitación, paredes con puertas y dinteles, techo, ventanas con luz, la puerta de la calle, los muebles del kit de Kenney
## (`Modulos`) y una luz cálida por habitación. Solo piezas de obra (`PiezasObra`) y muebles ya existentes.

const PARED := Color("ece6da")
const ZOCALO := Color("8a7a66")
const MARCO := Color("5b4632")
const CIELO := Color(0.55, 0.74, 0.92)

static func construir(raiz: Node3D) -> void:
	_suelos(raiz)
	_paredes(raiz)
	_techo(raiz)
	_ventanas(raiz)
	_puerta_calle(raiz)
	_muebles(raiz)
	_luces(raiz)

static func entorno() -> Environment:
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.1, 0.11, 0.13)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.82, 0.8, 0.78)
	e.ambient_light_energy = 0.42
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	return e

static func _suelos(raiz: Node3D) -> void:
	for s: Array in CasaPlano.SALAS:
		var x0 := float(s[1])
		var z0 := float(s[2])
		var w := float(s[3]) - x0
		var f := float(s[4]) - z0
		var c := Color(String(s[5]))
		PiezasObra._caja(raiz, Vector3(x0 + w / 2.0, -0.05, z0 + f / 2.0), Vector3(w, 0.1, f), PiezasObra._mat(c, 0.7), false)

static func _paredes(raiz: Node3D) -> void:
	var alto := CasaPlano.ALTO
	for r in CasaPlano.paredes():
		var c := r.get_center()
		PiezasObra._caja(raiz, Vector3(c.x, alto / 2.0, c.y), Vector3(r.size.x, alto, r.size.y), PiezasObra._mat(PARED, 0.9), false)
		## Zócalo: una franja más oscura al pie, que hace de la pared algo más que una caja.
		PiezasObra._caja(raiz, Vector3(c.x, 0.06, c.y), Vector3(r.size.x + 0.02, 0.12, r.size.y + 0.02), PiezasObra._mat(ZOCALO, 0.8), false)
	## Dinteles y marcos de cada puerta (la puerta de 2,1 m; encima, pared hasta el techo).
	for h: Array in CasaPlano.huecos():
		var horizontal := String(h[0]) == "h"
		var eje := float(h[1])
		var a := float(h[2])
		var b := float(h[3])
		var medio := (a + b) / 2.0
		var largo := b - a
		var g := CasaPlano.GROSOR
		var alto_puerta := 2.1
		var sobre := alto - alto_puerta
		if horizontal:
			PiezasObra._caja(raiz, Vector3(medio, alto_puerta + sobre / 2.0, eje), Vector3(largo, sobre, g), PiezasObra._mat(PARED, 0.9), false)
			PiezasObra._caja(raiz, Vector3(medio, alto_puerta + 0.03, eje), Vector3(largo + 0.12, 0.06, g + 0.04), PiezasObra._mat(MARCO, 0.6), false)
			for lado in [a + 0.03, b - 0.03]:
				PiezasObra._caja(raiz, Vector3(lado, alto_puerta / 2.0, eje), Vector3(0.06, alto_puerta, g + 0.04), PiezasObra._mat(MARCO, 0.6), false)
		else:
			PiezasObra._caja(raiz, Vector3(eje, alto_puerta + sobre / 2.0, medio), Vector3(g, sobre, largo), PiezasObra._mat(PARED, 0.9), false)
			PiezasObra._caja(raiz, Vector3(eje, alto_puerta + 0.03, medio), Vector3(g + 0.04, 0.06, largo + 0.12), PiezasObra._mat(MARCO, 0.6), false)
			for lado in [a + 0.03, b - 0.03]:
				PiezasObra._caja(raiz, Vector3(eje, alto_puerta / 2.0, lado), Vector3(g + 0.04, alto_puerta, 0.06), PiezasObra._mat(MARCO, 0.6), false)

static func _techo(raiz: Node3D) -> void:
	PiezasObra._caja(raiz, Vector3(CasaPlano.ANCHO / 2.0, CasaPlano.ALTO + 0.05, CasaPlano.FONDO / 2.0),
		Vector3(CasaPlano.ANCHO + 0.4, 0.1, CasaPlano.FONDO + 0.4), PiezasObra._mat(Color("f4f1ea"), 0.95), false)

## Ventanas: un marco oscuro y un cristal que brilla (la luz del día), pegadas a la cara interior de la pared exterior.
static func _ventanas(raiz: Node3D) -> void:
	var cristal := PiezasObra._mat_unico(CIELO, 0.2)
	cristal.emission_enabled = true
	cristal.emission = CIELO
	cristal.emission_energy_multiplier = 0.7
	var d := CasaPlano.GROSOR / 2.0
	for v: Array in CasaPlano.VENTANAS:
		var pos := float(v[1])
		var ancho := float(v[2])
		var y0 := float(v[3])
		var alto := float(v[4])
		var y := y0 + alto / 2.0
		match String(v[0]):
			"n":
				PiezasObra._caja(raiz, Vector3(pos, y, d + 0.01), Vector3(ancho + 0.12, alto + 0.12, 0.04), PiezasObra._mat(MARCO, 0.6), false)
				PiezasObra._caja(raiz, Vector3(pos, y, d + 0.03), Vector3(ancho, alto, 0.02), cristal, false)
			"s":
				var z := CasaPlano.FONDO - d - 0.01
				PiezasObra._caja(raiz, Vector3(pos, y, z), Vector3(ancho + 0.12, alto + 0.12, 0.04), PiezasObra._mat(MARCO, 0.6), false)
				PiezasObra._caja(raiz, Vector3(pos, y, z - 0.02), Vector3(ancho, alto, 0.02), cristal, false)
			"e":
				var x := CasaPlano.ANCHO - d - 0.01
				PiezasObra._caja(raiz, Vector3(x, y, pos), Vector3(0.04, alto + 0.12, ancho + 0.12), PiezasObra._mat(MARCO, 0.6), false)
				PiezasObra._caja(raiz, Vector3(x - 0.02, y, pos), Vector3(0.02, alto, ancho), cristal, false)
			_:
				PiezasObra._caja(raiz, Vector3(d + 0.01, y, pos), Vector3(0.04, alto + 0.12, ancho + 0.12), PiezasObra._mat(MARCO, 0.6), false)
				PiezasObra._caja(raiz, Vector3(d + 0.03, y, pos), Vector3(0.02, alto, ancho), cristal, false)

## La puerta de la calle, cerrada, en la pared oeste.
static func _puerta_calle(raiz: Node3D) -> void:
	var p := CasaPlano.PUERTA_CALLE
	PiezasObra._caja(raiz, Vector3(CasaPlano.GROSOR / 2.0 + 0.03, 1.05, p.y), Vector3(0.06, 2.1, 1.0), PiezasObra._mat(Color("6b4a2e"), 0.55), false)
	PiezasObra._caja(raiz, Vector3(CasaPlano.GROSOR / 2.0 + 0.03, 2.13, p.y), Vector3(0.08, 0.06, 1.12), PiezasObra._mat(MARCO, 0.6), false)
	for lado in [p.y - 0.53, p.y + 0.53]:
		PiezasObra._caja(raiz, Vector3(CasaPlano.GROSOR / 2.0 + 0.03, 1.05, lado), Vector3(0.08, 2.1, 0.06), PiezasObra._mat(MARCO, 0.6), false)
	PiezasObra._caja(raiz, Vector3(CasaPlano.GROSOR / 2.0 + 0.08, 1.0, p.y + 0.38), Vector3(0.05, 0.05, 0.14), PiezasObra._mat(Color("c9b27a"), 0.3), false)

static func _muebles(raiz: Node3D) -> void:
	var cont := Node3D.new()
	cont.name = "Muebles"
	raiz.add_child(cont)
	for m: Array in CasaPlano.MUEBLES:
		var n := Modulos.tomar(String(m[0]))
		cont.add_child(n)
		n.position = Vector3(float(m[1]), float(m[4]), float(m[2]))
		n.rotation.y = float(m[3])

static func _luces(raiz: Node3D) -> void:
	for s: Array in CasaPlano.SALAS:
		var c := CasaPlano.centro_de(String(s[0]))
		var grande := (float(s[3]) - float(s[1])) > 6.0
		var puntos: Array = [Vector2(2.75, 5.5), Vector2(8.25, 5.5)] if grande else [c]
		for pt: Vector2 in puntos:
			var l := OmniLight3D.new()
			l.position = Vector3(pt.x, CasaPlano.ALTO - 0.4, pt.y)
			l.light_color = Color(1.0, 0.94, 0.82)
			l.light_energy = 0.75
			l.omni_range = 7.0
			l.shadow_enabled = false
			raiz.add_child(l)
