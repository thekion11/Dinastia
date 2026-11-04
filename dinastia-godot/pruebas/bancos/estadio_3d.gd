extends BaseIdea
## BANCO ESPECIALIZADO «estadio_3d», FASE 2 (4-11-2026, megarreforma de los bancos): el estadio de 4 clubes distintos ya construido, pieza a pieza.
## Lo corre `herramientas/bancos_especiales.py estadio_3d` CON PANTALLA (xvfb + OpenGL): sin ella el motor no guarda las transformaciones ni los colores de los MultiMesh.
##   1. Butacas: colores del club (asiento 1/2/3 del perfil), ninguna sobre el campo, sin solapes, la grada sube con la distancia, aforo en rango.
##   2. Aficionados: cada uno sobre una butaca, sin solaparse entre sí.
##   3. Accesos: vomitorios, pasillos y escaleras.
##   4. Escala y alturas: campo reglamentario, nada enterrado, nada de la grada fuera de su sitio.
##   5. Iluminación: sol, torres de focos con luces, entorno.
##   6. Cada club con sus colores (y estadios distintos entre clubes distintos).
const Comun := preload("res://pruebas/bancos/ciudad_comun.gd")

var _dominantes: Array[String] = []
var _esperados: Array[String] = []

func _probar() -> void:
	_titulo("BANCO ESTADIO_3D (fase 2): butacas, aficionados, accesos, escala, luces y colores por club")
	if DisplayServer.get_name() == "headless":
		_comprobar(false, "este banco necesita pantalla (xvfb + OpenGL): córrelo con bancos_especiales.py estadio_3d")
		return
	Calidad.elegida = Calidad.MEDIO
	Partido.limpiar_contexto()
	var m := Mundo.new()
	var paises: Array[String] = ["CHI", "ARG"]
	m.generar(paises, 777)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var elegidos: Array = [m.ligas[0].clubes[0], m.ligas[0].clubes[5], m.ligas[m.ligas.size() - 1].clubes[2], m.ligas[m.ligas.size() - 1].clubes[9]]
	for c in elegidos:
		await _estadio(m, c)
	_colores_por_club()

func _estadio(m: Mundo, club: Club) -> void:
	var perfil: Dictionary = m.perfil_estadio_de(club)
	print("  ── %s · forma %s · aforo %d · asientos %s %s %s" % [club.nombre, str(perfil.get("forma")), int(perfil.get("aforo", 0)), str(perfil.get("asiento1")), str(perfil.get("asiento2")), str(perfil.get("asiento3"))])
	Azar.sembrar(4242)
	var v := VistaEstadio.new()
	add_child(v)
	await v.abrir(club, 0.5, null, null, perfil)
	for i in 60:
		await get_tree().process_frame
	var r: Node3D = v.get("_raiz3d")
	_campo_y_escala(r)
	var asientos := _butacas(r, perfil, club.nombre)
	_aficionados(r, asientos, club.nombre)
	_accesos(r, club.nombre)
	_luces(r, perfil, club.nombre)
	_enterrado(r, club.nombre)
	v.free()

## ---- 4. campo y escala
var _mitad := Vector2(52.5, 34.0)
var _centro := Vector2.ZERO

func _campo_y_escala(r: Node3D) -> void:
	var cesped := r.get_node_or_null("Cesped") as MeshInstance3D
	_comprobar(cesped != null, "hay césped")
	if cesped == null:
		return
	var t := cesped.get_aabb().size
	var ancho := maxf(t.x, t.z)
	var alto := minf(t.x, t.z)
	var cc := cesped.global_transform * cesped.get_aabb().get_center()
	_centro = Vector2(cc.x, cc.z)
	print("    centro del césped (%.1f, %.1f)" % [cc.x, cc.z])
	_mitad = Vector2(34.0, 52.5) if t.x < t.z else Vector2(52.5, 34.0)   ## el campo de juego (105 × 68), con su eje largo donde lo tenga el césped; el césped mide más: lleva su perímetro
	print("    césped %.1f × %.1f" % [ancho, alto])
	_comprobar(ancho >= 100.0 and ancho <= 125.0 and alto >= 64.0 and alto <= 85.0, "campo de medidas reglamentarias o algo mayores con su perímetro (%.1f × %.1f)" % [ancho, alto])

## ---- 1. butacas
func _butacas(r: Node3D, perfil: Dictionary, nombre: String) -> PackedVector3Array:
	var posiciones := PackedVector3Array()
	var colores := PackedColorArray()
	for g in r.find_children("Butacas*", "MultiMeshInstance3D", true, false):
		var mm := (g as MultiMeshInstance3D).multimesh
		for i in mm.instance_count:
			var col := mm.get_instance_color(i)
			var tf := mm.get_instance_transform(i)
			if col.a < 0.5 or tf.basis.get_scale().y < 0.01:
				continue   ## hueco o fila sin butaca (aforo): sin butaca
			posiciones.append((g as Node3D).global_transform * mm.get_instance_transform(i).origin)
			colores.append(col)
	var n := posiciones.size()
	var aforo := int(perfil.get("aforo", 0))
	print("    butacas %d (aforo %d)" % [n, aforo])
	_comprobar(n > 2000, "%s: butacas suficientes (%d)" % [nombre, n])
	_comprobar(float(n) > 0.04 * float(aforo) and float(n) < 3.0 * float(aforo), "%s: butacas y aforo en proporción (%d de aforo %d)" % [nombre, n, aforo])
	## Colores: cada butaca cerca de asiento1, 2 o 3 del perfil.
	var base: Array[Color] = []
	for k in ["asiento1", "asiento2", "asiento3"]:
		if perfil.has(k) and String(perfil[k]).begins_with("#"):
			base.append(Color(String(perfil[k])))
	var cerca := 0
	var cuenta := {}
	for col in colores:
		var mejor := 99.0
		var cual := -1
		for j in base.size():
			var d := Vector3(col.r - base[j].r, col.g - base[j].g, col.b - base[j].b).length()
			if d < mejor:
				mejor = d
				cual = j
		if mejor < 0.45:
			cerca += 1
			cuenta[cual] = int(cuenta.get(cual, 0)) + 1
	var fraccion := float(cerca) / maxf(1.0, float(n))
	print("    butacas con color del club: %.0f %% · reparto %s" % [fraccion * 100.0, str(cuenta)])
	_comprobar(fraccion >= 0.85, "%s: al menos el 85 %% de las butacas con los colores del club (%.0f %%)" % [nombre, fraccion * 100.0])
	var dom := -1
	var peor := 0
	for j in cuenta:
		if int(cuenta[j]) > peor:
			peor = int(cuenta[j])
			dom = int(j)
	_dominantes.append(base[dom].to_html(false) if dom >= 0 else "?")
	_esperados.append(String(perfil.get("asiento1", "")) + "|" + String(perfil.get("asiento2", "")) + "|" + String(perfil.get("asiento3", "")))
	## Solapes y campo
	var rejilla := {}
	var solapes := 0
	var en_campo := 0
	var ymin := INF
	var ymax := -INF
	for p in posiciones:
		var k := Vector3i(floori(p.x / 0.3), floori(p.y / 0.3), floori(p.z / 0.3))
		if rejilla.has(k):
			solapes += 1
		rejilla[k] = true
		if absf(p.x - _centro.x) < _mitad.x and absf(p.z - _centro.y) < _mitad.y:
			en_campo += 1
		ymin = minf(ymin, p.y)
		ymax = maxf(ymax, p.y)
	var bx := Vector4(INF, -INF, INF, -INF)
	for p in posiciones:
		bx = Vector4(minf(bx.x, p.x), maxf(bx.y, p.x), minf(bx.z, p.z), maxf(bx.w, p.z))
	print("    solapes %d, sobre el campo %d, alturas %.1f..%.1f m, extensión x %.0f..%.0f z %.0f..%.0f" % [solapes, en_campo, ymin, ymax, bx.x, bx.y, bx.z, bx.w])
	_comprobar(solapes <= int(0.002 * float(n)), "%s: butacas sin solapes (%d de %d, tope 0,2 %%)" % [nombre, solapes, n])
	_comprobar(en_campo == 0, "%s: ninguna butaca sobre el campo (%d)" % [nombre, en_campo])
	_comprobar(ymin >= -0.2 and ymax <= 80.0, "%s: butacas entre el suelo y 80 m (%.1f..%.1f)" % [nombre, ymin, ymax])
	## La grada sube al alejarse del campo.
	var sx := 0.0
	var sy := 0.0
	var sxx := 0.0
	var sxy := 0.0
	var syy := 0.0
	for p in posiciones:
		var d := Vector2(maxf(absf(p.x - _centro.x) - _mitad.x, 0.0), maxf(absf(p.z - _centro.y) - _mitad.y, 0.0)).length()
		sx += d
		sy += p.y
		sxx += d * d
		sxy += d * p.y
		syy += p.y * p.y
	var nn := float(maxi(1, n))
	var cov := sxy / nn - (sx / nn) * (sy / nn)
	var vx := sxx / nn - (sx / nn) * (sx / nn)
	var vy := syy / nn - (sy / nn) * (sy / nn)
	var corr := cov / maxf(0.0001, sqrt(vx * vy))
	var pendiente := cov / maxf(0.0001, vx)
	print("    distancia-altura de las butacas: correlación %.2f, pendiente %.2f m por m" % [corr, pendiente])
	_comprobar(pendiente > 0.1 and corr > 0.3, "%s: la grada sube al alejarse del campo (pendiente %.2f, correlación %.2f)" % [nombre, pendiente, corr])
	return posiciones

## ---- 2. aficionados
func _aficionados(r: Node3D, asientos: PackedVector3Array, nombre: String) -> void:
	var rejilla := {}
	for p in asientos:
		rejilla[Vector2i(floori(p.x / 1.0), floori(p.z / 1.0))] = true
	var total := 0
	var sobre := 0
	var solapes := 0
	var vistos := {}
	var cruces := {}
	for g in r.find_children("*", "MultiMeshInstance3D", true, false):
		var nm := String(g.name)
		if not (nm.begins_with("Hinchada") or nm.begins_with("PersonasCerca")):
			continue
		var grupo := "H" if nm.begins_with("Hinchada") else ("L" if nm.contains("_lejos_") else "P")   ## los de cerca (con animación) y los de lejos (Hinchada) se turnan por distancia: se miran por separado
		var mm := (g as MultiMeshInstance3D).multimesh
		for i in mm.instance_count:
			var col := mm.get_instance_color(i)
			var tr := (g as Node3D).global_transform * mm.get_instance_transform(i)
			if tr.basis.get_scale().y < 0.01 or col.a < 0.5:
				continue
			var p := tr.origin
			total += 1
			var celda := Vector2i(floori(p.x / 1.0), floori(p.z / 1.0))
			var hay := false
			for dx in [-1, 0, 1]:
				for dz in [-1, 0, 1]:
					if rejilla.has(celda + Vector2i(dx, dz)):
						hay = true
			if hay:
				sobre += 1
			var k := [grupo, floori(p.x / 0.25), floori(p.y / 0.25), floori(p.z / 0.25)]
			if vistos.has(k):
				solapes += 1
				var par := "%s~%s" % [vistos[k], nm.rstrip("0123456789@_")]
				cruces[par] = int(cruces.get(par, 0)) + 1
			vistos[k] = nm.rstrip("0123456789@_")
	print("    aficionados %d: sobre una butaca %.0f %%, solapes %d %s" % [total, 100.0 * float(sobre) / maxf(1.0, float(total)), solapes, str(cruces)])
	_comprobar(total > 500, "%s: hay aficionados (%d)" % [nombre, total])
	_comprobar(float(sobre) >= 0.9 * float(total), "%s: al menos el 90 %% de los aficionados junto a una butaca (%d de %d)" % [nombre, sobre, total])
	_comprobar(solapes <= int(0.01 * float(total)), "%s: aficionados separados (%d solapes de %d, tope 1 %%)" % [nombre, solapes, total])

## ---- 3. accesos
func _accesos(r: Node3D, nombre: String) -> void:
	var cuenta := {}
	for g in r.find_children("*", "MultiMeshInstance3D", true, false):
		var k := String(g.name).rstrip("0123456789@_")
		cuenta[k] = int(cuenta.get(k, 0)) + (g as MultiMeshInstance3D).multimesh.instance_count
	var vom := int(cuenta.get("VomitoriosHueco", 0))
	print("    accesos: vomitorios %d, pasillos %d, escaleras %d, barandillas %d" % [vom, int(cuenta.get("Pasillos", 0)), int(cuenta.get("EscalerasAcceso", 0)), int(cuenta.get("Barandillas", 0))])
	_comprobar(vom >= 8, "%s: vomitorios (%d)" % [nombre, vom])
	_comprobar(int(cuenta.get("Pasillos", 0)) >= 100, "%s: pasillos entre butacas (%d)" % [nombre, int(cuenta.get("Pasillos", 0))])
	_comprobar(int(cuenta.get("EscalerasAcceso", 0)) >= 10, "%s: escaleras de acceso (%d)" % [nombre, int(cuenta.get("EscalerasAcceso", 0))])
	_comprobar(r.get_node_or_null("TunelVestuario") != null, "%s: túnel de vestuarios" % nombre)
	_comprobar(int(cuenta.get("Barandillas", 0)) >= 100, "%s: barandillas (%d)" % [nombre, int(cuenta.get("Barandillas", 0))])

## ---- 5. iluminación
func _luces(r: Node3D, perfil: Dictionary, nombre: String) -> void:
	var soles := 0
	for l in r.find_children("*", "DirectionalLight3D", true, false):
		if (l as Light3D).light_energy > 0.0:
			soles += 1
	var torres := r.find_children("TorreFocos*", "Node3D", true, false)
	var emisivos := 0
	var altas := 0
	for t in torres:
		var tiene := false
		var ymax := -INF
		for n in (t as Node).find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			ymax = maxf(ymax, (mi.global_transform * mi.get_aabb()).end.y)
			for k in mi.mesh.get_surface_count() if mi.mesh != null else 0:
				var mat := mi.get_active_material(k)
				if mat is StandardMaterial3D and (mat as StandardMaterial3D).emission_enabled:
					tiene = true
		if tiene:
			emisivos += 1
		if ymax > 20.0:
			altas += 1
	var luces := r.find_children("*", "Light3D", true, false).size() - soles
	print("    luces: soles %d, torres de focos %d (%d con focos emisivos, %d de más de 20 m), otras luces %d; entorno %d" % [soles, torres.size(), emisivos, altas, luces, r.find_children("*", "WorldEnvironment", true, false).size()])
	_comprobar(soles >= 1 and soles <= 3, "%s: sol direccional (%d)" % [nombre, soles])
	var esperadas := 1 if String(perfil.get("focos", "torres")) == "torres" else 0
	_comprobar(torres.size() >= esperadas, "%s: torres de focos según el perfil (%d de al menos %d)" % [nombre, torres.size(), esperadas])
	_comprobar(luces >= 4 or esperadas == 0, "%s: luces repartidas por el recinto (%d)" % [nombre, luces])
	_comprobar(emisivos == torres.size() and altas == torres.size(), "%s: todas las torres con focos que lucen y más de 20 m de alto (%d/%d, %d)" % [nombre, emisivos, torres.size(), altas])
	_comprobar(r.find_children("*", "WorldEnvironment", true, false).size() >= 1, "%s: entorno del cielo" % nombre)
	var marcadores := r.find_children("PantallaMarcador*", "MeshInstance3D", true, false).size()
	var esperado := 2 if String(perfil.get("pantalla", "dos")) == "dos" else (1 if String(perfil.get("pantalla", "")) == "una" else -1)
	if esperado >= 0:
		_comprobar(marcadores == esperado, "%s: pantallas de marcador según el perfil (%d de %d)" % [nombre, marcadores, esperado])

## ---- 4. nada enterrado
func _enterrado(r: Node3D, nombre: String) -> void:
	var bajo := 0
	var ejemplos: Array[String] = []
	for h in r.get_children():
		if h is MeshInstance3D and (h as MeshInstance3D).mesh != null and (h as MeshInstance3D).visible:
			var c := (h as MeshInstance3D).global_transform * (h as MeshInstance3D).get_aabb()
			if c.end.y < -0.5 and not String(h.name).begins_with("Sombra"):
				bajo += 1
				ejemplos.append("%s y=%.1f..%.1f" % [h.name, c.position.y, c.end.y])
	_comprobar(bajo == 0, "%s: ninguna pieza del estadio enterrada bajo el suelo (%d)%s" % [nombre, bajo, "" if bajo == 0 else " " + str(ejemplos.slice(0, 4))])

## ---- 6. colores por club
func _colores_por_club() -> void:
	print("  colores dominantes de butaca por estadio: ", _dominantes, " esperados ", _esperados)
	var distintos := {}
	for e in _esperados:
		distintos[e] = true
	var doms := {}
	for d in _dominantes:
		doms[d] = true
	_comprobar(not _dominantes.has("?"), "cada estadio tiene un color dominante de butaca de su perfil")
	if distintos.size() >= 2:
		_comprobar(doms.size() >= 2, "clubes con colores distintos tienen estadios de butacas distintas (%d colores dominantes para %d perfiles)" % [doms.size(), distintos.size()])
