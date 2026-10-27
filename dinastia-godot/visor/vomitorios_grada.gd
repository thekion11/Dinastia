class_name VomitoriosGrada
extends RefCounted
## LOS ACCESOS DE LA GRADA (vomitorios). Salió de `stadium_builder_p6.gd` el 27-10-2026 (norma de 450 líneas).

static func montar(deck: MeshInstance3D, largo: float, fondo: float,
		lateral: bool) -> void:
	## Los accesos están en el borde ALTO de la rampa: depende de cómo esté girada la tribuna (ver `_butacas`).
	var sentido: float = 1.0 if (deck.basis * (Vector3(1, 0, 0) if lateral else Vector3(0, 0, 1))).y >= 0.0 else -1.0
	var d: float = sentido * (fondo * 0.5 - 0.35)
	## ACCESOS CON CUERPO (27-10-2026, «mejorar los accesos»; recolocados tras la revisión del líder: «flotaban cajas negras en el borde»).
	## Cada vomitorio es un bloque de hormigón METIDO EN LA GRADA, al final de un PASILLO (la misma columna libre con escalera de
	## `_butacas`), bajo y asentado sobre la rampa: una masa de 5 m de ancho, 2,3 m de alto y 1,6 m de fondo con el hueco negro metido en su
	## cara y el rótulo de SALIDA encima. Tres MultiMesh por grada (hormigón, hueco, rótulo): sin nodos por vomitorio.
	var cuantas_fila: int = maxi(1, int(largo / StadiumBuilder.PASO_BUTACA))
	var pasillos: Array[float] = []
	for c in range(cuantas_fila):
		if StadiumBuilder.es_pasillo(c, cuantas_fila):
			pasillos.append(-largo * 0.5 + 0.8 + float(c) * StadiumBuilder.PASO_BUTACA)
	var objetivo: int = clampi(int(largo / 26.0), 2, 6)
	var centros: Array[float] = []
	if pasillos.is_empty():
		for k in objetivo:
			centros.append(-largo * 0.5 + largo * (float(k) + 0.5) / float(objetivo))
	else:
		var paso: int = maxi(1, int(round(float(pasillos.size()) / float(objetivo))))
		for k in range(paso / 2, pasillos.size(), paso):
			centros.append(pasillos[k])
	var hormigon: Array[Transform3D] = []
	var hueco: Array[Transform3D] = []
	var rotulo: Array[Transform3D] = []
	for centro: float in centros:
		_caja_vom(hormigon, d + sentido * 0.45, 1.15, centro, 5.0, 2.3, 1.7, lateral)        ## el bloque, asentado en la rampa
		_caja_vom(hueco, d - sentido * 0.43, 0.95, centro, 1.9, 1.9, 0.12, lateral)         ## el hueco, metido en la cara del bloque
		_caja_vom(rotulo, d - sentido * 0.45, 2.1, centro, 1.3, 0.26, 0.06, lateral)        ## SALIDA sobre el hueco
	_multi_vom(deck, "VomitoriosHormigon", hormigon, null, Color(0.58, 0.58, 0.56), 0.0)
	_multi_vom(deck, "VomitoriosHueco", hueco, null, Color(0.02, 0.025, 0.03), 0.0)
	_multi_vom(deck, "VomitoriosRotulo", rotulo, null, Color(0.1, 0.85, 0.35), 1.6)

## Una caja en espacio del deck: `dep` sobre el eje del fondo, `y` el centro, `a` a lo largo; `an`/`al`/`pr`: ancho, alto, profundidad.
static func _caja_vom(lista: Array[Transform3D], dep: float, y: float, a: float, an: float, al: float, pr: float, lateral: bool) -> void:
	var pos := Vector3(dep, 0.3 + y, a) if lateral else Vector3(a, 0.3 + y, dep)
	var tam := Vector3(pr, al, an) if lateral else Vector3(an, al, pr)
	lista.append(Transform3D(Basis.from_scale(tam), pos))

static func _multi_vom(deck: MeshInstance3D, nombre: String, ts: Array[Transform3D], _tex: Texture2D, col: Color, brillo: float) -> void:
	if ts.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = BoxMesh.new()
	mm.instance_count = ts.size()
	for i in ts.size():
		mm.set_instance_transform(i, ts[i])
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.95 if brillo == 0.0 else 0.4
	if brillo > 0.0:
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = brillo
	var mi := MultiMeshInstance3D.new()
	mi.name = nombre
	mi.multimesh = mm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	deck.add_child(mi)
