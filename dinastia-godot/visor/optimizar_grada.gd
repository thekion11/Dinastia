class_name OptimizarGrada
extends RefCounted
## CULLING POR TROZOS DE LA GRADA (M-345, 28-10-2026). Cada tribuna lleva UN `MultiMesh` de miles de butacas (y otro de hinchas): su caja envolvente
## abarca toda la tribuna, así que con un solo rincón en pantalla se dibuja ENTERO. Aquí se parte en `tramos` trozos del mismo número de
## instancias a lo largo del eje largo de la tribuna: cada trozo tiene su propia caja y el culling de la cámara descarta los que no se ven.
## Mismo material, sombra y capa; el nombre se conserva con sufijo (`ButacasCerca_3`), que es lo que buscan `Optimizar.butacas_livianas` y la prueba.

const NOMBRES := ["ButacasCerca", "ButacasLejos", "Hinchada", "HinchadaCerca"]
const MIN_INSTANCIAS := 600
static var activo := true   ## las comprobaciones de «antes» (imágenes sin trocear) lo apagan

## Parte los MultiMesh grandes de la grada colgados de `raiz`. Devuelve cuántos partió.
## 2-11-2026 (120 FPS): en calidad MEDIO (y en el perfil ligero automático) las butacas cercanas llevan desde el principio la malla
## liviana (84 triángulos en vez de 1 944): medido en el partido, −36 % de triángulos (1,34 M → 0,85 M). ALTO y ULTRA no cambian.
## Trozos por tribuna según el nivel de calidad (6-11). Más trozos = menos triángulos fuera de pantalla pero más llamadas de dibujo;
## `TRAMOS_GRADA=n` fuerza un valor (solo para medir con `medir_partido.tscn`).
static func tramos_de(nivel: int) -> int:
	if OS.get_environment("TRAMOS_GRADA") != "":
		return maxi(1, int(OS.get_environment("TRAMOS_GRADA")))
	## ULTRA BAJA y BAJA (6-11): 3 trozos en vez de 8 (medido en ULTRA BAJA: 338 → 325 llamadas, +28 k triángulos); se ve igual.
	return 3 if nivel <= Calidad.BAJA else 8

static func trocear(raiz: Node, tramos := -1) -> int:
	if tramos < 0:
		tramos = tramos_de(Calidad.elegida)
	var hechos := _trocear(raiz, tramos)
	if Calidad.elegida <= Calidad.MEDIO:
		Optimizar.butacas_livianas(raiz, true)
	return hechos

static func _trocear(raiz: Node, tramos: int) -> int:
	if not activo or DisplayServer.get_name() == "headless":
		return 0   ## sin pantalla los MultiMesh no guardan sus datos
	var hechos := 0
	for nombre: String in NOMBRES:
		for n in raiz.find_children(nombre, "MultiMeshInstance3D", true, false):
			var mmi := n as MultiMeshInstance3D
			var mm := mmi.multimesh
			if mm == null or mm.mesh == null or mm.instance_count < MIN_INSTANCIAS or mm.transform_format != MultiMesh.TRANSFORM_3D:
				continue
			_partir(mmi, tramos)
			hechos += 1
	return hechos

static func _partir(mmi: MultiMeshInstance3D, tramos: int) -> void:
	var mm := mmi.multimesh
	var cuantas := mm.instance_count
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var pos := PackedVector2Array()
	pos.resize(cuantas)
	for i in cuantas:
		var o := mm.get_instance_transform(i).origin
		pos[i] = Vector2(o.x, o.z)
		lo = lo.min(pos[i])
		hi = hi.max(pos[i])
	var eje := 0 if (hi.x - lo.x) >= (hi.y - lo.y) else 1
	var orden: Array = range(cuantas)
	orden.sort_custom(func(a: int, b: int) -> bool: return pos[a][eje] < pos[b][eje])
	var por_tramo := ceili(float(cuantas) / float(tramos))
	var padre := mmi.get_parent()
	for t in tramos:
		var desde := t * por_tramo
		var hasta := mini(cuantas, desde + por_tramo)
		if desde >= hasta:
			break
		var nuevo := MultiMesh.new()
		nuevo.transform_format = MultiMesh.TRANSFORM_3D
		nuevo.use_colors = mm.use_colors
		nuevo.use_custom_data = mm.use_custom_data
		nuevo.mesh = mm.mesh
		nuevo.instance_count = hasta - desde
		for j in hasta - desde:
			var k: int = orden[desde + j]
			nuevo.set_instance_transform(j, mm.get_instance_transform(k))
			if mm.use_colors:
				nuevo.set_instance_color(j, mm.get_instance_color(k))
			if mm.use_custom_data:
				nuevo.set_instance_custom_data(j, mm.get_instance_custom_data(k))
		var m2 := MultiMeshInstance3D.new()
		m2.name = "%s_%d" % [mmi.name, t]
		m2.multimesh = nuevo
		m2.transform = mmi.transform
		m2.material_override = mmi.material_override
		m2.material_overlay = mmi.material_overlay
		m2.cast_shadow = mmi.cast_shadow
		m2.layers = mmi.layers
		m2.gi_mode = mmi.gi_mode
		m2.visibility_range_begin = mmi.visibility_range_begin
		m2.visibility_range_end = mmi.visibility_range_end
		m2.visibility_range_end_margin = mmi.visibility_range_end_margin
		for g in mmi.get_groups():
			m2.add_to_group(g)
		for m in mmi.get_meta_list():
			m2.set_meta(m, mmi.get_meta(m))
		padre.add_child(m2)
	padre.remove_child(mmi)
	mmi.free()

## EL PRÓLOGO NO NECESITA VER LEJOS (2-11-2026): tope de distancia de dibujo para todo lo pequeño o mediano que no tenga uno más
## corto (lo grande -terreno, horizonte, edificios de más de `GRANDE` m- se queda). Fuera del estadio (`sin_corte`) y sin rótulos.
## Devuelve cuántos objetos recibieron el tope.
const ROTULO_MINIMO := 45.0

static func limitar_vista(raiz: Node, hasta: float, grande := 90.0, guardar = null) -> int:
	var fuera := {}
	for r in raiz.find_children("*", "Node3D", true, false):
		if r.has_meta("sin_corte"):
			for x in r.find_children("*", "GeometryInstance3D", true, false):
				fuera[x] = true
	var n := 0
	for g_n in raiz.find_children("*", "GeometryInstance3D", true, false):
		var g := g_n as GeometryInstance3D
		if g is Label3D:
			## (3-11, R2 en MÍNIMO) Un rótulo no se lee a más de ~45 m y cada uno cuesta una llamada de dibujo: a pie de calle eran 2.584 y quitaban −19 % de llamadas.
			if not fuera.has(g) and Calidad.elegida <= Calidad.MINIMO and (g.visibility_range_end <= 0.0 or g.visibility_range_end > ROTULO_MINIMO):
				g.visibility_range_end = ROTULO_MINIMO
				g.visibility_range_end_margin = 8.0
				n += 1
			continue
		if fuera.has(g) or (g.visibility_range_end > 0.0 and g.visibility_range_end <= hasta):
			continue
		if g.get_aabb().size.length() > grande and _pieza_mayor(g) > PIEZA_PEQUENA:
			continue
		if guardar is Dictionary:
			(guardar as Dictionary)[g] = [g.visibility_range_end, g.visibility_range_end_margin]   ## (para devolverlo al salir del paseo)
		g.visibility_range_end = hasta
		g.visibility_range_end_margin = hasta * 0.1
		n += 1
	return n

## Lo último que hace la ciudad al optimizarse (7-11): las zonas de vista y, en ULTRA BAJA y BAJA de CUALQUIER sistema (no solo en móvil), el mismo tope
## de 450 m para lo pequeño: ciudad a pie 688 → 411 llamadas de dibujo, mapa aéreo 2.761 → 1.321 (ULTRA BAJA, `medir_ciudad`). Va AL FINAL, tras `agrupar`:
## si el tope existe antes, `agrupar` trata distinto las piezas (la grúa de la obra desaparecía). Móvil y motor ligero ya lo ponen antes.
static func al_final(raiz: Node3D, prologo: bool, ceder: Object = null) -> void:
	await FundirPiezas.fundir_ciudad(raiz, 160.0, "FundidoCiudad", ceder)   ## (7-11) primitivas sueltas por material y celda: menos nodos y llamadas, misma imagen
	SubsistemasQuietos.limpiar()
	if ceder != null:
		await ceder._marca("fundir_ciudad")   ## (6-11) `ceder`: el CityBuilder que construye por partes; cada pasada cede por separado
	ZonasVista.montar(raiz)
	if ceder != null:
		await ceder._marca("zonas_vista")
	if not prologo and Calidad.elegida <= Calidad.BAJA and not (EscalaMovil.es_movil() or Calidad.motor_ligero or OS.get_environment("MOVIL_SIM") != ""):
		limitar_vista(raiz, 450.0)   ## (el recorte más cerrado, 64 % del alcance a pie, solo rige MIENTRAS SE PASEA: `recorte_a_pie`; el mapa aéreo conserva sus 450 m)
		if ceder != null:
			await ceder._marca("limitar_vista")
		rotulos_cercanos(raiz)   ## y los rótulos 3D con alcance según su tamaño (galería del club, vestuario…)

## Un TROZO de agrupado (MultiMesh) con la caja grande pero solo piezas PEQUEÑAS dentro (ventanas, postes, troncos, hidrantes: menos de `PIEZA_PEQUENA` m) tampoco debe
## verse a 450 m (7-11; en ULTRA BAJA, ciudad a pie 411 → 312 llamadas). Los bloques de edificios (20-30 m por pieza) se quedan: en el mapa aéreo se ven desde lejos.
const PIEZA_PEQUENA := 14.0

## La pieza más grande de dentro de un trozo de agrupado; 9999 si no se sabe o es un agrupado enorme (> 4000 instancias: no se arriesga a esconder edificios).
static func _pieza_mayor(g: GeometryInstance3D) -> float:
	var mmi := g as MultiMeshInstance3D
	if mmi == null or mmi.multimesh == null or mmi.multimesh.mesh == null or mmi.multimesh.transform_format != MultiMesh.TRANSFORM_3D or mmi.multimesh.instance_count > 4000:
		return 9999.0
	var mm := mmi.multimesh
	var base := mm.mesh.get_aabb().size
	var mx := 0.0
	for i in mm.instance_count:
		mx = maxf(mx, (mm.get_instance_transform(i).basis * base).length())
	return mx

## Hasta dónde se dibuja a pie en ULTRA BAJA (200 m) y BAJA (300 m): alcance de la cámara, fin de la niebla (empieza al 43 %), y lo pequeño se corta al 64 % (7-11). `ALCANCE_PIE=n` lo cambia (mediciones).
static func alcance_a_pie() -> float:
	if OS.get_environment("ALCANCE_PIE") != "":
		return float(OS.get_environment("ALCANCE_PIE"))
	return 180.0 if Calidad.elegida <= Calidad.ULTRA_BAJA else 300.0   ## (7-11, aprobado por el dueño para llegar a < 120 llamadas: medido a pie 700 m → 275 llamadas, 300 m → 158, 200 m → 117-125, 180 m → 117)

static var _originales := {}   ## pieza → [alcance, margen] que tenía antes del recorte a pie

## (7-11) Mientras se PASEA en ULTRA BAJA o BAJA, lo pequeño se corta al 64 % del alcance a pie (128 m en ULTRA BAJA); al salir al mapa se devuelve todo a como estaba: el recorte
## estaba fijo desde que se construía la ciudad y dejaba el mapa aéreo sin árboles, bancos ni edificios pequeños (capturas antes/después con `ALCANCE_PIE`).
static func recorte_a_pie(cb: Node, si: bool) -> void:
	if si:
		if cb != null and _originales.is_empty():
			limitar_vista(cb, alcance_a_pie() * 0.64, 90.0, _originales)
		return
	for g: Variant in _originales:
		if is_instance_valid(g):
			(g as GeometryInstance3D).visibility_range_end = float(_originales[g][0])
			(g as GeometryInstance3D).visibility_range_end_margin = float(_originales[g][1])
	_originales.clear()

## Niebla de profundidad del paseo a pie en ULTRA BAJA y BAJA (7-11): con la cámara a 700 m de alcance (`explorador_ciudad_p4.gd`) la niebla va de 300 a 700 m y esconde el corte.
## Solo mientras se pasea: el mapa aéreo comparte entorno y quedaría tapado, así que se guarda lo anterior en un meta del entorno y se devuelve al salir (`_exit_tree`).
static func niebla_a_pie(nodo: Node3D, si: bool) -> void:
	recorte_a_pie(nodo.get("cb") as Node, si)   ## (el explorador ya lo llama al entrar y al salir del paseo)
	var w := nodo.get_world_3d()
	var env: Environment = w.environment if w != null else null
	if env == null:
		return
	if si and not env.has_meta("niebla_guardada"):
		env.set_meta("niebla_guardada", [env.fog_enabled, env.fog_mode, env.fog_density, env.fog_depth_begin, env.fog_depth_end, env.fog_depth_curve])
		env.fog_enabled = true
		env.fog_mode = Environment.FOG_MODE_DEPTH
		env.fog_depth_begin = alcance_a_pie() * 0.43
		env.fog_depth_end = alcance_a_pie()
		env.fog_depth_curve = 1.0
		env.fog_density = 1.0
	elif not si and env.has_meta("niebla_guardada"):
		var g: Array = env.get_meta("niebla_guardada")
		env.fog_enabled = g[0]
		env.fog_mode = g[1]
		env.fog_density = g[2]
		env.fog_depth_begin = g[3]
		env.fog_depth_end = g[4]
		env.fog_depth_curve = g[5]
		env.remove_meta("niebla_guardada")

## Rótulos 3D con alcance según su tamaño (7-11): cada `Label3D` es una llamada de dibujo y un texto no se lee a más de ~300 veces su altura (el nombre del personal, de 6 cm, a unos
## 17 m; el letrero de la fachada, de metro y medio, a 90 m). Solo a los que no traen tope o lo traen mayor. En ULTRA BAJA y BAJA, al acabar de montarse el prólogo. Devuelve cuántos.
static func rotulos_cercanos(raiz: Node) -> int:
	var n := 0
	if raiz == null:
		return 0
	for l: Node in raiz.find_children("*", "Label3D", true, false):
		var g := l as Label3D
		var r := clampf(float(g.font_size) * g.pixel_size * 300.0, 15.0, 90.0)
		if g.visibility_range_end <= 0.0 or g.visibility_range_end > r:
			g.visibility_range_end = r
			g.visibility_range_end_margin = r * 0.15
			n += 1
	return n

