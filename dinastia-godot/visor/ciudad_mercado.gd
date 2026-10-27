class_name CiudadMercado
extends RefCounted
## EL MERCADO CON PUESTOS (27-10-2026, relleno de la ciudad; P2-8 de la auditoría: «sin puestos, toldos ni cajas de fruta»). La nave (zócalo
## naranja y bóveda verde) gana su fachada modular con escaparates y marquesina al sur, una calle de puestos delante (`montana_rusa/stall-*`,
## CC0, de cara al visitante), cajas de fruta y verdura apiladas ante cada puesto y barriles en las esquinas.
const PUESTOS := ["stall-food", "stall-drinks", "stall-food", "stall-information", "stall-drinks", "stall-food"]
const RUTA := "res://assets/kenney/montana_rusa/%s.glb"
const BARRIL := "res://assets/kenney/comida/barrel.glb"
const FRUTAS := [Color(0.9, 0.35, 0.15), Color(0.85, 0.15, 0.2), Color(0.35, 0.65, 0.2), Color(0.95, 0.8, 0.2), Color(0.55, 0.25, 0.5)]

static func montar(ex: CiudadExpansion, c: Vector3, w: float, f: float) -> void:
	var b := ex.b
	var y := 0.3
	var h := absi(hash(Vector2(c.x * 1.1, c.z * 0.7)))
	## La fachada de la nave (la bóveda se queda encima).
	FachadaModular.montar(ex, c.x, c.z + f * 0.35, y, w * 0.8, 1)
	## Una calle de puestos delante de la fachada, de cara al sur, y dos más a los lados.
	var n := 6
	var zf := c.z + f * 0.35 + 9.0
	for k in n:
		var x := c.x + (float(k) - float(n - 1) / 2.0) * (w * 0.8 / float(n))
		var ruta := RUTA % PUESTOS[(h + k) % PUESTOS.size()]
		ex._pieza_kit(ruta, Vector3(x, y, zf), ex._escala_ancho(ruta, 4.0), PI)
		_cajas(b, Vector3(x, y, zf + 3.2), h + k)
	for sx: float in [-1.0, 1.0]:
		for k in 2:
			var ruta2 := RUTA % PUESTOS[(h + k + 3) % PUESTOS.size()]
			var p := Vector3(c.x + sx * (w * 0.5 - 4.0), y, c.z + f * 0.05 + float(k) * 12.0)
			ex._pieza_kit(ruta2, p, ex._escala_ancho(ruta2, 4.0), -PI * 0.5 * sx)
			_cajas(b, p + Vector3(-sx * 3.2, 0, 0), h + k + 7)
	## Barriles en las esquinas del frente.
	for sx: float in [-1.0, 1.0]:
		ex._pieza_kit(BARRIL, Vector3(c.x + sx * w * 0.42, y, c.z + f * 0.35 + 5.0), ex._escala_ancho(BARRIL, 1.0), 0.0)

## Cuatro cajas de fruta con su montón de color (cajas de 0,6 m en dos pisos).
static func _cajas(b: CityBuilder, p: Vector3, semilla: int) -> void:
	var madera := b._mat_simple(Color(0.55, 0.4, 0.25), 0.9)
	for i in 4:
		var q := p + Vector3(float(i % 2) * 0.7 - 0.35, 0.0, float(i / 2) * 0.7 - 0.35)
		b._caja_en(q + Vector3(0, 0.25, 0), Vector3(0.6, 0.5, 0.6), madera)
		b._caja_en(q + Vector3(0, 0.55, 0), Vector3(0.5, 0.18, 0.5), b._mat_simple(FRUTAS[(semilla + i) % FRUTAS.size()], 0.7))
