class_name CiudadIndustrial
extends RefCounted
## LAS MANZANAS INDUSTRIALES LLENAS (27-10-2026, relleno de la ciudad; auditoría: «más del 80 % de cada manzana vacía»). `_industrial`
## pone una nave, diez contenedores y a veces una chimenea; esto suma, sin tocar su azar (`_rng` es de todo el barrio): dos naves más
## en la franja sur, silos y cisterna (`industrial/water-tower`, `detail-tank-large`), camiones y cajas en los muelles, y una valla
## de tela metálica en los tres lados cerrados (el sur queda abierto como entrada). Todo sale de un hash de la posición.
const IND := "res://assets/kenney/industrial/%s.glb"
const NAVES := ["b", "d", "g", "h", "i", "j", "k", "n", "o", "p", "s"]
const CAMIONES := ["res://assets/ciudad/kenney_cars/delivery.glb", "res://assets/ciudad/kenney_cars_extra/truck.glb",
	"res://assets/ciudad/kenney_cars/garbage-truck.glb", "res://assets/ciudad/kenney_cars/van.glb"]
const CAJA := "res://assets/ciudad/kenney_cars/box.glb"
const Y := 0.12

static func rellenar(ex: CiudadExpansion, r: Rect2) -> void:
	var b := ex.b
	var c := Vector3(r.get_center().x, 0, r.get_center().y)
	var h := absi(hash(Vector2(c.x * 1.7, c.z * 0.9)))
	var w := r.size.x
	var f := r.size.y
	## Dos naves en la franja sur, de espaldas a la calle y de cara al patio.
	for k in 2:
		var ruta := IND % ("building-" + NAVES[(h + k * 3) % NAVES.size()])
		var kn: Dictionary = ex._malla_kit(ruta)
		if kn.is_empty():
			continue
		var caja: AABB = kn["caja"]
		var esc := minf(minf(w * 0.34 / maxf(caja.size.x, 0.01), f * 0.2 / maxf(caja.size.z, 0.01)), 8.0)
		ex._pieza_kit(ruta, c + Vector3(-w * 0.14 + float(k) * w * 0.4, Y, f * 0.32), esc, 0.0 if (h + k) % 2 == 0 else PI)
	## Silos, cisterna y torre de agua en el costado este.
	var altos := [IND % "water-tower", IND % "detail-tank-large", IND % "chimney-medium"]
	for k in 3:
		var ra: String = altos[(h + k) % altos.size()]
		ex._pieza_kit(ra, c + Vector3(w * 0.4, Y, f * (0.02 + float(k) * 0.12)), ex._escala_ancho(ra, 5.0), 0.0)
	## Camiones en los muelles de las naves y cajas apiladas.
	for k in 3:
		var rc: String = CAMIONES[(h + k) % CAMIONES.size()]
		ex._pieza_kit(rc, c + Vector3(-w * 0.34 + float(k) * w * 0.26, Y, f * 0.2), 2.6, PI * 0.5 * float(1 + 2 * (k % 2)))
	for k in 6:
		ex._pieza_kit(CAJA, c + Vector3(w * 0.12 + float(k % 3) * 0.75, Y + float(k / 3) * 0.6, f * 0.1), 0.85, 0.0)
	## Valla de tela metálica en norte, este y oeste (con la entrada al sur).
	var valla := b._mat_simple(Color(0.34, 0.36, 0.38), 0.6)
	var ix := w * 0.5 - 1.5
	var iz := f * 0.5 - 1.5
	b._caja_en(c + Vector3(0, 1.0, -iz), Vector3(w - 3.0, 2.0, 0.12), valla)
	for sx: float in [-1.0, 1.0]:
		b._caja_en(c + Vector3(sx * ix, 1.0, 0), Vector3(0.12, 2.0, f - 3.0), valla)

## (4-11, pasada 3) El centro de la parcela, solo en MEDIA o más (en MÍNIMA no suma llamadas): tres pilas de palés y cajas, en los MultiMesh de detalles por celda.
static func patio_central(ex: CiudadExpansion, r: Rect2) -> void:
	if Calidad.elegida <= Calidad.MINIMO:
		return
	ex._mat_det("palet_madera", Color(0.55, 0.4, 0.25), 0.9)
	ex._mat_det("caja_azul", Color(0.2, 0.35, 0.6), 0.7)
	ex._mat_det("caja_gris", Color(0.6, 0.62, 0.64), 0.7)
	var c := Vector3(r.get_center().x, 0, r.get_center().y)
	var hp := absi(hash(Vector2(c.x * 0.37, c.z * 1.3)))
	for pila in 3:
		var base := c + Vector3(-r.size.x * 0.12 + float(pila) * r.size.x * 0.17, 0.0, r.size.y * 0.05 + float((hp + pila) % 3 - 1) * r.size.y * 0.04)
		for ix in 3:
			for iz in 2:
				ex._lote_det("palet_madera", base + Vector3(float(ix) * 1.45, 0.2, float(iz) * 1.45), Vector3(1.3, 0.16, 1.3), 0.0)
				for nivel in 1 + (hp + ix + iz + pila) % 2:
					ex._lote_det("caja_azul" if (ix + iz + pila) % 2 == 0 else "caja_gris", base + Vector3(float(ix) * 1.45, 0.93 + float(nivel) * 1.1, float(iz) * 1.45), Vector3(1.2, 1.1, 1.2), 0.0)
