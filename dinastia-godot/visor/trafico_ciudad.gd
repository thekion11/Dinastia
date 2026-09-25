class_name TraficoCiudad
extends Node3D
## EL TRÁFICO DE LA CIUDAD DEPORTIVA: lo que separa una maqueta de un sitio.
##
## Hasta ahora el mapa tenía calles perfectas y absolutamente vacías, coches
## aparcados que no se movían nunca y un río con un velero clavado. Todo
## correcto y todo muerto. Este nodo mueve cosas por recorridos cerrados, que
## es la forma más barata de que una escena parezca viva: no hace falta
## simular nada -ni tráfico real, ni colisiones, ni semáforos-, basta con que
## SE MUEVAN y que cada uno vaya a su ritmo.
##
## CÓMO FUNCIONA. Un recorrido es una lista de puntos que se cierra sobre sí
## misma (`Ruta`). Cada vehículo guarda su distancia recorrida `s`; cada
## fotograma `s += velocidad * delta` y se le pregunta a la ruta dónde cae esa
## distancia y hacia dónde apunta. Al pasarse del largo total, `s` vuelve a
## empezar (`fmod`), así que el coche da la vuelta para siempre sin acumular
## error ni necesitar un caso especial para el final.
##
## POR QUÉ NO HAY DOS COCHES EN EL MISMO SITIO: cada uno arranca con su `s`
## repartido por la ruta y con una velocidad distinta, así que se separan y se
## alcanzan solos. Se cruzan sin chocar -no hay colisión- y a la altura de
## cámara del mapa eso no se nota; poner colisiones aquí sería pagar mucho por
## un detalle que nadie va a ver.

## Un recorrido cerrado, con sus distancias acumuladas ya calculadas para no
## recorrer la lista entera en cada fotograma y por cada vehículo.
class Ruta:
	var puntos: PackedVector3Array
	var acumulado: PackedFloat32Array
	var largo := 0.0

	func _init(ps: PackedVector3Array) -> void:
		puntos = ps
		acumulado = PackedFloat32Array()
		acumulado.resize(ps.size() + 1)
		acumulado[0] = 0.0
		for i in range(ps.size()):
			var a: Vector3 = ps[i]
			var b: Vector3 = ps[(i + 1) % ps.size()]
			largo += a.distance_to(b)
			acumulado[i + 1] = largo

	## Posición y dirección a una distancia `s` del inicio. Devuelve
	## `[posicion, direccion]`.
	func en(s: float) -> Array:
		if largo <= 0.001 or puntos.size() < 2:
			return [Vector3.ZERO, Vector3.FORWARD]
		var d: float = fposmod(s, largo)
		## Búsqueda binaria sobre el acumulado: con 20 vehículos y rutas de
		## docenas de tramos, recorrerlo en lineal cada fotograma se nota.
		var lo := 0
		var hi := puntos.size() - 1
		while lo < hi:
			var mid := (lo + hi + 1) / 2
			if acumulado[mid] <= d:
				lo = mid
			else:
				hi = mid - 1
		var a: Vector3 = puntos[lo]
		var b: Vector3 = puntos[(lo + 1) % puntos.size()]
		var tramo: float = maxf(a.distance_to(b), 0.001)
		var t: float = (d - acumulado[lo]) / tramo
		return [a.lerp(b, t), (b - a).normalized()]

var _rutas: Array = []          ## [Ruta]
var _vehiculos: Array = []      ## [{nodo, ruta, s, vel, alto}]

## Añade un recorrido y devuelve su índice, para colgarle vehículos.
func agregar_ruta(puntos: PackedVector3Array) -> int:
	_rutas.append(Ruta.new(puntos))
	return _rutas.size() - 1

## Cuelga un vehículo de una ruta. `giro_base` corrige modelos que no miran
## hacia -Z (los coches de Kenney miran a +X, por ejemplo): sin eso, la flota
## entera circula de lado y parece que va derrapando.
func agregar_vehiculo(nodo: Node3D, ruta: int, s: float, vel: float,
		alto: float = 0.0, giro_base: float = 0.0) -> void:
	if ruta < 0 or ruta >= _rutas.size():
		return
	add_child(nodo)
	_vehiculos.append({
		"nodo": nodo, "ruta": ruta, "s": s, "vel": vel,
		"alto": alto, "giro": giro_base,
	})
	_colocar(_vehiculos[_vehiculos.size() - 1])

func _process(delta: float) -> void:
	for v in _vehiculos:
		v["s"] = float(v["s"]) + float(v["vel"]) * delta
		_colocar(v)

func _colocar(v: Dictionary) -> void:
	var nodo: Node3D = v["nodo"]
	if not is_instance_valid(nodo):
		return
	var r: Ruta = _rutas[int(v["ruta"])]
	var par: Array = r.en(float(v["s"]))
	var pos: Vector3 = par[0]
	var dir: Vector3 = par[1]
	nodo.position = pos + Vector3(0, float(v["alto"]), 0)
	## `atan2` y no `look_at`: el vehículo solo gira sobre su eje vertical -un
	## coche no cabecea por seguir la calle- y `look_at` con un objetivo a la
	## misma altura da un transform degenerado en cuanto la dirección se
	## acerca a la vertical. Ver `dinastia-rotacion-euler-godot.md`.
	##
	## OJO CON EL SIGNO, que costó una ronda: `atan2(dir.x, dir.z)` alinea el
	## eje +Z LOCAL del nodo con la dirección de marcha. Los coches de Kenney
	## tienen el morro en su eje X (por eso el aparcamiento de siempre los gira
	## 90°), así que hay que restar 90°, no sumarlos. Sumando, el coche viaja
	## de culo: con +90° el morro apunta justo al revés que el movimiento, y a
	## la altura de cámara del mapa se ve exactamente como lo que es -toda la
	## flota circulando marcha atrás-.
	nodo.rotation.y = atan2(dir.x, dir.z) + float(v["giro"])

## Comprobación de orientación para las pruebas: hacia dónde mira de verdad el
## vehículo `i` y hacia dónde se está moviendo. Si el producto escalar de los
## dos no es ~1, va de lado o marcha atrás.
func diagnostico(i: int) -> Dictionary:
	if i < 0 or i >= _vehiculos.size():
		return {}
	var v: Dictionary = _vehiculos[i]
	var nodo: Node3D = v["nodo"]
	var r: Ruta = _rutas[int(v["ruta"])]
	var dir: Vector3 = r.en(float(v["s"]))[1]
	## El morro del modelo es su +X local (coches de Kenney).
	var morro: Vector3 = nodo.global_transform.basis.x.normalized()
	return {"alineacion": morro.dot(dir), "dir": dir, "morro": morro}
