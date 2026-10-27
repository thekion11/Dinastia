class_name CiudadPlaza
extends RefCounted
## LA PLAZA MAYOR LLENA (27-10-2026, relleno de la ciudad; auditoría: «~90 % de la losa vacía»). Sobre la losa, la fuente, la estatua del ídolo
## y el mural de siempre: un anillo de bancos alrededor de la fuente, farolas, puestos de mercado a los lados (`montana_rusa/stall-*`, CC0),
## y al norte unos soportales con la fachada modular (`FachadaModular`, cafés en dos plantas) y las terrazas con sombrilla delante.
const BANCO := "res://assets/kenney/muebles/bench.glb"
const PUESTOS := ["stall-food", "stall-drinks", "stall-information", "stall-food", "stall-drinks"]
const RUTA_PUESTO := "res://assets/kenney/montana_rusa/%s.glb"
const TOPE := 0.31   ## cara superior de la losa

static func montar(ex: CiudadExpansion, c: Vector3, w: float, f: float) -> void:
	var b := ex.b
	var y := TOPE
	## Bancos en anillo, mirando a la fuente (el de 0,4 m a ×2,5: ~1 m de ancho y ~1,2 m de alto).
	for k in 10:
		var ang := TAU * float(k) / 10.0
		var p := c + Vector3(cos(ang) * 13.0, 0, sin(ang) * 13.0)
		## Dos asientos del kit juntos por cada puesto del anillo (el modelo es de una plaza: ~0,4 m de ancho).
		for d: float in [-0.55, 0.55]:
			var q := p + Vector3(-sin(ang), 0, cos(ang)) * d
			ex._pieza_kit(BANCO, Vector3(q.x, y, q.z), ex._escala_ancho(BANCO, 1.0), -ang - PI * 0.5)
	## Farolas en un anillo exterior: poste, brazo y luminaria encendida.
	var poste := b._mat_simple(Color(0.16, 0.17, 0.2), 0.5)
	var luz := b._mat_simple(Color(1.0, 0.95, 0.8), 0.4, 1.4)
	for k in 8:
		var ang2 := TAU * (float(k) + 0.5) / 8.0
		var p2 := c + Vector3(cos(ang2) * w * 0.3, 0, sin(ang2) * f * 0.3)
		b._cil_en(Vector3(p2.x, y + 2.3, p2.z), 0.1, 4.6, poste)
		b._caja_en(Vector3(p2.x, y + 4.7, p2.z), Vector3(0.5, 0.18, 0.5), luz)
	## Puestos de mercado a los dos lados, de cara al centro (el mostrador del modelo mira a −Z).
	var h := absi(hash(Vector2(c.x, c.z)))
	var n := 0
	for sx: float in [-1.0, 1.0]:
		for dz: float in [-14.0, 4.0, 22.0]:
			var ruta := RUTA_PUESTO % PUESTOS[(h + n) % PUESTOS.size()]
			ex._pieza_kit(ruta, Vector3(c.x + sx * (w * 0.5 - 9.0), y, c.z + dz), ex._escala_ancho(ruta, 3.4), -PI * 0.5 * -sx)
			n += 1
	## Soportales al norte: edificio, fachada modular de dos plantas, columnas y cubierta.
	var zn := c.z - f * 0.5 + 6.0
	var ancho := w - 16.0
	var claro := b._mat_simple(Color(0.86, 0.8, 0.7), 0.85)
	b._caja_en(Vector3(c.x, y + 4.5, zn - 4.0), Vector3(ancho, 9.0, 8.0), claro)
	FachadaModular.montar(ex, c.x, zn, y, ancho, 2, false)
	b._caja_en(Vector3(c.x, y + 4.6, zn + 4.4), Vector3(ancho, 0.4, 5.2), claro)
	var piedra := b._mat_simple(Color(0.78, 0.74, 0.68), 0.8)
	var x := c.x - ancho * 0.5 + FachadaModular.MODULO * 0.5
	while x < c.x + ancho * 0.5:
		b._cil_en(Vector3(x, y + 2.3, zn + 6.4), 0.32, 4.6, piedra)
		x += FachadaModular.MODULO
	## Terrazas con sombrilla delante de los soportales (los colores de la feria).
	var tela := [Color(0.85, 0.2, 0.2), Color(0.95, 0.8, 0.2), Color(0.2, 0.5, 0.85), Color(0.25, 0.65, 0.35)]
	var blanco := b._mat_simple(Color(0.95, 0.95, 0.93), 0.5)
	for q in 8:
		var tx := c.x + (-1.0 if q % 2 == 0 else 1.0) * (10.0 + float(q / 2) * 9.0)
		var tz := zn + 11.0
		b._cil_en(Vector3(tx, y + 1.2, tz), 0.05, 2.4, blanco)
		b._cil_en(Vector3(tx, y + 0.74, tz), 0.55, 0.06, blanco)
		var cono := b._cil_en(Vector3(tx, y + 2.45, tz), 1.5, 0.5, b._mat_simple(tela[(h + q) % tela.size()], 0.7), 0.0)
		cono.name = "Sombrilla"
		## Lo que hay sobre la mesa (piezas de `comida`, CC0; `_pieza_kit` no consume `_rng`).
		var platos := ["croissant", "cup-coffee", "cake", "glass-wine", "donut-sprinkles", "cup-tea", "cupcake", "bread"]
		for j in 2:
			var nombre: String = platos[(q + j * 3) % platos.size()]
			ex._pieza_kit("res://assets/kenney/comida/%s.glb" % nombre, Vector3(tx + (-0.22 if j == 0 else 0.22), y + 0.78, tz + 0.1), 4.0, float(q * 70 + j * 140) * PI / 180.0)
			## Y una silla a cada lado, mirando a la mesa.
			ex._pieza_kit("res://assets/kenney/muebles/chairRounded.glb", Vector3(tx + (-1.0 if j == 0 else 1.0), y, tz), 1.0, PI * 0.5 if j == 0 else -PI * 0.5)
