extends "res://visor/stadium_builder_p4.gd"
## (Parte 5 de 11 de `stadium_builder.gd`.)

## Los trozos [centro, largo] de un tramo `largo` centrado en `centro` que
## quedan a los dos lados del hueco [g0, g1]. Si el hueco no lo toca, uno solo.
static func _tramos_sin_hueco(centro: float, largo: float, g0: float, g1: float) -> Array:
	var a := centro - largo / 2.0
	var b := centro + largo / 2.0
	if g1 <= a or g0 >= b:
		return [Vector2(centro, largo)]
	var sal: Array = []
	if g0 > a + 0.05:
		sal.append(Vector2((a + g0) / 2.0, g0 - a))
	if b > g1 + 0.05:
		sal.append(Vector2((g1 + b) / 2.0, b - g1))
	return sal

## Cuantas bandejas se dibujan de verdad. Manda lo que el club diseño, acotado
## por lo que el aforo justifica -un estadio de 8.000 con 5 bandejas seria
## falso-. `EstadioPropio.niveles_maximos()` repite este criterio a proposito,
## para no ofrecer en la pantalla de diseño una bandeja que el visor no va a
## dibujar (y cobrarla).
static func niveles_de(est: Dictionary, cap_efectiva: int) -> int:
	var niveles_est := int(est.get("niveles", 2))
	var niveles_cap: int = clampi(
		int(floor(float(cap_efectiva) / 22000.0)) + 1, 1, NIVELES_MAX)
	return clampi(mini(niveles_est, niveles_cap), 1, NIVELES_MAX)

## Lo que sube UNA bandeja.
static func subida_bandeja() -> float:
	return FONDO_BANDEJA * tan(deg_to_rad(RAKE_GRADOS))

## Altura total del graderio: las bandejas mas los frentes que las separan.
static func altura_de(est: Dictionary, cap_efectiva: int) -> float:
	var n := niveles_de(est, cap_efectiva)
	return ALTURA_PIE + float(n) * subida_bandeja() + float(n - 1) * FRENTE_BANDEJA

## Lo que ocupa la tribuna en planta, de la cara interior hacia afuera.
static func fondo_tribuna(niveles: int) -> float:
	return FONDO_BANDEJA + float(maxi(niveles - 1, 0)) * RETRANQUEO_BANDEJA

## El centro de la tribuna en el eje que la cruza. La cara interior se queda
## clavada en `eje - FRENTE_TRIBUNA` cueste lo que cueste, y lo que se mueve al
## crecer es el centro y la cara exterior.
static func centro_tribuna(eje: float, niveles: int) -> float:
	return eje - FRENTE_TRIBUNA + fondo_tribuna(niveles) / 2.0

## `colores`: `[claro, oscuro]` de la piel elegida -ver `Comercial.color_balon()`-.
## Vacío se queda con la piel "clásico" (blanco y negro) de siempre, así que
## nada que llame a esto sin conocer todavía la piel del club se rompe.
static func spawn_ball(root: Node3D, pos: Vector3, colores: Array = []) -> Balon3D:
	var claro: Color = colores[0] if colores.size() > 0 else Color("#f8faf6")
	var oscuro: Color = colores[1] if colores.size() > 1 else Color("#1a1a1a")
	var ball := Balon3D.crear(pos, claro, oscuro, String(colores[2]) if colores.size() > 2 else "clasico")
	root.add_child(ball)
	return ball

## est: perfil de perfilEstadio(). cap_efectiva: aforo real ya ajustado por las
## obras del club (capEfectivo() en el HTML). ocupacion: 0..1 de gente en la grada.
## LA EXPLANADA DE FONDO (13-9-2026). El césped es una plancha de solo
## 80×117 m -PITCH_WID/LEN más 12 de margen-, y NINGUNA otra geometría cubre
## el suelo más allá de eso. Encontrado con una captura real desde "Detrás
## del arco": esa cámara queda apenas FUERA del borde de esa plancha, y mirar
## hacia el campo desde ahí enseña una franja de "nada" -el cielo asomando
## por abajo, aquí de un gris azulado plano- antes de llegar al verde. Una
## base grande y neutra, bien por debajo del césped para no pelear en el
## z-fighting, asegura que NINGUNA cámara del estadio -sea cual sea su forma
## o tamaño- pueda ver ese hueco, sin tener que calcular el caso por caso.
static func _explanada_de_fondo(root: Node3D) -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(400.0, 400.0)
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.position = Vector3(0, -0.15, 0)
	## `Texturas.hormigon()` ya devuelve el MATERIAL completo, no una textura
	## suelta -asignarlo a `albedo_texture` no compila: son tipos distintos-.
	##
	## CORREGIDO (17-9-2026), reportado por el usuario como una franja
	## horizontal rota/temblorosa justo despues del perimetro: este plano de
	## 400x400 m con el `uv1_scale` normal de `hormigon()` (pensado para una
	## fachada de pocos metros, no para un suelo de fondo) se repite mas de
	## 200 veces de lado a lado. Visto en angulo rasante desde cualquier
	## camara del estadio -que es exactamente como se ve, nunca de frente-,
	## esa densidad de detalle fino (el mapa de normales sobre todo) hace
	## aliasing/muaré: no es un fallo de carga ni z-fighting, es la textura
	## repitiendose demasiadas veces para lo que el anti-aliasing del juego
	## puede filtrar a esa distancia. DUPLICADO y aflojado -mucho menos
	## repeticion y sin mapa de normales-, porque esta plancha es puro relleno
	## de fondo (el propio comentario de arriba ya lo dice: "para no pelear en
	## z-fighting", nunca se pensó como superficie protagonista).
	var mat_explanada: StandardMaterial3D = Texturas.hormigon(Color(0.30, 0.31, 0.33), 41).duplicate()
	## 26-9-2026: sin rayas en ángulo rasante. Se repite en el mundo (un
	## mosaico cada 2 m, el tamaño de una losa de hormigón) y con filtrado
	## anisótropo, en vez de estirar una textura sobre 400 m.
	mat_explanada.uv1_world_triplanar = true
	mat_explanada.uv1_scale = Vector3(0.5, 0.5, 0.5)
	mat_explanada.normal_enabled = false
	mi.material_override = mat_explanada
	root.add_child(mi)
static func _tm(que: String) -> void:
	if CityBuilder._medir_tiempos:
		var ahora := Time.get_ticks_usec()
		if que != "":
			print("TIEMPO estadio.%-16s %6.0f ms" % [que, (ahora - _t_tm) / 1000.0])
		_t_tm = ahora

static func _primera_malla(n: Node) -> Mesh:
	if n == null:
		return null
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		return (n as MeshInstance3D).mesh
	for c in n.get_children():
		var r := _primera_malla(c)
		if r != null:
			return r
	return null

static func _malla_butaca_lejos() -> Mesh:
	if _butaca_lejos != null:
		return _butaca_lejos
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var asiento := BoxMesh.new()
	asiento.size = Vector3(1.46, 0.07, 0.40)
	st.append_from(asiento, 0, Transform3D(Basis(), Vector3(-0.05, 0.40, 0.04)))
	var respaldo := BoxMesh.new()
	respaldo.size = Vector3(0.44, 0.38, 0.05)
	for k in 3:
		var x := -0.55 + float(k) * 0.5
		st.append_from(respaldo, 0, Transform3D(Basis(Vector3(1, 0, 0), -0.14), Vector3(x, 0.58, -0.20)))
	var viga := BoxMesh.new()
	viga.size = Vector3(1.40, 0.30, 0.06)
	st.append_from(viga, 0, Transform3D(Basis(), Vector3(-0.05, 0.20, -0.08)))
	_butaca_lejos = st.commit()
	return _butaca_lejos

## ¿Esta columna de butacas es un pasillo? Cada 8 grupos (≈ 12 m), en tribunas
## de al menos 12 grupos.
static func es_pasillo(c: int, cuantas_fila: int) -> bool:
	return cuantas_fila >= 12 and c % 8 == 4
## Los peldaños de todos los pasillos de una bandeja en un MultiMesh, y una
## barandilla por pasillo (en el espacio del deck, que va inclinado: la
## barandilla sigue la pendiente sola).
static func _montar_pasillos(deck: MeshInstance3D, escalones: Array[Transform3D], pasillos_l: Array[float],
		lateral: bool, fondo: float) -> void:
	if escalones.is_empty():
		return
	if _mat_peldano == null:
		_mat_peldano = StandardMaterial3D.new()
		_mat_peldano.albedo_color = Color(0.68, 0.68, 0.66)
		_mat_peldano.roughness = 0.9
		_mat_baranda = StandardMaterial3D.new()
		_mat_baranda.albedo_color = Color(0.82, 0.83, 0.85)
		_mat_baranda.metallic = 0.6
		_mat_baranda.roughness = 0.35
	var bm := BoxMesh.new()
	bm.size = Vector3(1.25, 0.42, PASO_FILA + 0.02)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = bm
	mm.instance_count = escalones.size()
	for k in escalones.size():
		mm.set_instance_transform(k, escalones[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Pasillos"
	mmi.multimesh = mm
	mmi.material_override = _mat_peldano
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	deck.add_child(mmi)
	if fondo < 3.0:
		return
	var rail := BoxMesh.new()
	rail.size = Vector3(0.05, 0.05, fondo - 0.6)
	var mr := MultiMesh.new()
	mr.transform_format = MultiMesh.TRANSFORM_3D
	mr.mesh = rail
	mr.instance_count = pasillos_l.size()
	for k in pasillos_l.size():
		var l: float = pasillos_l[k]
		var bas := Basis(Vector3.UP, PI * 0.5) if lateral else Basis()
		var pos := Vector3(0.0, 0.95, l) if lateral else Vector3(l, 0.95, 0.0)
		mr.set_instance_transform(k, Transform3D(bas, pos))
	var mri := MultiMeshInstance3D.new()
	mri.name = "Barandillas"
	mri.multimesh = mr
	mri.material_override = _mat_baranda
	mri.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	deck.add_child(mri)
static func _escaleras_de_acceso(deck: MeshInstance3D, escalones: Array[Transform3D], pasillos_l: Array[float], lateral: bool) -> void:
	var root := deck.get_parent() as Node3D
	if root == null or pasillos_l.is_empty():
		return
	var xfs: Array[Transform3D] = []
	for l: float in pasillos_l:
		## El primer peldaño de ese pasillo (fila 0): el de esa columna más bajo.
		var bajo := Vector3.INF
		for e: Transform3D in escalones:
			var o := e.origin
			if absf((o.z if lateral else o.x) - l) < 0.3:
				var g := deck.transform * o
				if bajo == Vector3.INF or g.y < bajo.y:
					bajo = g
		if bajo == Vector3.INF or bajo.y < 0.5:
			continue
		## Hacia el campo: −x en la lateral de +x, etc.
		var dir := Vector3(-signf(bajo.x), 0, 0) if lateral else Vector3(0, 0, -signf(bajo.z))
		var n := int(ceil((bajo.y - 0.05) / PELDANO_ALTO))
		for k in n:
			var alto := bajo.y - float(k) * PELDANO_ALTO
			var c := bajo + dir * (0.45 + float(k) * PELDANO_FONDO)
			c.y = alto * 0.5 - 0.1
			var bas := Basis.from_scale(Vector3(1.25, maxf(alto, 0.1), PELDANO_FONDO)) if not lateral \
				else Basis.from_scale(Vector3(PELDANO_FONDO, maxf(alto, 0.1), 1.25))
			xfs.append(Transform3D(bas, c))
	if xfs.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = BoxMesh.new()
	mm.instance_count = xfs.size()
	for k in xfs.size():
		mm.set_instance_transform(k, xfs[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "EscalerasAcceso"
	mmi.multimesh = mm
	mmi.material_override = _mat_peldano
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)

static func _mat_escalones() -> StandardMaterial3D:
	if _escalones == null:
		_escalones = Texturas.hormigon(Color(0.52, 0.52, 0.54), 83)
	return _escalones

static func _hinchas_horneados(nivel: String) -> Array:
	if _hornead.has(nivel):
		return _hornead[nivel]
	var l: Array = []
	for pz in POSES_PUBLICO:
		var ruta := "res://assets/ciudad/publico/hincha_%s_%s.res" % [pz, nivel]
		if not ResourceLoader.exists(ruta):
			l = []
			break
		l.append(load(ruta))
	_hornead[nivel] = l
	return l

## Un MultiMesh por pose con su shader de hinchada; `xfs`/`cols` se reparten
## entre las poses por un hash estable (la misma grada sale siempre igual).
static func _montar_horneados(deck: Node3D, nombre: String, mallas: Array, xfs: Array[Transform3D], cols: Array[Color], desde := 0.0, hasta := 0.0) -> void:
	var grupos: Array = []
	for _p in mallas.size():
		grupos.append([])
	for k in xfs.size():
		grupos[(k * 7919 + int(xfs[k].origin.x * 3.0) + int(xfs[k].origin.z * 5.0)) % mallas.size()].append(k)
	for g in mallas.size():
		var ids: Array = grupos[g]
		if ids.is_empty():
			continue
		## Alturas de cuello y pelo medidas al hornear esta pose (metadatos de la malla).
		var mat := ShaderMaterial.new()
		mat.shader = load("res://visor/hinchada.gdshader")
		var malla: Mesh = mallas[g]
		mat.set_shader_parameter("cuello_desde", float(malla.get_meta("cuello_desde", 0.70)))
		mat.set_shader_parameter("cuello_hasta", float(malla.get_meta("cuello_hasta", 0.73)))
		mat.set_shader_parameter("pelo_desde", float(malla.get_meta("pelo_desde", 0.86)))
		mat.set_shader_parameter("lado_max", 0.14)
		mat.set_shader_parameter("amplitud", 0.03)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = malla
		mm.instance_count = ids.size()
		for n in ids.size():
			mm.set_instance_transform(n, xfs[ids[n]])
			mm.set_instance_color(n, cols[ids[n]])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = mat
		mmi.name = "%s_%s" % [nombre, POSES_PUBLICO[g]]
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_begin = desde
		mmi.visibility_range_end = hasta
		deck.add_child(mmi)

static func _montar_publico_lod(deck: Node3D, nombre: String, mallas: Array, xfs: Array[Transform3D], cols: Array[Color]) -> void:
	var lejos := _hinchas_horneados("lejos")
	## SIN_LOD_PUBLICO=1: el montaje de antes (para medir antes/después).
	if lejos.is_empty() or xfs.is_empty() or OS.get_environment("SIN_LOD_PUBLICO") != "":
		_montar_horneados(deck, nombre, mallas, xfs, cols)
		return
	var suplentes: Array = [lejos[0], lejos[mini(2, lejos.size() - 1)]]
	## Eje largo de la bandeja (en su espacio local).
	var lo := xfs[0].origin
	var hi := xfs[0].origin
	for t in xfs:
		lo = lo.min(t.origin)
		hi = hi.max(t.origin)
	var eje := 0 if (hi.x - lo.x) >= (hi.z - lo.z) else 2
	var largo := maxf(hi[eje] - lo[eje], 0.001)
	for k in TRAMOS_PUBLICO:
		var tx: Array[Transform3D] = []
		var tc: Array[Color] = []
		for i in xfs.size():
			var f := clampi(int((xfs[i].origin[eje] - lo[eje]) / largo * TRAMOS_PUBLICO), 0, TRAMOS_PUBLICO - 1)
			if f == k:
				tx.append(xfs[i])
				tc.append(cols[i])
		if tx.is_empty():
			continue
		_montar_horneados(deck, "%s%d" % [nombre, k], mallas, tx, tc, 0.0, LOD_PUBLICO)
		_montar_horneados(deck, "%s%d_lejos" % [nombre, k], suplentes, tx, tc, LOD_PUBLICO, 0.0)

static func _malla_hincha_detalle() -> Mesh:
	if _malla_hincha_det != null:
		return _malla_hincha_det
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var torso := CylinderMesh.new()
	torso.top_radius = 0.16
	torso.bottom_radius = 0.13
	torso.height = 0.40
	torso.radial_segments = 7
	torso.rings = 1
	st.append_from(torso, 0, Transform3D(Basis().scaled(Vector3(1.0, 1.0, 0.72)), Vector3(0, 0.29, 0)))
	var hombros := CapsuleMesh.new()
	hombros.radius = 0.075
	hombros.height = 0.44
	hombros.radial_segments = 6
	hombros.rings = 1
	st.append_from(hombros, 0, Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5).scaled(Vector3(1.0, 1.0, 0.8)), Vector3(0, 0.47, 0)))
	var brazo := CapsuleMesh.new()
	brazo.radius = 0.045
	brazo.height = 0.40
	brazo.radial_segments = 5
	brazo.rings = 1
	for lado in [-1.0, 1.0]:
		## Brazos caídos y un poco adelantados, como sentado con las manos en
		## las rodillas.
		var b := Basis(Vector3(1, 0, 0), -0.35).rotated(Vector3(0, 0, 1), 0.10 * lado)
		st.append_from(brazo, 0, Transform3D(b, Vector3(0.20 * lado, 0.31, 0.05)))
	var cuello := CylinderMesh.new()
	cuello.top_radius = 0.045
	cuello.bottom_radius = 0.05
	cuello.height = 0.08
	cuello.radial_segments = 5
	cuello.rings = 1
	st.append_from(cuello, 0, Transform3D(Basis(), Vector3(0, 0.56, 0)))
	var cabeza := SphereMesh.new()
	cabeza.radius = 0.10
	cabeza.height = 0.23
	cabeza.radial_segments = 8
	cabeza.rings = 5
	st.append_from(cabeza, 0, Transform3D(Basis(), Vector3(0, 0.67, 0)))
	st.generate_normals()
	_malla_hincha_det = st.commit()
	return _malla_hincha_det

static func _malla_hincha_minima() -> Mesh:
	if _malla_hincha_min != null:
		return _malla_hincha_min
	var torso := CylinderMesh.new()
	torso.top_radius = 0.16
	torso.bottom_radius = 0.18
	torso.height = 0.55
	torso.radial_segments = 5
	torso.rings = 0
	torso.cap_bottom = false
	var cabeza := SphereMesh.new()
	cabeza.radius = 0.11
	cabeza.height = 0.22
	cabeza.radial_segments = 5
	cabeza.rings = 2
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(torso, 0, Transform3D(Basis(), Vector3(0, 0.28, 0)))
	st.append_from(cabeza, 0, Transform3D(Basis(), Vector3(0, 0.61, 0)))
	_malla_hincha_min = st.commit()
	return _malla_hincha_min

static func _malla_hincha_cache() -> Mesh:
	if Calidad.elegida == Calidad.MEDIO:
		return _malla_hincha_minima()
	if _malla_hincha != null:
		return _malla_hincha
	var torso := CapsuleMesh.new()
	torso.radius = 0.18
	torso.height = 0.55
	torso.radial_segments = 6
	torso.rings = 1
	var cabeza := SphereMesh.new()
	cabeza.radius = 0.11
	cabeza.height = 0.22
	cabeza.radial_segments = 6
	cabeza.rings = 4
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(torso, 0, Transform3D(Basis(), Vector3(0, 0.28, 0)))
	st.append_from(cabeza, 0, Transform3D(Basis(), Vector3(0, 0.61, 0)))
	_malla_hincha = st.commit()
	return _malla_hincha
