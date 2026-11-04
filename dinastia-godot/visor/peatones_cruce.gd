class_name PeatonesCruce
extends RefCounted
## PEATONES QUE CRUZAN CON EL SEMÁFORO (28-10-2026, pendiente del líder: «los peatones NPC respetan la fase peatonal»). Hasta ahora las rutas de
## peatones rodeaban las manzanas por su acera y nunca cruzaban una avenida. Aquí, en los `CUANTOS` cruces más cercanos al centro, cuatro
## esquinas forman un cuadrado de ruta cuyos cuatro lados SON pasos de cebra: el peatón que llega a la esquina espera en el bordillo (línea de
## detención a `PARADA` m de la esquina) hasta que la cabeza peatonal de ese eje está en verde fijo (`Semaforos.peatonal`) y cruza.
## El lado que va a lo largo de x es paralelo al tráfico del eje 1 (coches en z = eje 0) y por tanto lo gobierna el eje 1; el de z, el eje 0.

const CUANTOS := 24
const POR_CRUCE := 2
const PARADA := 0.8   ## m después de la esquina, antes del bordillo

## Las cuatro esquinas del cruce `p`, en orden (la ruta es un bucle cerrado).
static func esquinas(p: Vector3) -> PackedVector3Array:
	var o := CiudadExpansion.ANCHO_AV * 0.5 + 2.1
	return PackedVector3Array([p + Vector3(o, 0.3, o), p + Vector3(-o, 0.3, o), p + Vector3(-o, 0.3, -o), p + Vector3(o, 0.3, -o)])

## Las líneas de detención de la ruta del cruce `p`: [{s, eje}], una por lado.
static func controles(p: Vector3) -> Array[Dictionary]:
	var pts := esquinas(p)
	var sal: Array[Dictionary] = []
	var lado := pts[0].distance_to(pts[1])
	for k in 4:
		var a := pts[k]
		var c := pts[(k + 1) % 4]
		var a_lo_largo_de_x := absf(c.x - a.x) > absf(c.z - a.z)
		sal.append({"s": float(k) * lado + PARADA, "eje": 1 if a_lo_largo_de_x else 0})
	return sal

## Monta las rutas y los peatones; devuelve cuántos.
static func montar(ex: CiudadExpansion, t: TraficoCiudad, rng: RandomNumberGenerator) -> int:
	if ex.semaforos == null or ex.cruces_semaforo.is_empty():
		return 0
	var lista: Array = ex.cruces_semaforo.duplicate()
	lista.sort_custom(func(a: Vector3, b: Vector3) -> bool: return Vector2(a.x, a.z).length() < Vector2(b.x, b.z).length())
	var n := 0
	for p: Vector3 in lista.slice(0, CUANTOS):
		var id := t.agregar_ruta(esquinas(p))
		for c: Dictionary in controles(p):
			t.agregar_control(id, float(c["s"]), int(c["eje"]))
		var largo := t.largo_de(id)
		for q in POR_CRUCE:
			ex.b._un_peaton(t, rng, id, rng.randf() * largo)
			n += 1
	return n
