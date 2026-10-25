class_name TraficoCiudad
extends "res://visor/trafico_ciudad_p1.gd"
## [Capa 2/2 de `trafico_ciudad.gd`] _process, diagnostico

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
	_rejilla_paso(ojo)
	var idx := -1
	for v in _vehiculos:
		idx += 1
		## Nivel de detalle: 0 = cerca (cada fotograma), 1 = se ve de lejos
		## (150-260 m: 1 de cada 3), 2 = fuera de la vista (más de 260 m, que es
		## donde dejan de dibujarse: 1 de cada 12). El nivel se recalcula cuando
		## le toca moverse, así los que se saltan no cuestan casi nada.
		if v.get("oculto", false):
			continue
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
		var frena := false
		if semaforos != null and _controles.has(ruta):
			for c: Dictionary in _controles[ruta]:
				var d := fposmod(float(c["s"]) - s0, largo)
				if d < avance + 0.5 and d < 12.0 and not semaforos.verde(int(c["eje"])):
					avance = maxf(0.0, d - 0.3)
					frena = true
					break
		if v.has("faros") and bool(v["frena"]) != frena:
			v["frena"] = frena
			var fm: MeshInstance3D = v["faros"]
			if is_instance_valid(fm):
				fm.set_instance_shader_parameter("freno", 1.0 if frena else 0.0)
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
		## NADIE ATRAVIESA A NADIE (pmov, 25-10-2026): lo de arriba solo mira la
		## propia ruta; aquí se cede a quien cruza por delante desde OTRA ruta
		## (coches en un cruce sin semáforo, peatones en un paso de cebra).
		if avance > 0.0 and _cede_paso(v, idx, delta):
			avance = 0.0
			## Y se le encienden las luces de freno, como en el semáforo.
			if v.has("faros") and not bool(v["frena"]):
				v["frena"] = true
				var fm2: MeshInstance3D = v["faros"]
				if is_instance_valid(fm2):
					fm2.set_instance_shader_parameter("freno", 1.0)
		v["s"] = s0 + avance
		_colocar(v)

## Rejilla de 8 m con quién se mueve cerca de la cámara (a menos de 70 m), para
## que cada uno mire solo a sus vecinos. Se rehace cada fotograma: son pocos.
const CELDA_PASO := 8.0
const RADIO_PASO := 70.0
## Tras tanto rato cediendo, sigue: es la salida de emergencia para que un
## cruce raro (tres que se miran en corro) nunca se quede atascado.
const PACIENCIA_PASO := 4.0
var _rejilla := {}

func _rejilla_paso(ojo: Vector3) -> void:
	_rejilla.clear()
	var idx := -1
	for v: Dictionary in _vehiculos:
		idx += 1
		var alto := float(v["alto"])
		if alto >= 0.3 or v.get("oculto", false) or int(v.get("lod", 0)) > 0:
			continue
		var nodo: Node3D = v["nodo"]
		if not is_instance_valid(nodo):
			continue
		var q := nodo.position
		if ojo != Vector3.INF and maxf(absf(q.x - ojo.x), absf(q.z - ojo.z)) > RADIO_PASO:
			continue
		var dir: Vector3 = (_rutas[int(v["ruta"])] as Ruta).en(float(v["s"]))[1]
		var k := Vector2i(floori(q.x / CELDA_PASO), floori(q.z / CELDA_PASO))
		if not _rejilla.has(k):
			_rejilla[k] = []
		(_rejilla[k] as Array).append([idx, Vector2(q.x, q.z), Vector2(dir.x, dir.z).normalized(), alto < 0.05, q.y])

## Hueco que pide cada uno por delante (largo, medio ancho): un coche mira 7 m
## y su carril; un peatón, un paso y su hombro.
static func _hueco(coche: bool) -> Vector2:
	return Vector2(7.0, 1.7) if coche else Vector2(1.3, 0.55)

## ¿`b` (posición) está en el hueco de delante de quien está en `pa` mirando `da`?
## `ancho_extra`: lo que abulta el otro hacia el lado (un coche que cruza en
## perpendicular ocupa medio LARGO, 2,3 m), para que no se rocen.
static func _en_hueco(pa: Vector2, da: Vector2, coche: bool, pb: Vector2, ancho_extra: float) -> bool:
	var rel := pb - pa
	var h := _hueco(coche)
	var frente := rel.dot(da)
	if frente <= 0.2 or frente > h.x:
		return false
	return absf(rel.cross(da)) < h.y + ancho_extra

## ¿Debe esperar `v` porque otro le cruza por delante? Reglas, por orden:
## el de la misma ruta ya se trata arriba (cola y fila de peatones); el coche
## siempre cede al peatón; si los dos se tienen delante (cruce), cede el de
## índice mayor (estable: no bailan); y con `PACIENCIA_PASO` cumplida, sigue.
func _cede_paso(v: Dictionary, idx: int, delta: float) -> bool:
	var nodo: Node3D = v["nodo"]
	if not is_instance_valid(nodo) or float(v["alto"]) >= 0.3:
		return false
	if float(v.get("cediendo", 0.0)) > PACIENCIA_PASO:
		v["cediendo"] = 0.0
		v["sin_ceder"] = 1.5
		return false
	if float(v.get("sin_ceder", 0.0)) > 0.0:
		v["sin_ceder"] = float(v["sin_ceder"]) - delta
		return false
	var coche := float(v["alto"]) < 0.05
	var pa := Vector2(nodo.position.x, nodo.position.z)
	var d3: Vector3 = (_rutas[int(v["ruta"])] as Ruta).en(float(v["s"]))[1]
	var da := Vector2(d3.x, d3.z).normalized()
	var ruta := int(v["ruta"])
	var k0 := Vector2i(floori(pa.x / CELDA_PASO), floori(pa.y / CELDA_PASO))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for e: Array in _rejilla.get(k0 + Vector2i(dx, dz), []):
				var j := int(e[0])
				if j == idx:
					continue
				var o: Dictionary = _vehiculos[j]
				if int(o["ruta"]) == ruta:
					continue
				## Otra altura (la autopista por encima de una calle): no se cruzan.
				if absf(float(e[4]) - nodo.position.y) > 2.5:
					continue
				var pb: Vector2 = e[1]
				var otro_coche: bool = e[3]
				## Dos coches casi paralelos (carril de al lado, o el de enfrente) no
				## se cruzan: solo abultan su medio ancho. En perpendicular, medio largo.
				var paralelo := coche and otro_coche and absf(da.dot(e[2])) > 0.8
				var extra := (0.9 if paralelo else 2.3) if otro_coche else 0.3
				if not _en_hueco(pa, da, coche, pb, extra):
					continue
				## Un peatón no espera a un coche que viene: es el coche quien frena.
				if not coche and otro_coche and _en_hueco(pb, e[2], true, pa, 0.3):
					continue
				## Los dos se tienen delante y son iguales: pasa el de índice menor.
				if coche == otro_coche and j > idx and _en_hueco(pb, e[2], otro_coche, pa, extra if coche else 0.3):
					continue
				v["cediendo"] = float(v.get("cediendo", 0.0)) + delta
				return true
	v["cediendo"] = 0.0
	return false

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
