class_name CiudadRotonda
extends RefCounted
## LA ROTONDA DE LA CIUDAD (28-10-2026, M-168). En un cruce de dos avenidas SIN tráfico de la red (se escaneó: 38 de los 326 cruces con semáforo
## son avenida × avenida y ninguna ruta de coches pasa a menos de 16 m del escogido), así que no rompe la red: se le QUITA el semáforo y encima del
## cruce (24 × 24 m) se levanta una isla central de 6,5 m con bordillo, monumento y arbustos, un anillo asfaltado con sus rayas blancas, cuatro
## señales de «ceda el paso» y cuatro flechas azules de giro antihorario (se circula por la derecha). La isla es un obstáculo sólido para quien pasea
## o conduce el coche propio (`CityBuilder.circulos`). Todo en una sola función: nada de rutas nuevas.
const CENTRO := Vector3(-660.0, 0.0, 330.0)
const R_ISLA := 6.5
const R_ANILLO := 12.4
const Y := 0.14

## Quita de la lista de semáforos el del cruce de la rotonda.
static func quitar_semaforo(lista: Array) -> void:
	if OS.get_environment("SIN_ROTONDA") != "":   ## para las capturas «antes»
		return
	for i in range(lista.size() - 1, -1, -1):
		var p: Vector3 = lista[i]
		if Vector2(p.x - CENTRO.x, p.z - CENTRO.z).length() < 2.0:
			lista.remove_at(i)

static func montar(ex: CiudadExpansion) -> void:
	if OS.get_environment("SIN_ROTONDA") != "":
		return
	var b := ex.b
	var c := CENTRO
	var asfalto := b._mat_simple(Color(0.19, 0.19, 0.21), 0.95)
	var piedra := b._mat_simple(Color(0.66, 0.65, 0.62), 0.9)
	var cesped := b._mat_simple(Color(0.28, 0.58, 0.25), 0.95)
	var blanco := b._mat_simple(Color(0.95, 0.95, 0.92), 0.7)
	var azul := b._mat_simple(Color(0.1, 0.35, 0.75), 0.6)
	## Anillo de asfalto sobre el centro del cruce (tapa las rayas de las dos avenidas) y la isla con su bordillo.
	b._cil_en(c + Vector3(0, Y + 0.01, 0), R_ANILLO, 0.02, asfalto)
	b._cil_en(c + Vector3(0, Y + 0.2, 0), R_ISLA + 0.45, 0.4, piedra)
	b._cil_en(c + Vector3(0, Y + 0.22, 0), R_ISLA, 0.44, cesped)
	## Rayas del anillo: continua por fuera de la isla y discontinua en el borde exterior.
	for i in 48:
		var a := TAU * float(i) / 48.0
		b._caja_en(c + Vector3(cos(a) * (R_ISLA + 1.3), Y + 0.025, sin(a) * (R_ISLA + 1.3)), Vector3(1.0, 0.012, 0.14), blanco).rotation.y = -a + PI * 0.5
		if i % 2 == 0:
			b._caja_en(c + Vector3(cos(a) * (R_ANILLO - 0.4), Y + 0.025, sin(a) * (R_ANILLO - 0.4)), Vector3(1.4, 0.012, 0.16), blanco).rotation.y = -a + PI * 0.5
	## Monumento central: peana, columna y esfera dorada; seis arbustos alrededor y tres árboles.
	b._cil_en(c + Vector3(0, Y + 0.9, 0), 1.7, 1.0, piedra)
	b._cil_en(c + Vector3(0, Y + 3.4, 0), 0.4, 4.6, piedra)
	Mini3D.esfera(b, c + Vector3(0, Y + 6.0, 0), 0.7, b._mat_simple(Color(0.95, 0.78, 0.25), 0.3, 0.8))
	var arbustos := b._mat_simple(Color(0.2, 0.5, 0.2), 0.95)
	var pts: Array = []
	for i in 6:
		var a2 := TAU * float(i) / 6.0 + 0.3
		var q := c + Vector3(cos(a2) * 4.4, Y + 0.65, sin(a2) * 4.4)
		b._cil_en(q, 0.7, 0.7, arbustos)
	for i in 3:
		var a3 := TAU * float(i) / 3.0 + 1.0
		pts.append(c + Vector3(cos(a3) * 3.9, Y + 0.45, sin(a3) * 3.9))
	ex._arboles_en(pts, 0.8)
	## Cuatro flechas azules de giro antihorario en el bordillo (mirando a cada brazo) y cuatro señales de ceda el paso a la entrada de cada brazo.
	for i in 4:
		var dir := Vector3(cos(PI * 0.5 * float(i)), 0, sin(PI * 0.5 * float(i)))
		var disco := b._cil_en(c + dir * (R_ISLA + 0.1) + Vector3(0, Y + 1.5, 0), 0.5, 0.06, azul)
		disco.rotation = Vector3(PI * 0.5, atan2(dir.x, dir.z), 0)   ## el disco mira hacia fuera, al brazo
		b._rotulo(c + dir * (R_ISLA + 0.5) + Vector3(0, Y + 1.5, 0), "↺", Color(1, 1, 1), 40)
		var lado := Vector3(-dir.z, 0, dir.x)
		var entrada := c + dir * (R_ANILLO + 2.0) + lado * 5.0
		b._cil_en(entrada + Vector3(0, 1.1, 0), 0.05, 2.2, b._mat_simple(Color(0.4, 0.4, 0.45), 0.6))
		var tri := b._caja_en(entrada + Vector3(0, 2.3, 0), Vector3(0.9, 0.9, 0.05), b._mat_simple(Color(0.9, 0.12, 0.1), 0.5))
		tri.rotation = Vector3(0, atan2(dir.x, dir.z), PI * 0.25)
	b.circulos.append(Vector3(c.x, c.z, R_ISLA + 0.9))
