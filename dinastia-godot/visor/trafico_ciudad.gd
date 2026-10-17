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
## SEMÁFOROS Y PARADAS (7-10-2026, la ciudad grande). `semaforos` es el
## controlador (`Semaforos`); cada ruta puede tener «controles» -la línea de
## detención de un cruce y el eje que la gobierna- y cada vehículo, paradas
## donde se queda unos segundos (los autobuses).
var semaforos: Semaforos = null
var _controles := {}            ## ruta -> [{s, eje}]

## El punto de la ruta más cercano a `p`, como distancia recorrida.
func s_mas_cercano(ruta: int, p: Vector3) -> float:
	var r: Ruta = _rutas[ruta]
	var mejor := INF
	var s_mejor := 0.0
	for i in r.puntos.size():
		var a: Vector3 = r.puntos[i]
		var c: Vector3 = r.puntos[(i + 1) % r.puntos.size()]
		var q := Geometry3D.get_closest_point_to_segment(p, a, c)
		var d := q.distance_to(p)
		if d < mejor:
			mejor = d
			s_mejor = r.acumulado[i] + a.distance_to(q)
	return s_mejor

func largo_de(ruta: int) -> float:
	return (_rutas[ruta] as Ruta).largo

## Una línea de detención en la ruta: en `s` se para si el eje está en rojo.
func agregar_control(ruta: int, s: float, eje: int) -> void:
	if not _controles.has(ruta):
		_controles[ruta] = []
	(_controles[ruta] as Array).append({"s": s, "eje": eje})

## El último vehículo añadido respeta la cola (no se mete encima del de
## delante cuando este frena en un semáforo o en una parada).
func marcar_cola_al_ultimo() -> void:
	if not _vehiculos.is_empty():
		_vehiculos[_vehiculos.size() - 1]["cola"] = true
		var r := int(_vehiculos[_vehiculos.size() - 1]["ruta"])
		if not _en_cola.has(r):
			_en_cola[r] = []
		(_en_cola[r] as Array).append(_vehiculos[_vehiculos.size() - 1])

var _en_cola := {}              ## ruta -> [vehículos con cola]

## Paradas de un vehículo ya añadido (el último): distancias en la ruta.
func agregar_paradas_al_ultimo(paradas: Array, espera: float = 8.0) -> void:
	if _vehiculos.is_empty():
		return
	var v: Dictionary = _vehiculos[_vehiculos.size() - 1]
	v["paradas"] = paradas
	v["espera_parada"] = espera

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
	## Los peatones (alto bajo) se anotan por ruta para no atravesarse.
	if alto > 0.05 and alto < 0.3:
		if not _peatones_ruta.has(ruta):
			registrar_ruta_gente(ruta)
		(_peatones_ruta[ruta] as Array).append(_vehiculos[_vehiculos.size() - 1])
	_colocar(_vehiculos[_vehiculos.size() - 1])

var _peatones_ruta := {}        ## ruta -> [peatones]

## GENTE ALREDEDOR (13-10-2026). La ciudad mide 2,6 km y los peatones se
## repartían por bucles enormes: a pie casi no se veía a nadie. Como en los
## juegos de mundo abierto, los que quedan lejos de ti reaparecen en una acera
## cercana, a una distancia y por detrás de la cámara para no verlos «nacer».
## `mira`: hacia dónde mira la cámara (en el suelo). Mueve como mucho `tope`.
var _rng_gente := RandomNumberGenerator.new()
## Rutas de peatones por celdas de 100 m (para buscar solo las cercanas).
var _gente_celdas := {}

func registrar_ruta_gente(id: int) -> void:
	if id < 0 or id >= _rutas.size():
		return
	if not _peatones_ruta.has(id):
		_peatones_ruta[id] = []
	var ruta: Ruta = _rutas[id]
	var c := Vector3.ZERO
	for p: Vector3 in ruta.puntos:
		c += p
	c /= maxf(1.0, float(ruta.puntos.size()))
	var k := Vector2i(floori(c.x / 100.0), floori(c.z / 100.0))
	if not _gente_celdas.has(k):
		_gente_celdas[k] = []
	if not (_gente_celdas[k] as Array).has(id):
		(_gente_celdas[k] as Array).append(id)

func rutas_gente() -> Array:
	return _peatones_ruta.keys()

func _rutas_gente_cerca(centro: Vector3) -> Array:
	var out: Array = []
	var k0 := Vector2i(floori(centro.x / 100.0), floori(centro.z / 100.0))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			out.append_array(_gente_celdas.get(k0 + Vector2i(dx, dz), []))
	return out
func reciclar_peatones(centro: Vector3, mira: Vector3, lejos := 95.0, tope := 3, max_cerca := 28, inicial := false) -> int:
	var movidos := 0
	var c2 := Vector2(centro.x, centro.z)
	## Con bastante gente alrededor no se trae más (rendimiento y realismo).
	var cerca := 0
	for v0: Dictionary in _vehiculos:
		var a0 := float(v0["alto"])
		if a0 > 0.05 and a0 < 0.3 and is_instance_valid(v0["nodo"]):
			var n0: Node3D = v0["nodo"]
			if Vector2(n0.position.x, n0.position.z).distance_to(c2) < 80.0:
				cerca += 1
	if cerca >= max_cerca:
		return 0
	tope = mini(tope, max_cerca - cerca)
	var m2 := Vector2(mira.x, mira.z).normalized()
	for v: Dictionary in _vehiculos:
		if movidos >= tope:
			break
		var alto := float(v["alto"])
		if alto <= 0.05 or alto >= 0.3 or not is_instance_valid(v["nodo"]):
			continue
		var n: Node3D = v["nodo"]
		if Vector2(n.position.x, n.position.z).distance_to(c2) < lejos:
			continue
		## Busca en las rutas de peatones un punto a 40-75 m y a la espalda.
		var candidatas := _rutas_gente_cerca(centro)
		candidatas.shuffle()
		for r: int in candidatas:
			var ruta: Ruta = _rutas[r]
			var hecho := false
			for intento in 6:
				var sp := _rng_gente.randf() * ruta.largo
				var pos: Vector3 = ruta.en(sp)[0]
				var d := Vector2(pos.x, pos.z) - c2
				var dist := d.length()
				## Al entrar (`inicial`) vale cualquier sitio a 12-60 m; después, a la
				## espalda desde 40 m o por delante desde 55 m (de lejos no se nota).
				if inicial:
					if dist < 12.0 or dist > 60.0:
						continue
				elif dist < 40.0 or dist > 80.0 or (m2 != Vector2.ZERO and d.normalized().dot(m2) > 0.2 and dist < 55.0):
					continue
				var vieja := int(v["ruta"])
				if vieja != r:
					if _peatones_ruta.has(vieja):
						(_peatones_ruta[vieja] as Array).erase(v)
					(_peatones_ruta[r] as Array).append(v)
					v["ruta"] = r
				v["s"] = sp
				_colocar(v)
				movidos += 1
				hecho = true
				break
			if hecho:
				break
	return movidos

## Quién camina o conduce por la ciudad (lo pone `ExploradorCiudad`): todos le
## ceden el paso.
var jugador: Node3D = null

## Fotograma propio para repartir los lejanos (ver `_process`).
var _cuadro := 0

func _process(delta_real: float) -> void:
	## RENDIMIENTO (15-10-2026, medido con pruebas/sonda_explorador: 3,4 ms por
	## fotograma con ~310 coches y vecinos, y solo ~25 cerca). Los lejanos se
	## mueven menos a menudo con el tiempo acumulado (niveles abajo); la
	## posición del jugador se pide una vez, no dos por vehículo.
	_cuadro += 1
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var ojo := cam.global_position if cam != null else Vector3.INF
	var hay_jugador := jugador != null and is_instance_valid(jugador)
	var pj := jugador.global_position if hay_jugador else Vector3.ZERO
	var idx := -1
	for v in _vehiculos:
		idx += 1
		## Nivel de detalle: 0 = cerca (cada fotograma), 1 = se ve de lejos
		## (150-260 m: 1 de cada 3), 2 = fuera de la vista (más de 260 m, que es
		## donde dejan de dibujarse: 1 de cada 12). El nivel se recalcula cuando
		## le toca moverse, así los que se saltan no cuestan casi nada.
		var nivel := int(v.get("lod", 0))
		if nivel > 0 and (idx + _cuadro) % (3 if nivel == 1 else 12) != 0:
			v["dt"] = float(v.get("dt", 0.0)) + delta_real
			continue
		var delta := delta_real + float(v.get("dt", 0.0))
		v["dt"] = 0.0
		if ojo != Vector3.INF:
			var nv: Node3D = v["nodo"]
			if is_instance_valid(nv):
				var q := nv.position
				var lejos := maxf(absf(q.x - ojo.x), absf(q.z - ojo.z))
				v["lod"] = 0 if lejos < 150.0 else (1 if lejos < 260.0 else 2)
		if float(v.get("espera", 0.0)) > 0.0:
			v["espera"] = float(v["espera"]) - delta
			if float(v["espera"]) <= 0.0 and v.has("pausa"):
				v.erase("pausa")
				_animar(v, "caminar")
			continue
		## NPCs CON VIDA (etapa 1): de vez en cuando un peatón se detiene a mirar
		## el móvil o a descansar y luego sigue su camino.
		if float(v["alto"]) > 0.05 and float(v["alto"]) < 0.3 and randf() < 0.0004 * delta * 60.0:
			v["espera"] = randf_range(3.0, 9.0)
			v["pausa"] = true
			_animar(v, "parado")
			continue
		var avance := float(v["vel"]) * delta
		var ruta := int(v["ruta"])
		var s0 := float(v["s"])
		var largo := (_rutas[ruta] as Ruta).largo
		## En rojo (o ámbar), se detiene en la línea.
		if semaforos != null and _controles.has(ruta):
			for c: Dictionary in _controles[ruta]:
				var d := fposmod(float(c["s"]) - s0, largo)
				if d < avance + 0.5 and d < 12.0 and not semaforos.verde(int(c["eje"])):
					avance = maxf(0.0, d - 0.3)
					break
		## Las paradas del autobús.
		if v.has("paradas"):
			for ps: float in v["paradas"]:
				var d2 := fposmod(ps - s0, largo)
				if d2 < avance:
					avance = d2 + 0.05
					v["espera"] = float(v.get("espera_parada", 8.0))
					break
		if v.has("cola"):
			for o: Dictionary in _en_cola[ruta]:
				if o == v:
					continue
				var d3 := fposmod(float(o["s"]) - s0, largo)
				if d3 < 9.0:
					avance = minf(avance, maxf(0.0, d3 - 8.0))
		## Un peatón no atraviesa al que va delante en su ruta: si le alcanza a menos
		## de 0,9 m, se queda detrás (adelantar queda para una próxima pasada).
		if _peatones_ruta.has(ruta) and float(v["alto"]) > 0.05 and float(v["alto"]) < 0.3:
			for o: Dictionary in _peatones_ruta[ruta]:
				if o == v:
					continue
				var d4 := fposmod(float(o["s"]) - s0, largo)
				if d4 < 0.9 + avance:
					avance = minf(avance, maxf(0.0, d4 - 0.9))
					## Si se alcanzan, a veces se paran a charlar (etapa 1: NPCs con vida).
					if float(o.get("espera", 0.0)) <= 0.0 and randf() < 0.004:
						_charlar(v, o)
						avance = 0.0
		## CEDER EL PASO AL JUGADOR (etapa 5): un peatón se detiene si estás
		## delante a menos de 1,6 m; un coche, a menos de 7 m. Solo se mira a los
		## que están a menos de 14 m (barato) y solo hacia dónde van.
		if hay_jugador and avance > 0.0:
			var nodo_v: Node3D = v["nodo"]
			if is_instance_valid(nodo_v):
				var rel := Vector3(pj.x - nodo_v.position.x, 0, pj.z - nodo_v.position.z)
				var dist := rel.length()
				if dist < 14.0:
					var dir_v: Vector3 = (_rutas[ruta] as Ruta).en(s0)[1]
					var peaton := float(v["alto"]) < 0.3
					var umbral := 1.6 if peaton else 7.0
					if dist < umbral and rel.normalized().dot(Vector3(dir_v.x, 0, dir_v.z).normalized()) > 0.5:
						avance = 0.0
		v["s"] = s0 + avance
		_colocar(v)

## Dos peatones se paran, se miran y charlan unos segundos.
func _charlar(a: Dictionary, b: Dictionary) -> void:
	var t := randf_range(5.0, 11.0)
	var na: Node3D = a["nodo"]
	var nb: Node3D = b["nodo"]
	if not is_instance_valid(na) or not is_instance_valid(nb):
		return
	for par: Array in [[a, na, nb], [b, nb, na]]:
		var v: Dictionary = par[0]
		var yo: Node3D = par[1]
		var otro: Node3D = par[2]
		v["espera"] = t
		v["pausa"] = true
		var d := otro.global_position - yo.global_position
		yo.rotation.y = atan2(d.x, d.z)
		_gesto(v, "charla")

## Un gesto sacado de los clips reales (se añade al peatón la primera vez).
func _gesto(v: Dictionary, gesto: String) -> void:
	var nodo: Node3D = v["nodo"]
	for ap: AnimationPlayer in nodo.find_children("*", "AnimationPlayer", true, false):
		var lib := ap.get_animation_library("")
		if lib == null:
			continue
		if not lib.has_animation(gesto) and AnimExtra.UAL.has(gesto):
			var esq := FutbolistaQ.esqueleto_de(nodo)
			var clip: Animation = AnimQuaternius.cargar_real(String(AnimExtra.UAL[gesto]), str(ap.get_path_to(esq)) if esq != null else "")
			if clip != null:
				lib.add_animation(gesto, clip)
		if lib.has_animation(gesto):
			ap.play(gesto, 0.3)

## Pone una animación al peatón `v` (si su cuerpo la tiene).
func _animar(v: Dictionary, anim: String) -> void:
	var nodo: Node3D = v["nodo"]
	if not is_instance_valid(nodo):
		return
	for ap: AnimationPlayer in nodo.find_children("*", "AnimationPlayer", true, false):
		if ap.has_animation(anim):
			ap.play(anim, 0.3)

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
	## `atan2(dir.x, dir.z)` alinea el eje +Z LOCAL del nodo con la dirección
	## de marcha, que es donde tienen el morro los coches (`CityBuilder.
	## instanciar_coche`): su `giro` es 0. El -90° de antes suponía el morro en
	## X y dejaba la flota entera circulando de lado.
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
	## El morro del modelo es su +Z local (medido el 26-9-2026: los coches de
	## Kenney son largos en Z y el capó cae en +Z; antes se suponía X y la flota
	## iba de lado aunque esta prueba diera 1).
	var morro: Vector3 = nodo.global_transform.basis.z.normalized()
	return {"alineacion": morro.dot(dir), "dir": dir, "morro": morro}
