class_name ProbarNativoCiudad
extends RefCounted
## El tráfico de la ciudad en C++ = el de GDScript (18-11-2026, ciudad a C++, orden del dueño; lo llama `probar_nativo.gd`): `TraficoCiudad._process` por la
## extensión (`DinastiaNativo.trafico_paso`) frente a `_paso_gd`, con dos copias iguales de un cruce lleno (peatones, coches, un autobús con paradas y cola,
## semáforos, una sirena, el jugador y una cámara que reparte los niveles de detalle) durante 900 pasos: diccionarios de los móviles (hash de todos los
## valores, con su tipo), posición y giro de cada nodo, y el azar global (cuántas veces se llamó a `randf`).
## Devuelve {fallos: Array[String], textos: Array[String]}.

const PASOS := 900
const DT := 1.0 / 30.0

static func _armar(raiz: Node3D, semilla: int) -> Dictionary:
	var rr := RandomNumberGenerator.new()
	rr.seed = semilla
	var t := TraficoCiudad.new()
	raiz.add_child(t)
	t.set_process(false)
	var sem := Semaforos.new()
	raiz.add_child(sem)
	sem.set_process(false)
	t.semaforos = sem
	var rutas: Array[int] = []
	for eje in [Vector2(1, 0), Vector2(0, 1)]:
		for off in [-6.0, 6.0]:
			for sentido in [1.0, -1.0]:
				var d: Vector2 = eje * sentido
				var lado := Vector2(-d.y, d.x)
				var c: Vector2 = Vector2(-eje.y, eje.x) * off
				var a := c - d * 60.0
				var b := c + d * 60.0
				var e := b + lado * 30.0
				var f := a + lado * 30.0
				var r := t.agregar_ruta(PackedVector3Array([Vector3(a.x, 0, a.y), Vector3(b.x, 0, b.y), Vector3(e.x, 0, e.y), Vector3(f.x, 0, f.y)]))
				rutas.append(r)
				t.agregar_control(r, 55.0 + rr.randf() * 10.0, 0 if eje.x > 0.5 else 1)
	for r in rutas:
		for k in 7:
			t.agregar_vehiculo(Node3D.new(), r, 20.0 + k * 6.0 + rr.randf(), rr.randf_range(1.0, 1.6), 0.18, rr.randf() * 0.4)
	var rc: Array[int] = []
	for eje in [Vector2(1, 0), Vector2(0, 1)]:
		var a2: Vector2 = -eje * 80.0
		var b2: Vector2 = eje * 80.0
		var lado2: Vector2 = Vector2(-eje.y, eje.x) * 30.0
		var rcc := t.agregar_ruta(PackedVector3Array([Vector3(a2.x, 0, a2.y), Vector3(b2.x, 0, b2.y), Vector3(b2.x + lado2.x, 0, b2.y + lado2.y), Vector3(a2.x + lado2.x, 0, a2.y + lado2.y)]))
		rc.append(rcc)
		t.agregar_control(rcc, 60.0, 0 if eje.x > 0.5 else 1)
		for k in 9:
			t.agregar_vehiculo(Node3D.new(), rcc, 10.0 + k * 11.0, 6.0 + rr.randf() * 4.0)
			if k == 3:
				t.marcar_cola_al_ultimo()
			if k == 6:
				t.agregar_paradas_al_ultimo([40.0, 120.0], 3.0)
	## Un coche que corre solo por una ruta lejana (nivel de detalle 2) y bastantes peatones en ella.
	var lejos := t.agregar_ruta(PackedVector3Array([Vector3(600, 0, 0), Vector3(700, 0, 0), Vector3(700, 0, 80), Vector3(600, 0, 80)]))
	for k in 12:
		t.agregar_vehiculo(Node3D.new(), lejos, float(k) * 20.0, 1.2, 0.18)
	var cam := Camera3D.new()
	raiz.add_child(cam)
	cam.position = Vector3(10.0, 40.0, 10.0)
	cam.look_at(Vector3(0, 0, 0))
	cam.make_current()
	var jug := Node3D.new()
	raiz.add_child(jug)
	jug.position = Vector3(4.0, 0.0, -3.0)
	jug.rotation.y = 0.7
	t.jugador = jug
	t.jugador_huella = Vector2(0.9, 2.2)
	var amb := Node3D.new()
	raiz.add_child(amb)
	amb.position = Vector3(-20.0, 0.0, 6.0)
	## Obstáculos y círculos de choque repartidos junto a las rutas, indexados como el explorador (`_indexar_obstaculos`, `_indexar_circulos`).
	var obst: Array[Rect2] = []
	for q in 70:
		obst.append(Rect2(rr.randf_range(-60.0, 60.0), rr.randf_range(-60.0, 60.0), rr.randf_range(0.6, 3.0), rr.randf_range(0.6, 3.0)))
	var rej_obst := {}
	for r: Rect2 in obst:
		var a3 := r.grow(3.0)
		for i in range(floori(a3.position.x / 32.0), floori(a3.end.x / 32.0) + 1):
			for j in range(floori(a3.position.y / 32.0), floori(a3.end.y / 32.0) + 1):
				var kc := Vector2i(i, j)
				if not rej_obst.has(kc):
					rej_obst[kc] = [] as Array[Rect2]
				(rej_obst[kc] as Array[Rect2]).append(r)
	var rej_circ := {}
	for q in 60:
		var c := Vector3(rr.randf_range(-60.0, 60.0), rr.randf_range(-60.0, 60.0), rr.randf_range(0.2, 0.9))
		var kc := Vector2i(floori(c.x / 8.0), floori(c.y / 8.0))
		if not rej_circ.has(kc):
			rej_circ[kc] = []
		(rej_circ[kc] as Array).append(c)
	t.libre_fn = func(p: Vector3) -> bool: return _libre_gd(p, rej_obst, rej_circ)
	t.libre_ctx = {"obst": rej_obst, "circ": rej_circ, "radio": 0.3, "limite": ExploradorCiudad.LIMITE, "celda_obst": 32.0, "celda_circ": 8.0,
			"rio_x": CityBuilder.RIO_X, "celda_av": CiudadExpansion.CELDA, "ancho_av": CiudadExpansion.ANCHO_AV}
	return {"t": t, "sem": sem, "jug": jug, "amb": amb, "cam": cam}

## `libre_fn` del explorador (`libre_obst(q, 0.3) and not _choca_circulos(q, 0.3)`) con las mismas rejillas.
static func _libre_gd(p: Vector3, rej_obst: Dictionary, rej_circ: Dictionary) -> bool:
	var celda: Array[Rect2] = rej_obst.get(Vector2i(floori(p.x / 32.0), floori(p.z / 32.0)), [] as Array[Rect2])
	if not ExploradorCiudad.libre(p, 0.3, celda):
		return false
	var cx := floori(p.x / 8.0)
	var cz := floori(p.z / 8.0)
	for i in range(cx - 1, cx + 2):
		for j in range(cz - 1, cz + 2):
			var lista: Array = rej_circ.get(Vector2i(i, j), [])
			for c: Vector3 in lista:
				var dx := p.x - c.x
				var dz := p.z - c.y
				var r2 := 0.3 + c.z
				if dx * dx + dz * dz < r2 * r2:
					return false
	return true

static func _huella(t: TraficoCiudad) -> Array:
	var hs: Array = []
	for v: Dictionary in t._vehiculos:
		var ks := v.keys()
		ks.sort()
		var fila: Array = []
		for k in ks:
			var x: Variant = v[k]
			if x is Object:
				continue
			fila.append([k, typeof(x), x])
		var n: Node3D = v["nodo"]
		fila.append(n.position)
		fila.append(n.rotation)
		hs.append(fila)
	return hs

static func _correr(raiz: Node3D, nativo: bool, mixto := false) -> Dictionary:
	var m := _armar(raiz, 1811)
	var t: TraficoCiudad = m["t"]
	var sem: Semaforos = m["sem"]
	var jug: Node3D = m["jug"]
	var amb: Node3D = m["amb"]
	t.usar_nativo = nativo
	TraficoCiudad.sirenas.clear()
	TraficoCiudad.sirenas.append(amb)
	seed(18112)
	var hashes: Array = []
	var instantaneas: Array = []
	for i in PASOS:
		sem.t = fposmod(sem.t + DT, Semaforos.CICLO)
		sem._t_npc = -1000000
		jug.position += Vector3(0.02 * sin(float(i) * 0.05), 0.0, 0.015)
		amb.position.x += 0.05
		if mixto and i == PASOS / 2:
			t.usar_nativo = false   ## a mitad de la prueba vuelve a la versión GDScript: `lod` y `dt` tienen que pasar de la extensión a los diccionarios
			nativo = false
		t._process(DT)
		if nativo:
			t.volcar_estado_nativo()   ## `lod` y `dt` viven en la extensión: se escriben en los diccionarios para compararlos
		var h := _huella(t)
		hashes.append(hash(h))
		if i % 30 == 0:
			instantaneas.append(h)
	var azar := randf()
	TraficoCiudad.sirenas.clear()
	var movidos := 0
	for v: Dictionary in t._vehiculos:
		if absf(float(v["s"]) - float(v["s_ini"])) > 1.0:
			movidos += 1
	m["cam"].queue_free()
	t.queue_free()
	sem.queue_free()
	jug.queue_free()
	amb.queue_free()
	return {"hashes": hashes, "azar": azar, "movidos": movidos, "snap": instantaneas, "n": t._vehiculos.size()}

static func probar(nat: Object, raiz: Node3D) -> Dictionary:
	var fallos: Array[String] = []
	var textos: Array[String] = []
	if nat == null or not nat.has_method("trafico_paso"):
		fallos.append("la extensión no tiene trafico_paso")
		return {"fallos": fallos, "textos": textos}
	var a := _correr(raiz, false)
	var b := _correr(raiz, true)
	var c := _correr(raiz, true, true)
	var primero := -1
	for i in PASOS:
		if a["hashes"][i] != b["hashes"][i]:
			primero = i
			break
	if primero >= 0:
		fallos.append("el estado difiere desde el paso %d" % primero)
		## Qué móvil y qué clave, en la última instantánea común.
		var j: int = primero / 30
		var sa: Array = a["snap"][j]
		var sb: Array = b["snap"][j]
		var dif := 0
		for q in sa.size():
			if sa[q] != sb[q] and dif < 3:
				dif += 1
				for z in mini(sa[q].size(), sb[q].size()):
					if sa[q][z] != sb[q][z]:
						fallos.append("instantánea %d, móvil %d: GDScript %s | C++ %s" % [j, q, str(sa[q][z]), str(sb[q][z])])
						break
	for i in PASOS:
		if a["hashes"][i] != c["hashes"][i]:
			fallos.append("al volver de la extensión a GDScript a mitad de camino el estado difiere desde el paso %d" % i)
			break
	if a["azar"] != c["azar"]:
		fallos.append("al volver de la extensión a GDScript el azar global llegó distinto")
	if a["azar"] != b["azar"]:
		fallos.append("el azar global llegó distinto (%s frente a %s): distinto número de llamadas a randf" % [str(a["azar"]), str(b["azar"])])
	if int(a["movidos"]) < 40:
		fallos.append("la prueba no mueve a casi nadie (%d móviles recorren más de 1 m)" % int(a["movidos"]))
	textos.append("tráfico de la ciudad (%d móviles, %d pasos): %d recorren más de 1 m" % [int(a["n"]), PASOS, int(a["movidos"])])
	return {"fallos": fallos, "textos": textos}
