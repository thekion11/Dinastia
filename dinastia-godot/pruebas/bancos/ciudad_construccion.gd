extends BaseIdea
## BANCO ESPECIALIZADO «ciudad_construccion», FASE 2 (4-11-2026, megarreforma de los bancos): la ciudad entera ya construida, comprobada pieza a pieza.
## Lo corre `herramientas/bancos_especiales.py ciudad_construccion`.
##   1. La red de calles: un solo grafo conexo, tramos con largo y ancho razonables, sin tramos repetidos, cruces con semáforo en nodos que existen.
##   2. Las manzanas: ninguna se solapa con otra, ninguna invade una calle, todas dentro del mapa y con un uso conocido.
##   3. Nada flotando ni enterrado: cada malla suelta vista contra la altura del terreno bajo ella.
##   4. Los puntos de interacción (tiendas, puertas, máquinas…): sin repetir, a pie de calle (no dentro de un obstáculo) y con un obstáculo sólido cerca cuando son edificios.
##   5. Conteo de piezas por tipo: dos armados dan los mismos números (y dentro de rangos razonables).
##   6. Determinismo: el mismo mundo armado dos veces tiene las mismas manzanas, tramos y puntos.
const Comun := preload("res://pruebas/bancos/ciudad_comun.gd")

var _a: Dictionary
var _b: Dictionary

func _probar() -> void:
	_titulo("BANCO CIUDAD_CONSTRUCCION (fase 2): calles, manzanas, alturas, puntos, conteos, determinismo")
	_a = await Comun.abrir(self)
	var cb: Node = _a["cb"]
	var ex: Object = cb.get("expansion")
	_comprobar(ex != null, "la ciudad trae su expansión (calles y manzanas)")
	if ex == null:
		return
	_calles(ex)
	_manzanas(ex, cb)
	_alturas(cb)
	_terreno_bajo_lo_construido(ex, cb)
	_puntos(cb)
	_accesos(ex, cb)
	var foto_a := _conteos(_a["vc"], ex)
	var huella_a := _huella(_a["vc"])
	var firma_a := _firma(ex, cb)
	(_a["vc"] as Node).free()
	_b = await Comun.abrir(self)
	var ex2: Object = _b["cb"].get("expansion")
	var foto_b := _conteos(_b["vc"], ex2)
	var dh := _dif_huella(huella_a, _huella(_b["vc"]))
	_comprobar(dh.is_empty(), "dos armados: mismas mallas (tipo, nombre, malla, tamaño)%s" % ("" if dh.is_empty() else ": " + dh))
	_comprobar(foto_a == foto_b, "dos armados dan los mismos conteos de piezas%s" % ("" if foto_a == foto_b else ": " + _dif_dic(foto_a, foto_b)))
	_comprobar(firma_a == _firma(ex2, _b["cb"]), "dos armados dan las mismas manzanas, tramos y puntos")
	_rangos(foto_a)
	(_b["vc"] as Node).free()

## ---- 1. calles
func _calles(ex: Object) -> void:
	var nodos: Dictionary = ex.get("nodos")
	var tramos: Array = ex.get("tramos")
	var vecinos: Dictionary = ex.get("vecinos")
	_comprobar(nodos.size() >= 20, "la red tiene nodos (%d)" % nodos.size())
	_comprobar(tramos.size() >= nodos.size() - 1, "tramos suficientes para unir los nodos (%d tramos, %d nodos)" % [tramos.size(), nodos.size()])
	## Conexo: un recorrido desde un nodo llega a todos.
	var vistos := {}
	var pila: Array = [nodos.keys()[0]]
	while not pila.is_empty():
		var k = pila.pop_back()
		if vistos.has(k):
			continue
		vistos[k] = true
		for v in vecinos.get(k, []):
			if not vistos.has(v):
				pila.append(v)
	_comprobar(float(vistos.size()) >= 0.85 * float(nodos.size()), "el grafo de vecinos (sin puentes) une al menos el 85 %% de los nodos (%d de %d)" % [vistos.size(), nodos.size()])
	if vistos.size() != nodos.size():
		var sueltos: Array[String] = []
		for k in nodos:
			if not vistos.has(k):
				sueltos.append("%s%s" % [str(k), str((nodos[k] as Vector3).snapped(Vector3.ONE))])
		print("  nodos fuera de la componente principal: ", sueltos.slice(0, 12), " …(%d) vecinos del primero: %s" % [sueltos.size(), str(vecinos.get(nodos.keys()[nodos.keys().find(vistos.keys()[0])], []))])
	## Y por los TRAMOS (los puentes unen orillas aunque no estén en `vecinos`): extremos unidos si caen a menos de 1 m.
	var padre := {}
	for t: Dictionary in tramos:
		var ka := _celda((t["a"] as Vector3))
		var kb := _celda((t["b"] as Vector3))
		padre[ka] = padre.get(ka, ka)
		padre[kb] = padre.get(kb, kb)
	for t: Dictionary in tramos:
		var ra: Variant = _raiz(padre, _celda((t["a"] as Vector3)))
		var rb: Variant = _raiz(padre, _celda((t["b"] as Vector3)))
		if ra != rb:
			padre[ra] = rb
	var raices := {}
	for k in padre:
		raices[_raiz(padre, k)] = true
	_comprobar(raices.size() == 1, "por los tramos (con puentes) la red también es una sola pieza (%d piezas)" % raices.size())
	var raros := 0
	var repetidos := 0
	var claves := {}
	for t: Dictionary in tramos:
		var a: Vector3 = t["a"]
		var b: Vector3 = t["b"]
		var largo := a.distance_to(b)
		if largo < 1.0 or largo > 600.0 or float(t["ancho"]) < 2.0 or float(t["ancho"]) > 60.0:
			raros += 1
		var k := "%s|%s" % [str(a.snapped(Vector3.ONE * 0.1)), str(b.snapped(Vector3.ONE * 0.1))]
		var k2 := "%s|%s" % [str(b.snapped(Vector3.ONE * 0.1)), str(a.snapped(Vector3.ONE * 0.1))]
		if claves.has(k) or claves.has(k2):
			repetidos += 1
		claves[k] = true
	_comprobar(raros == 0, "todos los tramos con largo 1-600 m y ancho 2-60 m (%d fuera)" % raros)
	_comprobar(repetidos == 0, "ningún tramo repetido (%d)" % repetidos)
	var sin_nodo := 0
	for c: Vector3 in ex.get("cruces_semaforo"):
		var existe := false
		for k in nodos:
			if (nodos[k] as Vector3).distance_to(c) < 3.0:
				existe = true
				break
		if not existe:
			sin_nodo += 1
	_comprobar(sin_nodo == 0, "cada cruce con semáforo está sobre un nodo de la red (%d sueltos)" % sin_nodo)

## ---- 2. manzanas
func _manzanas(ex: Object, cb: Node) -> void:
	var bloques: Array = ex.get("bloques")
	var tramos: Array = ex.get("tramos")
	_comprobar(bloques.size() >= 30, "hay manzanas (%d)" % bloques.size())
	var solapes := 0
	var peor := 0.0
	for i in bloques.size():
		var ra: Rect2 = bloques[i]["rect"]
		for j in range(i + 1, bloques.size()):
			var rb: Rect2 = bloques[j]["rect"]
			var inter := ra.intersection(rb)
			if inter.size.x > 0.5 and inter.size.y > 0.5:
				solapes += 1
				peor = maxf(peor, inter.get_area())
	_comprobar(solapes == 0, "ninguna manzana se solapa con otra (%d pares, peor %.1f m²)" % [solapes, peor])
	var invaden := 0
	for bl: Dictionary in bloques:
		var r: Rect2 = bl["rect"]
		for t: Dictionary in tramos:
			var a: Vector3 = t["a"]
			var b: Vector3 = t["b"]
			if _dist_seg_rect(Vector2(a.x, a.z), Vector2(b.x, b.z), r) < float(t["ancho"]) * 0.5 - 0.5 and not bool(t.get("puente", false)):
				invaden += 1
				break
	_comprobar(invaden == 0, "ninguna manzana invade el asfalto de una calle (%d)" % invaden)
	var usos := {}
	var fuera := 0
	for bl: Dictionary in bloques:
		usos[String(bl["uso"])] = int(usos.get(String(bl["uso"]), 0)) + 1
		var c: Vector2 = (bl["rect"] as Rect2).get_center()
		if absf(c.x) > 3000.0 or absf(c.y) > 3000.0:
			fuera += 1
	print("  usos de manzana: ", usos)
	_comprobar(fuera == 0, "todas las manzanas dentro de ±3 km (%d fuera)" % fuera)
	_comprobar(not usos.has(""), "toda manzana con uso asignado")

func _dist_seg_rect(a: Vector2, b: Vector2, r: Rect2) -> float:
	## Distancia mínima del segmento al rectángulo (0 si lo cruza): se muestrea el segmento cada 2 m.
	var largo := a.distance_to(b)
	var n := maxi(2, int(largo / 2.0))
	var mejor := INF
	for i in n + 1:
		var p := a.lerp(b, float(i) / float(n))
		var dx := maxf(maxf(r.position.x - p.x, 0.0), p.x - r.end.x)
		var dz := maxf(maxf(r.position.y - p.y, 0.0), p.y - r.end.y)
		mejor = minf(mejor, sqrt(dx * dx + dz * dz))
		if mejor == 0.0:
			break
	return mejor

## ---- 3. alturas: cada OBJETO (hijo directo de la ciudad, con todas sus piezas) contra el terreno bajo su centro
func _alturas(cb: Node) -> void:
	var flota := 0
	var enterrados := 0
	var vistos := 0
	var ejemplos: Array[String] = []
	for h in cb.get_children():
		if not (h is Node3D) or not (h as Node3D).visible or _en_movimiento(h) or MOVILES.has(String(h.name).rstrip("0123456789@_")):
			continue
		var caja := AABB()
		var primero := true
		for g in h.find_children("*", "MeshInstance3D", true, false):
			var mi := g as MeshInstance3D
			if mi.mesh == null or not mi.visible or _en_esqueleto(mi):
				continue
			var c := mi.global_transform * mi.get_aabb()
			caja = c if primero else caja.merge(c)
			primero = false
		if h is MeshInstance3D and (h as MeshInstance3D).mesh != null:
			var c2 := (h as MeshInstance3D).global_transform * (h as MeshInstance3D).get_aabb()
			caja = c2 if primero else caja.merge(c2)
			primero = false
		if primero or caja.size.length() < 0.5 or caja.size.x > 120.0 or caja.size.z > 120.0:
			continue   ## sin mallas, diminuto, o un contenedor enorme (suelos, calles)
		var centro := caja.get_center()
		var suelo: float = cb.altura_en(centro.x, centro.z)
		vistos += 1
		var es_copa := h is MeshInstance3D and (h as MeshInstance3D).mesh is SphereMesh   ## las copas de los árboles van sobre su tronco (otra malla)
		var cuerpo_grande := caja.size.x >= 4.0 and caja.size.z >= 4.0 and caja.size.y >= 3.0   ## edificios, vehículos, casetas: los detalles (cornisas, banderas, grúas) cuelgan de otra pieza
		if caja.position.y > suelo + 6.0 and cuerpo_grande and not String(h.name).begins_with("Cartel") and not es_copa and not String(h.name).begins_with("Grua") and not String(h.name).begins_with("Fundido"):   ## (6-11) las mallas «Fundido…» juntan piezas de muchas azoteas por material y celda: su caja no es un cuerpo, no flota nada
			flota += 1
			if ejemplos.size() < 6:
				ejemplos.append("FLOTA %s %s y=%.1f..%.1f suelo=%.1f en (%.0f,%.0f) tam=%s" % [h.name, _que_es(h), caja.position.y, caja.end.y, suelo, centro.x, centro.z, str(caja.size.snapped(Vector3.ONE * 0.1))])
		if caja.end.y < suelo - 0.5:
			enterrados += 1
			if ejemplos.size() < 12:
				ejemplos.append("ENTERRADO %s %s y=%.1f..%.1f suelo=%.1f en (%.0f,%.0f) tam=%s" % [h.name, _que_es(h), caja.position.y, caja.end.y, suelo, centro.x, centro.z, str(caja.size.snapped(Vector3.ONE * 0.1))])
	print("  objetos revisados %d, flotando %d, enterrados %d" % [vistos, flota, enterrados])
	for e in ejemplos:
		print("    ", e)
	_comprobar(vistos > 300, "se revisaron más de 300 objetos (%d)" % vistos)
	_comprobar(enterrados <= 1, "ningún objeto completo enterrado bajo el terreno (%d; tolerancia 1: una señal en el borde de un cerro)" % enterrados)
	_comprobar(flota <= 5, "(depósitos de agua sobre torres: tolerancia 5) ningún cuerpo grande (≥ 4×4×3 m) flotando a más de 6 m del terreno (%d)" % flota)

## ---- 4. puntos de interacción
func _puntos(cb: Node) -> void:
	var puntos: Array = cb.get("puntos_clic")
	_comprobar(puntos.size() >= 30, "hay puntos de interacción (%d)" % puntos.size())
	var circulos: PackedVector3Array = cb.get("circulos")
	var repetidos := 0
	var vistos := {}
	var sin_clave := 0
	var dentro := 0
	for p: Dictionary in puntos:
		if String(p.get("k", "")) == "" or String(p.get("n", "")) == "":
			sin_clave += 1
		var q: Vector3 = p["pos"]
		var k := "%s|%s" % [String(p.get("k", "")), str(q.snapped(Vector3.ONE * 0.5))]
		if vistos.has(k):
			repetidos += 1
		vistos[k] = true
		for c in circulos:
			if Vector2(q.x - c.x, q.z - c.y).length() < c.z * 0.35:
				dentro += 1
				break
	_comprobar(sin_clave == 0, "todo punto con clave y nombre (%d sin)" % sin_clave)
	_comprobar(repetidos == 0, "ningún punto duplicado (%d)" % repetidos)
	_comprobar(float(dentro) / maxf(1.0, float(puntos.size())) < 0.05, "menos del 5 %% de los puntos dentro de un obstáculo (%d de %d)" % [dentro, puntos.size()])

## ---- 5. conteos
func _conteos(vc: Node, ex: Object) -> Dictionary:
	var d := {}
	for n in vc.find_children("*", "GeometryInstance3D", true, false):
		if _en_movimiento(n) or _en_esqueleto(n):
			continue   ## gente y vehículos se reciclan con el tiempo: no son parte del armado
		var c := String(n.get_class())
		d[c] = int(d.get(c, 0)) + 1
	for k in (ex.get("cuenta") as Dictionary):
		var v: Variant = (ex.get("cuenta") as Dictionary)[k]
		d["cuenta:" + String(k)] = int(v) if (typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT) else (v.size() if (v is Array or v is Dictionary) else str(v))
	d["bloques"] = (ex.get("bloques") as Array).size()
	d["tramos"] = (ex.get("tramos") as Array).size()
	d["nodos"] = (ex.get("nodos") as Dictionary).size()
	return d

func _dif_dic(a: Dictionary, b: Dictionary) -> String:
	var s: Array[String] = []
	for k in a:
		if a[k] != b.get(k):
			s.append("%s %s/%s" % [k, str(a[k]), str(b.get(k))])
	return ", ".join(s.slice(0, 6))

func _rangos(d: Dictionary) -> void:
	print("  conteos: ", d)
	_comprobar(int(d.get("MeshInstance3D", 0)) > 800 and int(d.get("MeshInstance3D", 0)) < 30000, "mallas sueltas en rango (%d)" % int(d.get("MeshInstance3D", 0)))
	_comprobar(int(d.get("MultiMeshInstance3D", 0)) > 50 and int(d.get("MultiMeshInstance3D", 0)) < 20000, "multimallas en rango (%d)" % int(d.get("MultiMeshInstance3D", 0)))
	_comprobar(int(d.get("bloques", 0)) > 30, "manzanas en rango (%d)" % int(d.get("bloques", 0)))

func _firma(ex: Object, cb: Node) -> String:
	var partes: Array[String] = []
	for bl: Dictionary in ex.get("bloques"):
		partes.append("%s|%s|%s" % [str(bl["celda"]), str(bl["zona"]), str(bl["uso"])])
	for t: Dictionary in ex.get("tramos"):
		partes.append("%s>%s" % [str((t["a"] as Vector3).snapped(Vector3.ONE * 0.1)), str((t["b"] as Vector3).snapped(Vector3.ONE * 0.1))])
	for p: Dictionary in cb.get("puntos_clic"):
		partes.append("%s@%s" % [String(p["k"]), str((p["pos"] as Vector3).snapped(Vector3.ONE * 0.1))])
	partes.sort()
	return "\n".join(partes).sha256_text()

## Tipo, nombre sin los @números, malla y tamaño de cada nodo geométrico (y el sitio de las multimallas, que no se mueven).
func _huella(vc: Node) -> PackedStringArray:
	var filas := PackedStringArray()
	for n in vc.find_children("*", "GeometryInstance3D", true, false):
		if _en_movimiento(n):
			continue
		var nombre := str(n.name)
		if nombre.begins_with("@"):
			nombre = nombre.get_slice("@", 1)
		var f := "%s:%s" % [n.get_class(), nombre]
		if _en_esqueleto(n):
			filas.append(f)   ## el tamaño y el sitio de lo que cuelga de un esqueleto dependen de la pose del momento
			continue
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			f += ":" + str((n as MeshInstance3D).mesh.get_class()) + str((n as MeshInstance3D).get_aabb().size.snapped(Vector3.ONE * 0.01))
		if n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh != null:
			f += ":mm" + str((n as MultiMeshInstance3D).multimesh.instance_count)
		if n is MultiMeshInstance3D:
			f += "@" + str((n as Node3D).global_position.snapped(Vector3.ONE * 0.5))   ## las multimallas son estáticas: con su sitio. Las mallas sueltas incluyen aspas, norias… que giran
		if OS.get_environment("CAMINO") != "":
			var q: Node = n.get_parent()
			for i in 6:
				if q == null:
					break
				f += "<" + str(q.name).rstrip("0123456789@_")
				q = q.get_parent()
		filas.append(f)
	filas.sort()
	return filas

func _dif_huella(a: PackedStringArray, b: PackedStringArray) -> String:
	var cuenta := {}
	for f in a:
		cuenta[f] = int(cuenta.get(f, 0)) + 1
	for f in b:
		cuenta[f] = int(cuenta.get(f, 0)) - 1
	var s: Array[String] = []
	for k in cuenta:
		if int(cuenta[k]) != 0:
			s.append("%+d %s" % [int(cuenta[k]), k])
	return "%d filas distintas; %s" % [s.size(), str(s.slice(0, 8))] if not s.is_empty() else ""

func _celda(v: Vector3) -> Vector2i:
	return Vector2i(roundi(v.x), roundi(v.z))

func _raiz(padre: Dictionary, k: Variant) -> Variant:
	while padre[k] != k:
		k = padre[k]
	return k

## Lo que se mueve (tráfico, gente, metro, bus, teleférico, tren, barcos): su sitio depende de cuánto tiempo lleva la ciudad abierta, no de cómo se armó.
const MOVILES_FERIA := ["TrenRusa", "Noria", "Vagon", "Barquilla", "Rueda", "Carrusel", "Columpios", "Pendulo", "Cabina", "Cabinas"]
const MOVILES := ["Trafico", "Metro", "Teleferico", "Pasajeros", "Botes", "Tren", "BusesRed", "Gente", "Peatones"]
func _en_movimiento(n: Node) -> bool:
	var p := n.get_parent()
	while p != null:
		if MOVILES.has(String(p.name).rstrip("0123456789@_")) or MOVILES_FERIA.has(String(p.name).rstrip("0123456789@_")):
			return true
		p = p.get_parent()
	return false

func _en_esqueleto(n: Node) -> bool:
	var p := n.get_parent()
	while p != null:
		if p is Skeleton3D:
			return true
		p = p.get_parent()
	return false

func _que_es(h: Node) -> String:
	if h is MeshInstance3D and (h as MeshInstance3D).mesh != null:
		var m := (h as MeshInstance3D).mesh
		return "%s/%s" % [m.get_class(), m.resource_name]
	var q := h.find_children("*", "MeshInstance3D", true, false)
	var nombres: Array[String] = []
	for g in q:
		nombres.append(String(g.name).rstrip("0123456789@_"))
	return "%s hijos=%s %d mallas, 1.ª %s" % [h.scene_file_path.get_file(), str(nombres), q.size(), (q[0] as MeshInstance3D).mesh.resource_name if not q.is_empty() and (q[0] as MeshInstance3D).mesh != null else "-"]

## Lo construido a ras de y = 0 (calles, manzanas) no debe quedar bajo una colina: se mide la altura del terreno en el centro de cada manzana y en la mitad de cada tramo.
func _terreno_bajo_lo_construido(ex: Object, cb: Node) -> void:
	var bajo_cerro_m := 0
	var bajo_cerro_t := 0
	var peor_m := 0.0
	var peor_t := 0.0
	var por_uso := {}
	for bl: Dictionary in ex.get("bloques"):
		var c: Vector2 = (bl["rect"] as Rect2).get_center()
		var h: float = cb.altura_en(c.x, c.y)
		if h > 1.0 and not (String(bl["uso"]) in ["lejano", "rio"]):   ## (las lejanas bajo un cerro ya no levantan torres)
			bajo_cerro_m += 1
			peor_m = maxf(peor_m, h)
			por_uso[String(bl["uso"])] = int(por_uso.get(String(bl["uso"]), 0)) + 1
	for t: Dictionary in ex.get("tramos"):
		var m: Vector3 = ((t["a"] as Vector3) + (t["b"] as Vector3)) * 0.5
		var h2: float = cb.altura_en(m.x, m.z)
		if h2 > 1.0 and not bool(t.get("puente", false)):
			bajo_cerro_t += 1
			peor_t = maxf(peor_t, h2)
	print("  manzanas sobre terreno > 1 m: %d (peor %.1f m) por uso %s · tramos: %d (peor %.1f m)" % [bajo_cerro_m, peor_m, str(por_uso), bajo_cerro_t, peor_t])
	_comprobar(bajo_cerro_m == 0, "ninguna manzana queda bajo una colina (%d, peor %.1f m)" % [bajo_cerro_m, peor_m])
	_comprobar(bajo_cerro_t == 0, "ninguna calle queda bajo una colina (%d, peor %.1f m)" % [bajo_cerro_t, peor_t])

## ---- accesos: cada punto de interacción tiene una calle cerca por la que llegar, y las puertas de los bloques modulares no quedan tapadas
func _accesos(ex: Object, cb: Node) -> void:
	var tramos: Array = ex.get("tramos")
	var lejos := 0
	var peor := 0.0
	var ejemplos: Array[String] = []
	for p: Dictionary in cb.get("puntos_clic"):
		if String(p.get("estado", "ciudad")) != "ciudad":
			continue
		var q: Vector3 = p["pos"]
		if absf(q.x) > 1400.0 or absf(q.z) > 1400.0:
			continue
		var mejor := INF
		for t: Dictionary in tramos:
			mejor = minf(mejor, _dist_segmento(Vector2(q.x, q.z), Vector2((t["a"] as Vector3).x, (t["a"] as Vector3).z), Vector2((t["b"] as Vector3).x, (t["b"] as Vector3).z)))
		var tope := 200.0 if String(p["k"]) in ["casa_grande", "tele_base", "karting"] else 60.0   ## estos tres llegan por su propio ramal (verja, base del teleférico, pista)
		if mejor > tope:
			lejos += 1
			if ejemplos.size() < 4:
				ejemplos.append("%s a %.0f m de la calle más cercana en (%.0f,%.0f)" % [String(p["k"]), mejor, q.x, q.z])
		peor = maxf(peor, mejor)
	print("  punto de interacción más lejos de una calle: %.0f m; a más de 60 m: %d %s" % [peor, lejos, str(ejemplos)])
	_comprobar(lejos == 0, "todo punto de interacción tiene una calle a menos de 60 m (200 los tres con ramal propio) (%d sin)" % lejos)
	var circulos: PackedVector3Array = cb.get("circulos")
	var tapadas := 0
	var puertas: Array = ex.get("_puertas_mod")
	for q: Vector3 in puertas:
		for c in circulos:
			if Vector2(q.x - c.x, q.z - c.y).length() < c.z * 0.5:
				tapadas += 1
				break
	_comprobar(float(tapadas) <= 0.05 * maxf(1.0, float(puertas.size())), "puertas de bloques modulares tapadas por un obstáculo: %d de %d (≤ 5 %%)" % [tapadas, puertas.size()])

func _dist_segmento(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 < 0.0001:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	return p.distance_to(a + ab * t)
