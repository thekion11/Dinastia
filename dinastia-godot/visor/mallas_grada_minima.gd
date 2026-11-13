class_name MallasGradaMinima
extends RefCounted
## MALLAS DE GRADA SIN CARAS OCULTAS (13-11-2026, orden del dueño: +15 FPS de promedio en el teléfono; frente DIBUJO). En MÍNIMA las butacas lejanas (3.653 grupos × 36 triángulos
## = 131 mil) y el público (1.387 personas × 45 = 62 mil) eran lo que más triángulos sumaba del estadio. Aquí, las mismas piezas SIN las caras que ninguna cámara ve
## (el suelo de cada caja, que va pegado a la viga o al escalón).
## Medido con `MULTI=1` de `pruebas/medir_partido_jugable.gd` (instancias × triángulos de cada MultiMesh); detalle en `docs/04_auditorias/rendimiento_120fps.md`.
static var _butaca: Mesh = null
static var _butaca_lejos: Mesh = null

## Un triángulo con su normal exterior `n`: Godot considera frontal el giro HORARIO visto desde fuera, así que se ordena según esa normal.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	if (b - a).cross(c - a).dot(n) > 0.0:
		var t := b
		b = c
		c = t
	for v: Vector3 in [a, b, c]:
		st.set_normal(n)
		st.add_vertex(v)

## Una caja de `tam` centrada en `c` (sin inclinar), con las caras que se pidan: arriba, abajo, frente (+Z), fondo (-Z), izquierda, derecha.
static func _caja(st: SurfaceTool, tam: Vector3, c: Vector3, giro_x: float, abajo: bool, arriba: bool) -> void:
	var b := Basis(Vector3(1, 0, 0), giro_x)
	var h := tam * 0.5
	var caras := [
		[Vector3.FORWARD * -1.0, [Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z)], true],        # +Z
		[Vector3.FORWARD, [Vector3(h.x, -h.y, -h.z), Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z)], true],           # -Z
		[Vector3.RIGHT, [Vector3(h.x, -h.y, h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z)], true],                # +X
		[Vector3.LEFT, [Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, h.y, -h.z)], true],             # -X
		[Vector3.UP, [Vector3(-h.x, h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, h.y, -h.z), Vector3(-h.x, h.y, -h.z)], arriba],                 # +Y
		[Vector3.DOWN, [Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z)], abajo]]           # -Y
	for cara: Array in caras:
		if not bool(cara[2]):
			continue
		var n := b * (cara[0] as Vector3)
		var v: Array = cara[1]
		_tri(st, b * (v[0] as Vector3) + c, b * (v[1] as Vector3) + c, b * (v[2] as Vector3) + c, n)
		_tri(st, b * (v[0] as Vector3) + c, b * (v[2] as Vector3) + c, b * (v[3] as Vector3) + c, n)

## La butaca de MÍNIMA: asiento, respaldo corrido y viga (como antes: tres cajas por grupo de tres) pero sin el suelo de ninguna y sin el techo de la viga
## (tapado por el asiento): 28 triángulos en vez de 36.
static func butaca() -> Mesh:
	if _butaca != null:
		return _butaca
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_caja(st, Vector3(1.46, 0.07, 0.40), Vector3(-0.05, 0.40, 0.04), 0.0, false, true)
	_caja(st, Vector3(1.46, 0.38, 0.05), Vector3(-0.05, 0.58, -0.20), -0.14, false, true)
	_caja(st, Vector3(1.40, 0.30, 0.06), Vector3(-0.05, 0.20, -0.08), 0.0, false, false)
	_butaca = st.commit()
	return _butaca

## La butaca lejana de MEDIA y superiores (13-11): la misma de siempre (asiento, tres respaldos, dos reposabrazos y viga) sin el suelo de ninguna caja ni el techo de la viga:
## 68 triángulos en vez de 84, visualmente idéntica (solo faltan caras que ninguna cámara ve).
static func butaca_lejos() -> Mesh:
	if _butaca_lejos != null:
		return _butaca_lejos
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_caja(st, Vector3(1.46, 0.07, 0.40), Vector3(-0.05, 0.40, 0.04), 0.0, false, true)
	for k in 3:
		_caja(st, Vector3(0.44, 0.38, 0.05), Vector3(-0.55 + float(k) * 0.5, 0.58, -0.20), -0.14, false, true)
	for xb in [-0.30, 0.20]:
		_caja(st, Vector3(0.05, 0.05, 0.32), Vector3(xb, 0.50, -0.02), 0.0, false, true)
	_caja(st, Vector3(1.40, 0.30, 0.06), Vector3(-0.05, 0.20, -0.08), 0.0, false, false)
	_butaca_lejos = st.commit()
	return _butaca_lejos
